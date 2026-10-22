-- =====================================================================
-- FSCC-12901 T1 + T2 (carpeta consolidada) - Paso 06
-- Cuerpo T1 PKG_F8_FACO_COMPENSA_DI (usa la especificacion de T2)
-- Fuente: docs/sql/FSCC-12957/04_pkg_compensa_di_body.sql (mantener ambas copias iguales)
-- =====================================================================

-- =====================================================================
-- FSCC-12957 (HU-01-T1) Compensacion automatica de DI - Falabella Colombia
-- 04 - Cuerpo de PKG_F8_FACO_COMPENSA_DI   (Oracle 10.2)
--
-- Flujo "Proceso 1 - Compensacion automatica de DI" (FSCC-12901):
--   cierre Y de la carga o sin sobres del mismo local-dia
--   (VTA_FACOV_CAJAS_CIERRE) -> calcular DR (logica de cuadratura F8)
--   -> DR = 0 ?            si: sin DI, pasa al Proceso 2        (DR_CERO)
--   -> min <= DR <= max ?  no: pendiente gestion de tiendas     (FUERA_RANGO)
--   -> ya tiene DI auto ?  si: pendiente revision (DUD-050)     (DI_AUTO_PREVIA)
--   -> ya tiene DI manual? si: pendiente revision del analista  (DI_MANUAL_PREVIA)
--   -> registrar DI = DR (mismo signo), fecha contable = fecha de venta,
--      usuario de proceso + glosa fija                          (DI_REGISTRADA)
-- =====================================================================

create or replace package body PKG_F8_FACO_COMPENSA_DI as

  g_ejecucion  number;
  g_usuario    varchar2(50) := c_usuario_di;

  e_ocupada    exception;
  pragma exception_init(e_ocupada, -54);   -- ORA-00054 (NOWAIT)

  -- ---------------------------------------------------------------
  -- Log en VTA_FACOLOG_CIERRE_AUTO (FSCC-12958) con log_proceso = 'T1'
  -- ---------------------------------------------------------------
  procedure pr_log (p_fecha     in date,
                    p_local     in number,
                    p_terminal  in number,
                    p_cierrey   in number,
                    p_dif_real  in number,
                    p_resultado in varchar2,
                    p_mensaje   in varchar2) is
    pragma autonomous_transaction;
  begin
    insert into VTA_FACOLOG_CIERRE_AUTO
      (log_id, log_ejecucion, log_proceso, log_nivel, log_fecha_vta, log_local,
       log_terminal, log_cierrey, log_dif_real, log_resultado, log_regla,
       log_mensaje, log_usuario, log_fechahora)
    values
      (SEQ_VTA_FACOLOG_CIERRE_AUTO.nextval, nvl(g_ejecucion, 0), 'T1',
       case when p_fecha is null then '-' else 'Y' end,
       p_fecha, p_local, p_terminal, p_cierrey, p_dif_real, p_resultado, null,
       substr(p_mensaje, 1, 1000), g_usuario, sysdate);
    commit;
  end pr_log;

  function fn_num_param (p_codigo in varchar2, p_default in number) return number is
  begin
    return to_number(PKG_F8_FACO_CIERRE_AUTO.fn_param(p_codigo, to_char(p_default)));
  end fn_num_param;

  -- ---------------------------------------------------------------
  -- DI ya registradas en el cierre Y (cualquier mov_rol)
  -- ---------------------------------------------------------------
  function fn_estado_di (p_fecha    in date,
                         p_local    in number,
                         p_terminal in number,
                         p_cierrey  in number) return varchar2 is
    v_total number;
    v_auto  number;
  begin
    select count(*),
           nvl(sum(case when m.mov_hechopor in (c_usuario_di, g_usuario) then 1 else 0 end), 0)
      into v_total, v_auto
      from VTA_FACOMOVDET m
     where m.mov_fecha    = p_fecha
       and m.mov_local    = p_local
       and m.mov_terminal = p_terminal
       and m.mov_cierrey  = p_cierrey
       and m.mov_tipomov  = 'DI';

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
  function fn_evalua_caja (p_fecha    in  date,
                           p_local    in  number,
                           p_terminal in  number,
                           p_cierrey  in  number,
                           o_dif_real out number) return varchar2 is
    v_min    number := fn_num_param('CA_DI_MIN', -1000);
    v_max    number := fn_num_param('CA_DI_MAX', 20000);
    v_estado varchar2(10);
  begin
    -- Base: Diferencia Real de la F8 (Label70 de Form3Y), despues de las
    -- compensaciones ya registradas (dotaciones, billetes falsos, etc.)
    o_dif_real := PKG_F8_FACO_CIERRE_AUTO.fn_dif_real(p_fecha, p_local, p_terminal, p_cierrey);

    if o_dif_real is null then
      return 'SIN_LIBVTA';
    elsif o_dif_real = 0 then
      return 'DR_CERO';
    elsif o_dif_real < v_min or o_dif_real > v_max then   -- limites inclusivos
      return 'FUERA_RANGO';
    end if;

    v_estado := fn_estado_di(p_fecha, p_local, p_terminal, p_cierrey);
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
    -- venta (fecha contable = fecha de venta), techkey SEQ_VTA_FACOVEN.
    -- MOV_NOMEMPLEADO / MOV_EMPEMPLEADO toman su default (' ').
    insert into VTA_FACOMOVDET
      (mov_fecha, mov_local, mov_terminal, mov_tipomov, mov_rol, mov_nombre,
       mov_secuencia, mov_numero, mov_monto, mov_hechopor, mov_regul,
       mov_fechareg, mov_techkey, mov_cierrey)
    values
      (p_fecha, p_local, p_terminal, 'DI', 0, ' ',
       0, 0, round(p_monto, 2), g_usuario, 'S',
       p_fecha, SEQ_VTA_FACOVEN.nextval, p_cierrey);

    -- Glosa fija (Form45: una observacion por caja / concepto / Y, en mayusculas)
    update VTA_FACOCOMPDES c
       set c.cpd_obs = c_glosa_di
     where c.cpd_fecha    = p_fecha
       and c.cpd_local    = p_local
       and c.cpd_terminal = p_terminal
       and c.cpd_tipmov   = 'DI'
       and c.cpd_cierrey  = p_cierrey;

    if sql%rowcount = 0 then
      -- cpd_secuencia la asigna TRG_VTA_FACOCOMPDES_I_SEQ
      insert into VTA_FACOCOMPDES (cpd_fecha, cpd_local, cpd_terminal, cpd_tipmov, cpd_obs, cpd_cierrey)
      values (p_fecha, p_local, p_terminal, 'DI', c_glosa_di, p_cierrey);
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
      select t.ter_estado
        into v_estado
        from VTA_FACOTERMSTATY t
       where t.ter_fecha = p_fecha and t.ter_local = p_local
         and t.ter_terminal = p_terminal and t.ter_cierrey = p_cierrey
         for update nowait;
    exception
      when no_data_found then
        pr_log(p_fecha, p_local, p_terminal, p_cierrey, null, 'SIN_TERMSTAT',
               'No existe el cierre Y en VTA_FACOTERMSTATY');
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

    v_resultado := fn_evalua_caja(p_fecha, p_local, p_terminal, p_cierrey, v_dr);

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
    v_dr2 := PKG_F8_FACO_CIERRE_AUTO.fn_dif_real(p_fecha, p_local, p_terminal, p_cierrey);
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
  procedure prc_compensa_di (p_ejecucion in number   default null,
                             p_usuario   in varchar2 default 'PROC_DI_AUTO',
                             p_max_cajas in number   default null) is
    v_dias number;
    v_n    number := 0;
  begin
    g_usuario := nvl(substr(p_usuario, 1, 50), c_usuario_di);
    if p_ejecucion is null then
      select SEQ_VTA_FACOLOG_CIERRE_AUTO.nextval into g_ejecucion from dual;
    else
      g_ejecucion := p_ejecucion;
    end if;

    if PKG_F8_FACO_CIERRE_AUTO.fn_param('CA_DI_ACTIVO', 'N') <> 'S' then
      pr_log(null, null, null, null, null, 'INACTIVO', 'Parametro 1502 CA_DI_ACTIVO distinto de S');
      return;
    end if;

    v_dias := fn_num_param('CA_DIAS', 30);
    pr_log(null, null, null, null, null, 'INICIO',
           'Rango [' || fn_num_param('CA_DI_MIN', -1000) || ', ' || fn_num_param('CA_DI_MAX', 20000) ||
           '] usuario ' || g_usuario);

    -- Cajas de la carga: universo comun VTA_FACOV_CAJAS_CIERRE (FSCC-12958):
    -- cierres Y pendientes de la cola + cajas sin sobres del mismo local-dia
    -- (CA_SIN_SOBRE). Son las mismas que despues evalua T2. La cola NO se
    -- modifica aqui.
    -- CK: FSCC-12901 - antes recorria VTA_FACOPRD_CIERRE (pcr_estado P, prv_cierrey <> 0).
    for c in (select v.cc_fecha f, v.cc_local l, v.cc_terminal t, v.cc_cierrey y
                from VTA_FACOV_CAJAS_CIERRE v
               where v.cc_fecha >= trunc(sysdate) - v_dias
               order by 1, 2, 3, 4) loop
      exit when p_max_cajas is not null and v_n >= p_max_cajas;
      v_n := v_n + 1;
      pr_procesa_caja(c.f, c.l, c.t, c.y);
    end loop;

    pr_log(null, null, null, null, null, 'FIN', 'Cajas evaluadas: ' || v_n);
  exception
    when others then
      rollback;
      pr_log(null, null, null, null, null, 'ERROR', substr(sqlerrm, 1, 1000));
      raise;
  end prc_compensa_di;

end PKG_F8_FACO_COMPENSA_DI;
/
