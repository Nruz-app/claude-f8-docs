-- =====================================================================
-- FCDVT-10 (HU-03) - Paso 04c
-- Cuerpo de PKG_F8_GRABA_MASIVA_YZ_SFCL   (Oracle 10.2)
-- Tottus Chile (Flg_Pais$ = "SFCL"), boton Cargar de Form174
-- xintec-nruz 11-11-2026
-- xintec-nruz 19-11-2026: MISMAS REGLAS QUE COLOMBIA. Copia de
--   pr_graba_grupo / prc_graba de docs/sql/FCDVT-14/04c_pkg_f8_graba_masiva_yz_body.sql
--   (PKG_F8_GRABA_MASIVA_YZ, FACO): misma toma del grupo, misma
--   revalidacion, mismo reemplazo, misma numeracion de Y, mismos mensajes.
--   Solo cambian los campos y las tablas (VTA_SFCL*, SQL estatico):
--     * libvta como Form19.GrabarTerceraZZZ rama SFCL (Form19.frm:555):
--       ademas de vta_montobol / vta_montoncr / vta_montofac, graba
--       vta_mmontondb (N.DEBITO) y vta_montoguia (GUIA FACTURABLES), y
--       vta_totalvta = det_total (la suma de los 5);
--     * zzz con las 58 columnas de concepto de Tottus que no son de venta.
--   Antes: MODIFICAR, Y1 automatica y formula de la Z (anterior_2026-11-19/).
--
-- Grabado (prc_graba, boton Cargar, etapa GRABADO del log), por grupo
-- CARGADO y con commit / rollback por grupo:
--   - toma el grupo con un update condicionado a CARGADO (dos ejecuciones
--     de Cargar a la vez: la segunda espera y lo omite);
--   - rechaza el grupo si la Z (termstat) o alguna Y (termstaty) del
--     terminal-dia esta cerrada (estado 1 o 2), si no tiene su Z y sus Y,
--     o si un numero de Y queda fuera de 1..98 (vacio = siguiente al mayor
--     informado del grupo);
--   - REEMPLAZA como Form19: borra la zzz de los techkeys, la libvta
--     'F8'/'Y' y todas las termstaty del dia;
--   - inserta la Z (libvta 'F8'/99 + zzz; termstat -1 si no existe) y cada
--     Y (libvta 'Y'/N + zzz + termstaty -1), con cada campo de
--     identificacion en su columna: bolfinal = NUM_BOLETA, crepo =
--     CONT_REPOSICION, secuencia_srx = SECUENCIA, vendedor = VENDEDOR,
--     hora = HHMM (igual que FACO y que Form19 para la Z);
--   - glosas 'CARGA MASIVA DE CIERRE Z|Y - CARGA <n>' y el usuario;
--   - deja el grupo en GRABADO, o en ERROR con el motivo.
--
-- OJO: TRG_VTA_SFCLZZZ_I (before insert en zzz) busca la Y en libvta por
-- techkey para actualizar VTA_SFCLTARJ; por eso libvta se inserta antes.
-- =====================================================================

create or replace package body PKG_F8_GRABA_MASIVA_YZ_SFCL as

  -- ------------------------------------------------------------------
  -- Pais habilitado: solo SFCL (FACO usa PKG_F8_GRABA_MASIVA_YZ)
  -- ------------------------------------------------------------------
  procedure pr_config (p_flg_pais in varchar2) is
  begin
    if p_flg_pais is null
       or upper(trim(p_flg_pais)) <> PKG_F8_CARGA_MASIVA_YZ_SFCL.c_pais then
      raise_application_error(-20001,
        'PKG_F8_GRABA_MASIVA_YZ_SFCL: pais no habilitado (' || nvl(p_flg_pais, '(nulo)')
        || '); solo SFCL. FACO usa PKG_F8_GRABA_MASIVA_YZ');
    end if;
  end pr_config;

  -- ------------------------------------------------------------------
  -- Log en VTA_SFCLCARGA_YZ_LOG (transaccion autonoma)
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
    insert into VTA_SFCLCARGA_YZ_LOG
      (log_id, log_carga, log_linea, log_etapa, log_campo, log_valor,
       log_motivo, log_usuario, log_fechahora)
    values
      (SEQ_VTA_SFCLCARGA_YZ_LOG.nextval, p_carga, p_linea, p_etapa,
       substr(p_campo, 1, 30), substr(p_valor, 1, 200),
       substr(p_motivo, 1, 1000), p_usuario, sysdate);
    commit;
  end prc_log;

  function fn_usuario (p_carga in number) return varchar2 is
    v_usuario varchar2(50);
  begin
    select max(log_usuario) into v_usuario
      from VTA_SFCLCARGA_YZ_LOG
     where log_carga = p_carga
       and log_etapa = 'INICIO';
    return v_usuario;
  end fn_usuario;

  -- ------------------------------------------------------------------
  -- Grabado
  -- ------------------------------------------------------------------

  -- Inserta una fila de VTA_SFCLLIBVTA a partir de la linea de DET.
  -- Columnas como Form19.GrabarTerceraZZZ (rama SFCL), con cada campo de
  -- identificacion en su columna (FORMATO_CARGA_YZ_SFCL.md).
  procedure pr_ins_libvta (p_carga   in number,
                           p_linea   in number,
                           p_tiporeg in varchar2,
                           p_sec     in number,
                           p_boli    in number,
                           p_nrollo  in number,
                           p_tk      in number) is
  begin
    insert into VTA_SFCLLIBVTA
      (vta_fecha, vta_local, vta_terminal, vta_tiporeg, vta_secuencia, vta_fecha_venta,
       vta_montobol, vta_montofac, vta_montoncr, vta_totalvta,
       vta_numbol, vta_numfac, vta_numncr, vta_monbol_iva,
       vta_monbol_ad, vta_monbol_ex, vta_moniva, vta_monadic,
       vta_bolinicial, vta_bolfinal, vta_cantbol, vta_nrollo,
       vta_crepo_inicial, vta_crepo_final, vta_estado, vta_tipof8,
       vta_secuencia_srx, vta_hora, vta_vendedor, vta_techkey,
       vta_mmontobolper, vta_mmontotkruc, vta_mmontondb, vta_mnetotkt, vta_montoguia)
    select d.det_fecha, d.det_local, d.det_terminal, p_tiporeg, p_sec, d.det_fecha,
           d.vta_montobol, d.vta_montofac, d.vta_montoncr, d.det_total,
           0, 0, 0, 0,
           0, 0, 0, 0,
           p_boli, d.det_num_boleta, d.det_num_boleta - p_boli + 1, p_nrollo,
           d.det_cont_repo, d.det_cont_repo, 'A', 'N',
           d.det_secuencia, to_number(replace(d.det_hora, ':')), d.det_vendedor, p_tk,
           0, 0, d.vta_mmontondb, 0, d.vta_montoguia
      from VTA_SFCLCARGA_YZ_DET d
     where d.det_carga = p_carga
       and d.det_linea = p_linea;
    if sql%rowcount <> 1 then
      raise_application_error(-20012, 'No se encontro la linea ' || p_linea || ' en el detalle');
    end if;
  end pr_ins_libvta;

  -- Inserta la fila de VTA_SFCLZZZ (columnas 17 a 74 del CSV) como
  -- Form19Y.arma_query_rec. El trigger TRG_VTA_SFCLZZZ_I actualiza
  -- VTA_SFCLTARJ y el movimiento 'AL'.
  procedure pr_ins_zzz (p_carga in number,
                        p_linea in number,
                        p_tk    in number) is
  begin
    insert into VTA_SFCLZZZ
      (rec_techkey, rec_fechaproceso,
       rec_mefectivo, rec_mchkdia, rec_mchkfecha, rec_mtransbank, rec_msodimac,
       rec_mcmr, rec_mtregalo, rec_mtotconvenio, rec_mchkfala, rec_mtotfacxcob,
       rec_mncredito, rec_mtde, rec_tarjedenred, rec_tarjamipass, rec_tarjsodexo,
       rec_mcanjepuntos, mtotgiftcorp, rec_mfpay, rec_mdotaciones, rec_mretiros,
       rec_matesoramiento, rec_mabonocmr, rec_mtotsif, rec_mavancecmr, rec_mintereses,
       rec_mtransferencia, rec_mretirotrans, rec_mtransferenciaint, rec_mreversatransint,
       rec_mretirotransint, rec_mtotatrf, rec_mtotalrevtrf, rec_mabonotde, rec_mrevabonotde,
       rec_msellosvrd, rec_mtotrecauda, r_rectelefono, r_recinternet, r_recargabip,
       r_juegosazar, r_pagoservicios, r_seguros, rec_mtotrevrecauda, rev_rectelefono,
       rev_recinternet, rev_recargabip, rev_juegosazar, rev_pagoservicios, rev_seguros,
       rec_mrevcanjepuntos, mquickpay, quickpaydebidtobf, rec_mtotalpeso, rec_linio,
       rec_ecom, rec_pluxee_junaeb, rec_edenred_junaeb, rec_edenred_privado)
    select p_tk, d.det_fecha,
           d.rec_mefectivo, d.rec_mchkdia, d.rec_mchkfecha, d.rec_mtransbank, d.rec_msodimac,
           d.rec_mcmr, d.rec_mtregalo, d.rec_mtotconvenio, d.rec_mchkfala, d.rec_mtotfacxcob,
           d.rec_mncredito, d.rec_mtde, d.rec_tarjedenred, d.rec_tarjamipass, d.rec_tarjsodexo,
           d.rec_mcanjepuntos, d.mtotgiftcorp, d.rec_mfpay, d.rec_mdotaciones, d.rec_mretiros,
           d.rec_matesoramiento, d.rec_mabonocmr, d.rec_mtotsif, d.rec_mavancecmr, d.rec_mintereses,
           d.rec_mtransferencia, d.rec_mretirotrans, d.rec_mtransferenciaint, d.rec_mreversatransint,
           d.rec_mretirotransint, d.rec_mtotatrf, d.rec_mtotalrevtrf, d.rec_mabonotde, d.rec_mrevabonotde,
           d.rec_msellosvrd, d.rec_mtotrecauda, d.r_rectelefono, d.r_recinternet, d.r_recargabip,
           d.r_juegosazar, d.r_pagoservicios, d.r_seguros, d.rec_mtotrevrecauda, d.rev_rectelefono,
           d.rev_recinternet, d.rev_recargabip, d.rev_juegosazar, d.rev_pagoservicios, d.rev_seguros,
           d.rec_mrevcanjepuntos, d.mquickpay, d.quickpaydebidtobf, d.rec_mtotalpeso, d.rec_linio,
           d.rec_ecom, d.rec_pluxee_junaeb, d.rec_edenred_junaeb, d.rec_edenred_privado
      from VTA_SFCLCARGA_YZ_DET d
     where d.det_carga = p_carga
       and d.det_linea = p_linea;
  end pr_ins_zzz;

  function fn_techkey return number is
    v_tk number;
  begin
    select SEQ_VTA_SFCLTEC.nextval into v_tk from dual;   -- Form19 / Form19Y
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
    select count(*) into v_n
      from VTA_SFCLTERMSTAT
     where ter_local    = p_local
       and ter_terminal = p_term
       and ter_fecha    = p_fecha
       and ter_estado in (1, 2);
    if v_n > 0 then
      raise_application_error(-20010,
        'La Z del terminal esta cerrada (termstat estado 1 o 2); no se reemplaza');
    end if;

    select count(*) into v_n
      from VTA_SFCLTERMSTATY
     where ter_local    = p_local
       and ter_terminal = p_term
       and ter_fecha    = p_fecha
       and ter_estado in (1, 2);
    if v_n > 0 then
      raise_application_error(-20010,
        'El terminal tiene ' || v_n || ' cierre(s) Y cerrado(s) (termstaty estado 1 o 2); no se reemplaza');
    end if;

    -- Lineas del grupo: la Z y las Y en el orden del archivo
    select max(det_linea) into v_lin_z
      from VTA_SFCLCARGA_YZ_DET
     where det_carga = p_carga and det_fecha = p_fecha and det_local = p_local
       and det_terminal = p_term and det_tipo = 'Z' and det_estado = 'OK';
    select det_linea, det_nro_y
      bulk collect into v_lin_y, v_nro_y
      from VTA_SFCLCARGA_YZ_DET
     where det_carga = p_carga and det_fecha = p_fecha and det_local = p_local
       and det_terminal = p_term and det_tipo = 'Y' and det_estado = 'OK'
     order by det_linea;
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
    select vta_tiporeg, vta_secuencia, nvl(vta_bolinicial, 0), nvl(vta_nrollo, 0)
      bulk collect into v_tiporeg, v_sec_ant, v_boli_a, v_roll_a
      from VTA_SFCLLIBVTA
     where vta_fecha_venta = p_fecha and vta_local = p_local and vta_terminal = p_term
       and vta_tiporeg in ('F8', 'Y');
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
    delete from VTA_SFCLZZZ
     where rec_techkey in (select l.vta_techkey
                             from VTA_SFCLLIBVTA l
                            where l.vta_fecha_venta = p_fecha
                              and l.vta_local       = p_local
                              and l.vta_terminal    = p_term
                              and l.vta_tiporeg in ('F8', 'Y')
                              and l.vta_techkey is not null);
    delete from VTA_SFCLLIBVTA
     where vta_fecha_venta = p_fecha and vta_local = p_local and vta_terminal = p_term
       and vta_tiporeg in ('F8', 'Y');
    delete from VTA_SFCLTERMSTATY
     where ter_fecha = p_fecha and ter_local = p_local and ter_terminal = p_term;

    -- 4) Z: libvta 'F8' / 99 + zzz; termstat -1 solo si no existe
    v_tk := fn_techkey;
    pr_ins_libvta(p_carga, v_lin_z, 'F8', 99, v_boli_z, v_roll_z, v_tk);
    pr_ins_zzz(p_carga, v_lin_z, v_tk);
    insert into VTA_SFCLTERMSTAT
      (ter_local, ter_terminal, ter_fecha, ter_estado, ter_notas, ter_cerradopor)
    select p_local, p_term, p_fecha, -1, v_glosa_z, p_usuario from dual
     where not exists (select 1 from VTA_SFCLTERMSTAT
                        where ter_local = p_local and ter_terminal = p_term
                          and ter_fecha = p_fecha);

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
      insert into VTA_SFCLTERMSTATY
        (ter_local, ter_terminal, ter_fecha, ter_cierrey, ter_estado, ter_notas, ter_cerradopor)
      values (p_local, p_term, p_fecha, v_nro_y(i), -1, v_glosa_y, p_usuario);
      -- El numero asignado queda en el detalle (Form175 lo muestra)
      update VTA_SFCLCARGA_YZ_DET
         set det_nro_y = v_nro_y(i)
       where det_carga = p_carga and det_linea = v_lin_y(i);
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

  -- ------------------------------------------------------------------
  -- API
  -- ------------------------------------------------------------------
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
    select res_fecha, res_local, res_terminal
      bulk collect into v_fechas, v_locales, v_terms
      from VTA_SFCLCARGA_YZ_RES
     where res_carga  = p_carga
       and res_estado = PKG_F8_CARGA_MASIVA_YZ_SFCL.c_estado_ok
     order by res_fecha, res_local, res_terminal;

    prc_log(p_carga, null, 'GRABADO', 'INICIO', to_char(v_fechas.count),
            'Inicio de Cargar: ' || v_fechas.count || ' grupo(s) '
            || PKG_F8_CARGA_MASIVA_YZ_SFCL.c_estado_ok, v_usuario);

    for g in 1 .. v_fechas.count loop
      v_grupo := to_char(v_fechas(g), 'dd-mm-yyyy') || ' L' || v_locales(g) || ' T' || v_terms(g);
      begin
        -- Toma el grupo: bloquea su fila de RES y confirma que sigue CARGADO.
        -- Si dos sesiones ejecutan Cargar sobre la misma carga, la segunda
        -- espera aqui hasta el commit de la primera y despues lo salta.
        update VTA_SFCLCARGA_YZ_RES
           set res_fechahora = sysdate
         where res_carga = p_carga and res_fecha = v_fechas(g)
           and res_local = v_locales(g) and res_terminal = v_terms(g)
           and res_estado = PKG_F8_CARGA_MASIVA_YZ_SFCL.c_estado_ok;
        if sql%rowcount = 0 then
          raise e_tomado;
        end if;
        pr_graba_grupo(p_carga, v_fechas(g), v_locales(g), v_terms(g), v_usuario, v_msg);
        update VTA_SFCLCARGA_YZ_RES
           set res_estado = c_estado_grabado, res_mensaje = substr(v_msg, 1, 1000),
               res_fechahora = sysdate
         where res_carga = p_carga and res_fecha = v_fechas(g)
           and res_local = v_locales(g) and res_terminal = v_terms(g);
        commit;
        o_grupos_ok := o_grupos_ok + 1;
        prc_log(p_carga, null, 'GRABADO', 'GRUPO', v_grupo, v_msg, v_usuario);
      exception
        when e_tomado then
          rollback;
          prc_log(p_carga, null, 'GRABADO', 'GRUPO', v_grupo,
                  'Se omite: ya no estaba ' || PKG_F8_CARGA_MASIVA_YZ_SFCL.c_estado_ok
                  || ' (lo grabo otra ejecucion de Cargar)', v_usuario);
        when others then
          if sqlcode between -20999 and -20000 then
            v_msg := 'No se grabo: ' || substr(sqlerrm, 12);   -- sin "ORA-200nn: "
          else
            v_msg := 'No se grabo (error Oracle): ' || sqlerrm;
          end if;
          rollback;   -- deshace todo lo del grupo (borrado e inserciones)
          update VTA_SFCLCARGA_YZ_RES
             set res_estado = 'ERROR', res_mensaje = substr(v_msg, 1, 1000),
                 res_fechahora = sysdate
           where res_carga = p_carga and res_fecha = v_fechas(g)
             and res_local = v_locales(g) and res_terminal = v_terms(g);
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
      if upper(trim(p_flg_pais)) = PKG_F8_CARGA_MASIVA_YZ_SFCL.c_pais then
        prc_log(p_carga, null, 'ERROR', null, null, 'prc_graba: ' || sqlerrm, v_usuario);
      end if;
      raise;
  end prc_graba;

end PKG_F8_GRABA_MASIVA_YZ_SFCL;
/
