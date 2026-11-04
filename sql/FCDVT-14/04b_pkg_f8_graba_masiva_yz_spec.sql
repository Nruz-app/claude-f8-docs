-- =====================================================================
-- FCDVT-14 - Paso 04b
-- Especificacion de PKG_F8_GRABA_MASIVA_YZ   (Oracle 10.2)
-- MULTIPAIS (habilitado: FACO)
-- xintec-nruz 04-11-2026
--
-- Carga masiva de cierres Y / Z de Form174, etapa 2 (boton Cargar): graba
-- en libvta, zzz y termstat(y) los grupos que la etapa 1 (boton Buscar,
-- PKG_F8_CARGA_MASIVA_YZ, pasos 03 y 04) dejo en CARGADO. Hasta el
-- 04-11-2026 este codigo era PKG_F8_CARGA_MASIVA_YZ.prc_graba
-- (anterior_2026-11-04b/); se separo en un package propio a pedido del
-- usuario, con la misma logica.
--
-- Depende de la spec de PKG_F8_CARGA_MASIVA_YZ (usa c_estado_ok = 'CARGADO')
-- y de sus tablas VTA_<pfx>CARGA_YZ_DET / _RES / _LOG (paso 02). Instalar
-- despues de 03 y 04 (INSTALAR.sql).
--
-- Uso desde Form174 (Command4_Click, ADODB.Command, autocommit), despues de
-- un Buscar con grupos CARGADO:
--   PKG_F8_GRABA_MASIVA_YZ.prc_graba(Flg_Pais$, carga, LOGINUSER, ok, error)
--
-- Estados del resumen que toca: CARGADO -> GRABADO, o CARGADO -> ERROR si no
-- se pudo grabar (motivo en res_mensaje y en el log, etapa GRABADO).
-- Detalle: 00_LEEME.md, FORMATO_CARGA_Y_FACO.md seccion 7 y
-- docs/README_FCDVT-14.md seccion 5.9.
-- =====================================================================

create or replace package PKG_F8_GRABA_MASIVA_YZ as

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
  --   p_flg_pais     : Flg_Pais$ (lista blanca; otro pais -> ORA-20001)
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

end PKG_F8_GRABA_MASIVA_YZ;
/
