-- =====================================================================
-- FCDVT-14 - Rollback, por partes (ejecutar solo la parte que corresponda)
-- =====================================================================
set feedback on

-- ---------------------------------------------------------------------
-- PARTE A - Rollback de 01_menu_ingreso_masivo_y.sql
--      Quita el permiso 460 (submenu "Ingreso de cierre de terminal Y
--      masivo" de FACO). El exe sigue funcionando: sin filas 460 la
--      rama de MDIForm1 nunca se ejecuta y el submenu queda oculto.
-- ---------------------------------------------------------------------
delete from VTA_FACORELPERMEN where mnu_codigo = 460;
delete from VTA_FACOMENU where mnu_codigo = 460;
commit;

select count(*) quedan_menu from VTA_FACOMENU where mnu_codigo = 460;
select count(*) quedan_rel from VTA_FACORELPERMEN where mnu_codigo = 460;

-- ---------------------------------------------------------------------
-- PARTE B - Desinstala la carga masiva Y/Z (pasos 02 a 05, 30-10-2026)
--      Borra el package, las tablas (con sus cargas y log) y las
--      secuencias. Un exe con el Buscar nuevo de Form174 da error al
--      buscar un archivo hasta que se vuelva a instalar.
--      Si se ejecuto 05, borrar tambien los sinonimos (como DBA):
--        drop synonym UINTRANETTS.PKG_F8_CARGA_MASIVA_YZ;   -- EDITAR
--        drop synonym UINTRANETTS.VTA_FACOCARGA_YZ_RES;     -- EDITAR
--        drop synonym UINTRANETTS.VTA_FACOCARGA_YZ_DET;     -- EDITAR
--        drop synonym UINTRANETTS.VTA_FACOCARGA_YZ_LOG;     -- EDITAR
-- ---------------------------------------------------------------------
drop package PKG_F8_CARGA_MASIVA_YZ;
drop table VTA_FACOCARGA_YZ_RES purge;
drop table VTA_FACOCARGA_YZ_DET purge;
drop table VTA_FACOCARGA_YZ_LOG purge;
drop sequence SEQ_VTA_FACOCARGA_YZ;
drop sequence SEQ_VTA_FACOCARGA_YZ_LOG;

select object_name, object_type from user_objects
 where object_name like 'VTA_FACOCARGA_YZ%'
    or object_name like 'SEQ_VTA_FACOCARGA_YZ%'
    or object_name = 'PKG_F8_CARGA_MASIVA_YZ';
