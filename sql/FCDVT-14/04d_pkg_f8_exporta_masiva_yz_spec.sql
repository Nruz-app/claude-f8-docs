-- =====================================================================
-- FCDVT-14 - Paso 04d
-- Especificacion de PKG_F8_EXPORTA_MASIVA_YZ   (Oracle 10.2)
-- MULTIPAIS (habilitado: FACO y SFCL)
-- xintec-nruz 16-11-2026
--
-- Boton "Descargar Excel" de Form174 (Ingreso del YYY Masivo): devuelve
-- las Z y las Y grabadas de un local y una fecha de venta, de todos los
-- terminales que las tengan (VTA_<pfx>LIBVTA 'F8' / 'Y' + VTA_<pfx>ZZZ),
-- vengan de la carga masiva (PKG_F8_GRABA_MASIVA_YZ) o de Form19 / Form19Y.
--
-- Cada linea sale con el MISMO formato del CSV de carga (separador ;,
-- columnas de fn_encabezado), asi el Excel descargado sirve de plantilla:
-- se puede corregir, guardar como CSV y volver a cargar con Buscar
-- (TIPO_CARGA = INGRESAR, que reemplaza la Z y las Y del terminal-dia).
--
-- Solo lectura: no graba nada. No usa las tablas VTA_<pfx>CARGA_YZ_*.
-- Para SFCL lee el encabezado de PKG_F8_CARGA_MASIVA_YZ_SFCL (FCDVT-10)
-- con SQL dinamico, asi este package compila aunque ese no este instalado.
--
-- Uso desde Form174 (Command2_Click, Recordset de solo lectura):
--   select PKG_F8_EXPORTA_MASIVA_YZ.fn_encabezado('FACO') encab from dual
--   select column_value linea
--     from table(PKG_F8_EXPORTA_MASIVA_YZ.fn_lineas('FACO', 5, to_date('20261016', 'yyyymmdd')))
--   select column_value linea
--     from table(PKG_F8_EXPORTA_MASIVA_YZ.fn_resumen('FACO', 5, to_date('20261016', 'yyyymmdd')))
-- Detalle: 00_LEEME.md y docs/README_FCDVT-14.md seccion 5.10.
-- =====================================================================

create or replace package PKG_F8_EXPORTA_MASIVA_YZ as

  -- Coleccion de lineas de texto (tipo de package; valido en table() para
  -- funciones pipelined desde Oracle 9i)
  type t_lineas is table of varchar2(4000);

  -- Encabezado del CSV de carga del pais (columnas separadas por ;):
  --   FACO: PKG_F8_CARGA_MASIVA_YZ.c_encabezado (56 columnas)
  --   SFCL: PKG_F8_CARGA_MASIVA_YZ_SFCL.fn_encabezado (segun VTA_PAINT_Z)
  -- Otro pais -> ORA-20001.
  function fn_encabezado (p_flg_pais in varchar2) return varchar2;

  -- Una linea por cierre (Z y cada Y) del local y la fecha, con las
  -- columnas de fn_encabezado en el mismo orden. Orden: terminal, la Z y
  -- despues las Y por numero. Identificacion (inverso de
  -- PKG_F8_GRABA_MASIVA_YZ.pr_ins_libvta):
  --   FECHA = vta_fecha_venta (dd-mm-yyyy), NRO_Y = vta_secuencia (vacio
  --   en la Z), HORA = vta_hora (HH:MM), SECUENCIA = vta_secuencia_srx,
  --   NUM_BOLETA = vta_bolfinal, VENDEDOR = vta_vendedor,
  --   CONT_REPOSICION = vta_crepo_final, TIPO = Z / Y, TIPO_CARGA = INGRESAR.
  -- Montos: cada columna del encabezado se toma de VTA_<pfx>LIBVTA o de
  -- VTA_<pfx>ZZZ (la que la tenga; si ninguna, 0), con punto decimal.
  -- Solo filas vigentes (vta_estado = 'A'). Sin cierres ese dia: no devuelve filas.
  -- Terminal con Y y sin Z vigente: se agrega una Z ARMADA con la suma de
  -- sus Y columna a columna e identificacion de la ultima Y (asi Buscar la
  -- acepta: exige una Z y que cuadre con las Y). Ver fn_resumen, Z_ARMADA.
  function fn_lineas (p_flg_pais in varchar2,
                      p_local    in number,
                      p_fecha    in date) return t_lineas pipelined;

  -- Resumen por terminal del local y la fecha (solo terminales con Z o Y):
  --   TERMINAL;CANT_Y;TOTAL_Y;TOTAL_Z;DIFERENCIA;ESTADO_Z;Y_CERRADAS;Z_ARMADA
  -- TOTAL_Y / TOTAL_Z = suma de vta_totalvta; DIFERENCIA = TOTAL_Z - TOTAL_Y;
  -- ESTADO_Z = ter_estado de VTA_<pfx>TERMSTAT (vacio si no hay fila);
  -- Y_CERRADAS = filas de VTA_<pfx>TERMSTATY con estado 1 o 2;
  -- Z_ARMADA = S si no hay Z vigente en libvta y fn_lineas la arma con la
  -- suma de las Y (TOTAL_Z y DIFERENCIA son los de la base: Z en 0).
  function fn_resumen (p_flg_pais in varchar2,
                       p_local    in number,
                       p_fecha    in date) return t_lineas pipelined;

end PKG_F8_EXPORTA_MASIVA_YZ;
/
