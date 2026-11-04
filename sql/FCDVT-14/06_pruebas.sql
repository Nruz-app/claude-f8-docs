-- =====================================================================
-- FCDVT-14 - Paso 06: consultas de solo lectura del resultado de una carga
-- xintec-nruz 30-10-2026 / 03-11-2026 (estado CARGADO, antes PROCESADO;
--   tablas FACO: para otro pais cambiar VTA_FACO* por VTA_<pfx>*)
-- xintec-nruz 04-11-2026: consultas 6 a 9, lo que graba Cargar (PKG_F8_GRABA_MASIVA_YZ.prc_graba)
-- La carga la hace Form174 (Buscar y Cargar). Reemplazar el numero de carga
-- (y en 6 a 9 la fecha y el local) en las lineas marcadas EDITAR (el MsgBox
-- de Form174 lo informa; o usar la consulta 1 para ver las ultimas).
--
-- Cargar con ejemplo_carga_Y_FACO_20.csv (16-10-2026, local 5) -> 3 grupos
-- GRABADO. Consultas 6 a 9: 3 libvta 'F8'/99 y 20 'Y' (T1 1-7, T2 1-7,
-- T3 1-6), 23 zzz, 3 termstat (las precreadas en -1 se conservan; si no
-- existian, -1 con 'CARGA MASIVA DE CIERRE Z - CARGA n'), 20 termstaty en -1
-- con 'CARGA MASIVA DE CIERRE Y - CARGA n' y las mismas zzz huerfanas
-- antes y despues de Cargar (la consulta 9 cuenta todo el pais en la
-- fecha, incluidas las que deja Form19). Repetir
-- Buscar + Cargar con el mismo archivo deja los mismos conteos (reemplaza).
--
-- Resultado esperado:
--   ejemplo_carga_Y_FACO_20.csv      -> 3 grupos CARGADO (16-10-2026,
--      local 5): T1 7 Y 9.400.000 = Z; T2 7 Y 7.435.000 = Z; T3 6 Y
--      9.490.000 = Z. Sin lineas con error.
--   ejemplo_carga_YZ_FACO_errores.csv -> 1 CARGADO (15-10 T1) y 4 ERROR:
--      15-10 T2 (Z 425.000 <> Y 420.000), 15-10 T3 (sin Z), 14-10 T1
--      (REC_MEFECTIVO 12a00 y TIPO X), 15-10 T99 (terminal no vigente);
--      mas 1 linea con 50 campos, sin grupo.
--   pruebas/ (03-11-2026; detalle por grupo y por linea en pruebas/README.md):
--      p01_campos_malos.csv     -> 1 CARGADO, 14 ERROR, 19 lineas con error
--      p02_falta_z.csv          -> 3 CARGADO, 3 ERROR (sin Z, sin Y, 2 Z)
--      p03_cuadratura.csv       -> 3 CARGADO, 1 ERROR (Z = suma Y + 1)
--      p04_nro_y.csv            -> 2 CARGADO, 1 ERROR (NRO_Y repetido)
--      p05_estructura.csv       -> 1 CARGADO, 1 ERROR (T99), 4 lineas con error
--      p06_encabezado_54.csv    -> carga rechazada (encabezado), sin grupos
--      p07_solo_encabezado.csv  -> sin grupos
--      p08_volumen.csv          -> 90 CARGADO (630 filas)
-- =====================================================================

prompt === 1. Ultimas cargas (INICIO y FIN de Buscar; GRABADO = Cargar)
select log_carga, log_etapa, log_usuario, log_campo, log_valor, log_motivo,
       to_char(log_fechahora, 'dd-mm-yyyy hh24:mi:ss') fechahora
  from VTA_FACOCARGA_YZ_LOG
 where log_etapa in ('INICIO', 'FIN', 'ERROR', 'GRABADO')
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
   and log_etapa in ('LECTURA', 'VALIDACION', 'RESUMEN', 'ERROR', 'GRABADO')
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

-- ---------------------------------------------------------------------
-- Lo que grabo Cargar (PKG_F8_GRABA_MASIVA_YZ.prc_graba). EDITAR fecha y local en cada consulta.
-- ---------------------------------------------------------------------
prompt === 6. libvta del dia: Z ('F8'/99) e Y por terminal
select l.vta_terminal, l.vta_tiporeg, count(*) filas,
       min(l.vta_secuencia) sec_min, max(l.vta_secuencia) sec_max,
       sum(l.vta_totalvta) total,
       sum(case when z.rec_techkey is null then 1 else 0 end) sin_zzz
  from VTA_FACOLIBVTA l, VTA_FACOZZZ z
 where l.vta_fecha_venta = to_date('16-10-2026', 'dd-mm-yyyy')   -- EDITAR fecha
   and l.vta_local = 5                                           -- EDITAR local
   and l.vta_tiporeg in ('F8', 'Y')
   and z.rec_techkey (+) = l.vta_techkey
 group by l.vta_terminal, l.vta_tiporeg
 order by 1, 2;

prompt === 7. Identificacion grabada (cada campo en su columna)
select vta_terminal, vta_tiporeg, vta_secuencia, vta_hora, vta_secuencia_srx,
       vta_bolinicial, vta_bolfinal, vta_cantbol, vta_vendedor,
       vta_crepo_inicial, vta_crepo_final, vta_montobol, vta_montoncr,
       vta_montofac, vta_totalvta, vta_estado, vta_tipof8, vta_techkey
  from VTA_FACOLIBVTA
 where vta_fecha_venta = to_date('16-10-2026', 'dd-mm-yyyy')     -- EDITAR fecha
   and vta_local = 5                                             -- EDITAR local
   and vta_tiporeg in ('F8', 'Y')
 order by vta_terminal, vta_tiporeg, vta_secuencia;

prompt === 8. Estados: termstat (Z) y termstaty (Y)
select 'Z' nivel, ter_terminal, null ter_cierrey, ter_estado, ter_notas, ter_cerradopor
  from VTA_FACOTERMSTAT
 where ter_fecha = to_date('16-10-2026', 'dd-mm-yyyy')           -- EDITAR fecha
   and ter_local = 5                                             -- EDITAR local
union all
select 'Y', ter_terminal, ter_cierrey, ter_estado, ter_notas, ter_cerradopor
  from VTA_FACOTERMSTATY
 where ter_fecha = to_date('16-10-2026', 'dd-mm-yyyy')           -- EDITAR fecha
   and ter_local = 5                                             -- EDITAR local
 order by 2, 1, 3;

prompt === 9. Control: zzz huerfanas de la fecha (igual antes y despues de Cargar) y totales Z = suma Y
select count(*) zzz_huerfanas
  from VTA_FACOZZZ z
 where z.rec_fechaproceso = to_date('16-10-2026', 'dd-mm-yyyy')  -- EDITAR fecha
   and not exists (select 1 from VTA_FACOLIBVTA l where l.vta_techkey = z.rec_techkey);
--   (cuenta las de todo el pais en esa fecha: comparar antes y despues de Cargar)

select vta_terminal,
       sum(case when vta_tiporeg = 'F8' then vta_totalvta end) total_z,
       sum(case when vta_tiporeg = 'Y'  then vta_totalvta end) suma_y
  from VTA_FACOLIBVTA
 where vta_fecha_venta = to_date('16-10-2026', 'dd-mm-yyyy')     -- EDITAR fecha
   and vta_local = 5                                             -- EDITAR local
   and vta_tiporeg in ('F8', 'Y')
 group by vta_terminal
 order by 1;
