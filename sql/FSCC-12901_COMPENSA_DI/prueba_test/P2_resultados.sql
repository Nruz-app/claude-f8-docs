-- =====================================================================
-- FSCC-12901 COMPENSA_DI - Sesion de prueba en test - P2: resultados
-- SOLO LECTURA. xintec-nruz 19-10-2026
-- Local 6, fecha de venta 31-08-2026, Y 1. Ejecutar despues de cada carga
-- (pruebas 1 a 4: T29, T40, T31, T24).
-- Si las tablas no se ven sin esquema:
--   alter session set current_schema = INTRANETTS;
-- =====================================================================

-- 1. Log del dia (una fila por caja evaluada). ESPERADO:
--    T29 DI_REGISTRADA  dif_real -800   monto_di -800   (prueba 1, DI negativa)
--    T40 DI_REGISTRADA  dif_real 15000  monto_di 15000  (prueba 2, DI positiva)
--    T31 FUERA_RANGO    dif_real -5000  sin DI          (prueba 3, no se crea la DI)
--    T24 DR_CERO        dif_real 0      sin DI          (prueba 4, caso normal)
select log_id, log_terminal, log_cierrey, log_sobres, log_dif_real, log_di_anterior,
       log_monto_di, log_resultado, log_mensaje, log_usuario, log_fechahora
  from VTA_FACOLOG_COMPENSA_DI
 where log_fecha_vta = to_date('20260831','yyyymmdd') and log_local = 6
 order by log_id;

-- 2. Estado de las Y. ESPERADO: las 4 abiertas (ter_estado <= 0, sin
--    PROC_CIERRE_AUTO). DR actual 0 en T29, T40 y T24; -5000 en T31.
select t.ter_terminal, t.ter_cierrey, t.ter_estado, t.ter_cerradopor,
       PKG_F8_COMPENSA_DI_CARGA.fn_dif_real('FACO', t.ter_fecha, t.ter_local, t.ter_terminal, t.ter_cierrey) dr_actual
  from VTA_FACOTERMSTATY t
 where t.ter_fecha = to_date('20260831','yyyymmdd') and t.ter_local = 6
   and t.ter_terminal in (29, 40, 31, 24)
 order by t.ter_terminal, t.ter_cierrey;

-- 3. DI registradas. ESPERADO: 2 filas (T29 -800; T40 15000), con
--    mov_hechopor PROC_DI_AUTO, mov_regul S y mov_fechareg = 31-08-2026.
select m.mov_terminal, m.mov_cierrey, m.mov_tipomov, m.mov_monto, m.mov_hechopor,
       m.mov_regul, m.mov_fechareg, m.mov_techkey
  from VTA_FACOMOVDET m
 where m.mov_fecha = to_date('20260831','yyyymmdd') and m.mov_local = 6
   and m.mov_terminal in (29, 40, 31, 24) and m.mov_tipomov = 'DI'
 order by m.mov_terminal;

-- 4. Observacion de la DI (lo que muestra Form4). ESPERADO: 2 filas
--    (T29, T40) con COMPENSACION AUTOMATICA DI.
select c.cpd_terminal, c.cpd_cierrey, c.cpd_tipmov, c.cpd_obs
  from VTA_FACOCOMPDES c
 where c.cpd_fecha = to_date('20260831','yyyymmdd') and c.cpd_local = 6
   and c.cpd_terminal in (29, 40, 31, 24) and c.cpd_tipmov = 'DI'
 order by c.cpd_terminal;

-- 5. Sobres cargados por caja. ESPERADO: 2 por caja (T29 2.670.000, T40 875.000,
--    T31 2.670.000, T24 2.342.000).
select prv_terminal, count(*) sobres, sum(prv_montosobre + nvl(prv_montodif, 0)) total
  from vta_FACOprd
 where prv_fechavta = to_date('20260831','yyyymmdd') and prv_local = 6
   and prv_terminal in (29, 40, 31, 24) and prv_tiporec = 'F8'
 group by prv_terminal
 order by prv_terminal;
