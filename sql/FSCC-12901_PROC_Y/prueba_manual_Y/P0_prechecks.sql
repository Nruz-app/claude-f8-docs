-- =====================================================================
-- FSCC-12901 - Prueba manual "camino feliz" del cierre Y (FACO)
-- P0: verificaciones previas. SOLO LECTURA (no modifica nada).
-- Ejecutar conectado al usuario de la base de test. Si las tablas no se
-- ven sin esquema:  alter session set current_schema = INTRANETTS;
--
-- Valores de la prueba (EDITAR si cambia el Excel PRD-LIST-TEST-V2.xlsx):
--   fecha venta 20260828, local 6, terminal 27, Y 1
--   sobres 3404295622, 3476295623, 3482295624 (total 7.583.000)
-- Cada consulta indica su resultado ESPERADO.
-- =====================================================================

-- 1. Y ya existentes del dia en la caja.
--    ESPERADO: sin filas. Si hay una Y, Form19Y asigna max+1 (no 1) y no
--    cuadra con la columna H del Excel -> ejecutar P9 o cambiar de caja.
with p as (select to_date('20260828','yyyymmdd') f, 6 l, 27 t from dual)
select 'TERMSTATY' origen, y.ter_cierrey y, to_char(y.ter_estado) estado, y.ter_notas detalle
  from vta_FACOtermstaty y, p
 where y.ter_fecha = p.f and y.ter_local = p.l and y.ter_terminal = p.t
union all
select 'LIBVTA_Y', l.vta_secuencia, l.vta_estado, 'techkey ' || l.vta_techkey
  from vta_FACOlibvta l, p
 where l.vta_tiporeg = 'Y' and l.vta_fecha_venta = p.f
   and l.vta_local = p.l and l.vta_terminal = p.t
order by 1, 2;

-- 2. Estado de la Z (vta_FACOtermstat).
--    ESPERADO: sin fila, o ter_estado distinto de 1 y 2 (cerrada: Form19Y
--    no deja ingresar la Y).
select ter_local, ter_terminal, ter_fecha, ter_estado, ter_notas
  from vta_FACOtermstat
 where ter_fecha = to_date('20260828','yyyymmdd') and ter_local = 6 and ter_terminal = 27;

-- 3. Sobres del Excel ya cargados. Form133 compara numero + fecha de venta
--    (sin local) y salta los que existen ("Ya existen los registros").
--    ESPERADO: sin filas.
select prv_techkey, prv_local, prv_terminal, prv_sobre, prv_montosobre,
       prv_montodif, prv_cierrey, prv_tiporec, prv_tiposobre
  from vta_FACOprd
 where prv_fechavta = to_date('20260828','yyyymmdd')
   and prv_sobre in (3404295622, 3476295623, 3482295624);

-- 3b. Otros sobres F8 de la caja/dia (se sumarian a la diferencia).
--     ESPERADO: 0.
select count(*) otros_sobres, nvl(sum(prv_montosobre + nvl(prv_montodif,0)),0) monto
  from vta_FACOprd
 where prv_fechavta = to_date('20260828','yyyymmdd')
   and prv_local = 6 and prv_terminal = 27 and prv_tiporec = 'F8';

-- 4. Relacion local/terminal (Form19Y.Oklt). ESPERADO: >= 1.
--    OJO: Oklt usa la FECHA DE LA PANTALLA F8 abierta (FormVariable), no la
--    de Form19Y: abrir antes la F8 con fecha 28-08-2026.
select count(*) terminal_vigente
  from vta_FACOterminales
 where ter_local = 6 and ter_terminal = 27
   and (ter_fechabaja >= to_date('20260828','yyyymmdd') or ter_fechabaja is null);

-- 5. Recaudadores para el combo de Form133. ESPERADO: al menos uno.
select vta_cod_recaud, vta_nombre from vta_FACOrecaudadora order by 1;

-- 6. "Ruido" de la caja/dia que impediria Diferencia Real = 0 o el cierre.
--    ESPERADO: todo 0.
select 'TARJETAS vta_FACOtarj 2000-2999' fuente, count(*) filas, nvl(sum(vta_monto_inf),0) monto
  from vta_FACOtarj
 where vta_fecha = to_date('20260828','yyyymmdd') and vta_local = 6 and vta_terminal = 27
   and vta_cod_tarj between 2000 and 2999
union all
select 'TESORERIA cheque a fecha', count(*), nvl(sum(tes_chefecha),0)
  from vta_FACOtesor
 where tes_fecha = to_date('20260828','yyyymmdd') and tes_local = 6 and tes_terminal = 27
union all
select 'GESTION CHEQUES tipo 1 (RY-01)', count(*), nvl(sum(chq_monto),0)
  from vta_FACOcheques
 where chq_fecha = to_date('20260828','yyyymmdd') and chq_local = 6 and chq_terminal = 27
   and chq_tipocheque = 1
union all
select 'USD vta_FACOrecmex 305', count(*), nvl(sum(mex_monto),0)
  from vta_FACOrecmex
 where mex_fecha = to_date('20260828','yyyymmdd') and mex_local = 6 and mex_terminal = 27
   and id_mdareg = 305
union all
select 'MOVDET (compensaciones / RY-03)', count(*), nvl(sum(mov_monto),0)
  from vta_FACOmovdet
 where mov_fecha = to_date('20260828','yyyymmdd') and mov_local = 6 and mov_terminal = 27
union all
select 'CARTAAVISO', count(*), nvl(sum(mov_monto),0)
  from vta_FACOcartaaviso
 where mov_fecha = to_date('20260828','yyyymmdd') and mov_local = 6 and mov_terminal = 27;

-- 7. Grilla "Detalle de Montos" de Form19Y para FACO (vta_paint_z).
--    Sirve para ubicar la fila de EFECTIVO (campo rec_mefectivo), la de
--    venta total y la de total formas de pago. pop_up 1/2 = fila calculada.
select z.vta_order_z, z.vtaglosa_z, z.vta_cmp_asoc, nvl(z.vta_pop_up,0) pop_up
  from vta_paint_z z
 where z.vta_localiz = 'FACO'
 order by z.vta_order_z;
