-- =====================================================================
-- FCDVT-10 (HU-03) - Paso 04
-- Cuerpo de PKG_F8_CARGA_MASIVA_YZ_SFCL   (Oracle 10.2)
-- Tottus Chile (Flg_Pais$ = "SFCL")
-- xintec-nruz 11-11-2026
-- Base: docs/sql/FCDVT-14/04_pkg_carga_masiva_yz_body.sql (FACO): mismas
-- funciones de lectura (fn_campo, fn_entero, fn_fecha, fn_hora), mismo log
-- y mismo resumen. Las tablas de SFCL son fijas, asi que el SQL es
-- estatico; solo los conceptos de VTA_SFCLZZZ van en SQL dinamico, armado
-- desde VTA_PAINT_Z (nombres validados contra user_tab_columns).
--
-- Configuracion (prc_config, desde VTA_PAINT_Z con vta_localiz = 'SFCL',
-- en vta_order_z; es lo mismo que pinta la grilla de Form19 / Form19Y):
--   * filas 2 a 6 = conceptos de venta (Form19Y.GrabarTerceraZZZ rama
--     SFCL, Form19Y.frm:865): BOLETAS -> vta_montobol, N.CREDITO ->
--     vta_montoncr, FACTURA -> vta_montofac, N.DEBITO -> vta_mmontondb,
--     GUIA FACTURABLES -> vta_montoguia; fila 7 = total de venta
--     (vta_totalvta = suma de las filas 2 a 6, Form19Y.Grid1_KeyPress).
--     Si VTA_PAINT_Z no tiene esa forma, ORA-20002;
--   * otros vta_pop_up = 0 con columna que no empieza con VTA_ (o que
--     empieza con MVTA_) = conceptos de VTA_SFCLZZZ (Form19Y.arma_query_rec);
--   * vta_pop_up = 0 con columna VTA_ fuera de las filas 2 a 6: Form19Y no
--     los graba; no van en el CSV (aviso en el log INICIO);
--   * vta_pop_up = 3 de VTA_SFCLZZZ (totales): se graban en 0;
--   * vta_validadorzzz 1..7 + vta_signo: formula de validacion de la Z
--     (Form19.FuncMontoValidaZZZ / Modulo1.StrCamposValidarZZZ).
--
-- Validaciones por linea (prc_inserta_linea, etapa LECTURA):
--   - 11 + n conceptos campos (se tolera un ; final);
--   - FECHA dd-mm-yyyy valida y anterior a hoy; LOCAL, TERMINAL y TIPO
--     obligatorios; TIPO_CARGA INGRESAR o MODIFICAR;
--   - INGRESAR: HORA, SECUENCIA, NUM_BOLETA, VENDEDOR, CONT_REPOSICION
--     obligatorios (como FACO); montos vacios = 0;
--   - MODIFICAR: la Y debe traer NRO_Y; la identificacion restante no se
--     usa; al menos un concepto informado; montos vacios = no cambian;
--   - NRO_Y de una Y entre 1 y 98; VENDEDOR <= 10 digitos; montos enteros
--     de hasta 12 digitos.
-- Validaciones contra la base (prc_procesa, etapa VALIDACION):
--   - local / terminal vigente a la fecha (Form19Y.Oklt);
--   - NRO_Y repetido en el archivo para el mismo terminal-dia;
--   - terminal cerrado ese dia (VTA_SFCLTERMSTAT estado 1 o 2);
--   - MODIFICAR: el cierre existe en VTA_SFCLLIBVTA y la Y no esta cerrada.
-- Resumen por fecha / local / terminal (etapa RESUMEN), ERROR si:
--   - hay filas con error, o mezcla INGRESAR y MODIFICAR;
--   - INGRESAR: no hay exactamente 1 Z; el terminal tiene Y cerradas; con
--     Y, total de venta de la Z <> suma de las Y; la Z no cuadra con la
--     formula de VTA_PAINT_Z. Z sin Y es valido (Cargar crea la Y1);
--   - MODIFICAR: mas de 1 Z. La cuadratura del resultado (base + cambios)
--     la valida Cargar.
-- =====================================================================

create or replace package body PKG_F8_CARGA_MASIVA_YZ_SFCL as

  -- ------------------------------------------------------------------
  -- Configuracion (desde VTA_PAINT_Z)
  -- ------------------------------------------------------------------
  type t_conc is record (
    col     varchar2(30),     -- vta_cmp_asoc (nombre en el CSV y en DETM)
    glosa   varchar2(50),
    destino varchar2(1),      -- L = VTA_SFCLLIBVTA (venta), Z = VTA_SFCLZZZ
    venta   pls_integer       -- 1..5 si es concepto de venta, si no 0
  );
  type t_concs is table of t_conc index by pls_integer;
  type t_idx   is table of pls_integer index by varchar2(30);
  type t_val   is table of number index by varchar2(30);
  type t_nums  is table of number index by pls_integer;
  type t_v30   is table of varchar2(30) index by pls_integer;
  type t_vld is record (
    col   varchar2(30),
    tabla varchar2(1),        -- L libvta, Z zzz
    grupo pls_integer,        -- vta_validadorzzz 1..7
    signo number              -- +1 / -1 (vta_signo)
  );
  type t_vlds is table of t_vld index by pls_integer;

  g_cargado  boolean := false;
  g_conc     t_concs;          -- conceptos del CSV, en orden (columna 11 + i)
  g_idx      t_idx;            -- vta_cmp_asoc -> posicion en g_conc
  g_venta    t_v30;            -- 1..5: vta_cmp_asoc de los conceptos de venta
  g_ztot     t_v30;            -- totales de zzz (vta_pop_up 3): se graban en 0
  g_vld      t_vlds;           -- formula de validacion de la Z
  g_vld_ok   boolean;
  g_aviso    varchar2(1000);
  g_encab    varchar2(4000);
  g_campos   pls_integer;
  g_sql_ins  varchar2(32767);
  g_sql_val  varchar2(32767);

  function fn_existe_col (p_tabla in varchar2, p_col in varchar2) return boolean is
    v_n number;
  begin
    select count(*) into v_n
      from user_tab_columns
     where table_name = p_tabla
       and column_name = p_col;
    return v_n > 0;
  end fn_existe_col;

  procedure pr_aviso (p_txt in varchar2) is
  begin
    g_aviso := substr(g_aviso || p_txt || ' ', 1, 1000);
  end pr_aviso;

  procedure pr_agrega_conc (p_col in varchar2, p_glosa in varchar2,
                            p_destino in varchar2, p_venta in pls_integer) is
    v_i pls_integer;
  begin
    if g_idx.exists(p_col) then
      raise_application_error(-20002,
        'VTA_PAINT_Z de SFCL: la columna ' || p_col || ' aparece en mas de un concepto');
    end if;
    v_i := g_conc.count + 1;
    g_conc(v_i).col     := p_col;
    g_conc(v_i).glosa   := p_glosa;
    g_conc(v_i).destino := p_destino;
    g_conc(v_i).venta   := p_venta;
    g_idx(p_col)        := v_i;
  end pr_agrega_conc;

  procedure prc_config (p_flg_pais in varchar2, p_forzar in boolean default false) is
    v_r     pls_integer := 0;
    v_zzz   boolean;
    v_t     varchar2(1);
    v_i     pls_integer;
    v_cols  varchar2(32767);
    v_vals  varchar2(32767);
    type t_g is table of varchar2(32767) index by pls_integer;
    v_g     t_g;
  begin
    if p_flg_pais is null or upper(trim(p_flg_pais)) <> c_pais then
      raise_application_error(-20001,
        'PKG_F8_CARGA_MASIVA_YZ_SFCL: pais no habilitado (' || nvl(p_flg_pais, '(nulo)')
        || '); solo SFCL. FACO usa PKG_F8_CARGA_MASIVA_YZ');
    end if;
    if g_cargado and not p_forzar then
      return;
    end if;

    g_cargado := false;
    g_conc.delete;
    g_idx.delete;
    g_venta.delete;
    g_ztot.delete;
    g_vld.delete;
    g_vld_ok  := true;
    g_aviso   := null;

    -- vta_pop_up nulo = 0 (editable), como Form19 / Form19Y (decode(VTA_POP_UP, null, 0, ...))
    for r in (select upper(trim(vta_cmp_asoc)) col, vtaglosa_z glosa,
                     nvl(vta_pop_up, 0) pop, nvl(vta_validadorzzz, 0) vld,
                     vta_signo signo
                from vta_paint_z
               where vta_localiz = c_pais
               order by vta_order_z) loop
      v_r := v_r + 1;
      -- Solo se valida el nombre de las filas que se usan (las demas pueden
      -- tener cualquier texto en vta_cmp_asoc sin afectar la carga)
      if r.col is not null
         and ((v_r between 2 and 6) or (v_r > 7 and r.pop in (0, 3)) or r.vld between 1 and 7)
         and not regexp_like(r.col, '^[A-Z][A-Z0-9_#$]{0,29}$') then
        raise_application_error(-20002,
          'VTA_PAINT_Z de SFCL: vta_cmp_asoc invalido en la fila ' || v_r || ' (' || r.col || ')');
      end if;

      if v_r between 2 and 6 then
        -- Conceptos de venta: filas 2 a 6 de la grilla de Form19Y
        if r.pop <> 0 or r.col is null or substr(r.col, 1, 4) <> 'VTA_' then
          raise_application_error(-20002,
            'VTA_PAINT_Z de SFCL: la fila ' || v_r || ' (' || r.glosa
            || ') no es un concepto de venta (vta_pop_up 0 y columna VTA_); la carga'
            || ' usa las filas 2 a 6 como Form19Y');
        end if;
        g_venta(v_r - 1) := r.col;
        pr_agrega_conc(r.col, r.glosa, 'L', v_r - 1);
      elsif v_r = 7 then
        -- Total de venta (vta_totalvta = filas 2 a 6)
        if r.pop <> 3 then
          raise_application_error(-20002,
            'VTA_PAINT_Z de SFCL: la fila 7 (' || r.glosa || ') no es el total de venta (vta_pop_up 3)');
        end if;
      elsif v_r > 7 and r.col is not null then
        -- La fila 1 (titulo VENTAS) no se graba: Form19Y.arma_query_rec recorre desde la 2
        v_zzz := substr(r.col, 1, 4) <> 'VTA_' or substr(r.col, 1, 5) = 'MVTA_';
        if r.pop = 0 then
          if v_zzz then
            if not fn_existe_col('VTA_SFCLZZZ', r.col) then
              raise_application_error(-20002,
                'VTA_PAINT_Z de SFCL: ' || r.col || ' (' || r.glosa || ') no existe en VTA_SFCLZZZ');
            end if;
            pr_agrega_conc(r.col, r.glosa, 'Z', 0);
          else
            pr_aviso(r.col || ' (' || r.glosa || ') no va en el CSV: Form19Y no lo graba.');
          end if;
        elsif r.pop = 3 and v_zzz and not g_idx.exists(r.col) then
          if fn_existe_col('VTA_SFCLZZZ', r.col) then
            g_ztot(g_ztot.count + 1) := r.col;
          else
            pr_aviso('Total ' || r.col || ' no existe en VTA_SFCLZZZ; no se graba.');
          end if;
        end if;
      end if;

      -- Formula de validacion de la Z
      if r.vld between 1 and 7 and r.col is not null then
        if fn_existe_col('VTA_SFCLLIBVTA', r.col) then
          v_t := 'L';
        elsif fn_existe_col('VTA_SFCLZZZ', r.col) then
          v_t := 'Z';
        else
          v_t := null;
        end if;
        if v_t is null then
          g_vld_ok := false;
          pr_aviso('Formula de validacion de la Z desactivada: ' || r.col
                   || ' no existe en VTA_SFCLLIBVTA ni en VTA_SFCLZZZ.');
        else
          v_i := g_vld.count + 1;
          g_vld(v_i).col   := r.col;
          g_vld(v_i).tabla := v_t;
          g_vld(v_i).grupo := r.vld;
          if trim(r.signo) = '-' then
            g_vld(v_i).signo := -1;
          else
            g_vld(v_i).signo := 1;
          end if;
        end if;
      end if;
    end loop;

    if v_r < 7 then
      raise_application_error(-20002,
        'VTA_PAINT_Z no tiene los conceptos de SFCL (filas: ' || v_r || ')');
    end if;

    -- Encabezado del CSV
    g_encab := c_encabezado_id;
    for i in 1 .. g_conc.count loop
      g_encab := g_encab || ';' || g_conc(i).col;
    end loop;
    g_campos := c_campos_id + g_conc.count;

    -- INSERT de zzz: conceptos desde DETM (vacio = 0) y totales en 0
    v_cols := 'rec_techkey, rec_fechaproceso';
    v_vals := ':1, :2';
    for i in 1 .. g_conc.count loop
      if g_conc(i).destino = 'Z' then
        v_cols := v_cols || ', ' || g_conc(i).col;
        v_vals := v_vals || ', nvl(max(decode(dtm_columna, ''' || g_conc(i).col
                         || ''', dtm_monto)), 0)';
      end if;
    end loop;
    for i in 1 .. g_ztot.count loop
      v_cols := v_cols || ', ' || g_ztot(i);
      v_vals := v_vals || ', 0';
    end loop;
    g_sql_ins := 'insert into VTA_SFCLZZZ (' || v_cols || ') select ' || v_vals
                 || ' from VTA_SFCLCARGA_YZ_DETM where dtm_carga = :3 and dtm_linea = :4';

    -- Formula de la Z: grupo7 - grupo6 - ... - grupo1 (FuncMontoValidaZZZ)
    g_sql_val := null;
    if g_vld_ok and g_vld.count > 0 then
      for k in 1 .. 7 loop
        v_g(k) := '0';
      end loop;
      for i in 1 .. g_vld.count loop
        v_g(g_vld(i).grupo) := v_g(g_vld(i).grupo) || ' + sum(nvl('
          || case g_vld(i).tabla when 'L' then 'l.' else 'z.' end
          || g_vld(i).col || ', 0)) * (' || g_vld(i).signo || ')';
      end loop;
      g_sql_val := 'select (' || v_g(7) || ') - (' || v_g(6) || ') - (' || v_g(5)
        || ') - (' || v_g(4) || ') - (' || v_g(3) || ') - (' || v_g(2) || ') - (' || v_g(1) || ')'
        || ' from VTA_SFCLLIBVTA l, VTA_SFCLZZZ z'
        || ' where l.vta_tiporeg = ''F8'' and l.vta_fecha_venta = :1'
        || ' and l.vta_local = :2 and l.vta_terminal = :3'
        || ' and l.vta_estado = ''A'' and l.vta_techkey = z.rec_techkey';
    end if;

    g_cargado := true;
  end prc_config;

  function fn_encabezado (p_flg_pais in varchar2) return varchar2 is
  begin
    prc_config(p_flg_pais);
    return g_encab;
  end fn_encabezado;

  function fn_col_venta (p_n in pls_integer) return varchar2 is
  begin
    prc_config(c_pais);
    return g_venta(p_n);
  end fn_col_venta;

  function fn_sql_ins_zzz return varchar2 is
  begin
    prc_config(c_pais);
    return g_sql_ins;
  end fn_sql_ins_zzz;

  function fn_sql_valida_z return varchar2 is
  begin
    prc_config(c_pais);
    return g_sql_val;
  end fn_sql_valida_z;

  function fn_sql_upd_zzz (p_carga in number, p_linea in number) return varchar2 is
    v_set  varchar2(32767);
    v_sel  varchar2(32767);
  begin
    prc_config(c_pais);
    for r in (select dtm_columna
                from VTA_SFCLCARGA_YZ_DETM
               where dtm_carga = p_carga
                 and dtm_linea = p_linea
               order by dtm_columna) loop
      if g_idx.exists(r.dtm_columna) then
        if g_conc(g_idx(r.dtm_columna)).destino = 'Z' then
          if v_set is not null then
            v_set := v_set || ', ';
            v_sel := v_sel || ', ';
          end if;
          v_set := v_set || r.dtm_columna;
          v_sel := v_sel || 'max(decode(dtm_columna, ''' || r.dtm_columna || ''', dtm_monto))';
        end if;
      end if;
    end loop;
    if v_set is null then
      return null;
    end if;
    return 'update VTA_SFCLZZZ set (' || v_set || ') = (select ' || v_sel
           || ' from VTA_SFCLCARGA_YZ_DETM where dtm_carga = :1 and dtm_linea = :2)'
           || ' where rec_techkey = :3';
  end fn_sql_upd_zzz;

  -- ------------------------------------------------------------------
  -- Log (transaccion autonoma: queda aunque el proceso haga rollback)
  -- ------------------------------------------------------------------
  procedure prc_log (p_carga   in number,
                     p_linea   in number,
                     p_etapa   in varchar2,
                     p_campo   in varchar2,
                     p_valor   in varchar2,
                     p_motivo  in varchar2,
                     p_usuario in varchar2 default null) is
    pragma autonomous_transaction;
    v_usuario varchar2(50) := p_usuario;
  begin
    if v_usuario is null then
      select max(log_usuario) into v_usuario
        from VTA_SFCLCARGA_YZ_LOG
       where log_carga = p_carga
         and log_etapa = 'INICIO';
    end if;
    insert into VTA_SFCLCARGA_YZ_LOG
      (log_id, log_carga, log_linea, log_etapa, log_campo, log_valor,
       log_motivo, log_usuario, log_fechahora)
    values
      (SEQ_VTA_SFCLCARGA_YZ_LOG.nextval, p_carga, p_linea, p_etapa,
       substr(p_campo, 1, 30), substr(p_valor, 1, 200),
       substr(p_motivo, 1, 1000), v_usuario, sysdate);
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
  -- Separacion de la linea (iguales a FACO)
  -- ------------------------------------------------------------------
  function fn_ncampos (p_txt in varchar2) return pls_integer is
  begin
    return nvl(length(p_txt), 0) - nvl(length(replace(p_txt, ';')), 0) + 1;
  end fn_ncampos;

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

  function fn_nombre (p_n in pls_integer) return varchar2 is
  begin
    if p_n <= c_campos_id then
      return fn_campo(c_encabezado_id, p_n);
    end if;
    return g_conc(p_n - c_campos_id).col;
  end fn_nombre;

  -- ------------------------------------------------------------------
  -- Conversion con registro del error (iguales a FACO)
  -- ------------------------------------------------------------------
  function fn_entero (p_carga  in number,
                      p_linea  in number,
                      p_n      in pls_integer,
                      p_valor  in varchar2,
                      p_oblig  in boolean,
                      p_vacio  in number,
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
  -- Formula de validacion de la Z con los montos del archivo. Usa los
  -- mismos valores que grabara Cargar: libvta = conceptos de venta y su
  -- total; zzz = conceptos del CSV (vacio = 0); el resto = 0.
  -- ------------------------------------------------------------------
  function fn_dif_valida_archivo (p_carga in number, p_linea in number) return number is
    v_vals  t_val;
    v_lib   t_val;
    v_total number;
    v_val   number;
    v_g     t_nums;
  begin
    for r in (select dtm_columna, dtm_monto
                from VTA_SFCLCARGA_YZ_DETM
               where dtm_carga = p_carga
                 and dtm_linea = p_linea) loop
      v_vals(r.dtm_columna) := r.dtm_monto;
    end loop;
    select det_total into v_total
      from VTA_SFCLCARGA_YZ_DET
     where det_carga = p_carga
       and det_linea = p_linea;

    -- Columnas de libvta que graba Cargar (pr_ins_libvta de 04c)
    v_lib('VTA_MONTOBOL')  := 0;
    v_lib('VTA_MONTONCR')  := 0;
    v_lib('VTA_MONTOFAC')  := 0;
    v_lib('VTA_MMONTONDB') := 0;
    v_lib('VTA_MONTOGUIA') := 0;
    if v_vals.exists(g_venta(1)) then v_lib('VTA_MONTOBOL')  := v_vals(g_venta(1)); end if;
    if v_vals.exists(g_venta(2)) then v_lib('VTA_MONTONCR')  := v_vals(g_venta(2)); end if;
    if v_vals.exists(g_venta(3)) then v_lib('VTA_MONTOFAC')  := v_vals(g_venta(3)); end if;
    if v_vals.exists(g_venta(4)) then v_lib('VTA_MMONTONDB') := v_vals(g_venta(4)); end if;
    if v_vals.exists(g_venta(5)) then v_lib('VTA_MONTOGUIA') := v_vals(g_venta(5)); end if;
    v_lib('VTA_TOTALVTA') := nvl(v_total, 0);

    for k in 1 .. 7 loop
      v_g(k) := 0;
    end loop;
    for i in 1 .. g_vld.count loop
      v_val := 0;
      if g_vld(i).tabla = 'L' then
        if v_lib.exists(g_vld(i).col) then
          v_val := v_lib(g_vld(i).col);
        end if;
      elsif g_idx.exists(g_vld(i).col) then
        if g_conc(g_idx(g_vld(i).col)).destino = 'Z' and v_vals.exists(g_vld(i).col) then
          v_val := v_vals(g_vld(i).col);
        end if;
      end if;
      v_g(g_vld(i).grupo) := v_g(g_vld(i).grupo) + g_vld(i).signo * v_val;
    end loop;
    return v_g(7) - v_g(6) - v_g(5) - v_g(4) - v_g(3) - v_g(2) - v_g(1);
  end fn_dif_valida_archivo;

  -- ------------------------------------------------------------------
  -- API
  -- ------------------------------------------------------------------
  procedure prc_inicia (p_flg_pais in  varchar2,
                        p_archivo  in  varchar2,
                        p_usuario  in  varchar2,
                        o_carga    out number) is
  begin
    prc_config(p_flg_pais, true);   -- relee VTA_PAINT_Z en cada carga
    select SEQ_VTA_SFCLCARGA_YZ.nextval into o_carga from dual;
    prc_log(o_carga, null, 'INICIO', null, c_pais,
            'Archivo: ' || p_archivo || '. Columnas: ' || g_campos, p_usuario);
    if g_aviso is not null then
      prc_log(o_carga, null, 'INICIO', 'AVISO', null, g_aviso, p_usuario);
    end if;
  end prc_inicia;

  procedure prc_inserta_linea (p_flg_pais in varchar2,
                               p_carga    in number,
                               p_linea    in number,
                               p_texto    in varchar2) is
    v_txt     varchar2(4000) := p_texto;
    v_n       pls_integer;
    v_err     boolean := false;
    v_mod     boolean := false;
    v_fecha   date;
    v_local   number;
    v_term    number;
    v_nroy    number;
    v_hora    varchar2(5);
    v_sec     number;
    v_bol     number;
    v_vend    number;
    v_crepo   number;
    v_tipo    varchar2(4000);
    v_tcarga  varchar2(4000);
    v_total   number;
    v_estado  varchar2(10);
    v_s       varchar2(4000);
    v_m       number;
    v_vals    t_nums;          -- posicion del concepto -> monto informado
    v_i       pls_integer;
  begin
    prc_config(p_flg_pais);

    -- Se tolera un ; final
    if substr(v_txt, -1) = ';' and fn_ncampos(v_txt) = g_campos + 1 then
      v_txt := substr(v_txt, 1, length(v_txt) - 1);
    end if;

    -- Linea 1: encabezado de la plantilla
    if p_linea = 1 then
      if nvl(upper(trim(v_txt)), '-') <> upper(g_encab) then
        prc_log(p_carga, p_linea, 'LECTURA', 'ENCABEZADO', substr(v_txt, 1, 200),
                'El encabezado no es el de la plantilla de Tottus (' || g_campos
                || ' columnas: fn_encabezado / Exportar Excel de Form174)');
      end if;
      return;
    end if;

    if trim(replace(v_txt, ';')) is null then
      return;
    end if;

    v_n := fn_ncampos(v_txt);
    if v_n <> g_campos then
      prc_log(p_carga, p_linea, 'LECTURA', 'LINEA', to_char(v_n),
              'La linea tiene ' || v_n || ' campos; deben ser ' || g_campos);
      insert into VTA_SFCLCARGA_YZ_DET (det_carga, det_linea, det_texto, det_estado)
      values (p_carga, p_linea, substr(p_texto, 1, 4000), 'ERROR');
      commit;
      return;
    end if;

    -- TIPO_CARGA primero: decide que campos son obligatorios
    v_tcarga := upper(fn_campo(v_txt, 11));
    if v_tcarga = 'MODIFICAR' then
      v_mod := true;
    elsif v_tcarga is null or v_tcarga <> 'INGRESAR' then
      prc_log(p_carga, p_linea, 'LECTURA', 'TIPO_CARGA', v_tcarga, 'Debe ser INGRESAR o MODIFICAR');
      v_err    := true;
      v_tcarga := substr(v_tcarga, 1, 20);
    end if;

    v_tipo := upper(fn_campo(v_txt, 10));
    if v_tipo is null or v_tipo not in ('Y', 'Z') then
      prc_log(p_carga, p_linea, 'LECTURA', 'TIPO', v_tipo, 'Debe ser Y o Z');
      v_err  := true;
      v_tipo := null;
    end if;

    -- Identificacion (columnas 1 a 9)
    v_fecha := fn_fecha (p_carga, p_linea, fn_campo(v_txt, 1), v_err);
    v_local := fn_entero(p_carga, p_linea, 2, fn_campo(v_txt, 2), true,  null, v_err);
    v_term  := fn_entero(p_carga, p_linea, 3, fn_campo(v_txt, 3), true,  null, v_err);
    v_nroy  := fn_entero(p_carga, p_linea, 4, fn_campo(v_txt, 4), false, null, v_err);
    if v_tipo = 'Y' then
      if v_mod and v_nroy is null and fn_campo(v_txt, 4) is null then
        prc_log(p_carga, p_linea, 'LECTURA', 'NRO_Y', null,
                'En MODIFICAR la Y debe indicar el NRO_Y que se modifica');
        v_err := true;
      elsif v_nroy is not null and (v_nroy < 1 or v_nroy > 98) then
        prc_log(p_carga, p_linea, 'LECTURA', 'NRO_Y', to_char(v_nroy),
                'Fuera de rango (1 a 98; el 99 es la Z)');
        v_err := true;
      end if;
    end if;

    if v_mod then
      -- MODIFICAR: solo cambian los conceptos; la identificacion restante
      -- se valida si viene, pero no se usa
      if fn_campo(v_txt, 5) is not null then
        v_hora := fn_hora(p_carga, p_linea, fn_campo(v_txt, 5), v_err);
      end if;
      v_sec   := fn_entero(p_carga, p_linea, 6, fn_campo(v_txt, 6), false, null, v_err);
      v_bol   := fn_entero(p_carga, p_linea, 7, fn_campo(v_txt, 7), false, null, v_err);
      v_vend  := fn_entero(p_carga, p_linea, 8, fn_campo(v_txt, 8), false, null, v_err);
      v_crepo := fn_entero(p_carga, p_linea, 9, fn_campo(v_txt, 9), false, null, v_err);
    else
      v_hora  := fn_hora  (p_carga, p_linea, fn_campo(v_txt, 5), v_err);
      v_sec   := fn_entero(p_carga, p_linea, 6, fn_campo(v_txt, 6), true, null, v_err);
      v_bol   := fn_entero(p_carga, p_linea, 7, fn_campo(v_txt, 7), true, null, v_err);
      v_vend  := fn_entero(p_carga, p_linea, 8, fn_campo(v_txt, 8), true, null, v_err);
      v_crepo := fn_entero(p_carga, p_linea, 9, fn_campo(v_txt, 9), true, null, v_err);
    end if;

    -- vta_sfcllibvta.vta_vendedor es NUMBER(10)
    if v_vend is not null and abs(v_vend) > 9999999999 then
      prc_log(p_carga, p_linea, 'LECTURA', 'VENDEDOR', to_char(v_vend),
              'Maximo 10 digitos (vta_vendedor es NUMBER(10))');
      v_err := true;
    end if;

    -- Montos (columnas 12 en adelante): solo se guardan los informados
    for i in 1 .. g_conc.count loop
      v_s := fn_campo(v_txt, c_campos_id + i);
      if v_s is not null then
        v_m := fn_entero(p_carga, p_linea, c_campos_id + i, v_s, false, null, v_err);
        if v_m is not null then
          if abs(v_m) > 999999999999 then
            prc_log(p_carga, p_linea, 'LECTURA', g_conc(i).col, to_char(v_m),
                    'Monto demasiado grande (maximo 12 digitos)');
            v_err := true;
          else
            v_vals(i) := v_m;
          end if;
        end if;
      end if;
    end loop;

    if v_mod then
      if v_vals.count = 0 and not v_err then
        prc_log(p_carga, p_linea, 'LECTURA', 'LINEA', null,
                'MODIFICAR sin conceptos informados: no hay nada que cambiar');
        v_err := true;
      end if;
      v_total := null;
    else
      -- Total de venta = filas 2 a 6 (vacio = 0)
      v_total := 0;
      for k in 1 .. 5 loop
        v_i := g_idx(g_venta(k));
        if v_vals.exists(v_i) then
          v_total := v_total + v_vals(v_i);
        end if;
      end loop;
    end if;

    if v_err then
      v_estado := 'ERROR';
    else
      v_estado := 'OK';
    end if;

    insert into VTA_SFCLCARGA_YZ_DET
      (det_carga, det_linea, det_texto, det_fecha, det_local, det_terminal,
       det_nro_y, det_hora, det_secuencia, det_num_boleta, det_vendedor,
       det_cont_repo, det_tipo, det_tipo_carga, det_total, det_estado, det_fechahora)
    values
      (p_carga, p_linea, substr(p_texto, 1, 4000), v_fecha, v_local, v_term,
       v_nroy, v_hora, v_sec, v_bol, v_vend,
       v_crepo, v_tipo, v_tcarga, v_total, v_estado, sysdate);

    v_i := v_vals.first;
    while v_i is not null loop
      insert into VTA_SFCLCARGA_YZ_DETM (dtm_carga, dtm_linea, dtm_columna, dtm_monto)
      values (p_carga, p_linea, g_conc(v_i).col, v_vals(v_i));
      v_i := v_vals.next(v_i);
    end loop;
    commit;
  exception
    when others then
      if g_cargado then
        prc_log(p_carga, p_linea, 'ERROR', null, null, 'prc_inserta_linea: ' || sqlerrm);
      end if;
      raise;
  end prc_inserta_linea;

  -- Marca una linea en error y lo registra (etapa VALIDACION)
  procedure pr_err_linea (p_carga in number, p_linea in number, p_campo in varchar2,
                          p_valor in varchar2, p_motivo in varchar2, p_usuario in varchar2) is
  begin
    prc_log(p_carga, p_linea, 'VALIDACION', p_campo, p_valor, p_motivo, p_usuario);
    update VTA_SFCLCARGA_YZ_DET
       set det_estado = 'ERROR'
     where det_carga = p_carga
       and det_linea = p_linea;
  end pr_err_linea;

  procedure prc_procesa (p_flg_pais     in  varchar2,
                         p_carga        in  number,
                         o_grupos_ok    out number,
                         o_grupos_error out number,
                         o_lin_error    out number) is
    v_usuario  varchar2(50);
    v_n        number;
    v_sin_grp  number;
    v_msg      varchar2(1000);
    v_ok       varchar2(1000);
    v_err      varchar2(1000);
    v_lin_z    number;
    v_dif      number;
  begin
    o_grupos_ok    := 0;
    o_grupos_error := 0;
    o_lin_error    := 0;
    prc_config(p_flg_pais);
    v_usuario      := fn_usuario(p_carga);

    -- Encabezado rechazado: no se procesa nada
    select count(*) into v_n
      from VTA_SFCLCARGA_YZ_LOG
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
                from VTA_SFCLCARGA_YZ_DET d
               where d.det_carga = p_carga
                 and d.det_fecha is not null
                 and d.det_local is not null
                 and d.det_terminal is not null
                 and not exists (select 1
                                   from VTA_SFCLTERMINALES t
                                  where t.ter_local    = d.det_local
                                    and t.ter_terminal = d.det_terminal
                                    and (t.ter_fechabaja >= d.det_fecha
                                         or t.ter_fechabaja is null))) loop
      pr_err_linea(p_carga, r.det_linea, 'TERMINAL', r.det_local || '-' || r.det_terminal,
                   'Local / terminal no existe o no esta vigente al '
                   || to_char(r.det_fecha, 'dd-mm-yyyy'), v_usuario);
    end loop;

    -- VALIDACION 2: NRO_Y repetido en el archivo (mismo terminal-dia)
    for r in (select det_linea, det_nro_y
                from (select d.det_linea, d.det_nro_y,
                             row_number() over (partition by d.det_fecha, d.det_local,
                                                             d.det_terminal, d.det_nro_y
                                                    order by d.det_linea) rn
                        from VTA_SFCLCARGA_YZ_DET d
                       where d.det_carga = p_carga
                         and d.det_tipo  = 'Y'
                         and d.det_nro_y is not null
                         and d.det_fecha is not null
                         and d.det_local is not null
                         and d.det_terminal is not null)
               where rn > 1) loop
      pr_err_linea(p_carga, r.det_linea, 'NRO_Y', to_char(r.det_nro_y),
                   'NRO_Y repetido en el archivo para el mismo terminal y fecha', v_usuario);
    end loop;

    -- VALIDACION 3: terminal cerrado ese dia (Form19Y: termstat 1 o 2)
    for r in (select d.det_linea, d.det_fecha
                from VTA_SFCLCARGA_YZ_DET d
               where d.det_carga = p_carga
                 and d.det_fecha is not null
                 and d.det_local is not null
                 and d.det_terminal is not null
                 and exists (select 1
                               from VTA_SFCLTERMSTAT s
                              where s.ter_local    = d.det_local
                                and s.ter_terminal = d.det_terminal
                                and s.ter_fecha    = d.det_fecha
                                and s.ter_estado in (1, 2))) loop
      pr_err_linea(p_carga, r.det_linea, 'TERMINAL', to_char(r.det_fecha, 'dd-mm-yyyy'),
                   'El terminal esta cerrado ese dia (VTA_SFCLTERMSTAT estado 1 o 2)', v_usuario);
    end loop;

    -- VALIDACION 4: MODIFICAR sobre un cierre que no existe
    for r in (select d.det_linea, d.det_tipo, d.det_nro_y
                from VTA_SFCLCARGA_YZ_DET d
               where d.det_carga = p_carga
                 and d.det_tipo_carga = 'MODIFICAR'
                 and d.det_fecha is not null
                 and d.det_local is not null
                 and d.det_terminal is not null
                 and (d.det_tipo = 'Z' or (d.det_tipo = 'Y' and d.det_nro_y is not null))
                 and not exists (select 1
                                   from VTA_SFCLLIBVTA l
                                  where l.vta_fecha_venta = d.det_fecha
                                    and l.vta_local       = d.det_local
                                    and l.vta_terminal    = d.det_terminal
                                    and l.vta_tiporeg     = decode(d.det_tipo, 'Z', 'F8', 'Y')
                                    and l.vta_secuencia   = decode(d.det_tipo, 'Z', 99, d.det_nro_y))) loop
      if r.det_tipo = 'Z' then
        pr_err_linea(p_carga, r.det_linea, 'TIPO', 'Z',
                     'MODIFICAR: el terminal no tiene Z grabada ese dia', v_usuario);
      else
        pr_err_linea(p_carga, r.det_linea, 'NRO_Y', to_char(r.det_nro_y),
                     'MODIFICAR: no existe la Y ' || r.det_nro_y || ' del terminal ese dia', v_usuario);
      end if;
    end loop;

    -- VALIDACION 5: MODIFICAR una Y cerrada (termstaty 1 o 2)
    for r in (select d.det_linea, d.det_nro_y
                from VTA_SFCLCARGA_YZ_DET d
               where d.det_carga = p_carga
                 and d.det_tipo_carga = 'MODIFICAR'
                 and d.det_tipo = 'Y'
                 and d.det_nro_y is not null
                 and exists (select 1
                               from VTA_SFCLTERMSTATY s
                              where s.ter_local    = d.det_local
                                and s.ter_terminal = d.det_terminal
                                and s.ter_fecha    = d.det_fecha
                                and s.ter_cierrey  = d.det_nro_y
                                and s.ter_estado in (1, 2))) loop
      pr_err_linea(p_carga, r.det_linea, 'NRO_Y', to_char(r.det_nro_y),
                   'MODIFICAR: la Y ' || r.det_nro_y || ' esta cerrada (VTA_SFCLTERMSTATY estado 1 o 2)',
                   v_usuario);
    end loop;
    commit;

    -- RESUMEN: un grupo por fecha / local / terminal, en PENDIENTE
    delete from VTA_SFCLCARGA_YZ_RES where res_carga = p_carga;
    insert into VTA_SFCLCARGA_YZ_RES
      (res_carga, res_fecha, res_local, res_terminal,
       res_cant_y, res_total_y, res_cant_z, res_total_z, res_lin_error,
       res_estado, res_mensaje, res_usuario, res_fechahora, res_tipo_carga)
    select p_carga, d.det_fecha, d.det_local, d.det_terminal,
           sum(case when d.det_tipo = 'Y' then 1 else 0 end),
           sum(case when d.det_tipo = 'Y' then d.det_total end),
           sum(case when d.det_tipo = 'Z' then 1 else 0 end),
           sum(case when d.det_tipo = 'Z' then d.det_total end),
           sum(case when d.det_estado = 'ERROR' then 1 else 0 end),
           'PENDIENTE', null, v_usuario, sysdate,
           case when min(d.det_tipo_carga) = max(d.det_tipo_carga)
                then max(d.det_tipo_carga) else 'MIXTO' end
      from VTA_SFCLCARGA_YZ_DET d
     where d.det_carga = p_carga
       and d.det_fecha is not null
       and d.det_local is not null
       and d.det_terminal is not null
     group by d.det_fecha, d.det_local, d.det_terminal;
    commit;   -- si lo que sigue falla, los grupos quedan PENDIENTE

    -- Lineas con error que no forman grupo (fecha, local o terminal ilegibles)
    select count(*) into v_sin_grp
      from VTA_SFCLCARGA_YZ_DET
     where det_carga = p_carga
       and det_estado = 'ERROR'
       and (det_fecha is null or det_local is null or det_terminal is null);

    -- Estado de cada grupo
    for g in (select res_fecha, res_local, res_terminal, res_cant_y, res_total_y,
                     res_cant_z, res_total_z, res_lin_error, res_tipo_carga
                from VTA_SFCLCARGA_YZ_RES
               where res_carga = p_carga) loop
      v_msg := null;
      v_ok  := null;
      if g.res_lin_error > 0 then
        v_msg := v_msg || g.res_lin_error || ' fila(s) con error (ver log). ';
      end if;

      if g.res_tipo_carga = 'MIXTO' then
        v_msg := v_msg || 'Mezcla INGRESAR y MODIFICAR en el mismo terminal y fecha. ';
      elsif g.res_tipo_carga = 'MODIFICAR' then
        if g.res_cant_z > 1 then
          v_msg := v_msg || 'Tiene ' || g.res_cant_z || ' filas Z; maximo 1. ';
        end if;
        v_ok := 'Modifica ' || g.res_cant_z || ' Z y ' || g.res_cant_y
                || ' Y. Cargar valida que la Z siga igual a la suma de las Y';
      else
        if g.res_cant_z = 0 then
          v_msg := v_msg || 'Sin fila Z. ';
        elsif g.res_cant_z > 1 then
          v_msg := v_msg || 'Tiene ' || g.res_cant_z || ' filas Z; debe ser 1. ';
        end if;

        -- INGRESAR reemplaza todas las Y del dia: no puede haber Y cerradas
        select count(*) into v_n
          from VTA_SFCLTERMSTATY
         where ter_local    = g.res_local
           and ter_terminal = g.res_terminal
           and ter_fecha    = g.res_fecha
           and ter_estado in (1, 2);
        if v_n > 0 then
          v_msg := v_msg || 'El terminal tiene ' || v_n
                         || ' cierre(s) Y cerrado(s) ese dia; INGRESAR los reemplazaria. ';
        end if;

        if g.res_cant_z = 1 and g.res_lin_error = 0 then
          if g.res_cant_y > 0
             and (g.res_total_z is null or g.res_total_y is null
                  or g.res_total_z <> g.res_total_y) then
            v_msg := v_msg || 'Total de venta de la Z (' || g.res_total_z
                           || ') distinto de la suma de las Y (' || g.res_total_y || '). ';
          end if;
          if g_sql_val is not null then
            select max(det_linea) into v_lin_z
              from VTA_SFCLCARGA_YZ_DET
             where det_carga = p_carga and det_fecha = g.res_fecha
               and det_local = g.res_local and det_terminal = g.res_terminal
               and det_tipo = 'Z';
            v_dif := fn_dif_valida_archivo(p_carga, v_lin_z);
            if v_dif <> 0 then
              v_msg := v_msg || 'Z descuadrada segun la formula de VTA_PAINT_Z (diferencia '
                             || v_dif || '). ';
            end if;
          end if;
        end if;
        -- Una Y ilegible no forma grupo: su Z quedaria "sin Y" y Cargar
        -- inventaria la Y1. Con lineas sin grupo no se acepta una Z sin Y.
        if g.res_cant_y = 0 and v_sin_grp > 0 then
          v_msg := v_msg || 'Z sin Y y el archivo tiene ' || v_sin_grp
                         || ' linea(s) con error sin grupo (fecha, local o terminal ilegibles):'
                         || ' no se crea la Y1 automatica; corregir el archivo. ';
        end if;
        if g.res_cant_y = 0 then
          v_ok := 'Z sin Y: Cargar crea la Y1 copiando la Z (como Form19)';
        else
          v_ok := 'Total de venta Z = suma de las Y';
        end if;
      end if;

      if v_msg is null then
        update VTA_SFCLCARGA_YZ_RES
           set res_estado  = c_estado_ok,
               res_mensaje = v_ok
         where res_carga    = p_carga
           and res_fecha    = g.res_fecha
           and res_local    = g.res_local
           and res_terminal = g.res_terminal;
      else
        v_msg := rtrim(v_msg);
        update VTA_SFCLCARGA_YZ_RES
           set res_estado  = 'ERROR',
               res_mensaje = substr(v_msg, 1, 1000)
         where res_carga    = p_carga
           and res_fecha    = g.res_fecha
           and res_local    = g.res_local
           and res_terminal = g.res_terminal;
        prc_log(p_carga, null, 'RESUMEN', 'GRUPO',
                to_char(g.res_fecha, 'dd-mm-yyyy') || ' L' || g.res_local || ' T' || g.res_terminal,
                v_msg, v_usuario);
      end if;
    end loop;

    select nvl(sum(case when res_estado = c_estado_ok then 1 else 0 end), 0),
           nvl(sum(case when res_estado = 'ERROR'     then 1 else 0 end), 0)
      into o_grupos_ok, o_grupos_error
      from VTA_SFCLCARGA_YZ_RES
     where res_carga = p_carga;

    select nvl(sum(case when det_estado = 'ERROR' then 1 else 0 end), 0)
      into o_lin_error
      from VTA_SFCLCARGA_YZ_DET
     where det_carga = p_carga;

    prc_log(p_carga, null, 'FIN', null, null,
            'Grupos ' || c_estado_ok || ': ' || o_grupos_ok || ', ERROR: ' || o_grupos_error
            || '. Lineas con error: ' || o_lin_error || ' (sin grupo: ' || v_sin_grp || ')',
            v_usuario);
    commit;
  exception
    when others then
      v_err := sqlerrm;
      rollback;
      if g_cargado then
        prc_log(p_carga, null, 'ERROR', null, null, 'prc_procesa: ' || v_err, v_usuario);
      end if;
      raise;
  end prc_procesa;

end PKG_F8_CARGA_MASIVA_YZ_SFCL;
/
