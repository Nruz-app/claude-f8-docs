-- =====================================================================
-- FSCC-12901 CIERRE_DIARIO - Paso 03
-- Especificacion de PKG_F8_CIERRE_DIARIO   (Oracle 10.2)
-- MULTIPAIS (habilitado: FACO)
-- xintec-nruz 20-10-2026
--
-- Cierre diario de cajas sin diferencia (modelo 19-10-2026): la carga de
-- sobres (Form133) solo registra la DI automatica y deja la caja Pendiente;
-- este proceso, llamado una vez al dia por un proceso externo (nhal1),
-- cierra las cajas de una fecha de venta que quedaron sin diferencia.
--
-- Simula el boton "Cerrar Terminal" de Consultas de Cuadratura
-- (FTEPROD/Form43.frm, Command4_Click -> CierraTerminalYYY), para TODOS los
-- locales de la fecha:
--   * universo: cierres Y Pendientes (ter_estado <= 0) con libro de ventas
--     de la Y (mismo SQL que Form43.FuncStrPivote);
--   * cierra solo si la Dif. Real es 0 en la F8 de la Y (Form3Y, la misma
--     de PKG_F8_COMPENSA_DI_CARGA.fn_dif_real) Y en la grilla de CC
--     (Form43.SubBuscarOpcion, fn_dif_real_cc);
--   * validaciones de CierraTerminalYYY: RY-01 cheque a fecha, RY-03
--     conceptos sin regularizar, RY-06 formula ZZZ (parametro, apagada);
--   * cierre igual que el boton: ter_estado = 1, ter_cerradopor = usuario.
-- FACO opera solo con cierre Y: la Z no se toca.
--
-- Parametros 1502 (VTA_<pfx>PARAM): CD_ACTIVO, CD_VAL_CHEQ, CD_VAL_ZZZ y
-- CA_DECIMAL. Log: VTA_<pfx>LOG_CIERRE_DIARIO.
-- Depende de PKG_F8_COMPENSA_DI_CARGA (version multipais del 20-10).
-- Detalle: 00_LEEME.md y docs/README_FSCC-12901.md (seccion 5h).
-- =====================================================================

create or replace package PKG_F8_CIERRE_DIARIO as

  c_usuario constant varchar2(30) := 'PROC_CIERRE_DIARIO';

  -- Cierre diario. Lo llama el proceso externo (nhal1) una vez al dia:
  --   begin PKG_F8_CIERRE_DIARIO.prc_cierre_diario('FACO', null); end;
  --   p_flg_pais : Flg_Pais$ (prefijo de tablas). Habilitado: FACO
  --   p_fecha    : fecha de venta a cerrar; nula = dia anterior
  --   p_usuario  : se graba en ter_cerradopor y en el log
  -- Commit por caja: un error en una caja queda en el log y no corta el
  -- resto. Un error general (pais no habilitado, falla del universo) se
  -- propaga, para que el proceso externo lo vea.
  procedure prc_cierre_diario (p_flg_pais in varchar2,
                               p_fecha    in date     default null,
                               p_usuario  in varchar2 default 'PROC_CIERRE_DIARIO');

  -- Igual, devolviendo el resumen (para pruebas o para quien lo necesite).
  --   o_ejecucion   : numero de la corrida (log_ejecucion)
  --   o_cerradas    : cajas cerradas
  --   o_no_cerradas : cajas evaluadas que no se cerraron (cualquier motivo)
  procedure prc_cierre_diario (p_flg_pais    in  varchar2,
                               p_fecha       in  date,
                               p_usuario     in  varchar2,
                               o_ejecucion   out number,
                               o_cerradas    out number,
                               o_no_cerradas out number);

  -- Simulacion de una caja, SIN grabar: CERRABLE o el motivo por el que
  -- no se cerraria (CON_DIFERENCIA, CON_DIFERENCIA_CC, BLOQUEADA RY-0x,
  -- SIN_LIBVTA, SIN_TERMSTAT, YA_CERRADA, INACTIVO). Se puede usar en un SELECT.
  function fn_evalua_caja (p_flg_pais in varchar2,
                           p_fecha    in date,
                           p_local    in number,
                           p_terminal in number,
                           p_cierrey  in number) return varchar2;

  -- Dif. Real de la caja como la muestra la grilla de Consultas de
  -- Cuadratura (Form43.SubBuscarOpcion). Solo lectura.
  function fn_dif_real_cc (p_flg_pais in varchar2,
                           p_fecha    in date,
                           p_local    in number,
                           p_terminal in number,
                           p_cierrey  in number) return number;

end PKG_F8_CIERRE_DIARIO;
/
