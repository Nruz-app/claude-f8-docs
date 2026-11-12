-- =====================================================================
-- FCDVT-10 (HU-03) - Instalacion de la carga masiva Y / Z de Tottus Chile
--   (02, 03, 04, 04b y 04c)
-- xintec-nruz 11-11-2026
--
-- ANTES, y por separado: 00_prechecks.sql (secciones 1 a 6).
-- DESPUES, por separado: 01_menu_ingreso_masivo_y_sfcl.sql (solo con el exe
-- nuevo), 05_grants_sinonimos.sql (si el exe usa otro usuario) y
-- 06_pruebas.sql. No toca los objetos de FACO (FCDVT-14).
--
-- Ejecutar desde esta carpeta, conectado como el duenio de las tablas
-- VTA_* (test: INTRANETTS):
--   sqlplus <usuario>@<base> @INSTALAR.sql
-- En DBeaver: ejecutar 02, 03, 04, 04b y 04c en ese orden (Alt+X).
-- =====================================================================
set echo on feedback on serveroutput on
whenever sqlerror exit failure rollback

prompt ===== Paso 02: tablas y secuencias VTA_SFCLCARGA_YZ_* (solo las que falten) =====
@02_tablas_carga_yz_sfcl.sql
prompt ===== Paso 03: especificacion PKG_F8_CARGA_MASIVA_YZ_SFCL (Buscar) =====
@03_pkg_carga_masiva_yz_sfcl_spec.sql
prompt ===== Paso 04: cuerpo PKG_F8_CARGA_MASIVA_YZ_SFCL (Buscar) =====
@04_pkg_carga_masiva_yz_sfcl_body.sql
prompt ===== Paso 04b: especificacion PKG_F8_GRABA_MASIVA_YZ_SFCL (Cargar) =====
@04b_pkg_f8_graba_masiva_yz_sfcl_spec.sql
prompt ===== Paso 04c: cuerpo PKG_F8_GRABA_MASIVA_YZ_SFCL (Cargar) =====
@04c_pkg_f8_graba_masiva_yz_sfcl_body.sql

prompt ===== Estado (esperado: 4 tablas, 2 secuencias, 2 packages con spec y body VALID; sin user_errors) =====
select object_name, object_type, status from user_objects
 where object_name in ('VTA_SFCLCARGA_YZ_DET', 'VTA_SFCLCARGA_YZ_DETM', 'VTA_SFCLCARGA_YZ_RES',
                       'VTA_SFCLCARGA_YZ_LOG', 'SEQ_VTA_SFCLCARGA_YZ', 'SEQ_VTA_SFCLCARGA_YZ_LOG',
                       'PKG_F8_CARGA_MASIVA_YZ_SFCL', 'PKG_F8_GRABA_MASIVA_YZ_SFCL')
 order by object_type, object_name;
select name, type, line, position, text from user_errors
 where name in ('PKG_F8_CARGA_MASIVA_YZ_SFCL', 'PKG_F8_GRABA_MASIVA_YZ_SFCL')
 order by type, sequence;

prompt ===== Configuracion leida de VTA_PAINT_Z (ORA-20002 = VTA_PAINT_Z no tiene la forma esperada) =====
select PKG_F8_CARGA_MASIVA_YZ_SFCL.fn_encabezado('SFCL') encabezado from dual;
