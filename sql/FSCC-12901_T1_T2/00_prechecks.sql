-- =====================================================================
-- FSCC-12901 T1 + T2 (carpeta consolidada) - Paso 00
-- Verificaciones previas (solo lectura). Conectado como el duenio de las
-- tablas VTA_FACO*. Cada consulta indica el resultado esperado
-- (referencia: base de test 06-10-2026).
-- =====================================================================
set linesize 200 pagesize 500 feedback on

prompt === 1. Objetos a crear no deben existir (esperado: 0 filas)
select object_name, object_type from all_objects
 where owner = sys_context('USERENV','CURRENT_SCHEMA')
   and object_name in ('VTA_FACOPRD_CIERRE', 'SEQ_VTA_FACOPRD_CIERRE',
                       'VTA_FACOLOG_CIERRE_AUTO', 'SEQ_VTA_FACOLOG_CIERRE_AUTO',
                       'TRG_VTA_FACOPRD_CIERRE_AI',
                       'PKG_F8_FACO_CIERRE_AUTO', 'PKG_F8_FACO_COMPENSA_DI',
                       'VTA_FACOV_CAJAS_CIERRE');

prompt === 2. Triggers existentes en VTA_FACOPRD (test: ninguno)
select owner, trigger_name, triggering_event, status from all_triggers where table_name = 'VTA_FACOPRD';

prompt === 3. Parametros 1502 libres, incluido CA_SIN_SOBRE (esperado: 0)
select count(*) from VTA_FACOPARAM where vta_ccodtipo = 1502;

prompt === 4. Rango DI manual vigente (test: 1500 DI = -500, 1501 DI = 20000; NO se modifica)
select vta_ccodtipo, vta_ccodigo, vta_xglosa from VTA_FACOPARAM where vta_ccodtipo in (1500, 1501);

prompt === 5. Formato numerico de Colombia (test: '#,#0' => CA_DECIMAL 0)
select vta_localiz, vta_numformat, vta_decround from VTA_PARAMETROS where vta_localiz = 'FACO';

prompt === 6. Columnas usadas por los paquetes (esperado: 0 filas = todas existen)
with req as (
  select 'VTA_FACOLIBVTA' t, 'VTA_SECUENCIA' c from dual union all
  select 'VTA_FACOZZZ', 'REC_MSODIMAC'        from dual union all
  select 'VTA_FACOZZZ', 'REC_MTARJ'           from dual union all
  select 'VTA_FACOTESOR', 'TES_CIERREY'       from dual union all
  select 'VTA_FACOTARJ', 'VTA_CIERREY'        from dual union all
  select 'VTA_FACORECMEX', 'MEX_CIERREY'      from dual union all
  select 'VTA_FACORECMEX', 'MEX_CANTIDAD'     from dual union all
  select 'VTA_FACODIFVEND', 'VEN_CIERREY'     from dual union all
  select 'VTA_FACOCARTAAVISO', 'MOV_CIERREY'  from dual union all
  select 'VTA_FACOMOVDET', 'MOV_SECUENCIA'    from dual union all
  select 'VTA_FACOMOVDET', 'MOV_HECHOPOR'     from dual union all
  select 'VTA_FACOCOMPDES', 'CPD_CIERREY'     from dual union all
  select 'VTA_FACOCHEQUES', 'CHQ_TIPOCHEQUE'  from dual union all
  select 'VTA_FACOPRD', 'PRV_COD_RECAUD'      from dual union all
  select 'VTA_FACOPRD', 'PRV_CIERREY'         from dual)
select r.t, r.c from req r
 where not exists (select 1 from all_tab_columns a
                    where a.owner = sys_context('USERENV','CURRENT_SCHEMA')
                      and a.table_name = r.t and a.column_name = r.c);

prompt === 7. Campos dinamicos de VTA_PAINT_Z FACO (formula ZZZ de la Y, RY-06) en UNA sola tabla (esperado: 0 filas)
select z.vta_order_z, z.vta_cmp_asoc
  from VTA_PAINT_Z z
 where z.vta_localiz = 'FACO' and z.vta_cmp_asoc is not null
   and (select count(*) from all_tab_columns a where a.owner = sys_context('USERENV','CURRENT_SCHEMA')
          and a.table_name in ('VTA_FACOLIBVTA','VTA_FACOZZZ')
          and a.column_name = upper(trim(z.vta_cmp_asoc))) <> 1;

prompt === 8. Signos de VTA_PAINT_Z FACO (test: solo '+')
select vta_signo, count(*) from VTA_PAINT_Z where vta_localiz = 'FACO' group by vta_signo;

prompt === 9. Unicidad asumida (esperado: 0). FACO opera solo con cierre Y: la Z (VTA_FACOTERMSTAT) no se usa
select count(*) tesor_mas_de_una_fila_por_y from (select tes_fecha, tes_local, tes_terminal, tes_cierrey
  from VTA_FACOTESOR group by tes_fecha, tes_local, tes_terminal, tes_cierrey having count(*) > 1);

prompt === 10. Concepto DI (test: coddif 8 'Diferencia no Imputable')
select mov_tipomov, vta_coddif, vta_glosadif from VTA_FACOCONCEPDIF where mov_tipomov = 'DI';

prompt === 11. Secuencia de la DI (test: SEQ_VTA_FACOVEN existe)
select sequence_name from all_sequences
 where sequence_owner = sys_context('USERENV','CURRENT_SCHEMA') and sequence_name = 'SEQ_VTA_FACOVEN';

prompt === 12. Trigger que numera VTA_FACOCOMPDES (test: TRG_VTA_FACOCOMPDES_I_SEQ ENABLED)
select trigger_name, status from all_triggers
 where table_owner = sys_context('USERENV','CURRENT_SCHEMA') and table_name = 'VTA_FACOCOMPDES';

prompt === 13. NOT NULL sin default en VTA_FACOMOVDET (test: las 11 que informa el INSERT de T1)
select column_name from all_tab_columns
 where owner = sys_context('USERENV','CURRENT_SCHEMA') and table_name = 'VTA_FACOMOVDET'
   and nullable = 'N' and data_default is null order by column_id;

prompt === 14. Opcion 1515 Cerrar Terminal CC en FACO (test: 0 y 0; la crea 03c_permiso_cc.sql)
select count(*) menu_1515 from VTA_FACOMENU where mnu_codigo = 1515;
select count(*) relpermen_1515 from VTA_FACORELPERMEN where mnu_codigo = 1515;
