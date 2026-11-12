-- =====================================================================
-- FCDVT-10 (HU-03) - Paso 03
-- Especificacion de PKG_F8_CARGA_MASIVA_YZ_SFCL   (Oracle 10.2)
-- Tottus Chile (Flg_Pais$ = "SFCL")
-- xintec-nruz 11-11-2026
-- Base: docs/sql/FCDVT-14/03_pkg_carga_masiva_yz_spec.sql (FACO). Las
-- firmas de prc_inicia, prc_inserta_linea y prc_procesa son las MISMAS
-- (con pais), asi Form174 solo cambia el nombre del package segun
-- Flg_Pais$. El package de FACO no se toca.
--
-- Diferencias con FACO:
--   * Conceptos: salen de VTA_PAINT_Z (vta_localiz = 'SFCL') en tiempo de
--     ejecucion, como en Form19 / Form19Y (no hay lista fija). El
--     encabezado del CSV lo da fn_encabezado (11 columnas de
--     identificacion + una por concepto vta_pop_up = 0, en vta_order_z,
--     con el nombre vta_cmp_asoc).
--   * TIPO_CARGA: INGRESAR y MODIFICAR (HU-03.3: en MODIFICAR un concepto
--     vacio no cambia).
--   * INGRESAR acepta una Z sin Y: Cargar crea la Y1 copiando la Z, como
--     Form19.GrabaYprima.
--   * La Z se valida con la formula de VTA_PAINT_Z (vta_validadorzzz /
--     vta_signo), como Form19.FuncMontoValidaZZZ.
--
-- Uso desde Form174 (ADODB.Command), con p_flg_pais = Flg_Pais$ ("SFCL"):
--   0) select PKG_F8_CARGA_MASIVA_YZ_SFCL.fn_encabezado('SFCL') from dual
--      (plantilla / Exportar Excel)
--   1) prc_inicia -> numero de carga
--   2) prc_inserta_linea -> una llamada por linea del archivo (incluida la 1)
--   3) prc_procesa -> validaciones contra la base + resumen
--   4) select ... from VTA_SFCLCARGA_YZ_RES where res_carga = :carga
-- Cargar: PKG_F8_GRABA_MASIVA_YZ_SFCL.prc_graba (pasos 04b y 04c).
--
-- Formato del CSV: FORMATO_CARGA_YZ_SFCL.md. Detalle: 00_LEEME.md.
-- =====================================================================

create or replace package PKG_F8_CARGA_MASIVA_YZ_SFCL as

  c_pais      constant varchar2(10) := 'SFCL';

  -- Columnas de identificacion (1 a 11), iguales a las de FACO
  c_encabezado_id constant varchar2(200) :=
    'FECHA;LOCAL;TERMINAL;NRO_Y;HORA;SECUENCIA;NUM_BOLETA;VENDEDOR;CONT_REPOSICION;TIPO;TIPO_CARGA';
  c_campos_id constant pls_integer := 11;

  -- Estado final de un grupo correcto (el mismo de FACO)
  c_estado_ok constant varchar2(20) := 'CARGADO';

  -- Encabezado completo del CSV (identificacion + conceptos de VTA_PAINT_Z)
  function fn_encabezado (p_flg_pais in varchar2) return varchar2;

  -- Abre una carga y graba el log INICIO (vuelve a leer VTA_PAINT_Z).
  procedure prc_inicia (p_flg_pais in  varchar2,
                        p_archivo  in  varchar2,
                        p_usuario  in  varchar2,
                        o_carga    out number);

  -- Recibe una linea del archivo. La linea 1 debe ser el encabezado
  -- (fn_encabezado; sin distinguir mayusculas; se tolera un ; final).
  procedure prc_inserta_linea (p_flg_pais in varchar2,
                               p_carga    in number,
                               p_linea    in number,
                               p_texto    in varchar2);

  -- Valida contra la base, arma el resumen y lo cierra en CARGADO o ERROR.
  procedure prc_procesa (p_flg_pais     in  varchar2,
                         p_carga        in  number,
                         o_grupos_ok    out number,
                         o_grupos_error out number,
                         o_lin_error    out number);

  -- ------------------------------------------------------------------
  -- Uso interno de PKG_F8_GRABA_MASIVA_YZ_SFCL (una sola configuracion)
  -- ------------------------------------------------------------------
  -- Valida el pais y carga los conceptos de VTA_PAINT_Z (p_forzar: relee)
  procedure prc_config (p_flg_pais in varchar2, p_forzar in boolean default false);

  -- Concepto de venta n (1 BOLETAS, 2 N.CREDITO, 3 FACTURA, 4 N.DEBITO,
  -- 5 GUIA FACTURABLES): su vta_cmp_asoc (clave en VTA_SFCLCARGA_YZ_DETM)
  function fn_col_venta (p_n in pls_integer) return varchar2;

  -- INSERT de VTA_SFCLZZZ desde DETM.
  -- Binds: :1 techkey, :2 fecha, :3 carga, :4 linea
  function fn_sql_ins_zzz return varchar2;

  -- UPDATE de VTA_SFCLZZZ solo con los conceptos informados en la linea
  -- (nulo si la linea no informa conceptos de zzz).
  -- Binds: :1 carga, :2 linea, :3 techkey
  function fn_sql_upd_zzz (p_carga in number, p_linea in number) return varchar2;

  -- Formula de validacion de la Z sobre la base (Form19.FuncMontoValidaZZZ);
  -- devuelve la diferencia (0 = cuadra). Nulo si la formula no se puede
  -- armar (ver log INICIO). Binds: :1 fecha, :2 local, :3 terminal
  function fn_sql_valida_z return varchar2;

end PKG_F8_CARGA_MASIVA_YZ_SFCL;
/
