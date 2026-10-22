-- =====================================================================
-- FSCC-12901 COMPENSA_DI - Paso 02: log de la compensacion automatica de DI
-- xintec-nruz 19-10-2026
-- Una fila por cada caja (cierre Y) evaluada por
-- PKG_F8_COMPENSA_DI_CARGA.prc_compensa_caja (llamada desde Form133).
-- =====================================================================

create table VTA_FACOLOG_COMPENSA_DI (
  log_id          number          not null,   -- SEQ_VTA_FACOLOG_COMPENSA_DI
  log_fecha_vta   date            not null,
  log_local       number          not null,
  log_terminal    number          not null,
  log_cierrey     number          not null,
  log_sobres      number,                     -- total sobres F8 (EFE + CHE) de la Y
  log_dif_real    number,                     -- diferencia real sin la DI automatica
  log_di_anterior number,                     -- DI automatica anterior borrada (recalculo)
  log_monto_di    number,                     -- DI registrada (null si no se registro)
  log_resultado   varchar2(30)    not null,
        -- DI_REGISTRADA, DR_CERO, FUERA_RANGO, DI_MANUAL_PREVIA, SIN_LIBVTA,
        -- SIN_TERMSTAT, YA_CERRADA, OCUPADA, SIN_Y, INACTIVO, ERROR
  log_mensaje     varchar2(1000),
  log_usuario     varchar2(50),
  log_fechahora   date            default sysdate not null,
  constraint PK_VTA_FACOLOG_COMPENSA_DI primary key (log_id)
);

create index IND_VTA_FACOLOG_COMPENSA_DI_01
  on VTA_FACOLOG_COMPENSA_DI (log_fecha_vta, log_local, log_terminal, log_cierrey);

create sequence SEQ_VTA_FACOLOG_COMPENSA_DI
  start with 1 increment by 1 nocache nocycle;

comment on table VTA_FACOLOG_COMPENSA_DI is 'FSCC-12901 Log de la compensacion automatica de DI al cargar sobres (Form133, FACO)';
