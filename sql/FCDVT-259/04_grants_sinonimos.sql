-- =====================================================================
-- FCDVT-259 - Paso 04: permisos y sinonimo de PKG_F8_EXPORTA_MASIVA_YZ
-- para el usuario del exe F8 (FACO)
-- xintec-nruz 16-11-2026 (antes en docs/sql/FCDVT-14/05_grants_sinonimos.sql)
--
-- Si el exe (Setup.ini, [CONNECT]) se conecta como el duenio de las
-- tablas VTA_*, este paso no hace falta. Si usa otro usuario, completar
-- los valores marcados EDITAR. Form176 solo ejecuta el package (no lee
-- tablas nuevas; los combos leen vta_FACOlocales y vta_FACOterminales,
-- que el exe ya usa).
-- =====================================================================
set serveroutput on

-- A) Como el duenio (test: INTRANETTS)
declare
  v_usuario varchar2(30) := 'UINTRANETTS';   -- EDITAR: usuario del exe
begin
  execute immediate 'grant execute on PKG_F8_EXPORTA_MASIVA_YZ to ' || v_usuario;
  dbms_output.put_line('Grant dado a ' || v_usuario);
end;
/

-- B) Como DBA (CREATE ANY SYNONYM)
declare
  v_usuario varchar2(30) := 'UINTRANETTS';   -- EDITAR: usuario del exe
  v_duenio  varchar2(30) := 'INTRANETTS';    -- EDITAR: duenio de las tablas
begin
  execute immediate 'create or replace synonym ' || v_usuario || '.PKG_F8_EXPORTA_MASIVA_YZ'
                    || ' for ' || v_duenio || '.PKG_F8_EXPORTA_MASIVA_YZ';
  dbms_output.put_line('Sinonimo ' || v_usuario || '.PKG_F8_EXPORTA_MASIVA_YZ');
end;
/

-- Verificacion (ESPERADO: el sinonimo del usuario del exe)
select owner, synonym_name, table_owner, table_name
  from all_synonyms
 where table_name = 'PKG_F8_EXPORTA_MASIVA_YZ';
