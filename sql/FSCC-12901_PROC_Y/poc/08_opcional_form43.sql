-- =====================================================================
-- POC FSCC-12901 v2 (multipais, FACO) - 08 (Opcional) Boton "Cerrar Terminal" de Form43 (DESARROLLO)
-- Ejecuta PKG_F8_CIERRE_AUTO.prc_cierre_dia('FACO', ...) sobre UN local del dia
-- PRD 3 (28-08-2026), como lo haria el analista desde Consultas de Cuadratura:
-- mismas reglas RY, SIN T1 (no registra DI), log_proceso CC.
-- Para verlo cerrar algo, ejecutar ANTES de 06 (o despues de 98): asi
-- encuentra las cajas P0/P6 abiertas. Despues de 06 solo quedan abiertas las
-- que tienen diferencia o concepto pendiente.
-- GRABA (cierres Y). Lo revierte 98 / 99.
-- =====================================================================

declare
  v_local number := 6;                 -- EDITAR: local del dia PRD 3
  v_ejec  number; v_cerr number; v_nocer number;
begin
  PKG_F8_CIERRE_AUTO.prc_cierre_dia(
    p_flg_pais    => 'FACO',             -- en Form43 es Flg_Pais$
    p_fecha       => '20260828',      -- un solo dia (DTPicker1 en Form43)
    p_local       => v_local,
    p_terminal    => 0,                 -- 0 = todos los terminales
    p_usuario     => 'POC_ANALISTA',    -- en Form43 es LOGINUSER
    o_ejecucion   => v_ejec,
    o_cerradas    => v_cerr,
    o_no_cerradas => v_nocer);

  delete from VTA_FACOPOC_CTRL where clave = 'EJECUCION_CC';
  insert into VTA_FACOPOC_CTRL values ('EJECUCION_CC', to_char(v_ejec));
  commit;
  dbms_output.put_line('Cerrar Terminal (CC): ejecucion ' || v_ejec ||
                       ' | Y cerradas ' || v_cerr || ' | Y no cerradas ' || v_nocer);
end;
/

-- Resultado de la ejecucion CC por resultado y regla
select l.log_resultado, l.log_regla, count(*) cajas
  from VTA_FACOLOG_CIERRE_AUTO l
 where l.log_ejecucion = (select to_number(valor) from VTA_FACOPOC_CTRL where clave = 'EJECUCION_CC')
   and l.log_nivel = 'Y'
 group by l.log_resultado, l.log_regla
 order by 1, 2;

-- Detalle
select l.log_terminal, l.log_cierrey, l.log_dif_real, l.log_resultado, l.log_regla, l.log_mensaje
  from VTA_FACOLOG_CIERRE_AUTO l
 where l.log_ejecucion = (select to_number(valor) from VTA_FACOPOC_CTRL where clave = 'EJECUCION_CC')
 order by l.log_id;
