-- =====================================================================
-- FCDVT-259 - Instalacion de Exportar Cierres Y y Z (Form176), FACO
--   (02 y 03)
-- xintec-nruz 16-11-2026
--
-- ANTES, y por separado: 00_prechecks.sql.
-- Requiere PKG_F8_CARGA_MASIVA_YZ (docs/sql/FCDVT-14, 03 y 04) instalado:
-- el body usa su c_encabezado.
-- DESPUES, por separado: 04_grants_sinonimos.sql (si el exe usa otro
-- usuario) y 05_pruebas.sql.
-- 01_menu_exporta_yz.sql (permiso 461) NO va aqui: se ejecuta aparte y
-- solo junto con el exe nuevo. Con el exe anterior la fila 461 cae en el
-- Else de MDIForm1.SubBuscarOpcionMenu (Buttons(461) no existe), da error
-- y corta la carga de los permisos siguientes (mismo caso que el 460 de
-- FCDVT-14).
--
-- Ejecutar desde esta carpeta, conectado como el duenio de las tablas
-- VTA_* (test: INTRANETTS):
--   sqlplus <usuario>@<base> @INSTALAR.sql
-- En DBeaver: ejecutar 02 y 03 en ese orden (Alt+X).
-- =====================================================================
set echo on feedback on serveroutput on
whenever sqlerror exit failure rollback

prompt ===== Paso 02: especificacion PKG_F8_EXPORTA_MASIVA_YZ (solo FACO) =====
@02_pkg_f8_exporta_masiva_yz_spec.sql
prompt ===== Paso 03: cuerpo PKG_F8_EXPORTA_MASIVA_YZ (solo FACO) =====
@03_pkg_f8_exporta_masiva_yz_body.sql

prompt ===== Estado (esperado: PACKAGE y PACKAGE BODY VALID; sin user_errors) =====
select object_name, object_type, status from user_objects
 where object_name = 'PKG_F8_EXPORTA_MASIVA_YZ'
 order by object_type;
select name, type, line, position, text from user_errors
 where name = 'PKG_F8_EXPORTA_MASIVA_YZ'
 order by type, sequence;
