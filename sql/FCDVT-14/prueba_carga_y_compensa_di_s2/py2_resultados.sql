-- =====================================================================
-- FCDVT-14 + FSCC-12901 - Sesion "crear Y con la carga masiva y
-- compensarla con DI" - py2: resultados. SOLO LECTURA.
-- xintec-nruz 06-11-2026
--
-- Fecha de venta 28-10-2026, local 5, terminales 1 a 4, Y 1. Ejecutar
-- despues del paso 2 (Form174 Buscar + Cargar) y de cada carga de
-- sobres (Form133). Parte A: la carga masiva. Parte B: la DI.
-- Si las tablas no se ven sin esquema:
--   alter session set current_schema = INTRANETTS;
-- =====================================================================

-- ============ PARTE A: CARGA MASIVA (Form174, FCDVT-14) ============

-- A1. Resumen de las cargas del dia. ESPERADO: 4 filas GRABADO, una por
--     terminal: res_cant_y 1, res_cant_z 1, sin res_lin_error, con
--     res_mensaje 'Grabado: Z + 1 Y (numeros 1 a 1)' y los totales
--       T1 2.670.800   T2 860.000   T3 2.675.000   T4 2.342.000
select res_carga, to_char(res_fecha, 'dd-mm-yyyy') fecha, res_local, res_terminal,
       res_cant_y, res_total_y, res_cant_z, res_total_z, res_lin_error,
       res_estado, res_mensaje, res_usuario
  from VTA_FACOCARGA_YZ_RES
 where res_fecha = to_date('20261028','yyyymmdd')
   and res_local = 5
 order by res_carga, res_terminal;

-- A2. Log de las cargas del dia. ESPERADO: fila GRABADO por grupo (4 en
--     total) y ninguna de ERROR; si un grupo quedo ERROR, el motivo esta
--     en log_motivo (linea log_linea).
select log_carga, log_id, log_linea, log_etapa, log_campo, log_valor,
       log_motivo, log_usuario, log_fechahora
  from VTA_FACOCARGA_YZ_LOG
 where log_carga in (select res_carga from VTA_FACOCARGA_YZ_RES
                      where res_fecha = to_date('20261028','yyyymmdd') and res_local = 5)
 order by log_carga, log_id;

-- A3. Lo grabado en el libro de ventas del dia. ESPERADO: por caja 2
--     filas: F8/99 (la Z) y Y/1, con vta_totalvta = total del grupo
--       T1 2.670.800   T2 860.000   T3 2.675.000   T4 2.342.000
select l.vta_local, l.vta_terminal, l.vta_tiporeg, l.vta_secuencia,
       l.vta_estado, l.vta_totalvta
  from vta_FACOlibvta l
 where l.vta_fecha_venta = to_date('20261028','yyyymmdd')
   and l.vta_local = 5 and l.vta_terminal in (1, 2, 3, 4)
   and l.vta_tiporeg in ('F8', 'Y')
 order by l.vta_terminal, l.vta_tiporeg, l.vta_secuencia;

-- A4. EFECTIVO grabado en la zzz de cada fila. ESPERADO: el de la tabla
--     de LEEME: T1 2.670.800, T2 860.000, T3 2.675.000, T4 2.342.000,
--     en la fila de la Z (F8/99) y en la de la Y (que son iguales:
--     BOLETAS = EFECTIVO y hay una sola Y).
select l.vta_local, l.vta_terminal, l.vta_tiporeg, l.vta_secuencia,
       z.rec_mefectivo
  from vta_FACOlibvta l, vta_FACOzzz z
 where l.vta_techkey = z.rec_techkey
   and l.vta_fecha_venta = to_date('20261028','yyyymmdd')
   and l.vta_local = 5 and l.vta_terminal in (1, 2, 3, 4)
   and l.vta_tiporeg in ('F8', 'Y')
 order by l.vta_terminal, l.vta_tiporeg, l.vta_secuencia;

-- A5. Identificacion de la Y (cada campo en su columna, FORMATO 3.1).
--     ESPERADO: T1 hora 1745 y T2 1420, T3 1610 y T4 1805; secuencias
--     2101, 2103, 2105 y 2107; boletas 6101000..4000; vendedor 71001 a
--     71004; crepo 4101, 4201, 4301 y 4401.
select l.vta_local, l.vta_terminal, l.vta_secuencia, l.vta_hora,
       l.vta_bolfinal, l.vta_vendedor, l.vta_crepo_inicial
  from vta_FACOlibvta l
 where l.vta_fecha_venta = to_date('20261028','yyyymmdd')
   and l.vta_local = 5 and l.vta_terminal in (1, 2, 3, 4)
   and l.vta_tiporeg = 'Y'
 order by l.vta_terminal;

-- A6. Estados. ESPERADO: termstaty, 4 filas en -1 con la glosa
--     'CARGA MASIVA DE CIERRE Y - CARGA <num>' (la caja de la prueba);
--     termstat, la de la Z en -1: con la glosa 'CARGA MASIVA DE CIERRE
--     Z - CARGA <num>' si la creo la carga, o precreada sin glosa (se
--     conserva).
select 'Y' nivel, t.ter_terminal, t.ter_cierrey, to_char(t.ter_estado) estado,
       t.ter_notas, t.ter_cerradopor
  from vta_FACOtermstaty t
 where t.ter_fecha = to_date('20261028','yyyymmdd')
   and t.ter_local = 5 and t.ter_terminal in (1, 2, 3, 4)
 union all
 select 'Z', s.ter_terminal, null, to_char(s.ter_estado), s.ter_notas, s.ter_cerradopor
  from vta_FACOtermstat s
 where s.ter_fecha = to_date('20261028','yyyymmdd')
   and s.ter_local = 5 and s.ter_terminal in (1, 2, 3, 4)
 order by 1, 2, 3;

-- ============ PARTE B: DI (Form133, FSCC-12901) ============

-- B1. Log del dia (una fila por caja evaluada). ESPERADO:
--       T1 DI_REGISTRADA  dif_real -800   monto_di -800   (prueba 1)
--       T2 DI_REGISTRADA  dif_real 15000  monto_di 15000  (prueba 2)
--       T3 FUERA_RANGO    dif_real -5000  sin DI          (prueba 3)
--       T4 DR_CERO        dif_real 0      sin DI          (prueba 4)
--     Nota: log_dif_real y log_sobres corresponden al momento de la
--     carga; el DR actual es la consulta B2.
select log_id, log_local, log_terminal, log_cierrey, log_sobres, log_dif_real,
       log_di_anterior, log_monto_di, log_resultado, log_mensaje, log_usuario,
       log_fechahora
  from VTA_FACOLOG_COMPENSA_DI
 where log_fecha_vta = to_date('20261028','yyyymmdd')
   and log_local = 5
 order by log_id;

-- B2. Estado de las Y y DR actual. ESPERADO: las 4 abiertas (ter_estado
--     <= 0, sin PROC_CIERRE_AUTO). DR actual 0 en T1, T2 y T4 (la DI la
--     compenso), -5000 en T3 (sin DI: queda la diferencia).
--     Despues del cierre con CC: ter_estado = 1 en T1, T2 y T4.
select t.ter_local, t.ter_terminal, t.ter_cierrey, t.ter_estado, t.ter_cerradopor,
       PKG_F8_COMPENSA_DI_CARGA.fn_dif_real('FACO', t.ter_fecha, t.ter_local,
                                            t.ter_terminal, t.ter_cierrey) dr_actual
  from VTA_FACOTERMSTATY t
 where t.ter_fecha = to_date('20261028','yyyymmdd')
   and t.ter_local = 5 and t.ter_terminal in (1, 2, 3, 4)
 order by t.ter_terminal, t.ter_cierrey;

-- B3. DI registradas. ESPERADO: 2 filas (T1 -800; T2 15000), con
--     mov_hechopor PROC_DI_AUTO, mov_regul S y mov_fechareg = 28-10-2026.
select m.mov_local, m.mov_terminal, m.mov_cierrey, m.mov_tipomov, m.mov_monto,
       m.mov_hechopor, m.mov_regul, m.mov_fechareg, m.mov_techkey
  from VTA_FACOMOVDET m
 where m.mov_fecha = to_date('20261028','yyyymmdd')
   and m.mov_local = 5 and m.mov_terminal in (1, 2, 3, 4)
   and m.mov_tipomov = 'DI'
 order by m.mov_terminal;

-- B4. Observacion de la DI (lo que muestra Form4). ESPERADO: 2 filas
--     (T1 y T2) con COMPENSACION AUTOMATICA DI.
select c.cpd_local, c.cpd_terminal, c.cpd_tipmov, c.cpd_obs
  from VTA_FACOCOMPDES c
 where c.cpd_fecha = to_date('20261028','yyyymmdd')
   and c.cpd_local = 5 and c.cpd_terminal in (1, 2, 3, 4)
   and c.cpd_tipmov = 'DI'
 order by c.cpd_terminal;

-- B5. Sobres cargados por caja. ESPERADO: 2 por caja (T1 2.670.000,
--     T2 875.000, T3 2.670.000, T4 2.342.000) con prv_cierrey = 1.
select prv_local, prv_terminal, prv_cierrey, count(*) sobres,
       sum(prv_montosobre + nvl(prv_montodif, 0)) total
  from vta_FACOprd
 where prv_fechavta = to_date('20261028','yyyymmdd')
   and prv_local = 5 and prv_terminal in (1, 2, 3, 4)
   and prv_tiporec = 'F8'
 group by prv_local, prv_terminal, prv_cierrey
 order by prv_terminal;
