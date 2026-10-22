-- =====================================================================
-- FSCC-12901 COMPENSA_DI - Paso 04
-- Especificacion de PKG_F8_COMPENSA_DI_CARGA   (Oracle 10.2, solo FACO)
-- xintec-nruz 19-10-2026
--
-- Modelo 19-10-2026 (reunion con el usuario de negocio):
--   * Al cargar sobres (Form133) NO se cierra la Y. Por cada caja cargada,
--     si la diferencia real (todos los sobres de la Y) esta entre CA_DI_MIN
--     y CA_DI_MAX (-1.000 / +20.000, inclusive) y no es 0, se registra una
--     DI (Diferencia No Imputable) por el valor EXACTO y con el mismo signo.
--   * La caja queda Pendiente (abierta); el cierre lo hara un cron diario
--     (pendiente, otro desarrollo).
--   * Observacion de la DI: 'COMPENSACION AUTOMATICA DI'
--     (xintec-nruz 20-10-2026: antes 'COMPENSACION AUTOMATICA DIFERENCIA DE DI')
--     (en mayusculas, como la guarda Form45).
--   * Si la caja ya tenia una DI automatica (carga anterior), se recalcula:
--     se borra la anterior y se evalua de nuevo con todos los sobres.
--     Una DI manual (Form38) no se toca.
--
-- Replica el registro manual de DI del exe (VB6):
--   Form4 (DI) -> Form38.CommandAceptar_Click -> Modulo1.InsertarRegistroMovDet
--   (FTEPROD/Modulo1.bas:3777) y Form45.GrabarObs (VTA_FACOCOMPDES).
-- La diferencia real es la de la F8 de la Y (Form3Y.FormateaDatos, Label70);
-- la consulta es la de PKG_F8_CIERRE_AUTO.pr_cuadratura (v2, validada en
-- las pruebas 1 a 3 de test) con las tablas VTA_FACO* fijas.
-- =====================================================================

create or replace package PKG_F8_COMPENSA_DI_CARGA as

  c_usuario constant varchar2(30) := 'PROC_DI_AUTO';
  c_glosa   constant varchar2(60) := 'COMPENSACION AUTOMATICA DI';  -- 20-10-2026

  -- Diferencia Real de la F8 de la Y, tal como esta hoy (incluye cualquier
  -- DI ya registrada). NULL si la Y no tiene libro de ventas. Solo lectura.
  function fn_dif_real (p_fecha    in date,
                        p_local    in number,
                        p_terminal in number,
                        p_cierrey  in number) return number;

  -- Diferencia Real SIN la DI automatica de la Y (la que se compensaria).
  -- Solo lectura.
  function fn_dif_real_sin_di (p_fecha    in date,
                               p_local    in number,
                               p_terminal in number,
                               p_cierrey  in number) return number;

  -- Resultado que obtendria prc_compensa_caja, sin grabar nada:
  -- COMPENSABLE, DR_CERO, FUERA_RANGO, DI_MANUAL_PREVIA, SIN_LIBVTA,
  -- SIN_TERMSTAT, YA_CERRADA, SIN_Y, INACTIVO. Se puede usar en un SELECT.
  function fn_evalua (p_fecha    in date,
                      p_local    in number,
                      p_terminal in number,
                      p_cierrey  in number) return varchar2;

  -- Compensacion automatica de DI de una caja (cierre Y). La llama Form133
  -- por cada caja (fecha de venta, local, terminal, Y) del Excel cargado.
  -- Hace commit. No propaga errores: los devuelve en o_resultado = 'ERROR'
  -- y o_mensaje, y deja una fila en VTA_FACOLOG_COMPENSA_DI.
  --   o_resultado: DI_REGISTRADA, DR_CERO, FUERA_RANGO, DI_MANUAL_PREVIA,
  --                SIN_LIBVTA, SIN_TERMSTAT, YA_CERRADA, OCUPADA, SIN_Y,
  --                INACTIVO, ERROR
  --   o_monto_di : monto de la DI registrada (null si no se registro)
  --   p_usuario  : usuario que hizo la carga (solo para el log). La DI se
  --                graba siempre con mov_hechopor = c_usuario, que es lo que
  --                la identifica como automatica.
  procedure prc_compensa_caja (p_fecha     in  date,
                               p_local     in  number,
                               p_terminal  in  number,
                               p_cierrey   in  number,
                               p_usuario   in  varchar2 default 'PROC_DI_AUTO',
                               o_resultado out varchar2,
                               o_monto_di  out number,
                               o_mensaje   out varchar2);

end PKG_F8_COMPENSA_DI_CARGA;
/
