-- =====================================================================
-- FCDVT-10 (HU-03) - Paso 06: consultas de prueba (SOLO LECTURA)
-- Carga masiva de cierres Y / Z, Tottus Chile (SFCL)
-- xintec-nruz 11-11-2026
-- Completar los valores EDITAR (carga, fecha y local) en cada consulta.
-- =====================================================================
set pagesize 200 linesize 250 feedback on
column res_mensaje format a80
column log_motivo format a80
column log_valor format a30
column encabezado format a250

prompt ===== 1) Encabezado del CSV (plantilla de Tottus, sale de VTA_PAINT_Z) =====
select PKG_F8_CARGA_MASIVA_YZ_SFCL.fn_encabezado('SFCL') encabezado from dual;

prompt ===== 2) Formula de validacion de la Z que usa Cargar (nulo = desactivada) =====
select PKG_F8_CARGA_MASIVA_YZ_SFCL.fn_sql_valida_z formula from dual;

prompt ===== 3) Ultimas cargas =====
select log_carga, min(log_fechahora) inicio, max(log_usuario) usuario,
       max(case when log_etapa = 'FIN' then log_motivo end) fin
  from VTA_SFCLCARGA_YZ_LOG
 group by log_carga
 order by log_carga desc;

prompt ===== 4) Resumen de una carga (grilla de Form174) =====
select res_fecha, res_local, res_terminal, res_tipo_carga, res_cant_z, res_total_z,
       res_cant_y, res_total_y, res_lin_error, res_estado, res_mensaje
  from VTA_SFCLCARGA_YZ_RES
 where res_carga = 0                                   -- EDITAR: numero de carga
 order by res_fecha, res_local, res_terminal;

prompt ===== 5) Log de una carga =====
select log_id, log_linea, log_etapa, log_campo, log_valor, log_motivo
  from VTA_SFCLCARGA_YZ_LOG
 where log_carga = 0                                   -- EDITAR: numero de carga
 order by log_linea nulls last, log_id;

prompt ===== 6) Detalle de una carga: lineas y montos informados =====
select d.det_linea, d.det_fecha, d.det_local, d.det_terminal, d.det_tipo, d.det_nro_y,
       d.det_tipo_carga, d.det_total, d.det_estado, m.dtm_columna, m.dtm_monto
  from VTA_SFCLCARGA_YZ_DET d, VTA_SFCLCARGA_YZ_DETM m
 where d.det_carga = 0                                 -- EDITAR: numero de carga
   and m.dtm_carga (+) = d.det_carga
   and m.dtm_linea (+) = d.det_linea
 order by d.det_linea, m.dtm_columna;

prompt ===== 7) Lo grabado en libvta para una fecha y un local (Z = F8/99; Y = Y/N) =====
select l.vta_terminal, l.vta_tiporeg, l.vta_secuencia, l.vta_techkey, l.vta_montobol, l.vta_montoncr,
       l.vta_montofac, l.vta_mmontondb, l.vta_montoguia, l.vta_totalvta, l.vta_bolinicial,
       l.vta_bolfinal, l.vta_cantbol, l.vta_hora, l.vta_secuencia_srx, l.vta_vendedor
  from VTA_SFCLLIBVTA l
 where l.vta_fecha_venta = to_date('01-01-2026', 'dd-mm-yyyy')   -- EDITAR
   and l.vta_local = 0                                           -- EDITAR
   and l.vta_tiporeg in ('F8', 'Y')
 order by l.vta_terminal, l.vta_tiporeg, l.vta_secuencia;

prompt ===== 8) Estado de la Z y de las Y (termstat / termstaty) =====
select 'Z' tipo, ter_terminal, null cierrey, ter_estado, ter_notas, ter_cerradopor
  from VTA_SFCLTERMSTAT
 where ter_fecha = to_date('01-01-2026', 'dd-mm-yyyy')           -- EDITAR
   and ter_local = 0                                             -- EDITAR
union all
select 'Y', ter_terminal, ter_cierrey, ter_estado, ter_notas, ter_cerradopor
  from VTA_SFCLTERMSTATY
 where ter_fecha = to_date('01-01-2026', 'dd-mm-yyyy')           -- EDITAR
   and ter_local = 0                                             -- EDITAR
 order by 2, 1, 3;

prompt ===== 9) zzz de un techkey (columnas no nulas: ver en la herramienta de consulta) =====
select * from VTA_SFCLZZZ where rec_techkey = 0                  -- EDITAR: techkey de la consulta 7
;
