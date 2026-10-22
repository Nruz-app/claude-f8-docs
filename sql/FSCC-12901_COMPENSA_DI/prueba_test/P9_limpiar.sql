-- =====================================================================
-- FSCC-12901 COMPENSA_DI - Sesion de prueba en test - P9: limpiar
-- MODIFICA DATOS: lo ejecuta el usuario, en TEST, revisando antes el
-- SELECT de control. xintec-nruz 19-10-2026
-- Borra lo de la prueba en el local 6, 31-08-2026, terminales 29, 40, 31
-- y 24: sobres de prueba, DI y observaciones, Y (libro de
-- ventas, ZZZ y estado) y el log del dia. Usar solo si esas cajas son
-- exclusivas de la prueba (P0_prechecks consulta 3 sin filas al empezar).
-- La fila de la Z (vta_FACOtermstat) que reabre Form133 NO se borra.
-- Sin commit automatico: al final, commit o rollback a mano.
-- Criterio copiado de FSCC-12901_PROC_Y/prueba_manual_Y/P9_limpiar.sql.
-- =====================================================================

-- Control previo (y repetir al final: todo 0)
select 'PRD' t, count(*) n from vta_FACOprd
 where prv_fechavta = to_date('20260831','yyyymmdd') and prv_local = 6
   and prv_terminal in (29, 40, 31, 24)
union all
select 'MOVDET', count(*) from vta_FACOmovdet
 where mov_fecha = to_date('20260831','yyyymmdd') and mov_local = 6
   and mov_terminal in (29, 40, 31, 24)
union all
select 'COMPDES', count(*) from vta_FACOcompdes
 where cpd_fecha = to_date('20260831','yyyymmdd') and cpd_local = 6
   and cpd_terminal in (29, 40, 31, 24)
union all
select 'LIBVTA_Y', count(*) from vta_FACOlibvta
 where vta_tiporeg = 'Y' and vta_fecha_venta = to_date('20260831','yyyymmdd')
   and vta_local = 6 and vta_terminal in (29, 40, 31, 24)
union all
select 'TERMSTATY', count(*) from vta_FACOtermstaty
 where ter_fecha = to_date('20260831','yyyymmdd') and ter_local = 6
   and ter_terminal in (29, 40, 31, 24)
union all
select 'LOG', count(*) from VTA_FACOLOG_COMPENSA_DI
 where log_fecha_vta = to_date('20260831','yyyymmdd') and log_local = 6
   and log_terminal in (29, 40, 31, 24);

-- 1. Sobres de la prueba
delete from vta_FACOprd
 where prv_fechavta = to_date('20260831','yyyymmdd') and prv_local = 6
   and prv_terminal in (29, 40, 31, 24)
   and prv_sobre in (2908310001, 2908310002, 4008310001, 4008310002,
                     3108310001, 3108310002, 2408310001, 2408310002);

-- 2. DI automaticas y su observacion
delete from vta_FACOmovdet
 where mov_fecha = to_date('20260831','yyyymmdd') and mov_local = 6
   and mov_terminal in (29, 40, 31, 24)
   and mov_tipomov = 'DI' and mov_hechopor = 'PROC_DI_AUTO';

delete from vta_FACOcompdes
 where cpd_fecha = to_date('20260831','yyyymmdd') and cpd_local = 6
   and cpd_terminal in (29, 40, 31, 24)
   and cpd_tipmov = 'DI' and cpd_obs in ('COMPENSACION AUTOMATICA DI', 'COMPENSACION AUTOMATICA DIFERENCIA DE DI');

-- 3. ZZZ de las Y (antes que libvta, porque se ubica por su techkey)
delete from vta_FACOzzz
 where rec_techkey in (select vta_techkey from vta_FACOlibvta
                        where vta_tiporeg = 'Y'
                          and vta_fecha_venta = to_date('20260831','yyyymmdd')
                          and vta_local = 6 and vta_terminal in (29, 40, 31, 24));

-- 4. Libro de ventas Y
delete from vta_FACOlibvta
 where vta_tiporeg = 'Y' and vta_fecha_venta = to_date('20260831','yyyymmdd')
   and vta_local = 6 and vta_terminal in (29, 40, 31, 24);

-- 5. Estado de las Y
delete from vta_FACOtermstaty
 where ter_fecha = to_date('20260831','yyyymmdd') and ter_local = 6
   and ter_terminal in (29, 40, 31, 24);

-- 6. Log de la prueba
delete from VTA_FACOLOG_COMPENSA_DI
 where log_fecha_vta = to_date('20260831','yyyymmdd') and log_local = 6
   and log_terminal in (29, 40, 31, 24);

-- commit;
-- rollback;
