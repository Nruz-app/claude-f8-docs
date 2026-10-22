-- =====================================================================
-- FSCC-12958 (HU-01-T2) Cierre de caja automatico - Falabella Colombia
-- 05 - Especificacion de PKG_F8_FACO_CIERRE_AUTO
--
-- Replica en PL/SQL la logica de cierre del exe F8 (VB6):
--   * cierre Y : Form3Y.CierraTerminal  (FTEPROD/Form3Y.frm:2801)
--   * diferencia real: FormateaDatos (Label70) + Modulo1.StrSumCompensado
-- y el flujo "Proceso 2 - Cierre de caja automatico" de FSCC-12901.
--
-- FACO opera SOLO con cierre Y (decision 07-10-2026): el paquete cierra
-- cierres Y (VTA_FACOTERMSTATY) y no toca la Z (VTA_FACOTERMSTAT), igual que
-- Form3Y.CierraTerminal. Las reglas RZ de Form3.CierraTerminal no aplican.
--
-- Puntos de entrada:
--   PRC_CIERRE_AUTOMATICO : proceso automatico (lo ejecuta un job externo).
--   PRC_CIERRE_RANGO      : boton "Cerrar Terminal" de Consultas de Cuadratura
--                           (Form43, Flg_Pais$ = "FACO"), ajuste FSCC-12901 DF-SCC.
-- =====================================================================

create or replace package PKG_F8_FACO_CIERRE_AUTO as

  c_usuario_def  constant varchar2(30) := 'PROC_CIERRE_AUTO';
  c_tipo_param   constant number       := 1502;

  -- Lee un parametro de VTA_FACOPARAM tipo 1502 (CA_ACTIVO, CA_VAL_CHEQ,
  -- CA_VAL_ZZZ, CA_DECIMAL, CA_DIAS, CA_SIN_SOBRE). Devuelve p_default si no existe.
  function fn_param (p_codigo  in varchar2,
                     p_default in varchar2) return varchar2;

  -- Diferencia Real de un cierre Y (Label70 de Form3Y).
  -- Devuelve NULL si no hay libro de ventas de la Y.
  function fn_dif_real (p_fecha    in date,
                        p_local    in number,
                        p_terminal in number,
                        p_cierrey  in number) return number;

  -- Columnas "Dif. de Caja" y "Compensacion" de Consultas de Cuadratura (Form43).
  -- Mismo calculo que fn_dif_real: fn_dif_real = round(fn_dif_caja - round(fn_compensado)).
  -- fn_dif_caja devuelve NULL si no hay libro de ventas; fn_compensado sin redondear.
  function fn_dif_caja (p_fecha    in date,
                        p_local    in number,
                        p_terminal in number,
                        p_cierrey  in number) return number;

  function fn_compensado (p_fecha    in date,
                          p_local    in number,
                          p_terminal in number,
                          p_cierrey  in number) return number;

  -- ---------------------------------------------------------------
  -- Validaciones individuales del cierre Y (publicas para poder probarlas
  -- por separado).
  -- ---------------------------------------------------------------

  -- RY-01 Cheque a fecha: gestion de cheques tipo 1 vs tesoreria (dia completo,
  -- como el exe). Devuelve el mensaje del exe si hay diferencia, null si cuadra.
  function fn_msg_cheque_fecha (p_fecha    in date,
                                p_local    in number,
                                p_terminal in number) return varchar2;

  -- RY-03 TRUE si existe un concepto p_tipo (SN, AF, ND, FN, NP, BF, CR, CT,
  -- CA, DP) sin regularizar en la Y. CA se busca en VTA_FACOCARTAAVISO.
  -- (BOOLEAN: usable desde PL/SQL, no desde SELECT)
  function fn_concepto_pendiente (p_fecha    in date,
                                  p_local    in number,
                                  p_terminal in number,
                                  p_cierrey  in number,
                                  p_tipo     in varchar2) return boolean;

  -- RY-06 Formula ZZZ de la Y: F7 - F6 - F5 - F4 - F3 - F2 - F1 (0 = cuadra).
  function fn_zzz (p_fecha    in date,
                   p_local    in number,
                   p_terminal in number,
                   p_cierrey  in number) return number;

  -- Validaciones de "Cerrar Terminal" de la Y (sin estado ni diferencia real,
  -- que el proceso evalua antes). o_regla null = todas OK.
  procedure pr_valida_y (p_fecha    in  date,
                         p_local    in  number,
                         p_terminal in  number,
                         p_cierrey  in  number,
                         o_regla    out varchar2,
                         o_mensaje  out varchar2);

  -- Proceso completo: T1 (PKG_F8_FACO_COMPENSA_DI) y luego cierre de las Y de
  -- VTA_FACOV_CAJAS_CIERRE (cola pendiente + cajas sin sobres del mismo
  -- local-dia si CA_SIN_SOBRE = S) que quedan con diferencia real 0 y cumplen
  -- las validaciones. La Z no se toca.
  -- p_max_cajas: limite opcional de cierres Y a evaluar por ejecucion.
  procedure prc_cierre_automatico (p_usuario   in varchar2 default 'PROC_CIERRE_AUTO',
                                   p_max_cajas in number   default null);

  -- Cierre manual desde Consultas de Cuadratura (Form43, FACO). Mismas reglas
  -- RY y flags que el proceso automatico, sin T1 y sin depender de CA_ACTIVO.
  -- Universo: cierres Y abiertos (ter_estado <= 0) con libro de ventas en el
  -- rango de fechas de venta, local y terminal (0 = todos). La Z no se toca.
  -- log_proceso = CC; ter_cerradopor = p_usuario (el analista).
  -- Fechas en texto yyyymmdd (patron de Form173).
  --   o_ejecucion   : numero de ejecucion en VTA_FACOLOG_CIERRE_AUTO
  --   o_cerradas    : cierres Y cerrados
  --   o_no_cerradas : cierres Y evaluados que no se cerraron
  procedure prc_cierre_rango (p_fecha_ini   in  varchar2,
                              p_fecha_fin   in  varchar2,
                              p_local       in  number,
                              p_terminal    in  number,
                              p_usuario     in  varchar2,
                              o_ejecucion   out number,
                              o_cerradas    out number,
                              o_no_cerradas out number);

end PKG_F8_FACO_CIERRE_AUTO;
/
