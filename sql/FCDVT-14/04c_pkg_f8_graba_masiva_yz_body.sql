-- =====================================================================
-- FCDVT-14 - Paso 04c
-- Cuerpo de PKG_F8_GRABA_MASIVA_YZ   (Oracle 10.2)
-- MULTIPAIS (habilitado: FACO)
-- xintec-nruz 04-11-2026
-- Fuente: el grabado que estaba en PKG_F8_CARGA_MASIVA_YZ
--   (anterior_2026-11-04b/04_pkg_carga_masiva_yz_body.sql, "Etapa 2"),
--   movido sin cambios de logica. pr_config, fn_r, prc_log y fn_usuario son
--   copias privadas de los de PKG_F8_CARGA_MASIVA_YZ (mismo patron que
--   PKG_F8_COMPENSA_DI_CARGA: lista blanca + marca {P}).
--
-- Grabado (prc_graba, boton Cargar, etapa GRABADO del log), por grupo
-- CARGADO y con commit / rollback por grupo:
--   - toma el grupo con un update condicionado a CARGADO (dos ejecuciones
--     de Cargar a la vez: la segunda espera y lo omite);
--   - rechaza el grupo si la Z (termstat) o alguna Y (termstaty) del
--     terminal-dia esta cerrada (estado 1 o 2), o si un numero de Y queda
--     fuera de 1..98 (vacio = siguiente al mayor informado del grupo);
--   - REEMPLAZA como Form19: borra la zzz de los techkeys, la libvta
--     'F8'/'Y' y todas las termstaty del dia;
--   - inserta la Z (libvta 'F8'/99 + zzz; termstat -1 si no existe) con las
--     columnas de Form19.GrabarTerceraZZZ (rama FACO, Form19.frm:495) y cada
--     Y (libvta 'Y'/N + zzz + termstaty -1) como Form19Y.GrabaZZZ, con cada
--     campo de identificacion en su columna (FORMATO_CARGA_Y_FACO.md 3.1);
--   - glosas 'CARGA MASIVA DE CIERRE Z|Y - CARGA <n>' y el usuario;
--   - deja el grupo en GRABADO, o en ERROR con el motivo.
-- =====================================================================

create or replace package body PKG_F8_GRABA_MASIVA_YZ as

  -- ------------------------------------------------------------------
  -- Configuracion del pais (lista blanca, la misma de
  -- PKG_F8_CARGA_MASIVA_YZ.pr_config: es la UNICA fuente del prefijo que
  -- se concatena en el SQL dinamico; nunca se usa el texto recibido).
  -- Para habilitar otro pais, agregarlo en los dos packages.
  -- ------------------------------------------------------------------
  type t_cfg is record (
    pais    varchar2(10),     -- valor de Flg_Pais$ recibido (normalizado)
    prefijo varchar2(10)      -- prefijo de tablas VTA_<prefijo>... (Chile: vacio)
  );
  g_cfg t_cfg;

  procedure pr_config (p_flg_pais in varchar2) is
    v_pais varchar2(10) := upper(trim(p_flg_pais));
    v_cfg  t_cfg;
  begin
    if g_cfg.pais is not null and g_cfg.pais = v_pais then
      return;   -- ya configurado
    end if;

    if v_pais = 'FACO' then
      -- Falabella Colombia: Y + Z por terminal-dia (Form19 / Form19Y)
      v_cfg.pais    := 'FACO';
      v_cfg.prefijo := 'FACO';
    -- elsif v_pais = 'SFCL' then ...  (ver 00_LEEME.md, "Multipais")
    else
      raise_application_error(-20001,
        'PKG_F8_GRABA_MASIVA_YZ: pais no habilitado (' || nvl(p_flg_pais, '(nulo)') || ')');
    end if;

    g_cfg := v_cfg;
  end pr_config;

  -- Reemplaza la marca {P} con el prefijo del pais configurado
  function fn_r (p_sql in varchar2) return varchar2 is
  begin
    return replace(p_sql, '{P}', g_cfg.prefijo);
  end fn_r;

  -- ------------------------------------------------------------------
  -- Log en VTA_{P}CARGA_YZ_LOG, la misma tabla de la etapa Buscar
  -- (transaccion autonoma: queda aunque el grupo haga rollback)
  -- ------------------------------------------------------------------
  procedure prc_log (p_carga   in number,
                     p_linea   in number,
                     p_etapa   in varchar2,
                     p_campo   in varchar2,
                     p_valor   in varchar2,
                     p_motivo  in varchar2,
                     p_usuario in varchar2) is
    pragma autonomous_transaction;
  begin
    execute immediate fn_r(
      q'[insert into VTA_{P}CARGA_YZ_LOG
           (log_id, log_carga, log_linea, log_etapa, log_campo, log_valor,
            log_motivo, log_usuario, log_fechahora)
         values
           (SEQ_VTA_{P}CARGA_YZ_LOG.nextval, :1, :2, :3, :4, :5, :6, :7, sysdate)]')
      using p_carga, p_linea, p_etapa,
            substr(p_campo, 1, 30), substr(p_valor, 1, 200),
            substr(p_motivo, 1, 1000), p_usuario;
    commit;
  end prc_log;

  -- Usuario que abrio la carga (log INICIO de Buscar), si no llega p_usuario
  function fn_usuario (p_carga in number) return varchar2 is
    v_usuario varchar2(50);
  begin
    execute immediate fn_r(
      q'[select max(log_usuario)
           from VTA_{P}CARGA_YZ_LOG
          where log_carga = :1
            and log_etapa = 'INICIO']')
      into v_usuario using p_carga;
    return v_usuario;
  end fn_usuario;

  -- ------------------------------------------------------------------
  -- Grabado (antes PKG_F8_CARGA_MASIVA_YZ.prc_graba, mismo codigo)
  -- ------------------------------------------------------------------

  -- Inserta una fila de VTA_{P}LIBVTA a partir de la linea de DET.
  -- Columnas como Form19.GrabarTerceraZZZ (rama FACO, :495), pero con cada
  -- campo de identificacion en su columna (FORMATO_CARGA_Y_FACO.md 3.1):
  -- bolfinal = NUM_BOLETA, crepo = CONT_REPOSICION, secuencia_srx =
  -- SECUENCIA, vendedor = VENDEDOR, hora = HHMM.
  procedure pr_ins_libvta (p_carga   in number,
                           p_linea   in number,
                           p_tiporeg in varchar2,
                           p_sec     in number,
                           p_boli    in number,
                           p_nrollo  in number,
                           p_tk      in number) is
  begin
    execute immediate fn_r(
      q'[insert into VTA_{P}LIBVTA
           (vta_fecha, vta_local, vta_terminal, vta_tiporeg, vta_secuencia, vta_fecha_venta,
            vta_montobol, vta_montofac, vta_montoncr, vta_totalvta,
            vta_numbol, vta_numfac, vta_numncr, vta_monbol_iva,
            vta_monbol_ad, vta_monbol_ex, vta_moniva, vta_monadic,
            vta_bolinicial, vta_bolfinal, vta_cantbol, vta_nrollo,
            vta_crepo_inicial, vta_crepo_final, vta_estado, vta_tipof8,
            vta_secuencia_srx, vta_hora, vta_vendedor, vta_techkey,
            vta_mmontobolper, vta_mmontotkruc, vta_mmontondb, vta_mnetotkt)
         select d.det_fecha, d.det_local, d.det_terminal, :1, :2, d.det_fecha,
                d.vta_montobol, d.vta_montofac, d.vta_montoncr, d.det_total,
                0, 0, 0, 0,
                0, 0, 0, 0,
                :3, d.det_num_boleta, d.det_num_boleta - :4 + 1, :5,
                d.det_cont_repo, d.det_cont_repo, 'A', 'N',
                d.det_secuencia, to_number(replace(d.det_hora, ':')), d.det_vendedor, :6,
                0, 0, 0, 0
           from VTA_{P}CARGA_YZ_DET d
          where d.det_carga = :7
            and d.det_linea = :8]')
      using p_tiporeg, p_sec, p_boli, p_boli, p_nrollo, p_tk, p_carga, p_linea;
    if sql%rowcount <> 1 then
      raise_application_error(-20012, 'No se encontro la linea ' || p_linea || ' en el detalle');
    end if;
  end pr_ins_libvta;

  -- Inserta la fila de VTA_{P}ZZZ (columnas 15 a 56 del CSV) como
  -- Form19Y.arma_query_rec. REC_MTOTATRF = suma de las columnas 35 a 39
  -- (Form19Y la recalcula, fila 29). Los triggers TRG_VTA_<pfx>ZZZ_I
  -- completan REC_MCMRREVCMP y REC_TARJEXTERNA.
  procedure pr_ins_zzz (p_carga in number,
                        p_linea in number,
                        p_tk    in number) is
  begin
    execute immediate fn_r(
      q'[insert into VTA_{P}ZZZ
           (rec_techkey, rec_fechaproceso,
            rec_mefectivo, rec_mrecaudaefec, rec_mchkdia, rec_mchkfecha, rec_mtarj,
            rec_msodimac, rec_mcmr, rec_mtregalo, rec_mtotconvenio, rec_mtraspasotde,
            rec_mrenueva, rec_mtotfacxcob, rec_mdotaciones, rec_mretiros, rec_mabonocmr,
            rec_mavancecmr, rec_mtotpreprenueva, rec_mtransferencia, rec_mreversatrans, rec_mretirotrans,
            rec_matrfefec, rec_matrfchk, rec_matrfcmr, rec_matrfdeb, rec_matrfcre,
            rec_mrevatottrf, rec_mrevatrfefec, rec_mrevatrfcmr, rec_mabonotde, rec_mtde,
            rec_msellosvrd, rec_mtotrecauda, rec_mtotrevrecauda, rec_mcanjepuntos, rec_mrevcanjepuntos,
            rec_mtotsif, rec_mrectercero, rec_mdevtercero, rec_mquickpaycmr, rec_mquickpaybco,
            rec_ecompay, rec_mpagopuntos, rec_mtotatrf)
         select :1, d.det_fecha,
                d.rec_mefectivo, d.rec_mrecaudaefec, d.rec_mchkdia, d.rec_mchkfecha, d.rec_mtarj,
                d.rec_msodimac, d.rec_mcmr, d.rec_mtregalo, d.rec_mtotconvenio, d.rec_mtraspasotde,
                d.rec_mrenueva, d.rec_mtotfacxcob, d.rec_mdotaciones, d.rec_mretiros, d.rec_mabonocmr,
                d.rec_mavancecmr, d.rec_mtotpreprenueva, d.rec_mtransferencia, d.rec_mreversatrans, d.rec_mretirotrans,
                d.rec_matrfefec, d.rec_matrfchk, d.rec_matrfcmr, d.rec_matrfdeb, d.rec_matrfcre,
                d.rec_mrevatottrf, d.rec_mrevatrfefec, d.rec_mrevatrfcmr, d.rec_mabonotde, d.rec_mtde,
                d.rec_msellosvrd, d.rec_mtotrecauda, d.rec_mtotrevrecauda, d.rec_mcanjepuntos, d.rec_mrevcanjepuntos,
                d.rec_mtotsif, d.rec_mrectercero, d.rec_mdevtercero, d.rec_mquickpaycmr, d.rec_mquickpaybco,
                d.rec_ecompay, d.rec_mpagopuntos,
                d.rec_matrfefec + d.rec_matrfchk + d.rec_matrfcmr + d.rec_matrfdeb + d.rec_matrfcre
           from VTA_{P}CARGA_YZ_DET d
          where d.det_carga = :2
            and d.det_linea = :3]')
      using p_tk, p_carga, p_linea;
  end pr_ins_zzz;

  function fn_techkey return number is
    v_tk number;
  begin
    -- Form19 / Form19Y: SEQ_VTA_<pfx>TEC fuera de Chile y Peru
    execute immediate fn_r('select SEQ_VTA_{P}TEC.nextval from dual') into v_tk;
    return v_tk;
  end fn_techkey;

  -- Graba un grupo (fecha / local / terminal). No hace commit ni rollback:
  -- lo hace prc_graba. Un error de negocio sale con ORA-20010..20012.
  -- Devuelve en o_msg el resumen para res_mensaje.
  procedure pr_graba_grupo (p_carga   in  number,
                            p_fecha   in  date,
                            p_local   in  number,
                            p_term    in  number,
                            p_usuario in  varchar2,
                            o_msg     out varchar2) is
    type t_num is table of number index by pls_integer;
    v_lin_y   t_num;          -- lineas Y del archivo, en orden
    v_nro_y   t_num;          -- NRO_Y informado (o nulo)
    v_lin_z   number;
    v_n       number;
    v_max     number;
    v_tk      number;
    v_boli    number;
    v_nrollo  number;
    v_ant_y   number;
    v_ant_z   number;
    type t_txt is table of varchar2(3) index by pls_integer;
    v_tiporeg t_txt;
    v_min     number;
    v_sec_ant t_num;
    v_boli_a  t_num;
    v_roll_a  t_num;
    v_boli_y  t_num;          -- bolinicial anterior de la Y, por numero
    v_roll_y  t_num;
    v_boli_z  number := 0;
    v_roll_z  number := 0;
    v_glosa_z varchar2(100) := 'CARGA MASIVA DE CIERRE Z - CARGA ' || p_carga;
    v_glosa_y varchar2(100) := 'CARGA MASIVA DE CIERRE Y - CARGA ' || p_carga;
  begin
    -- 1) Revalidacion contra la base (pudo cambiar desde Buscar)
    execute immediate fn_r(
      q'[select count(*)
           from VTA_{P}TERMSTAT
          where ter_local    = :1
            and ter_terminal = :2
            and ter_fecha    = :3
            and ter_estado in (1, 2)]')
      into v_n using p_local, p_term, p_fecha;
    if v_n > 0 then
      raise_application_error(-20010,
        'La Z del terminal esta cerrada (termstat estado 1 o 2); no se reemplaza');
    end if;

    execute immediate fn_r(
      q'[select count(*)
           from VTA_{P}TERMSTATY
          where ter_local    = :1
            and ter_terminal = :2
            and ter_fecha    = :3
            and ter_estado in (1, 2)]')
      into v_n using p_local, p_term, p_fecha;
    if v_n > 0 then
      raise_application_error(-20010,
        'El terminal tiene ' || v_n || ' cierre(s) Y cerrado(s) (termstaty estado 1 o 2); no se reemplaza');
    end if;

    -- Lineas del grupo: la Z y las Y en el orden del archivo
    execute immediate fn_r(
      q'[select max(det_linea)
           from VTA_{P}CARGA_YZ_DET
          where det_carga = :1 and det_fecha = :2 and det_local = :3
            and det_terminal = :4 and det_tipo = 'Z' and det_estado = 'OK']')
      into v_lin_z using p_carga, p_fecha, p_local, p_term;
    execute immediate fn_r(
      q'[select det_linea, det_nro_y
           from VTA_{P}CARGA_YZ_DET
          where det_carga = :1 and det_fecha = :2 and det_local = :3
            and det_terminal = :4 and det_tipo = 'Y' and det_estado = 'OK'
          order by det_linea]')
      bulk collect into v_lin_y, v_nro_y using p_carga, p_fecha, p_local, p_term;
    if v_lin_z is null or v_lin_y.count = 0 then
      raise_application_error(-20011, 'El grupo no tiene su Z y sus Y en el detalle');
    end if;

    -- Numero de Y: el informado, o el siguiente al mayor informado del grupo
    v_max := 0;
    for i in 1 .. v_lin_y.count loop
      if v_nro_y(i) is not null and v_nro_y(i) > v_max then
        v_max := v_nro_y(i);
      end if;
    end loop;
    for i in 1 .. v_lin_y.count loop
      if v_nro_y(i) is null then
        v_max      := v_max + 1;
        v_nro_y(i) := v_max;
      end if;
      if v_nro_y(i) < 1 or v_nro_y(i) > 98 then
        raise_application_error(-20011,
          'Linea ' || v_lin_y(i) || ': numero de Y ' || v_nro_y(i)
          || ' fuera de rango (1 a 98; el 99 es la Z)');
      end if;
    end loop;

    -- 2) Datos de los cierres anteriores (Form19.LeeZactual / Form19Y.LeeZactual)
    execute immediate fn_r(
      q'[select vta_tiporeg, vta_secuencia, nvl(vta_bolinicial, 0), nvl(vta_nrollo, 0)
           from VTA_{P}LIBVTA
          where vta_fecha_venta = :1 and vta_local = :2 and vta_terminal = :3
            and vta_tiporeg in ('F8', 'Y')]')
      bulk collect into v_tiporeg, v_sec_ant, v_boli_a, v_roll_a
      using p_fecha, p_local, p_term;
    v_ant_y := 0;
    v_ant_z := 0;
    for i in 1 .. v_tiporeg.count loop
      if v_tiporeg(i) = 'F8' then
        v_ant_z := v_ant_z + 1;
        if v_sec_ant(i) = 99 then
          v_boli_z := v_boli_a(i);
          v_roll_z := v_roll_a(i);
        end if;
      else
        v_ant_y := v_ant_y + 1;
        v_boli_y(v_sec_ant(i)) := v_boli_a(i);
        v_roll_y(v_sec_ant(i)) := v_roll_a(i);
      end if;
    end loop;

    -- 3) Reemplazo (como Form19.GrabarSegundaZZZ + Func_Eliminar_TermStatY),
    --    borrando ademas la zzz de los techkeys (Form19 la deja huerfana)
    execute immediate fn_r(
      q'[delete from VTA_{P}ZZZ
          where rec_techkey in (select l.vta_techkey
                                  from VTA_{P}LIBVTA l
                                 where l.vta_fecha_venta = :1
                                   and l.vta_local       = :2
                                   and l.vta_terminal    = :3
                                   and l.vta_tiporeg in ('F8', 'Y')
                                   and l.vta_techkey is not null)]')
      using p_fecha, p_local, p_term;
    execute immediate fn_r(
      q'[delete from VTA_{P}LIBVTA
          where vta_fecha_venta = :1 and vta_local = :2 and vta_terminal = :3
            and vta_tiporeg in ('F8', 'Y')]')
      using p_fecha, p_local, p_term;
    execute immediate fn_r(
      q'[delete from VTA_{P}TERMSTATY
          where ter_fecha = :1 and ter_local = :2 and ter_terminal = :3]')
      using p_fecha, p_local, p_term;

    -- 4) Z: libvta 'F8' / 99 + zzz; termstat -1 solo si no existe
    v_tk := fn_techkey;
    pr_ins_libvta(p_carga, v_lin_z, 'F8', 99, v_boli_z, v_roll_z, v_tk);
    pr_ins_zzz(p_carga, v_lin_z, v_tk);
    execute immediate fn_r(
      q'[insert into VTA_{P}TERMSTAT
           (ter_local, ter_terminal, ter_fecha, ter_estado, ter_notas, ter_cerradopor)
         select :1, :2, :3, -1, :4, :5 from dual
          where not exists (select 1 from VTA_{P}TERMSTAT
                             where ter_local = :6 and ter_terminal = :7 and ter_fecha = :8)]')
      using p_local, p_term, p_fecha, v_glosa_z, p_usuario, p_local, p_term, p_fecha;

    -- 5) Cada Y: libvta 'Y' / N + zzz + termstaty -1
    for i in 1 .. v_lin_y.count loop
      v_boli   := 0;
      v_nrollo := 0;
      if v_boli_y.exists(v_nro_y(i)) then
        v_boli   := v_boli_y(v_nro_y(i));
        v_nrollo := v_roll_y(v_nro_y(i));
      end if;
      v_tk := fn_techkey;
      pr_ins_libvta(p_carga, v_lin_y(i), 'Y', v_nro_y(i), v_boli, v_nrollo, v_tk);
      pr_ins_zzz(p_carga, v_lin_y(i), v_tk);
      execute immediate fn_r(
        q'[insert into VTA_{P}TERMSTATY
             (ter_local, ter_terminal, ter_fecha, ter_cierrey, ter_estado, ter_notas, ter_cerradopor)
           values (:1, :2, :3, :4, -1, :5, :6)]')
        using p_local, p_term, p_fecha, v_nro_y(i), v_glosa_y, p_usuario;
      -- El numero asignado queda en el detalle (Form175 lo muestra)
      execute immediate fn_r(
        q'[update VTA_{P}CARGA_YZ_DET
              set det_nro_y = :1
            where det_carga = :2 and det_linea = :3]')
        using v_nro_y(i), p_carga, v_lin_y(i);
    end loop;

    v_min := v_nro_y(1);
    v_max := v_nro_y(1);
    for i in 2 .. v_lin_y.count loop
      v_min := least(v_min, v_nro_y(i));
      v_max := greatest(v_max, v_nro_y(i));
    end loop;
    o_msg := 'Grabado: Z + ' || v_lin_y.count || ' Y (numeros '
             || v_min || ' a ' || v_max || ')';
    if v_ant_z + v_ant_y > 0 then
      o_msg := o_msg || '. Reemplazo lo anterior: ' || v_ant_z || ' Z y ' || v_ant_y || ' Y';
    end if;
  end pr_graba_grupo;

  procedure prc_graba (p_flg_pais     in  varchar2,
                       p_carga        in  number,
                       p_usuario      in  varchar2,
                       o_grupos_ok    out number,
                       o_grupos_error out number) is
    type t_fec is table of date index by pls_integer;
    type t_num is table of number index by pls_integer;
    v_fechas  t_fec;
    v_locales t_num;
    v_terms   t_num;
    v_usuario varchar2(50);
    v_msg     varchar2(1000);
    v_grupo   varchar2(200);
    e_tomado  exception;   -- otra sesion ya grabo (o esta grabando) el grupo
  begin
    o_grupos_ok    := 0;
    o_grupos_error := 0;
    pr_config(p_flg_pais);
    v_usuario := nvl(p_usuario, fn_usuario(p_carga));
    commit;   -- nada pendiente de la sesion antes del primer grupo

    -- Los grupos se leen antes del bucle: hay commit por grupo
    execute immediate fn_r(
      q'[select res_fecha, res_local, res_terminal
           from VTA_{P}CARGA_YZ_RES
          where res_carga  = :1
            and res_estado = :2
          order by res_fecha, res_local, res_terminal]')
      bulk collect into v_fechas, v_locales, v_terms
      using p_carga, PKG_F8_CARGA_MASIVA_YZ.c_estado_ok;

    prc_log(p_carga, null, 'GRABADO', 'INICIO', to_char(v_fechas.count),
            'Inicio de Cargar: ' || v_fechas.count || ' grupo(s) ' || PKG_F8_CARGA_MASIVA_YZ.c_estado_ok, v_usuario);

    for g in 1 .. v_fechas.count loop
      v_grupo := to_char(v_fechas(g), 'dd-mm-yyyy') || ' L' || v_locales(g) || ' T' || v_terms(g);
      begin
        -- Toma el grupo: bloquea su fila de RES y confirma que sigue CARGADO.
        -- Si dos sesiones ejecutan Cargar sobre la misma carga, la segunda
        -- espera aqui hasta el commit de la primera y despues lo salta.
        execute immediate fn_r(
          q'[update VTA_{P}CARGA_YZ_RES
                set res_fechahora = sysdate
              where res_carga = :1 and res_fecha = :2
                and res_local = :3 and res_terminal = :4
                and res_estado = :5]')
          using p_carga, v_fechas(g), v_locales(g), v_terms(g), PKG_F8_CARGA_MASIVA_YZ.c_estado_ok;
        if sql%rowcount = 0 then
          raise e_tomado;
        end if;
        pr_graba_grupo(p_carga, v_fechas(g), v_locales(g), v_terms(g), v_usuario, v_msg);
        execute immediate fn_r(
          q'[update VTA_{P}CARGA_YZ_RES
                set res_estado = :1, res_mensaje = :2, res_fechahora = sysdate
              where res_carga = :3 and res_fecha = :4
                and res_local = :5 and res_terminal = :6]')
          using c_estado_grabado, substr(v_msg, 1, 1000),
                p_carga, v_fechas(g), v_locales(g), v_terms(g);
        commit;
        o_grupos_ok := o_grupos_ok + 1;
        prc_log(p_carga, null, 'GRABADO', 'GRUPO', v_grupo, v_msg, v_usuario);
      exception
        when e_tomado then
          rollback;
          prc_log(p_carga, null, 'GRABADO', 'GRUPO', v_grupo,
                  'Se omite: ya no estaba ' || PKG_F8_CARGA_MASIVA_YZ.c_estado_ok || ' (lo grabo otra ejecucion de Cargar)',
                  v_usuario);
        when others then
          if sqlcode between -20999 and -20000 then
            v_msg := 'No se grabo: ' || substr(sqlerrm, 12);   -- sin "ORA-200nn: "
          else
            v_msg := 'No se grabo (error Oracle): ' || sqlerrm;
          end if;
          rollback;   -- deshace todo lo del grupo (borrado e inserciones)
          execute immediate fn_r(
            q'[update VTA_{P}CARGA_YZ_RES
                  set res_estado = 'ERROR', res_mensaje = :1, res_fechahora = sysdate
                where res_carga = :2 and res_fecha = :3
                  and res_local = :4 and res_terminal = :5]')
            using substr(v_msg, 1, 1000), p_carga, v_fechas(g), v_locales(g), v_terms(g);
          commit;
          o_grupos_error := o_grupos_error + 1;
          prc_log(p_carga, null, 'GRABADO', 'GRUPO', v_grupo, v_msg, v_usuario);
      end;
    end loop;

    prc_log(p_carga, null, 'GRABADO', 'FIN', null,
            'Fin de Cargar. Grupos ' || c_estado_grabado || ': ' || o_grupos_ok
            || ', ERROR: ' || o_grupos_error, v_usuario);
  exception
    when others then
      rollback;
      if g_cfg.pais = upper(trim(p_flg_pais)) then
        prc_log(p_carga, null, 'ERROR', null, null, 'prc_graba: ' || sqlerrm, v_usuario);
      end if;
      raise;
  end prc_graba;

end PKG_F8_GRABA_MASIVA_YZ;
/
