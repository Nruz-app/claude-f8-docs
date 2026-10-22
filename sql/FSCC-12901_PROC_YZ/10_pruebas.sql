-- =====================================================================
-- FSCC-12901 PROC_YZ (v2 multipais + cierre Z) - Paso 10
-- Pruebas (ejecutar bloque a bloque). Sin variables de sustitucion: cada
-- prueba trae al inicio sus valores marcados EDITAR (pais, fecha, local,
-- terminal, cierre Y). Funciona igual en SQL*Plus y en DBeaver.
-- Ejemplo: FACO, 28-08-2026, local 6, terminal 4, Y 1 = primera caja del dia
-- PRD 3 de la POC (poc/03_dia_prd3.sql). Cambiar por una caja real.
-- =====================================================================

-- 1. Compilacion (esperado: VALID y sin errores)
select object_name, object_type, status from all_objects
 where owner = sys_context('USERENV','CURRENT_SCHEMA')
   and object_name in ('PKG_F8_CIERRE_AUTO', 'PKG_F8_COMPENSA_DI_AUTO',
                       'TRG_VTA_FACOPRD_CIERRE_AI', 'VTA_FACOPRD_CIERRE', 'VTA_FACOLOG_CIERRE_AUTO')
 order by 1, 2;
select name, type, line, position, text from all_errors
 where owner = sys_context('USERENV','CURRENT_SCHEMA')
   and name in ('PKG_F8_CIERRE_AUTO', 'PKG_F8_COMPENSA_DI_AUTO')
 order by name, sequence;

-- 2. Configuracion del pais
--    2a. FACO habilitado (esperado: VTA_FACOTERMSTATY y los parametros 1502)
select PKG_F8_CIERRE_AUTO.fn_tabla('FACO', 'TERMSTATY') tabla,
       PKG_F8_CIERRE_AUTO.fn_param('FACO', 'CA_ACTIVO', '?')    ca_activo,
       PKG_F8_CIERRE_AUTO.fn_param('FACO', 'CA_DI_ACTIVO', '?') ca_di_activo,
       PKG_F8_CIERRE_AUTO.fn_param('FACO', 'CA_DI_MIN', '?')    ca_di_min,
       PKG_F8_CIERRE_AUTO.fn_param('FACO', 'CA_DI_MAX', '?')    ca_di_max,
       PKG_F8_CIERRE_AUTO.fn_param('FACO', 'CA_SIN_SOBRE', '?') ca_sin_sobre,
       PKG_F8_CIERRE_AUTO.fn_param('FACO', 'CA_CIERRA_Z', '?')   ca_cierra_z,
       PKG_F8_CIERRE_AUTO.fn_param('FACO', 'CA_Z_SIN_Y', '?')    ca_z_sin_y,
       PKG_F8_CIERRE_AUTO.fn_param('FACO', 'CA_Z_VAL_SUMA', '?') ca_z_val_suma,
       PKG_F8_CIERRE_AUTO.fn_param('FACO', 'CA_Z_VAL_DOL', '?')  ca_z_val_dol
  from dual;
--    2b. Pais no habilitado (esperado: ORA-20001 Pais no habilitado para cierre automatico: CHI)
select PKG_F8_CIERRE_AUTO.fn_tabla('CHI', 'TERMSTATY') from dual;

-- 3. Diferencia real del paquete vs "Diferencia Real" de la F8 (Form3Y).
--    Deben coincidir en al menos 10 cajas antes de activar el proceso.
--    Si v1 sigue instalado (MIGRAR_DESDE_V1), la columna igual_v1 debe ser S en todas.
with p as (select 'FACO' pais, to_date('28-08-2026','dd-mm-yyyy') f from dual)   -- EDITAR
select y.ter_fecha, y.ter_local, y.ter_terminal, y.ter_cierrey, y.ter_estado,
       PKG_F8_CIERRE_AUTO.fn_dif_caja  (p.pais, y.ter_fecha, y.ter_local, y.ter_terminal, y.ter_cierrey) dif_caja,
       PKG_F8_CIERRE_AUTO.fn_compensado(p.pais, y.ter_fecha, y.ter_local, y.ter_terminal, y.ter_cierrey) compensado,
       PKG_F8_CIERRE_AUTO.fn_dif_real  (p.pais, y.ter_fecha, y.ter_local, y.ter_terminal, y.ter_cierrey) dr_v2
  from VTA_FACOTERMSTATY y, p
 where y.ter_fecha = p.f
 order by 2, 3, 4;

-- 3b. (Solo si v1 esta instalado) paridad v1 / v2: esperado 0 filas
with p as (select 'FACO' pais, to_date('28-08-2026','dd-mm-yyyy') f from dual)   -- EDITAR
select * from (
  select y.ter_fecha, y.ter_local, y.ter_terminal, y.ter_cierrey,
         PKG_F8_FACO_CIERRE_AUTO.fn_dif_real(y.ter_fecha, y.ter_local, y.ter_terminal, y.ter_cierrey) dr_v1,
         PKG_F8_CIERRE_AUTO.fn_dif_real(p.pais, y.ter_fecha, y.ter_local, y.ter_terminal, y.ter_cierrey) dr_v2
    from VTA_FACOTERMSTATY y, p
   where y.ter_fecha = p.f)
 where nvl(dr_v1, -999999999) <> nvl(dr_v2, -999999999);

-- 4. Una caja: que haria T1 (sin grabar) y validaciones de T2
declare
  v_dr number; r varchar2(10); m varchar2(1000);
  -- EDITAR: pais y caja a probar
  v_pais     varchar2(10) := 'FACO';
  v_fecha    date   := to_date('28-08-2026','dd-mm-yyyy');
  v_local    number := 6;
  v_terminal number := 4;
  v_cierrey  number := 1;
begin
  dbms_output.put_line('T1 -> ' || PKG_F8_COMPENSA_DI_AUTO.fn_evalua_caja(
      v_pais, v_fecha, v_local, v_terminal, v_cierrey, v_dr) || ' DR=' || v_dr);
  dbms_output.put_line('DI existentes: ' || PKG_F8_COMPENSA_DI_AUTO.fn_estado_di(
      v_pais, v_fecha, v_local, v_terminal, v_cierrey));
  PKG_F8_CIERRE_AUTO.pr_valida_y(v_pais, v_fecha, v_local, v_terminal, v_cierrey, r, m);
  dbms_output.put_line('T2 Y -> ' || nvl(r, 'OK') || ' ' || m);
end;
/

-- 5. Validaciones sueltas de T2
with p as (select 'FACO' pais, to_date('28-08-2026','dd-mm-yyyy') f, 6 l, 4 t, 1 y from dual)   -- EDITAR
select PKG_F8_CIERRE_AUTO.fn_msg_cheque_fecha(p.pais, p.f, p.l, p.t) ry01_cheque,
       PKG_F8_CIERRE_AUTO.fn_zzz(p.pais, p.f, p.l, p.t, p.y)     ry06_zzz_y
  from p;

-- 6. Cola: estado de la carga (P pendiente, E en proceso, C procesada, O omitida)
select pcr_estado, pcr_resultado, count(*) from VTA_FACOPRD_CIERRE group by pcr_estado, pcr_resultado order by 1, 2;
-- Conciliacion: sobres F8/DOL del ultimo dia sin fila en la cola (esperado: 0 filas)
select p.prv_techkey, p.prv_fechavta, p.prv_local, p.prv_terminal, p.prv_cierrey
  from VTA_FACOPRD p
 where p.prv_tiporec in ('F8', 'DOL') and p.prv_fechadep >= trunc(sysdate) - 1
   and not exists (select 1 from VTA_FACOPRD_CIERRE q where q.prv_techkey = p.prv_techkey);

-- 7. Simulacion de T1 sobre la carga pendiente (cola P + sin sobre; no graba)
declare
  v_pais varchar2(10) := 'FACO';   -- EDITAR
  v_cur  sys_refcursor;
  v_f date; v_l number; v_t number; v_y number;
  v_dr number; v_res varchar2(30);
begin
  v_cur := PKG_F8_CIERRE_AUTO.fn_universo(v_pais, null);
  loop
    fetch v_cur into v_f, v_l, v_t, v_y;
    exit when v_cur%notfound;
    v_res := PKG_F8_COMPENSA_DI_AUTO.fn_evalua_caja(v_pais, v_f, v_l, v_t, v_y, v_dr);
    dbms_output.put_line(to_char(v_f,'dd-mm-yyyy') || ' ' || v_l || '/' || v_t || ' Y' || v_y ||
                         ' DR=' || nvl(to_char(v_dr), 'null') || ' -> ' || v_res);
  end loop;
  close v_cur;
end;
/

-- 8. Ejecucion completa (como el job): toma la carga, T1 y luego T2. GRABA.
begin
  PKG_F8_CIERRE_AUTO.prc_cierre_automatico(p_flg_pais => 'FACO');   -- EDITAR pais
end;
/

-- 9. Resumen de la ultima ejecucion
select l.log_proceso, l.log_nivel, l.log_fecha_vta, l.log_local, l.log_terminal, l.log_cierrey,
       l.log_dif_real, l.log_resultado, l.log_regla, l.log_mensaje
  from VTA_FACOLOG_CIERRE_AUTO l
 where l.log_ejecucion = (select max(log_ejecucion) from VTA_FACOLOG_CIERRE_AUTO)
 order by l.log_id;

select log_proceso, log_resultado, log_regla, count(*)
  from VTA_FACOLOG_CIERRE_AUTO
 where log_ejecucion = (select max(log_ejecucion) from VTA_FACOLOG_CIERRE_AUTO)
 group by log_proceso, log_resultado, log_regla order by 1, 2, 3;

-- 9b. Una ejecucion por carga: la cola de esa ejecucion quedo en C (esperado: sin E ni P de esa ejecucion)
select pcr_estado, count(*) from VTA_FACOPRD_CIERRE
 where pcr_ejecucion = (select max(log_ejecucion) from VTA_FACOLOG_CIERRE_AUTO)
 group by pcr_estado;

-- 9c. Segunda ejecucion sin carga nueva: no evalua nada
--     (esperado en su FIN: "Sobres de la carga: 0 | Cierres Y evaluados: 0")
begin
  PKG_F8_CIERRE_AUTO.prc_cierre_automatico(p_flg_pais => 'FACO');   -- EDITAR pais
end;
/
select log_resultado, log_mensaje from VTA_FACOLOG_CIERRE_AUTO
 where log_ejecucion = (select max(log_ejecucion) from VTA_FACOLOG_CIERRE_AUTO)
   and log_resultado in ('INICIO', 'FIN', 'INACTIVO');

-- 10. Resultado en las tablas del sistema
select m.mov_fecha, m.mov_local, m.mov_terminal, m.mov_cierrey, m.mov_monto, m.mov_hechopor, m.mov_fechareg
  from VTA_FACOMOVDET m where m.mov_tipomov = 'DI' and m.mov_hechopor = 'PROC_DI_AUTO'
 order by 1 desc, 2, 3, 4;
select ter_fecha, ter_local, ter_terminal, ter_cierrey, ter_estado, ter_cerradopor, ter_notas
  from VTA_FACOTERMSTATY where ter_cerradopor = 'PROC_CIERRE_AUTO' order by 1, 2, 3, 4;
-- La Z (VTA_FACOTERMSTAT): con CA_CIERRA_Z = N no debe cambiar (esperado: 0 filas).
-- Con CA_CIERRA_Z = S aparecen las Z cerradas por el proceso (ver prueba 13).
select ter_fecha, ter_local, ter_terminal, ter_estado, ter_cerradopor
  from VTA_FACOTERMSTAT where ter_cerradopor = 'PROC_CIERRE_AUTO';

-- 11. Cierre desde Consultas de Cuadratura (boton "Cerrar Terminal" de Form43), UN DIA.
-- ATENCION: GRABA (cierra las Y que cumplan). Revertir con 99_rollback.sql parte 2.
declare
  v_ejec number; v_cerr number; v_nocer number;
  -- EDITAR: pais, fecha de venta y local
  v_pais     varchar2(10) := 'FACO';
  v_fecha    date   := to_date('28-08-2026','dd-mm-yyyy');
  v_local    number := 6;
begin
  PKG_F8_CIERRE_AUTO.prc_cierre_dia(
    p_flg_pais  => v_pais,
    p_fecha     => to_char(v_fecha, 'yyyymmdd'),
    p_local     => v_local,
    p_terminal  => 0,
    p_usuario   => 'PRUEBA_CC',
    o_ejecucion => v_ejec, o_cerradas => v_cerr, o_no_cerradas => v_nocer);
  dbms_output.put_line('Ejecucion ' || v_ejec || ': cerradas ' || v_cerr || ', no cerradas ' || v_nocer);
end;
/

-- Matriz de casos propios de v2
-- V1 fn_tabla('CHI', ...)                      -> ORA-20001 pais no habilitado (nada se crea para Chile)
-- V2 dr_v1 = dr_v2 en todas las cajas          -> misma logica que v1 (prueba 3b)
-- V3 ejecucion con carga                       -> cola P -> E -> C, log INICIO/FIN con "Sobres de la carga: N"
-- V4 segunda ejecucion sin carga nueva          -> 0 sobres, 0 cajas evaluadas (una ejecucion por carga)
-- V5 nuevo sobre de una caja ya procesada       -> vuelve a la cola (P) y se evalua en la siguiente ejecucion
-- V6 caja bloqueada por un usuario (OCUPADA)   -> su fila vuelve a P para la siguiente ejecucion
-- V7 p_max_cajas = 5                           -> lo no evaluado vuelve a P (NO_EVALUADA)
-- V8 CA_ACTIVO = N y CA_DI_ACTIVO = S          -> solo T1; la cola queda en C con resultado SOLO_T1

-- =====================================================================
-- PROC_YZ: pruebas del cierre de la Z (Form3.CierraTerminal)
-- =====================================================================

-- 12. Diferencia real de la Z del paquete vs "Diferencia Real" de la F8 de la Z
--     (Form3, grilla de Y con cabecera del terminal). Deben coincidir antes de
--     activar CA_CIERRA_Z. Tambien muestra el estado de las Y del terminal.
with p as (select 'FACO' pais, to_date('28-08-2026','dd-mm-yyyy') f from dual)   -- EDITAR
select z.ter_fecha, z.ter_local, z.ter_terminal, z.ter_estado z_estado,
       (select count(*) from VTA_FACOTERMSTATY y
         where y.ter_fecha = z.ter_fecha and y.ter_local = z.ter_local and y.ter_terminal = z.ter_terminal) y_total,
       (select count(*) from VTA_FACOTERMSTATY y
         where y.ter_fecha = z.ter_fecha and y.ter_local = z.ter_local and y.ter_terminal = z.ter_terminal
           and nvl(y.ter_estado, 0) <> 1) y_no_cerradas,
       PKG_F8_CIERRE_AUTO.fn_dif_caja  (p.pais, z.ter_fecha, z.ter_local, z.ter_terminal, null) dif_caja_z,
       PKG_F8_CIERRE_AUTO.fn_compensado(p.pais, z.ter_fecha, z.ter_local, z.ter_terminal, null) compensado_z,
       PKG_F8_CIERRE_AUTO.fn_dif_real  (p.pais, z.ter_fecha, z.ter_local, z.ter_terminal, null) dr_z
  from VTA_FACOTERMSTAT z, p
 where z.ter_fecha = p.f
 order by 2, 3;

-- 13. Una Z: validaciones sueltas y conjunto (sin grabar)
declare
  r varchar2(10); m varchar2(1000);
  -- EDITAR: pais y terminal-dia a probar
  v_pais     varchar2(10) := 'FACO';
  v_fecha    date   := to_date('28-08-2026','dd-mm-yyyy');
  v_local    number := 6;
  v_terminal number := 4;
begin
  dbms_output.put_line('DR Z        = ' || nvl(to_char(PKG_F8_CIERRE_AUTO.fn_dif_real(v_pais, v_fecha, v_local, v_terminal, null)), 'null (sin libro F8)'));
  dbms_output.put_line('RZ-06 suma  = ' || nvl(PKG_F8_CIERRE_AUTO.fn_z_suma_y(v_pais, v_fecha, v_local, v_terminal), 'OK'));
  dbms_output.put_line('RZ-08 ZZZ Z = ' || PKG_F8_CIERRE_AUTO.fn_zzz(v_pais, v_fecha, v_local, v_terminal, null));
  dbms_output.put_line('RZ-09 USD   = ' || PKG_F8_CIERRE_AUTO.fn_dolares_z(v_pais, v_fecha, v_local, v_terminal));
  PKG_F8_CIERRE_AUTO.pr_valida_z(v_pais, v_fecha, v_local, v_terminal, r, m);
  dbms_output.put_line('pr_valida_z -> ' || nvl(r, 'OK') || ' ' || m);
end;
/

-- 14. Activar el cierre de la Z (solo cuando negocio lo confirme) y ejecutar.
--     GRABA. Para volver: mismo update con 'N'.
-- update VTA_FACOPARAM set vta_xglosa = 'S' where vta_ccodtipo = 1502 and vta_ccodigo = 'CA_CIERRA_Z';
-- commit;
-- begin PKG_F8_CIERRE_AUTO.prc_cierre_automatico(p_flg_pais => 'FACO'); end;
-- /

-- 15. Resultado de la Z en la ultima ejecucion (nivel Z del log) y en la tabla
select l.log_fecha_vta, l.log_local, l.log_terminal, l.log_dif_real, l.log_resultado, l.log_regla, l.log_mensaje
  from VTA_FACOLOG_CIERRE_AUTO l
 where l.log_ejecucion = (select max(log_ejecucion) from VTA_FACOLOG_CIERRE_AUTO)
   and l.log_nivel = 'Z'
 order by l.log_id;
select log_mensaje from VTA_FACOLOG_CIERRE_AUTO
 where log_ejecucion = (select max(log_ejecucion) from VTA_FACOLOG_CIERRE_AUTO) and log_resultado = 'FIN';
select ter_fecha, ter_local, ter_terminal, ter_estado, ter_cerradopor, ter_notas
  from VTA_FACOTERMSTAT where ter_cerradopor in ('PROC_CIERRE_AUTO', 'PRUEBA_CC') order by 1, 2, 3;

-- Matriz de casos de la Z (PROC_YZ). Todos con CA_CIERRA_Z = S salvo Z0.
-- Z0 CA_CIERRA_Z = N                              -> la Z no se toca; FIN sin texto "Z evaluadas" (igual que PROC_Y)
-- Z1 todas las Y cerradas, DR Z 0, Z = suma Y     -> CERRADA_Z (ter_estado 1, PROC_CIERRE_AUTO, nota 'CIERRE AUTOMATICO Z ...')
-- Z2 una Y queda abierta (CON_DIFERENCIA)         -> Z_Y_ABIERTAS (RZ-07)
-- Z3 terminal sin Y y CA_Z_SIN_Y = N              -> Z_SIN_Y (RZ-07)
-- Z4 sin libro de ventas 'F8'                     -> Z_SIN_LIBVTA (RZ-05)
-- Z5 DR de la Z <> 0 (p. ej. sobre sin Y, cierrey 0) -> Z_CON_DIFERENCIA (RZ-05)
-- Z6 concepto SN sin regularizar en otra Y        -> Z_BLOQUEADA RZ-03 (solo si esa Y se cerro igual)
-- Z7 libro 'F8' distinto de la suma de las Y      -> Z_BLOQUEADA RZ-06 con la glosa del campo
-- Z8 Z ya cerrada (1/2/3)                         -> Z_YA_CERRADA (no se cuenta como no cerrada)
-- Z9 Z bloqueada por otro usuario                 -> OCUPADA
-- Z10 carga de sobres posterior (Form133 reabre la Z a 0) -> la siguiente ejecucion la vuelve a cerrar
-- Z11 Form43 Cerrar Terminal (prc_cierre_dia)     -> cierra las Y y luego las Z del dia; resumen Z en el FIN
