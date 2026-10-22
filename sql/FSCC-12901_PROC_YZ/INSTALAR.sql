-- =====================================================================
-- FSCC-12901 PROC_YZ (v2 multipais + cierre Z) - Instalacion completa en una base SIN v1
-- (si PROC_Y ya esta instalado usar ACTUALIZAR_DESDE_PROC_Y.sql).
-- Ejecutar desde esta carpeta, conectado como el DUENIO de las tablas VTA_*:
--   sqlplus <usuario>@<base> @INSTALAR.sql
-- En DBeaver: abrir y ejecutar cada script en este orden (Alt+X).
-- El paso 09 (permisos y sinonimos) se ejecuta aparte.
--
-- Objetos POR PAIS (hoy solo FACO): 01, 02, 03, 03c, 08.
-- Objetos GENERICOS (uno por base): 04, 05, 06, 07.
-- =====================================================================
set echo on feedback on serveroutput on
whenever sqlerror exit failure rollback

prompt ===== Paso 00: verificaciones previas (revisar resultados esperados) =====
@00_prechecks.sql

prompt ===== Paso 01: cola FACO =====
@01_cola_FACO.sql
prompt ===== Paso 02: log FACO =====
@02_log_FACO.sql
prompt ===== Paso 03: parametros FACO (sin CA_DIAS; 4 de la Z, CA_CIERRA_Z = N) =====
@03_parametros_FACO.sql
prompt ===== Paso 03c: opcion 1515 Cerrar Terminal CC (Form43 FACO) =====
@03c_permiso_FACO.sql
prompt ===== Paso 04: especificacion PKG_F8_CIERRE_AUTO =====
@04_pkg_cierre_auto_spec.sql
prompt ===== Paso 05: especificacion PKG_F8_COMPENSA_DI_AUTO =====
@05_pkg_compensa_di_spec.sql
prompt ===== Paso 06: cuerpo PKG_F8_COMPENSA_DI_AUTO =====
@06_pkg_compensa_di_body.sql
prompt ===== Paso 07: cuerpo PKG_F8_CIERRE_AUTO (llama a T1; incluye la Z) =====
@07_pkg_cierre_auto_body.sql
prompt ===== Paso 08: trigger FACO (desde aqui los sobres entran a la cola) =====
@08_trigger_FACO.sql

prompt ===== Estado de los objetos (esperado: VALID) =====
select object_name, object_type, status from user_objects
 where object_name in ('VTA_FACOPRD_CIERRE','SEQ_VTA_FACOPRD_CIERRE','VTA_FACOLOG_CIERRE_AUTO',
                       'SEQ_VTA_FACOLOG_CIERRE_AUTO','PKG_F8_CIERRE_AUTO',
                       'PKG_F8_COMPENSA_DI_AUTO','TRG_VTA_FACOPRD_CIERRE_AI')
 order by object_type, object_name;
select name, type, line, position, text from user_errors
 where name in ('PKG_F8_CIERRE_AUTO','PKG_F8_COMPENSA_DI_AUTO','TRG_VTA_FACOPRD_CIERRE_AI')
 order by name, type, sequence;
