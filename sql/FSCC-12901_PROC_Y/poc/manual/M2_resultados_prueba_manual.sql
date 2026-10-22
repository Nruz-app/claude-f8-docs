-- =====================================================================
-- POC FSCC-12901 v2 (multipais, FACO) - Manual M2: resultados de la prueba por pantalla (DESARROLLO)
-- Ejecutar despues de cargar el Excel con Form133 y de correr el proceso
-- (06_ejecutar_proceso.sql). No graba.
-- =====================================================================

-- 1. Sobres cargados por Form133 y encolados por el trigger (esperado: 29 y 29)
select (select count(*) from VTA_FACOPRD
         where prv_fechavta = to_date('20260828','yyyymmdd') and prv_local in (6, 13)) sobres_form133,
       (select count(*) from VTA_FACOPRD_CIERRE
         where prv_fechavta = to_date('20260828','yyyymmdd') and prv_local in (6, 13)) en_cola
  from dual;

-- 2. Por caja: esperado vs obtenido (control = OK en las 23 cajas)
select c.c_local local, c.c_terminal terminal, c.c_cierrey y, c.escenario,
       c.esperado_t1, t1.log_resultado obtenido_t1, t1.log_dif_real dr_t1,
       c.esperado_t2, t2.log_resultado obtenido_t2, t2.log_regla regla,
       case when t1.log_resultado = c.esperado_t1 and t2.log_resultado = c.esperado_t2
            then 'OK' else 'DIFERENTE' end control,
       y.ter_estado estado_y, y.ter_cerradopor cerrado_por
  from VTA_FACOPOC_CASOS c, VTA_FACOTERMSTATY y,
       (select * from VTA_FACOLOG_CIERRE_AUTO
         where log_ejecucion = (select to_number(valor) from VTA_FACOPOC_CTRL where clave = 'EJECUCION_AUTO')
           and log_proceso = 'T1' and log_nivel = 'Y') t1,
       (select * from VTA_FACOLOG_CIERRE_AUTO
         where log_ejecucion = (select to_number(valor) from VTA_FACOPOC_CTRL where clave = 'EJECUCION_AUTO')
           and log_proceso = 'T2' and log_nivel = 'Y') t2
 where c.c_origen = 'PRD3' and c.c_local in (6, 13)
   and y.ter_fecha = c.c_fecha and y.ter_local = c.c_local
   and y.ter_terminal = c.c_terminal and y.ter_cierrey = c.c_cierrey
   and t1.log_fecha_vta (+) = c.c_fecha and t1.log_local (+) = c.c_local
   and t1.log_terminal (+) = c.c_terminal and t1.log_cierrey (+) = c.c_cierrey
   and t2.log_fecha_vta (+) = c.c_fecha and t2.log_local (+) = c.c_local
   and t2.log_terminal (+) = c.c_terminal and t2.log_cierrey (+) = c.c_cierrey
 order by 1, 2, 3;

-- 3. Resumen (esperado: CERRADA_Y 19, CON_DIFERENCIA 2, BLOQUEADA 2; DI 8)
select l.log_proceso, l.log_resultado, count(*) cajas
  from VTA_FACOLOG_CIERRE_AUTO l
 where l.log_ejecucion = (select to_number(valor) from VTA_FACOPOC_CTRL where clave = 'EJECUCION_AUTO')
   and l.log_nivel = 'Y' and l.log_local in (6, 13)
 group by l.log_proceso, l.log_resultado
 order by 1, 2;

-- 4. DI registradas (monto = DR con el mismo signo; fecha contable = fecha de venta)
select m.mov_local, m.mov_terminal, m.mov_cierrey, m.mov_monto, m.mov_fecha, m.mov_fechareg,
       m.mov_hechopor, o.cpd_obs glosa
  from VTA_FACOMOVDET m, VTA_FACOCOMPDES o
 where m.mov_tipomov = 'DI' and m.mov_hechopor = 'PROC_DI_AUTO'
   and m.mov_fecha = to_date('20260828','yyyymmdd') and m.mov_local in (6, 13)
   and o.cpd_fecha (+) = m.mov_fecha and o.cpd_local (+) = m.mov_local
   and o.cpd_terminal (+) = m.mov_terminal and o.cpd_cierrey (+) = m.mov_cierrey
   and o.cpd_tipmov (+) = 'DI'
 order by 1, 2, 3;

-- 5. Z del terminal-dia: Form133 la crea/reabre ('CARGA MANUAL DE SOBRES');
--    el proceso NO la toca (esperado: ninguna cerrada por PROC_CIERRE_AUTO)
select t.ter_local, count(*) z, sum(case when t.ter_cerradopor = 'PROC_CIERRE_AUTO' then 1 else 0 end) z_cerradas_proceso
  from VTA_FACOTERMSTAT t
 where t.ter_fecha = to_date('20260828','yyyymmdd') and t.ter_local in (6, 13)
 group by t.ter_local order by 1;

-- 6. Detalle del log para las cajas que quedaron abiertas (motivo)
select l.log_proceso, l.log_local, l.log_terminal, l.log_cierrey, l.log_dif_real, l.log_resultado, l.log_regla, l.log_mensaje
  from VTA_FACOLOG_CIERRE_AUTO l
 where l.log_ejecucion = (select to_number(valor) from VTA_FACOPOC_CTRL where clave = 'EJECUCION_AUTO')
   and l.log_nivel = 'Y' and l.log_local in (6, 13)
   and l.log_resultado in ('CON_DIFERENCIA', 'BLOQUEADA', 'FUERA_RANGO', 'ERROR', 'SIN_LIBVTA', 'SIN_TERMSTAT')
 order by l.log_local, l.log_terminal, l.log_cierrey, l.log_proceso;
