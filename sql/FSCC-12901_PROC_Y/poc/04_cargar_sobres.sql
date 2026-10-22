-- =====================================================================
-- POC FSCC-12901 v2 (multipais, FACO) - 04 Cargar sobres = simular Form133 "Cargar Archivo" (DESARROLLO)
-- Inserta en VTA_FACOPRD con el MISMO insert de 29 columnas que
-- Form133.CargarArchivo usa para Colombia (Form133.frm:1671, rama FACO).
-- El trigger TRG_VTA_FACOPRD_CIERRE_AI los encola en VTA_FACOPRD_CIERRE.
--   B) Dia PRD 3: los 486 sobres REALES del archivo.
--   A) Cajas reales copiadas de TEST: un sobre por caja segun escenario
--      (R0 deposito = efectivo declarado; E1 DR -800; E2 DR 0; E3 DR -30000;
--       S0 sin sobre). Ver 00_LEEME.
-- Marca: prv_modifpor = 'POC_FSCC12901'. GRABA. Lo revierte 99.
-- =====================================================================

-- ---------------------------------------------------------------
-- B) Sobres reales de PRD 3.xlsx
-- ---------------------------------------------------------------
declare
  v_n number := 0;
begin
  for s in (select * from VTA_FACOPOC_PRD3 order by p_local, p_terminal, p_sobre) loop
    insert into VTA_FACOPRD
      (prv_techkey, prv_fechadep, prv_local, prv_terminal, prv_tiporec, prv_prscli,
       prv_servicio, prv_sobre, prv_prsloc, prv_prscajero, prv_tiposobre, prv_ctacte,
       prv_nomcta, prv_totdocs, prv_tipodifdoc, prv_numdifdoc, prv_coddifdoc, prv_nomdifdoc,
       prv_montosobre, prv_tipodifmon, prv_montodif, prv_coddifmon, prv_nomdifmon,
       prv_serv2, prv_numrec, prv_fechavta, prv_modifpor, prv_cierrey, prv_cod_recaud)
    values
      (SEQ_VTA_FACOPRS.nextval, trunc(sysdate), s.p_local, s.p_terminal, 'F8', 1,
       'E', s.p_sobre, 1, 7, 'EFE', '00',
       'INTERNO', 0, 'C', 0, '000', 'in',
       s.p_monto, 'C', s.p_dif, 0, '000',
       'in', s.p_numrec, s.p_fecha, 'POC_FSCC12901', s.p_cierrey, '00562');
    v_n := v_n + 1;
  end loop;
  commit;
  dbms_output.put_line('PRD 3: ' || v_n || ' sobres cargados');
end;
/

-- ---------------------------------------------------------------
-- A) Sobres para las cajas reales de TEST
-- ---------------------------------------------------------------
declare
  v_k     number := 0;
  v_d0    number;
  v_efe   number;
  v_esc   varchar2(3);
  v_obj   number;
  v_monto number;
  v_t1    varchar2(30);
  v_t2    varchar2(30);
  v_regla varchar2(10);
  v_msg   varchar2(1000);
  v_ok    boolean;
  v_cnt   number := 0;
begin
  for y in (select t.ter_fecha f, t.ter_local l, t.ter_terminal te, t.ter_cierrey c
              from VTA_FACOTERMSTATY t, VTA_FACOPOC_DIAS d
             where d.d_origen = 'TEST' and t.ter_fecha = d.d_fecha and t.ter_local = d.d_local
               and t.ter_estado <= 0
             order by 1, 2, 3, 4) loop
    v_k := v_k + 1;
    v_d0 := PKG_F8_CIERRE_AUTO.fn_dif_real('FACO', y.f, y.l, y.te, y.c);
    select max(r.rec_mefectivo) into v_efe
      from VTA_FACOLIBVTA l, VTA_FACOZZZ r
     where l.vta_tiporeg = 'Y' and l.vta_estado = 'A' and l.vta_techkey = r.rec_techkey
       and l.vta_fecha_venta = y.f and l.vta_local = y.l and l.vta_terminal = y.te and l.vta_secuencia = y.c;

    -- Caja "limpia" para escenarios con resultado fijo: sin DI previa y sin reglas que bloqueen
    PKG_F8_CIERRE_AUTO.pr_valida_y('FACO', y.f, y.l, y.te, y.c, v_regla, v_msg);
    v_ok := v_d0 is not null and v_regla is null
            and PKG_F8_COMPENSA_DI_AUTO.fn_estado_di('FACO', y.f, y.l, y.te, y.c) = 'NINGUNA';

    v_esc := null; v_obj := null; v_monto := null; v_t1 := null; v_t2 := null;
    case mod(v_k, 5)
      when 2 then if v_ok and v_d0 < -800   then v_esc := 'E1'; v_obj := -800;   v_t1 := 'DI_REGISTRADA'; v_t2 := 'CERRADA_Y';      end if;
      when 3 then if v_ok and v_d0 < 0      then v_esc := 'E2'; v_obj := 0;      v_t1 := 'DR_CERO';       v_t2 := 'CERRADA_Y';      end if;
      when 4 then if v_ok and v_d0 < -30000 then v_esc := 'E3'; v_obj := -30000; v_t1 := 'FUERA_RANGO';   v_t2 := 'CON_DIFERENCIA'; end if;
      when 0 then v_esc := 'S0';             -- sin sobre: entra como SIN_SOBRE
      else null;
    end case;

    if v_esc is null then
      -- R0: deposito real = efectivo declarado (resultado: el que den sus datos)
      v_esc := case when nvl(v_efe, 0) > 0 then 'R0' else 'S0' end;
    end if;

    if v_esc in ('E1', 'E2', 'E3') then
      v_monto := v_obj - v_d0;           -- DR nueva = DR inicial + sobre
    elsif v_esc = 'R0' then
      v_monto := v_efe;
    end if;

    if v_monto is not null then
      insert into VTA_FACOPRD
        (prv_techkey, prv_fechadep, prv_local, prv_terminal, prv_tiporec, prv_prscli,
         prv_servicio, prv_sobre, prv_prsloc, prv_prscajero, prv_tiposobre, prv_ctacte,
         prv_nomcta, prv_totdocs, prv_tipodifdoc, prv_numdifdoc, prv_coddifdoc, prv_nomdifdoc,
         prv_montosobre, prv_tipodifmon, prv_montodif, prv_coddifmon, prv_nomdifmon,
         prv_serv2, prv_numrec, prv_fechavta, prv_modifpor, prv_cierrey, prv_cod_recaud)
      values
        (SEQ_VTA_FACOPRS.nextval, trunc(sysdate), y.l, y.te, 'F8', 1,
         'E', 99129010000 + v_k, 1, 7, 'EFE', '00',
         'INTERNO', 0, 'C', 0, '000', 'in',
         v_monto, 'C', 0, 0, '000',
         'in', 123, y.f, 'POC_FSCC12901', y.c, '00562');
      v_cnt := v_cnt + 1;
    end if;

    insert into VTA_FACOPOC_CASOS (c_origen, escenario, c_fecha, c_local, c_terminal, c_cierrey,
                                   dr_inicial, dr_objetivo, monto_sobre, esperado_t1, esperado_t2)
    values ('TEST', v_esc, y.f, y.l, y.te, y.c, v_d0, v_obj, v_monto, v_t1, v_t2);
  end loop;
  commit;
  dbms_output.put_line('TEST: ' || v_k || ' cajas abiertas, ' || v_cnt || ' sobres cargados');
end;
/

-- ---------------------------------------------------------------
-- Respaldo de los cierres Y del POC (lo usa 98_reiniciar.sql para repetir)
-- ---------------------------------------------------------------
create table VTA_FACOPOC_RESP_Y as
select y.ter_fecha, y.ter_local, y.ter_terminal, y.ter_cierrey, y.ter_estado, y.ter_cerradopor, y.ter_notas
  from VTA_FACOTERMSTATY y, VTA_FACOPOC_DIAS d
 where y.ter_fecha = d.d_fecha and y.ter_local = d.d_local;

-- ---------------------------------------------------------------
-- Controles
-- ---------------------------------------------------------------
-- 1. Cola creada por el trigger (esperado: una fila 'P' por sobre)
select (select count(*) from VTA_FACOPRD where prv_modifpor = 'POC_FSCC12901') sobres_poc,
       (select count(*) from VTA_FACOPRD_CIERRE where pcr_estado = 'P') cola_pendiente
  from dual;

-- 2. Universo que evaluara el proceso, por origen (v2: lo arma el paquete,
--    PKG_F8_CIERRE_AUTO.fn_universo; esta consulta lo aproxima).
--    COLA = cierres Y con sobres en la cola pendiente; SIN_SOBRE = cierres Y
--    abiertos del mismo local-dia sin sobres (el paquete exige ademas libro de ventas).
select 'COLA' cc_origen, d.d_origen,
       count(distinct to_char(q.prv_fechavta, 'yyyymmdd') || '-' || q.prv_local || '-' || q.prv_terminal || '-' || q.prv_cierrey) cajas
  from VTA_FACOPRD_CIERRE q, VTA_FACOPOC_DIAS d
 where q.pcr_estado = 'P' and q.prv_cierrey <> 0
   and q.prv_fechavta = d.d_fecha and q.prv_local = d.d_local
 group by d.d_origen
union all
select 'SIN_SOBRE', d.d_origen, count(*)
  from VTA_FACOTERMSTATY y, VTA_FACOPOC_DIAS d
 where y.ter_fecha = d.d_fecha and y.ter_local = d.d_local and y.ter_estado <= 0
   and not exists (select 1 from VTA_FACOPRD_CIERRE q
                    where q.pcr_estado = 'P' and q.prv_fechavta = y.ter_fecha and q.prv_local = y.ter_local
                      and q.prv_terminal = y.ter_terminal and q.prv_cierrey = y.ter_cierrey)
 group by d.d_origen
 order by 2, 1;

-- 3. DR despues de la carga vs objetivo (esperado: todas OK)
select c.c_origen, c.escenario, count(*) cajas,
       sum(case when PKG_F8_CIERRE_AUTO.fn_dif_real('FACO', c.c_fecha, c.c_local, c.c_terminal, c.c_cierrey)
                     = c.dr_objetivo then 1 else 0 end) dr_ok,
       sum(case when PKG_F8_CIERRE_AUTO.fn_dif_real('FACO', c.c_fecha, c.c_local, c.c_terminal, c.c_cierrey)
                     = c.dr_objetivo then 0 else 1 end) dr_revisar
  from VTA_FACOPOC_CASOS c
 where c.dr_objetivo is not null
 group by c.c_origen, c.escenario order by 1, 2;

-- 4. Escenarios de las cajas de TEST
select escenario, count(*) cajas from VTA_FACOPOC_CASOS where c_origen = 'TEST' group by escenario order by 1;
