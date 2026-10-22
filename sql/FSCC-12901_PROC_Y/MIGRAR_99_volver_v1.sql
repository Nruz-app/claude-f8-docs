-- =====================================================================
-- FSCC-12901 v2 MULTIPAIS - Vuelta atras de MIGRAR_DESDE_V1.sql
-- Deja la base como estaba con v1. Conectado como el duenio.
-- =====================================================================

-- 1. Filas que v2 dejo en E (ejecucion interrumpida) vuelven a pendiente
update VTA_FACOPRD_CIERRE set pcr_estado = 'P' where pcr_estado = 'E';
commit;

-- 2. Paquetes v2
drop package PKG_F8_CIERRE_AUTO;
drop package PKG_F8_COMPENSA_DI_AUTO;

-- 3. Estados de la cola de v1 (P, C, O, V)
alter table VTA_FACOPRD_CIERRE drop constraint CK_VTA_FACOPRD_CIERRE_EST;
alter table VTA_FACOPRD_CIERRE
  add constraint CK_VTA_FACOPRD_CIERRE_EST check (pcr_estado in ('P','C','O','V'));
comment on column VTA_FACOPRD_CIERRE.pcr_estado is 'P pendiente, C cerrada/terminada, O omitida (sin cierre Y), V vencida';
drop index IND_VTA_FACOPRD_CIERRE_03;

-- 4. Paquetes v1 validos (esperado: VALID)
select object_name, object_type, status from user_objects
 where object_name in ('PKG_F8_FACO_CIERRE_AUTO','PKG_F8_FACO_COMPENSA_DI')
 order by 1, 2;
