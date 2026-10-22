-- =====================================================================
-- FSCC-12901 CIERRE_DIARIO - Paso 06: pruebas
-- xintec-nruz 20-10-2026
-- Los bloques 1, 2 y 4 son de solo lectura; el 3 CIERRA cajas (commit por
-- caja). Valores a completar marcados EDITAR. Sesion de prueba guiada con
-- los datos de test en prueba_test/.
-- =====================================================================

-- 1. Parametros (ESPERADO: CD_ACTIVO S, CD_SIN_VENTA S, CD_VAL_CHEQ S,
--    CD_VAL_DOL N, CD_VAL_ZZZ N, CA_DECIMAL 0)
select trim(vta_ccodigo) codigo, vta_xglosa
  from VTA_FACOPARAM where vta_ccodtipo = 1502 order by 1;

-- 2b. (FCDVT-56) Simulacion SIN grabar de la etapa SIN VENTA de un local y
--     una fecha (EDITAR): los terminales que cerraria cerrando su Z.
--     Mismo universo que el proceso (fn_sql_universo_z), aqui por local.
select z.ter_local, z.ter_terminal, z.ter_estado,
       PKG_F8_CIERRE_DIARIO.fn_dif_real_cc('FACO', z.ter_fecha, z.ter_local, z.ter_terminal, 0) dr_cc,
       PKG_F8_CIERRE_DIARIO.fn_evalua_caja('FACO', z.ter_fecha, z.ter_local, z.ter_terminal, 0) resultado
  from (select distinct z.ter_fecha, z.ter_local, z.ter_terminal, z.ter_estado
          from VTA_FACOTERMSTAT z, VTA_FACOTERMINALES s
         where z.ter_fecha     = to_date('20261015','yyyymmdd')   -- EDITAR
           and z.ter_local     = 5                                -- EDITAR
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
                              and y.ter_local = z.ter_local and y.ter_terminal = z.ter_terminal)) z
 order by 1, 2;

-- 2c. (FCDVT-56) Volumen de la etapa SIN VENTA de una fecha (EDITAR), por
--     estado de la Z. Es lo que evaluara el proceso en TODOS los locales.
select z.ter_estado, count(*) terminales
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
 group by z.ter_estado
 order by 1;

-- 2. Simulacion SIN grabar de todas las cajas que tomaria el proceso para
--    una fecha (EDITAR): resultado esperado y las dos Dif. Real.
select t.ter_local, t.ter_terminal, t.ter_cierrey, t.ter_estado,
       PKG_F8_COMPENSA_DI_CARGA.fn_dif_real('FACO', t.ter_fecha, t.ter_local, t.ter_terminal, t.ter_cierrey) dr_f8,
       PKG_F8_CIERRE_DIARIO.fn_dif_real_cc('FACO', t.ter_fecha, t.ter_local, t.ter_terminal, t.ter_cierrey) dr_cc,
       PKG_F8_CIERRE_DIARIO.fn_evalua_caja('FACO', t.ter_fecha, t.ter_local, t.ter_terminal, t.ter_cierrey) resultado
  from (select distinct t.ter_fecha, t.ter_local, t.ter_terminal, t.ter_cierrey, t.ter_estado
          from VTA_FACOLIBVTA l, VTA_FACOZZZ r, VTA_FACOTERMSTATY t
         where l.vta_tiporeg     = 'Y'
           and t.ter_fecha       = to_date('20260831','yyyymmdd')   -- EDITAR
           and l.vta_estado      = 'A'
           and l.vta_techkey     = r.rec_techkey
           and l.vta_fecha_venta = t.ter_fecha
           and l.vta_local       = t.ter_local
           and l.vta_terminal    = t.ter_terminal
           and l.vta_secuencia   = t.ter_cierrey
           and t.ter_cierrey    <> 0
           and t.ter_estado     <= 0) t
 order by 1, 2, 3;

-- 3. Ejecucion de un dia (CIERRA). Lo mismo que hara nhal1, con la fecha
--    explicita (EDITAR). Con la fecha nula toma el dia anterior.
declare
  v_ej number; v_c number; v_nc number;
begin
  PKG_F8_CIERRE_DIARIO.prc_cierre_diario(
    p_flg_pais    => 'FACO',
    p_fecha       => to_date('20260831','yyyymmdd'),   -- EDITAR
    p_usuario     => 'PROC_CIERRE_DIARIO',
    o_ejecucion   => v_ej,
    o_cerradas    => v_c,
    o_no_cerradas => v_nc);
  dbms_output.put_line('Ejecucion ' || v_ej || ': cerradas ' || v_c || ', no cerradas ' || v_nc);
end;
/
-- Llamada de nhal1 (sin resumen):
--   begin PKG_F8_CIERRE_DIARIO.prc_cierre_diario('FACO', null); end;

-- 4. Log de la ultima ejecucion (INICIO, una fila por caja, FIN)
select l.log_id, l.log_fecha_vta, l.log_local, l.log_terminal, l.log_cierrey,
       l.log_dr_f8, l.log_dr_cc, l.log_resultado, l.log_regla, l.log_mensaje,
       l.log_usuario, l.log_fechahora
  from VTA_FACOLOG_CIERRE_DIARIO l
 where l.log_ejecucion = (select max(x.log_ejecucion) from VTA_FACOLOG_CIERRE_DIARIO x)
 order by l.log_id;

-- 5. Pais no habilitado. ESPERADO: ORA-20001 Pais no habilitado para el cierre diario: XX
select PKG_F8_CIERRE_DIARIO.fn_evalua_caja('XX', to_date('20260831','yyyymmdd'), 6, 24, 1) from dual;
