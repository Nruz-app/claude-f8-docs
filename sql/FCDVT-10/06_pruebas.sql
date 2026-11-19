-- =====================================================================
-- FCDVT-10 (HU-03) - Paso 06: consultas de prueba (SOLO LECTURA)
-- Carga masiva de cierres Y / Z, Tottus Chile (SFCL)
-- xintec-nruz 11-11-2026 / 19-11-2026 (reglas de Colombia: sin formula de la Z ni MODIFICAR)
-- Completar los valores EDITAR (carga, fecha y local) en cada consulta.
-- =====================================================================
set pagesize 200 linesize 250 feedback on
column res_mensaje format a80
column log_motivo format a80
column log_valor format a30
column encabezado format a250

prompt ===== 1) Encabezado del CSV (plantilla de Tottus, lista fija c_encabezado) =====
select PKG_F8_CARGA_MASIVA_YZ_SFCL.fn_encabezado('SFCL') encabezado from dual;

prompt ===== 3) Ultimas cargas =====
select log_carga, min(log_fechahora) inicio, max(log_usuario) usuario,
       max(case when log_etapa = 'FIN' then log_motivo end) fin
  from VTA_SFCLCARGA_YZ_LOG
 group by log_carga
 order by log_carga desc;

prompt ===== 4) Resumen de una carga (grilla de Form174) =====
select res_fecha, res_local, res_terminal, res_cant_z, res_total_z,
       res_cant_y, res_total_y, res_lin_error, res_estado, res_mensaje
  from VTA_SFCLCARGA_YZ_RES
 where res_carga = 0                                   -- EDITAR: numero de carga
 order by res_fecha, res_local, res_terminal;

prompt ===== 5) Log de una carga =====
select log_id, log_linea, log_etapa, log_campo, log_valor, log_motivo
  from VTA_SFCLCARGA_YZ_LOG
 where log_carga = 0                                   -- EDITAR: numero de carga
 order by log_linea nulls last, log_id;

prompt ===== 6) Detalle de una carga: lineas y conceptos de venta =====
select det_linea, det_fecha, det_local, det_terminal, det_tipo, det_nro_y,
       det_hora, det_tipo_carga, vta_montobol, vta_montoncr, vta_montofac,
       vta_mmontondb, vta_montoguia, det_total, det_estado
  from VTA_SFCLCARGA_YZ_DET
 where det_carga = 0                                   -- EDITAR: numero de carga
 order by det_linea;

prompt ===== 6b) Todos los montos de una linea (vacio en el CSV = 0) =====
select * from VTA_SFCLCARGA_YZ_DET
 where det_carga = 0                                   -- EDITAR: numero de carga
   and det_linea = 0                                   -- EDITAR: linea
;

prompt ===== 6c) Control: columnas de concepto de VTA_SFCLCARGA_YZ_DET (ESPERADO: 63, de la 15 a la 77) =====
select count(*) columnas_concepto, min(column_id) primera, max(column_id) ultima
  from user_tab_columns
 where table_name = 'VTA_SFCLCARGA_YZ_DET'
   and column_id between 15 and 77
   and column_name not like 'DET\_%' escape '\';

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
