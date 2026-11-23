-- =====================================================================
-- FCDVT-10 (HU-03) - Paso 03
-- Especificacion de PKG_F8_CARGA_MASIVA_YZ_SFCL   (Oracle 10.2)
-- Tottus Chile (Flg_Pais$ = "SFCL")
-- xintec-nruz 11-11-2026
-- xintec-nruz 19-11-2026: MISMAS REGLAS QUE COLOMBIA (FCDVT-14,
--   PKG_F8_CARGA_MASIVA_YZ). Solo cambian los campos de concepto: 63
--   columnas de Tottus en una lista fija (c_encabezado), igual que el
--   c_encabezado de FACO. Antes: conceptos leidos de VTA_PAINT_Z en cada
--   carga, MODIFICAR, Z sin Y con Y1 automatica, formula de la Z y
--   cerrados en Buscar (anterior_2026-11-19/).
--
-- Carga masiva de cierres Y / Z, etapa 1 (boton Buscar de Form174):
-- recibe el CSV linea a linea, lo separa y valida, y arma el resumen por
-- fecha / local / terminal que muestra la grilla. NO graba libvta, zzz ni
-- termstat(y): eso lo hace el boton Cargar con PKG_F8_GRABA_MASIVA_YZ_SFCL
-- (pasos 04b y 04c).
--
-- Uso desde Form174 (ADODB.Command, autocommit), con p_flg_pais = Flg_Pais$:
--   0) select PKG_F8_CARGA_MASIVA_YZ_SFCL.fn_encabezado('SFCL') from dual
--      (plantilla de Exportar Excel)
--   1) prc_inicia          -> numero de carga
--   2) prc_inserta_linea   -> una llamada por linea del archivo (incluida la 1)
--   3) prc_procesa         -> validaciones contra la base + resumen
--   4) select ... from VTA_SFCLCARGA_YZ_RES where res_carga = :carga
--
-- Las firmas son las de PKG_F8_CARGA_MASIVA_YZ (FACO): Form174 solo cambia
-- el nombre del package segun Flg_Pais$. Otro pais -> ORA-20001.
-- Estados del resumen: PENDIENTE, ERROR y CARGADO.
-- Formato del CSV: FORMATO_CARGA_YZ_SFCL.md. Detalle: 00_LEEME.md.
-- =====================================================================

create or replace package PKG_F8_CARGA_MASIVA_YZ_SFCL as

  c_pais constant varchar2(10) := 'SFCL';

  -- Encabezado obligatorio del CSV de Tottus (74 columnas, separador ;):
  -- 11 de identificacion (iguales a FACO) + 63 conceptos, con el nombre
  -- vta_cmp_asoc y en el orden de VTA_PAINT_Z de test (18-11-2026). Las 5
  -- primeras son la venta (libvta); las 58 siguientes van a VTA_SFCLZZZ.
  -- Debe ser igual a las columnas 15 a 77 de VTA_SFCLCARGA_YZ_DET.
  -- xintec-nruz 21-11-2026 FCDVT-10: varchar2(4000) (antes 1000). El literal
  -- mide 1031 caracteres (74 columnas) y el package compilaba VALID, pero
  -- reventaba ORA-06502 "character string buffer too small" al instanciarse
  -- (Buscar: "PKG_F8_CARGA_MASIVA_YZ_SFCL, carga 0"); FACO mide 760 y no lo ve.
  c_encabezado constant varchar2(4000) :=
       'FECHA;LOCAL;TERMINAL;NRO_Y;HORA;SECUENCIA;NUM_BOLETA;VENDEDOR;CONT_REPOSICION;TIPO;TIPO_CARGA'
    || ';VTA_MONTOBOL;VTA_MONTONCR;VTA_MONTOFAC;VTA_MMONTONDB;VTA_MONTOGUIA'
    || ';REC_MEFECTIVO;REC_MCHKDIA;REC_MCHKFECHA;REC_MTRANSBANK;REC_MSODIMAC;REC_MCMR'
    || ';REC_MTREGALO;REC_MTOTCONVENIO;REC_MCHKFALA;REC_MTOTFACXCOB;REC_MNCREDITO;REC_MTDE'
    || ';REC_TARJEDENRED;REC_TARJAMIPASS;REC_TARJSODEXO;REC_MCANJEPUNTOS;MTOTGIFTCORP;REC_MFPAY'
    || ';REC_MDOTACIONES;REC_MRETIROS;REC_MATESORAMIENTO;REC_MABONOCMR;REC_MTOTSIF;REC_MAVANCECMR'
    || ';REC_MINTERESES;REC_MTRANSFERENCIA;REC_MRETIROTRANS;REC_MTRANSFERENCIAINT;REC_MREVERSATRANSINT'
    || ';REC_MRETIROTRANSINT;REC_MTOTATRF;REC_MTOTALREVTRF;REC_MABONOTDE;REC_MREVABONOTDE'
    || ';REC_MSELLOSVRD;REC_MTOTRECAUDA;R_RECTELEFONO;R_RECINTERNET;R_RECARGABIP;R_JUEGOSAZAR'
    || ';R_PAGOSERVICIOS;R_SEGUROS;REC_MTOTREVRECAUDA;REV_RECTELEFONO;REV_RECINTERNET'
    || ';REV_RECARGABIP;REV_JUEGOSAZAR;REV_PAGOSERVICIOS;REV_SEGUROS;REC_MREVCANJEPUNTOS'
    || ';MQUICKPAY;QUICKPAYDEBIDTOBF;REC_MTOTALPESO;REC_LINIO;REC_ECOM;REC_PLUXEE_JUNAEB'
    || ';REC_EDENRED_JUNAEB;REC_EDENRED_PRIVADO';

  c_campos constant pls_integer := 74;

  -- Estado final de un grupo correcto (el mismo de FACO)
  c_estado_ok constant varchar2(20) := 'CARGADO';

  -- Encabezado del CSV (c_encabezado). Lo usa Exportar Excel de Form174.
  function fn_encabezado (p_flg_pais in varchar2) return varchar2;

  -- Abre una carga y graba el log INICIO.
  --   p_flg_pais : Flg_Pais$ (solo SFCL; otro pais -> ORA-20001)
  --   p_archivo  : ruta del CSV (solo para el log)
  --   p_usuario  : LOGINUSER (log y resumen)
  --   o_carga    : numero de carga (SEQ_VTA_SFCLCARGA_YZ)
  procedure prc_inicia (p_flg_pais in  varchar2,
                        p_archivo  in  varchar2,
                        p_usuario  in  varchar2,
                        o_carga    out number);

  -- Recibe una linea del archivo. La linea 1 debe ser c_encabezado (sin
  -- distinguir mayusculas; se tolera un ; final). Las lineas vacias se
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

end PKG_F8_CARGA_MASIVA_YZ_SFCL;
/
