-- =====================================================================
-- FSCC-12901 T1 + T2 (carpeta consolidada) - Paso 05
-- Especificacion T1 PKG_F8_FACO_COMPENSA_DI
-- Fuente: docs/sql/FSCC-12957/03_pkg_compensa_di_spec.sql (mantener ambas copias iguales)
-- =====================================================================

-- =====================================================================
-- FSCC-12957 (HU-01-T1) Compensacion automatica de DI - Falabella Colombia
-- 03 - Especificacion de PKG_F8_FACO_COMPENSA_DI
--
-- Registra en forma automatica una DI (Diferencia No Imputable) por el
-- monto de la Diferencia Real de cada cierre Y de la vista
-- VTA_FACOV_CAJAS_CIERRE (FSCC-12958: cola pendiente de VTA_FACOPRD_CIERRE
-- + cajas sin sobres del mismo local-dia), si -1000 <= DR <= 20000 y DR <> 0.
-- No cierra cajas: eso lo hace T2 (PKG_F8_FACO_CIERRE_AUTO), que llama a
-- PRC_COMPENSA_DI al inicio de PRC_CIERRE_AUTOMATICO.
--
-- Replica el registro manual de DI del exe F8 (VB6):
--   Form4 (boton DI) -> Form38.CommandAceptar_Click  (FTEPROD/Form38.frm:448)
--   Modulo1.InsertarRegistroMovDet                     (FTEPROD/Modulo1.bas:3777)
--   Form45.GrabarObs -> SubInsertarObs / SubUpdateObs  (observacion en VTA_FACOCOMPDES)
-- Reutiliza PKG_F8_FACO_CIERRE_AUTO.fn_dif_real (Label70 de Form3Y) y fn_param.
-- =====================================================================

create or replace package PKG_F8_FACO_COMPENSA_DI as

  c_usuario_di constant varchar2(30) := 'PROC_DI_AUTO';
  c_glosa_di   constant varchar2(60) := 'COMPENSACION AUTOMATICA DI';

  -- DI ya registradas en el cierre Y:
  --   'NINGUNA' | 'AUTO' (registrada por el usuario de proceso) | 'MANUAL'
  function fn_estado_di (p_fecha    in date,
                         p_local    in number,
                         p_terminal in number,
                         p_cierrey  in number) return varchar2;

  -- Evalua una caja SIN grabar nada (simulacion). Devuelve el resultado que
  -- obtendria el proceso: COMPENSABLE, DR_CERO, FUERA_RANGO, DI_AUTO_PREVIA,
  -- DI_MANUAL_PREVIA o SIN_LIBVTA, y la diferencia real en o_dif_real.
  function fn_evalua_caja (p_fecha    in  date,
                           p_local    in  number,
                           p_terminal in  number,
                           p_cierrey  in  number,
                           o_dif_real out number) return varchar2;

  -- Proceso T1 completo sobre las cajas de VTA_FACOV_CAJAS_CIERRE.
  --   p_ejecucion: id de la corrida de T2 (mismo resumen en el log); si es
  --                null, T1 toma su propio numero (ejecucion independiente).
  --   p_max_cajas: limite opcional de cajas a evaluar.
  procedure prc_compensa_di (p_ejecucion in number   default null,
                             p_usuario   in varchar2 default 'PROC_DI_AUTO',
                             p_max_cajas in number   default null);

end PKG_F8_FACO_COMPENSA_DI;
/
