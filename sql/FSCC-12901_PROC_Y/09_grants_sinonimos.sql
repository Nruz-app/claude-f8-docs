-- =====================================================================
-- FSCC-12901 v2 MULTIPAIS - Paso 09
-- Permisos y sinonimos para el usuario de aplicacion (exe, conexion
-- [CONNECT] de Setup.ini) y el del job.
-- Sin variables de sustitucion (DBeaver): EDITAR reemplazando USUARIO_APP
-- por el usuario real y DUENIO por el esquema duenio de las tablas VTA_*.
--   Parte A: conectado como el duenio.
--   Parte B: como DBA (CREATE ANY SYNONYM).
-- Los paquetes corren con derechos del duenio (SQL dinamico incluido):
-- basta EXECUTE. Paquetes: uno por base. Tablas: una por pais (aqui FACO).
-- =====================================================================

-- Parte A: permisos (EDITAR USUARIO_APP)
grant execute on PKG_F8_CIERRE_AUTO       to USUARIO_APP;
grant execute on PKG_F8_COMPENSA_DI_AUTO  to USUARIO_APP;
grant select  on VTA_FACOPRD_CIERRE       to USUARIO_APP;
grant select  on VTA_FACOLOG_CIERRE_AUTO  to USUARIO_APP;

-- Parte B: sinonimos (EDITAR USUARIO_APP y DUENIO)
create or replace synonym USUARIO_APP.PKG_F8_CIERRE_AUTO      for DUENIO.PKG_F8_CIERRE_AUTO;
create or replace synonym USUARIO_APP.PKG_F8_COMPENSA_DI_AUTO for DUENIO.PKG_F8_COMPENSA_DI_AUTO;
create or replace synonym USUARIO_APP.VTA_FACOPRD_CIERRE      for DUENIO.VTA_FACOPRD_CIERRE;
create or replace synonym USUARIO_APP.VTA_FACOLOG_CIERRE_AUTO for DUENIO.VTA_FACOLOG_CIERRE_AUTO;
