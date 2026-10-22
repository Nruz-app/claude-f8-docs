-- =====================================================================
-- FSCC-12958 (HU-01-T2) Cierre de caja automatico - Falabella Colombia
-- 07 - Permisos y sinonimos para el usuario de aplicacion
-- Patron de la base: el usuario de aplicacion accede a los objetos del
-- esquema duenio mediante sinonimos.
-- El paquete corre con derechos del duenio: quien lo ejecute solo
-- necesita EXECUTE. El exe (Form43, FACO) llama a PKG_F8_FACO_CIERRE_AUTO
-- con el usuario de la conexion [CONNECT] de Setup.ini: ese usuario debe
-- recibir el EXECUTE y el sinonimo (FSCC-12901 DF-SCC).
--
-- Uso (SQL*Plus):
--   1) El script pide el usuario de aplicacion (accept usuario_app).
--   2) Parte A: conectado como el esquema duenio.
--   3) Parte B: conectado como DBA (CREATE ANY SYNONYM), con
--      "alter session set current_schema = <duenio>" antes de ejecutarla,
--      o bien como el usuario de aplicacion si tiene CREATE SYNONYM.
-- =====================================================================

accept usuario_app char prompt 'Usuario de aplicacion que recibe permisos y sinonimos (ej. el usuario del exe o del job): '

-- Esquema duenio = esquema actual de la sesion (no se escribe fijo)
column esquema_actual new_value esquema_duenio noprint
select sys_context('USERENV', 'CURRENT_SCHEMA') esquema_actual from dual;
prompt Esquema duenio: &esquema_duenio  /  Usuario de aplicacion: &usuario_app

-- ---------------------------------------------------------------
-- Parte A: permisos (conectado como el duenio)
-- ---------------------------------------------------------------
grant execute on PKG_F8_FACO_CIERRE_AUTO  to &usuario_app;
grant select  on VTA_FACOPRD_CIERRE       to &usuario_app;
grant select  on VTA_FACOLOG_CIERRE_AUTO  to &usuario_app;
grant select  on VTA_FACOV_CAJAS_CIERRE   to &usuario_app;

-- ---------------------------------------------------------------
-- Parte B: sinonimos del usuario de aplicacion
-- ---------------------------------------------------------------
create or replace synonym &usuario_app..PKG_F8_FACO_CIERRE_AUTO for &esquema_duenio..PKG_F8_FACO_CIERRE_AUTO;
create or replace synonym &usuario_app..VTA_FACOPRD_CIERRE      for &esquema_duenio..VTA_FACOPRD_CIERRE;
create or replace synonym &usuario_app..VTA_FACOLOG_CIERRE_AUTO for &esquema_duenio..VTA_FACOLOG_CIERRE_AUTO;
create or replace synonym &usuario_app..VTA_FACOV_CAJAS_CIERRE  for &esquema_duenio..VTA_FACOV_CAJAS_CIERRE;
