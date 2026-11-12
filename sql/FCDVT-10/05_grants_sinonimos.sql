-- =====================================================================
-- FCDVT-10 (HU-03) - Paso 05: permisos y sinonimos para el usuario del exe
-- Tottus Chile (SFCL)
-- xintec-nruz 11-11-2026
-- Base: docs/sql/FCDVT-14/05_grants_sinonimos.sql.
--
-- Solo si el exe (Setup.ini, [CONNECT]) se conecta con un usuario distinto
-- del duenio de las tablas VTA_*. Completar los valores EDITAR.
-- Form174 ejecuta los dos packages y lee VTA_SFCLCARGA_YZ_RES; Form175 lee
-- VTA_SFCLCARGA_YZ_LOG y VTA_SFCLCARGA_YZ_DET.
-- =====================================================================
set serveroutput on

-- A) Como el duenio (test: INTRANETTS)
declare
  v_usuario varchar2(30) := 'UINTRANETTS';   -- EDITAR: usuario del exe
begin
  execute immediate 'grant execute on PKG_F8_CARGA_MASIVA_YZ_SFCL to ' || v_usuario;
  execute immediate 'grant execute on PKG_F8_GRABA_MASIVA_YZ_SFCL to ' || v_usuario;
  execute immediate 'grant select on VTA_SFCLCARGA_YZ_RES to ' || v_usuario;
  execute immediate 'grant select on VTA_SFCLCARGA_YZ_DET to ' || v_usuario;
  execute immediate 'grant select on VTA_SFCLCARGA_YZ_LOG to ' || v_usuario;
  dbms_output.put_line('Grants dados a ' || v_usuario);
end;
/

-- B) Como DBA (CREATE ANY SYNONYM)
declare
  v_usuario varchar2(30) := 'UINTRANETTS';   -- EDITAR: usuario del exe
  v_duenio  varchar2(30) := 'INTRANETTS';    -- EDITAR: duenio de las tablas
  procedure sin (p_obj in varchar2) is
  begin
    execute immediate 'create or replace synonym ' || v_usuario || '.' || p_obj
                      || ' for ' || v_duenio || '.' || p_obj;
    dbms_output.put_line('Sinonimo ' || v_usuario || '.' || p_obj);
  end sin;
begin
  sin('PKG_F8_CARGA_MASIVA_YZ_SFCL');
  sin('PKG_F8_GRABA_MASIVA_YZ_SFCL');
  sin('VTA_SFCLCARGA_YZ_RES');
  sin('VTA_SFCLCARGA_YZ_DET');
  sin('VTA_SFCLCARGA_YZ_LOG');
end;
/

-- Verificacion
select owner, synonym_name, table_owner, table_name
  from all_synonyms
 where table_name in ('PKG_F8_CARGA_MASIVA_YZ_SFCL', 'PKG_F8_GRABA_MASIVA_YZ_SFCL')
    or table_name like 'VTA\_SFCLCARGA\_YZ\_%' escape '\';
