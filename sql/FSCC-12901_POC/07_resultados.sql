-- =====================================================================
-- POC FSCC-12901 - 07 Resultados (DESARROLLO, no graba)
-- Revisar ANTES de 98_reiniciar.sql o 99_limpiar.sql (borran la evidencia).
-- Esperado = el del escenario; si el escenario no lo fija (R0, S0), la
-- prevision de 05_simular.sql.
-- =====================================================================

-- ---------------------------------------------------------------
-- 1. Resumen del log por proceso y resultado
-- ---------------------------------------------------------------
select l.log_proceso, l.log_resultado, l.log_regla, count(*) filas
  from VTA_FACOLOG_CIERRE_AUTO l
 where l.log_ejecucion = (select to_number(valor) from VTA_FACOPOC_CTRL where clave = 'EJECUCION_AUTO')
 group by l.log_proceso, l.log_resultado, l.log_regla
 order by 1, 2, 3;

-- ---------------------------------------------------------------
-- 2. Esperado vs obtenido por origen y escenario (objetivo: diferentes = 0)
-- ---------------------------------------------------------------
select r.c_origen, r.escenario, count(*) cajas,
       sum(case when r.obtenido_t1 = r.esperado1 and r.obtenido_t2 = r.esperado2 then 1 else 0 end) ok,
       sum(case when r.obtenido_t1 = r.esperado1 and r.obtenido_t2 = r.esperado2 then 0 else 1 end) diferentes,
       max(r.esperado1) esperado_t1, max(r.esperado2) esperado_t2
  from (select c.*, nvl(c.esperado_t1, c.prev_t1) esperado1, nvl(c.esperado_t2, c.prev_t2) esperado2,
               (select max(l.log_resultado) from VTA_FACOLOG_CIERRE_AUTO l
                 where l.log_ejecucion = (select to_number(valor) from VTA_FACOPOC_CTRL where clave = 'EJECUCION_AUTO')
                   and l.log_proceso = 'T1' and l.log_nivel = 'Y'
                   and l.log_fecha_vta = c.c_fecha and l.log_local = c.c_local
                   and l.log_terminal = c.c_terminal and l.log_cierrey = c.c_cierrey) obtenido_t1,
               (select max(l.log_resultado) from VTA_FACOLOG_CIERRE_AUTO l
                 where l.log_ejecucion = (select to_number(valor) from VTA_FACOPOC_CTRL where clave = 'EJECUCION_AUTO')
                   and l.log_proceso = 'T2' and l.log_nivel = 'Y'
                   and l.log_fecha_vta = c.c_fecha and l.log_local = c.c_local
                   and l.log_terminal = c.c_terminal and l.log_cierrey = c.c_cierrey) obtenido_t2
          from VTA_FACOPOC_CASOS c) r
 group by r.c_origen, r.escenario
 order by 1, 2;

-- ---------------------------------------------------------------
-- 3. Detalle de las cajas con diferencia (esperado: 0 filas)
-- ---------------------------------------------------------------
select r.c_origen, r.escenario, r.c_fecha, r.c_local, r.c_terminal, r.c_cierrey, r.dr_objetivo,
       r.esperado1, r.obtenido_t1, r.esperado2, r.obtenido_t2, r.regla, r.mensaje
  from (select c.*, nvl(c.esperado_t1, c.prev_t1) esperado1, nvl(c.esperado_t2, c.prev_t2) esperado2,
               t1.log_resultado obtenido_t1, t2.log_resultado obtenido_t2, t2.log_regla regla,
               nvl(t2.log_mensaje, t1.log_mensaje) mensaje
          from VTA_FACOPOC_CASOS c,
               (select * from VTA_FACOLOG_CIERRE_AUTO
                 where log_ejecucion = (select to_number(valor) from VTA_FACOPOC_CTRL where clave = 'EJECUCION_AUTO')
                   and log_proceso = 'T1' and log_nivel = 'Y') t1,
               (select * from VTA_FACOLOG_CIERRE_AUTO
                 where log_ejecucion = (select to_number(valor) from VTA_FACOPOC_CTRL where clave = 'EJECUCION_AUTO')
                   and log_proceso = 'T2' and log_nivel = 'Y') t2
         where t1.log_fecha_vta (+) = c.c_fecha and t1.log_local (+) = c.c_local
           and t1.log_terminal (+) = c.c_terminal and t1.log_cierrey (+) = c.c_cierrey
           and t2.log_fecha_vta (+) = c.c_fecha and t2.log_local (+) = c.c_local
           and t2.log_terminal (+) = c.c_terminal and t2.log_cierrey (+) = c.c_cierrey) r
 where nvl(r.obtenido_t1, '-') <> nvl(r.esperado1, '-') or nvl(r.obtenido_t2, '-') <> nvl(r.esperado2, '-')
 order by 1, 2, 3, 4, 5, 6;

-- ---------------------------------------------------------------
-- 4. DI registradas por T1 (CA1: monto = DR con el mismo signo; CA7: fecha
--    contable = fecha de venta; CA5: usuario de proceso + glosa)
-- ---------------------------------------------------------------
select c.c_origen, c.escenario, count(*) di,
       sum(case when m.mov_monto = c.dr_objetivo then 1 else 0 end) monto_igual_dr,
       sum(case when m.mov_fechareg = m.mov_fecha then 1 else 0 end) fecha_contable_ok,
       sum(case when o.cpd_obs = 'COMPENSACION AUTOMATICA DI' then 1 else 0 end) glosa_ok,
       min(m.mov_monto) monto_min, max(m.mov_monto) monto_max
  from VTA_FACOMOVDET m, VTA_FACOPOC_CASOS c, VTA_FACOCOMPDES o
 where m.mov_tipomov = 'DI' and m.mov_hechopor = 'PROC_DI_AUTO'
   and m.mov_fecha = c.c_fecha and m.mov_local = c.c_local
   and m.mov_terminal = c.c_terminal and m.mov_cierrey = c.c_cierrey
   and o.cpd_fecha (+) = m.mov_fecha and o.cpd_local (+) = m.mov_local
   and o.cpd_terminal (+) = m.mov_terminal and o.cpd_cierrey (+) = m.mov_cierrey
   and o.cpd_tipmov (+) = 'DI'
 group by c.c_origen, c.escenario
 order by 1, 2;

-- Ejemplos de DI (primeras 10)
select * from (
  select m.mov_fecha, m.mov_fechareg, m.mov_local, m.mov_terminal, m.mov_cierrey, m.mov_monto, m.mov_hechopor, m.mov_regul
    from VTA_FACOMOVDET m, VTA_FACOPOC_DIAS d
   where m.mov_tipomov = 'DI' and m.mov_hechopor = 'PROC_DI_AUTO'
     and m.mov_fecha = d.d_fecha and m.mov_local = d.d_local
   order by 1, 3, 4, 5)
 where rownum <= 10;

-- ---------------------------------------------------------------
-- 5. Cierres Y: estado final por origen y quien cerro
-- ---------------------------------------------------------------
select d.d_origen, y.ter_estado, nvl(y.ter_cerradopor, '(abierta)') cerrado_por, count(*) cajas
  from VTA_FACOTERMSTATY y, VTA_FACOPOC_DIAS d
 where y.ter_fecha = d.d_fecha and y.ter_local = d.d_local
 group by d.d_origen, y.ter_estado, nvl(y.ter_cerradopor, '(abierta)')
 order by 1, 2, 3;

-- ---------------------------------------------------------------
-- 6. Cola: estado final de los sobres del POC
-- ---------------------------------------------------------------
select q.pcr_estado, q.pcr_resultado, count(*) sobres
  from VTA_FACOPRD_CIERRE q
 where q.prv_techkey in (select prv_techkey from VTA_FACOPRD where prv_modifpor = 'POC_FSCC12901')
 group by q.pcr_estado, q.pcr_resultado
 order by 1, 2;

-- ---------------------------------------------------------------
-- 7. La Z no se toca (FACO solo cierre Y). Esperado: 0
-- ---------------------------------------------------------------
select count(*) z_cerradas_por_el_proceso
  from VTA_FACOTERMSTAT
 where ter_cerradopor = 'PROC_CIERRE_AUTO';

-- ---------------------------------------------------------------
-- 8. Rendimiento
-- ---------------------------------------------------------------
select (select valor from VTA_FACOPOC_CTRL where clave = 'DURACION_SEG') duracion_seg,
       count(distinct l.log_fecha_vta || '-' || l.log_local || '-' || l.log_terminal || '-' || l.log_cierrey) cajas_evaluadas,
       round(to_number((select valor from VTA_FACOPOC_CTRL where clave = 'DURACION_SEG'))
             / nullif(count(distinct l.log_fecha_vta || '-' || l.log_local || '-' || l.log_terminal || '-' || l.log_cierrey), 0), 3) seg_por_caja
  from VTA_FACOLOG_CIERRE_AUTO l
 where l.log_ejecucion = (select to_number(valor) from VTA_FACOPOC_CTRL where clave = 'EJECUCION_AUTO')
   and l.log_nivel = 'Y';
