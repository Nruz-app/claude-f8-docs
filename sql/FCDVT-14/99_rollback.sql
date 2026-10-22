-- =====================================================================
-- FCDVT-14 - Rollback de 01_menu_ingreso_masivo_y.sql
--      Quita el permiso 460 (submenu "Ingreso de cierre de terminal Y
--      masivo" de FACO). El exe sigue funcionando: sin filas 460 la
--      rama de MDIForm1 nunca se ejecuta y el submenu queda oculto.
-- =====================================================================
set feedback on
delete from VTA_FACORELPERMEN where mnu_codigo = 460;
delete from VTA_FACOMENU where mnu_codigo = 460;
commit;

select count(*) quedan_menu from VTA_FACOMENU where mnu_codigo = 460;
select count(*) quedan_rel from VTA_FACORELPERMEN where mnu_codigo = 460;
