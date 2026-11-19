-- =====================================================================
-- FCDVT-10 (HU-03) - Paso 02: tablas de la carga masiva de cierres Y / Z
-- Tottus Chile (Flg_Pais$ = "SFCL")
-- xintec-nruz 11-11-2026 (DDL estatico 18-11-2026; DET ancha 18-11-2026)
-- Base: docs/sql/FCDVT-14/02_tablas_carga_yz.sql (FACO).
--
-- Mismo esquema que Colombia: los montos van en columnas de
-- VTA_SFCLCARGA_YZ_DET (una por concepto), como las 45 de
-- VTA_FACOCARGA_YZ_DET, y no en una tabla de detalle aparte. Las 63 columnas
-- son los conceptos de VTA_PAINT_Z de SFCL (vta_pop_up = 0, en vta_order_z)
-- exportados de test el 18-11-2026: mismo nombre y mismo orden que el
-- encabezado del CSV (pruebas_cargar/encabezado.txt, paint_z_sfcl.csv).
-- La columna de cada concepto es su vta_cmp_asoc; los 5 primeros son los
-- conceptos de venta (filas 2 a 6 de VTA_PAINT_Z), que van a VTA_SFCLLIBVTA.
--
-- Importante: al ser columnas fijas, si se agrega o reordena un concepto en
-- VTA_PAINT_Z hay que recrear esta tabla con la lista nueva (las columnas de
-- concepto son la 15 a la 77, en el orden del encabezado) y reinstalar
-- PKG_F8_CARGA_MASIVA_YZ_SFCL. El package lo detecta en prc_config (ORA-20002
-- con el numero de columna). Para un ambiente ya instalado con la version
-- anterior (DET solo identificacion + DETM), 07_migra_det_ancha.sql recrea
-- esta tabla con el DDL de aqui.
--
-- Montos: nulo = concepto no informado en el CSV (en INGRESAR se graba 0; en
-- MODIFICAR no se cambia); 0 = informado en 0 (distingue vacio de cero).
--
-- Crea:
--   VTA_SFCLCARGA_YZ_DET  : una fila por linea del CSV, ya separada y tipada
--   VTA_SFCLCARGA_YZ_RES  : resumen por fecha / local / terminal (grilla)
--   VTA_SFCLCARGA_YZ_LOG  : log por carga, linea y campo
--   SEQ_VTA_SFCLCARGA_YZ y SEQ_VTA_SFCLCARGA_YZ_LOG
--
-- res_estado: PENDIENTE, ERROR, CARGADO (validado por Buscar), GRABADO
--   (Cargar lo grabo). res_tipo_carga: INGRESAR o MODIFICAR.
-- log_etapa: INICIO, LECTURA, VALIDACION, RESUMEN, FIN, ERROR, GRABADO.
--
-- DDL estatico (como la version FACO del 30-10): NO es reejecutable. Si los
-- objetos ya existen da ORA-00955 y corta INSTALAR.sql; para reinstalar,
-- 99_rollback.sql parte C. En test estan libres (00_prechecks.sql seccion 6).
-- =====================================================================

create table VTA_SFCLCARGA_YZ_DET (
  det_carga           number          not null,   -- SEQ_VTA_SFCLCARGA_YZ (una por archivo)
  det_linea           number          not null,   -- numero de linea del archivo (1 = encabezado)
  det_texto           varchar2(4000),             -- linea tal como venia
  det_fecha           date,                       -- FECHA (dd-mm-yyyy)
  det_local           number,                     -- LOCAL
  det_terminal        number,                     -- TERMINAL
  det_nro_y           number,                     -- NRO_Y (vacio = se asigna max+1 al cargar)
  det_hora            varchar2(5),                -- HORA (HH:MM)
  det_secuencia       number,                     -- SECUENCIA
  det_num_boleta      number,                     -- NUM_BOLETA
  det_vendedor        number,                     -- VENDEDOR
  det_cont_repo       number,                     -- CONT_REPOSICION
  det_tipo            varchar2(1),                -- TIPO: Y / Z
  det_tipo_carga      varchar2(20),               -- TIPO_CARGA: INGRESAR / MODIFICAR
  -- Conceptos de venta (filas 2 a 6 de VTA_PAINT_Z) -> VTA_SFCLLIBVTA
  vta_montobol        number,                     -- BOLETAS       -> vta_montobol
  vta_montoncr        number,                     -- N.CREDITO     -> vta_montoncr
  vta_montofac        number,                     -- FACTURA       -> vta_montofac
  vta_mmontondb       number,                     -- N.DEBITO      -> vta_mmontondb
  vta_montoguia       number,                     -- GUIA FACTURABLES -> vta_montoguia
  -- Conceptos de VTA_SFCLZZZ (nombre = vta_paint_z.vta_cmp_asoc)
  rec_mefectivo       number,
  rec_mchkdia         number,
  rec_mchkfecha       number,
  rec_mtransbank      number,
  rec_msodimac        number,
  rec_mcmr            number,
  rec_mtregalo        number,
  rec_mtotconvenio    number,
  rec_mchkfala        number,
  rec_mtotfacxcob     number,
  rec_mncredito       number,
  rec_mtde            number,
  rec_tarjedenred     number,
  rec_tarjamipass     number,
  rec_tarjsodexo      number,
  rec_mcanjepuntos    number,
  mtotgiftcorp        number,
  rec_mfpay           number,
  rec_mdotaciones     number,
  rec_mretiros        number,
  rec_matesoramiento  number,
  rec_mabonocmr       number,
  rec_mtotsif         number,
  rec_mavancecmr      number,
  rec_mintereses      number,
  rec_mtransferencia  number,
  rec_mretirotrans    number,
  rec_mtransferenciaint number,
  rec_mreversatransint number,
  rec_mretirotransint number,
  rec_mtotatrf        number,
  rec_mtotalrevtrf    number,
  rec_mabonotde       number,
  rec_mrevabonotde    number,
  rec_msellosvrd      number,
  rec_mtotrecauda     number,
  r_rectelefono       number,
  r_recinternet       number,
  r_recargabip        number,
  r_juegosazar        number,
  r_pagoservicios     number,
  r_seguros           number,
  rec_mtotrevrecauda  number,
  rev_rectelefono     number,
  rev_recinternet     number,
  rev_recargabip      number,
  rev_juegosazar      number,
  rev_pagoservicios   number,
  rev_seguros         number,
  rec_mrevcanjepuntos number,
  mquickpay           number,
  quickpaydebidtobf   number,
  rec_mtotalpeso      number,
  rec_linio           number,
  rec_ecom            number,
  rec_pluxee_junaeb   number,
  rec_edenred_junaeb  number,
  rec_edenred_privado number,
  det_total           number,                     -- TOTALES (fila 7 de VTA_PAINT_Z)
  det_estado          varchar2(10)    not null,   -- OK / ERROR (el motivo esta en el log)
  det_fechahora       date            default sysdate not null,
  constraint PK_VTA_SFCLCARGA_YZ_DET primary key (det_carga, det_linea)
);

create table VTA_SFCLCARGA_YZ_RES (
  res_carga           number          not null,   -- una por carga (SEQ_VTA_SFCLCARGA_YZ)
  res_fecha           date            not null,   -- fecha de venta del grupo
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
        -- CARGADO   : 1 Z, al menos 1 Y, sin errores y total Z = suma total Y
        -- GRABADO   : Cargar ya lo grabo (desde el 04-11-2026)
  res_mensaje         varchar2(1000),
  res_usuario         varchar2(50),
  res_fechahora       date            default sysdate not null,
  res_tipo_carga      varchar2(20),               -- TIPO_CARGA: INGRESAR / MODIFICAR
  constraint PK_VTA_SFCLCARGA_YZ_RES primary key (res_carga, res_fecha, res_local, res_terminal)
);

create table VTA_SFCLCARGA_YZ_LOG (
  log_id              number          not null,   -- SEQ_VTA_SFCLCARGA_YZ_LOG
  log_carga           number          not null,
  log_linea           number,                     -- linea del archivo (nula = de la carga)
  log_etapa           varchar2(20)    not null,
        -- INICIO, LECTURA (formato de la linea), VALIDACION (contra la base),
        -- RESUMEN (grupo en ERROR), FIN, ERROR (el proceso se cayo), GRABADO
  log_campo           varchar2(30),               -- columna del CSV
  log_valor           varchar2(200),              -- valor recibido
  log_motivo          varchar2(1000),
  log_usuario         varchar2(50),
  log_fechahora       date            default sysdate not null,
  constraint PK_VTA_SFCLCARGA_YZ_LOG primary key (log_id)
);

create index IND_VTA_SFCLCARGA_YZ_LOG_01
  on VTA_SFCLCARGA_YZ_LOG (log_carga, log_linea);

create sequence SEQ_VTA_SFCLCARGA_YZ
  start with 1 increment by 1 nocache nocycle;

create sequence SEQ_VTA_SFCLCARGA_YZ_LOG
  start with 1 increment by 1 nocache nocycle;

comment on table VTA_SFCLCARGA_YZ_DET  is 'FCDVT-10 Carga masiva Y/Z Tottus: lineas del CSV con una columna por concepto de VTA_PAINT_Z (PKG_F8_CARGA_MASIVA_YZ_SFCL)';
comment on table VTA_SFCLCARGA_YZ_RES  is 'FCDVT-10 Carga masiva Y/Z Tottus: resumen por fecha, local y terminal (grilla de Form174)';
comment on table VTA_SFCLCARGA_YZ_LOG  is 'FCDVT-10 Carga masiva Y/Z Tottus: log por carga, fila y campo';
