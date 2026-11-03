-- =====================================================================
-- FCDVT-14 - Rollback, por partes (ejecutar solo la parte que corresponda)
-- xintec-nruz 20-10-2026 / 30-10-2026 / 03-11-2026 (multipais: partes B y C)
-- Version anterior: anterior_2026-11-03/99_rollback.sql
-- =====================================================================
set feedback on serveroutput on

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
-- PARTE B - Desinstala la carga masiva Y/Z de UN prefijo (paso 02)
--      Borra las tablas (con sus cargas y log) y las secuencias del
--      prefijo del bloque EDITAR. El package queda (lo usan los demas
--      paises); para borrarlo tambien: drop package PKG_F8_CARGA_MASIVA_YZ;
--      Si se ejecuto 05, borrar tambien los sinonimos (como DBA):
--        drop synonym UINTRANETTS.VTA_FACOCARGA_YZ_RES;     -- EDITAR
--        drop synonym UINTRANETTS.VTA_FACOCARGA_YZ_DET;     -- EDITAR
--        drop synonym UINTRANETTS.VTA_FACOCARGA_YZ_LOG;     -- EDITAR
--      Un exe con el Buscar nuevo de Form174 da error al buscar un archivo
--      de ese pais hasta que se vuelva a instalar.
-- ---------------------------------------------------------------------
declare
  v_prefijo varchar2(10) := 'FACO';   -- EDITAR: prefijo del pais (Chile = '')
  v_p       varchar2(10) := upper(trim(v_prefijo));
  procedure borra (p_sql in varchar2) is
  begin
    execute immediate p_sql;
    dbms_output.put_line('OK: ' || p_sql);
  exception
    when others then
      dbms_output.put_line('No se pudo (' || sqlerrm || '): ' || p_sql);
  end borra;
begin
  borra('drop table VTA_' || v_p || 'CARGA_YZ_RES purge');
  borra('drop table VTA_' || v_p || 'CARGA_YZ_DET purge');
  borra('drop table VTA_' || v_p || 'CARGA_YZ_LOG purge');
  borra('drop sequence SEQ_VTA_' || v_p || 'CARGA_YZ');
  borra('drop sequence SEQ_VTA_' || v_p || 'CARGA_YZ_LOG');
end;
/

select object_name, object_type from user_objects
 where object_name like 'VTA\_%CARGA\_YZ%' escape '\'
    or object_name like 'SEQ\_VTA\_%CARGA\_YZ%' escape '\'
    or object_name = 'PKG_F8_CARGA_MASIVA_YZ';

-- ---------------------------------------------------------------------
-- PARTE C - Volver a la version solo FACO (la del 30-10-2026)
--      Si el package multipais no funciona: recompila la version anterior,
--      que usa VTA_FACOCARGA_YZ_* con SQL estatico. Las tablas FACO no
--      cambian (son las mismas en las dos versiones).
--      El exe tambien hay que volverlo atras: el Form174 del 03-11 llama a
--      las firmas con pais, que la version anterior no tiene. Usar
--      FTEPROD/Form174.frm.bak_FCDVT-14_Multipais y
--      FTEPROD/Form175.frm.bak_FCDVT-14_Multipais (y sincronizar docs/Cambios).
--      Ejecutar desde esta carpeta (sqlplus):
-- ---------------------------------------------------------------------
-- @anterior_2026-11-03/03_pkg_carga_masiva_yz_spec.sql
-- @anterior_2026-11-03/04_pkg_carga_masiva_yz_body.sql
-- select object_name, object_type, status from user_objects where object_name = 'PKG_F8_CARGA_MASIVA_YZ';
