-- =====================================================================
-- FCDVT-10 (HU-03) - Prueba "recarga v1 / v2" de la carga masiva de
-- Tottus Chile (SFCL) - py2: resultados. SOLO LECTURA.
-- xintec-nruz 12-11-2026
-- GENERADO por arma_prueba.py desde plantillas/py2_resultados.sql.tpl
-- (no editar a mano: volver a correr el generador).
--
-- Fecha {FECHA_DMY}, local {LOCAL}, terminales TA={TA}, TB={TB}, TC={TC},
-- TD={TD}. Ejecutar despues de Cargar v1 y otra vez despues de Cargar v2.
-- Los ESPERADO son los del final (despues de v2); entre parentesis, lo
-- que debe verse despues de v1.
-- Columna de pago usada para cuadrar la formula de la Z: {COL_PAGO}.
-- Si las tablas no se ven sin esquema:
--   alter session set current_schema = INTRANETTS;
-- =====================================================================

-- A1. Resumen de las cargas del dia. ESPERADO: carga v1 con 4 grupos
--     GRABADO y carga v2 (numero mayor) con 4 grupos GRABADO:
--       TA v1 'Grabado: Z + 1 Y (numeros 1 a 1)'           total 1.000.000
--          v2 '... Reemplazo lo anterior: 1 Z y 1 Y'        total 1.200.000
--       TB v1 'Grabado: Z + 2 Y (numeros 1 a 2)'           total 1.000.000
--          v2 'Grabado: Z + 1 Y (numeros 1 a 1). Reemplazo lo anterior: 1 Z y 2 Y'
--                                                           total 1.150.000
--       TC v1 'Grabado: Z + Y1 automatica (copia de la Z)' total   800.000
--          v2 '... (copia de la Z). Reemplazo lo anterior: 1 Z y 1 Y'
--                                                           total   950.000
--       TD v1 'Grabado: Z + 2 Y (numeros 1 a 2)'           total   800.000
--          v2 'Grabado: Z + Y1 automatica (copia de la Z). Reemplazo lo
--             anterior: 1 Z y 2 Y'                          total   900.000
--     Las filas de v1 siguen en GRABADO (historia de la carga).
select res_terminal, res_carga, res_tipo_carga, res_cant_z, res_total_z,
       res_cant_y, res_total_y, res_lin_error, res_estado, res_mensaje
  from VTA_SFCLCARGA_YZ_RES
 where res_fecha = to_date('{FECHA}','yyyymmdd')
   and res_local = {LOCAL}
   and res_terminal in ({TERMS})
 order by res_terminal, res_carga;

-- A2. Log de las cargas del dia (Buscar y Cargar). ESPERADO: sin filas
--     de ERROR; si un grupo quedo en ERROR, el motivo esta en log_motivo.
select log_carga, log_id, log_linea, log_etapa, log_campo, log_valor, log_motivo
  from VTA_SFCLCARGA_YZ_LOG
 where log_carga in (select res_carga from VTA_SFCLCARGA_YZ_RES
                      where res_fecha = to_date('{FECHA}','yyyymmdd')
                        and res_local = {LOCAL}
                        and res_terminal in ({TERMS}))
   and log_etapa in ('INICIO', 'RESUMEN', 'GRABADO', 'ERROR', 'FIN')
 order by log_carga, log_id;

-- B1. Libro de ventas (lo que quedo). ESPERADO despues de v2:
--       TA: F8/99 1.200.000 y Y/1 1.200.000   (v1: 1.000.000 y 1.000.000)
--       TB: F8/99 1.150.000 y Y/1 1.150.000   (v1: Z 1.000.000, Y/1 600.000,
--           Y/2 400.000; la Y/2 YA NO DEBE ESTAR)
--       TC: F8/99   950.000 y Y/1   950.000   (v1: 800.000 y Y1 automatica 800.000)
--       TD: F8/99   900.000 y Y/1   900.000   (v1: Z 800.000, Y/1 500.000,
--           Y/2 300.000; ahora solo la Y1 automatica)
--     Identificacion de v2 (hora / secuencia_srx / bolfinal): ver hoja
--     Resumen del Excel. La Y1 automatica copia la de la Z.
select l.vta_terminal, l.vta_tiporeg, l.vta_secuencia, l.vta_montobol, l.vta_totalvta,
       l.vta_hora, l.vta_secuencia_srx, l.vta_bolfinal, l.vta_vendedor,
       l.vta_crepo_inicial, l.vta_estado, l.vta_techkey
  from VTA_SFCLLIBVTA l
 where l.vta_fecha_venta = to_date('{FECHA}','yyyymmdd')
   and l.vta_local = {LOCAL}
   and l.vta_terminal in ({TERMS})
   and l.vta_tiporeg in ('F8', 'Y')
 order by l.vta_terminal, l.vta_tiporeg, l.vta_secuencia;

-- B2. Cantidad de filas por terminal (que v2 no dejo restos de v1).
--     ESPERADO despues de v2: 2 libvta y 2 zzz en las 4 terminales
--     (antes de v2: TA 2, TB 3, TC 2, TD 3).
select l.vta_terminal, count(*) filas_libvta, count(z.rec_techkey) filas_zzz
  from VTA_SFCLLIBVTA l, VTA_SFCLZZZ z
 where z.rec_techkey (+) = l.vta_techkey
   and l.vta_fecha_venta = to_date('{FECHA}','yyyymmdd')
   and l.vta_local = {LOCAL}
   and l.vta_terminal in ({TERMS})
   and l.vta_tiporeg in ('F8', 'Y')
 group by l.vta_terminal
 order by l.vta_terminal;

-- B3. Columna de pago en la zzz (la que cuadra la formula de la Z).
--     ESPERADO: el mismo monto de la venta en cada fila (F8 y Y) cuando la
--     formula esta activa; nulo si el generador no uso columna de pago.
select l.vta_terminal, l.vta_tiporeg, l.vta_secuencia, l.vta_totalvta,
       {COL_PAGO_EXPR} pago
  from VTA_SFCLLIBVTA l, VTA_SFCLZZZ z
 where z.rec_techkey = l.vta_techkey
   and l.vta_fecha_venta = to_date('{FECHA}','yyyymmdd')
   and l.vta_local = {LOCAL}
   and l.vta_terminal in ({TERMS})
   and l.vta_tiporeg in ('F8', 'Y')
 order by l.vta_terminal, l.vta_tiporeg, l.vta_secuencia;

-- C1. Estados. ESPERADO despues de v2: termstaty, UNA fila por terminal
--     (cierrey 1, estado -1) con la glosa 'CARGA MASIVA DE CIERRE Y -
--     CARGA <v2>'; en TB y TD la Y 2 de v1 ya no esta. termstat de la Z:
--     estado -1 con la glosa de la carga v1 (Cargar solo la inserta si no
--     existe; no la cambia).
select 'Z' nivel, s.ter_terminal, null cierrey, s.ter_estado, s.ter_notas, s.ter_cerradopor
  from VTA_SFCLTERMSTAT s
 where s.ter_fecha = to_date('{FECHA}','yyyymmdd')
   and s.ter_local = {LOCAL}
   and s.ter_terminal in ({TERMS})
union all
select 'Y', y.ter_terminal, y.ter_cierrey, y.ter_estado, y.ter_notas, y.ter_cerradopor
  from VTA_SFCLTERMSTATY y
 where y.ter_fecha = to_date('{FECHA}','yyyymmdd')
   and y.ter_local = {LOCAL}
   and y.ter_terminal in ({TERMS})
 order by 2, 1, 3;

-- D1. Lo que crea TRG_VTA_SFCLZZZ_I (VTA_SFCLTARJ 2001/2002 por Y).
--     Al insertar la zzz de la Z el trigger borra las 2001-2999 del
--     terminal-dia, y cada Y las vuelve a crear. ESPERADO despues de v2:
--     solo cierrey 1 en las 4 terminales (montos 0: el CSV no informa
--     transbank ni sodimac). Si en TB o TD aparece cierrey 2 con
--     y_existe = 'NO', quedo una fila huerfana de la Y 2 de v1.
select j.vta_terminal, j.vta_cierrey, j.vta_cod_tarj, j.vta_monto_z, j.vta_monto_inf,
       j.vta_trans,
       (select decode(count(*), 0, 'NO', 'SI') from VTA_SFCLTERMSTATY y
         where y.ter_fecha = j.vta_fecha and y.ter_local = j.vta_local
           and y.ter_terminal = j.vta_terminal and y.ter_cierrey = j.vta_cierrey) y_existe
  from VTA_SFCLTARJ j
 where j.vta_fecha = to_date('{FECHA}','yyyymmdd')
   and j.vta_local = {LOCAL}
   and j.vta_terminal in ({TERMS})
   and j.vta_cod_tarj between 2001 and 2999
 order by j.vta_terminal, j.vta_cierrey, j.vta_cod_tarj;

-- D2. Movimientos 'AL' (ajuste ley 20956) del trigger. ESPERADO: sin
--     filas (rec_mtotalpeso no viene en el CSV).
select mov_terminal, mov_cierrey, mov_tipomov, mov_monto, mov_hechopor
  from VTA_SFCLMOVDET
 where mov_fecha = to_date('{FECHA}','yyyymmdd')
   and mov_local = {LOCAL}
   and mov_terminal in ({TERMS})
   and mov_tipomov = 'AL'
 order by mov_terminal, mov_cierrey;

-- E1. RESPUESTA: que monto quedo al final, por terminal. ESPERADO:
--       TA total_z 1.200.000  cant_y 1  suma_y 1.200.000  (v1 1.000.000)
--       TB total_z 1.150.000  cant_y 1  suma_y 1.150.000  (v1 1.000.000, 2 Y)
--       TC total_z   950.000  cant_y 1  suma_y   950.000  (v1   800.000, Y1 aut.)
--       TD total_z   900.000  cant_y 1  suma_y   900.000  (v1   800.000, 2 Y)
--     carga_y = numero de carga de la glosa de la Y (debe ser el de v2).
select l.vta_terminal,
       sum(decode(l.vta_tiporeg, 'F8', l.vta_totalvta, 0)) total_z,
       sum(decode(l.vta_tiporeg, 'Y', 1, 0)) cant_y,
       sum(decode(l.vta_tiporeg, 'Y', l.vta_totalvta, 0)) suma_y,
       (select max(substr(y.ter_notas, instr(y.ter_notas, 'CARGA ', -1) + 6))
          from VTA_SFCLTERMSTATY y
         where y.ter_fecha = l.vta_fecha_venta and y.ter_local = l.vta_local
           and y.ter_terminal = l.vta_terminal) carga_y,
       (select max(r.res_carga) from VTA_SFCLCARGA_YZ_RES r
         where r.res_fecha = l.vta_fecha_venta and r.res_local = l.vta_local
           and r.res_terminal = l.vta_terminal and r.res_estado = 'GRABADO') ultima_carga
  from VTA_SFCLLIBVTA l
 where l.vta_fecha_venta = to_date('{FECHA}','yyyymmdd')
   and l.vta_local = {LOCAL}
   and l.vta_terminal in ({TERMS})
   and l.vta_tiporeg in ('F8', 'Y')
 group by l.vta_fecha_venta, l.vta_local, l.vta_terminal
 order by l.vta_terminal;
