-- =====================================================================
-- FSCC-12901 CIERRE_DIARIO - Sesion de prueba en test - P2: resultados
-- SOLO LECTURA. xintec-nruz 20-10-2026
-- =====================================================================

-- 1. Log de las ejecuciones de hoy (INICIO, una fila por caja, FIN). ESPERADO:
--    31-08: T24 CERRADA, T31 CON_DIFERENCIA (RY-05, dr_f8 -5000), T40 CERRADA;
--           FIN "Cajas evaluadas: 3 | cerradas: 2 | con diferencia: 1 ..."
--    28-08: T31 CON_DIFERENCIA (-1500), T44 CON_DIFERENCIA (25000)
--    31-08 repeticion: solo T31
select l.log_ejecucion, l.log_id, l.log_fecha_vta, l.log_local, l.log_terminal, l.log_cierrey,
       l.log_dr_f8, l.log_dr_cc, l.log_resultado, l.log_regla, l.log_mensaje,
       l.log_usuario, l.log_fechahora
  from VTA_FACOLOG_CIERRE_DIARIO l
 where l.log_fechahora >= trunc(sysdate)
 order by l.log_ejecucion, l.log_id;

-- 2. Estado de las Y. ESPERADO: 31-08 T24 y T40 con ter_estado 1 y
--    ter_cerradopor PROC_CIERRE_DIARIO; T31 sigue Pendiente; T29 sin cambios.
--    28-08 sin cambios.
select t.ter_fecha, t.ter_terminal, t.ter_cierrey, t.ter_estado, t.ter_cerradopor
  from VTA_FACOTERMSTATY t
 where t.ter_fecha in (to_date('20260831','yyyymmdd'), to_date('20260828','yyyymmdd'))
   and t.ter_local = 6
 order by 1 desc, 2, 3;

-- 3. En pantalla: Consultas de Cuadratura, local 6, del 28-08-2026 al
--    31-08-2026, Consulta. T24 y T40 del 31-08 deben verse "Cerrado".
