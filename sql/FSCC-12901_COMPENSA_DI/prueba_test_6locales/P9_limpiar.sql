-- =====================================================================
-- FSCC-12901 COMPENSA_DI - Prueba en test con 6 locales - P9: limpiar
-- MODIFICA DATOS: lo ejecuta el usuario, en TEST, revisando antes el
-- SELECT de control. xintec-nruz 20-10-2026
-- Borra lo de la prueba del 30-08-2026 en los locales 6, 18, 25, 35, 36 y
-- 38, terminales 29, 40, 31 y 24: sobres de prueba, DI y observaciones, Y
-- (libro de ventas, ZZZ y estado) y el log del dia. Usar solo si esas cajas
-- son exclusivas de la prueba (P0_prechecks consulta 3 sin filas al empezar).
-- La fila de la Z (vta_FACOtermstat) que reabre Form133 NO se borra.
-- Sin commit automatico: al final, commit o rollback a mano.
-- Criterio copiado de ../prueba_test/P9_limpiar.sql.
-- =====================================================================

-- Control previo (y repetir al final: todo 0)
select 'PRD' t, count(*) n from vta_FACOprd
 where prv_fechavta = to_date('20260830','yyyymmdd')
   and prv_local in (6, 18, 25, 35, 36, 38) and prv_terminal in (29, 40, 31, 24)
union all
select 'MOVDET', count(*) from vta_FACOmovdet
 where mov_fecha = to_date('20260830','yyyymmdd')
   and mov_local in (6, 18, 25, 35, 36, 38) and mov_terminal in (29, 40, 31, 24)
union all
select 'COMPDES', count(*) from vta_FACOcompdes
 where cpd_fecha = to_date('20260830','yyyymmdd')
   and cpd_local in (6, 18, 25, 35, 36, 38) and cpd_terminal in (29, 40, 31, 24)
union all
select 'LIBVTA_Y', count(*) from vta_FACOlibvta
 where vta_tiporeg = 'Y' and vta_fecha_venta = to_date('20260830','yyyymmdd')
   and vta_local in (6, 18, 25, 35, 36, 38) and vta_terminal in (29, 40, 31, 24)
union all
select 'TERMSTATY', count(*) from vta_FACOtermstaty
 where ter_fecha = to_date('20260830','yyyymmdd')
   and ter_local in (6, 18, 25, 35, 36, 38) and ter_terminal in (29, 40, 31, 24)
union all
select 'LOG', count(*) from VTA_FACOLOG_COMPENSA_DI
 where log_fecha_vta = to_date('20260830','yyyymmdd')
   and log_local in (6, 18, 25, 35, 36, 38) and log_terminal in (29, 40, 31, 24);

-- 1. Sobres de la prueba (<terminal>0830<local><n>)
delete from vta_FACOprd
 where prv_fechavta = to_date('20260830','yyyymmdd')
   and prv_local in (6, 18, 25, 35, 36, 38) and prv_terminal in (29, 40, 31, 24)
   and length(to_char(prv_sobre)) = 10
   and substr(to_char(prv_sobre), 1, 6) in ('290830', '400830', '310830', '240830');

-- 2. DI automaticas y su observacion
delete from vta_FACOmovdet
 where mov_fecha = to_date('20260830','yyyymmdd')
   and mov_local in (6, 18, 25, 35, 36, 38) and mov_terminal in (29, 40, 31, 24)
   and mov_tipomov = 'DI' and mov_hechopor = 'PROC_DI_AUTO';

delete from vta_FACOcompdes
 where cpd_fecha = to_date('20260830','yyyymmdd')
   and cpd_local in (6, 18, 25, 35, 36, 38) and cpd_terminal in (29, 40, 31, 24)
   and cpd_tipmov = 'DI' and cpd_obs in ('COMPENSACION AUTOMATICA DI', 'COMPENSACION AUTOMATICA DIFERENCIA DE DI');

-- 3. ZZZ de las Y (antes que libvta, porque se ubica por su techkey)
delete from vta_FACOzzz
 where rec_techkey in (select vta_techkey from vta_FACOlibvta
                        where vta_tiporeg = 'Y'
                          and vta_fecha_venta = to_date('20260830','yyyymmdd')
                          and vta_local in (6, 18, 25, 35, 36, 38)
                          and vta_terminal in (29, 40, 31, 24));

-- 4. Libro de ventas Y
delete from vta_FACOlibvta
 where vta_tiporeg = 'Y' and vta_fecha_venta = to_date('20260830','yyyymmdd')
   and vta_local in (6, 18, 25, 35, 36, 38) and vta_terminal in (29, 40, 31, 24);

-- 5. Estado de las Y
delete from vta_FACOtermstaty
 where ter_fecha = to_date('20260830','yyyymmdd')
   and ter_local in (6, 18, 25, 35, 36, 38) and ter_terminal in (29, 40, 31, 24);

-- 6. Log de la prueba
delete from VTA_FACOLOG_COMPENSA_DI
 where log_fecha_vta = to_date('20260830','yyyymmdd')
   and log_local in (6, 18, 25, 35, 36, 38) and log_terminal in (29, 40, 31, 24);

-- commit;
-- rollback;
