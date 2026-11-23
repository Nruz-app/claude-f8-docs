-- =====================================================================
-- FCDVT-10 (HU-03) - Paso 08: verificacion de los packages (SOLO LECTURA)
-- Carga masiva de cierres Y / Z, Tottus Chile (SFCL)
-- xintec-nruz 21-11-2026
-- Creado tras el ORA-06502 de la prueba en test: c_encabezado estaba
-- declarado varchar2(1000) y su literal mide 1031 caracteres (74 columnas).
-- El package compilaba VALID pero reventaba al instanciarse, en la primera
-- llamada (prc_inicia), con "character string buffer too small" en la linea
-- del constant. FACO no lo ve porque su encabezado mide 760.
--
-- Ejecutar conectado como el duenio de las tablas VTA_* (test: INTRANETTS),
-- DESPUES de recompilar 03, 04, 04b y 04c. No modifica nada.
-- =====================================================================
set pagesize 200 linesize 250 feedback on
column object_name format a34
column text format a80
column column_name format a28

prompt ===== 1) Estado de los packages (ESPERADO: PACKAGE y PACKAGE BODY VALID) =====
select object_name, object_type, status
  from user_objects
 where object_name like 'PKG_F8_%MASIVA_YZ_SFCL'
 order by object_name, object_type;

prompt ===== 2) Errores de compilacion (ESPERADO: 0 filas) =====
select name, type, line, position, text
  from user_errors
 where name like 'PKG_F8_%MASIVA_YZ_SFCL'
 order by name, type, sequence;

prompt ===== 3) Encabezado de la plantilla (ESPERADO: 1031 caracteres, 74 campos) =====
-- Si esta consulta da ORA-06502 en la linea del constant, la version
-- instalada de 03 sigue con varchar2(1000): recompilarla.
select length(PKG_F8_CARGA_MASIVA_YZ_SFCL.fn_encabezado('SFCL')) caracteres,
       length(PKG_F8_CARGA_MASIVA_YZ_SFCL.fn_encabezado('SFCL'))
         - length(replace(PKG_F8_CARGA_MASIVA_YZ_SFCL.fn_encabezado('SFCL'), ';')) + 1 campos
  from dual;

prompt ===== 4) fn_encabezado contra las columnas 15 a 77 de VTA_SFCLCARGA_YZ_DET (ESPERADO: 0 filas) =====
-- El campo n del encabezado (12 a 74) es el concepto de la columna n+3 de DET
-- (las 3 primeras de DET son la linea del archivo). Una fila aqui significa
-- que el orden o el nombre cambio en 02, 03, 04 o 04c.
with e as (
  select PKG_F8_CARGA_MASIVA_YZ_SFCL.fn_encabezado('SFCL') enc from dual
), campos as (
  select level pos,
         upper(trim(regexp_substr(e.enc, '[^;]+', 1, level))) campo
    from e
 connect by level <= 74
)
select c.pos, c.campo, t.column_name
  from campos c, user_tab_columns t
 where t.table_name = 'VTA_SFCLCARGA_YZ_DET'
   and t.column_id  = c.pos + 3
   and c.pos between 12 and 74
   and c.campo <> t.column_name
 order by c.pos;

prompt ===== 5) Ultima carga registrada en el log (ESPERADO tras un Buscar: INICIO y FIN) =====
select log_carga, log_linea, log_etapa, log_campo, substr(log_motivo, 1, 80) motivo
  from VTA_SFCLCARGA_YZ_LOG
 where log_carga = (select max(log_carga) from VTA_SFCLCARGA_YZ_LOG)
 order by log_id;
