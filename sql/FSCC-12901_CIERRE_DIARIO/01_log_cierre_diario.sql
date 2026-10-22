-- =====================================================================
-- FSCC-12901 CIERRE_DIARIO - Paso 01: log del cierre diario
-- xintec-nruz 20-10-2026
-- Una fila por cada caja (cierre Y) evaluada por
-- PKG_F8_CIERRE_DIARIO.prc_cierre_diario, mas una fila INICIO y otra FIN
-- por ejecucion (log_ejecucion = numero de la corrida).
-- Pais habilitado: FACO. Para otro pais, crear VTA_<pfx>LOG_CIERRE_DIARIO
-- y su secuencia con este mismo script cambiando el prefijo.
-- =====================================================================

create table VTA_FACOLOG_CIERRE_DIARIO (
  log_id          number          not null,   -- SEQ_VTA_FACOLOG_CIERRE_DIARIO
  log_ejecucion   number          not null,   -- corrida (mismo numero para todas sus filas)
  log_fecha_vta   date,                       -- fecha de venta procesada
  log_local       number,
  log_terminal    number,
  log_cierrey     number,
  log_dr_f8       number,                     -- Dif. Real de la F8 de la Y (Form3Y)
  log_dr_cc       number,                     -- Dif. Real de la grilla de Consultas de Cuadratura (Form43)
  log_resultado   varchar2(30)    not null,
        -- Por caja: CERRADA, CON_DIFERENCIA, CON_DIFERENCIA_CC, BLOQUEADA,
        --           SIN_LIBVTA, SIN_TERMSTAT, YA_CERRADA, OCUPADA, ERROR
        -- Terminal sin venta (FCDVT-56, log_cierrey 0): CERRADA_SIN_VENTA y
        --           los mismos motivos de arriba
        -- Por ejecucion: INICIO, FIN, INACTIVO, ERROR
  log_regla       varchar2(10),               -- RY-01..RY-06 (Y) y RZ-01..RZ-05 (Z sin venta), reglas de Cerrar Terminal
  log_mensaje     varchar2(1000),
  log_usuario     varchar2(50),
  log_fechahora   date            default sysdate not null,
  constraint PK_VTA_FACOLOG_CIERRE_DIARIO primary key (log_id)
);

create index IND_VTA_FACOLOG_CIERRE_DIA_01
  on VTA_FACOLOG_CIERRE_DIARIO (log_ejecucion);

create index IND_VTA_FACOLOG_CIERRE_DIA_02
  on VTA_FACOLOG_CIERRE_DIARIO (log_fecha_vta, log_local, log_terminal, log_cierrey);

create sequence SEQ_VTA_FACOLOG_CIERRE_DIARIO
  start with 1 increment by 1 nocache nocycle;

comment on table VTA_FACOLOG_CIERRE_DIARIO is 'FSCC-12901 Log del cierre diario de cajas (PKG_F8_CIERRE_DIARIO, FACO)';
