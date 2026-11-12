-- =====================================================================
-- FCDVT-10 (HU-03) - Rollback, por partes (ejecutar solo la que corresponda)
-- Tottus Chile (SFCL)
-- xintec-nruz 11-11-2026
-- No toca nada de FACO (FCDVT-14). Para deshacer lo que grabo Cargar en
-- un terminal-dia de prueba: 98_limpia_prueba.sql.
-- =====================================================================
set feedback on serveroutput on

-- ---------------------------------------------------------------------
-- PARTE A - Quita el permiso 460 de SFCL (01_menu_ingreso_masivo_y_sfcl.sql)
-- ---------------------------------------------------------------------
delete from VTA_SFCLRELPERMEN where mnu_codigo = 460;
delete from VTA_SFCLMENU where mnu_codigo = 460;
commit;

select count(*) quedan_menu from VTA_SFCLMENU where mnu_codigo = 460;
select count(*) quedan_rel from VTA_SFCLRELPERMEN where mnu_codigo = 460;

-- ---------------------------------------------------------------------
-- PARTE B - Borra los packages (primero el de grabado, que usa la spec
--      del de carga). Form174 da error de Oracle en SFCL hasta reinstalar.
--      Si se ejecuto 05, borrar tambien los sinonimos (como DBA):
--        drop synonym UINTRANETTS.PKG_F8_GRABA_MASIVA_YZ_SFCL;   -- EDITAR
--        drop synonym UINTRANETTS.PKG_F8_CARGA_MASIVA_YZ_SFCL;   -- EDITAR
-- ---------------------------------------------------------------------
-- drop package PKG_F8_GRABA_MASIVA_YZ_SFCL;
-- drop package PKG_F8_CARGA_MASIVA_YZ_SFCL;

-- ---------------------------------------------------------------------
-- PARTE C - Borra las tablas (con sus cargas y log) y las secuencias.
--      Ejecutar despues de la parte B.
--      Sinonimos de 05 (como DBA):
--        drop synonym UINTRANETTS.VTA_SFCLCARGA_YZ_RES;   -- EDITAR
--        drop synonym UINTRANETTS.VTA_SFCLCARGA_YZ_DET;   -- EDITAR
--        drop synonym UINTRANETTS.VTA_SFCLCARGA_YZ_LOG;   -- EDITAR
-- ---------------------------------------------------------------------
declare
  procedure borra (p_sql in varchar2) is
  begin
    execute immediate p_sql;
    dbms_output.put_line('OK: ' || p_sql);
  exception
    when others then
      dbms_output.put_line('No se pudo (' || sqlerrm || '): ' || p_sql);
  end borra;
begin
  null;
  -- Descomentar para ejecutar:
  -- borra('drop table VTA_SFCLCARGA_YZ_RES purge');
  -- borra('drop table VTA_SFCLCARGA_YZ_DETM purge');
  -- borra('drop table VTA_SFCLCARGA_YZ_DET purge');
  -- borra('drop table VTA_SFCLCARGA_YZ_LOG purge');
  -- borra('drop sequence SEQ_VTA_SFCLCARGA_YZ');
  -- borra('drop sequence SEQ_VTA_SFCLCARGA_YZ_LOG');
end;
/

select object_name, object_type, status from user_objects
 where object_name like 'VTA\_SFCLCARGA\_YZ%' escape '\'
    or object_name like 'SEQ\_VTA\_SFCLCARGA\_YZ%' escape '\'
    or object_name in ('PKG_F8_CARGA_MASIVA_YZ_SFCL', 'PKG_F8_GRABA_MASIVA_YZ_SFCL');
