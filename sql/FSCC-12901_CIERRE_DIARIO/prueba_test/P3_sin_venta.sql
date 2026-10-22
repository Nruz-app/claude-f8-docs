-- =====================================================================
-- FSCC-12901 CIERRE_DIARIO - Sesion de prueba en test - P3: SIN VENTA
-- FCDVT-56 (HU-14.2). xintec-nruz 22-10-2026
-- Terminales vigentes sin libro de ventas Y ni Y creada: el proceso cierra
-- su Z, como "Cerrar Terminal" de CC con la fila "Cierre Y 0".
-- Caso de la captura del usuario: local 5 UNICENTRO CALI, T2, 15-10-2026,
-- todo en 0, Pendiente (rojo).
-- Bloques 1 y 2 de SOLO LECTURA; el 3 CIERRA (commit por terminal) en TODOS
-- los locales de la fecha; el 5 reabre.
-- =====================================================================

-- 1. Simulacion del local 5 el 15-10 (EDITAR local/fecha). ESPERADO: T2
--    CERRABLE_SIN_VENTA con dr_cc 0; los que tengan sobres o compensaciones
--    del dia, CON_DIFERENCIA_CC.
select z.ter_terminal, z.ter_estado,
       PKG_F8_CIERRE_DIARIO.fn_dif_real_cc('FACO', z.ter_fecha, z.ter_local, z.ter_terminal, 0) dr_cc,
       PKG_F8_CIERRE_DIARIO.fn_evalua_caja('FACO', z.ter_fecha, z.ter_local, z.ter_terminal, 0) resultado
  from VTA_FACOTERMSTAT z
 where z.ter_fecha = to_date('20261015','yyyymmdd')   -- EDITAR
   and z.ter_local = 5                                -- EDITAR
 order by 1;

-- 2. Volumen del dia en TODOS los locales (lo que evaluara el bloque 3).
--    Revisar ANTES de ejecutar: en test pueden ser cientos de terminales.
select z.ter_local, count(*) terminales
  from VTA_FACOTERMSTAT z, VTA_FACOTERMINALES s
 where z.ter_fecha     = to_date('20261015','yyyymmdd')   -- EDITAR
   and z.ter_estado   <= 0
   and s.ter_local     = z.ter_local
   and s.ter_terminal  = z.ter_terminal
   and (s.ter_fechabaja is null or s.ter_fechabaja >= z.ter_fecha)
   and not exists (select 1 from VTA_FACOLIBVTA v
                    where v.vta_tiporeg = 'Y' and v.vta_estado = 'A'
                      and v.vta_fecha_venta = z.ter_fecha
                      and v.vta_local = z.ter_local and v.vta_terminal = z.ter_terminal)
   and not exists (select 1 from VTA_FACOTERMSTATY y
                    where y.ter_fecha = z.ter_fecha
                      and y.ter_local = z.ter_local and y.ter_terminal = z.ter_terminal)
 group by z.ter_local
 order by 1;

-- 3. Ejecucion del 15-10 (CIERRA las Y del dia y las Z sin venta de TODOS
--    los locales). ESPERADO: la fila FIN del log con "Sin venta evaluados: N
--    | cerrados: M ...".
declare
  v_ej number; v_c number; v_nc number;
begin
  PKG_F8_CIERRE_DIARIO.prc_cierre_diario('FACO', to_date('20261015','yyyymmdd'),   -- EDITAR
                                         'PROC_CIERRE_DIARIO', v_ej, v_c, v_nc);
  dbms_output.put_line('15-10 ejecucion ' || v_ej || ': cerradas ' || v_c || ', no cerradas ' || v_nc);
end;
/

-- 4. Resultados (SOLO LECTURA). ESPERADO: local 5 T2 CERRADA_SIN_VENTA en el
--    log y ter_estado 1 / PROC_CIERRE_DIARIO en VTA_FACOTERMSTAT. En pantalla:
--    CC, local 5, terminal 2, 15-10-2026: "Cerrado".
select l.log_ejecucion, l.log_local, l.log_terminal, l.log_cierrey, l.log_dr_cc,
       l.log_resultado, l.log_regla, l.log_mensaje
  from VTA_FACOLOG_CIERRE_DIARIO l
 where l.log_ejecucion = (select max(x.log_ejecucion) from VTA_FACOLOG_CIERRE_DIARIO x)
   and (l.log_local = 5 or l.log_local is null)                -- EDITAR
 order by l.log_id;

select t.ter_terminal, t.ter_estado, t.ter_cerradopor
  from VTA_FACOTERMSTAT t
 where t.ter_fecha = to_date('20261015','yyyymmdd')   -- EDITAR
   and t.ter_local = 5                                -- EDITAR
 order by 1;

-- 5. Reabrir para repetir (MODIFICA DATOS, sin commit automatico): las Z de
--    la fecha cerradas por el proceso vuelven a -1 (Z precreada).
update VTA_FACOTERMSTAT t
   set t.ter_estado = -1, t.ter_cerradopor = null
 where t.ter_fecha = to_date('20261015','yyyymmdd')   -- EDITAR
   and t.ter_cerradopor = 'PROC_CIERRE_DIARIO'
   and t.ter_estado = 1;
-- commit;
-- rollback;
