-- =====================================================================
-- FSCC-12958 (HU-01-T2) Cierre de caja automatico - Falabella Colombia
-- 01 - Tabla homologa de VTA_FACOPRD (cola de cajas a evaluar)
-- Esquema: duenio de las tablas VTA_FACO* (objetos sin prefijo)  |  Oracle 10.2
-- Cada sobre insertado en VTA_FACOPRD genera una fila aqui (trigger 04).
-- El procedimiento PKG_F8_FACO_CIERRE_AUTO.PRC_CIERRE_AUTOMATICO la lee.
-- =====================================================================

-- Los tipos de las columnas PRV_* se heredan de VTA_FACOPRD (CTAS vacio).
-- Verificado en test (06-10-2026): VTA_FACOPRD tiene 29 columnas, PK
-- IND_FACOPRV_PK_01 (prv_techkey), sin triggers; PRV_CIERREY NUMBER(2)
-- NOT NULL DEFAULT 0 (0 = sobre sin Y); PRV_COD_RECAUD VARCHAR2(20).
-- El CTAS copia las restricciones NOT NULL de las columnas origen.
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
  pcr_estado     varchar2(1)    default 'P' not null,
                                -- P pendiente (se reevalua en cada ejecucion)
                                -- C cerrada / nada mas que hacer
                                -- O omitida (sobre sin cierre Y)
                                -- V vencida (mas antigua que CA_DIAS)
  pcr_ejecucion  number,                           -- ultima ejecucion que la evaluo
  pcr_fechaproc  date,                             -- fecha/hora de la ultima evaluacion
  pcr_resultado  varchar2(30),                     -- ultimo resultado (ver log)
  pcr_mensaje    varchar2(1000),                   -- ultimo mensaje
  pcr_intentos   number         default 0 not null -- veces evaluada
);

alter table VTA_FACOPRD_CIERRE
  add constraint PK_VTA_FACOPRD_CIERRE primary key (pcr_id);

alter table VTA_FACOPRD_CIERRE
  add constraint CK_VTA_FACOPRD_CIERRE_EST check (pcr_estado in ('P','C','O','V'));

create index IND_VTA_FACOPRD_CIERRE_01
  on VTA_FACOPRD_CIERRE (pcr_estado);

create index IND_VTA_FACOPRD_CIERRE_02
  on VTA_FACOPRD_CIERRE (prv_fechavta, prv_local, prv_terminal, prv_cierrey);

create sequence SEQ_VTA_FACOPRD_CIERRE
  start with 1 increment by 1 nocache nocycle;

comment on table  VTA_FACOPRD_CIERRE is 'FSCC-12958 Cola de sobres F8 Colombia para cierre automatico de cajas (homologa de VTA_FACOPRD)';
comment on column VTA_FACOPRD_CIERRE.pcr_estado is 'P pendiente, C cerrada/terminada, O omitida (sin cierre Y), V vencida';
