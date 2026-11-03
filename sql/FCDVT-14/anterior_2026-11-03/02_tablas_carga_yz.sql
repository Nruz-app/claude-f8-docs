-- =====================================================================
-- FCDVT-14 - Paso 02: tablas de la carga masiva de cierres Y / Z (FACO)
-- xintec-nruz 30-10-2026
-- Las usa PKG_F8_CARGA_MASIVA_YZ (pasos 03 y 04), llamado desde
-- Form174 (boton Buscar):
--   VTA_FACOCARGA_YZ_DET : una fila por linea del CSV, ya separada y tipada
--   VTA_FACOCARGA_YZ_RES : resumen por fecha / local / terminal (grilla)
--   VTA_FACOCARGA_YZ_LOG : log por carga (INICIO, errores por fila/campo, FIN)
-- Formato del CSV: FORMATO_CARGA_Y_FACO.md (56 columnas).
-- Esta etapa NO graba libvta / zzz / termstat(y): eso lo hara Cargar.
-- =====================================================================

create table VTA_FACOCARGA_YZ_DET (
  det_carga           number          not null,   -- SEQ_VTA_FACOCARGA_YZ (una por archivo)
  det_linea           number          not null,   -- numero de linea en el archivo (1 = encabezado)
  det_texto           varchar2(4000),             -- linea tal como venia
  det_fecha           date,                       -- FECHA (dd-mm-yyyy)
  det_local           number,                     -- LOCAL
  det_terminal        number,                     -- TERMINAL
  det_nro_y           number,                     -- NRO_Y (vacio = se asignara max+1 al cargar)
  det_hora            varchar2(5),                -- HORA (HH:MM)
  det_secuencia       number,                     -- SECUENCIA
  det_num_boleta      number,                     -- NUM_BOLETA
  det_vendedor        number,                     -- VENDEDOR
  det_cont_repo       number,                     -- CONT_REPOSICION
  det_tipo            varchar2(1),                -- TIPO: Y / Z
  det_tipo_carga      varchar2(20),               -- TIPO_CARGA: INGRESAR (MODIFICAR fuera de alcance)
  -- Montos: mismo nombre que vta_paint_z.vta_cmp_asoc (columnas 12 a 56 del CSV)
  vta_montobol        number,
  vta_montoncr        number,
  vta_montofac        number,
  rec_mefectivo       number,
  rec_mrecaudaefec    number,
  rec_mchkdia         number,
  rec_mchkfecha       number,
  rec_mtarj           number,
  rec_msodimac        number,
  rec_mcmr            number,
  rec_mtregalo        number,
  rec_mtotconvenio    number,
  rec_mtraspasotde    number,
  rec_mrenueva        number,
  rec_mtotfacxcob     number,
  rec_mdotaciones     number,
  rec_mretiros        number,
  rec_mabonocmr       number,
  rec_mavancecmr      number,
  rec_mtotpreprenueva number,
  rec_mtransferencia  number,
  rec_mreversatrans   number,
  rec_mretirotrans    number,
  rec_matrfefec       number,
  rec_matrfchk        number,
  rec_matrfcmr        number,
  rec_matrfdeb        number,
  rec_matrfcre        number,
  rec_mrevatottrf     number,
  rec_mrevatrfefec    number,
  rec_mrevatrfcmr     number,
  rec_mabonotde       number,
  rec_mtde            number,
  rec_msellosvrd      number,
  rec_mtotrecauda     number,
  rec_mtotrevrecauda  number,
  rec_mcanjepuntos    number,
  rec_mrevcanjepuntos number,
  rec_mtotsif         number,
  rec_mrectercero     number,
  rec_mdevtercero     number,
  rec_mquickpaycmr    number,
  rec_mquickpaybco    number,
  rec_ecompay         number,
  rec_mpagopuntos     number,
  det_total           number,                     -- TOTALES = BOLETAS + N.CREDITO + FACTURA
  det_estado          varchar2(10)    not null,   -- OK / ERROR (el motivo esta en el log)
  det_fechahora       date            default sysdate not null,
  constraint PK_VTA_FACOCARGA_YZ_DET primary key (det_carga, det_linea)
);

create table VTA_FACOCARGA_YZ_RES (
  res_carga           number          not null,
  res_fecha           date            not null,
  res_local           number          not null,
  res_terminal        number          not null,
  res_cant_y          number          not null,   -- filas TIPO = Y
  res_total_y         number,                     -- suma de TOTALES de las Y
  res_cant_z          number          not null,   -- filas TIPO = Z (debe ser 1)
  res_total_z         number,                     -- TOTALES de la Z
  res_lin_error       number          not null,   -- filas del grupo con error de formato o de base
  res_estado          varchar2(20)    not null,
        -- PENDIENTE : recien creado (si queda asi, el proceso se cayo; ver log)
        -- ERROR     : no cuadra o tiene filas con error (motivo en res_mensaje)
        -- PROCESADO : 1 Z, al menos 1 Y, sin errores y total Z = suma total Y
  res_mensaje         varchar2(1000),
  res_usuario         varchar2(50),
  res_fechahora       date            default sysdate not null,
  constraint PK_VTA_FACOCARGA_YZ_RES primary key (res_carga, res_fecha, res_local, res_terminal)
);

create table VTA_FACOCARGA_YZ_LOG (
  log_id              number          not null,   -- SEQ_VTA_FACOCARGA_YZ_LOG
  log_carga           number          not null,
  log_linea           number,                     -- linea del archivo (nula = de la carga)
  log_etapa           varchar2(20)    not null,
        -- INICIO, LECTURA (formato de la linea), VALIDACION (contra la base),
        -- RESUMEN (grupo en ERROR), FIN, ERROR (el proceso se cayo)
  log_campo           varchar2(30),               -- columna del CSV
  log_valor           varchar2(200),              -- valor recibido
  log_motivo          varchar2(1000),
  log_usuario         varchar2(50),
  log_fechahora       date            default sysdate not null,
  constraint PK_VTA_FACOCARGA_YZ_LOG primary key (log_id)
);

create index IND_VTA_FACOCARGA_YZ_LOG_01
  on VTA_FACOCARGA_YZ_LOG (log_carga, log_linea);

create sequence SEQ_VTA_FACOCARGA_YZ
  start with 1 increment by 1 nocache nocycle;

create sequence SEQ_VTA_FACOCARGA_YZ_LOG
  start with 1 increment by 1 nocache nocycle;

comment on table VTA_FACOCARGA_YZ_DET is 'FCDVT-14 Carga masiva Y/Z FACO: lineas del CSV (PKG_F8_CARGA_MASIVA_YZ)';
comment on table VTA_FACOCARGA_YZ_RES is 'FCDVT-14 Carga masiva Y/Z FACO: resumen por fecha, local y terminal (grilla de Form174)';
comment on table VTA_FACOCARGA_YZ_LOG is 'FCDVT-14 Carga masiva Y/Z FACO: log por carga, fila y campo';
