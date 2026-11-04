-- =====================================================================
-- FCDVT-14 - Instalacion de la carga masiva Y / Z, Buscar y Cargar
--   (02, 03, 04, 04b y 04c)
-- MULTIPAIS (habilitado: FACO)
-- xintec-nruz 30-10-2026 / 03-11-2026 (multipais y estado CARGADO)
-- xintec-nruz 04-11-2026: dos packages: PKG_F8_CARGA_MASIVA_YZ (03 y 04,
--   Buscar) y PKG_F8_GRABA_MASIVA_YZ (04b y 04c, Cargar; usa la spec del
--   primero, por eso va despues)
-- Versiones anteriores: anterior_2026-11-04b/INSTALAR.sql (prc_graba dentro
--   del package de carga, descartada), anterior_2026-11-04/INSTALAR.sql (sin
--   Cargar), anterior_2026-11-03/INSTALAR.sql (solo FACO)
--
-- ANTES, y por separado: 00_prechecks.sql (seccion 13: objetos del prefijo).
-- 01_menu_ingreso_masivo_y.sql (permiso 460) ya esta en test y no se repite.
-- DESPUES, por separado: 05_grants_sinonimos.sql (si el exe usa otro
-- usuario) y 06_pruebas.sql.
--
-- 02 crea las tablas del prefijo de su bloque EDITAR (FACO) solo si no
-- existen: en test, donde VTA_FACOCARGA_YZ_* ya estan desde el 30-10, no
-- crea nada. 03 y 04 reemplazan PKG_F8_CARGA_MASIVA_YZ por la version
-- multipais; 04b y 04c crean PKG_F8_GRABA_MASIVA_YZ. Para quitar Cargar:
-- 99_rollback.sql, parte D; para volver a la version solo FACO: parte C.
--
-- Ejecutar desde esta carpeta, conectado como el duenio de las tablas
-- VTA_* (test: INTRANETTS):
--   sqlplus <usuario>@<base> @INSTALAR.sql
-- En DBeaver: ejecutar 02, 03, 04, 04b y 04c en ese orden (Alt+X).
-- =====================================================================
set echo on feedback on serveroutput on
whenever sqlerror exit failure rollback

prompt ===== Paso 02: tablas y secuencias VTA_<pfx>CARGA_YZ_* (solo las que falten) =====
@02_tablas_carga_yz.sql
prompt ===== Paso 03: especificacion PKG_F8_CARGA_MASIVA_YZ (multipais) =====
@03_pkg_carga_masiva_yz_spec.sql
prompt ===== Paso 04: cuerpo PKG_F8_CARGA_MASIVA_YZ (multipais) =====
@04_pkg_carga_masiva_yz_body.sql
prompt ===== Paso 04b: especificacion PKG_F8_GRABA_MASIVA_YZ (boton Cargar) =====
@04b_pkg_f8_graba_masiva_yz_spec.sql
prompt ===== Paso 04c: cuerpo PKG_F8_GRABA_MASIVA_YZ (boton Cargar) =====
@04c_pkg_f8_graba_masiva_yz_body.sql

prompt ===== Estado de los objetos (esperado FACO: 3 tablas, 2 secuencias, 2 packages con spec y body VALID; sin user_errors) =====
select object_name, object_type, status from user_objects
 where object_name in ('VTA_FACOCARGA_YZ_DET', 'VTA_FACOCARGA_YZ_RES', 'VTA_FACOCARGA_YZ_LOG',
                       'SEQ_VTA_FACOCARGA_YZ', 'SEQ_VTA_FACOCARGA_YZ_LOG',
                       'PKG_F8_CARGA_MASIVA_YZ', 'PKG_F8_GRABA_MASIVA_YZ')
 order by object_type, object_name;
select name, type, line, position, text from user_errors
 where name in ('PKG_F8_CARGA_MASIVA_YZ', 'PKG_F8_GRABA_MASIVA_YZ')
 order by type, sequence;
