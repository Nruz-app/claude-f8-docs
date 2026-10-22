-- =====================================================================
-- FSCC-12901 COMPENSA_DI - Sesion de prueba 2 en test - P9b: rehacer la prueba 2
-- MODIFICA DATOS: lo ejecuta el usuario, en TEST, revisando antes el
-- SELECT de control. xintec-nruz 20-10-2026
--
-- Caso: la prueba 2 (local 25, T12, 10-09-2026) dio SIN_TERMSTAT porque la
-- Y se ingreso en Form19Y con la F8 todavia en el local 5 de la prueba 1:
-- quedo en local 5 / T12 (techkey 82060, efectivo 860.000) y no en 25 / T12.
-- Este script deshace solo eso:
--   - la Y mal ingresada en local 5 / T12 (ZZZ, libro de ventas y estado);
--   - los 2 sobres de la prueba 2 en local 25 / T12 (si quedan, Form133
--     inserta 0 registros y no llama al paquete);
--   - el log SIN_TERMSTAT de local 25 / T12.
-- No toca la prueba 1 (local 5 / T27) ni la fila Z de 25 / T12.
-- Sin commit automatico: al final, commit o rollback a mano.
-- =====================================================================

-- Control previo. ESPERADO antes de borrar: TERMSTATY_5_12 1,
-- LIBVTA_Y_5_12 1, ZZZ_5_12 >= 0, PRD_25_12 2, LOG_25_12 1, MOVDET_5_12 0.
-- Repetir al final: todo 0.
select 'TERMSTATY_5_12' t, count(*) n from vta_FACOtermstaty
 where ter_fecha = to_date('20260910','yyyymmdd') and ter_local = 5 and ter_terminal = 12
union all
select 'LIBVTA_Y_5_12', count(*) from vta_FACOlibvta
 where vta_tiporeg = 'Y' and vta_fecha_venta = to_date('20260910','yyyymmdd')
   and vta_local = 5 and vta_terminal = 12
union all
select 'ZZZ_5_12', count(*) from vta_FACOzzz
 where rec_techkey in (select vta_techkey from vta_FACOlibvta
                        where vta_tiporeg = 'Y'
                          and vta_fecha_venta = to_date('20260910','yyyymmdd')
                          and vta_local = 5 and vta_terminal = 12)
union all
select 'MOVDET_5_12', count(*) from vta_FACOmovdet
 where mov_fecha = to_date('20260910','yyyymmdd') and mov_local = 5 and mov_terminal = 12
union all
select 'PRD_25_12', count(*) from vta_FACOprd
 where prv_fechavta = to_date('20260910','yyyymmdd') and prv_local = 25 and prv_terminal = 12
   and prv_sobre in (2512091001, 2512091002)
union all
select 'LOG_25_12', count(*) from VTA_FACOLOG_COMPENSA_DI
 where log_fecha_vta = to_date('20260910','yyyymmdd') and log_local = 25 and log_terminal = 12;

-- 1. ZZZ de la Y mal ingresada (antes que libvta, porque se ubica por su techkey)
delete from vta_FACOzzz
 where rec_techkey in (select vta_techkey from vta_FACOlibvta
                        where vta_tiporeg = 'Y'
                          and vta_fecha_venta = to_date('20260910','yyyymmdd')
                          and vta_local = 5 and vta_terminal = 12);

-- 2. Libro de ventas Y de local 5 / T12
delete from vta_FACOlibvta
 where vta_tiporeg = 'Y' and vta_fecha_venta = to_date('20260910','yyyymmdd')
   and vta_local = 5 and vta_terminal = 12;

-- 3. Estado de la Y de local 5 / T12
delete from vta_FACOtermstaty
 where ter_fecha = to_date('20260910','yyyymmdd') and ter_local = 5 and ter_terminal = 12;

-- 4. Sobres de la prueba 2 en local 25 / T12
delete from vta_FACOprd
 where prv_fechavta = to_date('20260910','yyyymmdd') and prv_local = 25 and prv_terminal = 12
   and prv_sobre in (2512091001, 2512091002);

-- 5. Log SIN_TERMSTAT de local 25 / T12
delete from VTA_FACOLOG_COMPENSA_DI
 where log_fecha_vta = to_date('20260910','yyyymmdd') and log_local = 25 and log_terminal = 12;

-- commit;
-- rollback;
