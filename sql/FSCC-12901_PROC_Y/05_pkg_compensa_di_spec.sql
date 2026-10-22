-- =====================================================================
-- FSCC-12901 v2 MULTIPAIS - Paso 05
-- Especificacion de PKG_F8_COMPENSA_DI_AUTO (T1 compensacion automatica DI)
--
-- v2 (13-10-2026): version multipais de PKG_F8_FACO_COMPENSA_DI (v1).
-- Misma logica; todas las rutinas reciben primero P_FLG_PAIS (Flg_Pais$) y
-- las tablas se resuelven con PKG_F8_CIERRE_AUTO (configuracion del pais).
-- Nombre distinto del PKG_F8_COMPENSACION_DI existente (Chile) a proposito.
--
-- Registra en forma automatica una DI (Diferencia No Imputable) por el
-- monto de la Diferencia Real de cada cierre Y del universo de la ejecucion
-- (PKG_F8_CIERRE_AUTO.fn_universo), si CA_DI_MIN <= DR <= CA_DI_MAX y DR <> 0.
-- No cierra cajas: eso lo hace T2 (PKG_F8_CIERRE_AUTO), que llama a
-- PRC_COMPENSA_DI al inicio de PRC_CIERRE_AUTOMATICO.
--
-- Replica el registro manual de DI del exe F8 (VB6):
--   Form4 (boton DI) -> Form38.CommandAceptar_Click  (FTEPROD/Form38.frm:448)
--   Modulo1.InsertarRegistroMovDet                     (FTEPROD/Modulo1.bas:3777)
--   Form45.GrabarObs -> SubInsertarObs / SubUpdateObs  (observacion en VTA_<pfx>COMPDES)
-- =====================================================================

create or replace package PKG_F8_COMPENSA_DI_AUTO as

  c_usuario_di constant varchar2(30) := 'PROC_DI_AUTO';
  c_glosa_di   constant varchar2(60) := 'COMPENSACION AUTOMATICA DI';

  -- DI ya registradas en el cierre Y:
  --   'NINGUNA' | 'AUTO' (registrada por el usuario de proceso) | 'MANUAL'
  function fn_estado_di (p_flg_pais in varchar2,
                         p_fecha    in date,
                         p_local    in number,
                         p_terminal in number,
                         p_cierrey  in number) return varchar2;

  -- Evalua una caja SIN grabar nada (simulacion). Devuelve el resultado que
  -- obtendria el proceso: COMPENSABLE, DR_CERO, FUERA_RANGO, DI_AUTO_PREVIA,
  -- DI_MANUAL_PREVIA o SIN_LIBVTA, y la diferencia real en o_dif_real.
  function fn_evalua_caja (p_flg_pais in  varchar2,
                           p_fecha    in  date,
                           p_local    in  number,
                           p_terminal in  number,
                           p_cierrey  in  number,
                           o_dif_real out number) return varchar2;

  -- Proceso T1 completo de un pais.
  --   p_ejecucion: id de la corrida de T2: evalua la carga tomada por esa
  --                ejecucion (cola E). Si es null, T1 toma su propio numero y
  --                evalua la cola pendiente (P) sin tomarla ni marcarla.
  --   p_max_cajas: limite opcional de cajas a evaluar.
  procedure prc_compensa_di (p_flg_pais  in varchar2,
                             p_ejecucion in number   default null,
                             p_usuario   in varchar2 default 'PROC_DI_AUTO',
                             p_max_cajas in number   default null);

end PKG_F8_COMPENSA_DI_AUTO;
/
