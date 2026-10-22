-- =====================================================================
-- FSCC-12901 COMPENSA_DI - Paso 07: pruebas
-- xintec-nruz 19-10-2026
--
-- Mientras Form133 no tenga el cambio de FORM133_cambios.md, la carga de
-- sobres NO llama al paquete: se carga el Excel en Form133 (los sobres
-- quedan en VTA_FACOPRD) y despues se ejecuta el bloque 3 a mano por caja.
-- Escenarios sugeridos (montos de la prueba 3; Y ingresada en Form19Y
-- ANTES de cargar los sobres, EFECTIVO = BOLETAS = lo indicado):
--   A  sobres 2.342.000  Y 2.342.000  -> DR 0        DR_CERO, sin DI
--   B  sobres 5.856.000  Y 5.855.500  -> DR +500     DI_REGISTRADA +500
--   C  sobres 2.670.000  Y 2.675.000  -> DR -5.000   FUERA_RANGO (< -1.000)
--   D  sobres 2.670.000  Y 2.671.000  -> DR -1.000   DI_REGISTRADA -1.000 (limite)
--   E  sobres   875.000  Y   860.000  -> DR +15.000  DI_REGISTRADA +15.000
--   F  sobres   875.000  Y   850.000  -> DR +25.000  FUERA_RANGO (> +20.000)
--   G  recarga sobre B: cargar 1 sobre mas de 300 en la misma Y
--      -> DR +800: borra la DI +500 y registra DI +800 (reemplaza)
-- En todos los casos la Y queda abierta (Pendiente).
-- =====================================================================

-- 1. Parametros (ESPERADO: CA_DECIMAL 0, CA_DI_ACTIVO S, CA_DI_MAX 20000, CA_DI_MIN -1000)
select trim(vta_ccodigo) codigo, vta_xglosa
  from VTA_FACOPARAM where vta_ccodtipo = 1502 order by 1;

-- 2. Simulacion SIN grabar. EDITAR fecha, local, terminal e Y.
select PKG_F8_COMPENSA_DI_CARGA.fn_evalua('FACO', to_date('20260829','yyyymmdd'), 6, 25, 1)          resultado,
       PKG_F8_COMPENSA_DI_CARGA.fn_dif_real_sin_di('FACO', to_date('20260829','yyyymmdd'), 6, 25, 1) dr_sin_di_auto,
       PKG_F8_COMPENSA_DI_CARGA.fn_dif_real('FACO', to_date('20260829','yyyymmdd'), 6, 25, 1)        dr_actual
  from dual;

-- 3. Ejecucion para una caja (lo mismo que hara Form133). EDITAR.
--    Multipais (20-10-2026): el pais va primero. Las firmas sin pais siguen
--    funcionando y equivalen a 'FACO'.
declare
  v_res varchar2(30);
  v_di  number;
  v_msg varchar2(1000);
begin
  PKG_F8_COMPENSA_DI_CARGA.prc_compensa_caja(
    p_flg_pais  => 'FACO',                           -- Flg_Pais$ del exe
    p_fecha     => to_date('20260829','yyyymmdd'),   -- EDITAR
    p_local     => 6,                                -- EDITAR
    p_terminal  => 25,                               -- EDITAR
    p_cierrey   => 1,                                -- EDITAR
    p_usuario   => 'PRUEBA_MANUAL',
    o_resultado => v_res,
    o_monto_di  => v_di,
    o_mensaje   => v_msg);
  dbms_output.put_line('Resultado: ' || v_res || ' | DI: ' || nvl(to_char(v_di), '-') || ' | ' || v_msg);
end;
/

-- 4. Log de la caja (EDITAR)
select log_id, log_cierrey, log_sobres, log_dif_real, log_di_anterior, log_monto_di,
       log_resultado, log_mensaje, log_usuario, log_fechahora
  from VTA_FACOLOG_COMPENSA_DI
 where log_fecha_vta = to_date('20260829','yyyymmdd') and log_local = 6 and log_terminal = 25
 order by log_id;

-- 5. DI y observacion grabadas (EDITAR). ESPERADO con DI: 1 fila DI,
--    mov_hechopor PROC_DI_AUTO, mov_regul S, mov_fechareg = fecha de venta;
--    cpd_obs = COMPENSACION AUTOMATICA DI.
select m.mov_cierrey, m.mov_tipomov, m.mov_monto, m.mov_hechopor, m.mov_regul,
       m.mov_fechareg, m.mov_techkey
  from VTA_FACOMOVDET m
 where m.mov_fecha = to_date('20260829','yyyymmdd') and m.mov_local = 6
   and m.mov_terminal = 25 and m.mov_tipomov = 'DI';

select c.cpd_cierrey, c.cpd_tipmov, c.cpd_obs
  from VTA_FACOCOMPDES c
 where c.cpd_fecha = to_date('20260829','yyyymmdd') and c.cpd_local = 6
   and c.cpd_terminal = 25 and c.cpd_tipmov = 'DI';

-- 6. La Y NO se cierra (ESPERADO: ter_estado <= 0, ter_cerradopor sin cambios).
--    Con DI registrada, dr_actual = 0 (en la F8 de la Y: Dif. de Caja = DI,
--    Compensacion = DI, Dif. Real 0, Estado Pendiente).
select t.ter_cierrey, t.ter_estado, t.ter_cerradopor,
       PKG_F8_COMPENSA_DI_CARGA.fn_dif_real('FACO', t.ter_fecha, t.ter_local, t.ter_terminal, t.ter_cierrey) dr_actual
  from VTA_FACOTERMSTATY t
 where t.ter_fecha = to_date('20260829','yyyymmdd') and t.ter_local = 6 and t.ter_terminal = 25;

-- 7. Resumen del dia: todas las cajas evaluadas y su ultimo resultado
select l.log_local, l.log_terminal, l.log_cierrey, l.log_dif_real, l.log_monto_di, l.log_resultado
  from VTA_FACOLOG_COMPENSA_DI l
 where l.log_fecha_vta = to_date('20260829','yyyymmdd')   -- EDITAR
   and l.log_id = (select max(x.log_id) from VTA_FACOLOG_COMPENSA_DI x
                    where x.log_fecha_vta = l.log_fecha_vta and x.log_local = l.log_local
                      and x.log_terminal = l.log_terminal and x.log_cierrey = l.log_cierrey)
 order by 1, 2, 3;

-- 8. Multipais (20-10-2026). ESPERADO:
--    a) con y sin pais el mismo valor (firma de compatibilidad = FACO);
--    b) un pais no habilitado da ORA-20001 "Pais no habilitado ...". EDITAR la caja.
select PKG_F8_COMPENSA_DI_CARGA.fn_dif_real('FACO', to_date('20260829','yyyymmdd'), 6, 25, 1) dr_con_pais,
       PKG_F8_COMPENSA_DI_CARGA.fn_dif_real(to_date('20260829','yyyymmdd'), 6, 25, 1)         dr_sin_pais
  from dual;
select PKG_F8_COMPENSA_DI_CARGA.fn_evalua('XX', to_date('20260829','yyyymmdd'), 6, 25, 1) from dual;
