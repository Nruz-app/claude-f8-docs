-- =====================================================================
-- FSCC-12901 CIERRE_DIARIO - Sesion de prueba en test - P1: ejecutar
-- CIERRA CAJAS (commit por caja). xintec-nruz 20-10-2026
-- Una ejecucion por fecha, como la hara nhal1 (aqui con la fecha explicita).
-- En DBeaver: ejecutar cada bloque con Alt+X y ver la salida (dbms_output).
-- 22-10-2026 FCDVT-56: con CD_SIN_VENTA = S el proceso cierra ademas las Z
-- de los terminales sin venta de la fecha (todos los locales) y los suma a
-- cerradas / no cerradas. Para obtener exactamente los ESPERADO de abajo,
-- poner antes CD_SIN_VENTA = N; si no, mirar la fila FIN del log (P2): la
-- parte de las Y debe coincidir. La etapa sin venta se prueba en P3.
-- =====================================================================

-- Prueba A: 31-08-2026. ESPERADO: cerradas 2 (T24, T40), no cerradas 1 (T31).
declare
  v_ej number; v_c number; v_nc number;
begin
  PKG_F8_CIERRE_DIARIO.prc_cierre_diario('FACO', to_date('20260831','yyyymmdd'),
                                         'PROC_CIERRE_DIARIO', v_ej, v_c, v_nc);
  dbms_output.put_line('31-08 ejecucion ' || v_ej || ': cerradas ' || v_c || ', no cerradas ' || v_nc);
end;
/

-- Prueba B: 28-08-2026. ESPERADO: cerradas 0, no cerradas 2 (T31, T44 con diferencia).
declare
  v_ej number; v_c number; v_nc number;
begin
  PKG_F8_CIERRE_DIARIO.prc_cierre_diario('FACO', to_date('20260828','yyyymmdd'),
                                         'PROC_CIERRE_DIARIO', v_ej, v_c, v_nc);
  dbms_output.put_line('28-08 ejecucion ' || v_ej || ': cerradas ' || v_c || ', no cerradas ' || v_nc);
end;
/

-- Prueba C: repetir el 31-08. ESPERADO: cerradas 0, no cerradas 1 (T31):
-- T24 y T40 ya no son Pendientes y no vuelven a entrar.
declare
  v_ej number; v_c number; v_nc number;
begin
  PKG_F8_CIERRE_DIARIO.prc_cierre_diario('FACO', to_date('20260831','yyyymmdd'),
                                         'PROC_CIERRE_DIARIO', v_ej, v_c, v_nc);
  dbms_output.put_line('31-08 (repeticion) ejecucion ' || v_ej || ': cerradas ' || v_c || ', no cerradas ' || v_nc);
end;
/

-- Prueba D (opcional): llamada como nhal1, sin fecha (toma el dia anterior a
-- hoy; en test normalmente no hay cajas: ESPERADO INICIO y FIN con 0 evaluadas).
-- begin PKG_F8_CIERRE_DIARIO.prc_cierre_diario('FACO', null); end;
-- /
