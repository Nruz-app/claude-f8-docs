-- =====================================================================
-- FSCC-12901 CIERRE_DIARIO - Sesion de prueba en test - P9: reabrir
-- MODIFICA DATOS, sin commit automatico. xintec-nruz 20-10-2026
-- Vuelve a Pendiente las cajas que cerro el proceso en la prueba, para
-- repetirla. Solo las del local 6 de esas dos fechas cerradas por
-- PROC_CIERRE_DIARIO. El log no se borra (queda como evidencia).
-- =====================================================================

-- Control (ESPERADO antes de reabrir: T24 y T40 del 31-08)
select t.ter_fecha, t.ter_terminal, t.ter_cierrey, t.ter_estado, t.ter_cerradopor
  from VTA_FACOTERMSTATY t
 where t.ter_fecha in (to_date('20260831','yyyymmdd'), to_date('20260828','yyyymmdd'))
   and t.ter_local = 6
   and t.ter_cerradopor = 'PROC_CIERRE_DIARIO'
   and t.ter_estado = 1;

update VTA_FACOTERMSTATY t
   set t.ter_estado = 0, t.ter_cerradopor = null
 where t.ter_fecha in (to_date('20260831','yyyymmdd'), to_date('20260828','yyyymmdd'))
   and t.ter_local = 6
   and t.ter_cerradopor = 'PROC_CIERRE_DIARIO'
   and t.ter_estado = 1;

-- commit;
-- rollback;
