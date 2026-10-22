-- =====================================================================
-- FSCC-12901 T1 + T2 (carpeta consolidada) - Instalacion completa
-- Ejecutar desde esta carpeta, conectado como el DUENIO de las tablas
-- VTA_FACO* (o como DBA con "alter session set current_schema = <duenio>"):
--   sqlplus <usuario>@<base> @INSTALAR.sql
-- El paso 09 (permisos y sinonimos) se ejecuta aparte (ver README.md).
-- =====================================================================
set echo on feedback on serveroutput on
whenever sqlerror exit failure rollback

prompt ===== Paso 00: verificaciones previas (revisar resultados esperados) =====
@00_prechecks.sql

prompt ===== Paso 01: tabla homologa (cola) =====
@01_tabla_homologa.sql
prompt ===== Paso 02: registro de ejecucion (log) =====
@02_log.sql
prompt ===== Paso 03: parametros =====
@03_parametros.sql
prompt ===== Paso 03b: vista del universo de cajas (T1 y T2) =====
@03b_vista_cajas.sql
prompt ===== Paso 03c: opcion 1515 Cerrar Terminal CC (Form43 FACO) =====
@03c_permiso_cc.sql
prompt ===== Paso 04: especificacion T2 =====
@04_pkg_cierre_auto_spec.sql
prompt ===== Paso 05: especificacion T1 =====
@05_pkg_compensa_di_spec.sql
prompt ===== Paso 06: cuerpo T1 =====
@06_pkg_compensa_di_body.sql
prompt ===== Paso 07: cuerpo T2 (llama a T1) =====
@07_pkg_cierre_auto_body.sql
prompt ===== Paso 08: trigger (desde aqui los sobres entran a la cola) =====
@08_trigger.sql

prompt ===== Estado de los objetos (esperado: VALID / ENABLED) =====
select object_name, object_type, status from user_objects
 where object_name in ('VTA_FACOPRD_CIERRE','SEQ_VTA_FACOPRD_CIERRE','VTA_FACOLOG_CIERRE_AUTO',
                       'SEQ_VTA_FACOLOG_CIERRE_AUTO','PKG_F8_FACO_CIERRE_AUTO',
                       'PKG_F8_FACO_COMPENSA_DI','TRG_VTA_FACOPRD_CIERRE_AI',
                       'VTA_FACOV_CAJAS_CIERRE')
 order by object_type, object_name;
select name, type, line, position, text from user_errors
 where name in ('PKG_F8_FACO_CIERRE_AUTO','PKG_F8_FACO_COMPENSA_DI','TRG_VTA_FACOPRD_CIERRE_AI')
 order by name, type, sequence;
