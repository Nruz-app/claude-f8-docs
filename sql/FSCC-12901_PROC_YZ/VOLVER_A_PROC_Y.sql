-- =====================================================================
-- FSCC-12901 PROC_YZ - Volver a PROC_Y (deshace ACTUALIZAR_DESDE_PROC_Y.sql)
-- Ejecutar desde ESTA carpeta (FSCC-12901_PROC_YZ), conectado como el duenio.
--
-- ANTES, si el proceso alcanzo a cerrar alguna Z y hay que reabrirla:
-- 99_rollback.sql parte 2 (por ejecucion) o, para todas, el bloque 0 de abajo.
-- =====================================================================
set echo on feedback on serveroutput on

-- 0. (Opcional, comentado) Reabrir TODAS las Z cerradas por el proceso
-- update VTA_FACOTERMSTAT z set z.ter_estado = 0, z.ter_cerradopor = null
--  where z.ter_estado = 1 and z.ter_cerradopor = 'PROC_CIERRE_AUTO';
-- commit;

-- 1. Parametros de la Z
delete from VTA_FACOPARAM
 where vta_ccodtipo = 1502
   and trim(vta_ccodigo) in ('CA_CIERRA_Z', 'CA_Z_SIN_Y', 'CA_Z_VAL_SUMA', 'CA_Z_VAL_DOL');
commit;

-- 2. PKG_F8_CIERRE_AUTO de PROC_Y (solo cierre Y)
@../FSCC-12901_PROC_Y/04_pkg_cierre_auto_spec.sql
@../FSCC-12901_PROC_Y/07_pkg_cierre_auto_body.sql

select object_name, object_type, status from user_objects
 where object_name in ('PKG_F8_CIERRE_AUTO', 'PKG_F8_COMPENSA_DI_AUTO')
 order by object_name, object_type;
