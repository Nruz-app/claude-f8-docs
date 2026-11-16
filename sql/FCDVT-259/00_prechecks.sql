-- =====================================================================
-- FCDVT-259 - Paso 00: prechecks de SOLO LECTURA (FACO)
-- xintec-nruz 16-11-2026
--
-- Antes de 01 (permiso de menu 461) y de 02/03 (PKG_F8_EXPORTA_MASIVA_YZ).
-- Ejecutar conectado como el duenio de las tablas VTA_* (test: INTRANETTS).
-- =====================================================================

prompt === 1. Codigo de menu 461 libre en FACO (ESPERADO: ninguna fila en las dos)
select m.mnu_codigo, m.mnu_descripcion, m.mnu_tipomenu from VTA_FACOMENU m where m.mnu_codigo = 461;
select r.per_codigo, r.rel_estado from VTA_FACORELPERMEN r where r.mnu_codigo = 461;

prompt === 2. Perfiles FACO con el permiso 460 (Ingreso del YYY Masivo, Form174); 01 da el 461 a 10 y 11
select r.per_codigo, r.rel_estado from VTA_FACORELPERMEN r where r.mnu_codigo = 460 order by 1;

prompt === 3. Dependencia: PKG_F8_CARGA_MASIVA_YZ (FCDVT-14) con spec VALID (02/03 usan su c_encabezado)
select object_name, object_type, status
  from user_objects
 where object_name in ('PKG_F8_CARGA_MASIVA_YZ', 'PKG_F8_EXPORTA_MASIVA_YZ')
 order by 1, 2;

prompt === 4. Encabezado de la plantilla FACO (ESPERADO: 56 columnas, empieza con FECHA;LOCAL;TERMINAL;NRO_Y)
-- Una constante de package no se puede leer desde SQL (PLS-221): se muestra con dbms_output
set serveroutput on
begin
  dbms_output.put_line(PKG_F8_CARGA_MASIVA_YZ.c_encabezado);
end;
/

prompt === 5. Columnas que usa el package (ESPERADO: 16 filas)
select table_name, column_name
  from user_tab_columns
 where (table_name = 'VTA_FACOLIBVTA'
        and column_name in ('VTA_FECHA_VENTA', 'VTA_LOCAL', 'VTA_TERMINAL', 'VTA_TIPOREG',
                            'VTA_SECUENCIA', 'VTA_ESTADO', 'VTA_TECHKEY', 'VTA_SECUENCIA_SRX',
                            'VTA_HORA', 'VTA_BOLFINAL', 'VTA_VENDEDOR', 'VTA_CREPO_FINAL'))
    or (table_name = 'VTA_FACOZZZ' and column_name = 'REC_TECHKEY')
    or (table_name = 'VTA_FACOLOCALES' and column_name in ('VTA_COD_LOCAL', 'VTA_GRUPO'))
    or (table_name = 'VTA_FACOTERMINALES' and column_name = 'TER_FECHABAJA')
 order by 1, 2;

prompt === 6. Cierres de FACO de los ultimos 3 dias (Form176 exporta de hoy - 2 a ayer; hoy se muestra solo de referencia)
select to_char(l.vta_fecha_venta, 'dd-mm-yyyy') fecha, l.vta_local,
       sum(case when l.vta_tiporeg = 'F8' then 1 else 0 end) z,
       sum(case when l.vta_tiporeg = 'Y' then 1 else 0 end) y,
       count(distinct l.vta_terminal) terminales
  from VTA_FACOLIBVTA l
 where l.vta_fecha_venta >= trunc(sysdate) - 2
   and l.vta_tiporeg in ('F8', 'Y')
   and l.vta_estado = 'A'
 group by l.vta_fecha_venta, l.vta_local
 order by l.vta_fecha_venta, l.vta_local;
