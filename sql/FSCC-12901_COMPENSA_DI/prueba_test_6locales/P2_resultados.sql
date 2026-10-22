-- =====================================================================
-- FSCC-12901 COMPENSA_DI - Prueba en test con 6 locales - P2: resultados
-- SOLO LECTURA. xintec-nruz 20-10-2026
-- Fecha de venta 30-08-2026, Y 1, locales 6, 18, 25, 35, 36 y 38.
-- Ejecutar despues de cada carga (pruebas 1 a 4: T29, T40, T31, T24).
-- Si las tablas no se ven sin esquema:
--   alter session set current_schema = INTRANETTS;
-- =====================================================================

-- 1. Log del dia (una fila por caja evaluada). ESPERADO por terminal:
--    T29 DI_REGISTRADA  dif_real = monto_di: -1 / -100 / -500 / -800 / -999 / -1000
--    T40 DI_REGISTRADA  dif_real = monto_di: 1 / 500 / 5000 / 15000 / 19999 / 20000
--    T31 FUERA_RANGO    dif_real: -1001 / -5000 / -50000 / 20001 / 25000 / 100000, sin DI
--    T24 DR_CERO        dif_real 0, sin DI
--    (orden de los locales: 6, 18, 25, 35, 36, 38)
select log_id, log_local, log_terminal, log_cierrey, log_sobres, log_dif_real, log_di_anterior,
       log_monto_di, log_resultado, log_mensaje, log_usuario, log_fechahora
  from VTA_FACOLOG_COMPENSA_DI
 where log_fecha_vta = to_date('20260830','yyyymmdd')
   and log_local in (6, 18, 25, 35, 36, 38)
 order by log_terminal, log_local, log_id;

-- 1b. Resumen del log. ESPERADO al final: T24 DR_CERO 6, T29 DI_REGISTRADA 6,
--     T31 FUERA_RANGO 6, T40 DI_REGISTRADA 6.
select log_terminal, log_resultado, count(*) cajas, sum(nvl(log_monto_di, 0)) suma_di
  from VTA_FACOLOG_COMPENSA_DI
 where log_fecha_vta = to_date('20260830','yyyymmdd')
   and log_local in (6, 18, 25, 35, 36, 38)
 group by log_terminal, log_resultado
 order by 1, 2;

-- 2. Estado de las Y. ESPERADO: las 24 abiertas (ter_estado <= 0, sin
--    PROC_CIERRE_AUTO). DR actual 0 en T29, T40 y T24; en T31 igual a la DR
--    del Excel (-1001 / -5000 / -50000 / 20001 / 25000 / 100000).
select t.ter_local, t.ter_terminal, t.ter_cierrey, t.ter_estado, t.ter_cerradopor,
       PKG_F8_COMPENSA_DI_CARGA.fn_dif_real('FACO', t.ter_fecha, t.ter_local, t.ter_terminal, t.ter_cierrey) dr_actual
  from VTA_FACOTERMSTATY t
 where t.ter_fecha = to_date('20260830','yyyymmdd')
   and t.ter_local in (6, 18, 25, 35, 36, 38)
   and t.ter_terminal in (29, 40, 31, 24)
 order by t.ter_terminal, t.ter_local, t.ter_cierrey;

-- 3. DI registradas. ESPERADO al final: 12 filas (6 en T29, 6 en T40) con el
--    mismo monto que la DR, mov_hechopor PROC_DI_AUTO, mov_regul S y
--    mov_fechareg = 30-08-2026. Ninguna en T31 ni T24.
select m.mov_local, m.mov_terminal, m.mov_cierrey, m.mov_tipomov, m.mov_monto, m.mov_hechopor,
       m.mov_regul, m.mov_fechareg, m.mov_techkey
  from VTA_FACOMOVDET m
 where m.mov_fecha = to_date('20260830','yyyymmdd')
   and m.mov_local in (6, 18, 25, 35, 36, 38)
   and m.mov_terminal in (29, 40, 31, 24) and m.mov_tipomov = 'DI'
 order by m.mov_terminal, m.mov_local;

-- 4. Observacion de la DI (lo que muestra Form4). ESPERADO: 12 filas
--    (T29 y T40) con COMPENSACION AUTOMATICA DI.
select c.cpd_local, c.cpd_terminal, c.cpd_cierrey, c.cpd_tipmov, c.cpd_obs
  from VTA_FACOCOMPDES c
 where c.cpd_fecha = to_date('20260830','yyyymmdd')
   and c.cpd_local in (6, 18, 25, 35, 36, 38)
   and c.cpd_terminal in (29, 40, 31, 24) and c.cpd_tipmov = 'DI'
 order by c.cpd_terminal, c.cpd_local;

-- 5. Sobres cargados por caja. ESPERADO: 2 por caja (24 cajas, 48 sobres);
--    el total de cada caja es la columna "Total sobres" de la hoja Resumen.
select prv_terminal, prv_local, count(*) sobres, sum(prv_montosobre + nvl(prv_montodif, 0)) total
  from vta_FACOprd
 where prv_fechavta = to_date('20260830','yyyymmdd')
   and prv_local in (6, 18, 25, 35, 36, 38)
   and prv_terminal in (29, 40, 31, 24) and prv_tiporec = 'F8'
 group by prv_terminal, prv_local
 order by prv_terminal, prv_local;
