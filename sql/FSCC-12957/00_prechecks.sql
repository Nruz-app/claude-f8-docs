-- =====================================================================
-- FSCC-12957 (HU-01-T1) Compensacion automatica de DI - Falabella Colombia
-- 00 - Verificaciones previas (solo lectura), conectado como el duenio.
-- Requiere que FSCC-12958 (cola, log, trigger y PKG_F8_FACO_CIERRE_AUTO)
-- este instalado o se instale en la misma ventana (ver README.md).
-- Resultados de referencia: test 06-10-2026.
-- =====================================================================
set linesize 200 pagesize 500 feedback on

prompt === 1. Objetos de FSCC-12958 que T1 reutiliza (esperado: los 5, VALID)
select object_name, object_type, status from all_objects
 where owner = sys_context('USERENV','CURRENT_SCHEMA')
   and object_name in ('VTA_FACOPRD_CIERRE', 'VTA_FACOLOG_CIERRE_AUTO',
                       'TRG_VTA_FACOPRD_CIERRE_AI', 'PKG_F8_FACO_CIERRE_AUTO',
                       'VTA_FACOV_CAJAS_CIERRE')
 order by 1, 2;

prompt === 2. Objeto nuevo de T1 no debe existir (esperado: 0 filas)
select object_name, object_type from all_objects
 where owner = sys_context('USERENV','CURRENT_SCHEMA') and object_name = 'PKG_F8_FACO_COMPENSA_DI';

prompt === 3. Parametros nuevos libres (esperado: 0)
select count(*) from VTA_FACOPARAM
 where vta_ccodtipo = 1502 and vta_ccodigo in ('CA_DI_ACTIVO', 'CA_DI_MIN', 'CA_DI_MAX');

prompt === 4. Rango DI manual vigente (test: 1500 DI = -500, 1501 DI = 20000; NO se modifica)
select vta_ccodtipo, vta_ccodigo, vta_xglosa from VTA_FACOPARAM where vta_ccodtipo in (1500, 1501);

prompt === 5. Concepto DI en VTA_FACOCONCEPDIF (test: coddif 8 'Diferencia no Imputable')
select mov_tipomov, vta_coddif, vta_glosadif from VTA_FACOCONCEPDIF where mov_tipomov = 'DI';

prompt === 6. Secuencia de mov_techkey que usa el exe para la DI (test: SEQ_VTA_FACOVEN)
select sequence_name, last_number from all_sequences
 where sequence_owner = sys_context('USERENV','CURRENT_SCHEMA') and sequence_name = 'SEQ_VTA_FACOVEN';

prompt === 7. Trigger que numera VTA_FACOCOMPDES (test: TRG_VTA_FACOCOMPDES_I_SEQ ENABLED)
select trigger_name, status from all_triggers
 where table_owner = sys_context('USERENV','CURRENT_SCHEMA') and table_name = 'VTA_FACOCOMPDES';

prompt === 8. Columnas NOT NULL de VTA_FACOMOVDET sin default (esperado: las 11 que informa el INSERT)
select column_name from all_tab_columns
 where owner = sys_context('USERENV','CURRENT_SCHEMA') and table_name = 'VTA_FACOMOVDET'
   and nullable = 'N' and data_default is null
 order by column_id;
-- test: MOV_FECHA, MOV_LOCAL, MOV_TERMINAL, MOV_TIPOMOV, MOV_ROL, MOV_NOMBRE,
--       MOV_SECUENCIA, MOV_NUMERO, MOV_MONTO, MOV_HECHOPOR, MOV_TECHKEY
--       (MOV_REGUL, MOV_CIERREY, MOV_NOMEMPLEADO, MOV_EMPEMPLEADO tienen default)

prompt === 9. Columna log_proceso en el log (si no existe, ejecutar 01_ajuste_log.sql)
select column_name, data_default from all_tab_columns
 where owner = sys_context('USERENV','CURRENT_SCHEMA')
   and table_name = 'VTA_FACOLOG_CIERRE_AUTO' and column_name = 'LOG_PROCESO';
