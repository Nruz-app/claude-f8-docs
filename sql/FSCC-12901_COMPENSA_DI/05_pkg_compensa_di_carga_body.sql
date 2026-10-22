-- =====================================================================
-- FSCC-12901 COMPENSA_DI - Paso 05
-- Cuerpo de PKG_F8_COMPENSA_DI_CARGA   (Oracle 10.2)
-- MULTIPAIS (habilitado: FACO)
-- xintec-nruz 19-10-2026 / 20-10-2026 (multipais)
-- Version anterior (solo FACO, SQL estatico, la del 19-10 probada en test):
--   anterior_20-10/05_pkg_compensa_di_carga_body.sql
--
-- Misma logica, mismos resultados y mensajes que la version anterior; cambia
-- solo como se arman las tablas:
--   * el pais llega por parametro (P_FLG_PAIS = Flg_Pais$ del exe) y
--     PR_CONFIG fija su configuracion desde una LISTA BLANCA (el texto
--     recibido nunca se concatena en el SQL);
--   * el SQL se escribe con marcas que FN_R reemplaza:
--         {P}      prefijo de tablas            VTA_{P}MOVDET -> VTA_FACOMOVDET
--         {EST}    tabla de estado del cierre   VTA_{P}{EST}  -> VTA_FACOTERMSTATY
--         {NIVEL}  vta_tiporeg del libro de ventas del cierre ('Y')
--         {TMIN} / {TMAX}  rango de codigos de tarjetas recaudadas
--         {USD}    codigo de moneda dolar (cmn_mdareg)
--         {SEQMOV} secuencia del techkey de VTA_<pfx>MOVDET
--         {FVEN}   filtro extra de VTA_<pfx>DIFVEND (FACO: ninguno)
--   * lecturas con DBMS_SQL y binds por nombre (:b_fecha, :b_local, :b_term,
--     :b_y, :b_txt), que enlaza todas las apariciones; escrituras con
--     EXECUTE IMMEDIATE ... USING.
--
-- Fuentes:
--   * pr_config / fn_r / fn_sql_nums / fn_param: PKG_F8_CIERRE_AUTO (v2
--     multipais, docs/sql/FSCC-12901_PROC_Y/07_pkg_cierre_auto_body.sql:64-215).
--   * pr_cuadratura: PKG_F8_CIERRE_AUTO.pr_cuadratura (mismo archivo, :354),
--     validada en las pruebas 1 a 3 de test.
--   * pr_registra_di: PKG_F8_COMPENSA_DI_AUTO.pr_registra_di
--     (docs/sql/FSCC-12901_PROC_Y/06_pkg_compensa_di_body.sql) con la glosa nueva.
-- Referencias al exe VB6 (FTEPROD/):
--   Form3Y.FormateaDatos :2704 (DR = sumaBZ - compensado redondeado)
--   Modulo1.StrSumCompensado :2630   Modulo1.InsertarRegistroMovDet :3777
--   Form38 (DI manual)   Form45.GrabarObs (observacion en VTA_<pfx>COMPDES)
--
-- Para habilitar otro pais ver 00_LEEME.md ("Multipais").
-- =====================================================================

create or replace package body PKG_F8_COMPENSA_DI_CARGA as

  c_tipo_param constant number       := 1502;
  c_glosa_ant  constant varchar2(60) := 'COMPENSACION AUTOMATICA DE DI';  -- glosa del 19-10 (ya grabada en test); xintec-nruz 20-10-2026
  c_pais_compat constant varchar2(10) := 'FACO';   -- firmas sin pais (compatibilidad)

  -- ---------------------------------------------------------------
  -- Configuracion del pais
  -- ---------------------------------------------------------------
  type t_cfg is record (
    pais        varchar2(10),   -- valor de Flg_Pais$ recibido (normalizado)
    prefijo     varchar2(10),   -- prefijo de tablas VTA_<prefijo>...
    tabla_est   varchar2(30),   -- tabla de estado del cierre (sin VTA_<prefijo>)
    nivel       varchar2(2),    -- vta_tiporeg del libro de ventas del cierre
    tarj_min    number,         -- tarjetas recaudadas: codigos tarj_min..tarj_max
    tarj_max    number,
    mda_usd     number,         -- moneda dolar en VTA_<pfx>RECMEX
    seq_movdet  varchar2(30),   -- secuencia del techkey de VTA_<pfx>MOVDET
    filtro_ven  varchar2(100)   -- filtro extra de VTA_<pfx>DIFVEND (alias v)
  );
  g_cfg t_cfg;

  type t_nums is table of number index by pls_integer;

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
      -- Falabella Colombia: cierre Y (Form3Y), la Z no se gestiona.
      v_cfg.pais       := 'FACO';
      v_cfg.prefijo    := 'FACO';
      v_cfg.tabla_est  := 'TERMSTATY';
      v_cfg.nivel      := 'Y';
      v_cfg.tarj_min   := 2000;     -- FuncLeeTarjeta CTARJ, rama FACO
      v_cfg.tarj_max   := 2999;
      v_cfg.mda_usd    := 305;      -- Modulo1 DOLAR = "305"
      v_cfg.seq_movdet := 'SEQ_VTA_FACOVEN';
      v_cfg.filtro_ven := null;     -- FACO: StrSumCompensado sin filtro VEN_REGUL

    -- -------------------------------------------------------------
    -- EJEMPLO (NO HABILITADO): como se agregaria otro pais con cierre Y,
    -- p. ej. Tottus Chile (Flg_Pais$ = "SFCL"). Antes de habilitarlo:
    --   1. crear VTA_<pfx>LOG_COMPENSA_DI + SEQ_VTA_<pfx>LOG_COMPENSA_DI
    --      (02_log_compensa_di.sql con el prefijo) y los parametros 1502
    --      en VTA_<pfx>PARAM (03_parametros.sql);
    --   2. revisar contra el exe (Form3Y / Modulo1.StrSumCompensado) sus
    --      diferencias de cuadratura: rango de tarjetas, moneda, filtro de
    --      DIFVEND, conceptos del compensado;
    --   3. confirmar la secuencia del techkey (Modulo1.InsertarRegistroMovDet)
    --      y el trigger de VTA_<pfx>COMPDES;
    --   4. en Form133, llamar al paquete tambien para ese Flg_Pais$.
    -- elsif v_pais = 'SFCL' then
    --   v_cfg.pais       := 'SFCL';
    --   v_cfg.prefijo    := 'SFCL';
    --   v_cfg.tabla_est  := 'TERMSTATY';
    --   v_cfg.nivel      := 'Y';
    --   v_cfg.tarj_min   := ...;
    --   v_cfg.tarj_max   := ...;
    --   v_cfg.mda_usd    := 305;
    --   v_cfg.seq_movdet := 'SEQ_VTA_SFCLVEN';
    --   v_cfg.filtro_ven := q'[and v.ven_regul = 'S']';
    -- -------------------------------------------------------------
    else
      raise_application_error(-20001,
        'Pais no habilitado para compensacion automatica de DI: ' || nvl(p_flg_pais, '(nulo)'));
    end if;

    g_cfg := v_cfg;
  end pr_config;

  -- Reemplaza las marcas del SQL con los valores del pais configurado
  function fn_r (p_sql in varchar2) return varchar2 is
  begin
    return replace(replace(replace(replace(replace(replace(replace(replace(p_sql,
             '{P}',      g_cfg.prefijo),
             '{EST}',    g_cfg.tabla_est),
             '{NIVEL}',  g_cfg.nivel),
             '{TMIN}',   to_char(g_cfg.tarj_min)),
             '{TMAX}',   to_char(g_cfg.tarj_max)),
             '{USD}',    to_char(g_cfg.mda_usd)),
             '{SEQMOV}', g_cfg.seq_movdet),
             '{FVEN}',   g_cfg.filtro_ven);
  end fn_r;

  -- Ejecuta un SELECT de una fila y p_ncols columnas numericas con binds por
  -- nombre (:b_fecha, :b_local, :b_term, :b_y, :b_txt; cada uno solo si aparece).
  -- Sin filas devuelve NULL en cada columna.
  function fn_sql_nums (p_sql      in varchar2,
                        p_ncols    in pls_integer,
                        p_fecha    in date,
                        p_local    in number,
                        p_terminal in number,
                        p_cierrey  in number,
                        p_txt      in varchar2 default null) return t_nums is
    c   integer;
    n   integer;
    x   number;
    v   t_nums;
  begin
    c := dbms_sql.open_cursor;
    begin
      dbms_sql.parse(c, p_sql, dbms_sql.native);
      if instr(p_sql, ':b_fecha') > 0 then dbms_sql.bind_variable(c, ':b_fecha', p_fecha);    end if;
      if instr(p_sql, ':b_local') > 0 then dbms_sql.bind_variable(c, ':b_local', p_local);    end if;
      if instr(p_sql, ':b_term')  > 0 then dbms_sql.bind_variable(c, ':b_term',  p_terminal); end if;
      if instr(p_sql, ':b_y')     > 0 then dbms_sql.bind_variable(c, ':b_y',     p_cierrey);  end if;
      if instr(p_sql, ':b_txt')   > 0 then dbms_sql.bind_variable(c, ':b_txt',   p_txt);      end if;
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

  function fn_num (p_codigo in varchar2, p_default in number) return number is
  begin
    return to_number(fn_param(p_codigo, to_char(p_default)));
  end fn_num;

  -- ---------------------------------------------------------------
  -- Log (transaccion autonoma: queda aunque la caja haga rollback)
  -- ---------------------------------------------------------------
  procedure pr_log (p_fecha       in date,
                    p_local       in number,
                    p_terminal    in number,
                    p_cierrey     in number,
                    p_sobres      in number,
                    p_dif_real    in number,
                    p_di_anterior in number,
                    p_monto_di    in number,
                    p_resultado   in varchar2,
                    p_mensaje     in varchar2,
                    p_usuario     in varchar2) is
    pragma autonomous_transaction;
  begin
    execute immediate fn_r(
      q'[insert into VTA_{P}LOG_COMPENSA_DI
           (log_id, log_fecha_vta, log_local, log_terminal, log_cierrey, log_sobres,
            log_dif_real, log_di_anterior, log_monto_di, log_resultado, log_mensaje,
            log_usuario, log_fechahora)
         values
           (SEQ_VTA_{P}LOG_COMPENSA_DI.nextval, :1, :2, :3, :4,
            :5, :6, :7, :8, :9, :10, :11, sysdate)]')
      using p_fecha, p_local, p_terminal, nvl(p_cierrey, 0),
            p_sobres, p_dif_real, p_di_anterior, p_monto_di, p_resultado,
            substr(p_mensaje, 1, 1000), substr(p_usuario, 1, 50);
    commit;
  exception
    when others then
      rollback;   -- el log nunca corta el proceso
  end pr_log;

  -- ---------------------------------------------------------------
  -- DI automatica vigente de la Y (regularizada, la que suma al compensado)
  -- ---------------------------------------------------------------
  function fn_di_auto (p_fecha in date, p_local in number, p_terminal in number,
                       p_cierrey in number) return number is
    v t_nums;
  begin
    v := fn_sql_nums(fn_r(
      q'[select nvl(sum(m.mov_monto), 0)
           from VTA_{P}MOVDET m
          where m.mov_fecha    = :b_fecha
            and m.mov_local    = :b_local
            and m.mov_terminal = :b_term
            and m.mov_cierrey  = :b_y
            and m.mov_tipomov  = 'DI'
            and m.mov_hechopor = :b_txt
            and m.mov_regul    = 'S'
            and m.mov_fechareg is not null]'),
      1, p_fecha, p_local, p_terminal, p_cierrey, c_usuario);
    return nvl(v(1), 0);
  end fn_di_auto;

  -- DI registradas por un usuario (Form38) en la Y
  function fn_di_manual (p_fecha in date, p_local in number, p_terminal in number,
                         p_cierrey in number) return number is
    v t_nums;
  begin
    v := fn_sql_nums(fn_r(
      q'[select count(*)
           from VTA_{P}MOVDET m
          where m.mov_fecha    = :b_fecha
            and m.mov_local    = :b_local
            and m.mov_terminal = :b_term
            and m.mov_cierrey  = :b_y
            and m.mov_tipomov  = 'DI'
            and nvl(m.mov_hechopor, '-') <> :b_txt]'),
      1, p_fecha, p_local, p_terminal, p_cierrey, c_usuario);
    return nvl(v(1), 0);
  end fn_di_manual;

  -- ---------------------------------------------------------------
  -- Cuadratura de la Y (Form3Y.FormateaDatos):
  --   o_sobres     = sobres F8 de la Y (EFE + CHE)
  --   o_dif_caja   = sumaBZ (Dif. de Caja)
  --   o_compensado = Compensacion (StrSumCompensado, Gopcion = "T")
  --   o_dif_real   = round(sumaBZ - round(compensado))  (Label70)
  -- sumaBZ = (prsefe-totefe)+(prschd-totchd)+totDol+(teschf-totchf)+(tesTarjeta-totTarjeta)
  -- Sin libro de ventas de la Y las salidas de cuadratura quedan en NULL.
  -- Mismas consultas que la version anterior; solo cambian las tablas ({P})
  -- y los literales del pais ({NIVEL}, {TMIN}, {TMAX}, {USD}, {FVEN}).
  -- ---------------------------------------------------------------
  procedure pr_cuadratura (p_fecha      in  date,
                           p_local      in  number,
                           p_terminal   in  number,
                           p_cierrey    in  number,
                           o_sobres     out number,
                           o_dif_caja   out number,
                           o_compensado out number,
                           o_dif_real   out number) is
    v_dec     number := fn_num('CA_DECIMAL', 0);
    v         t_nums;
    v_cnt     number;
    v_totefe  number; v_totchd number; v_totchf number; v_tottarj number;
    v_prsefe  number; v_prschd number;
    v_teschf  number; v_testarj number; v_totdol number;
    v_comp    number;
  begin
    o_dif_caja := null; o_compensado := null; o_dif_real := null;

    -- Sobres de la transportadora (LeeProsegur): tiporec F8, EFE / CHE
    v := fn_sql_nums(fn_r(
      q'[select nvl(sum(case when p.prv_tiposobre = 'EFE' then nvl(p.prv_montosobre,0) + nvl(p.prv_montodif,0) end), 0),
                nvl(sum(case when p.prv_tiposobre = 'CHE' then nvl(p.prv_montosobre,0) + nvl(p.prv_montodif,0) end), 0)
           from VTA_{P}PRD p
          where p.prv_fechavta = :b_fecha
            and p.prv_local    = :b_local
            and p.prv_terminal = :b_term
            and p.prv_tiporec  = 'F8'
            and p.prv_cierrey  = :b_y]'),
      2, p_fecha, p_local, p_terminal, p_cierrey);
    v_prsefe := v(1); v_prschd := v(2);
    o_sobres := v_prsefe + v_prschd;

    -- Declarado en la Y (LeeZ + ARMA_QUERY_Z)
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
            and l.vta_estado      = 'A'
            and l.vta_techkey     = r.rec_techkey
            and l.vta_secuencia   = :b_y]'),
      5, p_fecha, p_local, p_terminal, p_cierrey);
    v_cnt := v(1); v_totefe := v(2); v_totchd := v(3); v_totchf := v(4); v_tottarj := v(5);

    if nvl(v_cnt, 0) = 0 then
      return;   -- sin libro de ventas: el exe muestra "No hay Z disponible"
    end if;

    -- Cheque a fecha en tesoreria (LeeTes)
    v := fn_sql_nums(fn_r(
      q'[select nvl(sum(t.tes_chefecha), 0)
           from VTA_{P}TESOR t
          where t.tes_fecha    = :b_fecha
            and t.tes_local    = :b_local
            and t.tes_terminal = :b_term
            and t.tes_cierrey  = :b_y]'),
      1, p_fecha, p_local, p_terminal, p_cierrey);
    v_teschf := v(1);

    -- Tarjetas recaudadas (FuncLeeTarjeta CTARJ, rango del pais)
    v := fn_sql_nums(fn_r(
      q'[select nvl(sum(t.vta_monto_inf), 0)
           from VTA_{P}TARJ t
          where t.vta_fecha    = :b_fecha
            and t.vta_local    = :b_local
            and t.vta_terminal = :b_term
            and t.vta_cod_tarj between {TMIN} and {TMAX}
            and t.vta_cierrey  = :b_y]'),
      1, p_fecha, p_local, p_terminal, p_cierrey);
    v_testarj := v(1);

    -- Dolares recaudados (FunConsRecMon {USD}). FACO: totDol = tesDol
    v := fn_sql_nums(fn_r(
      q'[select nvl(sum(x.mex_monto), 0)
           from VTA_{P}RECMEX x
          where x.mex_fecha    = :b_fecha
            and x.mex_local    = :b_local
            and x.mex_terminal = :b_term
            and x.id_mdareg    = {USD}
            and x.mex_cierrey  = :b_y]'),
      1, p_fecha, p_local, p_terminal, p_cierrey);
    v_totdol := v(1);

    -- Compensado (Modulo1.StrSumCompensado, Gopcion = "T").
    -- Se mantiene UNION (no UNION ALL) para replicar exactamente al exe.
    v := fn_sql_nums(fn_r(
      q'[select nvl(sum(c.mov_monto), 0)
      from (
        -- TC: registrados el dia - regularizados ese dia
        select ( nvl((select sum(m.mov_monto) from VTA_{P}MOVDET m
                       where m.mov_fecha = :b_fecha and m.mov_local = :b_local
                         and m.mov_terminal = :b_term
                         and m.mov_cierrey = :b_y
                         and m.mov_tipomov = 'TC'), 0)
               - nvl((select sum(m.mov_monto) from VTA_{P}MOVDET m
                       where m.mov_fechareg = :b_fecha and m.mov_local = :b_local
                         and m.mov_terminal = :b_term
                         and m.mov_cierrey = :b_y
                         and m.mov_regul = 'S' and m.mov_tipomov = 'TC'), 0) ) mov_monto,
               d.mov_tipomov
          from VTA_{P}CONCEPDIF d
         where d.mov_tipomov = 'TC'
        union
        -- SN, ND, FN: regularizados del dia - regularizados ese dia
        select ( nvl((select sum(m.mov_monto) from VTA_{P}MOVDET m
                       where m.mov_fecha = :b_fecha and m.mov_local = :b_local
                         and m.mov_terminal = :b_term
                         and m.mov_cierrey = :b_y
                         and m.mov_regul = 'S' and m.mov_tipomov = d.mov_tipomov), 0)
               - nvl((select sum(m.mov_monto) from VTA_{P}MOVDET m
                       where m.mov_fechareg = :b_fecha and m.mov_local = :b_local
                         and m.mov_terminal = :b_term
                         and m.mov_cierrey = :b_y
                         and m.mov_regul = 'S' and m.mov_tipomov = d.mov_tipomov), 0) ),
               d.mov_tipomov
          from VTA_{P}CONCEPDIF d
         where d.mov_tipomov in ('SN', 'ND', 'FN')
        union
        -- BF
        select nvl((select sum(m.mov_monto) from VTA_{P}MOVDET m
                     where m.mov_fecha = :b_fecha and m.mov_local = :b_local
                       and m.mov_terminal = :b_term
                       and m.mov_cierrey = :b_y
                       and m.mov_regul = 'S' and m.mov_tipomov = 'BF'), 0),
               d.mov_tipomov
          from VTA_{P}CONCEPDIF d
         where d.mov_tipomov = 'BF'
        union
        -- NP / FT (una fila por concepto de concepdif, cada una con la suma NP+FT)
        select nvl((select sum(m.mov_monto) from VTA_{P}MOVDET m
                     where m.mov_fecha = :b_fecha and m.mov_local = :b_local
                       and m.mov_terminal = :b_term
                       and m.mov_cierrey = :b_y
                       and m.mov_regul = 'S' and m.mov_tipomov in ('NP', 'FT')), 0),
               d.mov_tipomov
          from VTA_{P}CONCEPDIF d
         where d.mov_tipomov in ('NP', 'FT')
        union
        -- Conceptos regularizados (incluye CA y DI)
        select nvl(sum(m.mov_monto), 0), d.mov_tipomov
          from VTA_{P}MOVDET m, VTA_{P}CONCEPDIF d
         where m.mov_fecha = :b_fecha and m.mov_local = :b_local
           and m.mov_terminal = :b_term
           and m.mov_cierrey = :b_y
           and m.mov_regul = 'S'
           and m.mov_fechareg is not null
           and m.mov_tipomov = d.mov_tipomov
           and d.mov_tipomov in ('TU','DV','P1','P2','CM','CB','CC','SB','SC','SV','CP','CF','CT',
                                 'RE','CR','PC','DN','AF','DD','AA','DI','AV','RP','DP','CA','DE','PM')
         group by d.mov_tipomov
        union
        -- Carta aviso central (VTA_<pfx>CARTAAVISO)
        select nvl(sum(m.mov_monto), 0), d.mov_tipomov
          from VTA_{P}CARTAAVISO m, VTA_{P}CONCEPDIF d
         where m.mov_fecha = :b_fecha and m.mov_local = :b_local
           and m.mov_terminal = :b_term
           and m.mov_cierrey = :b_y
           and m.mov_regul = 'S'
           and m.mov_fechareg is not null
           and m.mov_tipomov = d.mov_tipomov
           and d.mov_tipomov = 'CA'
         group by d.mov_tipomov
        union
        -- Vendedor / cajero ({FVEN}: filtro del pais; FACO sin filtro VEN_REGUL)
        select (select nvl(sum(v.ven_monto), 0) from VTA_{P}DIFVEND v
                 where v.ven_fecha = :b_fecha and v.ven_local = :b_local
                   and v.ven_terminal = :b_term
                   and v.ven_cierrey = :b_y {FVEN}),
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
        -- AL (cruce con libro de ventas del nivel del cierre)
        select nvl(sum(m.mov_monto), 0), d.mov_tipomov
          from VTA_{P}MOVDET m, VTA_{P}CONCEPDIF d,
               VTA_{P}LIBVTA l, VTA_{P}ZZZ z
         where m.mov_fecha = :b_fecha and m.mov_numero = m.mov_terminal
           and m.mov_fecha = l.vta_fecha_venta
           and m.mov_local = l.vta_local
           and m.mov_terminal = l.vta_terminal
           and l.vta_techkey = z.rec_techkey and l.vta_estado = 'A'
           and m.mov_local = :b_local and m.mov_terminal = :b_term
           and m.mov_cierrey = :b_y
           and l.vta_tiporeg = '{NIVEL}'
           and m.mov_secuencia = l.vta_secuencia
           and m.mov_tipomov = d.mov_tipomov
           and d.mov_tipomov = 'AL'
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

    o_dif_caja   := (v_prsefe - v_totefe) + (v_prschd - v_totchd) + v_totdol
                  + (v_teschf - v_totchf) + (v_testarj - v_tottarj);
    o_compensado := v_comp;
    -- El exe redondea el compensado ANTES de restarlo (Form3Y.FormateaDatos)
    o_dif_real   := round(o_dif_caja - round(v_comp, v_dec), v_dec);
  end pr_cuadratura;

  -- ---------------------------------------------------------------
  -- Funciones publicas de solo lectura
  -- ---------------------------------------------------------------
  function fn_dif_real (p_flg_pais in varchar2,
                        p_fecha    in date,
                        p_local    in number,
                        p_terminal in number,
                        p_cierrey  in number) return number is
    v_sob number; v_caja number; v_comp number; v_dr number;
  begin
    pr_config(p_flg_pais);
    pr_cuadratura(p_fecha, p_local, p_terminal, p_cierrey, v_sob, v_caja, v_comp, v_dr);
    return v_dr;
  end fn_dif_real;

  function fn_dif_real_sin_di (p_flg_pais in varchar2,
                               p_fecha    in date,
                               p_local    in number,
                               p_terminal in number,
                               p_cierrey  in number) return number is
    v_sob number; v_caja number; v_comp number; v_dr number;
  begin
    pr_config(p_flg_pais);
    pr_cuadratura(p_fecha, p_local, p_terminal, p_cierrey, v_sob, v_caja, v_comp, v_dr);
    if v_dr is null then
      return null;
    end if;
    -- la DI automatica es parte del compensado: se descuenta
    return round(v_caja - round(v_comp - fn_di_auto(p_fecha, p_local, p_terminal, p_cierrey),
                                fn_num('CA_DECIMAL', 0)),
                 fn_num('CA_DECIMAL', 0));
  end fn_dif_real_sin_di;

  function fn_evalua (p_flg_pais in varchar2,
                      p_fecha    in date,
                      p_local    in number,
                      p_terminal in number,
                      p_cierrey  in number) return varchar2 is
    v    t_nums;
    v_dr number;
  begin
    pr_config(p_flg_pais);
    if fn_param('CA_DI_ACTIVO', 'N') <> 'S' then
      return 'INACTIVO';
    elsif nvl(p_cierrey, 0) = 0 then
      return 'SIN_Y';
    end if;

    v := fn_sql_nums(fn_r(
      q'[select count(*), max(t.ter_estado)
           from VTA_{P}{EST} t
          where t.ter_fecha = :b_fecha and t.ter_local = :b_local
            and t.ter_terminal = :b_term and t.ter_cierrey = :b_y]'),
      2, p_fecha, p_local, p_terminal, p_cierrey);
    if nvl(v(1), 0) = 0 then
      return 'SIN_TERMSTAT';
    elsif v(2) > 0 then
      return 'YA_CERRADA';
    elsif fn_di_manual(p_fecha, p_local, p_terminal, p_cierrey) > 0 then
      return 'DI_MANUAL_PREVIA';
    end if;

    v_dr := fn_dif_real_sin_di(p_flg_pais, p_fecha, p_local, p_terminal, p_cierrey);
    if v_dr is null then
      return 'SIN_LIBVTA';
    elsif v_dr = 0 then
      return 'DR_CERO';
    elsif v_dr < fn_num('CA_DI_MIN', -1000) or v_dr > fn_num('CA_DI_MAX', 20000) then
      return 'FUERA_RANGO';   -- limites inclusivos
    end if;
    return 'COMPENSABLE';
  end fn_evalua;

  -- ---------------------------------------------------------------
  -- Borra la DI automatica de la Y y su observacion automatica.
  -- Devuelve el monto borrado.
  -- ---------------------------------------------------------------
  function fn_borra_di_auto (p_fecha in date, p_local in number, p_terminal in number,
                             p_cierrey in number) return number is
    v t_nums;
  begin
    v := fn_sql_nums(fn_r(
      q'[select nvl(sum(m.mov_monto), 0)
           from VTA_{P}MOVDET m
          where m.mov_fecha    = :b_fecha
            and m.mov_local    = :b_local
            and m.mov_terminal = :b_term
            and m.mov_cierrey  = :b_y
            and m.mov_tipomov  = 'DI'
            and m.mov_hechopor = :b_txt]'),
      1, p_fecha, p_local, p_terminal, p_cierrey, c_usuario);

    execute immediate fn_r(
      q'[delete from VTA_{P}MOVDET m
          where m.mov_fecha    = :1
            and m.mov_local    = :2
            and m.mov_terminal = :3
            and m.mov_cierrey  = :4
            and m.mov_tipomov  = 'DI'
            and m.mov_hechopor = :5]')
      using p_fecha, p_local, p_terminal, p_cierrey, c_usuario;

    -- Solo la observacion automatica (actual o la del 19-10; la v2 ya usaba la actual)
    execute immediate fn_r(
      q'[delete from VTA_{P}COMPDES c
          where c.cpd_fecha    = :1
            and c.cpd_local    = :2
            and c.cpd_terminal = :3
            and c.cpd_cierrey  = :4
            and c.cpd_tipmov   = 'DI'
            and c.cpd_obs in (:5, :6)]')
      using p_fecha, p_local, p_terminal, p_cierrey, c_glosa, c_glosa_ant;

    return nvl(v(1), 0);
  end fn_borra_di_auto;

  -- ---------------------------------------------------------------
  -- Registro de la DI (replica InsertarRegistroMovDet + Form45.GrabarObs)
  -- ---------------------------------------------------------------
  procedure pr_registra_di (p_fecha in date, p_local in number, p_terminal in number,
                            p_cierrey in number, p_monto in number) is
    v_filas number;
  begin
    -- Modulo1.InsertarRegistroMovDet: mov_rol 0, mov_nombre ' ', mov_secuencia 0,
    -- mov_numero 0, monto redondeado a 2, MOV_REGUL 'S' (regularizada: se ve
    -- en Compensado), MOV_FECHAREG = fecha de venta, techkey {SEQMOV}.
    execute immediate fn_r(
      q'[insert into VTA_{P}MOVDET
           (mov_fecha, mov_local, mov_terminal, mov_tipomov, mov_rol, mov_nombre,
            mov_secuencia, mov_numero, mov_monto, mov_hechopor, mov_regul,
            mov_fechareg, mov_techkey, mov_cierrey)
         values
           (:1, :2, :3, 'DI', 0, ' ',
            0, 0, :4, :5, 'S',
            :6, {SEQMOV}.nextval, :7)]')
      using p_fecha, p_local, p_terminal, round(p_monto, 2), c_usuario,
            p_fecha, p_cierrey;

    -- Observacion (Form45: una por caja / concepto / Y)
    execute immediate fn_r(
      q'[update VTA_{P}COMPDES c
            set c.cpd_obs = :1
          where c.cpd_fecha    = :2
            and c.cpd_local    = :3
            and c.cpd_terminal = :4
            and c.cpd_tipmov   = 'DI'
            and c.cpd_cierrey  = :5]')
      using c_glosa, p_fecha, p_local, p_terminal, p_cierrey;
    v_filas := sql%rowcount;

    if v_filas = 0 then
      -- cpd_secuencia la asigna el trigger TRG_VTA_<pfx>COMPDES_I_SEQ
      execute immediate fn_r(
        q'[insert into VTA_{P}COMPDES
             (cpd_fecha, cpd_local, cpd_terminal, cpd_tipmov, cpd_obs, cpd_cierrey)
           values
             (:1, :2, :3, 'DI', :4, :5)]')
        using p_fecha, p_local, p_terminal, c_glosa, p_cierrey;
    end if;
  end pr_registra_di;

  -- ---------------------------------------------------------------
  -- Compensacion automatica de una caja (cierre Y)
  -- ---------------------------------------------------------------
  procedure prc_compensa_caja (p_flg_pais  in  varchar2,
                               p_fecha     in  date,
                               p_local     in  number,
                               p_terminal  in  number,
                               p_cierrey   in  number,
                               p_usuario   in  varchar2 default 'PROC_DI_AUTO',
                               o_resultado out varchar2,
                               o_monto_di  out number,
                               o_mensaje   out varchar2) is
    v_fecha    date := trunc(p_fecha);
    v_estado   number;
    v_min      number;
    v_max      number;
    v_sob      number;
    v_caja     number;
    v_comp     number;
    v_dr       number;
    v_dr2      number;
    v_anterior number := 0;
    v_txt_ant  varchar2(100);
  begin
    o_resultado := null;
    o_monto_di  := null;
    o_mensaje   := null;

    -- Pais: sin configuracion valida no hay tablas (ni log) donde escribir
    begin
      pr_config(p_flg_pais);
    exception
      when others then
        o_resultado := 'ERROR';
        o_mensaje   := substr(sqlerrm, 1, 1000);
        return;
    end;

    if fn_param('CA_DI_ACTIVO', 'N') <> 'S' then
      o_resultado := 'INACTIVO';
      o_mensaje   := 'Parametro 1502 CA_DI_ACTIVO distinto de S: no se compensa';
      pr_log(v_fecha, p_local, p_terminal, p_cierrey, null, null, null, null,
             o_resultado, o_mensaje, p_usuario);
      return;
    end if;

    if nvl(p_cierrey, 0) = 0 then
      o_resultado := 'SIN_Y';
      o_mensaje   := 'Sobre sin cierre Y (prv_cierrey 0): no se compensa';
      pr_log(v_fecha, p_local, p_terminal, 0, null, null, null, null,
             o_resultado, o_mensaje, p_usuario);
      return;
    end if;

    v_min := fn_num('CA_DI_MIN', -1000);
    v_max := fn_num('CA_DI_MAX', 20000);

    savepoint sp_di_carga;

    -- La Y debe existir y estar abierta (Form38 no permite DI en caja cerrada)
    begin
      execute immediate fn_r(
        q'[select t.ter_estado
             from VTA_{P}{EST} t
            where t.ter_fecha = :1 and t.ter_local = :2
              and t.ter_terminal = :3 and t.ter_cierrey = :4
              for update nowait]')
        into v_estado
        using v_fecha, p_local, p_terminal, p_cierrey;
    exception
      when no_data_found then
        o_resultado := 'SIN_TERMSTAT';
        o_mensaje   := 'No existe el cierre Y en VTA_' || g_cfg.prefijo || g_cfg.tabla_est ||
                       ' (ingresar la Y antes de cargar los sobres)';
        pr_log(v_fecha, p_local, p_terminal, p_cierrey, null, null, null, null,
               o_resultado, o_mensaje, p_usuario);
        return;
      when e_ocupada then
        o_resultado := 'OCUPADA';
        o_mensaje   := 'Caja bloqueada por otro usuario: reintentar';
        pr_log(v_fecha, p_local, p_terminal, p_cierrey, null, null, null, null,
               o_resultado, o_mensaje, p_usuario);
        return;
    end;

    if v_estado > 0 then
      rollback to sp_di_carga;
      o_resultado := 'YA_CERRADA';
      o_mensaje   := 'Caja cerrada (estado ' || v_estado || '): no se compensa';
      pr_log(v_fecha, p_local, p_terminal, p_cierrey, null, null, null, null,
             o_resultado, o_mensaje, p_usuario);
      return;
    end if;

    if fn_di_manual(v_fecha, p_local, p_terminal, p_cierrey) > 0 then
      rollback to sp_di_carga;
      v_dr := fn_dif_real(p_flg_pais, v_fecha, p_local, p_terminal, p_cierrey);
      o_resultado := 'DI_MANUAL_PREVIA';
      o_mensaje   := 'La caja ya tiene una DI registrada por un usuario: no se compensa (revision del analista)';
      pr_log(v_fecha, p_local, p_terminal, p_cierrey, null, v_dr, null, null,
             o_resultado, o_mensaje, p_usuario);
      return;
    end if;

    -- Recalculo: se quita la DI automatica de una carga anterior y se evalua
    -- de nuevo con todos los sobres de la Y
    v_anterior := fn_borra_di_auto(v_fecha, p_local, p_terminal, p_cierrey);
    if v_anterior <> 0 then
      v_txt_ant := ' (se borro la DI automatica anterior por ' || v_anterior || ')';
    end if;

    pr_cuadratura(v_fecha, p_local, p_terminal, p_cierrey, v_sob, v_caja, v_comp, v_dr);

    if v_dr is null then
      o_resultado := 'SIN_LIBVTA';
      o_mensaje   := 'No hay libro de ventas de la Y (No hay Z disponible)' || v_txt_ant;
    elsif v_dr = 0 then
      o_resultado := 'DR_CERO';
      o_mensaje   := 'Diferencia real 0: sin DI' || v_txt_ant;
    elsif v_dr < v_min or v_dr > v_max then   -- limites inclusivos
      o_resultado := 'FUERA_RANGO';
      o_mensaje   := 'Diferencia real ' || v_dr || ' fuera del rango [' || v_min || ', ' ||
                     v_max || ']: sin DI, pendiente de gestion de tiendas' || v_txt_ant;
    end if;

    if o_resultado is not null then
      commit;   -- confirma el borrado de la DI anterior, si lo hubo
      pr_log(v_fecha, p_local, p_terminal, p_cierrey, v_sob, v_dr, nullif(v_anterior, 0), null,
             o_resultado, o_mensaje, p_usuario);
      return;
    end if;

    -- DI = DR con el mismo signo y por el valor exacto (DR -5000 -> DI -5000)
    pr_registra_di(v_fecha, p_local, p_terminal, p_cierrey, v_dr);

    -- Control: con la DI registrada la diferencia real debe quedar en 0
    v_dr2 := fn_dif_real(p_flg_pais, v_fecha, p_local, p_terminal, p_cierrey);
    if nvl(v_dr2, 1) <> 0 then
      rollback to sp_di_carga;   -- deshace tambien el borrado de la DI anterior
      o_resultado := 'ERROR';
      o_mensaje   := 'La diferencia real no quedo en 0 despues de registrar la DI (antes ' ||
                     v_dr || ', despues ' || nvl(to_char(v_dr2), 'null') || '): DI revertida';
      pr_log(v_fecha, p_local, p_terminal, p_cierrey, v_sob, v_dr, null, null,
             o_resultado, o_mensaje, p_usuario);
      return;
    end if;

    commit;
    o_resultado := 'DI_REGISTRADA';
    o_monto_di  := round(v_dr, 2);
    o_mensaje   := 'DI automatica por ' || v_dr || '; la caja queda Pendiente' ||
                   case when v_anterior <> 0 then ' (reemplaza DI anterior ' || v_anterior || ')' end;
    pr_log(v_fecha, p_local, p_terminal, p_cierrey, v_sob, v_dr, nullif(v_anterior, 0), o_monto_di,
           o_resultado, o_mensaje, p_usuario);

  exception
    when others then
      o_mensaje := substr(sqlerrm, 1, 1000);
      begin
        rollback to sp_di_carga;
      exception
        when others then rollback;
      end;
      o_resultado := 'ERROR';
      o_monto_di  := null;
      pr_log(v_fecha, p_local, p_terminal, p_cierrey, null, null, null, null,
             o_resultado, o_mensaje, p_usuario);
  end prc_compensa_caja;

  -- ---------------------------------------------------------------
  -- Compatibilidad (firmas del 19-10, sin pais): equivalen a FACO
  -- ---------------------------------------------------------------
  function fn_dif_real (p_fecha    in date,
                        p_local    in number,
                        p_terminal in number,
                        p_cierrey  in number) return number is
  begin
    return fn_dif_real(c_pais_compat, p_fecha, p_local, p_terminal, p_cierrey);
  end fn_dif_real;

  function fn_dif_real_sin_di (p_fecha    in date,
                               p_local    in number,
                               p_terminal in number,
                               p_cierrey  in number) return number is
  begin
    return fn_dif_real_sin_di(c_pais_compat, p_fecha, p_local, p_terminal, p_cierrey);
  end fn_dif_real_sin_di;

  function fn_evalua (p_fecha    in date,
                      p_local    in number,
                      p_terminal in number,
                      p_cierrey  in number) return varchar2 is
  begin
    return fn_evalua(c_pais_compat, p_fecha, p_local, p_terminal, p_cierrey);
  end fn_evalua;

  procedure prc_compensa_caja (p_fecha     in  date,
                               p_local     in  number,
                               p_terminal  in  number,
                               p_cierrey   in  number,
                               p_usuario   in  varchar2 default 'PROC_DI_AUTO',
                               o_resultado out varchar2,
                               o_monto_di  out number,
                               o_mensaje   out varchar2) is
  begin
    prc_compensa_caja(c_pais_compat, p_fecha, p_local, p_terminal, p_cierrey, p_usuario,
                      o_resultado, o_monto_di, o_mensaje);
  end prc_compensa_caja;

end PKG_F8_COMPENSA_DI_CARGA;
/
