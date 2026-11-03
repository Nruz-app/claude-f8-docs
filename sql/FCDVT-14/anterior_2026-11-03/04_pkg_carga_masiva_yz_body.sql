-- =====================================================================
-- FCDVT-14 - Paso 04
-- Cuerpo de PKG_F8_CARGA_MASIVA_YZ   (Oracle 10.2)
-- Habilitado: FACO
-- xintec-nruz 30-10-2026
--
-- Validaciones por linea (prc_inserta_linea, etapa LECTURA):
--   - 56 campos (se tolera un ; final);
--   - FECHA dd-mm-yyyy valida y anterior a hoy;
--   - LOCAL, TERMINAL, SECUENCIA, NUM_BOLETA, VENDEDOR, CONT_REPOSICION:
--     obligatorios y enteros; NRO_Y opcional y entero;
--   - HORA HH:MM (24 h);
--   - TIPO Y o Z; TIPO_CARGA = INGRESAR (MODIFICAR aun no se habilita);
--   - montos enteros (vacio = 0), como en FORMATO_CARGA_Y_FACO.md.
-- Validaciones contra la base (prc_procesa, etapa VALIDACION):
--   - local y terminal vigentes a la FECHA de la fila (misma consulta que
--     Form19Y.Oklt sobre vta_FACOterminales);
--   - NRO_Y repetido dentro del archivo para el mismo terminal-dia.
-- Resumen por fecha / local / terminal (prc_procesa, etapa RESUMEN):
--   ERROR si tiene filas con error, si no tiene exactamente 1 Z, si no tiene
--   Y o si el TOTAL de la Z (BOLETAS + N.CREDITO + FACTURA) es distinto de la
--   suma de los TOTALES de las Y. En otro caso, PROCESADO.
-- Fuera de alcance (lo hara Cargar): Z cerrada (Est_TermStat), NRO_Y ya
-- existente en la base y el grabado en libvta / zzz / termstat(y).
-- =====================================================================

create or replace package body PKG_F8_CARGA_MASIVA_YZ as

  type t_montos is table of number index by pls_integer;

  -- ------------------------------------------------------------------
  -- Log (transaccion autonoma: queda aunque el proceso haga rollback)
  -- ------------------------------------------------------------------
  procedure prc_log (p_carga  in number,
                     p_linea  in number,
                     p_etapa  in varchar2,
                     p_campo  in varchar2,
                     p_valor  in varchar2,
                     p_motivo in varchar2,
                     p_usuario in varchar2 default null) is
    pragma autonomous_transaction;
    v_usuario varchar2(50) := p_usuario;
  begin
    if v_usuario is null then
      select max(log_usuario) into v_usuario
        from VTA_FACOCARGA_YZ_LOG
       where log_carga = p_carga
         and log_etapa = 'INICIO';
    end if;
    insert into VTA_FACOCARGA_YZ_LOG
      (log_id, log_carga, log_linea, log_etapa, log_campo, log_valor,
       log_motivo, log_usuario, log_fechahora)
    values
      (SEQ_VTA_FACOCARGA_YZ_LOG.nextval, p_carga, p_linea, p_etapa,
       substr(p_campo, 1, 30), substr(p_valor, 1, 200),
       substr(p_motivo, 1, 1000), v_usuario, sysdate);
    commit;
  end prc_log;

  function fn_usuario (p_carga in number) return varchar2 is
    v_usuario varchar2(50);
  begin
    select max(log_usuario) into v_usuario
      from VTA_FACOCARGA_YZ_LOG
     where log_carga = p_carga
       and log_etapa = 'INICIO';
    return v_usuario;
  end fn_usuario;

  -- ------------------------------------------------------------------
  -- Separacion de la linea
  -- ------------------------------------------------------------------
  function fn_ncampos (p_txt in varchar2) return pls_integer is
  begin
    return nvl(length(p_txt), 0) - nvl(length(replace(p_txt, ';')), 0) + 1;
  end fn_ncampos;

  -- Campo n (1..) de la linea, sin espacios; nulo si no existe
  function fn_campo (p_txt in varchar2, p_n in pls_integer) return varchar2 is
    v_ini pls_integer;
    v_fin pls_integer;
  begin
    if p_n = 1 then
      v_ini := 1;
    else
      v_ini := instr(p_txt, ';', 1, p_n - 1);
      if v_ini = 0 then
        return null;
      end if;
      v_ini := v_ini + 1;
    end if;
    v_fin := instr(p_txt, ';', 1, p_n);
    if v_fin = 0 then
      v_fin := nvl(length(p_txt), 0) + 1;
    end if;
    return trim(substr(p_txt, v_ini, v_fin - v_ini));
  end fn_campo;

  -- Nombre de la columna n del encabezado
  function fn_nombre (p_n in pls_integer) return varchar2 is
  begin
    return fn_campo(c_encabezado, p_n);
  end fn_nombre;

  -- ------------------------------------------------------------------
  -- Conversion con registro del error
  -- ------------------------------------------------------------------
  function fn_entero (p_carga  in number,
                      p_linea  in number,
                      p_n      in pls_integer,
                      p_valor  in varchar2,
                      p_oblig  in boolean,
                      p_vacio  in number,       -- valor si viene vacio y no es obligatorio
                      io_err   in out boolean) return number is
  begin
    if p_valor is null then
      if p_oblig then
        prc_log(p_carga, p_linea, 'LECTURA', fn_nombre(p_n), null, 'Campo obligatorio vacio');
        io_err := true;
      end if;
      return p_vacio;
    end if;
    if not regexp_like(p_valor, '^-?[0-9]{1,15}$') then
      prc_log(p_carga, p_linea, 'LECTURA', fn_nombre(p_n), p_valor,
              'No es un numero entero (sin separador de miles ni decimales)');
      io_err := true;
      return null;
    end if;
    return to_number(p_valor);
  end fn_entero;

  function fn_fecha (p_carga in number,
                     p_linea in number,
                     p_valor in varchar2,
                     io_err  in out boolean) return date is
    v_fecha date;
  begin
    if p_valor is null then
      prc_log(p_carga, p_linea, 'LECTURA', 'FECHA', null, 'Campo obligatorio vacio');
      io_err := true;
      return null;
    end if;
    if not regexp_like(p_valor, '^[0-9]{2}-[0-9]{2}-[0-9]{4}$') then
      prc_log(p_carga, p_linea, 'LECTURA', 'FECHA', p_valor, 'Formato distinto de dd-mm-yyyy');
      io_err := true;
      return null;
    end if;
    begin
      v_fecha := to_date(p_valor, 'dd-mm-yyyy');
    exception
      when others then
        prc_log(p_carga, p_linea, 'LECTURA', 'FECHA', p_valor, 'Fecha inexistente');
        io_err := true;
        return null;
    end;
    if v_fecha >= trunc(sysdate) then
      prc_log(p_carga, p_linea, 'LECTURA', 'FECHA', p_valor, 'La fecha debe ser anterior a hoy');
      io_err := true;
    end if;
    return v_fecha;
  end fn_fecha;

  function fn_hora (p_carga in number,
                    p_linea in number,
                    p_valor in varchar2,
                    io_err  in out boolean) return varchar2 is
    v_pos pls_integer;
  begin
    if p_valor is null then
      prc_log(p_carga, p_linea, 'LECTURA', 'HORA', null, 'Campo obligatorio vacio');
      io_err := true;
      return null;
    end if;
    if not regexp_like(p_valor, '^[0-9]{1,2}:[0-9]{2}$') then
      prc_log(p_carga, p_linea, 'LECTURA', 'HORA', p_valor, 'Formato distinto de HH:MM');
      io_err := true;
      return null;
    end if;
    v_pos := instr(p_valor, ':');
    if to_number(substr(p_valor, 1, v_pos - 1)) > 23
       or to_number(substr(p_valor, v_pos + 1)) > 59 then
      prc_log(p_carga, p_linea, 'LECTURA', 'HORA', p_valor, 'Hora fuera de rango (00:00 a 23:59)');
      io_err := true;
      return null;
    end if;
    return lpad(p_valor, 5, '0');
  end fn_hora;

  -- ------------------------------------------------------------------
  -- API
  -- ------------------------------------------------------------------
  procedure prc_inicia (p_flg_pais in  varchar2,
                        p_archivo  in  varchar2,
                        p_usuario  in  varchar2,
                        o_carga    out number) is
  begin
    if nvl(upper(p_flg_pais), '-') <> 'FACO' then
      raise_application_error(-20001,
        'PKG_F8_CARGA_MASIVA_YZ: pais no habilitado (' || p_flg_pais || ')');
    end if;
    select SEQ_VTA_FACOCARGA_YZ.nextval into o_carga from dual;
    prc_log(o_carga, null, 'INICIO', null, upper(p_flg_pais),
            'Archivo: ' || p_archivo, p_usuario);
  end prc_inicia;

  procedure prc_inserta_linea (p_carga in number,
                               p_linea in number,
                               p_texto in varchar2) is
    v_txt     varchar2(4000) := p_texto;
    v_n       pls_integer;
    v_err     boolean := false;
    v_fecha   date;
    v_local   number;
    v_term    number;
    v_nroy    number;
    v_hora    varchar2(5);
    v_sec     number;
    v_bol     number;
    v_vend    number;
    v_crepo   number;
    v_tipo    varchar2(4000);   -- largo del campo libre: se valida antes de grabarlo
    v_tcarga  varchar2(4000);
    v_total   number;
    m         t_montos;
  begin
    -- Se tolera un ; final
    if substr(v_txt, -1) = ';' and fn_ncampos(v_txt) = c_campos + 1 then
      v_txt := substr(v_txt, 1, length(v_txt) - 1);
    end if;

    -- Linea 1: encabezado de la plantilla (vacia tambien es error)
    if p_linea = 1 then
      if nvl(upper(trim(v_txt)), '-') <> upper(c_encabezado) then
        prc_log(p_carga, p_linea, 'LECTURA', 'ENCABEZADO', substr(v_txt, 1, 200),
                'El encabezado no es el de la plantilla de carga masiva (56 columnas, ver FORMATO_CARGA_Y_FACO.md)');
      end if;
      return;
    end if;

    -- Lineas vacias (o solo ;) se ignoran
    if trim(replace(v_txt, ';')) is null then
      return;
    end if;

    v_n := fn_ncampos(v_txt);
    if v_n <> c_campos then
      prc_log(p_carga, p_linea, 'LECTURA', 'LINEA', to_char(v_n),
              'La linea tiene ' || v_n || ' campos; deben ser ' || c_campos);
      insert into VTA_FACOCARGA_YZ_DET (det_carga, det_linea, det_texto, det_estado)
      values (p_carga, p_linea, substr(p_texto, 1, 4000), 'ERROR');
      commit;
      return;
    end if;

    -- Identificacion (columnas 1 a 11)
    v_fecha  := fn_fecha (p_carga, p_linea, fn_campo(v_txt, 1), v_err);
    v_local  := fn_entero(p_carga, p_linea, 2, fn_campo(v_txt, 2), true,  null, v_err);
    v_term   := fn_entero(p_carga, p_linea, 3, fn_campo(v_txt, 3), true,  null, v_err);
    v_nroy   := fn_entero(p_carga, p_linea, 4, fn_campo(v_txt, 4), false, null, v_err);
    v_hora   := fn_hora  (p_carga, p_linea, fn_campo(v_txt, 5), v_err);
    v_sec    := fn_entero(p_carga, p_linea, 6, fn_campo(v_txt, 6), true,  null, v_err);
    v_bol    := fn_entero(p_carga, p_linea, 7, fn_campo(v_txt, 7), true,  null, v_err);
    v_vend   := fn_entero(p_carga, p_linea, 8, fn_campo(v_txt, 8), true,  null, v_err);
    v_crepo  := fn_entero(p_carga, p_linea, 9, fn_campo(v_txt, 9), true,  null, v_err);

    v_tipo := upper(fn_campo(v_txt, 10));
    if v_tipo is null or v_tipo not in ('Y', 'Z') then
      prc_log(p_carga, p_linea, 'LECTURA', 'TIPO', v_tipo, 'Debe ser Y o Z');
      v_err  := true;
      v_tipo := null;
    end if;

    v_tcarga := upper(fn_campo(v_txt, 11));
    if v_tcarga is null or v_tcarga <> 'INGRESAR' then
      if v_tcarga = 'MODIFICAR' then
        prc_log(p_carga, p_linea, 'LECTURA', 'TIPO_CARGA', v_tcarga,
                'MODIFICAR todavia no esta habilitado; solo INGRESAR');
      else
        prc_log(p_carga, p_linea, 'LECTURA', 'TIPO_CARGA', v_tcarga, 'Debe ser INGRESAR');
      end if;
      v_err    := true;
      v_tcarga := substr(v_tcarga, 1, 20);
    end if;

    -- Montos (columnas 12 a 56): enteros, vacio = 0
    for i in 1 .. 45 loop
      m(i) := fn_entero(p_carga, p_linea, i + 11, fn_campo(v_txt, i + 11), false, 0, v_err);
    end loop;

    if m(1) is not null and m(2) is not null and m(3) is not null then
      v_total := m(1) + m(2) + m(3);
    end if;

    insert into VTA_FACOCARGA_YZ_DET
      (det_carga, det_linea, det_texto, det_fecha, det_local, det_terminal,
       det_nro_y, det_hora, det_secuencia, det_num_boleta, det_vendedor,
       det_cont_repo, det_tipo, det_tipo_carga,
       vta_montobol, vta_montoncr, vta_montofac, rec_mefectivo, rec_mrecaudaefec,
       rec_mchkdia, rec_mchkfecha, rec_mtarj, rec_msodimac, rec_mcmr,
       rec_mtregalo, rec_mtotconvenio, rec_mtraspasotde, rec_mrenueva, rec_mtotfacxcob,
       rec_mdotaciones, rec_mretiros, rec_mabonocmr, rec_mavancecmr, rec_mtotpreprenueva,
       rec_mtransferencia, rec_mreversatrans, rec_mretirotrans, rec_matrfefec, rec_matrfchk,
       rec_matrfcmr, rec_matrfdeb, rec_matrfcre, rec_mrevatottrf, rec_mrevatrfefec,
       rec_mrevatrfcmr, rec_mabonotde, rec_mtde, rec_msellosvrd, rec_mtotrecauda,
       rec_mtotrevrecauda, rec_mcanjepuntos, rec_mrevcanjepuntos, rec_mtotsif, rec_mrectercero,
       rec_mdevtercero, rec_mquickpaycmr, rec_mquickpaybco, rec_ecompay, rec_mpagopuntos,
       det_total, det_estado, det_fechahora)
    values
      (p_carga, p_linea, substr(p_texto, 1, 4000), v_fecha, v_local, v_term,
       v_nroy, v_hora, v_sec, v_bol, v_vend,
       v_crepo, v_tipo, v_tcarga,
       m(1),  m(2),  m(3),  m(4),  m(5),
       m(6),  m(7),  m(8),  m(9),  m(10),
       m(11), m(12), m(13), m(14), m(15),
       m(16), m(17), m(18), m(19), m(20),
       m(21), m(22), m(23), m(24), m(25),
       m(26), m(27), m(28), m(29), m(30),
       m(31), m(32), m(33), m(34), m(35),
       m(36), m(37), m(38), m(39), m(40),
       m(41), m(42), m(43), m(44), m(45),
       v_total, case when v_err then 'ERROR' else 'OK' end, sysdate);
    commit;
  exception
    when others then
      prc_log(p_carga, p_linea, 'ERROR', null, null, 'prc_inserta_linea: ' || sqlerrm);
      raise;
  end prc_inserta_linea;

  procedure prc_procesa (p_carga        in  number,
                         o_grupos_ok    out number,
                         o_grupos_error out number,
                         o_lin_error    out number) is
    v_usuario  varchar2(50);
    v_n        number;
    v_sin_grp  number;
    v_msg      varchar2(1000);
    v_err      varchar2(1000);
  begin
    o_grupos_ok    := 0;
    o_grupos_error := 0;
    o_lin_error    := 0;
    v_usuario      := fn_usuario(p_carga);

    -- Encabezado rechazado: no se procesa nada
    select count(*) into v_n
      from VTA_FACOCARGA_YZ_LOG
     where log_carga = p_carga
       and log_linea = 1
       and log_campo = 'ENCABEZADO';
    if v_n > 0 then
      prc_log(p_carga, null, 'FIN', null, null,
              'Carga rechazada: el encabezado no es el de la plantilla', v_usuario);
      return;
    end if;

    -- VALIDACION 1: local y terminal vigentes a la fecha (Form19Y.Oklt)
    for r in (select d.det_linea, d.det_fecha, d.det_local, d.det_terminal
                from VTA_FACOCARGA_YZ_DET d
               where d.det_carga = p_carga
                 and d.det_fecha is not null
                 and d.det_local is not null
                 and d.det_terminal is not null
                 and not exists (select 1
                                   from vta_FACOterminales t
                                  where t.ter_local    = d.det_local
                                    and t.ter_terminal = d.det_terminal
                                    and (t.ter_fechabaja >= d.det_fecha
                                         or t.ter_fechabaja is null))) loop
      prc_log(p_carga, r.det_linea, 'VALIDACION', 'TERMINAL',
              r.det_local || '-' || r.det_terminal,
              'Local / terminal no existe o no esta vigente al '
              || to_char(r.det_fecha, 'dd-mm-yyyy'), v_usuario);
      update VTA_FACOCARGA_YZ_DET
         set det_estado = 'ERROR'
       where det_carga = p_carga
         and det_linea = r.det_linea;
    end loop;

    -- VALIDACION 2: NRO_Y repetido en el archivo (mismo terminal-dia)
    for r in (select det_linea, det_nro_y
                from (select d.det_linea, d.det_nro_y,
                             row_number() over (partition by d.det_fecha, d.det_local,
                                                             d.det_terminal, d.det_nro_y
                                                    order by d.det_linea) rn
                        from VTA_FACOCARGA_YZ_DET d
                       where d.det_carga = p_carga
                         and d.det_tipo  = 'Y'
                         and d.det_nro_y is not null
                         and d.det_fecha is not null
                         and d.det_local is not null
                         and d.det_terminal is not null)
               where rn > 1) loop
      prc_log(p_carga, r.det_linea, 'VALIDACION', 'NRO_Y', to_char(r.det_nro_y),
              'NRO_Y repetido en el archivo para el mismo terminal y fecha', v_usuario);
      update VTA_FACOCARGA_YZ_DET
         set det_estado = 'ERROR'
       where det_carga = p_carga
         and det_linea = r.det_linea;
    end loop;
    commit;

    -- RESUMEN: un grupo por fecha / local / terminal, en PENDIENTE
    delete from VTA_FACOCARGA_YZ_RES where res_carga = p_carga;
    insert into VTA_FACOCARGA_YZ_RES
      (res_carga, res_fecha, res_local, res_terminal,
       res_cant_y, res_total_y, res_cant_z, res_total_z, res_lin_error,
       res_estado, res_mensaje, res_usuario, res_fechahora)
    select p_carga, d.det_fecha, d.det_local, d.det_terminal,
           sum(case when d.det_tipo = 'Y' then 1 else 0 end),
           sum(case when d.det_tipo = 'Y' then d.det_total end),
           sum(case when d.det_tipo = 'Z' then 1 else 0 end),
           sum(case when d.det_tipo = 'Z' then d.det_total end),
           sum(case when d.det_estado = 'ERROR' then 1 else 0 end),
           'PENDIENTE', null, v_usuario, sysdate
      from VTA_FACOCARGA_YZ_DET d
     where d.det_carga = p_carga
       and d.det_fecha is not null
       and d.det_local is not null
       and d.det_terminal is not null
     group by d.det_fecha, d.det_local, d.det_terminal;
    commit;   -- si lo que sigue falla, los grupos quedan PENDIENTE

    -- Estado de cada grupo
    for g in (select *
                from VTA_FACOCARGA_YZ_RES
               where res_carga = p_carga) loop
      v_msg := null;
      if g.res_lin_error > 0 then
        v_msg := v_msg || g.res_lin_error || ' fila(s) con error (ver log). ';
      end if;
      if g.res_cant_z = 0 then
        v_msg := v_msg || 'Sin fila Z. ';
      elsif g.res_cant_z > 1 then
        v_msg := v_msg || 'Tiene ' || g.res_cant_z || ' filas Z; debe ser 1. ';
      end if;
      if g.res_cant_y = 0 then
        v_msg := v_msg || 'Sin filas Y. ';
      end if;
      if g.res_cant_z = 1 and g.res_cant_y > 0
         and g.res_lin_error = 0
         and (g.res_total_z is null or g.res_total_y is null
              or g.res_total_z <> g.res_total_y) then
        v_msg := v_msg || 'Total Z (' || g.res_total_z || ') distinto de la suma de las Y ('
                       || g.res_total_y || '). ';
      end if;

      if v_msg is null then
        update VTA_FACOCARGA_YZ_RES
           set res_estado  = 'PROCESADO',
               res_mensaje = 'Total Z = suma de las Y'
         where res_carga    = p_carga
           and res_fecha    = g.res_fecha
           and res_local    = g.res_local
           and res_terminal = g.res_terminal;
      else
        v_msg := rtrim(v_msg);
        update VTA_FACOCARGA_YZ_RES
           set res_estado  = 'ERROR',
               res_mensaje = v_msg
         where res_carga    = p_carga
           and res_fecha    = g.res_fecha
           and res_local    = g.res_local
           and res_terminal = g.res_terminal;
        prc_log(p_carga, null, 'RESUMEN', 'GRUPO',
                to_char(g.res_fecha, 'dd-mm-yyyy') || ' L' || g.res_local || ' T' || g.res_terminal,
                v_msg, v_usuario);
      end if;
    end loop;

    select nvl(sum(case when res_estado = 'PROCESADO' then 1 else 0 end), 0),
           nvl(sum(case when res_estado = 'ERROR'     then 1 else 0 end), 0)
      into o_grupos_ok, o_grupos_error
      from VTA_FACOCARGA_YZ_RES
     where res_carga = p_carga;

    select nvl(sum(case when det_estado = 'ERROR' then 1 else 0 end), 0),
           nvl(sum(case when det_estado = 'ERROR'
                         and (det_fecha is null or det_local is null or det_terminal is null)
                        then 1 else 0 end), 0)
      into o_lin_error, v_sin_grp
      from VTA_FACOCARGA_YZ_DET
     where det_carga = p_carga;

    prc_log(p_carga, null, 'FIN', null, null,
            'Grupos PROCESADO: ' || o_grupos_ok || ', ERROR: ' || o_grupos_error
            || '. Lineas con error: ' || o_lin_error || ' (sin grupo: ' || v_sin_grp || ')',
            v_usuario);
    commit;
  exception
    when others then
      v_err := sqlerrm;
      rollback;
      prc_log(p_carga, null, 'ERROR', null, null, 'prc_procesa: ' || v_err, v_usuario);
      raise;
  end prc_procesa;

end PKG_F8_CARGA_MASIVA_YZ;
/
