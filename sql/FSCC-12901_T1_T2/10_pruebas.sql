-- =====================================================================
-- FSCC-12901 T1 + T2 (carpeta consolidada) - Paso 10
-- Pruebas en TEST (ejecutar bloque a bloque).
-- Sin variables de sustitucion de SQL*Plus: cada prueba trae al inicio los valores
-- de la caja a probar, marcados EDITAR (fecha dd-mm-yyyy, local, terminal,
-- cierre Y). Asi funciona igual en SQL*Plus y en DBeaver (07-10-2026).
-- Ejemplo: 28-08-2026, local 6, terminal 4, Y 1 = primera caja del dia PRD 3 que
-- crea la POC en desarrollo (docs/sql/FSCC-12901_POC/). Cambiar por una caja real.
-- Fuentes: FSCC-12958/08_pruebas.sql + FSCC-12957/06_pruebas.sql
-- =====================================================================
set serveroutput on size 100000
set linesize 220 pagesize 200

-- 1. Compilacion (esperado: todo VALID y sin errores)
select object_name, object_type, status from all_objects
 where owner = sys_context('USERENV','CURRENT_SCHEMA')
   and object_name in ('PKG_F8_FACO_CIERRE_AUTO', 'PKG_F8_FACO_COMPENSA_DI',
                       'TRG_VTA_FACOPRD_CIERRE_AI', 'VTA_FACOPRD_CIERRE', 'VTA_FACOLOG_CIERRE_AUTO',
                       'VTA_FACOV_CAJAS_CIERRE')
 order by 1, 2;
select name, type, line, position, text from all_errors
 where owner = sys_context('USERENV','CURRENT_SCHEMA')
   and name in ('PKG_F8_FACO_CIERRE_AUTO', 'PKG_F8_FACO_COMPENSA_DI', 'TRG_VTA_FACOPRD_CIERRE_AI')
 order by name, sequence;

-- 2. Diferencia real del paquete vs "Diferencia Real" de la F8 (Form3Y, cierre Y).
--    Deben coincidir en al menos 10 cajas antes de activar el proceso.
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

-- 3. Una caja: que haria T1 (sin grabar) y validaciones de T2
declare
  v_dr number; r varchar2(10); m varchar2(1000);
  -- EDITAR: caja a probar (tomar una fila del resultado de la prueba de la DR)
  v_fecha    date   := to_date('28-08-2026','dd-mm-yyyy');
  v_local    number := 6;
  v_terminal number := 4;
  v_cierrey  number := 1;
begin
  dbms_output.put_line('T1 -> ' || PKG_F8_FACO_COMPENSA_DI.fn_evalua_caja(
      v_fecha, v_local, v_terminal, v_cierrey, v_dr) || ' DR=' || v_dr);
  dbms_output.put_line('DI existentes: ' || PKG_F8_FACO_COMPENSA_DI.fn_estado_di(
      v_fecha, v_local, v_terminal, v_cierrey));
  PKG_F8_FACO_CIERRE_AUTO.pr_valida_y(v_fecha, v_local, v_terminal, v_cierrey, r, m);
  dbms_output.put_line('T2 Y -> ' || nvl(r, 'OK') || ' ' || m);
end;
/

-- 4. Validaciones sueltas de T2
with p as (select to_date('28-08-2026','dd-mm-yyyy') f, 6 l, 4 t, 1 y from dual)   -- EDITAR: caja a probar
select PKG_F8_FACO_CIERRE_AUTO.fn_msg_cheque_fecha(p.f, p.l, p.t) ry01_cheque,
       PKG_F8_FACO_CIERRE_AUTO.fn_zzz(p.f, p.l, p.t, p.y)     ry06_zzz_y
  from p;

-- 5. Trigger: cargar sobres con Form133 y verificar la cola
select * from VTA_FACOPRD_CIERRE order by pcr_id desc;
-- Conciliacion: sobres F8/DOL de los ultimos dias sin fila en la cola
select p.prv_techkey, p.prv_fechavta, p.prv_local, p.prv_terminal, p.prv_cierrey
  from VTA_FACOPRD p
 where p.prv_tiporec in ('F8', 'DOL') and p.prv_fechadep >= trunc(sysdate) - 1
   and not exists (select 1 from VTA_FACOPRD_CIERRE q where q.prv_techkey = p.prv_techkey);

-- 6. Simulacion de T1 sobre el universo de cajas (vista; no graba)
declare
  v_dr number; v_res varchar2(30);
begin
  for c in (select cc_fecha f, cc_local l, cc_terminal t, cc_cierrey y
              from VTA_FACOV_CAJAS_CIERRE order by 1, 2, 3, 4) loop
    v_res := PKG_F8_FACO_COMPENSA_DI.fn_evalua_caja(c.f, c.l, c.t, c.y, v_dr);
    dbms_output.put_line(to_char(c.f,'dd-mm-yyyy') || ' ' || c.l || '/' || c.t || ' Y' || c.y ||
                         ' DR=' || nvl(to_char(v_dr), 'null') || ' -> ' || v_res);
  end loop;
end;
/

-- 7. Ejecucion completa (como el job): T1 y luego T2
begin
  PKG_F8_FACO_CIERRE_AUTO.prc_cierre_automatico;
end;
/

-- 8. Resumen de la ultima ejecucion
select l.log_proceso, l.log_nivel, l.log_fecha_vta, l.log_local, l.log_terminal, l.log_cierrey,
       l.log_dif_real, l.log_resultado, l.log_regla, l.log_mensaje
  from VTA_FACOLOG_CIERRE_AUTO l
 where l.log_ejecucion = (select max(log_ejecucion) from VTA_FACOLOG_CIERRE_AUTO)
 order by l.log_id;

select log_proceso, log_resultado, log_regla, count(*)
  from VTA_FACOLOG_CIERRE_AUTO
 where log_ejecucion = (select max(log_ejecucion) from VTA_FACOLOG_CIERRE_AUTO)
 group by log_proceso, log_resultado, log_regla order by 1, 2, 3;

-- 9. Resultado en las tablas del sistema
select m.mov_fecha, m.mov_local, m.mov_terminal, m.mov_cierrey, m.mov_monto, m.mov_hechopor, m.mov_fechareg
  from VTA_FACOMOVDET m where m.mov_tipomov = 'DI' and m.mov_hechopor = 'PROC_DI_AUTO'
 order by 1 desc, 2, 3, 4;
select ter_fecha, ter_local, ter_terminal, ter_cierrey, ter_estado, ter_cerradopor, ter_notas
  from VTA_FACOTERMSTATY where ter_cerradopor = 'PROC_CIERRE_AUTO' order by 1, 2, 3, 4;
-- La Z (VTA_FACOTERMSTAT) no debe cambiar: FACO solo cierre Y (esperado: 0 filas)
select ter_fecha, ter_local, ter_terminal, ter_estado, ter_cerradopor
  from VTA_FACOTERMSTAT  where ter_cerradopor = 'PROC_CIERRE_AUTO';

-- 10. Matriz de casos del flujo completo (ver README.md, seccion 8)

-- ---------------------------------------------------------------
-- 11. (FSCC-12901 DF-SCC) Vista VTA_FACOV_CAJAS_CIERRE: universo de T1 y T2
--    COLA = cierres Y con sobres pendientes; SIN_SOBRE = cierres Y abiertos
--    del mismo local-dia sin sobres (solo con CA_SIN_SOBRE = S)
-- ---------------------------------------------------------------
select cc_origen, count(*) from VTA_FACOV_CAJAS_CIERRE group by cc_origen;

select v.*, PKG_F8_FACO_CIERRE_AUTO.fn_dif_real(v.cc_fecha, v.cc_local, v.cc_terminal, v.cc_cierrey) dr
  from VTA_FACOV_CAJAS_CIERRE v
 where v.cc_origen = 'SIN_SOBRE' and rownum <= 20;

-- ---------------------------------------------------------------
-- 12. (FSCC-12901 DF-SCC) Columnas de Consultas de Cuadratura (Form43 FACO).
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
-- 13. (FSCC-12901 DF-SCC) Cierre desde Consultas de Cuadratura: lo mismo que
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
-- T25 (CA9, HU 07-10) Y con DR -22: T1 registra DI -22 -> DR 0 -> T2 cierra la Y en la misma ejecucion
-- T26 (solo Y, 07-10) Ninguna ejecucion modifica VTA_FACOTERMSTAT (ter_cerradopor de proceso = 0 filas)
