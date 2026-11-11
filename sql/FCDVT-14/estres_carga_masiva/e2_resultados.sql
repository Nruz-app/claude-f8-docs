-- =====================================================================
-- FCDVT-14 - Prueba de estres de la carga masiva (Form174).
-- e2: resultados. SOLO LECTURA. Correrlo despues del Buscar + Cargar de
-- cada etapa (a01/b01 con 1.000, a02/b02 con 2.000, a03/b03 con 5.000),
-- y anotar el resumen en el README junto al tiempo medido.
-- xintec-nruz 10-11-2026
--
-- La suma de res_total_y de las filas GRABADO de un etapa debe cuadrar
-- con la suma total del archivo usado (columna "Suma total Y" del
-- README):
--   Serie A (fecha 07-11-2026): a01 6.154.992.598 / a02 12.594.134.013
--     / a03 31.282.447.381
--   Serie B (agosto 2026): b01 5.313.587.971 / b02 11.551.857.959
--     / b03 30.394.072.340
-- Ejecutar conectado al usuario de test. Si las tablas no se ven sin
-- esquema:  alter session set current_schema = INTRANETTS;
-- =====================================================================

-- ============ PARTE A: SERIES DE LA PRUEBA ============

-- A1. Resumen por carga. ESPERADO: filas GRABADO (una por grupo), sin
--     res_lin_error, con res_mensaje 'Grabado: Z + N Y (numeros 1 a N)'.
--     La suma de res_cant_y + res_cant_z de todas las filas de la etapa
--     = lineas de datos del archivo; la suma de res_total_y = la suma
--     total del README.
select to_char(res_fecha, 'dd-mm-yyyy') fecha, res_estado,
       count(*) grupos, sum(res_cant_y) y, sum(res_cant_z) z,
       sum(res_total_y) suma_y, max(res_lin_error) lin_error,
       to_char(max(res_fechahora), 'hh24:mi:ss') ultima_carga
  from VTA_FACOCARGA_YZ_RES
 where (res_fecha = to_date('20261107','yyyymmdd')
        or res_fecha between to_date('20260801','yyyymmdd')
                         and to_date('20260831','yyyymmdd'))
   and res_local = 5
 group by res_fecha, res_estado
 order by res_fecha, res_estado;

-- A2. Detalle del grupo de la serie A (07-11-2026, terminal 1). ESPERADO:
--     res_cant_y = Y del archivo (999 / 1999 / 4999), res_cant_z = 1,
--     res_total_y = res_total_z = suma del grupo del README.
select res_carga, res_terminal, res_cant_y, res_total_y,
       res_cant_z, res_total_z, res_lin_error, res_estado, res_mensaje
  from VTA_FACOCARGA_YZ_RES
 where res_fecha = to_date('20261107','yyyymmdd') and res_local = 5
 order by res_carga;

-- A3. Resumen de la serie B por fecha. ESPERADO: 4 grupos por fecha
--     (terminales 1 a 4); la cantidad de Y por grupo sale del round-robin
--     (8 o 9 en b01, 16 o 17 en b02, 43 o 44 en b03).
select to_char(res_fecha, 'dd-mm-yyyy') fecha, count(*) grupos,
       sum(res_cant_y) y, sum(res_total_y) suma_y
  from VTA_FACOCARGA_YZ_RES
 where res_fecha between to_date('20260801','yyyymmdd')
                     and to_date('20260831','yyyymmdd')
   and res_local = 5
 group by res_fecha
 order by res_fecha;

-- A4. Errores del log de las cargas. ESPERADO: sin filas; si un grupo
--     quedo en ERROR, el motivo esta en log_motivo (linea log_linea).
select log_carga, log_linea, log_etapa, log_campo, log_valor, log_motivo
  from VTA_FACOCARGA_YZ_LOG
 where log_carga in (select res_carga from VTA_FACOCARGA_YZ_RES
                      where (res_fecha = to_date('20261107','yyyymmdd')
                             or res_fecha between to_date('20260801','yyyymmdd')
                                              and to_date('20260831','yyyymmdd'))
                        and res_local = 5)
 order by log_carga, log_linea;

-- A5. Lo grabado en el libro de ventas, serie A. ESPERADO: en el
--     07-11-2026 T1: 1 fila F8 (la Z) + las Y del archivo, y
--     sum(vta_totalvta) de las Y = suma del grupo del README.
select l.vta_tiporeg, count(*) filas, sum(l.vta_totalvta) total
  from vta_FACOlibvta l
 where l.vta_fecha_venta = to_date('20261107','yyyymmdd')
   and l.vta_local = 5 and l.vta_terminal = 1
   and l.vta_tiporeg in ('F8', 'Y')
 group by l.vta_tiporeg;

-- A6. Lo grabado en el libro de ventas, serie B. ESPERADO: por fecha,
--     4 F8 (una Z por terminal) + la cantidad de Y de A3.
select to_char(l.vta_fecha_venta, 'dd-mm-yyyy') fecha, l.vta_tiporeg,
       count(*) filas
  from vta_FACOlibvta l
 where l.vta_fecha_venta between to_date('20260801','yyyymmdd')
                             and to_date('20260831','yyyymmdd')
   and l.vta_local = 5 and l.vta_terminal in (1, 2, 3, 4)
   and l.vta_tiporeg in ('F8', 'Y')
 group by l.vta_fecha_venta, l.vta_tiporeg
 order by l.vta_fecha_venta, l.vta_tiporeg;

-- A7. Termstaty grabadas, serie A y B. ESPERADO: una fila por Y, en
--     -1, con la glosa 'CARGA MASIVA DE CIERRE Y - CARGA <num>'.
select 'A' serie, count(*) termstaty from vta_FACOtermstaty
 where ter_fecha = to_date('20261107','yyyymmdd') and ter_local = 5
union all
select 'B', count(*) from vta_FACOtermstaty
 where ter_fecha between to_date('20260801','yyyymmdd')
                     and to_date('20260831','yyyymmdd')
   and ter_local = 5 and ter_terminal in (1, 2, 3, 4);

exit
