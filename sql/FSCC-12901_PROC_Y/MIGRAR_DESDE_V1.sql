-- =====================================================================
-- FSCC-12901 v2 MULTIPAIS - Migracion desde v1 (base donde ya esta
-- instalado docs/sql/FSCC-12901_T1_T2, p. ej. desarrollo INTRANETDE).
-- Conectado como el duenio. En DBeaver: ejecutar como script (Alt+X).
--
-- NO borra nada de v1: v1 (PKG_F8_FACO_*) y v2 (PKG_F8_CIERRE_AUTO /
-- PKG_F8_COMPENSA_DI_AUTO) pueden convivir para comparar resultados.
-- No ejecutar los dos procesos automaticos a la vez sobre la misma cola.
--   1. Cola: se agrega el estado E (en proceso). V queda permitido por las
--      filas historicas de v1.
--   2. CA_DIAS: v2 no lo usa para FACO (se deja; v1 lo sigue leyendo).
--   3. Se compilan los paquetes v2 (scripts 04 a 07, en este orden).
-- Cola, log, secuencias, trigger, parametros y opcion 1515 se reutilizan.
-- Vuelta atras: MIGRAR_99_volver_v1.sql.
-- =====================================================================

-- 0. Objetos v1 presentes (esperado: 7 filas VALID, mas la vista)
select object_name, object_type, status from user_objects
 where object_name in ('VTA_FACOPRD_CIERRE','SEQ_VTA_FACOPRD_CIERRE','VTA_FACOLOG_CIERRE_AUTO',
                       'SEQ_VTA_FACOLOG_CIERRE_AUTO','TRG_VTA_FACOPRD_CIERRE_AI',
                       'PKG_F8_FACO_CIERRE_AUTO','PKG_F8_FACO_COMPENSA_DI','VTA_FACOV_CAJAS_CIERRE')
 order by object_type, object_name;

-- 1. Estados de la cola: P, E (nuevo), C, O y V (historico v1)
alter table VTA_FACOPRD_CIERRE drop constraint CK_VTA_FACOPRD_CIERRE_EST;
alter table VTA_FACOPRD_CIERRE
  add constraint CK_VTA_FACOPRD_CIERRE_EST check (pcr_estado in ('P','E','C','O','V'));
comment on column VTA_FACOPRD_CIERRE.pcr_estado is 'P pendiente, E en proceso (v2), C procesada, O omitida (sin cierre Y), V vencida (v1)';

-- 2. Indice para tomar la carga por ejecucion
create index IND_VTA_FACOPRD_CIERRE_03 on VTA_FACOPRD_CIERRE (pcr_estado, pcr_ejecucion);

-- 3. Compilar los paquetes v2: ejecutar a continuacion, en este orden,
--      04_pkg_cierre_auto_spec.sql
--      05_pkg_compensa_di_spec.sql
--      06_pkg_compensa_di_body.sql
--      07_pkg_cierre_auto_body.sql
--    y revisar:
select object_name, object_type, status from user_objects
 where object_name in ('PKG_F8_CIERRE_AUTO','PKG_F8_COMPENSA_DI_AUTO')
 order by 1, 2;
select name, type, line, position, text from user_errors
 where name in ('PKG_F8_CIERRE_AUTO','PKG_F8_COMPENSA_DI_AUTO')
 order by name, type, sequence;
