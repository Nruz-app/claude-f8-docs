-- =====================================================================
-- FCDVT-14 - Paso 02: tablas de la carga masiva de cierres Y / Z
-- MULTIPAIS: un juego de tablas por prefijo de pais (Flg_Pais$)
-- xintec-nruz 30-10-2026 / 03-11-2026 (multipais)
-- Version anterior (solo FACO, DDL estatico, la instalada en test el 30-10):
--   anterior_2026-11-03/02_tablas_carga_yz.sql
--
-- Las usa PKG_F8_CARGA_MASIVA_YZ (pasos 03 y 04), llamado desde
-- Form174 (botones Buscar y Cargar). Para el prefijo <P> crea:
--   VTA_<P>CARGA_YZ_DET : una fila por linea del CSV, ya separada y tipada
--   VTA_<P>CARGA_YZ_RES : resumen por fecha / local / terminal (grilla)
--   VTA_<P>CARGA_YZ_LOG : log por carga (INICIO, errores por fila/campo, FIN)
--   SEQ_VTA_<P>CARGA_YZ y SEQ_VTA_<P>CARGA_YZ_LOG
-- Ejemplos: FACO -> VTA_FACOCARGA_YZ_DET (los nombres que ya existen en
-- test); Chile (prefijo vacio) -> VTA_CARGA_YZ_DET.
--
-- Solo crea lo que NO existe: en test, con FACO ya instalado, no hace nada
-- y se puede volver a ejecutar. Formato del CSV: FORMATO_CARGA_Y_FACO.md.
-- Buscar no graba cierres; Cargar (prc_graba, 04-11-2026) graba en
-- libvta / zzz / termstat(y) los grupos CARGADO. Este script no cambia.
--
-- Columnas de DET: los montos tienen el nombre de vta_paint_z.vta_cmp_asoc
-- de FACO (columnas 12 a 56 del CSV). Antes de habilitar otro pais hay que
-- comparar su vta_paint_z (ver 00_LEEME.md, "Multipais").
--
-- res_estado:
--   PENDIENTE : recien creado (si queda asi, el proceso se cayo; ver log)
--   ERROR     : no cuadra o tiene filas con error (motivo en res_mensaje)
--   CARGADO   : 1 Z, al menos 1 Y, sin errores y total Z = suma total Y
--               (hasta el 03-11-2026 se llamaba PROCESADO)
--   GRABADO   : Cargar ya lo grabo (desde el 04-11-2026); si Cargar no
--               pudo, el grupo pasa a ERROR con el motivo
-- log_etapa: INICIO, LECTURA (formato de la linea), VALIDACION (contra la
--   base), RESUMEN (grupo en ERROR), FIN, ERROR (el proceso se cayo),
--   GRABADO (Cargar: inicio, resultado de cada grupo y fin)
-- =====================================================================
set serveroutput on

declare
  v_prefijo varchar2(10) := 'FACO';   -- EDITAR: prefijo del pais (FACO, SFCL, ...; Chile = '')
  v_p       varchar2(10);

  procedure crea (p_nombre in varchar2, p_tipo in varchar2, p_ddl in varchar2) is
    v_n number;
  begin
    select count(*) into v_n from user_objects
     where object_name = p_nombre and object_type = p_tipo;
    if v_n > 0 then
      dbms_output.put_line('Ya existe, no se crea: ' || p_tipo || ' ' || p_nombre);
    else
      execute immediate replace(p_ddl, '{P}', v_p);
      dbms_output.put_line('Creado: ' || p_tipo || ' ' || p_nombre);
    end if;
  end crea;
begin
  v_p := upper(trim(v_prefijo));

  crea('VTA_' || v_p || 'CARGA_YZ_DET', 'TABLE', q'[
create table VTA_{P}CARGA_YZ_DET (
  det_carga           number          not null,
  det_linea           number          not null,
  det_texto           varchar2(4000),
  det_fecha           date,
  det_local           number,
  det_terminal        number,
  det_nro_y           number,
  det_hora            varchar2(5),
  det_secuencia       number,
  det_num_boleta      number,
  det_vendedor        number,
  det_cont_repo       number,
  det_tipo            varchar2(1),
  det_tipo_carga      varchar2(20),
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
  det_total           number,
  det_estado          varchar2(10)    not null,
  det_fechahora       date            default sysdate not null,
  constraint PK_VTA_{P}CARGA_YZ_DET primary key (det_carga, det_linea)
)]');

  crea('VTA_' || v_p || 'CARGA_YZ_RES', 'TABLE', q'[
create table VTA_{P}CARGA_YZ_RES (
  res_carga           number          not null,
  res_fecha           date            not null,
  res_local           number          not null,
  res_terminal        number          not null,
  res_cant_y          number          not null,
  res_total_y         number,
  res_cant_z          number          not null,
  res_total_z         number,
  res_lin_error       number          not null,
  res_estado          varchar2(20)    not null,
  res_mensaje         varchar2(1000),
  res_usuario         varchar2(50),
  res_fechahora       date            default sysdate not null,
  constraint PK_VTA_{P}CARGA_YZ_RES primary key (res_carga, res_fecha, res_local, res_terminal)
)]');

  crea('VTA_' || v_p || 'CARGA_YZ_LOG', 'TABLE', q'[
create table VTA_{P}CARGA_YZ_LOG (
  log_id              number          not null,
  log_carga           number          not null,
  log_linea           number,
  log_etapa           varchar2(20)    not null,
  log_campo           varchar2(30),
  log_valor           varchar2(200),
  log_motivo          varchar2(1000),
  log_usuario         varchar2(50),
  log_fechahora       date            default sysdate not null,
  constraint PK_VTA_{P}CARGA_YZ_LOG primary key (log_id)
)]');

  crea('IND_VTA_' || v_p || 'CARGA_YZ_LOG_01', 'INDEX',
       'create index IND_VTA_{P}CARGA_YZ_LOG_01 on VTA_{P}CARGA_YZ_LOG (log_carga, log_linea)');

  crea('SEQ_VTA_' || v_p || 'CARGA_YZ', 'SEQUENCE',
       'create sequence SEQ_VTA_{P}CARGA_YZ start with 1 increment by 1 nocache nocycle');
  crea('SEQ_VTA_' || v_p || 'CARGA_YZ_LOG', 'SEQUENCE',
       'create sequence SEQ_VTA_{P}CARGA_YZ_LOG start with 1 increment by 1 nocache nocycle');

  execute immediate replace(q'[comment on table VTA_{P}CARGA_YZ_DET is 'FCDVT-14 Carga masiva Y/Z: lineas del CSV (PKG_F8_CARGA_MASIVA_YZ)']', '{P}', v_p);
  execute immediate replace(q'[comment on table VTA_{P}CARGA_YZ_RES is 'FCDVT-14 Carga masiva Y/Z: resumen por fecha, local y terminal (grilla de Form174). Estados PENDIENTE / ERROR / CARGADO']', '{P}', v_p);
  execute immediate replace(q'[comment on table VTA_{P}CARGA_YZ_LOG is 'FCDVT-14 Carga masiva Y/Z: log por carga, fila y campo']', '{P}', v_p);
end;
/
