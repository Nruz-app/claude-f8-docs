-- =====================================================================
-- FCDVT-10 (HU-03) - Paso 04b
-- Especificacion de PKG_F8_GRABA_MASIVA_YZ_SFCL   (Oracle 10.2)
-- Tottus Chile (Flg_Pais$ = "SFCL"), boton Cargar de Form174
-- xintec-nruz 11-11-2026
-- xintec-nruz 19-11-2026: MISMAS REGLAS QUE COLOMBIA
--   (docs/sql/FCDVT-14/04b_pkg_f8_graba_masiva_yz_spec.sql, misma firma de
--   prc_graba). Antes: MODIFICAR, Y1 automatica y formula de la Z
--   (anterior_2026-11-19/).
--
-- Graba en libvta, zzz y termstat(y) los grupos que Buscar
-- (PKG_F8_CARGA_MASIVA_YZ_SFCL, pasos 03 y 04) dejo en CARGADO. Usa
-- c_estado_ok de la spec del paso 03, asi que va despues.
--
-- Uso desde Form174 (Command4_Click, ADODB.Command, autocommit), despues de
-- un Buscar con grupos CARGADO:
--   PKG_F8_GRABA_MASIVA_YZ_SFCL.prc_graba(Flg_Pais$, carga, LOGINUSER, ok, error)
--
-- Estados del resumen que toca: CARGADO -> GRABADO, o CARGADO -> ERROR si no
-- se pudo grabar (motivo en res_mensaje y en el log, etapa GRABADO).
-- =====================================================================

create or replace package PKG_F8_GRABA_MASIVA_YZ_SFCL as

  -- Estado de un grupo que Cargar ya grabo en libvta / zzz / termstat(y)
  c_estado_grabado constant varchar2(20) := 'GRABADO';

  -- Boton Cargar: graba cada grupo CARGADO de la carga, como Form19 (Z) y
  -- Form19Y (Y), con los campos en su columna. Por cada terminal-dia:
  --   1) toma el grupo (sigue CARGADO; si otra ejecucion de Cargar ya lo
  --      grabo, lo omite);
  --   2) revalida: la Z (termstat) y ninguna Y (termstaty) cerradas (1/2);
  --      numero de Y entre 1 y 98 (vacio = siguiente al mayor informado);
  --   3) borra la zzz de sus techkeys, la libvta 'F8'/'Y' y todas las
  --      termstaty del dia (REEMPLAZA lo que habia, como Form19);
  --   4) inserta la Z (libvta 'F8'/99 + zzz; termstat -1 si no existe) y
  --      cada Y (libvta 'Y'/N + zzz + termstaty -1);
  --   5) grupo -> GRABADO y commit. Si algo falla: rollback del grupo,
  --      grupo -> ERROR con el motivo (res_mensaje y log, etapa GRABADO)
  --      y sigue con el siguiente.
  --   p_flg_pais     : Flg_Pais$ (solo SFCL; otro -> ORA-20001)
  --   p_carga        : numero de carga (el de Buscar)
  --   p_usuario      : LOGINUSER (ter_cerradopor y log)
  --   o_grupos_ok    : grupos GRABADO en esta llamada
  --   o_grupos_error : grupos que no se pudieron grabar (quedan ERROR)
  -- Una carga sin grupos CARGADO (por ejemplo, ya grabada) devuelve 0 / 0.
  procedure prc_graba (p_flg_pais     in  varchar2,
                       p_carga        in  number,
                       p_usuario      in  varchar2,
                       o_grupos_ok    out number,
                       o_grupos_error out number);

end PKG_F8_GRABA_MASIVA_YZ_SFCL;
/
