-- =====================================================================
-- FCDVT-14 - Instalacion de la carga masiva Y / Z, etapa Buscar (02 a 04)
-- MULTIPAIS (habilitado: FACO)
-- xintec-nruz 30-10-2026 / 03-11-2026 (multipais y estado CARGADO)
-- Version anterior (solo FACO): anterior_2026-11-03/INSTALAR.sql
--
-- ANTES, y por separado: 00_prechecks.sql (seccion 13: objetos del prefijo).
-- 01_menu_ingreso_masivo_y.sql (permiso 460) ya esta en test y no se repite.
-- DESPUES, por separado: 05_grants_sinonimos.sql (si el exe usa otro
-- usuario) y 06_pruebas.sql.
--
-- 02 crea las tablas del prefijo de su bloque EDITAR (FACO) solo si no
-- existen: en test, donde VTA_FACOCARGA_YZ_* ya estan desde el 30-10, no
-- crea nada. 03 y 04 reemplazan el package por la version multipais.
-- Para volver a la version solo FACO: 99_rollback.sql, parte C.
--
-- Ejecutar desde esta carpeta, conectado como el duenio de las tablas
-- VTA_* (test: INTRANETTS):
--   sqlplus <usuario>@<base> @INSTALAR.sql
-- En DBeaver: ejecutar 02, 03 y 04 en ese orden (Alt+X).
-- =====================================================================
set echo on feedback on serveroutput on
whenever sqlerror exit failure rollback

prompt ===== Paso 02: tablas y secuencias VTA_<pfx>CARGA_YZ_* (solo las que falten) =====
@02_tablas_carga_yz.sql
prompt ===== Paso 03: especificacion PKG_F8_CARGA_MASIVA_YZ (multipais) =====
@03_pkg_carga_masiva_yz_spec.sql
prompt ===== Paso 04: cuerpo PKG_F8_CARGA_MASIVA_YZ (multipais) =====
@04_pkg_carga_masiva_yz_body.sql

prompt ===== Estado de los objetos (esperado FACO: 3 tablas, 2 secuencias, spec y body VALID; sin user_errors) =====
select object_name, object_type, status from user_objects
 where object_name in ('VTA_FACOCARGA_YZ_DET', 'VTA_FACOCARGA_YZ_RES', 'VTA_FACOCARGA_YZ_LOG',
                       'SEQ_VTA_FACOCARGA_YZ', 'SEQ_VTA_FACOCARGA_YZ_LOG',
                       'PKG_F8_CARGA_MASIVA_YZ')
 order by object_type, object_name;
select name, type, line, position, text from user_errors
 where name = 'PKG_F8_CARGA_MASIVA_YZ'
 order by type, sequence;
