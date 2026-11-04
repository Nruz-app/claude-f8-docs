-- =====================================================================
-- FCDVT-14 - Paso 03
-- Especificacion de PKG_F8_CARGA_MASIVA_YZ   (Oracle 10.2)
-- MULTIPAIS (habilitado: FACO)
-- xintec-nruz 30-10-2026 / 03-11-2026 (multipais y estado CARGADO)
-- xintec-nruz 04-11-2026: prc_graba (boton Cargar) y estado GRABADO
-- Versiones anteriores:
--   anterior_2026-11-04/ : multipais sin prc_graba (03-11)
--   anterior_2026-11-03/ : solo FACO (la instalada en test el 30-10)
--
-- Carga masiva de cierres Y / Z de Form174:
--   * etapa 1 (boton Buscar): recibe el CSV linea a linea, lo separa y
--     valida, y arma el resumen por fecha / local / terminal que muestra
--     la grilla. No graba cierres.
--   * etapa 2 (boton Cargar, prc_graba): graba los grupos CARGADO en
--     libvta, zzz y termstat(y), REEMPLAZANDO la Z y las Y que el
--     terminal-dia ya tenga (como Form19), con commit por grupo.
--
-- Uso desde Form174 (ADODB.Command, autocommit), con p_flg_pais = Flg_Pais$:
--   1) prc_inicia          -> numero de carga
--   2) prc_inserta_linea   -> una llamada por linea del archivo (incluida la 1)
--   3) prc_procesa         -> validaciones contra la base + resumen
--   4) select ... from VTA_<pfx>CARGA_YZ_RES where res_carga = :carga
--   5) prc_graba           -> (Cargar) graba los grupos CARGADO
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
-- PROCESADO); despues de Cargar, GRABADO (o ERROR si no se pudo grabar). Formato del CSV: FORMATO_CARGA_Y_FACO.md.
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

  -- Estado de un grupo que Cargar (prc_graba) ya grabo en libvta / zzz / termstat(y)
  c_estado_grabado constant varchar2(20) := 'GRABADO';

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

  -- Boton Cargar: graba cada grupo CARGADO de la carga, como Form19 (Z) y
  -- Form19Y (Y), con los campos en su columna. Por cada terminal-dia:
  --   1) revalida: la Z (termstat) y ninguna Y (termstaty) cerradas (1/2);
  --      numero de Y entre 1 y 98 (vacio = siguiente libre del grupo);
  --   2) borra la zzz de sus techkeys, la libvta 'F8'/'Y' y todas las
  --      termstaty del dia (REEMPLAZA lo que habia, como Form19);
  --   3) inserta la Z (libvta 'F8'/99 + zzz; termstat -1 si no existe) y
  --      cada Y (libvta 'Y'/N + zzz + termstaty -1);
  --   4) grupo -> GRABADO y commit. Si algo falla: rollback del grupo,
  --      grupo -> ERROR con el motivo (res_mensaje y log, etapa GRABADO)
  --      y sigue con el siguiente.
  --   p_usuario      : LOGINUSER (ter_cerradopor y log)
  --   o_grupos_ok    : grupos GRABADO en esta llamada
  --   o_grupos_error : grupos que no se pudieron grabar (quedan ERROR)
  -- Una carga sin grupos CARGADO (por ejemplo, ya grabada) devuelve 0 / 0.
  procedure prc_graba (p_flg_pais     in  varchar2,
                       p_carga        in  number,
                       p_usuario      in  varchar2,
                       o_grupos_ok    out number,
                       o_grupos_error out number);

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
