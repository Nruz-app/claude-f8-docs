-- =====================================================================
-- FSCC-12901 PROC_YZ (v2 multipais + cierre Z) - Paso 07
-- Cuerpo de PKG_F8_CIERRE_AUTO   (Oracle 10.2)
--
-- Misma logica que v1 (PKG_F8_FACO_CIERRE_AUTO, docs/sql/FSCC-12901_T1_T2/
-- 07_pkg_cierre_auto_body.sql); cambia solo:
--   * el pais llega por parametro (P_FLG_PAIS = Flg_Pais$ del exe) y las
--     tablas se arman con su prefijo: el SQL se escribe con marcas que
--     FN_R reemplaza segun la configuracion del pais:
--         {P}     prefijo de tablas        VTA_{P}TERMSTATY -> VTA_FACOTERMSTATY
--         {NIVEL} tipo de registro del libro de ventas del cierre ('Y')
--         {TMIN} / {TMAX}  rango de codigos de tarjetas recaudadas
--         {USD}   codigo de moneda dolar (cmn_mdareg)
--         {SEQMOV} secuencia del techkey de VTA_<pfx>MOVDET
--   * consultas con SQL dinamico y binds (:b_fecha, :b_local, :b_term, :b_y,
--     :b_txt via DBMS_SQL, que enlaza por nombre todas las apariciones);
--   * universo "carga del dia" (modo CARGA): la ejecucion toma la cola
--     pendiente (P -> E) y al terminar la deja procesada (C). Sin CA_DIAS.
--
-- PROC_YZ (15-10-2026): agrega el cierre de la Z (VTA_<pfx>TERMSTAT), que
-- replica Form3.CierraTerminal (FTEPROD/Form3.frm:3439). Apagado por defecto
-- (parametro 1502 CA_CIERRA_Z = N): con N el paquete se comporta igual que
-- PROC_Y. Con S, despues de evaluar las Y de cada caja se intenta cerrar la Z
-- del terminal y dia (pr_procesa_z). Las consultas de la Z son las mismas de
-- la Y sin el filtro de numero de Y y con libro de ventas 'F8' (fn_rz), igual
-- que hace el exe (StrSumCompensado, LeeZ, LeeProsegur... sin cierrey).
-- El SQL de la Y no cambia: fn_rz con p_z = FALSE es exactamente fn_r.
--
-- Referencias al exe VB6 (FTEPROD/):
--   Form3Y.CierraTerminal :2801   Form3Y.FormateaDatos :2704
--   Form3Y.FuncvalidarConcepto :1700  Modulo1.StrSumCompensado :2630
--   Modulo1.FuncMontoValidaZZZYY :4160  StrCamposValidarZZZ :4053
--   Modulo1.Func_ValorGestionCheque :5681  Func_ValorChequeFecha :5632
--   Z: Form3.CierraTerminal :3439  Form3.FuncValidadCierreyyyy :2153
--      Form3.FuncvalidarDifDolares :1966  Modulo1.FuncValidarZSumaY :5531
--      Modulo1.FuncMontoValidaZZZ :4105
-- Detalle funcional: docs/CierreCaja_FACO_Reglas.md (Y: 3, Z: 4 y 6.2)
-- =====================================================================

create or replace package body PKG_F8_CIERRE_AUTO as

  -- ---------------------------------------------------------------
  -- Configuracion del pais
  -- ---------------------------------------------------------------
  type t_cfg is record (
    pais        varchar2(10),   -- valor de Flg_Pais$ recibido
    prefijo     varchar2(10),   -- prefijo de tablas VTA_<prefijo>...
    localiz     varchar2(10),   -- VTA_PAINT_Z.vta_localiz
    nivel       varchar2(1),    -- nivel que cierra el proceso: Y (cierre parcial)
    nivel_z     varchar2(2),    -- tipo de registro del libro de ventas de la Z ('F8')
    tarj_min    number,         -- tarjetas recaudadas: codigos tarj_min..tarj_max
    tarj_max    number,
    mda_usd     number,         -- moneda dolar en VTA_<pfx>RECMEX
    modo        varchar2(10),   -- universo: CARGA (la carga del dia)
    seq_movdet  varchar2(30)    -- secuencia del techkey de VTA_<pfx>MOVDET
  );
  g_cfg        t_cfg;

  type t_nums is table of number index by pls_integer;
  type t_conceptos is table of varchar2(200) index by varchar2(2);

  -- ---------------------------------------------------------------
  -- Estado de la ejecucion
  -- ---------------------------------------------------------------
  g_ejecucion  number;
  g_usuario    varchar2(50) := c_usuario_def;
  g_dec        number;          -- decimales de redondeo (CA_DECIMAL)
  g_proceso    varchar2(2) := 'T2';  -- log_proceso: T2 automatico, CC Consultas de Cuadratura
  g_len_notas_z number;         -- largo de TER_NOTAS en VTA_<pfx>TERMSTAT (se lee una vez)

  -- Terminal-dia cuya Z se evalua al final de la ejecucion
  type t_term is record (f date, l number, t number);
  type t_terms is table of t_term index by varchar2(40);

  e_ocupada    exception;
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
      -- Falabella Colombia: cierre Y (Form3Y) y, si CA_CIERRA_Z = S, la Z (Form3).
      v_cfg.pais       := 'FACO';
      v_cfg.prefijo    := 'FACO';
      v_cfg.localiz    := 'FACO';
      v_cfg.nivel      := 'Y';
      v_cfg.nivel_z    := 'F8';     -- Form3.LeeZ / FuncValidarZSumaY: vta_tiporeg = 'F8'
      v_cfg.tarj_min   := 2000;     -- FuncLeeTarjeta CTARJ, rama FACO
      v_cfg.tarj_max   := 2999;
      v_cfg.mda_usd    := 305;      -- Modulo1 DOLAR = "305"
      v_cfg.modo       := 'CARGA';  -- una ejecucion por carga, sin ventana de dias
      v_cfg.seq_movdet := 'SEQ_VTA_FACOVEN';

    -- -------------------------------------------------------------
    -- EJEMPLO (NO HABILITADO): como se agregaria otro pais, p. ej.
    -- Falabella Chile (Flg_Pais$ = "CHI", tablas sin prefijo). Antes de
    -- habilitarlo hay que crear sus objetos (cola VTA_PRD_CIERRE, log
    -- VTA_LOG_CIERRE_AUTO, secuencias, trigger y parametros 1502 en
    -- VTA_PARAM), revisar contra el exe sus diferencias de cuadratura,
    -- revisar el proceso de la Z (pr_procesa_z, PROC_YZ) y agregar el
    -- modo DIAS (fecha de proceso - CA_DIAS) en fn_universo.
    -- elsif v_pais in ('CHI', 'CL') then
    --   v_cfg.pais       := v_pais;
    --   v_cfg.prefijo    := null;          -- VTA_TERMSTAT, VTA_PRD, ...
    --   v_cfg.localiz    := 'CHI';
    --   v_cfg.nivel      := 'Y';
    --   v_cfg.nivel_z    := 'F8';
    --   v_cfg.tarj_min   := ...;
    --   v_cfg.tarj_max   := ...;
    --   v_cfg.mda_usd    := 305;
    --   v_cfg.modo       := 'DIAS';        -- fecha de proceso - CA_DIAS
    --   v_cfg.seq_movdet := 'SEQ_VTA_VEN';
    -- -------------------------------------------------------------
    else
      raise_application_error(-20001,
        'Pais no habilitado para cierre automatico: ' || nvl(p_flg_pais, '(nulo)'));
    end if;

    g_cfg := v_cfg;
    g_dec := null;   -- los decimales son por pais (CA_DECIMAL)
    g_len_notas_z := null;
  end pr_config;

  -- Reemplaza las marcas del SQL con los valores del pais configurado
  function fn_r (p_sql in varchar2) return varchar2 is
  begin
    return replace(replace(replace(replace(replace(replace(p_sql,
             '{P}',      g_cfg.prefijo),
             '{NIVEL}',  g_cfg.nivel),
             '{TMIN}',   to_char(g_cfg.tarj_min)),
             '{TMAX}',   to_char(g_cfg.tarj_max)),
             '{USD}',    to_char(g_cfg.mda_usd)),
             '{SEQMOV}', g_cfg.seq_movdet);
  end fn_r;

  -- SQL de la Y convertido a SQL de la Z (p_z = TRUE), igual que el exe:
  --   * '{NIVEL}' -> nivel de la Z ('F8') en vez de 'Y';
  --   * cada filtro de numero de Y "alias.columna = :b_y" pasa a "1 = 1"
  --     (StrSumCompensado, LeeZ, LeeProsegur, LeeTes... sin cierrey).
  -- Sin :b_y en el texto, fn_sql_nums no enlaza el numero de Y.
  -- Con p_z = FALSE devuelve exactamente fn_r(p_sql): el SQL de la Y no cambia.
  function fn_rz (p_sql in varchar2, p_z in boolean) return varchar2 is
  begin
    if not p_z then
      return fn_r(p_sql);
    end if;
    return regexp_replace(fn_r(replace(p_sql, '{NIVEL}', g_cfg.nivel_z)),
                          '[[:alnum:]_]+\.[[:alnum:]_]+[[:space:]]*=[[:space:]]*:b_y', '1 = 1');
  end fn_rz;

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
  -- Utilitarios publicos
  -- ---------------------------------------------------------------
  function fn_tabla (p_flg_pais in varchar2,
                     p_base     in varchar2) return varchar2 is
  begin
    pr_config(p_flg_pais);
    return 'VTA_' || g_cfg.prefijo || upper(p_base);
  end fn_tabla;

  function fn_sql (p_flg_pais in varchar2,
                   p_sql      in varchar2) return varchar2 is
  begin
    pr_config(p_flg_pais);
    return fn_r(p_sql);
  end fn_sql;

  function fn_param (p_flg_pais in varchar2,
                     p_codigo   in varchar2,
                     p_default  in varchar2) return varchar2 is
    v_valor varchar2(200);
  begin
    pr_config(p_flg_pais);
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

  function fn_dec return number is
  begin
    if g_dec is null then
      g_dec := to_number(fn_param(g_cfg.pais, 'CA_DECIMAL', '0'));
    end if;
    return g_dec;
  end fn_dec;

  procedure pr_registra_log (p_flg_pais  in varchar2,
                             p_ejecucion in number,
                             p_proceso   in varchar2,
                             p_nivel     in varchar2,
                             p_fecha     in date,
                             p_local     in number,
                             p_terminal  in number,
                             p_cierrey   in number,
                             p_dif_real  in number,
                             p_resultado in varchar2,
                             p_regla     in varchar2,
                             p_mensaje   in varchar2,
                             p_usuario   in varchar2) is
    pragma autonomous_transaction;
  begin
    pr_config(p_flg_pais);
    execute immediate fn_r(
      q'[insert into VTA_{P}LOG_CIERRE_AUTO
           (log_id, log_ejecucion, log_proceso, log_nivel, log_fecha_vta, log_local, log_terminal,
            log_cierrey, log_dif_real, log_resultado, log_regla, log_mensaje,
            log_usuario, log_fechahora)
         values
           (SEQ_VTA_{P}LOG_CIERRE_AUTO.nextval, :1, :2, :3, :4, :5, :6,
            :7, :8, :9, :10, :11, :12, sysdate)]')
      using nvl(p_ejecucion, 0), p_proceso, p_nivel, p_fecha, p_local, p_terminal,
            p_cierrey, p_dif_real, p_resultado, p_regla, substr(p_mensaje, 1, 1000),
            substr(p_usuario, 1, 50);
    commit;
  end pr_registra_log;

  function fn_nueva_ejecucion (p_flg_pais in varchar2) return number is
    v_n number;
  begin
    pr_config(p_flg_pais);
    execute immediate fn_r('select SEQ_VTA_{P}LOG_CIERRE_AUTO.nextval from dual') into v_n;
    return v_n;
  end fn_nueva_ejecucion;

  -- Log de la ejecucion en curso de este paquete
  procedure pr_log (p_nivel     in varchar2,
                    p_fecha     in date,
                    p_local     in number,
                    p_terminal  in number,
                    p_cierrey   in number,
                    p_dif_real  in number,
                    p_resultado in varchar2,
                    p_regla     in varchar2,
                    p_mensaje   in varchar2) is
  begin
    pr_registra_log(g_cfg.pais, g_ejecucion, g_proceso, p_nivel, p_fecha, p_local, p_terminal,
                    p_cierrey, p_dif_real, p_resultado, p_regla, p_mensaje, g_usuario);
  end pr_log;

  -- ---------------------------------------------------------------
  -- Universo de cajas de una ejecucion (reemplaza a la vista
  -- VTA_FACOV_CAJAS_CIERRE de v1, que queda sin uso en v2):
  --   COLA      : cierres Y de la carga (cola E de la ejecucion, o P si
  --               p_ejecucion es nulo), sobres con Y (prv_cierrey <> 0).
  --   SIN_SOBRE : cierres Y abiertos del mismo local y fecha de venta de la
  --               carga, sin sobres ("cajas sin movimiento", DF-SCC fila 12 /
  --               CA8), si CA_SIN_SOBRE = S y la Y tiene libro de ventas.
  -- UNION elimina las Y repetidas (varios sobres o COLA + SIN_SOBRE).
  -- p_ejecucion es un numero interno de la secuencia: va como literal.
  -- ---------------------------------------------------------------
  function fn_universo (p_flg_pais  in varchar2,
                        p_ejecucion in number) return sys_refcursor is
    v_cola varchar2(200);
    v_sql  varchar2(4000);
    v_cur  sys_refcursor;
  begin
    pr_config(p_flg_pais);
    if p_ejecucion is null then
      v_cola := q'[q.pcr_estado = 'P']';
    else
      v_cola := q'[q.pcr_estado = 'E' and q.pcr_ejecucion = ]' || to_char(trunc(p_ejecucion));
    end if;

    v_sql :=
      q'[select q.prv_fechavta f, q.prv_local l, q.prv_terminal t, q.prv_cierrey y
           from VTA_{P}PRD_CIERRE q
          where ]' || v_cola || q'[
            and q.prv_cierrey <> 0]';

    if fn_param(p_flg_pais, 'CA_SIN_SOBRE', 'N') = 'S' then
      v_sql := v_sql || q'[
         union
         select y.ter_fecha, y.ter_local, y.ter_terminal, y.ter_cierrey
           from VTA_{P}TERMSTATY y
          where y.ter_estado <= 0
            and exists (select 1 from VTA_{P}PRD_CIERRE q
                         where ]' || v_cola || q'[
                           and q.prv_fechavta = y.ter_fecha
                           and q.prv_local = y.ter_local)
            and exists (select 1 from VTA_{P}LIBVTA l, VTA_{P}ZZZ r
                         where l.vta_tiporeg = '{NIVEL}'
                           and l.vta_techkey = r.rec_techkey
                           and l.vta_estado = 'A'
                           and l.vta_fecha_venta = y.ter_fecha
                           and l.vta_local = y.ter_local
                           and l.vta_terminal = y.ter_terminal
                           and l.vta_secuencia = y.ter_cierrey)]';
    end if;

    -- Modo CARGA (FACO): sin filtro de fechas. Un pais en modo DIAS (ejemplo
    -- Chile) agregaria aqui: f >= trunc(sysdate) - CA_DIAS.
    v_sql := 'select f, l, t, y from (' || v_sql || ') order by 1, 2, 3, 4';
    open v_cur for fn_r(v_sql);
    return v_cur;
  end fn_universo;

  -- Mensajes de conceptos pendientes (Form3Y.CierraTerminal, mismo orden)
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
  -- Cuadratura de la caja (FormateaDatos / Form43.SubBuscarOpcion):
  --   o_dif_caja    = sumaBZ (Dif. de Caja, sin redondear)
  --   o_compensado  = compensado (Compensacion, sin redondear)
  --   o_dif_real    = Diferencia Real (Label70) = round(sumaBZ - round(compensado))
  -- sumaBZ = (prsefe-totefe)+(prschd-totchd)+totDol+(teschf-totchf)+(tesTarjeta-totTarjeta)
  -- Sin libro de ventas de la Y las tres salidas quedan en NULL ("No hay Z disponible").
  -- Mismas consultas que v1; solo cambian las tablas ({P}) y los literales
  -- del pais ({NIVEL}, {TMIN}, {TMAX}, {USD}).
  -- PROC_YZ: p_cierrey NULL = cuadratura de la Z (Form3.FormateaDatos :3337):
  -- las mismas consultas sin filtro de Y y con libro de ventas 'F8' (fn_rz).
  -- Sin libro de ventas 'F8' las salidas quedan en NULL.
  -- ---------------------------------------------------------------
  procedure pr_cuadratura (p_fecha      in  date,
                           p_local      in  number,
                           p_terminal   in  number,
                           p_cierrey    in  number,
                           o_dif_caja   out number,
                           o_compensado out number,
                           o_dif_real   out number) is
    v          t_nums;
    v_cnt      number;
    v_totefe   number; v_totchd number; v_totchf number; v_tottarj number;
    v_prsefe   number; v_prschd number;
    v_teschf   number; v_testarj number; v_totdol number;
    v_comp     number;
    v_z        boolean := p_cierrey is null;   -- PROC_YZ: sin numero de Y = Z (dia completo)
  begin
    -- Declarado en la Y (LeeZ + ARMA_QUERY_Z). Z: libro de ventas 'F8' sin vta_secuencia
    -- (Form3.LeeZ :2345, rama FACO de ARMA_QUERY_Z).
    v := fn_sql_nums(fn_rz(
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
            and l.vta_secuencia   = :b_y]', v_z),
      5, p_fecha, p_local, p_terminal, p_cierrey);
    v_cnt := v(1); v_totefe := v(2); v_totchd := v(3); v_totchf := v(4); v_tottarj := v(5);

    o_dif_caja := null; o_compensado := null; o_dif_real := null;
    if nvl(v_cnt, 0) = 0 then
      return;   -- sin libro de ventas: el exe muestra "No hay Z disponible"
    end if;

    -- Sobres de la transportadora (LeeProsegur): tiporec F8, EFE / CHE
    v := fn_sql_nums(fn_rz(
      q'[select nvl(sum(case when p.prv_tiposobre = 'EFE' then nvl(p.prv_montosobre,0) + nvl(p.prv_montodif,0) end), 0),
                nvl(sum(case when p.prv_tiposobre = 'CHE' then nvl(p.prv_montosobre,0) + nvl(p.prv_montodif,0) end), 0)
           from VTA_{P}PRD p
          where p.prv_fechavta = :b_fecha
            and p.prv_local    = :b_local
            and p.prv_terminal = :b_term
            and p.prv_tiporec  = 'F8'
            and p.prv_cierrey  = :b_y]', v_z),
      2, p_fecha, p_local, p_terminal, p_cierrey);
    v_prsefe := v(1); v_prschd := v(2);

    -- Cheque a fecha en tesoreria (LeeTes). Verificado en test (06-10-2026): una fila por Y.
    v := fn_sql_nums(fn_rz(
      q'[select nvl(sum(t.tes_chefecha), 0)
           from VTA_{P}TESOR t
          where t.tes_fecha    = :b_fecha
            and t.tes_local    = :b_local
            and t.tes_terminal = :b_term
            and t.tes_cierrey  = :b_y]', v_z),
      1, p_fecha, p_local, p_terminal, p_cierrey);
    v_teschf := v(1);

    -- Tarjetas recaudadas (FuncLeeTarjeta CTARJ, rango del pais)
    v := fn_sql_nums(fn_rz(
      q'[select nvl(sum(t.vta_monto_inf), 0)
           from VTA_{P}TARJ t
          where t.vta_fecha    = :b_fecha
            and t.vta_local    = :b_local
            and t.vta_terminal = :b_term
            and t.vta_cod_tarj between {TMIN} and {TMAX}
            and t.vta_cierrey  = :b_y]', v_z),
      1, p_fecha, p_local, p_terminal, p_cierrey);
    v_testarj := v(1);

    -- Dolares recaudados (FunConsRecMon {USD}). FACO: totDol = tesDol
    v := fn_sql_nums(fn_rz(
      q'[select nvl(sum(x.mex_monto), 0)
           from VTA_{P}RECMEX x
          where x.mex_fecha    = :b_fecha
            and x.mex_local    = :b_local
            and x.mex_terminal = :b_term
            and x.id_mdareg    = {USD}
            and x.mex_cierrey  = :b_y]', v_z),
      1, p_fecha, p_local, p_terminal, p_cierrey);
    v_totdol := v(1);

    -- Compensado (Modulo1.StrSumCompensado, Gopcion = "T").
    -- Se mantiene UNION (no UNION ALL) para replicar exactamente al exe.
    v := fn_sql_nums(fn_rz(
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
        -- Vendedor / cajero (FACO: sin filtro VEN_REGUL)
        select (select nvl(sum(v.ven_monto), 0) from VTA_{P}DIFVEND v
                 where v.ven_fecha = :b_fecha and v.ven_local = :b_local
                   and v.ven_terminal = :b_term
                   and v.ven_cierrey = :b_y),
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
      ) c]', v_z),
      1, p_fecha, p_local, p_terminal, p_cierrey);
    v_comp := v(1);

    o_dif_caja   := (v_prsefe - v_totefe) + (v_prschd - v_totchd) + v_totdol
                  + (v_teschf - v_totchf) + (v_testarj - v_tottarj);
    o_compensado := v_comp;
    -- El exe redondea el compensado ANTES de restarlo (Form3Y.FormateaDatos):
    --   VG_ValorCompensado = Format(ValorCompensacion, gFormat)
    --   Label70 = Format(sumaBZ - VG_ValorCompensado, gFormat)
    -- gFormat de FACO = vta_parametros.vta_numformat '#,#0' (0 decimales, CA_DECIMAL).
    o_dif_real   := round(o_dif_caja - round(v_comp, fn_dec), fn_dec);
  end pr_cuadratura;

  -- Diferencia Real (Label70) = round(sumaBZ - round(compensado))
  function fn_dif_real (p_flg_pais in varchar2,
                        p_fecha    in date,
                        p_local    in number,
                        p_terminal in number,
                        p_cierrey  in number) return number is
    v_caja number; v_comp number; v_dr number;
  begin
    pr_config(p_flg_pais);
    pr_cuadratura(p_fecha, p_local, p_terminal, p_cierrey, v_caja, v_comp, v_dr);
    return v_dr;
  end fn_dif_real;

  -- Columna "Dif. de Caja" de Form43
  function fn_dif_caja (p_flg_pais in varchar2,
                        p_fecha    in date,
                        p_local    in number,
                        p_terminal in number,
                        p_cierrey  in number) return number is
    v_caja number; v_comp number; v_dr number;
  begin
    pr_config(p_flg_pais);
    pr_cuadratura(p_fecha, p_local, p_terminal, p_cierrey, v_caja, v_comp, v_dr);
    return v_caja;
  end fn_dif_caja;

  -- Columna "Compensacion" de Form43
  function fn_compensado (p_flg_pais in varchar2,
                          p_fecha    in date,
                          p_local    in number,
                          p_terminal in number,
                          p_cierrey  in number) return number is
    v_caja number; v_comp number; v_dr number;
  begin
    pr_config(p_flg_pais);
    pr_cuadratura(p_fecha, p_local, p_terminal, p_cierrey, v_caja, v_comp, v_dr);
    return v_comp;
  end fn_compensado;

  -- ---------------------------------------------------------------
  -- RY-01 Cheque a fecha: gestion de cheques (tipo 1) = tesoreria
  -- (dia completo, sin filtro de Y, igual que el exe)
  -- ---------------------------------------------------------------
  function fn_msg_cheque_fecha (p_flg_pais in varchar2,
                                p_fecha    in date,
                                p_local    in number,
                                p_terminal in number) return varchar2 is
    v         t_nums;
    v_gestion number;
    v_tesor   number;
  begin
    pr_config(p_flg_pais);
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

    if round(v_gestion, fn_dec) <> round(v_tesor, fn_dec) then
      return 'Existe diferencia para el concepto cheques a Fecha entre la Gestion de Cheque : ( '
             || v_gestion || ' ) versus columna tesoreria : ( ' || v_tesor || ' ) , para poder cerrar Y.';
    end if;
    return null;
  end fn_msg_cheque_fecha;

  -- ---------------------------------------------------------------
  -- RY-03 Concepto declarado sin regularizar (FuncvalidarConcepto)
  -- ---------------------------------------------------------------
  function fn_concepto_pendiente (p_flg_pais in varchar2,
                                  p_fecha    in date,
                                  p_local    in number,
                                  p_terminal in number,
                                  p_cierrey  in number,
                                  p_tipo     in varchar2) return boolean is
    v t_nums;
  begin
    pr_config(p_flg_pais);
    -- PROC_YZ: p_cierrey NULL = todo el dia, sin filtro de Y (RZ-03, Form3.FuncvalidarConcepto :1872)
    v := fn_sql_nums(fn_rz(
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
      end, p_cierrey is null),
      1, p_fecha, p_local, p_terminal, p_cierrey, p_tipo);
    return nvl(v(1), 0) > 0;
  end fn_concepto_pendiente;

  -- ---------------------------------------------------------------
  -- RY-06 Formula ZZZ de la Y (FuncValidaZZZ + FuncMontoValidaZZZYY)
  -- Verificado en test (06-10-2026): VTA_PAINT_Z.vta_signo es CHAR(1) y vale
  -- '+' en todas las filas FACO; los campos de vta_cmp_asoc existen en una
  -- sola de VTA_<pfx>LIBVTA / VTA_<pfx>ZZZ, por lo que van sin prefijo.
  -- Diferencia = F7 - F6 - F5 - F4 - F3 - F2 - F1, con F(k) armada desde
  -- VTA_PAINT_Z.vta_validadorzzz = k (filas del pais: vta_localiz). Corrige
  -- el bug del exe (Form3Y pasaba el local en vez del numero de Y).
  -- ---------------------------------------------------------------
  function fn_zzz (p_flg_pais in varchar2,
                   p_fecha    in date,
                   p_local    in number,
                   p_terminal in number,
                   p_cierrey  in number) return number is
    type t_num is table of number index by pls_integer;
    v_f    t_num;
    v_expr varchar2(4000);
    v_sql  varchar2(4000);
  begin
    pr_config(p_flg_pais);
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
        if p_cierrey is null then
          -- PROC_YZ: formula ZZZ de la Z (RZ-08, FuncMontoValidaZZZ :4105): libro 'F8', sin Y
          v_sql := v_sql || ' and l.vta_tiporeg = ''' || g_cfg.nivel_z || '''';
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
  -- Validaciones Y (orden de Form3Y.CierraTerminal; estado y DR se
  -- evaluan antes en el proceso, segun el diagrama del Proceso 2)
  -- ---------------------------------------------------------------
  procedure pr_valida_y (p_flg_pais in  varchar2,
                         p_fecha    in  date,
                         p_local    in  number,
                         p_terminal in  number,
                         p_cierrey  in  number,
                         o_regla    out varchar2,
                         o_mensaje  out varchar2) is
    v_c   t_conceptos := fn_conceptos;
    v_k   varchar2(2);
    v_zzz number;
  begin
    pr_config(p_flg_pais);
    o_regla := null; o_mensaje := null;

    -- RY-01 cheque a fecha
    if fn_param(p_flg_pais, 'CA_VAL_CHEQ', 'S') = 'S' then
      o_mensaje := fn_msg_cheque_fecha(p_flg_pais, p_fecha, p_local, p_terminal);
      if o_mensaje is not null then o_regla := 'RY-01'; return; end if;
    end if;

    -- RY-03 conceptos sin regularizar en la Y (orden del exe)
    for i in 1 .. 10 loop
      v_k := case i when 1 then 'SN' when 2 then 'AF' when 3 then 'ND' when 4 then 'FN'
                    when 5 then 'NP' when 6 then 'BF' when 7 then 'CR' when 8 then 'CT'
                    when 9 then 'CA' else 'DP' end;
      if fn_concepto_pendiente(p_flg_pais, p_fecha, p_local, p_terminal, p_cierrey, v_k) then
        o_regla := 'RY-03'; o_mensaje := v_c(v_k); return;
      end if;
    end loop;

    -- RY-06 formula ZZZ (opcion 103 del exe, aqui flag)
    if fn_param(p_flg_pais, 'CA_VAL_ZZZ', 'N') = 'S' then
      v_zzz := fn_zzz(p_flg_pais, p_fecha, p_local, p_terminal, p_cierrey);
      if v_zzz <> 0 then
        o_regla := 'RY-06';
        o_mensaje := 'Error, Y descuadrada, favor revisar... diferencia : ' || v_zzz;
        return;
      end if;
    end if;
  end pr_valida_y;

  -- =================================================================
  -- PROC_YZ: validaciones de la Z (Form3.CierraTerminal :3439)
  -- =================================================================

  -- RZ-07 Todas las Y del terminal y dia cerradas (FuncValidadCierreyyyy :2153).
  -- Diferencias con el exe, a pedido del negocio ("para cerrar la Z deben
  -- estar cerradas todas las Y"):
  --   * revisa TODAS las filas de VTA_<pfx>TERMSTATY del terminal-dia (el exe
  --     solo las que tienen libro de ventas de la Y);
  --   * sin ninguna Y la Z NO se cierra (el exe avisa y deja seguir, D2),
  --     salvo CA_Z_SIN_Y = S.
  -- o_resultado: null (OK), Z_SIN_Y o Z_Y_ABIERTAS.
  procedure pr_y_cerradas (p_fecha     in  date,
                           p_local     in  number,
                           p_terminal  in  number,
                           o_resultado out varchar2,
                           o_mensaje   out varchar2) is
    v_total number;
    v_y     number;
    v_est   number;
  begin
    o_resultado := null; o_mensaje := null;
    execute immediate fn_r(
      q'[select count(*) from VTA_{P}TERMSTATY t
          where t.ter_fecha = :1 and t.ter_local = :2 and t.ter_terminal = :3]')
      into v_total using p_fecha, p_local, p_terminal;

    if v_total = 0 then
      if fn_param(g_cfg.pais, 'CA_Z_SIN_Y', 'N') <> 'S' then
        o_resultado := 'Z_SIN_Y';
        o_mensaje   := 'El terminal no tiene cierres Y para el dia: la Z no se cierra (CA_Z_SIN_Y = N)';
      end if;
      return;
    end if;

    -- Primera Y no cerrada (estado distinto de 1: -1/0 pendiente, 2 impreso, 3 sin dato)
    begin
      execute immediate fn_r(
        q'[select y, e from (
             select t.ter_cierrey y, nvl(t.ter_estado, 0) e
               from VTA_{P}TERMSTATY t
              where t.ter_fecha = :1 and t.ter_local = :2 and t.ter_terminal = :3
                and nvl(t.ter_estado, 0) <> 1
              order by t.ter_cierrey)
            where rownum = 1]')
        into v_y, v_est using p_fecha, p_local, p_terminal;
    exception
      when no_data_found then
        return;   -- todas cerradas
    end;

    o_resultado := 'Z_Y_ABIERTAS';
    o_mensaje   := 'No se puede cerrar el terminal, Porque se encuentra con estado '
                   || case when v_est in (-1, 0) then 'Pendiente'
                           when v_est = 2 then 'Impreso'
                           when v_est = 3 then 'Sin dato'
                           else 'desconocido (' || v_est || ')' end
                   || ', el N de cierre de Y : ' || v_y || ' del terminal : ' || p_terminal;
  end pr_y_cerradas;

  -- RZ-06 Z = suma de las Y (Modulo1.FuncValidarZSumaY :5531 / FuncBuscaValorCampoLib).
  -- Por cada campo de VTA_PAINT_Z del pais sin pop-up y con vta_order_z fuera
  -- de 56..76: suma en libro 'F8' + zzz + TERMSTAT contra suma en libro 'Y' +
  -- zzz + TERMSTATY (vta_secuencia = ter_cierrey). Devuelve el mensaje de la
  -- primera diferencia, o NULL si cuadra.
  function fn_z_suma_y (p_flg_pais in varchar2,
                        p_fecha    in date,
                        p_local    in number,
                        p_terminal in number) return varchar2 is
    v_z  number;
    v_y  number;
  begin
    pr_config(p_flg_pais);
    for c in (select trim(z.vtaglosa_z) glosa, trim(z.vta_cmp_asoc) campo
                from VTA_PAINT_Z z
               where z.vta_localiz = g_cfg.localiz
                 and nvl(z.vta_pop_up, 0) = 0
                 and z.vta_cmp_asoc is not null
                 and (z.vta_order_z < 56 or z.vta_order_z > 76)
               order by z.vta_order_z) loop
      execute immediate fn_r(
        'select nvl(sum(' || c.campo || '), 0)'
        || ' from VTA_{P}LIBVTA l, VTA_{P}ZZZ r, VTA_{P}TERMSTAT t'
        || ' where l.vta_tiporeg = ''' || g_cfg.nivel_z || ''''
        || ' and l.vta_fecha_venta = :1 and l.vta_local = :2 and l.vta_terminal = :3'
        || q'[ and l.vta_estado = 'A' and l.vta_techkey = r.rec_techkey]'
        || ' and l.vta_fecha_venta = t.ter_fecha and l.vta_local = t.ter_local'
        || ' and l.vta_terminal = t.ter_terminal')
        into v_z using p_fecha, p_local, p_terminal;

      execute immediate fn_r(
        'select nvl(sum(' || c.campo || '), 0)'
        || ' from VTA_{P}LIBVTA l, VTA_{P}ZZZ r, VTA_{P}TERMSTATY t'
        || q'[ where l.vta_tiporeg = '{NIVEL}']'
        || ' and l.vta_fecha_venta = :1 and l.vta_local = :2 and l.vta_terminal = :3'
        || q'[ and l.vta_estado = 'A' and l.vta_techkey = r.rec_techkey]'
        || ' and l.vta_fecha_venta = t.ter_fecha and l.vta_local = t.ter_local'
        || ' and l.vta_terminal = t.ter_terminal and l.vta_secuencia = t.ter_cierrey')
        into v_y using p_fecha, p_local, p_terminal;

      if v_z - v_y <> 0 then
        return 'En el monto ' || c.glosa || ' Existe diferencia entre el Z y la sumatoria de las Y'
               || ' (Z ' || v_z || ' / suma Y ' || v_y || ')';
      end if;
    end loop;
    return null;
  end fn_z_suma_y;

  -- RZ-09 Dolares declarados vs dolares de la transportadora
  -- (Form3.FuncvalidarDifDolares :1966). 0 = cuadra.
  function fn_dolares_z (p_flg_pais in varchar2,
                         p_fecha    in date,
                         p_local    in number,
                         p_terminal in number) return number is
    v t_nums;
  begin
    pr_config(p_flg_pais);
    v := fn_sql_nums(fn_r(
      q'[select (select nvl(sum(nvl(r.mex_cantidad, 0) * -1), 0)
                   from VTA_{P}RECMEX r
                  where r.mex_fecha = :b_fecha and r.mex_local = :b_local
                    and r.id_mdareg = {USD} and r.mex_terminal = :b_term)
              + (select nvl(sum(nvl(p.prv_montosobre, 0) + nvl(p.prv_montodif, 0)), 0)
                   from VTA_{P}PRD p
                  where p.prv_fechavta = :b_fecha and p.prv_tiporec = 'DOL'
                    and p.prv_local = :b_local and p.prv_terminal = :b_term)
           from dual]'),
      1, p_fecha, p_local, p_terminal, null);
    return round(nvl(v(1), 0), fn_dec);
  end fn_dolares_z;

  -- Validaciones de "Cerrar Terminal" de la Z (Form3.CierraTerminal) salvo el
  -- estado (RZ-02) y la diferencia real (RZ-05), que se evaluan antes en
  -- pr_procesa_z, como en la Y. o_regla null = todas OK. Orden:
  --   RZ-07 Y cerradas (primero: es el requisito del negocio)
  --   RZ-01 cheque a fecha (CA_VAL_CHEQ; el exe exime perfiles 8/10/12, aqui no hay perfil)
  --   RZ-03 conceptos sin regularizar en TODO el dia
  --   RZ-06 Z = suma de las Y (CA_Z_VAL_SUMA)
  --   RZ-08 formula ZZZ de la Z (CA_VAL_ZZZ, opcion 103 del exe)
  --   RZ-09 dolares (CA_Z_VAL_DOL, opcion 109 del exe)
  procedure pr_valida_z (p_flg_pais in  varchar2,
                         p_fecha    in  date,
                         p_local    in  number,
                         p_terminal in  number,
                         o_regla    out varchar2,
                         o_mensaje  out varchar2) is
    v_c   t_conceptos := fn_conceptos;
    v_k   varchar2(2);
    v_res varchar2(30);
    v_num number;
  begin
    pr_config(p_flg_pais);
    o_regla := null; o_mensaje := null;

    -- RZ-07 todas las Y cerradas
    pr_y_cerradas(p_fecha, p_local, p_terminal, v_res, o_mensaje);
    if v_res is not null then o_regla := 'RZ-07'; return; end if;

    -- RZ-01 cheque a fecha (dia completo, igual que la Y)
    if fn_param(p_flg_pais, 'CA_VAL_CHEQ', 'S') = 'S' then
      o_mensaje := fn_msg_cheque_fecha(p_flg_pais, p_fecha, p_local, p_terminal);
      if o_mensaje is not null then o_regla := 'RZ-01'; return; end if;
    end if;

    -- RZ-03 conceptos sin regularizar en el dia (sin filtro de Y)
    for i in 1 .. 10 loop
      v_k := case i when 1 then 'SN' when 2 then 'AF' when 3 then 'ND' when 4 then 'FN'
                    when 5 then 'NP' when 6 then 'BF' when 7 then 'CR' when 8 then 'CT'
                    when 9 then 'CA' else 'DP' end;
      if fn_concepto_pendiente(p_flg_pais, p_fecha, p_local, p_terminal, null, v_k) then
        o_regla := 'RZ-03'; o_mensaje := v_c(v_k); return;
      end if;
    end loop;

    -- RZ-06 Z = suma de las Y
    if fn_param(p_flg_pais, 'CA_Z_VAL_SUMA', 'S') = 'S' then
      o_mensaje := fn_z_suma_y(p_flg_pais, p_fecha, p_local, p_terminal);
      if o_mensaje is not null then o_regla := 'RZ-06'; return; end if;
    end if;

    -- RZ-08 formula ZZZ de la Z
    if fn_param(p_flg_pais, 'CA_VAL_ZZZ', 'N') = 'S' then
      v_num := fn_zzz(p_flg_pais, p_fecha, p_local, p_terminal, null);
      if v_num <> 0 then
        o_regla := 'RZ-08';
        o_mensaje := 'Error, Z descuadrada, favor revisar... diferencia : ' || v_num;
        return;
      end if;
    end if;

    -- RZ-09 dolares declarados = dolares de la transportadora
    if fn_param(p_flg_pais, 'CA_Z_VAL_DOL', 'N') = 'S' then
      v_num := fn_dolares_z(p_flg_pais, p_fecha, p_local, p_terminal);
      if v_num <> 0 then
        o_regla := 'RZ-09';
        o_mensaje := 'Error, existen diferencias entre los dolares declarados y los dolares informado'
                     || ' por Prosegur , favor revisar... diferencia ' || v_num;
        return;
      end if;
    end if;
  end pr_valida_z;

  -- ---------------------------------------------------------------
  -- Marca las filas de la cola de una caja.
  --   Proceso automatico (T2): solo las de SU carga (E de esta ejecucion); los
  --     sobres que llegaron mientras corria (P) quedan para la siguiente.
  --   Consultas de Cuadratura (CC): las pendientes (P o E) de la caja.
  --   p_estado null = no cambia el estado (cierre CC que no cerro la caja).
  -- ---------------------------------------------------------------
  procedure pr_marca_cola (p_fecha in date, p_local in number, p_terminal in number,
                           p_cierrey in number, p_estado in varchar2,
                           p_resultado in varchar2, p_mensaje in varchar2) is
    v_filtro varchar2(200);
  begin
    if g_proceso = 'CC' then
      v_filtro := q'[q.pcr_estado in ('P', 'E')]';
    else
      v_filtro := q'[q.pcr_estado = 'E' and q.pcr_ejecucion = ]' || to_char(trunc(g_ejecucion));
    end if;
    execute immediate fn_r(
      q'[update VTA_{P}PRD_CIERRE q
            set q.pcr_estado    = nvl(:1, q.pcr_estado),
                q.pcr_resultado = :2,
                q.pcr_mensaje   = :3,
                q.pcr_fechaproc = sysdate,
                q.pcr_ejecucion = :4,
                q.pcr_intentos  = q.pcr_intentos + 1
          where ]' || v_filtro || q'[
            and q.prv_fechavta = :5
            and q.prv_local    = :6
            and q.prv_terminal = :7
            and q.prv_cierrey  = :8]')
      using p_estado, p_resultado, substr(p_mensaje, 1, 1000), g_ejecucion,
            p_fecha, p_local, p_terminal, p_cierrey;
  end pr_marca_cola;

  function fn_nota (p_nota_actual in varchar2,
                    p_nivel       in varchar2 default 'Y',
                    p_largo       in number   default 2500) return varchar2 is
  begin
    -- La nota distingue el cierre desde Consultas de Cuadratura.
    -- PROC_YZ: la Z lleva 'Z' en la nota; la de la Y no cambia.
    return substr(case when g_proceso = 'CC' then 'CIERRE CC ' else 'CIERRE AUTOMATICO ' end
                  || case when p_nivel = 'Z' then 'Z FSCC-12901 '
                          when g_proceso = 'CC' then 'FSCC-12901 '
                          else 'FSCC-12958 ' end
                  || to_char(sysdate, 'dd-mm-yyyy hh24:mi')
                  || case when p_nota_actual is not null then ' | ' || p_nota_actual end, 1, p_largo);
  end fn_nota;

  -- Largo de TER_NOTAS en VTA_<pfx>TERMSTAT (la nota de la Z se corta a ese largo)
  function fn_largo_notas_z return number is
  begin
    if g_len_notas_z is null then
      begin
        select c.data_length into g_len_notas_z
          from user_tab_columns c
         where c.table_name = 'VTA_' || g_cfg.prefijo || 'TERMSTAT'
           and c.column_name = 'TER_NOTAS';
      exception
        when no_data_found then
          g_len_notas_z := 100;   -- prudente si no se encuentra (paquete con otro duenio)
      end;
    end if;
    return g_len_notas_z;
  end fn_largo_notas_z;

  -- ---------------------------------------------------------------
  -- Proceso de una Y (Proceso 2 del diagrama). o_resultado = log_resultado
  -- (CERRADA_Y, YA_CERRADA, CON_DIFERENCIA, BLOQUEADA, SIN_LIBVTA, OCUPADA, ...)
  -- Estado final de la cola (v2, una ejecucion por carga):
  --   proceso automatico (T2): C con el resultado, salvo OCUPADA que vuelve a P;
  --   Consultas de Cuadratura (CC): C solo si cerro; si no, sin cambio.
  -- ---------------------------------------------------------------
  procedure pr_procesa_y (p_fecha in date, p_local in number, p_terminal in number, p_cierrey in number,
                          o_resultado out varchar2) is
    v_estado  number;
    v_notas   varchar2(2500);
    v_nota    varchar2(2500);   -- nota nueva (fn_nota es privada: no se puede usar dentro del SQL, PLS-00231)
    v_dr      number;
    v_regla   varchar2(10);
    v_msg     varchar2(1000);
    v_fin     varchar2(1);      -- estado de cola para una caja que no se cierra
  begin
    v_fin := case when g_proceso = 'CC' then null else 'C' end;
    savepoint sp_y;

    begin
      execute immediate fn_r(
        q'[select t.ter_estado, t.ter_notas
             from VTA_{P}TERMSTATY t
            where t.ter_fecha = :1 and t.ter_local = :2
              and t.ter_terminal = :3 and t.ter_cierrey = :4
              for update nowait]')
        into v_estado, v_notas
        using p_fecha, p_local, p_terminal, p_cierrey;
    exception
      when no_data_found then
        pr_marca_cola(p_fecha, p_local, p_terminal, p_cierrey, v_fin, 'SIN_TERMSTAT', 'No existe el cierre Y en VTA_' || g_cfg.prefijo || 'TERMSTATY');
        commit;
        o_resultado := 'SIN_TERMSTAT';
        pr_log('Y', p_fecha, p_local, p_terminal, p_cierrey, null, 'SIN_TERMSTAT', 'RY-02', 'No existe el cierre Y en VTA_' || g_cfg.prefijo || 'TERMSTATY');
        return;
      when e_ocupada then
        pr_marca_cola(p_fecha, p_local, p_terminal, p_cierrey,
                      case when g_proceso = 'CC' then null else 'P' end,
                      'OCUPADA', 'Caja bloqueada por otro usuario');
        commit;
        o_resultado := 'OCUPADA';
        pr_log('Y', p_fecha, p_local, p_terminal, p_cierrey, null, 'OCUPADA', null, 'Caja bloqueada por otro usuario');
        return;
    end;

    -- RY-02 estado: 1 cerrado, 2 impreso, 3 sin datos -> no se reabre
    if v_estado > 0 then
      rollback to sp_y;
      pr_marca_cola(p_fecha, p_local, p_terminal, p_cierrey, 'C', 'YA_CERRADA', 'Terminal ya se Encuentra Cerrado');
      commit;
      o_resultado := 'YA_CERRADA';
      pr_log('Y', p_fecha, p_local, p_terminal, p_cierrey, null, 'YA_CERRADA', 'RY-02', 'Terminal ya se Encuentra Cerrado (estado ' || v_estado || ')');
      return;
    end if;

    -- Recalcular la Diferencia Real (diagrama) / RY-05
    v_dr := fn_dif_real(g_cfg.pais, p_fecha, p_local, p_terminal, p_cierrey);
    if v_dr is null then
      rollback to sp_y;
      pr_marca_cola(p_fecha, p_local, p_terminal, p_cierrey, v_fin, 'SIN_LIBVTA', 'No hay Z disponible (sin libro de ventas de la Y)');
      commit;
      o_resultado := 'SIN_LIBVTA';
      pr_log('Y', p_fecha, p_local, p_terminal, p_cierrey, null, 'SIN_LIBVTA', null, 'No hay Z disponible (sin libro de ventas de la Y)');
      return;
    elsif v_dr <> 0 then
      rollback to sp_y;
      pr_marca_cola(p_fecha, p_local, p_terminal, p_cierrey, v_fin, 'CON_DIFERENCIA', 'Falta Monto por Compensar');
      commit;
      o_resultado := 'CON_DIFERENCIA';
      pr_log('Y', p_fecha, p_local, p_terminal, p_cierrey, v_dr, 'CON_DIFERENCIA', 'RY-05', 'Falta Monto por Compensar');
      return;
    end if;

    -- Validaciones de Cerrar Terminal
    pr_valida_y(g_cfg.pais, p_fecha, p_local, p_terminal, p_cierrey, v_regla, v_msg);
    if v_regla is not null then
      rollback to sp_y;
      pr_marca_cola(p_fecha, p_local, p_terminal, p_cierrey, v_fin, 'BLOQUEADA', v_regla || ' ' || v_msg);
      commit;
      o_resultado := 'BLOQUEADA';
      pr_log('Y', p_fecha, p_local, p_terminal, p_cierrey, v_dr, 'BLOQUEADA', v_regla, v_msg);
      return;
    end if;

    -- Cerrar el cierre Y: estado cerrado, usuario de proceso, fecha y nota.
    v_nota := fn_nota(v_notas);
    execute immediate fn_r(
      q'[update VTA_{P}TERMSTATY t
            set t.ter_estado     = 1,
                t.ter_cerradopor = :1,
                t.ter_notas      = :2
          where t.ter_fecha = :3 and t.ter_local = :4
            and t.ter_terminal = :5 and t.ter_cierrey = :6]')
      using g_usuario, v_nota, p_fecha, p_local, p_terminal, p_cierrey;

    pr_marca_cola(p_fecha, p_local, p_terminal, p_cierrey, 'C', 'CERRADA_Y', null);
    commit;
    o_resultado := 'CERRADA_Y';
    pr_log('Y', p_fecha, p_local, p_terminal, p_cierrey, v_dr, 'CERRADA_Y', null, null);

  exception
    when others then
      v_msg := substr(sqlerrm, 1, 1000);
      begin
        rollback to sp_y;
      exception
        when others then rollback;   -- ORA-01086: el savepoint ya no existe tras un commit
      end;
      pr_marca_cola(p_fecha, p_local, p_terminal, p_cierrey, v_fin, 'ERROR', v_msg);
      commit;
      o_resultado := 'ERROR';
      pr_log('Y', p_fecha, p_local, p_terminal, p_cierrey, null, 'ERROR', null, v_msg);
  end pr_procesa_y;

  -- ---------------------------------------------------------------
  -- PROC_YZ: proceso de la Z de un terminal-dia (Form3.CierraTerminal).
  -- Se llama despues de evaluar las Y, solo si CA_CIERRA_Z = S.
  -- No toca la cola (la cola es por Y). Registra en el log con nivel 'Z' y
  -- log_cierrey nulo. o_resultado = log_resultado:
  --   CERRADA_Z, Z_YA_CERRADA, Z_SIN_TERMSTAT, Z_SIN_Y, Z_Y_ABIERTAS,
  --   Z_SIN_LIBVTA, Z_CON_DIFERENCIA, Z_BLOQUEADA, OCUPADA, ERROR
  -- Orden: bloqueo -> RZ-02 estado -> RZ-07 Y cerradas -> RZ-05 diferencia
  -- real del dia -> pr_valida_z (RZ-01, RZ-03, RZ-06, RZ-08, RZ-09) -> UPDATE.
  -- ---------------------------------------------------------------
  procedure pr_procesa_z (p_fecha in date, p_local in number, p_terminal in number,
                          o_resultado out varchar2) is
    v_estado  number;
    v_notas   varchar2(4000);
    v_nota    varchar2(4000);
    v_dr      number;
    v_regla   varchar2(10);
    v_res     varchar2(30);
    v_msg     varchar2(1000);
  begin
    savepoint sp_z;

    -- Bloquear la Z (D5: el exe no bloquea)
    begin
      execute immediate fn_r(
        q'[select t.ter_estado, t.ter_notas
             from VTA_{P}TERMSTAT t
            where t.ter_fecha = :1 and t.ter_local = :2 and t.ter_terminal = :3
              for update nowait]')
        into v_estado, v_notas
        using p_fecha, p_local, p_terminal;
    exception
      when no_data_found then
        o_resultado := 'Z_SIN_TERMSTAT';
        pr_log('Z', p_fecha, p_local, p_terminal, null, null, 'Z_SIN_TERMSTAT', 'RZ-02',
               'No existe la Z en VTA_' || g_cfg.prefijo || 'TERMSTAT');
        return;
      when e_ocupada then
        o_resultado := 'OCUPADA';
        pr_log('Z', p_fecha, p_local, p_terminal, null, null, 'OCUPADA', null, 'Z bloqueada por otro usuario');
        return;
    end;

    -- RZ-02 estado: 1 cerrado, 2 impreso, 3 sin datos -> no se toca
    if nvl(v_estado, 0) > 0 then
      rollback to sp_z;
      o_resultado := 'Z_YA_CERRADA';
      pr_log('Z', p_fecha, p_local, p_terminal, null, null, 'Z_YA_CERRADA', 'RZ-02',
             'Terminal ya se Encuentra Cerrado (estado ' || v_estado || ')');
      return;
    end if;

    -- RZ-07 todas las Y cerradas (antes de calcular: es lo mas frecuente)
    pr_y_cerradas(p_fecha, p_local, p_terminal, v_res, v_msg);
    if v_res is not null then
      rollback to sp_z;
      o_resultado := v_res;
      pr_log('Z', p_fecha, p_local, p_terminal, null, null, v_res, 'RZ-07', v_msg);
      return;
    end if;

    -- RZ-05 diferencia real del dia (Form3 Label70)
    v_dr := fn_dif_real(g_cfg.pais, p_fecha, p_local, p_terminal, null);
    if v_dr is null then
      rollback to sp_z;
      o_resultado := 'Z_SIN_LIBVTA';
      pr_log('Z', p_fecha, p_local, p_terminal, null, null, 'Z_SIN_LIBVTA', 'RZ-05',
             'No hay libro de ventas de la Z (vta_tiporeg ' || g_cfg.nivel_z || ')');
      return;
    elsif v_dr <> 0 then
      rollback to sp_z;
      o_resultado := 'Z_CON_DIFERENCIA';
      pr_log('Z', p_fecha, p_local, p_terminal, null, v_dr, 'Z_CON_DIFERENCIA', 'RZ-05', 'Falta Monto por Compensar');
      return;
    end if;

    -- Resto de las validaciones de Cerrar Terminal de la Z
    pr_valida_z(g_cfg.pais, p_fecha, p_local, p_terminal, v_regla, v_msg);
    if v_regla is not null then
      rollback to sp_z;
      o_resultado := case when v_regla = 'RZ-07' then 'Z_Y_ABIERTAS' else 'Z_BLOQUEADA' end;
      pr_log('Z', p_fecha, p_local, p_terminal, null, v_dr, o_resultado, v_regla, v_msg);
      return;
    end if;

    -- Cerrar la Z: estado cerrado, usuario de proceso y nota (Form3 no graba
    -- ter_fechacierre en FACO).
    v_nota := fn_nota(v_notas, 'Z', fn_largo_notas_z);
    execute immediate fn_r(
      q'[update VTA_{P}TERMSTAT t
            set t.ter_estado     = 1,
                t.ter_cerradopor = :1,
                t.ter_notas      = :2
          where t.ter_fecha = :3 and t.ter_local = :4 and t.ter_terminal = :5]')
      using g_usuario, v_nota, p_fecha, p_local, p_terminal;
    commit;
    o_resultado := 'CERRADA_Z';
    pr_log('Z', p_fecha, p_local, p_terminal, null, v_dr, 'CERRADA_Z', null, null);

  exception
    when others then
      v_msg := substr(sqlerrm, 1, 1000);
      begin
        rollback to sp_z;
      exception
        when others then rollback;
      end;
      o_resultado := 'ERROR';
      pr_log('Z', p_fecha, p_local, p_terminal, null, null, 'ERROR', null, v_msg);
  end pr_procesa_z;

  -- Agrega el terminal-dia a la lista de Z a evaluar (sin repetir)
  procedure pr_agrega_term (p_terms in out nocopy t_terms,
                            p_fecha in date, p_local in number, p_terminal in number) is
    v_k varchar2(40) := to_char(p_fecha, 'yyyymmdd') || '|' || lpad(p_local, 6, '0')
                        || '|' || lpad(p_terminal, 6, '0');
    v_r t_term;
  begin
    if not p_terms.exists(v_k) then
      v_r.f := p_fecha;
      v_r.l := p_local;
      v_r.t := p_terminal;
      p_terms(v_k) := v_r;
    end if;
  end pr_agrega_term;

  -- Evalua la Z de cada terminal-dia de la lista. Devuelve cerradas / no cerradas.
  procedure pr_procesa_lista_z (p_terms   in out nocopy t_terms,
                                o_cerr    out number,
                                o_nocer   out number) is
    v_k   varchar2(40);
    v_res varchar2(30);
  begin
    o_cerr := 0; o_nocer := 0;
    v_k := p_terms.first;
    while v_k is not null loop
      pr_procesa_z(p_terms(v_k).f, p_terms(v_k).l, p_terms(v_k).t, v_res);
      if v_res = 'CERRADA_Z' then
        o_cerr := o_cerr + 1;
      elsif v_res <> 'Z_YA_CERRADA' then
        o_nocer := o_nocer + 1;
      end if;
      v_k := p_terms.next(v_k);
    end loop;
  end pr_procesa_lista_z;

  -- ---------------------------------------------------------------
  -- Punto de entrada del proceso automatico (T1 -> T2). Cierres Y y, con
  -- CA_CIERRA_Z = S, la Z de cada terminal-dia evaluado (PROC_YZ).
  -- ---------------------------------------------------------------
  procedure prc_cierre_automatico (p_flg_pais  in varchar2,
                                   p_usuario   in varchar2 default 'PROC_CIERRE_AUTO',
                                   p_max_cajas in number   default null) is
    v_cur   sys_refcursor;
    v_f     date;
    v_l     number;
    v_t     number;
    v_y     number;
    v_n     number := 0;
    v_cerr  number := 0;
    v_nocer number := 0;
    v_carga number;
    v_res   varchar2(30);
    v_terms t_terms;          -- PROC_YZ: terminal-dia de las Y evaluadas
    v_zcerr  number := 0;
    v_znocer number := 0;
    v_txt_z  varchar2(200);
  begin
    pr_config(p_flg_pais);
    g_proceso   := 'T2';   -- el estado del paquete persiste en la sesion
    g_usuario   := nvl(substr(p_usuario, 1, 50), c_usuario_def);
    g_dec       := null;
    g_ejecucion := fn_nueva_ejecucion(g_cfg.pais);

    -- Interruptores independientes: CA_DI_ACTIVO (T1) y CA_ACTIVO (T2).
    -- Si ambos estan apagados no se hace nada (la cola queda pendiente).
    if fn_param(g_cfg.pais, 'CA_ACTIVO', 'N') <> 'S' and fn_param(g_cfg.pais, 'CA_DI_ACTIVO', 'N') <> 'S' then
      pr_log('-', null, null, null, null, null, 'INACTIVO', null, 'Parametros 1502 CA_ACTIVO y CA_DI_ACTIVO distintos de S');
      return;
    end if;
    pr_log('-', null, null, null, null, null, 'INICIO', null, 'Pais ' || g_cfg.pais || ' | usuario ' || g_usuario);

    -- Sobres sin cierre Y: no se pueden asociar a una caja.
    -- PRV_CIERREY es NUMBER(2) NOT NULL DEFAULT 0 en VTA_<pfx>PRD: 0 = sin Y.
    execute immediate fn_r(
      q'[update VTA_{P}PRD_CIERRE q
            set q.pcr_estado = 'O', q.pcr_resultado = 'SIN_CIERREY',
                q.pcr_mensaje = 'Sobre sin numero de cierre Y', q.pcr_fechaproc = sysdate,
                q.pcr_ejecucion = :1
          where q.pcr_estado in ('P', 'E') and nvl(q.prv_cierrey, 0) = 0]')
      using g_ejecucion;

    -- Tomar la carga (modo CARGA): lo pendiente pasa a E con esta ejecucion.
    -- Incluye filas E de una ejecucion anterior que no termino.
    -- Lo que llegue mientras corre el proceso queda en P para la siguiente.
    execute immediate fn_r(
      q'[update VTA_{P}PRD_CIERRE q
            set q.pcr_estado = 'E', q.pcr_ejecucion = :1
          where q.pcr_estado in ('P', 'E')]')
      using g_ejecucion;
    v_carga := sql%rowcount;
    commit;

    -- T1: compensacion automatica de DI sobre las mismas cajas, ANTES del
    -- cierre (diagrama general: T1 -> T2). T1 revisa su propio interruptor
    -- (CA_DI_ACTIVO) y registra en el mismo log con log_proceso = 'T1'.
    -- Un error en T1 no impide ejecutar T2.
    begin
      PKG_F8_COMPENSA_DI_AUTO.prc_compensa_di(p_flg_pais  => g_cfg.pais,
                                              p_ejecucion => g_ejecucion,
                                              p_max_cajas => p_max_cajas);
    exception
      when others then
        pr_log('-', null, null, null, null, null, 'ERROR', null,
               'Fallo T1 (PKG_F8_COMPENSA_DI_AUTO): ' || substr(sqlerrm, 1, 900));
    end;
    pr_config(p_flg_pais);   -- T1 puede haber usado otro pais en esta sesion

    -- T2 apagado: la carga queda procesada solo por T1
    if fn_param(g_cfg.pais, 'CA_ACTIVO', 'N') <> 'S' then
      execute immediate fn_r(
        q'[update VTA_{P}PRD_CIERRE q
              set q.pcr_estado = 'C', q.pcr_resultado = 'SOLO_T1', q.pcr_fechaproc = sysdate,
                  q.pcr_mensaje = 'CA_ACTIVO distinto de S: la carga se evaluo solo con T1'
            where q.pcr_estado = 'E' and q.pcr_ejecucion = :1]')
        using g_ejecucion;
      commit;
      pr_log('-', null, null, null, null, null, 'INACTIVO', null, 'Parametro 1502 CA_ACTIVO distinto de S: solo se ejecuto T1');
      return;
    end if;

    -- Cierres Y de la carga (cola E + cajas sin sobres del mismo local-dia;
    -- incluye las que ya tenian DR 0 y las compensadas por T1).
    v_cur := fn_universo(g_cfg.pais, g_ejecucion);
    loop
      fetch v_cur into v_f, v_l, v_t, v_y;
      exit when v_cur%notfound;
      exit when p_max_cajas is not null and v_n >= p_max_cajas;
      v_n := v_n + 1;
      pr_procesa_y(v_f, v_l, v_t, v_y, v_res);
      if v_res = 'CERRADA_Y' then
        v_cerr := v_cerr + 1;
      elsif v_res <> 'YA_CERRADA' then
        v_nocer := v_nocer + 1;
      end if;
      pr_agrega_term(v_terms, v_f, v_l, v_t);
    end loop;
    close v_cur;

    -- Lo que quedo en E (limite p_max_cajas) vuelve a P para la siguiente ejecucion.
    execute immediate fn_r(
      q'[update VTA_{P}PRD_CIERRE q
            set q.pcr_estado = 'P', q.pcr_resultado = 'NO_EVALUADA'
          where q.pcr_estado = 'E' and q.pcr_ejecucion = :1]')
      using g_ejecucion;
    commit;

    -- PROC_YZ: la Z de cada terminal-dia evaluado, si CA_CIERRA_Z = S
    -- (con N la Z no se toca, igual que PROC_Y).
    if fn_param(g_cfg.pais, 'CA_CIERRA_Z', 'N') = 'S' then
      pr_procesa_lista_z(v_terms, v_zcerr, v_znocer);
      v_txt_z := ' | Z evaluadas: ' || v_terms.count || ' | Z cerradas: ' || v_zcerr
                 || ' | Z no cerradas: ' || v_znocer;
    end if;

    pr_log('-', null, null, null, null, null, 'FIN', null,
           'Sobres de la carga: ' || v_carga || ' | Cierres Y evaluados: ' || v_n
           || ' | Y cerradas: ' || v_cerr || ' | Y no cerradas: ' || v_nocer || v_txt_z);
  exception
    when others then
      if v_cur%isopen then
        close v_cur;
      end if;
      rollback;
      pr_log('-', null, null, null, null, null, 'ERROR', null, sqlerrm);
      raise;
  end prc_cierre_automatico;

  -- ---------------------------------------------------------------
  -- Punto de entrada de Consultas de Cuadratura (Form43, boton "Cerrar
  -- Terminal"), un dia por vez. DF-SCC fila 12: cerrar desde CC las cajas
  -- con Diferencia Real 0, incluidas las cajas sin movimiento. Cierres Y y,
  -- con CA_CIERRA_Z = S, las Z abiertas del dia (PROC_YZ).
  -- ---------------------------------------------------------------
  procedure prc_cierre_dia (p_flg_pais    in  varchar2,
                            p_fecha       in  varchar2,
                            p_local       in  number,
                            p_terminal    in  number,
                            p_usuario     in  varchar2,
                            o_ejecucion   out number,
                            o_cerradas    out number,
                            o_no_cerradas out number) is
    v_dia   date;
    v_cur   sys_refcursor;
    v_f     date;
    v_l     number;
    v_t     number;
    v_y     number;
    v_res   varchar2(30);
    v_n     number := 0;
    v_terms  t_terms;         -- PROC_YZ
    v_zcerr  number := 0;
    v_znocer number := 0;
    v_txt_z  varchar2(200);
  begin
    o_cerradas    := 0;
    o_no_cerradas := 0;
    pr_config(p_flg_pais);
    g_proceso   := 'CC';
    g_usuario   := nvl(substr(trim(p_usuario), 1, 50), c_usuario_def);
    g_dec       := null;
    g_ejecucion := fn_nueva_ejecucion(g_cfg.pais);
    o_ejecucion := g_ejecucion;
    -- Un solo dia de venta (yyyymmdd), obligatorio
    if trim(p_fecha) is null then
      raise_application_error(-20002, 'Fecha obligatoria (yyyymmdd) para el cierre desde Consultas de Cuadratura');
    end if;
    v_dia := to_date(trim(p_fecha), 'yyyymmdd');

    pr_log('-', v_dia, p_local, nullif(p_terminal, 0), null, null, 'INICIO', null,
           'Consultas de Cuadratura dia ' || to_char(v_dia, 'dd-mm-yyyy') || ' usuario ' || g_usuario);

    -- Cierres Y abiertos con libro de ventas del dia (mismo universo que Form43)
    open v_cur for fn_r(
      q'[select distinct t.ter_fecha f, t.ter_local l, t.ter_terminal te, t.ter_cierrey y
           from VTA_{P}TERMSTATY t, VTA_{P}LIBVTA l, VTA_{P}ZZZ r
          where t.ter_fecha = :1
            and t.ter_local = :2
            and (nvl(:3, 0) = 0 or t.ter_terminal = :4)
            and t.ter_estado <= 0
            and l.vta_tiporeg = '{NIVEL}'
            and l.vta_estado = 'A'
            and l.vta_techkey = r.rec_techkey
            and l.vta_fecha_venta = t.ter_fecha
            and l.vta_local = t.ter_local
            and l.vta_terminal = t.ter_terminal
            and l.vta_secuencia = t.ter_cierrey
          order by 1, 2, 3, 4]')
      using v_dia, p_local, p_terminal, p_terminal;
    loop
      fetch v_cur into v_f, v_l, v_t, v_y;
      exit when v_cur%notfound;
      v_n := v_n + 1;
      pr_procesa_y(v_f, v_l, v_t, v_y, v_res);
      if v_res = 'CERRADA_Y' then
        o_cerradas := o_cerradas + 1;
      elsif v_res <> 'YA_CERRADA' then
        o_no_cerradas := o_no_cerradas + 1;
      end if;
    end loop;
    close v_cur;

    -- PROC_YZ: Z abiertas del dia, local y terminal (0 = todos), si CA_CIERRA_Z = S.
    -- Como Form43 para FACO: primero las Y y despues las Z. Incluye terminales
    -- cuyas Y ya estaban cerradas. Los contadores de salida siguen siendo de Y
    -- (misma firma que usa Form43); el resumen de la Z va en el FIN del log.
    if fn_param(g_cfg.pais, 'CA_CIERRA_Z', 'N') = 'S' then
      open v_cur for fn_r(
        q'[select t.ter_fecha, t.ter_local, t.ter_terminal
             from VTA_{P}TERMSTAT t
            where t.ter_fecha = :1
              and t.ter_local = :2
              and (nvl(:3, 0) = 0 or t.ter_terminal = :4)
              and nvl(t.ter_estado, 0) <= 0
            order by 1, 2, 3]')
        using v_dia, p_local, p_terminal, p_terminal;
      loop
        fetch v_cur into v_f, v_l, v_t;
        exit when v_cur%notfound;
        pr_agrega_term(v_terms, v_f, v_l, v_t);
      end loop;
      close v_cur;
      pr_procesa_lista_z(v_terms, v_zcerr, v_znocer);
      v_txt_z := ' | Z evaluadas: ' || v_terms.count || ' | Z cerradas: ' || v_zcerr
                 || ' | Z no cerradas: ' || v_znocer;
    end if;

    pr_log('-', v_dia, p_local, nullif(p_terminal, 0), null, null, 'FIN', null,
           'Cierres Y evaluados: ' || v_n || ' | Y cerradas: ' || o_cerradas
           || ' | Y no cerradas: ' || o_no_cerradas || v_txt_z);
    g_proceso := 'T2';
  exception
    when others then
      if v_cur%isopen then
        close v_cur;
      end if;
      rollback;
      pr_log('-', null, p_local, nullif(p_terminal, 0), null, null, 'ERROR', null, sqlerrm);
      g_proceso := 'T2';
      raise;
  end prc_cierre_dia;

end PKG_F8_CIERRE_AUTO;
/
