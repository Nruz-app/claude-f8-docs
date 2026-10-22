-- =====================================================================
-- POC FSCC-12901 - 05 Simular (DESARROLLO)
-- Anticipa, caja por caja, que haran T1 y T2 SIN grabar en las tablas del
-- sistema (solo guarda la prevision en VTA_FACOPOC_CASOS.prev_t1 / prev_t2):
--   T1: PKG_F8_FACO_COMPENSA_DI.fn_evalua_caja
--   T2: si T1 deja la DR en 0 (COMPENSABLE o DR_CERO) -> pr_valida_y decide
--       CERRADA_Y o BLOQUEADA; si la DR sigue <> 0 -> CON_DIFERENCIA.
-- 07_resultados.sql compara lo obtenido contra lo esperado del escenario o,
-- si el escenario no fija resultado (R0, S0), contra esta prevision.
-- =====================================================================

declare
  v_dr    number;
  v_t1    varchar2(30);
  v_t2    varchar2(30);
  v_regla varchar2(10);
  v_msg   varchar2(1000);
  v_n     number := 0;
begin
  for c in (select rowid rid, x.* from VTA_FACOPOC_CASOS x) loop
    v_t1 := PKG_F8_FACO_COMPENSA_DI.fn_evalua_caja(c.c_fecha, c.c_local, c.c_terminal, c.c_cierrey, v_dr);
    if v_t1 in ('COMPENSABLE', 'DR_CERO') then
      PKG_F8_FACO_CIERRE_AUTO.pr_valida_y(c.c_fecha, c.c_local, c.c_terminal, c.c_cierrey, v_regla, v_msg);
      v_t2 := case when v_regla is null then 'CERRADA_Y' else 'BLOQUEADA' end;
    elsif v_t1 in ('YA_CERRADA', 'SIN_LIBVTA') then
      v_t2 := v_t1;
    else
      v_t2 := 'CON_DIFERENCIA';
    end if;
    if v_t1 = 'COMPENSABLE' then
      v_t1 := 'DI_REGISTRADA';
    end if;
    update VTA_FACOPOC_CASOS set prev_t1 = v_t1, prev_t2 = v_t2 where rowid = c.rid;
    v_n := v_n + 1;
  end loop;
  commit;
  dbms_output.put_line('Prevision calculada para ' || v_n || ' cajas');
end;
/

-- 1. Prevision por origen y escenario
select c_origen, escenario, prev_t1, prev_t2, count(*) cajas
  from VTA_FACOPOC_CASOS
 group by c_origen, escenario, prev_t1, prev_t2
 order by 1, 2, 3, 4;

-- 2. Escenarios con resultado fijo donde la prevision NO coincide (esperado: 0 filas)
select c_origen, escenario, c_local, c_terminal, c_cierrey, dr_objetivo,
       esperado_t1, prev_t1, esperado_t2, prev_t2
  from VTA_FACOPOC_CASOS
 where esperado_t1 is not null
   and (esperado_t1 <> prev_t1 or esperado_t2 <> prev_t2)
 order by 1, 2, 3, 4, 5;
