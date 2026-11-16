-- =====================================================================
-- FCDVT-259 - Paso 05: pruebas de SOLO LECTURA de PKG_F8_EXPORTA_MASIVA_YZ
-- xintec-nruz 16-11-2026
--
-- Lo mismo que exporta Form176 con cada combinacion de filtros. EDITAR el
-- local, el terminal y las fechas (elegir un local y fecha de la consulta 6
-- de 00_prechecks.sql). El package no aplica la regla de "2 dias hacia
-- atras" (la valida Form176): aqui se puede consultar cualquier fecha.
-- Prueba de punta a punta con datos propios: carpeta pruebas/.
-- =====================================================================

prompt === 1. Encabezado (ESPERADO: 56 columnas, igual a PKG_F8_CARGA_MASIVA_YZ.c_encabezado)
select PKG_F8_EXPORTA_MASIVA_YZ.fn_encabezado encabezado from dual;

prompt === 2. Un local, todos los terminales, un dia (por terminal la Z y despues sus Y)
select rownum n, column_value linea
  from table(PKG_F8_EXPORTA_MASIVA_YZ.fn_lineas(5, 0,                                  -- EDITAR local
                                                to_date('15-11-2026', 'dd-mm-yyyy'),   -- EDITAR fecha inicio
                                                to_date('15-11-2026', 'dd-mm-yyyy'))); -- EDITAR fecha fin

prompt === 3. Comparacion con libvta del mismo local y dia (ESPERADO: Z_LIBVTA <= Z_CSV, Y_LIBVTA = Y_CSV por terminal;
prompt ===    Z_CSV = 1 en cada terminal con cierres; si Z_LIBVTA = 0, la Z del CSV es la armada)
with l as (select ';' || column_value || ';' x
             from table(PKG_F8_EXPORTA_MASIVA_YZ.fn_lineas(5, 0,                       -- EDITAR local
                                                           to_date('15-11-2026', 'dd-mm-yyyy'),
                                                           to_date('15-11-2026', 'dd-mm-yyyy')))),
     v as (select to_number(substr(l.x, instr(l.x, ';', 1, 3) + 1, instr(l.x, ';', 1, 4) - instr(l.x, ';', 1, 3) - 1)) term,
                  substr(l.x, instr(l.x, ';', 1, 10) + 1, instr(l.x, ';', 1, 11) - instr(l.x, ';', 1, 10) - 1) tipo
             from l)
select v.term,
       sum(case when v.tipo = 'Z' then 1 else 0 end) z_csv,
       sum(case when v.tipo = 'Y' then 1 else 0 end) y_csv,
       (select count(*) from VTA_FACOLIBVTA b
         where b.vta_fecha_venta = to_date('15-11-2026', 'dd-mm-yyyy') and b.vta_local = 5   -- EDITAR
           and b.vta_terminal = v.term and b.vta_tiporeg = 'F8' and b.vta_estado = 'A') z_libvta,
       (select count(*) from VTA_FACOLIBVTA b
         where b.vta_fecha_venta = to_date('15-11-2026', 'dd-mm-yyyy') and b.vta_local = 5   -- EDITAR
           and b.vta_terminal = v.term and b.vta_tiporeg = 'Y' and b.vta_estado = 'A') y_libvta
  from v
 group by v.term
 order by 1;

prompt === 4. Un terminal (ESPERADO: solo lineas de ese terminal; sin cierres, ninguna fila)
select rownum n, column_value linea
  from table(PKG_F8_EXPORTA_MASIVA_YZ.fn_lineas(5, 1,                                  -- EDITAR local y terminal
                                                to_date('15-11-2026', 'dd-mm-yyyy'),
                                                to_date('15-11-2026', 'dd-mm-yyyy')));

prompt === 5. Todos los locales, rango de dos dias: cantidad de lineas por fecha y local
with l as (select ';' || column_value || ';' x
             from table(PKG_F8_EXPORTA_MASIVA_YZ.fn_lineas(0, 0,
                                                           to_date('14-11-2026', 'dd-mm-yyyy'),   -- EDITAR
                                                           to_date('15-11-2026', 'dd-mm-yyyy'))))  -- EDITAR
select substr(x, 2, 10) fecha,
       substr(x, instr(x, ';', 1, 2) + 1, instr(x, ';', 1, 3) - instr(x, ';', 1, 2) - 1) local,
       count(*) lineas
  from l
 group by substr(x, 2, 10), substr(x, instr(x, ';', 1, 2) + 1, instr(x, ';', 1, 3) - instr(x, ';', 1, 2) - 1)
 order by 1, 2;

prompt === 6. Todos los locales de un grupo (usuario de grupo con TODOS LOS LOCALES): solo locales con vta_grupo = 1
select count(*) lineas
  from table(PKG_F8_EXPORTA_MASIVA_YZ.fn_lineas(0, 0,
                                                to_date('15-11-2026', 'dd-mm-yyyy'),
                                                to_date('15-11-2026', 'dd-mm-yyyy'),
                                                1));                                   -- EDITAR grupo
select vta_cod_local from VTA_FACOLOCALES where vta_grupo = 1 order by 1;             -- EDITAR grupo

prompt === 7. Fecha fin anterior a la de inicio (ESPERADO: ORA-20004 ... la fecha fin no puede ser anterior a la fecha inicio)
select column_value linea
  from table(PKG_F8_EXPORTA_MASIVA_YZ.fn_lineas(5, 0,
                                                to_date('15-11-2026', 'dd-mm-yyyy'),
                                                to_date('14-11-2026', 'dd-mm-yyyy')));
