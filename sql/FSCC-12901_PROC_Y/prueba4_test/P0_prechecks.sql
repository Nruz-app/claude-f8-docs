-- =====================================================================
-- FSCC-12901 Prueba 4 en test (demostracion) - P0: verificaciones previas
-- SOLO LECTURA (no modifica nada). xintec-nruz 19-10-2026
--
-- Repite la prueba 3 (prueba3_test/, OK el 16-10-2026) con terminales y
-- fecha nuevas, para mostrar el cierre automatico al usuario:
--   local 6, fecha de venta 29-08-2026, Y 1
--   T25 cuadre exacto   sobres 2508290001, 2508290002 (2.342.000)
--   T42 DI +500         sobres 4208290001, 4208290002 (5.856.000)
--   T32 faltante -1.500 sobres 3208290001, 3208290002 (2.670.000)
--   T45 sobrante +25000 sobres 4508290001, 4508290002 (875.000)
-- Se usa el 29-08 (no el 28-08) porque las Y de T31 y T44 de la prueba 3
-- siguen abiertas el 28-08 y CA_SIN_SOBRE = S las volveria a evaluar (H1).
--
-- Ejecutar conectado al usuario de test. Si las tablas no se ven sin
-- esquema:  alter session set current_schema = INTRANETTS;
-- Cada consulta indica su resultado ESPERADO. Si una terminal no esta
-- libre, elegir otra con la consulta 8 y regenerar su Excel.
-- =====================================================================

-- 1. Parametros 1502. ESPERADO: CA_ACTIVO y CA_DI_ACTIVO en S, CA_SIN_SOBRE en S.
select vta_ccodigo, '[' || vta_xglosa || ']' glosa, vta_dfechareg
  from VTA_FACOPARAM
 where vta_ccodtipo = 1502
 order by vta_ccodigo;

-- 2. Cola pendiente. ESPERADO: sin filas en P ni E.
--    El paquete toma TODAS las filas P de la cola, no solo la ultima carga
--    (en la prueba 3 cerro tambien la T29 que habia quedado en P).
select pcr_estado, prv_fechavta, prv_local, prv_terminal, count(*) sobres
  from VTA_FACOPRD_CIERRE
 where pcr_estado in ('P', 'E')
 group by pcr_estado, prv_fechavta, prv_local, prv_terminal
 order by 1, 2, 3, 4;

-- 3. Y ya existentes del dia en las 4 cajas. ESPERADO: sin filas.
--    Si hay una Y, Form19Y asigna max+1 (no 1) y no cuadra con el Excel.
select 'TERMSTATY' origen, y.ter_terminal terminal, y.ter_cierrey y,
       to_char(y.ter_estado) estado, y.ter_notas detalle
  from vta_FACOtermstaty y
 where y.ter_fecha = to_date('20260829','yyyymmdd') and y.ter_local = 6
   and y.ter_terminal in (25, 42, 32, 45)
union all
select 'LIBVTA_Y', l.vta_terminal, l.vta_secuencia, l.vta_estado, 'techkey ' || l.vta_techkey
  from vta_FACOlibvta l
 where l.vta_tiporeg = 'Y' and l.vta_fecha_venta = to_date('20260829','yyyymmdd')
   and l.vta_local = 6 and l.vta_terminal in (25, 42, 32, 45)
order by 1, 2, 3;

-- 4. Estado de la Z. ESPERADO: sin filas, o ter_estado distinto de 1 y 2
--    (con la Z cerrada Form19Y no deja ingresar la Y).
select ter_local, ter_terminal, ter_fecha, ter_estado, ter_notas
  from vta_FACOtermstat
 where ter_fecha = to_date('20260829','yyyymmdd') and ter_local = 6
   and ter_terminal in (25, 42, 32, 45);

-- 5. Sobres del Excel ya cargados. Form133 compara numero + fecha de venta
--    (sin local) y salta los que existen. ESPERADO: sin filas.
select prv_techkey, prv_local, prv_terminal, prv_sobre, prv_montosobre, prv_tiporec
  from vta_FACOprd
 where prv_fechavta = to_date('20260829','yyyymmdd')
   and prv_sobre in (2508290001, 2508290002, 4208290001, 4208290002,
                     3208290001, 3208290002, 4508290001, 4508290002);

-- 5b. Otros sobres F8 de las cajas ese dia (se sumarian a la DR). ESPERADO: sin filas.
select prv_terminal, count(*) otros_sobres, sum(prv_montosobre + nvl(prv_montodif,0)) monto
  from vta_FACOprd
 where prv_fechavta = to_date('20260829','yyyymmdd')
   and prv_local = 6 and prv_terminal in (25, 42, 32, 45) and prv_tiporec = 'F8'
 group by prv_terminal;

-- 6. Terminal vigente y tipo. ESPERADO: 4 filas, ter_tipo 0.
--    ter_tipo 2 = Autopago (PKG_F8_FACO_CIERRE_TER_PM_AP podria cerrarla, H5);
--    1 = POS Mobile. Oklt de Form19Y usa la fecha de la F8 abierta.
select ter_terminal, nvl(ter_tipo, 0) ter_tipo, ter_fechabaja
  from vta_FACOterminales
 where ter_local = 6 and ter_terminal in (25, 42, 32, 45)
   and (ter_fechabaja >= to_date('20260829','yyyymmdd') or ter_fechabaja is null)
 order by ter_terminal;

-- 7. Ruido de las cajas que impediria DR = 0 o el cierre. ESPERADO: sin filas.
select 'TARJETAS 2000-2999' fuente, vta_terminal terminal, count(*) filas, sum(vta_monto_inf) monto
  from vta_FACOtarj
 where vta_fecha = to_date('20260829','yyyymmdd') and vta_local = 6
   and vta_terminal in (25, 42, 32, 45) and vta_cod_tarj between 2000 and 2999
 group by vta_terminal
union all
select 'TESORERIA cheque a fecha', tes_terminal, count(*), sum(tes_chefecha)
  from vta_FACOtesor
 where tes_fecha = to_date('20260829','yyyymmdd') and tes_local = 6
   and tes_terminal in (25, 42, 32, 45)
 group by tes_terminal
union all
select 'GESTION CHEQUES tipo 1', chq_terminal, count(*), sum(chq_monto)
  from vta_FACOcheques
 where chq_fecha = to_date('20260829','yyyymmdd') and chq_local = 6
   and chq_terminal in (25, 42, 32, 45) and chq_tipocheque = 1
 group by chq_terminal
union all
select 'USD recmex 305', mex_terminal, count(*), sum(mex_monto)
  from vta_FACOrecmex
 where mex_fecha = to_date('20260829','yyyymmdd') and mex_local = 6
   and mex_terminal in (25, 42, 32, 45) and id_mdareg = 305
 group by mex_terminal
union all
select 'MOVDET', mov_terminal, count(*), sum(mov_monto)
  from vta_FACOmovdet
 where mov_fecha = to_date('20260829','yyyymmdd') and mov_local = 6
   and mov_terminal in (25, 42, 32, 45)
 group by mov_terminal
union all
select 'CARTAAVISO', mov_terminal, count(*), sum(mov_monto)
  from vta_FACOcartaaviso
 where mov_fecha = to_date('20260829','yyyymmdd') and mov_local = 6
   and mov_terminal in (25, 42, 32, 45)
 group by mov_terminal;

-- 8. H1: otras Y abiertas del local 6 el 29-08-2026 (CA_SIN_SOBRE = S las
--    incluiria en la ejecucion). ESPERADO: sin filas antes de digitar las Y.
select y.ter_terminal, y.ter_cierrey, y.ter_estado, y.ter_cerradopor
  from vta_FACOtermstaty y
 where y.ter_fecha = to_date('20260829','yyyymmdd') and y.ter_local = 6
   and y.ter_estado <= 0
 order by 1, 2;

-- 9. Terminales libres del local 6 el 29-08-2026 (por si hay que cambiar
--    alguna): vigentes, tipo 0, sin Y, sin Z cerrada (1/2) y sin sobres
--    ese dia. En FACO la Z puede estar precreada en -1: eso no molesta.
select t.ter_terminal
  from vta_FACOterminales t
 where t.ter_local = 6
   and nvl(t.ter_tipo, 0) = 0
   and (t.ter_fechabaja >= to_date('20260829','yyyymmdd') or t.ter_fechabaja is null)
   and not exists (select 1 from vta_FACOtermstaty y
                    where y.ter_fecha = to_date('20260829','yyyymmdd')
                      and y.ter_local = t.ter_local and y.ter_terminal = t.ter_terminal)
   and not exists (select 1 from vta_FACOtermstat z
                    where z.ter_fecha = to_date('20260829','yyyymmdd')
                      and z.ter_local = t.ter_local and z.ter_terminal = t.ter_terminal
                      and z.ter_estado in (1, 2))
   and not exists (select 1 from vta_FACOprd p
                    where p.prv_fechavta = to_date('20260829','yyyymmdd')
                      and p.prv_local = t.ter_local and p.prv_terminal = t.ter_terminal)
 order by t.ter_terminal;
