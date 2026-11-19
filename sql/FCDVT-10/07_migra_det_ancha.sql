-- =====================================================================
-- FCDVT-10 (HU-03) - Paso 07: lleva VTA_SFCLCARGA_YZ_DET al esquema ancho
-- Tottus Chile (Flg_Pais$ = "SFCL")
-- xintec-nruz 18-11-2026 / 19-11-2026 (reglas de Colombia: lista fija de conceptos)
--
-- SOLO para un ambiente donde ya se ejecuto la version anterior de
-- 02_tablas_carga_yz_sfcl.sql (DET solo con la identificacion y los montos
-- en VTA_SFCLCARGA_YZ_DETM). Deja VTA_SFCLCARGA_YZ_DET como la tabla de
-- Colombia (VTA_FACOCARGA_YZ_DET): una columna por concepto, con el nombre y
-- el orden de la lista fija PKG_F8_CARGA_MASIVA_YZ_SFCL.c_encabezado.
--
--   Parte A: recrea VTA_SFCLCARGA_YZ_DET con las 63 columnas de concepto en
--            las posiciones 15 a 77 y det_total / det_estado / det_fechahora
--            en 78 a 80 (el mismo DDL de 02). NO se copian filas: las
--            cargas de prueba se vuelven a subir con Form174.
--   Parte B: borra VTA_SFCLCARGA_YZ_DETM (sus montos no se trasladan)
--   Parte C: verificaciones
--
-- Por que se recrea y no un alter table ... add: asi la tabla queda igual a
-- la de una instalacion limpia (conceptos en las posiciones 15 a 77, en el
-- orden del encabezado; consulta 6c de 06_pruebas.sql). Los packages leen y
-- graban las columnas por nombre.
--
-- Para una instalacion limpia NO se usa este script: 02 ya crea la tabla
-- ancha. DESPUES de las partes A y B los packages quedan INVALID: ejecutar
-- 03, 04, 04b y 04c en ese orden (no 02: daria ORA-00955 en RES). Si en el
-- ambiente se corrio 05_grants_sinonimos.sql, volver a ejecutarlo: los
-- grants y sinonimos de DET se pierden al recrear la tabla.
-- Ejecutar como el duenio de las tablas (test: INTRANETTS). No es
-- reejecutable en la practica: la parte A avisa y no hace nada si la tabla
-- ya es ancha, y la parte B avisa si DETM ya no existe.
-- =====================================================================
set serveroutput on

-- ---------------------------------------------------------------------
-- PARTE A - Recrea VTA_SFCLCARGA_YZ_DET (DDL identico a
--   02_tablas_carga_yz_sfcl.sql). Primero se crea DET_NEW, para no quedar
--   sin tabla si algo falla; al final se renombra.
-- ---------------------------------------------------------------------
declare
  v_n number;
begin
  select count(*) into v_n
    from user_tab_columns
   where table_name = 'VTA_SFCLCARGA_YZ_DET'
     and column_name = 'VTA_MONTOBOL';
  if v_n > 0 then
    dbms_output.put_line('VTA_SFCLCARGA_YZ_DET ya tiene las columnas de concepto: no se toca.');
    return;
  end if;

  select count(*) into v_n
    from user_tables
   where table_name = 'VTA_SFCLCARGA_YZ_DET';
  if v_n = 0 then
    dbms_output.put_line('VTA_SFCLCARGA_YZ_DET no existe: instalacion limpia, ejecutar 02_tablas_carga_yz_sfcl.sql.');
    return;
  end if;

  select count(*) into v_n from VTA_SFCLCARGA_YZ_DET;
  dbms_output.put_line('Filas de VTA_SFCLCARGA_YZ_DET que se descartan: ' || v_n);

  execute immediate q'[
create table VTA_SFCLCARGA_YZ_DET_NEW (
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
  vta_mmontondb       number,
  vta_montoguia       number,
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
  det_total           number,
  det_estado          varchar2(10)    not null,
  det_fechahora       date            default sysdate not null,
  constraint PK_VTA_SFCLCARGA_YZ_DET_NEW primary key (det_carga, det_linea)
)]';

  execute immediate 'comment on table VTA_SFCLCARGA_YZ_DET_NEW is '
    || q'['FCDVT-10 Carga masiva Y/Z Tottus: lineas del CSV con una columna por concepto de Tottus (PKG_F8_CARGA_MASIVA_YZ_SFCL)']';

  execute immediate 'drop table VTA_SFCLCARGA_YZ_DET purge';
  execute immediate 'alter table VTA_SFCLCARGA_YZ_DET_NEW rename to VTA_SFCLCARGA_YZ_DET';
  execute immediate 'alter table VTA_SFCLCARGA_YZ_DET rename constraint PK_VTA_SFCLCARGA_YZ_DET_NEW to PK_VTA_SFCLCARGA_YZ_DET';
  execute immediate 'alter index PK_VTA_SFCLCARGA_YZ_DET_NEW rename to PK_VTA_SFCLCARGA_YZ_DET';

  dbms_output.put_line('VTA_SFCLCARGA_YZ_DET recreada: 14 de identificacion + 63 conceptos (15 a 77) + det_total / det_estado / det_fechahora.');
end;
/

-- ---------------------------------------------------------------------
-- PARTE B - Fuera la tabla de montos (DETM). Sus filas NO se trasladan.
-- ---------------------------------------------------------------------
declare
  v_n number;
begin
  select count(*) into v_n
    from user_tables
   where table_name = 'VTA_SFCLCARGA_YZ_DETM';
  if v_n = 0 then
    dbms_output.put_line('VTA_SFCLCARGA_YZ_DETM no existe: nada que borrar.');
  else
    execute immediate 'drop table VTA_SFCLCARGA_YZ_DETM purge';
    dbms_output.put_line('VTA_SFCLCARGA_YZ_DETM borrada (sus montos no se trasladaron).');
  end if;
end;
/

commit;

-- ---------------------------------------------------------------------
-- PARTE C - Verificaciones
-- ---------------------------------------------------------------------
prompt ===== C1) Columnas de concepto de DET (esperado: 63, de la 15 a la 77) =====
select count(*) columnas_concepto, min(column_id) primera, max(column_id) ultima
  from user_tab_columns
 where table_name = 'VTA_SFCLCARGA_YZ_DET'
   and column_id >= 15
   and column_name not like 'DET\_%' escape '\';

prompt ===== C2) Columnas de concepto de DET que faltan respecto de la lista fija (ESPERADO: 0 filas) =====
with l as (
  select 'VTA_MONTOBOL;VTA_MONTONCR;VTA_MONTOFAC;VTA_MMONTONDB;VTA_MONTOGUIA;REC_MEFECTIVO'
      || ';REC_MCHKDIA;REC_MCHKFECHA;REC_MTRANSBANK;REC_MSODIMAC;REC_MCMR;REC_MTREGALO'
      || ';REC_MTOTCONVENIO;REC_MCHKFALA;REC_MTOTFACXCOB;REC_MNCREDITO;REC_MTDE;REC_TARJEDENRED'
      || ';REC_TARJAMIPASS;REC_TARJSODEXO;REC_MCANJEPUNTOS;MTOTGIFTCORP;REC_MFPAY;REC_MDOTACIONES'
      || ';REC_MRETIROS;REC_MATESORAMIENTO;REC_MABONOCMR;REC_MTOTSIF;REC_MAVANCECMR;REC_MINTERESES'
      || ';REC_MTRANSFERENCIA;REC_MRETIROTRANS;REC_MTRANSFERENCIAINT;REC_MREVERSATRANSINT;REC_MRETIROTRANSINT;REC_MTOTATRF'
      || ';REC_MTOTALREVTRF;REC_MABONOTDE;REC_MREVABONOTDE;REC_MSELLOSVRD;REC_MTOTRECAUDA;R_RECTELEFONO'
      || ';R_RECINTERNET;R_RECARGABIP;R_JUEGOSAZAR;R_PAGOSERVICIOS;R_SEGUROS;REC_MTOTREVRECAUDA'
      || ';REV_RECTELEFONO;REV_RECINTERNET;REV_RECARGABIP;REV_JUEGOSAZAR;REV_PAGOSERVICIOS;REV_SEGUROS'
      || ';REC_MREVCANJEPUNTOS;MQUICKPAY;QUICKPAYDEBIDTOBF;REC_MTOTALPESO;REC_LINIO;REC_ECOM'
      || ';REC_PLUXEE_JUNAEB;REC_EDENRED_JUNAEB;REC_EDENRED_PRIVADO' lista from dual
), c as (
  select level pos, regexp_substr(l.lista, '[^;]+', 1, level) col
    from l
 connect by level <= 63
)
select c.pos, c.col
  from c
 where not exists (select 1 from user_tab_columns t
                    where t.table_name = 'VTA_SFCLCARGA_YZ_DET'
                      and t.column_name = c.col
                      and t.column_id   = 14 + c.pos)
 order by c.pos;

prompt ===== C3) Objetos de la carga masiva (esperado: 3 tablas, 2 secuencias, 2 packages; sin DETM) =====
select object_name, object_type, status
  from user_objects
 where object_name like 'VTA\_SFCLCARGA\_YZ%' escape '\'
    or object_name like 'SEQ\_VTA\_SFCLCARGA\_YZ%' escape '\'
    or object_name in ('PKG_F8_CARGA_MASIVA_YZ_SFCL', 'PKG_F8_GRABA_MASIVA_YZ_SFCL')
 order by object_type, object_name;

prompt ===== C4) Errores de compilacion (esperado: 0 filas despues de recompilar 03, 04, 04b y 04c) =====
select name, type, line, position, text
  from user_errors
 where name in ('PKG_F8_CARGA_MASIVA_YZ_SFCL', 'PKG_F8_GRABA_MASIVA_YZ_SFCL')
 order by name, type, sequence;
