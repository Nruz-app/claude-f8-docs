-- =====================================================================
-- FCDVT-14 + FSCC-12901 - Sesion "crear Y con la carga masiva y
-- compensarla con DI" - py2: resultados. SOLO LECTURA.
-- xintec-nruz 13-11-2026
--
-- Sesion 8: fecha de venta 12-11-2026, local 5, terminales 1 a 6, Y 1.
-- Ejecutar despues de cada paso (carga v1, sobres, carga v2, sobres T5).
-- Parte A: la carga masiva. Parte B: la DI. Parte C: la recarga v1/v2
-- de T5 y T6 (que monto queda al final).
-- Los ESPERADO son los del final de la sesion (despues de la v2 y de los
-- sobres de T5).
-- Si las tablas no se ven sin esquema:
--   alter session set current_schema = INTRANETTS;
-- =====================================================================

-- ============ PARTE A: CARGA MASIVA (Form174, FCDVT-14) ============

-- A1. Resumen de las cargas del dia. ESPERADO: 8 filas GRABADO, con
--     res_cant_y 1, res_cant_z 1 y sin res_lin_error:
--     carga v1 (6 filas): res_mensaje 'Grabado: Z + 1 Y (numeros 1 a 1)'
--       T1 2.670.800  T2 860.000  T3 2.675.000  T4 2.342.000
--       T5 1.000.000  T6 1.500.800
--     carga v2 (2 filas, numero mayor): 'Grabado: Z + 1 Y (numeros 1 a
--     1). Reemplazo lo anterior: 1 Z y 1 Y'
--       T5 1.200.000  T6 1.490.000
--     Las filas de v1 de T5 y T6 siguen en GRABADO (es la historia de la
--     carga): lo que vale es lo que esta en libvta/zzz (A3, A4, C2).
select res_carga, to_char(res_fecha, 'dd-mm-yyyy') fecha, res_local, res_terminal,
       res_cant_y, res_total_y, res_cant_z, res_total_z, res_lin_error,
       res_estado, res_mensaje, res_usuario
  from VTA_FACOCARGA_YZ_RES
 where res_fecha = to_date('20261112','yyyymmdd')
   and res_local = 5
 order by res_carga, res_terminal;

-- A2. Log de las cargas del dia. ESPERADO: fila GRABADO por grupo (6 en
--     la carga v1 y 2 en la v2) y ninguna de ERROR; si un grupo quedo ERROR, el motivo esta
--     en log_motivo (linea log_linea).
select log_carga, log_id, log_linea, log_etapa, log_campo, log_valor,
       log_motivo, log_usuario, log_fechahora
  from VTA_FACOCARGA_YZ_LOG
 where log_carga in (select res_carga from VTA_FACOCARGA_YZ_RES
                      where res_fecha = to_date('20261112','yyyymmdd') and res_local = 5)
 order by log_carga, log_id;

-- A3. Lo grabado en el libro de ventas del dia. ESPERADO: por caja 2
--     filas (no 4: v2 borro las de v1): F8/99 (la Z) y Y/1, con
--     vta_totalvta = total del grupo
--       T1 2.670.800   T2 860.000   T3 2.675.000   T4 2.342.000
--       T5 1.200.000 (v2; en v1 era 1.000.000)
--       T6 1.490.000 (v2; en v1 era 1.500.800)
select l.vta_local, l.vta_terminal, l.vta_tiporeg, l.vta_secuencia,
       l.vta_estado, l.vta_totalvta
  from vta_FACOlibvta l
 where l.vta_fecha_venta = to_date('20261112','yyyymmdd')
   and l.vta_local = 5 and l.vta_terminal in (1, 2, 3, 4, 5, 6)
   and l.vta_tiporeg in ('F8', 'Y')
 order by l.vta_terminal, l.vta_tiporeg, l.vta_secuencia;

-- A4. EFECTIVO grabado en la zzz de cada fila. ESPERADO: el de la tabla
--     de LEEME: T1 2.670.800, T2 860.000, T3 2.675.000, T4 2.342.000,
--     T5 1.200.000 y T6 1.490.000 (los de v2), en la fila de la Z (F8/99) y en la de la Y (que son iguales:
--     BOLETAS = EFECTIVO y hay una sola Y).
select l.vta_local, l.vta_terminal, l.vta_tiporeg, l.vta_secuencia,
       z.rec_mefectivo
  from vta_FACOlibvta l, vta_FACOzzz z
 where l.vta_techkey = z.rec_techkey
   and l.vta_fecha_venta = to_date('20261112','yyyymmdd')
   and l.vta_local = 5 and l.vta_terminal in (1, 2, 3, 4, 5, 6)
   and l.vta_tiporeg in ('F8', 'Y')
 order by l.vta_terminal, l.vta_tiporeg, l.vta_secuencia;

-- A5. Identificacion de la Y (cada campo en su columna, FORMATO 3.1).
--     ESPERADO: T1 hora 1745 y T2 1420, T3 1610 y T4 1805; secuencias
--     2101, 2103, 2105 y 2107; boletas 6101000..4000; vendedor 71001 a
--     71004; crepo 4101, 4201, 4301 y 4401. T5 y T6 con los datos de v2
--     (no los de v1): T5 hora 1930, secuencia 2209, boleta 6105500,
--     vendedor 71005, crepo 4502; T6 hora 2010, secuencia 2211, boleta
--     6106500, vendedor 71006, crepo 4602.
select l.vta_local, l.vta_terminal, l.vta_secuencia, l.vta_hora,
       l.vta_bolfinal, l.vta_vendedor, l.vta_crepo_inicial
  from vta_FACOlibvta l
 where l.vta_fecha_venta = to_date('20261112','yyyymmdd')
   and l.vta_local = 5 and l.vta_terminal in (1, 2, 3, 4, 5, 6)
   and l.vta_tiporeg = 'Y'
 order by l.vta_terminal;

-- A6. Estados. ESPERADO: termstaty, 6 filas en -1 con la glosa
--     'CARGA MASIVA DE CIERRE Y - CARGA <num>': T1 a T4 con el numero de
--     la carga v1, T5 y T6 con el de la v2 (Cargar borra y reinserta la
--     termstaty);
--     termstat, la de la Z en -1: con la glosa 'CARGA MASIVA DE CIERRE
--     Z - CARGA <num>' si la creo la carga, o precreada sin glosa (se
--     conserva). OJO: en T5 y T6 la termstat de la Z queda con el numero
--     de la carga v1 (Cargar solo la inserta si no existe; no la toca).
select 'Y' nivel, t.ter_terminal, t.ter_cierrey, to_char(t.ter_estado) estado,
       t.ter_notas, t.ter_cerradopor
  from vta_FACOtermstaty t
 where t.ter_fecha = to_date('20261112','yyyymmdd')
   and t.ter_local = 5 and t.ter_terminal in (1, 2, 3, 4, 5, 6)
 union all
 select 'Z', s.ter_terminal, null, to_char(s.ter_estado), s.ter_notas, s.ter_cerradopor
  from vta_FACOtermstat s
 where s.ter_fecha = to_date('20261112','yyyymmdd')
   and s.ter_local = 5 and s.ter_terminal in (1, 2, 3, 4, 5, 6)
 order by 1, 2, 3;

-- ============ PARTE B: DI (Form133, FSCC-12901) ============

-- B1. Log del dia (una fila por caja evaluada). ESPERADO:
--       T1 DI_REGISTRADA  dif_real -800   monto_di -800   (prueba 1)
--       T2 DI_REGISTRADA  dif_real 15000  monto_di 15000  (prueba 2)
--       T3 FUERA_RANGO    dif_real -5000  sin DI          (prueba 3)
--       T4 DR_CERO        dif_real 0      sin DI          (prueba 4)
--       T6 DI_REGISTRADA  dif_real -800   monto_di -800   (prueba 6,
--                         contra el efectivo de v1 1.500.800)
--       T5 DI_REGISTRADA  dif_real -500   monto_di -500   (prueba 5,
--                         contra el efectivo de v2 1.200.000; con v1
--                         habria sido +199.500 FUERA_RANGO)
--     Nota: log_dif_real y log_sobres corresponden al momento de la
--     carga; el DR actual es la consulta B2.
select log_id, log_local, log_terminal, log_cierrey, log_sobres, log_dif_real,
       log_di_anterior, log_monto_di, log_resultado, log_mensaje, log_usuario,
       log_fechahora
  from VTA_FACOLOG_COMPENSA_DI
 where log_fecha_vta = to_date('20261112','yyyymmdd')
   and log_local = 5
 order by log_id;

-- B2. Estado de las Y y DR actual. ESPERADO: las 6 abiertas (ter_estado
--     <= 0, sin PROC_CIERRE_AUTO). DR actual 0 en T1, T2, T4 y T5 (la DI
--     la compenso), -5000 en T3 (sin DI: queda la diferencia) y +10.800
--     en T6 (la DI -800 de v1 quedo y la Y ahora es 1.490.000; ver C2).
--     Despues del cierre con CC: ter_estado = 1 en T1, T2, T4 y T5.
select t.ter_local, t.ter_terminal, t.ter_cierrey, t.ter_estado, t.ter_cerradopor,
       PKG_F8_COMPENSA_DI_CARGA.fn_dif_real('FACO', t.ter_fecha, t.ter_local,
                                            t.ter_terminal, t.ter_cierrey) dr_actual
  from VTA_FACOTERMSTATY t
 where t.ter_fecha = to_date('20261112','yyyymmdd')
   and t.ter_local = 5 and t.ter_terminal in (1, 2, 3, 4, 5, 6)
 order by t.ter_terminal, t.ter_cierrey;

-- B3. DI registradas. ESPERADO: 4 filas (T1 -800; T2 15000; T5 -500;
--     T6 -800, la de v1, que Cargar v2 no borra), con
--     mov_hechopor PROC_DI_AUTO, mov_regul S y mov_fechareg = 12-11-2026.
select m.mov_local, m.mov_terminal, m.mov_cierrey, m.mov_tipomov, m.mov_monto,
       m.mov_hechopor, m.mov_regul, m.mov_fechareg, m.mov_techkey
  from VTA_FACOMOVDET m
 where m.mov_fecha = to_date('20261112','yyyymmdd')
   and m.mov_local = 5 and m.mov_terminal in (1, 2, 3, 4, 5, 6)
   and m.mov_tipomov = 'DI'
 order by m.mov_terminal;

-- B4. Observacion de la DI (lo que muestra Form4). ESPERADO: 4 filas
--     (T1, T2, T5 y T6) con COMPENSACION AUTOMATICA DI.
select c.cpd_local, c.cpd_terminal, c.cpd_tipmov, c.cpd_obs
  from VTA_FACOCOMPDES c
 where c.cpd_fecha = to_date('20261112','yyyymmdd')
   and c.cpd_local = 5 and c.cpd_terminal in (1, 2, 3, 4, 5, 6)
   and c.cpd_tipmov = 'DI'
 order by c.cpd_terminal;

-- B5. Sobres cargados por caja. ESPERADO: 2 por caja (T1 2.670.000,
--     T2 875.000, T3 2.670.000, T4 2.342.000, T5 1.199.500, T6 1.500.000)
--     con prv_cierrey = 1.
select prv_local, prv_terminal, prv_cierrey, count(*) sobres,
       sum(prv_montosobre + nvl(prv_montodif, 0)) total
  from vta_FACOprd
 where prv_fechavta = to_date('20261112','yyyymmdd')
   and prv_local = 5 and prv_terminal in (1, 2, 3, 4, 5, 6)
   and prv_tiporec = 'F8'
 group by prv_local, prv_terminal, prv_cierrey
 order by prv_terminal;

-- ============ PARTE C: RECARGA v1 / v2 (T5 y T6) ============

-- C1. Las dos cargas de T5 y T6 lado a lado. ESPERADO: 2 filas por
--     terminal; la de numero menor (v1) con T5 1.000.000 / T6 1.500.800
--     y la mayor (v2) con T5 1.200.000 / T6 1.490.000 y el mensaje
--     '... Reemplazo lo anterior: 1 Z y 1 Y'. Las dos en GRABADO.
select res_terminal, res_carga, res_total_y, res_total_z, res_estado,
       res_mensaje, res_fechahora
  from VTA_FACOCARGA_YZ_RES
 where res_fecha = to_date('20261112','yyyymmdd')
   and res_local = 5 and res_terminal in (5, 6)
 order by res_terminal, res_carga;

-- C2. Monto que quedo al final y cuadratura de la Y. ESPERADO:
--       T5 efectivo_y 1.200.000  sobres 1.199.500  dif_caja -500
--          di -500  dif_real 0        (v2 antes de los sobres)
--       T6 efectivo_y 1.490.000  sobres 1.500.000  dif_caja +10.000
--          di -800  dif_real +10.800  (v2 despues de los sobres: la DI
--          -800 calculada con v1 no se recalcula al recargar)
--     dif_caja = fn_dif_real_sin_di (DR sin la DI automatica);
--     dif_real = fn_dif_real (lo que muestra Form3Y y usa el cierre).
--     glosa_y muestra que carga dejo la Y (debe ser la v2).
select l.vta_terminal, z.rec_mefectivo efectivo_y, y.ter_notas glosa_y,
       (select sum(p.prv_montosobre + nvl(p.prv_montodif, 0))
          from vta_FACOprd p
         where p.prv_fechavta = l.vta_fecha_venta and p.prv_local = l.vta_local
           and p.prv_terminal = l.vta_terminal and p.prv_tiporec = 'F8') sobres,
       PKG_F8_COMPENSA_DI_CARGA.fn_dif_real_sin_di('FACO', l.vta_fecha_venta, l.vta_local,
                                                   l.vta_terminal, 1) dif_caja,
       (select sum(m.mov_monto) from VTA_FACOMOVDET m
         where m.mov_fecha = l.vta_fecha_venta and m.mov_local = l.vta_local
           and m.mov_terminal = l.vta_terminal and m.mov_cierrey = 1
           and m.mov_tipomov = 'DI') di,
       PKG_F8_COMPENSA_DI_CARGA.fn_dif_real('FACO', l.vta_fecha_venta, l.vta_local,
                                            l.vta_terminal, 1) dif_real
  from vta_FACOlibvta l, vta_FACOzzz z, vta_FACOtermstaty y
 where l.vta_techkey = z.rec_techkey
   and y.ter_fecha = l.vta_fecha_venta and y.ter_local = l.vta_local
   and y.ter_terminal = l.vta_terminal and y.ter_cierrey = l.vta_secuencia
   and l.vta_fecha_venta = to_date('20261112','yyyymmdd')
   and l.vta_local = 5 and l.vta_terminal in (5, 6)
   and l.vta_tiporeg = 'Y'
 order by l.vta_terminal;

-- C3. Que no quedaron filas de v1. ESPERADO: 2 por terminal en libvta
--     (F8/99 + Y/1) y 2 en zzz; si hay 4, Cargar v2 no reemplazo.
select l.vta_terminal, count(*) filas_libvta, count(z.rec_techkey) filas_zzz
  from vta_FACOlibvta l, vta_FACOzzz z
 where l.vta_techkey = z.rec_techkey (+)
   and l.vta_fecha_venta = to_date('20261112','yyyymmdd')
   and l.vta_local = 5 and l.vta_terminal in (5, 6)
   and l.vta_tiporeg in ('F8', 'Y')
 group by l.vta_terminal
 order by l.vta_terminal;
