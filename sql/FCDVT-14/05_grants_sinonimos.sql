-- =====================================================================
-- FCDVT-14 - Paso 05: permisos y sinonimos para el usuario del exe F8
-- MULTIPAIS: por prefijo de pais
-- xintec-nruz 30-10-2026 / 03-11-2026 (multipais)
-- xintec-nruz 04-11-2026: tambien PKG_F8_GRABA_MASIVA_YZ (boton Cargar)
-- Version anterior (solo FACO): anterior_2026-11-03/05_grants_sinonimos.sql
--
-- Si el exe (Setup.ini, [CONNECT]) se conecta como el duenio de las
-- tablas VTA_*, este paso no hace falta. Si usa otro usuario, completar
-- los valores marcados EDITAR.
-- Form174 ejecuta el package y lee VTA_<pfx>CARGA_YZ_RES (grilla);
-- Form175 lee VTA_<pfx>CARGA_YZ_LOG y VTA_<pfx>CARGA_YZ_DET.
-- =====================================================================
set serveroutput on

-- A) Como el duenio (test: INTRANETTS)
declare
  v_prefijo varchar2(10) := 'FACO';          -- EDITAR: prefijo del pais (Chile = '')
  v_usuario varchar2(30) := 'UINTRANETTS';   -- EDITAR: usuario del exe
  v_p       varchar2(10) := upper(trim(v_prefijo));
begin
  execute immediate 'grant execute on PKG_F8_CARGA_MASIVA_YZ to ' || v_usuario;
  execute immediate 'grant execute on PKG_F8_GRABA_MASIVA_YZ to ' || v_usuario;
  execute immediate 'grant select on VTA_' || v_p || 'CARGA_YZ_RES to ' || v_usuario;
  execute immediate 'grant select on VTA_' || v_p || 'CARGA_YZ_DET to ' || v_usuario;
  execute immediate 'grant select on VTA_' || v_p || 'CARGA_YZ_LOG to ' || v_usuario;
  dbms_output.put_line('Grants dados a ' || v_usuario || ' (prefijo ' || nvl(v_p, '(vacio)') || ')');
end;
/

-- B) Como DBA (CREATE ANY SYNONYM)
declare
  v_prefijo varchar2(10) := 'FACO';          -- EDITAR: prefijo del pais (Chile = '')
  v_usuario varchar2(30) := 'UINTRANETTS';   -- EDITAR: usuario del exe
  v_duenio  varchar2(30) := 'INTRANETTS';    -- EDITAR: duenio de las tablas
  v_p       varchar2(10) := upper(trim(v_prefijo));
  procedure sin (p_obj in varchar2) is
  begin
    execute immediate 'create or replace synonym ' || v_usuario || '.' || p_obj
                      || ' for ' || v_duenio || '.' || p_obj;
    dbms_output.put_line('Sinonimo ' || v_usuario || '.' || p_obj);
  end sin;
begin
  sin('PKG_F8_CARGA_MASIVA_YZ');
  sin('PKG_F8_GRABA_MASIVA_YZ');
  sin('VTA_' || v_p || 'CARGA_YZ_RES');
  sin('VTA_' || v_p || 'CARGA_YZ_DET');
  sin('VTA_' || v_p || 'CARGA_YZ_LOG');
end;
/

-- Verificacion (ESPERADO: el package y las 3 tablas de cada prefijo instalado)
select owner, synonym_name, table_owner, table_name
  from all_synonyms
 where table_name in ('PKG_F8_CARGA_MASIVA_YZ', 'PKG_F8_GRABA_MASIVA_YZ')
    or table_name like 'VTA\_%CARGA\_YZ\_%' escape '\';
