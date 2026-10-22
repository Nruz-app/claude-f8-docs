-- =====================================================================
-- FSCC-12901 COMPENSA_DI - Sesion de prueba 4 en test - P9: limpiar
-- MODIFICA DATOS: lo ejecuta el usuario, en TEST, revisando antes el
-- SELECT de control. xintec-nruz 20-10-2026
-- Copia de ../prueba_test3/P9_limpiar.sql (misma prueba, fecha 20-08-2026).
-- Borra lo de la prueba del 20-08-2026 en las cajas (local, terminal)
-- (5, 27), (25, 12), (18, 10) y (19, 5): sobres de prueba, DI y
-- observaciones, Y (libro de ventas, ZZZ y estado) y el log. Usar solo si
-- esas cajas son exclusivas de la prueba (P0_prechecks consulta 3 sin
-- filas al empezar).
-- La fila de la Z (vta_FACOtermstat) que reabre Form133 NO se borra.
-- Sin commit automatico: al final, commit o rollback a mano.
-- =====================================================================

-- Control previo (y repetir al final: todo 0)
select 'PRD' t, count(*) n from vta_FACOprd
 where prv_fechavta = to_date('20260820','yyyymmdd')
   and (prv_local, prv_terminal) in ((5, 27), (25, 12), (18, 10), (19, 5))
union all
select 'MOVDET', count(*) from vta_FACOmovdet
 where mov_fecha = to_date('20260820','yyyymmdd')
   and (mov_local, mov_terminal) in ((5, 27), (25, 12), (18, 10), (19, 5))
union all
select 'COMPDES', count(*) from vta_FACOcompdes
 where cpd_fecha = to_date('20260820','yyyymmdd')
   and (cpd_local, cpd_terminal) in ((5, 27), (25, 12), (18, 10), (19, 5))
union all
select 'LIBVTA_Y', count(*) from vta_FACOlibvta
 where vta_tiporeg = 'Y' and vta_fecha_venta = to_date('20260820','yyyymmdd')
   and (vta_local, vta_terminal) in ((5, 27), (25, 12), (18, 10), (19, 5))
union all
select 'TERMSTATY', count(*) from vta_FACOtermstaty
 where ter_fecha = to_date('20260820','yyyymmdd')
   and (ter_local, ter_terminal) in ((5, 27), (25, 12), (18, 10), (19, 5))
union all
select 'LOG', count(*) from VTA_FACOLOG_COMPENSA_DI
 where log_fecha_vta = to_date('20260820','yyyymmdd')
   and (log_local, log_terminal) in ((5, 27), (25, 12), (18, 10), (19, 5));

-- 1. Sobres de la prueba
delete from vta_FACOprd
 where prv_fechavta = to_date('20260820','yyyymmdd')
   and (prv_local, prv_terminal) in ((5, 27), (25, 12), (18, 10), (19, 5))
   and prv_sobre in (527082001, 527082002, 2512082001, 2512082002,
                     1810082001, 1810082002, 1905082001, 1905082002);

-- 2. DI automaticas y su observacion
delete from vta_FACOmovdet
 where mov_fecha = to_date('20260820','yyyymmdd')
   and (mov_local, mov_terminal) in ((5, 27), (25, 12), (18, 10), (19, 5))
   and mov_tipomov = 'DI' and mov_hechopor = 'PROC_DI_AUTO';

delete from vta_FACOcompdes
 where cpd_fecha = to_date('20260820','yyyymmdd')
   and (cpd_local, cpd_terminal) in ((5, 27), (25, 12), (18, 10), (19, 5))
   and cpd_tipmov = 'DI' and cpd_obs in ('COMPENSACION AUTOMATICA DI', 'COMPENSACION AUTOMATICA DIFERENCIA DE DI');

-- 3. ZZZ de las Y (antes que libvta, porque se ubica por su techkey)
delete from vta_FACOzzz
 where rec_techkey in (select vta_techkey from vta_FACOlibvta
                        where vta_tiporeg = 'Y'
                          and vta_fecha_venta = to_date('20260820','yyyymmdd')
                          and (vta_local, vta_terminal) in ((5, 27), (25, 12), (18, 10), (19, 5)));

-- 4. Libro de ventas Y
delete from vta_FACOlibvta
 where vta_tiporeg = 'Y' and vta_fecha_venta = to_date('20260820','yyyymmdd')
   and (vta_local, vta_terminal) in ((5, 27), (25, 12), (18, 10), (19, 5));

-- 5. Estado de las Y
delete from vta_FACOtermstaty
 where ter_fecha = to_date('20260820','yyyymmdd')
   and (ter_local, ter_terminal) in ((5, 27), (25, 12), (18, 10), (19, 5));

-- 6. Log de la prueba
delete from VTA_FACOLOG_COMPENSA_DI
 where log_fecha_vta = to_date('20260820','yyyymmdd')
   and (log_local, log_terminal) in ((5, 27), (25, 12), (18, 10), (19, 5));

-- commit;
-- rollback;
