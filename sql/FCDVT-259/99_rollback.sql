-- =====================================================================
-- FCDVT-259 - Rollback, por partes (ejecutar solo la parte que corresponda)
-- xintec-nruz 16-11-2026
--
-- Las dos partes son independientes. Ninguna borra datos de cierres:
-- el package es de solo lectura.
-- En el exe, la vuelta atras es volver a los respaldos .bak_FCDVT-259 de
-- MDIForm1.frm y recaudacion.vbp y quitar Form176 (y sincronizar
-- docs/Cambios).
-- =====================================================================
set feedback on serveroutput on

-- ---------------------------------------------------------------------
-- PARTE A - Rollback de 01_menu_exporta_yz.sql
--      Quita el permiso 461 (submenu "Exportar Cierres Y y Z" de FACO).
--      El exe sigue funcionando: sin filas 461 la rama de MDIForm1 nunca
--      se ejecuta y el submenu queda oculto.
-- ---------------------------------------------------------------------
delete from VTA_FACORELPERMEN where mnu_codigo = 461;
delete from VTA_FACOMENU where mnu_codigo = 461;
commit;

select count(*) quedan_menu from VTA_FACOMENU where mnu_codigo = 461;
select count(*) quedan_rel from VTA_FACORELPERMEN where mnu_codigo = 461;

-- ---------------------------------------------------------------------
-- PARTE B - Quitar PKG_F8_EXPORTA_MASIVA_YZ (pasos 02 y 03)
--      Con el package borrado, Exportar de Form176 muestra el error de
--      Oracle. Form174 (Buscar / Cargar) no lo usa.
-- ---------------------------------------------------------------------
-- drop package PKG_F8_EXPORTA_MASIVA_YZ;
-- Si se ejecuto 04 (como DBA):
--   drop synonym UINTRANETTS.PKG_F8_EXPORTA_MASIVA_YZ;    -- EDITAR
-- select object_name, object_type, status from user_objects
--  where object_name = 'PKG_F8_EXPORTA_MASIVA_YZ';
