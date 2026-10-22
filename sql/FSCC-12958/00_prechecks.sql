-- =====================================================================
-- FSCC-12958 (HU-01-T2) Cierre de caja automatico - Falabella Colombia
-- 00 - Verificaciones previas (solo lectura). Ejecutar en el ambiente
--      destino ANTES de instalar. Resultados de referencia: test 06-10-2026.
-- =====================================================================
set linesize 200 pagesize 500 feedback on

prompt === 1. Objetos a crear no deben existir (esperado: 0 filas)
select owner, object_name, object_type from all_objects
 where owner = sys_context('USERENV','CURRENT_SCHEMA')
   and object_name in ('VTA_FACOPRD_CIERRE','SEQ_VTA_FACOPRD_CIERRE','VTA_FACOLOG_CIERRE_AUTO',
                       'SEQ_VTA_FACOLOG_CIERRE_AUTO','TRG_VTA_FACOPRD_CIERRE_AI','PKG_F8_FACO_CIERRE_AUTO',
                       'VTA_FACOV_CAJAS_CIERRE');

prompt === 2. Triggers existentes en VTA_FACOPRD (test: ninguno)
select owner, trigger_name, triggering_event, status from all_triggers where table_name = 'VTA_FACOPRD';

prompt === 3. Tipo de parametro 1502 libre, incluido CA_SIN_SOBRE (esperado: 0)
select count(*) from VTA_FACOPARAM where vta_ccodtipo = 1502;

prompt === 4. Formato numerico de Colombia (test: VTA_NUMFORMAT '#,#0' => CA_DECIMAL 0)
select vta_localiz, vta_numformat, vta_decround from VTA_PARAMETROS where vta_localiz = 'FACO';

prompt === 5. Columnas usadas por el paquete (esperado: 0 filas = todas existen)
with req as (
  select 'VTA_FACOLIBVTA' t, 'VTA_SECUENCIA' c from dual union all
  select 'VTA_FACOZZZ', 'REC_MSODIMAC'   from dual union all
  select 'VTA_FACOZZZ', 'REC_MTARJ'      from dual union all
  select 'VTA_FACOTESOR', 'TES_CIERREY'  from dual union all
  select 'VTA_FACOTARJ', 'VTA_CIERREY'   from dual union all
  select 'VTA_FACORECMEX', 'MEX_CIERREY' from dual union all
  select 'VTA_FACORECMEX', 'MEX_CANTIDAD' from dual union all
  select 'VTA_FACODIFVEND', 'VEN_CIERREY' from dual union all
  select 'VTA_FACOCARTAAVISO', 'MOV_CIERREY' from dual union all
  select 'VTA_FACOMOVDET', 'MOV_SECUENCIA' from dual union all
  select 'VTA_FACOCHEQUES', 'CHQ_TIPOCHEQUE' from dual union all
  select 'VTA_FACOPRD', 'PRV_COD_RECAUD' from dual union all
  select 'VTA_FACOPRD', 'PRV_CIERREY'    from dual)
select r.t, r.c from req r
 where not exists (select 1 from all_tab_columns a
                    where a.owner = sys_context('USERENV','CURRENT_SCHEMA') and a.table_name = r.t and a.column_name = r.c);

prompt === 6. Campos dinamicos de VTA_PAINT_Z FACO (formula ZZZ de la Y, RY-06): cada uno en UNA tabla (esperado: 0 filas)
select z.vta_order_z, z.vta_cmp_asoc,
       (select count(*) from all_tab_columns a where a.owner = sys_context('USERENV','CURRENT_SCHEMA')
          and a.table_name in ('VTA_FACOLIBVTA','VTA_FACOZZZ')
          and a.column_name = upper(trim(z.vta_cmp_asoc))) ocurrencias
  from VTA_PAINT_Z z
 where z.vta_localiz = 'FACO' and z.vta_cmp_asoc is not null
   and (select count(*) from all_tab_columns a where a.owner = sys_context('USERENV','CURRENT_SCHEMA')
          and a.table_name in ('VTA_FACOLIBVTA','VTA_FACOZZZ')
          and a.column_name = upper(trim(z.vta_cmp_asoc))) <> 1;

prompt === 7. Signos de VTA_PAINT_Z FACO (test: solo '+')
select vta_signo, count(*) from VTA_PAINT_Z where vta_localiz = 'FACO' group by vta_signo;

prompt === 8. Unicidad asumida (esperado: 0). FACO opera solo con cierre Y: la Z (VTA_FACOTERMSTAT) no se usa
select count(*) tesor_mas_de_una_fila_por_y from (select tes_fecha, tes_local, tes_terminal, tes_cierrey
  from VTA_FACOTESOR group by tes_fecha, tes_local, tes_terminal, tes_cierrey having count(*) > 1);

prompt === 9. Opcion 1515 Cerrar Terminal CC en FACO (test: 0 y 0; la crea 03c_permiso_cc.sql)
select count(*) menu_1515 from VTA_FACOMENU where mnu_codigo = 1515;
select count(*) relpermen_1515 from VTA_FACORELPERMEN where mnu_codigo = 1515;
