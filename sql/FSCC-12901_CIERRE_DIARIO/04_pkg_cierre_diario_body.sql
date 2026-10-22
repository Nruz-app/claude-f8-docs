-- =====================================================================
-- FSCC-12901 CIERRE_DIARIO - Paso 04
-- Cuerpo de PKG_F8_CIERRE_DIARIO   (Oracle 10.2)
-- MULTIPAIS (habilitado: FACO)
-- xintec-nruz 20-10-2026
--
-- Simula "Cerrar Terminal" de Consultas de Cuadratura (FTEPROD/Form43.frm):
--   Command4_Click :2915 (filas con Cierre Y <> 0, Dif. Real 0 y estado
--   distinto de Cerrado) -> CierraTerminalYYY :4618.
--
-- Fuentes:
--   * pr_config / fn_r / fn_sql_nums / fn_param: PKG_F8_COMPENSA_DI_CARGA
--     (docs/sql/FSCC-12901_COMPENSA_DI/05) y PKG_F8_CIERRE_AUTO (v2,
--     docs/sql/FSCC-12901_PROC_Y/07_pkg_cierre_auto_body.sql:64-215).
--   * fn_conceptos, fn_msg_cheque_fecha (RY-01), fn_concepto_pendiente
--     (RY-03), fn_zzz (RY-06), pr_valida_y, pr_procesa_y: PKG_F8_CIERRE_AUTO
--     (v2, mismo archivo :328-941), probado en test el 16-10 (prueba 3),
--     sin la cola de sobres.
--   * fn_dif_real_cc: Form43.SubBuscarOpcion :999 (Dif. de Caja),
--     ValorCompensacion :406 / StrSumCompensado :441, FuncValorZoY :3279,
--     FuncBuscarRecEfectivo :1643, FuncBuscarRecModRec :1703,
--     FuncBuscarRecCheFecha :1821, FuncBuscarRecTarj :1882.
--   * Universo: Form43.FuncStrPivote :2081 (rama ARG/SFCL/FACO/HTPE).
--
-- 22-10-2026 FCDVT-56 (HU-14.2): segunda etapa SIN VENTA. Simula el segundo
-- recorrido de Command4_Click (filas con Cierre Y = 0 y Dif. Real 0) ->
-- Form43.CierraTerminal :4077, que cierra la Z (VTA_<pfx>TERMSTAT):
--   * universo: el UNION de FCDVT-56 en Form43.FuncStrPivote :2212 (Z
--     Pendiente de un terminal vigente sin libro de ventas Y), para todos
--     los locales, y ademas SIN ninguna Y creada en TERMSTATY (decision del
--     usuario del 22-10: si ya se creo la Y, el terminal espera sobres);
--   * Dif. Real de la grilla de CC con Y = 0: el exe arma sus consultas sin
--     filtro de Y (todo el terminal-dia); aqui fn_sql_nums quita el filtro;
--   * validaciones de CierraTerminal: RZ-01 conceptos sin regularizar del
--     dia, RZ-02 Z contra suma de Y (FuncValidarZSumaY), RZ-03 formula ZZZ
--     de la Z (CD_VAL_ZZZ), RZ-04 dolares contra Prosegur (CD_VAL_DOL);
--   * cierre igual que el boton: ter_estado = 1, ter_cerradopor = usuario.
--   Parametro 1502 CD_SIN_VENTA (S/N) la enciende.
--
-- Marcas del SQL dinamico (las reemplaza fn_r segun pr_config):
--   {P} prefijo de tablas  {EST} tabla de estado del cierre  {NIVEL} tiporeg
--   {USD} / {EUR} monedas en RECMEX  {CCCA} 'CA' en la lista de regularizados
--   del compensado de CC (FACO: no va)  {ESTZ} tabla de estado de la Z
-- =====================================================================

create or replace package body PKG_F8_CIERRE_DIARIO as

  c_tipo_param constant number := 1502;

  -- ---------------------------------------------------------------
  -- Configuracion del pais
  -- ---------------------------------------------------------------
  type t_cfg is record (
    pais        varchar2(10),   -- valor de Flg_Pais$ recibido (normalizado)
    prefijo     varchar2(10),   -- prefijo de tablas VTA_<prefijo>...
    tabla_est   varchar2(30),   -- tabla de estado del cierre (sin VTA_<prefijo>)
    nivel       varchar2(2),    -- vta_tiporeg del libro de ventas del cierre
    localiz     varchar2(10),   -- VTA_PAINT_Z.vta_localiz (formula ZZZ)
    mda_usd     number,         -- moneda dolar en VTA_<pfx>RECMEX
    mda_eur     number,         -- moneda euro en VTA_<pfx>RECMEX
    cc_lista_ca varchar2(10),   -- 'CA' en la lista de regularizados del compensado de CC
    tabla_z     varchar2(30),   -- tabla de estado de la Z (sin VTA_<prefijo>)
    sin_venta   varchar2(1)     -- S: el pais admite la etapa SIN VENTA (cierre de la Z)
  );
  g_cfg t_cfg;

  type t_nums is table of number index by pls_integer;
  type t_conceptos is table of varchar2(200) index by varchar2(2);

  -- Estado de la ejecucion en curso
  g_ejecucion number;
  g_usuario   varchar2(50) := c_usuario;

  e_ocupada exception;
  pragma exception_init(e_ocupada, -54);   -- ORA-00054 resource busy (NOWAIT)

  -- ---------------------------------------------------------------
  -- Paises habilitados. Es la UNICA fuente del prefijo que se concatena
  -- en el SQL dinamico (lista blanca: nunca se usa el texto recibido).
  -- ---------------------------------------------------------------
  procedure pr_config (p_flg_pais in varchar2) is
    v_pais varchar2(10) := upper(trim(p_flg_pais));
    v_cfg  t_cfg;
  begin
    if g_cfg.pais is not null and g_cfg.pais = v_pais then
      return;   -- ya configurado
    end if;

    if v_pais = 'FACO' then
      -- Falabella Colombia: cierre Y (Form3Y / CierraTerminalYYY), la Z no se gestiona.
      v_cfg.pais        := 'FACO';
      v_cfg.prefijo     := 'FACO';
      v_cfg.tabla_est   := 'TERMSTATY';
      v_cfg.nivel       := 'Y';
      v_cfg.localiz     := 'FACO';
      v_cfg.mda_usd     := 305;      -- Modulo1 DOLAR = "305"
      v_cfg.mda_eur     := 304;      -- Modulo1 EUROS = "304"
      v_cfg.cc_lista_ca := null;     -- StrSumCompensado :738: FACO no suma CA de MOVDET
      v_cfg.tabla_z     := 'TERMSTAT';
      v_cfg.sin_venta   := 'S';      -- FCDVT-56: Form43.CierraTerminal cierra la Z de los sin venta

    -- -------------------------------------------------------------
    -- EJEMPLO (NO HABILITADO): otro pais con cierre Y, p. ej. Tottus Chile
    -- (Flg_Pais$ = "SFCL"). Antes de habilitarlo:
    --   1. habilitarlo tambien en PKG_F8_COMPENSA_DI_CARGA.pr_config (la
    --      Dif. Real de la F8 sale de ahi);
    --   2. crear VTA_<pfx>LOG_CIERRE_DIARIO + secuencia (01 con el prefijo)
    --      y los parametros 1502 CD_* y CA_DECIMAL en VTA_<pfx>PARAM (02);
    --   3. revisar contra el exe sus diferencias: Form43.SubBuscarOpcion
    --      (SFCL tiene rama propia y otra formula de Dif. de Caja),
    --      CierraTerminalYYY (SFCL valida FuncMontoValidaZZZYY siempre) y
    --      StrSumCompensado (lista de conceptos);
    --   4. agregar aqui la rama.
    -- elsif v_pais = 'SFCL' then
    --   v_cfg.pais        := 'SFCL';
    --   v_cfg.prefijo     := 'SFCL';
    --   v_cfg.tabla_est   := 'TERMSTATY';
    --   v_cfg.nivel       := 'Y';
    --   v_cfg.localiz     := 'SFCL';
    --   v_cfg.mda_usd     := 305;
    --   v_cfg.mda_eur     := 304;
    --   v_cfg.cc_lista_ca := null;
    --   v_cfg.tabla_z     := 'TERMSTAT';
    --   v_cfg.sin_venta   := 'N';   -- revisar antes Form43.CierraTerminal para el pais
    -- -------------------------------------------------------------
    else
      raise_application_error(-20001,
        'Pais no habilitado para el cierre diario: ' || nvl(p_flg_pais, '(nulo)'));
    end if;

    g_cfg := v_cfg;
  end pr_config;

  -- Reemplaza las marcas del SQL con los valores del pais configurado
  function fn_r (p_sql in varchar2) return varchar2 is
  begin
    return replace(replace(replace(replace(replace(replace(replace(p_sql,
             '{P}',     g_cfg.prefijo),
             '{ESTZ}',  g_cfg.tabla_z),
             '{EST}',   g_cfg.tabla_est),
             '{NIVEL}', g_cfg.nivel),
             '{USD}',   to_char(g_cfg.mda_usd)),
             '{EUR}',   to_char(g_cfg.mda_eur)),
             '{CCCA}',  case when g_cfg.cc_lista_ca is not null
                             then ', ''' || g_cfg.cc_lista_ca || '''' end);
  end fn_r;

  -- FCDVT-56: con Y = 0 (terminal sin venta) el exe arma las consultas SIN
  -- el filtro de Y (Form43: If vcierrey <> "0" ... "and x.cierrey = ...")
  -- y suma todo el terminal-dia. Esta funcion quita del SQL cada condicion
  -- "and <alias>.<columna> = :b_y".
  function fn_sin_y (p_sql in varchar2) return varchar2 is
  begin
    return regexp_replace(p_sql,
             '[[:space:]]+and[[:space:]]+[a-z]+\.[a-z_]+[[:space:]]*=[[:space:]]*:b_y',
             '', 1, 0, 'i');
  end fn_sin_y;

  -- Ejecuta un SELECT de una fila y p_ncols columnas numericas con binds por
  -- nombre (:b_fecha, :b_local, :b_term, :b_y, :b_txt; cada uno solo si aparece).
  -- Con p_cierrey = 0 se quitan los filtros de Y (fn_sin_y), como el exe.
  -- Sin filas devuelve NULL en cada columna.
  function fn_sql_nums (p_sql      in varchar2,
                        p_ncols    in pls_integer,
                        p_fecha    in date,
                        p_local    in number,
                        p_terminal in number,
                        p_cierrey  in number,
                        p_txt      in varchar2 default null) return t_nums is
    c     integer;
    n     integer;
    x     number;
    v     t_nums;
    v_sql varchar2(32767) := case when p_cierrey = 0 then fn_sin_y(p_sql) else p_sql end;
  begin
    c := dbms_sql.open_cursor;
    begin
      dbms_sql.parse(c, v_sql, dbms_sql.native);
      if instr(v_sql, ':b_fecha') > 0 then dbms_sql.bind_variable(c, ':b_fecha', p_fecha);    end if;
      if instr(v_sql, ':b_local') > 0 then dbms_sql.bind_variable(c, ':b_local', p_local);    end if;
      if instr(v_sql, ':b_term')  > 0 then dbms_sql.bind_variable(c, ':b_term',  p_terminal); end if;
      if instr(v_sql, ':b_y')     > 0 then dbms_sql.bind_variable(c, ':b_y',     p_cierrey);  end if;
      if instr(v_sql, ':b_txt')   > 0 then dbms_sql.bind_variable(c, ':b_txt',   p_txt);      end if;
      for i in 1 .. p_ncols loop
        dbms_sql.define_column(c, i, x);
      end loop;
      n := dbms_sql.execute(c);
      if dbms_sql.fetch_rows(c) > 0 then
        for i in 1 .. p_ncols loop
          dbms_sql.column_value(c, i, x);
          v(i) := x;
        end loop;
      else
        for i in 1 .. p_ncols loop
          v(i) := null;
        end loop;
      end if;
      dbms_sql.close_cursor(c);
    exception
      when others then
        if dbms_sql.is_open(c) then
          dbms_sql.close_cursor(c);
        end if;
        raise;
    end;
    return v;
  end fn_sql_nums;

  -- ---------------------------------------------------------------
  -- Parametros VTA_<pfx>PARAM tipo 1502 (pais ya configurado)
  -- ---------------------------------------------------------------
  function fn_param (p_codigo in varchar2, p_default in varchar2) return varchar2 is
    v_valor varchar2(200);
  begin
    execute immediate fn_r(
      q'[select trim(p.vta_xglosa)
           from VTA_{P}PARAM p
          where p.vta_ccodtipo = :1
            and trim(p.vta_ccodigo) = :2
            and rownum = 1]')
      into v_valor
      using c_tipo_param, p_codigo;
    return nvl(v_valor, p_default);
  exception
    when no_data_found then
      return p_default;
  end fn_param;

  -- Decimales de redondeo (gFormat del pais; FACO 0)
  function fn_dec return number is
  begin
    return to_number(fn_param('CA_DECIMAL', '0'));
  end fn_dec;

  -- ---------------------------------------------------------------
  -- Log (transaccion autonoma: queda aunque la caja haga rollback)
  -- ---------------------------------------------------------------
  procedure pr_log (p_fecha     in date,
                    p_local     in number,
                    p_terminal  in number,
                    p_cierrey   in number,
                    p_dr_f8     in number,
                    p_dr_cc     in number,
                    p_resultado in varchar2,
                    p_regla     in varchar2,
                    p_mensaje   in varchar2) is
    pragma autonomous_transaction;
  begin
    execute immediate fn_r(
      q'[insert into VTA_{P}LOG_CIERRE_DIARIO
           (log_id, log_ejecucion, log_fecha_vta, log_local, log_terminal, log_cierrey,
            log_dr_f8, log_dr_cc, log_resultado, log_regla, log_mensaje,
            log_usuario, log_fechahora)
         values
           (SEQ_VTA_{P}LOG_CIERRE_DIARIO.nextval, :1, :2, :3, :4, :5,
            :6, :7, :8, :9, :10, :11, sysdate)]')
      using nvl(g_ejecucion, 0), p_fecha, p_local, p_terminal, p_cierrey,
            p_dr_f8, p_dr_cc, p_resultado, p_regla, substr(p_mensaje, 1, 1000),
            substr(g_usuario, 1, 50);
    commit;
  exception
    when others then
      rollback;   -- el log nunca corta el proceso
  end pr_log;

  function fn_nueva_ejecucion return number is
    v_n number;
  begin
    execute immediate fn_r('select SEQ_VTA_{P}LOG_CIERRE_DIARIO.nextval from dual') into v_n;
    return v_n;
  end fn_nueva_ejecucion;

  -- ---------------------------------------------------------------
  -- Dif. Real de la F8 de la Y (Form3Y.FormateaDatos): la misma con la
  -- que PKG_F8_COMPENSA_DI_CARGA decide la DI automatica. NULL sin libro
  -- de ventas de la Y.
  -- ---------------------------------------------------------------
  function fn_dif_real_f8 (p_fecha in date, p_local in number, p_terminal in number,
                           p_cierrey in number) return number is
  begin
    return PKG_F8_COMPENSA_DI_CARGA.fn_dif_real(g_cfg.pais, p_fecha, p_local, p_terminal, p_cierrey);
  end fn_dif_real_f8;

  -- ---------------------------------------------------------------
  -- Dif. Real de la grilla de Consultas de Cuadratura (Form43):
  --   Dif. de Caja = (BEfectivo - Zefectivo) + (BChequeDia - Zchequedia)
  --                + BDolares + BEuros + (Btarjeta - Ztarjeta)
  --                + (BChequeFecha - Zchequefecha)          (SubBuscarOpcion :1074)
  --   (BTicker y Bcmr dan 0 en FACO: FuncBuscarRecTarj filtra cod 9999999)
  --   Dif. Real    = Format(Dif. de Caja) - Format(Compensacion)   (:1084)
  -- Diferencias con la F8 de la Y (por eso se exigen las dos en 0):
  --   * sobres tiporec F8 y DOL (FuncBuscarRecEfectivo :1643);
  --   * dolares {USD} y euros {EUR} de RECMEX (FuncBuscarRecModRec :1703);
  --   * tarjetas: todos los codigos (FuncBuscarRecTarj :1882);
  --   * compensado (StrSumCompensado :441): 'AL' en la lista de
  --     regularizados y sin 'CA' de MOVDET en FACO ({CCCA}).
  -- NULL si la Y no tiene libro de ventas.
  -- FCDVT-56: con p_cierrey = 0 (terminal sin venta) calcula como la fila
  -- "Cierre Y 0" de la grilla: todas las consultas sin filtro de Y (todo el
  -- terminal-dia) y sin exigir libro de ventas (la Z declarada da 0).
  -- ---------------------------------------------------------------
  function fn_dif_real_cc_int (p_fecha in date, p_local in number, p_terminal in number,
                               p_cierrey in number) return number is
    v        t_nums;
    v_dec    number := fn_dec;
    v_cnt    number;
    v_zefe   number; v_zchd number; v_zchf number; v_ztarj number;
    v_befe   number; v_bchd number;
    v_bdol   number; v_beur number;
    v_bchf   number; v_btarj number;
    v_comp   number;
    v_caja   number;
  begin
    -- Declarado en la Y (FuncValorZoY, rama FACO :3344)
    v := fn_sql_nums(fn_r(
      q'[select count(*),
                nvl(sum(r.rec_mefectivo), 0),
                nvl(sum(r.rec_mchkdia), 0),
                nvl(sum(r.rec_mchkfecha), 0),
                nvl(sum(r.rec_mtarj), 0) + nvl(sum(r.rec_msodimac), 0)
           from VTA_{P}LIBVTA l, VTA_{P}ZZZ r
          where l.vta_tiporeg     = '{NIVEL}'
            and l.vta_fecha_venta = :b_fecha
            and l.vta_local       = :b_local
            and l.vta_terminal    = :b_term
            and l.vta_secuencia   = :b_y
            and l.vta_estado      = 'A'
            and l.vta_techkey     = r.rec_techkey]'),
      5, p_fecha, p_local, p_terminal, p_cierrey);
    v_cnt := v(1); v_zefe := v(2); v_zchd := v(3); v_zchf := v(4); v_ztarj := v(5);
    if nvl(v_cnt, 0) = 0 and p_cierrey <> 0 then
      return null;
    end if;

    -- Sobres (FuncBuscarRecEfectivo "EFE" / "CHE"): tiporec F8 o DOL
    v := fn_sql_nums(fn_r(
      q'[select nvl(sum(case when p.prv_tiposobre = 'EFE' then nvl(p.prv_montosobre,0) + nvl(p.prv_montodif,0) end), 0),
                nvl(sum(case when p.prv_tiposobre = 'CHE' then nvl(p.prv_montosobre,0) + nvl(p.prv_montodif,0) end), 0)
           from VTA_{P}PRD p
          where p.prv_fechavta = :b_fecha
            and p.prv_local    = :b_local
            and p.prv_terminal = :b_term
            and p.prv_cierrey  = :b_y
            and (p.prv_tiporec = 'F8' or p.prv_tiporec = 'DOL')]'),
      2, p_fecha, p_local, p_terminal, p_cierrey);
    v_befe := v(1); v_bchd := v(2);

    -- Dolares y euros recaudados (FuncBuscarRecModRec DOLAR / EUROS)
    v := fn_sql_nums(fn_r(
      q'[select nvl(sum(case when x.id_mdareg = {USD} then x.mex_monto end), 0),
                nvl(sum(case when x.id_mdareg = {EUR} then x.mex_monto end), 0)
           from VTA_{P}RECMEX x
          where x.mex_fecha    = :b_fecha
            and x.mex_local    = :b_local
            and x.mex_terminal = :b_term
            and x.mex_cierrey  = :b_y]'),
      2, p_fecha, p_local, p_terminal, p_cierrey);
    v_bdol := v(1); v_beur := v(2);

    -- Cheque a fecha en tesoreria (FuncBuscarRecCheFecha)
    v := fn_sql_nums(fn_r(
      q'[select nvl(sum(t.tes_chefecha), 0)
           from VTA_{P}TESOR t
          where t.tes_fecha    = :b_fecha
            and t.tes_local    = :b_local
            and t.tes_terminal = :b_term
            and t.tes_cierrey  = :b_y]'),
      1, p_fecha, p_local, p_terminal, p_cierrey);
    v_bchf := v(1);

    -- Tarjetas (FuncBuscarRecTarj "tarj"): FACO sin filtro de codigo
    v := fn_sql_nums(fn_r(
      q'[select nvl(sum(t.vta_monto_inf), 0)
           from VTA_{P}TARJ t
          where t.vta_fecha    = :b_fecha
            and t.vta_local    = :b_local
            and t.vta_terminal = :b_term
            and t.vta_cierrey  = :b_y]'),
      1, p_fecha, p_local, p_terminal, p_cierrey);
    v_btarj := v(1);

    -- Compensacion (ValorCompensacion -> Form43.StrSumCompensado).
    -- UNION (no UNION ALL) igual que el exe.
    v := fn_sql_nums(fn_r(
      q'[select nvl(sum(c.mov_monto), 0)
      from (
        -- TC: registrados el dia - regularizados ese dia
        select ( nvl((select sum(m.mov_monto) from VTA_{P}MOVDET m
                       where m.mov_fecha = :b_fecha and m.mov_local = :b_local
                         and m.mov_terminal = :b_term and m.mov_cierrey = :b_y
                         and m.mov_tipomov = 'TC'), 0)
               - nvl((select sum(m.mov_monto) from VTA_{P}MOVDET m
                       where m.mov_fechareg = :b_fecha and m.mov_local = :b_local
                         and m.mov_terminal = :b_term and m.mov_cierrey = :b_y
                         and m.mov_regul = 'S' and m.mov_tipomov = 'TC'), 0) ) mov_monto,
               d.mov_tipomov
          from VTA_{P}CONCEPDIF d
         where d.mov_tipomov = 'TC'
        union
        -- SN, ND, FN: regularizados del dia - regularizados ese dia
        select ( nvl((select sum(m.mov_monto) from VTA_{P}MOVDET m
                       where m.mov_fecha = :b_fecha and m.mov_local = :b_local
                         and m.mov_terminal = :b_term and m.mov_cierrey = :b_y
                         and m.mov_regul = 'S' and m.mov_tipomov = d.mov_tipomov), 0)
               - nvl((select sum(m.mov_monto) from VTA_{P}MOVDET m
                       where m.mov_fechareg = :b_fecha and m.mov_local = :b_local
                         and m.mov_terminal = :b_term and m.mov_cierrey = :b_y
                         and m.mov_regul = 'S' and m.mov_tipomov = d.mov_tipomov), 0) ),
               d.mov_tipomov
          from VTA_{P}CONCEPDIF d
         where d.mov_tipomov in ('SN', 'ND', 'FN')
        union
        -- BF
        select nvl((select sum(m.mov_monto) from VTA_{P}MOVDET m
                     where m.mov_fecha = :b_fecha and m.mov_local = :b_local
                       and m.mov_terminal = :b_term and m.mov_cierrey = :b_y
                       and m.mov_regul = 'S' and m.mov_tipomov = 'BF'), 0),
               d.mov_tipomov
          from VTA_{P}CONCEPDIF d
         where d.mov_tipomov = 'BF'
        union
        -- NP / FT (una fila por concepto de concepdif, cada una con la suma NP+FT)
        select nvl((select sum(m.mov_monto) from VTA_{P}MOVDET m
                     where m.mov_fecha = :b_fecha and m.mov_local = :b_local
                       and m.mov_terminal = :b_term and m.mov_cierrey = :b_y
                       and m.mov_regul = 'S' and m.mov_tipomov in ('NP', 'FT')), 0),
               d.mov_tipomov
          from VTA_{P}CONCEPDIF d
         where d.mov_tipomov in ('NP', 'FT')
        union
        -- Conceptos regularizados (Form43 :738: incluye AL; CA solo si {CCCA})
        select nvl(sum(m.mov_monto), 0), d.mov_tipomov
          from VTA_{P}MOVDET m, VTA_{P}CONCEPDIF d
         where m.mov_fecha = :b_fecha and m.mov_local = :b_local
           and m.mov_terminal = :b_term and m.mov_cierrey = :b_y
           and m.mov_regul = 'S'
           and m.mov_fechareg is not null
           and m.mov_tipomov = d.mov_tipomov
           and d.mov_tipomov in ('AL','TU','DV','P1','P2','CM','CB','CC','SB','SC','SV','CP','CF','CT'{CCCA},
                                 'RE','CR','PC','DN','AF','DD','AA','DI','AV','RP','DP','DE','PM')
         group by d.mov_tipomov
        union
        -- Vendedor / cajero
        select (select nvl(sum(v.ven_monto), 0) from VTA_{P}DIFVEND v
                 where v.ven_fecha = :b_fecha and v.ven_local = :b_local
                   and v.ven_terminal = :b_term and v.ven_cierrey = :b_y),
               d.mov_tipomov
          from VTA_{P}CONCEPDIF d
         where d.vta_coddif = 1
        union
        -- DT / NC con mov_numero <> terminal
        select nvl(sum(m.mov_monto), 0), d.mov_tipomov
          from VTA_{P}MOVDET m, VTA_{P}CONCEPDIF d
         where m.mov_fecha = :b_fecha and m.mov_numero <> m.mov_terminal
           and m.mov_local = :b_local and m.mov_terminal = :b_term
           and m.mov_cierrey = :b_y
           and m.mov_tipomov = d.mov_tipomov
           and d.mov_tipomov in ('DT', 'NC')
         group by d.mov_tipomov
        union
        -- DT / NC con mov_numero = terminal
        select nvl(sum(m.mov_monto), 0), d.mov_tipomov
          from VTA_{P}MOVDET m, VTA_{P}CONCEPDIF d
         where m.mov_fecha = :b_fecha and m.mov_numero = m.mov_terminal
           and m.mov_local = :b_local and m.mov_terminal = :b_term
           and m.mov_cierrey = :b_y
           and m.mov_tipomov = d.mov_tipomov
           and d.mov_tipomov in ('DT', 'NC')
         group by d.mov_tipomov
        union
        -- Carta aviso central (VTA_<pfx>CARTAAVISO)
        select nvl(sum(m.mov_monto), 0), d.mov_tipomov
          from VTA_{P}CARTAAVISO m, VTA_{P}CONCEPDIF d
         where m.mov_fecha = :b_fecha and m.mov_local = :b_local
           and m.mov_terminal = :b_term and m.mov_cierrey = :b_y
           and m.mov_regul = 'S'
           and m.mov_fechareg is not null
           and m.mov_tipomov = d.mov_tipomov
           and d.mov_tipomov = 'CA'
         group by d.mov_tipomov
        union
        -- TB
        select nvl(sum(m.mov_monto), 0), d.mov_tipomov
          from VTA_{P}MOVDET m, VTA_{P}CONCEPDIF d
         where m.mov_fecha = :b_fecha and m.mov_numero = m.mov_terminal
           and m.mov_local = :b_local and m.mov_terminal = :b_term
           and m.mov_cierrey = :b_y
           and m.mov_tipomov = d.mov_tipomov
           and d.mov_tipomov = 'TB'
         group by d.mov_tipomov
      ) c]'),
      1, p_fecha, p_local, p_terminal, p_cierrey);
    v_comp := v(1);

    v_caja := (v_befe - v_zefe) + (v_bchd - v_zchd) + v_bdol + v_beur
            + (v_btarj - v_ztarj) + (v_bchf - v_zchf);
    -- Format(x, gFormat) redondea cada termino antes de restar
    return round(round(v_caja, v_dec) - round(v_comp, v_dec), v_dec);
  end fn_dif_real_cc_int;

  -- ---------------------------------------------------------------
  -- Mensajes de conceptos pendientes (CierraTerminalYYY, mismo orden)
  -- ---------------------------------------------------------------
  function fn_conceptos return t_conceptos is
    v t_conceptos;
  begin
    v('SN') := 'Falta regularizar el Sobres No Enviado declarada, o elimine el registro';
    v('AF') := 'Falta regularizar Atesoramiento Fondo Fijo, o elimine el registro';
    v('ND') := 'Falta regularizar N/D no digitada declarada, o elimine el registro';
    v('FN') := 'Falta regularizar Factura no digitada declarada, o elimine el registro';
    v('NP') := 'Falta regularizar el N/C Publicidad declarada, o elimine el registro';
    v('BF') := 'Falta regularizar el Billete Falso declarada, o elimine el registro';
    v('CR') := 'Falta regularizar el Certificado Regalo declarada, o elimine el registro';
    v('CT') := 'Falta regularizar el carta aviso Tienda declarada, o elimine el registro';
    v('CA') := 'Falta regularizar el carta aviso central declarada, o elimine el registro';
    v('DP') := 'Falta regularizar la Diferencia Prestadora declarada, o elimine el registro';
    return v;
  end fn_conceptos;

  -- ---------------------------------------------------------------
  -- RY-01 Cheque a fecha: gestion de cheques (tipo 1) = tesoreria
  -- (Func_ValorGestionCheque / Func_ValorChequeFecha, Modulo1.bas:5681 /
  -- :5632): dia completo del terminal, sin filtro de Y, igual que el exe.
  -- ---------------------------------------------------------------
  function fn_msg_cheque_fecha (p_fecha in date, p_local in number, p_terminal in number)
    return varchar2 is
    v         t_nums;
    v_dec     number := fn_dec;
    v_gestion number;
    v_tesor   number;
  begin
    v := fn_sql_nums(fn_r(
      q'[select nvl(sum(c.chq_monto), 0)
           from VTA_{P}CHEQUES c
          where c.chq_fecha = :b_fecha and c.chq_local = :b_local
            and c.chq_terminal = :b_term and c.chq_tipocheque = 1]'),
      1, p_fecha, p_local, p_terminal, null);
    v_gestion := v(1);

    v := fn_sql_nums(fn_r(
      q'[select nvl(sum(t.tes_chefecha), 0)
           from VTA_{P}TESOR t
          where t.tes_fecha = :b_fecha and t.tes_local = :b_local and t.tes_terminal = :b_term]'),
      1, p_fecha, p_local, p_terminal, null);
    v_tesor := v(1);

    if round(v_gestion, v_dec) <> round(v_tesor, v_dec) then
      return 'Existe diferencia para el concepto cheques a Fecha entre la Gestion de Cheque : ( '
             || v_gestion || ' ) versus columna tesoreria : ( ' || v_tesor || ' ) , para poder cerrar Y.';
    end if;
    return null;
  end fn_msg_cheque_fecha;

  -- ---------------------------------------------------------------
  -- RY-03 Concepto declarado sin regularizar en la Y (FuncvalidarConcepto
  -- :4820): CA se busca en CARTAAVISO, el resto en MOVDET.
  -- ---------------------------------------------------------------
  function fn_concepto_pendiente (p_fecha in date, p_local in number, p_terminal in number,
                                  p_cierrey in number, p_tipo in varchar2) return boolean is
    v t_nums;
  begin
    v := fn_sql_nums(fn_r(
      case when p_tipo = 'CA' then
        q'[select count(*)
             from VTA_{P}CARTAAVISO m
            where m.mov_fecha = :b_fecha and m.mov_local = :b_local and m.mov_terminal = :b_term
              and (m.mov_regul is null or m.mov_regul in (' ', 'N'))
              and m.mov_tipomov = :b_txt
              and m.mov_cierrey = :b_y]'
      else
        q'[select count(*)
             from VTA_{P}MOVDET m
            where m.mov_fecha = :b_fecha and m.mov_local = :b_local and m.mov_terminal = :b_term
              and (m.mov_regul is null or m.mov_regul in (' ', 'N'))
              and m.mov_tipomov = :b_txt
              and m.mov_cierrey = :b_y]'
      end),
      1, p_fecha, p_local, p_terminal, p_cierrey, p_tipo);
    return nvl(v(1), 0) > 0;
  end fn_concepto_pendiente;

  -- ---------------------------------------------------------------
  -- RY-06 Formula ZZZ de la Y (FuncValidaZZZ + FuncMontoValidaZZZYY).
  -- Diferencia = F7 - F6 - F5 - F4 - F3 - F2 - F1, con F(k) armada desde
  -- VTA_PAINT_Z.vta_validadorzzz = k (filas del pais: vta_localiz). Corrige
  -- el bug del exe (pasaba el local en vez del numero de Y). Solo si el
  -- parametro CD_VAL_ZZZ = S (el exe la aplica solo con la opcion 103).
  -- FCDVT-56: con p_cierrey = 0 es la formula de la Z (FuncMontoValidaZZZ,
  -- Modulo1.bas:4105, que usa CierraTerminal): libro de ventas 'F8', sin Y.
  -- ---------------------------------------------------------------
  function fn_zzz (p_fecha in date, p_local in number, p_terminal in number,
                   p_cierrey in number) return number is
    type t_num is table of number index by pls_integer;
    v_f    t_num;
    v_expr varchar2(4000);
    v_sql  varchar2(4000);
  begin
    for k in 1 .. 7 loop
      v_expr := null;
      for r in (select z.vta_cmp_asoc, z.vta_signo
                  from VTA_PAINT_Z z
                 where z.vta_localiz = g_cfg.localiz
                   and z.vta_validadorzzz = k
                   and z.vta_cmp_asoc is not null
                 order by z.vta_order_z) loop
        v_expr := v_expr || case when v_expr is not null then ' + ' end
               || 'nvl(sum(' || r.vta_cmp_asoc || '),0) * ' || nvl(trim(r.vta_signo), '+') || '1';
      end loop;

      if v_expr is null then
        v_f(k) := 0;
      else
        v_sql := 'select ' || v_expr ||
                 ' from VTA_{P}LIBVTA l, VTA_{P}ZZZ r' ||
                 ' where l.vta_fecha_venta = :f and l.vta_local = :lo and l.vta_terminal = :te' ||
                 q'[ and l.vta_estado = 'A' and l.vta_techkey = r.rec_techkey]';
        if nvl(p_cierrey, 0) = 0 then
          v_sql := v_sql || q'[ and l.vta_tiporeg = 'F8']';
          execute immediate fn_r(v_sql) into v_f(k) using p_fecha, p_local, p_terminal;
        else
          v_sql := v_sql || q'[ and l.vta_tiporeg = '{NIVEL}' and l.vta_secuencia = :y]';
          execute immediate fn_r(v_sql) into v_f(k) using p_fecha, p_local, p_terminal, p_cierrey;
        end if;
        v_f(k) := nvl(v_f(k), 0);
      end if;
    end loop;
    return round(v_f(7) - v_f(6) - v_f(5) - v_f(4) - v_f(3) - v_f(2) - v_f(1), fn_dec);
  end fn_zzz;

  -- ---------------------------------------------------------------
  -- Validaciones de CierraTerminalYYY (FACO), en su orden:
  -- RY-01 cheque a fecha, RY-03 conceptos, RY-06 ZZZ.
  -- ---------------------------------------------------------------
  procedure pr_valida_y (p_fecha    in  date,
                         p_local    in  number,
                         p_terminal in  number,
                         p_cierrey  in  number,
                         o_regla    out varchar2,
                         o_mensaje  out varchar2) is
    v_c   t_conceptos := fn_conceptos;
    v_k   varchar2(2);
    v_zzz number;
  begin
    o_regla := null; o_mensaje := null;

    -- RY-01 cheque a fecha
    if fn_param('CD_VAL_CHEQ', 'S') = 'S' then
      o_mensaje := fn_msg_cheque_fecha(p_fecha, p_local, p_terminal);
      if o_mensaje is not null then o_regla := 'RY-01'; return; end if;
    end if;

    -- RY-03 conceptos sin regularizar en la Y (orden del exe)
    for i in 1 .. 10 loop
      v_k := case i when 1 then 'SN' when 2 then 'AF' when 3 then 'ND' when 4 then 'FN'
                    when 5 then 'NP' when 6 then 'BF' when 7 then 'CR' when 8 then 'CT'
                    when 9 then 'CA' else 'DP' end;
      if fn_concepto_pendiente(p_fecha, p_local, p_terminal, p_cierrey, v_k) then
        o_regla := 'RY-03'; o_mensaje := v_c(v_k); return;
      end if;
    end loop;

    -- RY-06 formula ZZZ (opcion 103 del exe; aqui parametro)
    if fn_param('CD_VAL_ZZZ', 'N') = 'S' then
      v_zzz := fn_zzz(p_fecha, p_local, p_terminal, p_cierrey);
      if v_zzz <> 0 then
        o_regla := 'RY-06';
        o_mensaje := 'Error, Y descuadrada, favor revisar... diferencia : ' || v_zzz;
        return;
      end if;
    end if;
  end pr_valida_y;

  -- ---------------------------------------------------------------
  -- Proceso de una caja (cierre Y). o_resultado = log_resultado:
  -- CERRADA, CON_DIFERENCIA, CON_DIFERENCIA_CC, BLOQUEADA, SIN_LIBVTA,
  -- SIN_TERMSTAT, YA_CERRADA, OCUPADA, ERROR. Commit por caja.
  -- ---------------------------------------------------------------
  procedure pr_procesa_y (p_fecha in date, p_local in number, p_terminal in number,
                          p_cierrey in number, o_resultado out varchar2) is
    v_estado  number;
    v_dr      number;
    v_dr_cc   number;
    v_regla   varchar2(10);
    v_msg     varchar2(1000);
  begin
    savepoint sp_y;

    -- La Y debe existir, estar Pendiente y no estar tomada por otro usuario
    begin
      execute immediate fn_r(
        q'[select t.ter_estado
             from VTA_{P}{EST} t
            where t.ter_fecha = :1 and t.ter_local = :2
              and t.ter_terminal = :3 and t.ter_cierrey = :4
              for update nowait]')
        into v_estado
        using p_fecha, p_local, p_terminal, p_cierrey;
    exception
      when no_data_found then
        o_resultado := 'SIN_TERMSTAT';
        pr_log(p_fecha, p_local, p_terminal, p_cierrey, null, null, o_resultado, null,
               'No existe el cierre Y en VTA_' || g_cfg.prefijo || g_cfg.tabla_est);
        return;
      when e_ocupada then
        o_resultado := 'OCUPADA';
        pr_log(p_fecha, p_local, p_terminal, p_cierrey, null, null, o_resultado, null,
               'Caja bloqueada por otro usuario: queda para la proxima ejecucion');
        return;
    end;

    -- Estado: 1 cerrado, 2 impreso, 3 sin datos -> no se toca
    if v_estado > 0 then
      rollback to sp_y;
      o_resultado := 'YA_CERRADA';
      pr_log(p_fecha, p_local, p_terminal, p_cierrey, null, null, o_resultado, null,
             'Terminal ya se Encuentra Cerrado (estado ' || v_estado || ')');
      return;
    end if;

    -- RY-05 Dif. Real de la F8 de la Y
    v_dr := fn_dif_real_f8(p_fecha, p_local, p_terminal, p_cierrey);
    if v_dr is null then
      rollback to sp_y;
      o_resultado := 'SIN_LIBVTA';
      pr_log(p_fecha, p_local, p_terminal, p_cierrey, null, null, o_resultado, null,
             'No hay Z disponible (sin libro de ventas de la Y)');
      return;
    end if;

    -- Dif. Real de la grilla de Consultas de Cuadratura
    v_dr_cc := fn_dif_real_cc_int(p_fecha, p_local, p_terminal, p_cierrey);

    if v_dr <> 0 then
      rollback to sp_y;
      o_resultado := 'CON_DIFERENCIA';
      pr_log(p_fecha, p_local, p_terminal, p_cierrey, v_dr, v_dr_cc, o_resultado, 'RY-05',
             'Falta Monto por Compensar (Dif. Real de la F8 de la Y ' || v_dr || ')');
      return;
    elsif nvl(v_dr_cc, 1) <> 0 then
      rollback to sp_y;
      o_resultado := 'CON_DIFERENCIA_CC';
      pr_log(p_fecha, p_local, p_terminal, p_cierrey, v_dr, v_dr_cc, o_resultado, 'RY-05',
             'Dif. Real 0 en la F8 de la Y pero ' || nvl(to_char(v_dr_cc), 'nula') ||
             ' en Consultas de Cuadratura: revisar sobres DOL, euros, tarjetas o conceptos AL/CA');
      return;
    end if;

    -- Validaciones de Cerrar Terminal
    pr_valida_y(p_fecha, p_local, p_terminal, p_cierrey, v_regla, v_msg);
    if v_regla is not null then
      rollback to sp_y;
      o_resultado := 'BLOQUEADA';
      pr_log(p_fecha, p_local, p_terminal, p_cierrey, v_dr, v_dr_cc, o_resultado, v_regla, v_msg);
      return;
    end if;

    -- Cierre (CierraTerminalYYY :4742): estado 1 y usuario del proceso
    execute immediate fn_r(
      q'[update VTA_{P}{EST} t
            set t.ter_estado     = 1,
                t.ter_cerradopor = :1
          where t.ter_fecha = :2 and t.ter_local = :3
            and t.ter_terminal = :4 and t.ter_cierrey = :5]')
      using g_usuario, p_fecha, p_local, p_terminal, p_cierrey;

    commit;
    o_resultado := 'CERRADA';
    pr_log(p_fecha, p_local, p_terminal, p_cierrey, v_dr, v_dr_cc, o_resultado, null, null);

  exception
    when others then
      v_msg := substr(sqlerrm, 1, 1000);
      begin
        rollback to sp_y;
      exception
        when others then rollback;   -- ORA-01086: el savepoint ya no existe
      end;
      o_resultado := 'ERROR';
      pr_log(p_fecha, p_local, p_terminal, p_cierrey, v_dr, v_dr_cc, o_resultado, null, v_msg);
  end pr_procesa_y;

  -- ===============================================================
  -- FCDVT-56 (22-10-2026): etapa SIN VENTA, cierre de la Z de los
  -- terminales vigentes sin libro de ventas Y ni Y creada.
  -- Simula el segundo recorrido de Form43.Command4_Click (Cierre Y = 0,
  -- Dif. Real 0) -> Form43.CierraTerminal :4077.
  -- ===============================================================

  -- RZ-02 Z contra suma de las Y (FuncValidarZSumaY, Modulo1.bas:5531):
  -- por cada monto de VTA_PAINT_Z del pais (pop_up 0, orden fuera de 56-76),
  -- libro de ventas F8 (Z) = suma del libro de ventas de las Y.
  -- NULL si cuadra; si no, el mensaje del exe.
  function fn_msg_z_suma_y (p_fecha in date, p_local in number, p_terminal in number)
    return varchar2 is
    v   t_nums;
    v_z number;
    v_y number;
  begin
    -- Sin libro de ventas F8 todos los montos de la Z dan 0, y en esta etapa
    -- el terminal tampoco tiene libro de ventas Y: cuadra sin mas consultas.
    v := fn_sql_nums(fn_r(
      q'[select count(*)
           from VTA_{P}LIBVTA l, VTA_{P}ZZZ r, VTA_{P}{ESTZ} t
          where l.vta_tiporeg     = 'F8'
            and l.vta_fecha_venta = :b_fecha
            and l.vta_local       = :b_local
            and l.vta_terminal    = :b_term
            and l.vta_estado      = 'A'
            and l.vta_techkey     = r.rec_techkey
            and l.vta_fecha_venta = t.ter_fecha
            and l.vta_local       = t.ter_local
            and l.vta_terminal    = t.ter_terminal]'),
      1, p_fecha, p_local, p_terminal, null);
    if nvl(v(1), 0) = 0 then
      return null;
    end if;

    for c in (select z.vtaglosa_z glosa, z.vta_cmp_asoc campo
                from VTA_PAINT_Z z
               where z.vta_localiz = g_cfg.localiz
                 and nvl(z.vta_pop_up, 0) = 0
                 and (z.vta_order_z < 56 or z.vta_order_z > 76)
                 and z.vta_cmp_asoc is not null
               order by z.vta_order_z) loop
      v := fn_sql_nums(fn_r(
        'select nvl(sum(' || c.campo || '), 0)' ||
        q'[ from VTA_{P}LIBVTA l, VTA_{P}ZZZ r, VTA_{P}{ESTZ} t
           where l.vta_tiporeg = 'F8'
             and l.vta_fecha_venta = :b_fecha and l.vta_local = :b_local and l.vta_terminal = :b_term
             and l.vta_estado = 'A' and l.vta_techkey = r.rec_techkey
             and l.vta_fecha_venta = t.ter_fecha and l.vta_local = t.ter_local
             and l.vta_terminal = t.ter_terminal]'),
        1, p_fecha, p_local, p_terminal, null);
      v_z := nvl(v(1), 0);
      v := fn_sql_nums(fn_r(
        'select nvl(sum(' || c.campo || '), 0)' ||
        q'[ from VTA_{P}LIBVTA l, VTA_{P}ZZZ r, VTA_{P}{EST} t
           where l.vta_tiporeg = '{NIVEL}'
             and l.vta_fecha_venta = :b_fecha and l.vta_local = :b_local and l.vta_terminal = :b_term
             and l.vta_estado = 'A' and l.vta_techkey = r.rec_techkey
             and l.vta_fecha_venta = t.ter_fecha and l.vta_local = t.ter_local
             and l.vta_terminal = t.ter_terminal and l.vta_secuencia = t.ter_cierrey]'),
        1, p_fecha, p_local, p_terminal, null);
      v_y := nvl(v(1), 0);
      if v_z - v_y <> 0 then
        return 'En el monto ' || c.glosa || ' Existe diferencia entre el Z y la sumatoria de las Y';
      end if;
    end loop;
    return null;
  end fn_msg_z_suma_y;

  -- RZ-04 Dolares declarados contra Prosegur (FuncvalidarDifDolares :4477;
  -- el exe lo aplica solo con la opcion Btovalidacionprddolar del perfil,
  -- aqui con el parametro CD_VAL_DOL). NULL si cuadra.
  function fn_msg_dolares (p_fecha in date, p_local in number, p_terminal in number)
    return varchar2 is
    v t_nums;
  begin
    v := fn_sql_nums(fn_r(
      q'[select nvl(sum(a.monto), 0)
           from (select sum(nvl(x.mex_cantidad, 0) * -1) monto
                   from VTA_{P}RECMEX x
                  where x.mex_fecha    = :b_fecha
                    and x.mex_local    = :b_local
                    and x.id_mdareg    = {USD}
                    and x.mex_terminal = :b_term
                 union all
                 select sum(p.prv_montosobre) + sum(p.prv_montodif)
                   from VTA_{P}PRD p
                  where p.prv_fechavta = :b_fecha
                    and p.prv_tiporec  = 'DOL'
                    and p.prv_local    = :b_local
                    and p.prv_terminal = :b_term) a]'),
      1, p_fecha, p_local, p_terminal, null);
    if nvl(v(1), 0) <> 0 then
      return 'Error, existen diferencias entre los dolares declarados y los dolares informado por Prosegur, '
             || 'favor revisar... diferencia ' || v(1);
    end if;
    return null;
  end fn_msg_dolares;

  -- Validaciones de Form43.CierraTerminal (FACO), en su orden:
  -- RZ-01 conceptos sin regularizar del dia (FuncvalidarConcepto sin Y),
  -- RZ-02 Z contra suma de Y, RZ-03 formula ZZZ de la Z, RZ-04 dolares.
  -- FuncValidadCierreyyyy no se replica: sin libro de ventas Y no tiene
  -- filas y el exe la da por buena.
  procedure pr_valida_z (p_fecha    in  date,
                         p_local    in  number,
                         p_terminal in  number,
                         o_regla    out varchar2,
                         o_mensaje  out varchar2) is
    v_c   t_conceptos := fn_conceptos;
    v_k   varchar2(2);
    v_zzz number;
  begin
    o_regla := null; o_mensaje := null;

    -- RZ-01 conceptos (mismo orden que CierraTerminal; Y = 0: todo el dia)
    for i in 1 .. 10 loop
      v_k := case i when 1 then 'SN' when 2 then 'AF' when 3 then 'ND' when 4 then 'FN'
                    when 5 then 'NP' when 6 then 'BF' when 7 then 'CR' when 8 then 'CT'
                    when 9 then 'CA' else 'DP' end;
      if fn_concepto_pendiente(p_fecha, p_local, p_terminal, 0, v_k) then
        o_regla := 'RZ-01'; o_mensaje := v_c(v_k); return;
      end if;
    end loop;

    -- RZ-02 Z contra suma de las Y
    o_mensaje := fn_msg_z_suma_y(p_fecha, p_local, p_terminal);
    if o_mensaje is not null then o_regla := 'RZ-02'; return; end if;

    -- RZ-03 formula ZZZ de la Z (opcion Btovalidacionzzz del exe; aqui parametro)
    if fn_param('CD_VAL_ZZZ', 'N') = 'S' then
      v_zzz := fn_zzz(p_fecha, p_local, p_terminal, 0);
      if v_zzz <> 0 then
        o_regla := 'RZ-03';
        o_mensaje := 'Error, Z descuadrada, favor revisar... diferencia : ' || v_zzz;
        return;
      end if;
    end if;

    -- RZ-04 dolares contra Prosegur (opcion Btovalidacionprddolar; aqui parametro)
    if fn_param('CD_VAL_DOL', 'N') = 'S' then
      o_mensaje := fn_msg_dolares(p_fecha, p_local, p_terminal);
      if o_mensaje is not null then o_regla := 'RZ-04'; return; end if;
    end if;
  end pr_valida_z;

  -- Proceso de un terminal sin venta (cierre de la Z). o_resultado =
  -- log_resultado: CERRADA_SIN_VENTA, CON_DIFERENCIA_CC, BLOQUEADA,
  -- SIN_TERMSTAT, YA_CERRADA, OCUPADA, ERROR. Commit por terminal.
  procedure pr_procesa_z (p_fecha in date, p_local in number, p_terminal in number,
                          o_resultado out varchar2) is
    v_est   t_nums;
    v_max   number;
    v_dr_cc number;
    v_regla varchar2(10);
    v_msg   varchar2(1000);
  begin
    savepoint sp_z;

    -- La Z debe existir, estar Pendiente y no estar tomada por otro usuario
    begin
      execute immediate fn_r(
        q'[select t.ter_estado
             from VTA_{P}{ESTZ} t
            where t.ter_fecha = :1 and t.ter_local = :2 and t.ter_terminal = :3
              for update nowait]')
        bulk collect into v_est
        using p_fecha, p_local, p_terminal;
    exception
      when e_ocupada then
        o_resultado := 'OCUPADA';
        pr_log(p_fecha, p_local, p_terminal, 0, null, null, o_resultado, null,
               'Terminal bloqueado por otro usuario: queda para la proxima ejecucion');
        return;
    end;
    if v_est.count = 0 then
      o_resultado := 'SIN_TERMSTAT';
      pr_log(p_fecha, p_local, p_terminal, 0, null, null, o_resultado, null,
             'No existe la Z en VTA_' || g_cfg.prefijo || g_cfg.tabla_z);
      return;
    end if;
    v_max := nvl(v_est(v_est.first), 0);
    for i in v_est.first .. v_est.last loop
      v_max := greatest(v_max, nvl(v_est(i), 0));
    end loop;

    -- Estado: 1 cerrado, 2 impreso, 3 sin datos -> no se toca
    if v_max > 0 then
      rollback to sp_z;
      o_resultado := 'YA_CERRADA';
      pr_log(p_fecha, p_local, p_terminal, 0, null, null, o_resultado, null,
             'Terminal ya se Encuentra Cerrado (estado ' || v_max || ')');
      return;
    end if;

    -- Dif. Real de la fila "Cierre Y 0" de CC (Command4_Click exige 0).
    -- Si llegaron sobres, retiros o compensaciones del dia no da 0.
    v_dr_cc := fn_dif_real_cc_int(p_fecha, p_local, p_terminal, 0);
    if nvl(v_dr_cc, 1) <> 0 then
      rollback to sp_z;
      o_resultado := 'CON_DIFERENCIA_CC';
      pr_log(p_fecha, p_local, p_terminal, 0, null, v_dr_cc, o_resultado, 'RZ-05',
             'Terminal sin venta con Dif. Real ' || nvl(to_char(v_dr_cc), 'nula') ||
             ' en Consultas de Cuadratura (sobres, retiros o compensaciones del dia)');
      return;
    end if;

    -- Validaciones de CierraTerminal
    pr_valida_z(p_fecha, p_local, p_terminal, v_regla, v_msg);
    if v_regla is not null then
      rollback to sp_z;
      o_resultado := 'BLOQUEADA';
      pr_log(p_fecha, p_local, p_terminal, 0, null, v_dr_cc, o_resultado, v_regla, v_msg);
      return;
    end if;

    -- Cierre (CierraTerminal :4262): estado 1 y usuario del proceso
    execute immediate fn_r(
      q'[update VTA_{P}{ESTZ} t
            set t.ter_estado     = 1,
                t.ter_cerradopor = :1
          where t.ter_fecha = :2 and t.ter_local = :3 and t.ter_terminal = :4]')
      using g_usuario, p_fecha, p_local, p_terminal;

    commit;
    o_resultado := 'CERRADA_SIN_VENTA';
    pr_log(p_fecha, p_local, p_terminal, 0, null, v_dr_cc, o_resultado, null,
           'Z cerrada (estado anterior ' || v_max || ')');

  exception
    when others then
      v_msg := substr(sqlerrm, 1, 1000);
      begin
        rollback to sp_z;
      exception
        when others then rollback;   -- ORA-01086: el savepoint ya no existe
      end;
      o_resultado := 'ERROR';
      pr_log(p_fecha, p_local, p_terminal, 0, null, v_dr_cc, o_resultado, null, v_msg);
  end pr_procesa_z;

  -- Universo de la etapa SIN VENTA (SQL para open ... using fecha):
  -- el UNION de Form43.FuncStrPivote (FCDVT-56) para todos los locales,
  -- solo Z Pendientes y sin ninguna Y creada (decision del 22-10).
  function fn_sql_universo_z return varchar2 is
  begin
    return fn_r(
      q'[select distinct z.ter_fecha, z.ter_local, z.ter_terminal
           from VTA_{P}{ESTZ} z, VTA_{P}TERMINALES s
          where z.ter_fecha     = :1
            and z.ter_estado   <= 0
            and s.ter_local     = z.ter_local
            and s.ter_terminal  = z.ter_terminal
            and (s.ter_fechabaja is null or s.ter_fechabaja >= z.ter_fecha)
            and not exists (select 1 from VTA_{P}LIBVTA v
                             where v.vta_tiporeg     = '{NIVEL}'
                               and v.vta_estado      = 'A'
                               and v.vta_fecha_venta = z.ter_fecha
                               and v.vta_local       = z.ter_local
                               and v.vta_terminal    = z.ter_terminal)
            and not exists (select 1 from VTA_{P}{EST} y
                             where y.ter_fecha    = z.ter_fecha
                               and y.ter_local    = z.ter_local
                               and y.ter_terminal = z.ter_terminal)
          order by 1, 2, 3]');
  end fn_sql_universo_z;

  -- S si la etapa SIN VENTA corre para el pais configurado
  function fn_sin_venta_activa return boolean is
  begin
    return nvl(g_cfg.sin_venta, 'N') = 'S' and fn_param('CD_SIN_VENTA', 'N') = 'S';
  end fn_sin_venta_activa;

  -- ---------------------------------------------------------------
  -- Cierre diario (con resumen)
  -- ---------------------------------------------------------------
  procedure prc_cierre_diario (p_flg_pais    in  varchar2,
                               p_fecha       in  date,
                               p_usuario     in  varchar2,
                               o_ejecucion   out number,
                               o_cerradas    out number,
                               o_no_cerradas out number) is
    v_fecha  date;
    v_cur    sys_refcursor;
    v_f      date;
    v_l      number;
    v_t      number;
    v_y      number;
    v_res    varchar2(30);
    v_n      number := 0;
    v_cdif   number := 0;
    v_bloq   number := 0;
    v_err    number := 0;
    v_otras  number := 0;
    -- FCDVT-56: etapa SIN VENTA
    v_sv     boolean := false;
    v_zn     number := 0;
    v_zc     number := 0;
    v_zdif   number := 0;
    v_zbloq  number := 0;
    v_zerr   number := 0;
    v_zotras number := 0;
  begin
    o_ejecucion   := null;
    o_cerradas    := 0;
    o_no_cerradas := 0;

    pr_config(p_flg_pais);   -- pais no habilitado: ORA-20001 (se propaga)
    g_usuario   := nvl(substr(trim(p_usuario), 1, 50), c_usuario);
    g_ejecucion := fn_nueva_ejecucion;
    o_ejecucion := g_ejecucion;
    v_fecha     := nvl(trunc(p_fecha), trunc(sysdate) - 1);

    if fn_param('CD_ACTIVO', 'N') <> 'S' then
      pr_log(v_fecha, null, null, null, null, null, 'INACTIVO', null,
             'Parametro 1502 CD_ACTIVO distinto de S: no se cierra nada');
      return;
    end if;

    v_sv := fn_sin_venta_activa;
    pr_log(v_fecha, null, null, null, null, null, 'INICIO', null,
           'Pais ' || g_cfg.pais || ' | fecha de venta ' || to_char(v_fecha, 'dd-mm-yyyy') ||
           case when p_fecha is null then ' (dia anterior)' end || ' | usuario ' || g_usuario ||
           ' | sin venta ' || case when v_sv then 'S' else 'N' end);

    -- Universo: Form43.FuncStrPivote (todos los locales de la fecha), solo
    -- cierres Y Pendientes (decision 20-10) y con numero de Y (Command4_Click).
    open v_cur for fn_r(
      q'[select distinct t.ter_fecha, t.ter_local, t.ter_terminal, t.ter_cierrey
           from VTA_{P}LIBVTA l, VTA_{P}ZZZ r, VTA_{P}{EST} t
          where l.vta_tiporeg     = '{NIVEL}'
            and t.ter_fecha       = :1
            and l.vta_estado      = 'A'
            and l.vta_techkey     = r.rec_techkey
            and l.vta_fecha_venta = t.ter_fecha
            and l.vta_local       = t.ter_local
            and l.vta_terminal    = t.ter_terminal
            and l.vta_secuencia   = t.ter_cierrey
            and t.ter_cierrey    <> 0
            and t.ter_estado     <= 0
          order by 1, 2, 3, 4]')
      using v_fecha;
    loop
      fetch v_cur into v_f, v_l, v_t, v_y;
      exit when v_cur%notfound;
      v_n := v_n + 1;
      pr_procesa_y(v_f, v_l, v_t, v_y, v_res);
      if v_res = 'CERRADA' then
        o_cerradas := o_cerradas + 1;
      else
        o_no_cerradas := o_no_cerradas + 1;
        if v_res in ('CON_DIFERENCIA', 'CON_DIFERENCIA_CC') then
          v_cdif := v_cdif + 1;
        elsif v_res = 'BLOQUEADA' then
          v_bloq := v_bloq + 1;
        elsif v_res = 'ERROR' then
          v_err := v_err + 1;
        else
          v_otras := v_otras + 1;
        end if;
      end if;
    end loop;
    close v_cur;

    -- FACO opera solo con cierre Y: la Z (VTA_FACOTERMSTAT) no se toca...
    -- FCDVT-56: ...salvo la de los terminales sin venta, como el segundo
    -- recorrido de Cerrar Terminal de CC (parametro CD_SIN_VENTA).
    if v_sv then
      open v_cur for fn_sql_universo_z using v_fecha;
      loop
        fetch v_cur into v_f, v_l, v_t;
        exit when v_cur%notfound;
        v_zn := v_zn + 1;
        pr_procesa_z(v_f, v_l, v_t, v_res);
        if v_res = 'CERRADA_SIN_VENTA' then
          v_zc := v_zc + 1;
        elsif v_res = 'CON_DIFERENCIA_CC' then
          v_zdif := v_zdif + 1;
        elsif v_res = 'BLOQUEADA' then
          v_zbloq := v_zbloq + 1;
        elsif v_res = 'ERROR' then
          v_zerr := v_zerr + 1;
        else
          v_zotras := v_zotras + 1;
        end if;
      end loop;
      close v_cur;
      o_cerradas    := o_cerradas + v_zc;
      o_no_cerradas := o_no_cerradas + (v_zn - v_zc);
    end if;

    pr_log(v_fecha, null, null, null, null, null, 'FIN', null,
           'Cajas evaluadas: ' || v_n || ' | cerradas: ' || (o_cerradas - v_zc) ||
           ' | con diferencia: ' || v_cdif || ' | bloqueadas: ' || v_bloq ||
           ' | errores: ' || v_err || ' | otras: ' || v_otras ||
           case when v_sv then
             ' || Sin venta evaluados: ' || v_zn || ' | cerrados: ' || v_zc ||
             ' | con diferencia: ' || v_zdif || ' | bloqueados: ' || v_zbloq ||
             ' | errores: ' || v_zerr || ' | otros: ' || v_zotras
           end);
  exception
    when others then
      if v_cur%isopen then
        close v_cur;
      end if;
      rollback;
      if g_cfg.pais is not null and g_ejecucion is not null then
        pr_log(v_fecha, null, null, null, null, null, 'ERROR', null, substr(sqlerrm, 1, 1000));
      end if;
      raise;
  end prc_cierre_diario;

  -- Cierre diario (lo llama nhal1): sin resumen
  procedure prc_cierre_diario (p_flg_pais in varchar2,
                               p_fecha    in date     default null,
                               p_usuario  in varchar2 default 'PROC_CIERRE_DIARIO') is
    v_ej number; v_c number; v_nc number;
  begin
    prc_cierre_diario(p_flg_pais, p_fecha, p_usuario, v_ej, v_c, v_nc);
  end prc_cierre_diario;

  -- ---------------------------------------------------------------
  -- Funciones publicas de solo lectura
  -- ---------------------------------------------------------------
  function fn_dif_real_cc (p_flg_pais in varchar2,
                           p_fecha    in date,
                           p_local    in number,
                           p_terminal in number,
                           p_cierrey  in number) return number is
  begin
    pr_config(p_flg_pais);
    return fn_dif_real_cc_int(trunc(p_fecha), p_local, p_terminal, p_cierrey);
  end fn_dif_real_cc;

  function fn_evalua_caja (p_flg_pais in varchar2,
                           p_fecha    in date,
                           p_local    in number,
                           p_terminal in number,
                           p_cierrey  in number) return varchar2 is
    v       t_nums;
    v_fecha date := trunc(p_fecha);
    v_dr    number;
    v_dr_cc number;
    v_regla varchar2(10);
    v_msg   varchar2(1000);
  begin
    pr_config(p_flg_pais);
    if fn_param('CD_ACTIVO', 'N') <> 'S' then
      return 'INACTIVO';
    end if;

    -- FCDVT-56: Y = 0 simula la etapa SIN VENTA (cierre de la Z)
    if nvl(p_cierrey, 0) = 0 then
      if not fn_sin_venta_activa then
        return 'INACTIVO SIN_VENTA (CD_SIN_VENTA)';
      end if;
      v := fn_sql_nums(fn_r(
        q'[select (select count(*) from VTA_{P}{ESTZ} t
                    where t.ter_fecha = :b_fecha and t.ter_local = :b_local and t.ter_terminal = :b_term),
                  (select max(t.ter_estado) from VTA_{P}{ESTZ} t
                    where t.ter_fecha = :b_fecha and t.ter_local = :b_local and t.ter_terminal = :b_term),
                  (select count(*) from VTA_{P}TERMINALES s
                    where s.ter_local = :b_local and s.ter_terminal = :b_term
                      and (s.ter_fechabaja is null or s.ter_fechabaja >= :b_fecha)),
                  (select count(*) from VTA_{P}LIBVTA l
                    where l.vta_tiporeg = '{NIVEL}' and l.vta_estado = 'A'
                      and l.vta_fecha_venta = :b_fecha and l.vta_local = :b_local
                      and l.vta_terminal = :b_term),
                  (select count(*) from VTA_{P}{EST} y
                    where y.ter_fecha = :b_fecha and y.ter_local = :b_local and y.ter_terminal = :b_term)
             from dual]'),
        5, v_fecha, p_local, p_terminal, null);
      if nvl(v(1), 0) = 0 then
        return 'SIN_TERMSTAT';
      elsif v(2) > 0 then
        return 'YA_CERRADA';
      elsif nvl(v(3), 0) = 0 then
        return 'DADO_DE_BAJA';
      elsif nvl(v(4), 0) > 0 then
        return 'CON_VENTA (va por la etapa de la Y)';
      elsif nvl(v(5), 0) > 0 then
        return 'ESPERA_SOBRES (ya tiene Y creada)';
      end if;

      v_dr_cc := fn_dif_real_cc_int(v_fecha, p_local, p_terminal, 0);
      if nvl(v_dr_cc, 1) <> 0 then
        return 'CON_DIFERENCIA_CC ' || nvl(to_char(v_dr_cc), 'nula');
      end if;

      pr_valida_z(v_fecha, p_local, p_terminal, v_regla, v_msg);
      if v_regla is not null then
        return substr('BLOQUEADA ' || v_regla || ': ' || v_msg, 1, 400);
      end if;
      return 'CERRABLE_SIN_VENTA';
    end if;

    v := fn_sql_nums(fn_r(
      q'[select count(*), max(t.ter_estado)
           from VTA_{P}{EST} t
          where t.ter_fecha = :b_fecha and t.ter_local = :b_local
            and t.ter_terminal = :b_term and t.ter_cierrey = :b_y]'),
      2, v_fecha, p_local, p_terminal, p_cierrey);
    if nvl(v(1), 0) = 0 then
      return 'SIN_TERMSTAT';
    elsif v(2) > 0 then
      return 'YA_CERRADA';
    end if;

    v_dr := fn_dif_real_f8(v_fecha, p_local, p_terminal, p_cierrey);
    if v_dr is null then
      return 'SIN_LIBVTA';
    elsif v_dr <> 0 then
      return 'CON_DIFERENCIA ' || v_dr;
    end if;

    v_dr_cc := fn_dif_real_cc_int(v_fecha, p_local, p_terminal, p_cierrey);
    if nvl(v_dr_cc, 1) <> 0 then
      return 'CON_DIFERENCIA_CC ' || nvl(to_char(v_dr_cc), 'nula');
    end if;

    pr_valida_y(v_fecha, p_local, p_terminal, p_cierrey, v_regla, v_msg);
    if v_regla is not null then
      return substr('BLOQUEADA ' || v_regla || ': ' || v_msg, 1, 400);
    end if;
    return 'CERRABLE';
  end fn_evalua_caja;

end PKG_F8_CIERRE_DIARIO;
/
