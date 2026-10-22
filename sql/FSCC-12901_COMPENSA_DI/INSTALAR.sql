-- =====================================================================
-- FSCC-12901 COMPENSA_DI - Instalacion (pasos 02 a 05)
-- xintec-nruz 19-10-2026
-- ANTES, y por separado: 00_prechecks.sql y 01_DESINSTALAR_v2.sql.
-- DESPUES, por separado: 06_grants_sinonimos.sql (parte B como DBA) y
-- 07_pruebas.sql.
-- Ejecutar desde esta carpeta, conectado como el duenio de las tablas
-- VTA_FACO* (test: INTRANETTS):
--   sqlplus <usuario>@<base> @INSTALAR.sql
-- En DBeaver: ejecutar 02, 03, 04 y 05 en ese orden (Alt+X).
-- =====================================================================
set echo on feedback on serveroutput on
whenever sqlerror exit failure rollback

prompt ===== Paso 02: log VTA_FACOLOG_COMPENSA_DI =====
@02_log_compensa_di.sql
prompt ===== Paso 03: parametros 1502 =====
@03_parametros.sql
prompt ===== Paso 04: especificacion PKG_F8_COMPENSA_DI_CARGA =====
@04_pkg_compensa_di_carga_spec.sql
prompt ===== Paso 05: cuerpo PKG_F8_COMPENSA_DI_CARGA =====
@05_pkg_compensa_di_carga_body.sql

prompt ===== Estado de los objetos (esperado: 4 VALID, sin user_errors) =====
select object_name, object_type, status from user_objects
 where object_name in ('VTA_FACOLOG_COMPENSA_DI', 'SEQ_VTA_FACOLOG_COMPENSA_DI',
                       'PKG_F8_COMPENSA_DI_CARGA')
 order by object_type, object_name;
select name, type, line, position, text from user_errors
 where name = 'PKG_F8_COMPENSA_DI_CARGA'
 order by type, sequence;
