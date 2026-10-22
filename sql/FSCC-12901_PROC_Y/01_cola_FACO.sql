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
