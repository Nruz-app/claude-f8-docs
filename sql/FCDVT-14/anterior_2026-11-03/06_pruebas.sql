-- =====================================================================
-- FCDVT-14 - Paso 06: consultas de solo lectura del resultado de una carga
-- xintec-nruz 30-10-2026
-- La carga la hace Form174 (Buscar). Reemplazar el numero de carga en las
-- lineas marcadas EDITAR (el MsgBox de Form174 lo informa; o usar la
-- consulta 1 para ver las ultimas).
--
-- Resultado esperado:
--   ejemplo_carga_Y_FACO_20.csv      -> 3 grupos PROCESADO (16-10-2026,
--      local 5): T1 7 Y 9.400.000 = Z; T2 7 Y 7.435.000 = Z; T3 6 Y
--      9.490.000 = Z. Sin lineas con error.
--   ejemplo_carga_YZ_FACO_errores.csv -> 1 PROCESADO (15-10 T1) y 4 ERROR:
--      15-10 T2 (Z 425.000 <> Y 420.000), 15-10 T3 (sin Z), 14-10 T1
--      (REC_MEFECTIVO 12a00 y TIPO X), 15-10 T99 (terminal no vigente);
--      mas 1 linea con 50 campos, sin grupo.
--   pruebas/ (03-11-2026; detalle por grupo y por linea en pruebas/README.md):
--      p01_campos_malos.csv     -> 1 PROCESADO, 14 ERROR, 19 lineas con error
--      p02_falta_z.csv          -> 3 PROCESADO, 3 ERROR (sin Z, sin Y, 2 Z)
--      p03_cuadratura.csv       -> 3 PROCESADO, 1 ERROR (Z = suma Y + 1)
--      p04_nro_y.csv            -> 2 PROCESADO, 1 ERROR (NRO_Y repetido)
--      p05_estructura.csv       -> 1 PROCESADO, 1 ERROR (T99), 4 lineas con error
--      p06_encabezado_54.csv    -> carga rechazada (encabezado), sin grupos
--      p07_solo_encabezado.csv  -> sin grupos
--      p08_volumen.csv          -> 90 PROCESADO (630 filas)
-- =====================================================================

prompt === 1. Ultimas cargas (INICIO y FIN)
select log_carga, log_etapa, log_usuario, log_valor, log_motivo,
       to_char(log_fechahora, 'dd-mm-yyyy hh24:mi:ss') fechahora
  from VTA_FACOCARGA_YZ_LOG
 where log_etapa in ('INICIO', 'FIN', 'ERROR')
   and log_carga >= (select nvl(max(log_carga), 0) - 4 from VTA_FACOCARGA_YZ_LOG)
 order by log_carga desc, log_id;

prompt === 2. Resumen (lo que muestra la grilla)
select res_fecha, res_local, res_terminal, res_cant_y, res_total_y,
       res_cant_z, res_total_z, res_lin_error, res_estado, res_mensaje
  from VTA_FACOCARGA_YZ_RES
 where res_carga = 1                      -- EDITAR numero de carga
 order by res_fecha, res_local, res_terminal;

prompt === 3. Errores por linea y campo
select log_linea, log_etapa, log_campo, log_valor, log_motivo
  from VTA_FACOCARGA_YZ_LOG
 where log_carga = 1                      -- EDITAR numero de carga
   and log_etapa in ('LECTURA', 'VALIDACION', 'RESUMEN', 'ERROR')
 order by log_linea nulls last, log_id;

prompt === 4. Detalle de las lineas
select det_linea, det_fecha, det_local, det_terminal, det_tipo, det_nro_y,
       det_hora, det_total, det_estado
  from VTA_FACOCARGA_YZ_DET
 where det_carga = 1                      -- EDITAR numero de carga
 order by det_linea;

prompt === 5. Control: Z contra suma de Y concepto a concepto (solo informativo)
select d.det_fecha, d.det_local, d.det_terminal,
       sum(case when d.det_tipo = 'Z' then d.rec_mefectivo else -d.rec_mefectivo end) dif_efectivo,
       sum(case when d.det_tipo = 'Z' then d.rec_mtarj     else -d.rec_mtarj     end) dif_tarjeta,
       sum(case when d.det_tipo = 'Z' then d.rec_mretiros  else -d.rec_mretiros  end) dif_retiros
  from VTA_FACOCARGA_YZ_DET d
 where d.det_carga = 1                    -- EDITAR numero de carga
   and d.det_tipo in ('Y', 'Z')
 group by d.det_fecha, d.det_local, d.det_terminal
 order by 1, 2, 3;
