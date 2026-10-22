-- =====================================================================
-- FSCC-12901 - Prueba manual "camino feliz" del cierre Y (FACO)
-- P2: resultados despues de Form19Y + Form133 (+ Cerrar Terminal).
-- SOLO LECTURA. Valores: 20260828, local 6, terminal 27, Y 1 (EDITAR).
-- Replica la Diferencia Real de la F8 de la Y (CierreCaja_FACO_Reglas.md
-- 2.1). El compensado se aproxima con el total de movdet de la Y: en el
-- camino feliz debe ser 0; si no, usar la consulta completa del 2.3.
-- =====================================================================

-- 1. Lo grabado por Form19Y. ESPERADO: una fila libvta Y secuencia 1
--    (estado A) con su zzz y rec_mefectivo = 7583000.
select l.vta_secuencia y, l.vta_estado, l.vta_techkey,
       r.rec_mefectivo, r.rec_mchkdia, r.rec_mchkfecha, r.rec_mtarj, r.rec_msodimac
  from vta_FACOlibvta l, vta_FACOzzz r
 where l.vta_tiporeg = 'Y' and l.vta_fecha_venta = to_date('20260828','yyyymmdd')
   and l.vta_local = 6 and l.vta_terminal = 27 and l.vta_techkey = r.rec_techkey;

-- ESPERADO: Y 1 con estado -1 antes de cerrar y 1 despues de Cerrar Terminal.
select ter_cierrey, ter_estado, ter_notas, ter_cerradopor
  from vta_FACOtermstaty
 where ter_fecha = to_date('20260828','yyyymmdd') and ter_local = 6 and ter_terminal = 27;

-- 2. Lo grabado por Form133. ESPERADO: 3 filas F8/EFE, Y 1, total 7.583.000.
select prv_sobre, prv_montosobre, prv_montodif, prv_cierrey, prv_tiporec,
       prv_tiposobre, prv_cod_recaud, prv_fechadep
  from vta_FACOprd
 where prv_fechavta = to_date('20260828','yyyymmdd') and prv_local = 6 and prv_terminal = 27
 order by prv_sobre;

-- Z reabierta por Form133.AbrirTerminal (estado 0, 'CARGA MANUAL DE SOBRES').
select ter_estado, ter_notas
  from vta_FACOtermstat
 where ter_fecha = to_date('20260828','yyyymmdd') and ter_local = 6 and ter_terminal = 27;

-- 3. Diferencia Real de la Y por componente. ESPERADO: todo 0 salvo
--    prsefe = totefe = 7583000.
with p as (select to_date('20260828','yyyymmdd') f, 6 l, 27 t, 1 y from dual),
y as (select nvl(sum(r.rec_mefectivo),0) totefe, nvl(sum(r.rec_mchkdia),0) totchd,
             nvl(sum(r.rec_mchkfecha),0) totchf,
             nvl(sum(r.rec_mtarj),0) + nvl(sum(r.rec_msodimac),0) tottarj
        from vta_FACOlibvta l, vta_FACOzzz r, p
       where l.vta_tiporeg = 'Y' and l.vta_fecha_venta = p.f and l.vta_local = p.l
         and l.vta_terminal = p.t and l.vta_estado = 'A' and l.vta_techkey = r.rec_techkey
         and l.vta_secuencia = p.y),
s as (select nvl(sum(case when x.prv_tiposobre = 'EFE' then nvl(x.prv_montosobre,0) + nvl(x.prv_montodif,0) end),0) prsefe,
             nvl(sum(case when x.prv_tiposobre = 'CHE' then nvl(x.prv_montosobre,0) + nvl(x.prv_montodif,0) end),0) prschd
        from vta_FACOprd x, p
       where x.prv_fechavta = p.f and x.prv_local = p.l and x.prv_terminal = p.t
         and x.prv_tiporec = 'F8' and x.prv_cierrey = p.y),
te as (select nvl(max(t.tes_chefecha),0) teschf
         from vta_FACOtesor t, p
        where t.tes_fecha = p.f and t.tes_local = p.l and t.tes_terminal = p.t and t.tes_cierrey = p.y),
tj as (select nvl(sum(t.vta_monto_inf),0) testarj
         from vta_FACOtarj t, p
        where t.vta_fecha = p.f and t.vta_local = p.l and t.vta_terminal = p.t
          and t.vta_cierrey = p.y and t.vta_cod_tarj between 2000 and 2999),
d as (select nvl(sum(x.mex_monto),0) totdol
        from vta_FACOrecmex x, p
       where x.mex_fecha = p.f and x.mex_local = p.l and x.mex_terminal = p.t
         and x.id_mdareg = 305 and x.mex_cierrey = p.y),
c as (select nvl(sum(m.mov_monto),0) compensado
        from vta_FACOmovdet m, p
       where m.mov_fecha = p.f and m.mov_local = p.l and m.mov_terminal = p.t and m.mov_cierrey = p.y)
select s.prsefe, y.totefe,
       s.prsefe - y.totefe          dif_efectivo,
       s.prschd - y.totchd          dif_cheque_dia,
       d.totdol                     dif_usd,
       te.teschf - y.totchf         dif_cheque_fecha,
       tj.testarj - y.tottarj       dif_tarjetas,
       (s.prsefe - y.totefe) + (s.prschd - y.totchd) + d.totdol
         + (te.teschf - y.totchf) + (tj.testarj - y.tottarj) dif_caja,
       c.compensado,
       (s.prsefe - y.totefe) + (s.prschd - y.totchd) + d.totdol
         + (te.teschf - y.totchf) + (tj.testarj - y.tottarj) - c.compensado diferencia_real
  from y, s, te, tj, d, c;
