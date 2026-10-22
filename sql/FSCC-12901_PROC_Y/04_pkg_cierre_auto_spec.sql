-- =====================================================================
-- FSCC-12901 v2 MULTIPAIS - Paso 04
-- Especificacion de PKG_F8_CIERRE_AUTO (T2 cierre automatico + utilitarios
-- comunes que usa T1 PKG_F8_COMPENSA_DI_AUTO).
--
-- v2 (13-10-2026): version multipais de PKG_F8_FACO_CIERRE_AUTO (v1).
--   * Todas las rutinas publicas reciben primero P_FLG_PAIS, el mismo valor
--     que Flg_Pais$ del exe (prefijo de tablas VTA_<pfx>...).
--   * Las tablas se arman en tiempo de ejecucion: 'VTA_' || prefijo || 'X'
--     (igual que "vta_" + Flg_Pais "x" en el exe VB6), con SQL dinamico y binds.
--   * Cada pais tiene su configuracion (prefijo, nivel de cierre, rango de
--     tarjetas, moneda dolar, modo del universo...) en PR_CONFIG del cuerpo.
--     Hoy solo esta habilitado FACO (Falabella Colombia) con la MISMA logica
--     de v1. Otro pais -> ORA-20001 'Pais no habilitado'.
--   * Universo FACO = "carga del dia": cada ejecucion toma la cola pendiente
--     (una ejecucion por carga); sin ventana de dias (CA_DIAS es del modelo
--     de Chile, ver ejemplo comentado en PR_CONFIG).
--
-- Replica la logica de cierre del exe F8 (VB6):
--   * cierre Y : Form3Y.CierraTerminal  (FTEPROD/Form3Y.frm:2801)
--   * diferencia real: FormateaDatos (Label70) + Modulo1.StrSumCompensado
-- FACO opera SOLO con cierre Y: no toca la Z (VTA_FACOTERMSTAT).
-- =====================================================================

create or replace package PKG_F8_CIERRE_AUTO as

  c_usuario_def  constant varchar2(30) := 'PROC_CIERRE_AUTO';
  c_tipo_param   constant number       := 1502;

  -- ---------------------------------------------------------------
  -- Configuracion / utilitarios multipais
  -- ---------------------------------------------------------------

  -- Nombre real de una tabla del pais: fn_tabla('FACO', 'TERMSTATY') = 'VTA_FACOTERMSTATY'.
  -- Error ORA-20001 si el pais no esta habilitado.
  function fn_tabla (p_flg_pais in varchar2,
                     p_base     in varchar2) return varchar2;

  -- Texto SQL con las marcas del pais reemplazadas ({P} prefijo, {NIVEL},
  -- {TMIN}, {TMAX}, {USD}, {SEQMOV}). Lo usa T1 para su SQL dinamico.
  function fn_sql (p_flg_pais in varchar2,
                   p_sql      in varchar2) return varchar2;

  -- Lee un parametro de VTA_<pfx>PARAM tipo 1502 (CA_ACTIVO, CA_DI_ACTIVO,
  -- CA_DI_MIN, CA_DI_MAX, CA_VAL_CHEQ, CA_VAL_ZZZ, CA_DECIMAL, CA_SIN_SOBRE;
  -- CA_DIAS solo en paises con modo DIAS). Devuelve p_default si no existe.
  function fn_param (p_flg_pais in varchar2,
                     p_codigo   in varchar2,
                     p_default  in varchar2) return varchar2;

  -- Registro en VTA_<pfx>LOG_CIERRE_AUTO (transaccion autonoma).
  -- Lo usan T1 (p_proceso 'T1') y T2 ('T2' / 'CC').
  procedure pr_registra_log (p_flg_pais  in varchar2,
                             p_ejecucion in number,
                             p_proceso   in varchar2,
                             p_nivel     in varchar2,
                             p_fecha     in date,
                             p_local     in number,
                             p_terminal  in number,
                             p_cierrey   in number,
                             p_dif_real  in number,
                             p_resultado in varchar2,
                             p_regla     in varchar2,
                             p_mensaje   in varchar2,
                             p_usuario   in varchar2);

  -- Numero nuevo de ejecucion (SEQ_VTA_<pfx>LOG_CIERRE_AUTO).
  function fn_nueva_ejecucion (p_flg_pais in varchar2) return number;

  -- Universo de cierres Y de una ejecucion (columnas: fecha, local, terminal, cierrey):
  --   p_ejecucion no nulo: cajas de la carga tomada por esa ejecucion (cola en
  --                        estado E) + cajas sin sobre del mismo local-dia
  --                        (CA_SIN_SOBRE = S, con libro de ventas de la Y).
  --   p_ejecucion nulo   : lo mismo sobre la cola pendiente (estado P), sin
  --                        tomarla (uso de T1 independiente / simulacion).
  function fn_universo (p_flg_pais  in varchar2,
                        p_ejecucion in number) return sys_refcursor;

  -- ---------------------------------------------------------------
  -- Cuadratura (Form3Y Label70 / Form43)
  -- ---------------------------------------------------------------

  -- Diferencia Real de un cierre Y. NULL si no hay libro de ventas de la Y.
  function fn_dif_real (p_flg_pais in varchar2,
                        p_fecha    in date,
                        p_local    in number,
                        p_terminal in number,
                        p_cierrey  in number) return number;

  -- Columnas "Dif. de Caja" y "Compensacion" de Consultas de Cuadratura (Form43).
  -- fn_dif_real = round(fn_dif_caja - round(fn_compensado)).
  function fn_dif_caja (p_flg_pais in varchar2,
                        p_fecha    in date,
                        p_local    in number,
                        p_terminal in number,
                        p_cierrey  in number) return number;

  function fn_compensado (p_flg_pais in varchar2,
                          p_fecha    in date,
                          p_local    in number,
                          p_terminal in number,
                          p_cierrey  in number) return number;

  -- ---------------------------------------------------------------
  -- Validaciones individuales del cierre Y
  -- ---------------------------------------------------------------

  -- RY-01 Cheque a fecha: gestion de cheques tipo 1 vs tesoreria (dia completo).
  function fn_msg_cheque_fecha (p_flg_pais in varchar2,
                                p_fecha    in date,
                                p_local    in number,
                                p_terminal in number) return varchar2;

  -- RY-03 TRUE si existe un concepto p_tipo (SN, AF, ND, FN, NP, BF, CR, CT,
  -- CA, DP) sin regularizar en la Y. CA se busca en VTA_<pfx>CARTAAVISO.
  function fn_concepto_pendiente (p_flg_pais in varchar2,
                                  p_fecha    in date,
                                  p_local    in number,
                                  p_terminal in number,
                                  p_cierrey  in number,
                                  p_tipo     in varchar2) return boolean;

  -- RY-06 Formula ZZZ de la Y: F7 - F6 - F5 - F4 - F3 - F2 - F1 (0 = cuadra).
  function fn_zzz (p_flg_pais in varchar2,
                   p_fecha    in date,
                   p_local    in number,
                   p_terminal in number,
                   p_cierrey  in number) return number;

  -- Validaciones de "Cerrar Terminal" de la Y. o_regla null = todas OK.
  procedure pr_valida_y (p_flg_pais in  varchar2,
                         p_fecha    in  date,
                         p_local    in  number,
                         p_terminal in  number,
                         p_cierrey  in  number,
                         o_regla    out varchar2,
                         o_mensaje  out varchar2);

  -- ---------------------------------------------------------------
  -- Puntos de entrada
  -- ---------------------------------------------------------------

  -- Proceso completo de un pais (lo ejecuta el job, una vez por carga):
  --   1. toma la carga (cola P -> E con esta ejecucion);
  --   2. T1 PKG_F8_COMPENSA_DI_AUTO sobre el universo de la ejecucion;
  --   3. T2 cierra las Y con diferencia real 0 que pasan las validaciones;
  --   4. la cola de la carga queda en C (procesada) con su ultimo resultado.
  -- La Z no se toca. p_max_cajas: limite opcional (lo no evaluado vuelve a P).
  procedure prc_cierre_automatico (p_flg_pais  in varchar2,
                                   p_usuario   in varchar2 default 'PROC_CIERRE_AUTO',
                                   p_max_cajas in number   default null);

  -- Cierre manual desde Consultas de Cuadratura (Form43, boton "Cerrar
  -- Terminal"), UN DIA por vez. Mismas reglas RY, sin T1 y sin depender de
  -- CA_ACTIVO. Universo: cierres Y abiertos con libro de ventas de la fecha de
  -- venta p_fecha (yyyymmdd), del local y del terminal (0 = todos).
  -- log_proceso = CC; ter_cerradopor = p_usuario (el analista).
  -- (13-10-2026: reemplaza a prc_cierre_rango de v1; el DF-SCC fila 12 no pide
  --  rango de fechas y Form43 ya exigia "Seleccione Dia de Cierre de Terminal".)
  procedure prc_cierre_dia (p_flg_pais    in  varchar2,
                            p_fecha       in  varchar2,
                            p_local       in  number,
                            p_terminal    in  number,
                            p_usuario     in  varchar2,
                            o_ejecucion   out number,
                            o_cerradas    out number,
                            o_no_cerradas out number);

end PKG_F8_CIERRE_AUTO;
/
