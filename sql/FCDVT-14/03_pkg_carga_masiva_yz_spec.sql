-- =====================================================================
-- FCDVT-14 - Paso 03
-- Especificacion de PKG_F8_CARGA_MASIVA_YZ   (Oracle 10.2)
-- MULTIPAIS (habilitado: FACO)
-- xintec-nruz 30-10-2026 / 03-11-2026 (multipais y estado CARGADO)
-- Version anterior (solo FACO, la instalada en test el 30-10):
--   anterior_2026-11-03/03_pkg_carga_masiva_yz_spec.sql
--
-- Carga masiva de cierres Y / Z, etapa 1 (boton Buscar de Form174):
-- recibe el CSV linea a linea, lo separa y valida, y arma el resumen por
-- fecha / local / terminal que muestra la grilla. NO graba libvta, zzz ni
-- termstat(y): eso lo hara el boton Cargar en la etapa siguiente.
--
-- Uso desde Form174 (ADODB.Command, autocommit), con p_flg_pais = Flg_Pais$:
--   1) prc_inicia          -> numero de carga
--   2) prc_inserta_linea   -> una llamada por linea del archivo (incluida la 1)
--   3) prc_procesa         -> validaciones contra la base + resumen
--   4) select ... from VTA_<pfx>CARGA_YZ_RES where res_carga = :carga
--
-- El pais elige las tablas VTA_<pfx>CARGA_YZ_DET / _RES / _LOG, las
-- secuencias SEQ_VTA_<pfx>CARGA_YZ[_LOG] (paso 02) y VTA_<pfx>TERMINALES.
-- Solo se aceptan los paises de la lista blanca del cuerpo (pr_config);
-- otro pais -> ORA-20001. El numero de carga es por pais.
--
-- Compatibilidad: prc_inserta_linea y prc_procesa sin pais (las firmas del
-- 30-10, que usa el exe anterior) siguen existiendo y trabajan con FACO.
--
-- Estados del resumen: PENDIENTE, ERROR y CARGADO (hasta el 03-11-2026,
-- PROCESADO). Formato del CSV: FORMATO_CARGA_Y_FACO.md.
-- Detalle: 00_LEEME.md y docs/README_FCDVT-14.md (secciones 5.5 y 5.8).
-- =====================================================================

create or replace package PKG_F8_CARGA_MASIVA_YZ as

  -- Encabezado obligatorio del CSV de FACO (56 columnas, separador ;).
  -- Otro pais puede tener otro encabezado (pr_config del cuerpo).
  c_encabezado constant varchar2(1000) :=
       'FECHA;LOCAL;TERMINAL;NRO_Y;HORA;SECUENCIA;NUM_BOLETA;VENDEDOR;CONT_REPOSICION;TIPO;TIPO_CARGA'
    || ';VTA_MONTOBOL;VTA_MONTONCR;VTA_MONTOFAC;REC_MEFECTIVO;REC_MRECAUDAEFEC;REC_MCHKDIA'
    || ';REC_MCHKFECHA;REC_MTARJ;REC_MSODIMAC;REC_MCMR;REC_MTREGALO;REC_MTOTCONVENIO'
    || ';REC_MTRASPASOTDE;REC_MRENUEVA;REC_MTOTFACXCOB;REC_MDOTACIONES;REC_MRETIROS;REC_MABONOCMR'
    || ';REC_MAVANCECMR;REC_MTOTPREPRENUEVA;REC_MTRANSFERENCIA;REC_MREVERSATRANS;REC_MRETIROTRANS;REC_MATRFEFEC'
    || ';REC_MATRFCHK;REC_MATRFCMR;REC_MATRFDEB;REC_MATRFCRE;REC_MREVATOTTRF;REC_MREVATRFEFEC'
    || ';REC_MREVATRFCMR;REC_MABONOTDE;REC_MTDE;REC_MSELLOSVRD;REC_MTOTRECAUDA;REC_MTOTREVRECAUDA'
    || ';REC_MCANJEPUNTOS;REC_MREVCANJEPUNTOS;REC_MTOTSIF;REC_MRECTERCERO;REC_MDEVTERCERO;REC_MQUICKPAYCMR'
    || ';REC_MQUICKPAYBCO;REC_ECOMPAY;REC_MPAGOPUNTOS';

  c_campos constant pls_integer := 56;

  -- Estado final de un grupo correcto (antes 'PROCESADO')
  c_estado_ok constant varchar2(20) := 'CARGADO';

  -- Abre una carga y graba el log INICIO.
  --   p_flg_pais : Flg_Pais$ (lista blanca; otro pais -> ORA-20001)
  --   p_archivo  : ruta del CSV (solo para el log)
  --   p_usuario  : LOGINUSER (log y resumen)
  --   o_carga    : numero de carga (SEQ_VTA_<pfx>CARGA_YZ)
  procedure prc_inicia (p_flg_pais in  varchar2,
                        p_archivo  in  varchar2,
                        p_usuario  in  varchar2,
                        o_carga    out number);

  -- Recibe una linea del archivo. La linea 1 debe ser el encabezado del pais
  -- (sin distinguir mayusculas; se tolera un ; final). Las lineas vacias se
  -- ignoran. Cada error de formato queda en el log (linea, campo, valor y
  -- motivo) y la fila se guarda en DET con det_estado = 'ERROR'.
  procedure prc_inserta_linea (p_flg_pais in varchar2,
                               p_carga    in number,
                               p_linea    in number,
                               p_texto    in varchar2);

  -- Valida contra la base (terminal vigente, NRO_Y repetido en el archivo),
  -- arma el resumen (estado PENDIENTE) y lo cierra en CARGADO o ERROR.
  --   o_grupos_ok    : grupos CARGADO
  --   o_grupos_error : grupos ERROR
  --   o_lin_error    : lineas con error (con o sin grupo)
  -- Si el proceso se cae, lo anota en el log (etapa ERROR), los grupos
  -- quedan PENDIENTE y el error se propaga a Form174.
  procedure prc_procesa (p_flg_pais     in  varchar2,
                         p_carga        in  number,
                         o_grupos_ok    out number,
                         o_grupos_error out number,
                         o_lin_error    out number);

  -- Compatibilidad (firmas del 30-10, exe anterior): trabajan con FACO.
  procedure prc_inserta_linea (p_carga in number,
                               p_linea in number,
                               p_texto in varchar2);

  procedure prc_procesa (p_carga        in  number,
                         o_grupos_ok    out number,
                         o_grupos_error out number,
                         o_lin_error    out number);

end PKG_F8_CARGA_MASIVA_YZ;
/
