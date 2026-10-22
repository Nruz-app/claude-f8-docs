-- =====================================================================
-- FSCC-12901 Prueba 3 en test - activar el proceso y reprocesar la carga
-- xintec-nruz 16-10-2026
--
-- Caso: Form133 llamo al paquete y el log respondio
--   "INACTIVO: Parametros 1502 CA_ACTIVO y CA_DI_ACTIVO distintos de S".
-- El paquete salio ANTES de tomar la cola: los sobres cargados siguen en
-- VTA_FACOPRD_CIERRE con estado P. No hay que volver a cargar el Excel
-- (Form133 diria "Ya existen los registros"): basta con activar los
-- parametros y ejecutar el paquete una vez.
--
-- Ejecutar conectado como INTRANETTS (dueno de VTA_*). Lo ejecuta el usuario.
-- =====================================================================

-- 1) Diagnostico (solo lectura): valores actuales de los parametros 1502.
--    Esperado: 8 filas; CA_ACTIVO y CA_DI_ACTIVO en S.
--    Si no hay filas, la parte 1 del traspaso no quedo grabada.
select vta_ccodigo, '[' || vta_xglosa || ']' glosa, vta_dfechareg
  from VTA_FACOPARAM
 where vta_ccodtipo = 1502
 order by vta_ccodigo;

-- 2) Diagnostico (solo lectura): sobres de la prueba 1 en la cola (esperado: 3 filas en P).
select pcr_id, prv_local, prv_terminal, prv_sobre, prv_montosobre, prv_cierrey,
       pcr_estado, pcr_ejecucion, pcr_resultado
  from VTA_FACOPRD_CIERRE
 where prv_local = 6
   and prv_fechavta = to_date('20260828', 'yyyymmdd')
 order by pcr_id;

-- 3) Activar T1 y T2 (si las filas existen con otro valor).
update VTA_FACOPARAM
   set vta_xglosa = 'S'
 where vta_ccodtipo = 1502
   and trim(vta_ccodigo) in ('CA_ACTIVO', 'CA_DI_ACTIVO');
-- Esperado: 2 filas actualizadas. Si son 0 filas, NO seguir: faltan los
-- parametros; insertar los 8 desde 03_parametros_FACO.sql y volver al paso 1.
commit;

-- 4) Reprocesar la carga pendiente (lo mismo que hace Form133 al terminar la carga).
begin
  PKG_F8_CIERRE_AUTO.prc_cierre_automatico('FACO');
end;
/

-- 5) Resultado (solo lectura). Prueba 1 esperado:
--    T2 INICIO, T1 INICIO, T1 DR_CERO (6/29/Y1), T1 FIN, T2 CERRADA_Y (6/29/Y1), T2 FIN.
select log_id, log_proceso, log_nivel, log_local, log_terminal, log_cierrey,
       log_dif_real, log_resultado, log_regla, log_mensaje
  from VTA_FACOLOG_CIERRE_AUTO
 where log_ejecucion = (select max(log_ejecucion) from VTA_FACOLOG_CIERRE_AUTO)
 order by log_id;

-- 6) Estado de la Y (esperado ter_estado = 1, ter_cerradopor = PROC_CIERRE_AUTO).
select ter_fecha, ter_local, ter_terminal, ter_cierrey, ter_estado, ter_cerradopor, ter_notas
  from VTA_FACOTERMSTATY
 where ter_local = 6
   and ter_terminal = 29
   and ter_fecha = to_date('20260828', 'yyyymmdd');
