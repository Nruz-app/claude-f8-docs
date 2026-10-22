-- =====================================================================
-- FSCC-12957 (HU-01-T1) Compensacion automatica de DI - Falabella Colombia
-- 02 - Parametros de T1 en VTA_FACOPARAM (tipo 1502, mismo tipo que T2)
-- Rango propio del proceso automatico: NO se toca el rango de la DI
-- manual (1500/1501 'DI', hoy -500 / 20000 en test), que usa Form38.
-- Valores modificables con UPDATE sin recompilar (se leen en cada ejecucion).
-- =====================================================================

-- Verificar que no existan (esperado: 0)
select count(*) from VTA_FACOPARAM
 where vta_ccodtipo = 1502 and vta_ccodigo in ('CA_DI_ACTIVO', 'CA_DI_MIN', 'CA_DI_MAX');

insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_DI_ACTIVO', 'S',     sysdate);  -- S/N T1 activa ("T1 activa" del diagrama general)
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_DI_MIN',    '-1000', sysdate);  -- limite inferior de la diferencia real (inclusive)
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_DI_MAX',    '20000', sysdate);  -- limite superior de la diferencia real (inclusive)
commit;

-- Los parametros comunes de FSCC-12958 tambien aplican a T1:
--   CA_DECIMAL (redondeo de la diferencia real) y CA_DIAS (antiguedad maxima).
