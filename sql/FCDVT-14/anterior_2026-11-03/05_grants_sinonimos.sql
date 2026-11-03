-- =====================================================================
-- FCDVT-14 - Paso 05: permisos y sinonimos para el usuario del exe F8
-- xintec-nruz 30-10-2026
-- Si el exe (Setup.ini, [CONNECT]) se conecta como el duenio de las
-- tablas VTA_FACO*, este paso no hace falta. Si usa otro usuario,
-- reemplazar UINTRANETTS por ese usuario en las lineas marcadas EDITAR.
-- Form174 ejecuta el package y lee VTA_FACOCARGA_YZ_RES (grilla).
-- =====================================================================

-- A) Como el duenio (test: INTRANETTS)
grant execute on PKG_F8_CARGA_MASIVA_YZ to UINTRANETTS;   -- EDITAR usuario del exe
grant select  on VTA_FACOCARGA_YZ_RES   to UINTRANETTS;   -- EDITAR
grant select  on VTA_FACOCARGA_YZ_DET   to UINTRANETTS;   -- EDITAR
grant select  on VTA_FACOCARGA_YZ_LOG   to UINTRANETTS;   -- EDITAR

-- B) Como DBA (CREATE ANY SYNONYM)
create or replace synonym UINTRANETTS.PKG_F8_CARGA_MASIVA_YZ for INTRANETTS.PKG_F8_CARGA_MASIVA_YZ;   -- EDITAR
create or replace synonym UINTRANETTS.VTA_FACOCARGA_YZ_RES   for INTRANETTS.VTA_FACOCARGA_YZ_RES;     -- EDITAR
create or replace synonym UINTRANETTS.VTA_FACOCARGA_YZ_DET   for INTRANETTS.VTA_FACOCARGA_YZ_DET;     -- EDITAR
create or replace synonym UINTRANETTS.VTA_FACOCARGA_YZ_LOG   for INTRANETTS.VTA_FACOCARGA_YZ_LOG;     -- EDITAR

-- Verificacion (ESPERADO: 4 sinonimos)
select owner, synonym_name, table_owner, table_name
  from all_synonyms
 where table_name in ('PKG_F8_CARGA_MASIVA_YZ', 'VTA_FACOCARGA_YZ_RES',
                      'VTA_FACOCARGA_YZ_DET', 'VTA_FACOCARGA_YZ_LOG');
