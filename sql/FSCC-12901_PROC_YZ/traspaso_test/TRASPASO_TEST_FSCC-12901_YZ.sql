-- =====================================================================
-- FSCC-12901 PROC_YZ - TRASPASO A TEST (archivo unico)
-- Cierre automatico de cajas Y y Z (T2) y compensacion automatica de DI
-- (T1), Falabella Colombia (FACO). La Z queda APAGADA (CA_CIERRA_Z = N).
-- Generado: 15-10-2026 desde docs/sql/FSCC-12901_PROC_YZ (scripts 00 a 09),
-- a partir del traspaso de PROC_Y (14-10-2026): cambian las PARTES 0, 1c,
-- 2a y 2d; el resto es identico.
-- SI PROC_Y YA ESTA INSTALADO EN TEST: NO usar este archivo, sino
-- ../ACTUALIZAR_DESDE_PROC_Y.sql (agrega 4 parametros y recompila).
--
-- DONDE Y COMO EJECUTAR
--   Base   : test, sgfnprds (requiere VPN).
--   Usuario: conectado como el DUENIO de las tablas VTA_* (INTRANETTS).
--            UINTRANETTS no tiene CREATE: no sirve para instalar.
--   SQL*Plus: sqlplus INTRANETTS@<alias_test> @TRASPASO_TEST_FSCC-12901_YZ.sql
--   DBeaver : abrir el archivo y ejecutar como script (Alt+X).
--   La PARTE 5B (sinonimos) requiere CREATE ANY SYNONYM (DBA).
--   La PARTE 6 (job) esta comentada; se activa aparte cuando se defina.
--
-- REQUISITO: base SIN ninguna version previa de FSCC-12901 (al 14-10-2026
-- test no tiene objetos de FSCC-12901). La PARTE 0 lo verifica: si las
-- consultas 0 y 1 devuelven filas, NO continuar.
--
-- OBJETOS QUE CREA
--   Tablas    : VTA_FACOPRD_CIERRE (cola), VTA_FACOLOG_CIERRE_AUTO (log)
--   Indices   : PK_VTA_FACOPRD_CIERRE, IND_VTA_FACOPRD_CIERRE_01/_02,
--               PK_VTA_FACOLOG_CIERRE_AUTO, IND_VTA_FACOLOG_CIERRE_AUTO_01/_02
--   Check     : CK_VTA_FACOPRD_CIERRE_EST
--   Secuencias: SEQ_VTA_FACOPRD_CIERRE, SEQ_VTA_FACOLOG_CIERRE_AUTO
--   Paquetes  : PKG_F8_CIERRE_AUTO, PKG_F8_COMPENSA_DI_AUTO (spec + body)
--   Trigger   : TRG_VTA_FACOPRD_CIERRE_AI (after insert on VTA_FACOPRD)
-- DATOS QUE INSERTA
--   VTA_FACOPARAM     : tipo 1502 (12 parametros CA_*; CA_CIERRA_Z = N)
--   VTA_FACOMENU      : opcion 1515 (Cerrar Terminal desde Consulta Cuadratura)
--   VTA_FACORELPERMEN : 1515 para todos los perfiles; habilitada (-1) en 7 y 9
-- PERMISOS (PARTE 5): grants y sinonimos para UINTRANETTS.
-- USA (deben existir, los revisa la PARTE 0): VTA_FACOPRD, VTA_FACOLIBVTA,
--   VTA_FACOZZZ, VTA_FACOTERMSTATY, VTA_FACOTERMSTAT, VTA_FACOTESOR, VTA_FACOTARJ, VTA_FACORECMEX,
--   VTA_FACODIFVEND, VTA_FACOCARTAAVISO, VTA_FACOMOVDET, VTA_FACOCOMPDES,
--   VTA_FACOCHEQUES, VTA_FACOCONCEPDIF, VTA_PAINT_Z, SEQ_VTA_FACOVEN, DBMS_SQL.
--
-- ORDEN: 0 prechecks -> 1 objetos FACO -> 2 paquetes -> 3 trigger (al final,
-- para que la cola reciba sobres solo con los paquetes ya compilados)
-- -> 4 validacion -> 5 permisos -> 6 job (opcional).
-- Vuelta atras: ROLLBACK_TEST_FSCC-12901_YZ.sql (misma carpeta).
-- Convenciones: ASCII, sin prefijo de esquema, Oracle 10.2.
-- =====================================================================
set define off
set serveroutput on
set echo on feedback on
-- Solo SQL*Plus: detener al primer error (en DBeaver dejarlo comentado).
-- whenever sqlerror exit failure rollback

-- #####################################################################
-- ## PARTE 0: VERIFICACIONES PREVIAS (solo lectura; revisar lo esperado)
-- ## Fuente: docs/sql/FSCC-12901_PROC_YZ/00_prechecks.sql (PROC_YZ: incluye la Z)
-- #####################################################################
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

-- #####################################################################
-- ## PARTE 1a: COLA VTA_FACOPRD_CIERRE + SEQ_VTA_FACOPRD_CIERRE
-- ## Fuente: docs/sql/FSCC-12901_PROC_YZ/01_cola_FACO.sql (copia sin cambios, igual a PROC_Y)
-- #####################################################################
-- =====================================================================
-- FSCC-12901 v2 MULTIPAIS - Paso 01 (objeto POR PAIS: FACO)
-- Cola VTA_FACOPRD_CIERRE (homologa de VTA_FACOPRD) + secuencia.
-- Igual que v1 salvo los estados de la cola (modo CARGA, una ejecucion por carga):
--   P pendiente  -> llego en una carga y aun no la toma el proceso
--   E en proceso -> tomada por la ejecucion pcr_ejecucion
--   C procesada  -> evaluada (pcr_resultado = ultimo resultado). Solo una
--                   carga nueva (otro sobre) vuelve a poner la caja en la cola.
--   O omitida    -> sobre sin cierre Y
-- (v1 tenia ademas V vencida por CA_DIAS; en v2 no hay ventana de dias.)
--
-- OTRO PAIS: copiar el script reemplazando FACO por su prefijo (Flg_Pais$);
-- con prefijo vacio (Chile) los nombres quedan VTA_PRD_CIERRE, SEQ_VTA_PRD_CIERRE...
-- Esquema: duenio de las tablas VTA_FACO* (objetos sin prefijo) | Oracle 10.2
-- Si v1 ya esta instalado NO ejecutar: usar MIGRAR_DESDE_V1.sql.
-- =====================================================================

-- Los tipos de las columnas PRV_* se heredan de VTA_FACOPRD (CTAS vacio).
-- Verificado en test (06-10-2026): PRV_CIERREY NUMBER(2) NOT NULL DEFAULT 0
-- (0 = sobre sin Y); PRV_COD_RECAUD VARCHAR2(20).
create table VTA_FACOPRD_CIERRE as
select p.prv_techkey,
       p.prv_fechavta,
       p.prv_local,
       p.prv_terminal,
       p.prv_cierrey,
       p.prv_tiporec,
       p.prv_tiposobre,
       p.prv_sobre,
       p.prv_montosobre,
       p.prv_montodif,
       p.prv_fechadep,
       p.prv_cod_recaud
from   VTA_FACOPRD p
where  1 = 0;

-- Columnas de control del proceso
alter table VTA_FACOPRD_CIERRE add (
  pcr_id         number         not null,          -- SEQ_VTA_FACOPRD_CIERRE
  pcr_fechareg   date           default sysdate not null,
  pcr_estado     varchar2(1)    default 'P' not null,   -- P / E / C / O
  pcr_ejecucion  number,                           -- ejecucion que la tomo / evaluo
  pcr_fechaproc  date,                             -- fecha/hora de la ultima evaluacion
  pcr_resultado  varchar2(30),                     -- ultimo resultado (ver log)
  pcr_mensaje    varchar2(1000),                   -- ultimo mensaje
  pcr_intentos   number         default 0 not null -- veces evaluada
);

alter table VTA_FACOPRD_CIERRE
  add constraint PK_VTA_FACOPRD_CIERRE primary key (pcr_id);

alter table VTA_FACOPRD_CIERRE
  add constraint CK_VTA_FACOPRD_CIERRE_EST check (pcr_estado in ('P','E','C','O'));

create index IND_VTA_FACOPRD_CIERRE_01
  on VTA_FACOPRD_CIERRE (pcr_estado, pcr_ejecucion);

create index IND_VTA_FACOPRD_CIERRE_02
  on VTA_FACOPRD_CIERRE (prv_fechavta, prv_local, prv_terminal, prv_cierrey);

create sequence SEQ_VTA_FACOPRD_CIERRE
  start with 1 increment by 1 nocache nocycle;

comment on table  VTA_FACOPRD_CIERRE is 'FSCC-12901 Cola de sobres F8 Colombia para cierre automatico de cajas (homologa de VTA_FACOPRD)';
comment on column VTA_FACOPRD_CIERRE.pcr_estado is 'P pendiente, E en proceso, C procesada, O omitida (sin cierre Y)';

-- #####################################################################
-- ## PARTE 1b: LOG VTA_FACOLOG_CIERRE_AUTO + SEQ_VTA_FACOLOG_CIERRE_AUTO
-- ## Fuente: docs/sql/FSCC-12901_PROC_YZ/02_log_FACO.sql (copia sin cambios, igual a PROC_Y)
-- #####################################################################
-- =====================================================================
-- FSCC-12901 v2 MULTIPAIS - Paso 02 (objeto POR PAIS: FACO)
-- Registro de ejecucion VTA_FACOLOG_CIERRE_AUTO + secuencia (igual que v1).
-- Los paquetes genericos escriben en VTA_<pfx>LOG_CIERRE_AUTO y numeran la
-- ejecucion con SEQ_VTA_<pfx>LOG_CIERRE_AUTO.
-- OTRO PAIS: copiar reemplazando FACO por su prefijo.
-- Si v1 ya esta instalado NO ejecutar: usar MIGRAR_DESDE_V1.sql.
-- =====================================================================

create table VTA_FACOLOG_CIERRE_AUTO (
  log_id         number          not null,   -- SEQ_VTA_FACOLOG_CIERRE_AUTO
  log_ejecucion  number          not null,   -- mismo valor para toda la corrida
  log_proceso    varchar2(2)     default 'T2' not null,  -- T1 compensacion DI / T2 cierre / CC cierre desde Form43
  log_nivel      varchar2(1)     not null,   -- Y = cierre Y, - = proceso
  log_fecha_vta  date,
  log_local      number,
  log_terminal   number,
  log_cierrey    number,                     -- numero de cierre Y (null en nivel -)
  log_dif_real   number,                     -- diferencia real calculada
  log_resultado  varchar2(30)    not null,
        -- CERRADA_Y, CON_DIFERENCIA, BLOQUEADA, YA_CERRADA,
        -- SIN_LIBVTA, SIN_TERMSTAT, OCUPADA, ERROR, INACTIVO, INICIO, FIN
        -- T1: DI_REGISTRADA, DR_CERO, FUERA_RANGO, DI_AUTO_PREVIA,
        --     DI_MANUAL_PREVIA (ademas SIN_LIBVTA, YA_CERRADA, OCUPADA, ERROR, INACTIVO)
  log_regla      varchar2(10),               -- RY-01..RY-06
  log_mensaje    varchar2(1000),
  log_usuario    varchar2(50),
  log_fechahora  date            default sysdate not null,
  constraint PK_VTA_FACOLOG_CIERRE_AUTO primary key (log_id)
);

create index IND_VTA_FACOLOG_CIERRE_AUTO_01
  on VTA_FACOLOG_CIERRE_AUTO (log_ejecucion);

create index IND_VTA_FACOLOG_CIERRE_AUTO_02
  on VTA_FACOLOG_CIERRE_AUTO (log_fecha_vta, log_local, log_terminal);

create sequence SEQ_VTA_FACOLOG_CIERRE_AUTO
  start with 1 increment by 1 nocache nocycle;

comment on table VTA_FACOLOG_CIERRE_AUTO is 'FSCC-12901 Registro de ejecucion del cierre automatico de cajas F8 Colombia';

-- #####################################################################
-- ## PARTE 1c: PARAMETROS 1502 EN VTA_FACOPARAM
-- ## Fuente: docs/sql/FSCC-12901_PROC_YZ/03_parametros_FACO.sql (PROC_YZ: incluye la Z)
-- #####################################################################
-- =====================================================================
-- FSCC-12901 PROC_YZ (v2 multipais + cierre Z) - Paso 03 (objeto POR PAIS: FACO)
-- Parametros de T1 y T2 en VTA_FACOPARAM (tipo 1502). Se leen en cada
-- ejecucion con PKG_F8_CIERRE_AUTO.fn_param('FACO', codigo, default).
-- Cambio frente a v1: SIN CA_DIAS. Colombia procesa solo la carga del dia
-- (una ejecucion por carga); la ventana de dias es del modelo de Chile.
-- El rango de la DI manual (1500/1501 'DI', -500 / 20000) NO se toca.
-- OTRO PAIS: los mismos codigos en VTA_<pfx>PARAM (Chile: VTA_PARAM).
-- PROC_YZ: 4 parametros nuevos de la Z (12 en total). Si PROC_Y ya esta
-- instalado NO ejecutar este script: usar ACTUALIZAR_DESDE_PROC_Y.sql.
-- =====================================================================

-- Verificar tipo 1502 libre (esperado: 0)
select count(*) from VTA_FACOPARAM where vta_ccodtipo = 1502;

-- ---- T1: compensacion automatica de DI (FSCC-12957) ----
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_DI_ACTIVO', 'S',     sysdate);  -- S/N T1 activa (switch del negocio)
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_DI_MIN',    '-1000', sysdate);  -- limite inferior DR (inclusive)
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_DI_MAX',    '20000', sysdate);  -- limite superior DR (inclusive)

-- ---- T2: cierre de caja automatico (FSCC-12958) ----
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_ACTIVO',    'S',     sysdate);  -- S/N T2 activa (switch del negocio)
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_VAL_CHEQ',  'S',     sysdate);  -- S/N cheque a fecha (RY-01)
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_VAL_ZZZ',   'N',     sysdate);  -- S/N formula ZZZ (RY-06, opcion 103)

-- ---- Comunes ----
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_DECIMAL',   '0',     sysdate);  -- decimales: gFormat FACO '#,#0'
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_SIN_SOBRE', 'S',     sysdate);  -- S/N incluir cajas sin sobres del mismo local-dia (DF fila 12)

-- ---- PROC_YZ: cierre de la Z (Form3.CierraTerminal) ----
-- Apagado hasta que negocio confirme que la Z va: con CA_CIERRA_Z = N el
-- proceso se comporta igual que PROC_Y. Para activar:
--   update VTA_FACOPARAM set vta_xglosa = 'S'
--    where vta_ccodtipo = 1502 and vta_ccodigo = 'CA_CIERRA_Z'; commit;
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_CIERRA_Z',   'N',    sysdate);  -- S/N cerrar la Z despues de las Y (switch del negocio)
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_Z_SIN_Y',    'N',    sysdate);  -- S/N cerrar la Z de un terminal sin ninguna Y (exe: S, D2)
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_Z_VAL_SUMA', 'S',    sysdate);  -- S/N Z = suma de las Y por campo de VTA_PAINT_Z (RZ-06)
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_Z_VAL_DOL',  'N',    sysdate);  -- S/N dolares declarados = transportadora (RZ-09, opcion 109)
-- La Z reutiliza CA_VAL_CHEQ (RZ-01) y CA_VAL_ZZZ (RZ-08).
commit;

select vta_ccodigo, vta_xglosa from VTA_FACOPARAM where vta_ccodtipo = 1502 order by 1;

-- #####################################################################
-- ## PARTE 1d: OPCION 1515 CERRAR TERMINAL (Form43 FACO)
-- ## Fuente: docs/sql/FSCC-12901_PROC_YZ/03c_permiso_FACO.sql (copia sin cambios, igual a PROC_Y)
-- #####################################################################
-- =====================================================================
-- FSCC-12901 v2 MULTIPAIS - Paso 03c (objeto POR PAIS: FACO)
-- Opcion 1515 Cerrar Terminal desde Consultas de Cuadratura (Form43 FACO).
-- Identico a v1 (FSCC-12901_T1_T2/03c_permiso_cc.sql); idempotente.
-- OTRO PAIS: VTA_<pfx>MENU / VTA_<pfx>RELPERMEN / VTA_<pfx>PERFILES.
-- =====================================================================

insert into VTA_FACOMENU (mnu_codigo, mnu_descripcion, mnu_tipomenu, mnu_habilitar)
select 1515, 'Cerrar Terminal desde Consulta Cuadratura', 'opcion', 1
  from dual
 where not exists (select 1 from VTA_FACOMENU m where m.mnu_codigo = 1515);

insert into VTA_FACORELPERMEN (per_codigo, mnu_codigo, rel_estado)
select p.per_codigo, 1515, 0
  from VTA_FACOPERFILES p
 where not exists (select 1 from VTA_FACORELPERMEN r
                    where r.per_codigo = p.per_codigo and r.mnu_codigo = 1515);
commit;

-- Habilitar para los perfiles que defina negocio (-1 = habilitado).
-- Ejemplo (perfiles de test: 7 Tesoreria Analista, 9 Administrador):
-- update VTA_FACORELPERMEN set rel_estado = -1 where mnu_codigo = 1515 and per_codigo in (7, 9);
-- commit;

select r.per_codigo, r.rel_estado from VTA_FACORELPERMEN r where r.mnu_codigo = 1515 order by 1;

-- Traspaso a test: habilitar 1515 para 7 Tesoreria Analista y 9 Administrador
update VTA_FACORELPERMEN set rel_estado = -1 where mnu_codigo = 1515 and per_codigo in (7, 9);
commit;
select r.per_codigo, r.rel_estado from VTA_FACORELPERMEN r where r.mnu_codigo = 1515 order by 1;

-- #####################################################################
-- ## PARTE 2a: ESPECIFICACION PKG_F8_CIERRE_AUTO
-- ## Fuente: docs/sql/FSCC-12901_PROC_YZ/04_pkg_cierre_auto_spec.sql (PROC_YZ: incluye la Z)
-- #####################################################################
-- =====================================================================
-- FSCC-12901 PROC_YZ (v2 multipais + cierre Z) - Paso 04
-- Especificacion de PKG_F8_CIERRE_AUTO (T2 cierre automatico + utilitarios
-- comunes que usa T1 PKG_F8_COMPENSA_DI_AUTO).
--
-- v2 (13-10-2026): version multipais de PKG_F8_FACO_CIERRE_AUTO (v1).
--   * Todas las rutinas publicas reciben primero P_FLG_PAIS, el mismo valor
--     que Flg_Pais$ del exe (prefijo de tablas VTA_<pfx>...).
--   * Las tablas se arman en tiempo de ejecucion: 'VTA_' || prefijo || 'X'
--     (igual que "vta_" + Flg_Pais "x" en el exe VB6), con SQL dinamico y binds.
--   * Cada pais tiene su configuracion (prefijo, nivel de cierre, rango de
--     tarjetas, moneda dolar, modo del universo...) en PR_CONFIG del cuerpo.
--     Hoy solo esta habilitado FACO (Falabella Colombia) con la MISMA logica
--     de v1. Otro pais -> ORA-20001 'Pais no habilitado'.
--   * Universo FACO = "carga del dia": cada ejecucion toma la cola pendiente
--     (una ejecucion por carga); sin ventana de dias (CA_DIAS es del modelo
--     de Chile, ver ejemplo comentado en PR_CONFIG).
--
-- Replica la logica de cierre del exe F8 (VB6):
--   * cierre Y : Form3Y.CierraTerminal  (FTEPROD/Form3Y.frm:2801)
--   * diferencia real: FormateaDatos (Label70) + Modulo1.StrSumCompensado
--   * cierre Z : Form3.CierraTerminal   (FTEPROD/Form3.frm:3439)   [PROC_YZ]
--
-- PROC_YZ (15-10-2026): agrega el cierre de la Z (VTA_<pfx>TERMSTAT).
-- Apagado por defecto: parametro 1502 CA_CIERRA_Z = N -> la Z no se toca y
-- el paquete se comporta igual que PROC_Y. Con S, despues de las Y se
-- intenta cerrar la Z de cada terminal-dia evaluado (requisito: todas sus Y
-- cerradas). En las funciones de cuadratura, p_cierrey NULL = la Z.
-- =====================================================================

create or replace package PKG_F8_CIERRE_AUTO as

  c_usuario_def  constant varchar2(30) := 'PROC_CIERRE_AUTO';
  c_tipo_param   constant number       := 1502;

  -- ---------------------------------------------------------------
  -- Configuracion / utilitarios multipais
  -- ---------------------------------------------------------------

  -- Nombre real de una tabla del pais: fn_tabla('FACO', 'TERMSTATY') = 'VTA_FACOTERMSTATY'.
  -- Error ORA-20001 si el pais no esta habilitado.
  function fn_tabla (p_flg_pais in varchar2,
                     p_base     in varchar2) return varchar2;

  -- Texto SQL con las marcas del pais reemplazadas ({P} prefijo, {NIVEL},
  -- {TMIN}, {TMAX}, {USD}, {SEQMOV}). Lo usa T1 para su SQL dinamico.
  function fn_sql (p_flg_pais in varchar2,
                   p_sql      in varchar2) return varchar2;

  -- Lee un parametro de VTA_<pfx>PARAM tipo 1502 (CA_ACTIVO, CA_DI_ACTIVO,
  -- CA_DI_MIN, CA_DI_MAX, CA_VAL_CHEQ, CA_VAL_ZZZ, CA_DECIMAL, CA_SIN_SOBRE;
  -- Z: CA_CIERRA_Z, CA_Z_SIN_Y, CA_Z_VAL_SUMA, CA_Z_VAL_DOL;
  -- CA_DIAS solo en paises con modo DIAS). Devuelve p_default si no existe.
  function fn_param (p_flg_pais in varchar2,
                     p_codigo   in varchar2,
                     p_default  in varchar2) return varchar2;

  -- Registro en VTA_<pfx>LOG_CIERRE_AUTO (transaccion autonoma).
  -- Lo usan T1 (p_proceso 'T1') y T2 ('T2' / 'CC').
  procedure pr_registra_log (p_flg_pais  in varchar2,
                             p_ejecucion in number,
                             p_proceso   in varchar2,
                             p_nivel     in varchar2,
                             p_fecha     in date,
                             p_local     in number,
                             p_terminal  in number,
                             p_cierrey   in number,
                             p_dif_real  in number,
                             p_resultado in varchar2,
                             p_regla     in varchar2,
                             p_mensaje   in varchar2,
                             p_usuario   in varchar2);

  -- Numero nuevo de ejecucion (SEQ_VTA_<pfx>LOG_CIERRE_AUTO).
  function fn_nueva_ejecucion (p_flg_pais in varchar2) return number;

  -- Universo de cierres Y de una ejecucion (columnas: fecha, local, terminal, cierrey):
  --   p_ejecucion no nulo: cajas de la carga tomada por esa ejecucion (cola en
  --                        estado E) + cajas sin sobre del mismo local-dia
  --                        (CA_SIN_SOBRE = S, con libro de ventas de la Y).
  --   p_ejecucion nulo   : lo mismo sobre la cola pendiente (estado P), sin
  --                        tomarla (uso de T1 independiente / simulacion).
  function fn_universo (p_flg_pais  in varchar2,
                        p_ejecucion in number) return sys_refcursor;

  -- ---------------------------------------------------------------
  -- Cuadratura (Form3Y Label70 / Form43)
  -- ---------------------------------------------------------------

  -- Diferencia Real de un cierre Y. NULL si no hay libro de ventas de la Y.
  -- PROC_YZ: p_cierrey NULL = Diferencia Real de la Z (dia completo, Form3
  -- Label70); NULL si no hay libro de ventas 'F8'. Igual en fn_dif_caja y
  -- fn_compensado.
  function fn_dif_real (p_flg_pais in varchar2,
                        p_fecha    in date,
                        p_local    in number,
                        p_terminal in number,
                        p_cierrey  in number) return number;

  -- Columnas "Dif. de Caja" y "Compensacion" de Consultas de Cuadratura (Form43).
  -- fn_dif_real = round(fn_dif_caja - round(fn_compensado)).
  function fn_dif_caja (p_flg_pais in varchar2,
                        p_fecha    in date,
                        p_local    in number,
                        p_terminal in number,
                        p_cierrey  in number) return number;

  function fn_compensado (p_flg_pais in varchar2,
                          p_fecha    in date,
                          p_local    in number,
                          p_terminal in number,
                          p_cierrey  in number) return number;

  -- ---------------------------------------------------------------
  -- Validaciones individuales del cierre Y
  -- ---------------------------------------------------------------

  -- RY-01 Cheque a fecha: gestion de cheques tipo 1 vs tesoreria (dia completo).
  function fn_msg_cheque_fecha (p_flg_pais in varchar2,
                                p_fecha    in date,
                                p_local    in number,
                                p_terminal in number) return varchar2;

  -- RY-03 TRUE si existe un concepto p_tipo (SN, AF, ND, FN, NP, BF, CR, CT,
  -- CA, DP) sin regularizar en la Y. CA se busca en VTA_<pfx>CARTAAVISO.
  -- PROC_YZ: p_cierrey NULL = en todo el dia (RZ-03).
  function fn_concepto_pendiente (p_flg_pais in varchar2,
                                  p_fecha    in date,
                                  p_local    in number,
                                  p_terminal in number,
                                  p_cierrey  in number,
                                  p_tipo     in varchar2) return boolean;

  -- RY-06 Formula ZZZ de la Y: F7 - F6 - F5 - F4 - F3 - F2 - F1 (0 = cuadra).
  -- PROC_YZ: p_cierrey NULL = formula de la Z (RZ-08, libro 'F8').
  function fn_zzz (p_flg_pais in varchar2,
                   p_fecha    in date,
                   p_local    in number,
                   p_terminal in number,
                   p_cierrey  in number) return number;

  -- Validaciones de "Cerrar Terminal" de la Y. o_regla null = todas OK.
  procedure pr_valida_y (p_flg_pais in  varchar2,
                         p_fecha    in  date,
                         p_local    in  number,
                         p_terminal in  number,
                         p_cierrey  in  number,
                         o_regla    out varchar2,
                         o_mensaje  out varchar2);

  -- ---------------------------------------------------------------
  -- PROC_YZ: validaciones individuales del cierre Z (Form3.CierraTerminal)
  -- ---------------------------------------------------------------

  -- RZ-06 Z = suma de las Y por cada campo de VTA_PAINT_Z (FuncValidarZSumaY).
  -- Devuelve el mensaje de la primera diferencia o NULL si cuadra.
  function fn_z_suma_y (p_flg_pais in varchar2,
                        p_fecha    in date,
                        p_local    in number,
                        p_terminal in number) return varchar2;

  -- RZ-09 Dolares declarados (RECMEX) vs dolares de la transportadora (PRD DOL). 0 = cuadra.
  function fn_dolares_z (p_flg_pais in varchar2,
                         p_fecha    in date,
                         p_local    in number,
                         p_terminal in number) return number;

  -- Validaciones de "Cerrar Terminal" de la Z, salvo estado (RZ-02) y
  -- diferencia real (RZ-05). Orden: RZ-07 todas las Y cerradas, RZ-01, RZ-03,
  -- RZ-06, RZ-08, RZ-09. o_regla null = todas OK.
  procedure pr_valida_z (p_flg_pais in  varchar2,
                         p_fecha    in  date,
                         p_local    in  number,
                         p_terminal in  number,
                         o_regla    out varchar2,
                         o_mensaje  out varchar2);

  -- ---------------------------------------------------------------
  -- Puntos de entrada
  -- ---------------------------------------------------------------

  -- Proceso completo de un pais (lo ejecuta el job, una vez por carga):
  --   1. toma la carga (cola P -> E con esta ejecucion);
  --   2. T1 PKG_F8_COMPENSA_DI_AUTO sobre el universo de la ejecucion;
  --   3. T2 cierra las Y con diferencia real 0 que pasan las validaciones;
  --   4. la cola de la carga queda en C (procesada) con su ultimo resultado;
  --   5. PROC_YZ: si CA_CIERRA_Z = S, intenta cerrar la Z de cada terminal-dia
  --      evaluado (con N la Z no se toca).
  -- p_max_cajas: limite opcional (lo no evaluado vuelve a P).
  procedure prc_cierre_automatico (p_flg_pais  in varchar2,
                                   p_usuario   in varchar2 default 'PROC_CIERRE_AUTO',
                                   p_max_cajas in number   default null);

  -- Cierre manual desde Consultas de Cuadratura (Form43, boton "Cerrar
  -- Terminal"), UN DIA por vez. Mismas reglas RY, sin T1 y sin depender de
  -- CA_ACTIVO. Universo: cierres Y abiertos con libro de ventas de la fecha de
  -- venta p_fecha (yyyymmdd), del local y del terminal (0 = todos).
  -- log_proceso = CC; ter_cerradopor = p_usuario (el analista).
  -- PROC_YZ: si CA_CIERRA_Z = S, despues de las Y intenta cerrar las Z abiertas
  -- del dia, local y terminal. Los contadores de salida siguen siendo de Y.
  -- (13-10-2026: reemplaza a prc_cierre_rango de v1; el DF-SCC fila 12 no pide
  --  rango de fechas y Form43 ya exigia "Seleccione Dia de Cierre de Terminal".)
  procedure prc_cierre_dia (p_flg_pais    in  varchar2,
                            p_fecha       in  varchar2,
                            p_local       in  number,
                            p_terminal    in  number,
                            p_usuario     in  varchar2,
                            o_ejecucion   out number,
                            o_cerradas    out number,
                            o_no_cerradas out number);

end PKG_F8_CIERRE_AUTO;
/

-- #####################################################################
-- ## PARTE 2b: ESPECIFICACION PKG_F8_COMPENSA_DI_AUTO
-- ## Fuente: docs/sql/FSCC-12901_PROC_YZ/05_pkg_compensa_di_spec.sql (copia sin cambios, igual a PROC_Y)
-- #####################################################################
-- =====================================================================
-- FSCC-12901 v2 MULTIPAIS - Paso 05
-- Especificacion de PKG_F8_COMPENSA_DI_AUTO (T1 compensacion automatica DI)
--
-- v2 (13-10-2026): version multipais de PKG_F8_FACO_COMPENSA_DI (v1).
-- Misma logica; todas las rutinas reciben primero P_FLG_PAIS (Flg_Pais$) y
-- las tablas se resuelven con PKG_F8_CIERRE_AUTO (configuracion del pais).
-- Nombre distinto del PKG_F8_COMPENSACION_DI existente (Chile) a proposito.
--
-- Registra en forma automatica una DI (Diferencia No Imputable) por el
-- monto de la Diferencia Real de cada cierre Y del universo de la ejecucion
-- (PKG_F8_CIERRE_AUTO.fn_universo), si CA_DI_MIN <= DR <= CA_DI_MAX y DR <> 0.
-- No cierra cajas: eso lo hace T2 (PKG_F8_CIERRE_AUTO), que llama a
-- PRC_COMPENSA_DI al inicio de PRC_CIERRE_AUTOMATICO.
--
-- Replica el registro manual de DI del exe F8 (VB6):
--   Form4 (boton DI) -> Form38.CommandAceptar_Click  (FTEPROD/Form38.frm:448)
--   Modulo1.InsertarRegistroMovDet                     (FTEPROD/Modulo1.bas:3777)
--   Form45.GrabarObs -> SubInsertarObs / SubUpdateObs  (observacion en VTA_<pfx>COMPDES)
-- =====================================================================

create or replace package PKG_F8_COMPENSA_DI_AUTO as

  c_usuario_di constant varchar2(30) := 'PROC_DI_AUTO';
  c_glosa_di   constant varchar2(60) := 'COMPENSACION AUTOMATICA DI';

  -- DI ya registradas en el cierre Y:
  --   'NINGUNA' | 'AUTO' (registrada por el usuario de proceso) | 'MANUAL'
  function fn_estado_di (p_flg_pais in varchar2,
                         p_fecha    in date,
                         p_local    in number,
                         p_terminal in number,
                         p_cierrey  in number) return varchar2;

  -- Evalua una caja SIN grabar nada (simulacion). Devuelve el resultado que
  -- obtendria el proceso: COMPENSABLE, DR_CERO, FUERA_RANGO, DI_AUTO_PREVIA,
  -- DI_MANUAL_PREVIA o SIN_LIBVTA, y la diferencia real en o_dif_real.
  function fn_evalua_caja (p_flg_pais in  varchar2,
                           p_fecha    in  date,
                           p_local    in  number,
                           p_terminal in  number,
                           p_cierrey  in  number,
                           o_dif_real out number) return varchar2;

  -- Proceso T1 completo de un pais.
  --   p_ejecucion: id de la corrida de T2: evalua la carga tomada por esa
  --                ejecucion (cola E). Si es null, T1 toma su propio numero y
  --                evalua la cola pendiente (P) sin tomarla ni marcarla.
  --   p_max_cajas: limite opcional de cajas a evaluar.
  procedure prc_compensa_di (p_flg_pais  in varchar2,
                             p_ejecucion in number   default null,
                             p_usuario   in varchar2 default 'PROC_DI_AUTO',
                             p_max_cajas in number   default null);

end PKG_F8_COMPENSA_DI_AUTO;
/

-- #####################################################################
-- ## PARTE 2c: CUERPO PKG_F8_COMPENSA_DI_AUTO (T1)
-- ## Fuente: docs/sql/FSCC-12901_PROC_YZ/06_pkg_compensa_di_body.sql (copia sin cambios, igual a PROC_Y)
-- #####################################################################
-- =====================================================================
-- FSCC-12901 v2 MULTIPAIS - Paso 06
-- Cuerpo de PKG_F8_COMPENSA_DI_AUTO   (Oracle 10.2)
--
-- Misma logica que v1 (PKG_F8_FACO_COMPENSA_DI). Las tablas se resuelven con
-- PKG_F8_CIERRE_AUTO.fn_tabla (prefijo del pais) y el log se escribe con
-- PKG_F8_CIERRE_AUTO.pr_registra_log (VTA_<pfx>LOG_CIERRE_AUTO).
--
-- Flujo "Proceso 1 - Compensacion automatica de DI" (FSCC-12901):
--   cierre Y de la carga o sin sobres del mismo local-dia
--   (PKG_F8_CIERRE_AUTO.fn_universo) -> calcular DR (logica de cuadratura F8)
--   -> DR = 0 ?            si: sin DI, pasa al Proceso 2        (DR_CERO)
--   -> min <= DR <= max ?  no: pendiente gestion de tiendas     (FUERA_RANGO)
--   -> ya tiene DI auto ?  si: pendiente revision (DUD-050)     (DI_AUTO_PREVIA)
--   -> ya tiene DI manual? si: pendiente revision del analista  (DI_MANUAL_PREVIA)
--   -> registrar DI = DR (mismo signo), fecha contable = fecha de venta,
--      usuario de proceso + glosa fija                          (DI_REGISTRADA)
-- =====================================================================

create or replace package body PKG_F8_COMPENSA_DI_AUTO as

  g_pais       varchar2(10);
  g_ejecucion  number;
  g_usuario    varchar2(50) := c_usuario_di;

  e_ocupada    exception;
  pragma exception_init(e_ocupada, -54);   -- ORA-00054 (NOWAIT)

  -- Nombre real de una tabla del pais en curso
  function fn_t (p_base in varchar2) return varchar2 is
  begin
    return PKG_F8_CIERRE_AUTO.fn_tabla(g_pais, p_base);
  end fn_t;

  -- ---------------------------------------------------------------
  -- Log en VTA_<pfx>LOG_CIERRE_AUTO con log_proceso = 'T1'
  -- ---------------------------------------------------------------
  procedure pr_log (p_fecha     in date,
                    p_local     in number,
                    p_terminal  in number,
                    p_cierrey   in number,
                    p_dif_real  in number,
                    p_resultado in varchar2,
                    p_mensaje   in varchar2) is
  begin
    PKG_F8_CIERRE_AUTO.pr_registra_log(g_pais, g_ejecucion, 'T1',
                                       case when p_fecha is null then '-' else 'Y' end,
                                       p_fecha, p_local, p_terminal, p_cierrey, p_dif_real,
                                       p_resultado, null, p_mensaje, g_usuario);
  end pr_log;

  function fn_num_param (p_codigo in varchar2, p_default in number) return number is
  begin
    return to_number(PKG_F8_CIERRE_AUTO.fn_param(g_pais, p_codigo, to_char(p_default)));
  end fn_num_param;

  -- ---------------------------------------------------------------
  -- DI ya registradas en el cierre Y (cualquier mov_rol)
  -- ---------------------------------------------------------------
  function fn_estado_di (p_flg_pais in varchar2,
                         p_fecha    in date,
                         p_local    in number,
                         p_terminal in number,
                         p_cierrey  in number) return varchar2 is
    v_total number;
    v_auto  number;
  begin
    g_pais := upper(trim(p_flg_pais));
    execute immediate
      'select count(*),
              nvl(sum(case when m.mov_hechopor in (:1, :2) then 1 else 0 end), 0)
         from ' || fn_t('MOVDET') || ' m
        where m.mov_fecha    = :3
          and m.mov_local    = :4
          and m.mov_terminal = :5
          and m.mov_cierrey  = :6
          and m.mov_tipomov  = ''DI'''
      into v_total, v_auto
      using c_usuario_di, g_usuario, p_fecha, p_local, p_terminal, p_cierrey;

    if v_auto > 0 then
      return 'AUTO';
    elsif v_total > 0 then
      return 'MANUAL';
    end if;
    return 'NINGUNA';
  end fn_estado_di;

  -- ---------------------------------------------------------------
  -- Evaluacion de una caja sin grabar (reglas de FSCC-12957)
  -- ---------------------------------------------------------------
  function fn_evalua_caja (p_flg_pais in  varchar2,
                           p_fecha    in  date,
                           p_local    in  number,
                           p_terminal in  number,
                           p_cierrey  in  number,
                           o_dif_real out number) return varchar2 is
    v_min    number;
    v_max    number;
    v_estado varchar2(10);
  begin
    g_pais := upper(trim(p_flg_pais));
    v_min  := fn_num_param('CA_DI_MIN', -1000);
    v_max  := fn_num_param('CA_DI_MAX', 20000);

    -- Base: Diferencia Real de la F8 (Label70 de Form3Y), despues de las
    -- compensaciones ya registradas (dotaciones, billetes falsos, etc.)
    o_dif_real := PKG_F8_CIERRE_AUTO.fn_dif_real(g_pais, p_fecha, p_local, p_terminal, p_cierrey);

    if o_dif_real is null then
      return 'SIN_LIBVTA';
    elsif o_dif_real = 0 then
      return 'DR_CERO';
    elsif o_dif_real < v_min or o_dif_real > v_max then   -- limites inclusivos
      return 'FUERA_RANGO';
    end if;

    v_estado := fn_estado_di(g_pais, p_fecha, p_local, p_terminal, p_cierrey);
    if v_estado = 'AUTO' then
      return 'DI_AUTO_PREVIA';
    elsif v_estado = 'MANUAL' then
      return 'DI_MANUAL_PREVIA';
    end if;
    return 'COMPENSABLE';
  end fn_evalua_caja;

  -- ---------------------------------------------------------------
  -- Registro de la DI (replica InsertarRegistroMovDet + Form45.GrabarObs)
  -- ---------------------------------------------------------------
  procedure pr_registra_di (p_fecha in date, p_local in number, p_terminal in number,
                            p_cierrey in number, p_monto in number) is
  begin
    -- Modulo1.InsertarRegistroMovDet: mov_rol 0, mov_nombre ' ', mov_secuencia 0,
    -- mov_numero 0, monto redondeado a 2, MOV_REGUL 'S', MOV_FECHAREG = fecha de
    -- venta (fecha contable = fecha de venta), techkey con la secuencia del pais
    -- ({SEQMOV}; FACO: SEQ_VTA_FACOVEN).
    -- MOV_NOMEMPLEADO / MOV_EMPEMPLEADO toman su default (' ').
    execute immediate PKG_F8_CIERRE_AUTO.fn_sql(g_pais,
      q'[insert into VTA_{P}MOVDET
           (mov_fecha, mov_local, mov_terminal, mov_tipomov, mov_rol, mov_nombre,
            mov_secuencia, mov_numero, mov_monto, mov_hechopor, mov_regul,
            mov_fechareg, mov_techkey, mov_cierrey)
         values
           (:1, :2, :3, 'DI', 0, ' ',
            0, 0, :4, :5, 'S',
            :6, {SEQMOV}.nextval, :7)]')
      using p_fecha, p_local, p_terminal, round(p_monto, 2), g_usuario, p_fecha, p_cierrey;

    -- Glosa fija (Form45: una observacion por caja / concepto / Y, en mayusculas)
    execute immediate
      'update ' || fn_t('COMPDES') || ' c
          set c.cpd_obs = :1
        where c.cpd_fecha    = :2
          and c.cpd_local    = :3
          and c.cpd_terminal = :4
          and c.cpd_tipmov   = ''DI''
          and c.cpd_cierrey  = :5'
      using c_glosa_di, p_fecha, p_local, p_terminal, p_cierrey;

    if sql%rowcount = 0 then
      -- cpd_secuencia la asigna el trigger de la tabla (FACO: TRG_VTA_FACOCOMPDES_I_SEQ)
      execute immediate
        'insert into ' || fn_t('COMPDES') || '
           (cpd_fecha, cpd_local, cpd_terminal, cpd_tipmov, cpd_obs, cpd_cierrey)
         values (:1, :2, :3, ''DI'', :4, :5)'
        using p_fecha, p_local, p_terminal, c_glosa_di, p_cierrey;
    end if;
  end pr_registra_di;

  -- ---------------------------------------------------------------
  -- Proceso de una caja (cierre Y)
  -- ---------------------------------------------------------------
  procedure pr_procesa_caja (p_fecha in date, p_local in number, p_terminal in number,
                             p_cierrey in number) is
    v_estado    number;
    v_resultado varchar2(30);
    v_dr        number;
    v_dr2       number;
    v_msg       varchar2(1000);
  begin
    savepoint sp_di;

    -- La caja debe existir y estar abierta (Form38 no permite DI en caja cerrada)
    begin
      execute immediate
        'select t.ter_estado
           from ' || fn_t('TERMSTATY') || ' t
          where t.ter_fecha = :1 and t.ter_local = :2
            and t.ter_terminal = :3 and t.ter_cierrey = :4
            for update nowait'
        into v_estado
        using p_fecha, p_local, p_terminal, p_cierrey;
    exception
      when no_data_found then
        pr_log(p_fecha, p_local, p_terminal, p_cierrey, null, 'SIN_TERMSTAT',
               'No existe el cierre Y en ' || fn_t('TERMSTATY'));
        return;
      when e_ocupada then
        pr_log(p_fecha, p_local, p_terminal, p_cierrey, null, 'OCUPADA',
               'Caja bloqueada por otro usuario');
        return;
    end;

    if v_estado > 0 then
      rollback to sp_di;
      pr_log(p_fecha, p_local, p_terminal, p_cierrey, null, 'YA_CERRADA',
             'Caja cerrada (estado ' || v_estado || '): no se registra DI');
      return;
    end if;

    v_resultado := fn_evalua_caja(g_pais, p_fecha, p_local, p_terminal, p_cierrey, v_dr);

    if v_resultado <> 'COMPENSABLE' then
      rollback to sp_di;
      v_msg := case v_resultado
                 when 'DR_CERO'          then 'Diferencia real 0: sin DI, pasa al cierre (T2)'
                 when 'FUERA_RANGO'      then 'Diferencia real fuera del rango [' ||
                                              fn_num_param('CA_DI_MIN', -1000) || ', ' ||
                                              fn_num_param('CA_DI_MAX', 20000) ||
                                              ']: pendiente para gestion de tiendas'
                 when 'DI_AUTO_PREVIA'   then 'La caja ya tiene una DI automatica de una carga anterior: revision del analista (DUD-050)'
                 when 'DI_MANUAL_PREVIA' then 'La caja ya tiene una DI registrada por el analista: revision del analista'
                 when 'SIN_LIBVTA'       then 'No hay Z disponible (sin libro de ventas de la Y)'
               end;
      pr_log(p_fecha, p_local, p_terminal, p_cierrey, v_dr, v_resultado, v_msg);
      return;
    end if;

    -- Registrar DI = DR con el mismo signo (DR -22 -> DI -22)
    pr_registra_di(p_fecha, p_local, p_terminal, p_cierrey, v_dr);

    -- Control: con la DI registrada la diferencia real debe quedar en 0
    v_dr2 := PKG_F8_CIERRE_AUTO.fn_dif_real(g_pais, p_fecha, p_local, p_terminal, p_cierrey);
    if nvl(v_dr2, 1) <> 0 then
      rollback to sp_di;
      pr_log(p_fecha, p_local, p_terminal, p_cierrey, v_dr, 'ERROR',
             'La diferencia real no quedo en 0 despues de registrar la DI (antes ' ||
             v_dr || ', despues ' || nvl(to_char(v_dr2), 'null') || '): DI revertida');
      return;
    end if;

    commit;
    pr_log(p_fecha, p_local, p_terminal, p_cierrey, v_dr, 'DI_REGISTRADA',
           'DI automatica por ' || v_dr || '; diferencia real queda en 0');

  exception
    when others then
      v_msg := substr(sqlerrm, 1, 1000);
      begin
        rollback to sp_di;
      exception
        when others then rollback;
      end;
      pr_log(p_fecha, p_local, p_terminal, p_cierrey, null, 'ERROR', v_msg);
  end pr_procesa_caja;

  -- ---------------------------------------------------------------
  -- Punto de entrada de T1
  -- ---------------------------------------------------------------
  procedure prc_compensa_di (p_flg_pais  in varchar2,
                             p_ejecucion in number   default null,
                             p_usuario   in varchar2 default 'PROC_DI_AUTO',
                             p_max_cajas in number   default null) is
    v_cur sys_refcursor;
    v_f   date;
    v_l   number;
    v_t   number;
    v_y   number;
    v_n   number := 0;
  begin
    g_pais    := upper(trim(p_flg_pais));
    g_usuario := nvl(substr(p_usuario, 1, 50), c_usuario_di);
    if p_ejecucion is null then
      g_ejecucion := PKG_F8_CIERRE_AUTO.fn_nueva_ejecucion(g_pais);   -- valida el pais
    else
      g_ejecucion := p_ejecucion;
    end if;

    if PKG_F8_CIERRE_AUTO.fn_param(g_pais, 'CA_DI_ACTIVO', 'N') <> 'S' then
      pr_log(null, null, null, null, null, 'INACTIVO', 'Parametro 1502 CA_DI_ACTIVO distinto de S');
      return;
    end if;

    pr_log(null, null, null, null, null, 'INICIO',
           'Pais ' || g_pais || ' | rango [' || fn_num_param('CA_DI_MIN', -1000) || ', ' ||
           fn_num_param('CA_DI_MAX', 20000) || '] | usuario ' || g_usuario);

    -- Cajas de la carga: mismo universo que despues evalua T2 (cola de la
    -- ejecucion + cajas sin sobres del mismo local-dia). La cola NO se
    -- modifica aqui.
    v_cur := PKG_F8_CIERRE_AUTO.fn_universo(g_pais, p_ejecucion);
    loop
      fetch v_cur into v_f, v_l, v_t, v_y;
      exit when v_cur%notfound;
      exit when p_max_cajas is not null and v_n >= p_max_cajas;
      v_n := v_n + 1;
      pr_procesa_caja(v_f, v_l, v_t, v_y);
    end loop;
    close v_cur;

    pr_log(null, null, null, null, null, 'FIN', 'Cajas evaluadas: ' || v_n);
  exception
    when others then
      if v_cur%isopen then
        close v_cur;
      end if;
      rollback;
      pr_log(null, null, null, null, null, 'ERROR', substr(sqlerrm, 1, 1000));
      raise;
  end prc_compensa_di;

end PKG_F8_COMPENSA_DI_AUTO;
/

-- #####################################################################
-- ## PARTE 2d: CUERPO PKG_F8_CIERRE_AUTO (T2, llama a T1)
-- ## Fuente: docs/sql/FSCC-12901_PROC_YZ/07_pkg_cierre_auto_body.sql (PROC_YZ: incluye la Z)
-- #####################################################################
-- =====================================================================
-- FSCC-12901 PROC_YZ (v2 multipais + cierre Z) - Paso 07
-- Cuerpo de PKG_F8_CIERRE_AUTO   (Oracle 10.2)
--
-- Misma logica que v1 (PKG_F8_FACO_CIERRE_AUTO, docs/sql/FSCC-12901_T1_T2/
-- 07_pkg_cierre_auto_body.sql); cambia solo:
--   * el pais llega por parametro (P_FLG_PAIS = Flg_Pais$ del exe) y las
--     tablas se arman con su prefijo: el SQL se escribe con marcas que
--     FN_R reemplaza segun la configuracion del pais:
--         {P}     prefijo de tablas        VTA_{P}TERMSTATY -> VTA_FACOTERMSTATY
--         {NIVEL} tipo de registro del libro de ventas del cierre ('Y')
--         {TMIN} / {TMAX}  rango de codigos de tarjetas recaudadas
--         {USD}   codigo de moneda dolar (cmn_mdareg)
--         {SEQMOV} secuencia del techkey de VTA_<pfx>MOVDET
--   * consultas con SQL dinamico y binds (:b_fecha, :b_local, :b_term, :b_y,
--     :b_txt via DBMS_SQL, que enlaza por nombre todas las apariciones);
--   * universo "carga del dia" (modo CARGA): la ejecucion toma la cola
--     pendiente (P -> E) y al terminar la deja procesada (C). Sin CA_DIAS.
--
-- PROC_YZ (15-10-2026): agrega el cierre de la Z (VTA_<pfx>TERMSTAT), que
-- replica Form3.CierraTerminal (FTEPROD/Form3.frm:3439). Apagado por defecto
-- (parametro 1502 CA_CIERRA_Z = N): con N el paquete se comporta igual que
-- PROC_Y. Con S, despues de evaluar las Y de cada caja se intenta cerrar la Z
-- del terminal y dia (pr_procesa_z). Las consultas de la Z son las mismas de
-- la Y sin el filtro de numero de Y y con libro de ventas 'F8' (fn_rz), igual
-- que hace el exe (StrSumCompensado, LeeZ, LeeProsegur... sin cierrey).
-- El SQL de la Y no cambia: fn_rz con p_z = FALSE es exactamente fn_r.
--
-- Referencias al exe VB6 (FTEPROD/):
--   Form3Y.CierraTerminal :2801   Form3Y.FormateaDatos :2704
--   Form3Y.FuncvalidarConcepto :1700  Modulo1.StrSumCompensado :2630
--   Modulo1.FuncMontoValidaZZZYY :4160  StrCamposValidarZZZ :4053
--   Modulo1.Func_ValorGestionCheque :5681  Func_ValorChequeFecha :5632
--   Z: Form3.CierraTerminal :3439  Form3.FuncValidadCierreyyyy :2153
--      Form3.FuncvalidarDifDolares :1966  Modulo1.FuncValidarZSumaY :5531
--      Modulo1.FuncMontoValidaZZZ :4105
-- Detalle funcional: docs/CierreCaja_FACO_Reglas.md (Y: 3, Z: 4 y 6.2)
-- =====================================================================

create or replace package body PKG_F8_CIERRE_AUTO as

  -- ---------------------------------------------------------------
  -- Configuracion del pais
  -- ---------------------------------------------------------------
  type t_cfg is record (
    pais        varchar2(10),   -- valor de Flg_Pais$ recibido
    prefijo     varchar2(10),   -- prefijo de tablas VTA_<prefijo>...
    localiz     varchar2(10),   -- VTA_PAINT_Z.vta_localiz
    nivel       varchar2(1),    -- nivel que cierra el proceso: Y (cierre parcial)
    nivel_z     varchar2(2),    -- tipo de registro del libro de ventas de la Z ('F8')
    tarj_min    number,         -- tarjetas recaudadas: codigos tarj_min..tarj_max
    tarj_max    number,
    mda_usd     number,         -- moneda dolar en VTA_<pfx>RECMEX
    modo        varchar2(10),   -- universo: CARGA (la carga del dia)
    seq_movdet  varchar2(30)    -- secuencia del techkey de VTA_<pfx>MOVDET
  );
  g_cfg        t_cfg;

  type t_nums is table of number index by pls_integer;
  type t_conceptos is table of varchar2(200) index by varchar2(2);

  -- ---------------------------------------------------------------
  -- Estado de la ejecucion
  -- ---------------------------------------------------------------
  g_ejecucion  number;
  g_usuario    varchar2(50) := c_usuario_def;
  g_dec        number;          -- decimales de redondeo (CA_DECIMAL)
  g_proceso    varchar2(2) := 'T2';  -- log_proceso: T2 automatico, CC Consultas de Cuadratura
  g_len_notas_z number;         -- largo de TER_NOTAS en VTA_<pfx>TERMSTAT (se lee una vez)

  -- Terminal-dia cuya Z se evalua al final de la ejecucion
  type t_term is record (f date, l number, t number);
  type t_terms is table of t_term index by varchar2(40);

  e_ocupada    exception;
  pragma exception_init(e_ocupada, -54);   -- ORA-00054 resource busy (NOWAIT)

  -- ---------------------------------------------------------------
  -- Paises habilitados. Es la UNICA fuente del prefijo que se concatena
  -- en el SQL dinamico (lista blanca: nunca se usa el texto recibido).
  -- ---------------------------------------------------------------
  procedure pr_config (p_flg_pais in varchar2) is
    v_pais varchar2(10) := upper(trim(p_flg_pais));
    v_cfg  t_cfg;
  begin
    if g_cfg.pais is not null and g_cfg.pais = v_pais then
      return;   -- ya configurado
    end if;

    if v_pais = 'FACO' then
      -- Falabella Colombia: cierre Y (Form3Y) y, si CA_CIERRA_Z = S, la Z (Form3).
      v_cfg.pais       := 'FACO';
      v_cfg.prefijo    := 'FACO';
      v_cfg.localiz    := 'FACO';
      v_cfg.nivel      := 'Y';
      v_cfg.nivel_z    := 'F8';     -- Form3.LeeZ / FuncValidarZSumaY: vta_tiporeg = 'F8'
      v_cfg.tarj_min   := 2000;     -- FuncLeeTarjeta CTARJ, rama FACO
      v_cfg.tarj_max   := 2999;
      v_cfg.mda_usd    := 305;      -- Modulo1 DOLAR = "305"
      v_cfg.modo       := 'CARGA';  -- una ejecucion por carga, sin ventana de dias
      v_cfg.seq_movdet := 'SEQ_VTA_FACOVEN';

    -- -------------------------------------------------------------
    -- EJEMPLO (NO HABILITADO): como se agregaria otro pais, p. ej.
    -- Falabella Chile (Flg_Pais$ = "CHI", tablas sin prefijo). Antes de
    -- habilitarlo hay que crear sus objetos (cola VTA_PRD_CIERRE, log
    -- VTA_LOG_CIERRE_AUTO, secuencias, trigger y parametros 1502 en
    -- VTA_PARAM), revisar contra el exe sus diferencias de cuadratura,
    -- revisar el proceso de la Z (pr_procesa_z, PROC_YZ) y agregar el
    -- modo DIAS (fecha de proceso - CA_DIAS) en fn_universo.
    -- elsif v_pais in ('CHI', 'CL') then
    --   v_cfg.pais       := v_pais;
    --   v_cfg.prefijo    := null;          -- VTA_TERMSTAT, VTA_PRD, ...
    --   v_cfg.localiz    := 'CHI';
    --   v_cfg.nivel      := 'Y';
    --   v_cfg.nivel_z    := 'F8';
    --   v_cfg.tarj_min   := ...;
    --   v_cfg.tarj_max   := ...;
    --   v_cfg.mda_usd    := 305;
    --   v_cfg.modo       := 'DIAS';        -- fecha de proceso - CA_DIAS
    --   v_cfg.seq_movdet := 'SEQ_VTA_VEN';
    -- -------------------------------------------------------------
    else
      raise_application_error(-20001,
        'Pais no habilitado para cierre automatico: ' || nvl(p_flg_pais, '(nulo)'));
    end if;

    g_cfg := v_cfg;
    g_dec := null;   -- los decimales son por pais (CA_DECIMAL)
    g_len_notas_z := null;
  end pr_config;

  -- Reemplaza las marcas del SQL con los valores del pais configurado
  function fn_r (p_sql in varchar2) return varchar2 is
  begin
    return replace(replace(replace(replace(replace(replace(p_sql,
             '{P}',      g_cfg.prefijo),
             '{NIVEL}',  g_cfg.nivel),
             '{TMIN}',   to_char(g_cfg.tarj_min)),
             '{TMAX}',   to_char(g_cfg.tarj_max)),
             '{USD}',    to_char(g_cfg.mda_usd)),
             '{SEQMOV}', g_cfg.seq_movdet);
  end fn_r;

  -- SQL de la Y convertido a SQL de la Z (p_z = TRUE), igual que el exe:
  --   * '{NIVEL}' -> nivel de la Z ('F8') en vez de 'Y';
  --   * cada filtro de numero de Y "alias.columna = :b_y" pasa a "1 = 1"
  --     (StrSumCompensado, LeeZ, LeeProsegur, LeeTes... sin cierrey).
  -- Sin :b_y en el texto, fn_sql_nums no enlaza el numero de Y.
  -- Con p_z = FALSE devuelve exactamente fn_r(p_sql): el SQL de la Y no cambia.
  function fn_rz (p_sql in varchar2, p_z in boolean) return varchar2 is
  begin
    if not p_z then
      return fn_r(p_sql);
    end if;
    return regexp_replace(fn_r(replace(p_sql, '{NIVEL}', g_cfg.nivel_z)),
                          '[[:alnum:]_]+\.[[:alnum:]_]+[[:space:]]*=[[:space:]]*:b_y', '1 = 1');
  end fn_rz;

  -- Ejecuta un SELECT de una fila y p_ncols columnas numericas con binds por
  -- nombre (:b_fecha, :b_local, :b_term, :b_y, :b_txt; cada uno solo si aparece).
  -- Sin filas devuelve NULL en cada columna.
  function fn_sql_nums (p_sql      in varchar2,
                        p_ncols    in pls_integer,
                        p_fecha    in date,
                        p_local    in number,
                        p_terminal in number,
                        p_cierrey  in number,
                        p_txt      in varchar2 default null) return t_nums is
    c   integer;
    n   integer;
    x   number;
    v   t_nums;
  begin
    c := dbms_sql.open_cursor;
    begin
      dbms_sql.parse(c, p_sql, dbms_sql.native);
      if instr(p_sql, ':b_fecha') > 0 then dbms_sql.bind_variable(c, ':b_fecha', p_fecha);    end if;
      if instr(p_sql, ':b_local') > 0 then dbms_sql.bind_variable(c, ':b_local', p_local);    end if;
      if instr(p_sql, ':b_term')  > 0 then dbms_sql.bind_variable(c, ':b_term',  p_terminal); end if;
      if instr(p_sql, ':b_y')     > 0 then dbms_sql.bind_variable(c, ':b_y',     p_cierrey);  end if;
      if instr(p_sql, ':b_txt')   > 0 then dbms_sql.bind_variable(c, ':b_txt',   p_txt);      end if;
      for i in 1 .. p_ncols loop
        dbms_sql.define_column(c, i, x);
      end loop;
      n := dbms_sql.execute(c);
      if dbms_sql.fetch_rows(c) > 0 then
        for i in 1 .. p_ncols loop
          dbms_sql.column_value(c, i, x);
          v(i) := x;
        end loop;
      else
        for i in 1 .. p_ncols loop
          v(i) := null;
        end loop;
      end if;
      dbms_sql.close_cursor(c);
    exception
      when others then
        if dbms_sql.is_open(c) then
          dbms_sql.close_cursor(c);
        end if;
        raise;
    end;
    return v;
  end fn_sql_nums;

  -- ---------------------------------------------------------------
  -- Utilitarios publicos
  -- ---------------------------------------------------------------
  function fn_tabla (p_flg_pais in varchar2,
                     p_base     in varchar2) return varchar2 is
  begin
    pr_config(p_flg_pais);
    return 'VTA_' || g_cfg.prefijo || upper(p_base);
  end fn_tabla;

  function fn_sql (p_flg_pais in varchar2,
                   p_sql      in varchar2) return varchar2 is
  begin
    pr_config(p_flg_pais);
    return fn_r(p_sql);
  end fn_sql;

  function fn_param (p_flg_pais in varchar2,
                     p_codigo   in varchar2,
                     p_default  in varchar2) return varchar2 is
    v_valor varchar2(200);
  begin
    pr_config(p_flg_pais);
    execute immediate fn_r(
      q'[select trim(p.vta_xglosa)
           from VTA_{P}PARAM p
          where p.vta_ccodtipo = :1
            and trim(p.vta_ccodigo) = :2
            and rownum = 1]')
      into v_valor
      using c_tipo_param, p_codigo;
    return nvl(v_valor, p_default);
  exception
    when no_data_found then
      return p_default;
  end fn_param;

  function fn_dec return number is
  begin
    if g_dec is null then
      g_dec := to_number(fn_param(g_cfg.pais, 'CA_DECIMAL', '0'));
    end if;
    return g_dec;
  end fn_dec;

  procedure pr_registra_log (p_flg_pais  in varchar2,
                             p_ejecucion in number,
                             p_proceso   in varchar2,
                             p_nivel     in varchar2,
                             p_fecha     in date,
                             p_local     in number,
                             p_terminal  in number,
                             p_cierrey   in number,
                             p_dif_real  in number,
                             p_resultado in varchar2,
                             p_regla     in varchar2,
                             p_mensaje   in varchar2,
                             p_usuario   in varchar2) is
    pragma autonomous_transaction;
  begin
    pr_config(p_flg_pais);
    execute immediate fn_r(
      q'[insert into VTA_{P}LOG_CIERRE_AUTO
           (log_id, log_ejecucion, log_proceso, log_nivel, log_fecha_vta, log_local, log_terminal,
            log_cierrey, log_dif_real, log_resultado, log_regla, log_mensaje,
            log_usuario, log_fechahora)
         values
           (SEQ_VTA_{P}LOG_CIERRE_AUTO.nextval, :1, :2, :3, :4, :5, :6,
            :7, :8, :9, :10, :11, :12, sysdate)]')
      using nvl(p_ejecucion, 0), p_proceso, p_nivel, p_fecha, p_local, p_terminal,
            p_cierrey, p_dif_real, p_resultado, p_regla, substr(p_mensaje, 1, 1000),
            substr(p_usuario, 1, 50);
    commit;
  end pr_registra_log;

  function fn_nueva_ejecucion (p_flg_pais in varchar2) return number is
    v_n number;
  begin
    pr_config(p_flg_pais);
    execute immediate fn_r('select SEQ_VTA_{P}LOG_CIERRE_AUTO.nextval from dual') into v_n;
    return v_n;
  end fn_nueva_ejecucion;

  -- Log de la ejecucion en curso de este paquete
  procedure pr_log (p_nivel     in varchar2,
                    p_fecha     in date,
                    p_local     in number,
                    p_terminal  in number,
                    p_cierrey   in number,
                    p_dif_real  in number,
                    p_resultado in varchar2,
                    p_regla     in varchar2,
                    p_mensaje   in varchar2) is
  begin
    pr_registra_log(g_cfg.pais, g_ejecucion, g_proceso, p_nivel, p_fecha, p_local, p_terminal,
                    p_cierrey, p_dif_real, p_resultado, p_regla, p_mensaje, g_usuario);
  end pr_log;

  -- ---------------------------------------------------------------
  -- Universo de cajas de una ejecucion (reemplaza a la vista
  -- VTA_FACOV_CAJAS_CIERRE de v1, que queda sin uso en v2):
  --   COLA      : cierres Y de la carga (cola E de la ejecucion, o P si
  --               p_ejecucion es nulo), sobres con Y (prv_cierrey <> 0).
  --   SIN_SOBRE : cierres Y abiertos del mismo local y fecha de venta de la
  --               carga, sin sobres ("cajas sin movimiento", DF-SCC fila 12 /
  --               CA8), si CA_SIN_SOBRE = S y la Y tiene libro de ventas.
  -- UNION elimina las Y repetidas (varios sobres o COLA + SIN_SOBRE).
  -- p_ejecucion es un numero interno de la secuencia: va como literal.
  -- ---------------------------------------------------------------
  function fn_universo (p_flg_pais  in varchar2,
                        p_ejecucion in number) return sys_refcursor is
    v_cola varchar2(200);
    v_sql  varchar2(4000);
    v_cur  sys_refcursor;
  begin
    pr_config(p_flg_pais);
    if p_ejecucion is null then
      v_cola := q'[q.pcr_estado = 'P']';
    else
      v_cola := q'[q.pcr_estado = 'E' and q.pcr_ejecucion = ]' || to_char(trunc(p_ejecucion));
    end if;

    v_sql :=
      q'[select q.prv_fechavta f, q.prv_local l, q.prv_terminal t, q.prv_cierrey y
           from VTA_{P}PRD_CIERRE q
          where ]' || v_cola || q'[
            and q.prv_cierrey <> 0]';

    if fn_param(p_flg_pais, 'CA_SIN_SOBRE', 'N') = 'S' then
      v_sql := v_sql || q'[
         union
         select y.ter_fecha, y.ter_local, y.ter_terminal, y.ter_cierrey
           from VTA_{P}TERMSTATY y
          where y.ter_estado <= 0
            and exists (select 1 from VTA_{P}PRD_CIERRE q
                         where ]' || v_cola || q'[
                           and q.prv_fechavta = y.ter_fecha
                           and q.prv_local = y.ter_local)
            and exists (select 1 from VTA_{P}LIBVTA l, VTA_{P}ZZZ r
                         where l.vta_tiporeg = '{NIVEL}'
                           and l.vta_techkey = r.rec_techkey
                           and l.vta_estado = 'A'
                           and l.vta_fecha_venta = y.ter_fecha
                           and l.vta_local = y.ter_local
                           and l.vta_terminal = y.ter_terminal
                           and l.vta_secuencia = y.ter_cierrey)]';
    end if;

    -- Modo CARGA (FACO): sin filtro de fechas. Un pais en modo DIAS (ejemplo
    -- Chile) agregaria aqui: f >= trunc(sysdate) - CA_DIAS.
    v_sql := 'select f, l, t, y from (' || v_sql || ') order by 1, 2, 3, 4';
    open v_cur for fn_r(v_sql);
    return v_cur;
  end fn_universo;

  -- Mensajes de conceptos pendientes (Form3Y.CierraTerminal, mismo orden)
  function fn_conceptos return t_conceptos is
    v t_conceptos;
  begin
    v('SN') := 'Falta regularizar el Sobres No Enviado declarada, o elimine el registro';
    v('AF') := 'Falta regularizar Atesoramiento Fondo Fijo, o elimine el registro';
    v('ND') := 'Falta regularizar N/D no digitada declarada, o elimine el registro';
    v('FN') := 'Falta regularizar Factura no digitada declarada, o elimine el registro';
    v('NP') := 'Falta regularizar el N/C Publicidad declarada, o elimine el registro';
    v('BF') := 'Falta regularizar el Billete Falso declarada, o elimine el registro';
    v('CR') := 'Falta regularizar el Certificado Regalo declarada, o elimine el registro';
    v('CT') := 'Falta regularizar el carta aviso Tienda declarada, o elimine el registro';
    v('CA') := 'Falta regularizar el carta aviso central declarada, o elimine el registro';
    v('DP') := 'Falta regularizar la Diferencia Prestadora declarada, o elimine el registro';
    return v;
  end fn_conceptos;

  -- ---------------------------------------------------------------
  -- Cuadratura de la caja (FormateaDatos / Form43.SubBuscarOpcion):
  --   o_dif_caja    = sumaBZ (Dif. de Caja, sin redondear)
  --   o_compensado  = compensado (Compensacion, sin redondear)
  --   o_dif_real    = Diferencia Real (Label70) = round(sumaBZ - round(compensado))
  -- sumaBZ = (prsefe-totefe)+(prschd-totchd)+totDol+(teschf-totchf)+(tesTarjeta-totTarjeta)
  -- Sin libro de ventas de la Y las tres salidas quedan en NULL ("No hay Z disponible").
  -- Mismas consultas que v1; solo cambian las tablas ({P}) y los literales
  -- del pais ({NIVEL}, {TMIN}, {TMAX}, {USD}).
  -- PROC_YZ: p_cierrey NULL = cuadratura de la Z (Form3.FormateaDatos :3337):
  -- las mismas consultas sin filtro de Y y con libro de ventas 'F8' (fn_rz).
  -- Sin libro de ventas 'F8' las salidas quedan en NULL.
  -- ---------------------------------------------------------------
  procedure pr_cuadratura (p_fecha      in  date,
                           p_local      in  number,
                           p_terminal   in  number,
                           p_cierrey    in  number,
                           o_dif_caja   out number,
                           o_compensado out number,
                           o_dif_real   out number) is
    v          t_nums;
    v_cnt      number;
    v_totefe   number; v_totchd number; v_totchf number; v_tottarj number;
    v_prsefe   number; v_prschd number;
    v_teschf   number; v_testarj number; v_totdol number;
    v_comp     number;
    v_z        boolean := p_cierrey is null;   -- PROC_YZ: sin numero de Y = Z (dia completo)
  begin
    -- Declarado en la Y (LeeZ + ARMA_QUERY_Z). Z: libro de ventas 'F8' sin vta_secuencia
    -- (Form3.LeeZ :2345, rama FACO de ARMA_QUERY_Z).
    v := fn_sql_nums(fn_rz(
      q'[select count(*),
                nvl(sum(r.rec_mefectivo), 0),
                nvl(sum(r.rec_mchkdia), 0),
                nvl(sum(r.rec_mchkfecha), 0),
                nvl(sum(r.rec_mtarj), 0) + nvl(sum(r.rec_msodimac), 0)
           from VTA_{P}LIBVTA l, VTA_{P}ZZZ r
          where l.vta_tiporeg     = '{NIVEL}'
            and l.vta_fecha_venta = :b_fecha
            and l.vta_local       = :b_local
            and l.vta_terminal    = :b_term
            and l.vta_estado      = 'A'
            and l.vta_techkey     = r.rec_techkey
            and l.vta_secuencia   = :b_y]', v_z),
      5, p_fecha, p_local, p_terminal, p_cierrey);
    v_cnt := v(1); v_totefe := v(2); v_totchd := v(3); v_totchf := v(4); v_tottarj := v(5);

    o_dif_caja := null; o_compensado := null; o_dif_real := null;
    if nvl(v_cnt, 0) = 0 then
      return;   -- sin libro de ventas: el exe muestra "No hay Z disponible"
    end if;

    -- Sobres de la transportadora (LeeProsegur): tiporec F8, EFE / CHE
    v := fn_sql_nums(fn_rz(
      q'[select nvl(sum(case when p.prv_tiposobre = 'EFE' then nvl(p.prv_montosobre,0) + nvl(p.prv_montodif,0) end), 0),
                nvl(sum(case when p.prv_tiposobre = 'CHE' then nvl(p.prv_montosobre,0) + nvl(p.prv_montodif,0) end), 0)
           from VTA_{P}PRD p
          where p.prv_fechavta = :b_fecha
            and p.prv_local    = :b_local
            and p.prv_terminal = :b_term
            and p.prv_tiporec  = 'F8'
            and p.prv_cierrey  = :b_y]', v_z),
      2, p_fecha, p_local, p_terminal, p_cierrey);
    v_prsefe := v(1); v_prschd := v(2);

    -- Cheque a fecha en tesoreria (LeeTes). Verificado en test (06-10-2026): una fila por Y.
    v := fn_sql_nums(fn_rz(
      q'[select nvl(sum(t.tes_chefecha), 0)
           from VTA_{P}TESOR t
          where t.tes_fecha    = :b_fecha
            and t.tes_local    = :b_local
            and t.tes_terminal = :b_term
            and t.tes_cierrey  = :b_y]', v_z),
      1, p_fecha, p_local, p_terminal, p_cierrey);
    v_teschf := v(1);

    -- Tarjetas recaudadas (FuncLeeTarjeta CTARJ, rango del pais)
    v := fn_sql_nums(fn_rz(
      q'[select nvl(sum(t.vta_monto_inf), 0)
           from VTA_{P}TARJ t
          where t.vta_fecha    = :b_fecha
            and t.vta_local    = :b_local
            and t.vta_terminal = :b_term
            and t.vta_cod_tarj between {TMIN} and {TMAX}
            and t.vta_cierrey  = :b_y]', v_z),
      1, p_fecha, p_local, p_terminal, p_cierrey);
    v_testarj := v(1);

    -- Dolares recaudados (FunConsRecMon {USD}). FACO: totDol = tesDol
    v := fn_sql_nums(fn_rz(
      q'[select nvl(sum(x.mex_monto), 0)
           from VTA_{P}RECMEX x
          where x.mex_fecha    = :b_fecha
            and x.mex_local    = :b_local
            and x.mex_terminal = :b_term
            and x.id_mdareg    = {USD}
            and x.mex_cierrey  = :b_y]', v_z),
      1, p_fecha, p_local, p_terminal, p_cierrey);
    v_totdol := v(1);

    -- Compensado (Modulo1.StrSumCompensado, Gopcion = "T").
    -- Se mantiene UNION (no UNION ALL) para replicar exactamente al exe.
    v := fn_sql_nums(fn_rz(
      q'[select nvl(sum(c.mov_monto), 0)
      from (
        -- TC: registrados el dia - regularizados ese dia
        select ( nvl((select sum(m.mov_monto) from VTA_{P}MOVDET m
                       where m.mov_fecha = :b_fecha and m.mov_local = :b_local
                         and m.mov_terminal = :b_term
                         and m.mov_cierrey = :b_y
                         and m.mov_tipomov = 'TC'), 0)
               - nvl((select sum(m.mov_monto) from VTA_{P}MOVDET m
                       where m.mov_fechareg = :b_fecha and m.mov_local = :b_local
                         and m.mov_terminal = :b_term
                         and m.mov_cierrey = :b_y
                         and m.mov_regul = 'S' and m.mov_tipomov = 'TC'), 0) ) mov_monto,
               d.mov_tipomov
          from VTA_{P}CONCEPDIF d
         where d.mov_tipomov = 'TC'
        union
        -- SN, ND, FN: regularizados del dia - regularizados ese dia
        select ( nvl((select sum(m.mov_monto) from VTA_{P}MOVDET m
                       where m.mov_fecha = :b_fecha and m.mov_local = :b_local
                         and m.mov_terminal = :b_term
                         and m.mov_cierrey = :b_y
                         and m.mov_regul = 'S' and m.mov_tipomov = d.mov_tipomov), 0)
               - nvl((select sum(m.mov_monto) from VTA_{P}MOVDET m
                       where m.mov_fechareg = :b_fecha and m.mov_local = :b_local
                         and m.mov_terminal = :b_term
                         and m.mov_cierrey = :b_y
                         and m.mov_regul = 'S' and m.mov_tipomov = d.mov_tipomov), 0) ),
               d.mov_tipomov
          from VTA_{P}CONCEPDIF d
         where d.mov_tipomov in ('SN', 'ND', 'FN')
        union
        -- BF
        select nvl((select sum(m.mov_monto) from VTA_{P}MOVDET m
                     where m.mov_fecha = :b_fecha and m.mov_local = :b_local
                       and m.mov_terminal = :b_term
                       and m.mov_cierrey = :b_y
                       and m.mov_regul = 'S' and m.mov_tipomov = 'BF'), 0),
               d.mov_tipomov
          from VTA_{P}CONCEPDIF d
         where d.mov_tipomov = 'BF'
        union
        -- NP / FT (una fila por concepto de concepdif, cada una con la suma NP+FT)
        select nvl((select sum(m.mov_monto) from VTA_{P}MOVDET m
                     where m.mov_fecha = :b_fecha and m.mov_local = :b_local
                       and m.mov_terminal = :b_term
                       and m.mov_cierrey = :b_y
                       and m.mov_regul = 'S' and m.mov_tipomov in ('NP', 'FT')), 0),
               d.mov_tipomov
          from VTA_{P}CONCEPDIF d
         where d.mov_tipomov in ('NP', 'FT')
        union
        -- Conceptos regularizados (incluye CA y DI)
        select nvl(sum(m.mov_monto), 0), d.mov_tipomov
          from VTA_{P}MOVDET m, VTA_{P}CONCEPDIF d
         where m.mov_fecha = :b_fecha and m.mov_local = :b_local
           and m.mov_terminal = :b_term
           and m.mov_cierrey = :b_y
           and m.mov_regul = 'S'
           and m.mov_fechareg is not null
           and m.mov_tipomov = d.mov_tipomov
           and d.mov_tipomov in ('TU','DV','P1','P2','CM','CB','CC','SB','SC','SV','CP','CF','CT',
                                 'RE','CR','PC','DN','AF','DD','AA','DI','AV','RP','DP','CA','DE','PM')
         group by d.mov_tipomov
        union
        -- Carta aviso central (VTA_<pfx>CARTAAVISO)
        select nvl(sum(m.mov_monto), 0), d.mov_tipomov
          from VTA_{P}CARTAAVISO m, VTA_{P}CONCEPDIF d
         where m.mov_fecha = :b_fecha and m.mov_local = :b_local
           and m.mov_terminal = :b_term
           and m.mov_cierrey = :b_y
           and m.mov_regul = 'S'
           and m.mov_fechareg is not null
           and m.mov_tipomov = d.mov_tipomov
           and d.mov_tipomov = 'CA'
         group by d.mov_tipomov
        union
        -- Vendedor / cajero (FACO: sin filtro VEN_REGUL)
        select (select nvl(sum(v.ven_monto), 0) from VTA_{P}DIFVEND v
                 where v.ven_fecha = :b_fecha and v.ven_local = :b_local
                   and v.ven_terminal = :b_term
                   and v.ven_cierrey = :b_y),
               d.mov_tipomov
          from VTA_{P}CONCEPDIF d
         where d.vta_coddif = 1
        union
        -- DT / NC con mov_numero <> terminal
        select nvl(sum(m.mov_monto), 0), d.mov_tipomov
          from VTA_{P}MOVDET m, VTA_{P}CONCEPDIF d
         where m.mov_fecha = :b_fecha and m.mov_numero <> m.mov_terminal
           and m.mov_local = :b_local and m.mov_terminal = :b_term
           and m.mov_cierrey = :b_y
           and m.mov_tipomov = d.mov_tipomov
           and d.mov_tipomov in ('DT', 'NC')
         group by d.mov_tipomov
        union
        -- DT / NC con mov_numero = terminal
        select nvl(sum(m.mov_monto), 0), d.mov_tipomov
          from VTA_{P}MOVDET m, VTA_{P}CONCEPDIF d
         where m.mov_fecha = :b_fecha and m.mov_numero = m.mov_terminal
           and m.mov_local = :b_local and m.mov_terminal = :b_term
           and m.mov_cierrey = :b_y
           and m.mov_tipomov = d.mov_tipomov
           and d.mov_tipomov in ('DT', 'NC')
         group by d.mov_tipomov
        union
        -- AL (cruce con libro de ventas del nivel del cierre)
        select nvl(sum(m.mov_monto), 0), d.mov_tipomov
          from VTA_{P}MOVDET m, VTA_{P}CONCEPDIF d,
               VTA_{P}LIBVTA l, VTA_{P}ZZZ z
         where m.mov_fecha = :b_fecha and m.mov_numero = m.mov_terminal
           and m.mov_fecha = l.vta_fecha_venta
           and m.mov_local = l.vta_local
           and m.mov_terminal = l.vta_terminal
           and l.vta_techkey = z.rec_techkey and l.vta_estado = 'A'
           and m.mov_local = :b_local and m.mov_terminal = :b_term
           and m.mov_cierrey = :b_y
           and l.vta_tiporeg = '{NIVEL}'
           and m.mov_secuencia = l.vta_secuencia
           and m.mov_tipomov = d.mov_tipomov
           and d.mov_tipomov = 'AL'
         group by d.mov_tipomov
        union
        -- TB
        select nvl(sum(m.mov_monto), 0), d.mov_tipomov
          from VTA_{P}MOVDET m, VTA_{P}CONCEPDIF d
         where m.mov_fecha = :b_fecha and m.mov_numero = m.mov_terminal
           and m.mov_local = :b_local and m.mov_terminal = :b_term
           and m.mov_cierrey = :b_y
           and m.mov_tipomov = d.mov_tipomov
           and d.mov_tipomov = 'TB'
         group by d.mov_tipomov
      ) c]', v_z),
      1, p_fecha, p_local, p_terminal, p_cierrey);
    v_comp := v(1);

    o_dif_caja   := (v_prsefe - v_totefe) + (v_prschd - v_totchd) + v_totdol
                  + (v_teschf - v_totchf) + (v_testarj - v_tottarj);
    o_compensado := v_comp;
    -- El exe redondea el compensado ANTES de restarlo (Form3Y.FormateaDatos):
    --   VG_ValorCompensado = Format(ValorCompensacion, gFormat)
    --   Label70 = Format(sumaBZ - VG_ValorCompensado, gFormat)
    -- gFormat de FACO = vta_parametros.vta_numformat '#,#0' (0 decimales, CA_DECIMAL).
    o_dif_real   := round(o_dif_caja - round(v_comp, fn_dec), fn_dec);
  end pr_cuadratura;

  -- Diferencia Real (Label70) = round(sumaBZ - round(compensado))
  function fn_dif_real (p_flg_pais in varchar2,
                        p_fecha    in date,
                        p_local    in number,
                        p_terminal in number,
                        p_cierrey  in number) return number is
    v_caja number; v_comp number; v_dr number;
  begin
    pr_config(p_flg_pais);
    pr_cuadratura(p_fecha, p_local, p_terminal, p_cierrey, v_caja, v_comp, v_dr);
    return v_dr;
  end fn_dif_real;

  -- Columna "Dif. de Caja" de Form43
  function fn_dif_caja (p_flg_pais in varchar2,
                        p_fecha    in date,
                        p_local    in number,
                        p_terminal in number,
                        p_cierrey  in number) return number is
    v_caja number; v_comp number; v_dr number;
  begin
    pr_config(p_flg_pais);
    pr_cuadratura(p_fecha, p_local, p_terminal, p_cierrey, v_caja, v_comp, v_dr);
    return v_caja;
  end fn_dif_caja;

  -- Columna "Compensacion" de Form43
  function fn_compensado (p_flg_pais in varchar2,
                          p_fecha    in date,
                          p_local    in number,
                          p_terminal in number,
                          p_cierrey  in number) return number is
    v_caja number; v_comp number; v_dr number;
  begin
    pr_config(p_flg_pais);
    pr_cuadratura(p_fecha, p_local, p_terminal, p_cierrey, v_caja, v_comp, v_dr);
    return v_comp;
  end fn_compensado;

  -- ---------------------------------------------------------------
  -- RY-01 Cheque a fecha: gestion de cheques (tipo 1) = tesoreria
  -- (dia completo, sin filtro de Y, igual que el exe)
  -- ---------------------------------------------------------------
  function fn_msg_cheque_fecha (p_flg_pais in varchar2,
                                p_fecha    in date,
                                p_local    in number,
                                p_terminal in number) return varchar2 is
    v         t_nums;
    v_gestion number;
    v_tesor   number;
  begin
    pr_config(p_flg_pais);
    v := fn_sql_nums(fn_r(
      q'[select nvl(sum(c.chq_monto), 0)
           from VTA_{P}CHEQUES c
          where c.chq_fecha = :b_fecha and c.chq_local = :b_local
            and c.chq_terminal = :b_term and c.chq_tipocheque = 1]'),
      1, p_fecha, p_local, p_terminal, null);
    v_gestion := v(1);

    v := fn_sql_nums(fn_r(
      q'[select nvl(sum(t.tes_chefecha), 0)
           from VTA_{P}TESOR t
          where t.tes_fecha = :b_fecha and t.tes_local = :b_local and t.tes_terminal = :b_term]'),
      1, p_fecha, p_local, p_terminal, null);
    v_tesor := v(1);

    if round(v_gestion, fn_dec) <> round(v_tesor, fn_dec) then
      return 'Existe diferencia para el concepto cheques a Fecha entre la Gestion de Cheque : ( '
             || v_gestion || ' ) versus columna tesoreria : ( ' || v_tesor || ' ) , para poder cerrar Y.';
    end if;
    return null;
  end fn_msg_cheque_fecha;

  -- ---------------------------------------------------------------
  -- RY-03 Concepto declarado sin regularizar (FuncvalidarConcepto)
  -- ---------------------------------------------------------------
  function fn_concepto_pendiente (p_flg_pais in varchar2,
                                  p_fecha    in date,
                                  p_local    in number,
                                  p_terminal in number,
                                  p_cierrey  in number,
                                  p_tipo     in varchar2) return boolean is
    v t_nums;
  begin
    pr_config(p_flg_pais);
    -- PROC_YZ: p_cierrey NULL = todo el dia, sin filtro de Y (RZ-03, Form3.FuncvalidarConcepto :1872)
    v := fn_sql_nums(fn_rz(
      case when p_tipo = 'CA' then
        q'[select count(*)
             from VTA_{P}CARTAAVISO m
            where m.mov_fecha = :b_fecha and m.mov_local = :b_local and m.mov_terminal = :b_term
              and (m.mov_regul is null or m.mov_regul in (' ', 'N'))
              and m.mov_tipomov = :b_txt
              and m.mov_cierrey = :b_y]'
      else
        q'[select count(*)
             from VTA_{P}MOVDET m
            where m.mov_fecha = :b_fecha and m.mov_local = :b_local and m.mov_terminal = :b_term
              and (m.mov_regul is null or m.mov_regul in (' ', 'N'))
              and m.mov_tipomov = :b_txt
              and m.mov_cierrey = :b_y]'
      end, p_cierrey is null),
      1, p_fecha, p_local, p_terminal, p_cierrey, p_tipo);
    return nvl(v(1), 0) > 0;
  end fn_concepto_pendiente;

  -- ---------------------------------------------------------------
  -- RY-06 Formula ZZZ de la Y (FuncValidaZZZ + FuncMontoValidaZZZYY)
  -- Verificado en test (06-10-2026): VTA_PAINT_Z.vta_signo es CHAR(1) y vale
  -- '+' en todas las filas FACO; los campos de vta_cmp_asoc existen en una
  -- sola de VTA_<pfx>LIBVTA / VTA_<pfx>ZZZ, por lo que van sin prefijo.
  -- Diferencia = F7 - F6 - F5 - F4 - F3 - F2 - F1, con F(k) armada desde
  -- VTA_PAINT_Z.vta_validadorzzz = k (filas del pais: vta_localiz). Corrige
  -- el bug del exe (Form3Y pasaba el local en vez del numero de Y).
  -- ---------------------------------------------------------------
  function fn_zzz (p_flg_pais in varchar2,
                   p_fecha    in date,
                   p_local    in number,
                   p_terminal in number,
                   p_cierrey  in number) return number is
    type t_num is table of number index by pls_integer;
    v_f    t_num;
    v_expr varchar2(4000);
    v_sql  varchar2(4000);
  begin
    pr_config(p_flg_pais);
    for k in 1 .. 7 loop
      v_expr := null;
      for r in (select z.vta_cmp_asoc, z.vta_signo
                  from VTA_PAINT_Z z
                 where z.vta_localiz = g_cfg.localiz
                   and z.vta_validadorzzz = k
                   and z.vta_cmp_asoc is not null
                 order by z.vta_order_z) loop
        v_expr := v_expr || case when v_expr is not null then ' + ' end
               || 'nvl(sum(' || r.vta_cmp_asoc || '),0) * ' || nvl(trim(r.vta_signo), '+') || '1';
      end loop;

      if v_expr is null then
        v_f(k) := 0;
      else
        v_sql := 'select ' || v_expr ||
                 ' from VTA_{P}LIBVTA l, VTA_{P}ZZZ r' ||
                 ' where l.vta_fecha_venta = :f and l.vta_local = :lo and l.vta_terminal = :te' ||
                 q'[ and l.vta_estado = 'A' and l.vta_techkey = r.rec_techkey]';
        if p_cierrey is null then
          -- PROC_YZ: formula ZZZ de la Z (RZ-08, FuncMontoValidaZZZ :4105): libro 'F8', sin Y
          v_sql := v_sql || ' and l.vta_tiporeg = ''' || g_cfg.nivel_z || '''';
          execute immediate fn_r(v_sql) into v_f(k) using p_fecha, p_local, p_terminal;
        else
          v_sql := v_sql || q'[ and l.vta_tiporeg = '{NIVEL}' and l.vta_secuencia = :y]';
          execute immediate fn_r(v_sql) into v_f(k) using p_fecha, p_local, p_terminal, p_cierrey;
        end if;
        v_f(k) := nvl(v_f(k), 0);
      end if;
    end loop;
    return round(v_f(7) - v_f(6) - v_f(5) - v_f(4) - v_f(3) - v_f(2) - v_f(1), fn_dec);
  end fn_zzz;

  -- ---------------------------------------------------------------
  -- Validaciones Y (orden de Form3Y.CierraTerminal; estado y DR se
  -- evaluan antes en el proceso, segun el diagrama del Proceso 2)
  -- ---------------------------------------------------------------
  procedure pr_valida_y (p_flg_pais in  varchar2,
                         p_fecha    in  date,
                         p_local    in  number,
                         p_terminal in  number,
                         p_cierrey  in  number,
                         o_regla    out varchar2,
                         o_mensaje  out varchar2) is
    v_c   t_conceptos := fn_conceptos;
    v_k   varchar2(2);
    v_zzz number;
  begin
    pr_config(p_flg_pais);
    o_regla := null; o_mensaje := null;

    -- RY-01 cheque a fecha
    if fn_param(p_flg_pais, 'CA_VAL_CHEQ', 'S') = 'S' then
      o_mensaje := fn_msg_cheque_fecha(p_flg_pais, p_fecha, p_local, p_terminal);
      if o_mensaje is not null then o_regla := 'RY-01'; return; end if;
    end if;

    -- RY-03 conceptos sin regularizar en la Y (orden del exe)
    for i in 1 .. 10 loop
      v_k := case i when 1 then 'SN' when 2 then 'AF' when 3 then 'ND' when 4 then 'FN'
                    when 5 then 'NP' when 6 then 'BF' when 7 then 'CR' when 8 then 'CT'
                    when 9 then 'CA' else 'DP' end;
      if fn_concepto_pendiente(p_flg_pais, p_fecha, p_local, p_terminal, p_cierrey, v_k) then
        o_regla := 'RY-03'; o_mensaje := v_c(v_k); return;
      end if;
    end loop;

    -- RY-06 formula ZZZ (opcion 103 del exe, aqui flag)
    if fn_param(p_flg_pais, 'CA_VAL_ZZZ', 'N') = 'S' then
      v_zzz := fn_zzz(p_flg_pais, p_fecha, p_local, p_terminal, p_cierrey);
      if v_zzz <> 0 then
        o_regla := 'RY-06';
        o_mensaje := 'Error, Y descuadrada, favor revisar... diferencia : ' || v_zzz;
        return;
      end if;
    end if;
  end pr_valida_y;

  -- =================================================================
  -- PROC_YZ: validaciones de la Z (Form3.CierraTerminal :3439)
  -- =================================================================

  -- RZ-07 Todas las Y del terminal y dia cerradas (FuncValidadCierreyyyy :2153).
  -- Diferencias con el exe, a pedido del negocio ("para cerrar la Z deben
  -- estar cerradas todas las Y"):
  --   * revisa TODAS las filas de VTA_<pfx>TERMSTATY del terminal-dia (el exe
  --     solo las que tienen libro de ventas de la Y);
  --   * sin ninguna Y la Z NO se cierra (el exe avisa y deja seguir, D2),
  --     salvo CA_Z_SIN_Y = S.
  -- o_resultado: null (OK), Z_SIN_Y o Z_Y_ABIERTAS.
  procedure pr_y_cerradas (p_fecha     in  date,
                           p_local     in  number,
                           p_terminal  in  number,
                           o_resultado out varchar2,
                           o_mensaje   out varchar2) is
    v_total number;
    v_y     number;
    v_est   number;
  begin
    o_resultado := null; o_mensaje := null;
    execute immediate fn_r(
      q'[select count(*) from VTA_{P}TERMSTATY t
          where t.ter_fecha = :1 and t.ter_local = :2 and t.ter_terminal = :3]')
      into v_total using p_fecha, p_local, p_terminal;

    if v_total = 0 then
      if fn_param(g_cfg.pais, 'CA_Z_SIN_Y', 'N') <> 'S' then
        o_resultado := 'Z_SIN_Y';
        o_mensaje   := 'El terminal no tiene cierres Y para el dia: la Z no se cierra (CA_Z_SIN_Y = N)';
      end if;
      return;
    end if;

    -- Primera Y no cerrada (estado distinto de 1: -1/0 pendiente, 2 impreso, 3 sin dato)
    begin
      execute immediate fn_r(
        q'[select y, e from (
             select t.ter_cierrey y, nvl(t.ter_estado, 0) e
               from VTA_{P}TERMSTATY t
              where t.ter_fecha = :1 and t.ter_local = :2 and t.ter_terminal = :3
                and nvl(t.ter_estado, 0) <> 1
              order by t.ter_cierrey)
            where rownum = 1]')
        into v_y, v_est using p_fecha, p_local, p_terminal;
    exception
      when no_data_found then
        return;   -- todas cerradas
    end;

    o_resultado := 'Z_Y_ABIERTAS';
    o_mensaje   := 'No se puede cerrar el terminal, Porque se encuentra con estado '
                   || case when v_est in (-1, 0) then 'Pendiente'
                           when v_est = 2 then 'Impreso'
                           when v_est = 3 then 'Sin dato'
                           else 'desconocido (' || v_est || ')' end
                   || ', el N de cierre de Y : ' || v_y || ' del terminal : ' || p_terminal;
  end pr_y_cerradas;

  -- RZ-06 Z = suma de las Y (Modulo1.FuncValidarZSumaY :5531 / FuncBuscaValorCampoLib).
  -- Por cada campo de VTA_PAINT_Z del pais sin pop-up y con vta_order_z fuera
  -- de 56..76: suma en libro 'F8' + zzz + TERMSTAT contra suma en libro 'Y' +
  -- zzz + TERMSTATY (vta_secuencia = ter_cierrey). Devuelve el mensaje de la
  -- primera diferencia, o NULL si cuadra.
  function fn_z_suma_y (p_flg_pais in varchar2,
                        p_fecha    in date,
                        p_local    in number,
                        p_terminal in number) return varchar2 is
    v_z  number;
    v_y  number;
  begin
    pr_config(p_flg_pais);
    for c in (select trim(z.vtaglosa_z) glosa, trim(z.vta_cmp_asoc) campo
                from VTA_PAINT_Z z
               where z.vta_localiz = g_cfg.localiz
                 and nvl(z.vta_pop_up, 0) = 0
                 and z.vta_cmp_asoc is not null
                 and (z.vta_order_z < 56 or z.vta_order_z > 76)
               order by z.vta_order_z) loop
      execute immediate fn_r(
        'select nvl(sum(' || c.campo || '), 0)'
        || ' from VTA_{P}LIBVTA l, VTA_{P}ZZZ r, VTA_{P}TERMSTAT t'
        || ' where l.vta_tiporeg = ''' || g_cfg.nivel_z || ''''
        || ' and l.vta_fecha_venta = :1 and l.vta_local = :2 and l.vta_terminal = :3'
        || q'[ and l.vta_estado = 'A' and l.vta_techkey = r.rec_techkey]'
        || ' and l.vta_fecha_venta = t.ter_fecha and l.vta_local = t.ter_local'
        || ' and l.vta_terminal = t.ter_terminal')
        into v_z using p_fecha, p_local, p_terminal;

      execute immediate fn_r(
        'select nvl(sum(' || c.campo || '), 0)'
        || ' from VTA_{P}LIBVTA l, VTA_{P}ZZZ r, VTA_{P}TERMSTATY t'
        || q'[ where l.vta_tiporeg = '{NIVEL}']'
        || ' and l.vta_fecha_venta = :1 and l.vta_local = :2 and l.vta_terminal = :3'
        || q'[ and l.vta_estado = 'A' and l.vta_techkey = r.rec_techkey]'
        || ' and l.vta_fecha_venta = t.ter_fecha and l.vta_local = t.ter_local'
        || ' and l.vta_terminal = t.ter_terminal and l.vta_secuencia = t.ter_cierrey')
        into v_y using p_fecha, p_local, p_terminal;

      if v_z - v_y <> 0 then
        return 'En el monto ' || c.glosa || ' Existe diferencia entre el Z y la sumatoria de las Y'
               || ' (Z ' || v_z || ' / suma Y ' || v_y || ')';
      end if;
    end loop;
    return null;
  end fn_z_suma_y;

  -- RZ-09 Dolares declarados vs dolares de la transportadora
  -- (Form3.FuncvalidarDifDolares :1966). 0 = cuadra.
  function fn_dolares_z (p_flg_pais in varchar2,
                         p_fecha    in date,
                         p_local    in number,
                         p_terminal in number) return number is
    v t_nums;
  begin
    pr_config(p_flg_pais);
    v := fn_sql_nums(fn_r(
      q'[select (select nvl(sum(nvl(r.mex_cantidad, 0) * -1), 0)
                   from VTA_{P}RECMEX r
                  where r.mex_fecha = :b_fecha and r.mex_local = :b_local
                    and r.id_mdareg = {USD} and r.mex_terminal = :b_term)
              + (select nvl(sum(nvl(p.prv_montosobre, 0) + nvl(p.prv_montodif, 0)), 0)
                   from VTA_{P}PRD p
                  where p.prv_fechavta = :b_fecha and p.prv_tiporec = 'DOL'
                    and p.prv_local = :b_local and p.prv_terminal = :b_term)
           from dual]'),
      1, p_fecha, p_local, p_terminal, null);
    return round(nvl(v(1), 0), fn_dec);
  end fn_dolares_z;

  -- Validaciones de "Cerrar Terminal" de la Z (Form3.CierraTerminal) salvo el
  -- estado (RZ-02) y la diferencia real (RZ-05), que se evaluan antes en
  -- pr_procesa_z, como en la Y. o_regla null = todas OK. Orden:
  --   RZ-07 Y cerradas (primero: es el requisito del negocio)
  --   RZ-01 cheque a fecha (CA_VAL_CHEQ; el exe exime perfiles 8/10/12, aqui no hay perfil)
  --   RZ-03 conceptos sin regularizar en TODO el dia
  --   RZ-06 Z = suma de las Y (CA_Z_VAL_SUMA)
  --   RZ-08 formula ZZZ de la Z (CA_VAL_ZZZ, opcion 103 del exe)
  --   RZ-09 dolares (CA_Z_VAL_DOL, opcion 109 del exe)
  procedure pr_valida_z (p_flg_pais in  varchar2,
                         p_fecha    in  date,
                         p_local    in  number,
                         p_terminal in  number,
                         o_regla    out varchar2,
                         o_mensaje  out varchar2) is
    v_c   t_conceptos := fn_conceptos;
    v_k   varchar2(2);
    v_res varchar2(30);
    v_num number;
  begin
    pr_config(p_flg_pais);
    o_regla := null; o_mensaje := null;

    -- RZ-07 todas las Y cerradas
    pr_y_cerradas(p_fecha, p_local, p_terminal, v_res, o_mensaje);
    if v_res is not null then o_regla := 'RZ-07'; return; end if;

    -- RZ-01 cheque a fecha (dia completo, igual que la Y)
    if fn_param(p_flg_pais, 'CA_VAL_CHEQ', 'S') = 'S' then
      o_mensaje := fn_msg_cheque_fecha(p_flg_pais, p_fecha, p_local, p_terminal);
      if o_mensaje is not null then o_regla := 'RZ-01'; return; end if;
    end if;

    -- RZ-03 conceptos sin regularizar en el dia (sin filtro de Y)
    for i in 1 .. 10 loop
      v_k := case i when 1 then 'SN' when 2 then 'AF' when 3 then 'ND' when 4 then 'FN'
                    when 5 then 'NP' when 6 then 'BF' when 7 then 'CR' when 8 then 'CT'
                    when 9 then 'CA' else 'DP' end;
      if fn_concepto_pendiente(p_flg_pais, p_fecha, p_local, p_terminal, null, v_k) then
        o_regla := 'RZ-03'; o_mensaje := v_c(v_k); return;
      end if;
    end loop;

    -- RZ-06 Z = suma de las Y
    if fn_param(p_flg_pais, 'CA_Z_VAL_SUMA', 'S') = 'S' then
      o_mensaje := fn_z_suma_y(p_flg_pais, p_fecha, p_local, p_terminal);
      if o_mensaje is not null then o_regla := 'RZ-06'; return; end if;
    end if;

    -- RZ-08 formula ZZZ de la Z
    if fn_param(p_flg_pais, 'CA_VAL_ZZZ', 'N') = 'S' then
      v_num := fn_zzz(p_flg_pais, p_fecha, p_local, p_terminal, null);
      if v_num <> 0 then
        o_regla := 'RZ-08';
        o_mensaje := 'Error, Z descuadrada, favor revisar... diferencia : ' || v_num;
        return;
      end if;
    end if;

    -- RZ-09 dolares declarados = dolares de la transportadora
    if fn_param(p_flg_pais, 'CA_Z_VAL_DOL', 'N') = 'S' then
      v_num := fn_dolares_z(p_flg_pais, p_fecha, p_local, p_terminal);
      if v_num <> 0 then
        o_regla := 'RZ-09';
        o_mensaje := 'Error, existen diferencias entre los dolares declarados y los dolares informado'
                     || ' por Prosegur , favor revisar... diferencia ' || v_num;
        return;
      end if;
    end if;
  end pr_valida_z;

  -- ---------------------------------------------------------------
  -- Marca las filas de la cola de una caja.
  --   Proceso automatico (T2): solo las de SU carga (E de esta ejecucion); los
  --     sobres que llegaron mientras corria (P) quedan para la siguiente.
  --   Consultas de Cuadratura (CC): las pendientes (P o E) de la caja.
  --   p_estado null = no cambia el estado (cierre CC que no cerro la caja).
  -- ---------------------------------------------------------------
  procedure pr_marca_cola (p_fecha in date, p_local in number, p_terminal in number,
                           p_cierrey in number, p_estado in varchar2,
                           p_resultado in varchar2, p_mensaje in varchar2) is
    v_filtro varchar2(200);
  begin
    if g_proceso = 'CC' then
      v_filtro := q'[q.pcr_estado in ('P', 'E')]';
    else
      v_filtro := q'[q.pcr_estado = 'E' and q.pcr_ejecucion = ]' || to_char(trunc(g_ejecucion));
    end if;
    execute immediate fn_r(
      q'[update VTA_{P}PRD_CIERRE q
            set q.pcr_estado    = nvl(:1, q.pcr_estado),
                q.pcr_resultado = :2,
                q.pcr_mensaje   = :3,
                q.pcr_fechaproc = sysdate,
                q.pcr_ejecucion = :4,
                q.pcr_intentos  = q.pcr_intentos + 1
          where ]' || v_filtro || q'[
            and q.prv_fechavta = :5
            and q.prv_local    = :6
            and q.prv_terminal = :7
            and q.prv_cierrey  = :8]')
      using p_estado, p_resultado, substr(p_mensaje, 1, 1000), g_ejecucion,
            p_fecha, p_local, p_terminal, p_cierrey;
  end pr_marca_cola;

  function fn_nota (p_nota_actual in varchar2,
                    p_nivel       in varchar2 default 'Y',
                    p_largo       in number   default 2500) return varchar2 is
  begin
    -- La nota distingue el cierre desde Consultas de Cuadratura.
    -- PROC_YZ: la Z lleva 'Z' en la nota; la de la Y no cambia.
    return substr(case when g_proceso = 'CC' then 'CIERRE CC ' else 'CIERRE AUTOMATICO ' end
                  || case when p_nivel = 'Z' then 'Z FSCC-12901 '
                          when g_proceso = 'CC' then 'FSCC-12901 '
                          else 'FSCC-12958 ' end
                  || to_char(sysdate, 'dd-mm-yyyy hh24:mi')
                  || case when p_nota_actual is not null then ' | ' || p_nota_actual end, 1, p_largo);
  end fn_nota;

  -- Largo de TER_NOTAS en VTA_<pfx>TERMSTAT (la nota de la Z se corta a ese largo)
  function fn_largo_notas_z return number is
  begin
    if g_len_notas_z is null then
      begin
        select c.data_length into g_len_notas_z
          from user_tab_columns c
         where c.table_name = 'VTA_' || g_cfg.prefijo || 'TERMSTAT'
           and c.column_name = 'TER_NOTAS';
      exception
        when no_data_found then
          g_len_notas_z := 100;   -- prudente si no se encuentra (paquete con otro duenio)
      end;
    end if;
    return g_len_notas_z;
  end fn_largo_notas_z;

  -- ---------------------------------------------------------------
  -- Proceso de una Y (Proceso 2 del diagrama). o_resultado = log_resultado
  -- (CERRADA_Y, YA_CERRADA, CON_DIFERENCIA, BLOQUEADA, SIN_LIBVTA, OCUPADA, ...)
  -- Estado final de la cola (v2, una ejecucion por carga):
  --   proceso automatico (T2): C con el resultado, salvo OCUPADA que vuelve a P;
  --   Consultas de Cuadratura (CC): C solo si cerro; si no, sin cambio.
  -- ---------------------------------------------------------------
  procedure pr_procesa_y (p_fecha in date, p_local in number, p_terminal in number, p_cierrey in number,
                          o_resultado out varchar2) is
    v_estado  number;
    v_notas   varchar2(2500);
    v_nota    varchar2(2500);   -- nota nueva (fn_nota es privada: no se puede usar dentro del SQL, PLS-00231)
    v_dr      number;
    v_regla   varchar2(10);
    v_msg     varchar2(1000);
    v_fin     varchar2(1);      -- estado de cola para una caja que no se cierra
  begin
    v_fin := case when g_proceso = 'CC' then null else 'C' end;
    savepoint sp_y;

    begin
      execute immediate fn_r(
        q'[select t.ter_estado, t.ter_notas
             from VTA_{P}TERMSTATY t
            where t.ter_fecha = :1 and t.ter_local = :2
              and t.ter_terminal = :3 and t.ter_cierrey = :4
              for update nowait]')
        into v_estado, v_notas
        using p_fecha, p_local, p_terminal, p_cierrey;
    exception
      when no_data_found then
        pr_marca_cola(p_fecha, p_local, p_terminal, p_cierrey, v_fin, 'SIN_TERMSTAT', 'No existe el cierre Y en VTA_' || g_cfg.prefijo || 'TERMSTATY');
        commit;
        o_resultado := 'SIN_TERMSTAT';
        pr_log('Y', p_fecha, p_local, p_terminal, p_cierrey, null, 'SIN_TERMSTAT', 'RY-02', 'No existe el cierre Y en VTA_' || g_cfg.prefijo || 'TERMSTATY');
        return;
      when e_ocupada then
        pr_marca_cola(p_fecha, p_local, p_terminal, p_cierrey,
                      case when g_proceso = 'CC' then null else 'P' end,
                      'OCUPADA', 'Caja bloqueada por otro usuario');
        commit;
        o_resultado := 'OCUPADA';
        pr_log('Y', p_fecha, p_local, p_terminal, p_cierrey, null, 'OCUPADA', null, 'Caja bloqueada por otro usuario');
        return;
    end;

    -- RY-02 estado: 1 cerrado, 2 impreso, 3 sin datos -> no se reabre
    if v_estado > 0 then
      rollback to sp_y;
      pr_marca_cola(p_fecha, p_local, p_terminal, p_cierrey, 'C', 'YA_CERRADA', 'Terminal ya se Encuentra Cerrado');
      commit;
      o_resultado := 'YA_CERRADA';
      pr_log('Y', p_fecha, p_local, p_terminal, p_cierrey, null, 'YA_CERRADA', 'RY-02', 'Terminal ya se Encuentra Cerrado (estado ' || v_estado || ')');
      return;
    end if;

    -- Recalcular la Diferencia Real (diagrama) / RY-05
    v_dr := fn_dif_real(g_cfg.pais, p_fecha, p_local, p_terminal, p_cierrey);
    if v_dr is null then
      rollback to sp_y;
      pr_marca_cola(p_fecha, p_local, p_terminal, p_cierrey, v_fin, 'SIN_LIBVTA', 'No hay Z disponible (sin libro de ventas de la Y)');
      commit;
      o_resultado := 'SIN_LIBVTA';
      pr_log('Y', p_fecha, p_local, p_terminal, p_cierrey, null, 'SIN_LIBVTA', null, 'No hay Z disponible (sin libro de ventas de la Y)');
      return;
    elsif v_dr <> 0 then
      rollback to sp_y;
      pr_marca_cola(p_fecha, p_local, p_terminal, p_cierrey, v_fin, 'CON_DIFERENCIA', 'Falta Monto por Compensar');
      commit;
      o_resultado := 'CON_DIFERENCIA';
      pr_log('Y', p_fecha, p_local, p_terminal, p_cierrey, v_dr, 'CON_DIFERENCIA', 'RY-05', 'Falta Monto por Compensar');
      return;
    end if;

    -- Validaciones de Cerrar Terminal
    pr_valida_y(g_cfg.pais, p_fecha, p_local, p_terminal, p_cierrey, v_regla, v_msg);
    if v_regla is not null then
      rollback to sp_y;
      pr_marca_cola(p_fecha, p_local, p_terminal, p_cierrey, v_fin, 'BLOQUEADA', v_regla || ' ' || v_msg);
      commit;
      o_resultado := 'BLOQUEADA';
      pr_log('Y', p_fecha, p_local, p_terminal, p_cierrey, v_dr, 'BLOQUEADA', v_regla, v_msg);
      return;
    end if;

    -- Cerrar el cierre Y: estado cerrado, usuario de proceso, fecha y nota.
    v_nota := fn_nota(v_notas);
    execute immediate fn_r(
      q'[update VTA_{P}TERMSTATY t
            set t.ter_estado     = 1,
                t.ter_cerradopor = :1,
                t.ter_notas      = :2
          where t.ter_fecha = :3 and t.ter_local = :4
            and t.ter_terminal = :5 and t.ter_cierrey = :6]')
      using g_usuario, v_nota, p_fecha, p_local, p_terminal, p_cierrey;

    pr_marca_cola(p_fecha, p_local, p_terminal, p_cierrey, 'C', 'CERRADA_Y', null);
    commit;
    o_resultado := 'CERRADA_Y';
    pr_log('Y', p_fecha, p_local, p_terminal, p_cierrey, v_dr, 'CERRADA_Y', null, null);

  exception
    when others then
      v_msg := substr(sqlerrm, 1, 1000);
      begin
        rollback to sp_y;
      exception
        when others then rollback;   -- ORA-01086: el savepoint ya no existe tras un commit
      end;
      pr_marca_cola(p_fecha, p_local, p_terminal, p_cierrey, v_fin, 'ERROR', v_msg);
      commit;
      o_resultado := 'ERROR';
      pr_log('Y', p_fecha, p_local, p_terminal, p_cierrey, null, 'ERROR', null, v_msg);
  end pr_procesa_y;

  -- ---------------------------------------------------------------
  -- PROC_YZ: proceso de la Z de un terminal-dia (Form3.CierraTerminal).
  -- Se llama despues de evaluar las Y, solo si CA_CIERRA_Z = S.
  -- No toca la cola (la cola es por Y). Registra en el log con nivel 'Z' y
  -- log_cierrey nulo. o_resultado = log_resultado:
  --   CERRADA_Z, Z_YA_CERRADA, Z_SIN_TERMSTAT, Z_SIN_Y, Z_Y_ABIERTAS,
  --   Z_SIN_LIBVTA, Z_CON_DIFERENCIA, Z_BLOQUEADA, OCUPADA, ERROR
  -- Orden: bloqueo -> RZ-02 estado -> RZ-07 Y cerradas -> RZ-05 diferencia
  -- real del dia -> pr_valida_z (RZ-01, RZ-03, RZ-06, RZ-08, RZ-09) -> UPDATE.
  -- ---------------------------------------------------------------
  procedure pr_procesa_z (p_fecha in date, p_local in number, p_terminal in number,
                          o_resultado out varchar2) is
    v_estado  number;
    v_notas   varchar2(4000);
    v_nota    varchar2(4000);
    v_dr      number;
    v_regla   varchar2(10);
    v_res     varchar2(30);
    v_msg     varchar2(1000);
  begin
    savepoint sp_z;

    -- Bloquear la Z (D5: el exe no bloquea)
    begin
      execute immediate fn_r(
        q'[select t.ter_estado, t.ter_notas
             from VTA_{P}TERMSTAT t
            where t.ter_fecha = :1 and t.ter_local = :2 and t.ter_terminal = :3
              for update nowait]')
        into v_estado, v_notas
        using p_fecha, p_local, p_terminal;
    exception
      when no_data_found then
        o_resultado := 'Z_SIN_TERMSTAT';
        pr_log('Z', p_fecha, p_local, p_terminal, null, null, 'Z_SIN_TERMSTAT', 'RZ-02',
               'No existe la Z en VTA_' || g_cfg.prefijo || 'TERMSTAT');
        return;
      when e_ocupada then
        o_resultado := 'OCUPADA';
        pr_log('Z', p_fecha, p_local, p_terminal, null, null, 'OCUPADA', null, 'Z bloqueada por otro usuario');
        return;
    end;

    -- RZ-02 estado: 1 cerrado, 2 impreso, 3 sin datos -> no se toca
    if nvl(v_estado, 0) > 0 then
      rollback to sp_z;
      o_resultado := 'Z_YA_CERRADA';
      pr_log('Z', p_fecha, p_local, p_terminal, null, null, 'Z_YA_CERRADA', 'RZ-02',
             'Terminal ya se Encuentra Cerrado (estado ' || v_estado || ')');
      return;
    end if;

    -- RZ-07 todas las Y cerradas (antes de calcular: es lo mas frecuente)
    pr_y_cerradas(p_fecha, p_local, p_terminal, v_res, v_msg);
    if v_res is not null then
      rollback to sp_z;
      o_resultado := v_res;
      pr_log('Z', p_fecha, p_local, p_terminal, null, null, v_res, 'RZ-07', v_msg);
      return;
    end if;

    -- RZ-05 diferencia real del dia (Form3 Label70)
    v_dr := fn_dif_real(g_cfg.pais, p_fecha, p_local, p_terminal, null);
    if v_dr is null then
      rollback to sp_z;
      o_resultado := 'Z_SIN_LIBVTA';
      pr_log('Z', p_fecha, p_local, p_terminal, null, null, 'Z_SIN_LIBVTA', 'RZ-05',
             'No hay libro de ventas de la Z (vta_tiporeg ' || g_cfg.nivel_z || ')');
      return;
    elsif v_dr <> 0 then
      rollback to sp_z;
      o_resultado := 'Z_CON_DIFERENCIA';
      pr_log('Z', p_fecha, p_local, p_terminal, null, v_dr, 'Z_CON_DIFERENCIA', 'RZ-05', 'Falta Monto por Compensar');
      return;
    end if;

    -- Resto de las validaciones de Cerrar Terminal de la Z
    pr_valida_z(g_cfg.pais, p_fecha, p_local, p_terminal, v_regla, v_msg);
    if v_regla is not null then
      rollback to sp_z;
      o_resultado := case when v_regla = 'RZ-07' then 'Z_Y_ABIERTAS' else 'Z_BLOQUEADA' end;
      pr_log('Z', p_fecha, p_local, p_terminal, null, v_dr, o_resultado, v_regla, v_msg);
      return;
    end if;

    -- Cerrar la Z: estado cerrado, usuario de proceso y nota (Form3 no graba
    -- ter_fechacierre en FACO).
    v_nota := fn_nota(v_notas, 'Z', fn_largo_notas_z);
    execute immediate fn_r(
      q'[update VTA_{P}TERMSTAT t
            set t.ter_estado     = 1,
                t.ter_cerradopor = :1,
                t.ter_notas      = :2
          where t.ter_fecha = :3 and t.ter_local = :4 and t.ter_terminal = :5]')
      using g_usuario, v_nota, p_fecha, p_local, p_terminal;
    commit;
    o_resultado := 'CERRADA_Z';
    pr_log('Z', p_fecha, p_local, p_terminal, null, v_dr, 'CERRADA_Z', null, null);

  exception
    when others then
      v_msg := substr(sqlerrm, 1, 1000);
      begin
        rollback to sp_z;
      exception
        when others then rollback;
      end;
      o_resultado := 'ERROR';
      pr_log('Z', p_fecha, p_local, p_terminal, null, null, 'ERROR', null, v_msg);
  end pr_procesa_z;

  -- Agrega el terminal-dia a la lista de Z a evaluar (sin repetir)
  procedure pr_agrega_term (p_terms in out nocopy t_terms,
                            p_fecha in date, p_local in number, p_terminal in number) is
    v_k varchar2(40) := to_char(p_fecha, 'yyyymmdd') || '|' || lpad(p_local, 6, '0')
                        || '|' || lpad(p_terminal, 6, '0');
    v_r t_term;
  begin
    if not p_terms.exists(v_k) then
      v_r.f := p_fecha;
      v_r.l := p_local;
      v_r.t := p_terminal;
      p_terms(v_k) := v_r;
    end if;
  end pr_agrega_term;

  -- Evalua la Z de cada terminal-dia de la lista. Devuelve cerradas / no cerradas.
  procedure pr_procesa_lista_z (p_terms   in out nocopy t_terms,
                                o_cerr    out number,
                                o_nocer   out number) is
    v_k   varchar2(40);
    v_res varchar2(30);
  begin
    o_cerr := 0; o_nocer := 0;
    v_k := p_terms.first;
    while v_k is not null loop
      pr_procesa_z(p_terms(v_k).f, p_terms(v_k).l, p_terms(v_k).t, v_res);
      if v_res = 'CERRADA_Z' then
        o_cerr := o_cerr + 1;
      elsif v_res <> 'Z_YA_CERRADA' then
        o_nocer := o_nocer + 1;
      end if;
      v_k := p_terms.next(v_k);
    end loop;
  end pr_procesa_lista_z;

  -- ---------------------------------------------------------------
  -- Punto de entrada del proceso automatico (T1 -> T2). Cierres Y y, con
  -- CA_CIERRA_Z = S, la Z de cada terminal-dia evaluado (PROC_YZ).
  -- ---------------------------------------------------------------
  procedure prc_cierre_automatico (p_flg_pais  in varchar2,
                                   p_usuario   in varchar2 default 'PROC_CIERRE_AUTO',
                                   p_max_cajas in number   default null) is
    v_cur   sys_refcursor;
    v_f     date;
    v_l     number;
    v_t     number;
    v_y     number;
    v_n     number := 0;
    v_cerr  number := 0;
    v_nocer number := 0;
    v_carga number;
    v_res   varchar2(30);
    v_terms t_terms;          -- PROC_YZ: terminal-dia de las Y evaluadas
    v_zcerr  number := 0;
    v_znocer number := 0;
    v_txt_z  varchar2(200);
  begin
    pr_config(p_flg_pais);
    g_proceso   := 'T2';   -- el estado del paquete persiste en la sesion
    g_usuario   := nvl(substr(p_usuario, 1, 50), c_usuario_def);
    g_dec       := null;
    g_ejecucion := fn_nueva_ejecucion(g_cfg.pais);

    -- Interruptores independientes: CA_DI_ACTIVO (T1) y CA_ACTIVO (T2).
    -- Si ambos estan apagados no se hace nada (la cola queda pendiente).
    if fn_param(g_cfg.pais, 'CA_ACTIVO', 'N') <> 'S' and fn_param(g_cfg.pais, 'CA_DI_ACTIVO', 'N') <> 'S' then
      pr_log('-', null, null, null, null, null, 'INACTIVO', null, 'Parametros 1502 CA_ACTIVO y CA_DI_ACTIVO distintos de S');
      return;
    end if;
    pr_log('-', null, null, null, null, null, 'INICIO', null, 'Pais ' || g_cfg.pais || ' | usuario ' || g_usuario);

    -- Sobres sin cierre Y: no se pueden asociar a una caja.
    -- PRV_CIERREY es NUMBER(2) NOT NULL DEFAULT 0 en VTA_<pfx>PRD: 0 = sin Y.
    execute immediate fn_r(
      q'[update VTA_{P}PRD_CIERRE q
            set q.pcr_estado = 'O', q.pcr_resultado = 'SIN_CIERREY',
                q.pcr_mensaje = 'Sobre sin numero de cierre Y', q.pcr_fechaproc = sysdate,
                q.pcr_ejecucion = :1
          where q.pcr_estado in ('P', 'E') and nvl(q.prv_cierrey, 0) = 0]')
      using g_ejecucion;

    -- Tomar la carga (modo CARGA): lo pendiente pasa a E con esta ejecucion.
    -- Incluye filas E de una ejecucion anterior que no termino.
    -- Lo que llegue mientras corre el proceso queda en P para la siguiente.
    execute immediate fn_r(
      q'[update VTA_{P}PRD_CIERRE q
            set q.pcr_estado = 'E', q.pcr_ejecucion = :1
          where q.pcr_estado in ('P', 'E')]')
      using g_ejecucion;
    v_carga := sql%rowcount;
    commit;

    -- T1: compensacion automatica de DI sobre las mismas cajas, ANTES del
    -- cierre (diagrama general: T1 -> T2). T1 revisa su propio interruptor
    -- (CA_DI_ACTIVO) y registra en el mismo log con log_proceso = 'T1'.
    -- Un error en T1 no impide ejecutar T2.
    begin
      PKG_F8_COMPENSA_DI_AUTO.prc_compensa_di(p_flg_pais  => g_cfg.pais,
                                              p_ejecucion => g_ejecucion,
                                              p_max_cajas => p_max_cajas);
    exception
      when others then
        pr_log('-', null, null, null, null, null, 'ERROR', null,
               'Fallo T1 (PKG_F8_COMPENSA_DI_AUTO): ' || substr(sqlerrm, 1, 900));
    end;
    pr_config(p_flg_pais);   -- T1 puede haber usado otro pais en esta sesion

    -- T2 apagado: la carga queda procesada solo por T1
    if fn_param(g_cfg.pais, 'CA_ACTIVO', 'N') <> 'S' then
      execute immediate fn_r(
        q'[update VTA_{P}PRD_CIERRE q
              set q.pcr_estado = 'C', q.pcr_resultado = 'SOLO_T1', q.pcr_fechaproc = sysdate,
                  q.pcr_mensaje = 'CA_ACTIVO distinto de S: la carga se evaluo solo con T1'
            where q.pcr_estado = 'E' and q.pcr_ejecucion = :1]')
        using g_ejecucion;
      commit;
      pr_log('-', null, null, null, null, null, 'INACTIVO', null, 'Parametro 1502 CA_ACTIVO distinto de S: solo se ejecuto T1');
      return;
    end if;

    -- Cierres Y de la carga (cola E + cajas sin sobres del mismo local-dia;
    -- incluye las que ya tenian DR 0 y las compensadas por T1).
    v_cur := fn_universo(g_cfg.pais, g_ejecucion);
    loop
      fetch v_cur into v_f, v_l, v_t, v_y;
      exit when v_cur%notfound;
      exit when p_max_cajas is not null and v_n >= p_max_cajas;
      v_n := v_n + 1;
      pr_procesa_y(v_f, v_l, v_t, v_y, v_res);
      if v_res = 'CERRADA_Y' then
        v_cerr := v_cerr + 1;
      elsif v_res <> 'YA_CERRADA' then
        v_nocer := v_nocer + 1;
      end if;
      pr_agrega_term(v_terms, v_f, v_l, v_t);
    end loop;
    close v_cur;

    -- Lo que quedo en E (limite p_max_cajas) vuelve a P para la siguiente ejecucion.
    execute immediate fn_r(
      q'[update VTA_{P}PRD_CIERRE q
            set q.pcr_estado = 'P', q.pcr_resultado = 'NO_EVALUADA'
          where q.pcr_estado = 'E' and q.pcr_ejecucion = :1]')
      using g_ejecucion;
    commit;

    -- PROC_YZ: la Z de cada terminal-dia evaluado, si CA_CIERRA_Z = S
    -- (con N la Z no se toca, igual que PROC_Y).
    if fn_param(g_cfg.pais, 'CA_CIERRA_Z', 'N') = 'S' then
      pr_procesa_lista_z(v_terms, v_zcerr, v_znocer);
      v_txt_z := ' | Z evaluadas: ' || v_terms.count || ' | Z cerradas: ' || v_zcerr
                 || ' | Z no cerradas: ' || v_znocer;
    end if;

    pr_log('-', null, null, null, null, null, 'FIN', null,
           'Sobres de la carga: ' || v_carga || ' | Cierres Y evaluados: ' || v_n
           || ' | Y cerradas: ' || v_cerr || ' | Y no cerradas: ' || v_nocer || v_txt_z);
  exception
    when others then
      if v_cur%isopen then
        close v_cur;
      end if;
      rollback;
      pr_log('-', null, null, null, null, null, 'ERROR', null, sqlerrm);
      raise;
  end prc_cierre_automatico;

  -- ---------------------------------------------------------------
  -- Punto de entrada de Consultas de Cuadratura (Form43, boton "Cerrar
  -- Terminal"), un dia por vez. DF-SCC fila 12: cerrar desde CC las cajas
  -- con Diferencia Real 0, incluidas las cajas sin movimiento. Cierres Y y,
  -- con CA_CIERRA_Z = S, las Z abiertas del dia (PROC_YZ).
  -- ---------------------------------------------------------------
  procedure prc_cierre_dia (p_flg_pais    in  varchar2,
                            p_fecha       in  varchar2,
                            p_local       in  number,
                            p_terminal    in  number,
                            p_usuario     in  varchar2,
                            o_ejecucion   out number,
                            o_cerradas    out number,
                            o_no_cerradas out number) is
    v_dia   date;
    v_cur   sys_refcursor;
    v_f     date;
    v_l     number;
    v_t     number;
    v_y     number;
    v_res   varchar2(30);
    v_n     number := 0;
    v_terms  t_terms;         -- PROC_YZ
    v_zcerr  number := 0;
    v_znocer number := 0;
    v_txt_z  varchar2(200);
  begin
    o_cerradas    := 0;
    o_no_cerradas := 0;
    pr_config(p_flg_pais);
    g_proceso   := 'CC';
    g_usuario   := nvl(substr(trim(p_usuario), 1, 50), c_usuario_def);
    g_dec       := null;
    g_ejecucion := fn_nueva_ejecucion(g_cfg.pais);
    o_ejecucion := g_ejecucion;
    -- Un solo dia de venta (yyyymmdd), obligatorio
    if trim(p_fecha) is null then
      raise_application_error(-20002, 'Fecha obligatoria (yyyymmdd) para el cierre desde Consultas de Cuadratura');
    end if;
    v_dia := to_date(trim(p_fecha), 'yyyymmdd');

    pr_log('-', v_dia, p_local, nullif(p_terminal, 0), null, null, 'INICIO', null,
           'Consultas de Cuadratura dia ' || to_char(v_dia, 'dd-mm-yyyy') || ' usuario ' || g_usuario);

    -- Cierres Y abiertos con libro de ventas del dia (mismo universo que Form43)
    open v_cur for fn_r(
      q'[select distinct t.ter_fecha f, t.ter_local l, t.ter_terminal te, t.ter_cierrey y
           from VTA_{P}TERMSTATY t, VTA_{P}LIBVTA l, VTA_{P}ZZZ r
          where t.ter_fecha = :1
            and t.ter_local = :2
            and (nvl(:3, 0) = 0 or t.ter_terminal = :4)
            and t.ter_estado <= 0
            and l.vta_tiporeg = '{NIVEL}'
            and l.vta_estado = 'A'
            and l.vta_techkey = r.rec_techkey
            and l.vta_fecha_venta = t.ter_fecha
            and l.vta_local = t.ter_local
            and l.vta_terminal = t.ter_terminal
            and l.vta_secuencia = t.ter_cierrey
          order by 1, 2, 3, 4]')
      using v_dia, p_local, p_terminal, p_terminal;
    loop
      fetch v_cur into v_f, v_l, v_t, v_y;
      exit when v_cur%notfound;
      v_n := v_n + 1;
      pr_procesa_y(v_f, v_l, v_t, v_y, v_res);
      if v_res = 'CERRADA_Y' then
        o_cerradas := o_cerradas + 1;
      elsif v_res <> 'YA_CERRADA' then
        o_no_cerradas := o_no_cerradas + 1;
      end if;
    end loop;
    close v_cur;

    -- PROC_YZ: Z abiertas del dia, local y terminal (0 = todos), si CA_CIERRA_Z = S.
    -- Como Form43 para FACO: primero las Y y despues las Z. Incluye terminales
    -- cuyas Y ya estaban cerradas. Los contadores de salida siguen siendo de Y
    -- (misma firma que usa Form43); el resumen de la Z va en el FIN del log.
    if fn_param(g_cfg.pais, 'CA_CIERRA_Z', 'N') = 'S' then
      open v_cur for fn_r(
        q'[select t.ter_fecha, t.ter_local, t.ter_terminal
             from VTA_{P}TERMSTAT t
            where t.ter_fecha = :1
              and t.ter_local = :2
              and (nvl(:3, 0) = 0 or t.ter_terminal = :4)
              and nvl(t.ter_estado, 0) <= 0
            order by 1, 2, 3]')
        using v_dia, p_local, p_terminal, p_terminal;
      loop
        fetch v_cur into v_f, v_l, v_t;
        exit when v_cur%notfound;
        pr_agrega_term(v_terms, v_f, v_l, v_t);
      end loop;
      close v_cur;
      pr_procesa_lista_z(v_terms, v_zcerr, v_znocer);
      v_txt_z := ' | Z evaluadas: ' || v_terms.count || ' | Z cerradas: ' || v_zcerr
                 || ' | Z no cerradas: ' || v_znocer;
    end if;

    pr_log('-', v_dia, p_local, nullif(p_terminal, 0), null, null, 'FIN', null,
           'Cierres Y evaluados: ' || v_n || ' | Y cerradas: ' || o_cerradas
           || ' | Y no cerradas: ' || o_no_cerradas || v_txt_z);
    g_proceso := 'T2';
  exception
    when others then
      if v_cur%isopen then
        close v_cur;
      end if;
      rollback;
      pr_log('-', null, p_local, nullif(p_terminal, 0), null, null, 'ERROR', null, sqlerrm);
      g_proceso := 'T2';
      raise;
  end prc_cierre_dia;

end PKG_F8_CIERRE_AUTO;
/

-- #####################################################################
-- ## PARTE 3: TRIGGER TRG_VTA_FACOPRD_CIERRE_AI (desde aqui los sobres entran a la cola)
-- ## Fuente: docs/sql/FSCC-12901_PROC_YZ/08_trigger_FACO.sql (copia sin cambios, igual a PROC_Y)
-- #####################################################################
-- =====================================================================
-- FSCC-12901 v2 MULTIPAIS - Paso 08 (objeto POR PAIS: FACO)
-- Trigger TRG_VTA_FACOPRD_CIERRE_AI: clona cada sobre insertado en VTA_FACOPRD
-- hacia la cola VTA_FACOPRD_CIERRE en estado P. Identico a v1.
-- Se ejecuta para todas las vias de insercion (Form133 carga manual,
-- Form21, Form124, etc.). Solo F8 y DOL.
-- OTRO PAIS: copiar reemplazando FACO por su prefijo (trigger sobre VTA_<pfx>PRD).
-- Si v1 ya esta instalado el trigger ya existe: no hace falta recrearlo.
-- =====================================================================

create or replace trigger TRG_VTA_FACOPRD_CIERRE_AI
after insert on VTA_FACOPRD
for each row
when (new.prv_tiporec in ('F8', 'DOL'))
begin
  insert into VTA_FACOPRD_CIERRE
    (pcr_id, prv_techkey, prv_fechavta, prv_local, prv_terminal, prv_cierrey,
     prv_tiporec, prv_tiposobre, prv_sobre, prv_montosobre, prv_montodif,
     prv_fechadep, prv_cod_recaud, pcr_fechareg, pcr_estado, pcr_intentos)
  values
    (SEQ_VTA_FACOPRD_CIERRE.nextval, :new.prv_techkey, :new.prv_fechavta,
     :new.prv_local, :new.prv_terminal, :new.prv_cierrey,
     :new.prv_tiporec, :new.prv_tiposobre, :new.prv_sobre, :new.prv_montosobre,
     :new.prv_montodif, :new.prv_fechadep, :new.prv_cod_recaud, sysdate, 'P', 0);
exception
  -- DECISION A REVISAR: si la copia falla no se debe impedir la grabacion
  -- del sobre (la carga de recaudacion es prioritaria). El costo es que esa
  -- caja no entra a la cola; README.md trae una consulta de conciliacion
  -- (sobres de VTA_FACOPRD sin fila en VTA_FACOPRD_CIERRE) para detectarlo.
  -- Si negocio prefiere que la carga falle, eliminar este bloque.
  when others then
    null;
end;
/

-- #####################################################################
-- ## PARTE 4: VALIDACION
-- ## Esperado: 9 filas VALID (2 TABLE, 2 SEQUENCE, 2 PACKAGE,
-- ## 2 PACKAGE BODY, 1 TRIGGER) y 0 filas en user_errors.
-- #####################################################################
select object_name, object_type, status from user_objects
 where object_name in ('VTA_FACOPRD_CIERRE','SEQ_VTA_FACOPRD_CIERRE','VTA_FACOLOG_CIERRE_AUTO',
                       'SEQ_VTA_FACOLOG_CIERRE_AUTO','PKG_F8_CIERRE_AUTO',
                       'PKG_F8_COMPENSA_DI_AUTO','TRG_VTA_FACOPRD_CIERRE_AI')
 order by object_type, object_name;
select name, type, line, position, text from user_errors
 where name in ('PKG_F8_CIERRE_AUTO','PKG_F8_COMPENSA_DI_AUTO','TRG_VTA_FACOPRD_CIERRE_AI')
 order by name, type, sequence;
-- Parametros (esperado: 12 filas) y opcion 1515 (esperado: 7 y 9 en -1, resto 0)
select vta_ccodigo, vta_xglosa from VTA_FACOPARAM where vta_ccodtipo = 1502 order by 1;
select r.per_codigo, r.rel_estado from VTA_FACORELPERMEN r where r.mnu_codigo = 1515 order by 1;

-- #####################################################################
-- ## PARTE 5: PERMISOS Y SINONIMOS PARA UINTRANETTS (usuario del exe)
-- ## Fuente: docs/sql/FSCC-12901_PROC_YZ/09_grants_sinonimos.sql,
-- ## con USUARIO_APP = UINTRANETTS y DUENIO = INTRANETTS.
-- ## 5A como INTRANETTS. 5B como DBA (CREATE ANY SYNONYM).
-- #####################################################################
-- 5A: permisos
grant execute on PKG_F8_CIERRE_AUTO       to UINTRANETTS;
grant execute on PKG_F8_COMPENSA_DI_AUTO  to UINTRANETTS;
grant select  on VTA_FACOPRD_CIERRE       to UINTRANETTS;
grant select  on VTA_FACOLOG_CIERRE_AUTO  to UINTRANETTS;

-- 5B: sinonimos (DBA)
create or replace synonym UINTRANETTS.PKG_F8_CIERRE_AUTO      for INTRANETTS.PKG_F8_CIERRE_AUTO;
create or replace synonym UINTRANETTS.PKG_F8_COMPENSA_DI_AUTO for INTRANETTS.PKG_F8_COMPENSA_DI_AUTO;
create or replace synonym UINTRANETTS.VTA_FACOPRD_CIERRE      for INTRANETTS.VTA_FACOPRD_CIERRE;
create or replace synonym UINTRANETTS.VTA_FACOLOG_CIERRE_AUTO for INTRANETTS.VTA_FACOLOG_CIERRE_AUTO;

-- Verificacion (esperado: 4 sinonimos)
select owner, synonym_name, table_owner, table_name from all_synonyms
 where owner = 'UINTRANETTS'
   and synonym_name in ('PKG_F8_CIERRE_AUTO','PKG_F8_COMPENSA_DI_AUTO',
                        'VTA_FACOPRD_CIERRE','VTA_FACOLOG_CIERRE_AUTO');

-- #####################################################################
-- ## PARTE 6 (OPCIONAL, COMENTADA): JOB DEL PROCESO AUTOMATICO
-- ## DBMS_JOB (Oracle 10.2), como INTRANETTS. Descomentar cuando negocio
-- ## defina la frecuencia. EDITAR next_date / interval (ejemplo: cada hora).
-- ## Anotar el numero de job que imprime: lo pide el rollback.
-- ## No ejecutar a la vez con un job de v1 (en test no existe).
-- #####################################################################
-- declare
--   v_job number;
-- begin
--   dbms_job.submit(
--     job       => v_job,
--     what      => 'begin PKG_F8_CIERRE_AUTO.prc_cierre_automatico(p_flg_pais => ''FACO''); end;',
--     next_date => sysdate + 5/1440,
--     interval  => 'sysdate + 1/24');
--   commit;
--   dbms_output.put_line('Job creado: ' || v_job);
-- end;
-- /
-- select job, what, next_date, interval, broken from user_jobs
--  where upper(what) like '%PKG_F8_CIERRE_AUTO%';

-- ===================== FIN TRASPASO FSCC-12901 v2 =====================
