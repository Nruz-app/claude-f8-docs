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
