-- =====================================================================
-- FSCC-12901 - Prueba manual "camino feliz" del cierre Y (FACO)
-- P9: deshacer la prueba para repetirla. MODIFICA DATOS: lo ejecuta el
-- usuario, en TEST, revisando antes el SELECT de control.
-- Valores: 20260828, local 6, terminal 27 (EDITAR). Borra TODAS las Y de
-- esa caja/dia: usar solo si la caja es exclusiva de la prueba.
-- La fila de la Z (vta_FACOtermstat) que reabre Form133 NO se borra.
-- Sin commit automatico: al final, commit o rollback a mano.
-- =====================================================================

-- Control previo (y repetir al final: todo 0)
select 'PRD' t, count(*) n from vta_FACOprd
 where prv_fechavta = to_date('20260828','yyyymmdd')
   and prv_sobre in (3404295622, 3476295623, 3482295624)
union all
select 'LIBVTA_Y', count(*) from vta_FACOlibvta
 where vta_tiporeg = 'Y' and vta_fecha_venta = to_date('20260828','yyyymmdd')
   and vta_local = 6 and vta_terminal = 27
union all
select 'TERMSTATY', count(*) from vta_FACOtermstaty
 where ter_fecha = to_date('20260828','yyyymmdd') and ter_local = 6 and ter_terminal = 27;

-- 1. Sobres de la prueba
delete from vta_FACOprd
 where prv_fechavta = to_date('20260828','yyyymmdd')
   and prv_local = 6 and prv_terminal = 27
   and prv_sobre in (3404295622, 3476295623, 3482295624);

-- 2. ZZZ de las Y (antes que libvta, porque se ubica por su techkey)
delete from vta_FACOzzz
 where rec_techkey in (select vta_techkey from vta_FACOlibvta
                        where vta_tiporeg = 'Y'
                          and vta_fecha_venta = to_date('20260828','yyyymmdd')
                          and vta_local = 6 and vta_terminal = 27);

-- 3. Libro de ventas Y
delete from vta_FACOlibvta
 where vta_tiporeg = 'Y' and vta_fecha_venta = to_date('20260828','yyyymmdd')
   and vta_local = 6 and vta_terminal = 27;

-- 4. Estado de las Y
delete from vta_FACOtermstaty
 where ter_fecha = to_date('20260828','yyyymmdd') and ter_local = 6 and ter_terminal = 27;

-- commit;
-- rollback;
