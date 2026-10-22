-- =====================================================================
-- FSCC-12901 T1 + T2 (carpeta consolidada) - Paso 09
-- Permisos y sinonimos para el usuario de aplicacion / del job.
--   Parte A: conectado como el esquema duenio.
--   Parte B: como DBA (CREATE ANY SYNONYM) con current_schema = duenio.
-- Los paquetes corren con derechos del duenio: basta EXECUTE.
-- El exe (Form43, FACO) llama a PKG_F8_FACO_CIERRE_AUTO con el usuario de
-- la conexion [CONNECT] de Setup.ini: ese usuario debe recibir el EXECUTE
-- y el sinonimo (FSCC-12901 DF-SCC).
-- =====================================================================

accept usuario_app char prompt 'Usuario de aplicacion que recibe permisos y sinonimos (ej. el usuario del exe o del job): '

column esquema_actual new_value esquema_duenio noprint
select sys_context('USERENV', 'CURRENT_SCHEMA') esquema_actual from dual;
prompt Esquema duenio: &esquema_duenio  /  Usuario de aplicacion: &usuario_app

-- Parte A: permisos
grant execute on PKG_F8_FACO_CIERRE_AUTO  to &usuario_app;
grant execute on PKG_F8_FACO_COMPENSA_DI  to &usuario_app;
grant select  on VTA_FACOPRD_CIERRE       to &usuario_app;
grant select  on VTA_FACOLOG_CIERRE_AUTO  to &usuario_app;
grant select  on VTA_FACOV_CAJAS_CIERRE   to &usuario_app;

-- Parte B: sinonimos
create or replace synonym &usuario_app..PKG_F8_FACO_CIERRE_AUTO for &esquema_duenio..PKG_F8_FACO_CIERRE_AUTO;
create or replace synonym &usuario_app..PKG_F8_FACO_COMPENSA_DI for &esquema_duenio..PKG_F8_FACO_COMPENSA_DI;
create or replace synonym &usuario_app..VTA_FACOPRD_CIERRE      for &esquema_duenio..VTA_FACOPRD_CIERRE;
create or replace synonym &usuario_app..VTA_FACOLOG_CIERRE_AUTO for &esquema_duenio..VTA_FACOLOG_CIERRE_AUTO;
create or replace synonym &usuario_app..VTA_FACOV_CAJAS_CIERRE  for &esquema_duenio..VTA_FACOV_CAJAS_CIERRE;
