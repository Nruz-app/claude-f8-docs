-- =====================================================================
-- FSCC-12957 (HU-01-T1) Compensacion automatica de DI - Falabella Colombia
-- 05 - Permisos y sinonimos (mismo esquema de FSCC-12958/07)
--   Parte A: conectado como el esquema duenio.
--   Parte B: como DBA (CREATE ANY SYNONYM) con current_schema = duenio.
-- =====================================================================

accept usuario_app char prompt 'Usuario de aplicacion que recibe permisos y sinonimos (ej. el usuario del exe o del job): '

column esquema_actual new_value esquema_duenio noprint
select sys_context('USERENV', 'CURRENT_SCHEMA') esquema_actual from dual;
prompt Esquema duenio: &esquema_duenio  /  Usuario de aplicacion: &usuario_app

-- Parte A
grant execute on PKG_F8_FACO_COMPENSA_DI to &usuario_app;

-- Parte B
create or replace synonym &usuario_app..PKG_F8_FACO_COMPENSA_DI for &esquema_duenio..PKG_F8_FACO_COMPENSA_DI;
