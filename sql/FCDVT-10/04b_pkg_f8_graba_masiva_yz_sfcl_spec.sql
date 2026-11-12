-- =====================================================================
-- FCDVT-10 (HU-03) - Paso 04b
-- Especificacion de PKG_F8_GRABA_MASIVA_YZ_SFCL   (Oracle 10.2)
-- Tottus Chile (Flg_Pais$ = "SFCL"), boton Cargar de Form174
-- xintec-nruz 11-11-2026
-- Base: docs/sql/FCDVT-14/04b_pkg_f8_graba_masiva_yz_spec.sql (FACO), con
-- la misma firma de prc_graba. Usa PKG_F8_CARGA_MASIVA_YZ_SFCL (spec del
-- paso 03: c_estado_ok, prc_config y el SQL de zzz), asi que va despues.
--
-- Graba los grupos CARGADO de una carga (por grupo, commit o rollback):
--   INGRESAR : reemplaza la Z y las Y del terminal-dia (como Form19); si el
--              grupo no trae Y, crea la Y1 copiando la Z (Form19.GrabaYprima).
--   MODIFICAR: actualiza solo los conceptos informados de la Z / las Y que
--              ya existen y recalcula vta_totalvta.
-- Despues valida en la base: Z = suma de las Y (total de venta) y la
-- formula de VTA_PAINT_Z para la Z. Si no cuadra, rollback del grupo.
-- Deja el grupo en GRABADO, o en ERROR con el motivo.
-- =====================================================================

create or replace package PKG_F8_GRABA_MASIVA_YZ_SFCL as

  c_estado_grabado constant varchar2(20) := 'GRABADO';

  --   p_flg_pais     : Flg_Pais$ (solo SFCL; otro -> ORA-20001)
  --   p_carga        : numero de carga (prc_inicia de PKG_F8_CARGA_MASIVA_YZ_SFCL)
  --   p_usuario      : LOGINUSER (ter_cerradopor y log)
  --   o_grupos_ok    : grupos GRABADO en esta ejecucion
  --   o_grupos_error : grupos que pasaron a ERROR
  procedure prc_graba (p_flg_pais     in  varchar2,
                       p_carga        in  number,
                       p_usuario      in  varchar2,
                       o_grupos_ok    out number,
                       o_grupos_error out number);

end PKG_F8_GRABA_MASIVA_YZ_SFCL;
/
