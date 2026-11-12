-- =====================================================================
-- FCDVT-10 (HU-03) - Paso 02: tablas de la carga masiva de cierres Y / Z
-- Tottus Chile (Flg_Pais$ = "SFCL")
-- xintec-nruz 11-11-2026
-- Base: docs/sql/FCDVT-14/02_tablas_carga_yz.sql (FACO). RES y LOG tienen
-- la misma estructura que las de FACO (las leen Form174 y Form175 sin
-- cambios). DET cambia: los montos NO van en columnas fijas sino en
-- VTA_SFCLCARGA_YZ_DETM (una fila por concepto informado), porque los
-- conceptos de Tottus salen de VTA_PAINT_Z (vta_localiz = 'SFCL') en
-- tiempo de ejecucion, igual que en Form19 / Form19Y.
--
-- Crea (solo lo que NO existe; se puede volver a ejecutar):
--   VTA_SFCLCARGA_YZ_DET  : una fila por linea del CSV (identificacion)
--   VTA_SFCLCARGA_YZ_DETM : montos informados por linea y concepto
--                           (fila ausente = concepto vacio en el CSV:
--                            INGRESAR lo toma como 0, MODIFICAR no lo cambia)
--   VTA_SFCLCARGA_YZ_RES  : resumen por fecha / local / terminal (grilla)
--   VTA_SFCLCARGA_YZ_LOG  : log por carga, linea y campo
--   SEQ_VTA_SFCLCARGA_YZ y SEQ_VTA_SFCLCARGA_YZ_LOG
--
-- res_estado: PENDIENTE, ERROR, CARGADO (validado por Buscar), GRABADO
--   (Cargar lo grabo). res_tipo_carga: INGRESAR o MODIFICAR.
-- log_etapa: INICIO, LECTURA, VALIDACION, RESUMEN, FIN, ERROR, GRABADO.
-- =====================================================================
set serveroutput on

declare
  procedure crea (p_nombre in varchar2, p_tipo in varchar2, p_ddl in varchar2) is
    v_n number;
  begin
    select count(*) into v_n from user_objects
     where object_name = p_nombre and object_type = p_tipo;
    if v_n > 0 then
      dbms_output.put_line('Ya existe, no se crea: ' || p_tipo || ' ' || p_nombre);
    else
      execute immediate p_ddl;
      dbms_output.put_line('Creado: ' || p_tipo || ' ' || p_nombre);
    end if;
  end crea;
begin
  crea('VTA_SFCLCARGA_YZ_DET', 'TABLE', q'[
create table VTA_SFCLCARGA_YZ_DET (
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
  det_total           number,
  det_estado          varchar2(10)    not null,
  det_fechahora       date            default sysdate not null,
  constraint PK_VTA_SFCLCARGA_YZ_DET primary key (det_carga, det_linea)
)]');

  crea('VTA_SFCLCARGA_YZ_DETM', 'TABLE', q'[
create table VTA_SFCLCARGA_YZ_DETM (
  dtm_carga           number          not null,
  dtm_linea           number          not null,
  dtm_columna         varchar2(30)    not null,
  dtm_monto           number          not null,
  constraint PK_VTA_SFCLCARGA_YZ_DETM primary key (dtm_carga, dtm_linea, dtm_columna)
)]');

  crea('VTA_SFCLCARGA_YZ_RES', 'TABLE', q'[
create table VTA_SFCLCARGA_YZ_RES (
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
  res_tipo_carga      varchar2(20),
  constraint PK_VTA_SFCLCARGA_YZ_RES primary key (res_carga, res_fecha, res_local, res_terminal)
)]');

  crea('VTA_SFCLCARGA_YZ_LOG', 'TABLE', q'[
create table VTA_SFCLCARGA_YZ_LOG (
  log_id              number          not null,
  log_carga           number          not null,
  log_linea           number,
  log_etapa           varchar2(20)    not null,
  log_campo           varchar2(30),
  log_valor           varchar2(200),
  log_motivo          varchar2(1000),
  log_usuario         varchar2(50),
  log_fechahora       date            default sysdate not null,
  constraint PK_VTA_SFCLCARGA_YZ_LOG primary key (log_id)
)]');

  crea('IND_VTA_SFCLCARGA_YZ_LOG_01', 'INDEX',
       'create index IND_VTA_SFCLCARGA_YZ_LOG_01 on VTA_SFCLCARGA_YZ_LOG (log_carga, log_linea)');

  crea('SEQ_VTA_SFCLCARGA_YZ', 'SEQUENCE',
       'create sequence SEQ_VTA_SFCLCARGA_YZ start with 1 increment by 1 nocache nocycle');
  crea('SEQ_VTA_SFCLCARGA_YZ_LOG', 'SEQUENCE',
       'create sequence SEQ_VTA_SFCLCARGA_YZ_LOG start with 1 increment by 1 nocache nocycle');

  execute immediate q'[comment on table VTA_SFCLCARGA_YZ_DET is 'FCDVT-10 Carga masiva Y/Z Tottus: lineas del CSV (PKG_F8_CARGA_MASIVA_YZ_SFCL)']';
  execute immediate q'[comment on table VTA_SFCLCARGA_YZ_DETM is 'FCDVT-10 Carga masiva Y/Z Tottus: montos informados por linea y concepto (vta_paint_z.vta_cmp_asoc)']';
  execute immediate q'[comment on table VTA_SFCLCARGA_YZ_RES is 'FCDVT-10 Carga masiva Y/Z Tottus: resumen por fecha, local y terminal (grilla de Form174)']';
  execute immediate q'[comment on table VTA_SFCLCARGA_YZ_LOG is 'FCDVT-10 Carga masiva Y/Z Tottus: log por carga, fila y campo']';
end;
/
