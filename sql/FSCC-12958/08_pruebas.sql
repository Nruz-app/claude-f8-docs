-- =====================================================================
-- FSCC-12958 (HU-01-T2) Cierre de caja automatico - Falabella Colombia
-- 08 - Pruebas (ambiente de TEST). Ejecutar paso a paso.
-- Sin variables de sustitucion de SQL*Plus: cada prueba trae al inicio los valores
-- de la caja a probar, marcados EDITAR (fecha dd-mm-yyyy, local, terminal,
-- cierre Y). Asi funciona igual en SQL*Plus y en DBeaver (07-10-2026).
-- Ejemplo: 28-08-2026, local 6, terminal 4, Y 1 = primera caja del dia PRD 3 que
-- crea la POC en desarrollo (docs/sql/FSCC-12901_POC/). Cambiar por una caja real.
-- =====================================================================
set serveroutput on size 100000
set linesize 220 pagesize 200

-- ---------------------------------------------------------------
-- 0. Compilacion
-- ---------------------------------------------------------------
select object_name, object_type, status
  from all_objects
 where owner = sys_context('USERENV','CURRENT_SCHEMA')
   and object_name in ('PKG_F8_FACO_CIERRE_AUTO', 'TRG_VTA_FACOPRD_CIERRE_AI',
                       'VTA_FACOPRD_CIERRE', 'VTA_FACOLOG_CIERRE_AUTO', 'VTA_FACOV_CAJAS_CIERRE');
select line, position, text from all_errors
 where owner = sys_context('USERENV','CURRENT_SCHEMA') and name = 'PKG_F8_FACO_CIERRE_AUTO' order by sequence;

-- ---------------------------------------------------------------
-- 1. Diferencia real: comparar contra la F8 (Form3Y, campo "Diferencia Real")
--    para al menos 10 cajas. Deben coincidir.
-- ---------------------------------------------------------------
-- 2a. Una fecha con datos (recomendado; con la POC cargada, 28-08-2026). EDITAR la fecha.
with p as (select to_date('28-08-2026','dd-mm-yyyy') f from dual)
select y.ter_fecha, y.ter_local, y.ter_terminal, y.ter_cierrey, y.ter_estado,
       PKG_F8_FACO_CIERRE_AUTO.fn_dif_real(y.ter_fecha, y.ter_local, y.ter_terminal, y.ter_cierrey) dr_y
  from VTA_FACOTERMSTATY y, p
 where y.ter_fecha = p.f
 order by 2, 3, 4;

-- 2b. Ultimos 60 dias (solo si el ambiente tiene datos recientes; si no, no devuelve filas).
--     El rownum va despues del order by para tomar las 20 cajas mas recientes.
select * from (
  select y.ter_fecha, y.ter_local, y.ter_terminal, y.ter_cierrey, y.ter_estado,
         PKG_F8_FACO_CIERRE_AUTO.fn_dif_real(y.ter_fecha, y.ter_local, y.ter_terminal, y.ter_cierrey) dr_y
    from VTA_FACOTERMSTATY y
   where y.ter_fecha >= trunc(sysdate) - 60
   order by y.ter_fecha desc, 2, 3, 4)
 where rownum <= 20;

-- ---------------------------------------------------------------
-- 2. Validaciones sueltas de una caja
-- ---------------------------------------------------------------
declare
  r varchar2(10); m varchar2(1000);
  -- EDITAR: caja a probar (tomar una fila del resultado de la prueba de la DR)
  v_fecha    date   := to_date('28-08-2026','dd-mm-yyyy');
  v_local    number := 6;
  v_terminal number := 4;
  v_cierrey  number := 1;
begin
  PKG_F8_FACO_CIERRE_AUTO.pr_valida_y(v_fecha, v_local, v_terminal, v_cierrey, r, m);
  dbms_output.put_line('Y -> ' || nvl(r, 'OK') || ' ' || m);
end;
/

-- 2b. Cada validacion por separado (funciones publicas)
with p as (select to_date('28-08-2026','dd-mm-yyyy') f, 6 l, 4 t, 1 y from dual)   -- EDITAR: caja a probar
select PKG_F8_FACO_CIERRE_AUTO.fn_msg_cheque_fecha(p.f, p.l, p.t) ry01_cheque,
       PKG_F8_FACO_CIERRE_AUTO.fn_zzz(p.f, p.l, p.t, p.y)     ry06_zzz_y
  from p;

-- fn_concepto_pendiente devuelve BOOLEAN: se prueba desde PL/SQL
declare
  type t_tipos is table of varchar2(2);
  v t_tipos := t_tipos('SN','AF','ND','FN','NP','BF','CR','CT','CA','DP');
  -- EDITAR: caja a probar (tomar una fila del resultado de la prueba de la DR)
  v_fecha    date   := to_date('28-08-2026','dd-mm-yyyy');
  v_local    number := 6;
  v_terminal number := 4;
  v_cierrey  number := 1;
begin
  for i in 1 .. v.count loop
    dbms_output.put_line(v(i) || ' Y: ' ||
      case when PKG_F8_FACO_CIERRE_AUTO.fn_concepto_pendiente(v_fecha, v_local, v_terminal, v_cierrey, v(i))
           then 'PENDIENTE' else 'ok' end);
  end loop;
end;
/

-- ---------------------------------------------------------------
-- 3. Trigger: cargar un sobre con Form133 (o insertar en VTA_FACOPRD) y
--    verificar la fila en la cola
-- ---------------------------------------------------------------
select * from VTA_FACOPRD_CIERRE order by pcr_id desc;

-- Conciliacion: sobres F8/DOL sin fila en la cola (trigger fallo o era anterior)
select p.prv_techkey, p.prv_fechavta, p.prv_local, p.prv_terminal, p.prv_cierrey
  from VTA_FACOPRD p
 where p.prv_tiporec in ('F8', 'DOL')
   and p.prv_fechadep >= trunc(sysdate) - 1
   and not exists (select 1 from VTA_FACOPRD_CIERRE q where q.prv_techkey = p.prv_techkey);

-- ---------------------------------------------------------------
-- 4. Ejecucion del proceso
-- ---------------------------------------------------------------
begin
  PKG_F8_FACO_CIERRE_AUTO.prc_cierre_automatico('PROC_CIERRE_AUTO');
end;
/

-- Resumen de la ultima ejecucion
select l.log_nivel, l.log_fecha_vta, l.log_local, l.log_terminal, l.log_cierrey,
       l.log_dif_real, l.log_resultado, l.log_regla, l.log_mensaje
  from VTA_FACOLOG_CIERRE_AUTO l
 where l.log_ejecucion = (select max(log_ejecucion) from VTA_FACOLOG_CIERRE_AUTO)
 order by l.log_id;

select log_resultado, log_regla, count(*)
  from VTA_FACOLOG_CIERRE_AUTO
 where log_ejecucion = (select max(log_ejecucion) from VTA_FACOLOG_CIERRE_AUTO)
 group by log_resultado, log_regla order by 1, 2;

-- Cajas cerradas por el proceso
select ter_fecha, ter_local, ter_terminal, ter_cierrey, ter_estado, ter_cerradopor, ter_notas
  from VTA_FACOTERMSTATY where ter_cerradopor = 'PROC_CIERRE_AUTO' order by 1, 2, 3, 4;
-- La Z (VTA_FACOTERMSTAT) no debe cambiar: FACO solo cierre Y (esperado: 0 filas)
select ter_fecha, ter_local, ter_terminal, ter_estado, ter_cerradopor
  from VTA_FACOTERMSTAT  where ter_cerradopor = 'PROC_CIERRE_AUTO';

-- ---------------------------------------------------------------
-- 5. Matriz de casos (preparar datos en test y verificar resultado del log)
-- ---------------------------------------------------------------
-- T01 Y con DR 0 y sin pendientes                  -> CERRADA_Y; la Z no cambia
-- T02 Y con DR distinta de 0                       -> CON_DIFERENCIA RY-05, cola sigue 'P'
-- T03 Y con SN sin regularizar (repetir AF..DP)    -> BLOQUEADA RY-03 + mensaje del concepto
-- T04 Cheque a fecha gestion <> tesoreria          -> BLOQUEADA RY-01 (con CA_VAL_CHEQ = S)
-- T05 Y en estado 1, 2 o 3                         -> YA_CERRADA RY-02, cola 'C'
-- T06 Y sin libro de ventas                        -> SIN_LIBVTA
-- T07 Terminal con 3 Y, una con diferencia         -> 2 CERRADA_Y, 1 CON_DIFERENCIA; termstat sin cambios
-- T08 Y compensada por T1 (DI) en la misma corrida -> DI_REGISTRADA (T1) y CERRADA_Y (T2)   [CA9]
-- T09 (eliminado 07-10-2026: no hay nivel Z)
-- T10 CA_VAL_ZZZ = S y formula ZZZ descuadrada     -> BLOQUEADA RY-06
-- T11 (eliminado 07-10-2026: RZ-09 dolares, no hay nivel Z)
-- T12 Caja abierta en la F8 por un analista (bloqueo) mientras corre -> OCUPADA
-- T13 Ejecutar dos veces seguidas                  -> sin cambios en lo cerrado, sin errores
-- T14 CA_ACTIVO = N                                -> log INACTIVO, sin cambios
-- T15 Sobre sin cierre Y (prv_cierrey 0)           -> cola 'O' SIN_CIERREY
-- T16 Terminal Autopago (ter_tipo 2)               -> mismo resultado que el cierre AUTOMATICO actual
-- T17 Comparar 10 cajas: misma regla que mostraria Form3Y al cerrar manualmente

-- ---------------------------------------------------------------
-- 6. (FSCC-12901 DF-SCC) Vista VTA_FACOV_CAJAS_CIERRE: universo de T1 y T2
--    COLA = cierres Y con sobres pendientes; SIN_SOBRE = cierres Y abiertos
--    del mismo local-dia sin sobres (solo con CA_SIN_SOBRE = S)
-- ---------------------------------------------------------------
select cc_origen, count(*) from VTA_FACOV_CAJAS_CIERRE group by cc_origen;

select v.*, PKG_F8_FACO_CIERRE_AUTO.fn_dif_real(v.cc_fecha, v.cc_local, v.cc_terminal, v.cc_cierrey) dr
  from VTA_FACOV_CAJAS_CIERRE v
 where v.cc_origen = 'SIN_SOBRE' and rownum <= 20;

-- ---------------------------------------------------------------
-- 7. (FSCC-12901 DF-SCC) Columnas de Consultas de Cuadratura (Form43 FACO).
--    Comparar con la grilla del exe: Dif. de Caja / Compensacion / Dif. Real.
--    Debe cumplirse dif_real = round(dif_caja - round(compensado)).
-- ---------------------------------------------------------------
with p as (select to_date('28-08-2026','dd-mm-yyyy') f, 6 l, 4 t, 1 y from dual)   -- EDITAR: caja a probar
select y.ter_fecha, y.ter_local, y.ter_terminal, y.ter_cierrey,
       PKG_F8_FACO_CIERRE_AUTO.fn_dif_caja  (y.ter_fecha, y.ter_local, y.ter_terminal, y.ter_cierrey) dif_caja,
       PKG_F8_FACO_CIERRE_AUTO.fn_compensado(y.ter_fecha, y.ter_local, y.ter_terminal, y.ter_cierrey) compensado,
       PKG_F8_FACO_CIERRE_AUTO.fn_dif_real  (y.ter_fecha, y.ter_local, y.ter_terminal, y.ter_cierrey) dif_real
  from VTA_FACOTERMSTATY y, p
 where y.ter_fecha = p.f and y.ter_local = p.l
 order by 3, 4;

-- ---------------------------------------------------------------
-- 8. (FSCC-12901 DF-SCC) Cierre desde Consultas de Cuadratura: lo mismo que
--    hace el boton "Cerrar Terminal" de Form43 en FACO (terminal 0 = todos)
-- ---------------------------------------------------------------
-- ATENCION: esta prueba GRABA (cierra las Y que cumplan). Revertir con 99_rollback.sql paso 2a.
declare
  v_ejec number; v_cerr number; v_nocer number;
  -- EDITAR: fecha de venta y local
  v_fecha    date   := to_date('28-08-2026','dd-mm-yyyy');
  v_local    number := 6;
begin
  PKG_F8_FACO_CIERRE_AUTO.prc_cierre_rango(
    p_fecha_ini => to_char(v_fecha, 'yyyymmdd'),
    p_fecha_fin => to_char(v_fecha, 'yyyymmdd'),
    p_local     => v_local,
    p_terminal  => 0,
    p_usuario   => 'PRUEBA_CC',
    o_ejecucion => v_ejec, o_cerradas => v_cerr, o_no_cerradas => v_nocer);
  dbms_output.put_line('Ejecucion ' || v_ejec || ': cerradas ' || v_cerr || ', no cerradas ' || v_nocer);
end;
/

select l.log_proceso, l.log_nivel, l.log_terminal, l.log_cierrey, l.log_dif_real,
       l.log_resultado, l.log_regla, l.log_mensaje
  from VTA_FACOLOG_CIERRE_AUTO l
 where l.log_ejecucion = (select max(log_ejecucion) from VTA_FACOLOG_CIERRE_AUTO where log_proceso = 'CC')
 order by l.log_id;

-- Matriz de casos del ajuste DF-SCC
-- T18 Caja sin sobres, mismo local-dia de una carga, DR 0    -> vista SIN_SOBRE; CERRADA_Y
-- T19 Caja sin sobres con CA_SIN_SOBRE = N                    -> no aparece en la vista
-- T20 Caja sin sobres con DR en rango (ej. -500)              -> T1 DI_REGISTRADA; T2 CERRADA_Y
-- T21 prc_cierre_rango con DR 0                               -> CERRADA_Y, log_proceso CC,
--                                                                ter_cerradopor = usuario, nota "CIERRE CC FSCC-12901"
-- T22 prc_cierre_rango con DR <> 0                            -> CON_DIFERENCIA, no se cierra
-- T23 prc_cierre_rango con CA_ACTIVO = N                      -> igual cierra (accion manual)
-- T24 Form43 FACO: la grilla muestra tambien las filas con DR 0 y Cerrar Terminal informa el resumen
