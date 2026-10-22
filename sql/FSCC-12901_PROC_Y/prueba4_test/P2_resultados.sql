-- =====================================================================
-- FSCC-12901 Prueba 4 en test (demostracion) - P2: resultados
-- SOLO LECTURA. xintec-nruz 19-10-2026
-- Local 6, fecha de venta 29-08-2026, Y 1, terminales 25, 42, 32 y 45.
-- Ejecutar despues de la carga en Form133 (que llama al paquete).
-- Si las tablas no se ven sin esquema:
--   alter session set current_schema = INTRANETTS;
-- =====================================================================

-- 1. Log de la ultima ejecucion. ESPERADO (por caja):
--    T25 T1 DR_CERO        / T2 CERRADA_Y
--    T42 T1 DI_REGISTRADA  / T2 CERRADA_Y      (DR +500 compensada)
--    T32 T1 FUERA_RANGO    / T2 CON_DIFERENCIA (DR -1.500)
--    T45 T1 FUERA_RANGO    / T2 CON_DIFERENCIA (DR +25.000)
--    Si se cargo un Excel por vez, hay una ejecucion por carga: usar la
--    consulta 1b.
select log_id, log_proceso, log_nivel, log_local, log_terminal, log_cierrey,
       log_dif_real, log_resultado, log_regla, log_mensaje
  from VTA_FACOLOG_CIERRE_AUTO
 where log_ejecucion = (select max(log_ejecucion) from VTA_FACOLOG_CIERRE_AUTO)
 order by log_id;

-- 1b. Log de las 4 cajas en todas las ejecuciones del dia de prueba.
select log_ejecucion, log_id, log_proceso, log_terminal, log_cierrey,
       log_dif_real, log_resultado, log_regla
  from VTA_FACOLOG_CIERRE_AUTO
 where log_fecha_vta = to_date('20260829','yyyymmdd') and log_local = 6
   and log_terminal in (25, 42, 32, 45)
 order by log_ejecucion, log_id;

-- 2. Estado de las Y. ESPERADO: T25 y T42 ter_estado 1 y ter_cerradopor
--    PROC_CIERRE_AUTO; T32 y T45 abiertas (ter_estado <= 0).
select ter_terminal, ter_cierrey, ter_estado, ter_cerradopor, ter_notas
  from VTA_FACOTERMSTATY
 where ter_fecha = to_date('20260829','yyyymmdd') and ter_local = 6
   and ter_terminal in (25, 42, 32, 45)
 order by ter_terminal, ter_cierrey;

-- 3. DI automatica. ESPERADO: 1 fila, T42, mov_monto 500,
--    mov_hechopor PROC_DI_AUTO, mov_regul S, mov_cierrey 1. Ninguna en T25, T32, T45.
select mov_terminal, mov_cierrey, mov_tipomov, mov_monto, mov_hechopor, mov_regul
  from VTA_FACOMOVDET
 where mov_fecha = to_date('20260829','yyyymmdd') and mov_local = 6
   and mov_terminal in (25, 42, 32, 45) and mov_tipomov = 'DI'
 order by mov_terminal;

-- 4. Cola de la carga. ESPERADO: 8 sobres en C, con el resultado de su caja.
select pcr_id, prv_terminal, prv_sobre, prv_montosobre, prv_cierrey,
       pcr_estado, pcr_ejecucion, pcr_resultado
  from VTA_FACOPRD_CIERRE
 where prv_fechavta = to_date('20260829','yyyymmdd') and prv_local = 6
 order by prv_terminal, pcr_id;
