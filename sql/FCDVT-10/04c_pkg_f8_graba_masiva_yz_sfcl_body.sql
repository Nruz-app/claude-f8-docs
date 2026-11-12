-- =====================================================================
-- FCDVT-10 (HU-03) - Paso 04c
-- Cuerpo de PKG_F8_GRABA_MASIVA_YZ_SFCL   (Oracle 10.2)
-- Tottus Chile (Flg_Pais$ = "SFCL"), boton Cargar de Form174
-- xintec-nruz 11-11-2026
-- Base: docs/sql/FCDVT-14/04c_pkg_f8_graba_masiva_yz_body.sql (FACO):
-- misma toma del grupo, misma revalidacion, mismo reemplazo y misma
-- numeracion de Y. SQL estatico sobre las tablas SFCL; solo VTA_SFCLZZZ va
-- en SQL dinamico, armado por PKG_F8_CARGA_MASIVA_YZ_SFCL desde VTA_PAINT_Z.
--
-- INGRESAR (por grupo):
--   - rechaza si la Z (termstat) o alguna Y (termstaty) del terminal-dia
--     esta cerrada (estado 1 o 2);
--   - REEMPLAZA como Form19 (rama SFCL): borra la zzz de los techkeys, la
--     libvta 'F8' / 'Y' y todas las termstaty del dia;
--   - Z: libvta 'F8' / 99 con las columnas de Form19.GrabarTerceraZZZ (rama
--     SFCL, Form19.frm:585): vta_montobol, vta_montoncr, vta_montofac,
--     vta_mmontondb, vta_montoguia y vta_totalvta = su suma; zzz; termstat
--     -1 si no existe;
--   - cada Y: libvta 'Y' / N + zzz + termstaty -1 (Form19Y.GrabaZZZ);
--   - sin Y en el grupo: Y1 = copia de la Z (Form19.GrabaYprima);
--   - identificacion en su columna (como FACO): bolfinal = NUM_BOLETA,
--     crepo = CONT_REPOSICION, secuencia_srx = SECUENCIA, vendedor =
--     VENDEDOR, hora = HHMM (Form19Y de SFCL graba secuencia_srx = hora).
-- MODIFICAR (por grupo):
--   - rechaza si la Z del dia o la Y modificada estan cerradas;
--   - por linea: update de libvta (venta y vta_totalvta, solo si viene
--     algun concepto de venta) y de zzz solo en los conceptos informados;
--     la fila zzz de una Y se reinserta igual para que TRG_VTA_SFCLZZZ_I
--     actualice VTA_SFCLTARJ y el movimiento 'AL' (la de la Z no: su
--     insert borra los del dia). No toca termstat(y).
-- Al final de los dos: total de venta de la Z = suma de las Y del dia, y la
-- Z cumple la formula de VTA_PAINT_Z (Form19.FuncMontoValidaZZZ; en
-- MODIFICAR solo si se modifico la Z). Si no, rollback y ERROR.
-- Glosas: 'CARGA MASIVA DE CIERRE Z|Y - CARGA <n>'.
--
-- OJO: TRG_VTA_SFCLZZZ_I (before insert en zzz) busca la Y en libvta por
-- techkey para actualizar VTA_SFCLTARJ; por eso libvta se inserta antes.
-- =====================================================================

create or replace package body PKG_F8_GRABA_MASIVA_YZ_SFCL as

  type t_num is table of number index by pls_integer;

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

  -- Monto informado del concepto de venta n (1..5) en la linea; nulo si vacio
  function fn_venta (p_carga in number, p_linea in number, p_n in pls_integer) return number is
    v_col   varchar2(30) := PKG_F8_CARGA_MASIVA_YZ_SFCL.fn_col_venta(p_n);
    v_monto number;
  begin
    select max(dtm_monto) into v_monto
      from VTA_SFCLCARGA_YZ_DETM
     where dtm_carga   = p_carga
       and dtm_linea   = p_linea
       and dtm_columna = v_col;
    return v_monto;
  end fn_venta;

  function fn_techkey return number is
    v_tk number;
  begin
    select SEQ_VTA_SFCLTEC.nextval into v_tk from dual;   -- Form19 / Form19Y
    return v_tk;
  end fn_techkey;

  -- Inserta una fila de libvta con los datos de la linea p_linea de DET
  procedure pr_ins_libvta (p_carga   in number,
                           p_linea   in number,
                           p_tiporeg in varchar2,
                           p_sec     in number,
                           p_boli    in number,
                           p_nrollo  in number,
                           p_tk      in number) is
    v_bol  number := nvl(fn_venta(p_carga, p_linea, 1), 0);
    v_ncr  number := nvl(fn_venta(p_carga, p_linea, 2), 0);
    v_fac  number := nvl(fn_venta(p_carga, p_linea, 3), 0);
    v_ndb  number := nvl(fn_venta(p_carga, p_linea, 4), 0);
    v_guia number := nvl(fn_venta(p_carga, p_linea, 5), 0);
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
           v_bol, v_fac, v_ncr, v_bol + v_ncr + v_fac + v_ndb + v_guia,
           0, 0, 0, 0,
           0, 0, 0, 0,
           p_boli, d.det_num_boleta, d.det_num_boleta - p_boli + 1, p_nrollo,
           d.det_cont_repo, d.det_cont_repo, 'A', 'N',
           d.det_secuencia, to_number(replace(d.det_hora, ':')), d.det_vendedor, p_tk,
           0, 0, v_ndb, 0, v_guia
      from VTA_SFCLCARGA_YZ_DET d
     where d.det_carga = p_carga
       and d.det_linea = p_linea;
    if sql%rowcount <> 1 then
      raise_application_error(-20012, 'No se encontro la linea ' || p_linea || ' en el detalle');
    end if;
  end pr_ins_libvta;

  procedure pr_ins_zzz (p_carga in number, p_linea in number,
                        p_fecha in date, p_tk in number) is
  begin
    execute immediate PKG_F8_CARGA_MASIVA_YZ_SFCL.fn_sql_ins_zzz
      using p_tk, p_fecha, p_carga, p_linea;
  end pr_ins_zzz;

  -- Revalida la Z en la base: suma de las Y y formula de VTA_PAINT_Z
  procedure pr_valida_base (p_fecha in date, p_local in number, p_term in number,
                            p_formula in boolean) is
    v_cant_z  number;
    v_cant_y  number;
    v_total_z number;
    v_total_y number;
    v_sql     varchar2(32767);
    v_dif     number;
  begin
    select sum(case when vta_tiporeg = 'F8' and vta_secuencia = 99 then 1 else 0 end),
           sum(case when vta_tiporeg = 'Y' then 1 else 0 end),
           sum(case when vta_tiporeg = 'F8' and vta_secuencia = 99 then nvl(vta_totalvta, 0) end),
           sum(case when vta_tiporeg = 'Y' then nvl(vta_totalvta, 0) end)
      into v_cant_z, v_cant_y, v_total_z, v_total_y
      from VTA_SFCLLIBVTA
     where vta_fecha_venta = p_fecha
       and vta_local       = p_local
       and vta_terminal    = p_term
       and vta_tiporeg in ('F8', 'Y');
    if nvl(v_cant_z, 0) = 1 and nvl(v_cant_y, 0) > 0
       and nvl(v_total_z, 0) <> nvl(v_total_y, 0) then
      raise_application_error(-20013,
        'Total de venta de la Z (' || v_total_z || ') distinto de la suma de las '
        || v_cant_y || ' Y (' || v_total_y || ')');
    end if;

    if p_formula then
      v_sql := PKG_F8_CARGA_MASIVA_YZ_SFCL.fn_sql_valida_z;
      if v_sql is not null then
        execute immediate v_sql into v_dif using p_fecha, p_local, p_term;
        if nvl(v_dif, 0) <> 0 then
          raise_application_error(-20013,
            'Z descuadrada segun la formula de VTA_PAINT_Z (diferencia ' || v_dif || ')');
        end if;
      end if;
    end if;
  end pr_valida_base;

  -- ------------------------------------------------------------------
  -- INGRESAR: reemplaza la Z y las Y del terminal-dia
  -- ------------------------------------------------------------------
  procedure pr_graba_ingresar (p_carga   in  number,
                               p_fecha   in  date,
                               p_local   in  number,
                               p_term    in  number,
                               p_usuario in  varchar2,
                               o_msg     out varchar2) is
    v_lin_y   t_num;
    v_nro_y   t_num;
    v_lin_z   number;
    v_n       number;
    v_max     number;
    v_min     number;
    v_tk      number;
    v_boli    number;
    v_nrollo  number;
    v_ant_y   number := 0;
    v_ant_z   number := 0;
    type t_txt is table of varchar2(3) index by pls_integer;
    v_tiporeg t_txt;
    v_sec_ant t_num;
    v_boli_a  t_num;
    v_roll_a  t_num;
    v_boli_y  t_num;
    v_roll_y  t_num;
    v_boli_z  number := 0;
    v_roll_z  number := 0;
    v_glosa_z varchar2(100) := 'CARGA MASIVA DE CIERRE Z - CARGA ' || p_carga;
    v_glosa_y varchar2(100) := 'CARGA MASIVA DE CIERRE Y - CARGA ' || p_carga;
  begin
    -- 1) Revalidacion contra la base (pudo cambiar desde Buscar)
    select count(*) into v_n
      from VTA_SFCLTERMSTAT
     where ter_local = p_local and ter_terminal = p_term and ter_fecha = p_fecha
       and ter_estado in (1, 2);
    if v_n > 0 then
      raise_application_error(-20010,
        'La Z del terminal esta cerrada (termstat estado 1 o 2); no se reemplaza');
    end if;
    select count(*) into v_n
      from VTA_SFCLTERMSTATY
     where ter_local = p_local and ter_terminal = p_term and ter_fecha = p_fecha
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
    if v_lin_z is null then
      raise_application_error(-20011, 'El grupo no tiene su Z en el detalle');
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

    -- 3) Reemplazo (Form19.GrabarSegundaZZZ + Func_Eliminar_TermStatY),
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
    pr_ins_zzz(p_carga, v_lin_z, p_fecha, v_tk);
    insert into VTA_SFCLTERMSTAT
      (ter_local, ter_terminal, ter_fecha, ter_estado, ter_notas, ter_cerradopor)
    select p_local, p_term, p_fecha, -1, v_glosa_z, p_usuario from dual
     where not exists (select 1 from VTA_SFCLTERMSTAT
                        where ter_local = p_local and ter_terminal = p_term
                          and ter_fecha = p_fecha);

    if v_lin_y.count = 0 then
      -- 5a) Sin Y: Y1 = copia de la Z (Form19.GrabaYprima, misma bolinicial)
      v_tk := fn_techkey;
      pr_ins_libvta(p_carga, v_lin_z, 'Y', 1, v_boli_z, v_roll_z, v_tk);
      pr_ins_zzz(p_carga, v_lin_z, p_fecha, v_tk);
      insert into VTA_SFCLTERMSTATY
        (ter_local, ter_terminal, ter_fecha, ter_cierrey, ter_estado, ter_notas, ter_cerradopor)
      values (p_local, p_term, p_fecha, 1, -1, v_glosa_y, p_usuario);
      o_msg := 'Grabado: Z + Y1 automatica (copia de la Z)';
    else
      -- 5b) Cada Y: libvta 'Y' / N + zzz + termstaty -1
      for i in 1 .. v_lin_y.count loop
        v_boli   := 0;
        v_nrollo := 0;
        if v_boli_y.exists(v_nro_y(i)) then
          v_boli   := v_boli_y(v_nro_y(i));
          v_nrollo := v_roll_y(v_nro_y(i));
        end if;
        v_tk := fn_techkey;
        pr_ins_libvta(p_carga, v_lin_y(i), 'Y', v_nro_y(i), v_boli, v_nrollo, v_tk);
        pr_ins_zzz(p_carga, v_lin_y(i), p_fecha, v_tk);
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
      o_msg := 'Grabado: Z + ' || v_lin_y.count || ' Y (numeros ' || v_min || ' a ' || v_max || ')';
    end if;

    -- 6) Cuadratura en la base (lo mismo que valido Buscar con el archivo)
    pr_valida_base(p_fecha, p_local, p_term, true);

    if v_ant_z + v_ant_y > 0 then
      o_msg := o_msg || '. Reemplazo lo anterior: ' || v_ant_z || ' Z y ' || v_ant_y || ' Y';
    end if;
  end pr_graba_ingresar;

  -- ------------------------------------------------------------------
  -- MODIFICAR: cambia solo los conceptos informados de cierres existentes
  -- ------------------------------------------------------------------
  procedure pr_graba_modificar (p_carga   in  number,
                                p_fecha   in  date,
                                p_local   in  number,
                                p_term    in  number,
                                o_msg     out varchar2) is
    v_n       number;
    v_tk      number;
    v_tiporeg varchar2(3);
    v_sec     number;
    v_bol     number;
    v_ncr     number;
    v_fac     number;
    v_ndb     number;
    v_guia    number;
    v_sql     varchar2(32767);
    v_cant_z  number := 0;
    v_cant_y  number := 0;
    v_cant_c  number;
    v_tot_c   number := 0;
    v_zzz     VTA_SFCLZZZ%rowtype;
  begin
    select count(*) into v_n
      from VTA_SFCLTERMSTAT
     where ter_local = p_local and ter_terminal = p_term and ter_fecha = p_fecha
       and ter_estado in (1, 2);
    if v_n > 0 then
      raise_application_error(-20010,
        'El terminal esta cerrado ese dia (termstat estado 1 o 2); no se modifica');
    end if;

    for r in (select det_linea, det_tipo, det_nro_y
                from VTA_SFCLCARGA_YZ_DET
               where det_carga = p_carga and det_fecha = p_fecha and det_local = p_local
                 and det_terminal = p_term and det_estado = 'OK'
               order by det_linea) loop
      if r.det_tipo = 'Z' then
        v_tiporeg := 'F8';
        v_sec     := 99;
      else
        v_tiporeg := 'Y';
        v_sec     := r.det_nro_y;
        select count(*) into v_n
          from VTA_SFCLTERMSTATY
         where ter_local = p_local and ter_terminal = p_term and ter_fecha = p_fecha
           and ter_cierrey = v_sec and ter_estado in (1, 2);
        if v_n > 0 then
          raise_application_error(-20010,
            'La Y ' || v_sec || ' esta cerrada (termstaty estado 1 o 2); no se modifica');
        end if;
      end if;

      select count(*), max(vta_techkey) into v_n, v_tk
        from VTA_SFCLLIBVTA
       where vta_fecha_venta = p_fecha and vta_local = p_local and vta_terminal = p_term
         and vta_tiporeg = v_tiporeg and vta_secuencia = v_sec;
      if v_n = 0 then
        raise_application_error(-20011,
          'Linea ' || r.det_linea || ': no existe el cierre ' || v_tiporeg || ' ' || v_sec);
      elsif v_n > 1 then
        raise_application_error(-20011,
          'Linea ' || r.det_linea || ': hay ' || v_n || ' registros ' || v_tiporeg || ' ' || v_sec
          || ' en libvta; no se modifica');
      end if;

      -- libvta: conceptos de venta informados y su total
      v_bol  := fn_venta(p_carga, r.det_linea, 1);
      v_ncr  := fn_venta(p_carga, r.det_linea, 2);
      v_fac  := fn_venta(p_carga, r.det_linea, 3);
      v_ndb  := fn_venta(p_carga, r.det_linea, 4);
      v_guia := fn_venta(p_carga, r.det_linea, 5);
      -- Solo si viene algun concepto de venta: si no, vta_totalvta no se recalcula
      if coalesce(v_bol, v_ncr, v_fac, v_ndb, v_guia) is not null then
      update VTA_SFCLLIBVTA
         set vta_montobol  = nvl(v_bol,  vta_montobol),
             vta_montoncr  = nvl(v_ncr,  vta_montoncr),
             vta_montofac  = nvl(v_fac,  vta_montofac),
             vta_mmontondb = nvl(v_ndb,  vta_mmontondb),
             vta_montoguia = nvl(v_guia, vta_montoguia),
             vta_totalvta  = nvl(v_bol,  nvl(vta_montobol, 0))
                           + nvl(v_ncr,  nvl(vta_montoncr, 0))
                           + nvl(v_fac,  nvl(vta_montofac, 0))
                           + nvl(v_ndb,  nvl(vta_mmontondb, 0))
                           + nvl(v_guia, nvl(vta_montoguia, 0))
       where vta_fecha_venta = p_fecha and vta_local = p_local and vta_terminal = p_term
         and vta_tiporeg = v_tiporeg and vta_secuencia = v_sec;
      end if;

      -- zzz: solo los conceptos informados
      v_sql := PKG_F8_CARGA_MASIVA_YZ_SFCL.fn_sql_upd_zzz(p_carga, r.det_linea);
      if v_sql is not null then
        if v_tk is null then
          raise_application_error(-20011,
            'Linea ' || r.det_linea || ': el cierre ' || v_tiporeg || ' ' || v_sec
            || ' no tiene techkey; no se pueden modificar sus conceptos de zzz');
        end if;
        execute immediate v_sql using p_carga, r.det_linea, v_tk;
        if sql%rowcount = 0 then
          raise_application_error(-20011,
            'Linea ' || r.det_linea || ': el cierre ' || v_tiporeg || ' ' || v_sec
            || ' no tiene fila en VTA_SFCLZZZ (techkey ' || v_tk || ')');
        end if;
        -- TRG_VTA_SFCLZZZ_I es solo BEFORE INSERT: en una Y actualiza
        -- VTA_SFCLTARJ (2001 rec_mtransbank, 2002 rec_msodimac) y el
        -- movimiento 'AL' (rec_mtotalpeso). Para que tome los montos nuevos,
        -- la fila de la Y se borra y se vuelve a insertar igual (Form19Y la
        -- regraba con INSERT). La Z NO: su insert borra las TARJ y 'AL' de
        -- todo el dia; se queda con el UPDATE.
        if r.det_tipo = 'Y' then
          select * into v_zzz from VTA_SFCLZZZ where rec_techkey = v_tk;
          delete from VTA_SFCLZZZ where rec_techkey = v_tk;
          insert into VTA_SFCLZZZ values v_zzz;
        end if;
      end if;

      select count(*) into v_cant_c
        from VTA_SFCLCARGA_YZ_DETM
       where dtm_carga = p_carga and dtm_linea = r.det_linea;
      v_tot_c := v_tot_c + v_cant_c;
      if r.det_tipo = 'Z' then
        v_cant_z := v_cant_z + 1;
      else
        v_cant_y := v_cant_y + 1;
      end if;
    end loop;

    if v_cant_z + v_cant_y = 0 then
      raise_application_error(-20011, 'El grupo no tiene lineas para modificar');
    end if;

    -- Cuadratura del resultado (base + cambios); la formula, si cambio la Z
    pr_valida_base(p_fecha, p_local, p_term, v_cant_z > 0);

    o_msg := 'Modificado: ' || v_cant_z || ' Z y ' || v_cant_y || ' Y ('
             || v_tot_c || ' concepto(s))';
  end pr_graba_modificar;

  -- ------------------------------------------------------------------
  -- API
  -- ------------------------------------------------------------------
  procedure prc_graba (p_flg_pais     in  varchar2,
                       p_carga        in  number,
                       p_usuario      in  varchar2,
                       o_grupos_ok    out number,
                       o_grupos_error out number) is
    type t_fec is table of date index by pls_integer;
    type t_tc  is table of varchar2(20) index by pls_integer;
    v_fechas  t_fec;
    v_locales t_num;
    v_terms   t_num;
    v_tcargas t_tc;
    v_usuario varchar2(50);
    v_msg     varchar2(1000);
    v_grupo   varchar2(200);
    v_ok      boolean := false;   -- prc_config acepto el pais
    e_tomado  exception;
  begin
    o_grupos_ok    := 0;
    o_grupos_error := 0;
    PKG_F8_CARGA_MASIVA_YZ_SFCL.prc_config(p_flg_pais, true);   -- valida pais y relee VTA_PAINT_Z
    v_ok := true;
    v_usuario := nvl(p_usuario, fn_usuario(p_carga));
    commit;

    select res_fecha, res_local, res_terminal, res_tipo_carga
      bulk collect into v_fechas, v_locales, v_terms, v_tcargas
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
        -- Toma el grupo (si otra sesion lo esta grabando, espera y lo omite)
        update VTA_SFCLCARGA_YZ_RES
           set res_fechahora = sysdate
         where res_carga = p_carga and res_fecha = v_fechas(g)
           and res_local = v_locales(g) and res_terminal = v_terms(g)
           and res_estado = PKG_F8_CARGA_MASIVA_YZ_SFCL.c_estado_ok;
        if sql%rowcount = 0 then
          raise e_tomado;
        end if;

        if v_tcargas(g) = 'MODIFICAR' then
          pr_graba_modificar(p_carga, v_fechas(g), v_locales(g), v_terms(g), v_msg);
        else
          pr_graba_ingresar(p_carga, v_fechas(g), v_locales(g), v_terms(g), v_usuario, v_msg);
        end if;

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
            v_msg := 'No se grabo: ' || substr(sqlerrm, 12);
          else
            v_msg := 'No se grabo (error Oracle): ' || sqlerrm;
          end if;
          rollback;   -- deshace todo lo del grupo
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
      if v_ok then
        prc_log(p_carga, null, 'ERROR', null, null, 'prc_graba: ' || sqlerrm, v_usuario);
      end if;
      raise;
  end prc_graba;

end PKG_F8_GRABA_MASIVA_YZ_SFCL;
/
