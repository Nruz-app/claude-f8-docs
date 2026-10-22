-- =====================================================================
-- FSCC-12901 COMPENSA_DI - Paso 06: permisos y sinonimos para el usuario
-- de la aplicacion ([CONNECT] del exe). Test: INTRANETTS -> UINTRANETTS.
-- xintec-nruz 19-10-2026
-- =====================================================================

-- A) Como el duenio (INTRANETTS)
grant execute on PKG_F8_COMPENSA_DI_CARGA to UINTRANETTS;
grant select  on VTA_FACOLOG_COMPENSA_DI  to UINTRANETTS;

-- B) Como DBA (CREATE ANY SYNONYM)
create or replace synonym UINTRANETTS.PKG_F8_COMPENSA_DI_CARGA for INTRANETTS.PKG_F8_COMPENSA_DI_CARGA;
create or replace synonym UINTRANETTS.VTA_FACOLOG_COMPENSA_DI  for INTRANETTS.VTA_FACOLOG_COMPENSA_DI;

-- Verificacion (ESPERADO: 2 sinonimos)
select owner, synonym_name, table_owner, table_name
  from all_synonyms
 where table_name in ('PKG_F8_COMPENSA_DI_CARGA', 'VTA_FACOLOG_COMPENSA_DI');
