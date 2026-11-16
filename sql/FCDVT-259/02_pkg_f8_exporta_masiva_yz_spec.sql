-- =====================================================================
-- FCDVT-259 - Paso 02
-- Especificacion de PKG_F8_EXPORTA_MASIVA_YZ   (Oracle 10.2)
-- SOLO FALABELLA COLOMBIA (FACO): tablas VTA_FACO* fijas, sin prefijo.
-- xintec-nruz 16-11-2026
--
-- Boton "Exportar" de Form176 (Exportar Cierres Y y Z, plantilla de
-- carga): devuelve las Z y las Y grabadas (VTA_FACOLIBVTA 'F8' / 'Y' +
-- VTA_FACOZZZ) de un rango de fechas, un local (0 = todos) y un terminal
-- (0 = todos), vengan de la carga masiva (PKG_F8_GRABA_MASIVA_YZ) o de
-- Form19 / Form19Y.
--
-- Cada linea sale con el MISMO formato del CSV de carga de Form174
-- (separador ;, columnas de fn_encabezado = PKG_F8_CARGA_MASIVA_YZ.
-- c_encabezado, 56 columnas): el CSV exportado se vuelve a cargar con
-- Buscar de Form174 sin cambios (TIPO_CARGA = INGRESAR, que reemplaza la
-- Z y las Y del terminal-dia).
--
-- Solo lectura: no graba nada. No usa las tablas VTA_FACOCARGA_YZ_*.
--
-- Origen: version multipais FACO/SFCL de FCDVT-14 (04d/04e del 16-11,
-- boton Descargar Excel de Form174, revertido el 16-11 y nunca instalado).
-- Cambios: solo FACO (sin p_flg_pais), filtros de Form176 (rango de
-- fechas, local 0, terminal 0, grupo) y sin fn_resumen (el exe cuenta
-- las lineas).
--
-- Uso desde Form176 (Recordset de solo lectura):
--   select PKG_F8_EXPORTA_MASIVA_YZ.fn_encabezado encab from dual
--   select column_value linea
--     from table(PKG_F8_EXPORTA_MASIVA_YZ.fn_lineas(5, 0,
--                  to_date('20261115', 'yyyymmdd'), to_date('20261116', 'yyyymmdd'), null))
-- Detalle: 00_LEEME.md y docs/README_FCDVT-259.md.
-- =====================================================================

create or replace package PKG_F8_EXPORTA_MASIVA_YZ as

  -- Coleccion de lineas de texto (tipo de package; valido en table() para
  -- funciones pipelined desde Oracle 9i)
  type t_lineas is table of varchar2(4000);

  -- Encabezado del CSV de carga de FACO (PKG_F8_CARGA_MASIVA_YZ.c_encabezado,
  -- 56 columnas separadas por ;)
  function fn_encabezado return varchar2;

  -- Una linea por cierre (Z y cada Y), con las columnas de fn_encabezado en
  -- el mismo orden. Filtros:
  --   p_fecha_ini .. p_fecha_fin : vta_fecha_venta (se truncan; fin >= ini,
  --                                si no ORA-20004);
  --   p_local    : 0 = todos los locales;
  --   p_terminal : 0 = todos los terminales;
  --   p_grupo    : null = sin filtro; si viene, solo los locales de
  --                VTA_FACOLOCALES con vta_grupo = p_grupo (usuarios de
  --                grupo que eligen "TODOS LOS LOCALES" en Form176).
  -- Orden: fecha, local, terminal, la Z y despues las Y por numero.
  -- Identificacion (inverso de PKG_F8_GRABA_MASIVA_YZ.pr_ins_libvta):
  --   FECHA = vta_fecha_venta (dd-mm-yyyy), NRO_Y = vta_secuencia (vacio
  --   en la Z), HORA = vta_hora (HH:MM), SECUENCIA = vta_secuencia_srx,
  --   NUM_BOLETA = vta_bolfinal, VENDEDOR = vta_vendedor,
  --   CONT_REPOSICION = vta_crepo_final, TIPO = Z / Y, TIPO_CARGA = INGRESAR.
  -- Montos: cada columna del encabezado se toma de VTA_FACOLIBVTA o de
  -- VTA_FACOZZZ (la que la tenga; si ninguna, 0), con punto decimal.
  -- Solo filas vigentes (vta_estado = 'A'). Sin cierres: no devuelve filas.
  -- Terminal-dia con Y y sin Z vigente (FACO cerrado solo con Y): se agrega
  -- una Z ARMADA con la suma de sus Y columna a columna e identificacion de
  -- la ultima Y (asi Buscar de Form174 la acepta: exige una Z que cuadre).
  function fn_lineas (p_local     in number,
                      p_terminal  in number,
                      p_fecha_ini in date,
                      p_fecha_fin in date,
                      p_grupo     in number default null) return t_lineas pipelined;

end PKG_F8_EXPORTA_MASIVA_YZ;
/
