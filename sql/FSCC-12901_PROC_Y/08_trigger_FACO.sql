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
