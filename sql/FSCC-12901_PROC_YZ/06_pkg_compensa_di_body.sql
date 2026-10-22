-- =====================================================================
-- FSCC-12901 v2 MULTIPAIS - Paso 06
-- Cuerpo de PKG_F8_COMPENSA_DI_AUTO   (Oracle 10.2)
--
-- Misma logica que v1 (PKG_F8_FACO_COMPENSA_DI). Las tablas se resuelven con
-- PKG_F8_CIERRE_AUTO.fn_tabla (prefijo del pais) y el log se escribe con
-- PKG_F8_CIERRE_AUTO.pr_registra_log (VTA_<pfx>LOG_CIERRE_AUTO).
--
-- Flujo "Proceso 1 - Compensacion automatica de DI" (FSCC-12901):
--   cierre Y de la carga o sin sobres del mismo local-dia
--   (PKG_F8_CIERRE_AUTO.fn_universo) -> calcular DR (logica de cuadratura F8)
--   -> DR = 0 ?            si: sin DI, pasa al Proceso 2        (DR_CERO)
--   -> min <= DR <= max ?  no: pendiente gestion de tiendas     (FUERA_RANGO)
--   -> ya tiene DI auto ?  si: pendiente revision (DUD-050)     (DI_AUTO_PREVIA)
--   -> ya tiene DI manual? si: pendiente revision del analista  (DI_MANUAL_PREVIA)
--   -> registrar DI = DR (mismo signo), fecha contable = fecha de venta,
--      usuario de proceso + glosa fija                          (DI_REGISTRADA)
-- =====================================================================

create or replace package body PKG_F8_COMPENSA_DI_AUTO as

  g_pais       varchar2(10);
  g_ejecucion  number;
  g_usuario    varchar2(50) := c_usuario_di;

  e_ocupada    exception;
  pragma exception_init(e_ocupada, -54);   -- ORA-00054 (NOWAIT)

  -- Nombre real de una tabla del pais en curso
  function fn_t (p_base in varchar2) return varchar2 is
  begin
    return PKG_F8_CIERRE_AUTO.fn_tabla(g_pais, p_base);
  end fn_t;

  -- ---------------------------------------------------------------
  -- Log en VTA_<pfx>LOG_CIERRE_AUTO con log_proceso = 'T1'
  -- ---------------------------------------------------------------
  procedure pr_log (p_fecha     in date,
                    p_local     in number,
                    p_terminal  in number,
                    p_cierrey   in number,
                    p_dif_real  in number,
                    p_resultado in varchar2,
                    p_mensaje   in varchar2) is
  begin
    PKG_F8_CIERRE_AUTO.pr_registra_log(g_pais, g_ejecucion, 'T1',
                                       case when p_fecha is null then '-' else 'Y' end,
                                       p_fecha, p_local, p_terminal, p_cierrey, p_dif_real,
                                       p_resultado, null, p_mensaje, g_usuario);
  end pr_log;

  function fn_num_param (p_codigo in varchar2, p_default in number) return number is
  begin
    return to_number(PKG_F8_CIERRE_AUTO.fn_param(g_pais, p_codigo, to_char(p_default)));
  end fn_num_param;

  -- ---------------------------------------------------------------
  -- DI ya registradas en el cierre Y (cualquier mov_rol)
  -- ---------------------------------------------------------------
  function fn_estado_di (p_flg_pais in varchar2,
                         p_fecha    in date,
                         p_local    in number,
                         p_terminal in number,
                         p_cierrey  in number) return varchar2 is
    v_total number;
    v_auto  number;
  begin
    g_pais := upper(trim(p_flg_pais));
    execute immediate
      'select count(*),
              nvl(sum(case when m.mov_hechopor in (:1, :2) then 1 else 0 end), 0)
         from ' || fn_t('MOVDET') || ' m
        where m.mov_fecha    = :3
          and m.mov_local    = :4
          and m.mov_terminal = :5
          and m.mov_cierrey  = :6
          and m.mov_tipomov  = ''DI'''
      into v_total, v_auto
      using c_usuario_di, g_usuario, p_fecha, p_local, p_terminal, p_cierrey;

    if v_auto > 0 then
      return 'AUTO';
    elsif v_total > 0 then
      return 'MANUAL';
    end if;
    return 'NINGUNA';
  end fn_estado_di;

  -- ---------------------------------------------------------------
  -- Evaluacion de una caja sin grabar (reglas de FSCC-12957)
  -- ---------------------------------------------------------------
  function fn_evalua_caja (p_flg_pais in  varchar2,
                           p_fecha    in  date,
                           p_local    in  number,
                           p_terminal in  number,
                           p_cierrey  in  number,
                           o_dif_real out number) return varchar2 is
    v_min    number;
    v_max    number;
    v_estado varchar2(10);
  begin
    g_pais := upper(trim(p_flg_pais));
    v_min  := fn_num_param('CA_DI_MIN', -1000);
    v_max  := fn_num_param('CA_DI_MAX', 20000);

    -- Base: Diferencia Real de la F8 (Label70 de Form3Y), despues de las
    -- compensaciones ya registradas (dotaciones, billetes falsos, etc.)
    o_dif_real := PKG_F8_CIERRE_AUTO.fn_dif_real(g_pais, p_fecha, p_local, p_terminal, p_cierrey);

    if o_dif_real is null then
      return 'SIN_LIBVTA';
    elsif o_dif_real = 0 then
      return 'DR_CERO';
    elsif o_dif_real < v_min or o_dif_real > v_max then   -- limites inclusivos
      return 'FUERA_RANGO';
    end if;

    v_estado := fn_estado_di(g_pais, p_fecha, p_local, p_terminal, p_cierrey);
    if v_estado = 'AUTO' then
      return 'DI_AUTO_PREVIA';
    elsif v_estado = 'MANUAL' then
      return 'DI_MANUAL_PREVIA';
    end if;
    return 'COMPENSABLE';
  end fn_evalua_caja;

  -- ---------------------------------------------------------------
  -- Registro de la DI (replica InsertarRegistroMovDet + Form45.GrabarObs)
  -- ---------------------------------------------------------------
  procedure pr_registra_di (p_fecha in date, p_local in number, p_terminal in number,
                            p_cierrey in number, p_monto in number) is
  begin
    -- Modulo1.InsertarRegistroMovDet: mov_rol 0, mov_nombre ' ', mov_secuencia 0,
    -- mov_numero 0, monto redondeado a 2, MOV_REGUL 'S', MOV_FECHAREG = fecha de
    -- venta (fecha contable = fecha de venta), techkey con la secuencia del pais
    -- ({SEQMOV}; FACO: SEQ_VTA_FACOVEN).
    -- MOV_NOMEMPLEADO / MOV_EMPEMPLEADO toman su default (' ').
    execute immediate PKG_F8_CIERRE_AUTO.fn_sql(g_pais,
      q'[insert into VTA_{P}MOVDET
           (mov_fecha, mov_local, mov_terminal, mov_tipomov, mov_rol, mov_nombre,
            mov_secuencia, mov_numero, mov_monto, mov_hechopor, mov_regul,
            mov_fechareg, mov_techkey, mov_cierrey)
         values
           (:1, :2, :3, 'DI', 0, ' ',
            0, 0, :4, :5, 'S',
            :6, {SEQMOV}.nextval, :7)]')
      using p_fecha, p_local, p_terminal, round(p_monto, 2), g_usuario, p_fecha, p_cierrey;

    -- Glosa fija (Form45: una observacion por caja / concepto / Y, en mayusculas)
    execute immediate
      'update ' || fn_t('COMPDES') || ' c
          set c.cpd_obs = :1
        where c.cpd_fecha    = :2
          and c.cpd_local    = :3
          and c.cpd_terminal = :4
          and c.cpd_tipmov   = ''DI''
          and c.cpd_cierrey  = :5'
      using c_glosa_di, p_fecha, p_local, p_terminal, p_cierrey;

    if sql%rowcount = 0 then
      -- cpd_secuencia la asigna el trigger de la tabla (FACO: TRG_VTA_FACOCOMPDES_I_SEQ)
      execute immediate
        'insert into ' || fn_t('COMPDES') || '
           (cpd_fecha, cpd_local, cpd_terminal, cpd_tipmov, cpd_obs, cpd_cierrey)
         values (:1, :2, :3, ''DI'', :4, :5)'
        using p_fecha, p_local, p_terminal, c_glosa_di, p_cierrey;
    end if;
  end pr_registra_di;

  -- ---------------------------------------------------------------
  -- Proceso de una caja (cierre Y)
  -- ---------------------------------------------------------------
  procedure pr_procesa_caja (p_fecha in date, p_local in number, p_terminal in number,
                             p_cierrey in number) is
    v_estado    number;
    v_resultado varchar2(30);
    v_dr        number;
    v_dr2       number;
    v_msg       varchar2(1000);
  begin
    savepoint sp_di;

    -- La caja debe existir y estar abierta (Form38 no permite DI en caja cerrada)
    begin
      execute immediate
        'select t.ter_estado
           from ' || fn_t('TERMSTATY') || ' t
          where t.ter_fecha = :1 and t.ter_local = :2
            and t.ter_terminal = :3 and t.ter_cierrey = :4
            for update nowait'
        into v_estado
        using p_fecha, p_local, p_terminal, p_cierrey;
    exception
      when no_data_found then
        pr_log(p_fecha, p_local, p_terminal, p_cierrey, null, 'SIN_TERMSTAT',
               'No existe el cierre Y en ' || fn_t('TERMSTATY'));
        return;
      when e_ocupada then
        pr_log(p_fecha, p_local, p_terminal, p_cierrey, null, 'OCUPADA',
               'Caja bloqueada por otro usuario');
        return;
    end;

    if v_estado > 0 then
      rollback to sp_di;
      pr_log(p_fecha, p_local, p_terminal, p_cierrey, null, 'YA_CERRADA',
             'Caja cerrada (estado ' || v_estado || '): no se registra DI');
      return;
    end if;

    v_resultado := fn_evalua_caja(g_pais, p_fecha, p_local, p_terminal, p_cierrey, v_dr);

    if v_resultado <> 'COMPENSABLE' then
      rollback to sp_di;
      v_msg := case v_resultado
                 when 'DR_CERO'          then 'Diferencia real 0: sin DI, pasa al cierre (T2)'
                 when 'FUERA_RANGO'      then 'Diferencia real fuera del rango [' ||
                                              fn_num_param('CA_DI_MIN', -1000) || ', ' ||
                                              fn_num_param('CA_DI_MAX', 20000) ||
                                              ']: pendiente para gestion de tiendas'
                 when 'DI_AUTO_PREVIA'   then 'La caja ya tiene una DI automatica de una carga anterior: revision del analista (DUD-050)'
                 when 'DI_MANUAL_PREVIA' then 'La caja ya tiene una DI registrada por el analista: revision del analista'
                 when 'SIN_LIBVTA'       then 'No hay Z disponible (sin libro de ventas de la Y)'
               end;
      pr_log(p_fecha, p_local, p_terminal, p_cierrey, v_dr, v_resultado, v_msg);
      return;
    end if;

    -- Registrar DI = DR con el mismo signo (DR -22 -> DI -22)
    pr_registra_di(p_fecha, p_local, p_terminal, p_cierrey, v_dr);

    -- Control: con la DI registrada la diferencia real debe quedar en 0
    v_dr2 := PKG_F8_CIERRE_AUTO.fn_dif_real(g_pais, p_fecha, p_local, p_terminal, p_cierrey);
    if nvl(v_dr2, 1) <> 0 then
      rollback to sp_di;
      pr_log(p_fecha, p_local, p_terminal, p_cierrey, v_dr, 'ERROR',
             'La diferencia real no quedo en 0 despues de registrar la DI (antes ' ||
             v_dr || ', despues ' || nvl(to_char(v_dr2), 'null') || '): DI revertida');
      return;
    end if;

    commit;
    pr_log(p_fecha, p_local, p_terminal, p_cierrey, v_dr, 'DI_REGISTRADA',
           'DI automatica por ' || v_dr || '; diferencia real queda en 0');

  exception
    when others then
      v_msg := substr(sqlerrm, 1, 1000);
      begin
        rollback to sp_di;
      exception
        when others then rollback;
      end;
      pr_log(p_fecha, p_local, p_terminal, p_cierrey, null, 'ERROR', v_msg);
  end pr_procesa_caja;

  -- ---------------------------------------------------------------
  -- Punto de entrada de T1
  -- ---------------------------------------------------------------
  procedure prc_compensa_di (p_flg_pais  in varchar2,
                             p_ejecucion in number   default null,
                             p_usuario   in varchar2 default 'PROC_DI_AUTO',
                             p_max_cajas in number   default null) is
    v_cur sys_refcursor;
    v_f   date;
    v_l   number;
    v_t   number;
    v_y   number;
    v_n   number := 0;
  begin
    g_pais    := upper(trim(p_flg_pais));
    g_usuario := nvl(substr(p_usuario, 1, 50), c_usuario_di);
    if p_ejecucion is null then
      g_ejecucion := PKG_F8_CIERRE_AUTO.fn_nueva_ejecucion(g_pais);   -- valida el pais
    else
      g_ejecucion := p_ejecucion;
    end if;

    if PKG_F8_CIERRE_AUTO.fn_param(g_pais, 'CA_DI_ACTIVO', 'N') <> 'S' then
      pr_log(null, null, null, null, null, 'INACTIVO', 'Parametro 1502 CA_DI_ACTIVO distinto de S');
      return;
    end if;

    pr_log(null, null, null, null, null, 'INICIO',
           'Pais ' || g_pais || ' | rango [' || fn_num_param('CA_DI_MIN', -1000) || ', ' ||
           fn_num_param('CA_DI_MAX', 20000) || '] | usuario ' || g_usuario);

    -- Cajas de la carga: mismo universo que despues evalua T2 (cola de la
    -- ejecucion + cajas sin sobres del mismo local-dia). La cola NO se
    -- modifica aqui.
    v_cur := PKG_F8_CIERRE_AUTO.fn_universo(g_pais, p_ejecucion);
    loop
      fetch v_cur into v_f, v_l, v_t, v_y;
      exit when v_cur%notfound;
      exit when p_max_cajas is not null and v_n >= p_max_cajas;
      v_n := v_n + 1;
      pr_procesa_caja(v_f, v_l, v_t, v_y);
    end loop;
    close v_cur;

    pr_log(null, null, null, null, null, 'FIN', 'Cajas evaluadas: ' || v_n);
  exception
    when others then
      if v_cur%isopen then
        close v_cur;
      end if;
      rollback;
      pr_log(null, null, null, null, null, 'ERROR', substr(sqlerrm, 1, 1000));
      raise;
  end prc_compensa_di;

end PKG_F8_COMPENSA_DI_AUTO;
/
