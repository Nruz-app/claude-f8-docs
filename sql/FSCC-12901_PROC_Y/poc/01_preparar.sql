-- =====================================================================
-- POC FSCC-12901 v2 (multipais, FACO) - 01 Preparar (DESARROLLO)
-- Verifica los objetos y crea las tablas de control del POC.
-- v2: ya no amplia CA_DIAS. Colombia procesa la carga del dia (la cola), sin
-- ventana de dias, asi que las fechas de 2026 entran igual al proceso.
-- GRABA: tablas VTA_FACOPOC_* (las borra 99).
-- Ejecutar bloque a bloque (o como script), conectado como el duenio de VTA_FACO*.
-- =====================================================================

-- ---------------------------------------------------------------
-- 1. Objetos instalados (esperado: 7 filas VALID: 2 tablas, 2 paquetes con su cuerpo y el trigger)
-- ---------------------------------------------------------------
select object_name, object_type, status
  from user_objects
 where object_name in ('VTA_FACOPRD_CIERRE','VTA_FACOLOG_CIERRE_AUTO',
                       'PKG_F8_CIERRE_AUTO','PKG_F8_COMPENSA_DI_AUTO','TRG_VTA_FACOPRD_CIERRE_AI')
 order by object_type, object_name;

-- Parametros 1502 (esperado: 8 filas, 9 si se migro desde v1 (CA_DIAS queda pero v2 no lo usa); CA_ACTIVO = S, CA_DI_ACTIVO = S, CA_SIN_SOBRE = S)
select trim(vta_ccodigo) codigo, vta_xglosa valor
  from VTA_FACOPARAM where vta_ccodtipo = 1502 order by 1;

-- ---------------------------------------------------------------
-- 2. El ambiente debe estar limpio para las fechas del POC
--    (esperado: 0 y 0. Si no, ejecutar antes 99_limpiar.sql)
-- ---------------------------------------------------------------
select (select count(*) from VTA_FACOTERMSTATY where ter_fecha >= to_date('20260101','yyyymmdd')) y_2026_existentes,
       (select count(*) from VTA_FACOPRD_CIERRE where pcr_estado in ('P', 'E')) cola_pendiente
  from dual;

-- ---------------------------------------------------------------
-- 3. Tablas de control del POC
-- ---------------------------------------------------------------
create table VTA_FACOPOC_CTRL (
  clave  varchar2(30) not null,
  valor  varchar2(200)
);

-- Local-dia cargados por el POC (TEST = copia de test; PRD3 = dia de PRD 3.xlsx)
create table VTA_FACOPOC_DIAS (
  d_origen  varchar2(10) not null,
  d_fecha   date         not null,
  d_local   number       not null
);

-- Cajas (cierres Y) del POC con su escenario y lo esperado
create table VTA_FACOPOC_CASOS (
  c_origen     varchar2(10) not null,   -- TEST / PRD3
  escenario    varchar2(3)  not null,   -- ver 00_LEEME
  c_fecha      date         not null,
  c_local      number       not null,
  c_terminal   number       not null,
  c_cierrey    number       not null,
  dr_inicial   number,                  -- DR antes de cargar sobres
  dr_objetivo  number,                  -- DR buscada (null = la que resulte)
  monto_sobre  number,                  -- sobre agregado por el POC (null = sin sobre o sobres reales)
  esperado_t1  varchar2(30),            -- null = se usa la prevision de 05
  esperado_t2  varchar2(30),
  prev_t1      varchar2(30),            -- prevision calculada por 05_simular.sql
  prev_t2      varchar2(30)
);

-- Filas reales del archivo PRD 3.xlsx (las carga 03_dia_prd3.sql)
create table VTA_FACOPOC_PRD3 (
  p_local     number not null,
  p_terminal  number not null,
  p_sobre     number not null,
  p_monto     number not null,
  p_dif       number not null,
  p_numrec    number not null,
  p_fecha     date   not null,
  p_cierrey   number not null
);

select * from VTA_FACOPOC_CTRL;
