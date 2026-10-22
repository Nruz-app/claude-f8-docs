-- =====================================================================
-- FSCC-12901 CIERRE_DIARIO - Paso 05: permisos y sinonimos para el usuario
-- con el que corre el proceso externo (nhal1).
-- xintec-nruz 20-10-2026
-- Si nhal1 se conecta como el duenio (test: INTRANETTS), este paso no hace
-- falta. Si usa otro usuario, reemplazar UINTRANETTS por ese usuario en
-- las lineas marcadas EDITAR.
-- =====================================================================

-- A) Como el duenio (INTRANETTS)
grant execute on PKG_F8_CIERRE_DIARIO      to UINTRANETTS;   -- EDITAR usuario de nhal1
grant select  on VTA_FACOLOG_CIERRE_DIARIO to UINTRANETTS;   -- EDITAR usuario de nhal1

-- B) Como DBA (CREATE ANY SYNONYM)
create or replace synonym UINTRANETTS.PKG_F8_CIERRE_DIARIO      for INTRANETTS.PKG_F8_CIERRE_DIARIO;        -- EDITAR
create or replace synonym UINTRANETTS.VTA_FACOLOG_CIERRE_DIARIO for INTRANETTS.VTA_FACOLOG_CIERRE_DIARIO;   -- EDITAR

-- Verificacion (ESPERADO: 2 sinonimos)
select owner, synonym_name, table_owner, table_name
  from all_synonyms
 where table_name in ('PKG_F8_CIERRE_DIARIO', 'VTA_FACOLOG_CIERRE_DIARIO');
