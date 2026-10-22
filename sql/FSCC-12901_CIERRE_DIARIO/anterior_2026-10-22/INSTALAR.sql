-- =====================================================================
-- FSCC-12901 CIERRE_DIARIO - Instalacion (pasos 01 a 04)
-- xintec-nruz 20-10-2026
-- ANTES, y por separado: 00_prechecks.sql (consulta 2 con filas: la version
-- multipais de PKG_F8_COMPENSA_DI_CARGA debe estar instalada).
-- DESPUES, por separado: 05_grants_sinonimos.sql (si nhal1 usa otro usuario)
-- y 06_pruebas.sql.
-- Ejecutar desde esta carpeta, conectado como el duenio de las tablas
-- VTA_FACO* (test: INTRANETTS):
--   sqlplus <usuario>@<base> @INSTALAR.sql
-- En DBeaver: ejecutar 01, 02, 03 y 04 en ese orden (Alt+X).
-- =====================================================================
set echo on feedback on serveroutput on
whenever sqlerror exit failure rollback

prompt ===== Paso 01: log VTA_FACOLOG_CIERRE_DIARIO =====
@01_log_cierre_diario.sql
prompt ===== Paso 02: parametros 1502 CD_* =====
@02_parametros.sql
prompt ===== Paso 03: especificacion PKG_F8_CIERRE_DIARIO =====
@03_pkg_cierre_diario_spec.sql
prompt ===== Paso 04: cuerpo PKG_F8_CIERRE_DIARIO =====
@04_pkg_cierre_diario_body.sql

prompt ===== Estado de los objetos (esperado: 4 VALID, sin user_errors) =====
select object_name, object_type, status from user_objects
 where object_name in ('VTA_FACOLOG_CIERRE_DIARIO', 'SEQ_VTA_FACOLOG_CIERRE_DIARIO',
                       'PKG_F8_CIERRE_DIARIO')
 order by object_type, object_name;
select name, type, line, position, text from user_errors
 where name = 'PKG_F8_CIERRE_DIARIO'
 order by type, sequence;
