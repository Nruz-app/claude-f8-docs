-- =====================================================================
-- FSCC-12901 PROC_YZ (v2 multipais + cierre Z) - Paso 00
-- Verificaciones previas (solo lectura), pais FACO. Conectado como el duenio
-- de las tablas VTA_FACO*. Cada consulta indica el resultado esperado
-- (referencia: base de test 06-10-2026). Sin SET/PROMPT: sirve en DBeaver.
-- =====================================================================

-- === 0. Paquetes genericos v2: no deben existir (esperado: 0 filas en el esquema;
--        si aparecen en otro esquema como sinonimo, revisar el nombre)
select owner, object_name, object_type from all_objects
 where object_name in ('PKG_F8_CIERRE_AUTO', 'PKG_F8_COMPENSA_DI_AUTO');

-- === 1. Objetos por pais (FACO). Si v1 ya esta instalado aparecen las 5
--        primeras filas (cola, log, secuencias y trigger): en ese caso NO usar
--        INSTALAR.sql sino MIGRAR_DESDE_V1.sql.
select object_name, object_type, status from all_objects
 where owner = sys_context('USERENV','CURRENT_SCHEMA')
   and object_name in ('VTA_FACOPRD_CIERRE', 'SEQ_VTA_FACOPRD_CIERRE',
                       'VTA_FACOLOG_CIERRE_AUTO', 'SEQ_VTA_FACOLOG_CIERRE_AUTO',
                       'TRG_VTA_FACOPRD_CIERRE_AI',
                       'PKG_F8_FACO_CIERRE_AUTO', 'PKG_F8_FACO_COMPENSA_DI',
                       'VTA_FACOV_CAJAS_CIERRE')
 order by object_type, object_name;

-- === 1b. DBMS_SQL disponible para el duenio (lo usa PKG_F8_CIERRE_AUTO; esperado: 1 fila)
select owner, object_name, object_type from all_objects
 where object_name = 'DBMS_SQL' and object_type = 'PACKAGE';

-- === 2. Triggers existentes en VTA_FACOPRD (test: ninguno)
select owner, trigger_name, triggering_event, status from all_triggers where table_name = 'VTA_FACOPRD';

-- === 3. Parametros 1502 libres, incluido CA_SIN_SOBRE (esperado: 0)
select count(*) from VTA_FACOPARAM where vta_ccodtipo = 1502;

-- === 4. Rango DI manual vigente (test: 1500 DI = -500, 1501 DI = 20000; NO se modifica)
select vta_ccodtipo, vta_ccodigo, vta_xglosa from VTA_FACOPARAM where vta_ccodtipo in (1500, 1501);

-- === 5. Formato numerico de Colombia (test: '#,#0' => CA_DECIMAL 0)
select vta_localiz, vta_numformat, vta_decround from VTA_PARAMETROS where vta_localiz = 'FACO';

-- === 6. Columnas usadas por los paquetes (esperado: 0 filas = todas existen)
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

-- === 7. Campos dinamicos de VTA_PAINT_Z FACO (formula ZZZ de la Y, RY-06) en UNA sola tabla (esperado: 0 filas)
select z.vta_order_z, z.vta_cmp_asoc
  from VTA_PAINT_Z z
 where z.vta_localiz = 'FACO' and z.vta_cmp_asoc is not null
   and (select count(*) from all_tab_columns a where a.owner = sys_context('USERENV','CURRENT_SCHEMA')
          and a.table_name in ('VTA_FACOLIBVTA','VTA_FACOZZZ')
          and a.column_name = upper(trim(z.vta_cmp_asoc))) <> 1;

-- === 8. Signos de VTA_PAINT_Z FACO (test: solo '+')
select vta_signo, count(*) from VTA_PAINT_Z where vta_localiz = 'FACO' group by vta_signo;

-- === 9. Unicidad asumida (esperado: 0)
select count(*) tesor_mas_de_una_fila_por_y from (select tes_fecha, tes_local, tes_terminal, tes_cierrey
  from VTA_FACOTESOR group by tes_fecha, tes_local, tes_terminal, tes_cierrey having count(*) > 1);

-- === 10. Concepto DI (test: coddif 8 'Diferencia no Imputable')
select mov_tipomov, vta_coddif, vta_glosadif from VTA_FACOCONCEPDIF where mov_tipomov = 'DI';

-- === 11. Secuencia de la DI (test: SEQ_VTA_FACOVEN existe)
select sequence_name from all_sequences
 where sequence_owner = sys_context('USERENV','CURRENT_SCHEMA') and sequence_name = 'SEQ_VTA_FACOVEN';

-- === 12. Trigger que numera VTA_FACOCOMPDES (test: TRG_VTA_FACOCOMPDES_I_SEQ ENABLED)
select trigger_name, status from all_triggers
 where table_owner = sys_context('USERENV','CURRENT_SCHEMA') and table_name = 'VTA_FACOCOMPDES';

-- === 13. NOT NULL sin default en VTA_FACOMOVDET (test: las 11 que informa el INSERT de T1)
select column_name from all_tab_columns
 where owner = sys_context('USERENV','CURRENT_SCHEMA') and table_name = 'VTA_FACOMOVDET'
   and nullable = 'N' and data_default is null order by column_id;

-- === 14. Opcion 1515 Cerrar Terminal CC en FACO (test: 0 y 0; la crea 03c_permiso_FACO.sql)
select count(*) menu_1515 from VTA_FACOMENU where mnu_codigo = 1515;
select count(*) relpermen_1515 from VTA_FACORELPERMEN where mnu_codigo = 1515;

-- =====================================================================
-- PROC_YZ: verificaciones del cierre de la Z (VTA_FACOTERMSTAT)
-- =====================================================================

-- === 15. Columnas que usa el cierre de la Z (esperado: 0 filas = todas existen)
with req as (
  select 'VTA_FACOTERMSTAT' t, 'TER_ESTADO' c from dual union all
  select 'VTA_FACOTERMSTAT', 'TER_NOTAS'      from dual union all
  select 'VTA_FACOTERMSTAT', 'TER_CERRADOPOR' from dual union all
  select 'VTA_PAINT_Z', 'VTAGLOSA_Z'          from dual union all
  select 'VTA_PAINT_Z', 'VTA_POP_UP'          from dual union all
  select 'VTA_PAINT_Z', 'VTA_ORDER_Z'         from dual)
select r.t, r.c from req r
 where not exists (select 1 from all_tab_columns a
                    where a.table_name = r.t and a.column_name = r.c);

-- === 16. Largo de TER_NOTAS y TER_CERRADOPOR en la Z (la nota se corta al largo
--         de TER_NOTAS; TER_CERRADOPOR debe admitir 'PROC_CIERRE_AUTO' = 16)
select column_name, data_type, data_length from all_tab_columns
 where owner = sys_context('USERENV','CURRENT_SCHEMA') and table_name = 'VTA_FACOTERMSTAT'
   and column_name in ('TER_NOTAS', 'TER_CERRADOPOR');

-- === 17. Campos de VTA_PAINT_Z para Z = suma de las Y (RZ-06): cada campo debe existir
--         en UNA sola tabla del cruce Z (LIBVTA, ZZZ, TERMSTAT) y del cruce Y
--         (LIBVTA, ZZZ, TERMSTATY). Esperado: 0 filas.
select z.vta_order_z, z.vta_cmp_asoc, 'Z' cruce
  from VTA_PAINT_Z z
 where z.vta_localiz = 'FACO' and nvl(z.vta_pop_up, 0) = 0 and z.vta_cmp_asoc is not null
   and (z.vta_order_z < 56 or z.vta_order_z > 76)
   and (select count(*) from all_tab_columns a where a.owner = sys_context('USERENV','CURRENT_SCHEMA')
          and a.table_name in ('VTA_FACOLIBVTA','VTA_FACOZZZ','VTA_FACOTERMSTAT')
          and a.column_name = upper(trim(z.vta_cmp_asoc))) <> 1
union all
select z.vta_order_z, z.vta_cmp_asoc, 'Y'
  from VTA_PAINT_Z z
 where z.vta_localiz = 'FACO' and nvl(z.vta_pop_up, 0) = 0 and z.vta_cmp_asoc is not null
   and (z.vta_order_z < 56 or z.vta_order_z > 76)
   and (select count(*) from all_tab_columns a where a.owner = sys_context('USERENV','CURRENT_SCHEMA')
          and a.table_name in ('VTA_FACOLIBVTA','VTA_FACOZZZ','VTA_FACOTERMSTATY')
          and a.column_name = upper(trim(z.vta_cmp_asoc))) <> 1;

-- === 18. Una sola Z por terminal-dia (esperado: 0)
select count(*) z_repetidas from (select ter_fecha, ter_local, ter_terminal
  from VTA_FACOTERMSTAT group by ter_fecha, ter_local, ter_terminal having count(*) > 1);

-- === 19. (Informativo) Uso real de la Z en los ultimos 6 meses: si hay estado 1
--         con usuarios reales, en FACO se cierra la Z hoy.
select t.ter_estado, nvl(t.ter_cerradopor, '(nulo)') cerradopor, count(*) cantidad,
       min(t.ter_fecha) desde, max(t.ter_fecha) hasta
  from VTA_FACOTERMSTAT t
 where t.ter_fecha >= add_months(trunc(sysdate), -6)
 group by t.ter_estado, nvl(t.ter_cerradopor, '(nulo)')
 order by 3 desc;

-- === 20. (Informativo) Libro de ventas de la Z ('F8') y de las Y en los ultimos 6
--         meses: sin filas 'F8' la Z nunca podra cerrarse (Z_SIN_LIBVTA).
select l.vta_tiporeg, count(*) cantidad, min(l.vta_fecha_venta) desde, max(l.vta_fecha_venta) hasta
  from VTA_FACOLIBVTA l
 where l.vta_fecha_venta >= add_months(trunc(sysdate), -6)
 group by l.vta_tiporeg order by 1;
