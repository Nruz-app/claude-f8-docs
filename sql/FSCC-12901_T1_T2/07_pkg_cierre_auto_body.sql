-- =====================================================================
-- FSCC-12901 T1 + T2 (carpeta consolidada) - Paso 07
-- Cuerpo T2 PKG_F8_FACO_CIERRE_AUTO (llama a T1 al inicio)
-- Fuente: docs/sql/FSCC-12958/06_pkg_cierre_auto_body.sql (mantener ambas copias iguales)
-- =====================================================================

-- =====================================================================
-- FSCC-12958 (HU-01-T2) Cierre de caja automatico - Falabella Colombia
-- 06 - Cuerpo de PKG_F8_FACO_CIERRE_AUTO   (Oracle 10.2)
--
-- Referencias al exe VB6 (FTEPROD/):
--   Form3Y.CierraTerminal :2801   Form3Y.FormateaDatos :2704
--   Form3Y.FuncvalidarConcepto :1700  Modulo1.StrSumCompensado :2630
--   Modulo1.FuncMontoValidaZZZYY :4160  StrCamposValidarZZZ :4053
--   Modulo1.Func_ValorGestionCheque :5681  Func_ValorChequeFecha :5632
-- FACO opera SOLO con cierre Y (decision 07-10-2026, FSCC-12901): el proceso
-- cierra VTA_FACOTERMSTATY y no toca la Z (VTA_FACOTERMSTAT), igual que
-- Form3Y.CierraTerminal. Las reglas RZ de Form3 no aplican.
-- Detalle funcional: docs/CierreCaja_FACO_Reglas.md
-- =====================================================================

create or replace package body PKG_F8_FACO_CIERRE_AUTO as

  -- ---------------------------------------------------------------
  -- Estado de la ejecucion
  -- ---------------------------------------------------------------
  g_ejecucion  number;
  g_usuario    varchar2(50) := c_usuario_def;
  g_dec        number;          -- decimales de redondeo (CA_DECIMAL)
  g_proceso    varchar2(2) := 'T2';  -- log_proceso: T2 automatico, CC Consultas de Cuadratura

  e_ocupada    exception;
  pragma exception_init(e_ocupada, -54);   -- ORA-00054 resource busy (NOWAIT)

  type t_conceptos is table of varchar2(200) index by varchar2(2);

  -- ---------------------------------------------------------------
  -- Utilitarios
  -- ---------------------------------------------------------------
  function fn_param (p_codigo  in varchar2,
                     p_default in varchar2) return varchar2 is
    v_valor varchar2(200);
  begin
    select trim(p.vta_xglosa)
      into v_valor
      from VTA_FACOPARAM p
     where p.vta_ccodtipo = c_tipo_param
       and trim(p.vta_ccodigo) = p_codigo
       and rownum = 1;
    return nvl(v_valor, p_default);
  exception
    when no_data_found then
      return p_default;
  end fn_param;

  function fn_dec return number is
  begin
    if g_dec is null then
      g_dec := to_number(fn_param('CA_DECIMAL', '0'));
    end if;
    return g_dec;
  end fn_dec;

  -- Log con transaccion autonoma: queda registrado aunque la caja haga rollback
  procedure pr_log (p_nivel     in varchar2,
                    p_fecha     in date,
                    p_local     in number,
                    p_terminal  in number,
                    p_cierrey   in number,
                    p_dif_real  in number,
                    p_resultado in varchar2,
                    p_regla     in varchar2,
                    p_mensaje   in varchar2) is
    pragma autonomous_transaction;
  begin
    insert into VTA_FACOLOG_CIERRE_AUTO
      (log_id, log_ejecucion, log_proceso, log_nivel, log_fecha_vta, log_local, log_terminal,
       log_cierrey, log_dif_real, log_resultado, log_regla, log_mensaje,
       log_usuario, log_fechahora)
    values
      (SEQ_VTA_FACOLOG_CIERRE_AUTO.nextval, nvl(g_ejecucion, 0), g_proceso, p_nivel,
       p_fecha, p_local, p_terminal, p_cierrey, p_dif_real, p_resultado, p_regla,
       substr(p_mensaje, 1, 1000), g_usuario, sysdate);
    commit;
  end pr_log;

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
  -- sumaBZ FACO = (prsefe-totefe)+(prschd-totchd)+totDol+(teschf-totchf)+(tesTarjeta-totTarjeta)
  -- Sin libro de ventas de la Y las tres salidas quedan en NULL ("No hay Z disponible").
  -- CK: FSCC-12901 - antes era el cuerpo de fn_dif_real; se separa para Form43.
  -- ---------------------------------------------------------------
  procedure pr_cuadratura (p_fecha      in  date,
                           p_local      in  number,
                           p_terminal   in  number,
                           p_cierrey    in  number,
                           o_dif_caja   out number,
                           o_compensado out number,
                           o_dif_real   out number) is
    v_tipo     varchar2(2) := 'Y';   -- FACO: solo cierre Y (07-10-2026)
    v_cnt      number;
    v_totefe   number; v_totchd number; v_totchf number; v_tottarj number;
    v_prsefe   number; v_prschd number;
    v_teschf   number; v_testarj number; v_totdol number;
    v_comp     number;
  begin
    -- Declarado en la Y / Z (LeeZ + ARMA_QUERY_Z, rama FACO)
    select count(*),
           nvl(sum(r.rec_mefectivo), 0),
           nvl(sum(r.rec_mchkdia), 0),
           nvl(sum(r.rec_mchkfecha), 0),
           nvl(sum(r.rec_mtarj), 0) + nvl(sum(r.rec_msodimac), 0)
      into v_cnt, v_totefe, v_totchd, v_totchf, v_tottarj
      from VTA_FACOLIBVTA l, VTA_FACOZZZ r
     where l.vta_tiporeg     = v_tipo
       and l.vta_fecha_venta = p_fecha
       and l.vta_local       = p_local
       and l.vta_terminal    = p_terminal
       and l.vta_estado      = 'A'
       and l.vta_techkey     = r.rec_techkey
       and l.vta_secuencia = p_cierrey;

    o_dif_caja := null; o_compensado := null; o_dif_real := null;
    if v_cnt = 0 then
      return;   -- sin libro de ventas: el exe muestra "No hay Z disponible"
    end if;

    -- Sobres Prosegur (LeeProsegur): tiporec F8, EFE / CHE
    select nvl(sum(case when p.prv_tiposobre = 'EFE' then nvl(p.prv_montosobre,0) + nvl(p.prv_montodif,0) end), 0),
           nvl(sum(case when p.prv_tiposobre = 'CHE' then nvl(p.prv_montosobre,0) + nvl(p.prv_montodif,0) end), 0)
      into v_prsefe, v_prschd
      from VTA_FACOPRD p
     where p.prv_fechavta = p_fecha
       and p.prv_local    = p_local
       and p.prv_terminal = p_terminal
       and p.prv_tiporec  = 'F8'
       and p.prv_cierrey = p_cierrey;

    -- Cheque a fecha en tesoreria (LeeTes). Form3Y toma la primera fila de la Y;
    -- aqui se suma. Verificado en test (06-10-2026): una fila por Y.
    select nvl(sum(t.tes_chefecha), 0)
      into v_teschf
      from VTA_FACOTESOR t
     where t.tes_fecha    = p_fecha
       and t.tes_local    = p_local
       and t.tes_terminal = p_terminal
       and t.tes_cierrey = p_cierrey;

    -- Tarjetas recaudadas (FuncLeeTarjeta CTARJ, FACO: codigos 2000-2999)
    select nvl(sum(t.vta_monto_inf), 0)
      into v_testarj
      from VTA_FACOTARJ t
     where t.vta_fecha    = p_fecha
       and t.vta_local    = p_local
       and t.vta_terminal = p_terminal
       and t.vta_cod_tarj between 2000 and 2999
       and t.vta_cierrey = p_cierrey;

    -- Dolares recaudados (FunConsRecMon 305). FACO: totDol = tesDol
    select nvl(sum(x.mex_monto), 0)
      into v_totdol
      from VTA_FACORECMEX x
     where x.mex_fecha    = p_fecha
       and x.mex_local    = p_local
       and x.mex_terminal = p_terminal
       and x.id_mdareg    = 305
       and x.mex_cierrey = p_cierrey;

    -- Compensado (Modulo1.StrSumCompensado, Gopcion = "T", rama FACO).
    -- Se mantiene UNION (no UNION ALL) para replicar exactamente al exe.
    select nvl(sum(c.mov_monto), 0)
      into v_comp
      from (
        -- TC: registrados el dia - regularizados ese dia
        select ( nvl((select sum(m.mov_monto) from VTA_FACOMOVDET m
                       where m.mov_fecha = p_fecha and m.mov_local = p_local
                         and m.mov_terminal = p_terminal
                         and m.mov_cierrey = p_cierrey
                         and m.mov_tipomov = 'TC'), 0)
               - nvl((select sum(m.mov_monto) from VTA_FACOMOVDET m
                       where m.mov_fechareg = p_fecha and m.mov_local = p_local
                         and m.mov_terminal = p_terminal
                         and m.mov_cierrey = p_cierrey
                         and m.mov_regul = 'S' and m.mov_tipomov = 'TC'), 0) ) mov_monto,
               d.mov_tipomov
          from VTA_FACOCONCEPDIF d
         where d.mov_tipomov = 'TC'
        union
        -- SN, ND, FN: regularizados del dia - regularizados ese dia
        select ( nvl((select sum(m.mov_monto) from VTA_FACOMOVDET m
                       where m.mov_fecha = p_fecha and m.mov_local = p_local
                         and m.mov_terminal = p_terminal
                         and m.mov_cierrey = p_cierrey
                         and m.mov_regul = 'S' and m.mov_tipomov = d.mov_tipomov), 0)
               - nvl((select sum(m.mov_monto) from VTA_FACOMOVDET m
                       where m.mov_fechareg = p_fecha and m.mov_local = p_local
                         and m.mov_terminal = p_terminal
                         and m.mov_cierrey = p_cierrey
                         and m.mov_regul = 'S' and m.mov_tipomov = d.mov_tipomov), 0) ),
               d.mov_tipomov
          from VTA_FACOCONCEPDIF d
         where d.mov_tipomov in ('SN', 'ND', 'FN')
        union
        -- BF
        select nvl((select sum(m.mov_monto) from VTA_FACOMOVDET m
                     where m.mov_fecha = p_fecha and m.mov_local = p_local
                       and m.mov_terminal = p_terminal
                       and m.mov_cierrey = p_cierrey
                       and m.mov_regul = 'S' and m.mov_tipomov = 'BF'), 0),
               d.mov_tipomov
          from VTA_FACOCONCEPDIF d
         where d.mov_tipomov = 'BF'
        union
        -- NP / FT (una fila por concepto de concepdif, cada una con la suma NP+FT)
        select nvl((select sum(m.mov_monto) from VTA_FACOMOVDET m
                     where m.mov_fecha = p_fecha and m.mov_local = p_local
                       and m.mov_terminal = p_terminal
                       and m.mov_cierrey = p_cierrey
                       and m.mov_regul = 'S' and m.mov_tipomov in ('NP', 'FT')), 0),
               d.mov_tipomov
          from VTA_FACOCONCEPDIF d
         where d.mov_tipomov in ('NP', 'FT')
        union
        -- Conceptos regularizados (incluye CA y DI para FACO)
        select nvl(sum(m.mov_monto), 0), d.mov_tipomov
          from VTA_FACOMOVDET m, VTA_FACOCONCEPDIF d
         where m.mov_fecha = p_fecha and m.mov_local = p_local
           and m.mov_terminal = p_terminal
           and m.mov_cierrey = p_cierrey
           and m.mov_regul = 'S'
           and m.mov_fechareg is not null
           and m.mov_tipomov = d.mov_tipomov
           and d.mov_tipomov in ('TU','DV','P1','P2','CM','CB','CC','SB','SC','SV','CP','CF','CT',
                                 'RE','CR','PC','DN','AF','DD','AA','DI','AV','RP','DP','CA','DE','PM')
         group by d.mov_tipomov
        union
        -- Carta aviso central (VTA_FACOCARTAAVISO)
        select nvl(sum(m.mov_monto), 0), d.mov_tipomov
          from VTA_FACOCARTAAVISO m, VTA_FACOCONCEPDIF d
         where m.mov_fecha = p_fecha and m.mov_local = p_local
           and m.mov_terminal = p_terminal
           and m.mov_cierrey = p_cierrey
           and m.mov_regul = 'S'
           and m.mov_fechareg is not null
           and m.mov_tipomov = d.mov_tipomov
           and d.mov_tipomov = 'CA'
         group by d.mov_tipomov
        union
        -- Vendedor / cajero (FACO: sin filtro VEN_REGUL)
        select (select nvl(sum(v.ven_monto), 0) from VTA_FACODIFVEND v
                 where v.ven_fecha = p_fecha and v.ven_local = p_local
                   and v.ven_terminal = p_terminal
                   and v.ven_cierrey = p_cierrey),
               d.mov_tipomov
          from VTA_FACOCONCEPDIF d
         where d.vta_coddif = 1
        union
        -- DT / NC con mov_numero <> terminal
        select nvl(sum(m.mov_monto), 0), d.mov_tipomov
          from VTA_FACOMOVDET m, VTA_FACOCONCEPDIF d
         where m.mov_fecha = p_fecha and m.mov_numero <> m.mov_terminal
           and m.mov_local = p_local and m.mov_terminal = p_terminal
           and m.mov_cierrey = p_cierrey
           and m.mov_tipomov = d.mov_tipomov
           and d.mov_tipomov in ('DT', 'NC')
         group by d.mov_tipomov
        union
        -- DT / NC con mov_numero = terminal
        select nvl(sum(m.mov_monto), 0), d.mov_tipomov
          from VTA_FACOMOVDET m, VTA_FACOCONCEPDIF d
         where m.mov_fecha = p_fecha and m.mov_numero = m.mov_terminal
           and m.mov_local = p_local and m.mov_terminal = p_terminal
           and m.mov_cierrey = p_cierrey
           and m.mov_tipomov = d.mov_tipomov
           and d.mov_tipomov in ('DT', 'NC')
         group by d.mov_tipomov
        union
        -- AL (cruce con libro de ventas: 'Y' en cierre Y, 'F8' en Z)
        select nvl(sum(m.mov_monto), 0), d.mov_tipomov
          from VTA_FACOMOVDET m, VTA_FACOCONCEPDIF d,
               VTA_FACOLIBVTA l, VTA_FACOZZZ z
         where m.mov_fecha = p_fecha and m.mov_numero = m.mov_terminal
           and m.mov_fecha = l.vta_fecha_venta
           and m.mov_local = l.vta_local
           and m.mov_terminal = l.vta_terminal
           and l.vta_techkey = z.rec_techkey and l.vta_estado = 'A'
           and m.mov_local = p_local and m.mov_terminal = p_terminal
           and m.mov_cierrey = p_cierrey
           and l.vta_tiporeg = v_tipo
           and m.mov_secuencia = l.vta_secuencia
           and m.mov_tipomov = d.mov_tipomov
           and d.mov_tipomov = 'AL'
         group by d.mov_tipomov
        union
        -- TB
        select nvl(sum(m.mov_monto), 0), d.mov_tipomov
          from VTA_FACOMOVDET m, VTA_FACOCONCEPDIF d
         where m.mov_fecha = p_fecha and m.mov_numero = m.mov_terminal
           and m.mov_local = p_local and m.mov_terminal = p_terminal
           and m.mov_cierrey = p_cierrey
           and m.mov_tipomov = d.mov_tipomov
           and d.mov_tipomov = 'TB'
         group by d.mov_tipomov
      ) c;

    o_dif_caja   := (v_prsefe - v_totefe) + (v_prschd - v_totchd) + v_totdol
                  + (v_teschf - v_totchf) + (v_testarj - v_tottarj);
    o_compensado := v_comp;
    -- El exe redondea el compensado ANTES de restarlo (Form3Y.FormateaDatos):
    --   VG_ValorCompensado = Format(ValorCompensacion, gFormat)
    --   Label70 = Format(sumaBZ - VG_ValorCompensado, gFormat)
    -- gFormat de FACO = vta_parametros.vta_numformat '#,#0' (0 decimales).
    o_dif_real   := round(o_dif_caja - round(v_comp, fn_dec), fn_dec);
  end pr_cuadratura;

  -- Diferencia Real (Label70) = round(sumaBZ - round(compensado))
  function fn_dif_real (p_fecha    in date,
                        p_local    in number,
                        p_terminal in number,
                        p_cierrey  in number) return number is
    v_caja number; v_comp number; v_dr number;
  begin
    pr_cuadratura(p_fecha, p_local, p_terminal, p_cierrey, v_caja, v_comp, v_dr);
    return v_dr;
  end fn_dif_real;

  -- Columna "Dif. de Caja" de Form43 (FACO)
  function fn_dif_caja (p_fecha    in date,
                        p_local    in number,
                        p_terminal in number,
                        p_cierrey  in number) return number is
    v_caja number; v_comp number; v_dr number;
  begin
    pr_cuadratura(p_fecha, p_local, p_terminal, p_cierrey, v_caja, v_comp, v_dr);
    return v_caja;
  end fn_dif_caja;

  -- Columna "Compensacion" de Form43 (FACO)
  function fn_compensado (p_fecha    in date,
                          p_local    in number,
                          p_terminal in number,
                          p_cierrey  in number) return number is
    v_caja number; v_comp number; v_dr number;
  begin
    pr_cuadratura(p_fecha, p_local, p_terminal, p_cierrey, v_caja, v_comp, v_dr);
    return v_comp;
  end fn_compensado;

  -- ---------------------------------------------------------------
  -- RY-01 Cheque a fecha: gestion de cheques (tipo 1) = tesoreria
  -- (dia completo, sin filtro de Y, igual que el exe)
  -- ---------------------------------------------------------------
  function fn_msg_cheque_fecha (p_fecha in date, p_local in number, p_terminal in number) return varchar2 is
    v_gestion number;
    v_tesor   number;
  begin
    select nvl(sum(c.chq_monto), 0)
      into v_gestion
      from VTA_FACOCHEQUES c
     where c.chq_fecha = p_fecha and c.chq_local = p_local
       and c.chq_terminal = p_terminal and c.chq_tipocheque = 1;

    select nvl(sum(t.tes_chefecha), 0)
      into v_tesor
      from VTA_FACOTESOR t
     where t.tes_fecha = p_fecha and t.tes_local = p_local and t.tes_terminal = p_terminal;

    if round(v_gestion, fn_dec) <> round(v_tesor, fn_dec) then
      return 'Existe diferencia para el concepto cheques a Fecha entre la Gestion de Cheque : ( '
             || v_gestion || ' ) versus columna tesoreria : ( ' || v_tesor || ' ) , para poder cerrar Y.';
    end if;
    return null;
  end fn_msg_cheque_fecha;

  -- ---------------------------------------------------------------
  -- RY-03 Concepto declarado sin regularizar (FuncvalidarConcepto)
  -- ---------------------------------------------------------------
  function fn_concepto_pendiente (p_fecha in date, p_local in number, p_terminal in number,
                                  p_cierrey in number, p_tipo in varchar2) return boolean is
    v_cnt number;
  begin
    if p_tipo = 'CA' then
      select count(*) into v_cnt
        from VTA_FACOCARTAAVISO m
       where m.mov_fecha = p_fecha and m.mov_local = p_local and m.mov_terminal = p_terminal
         and (m.mov_regul is null or m.mov_regul in (' ', 'N'))
         and m.mov_tipomov = p_tipo
         and m.mov_cierrey = p_cierrey;
    else
      select count(*) into v_cnt
        from VTA_FACOMOVDET m
       where m.mov_fecha = p_fecha and m.mov_local = p_local and m.mov_terminal = p_terminal
         and (m.mov_regul is null or m.mov_regul in (' ', 'N'))
         and m.mov_tipomov = p_tipo
         and m.mov_cierrey = p_cierrey;
    end if;
    return v_cnt > 0;
  end fn_concepto_pendiente;

  -- ---------------------------------------------------------------
  -- RY-06 Formula ZZZ de la Y (FuncValidaZZZ + FuncMontoValidaZZZYY)
  -- Verificado en test (06-10-2026): VTA_PAINT_Z.vta_signo es CHAR(1) y vale
  -- '+' en todas las filas FACO; los campos de vta_cmp_asoc existen en una
  -- sola de VTA_FACOLIBVTA / VTA_FACOZZZ, por lo que van sin prefijo.
  -- Grupos FACO: 1 ventas (boletas, NC, facturas), 2 abono/avance CMR,
  -- reversa recaudacion, pago facturas, 3 recaudacion, 6 gift card,
  -- 7 formas de pago.
  -- Diferencia = F7 - F6 - F5 - F4 - F3 - F2 - F1, con F(k) armada desde
  -- VTA_PAINT_Z.vta_validadorzzz = k. Corrige el bug del exe (Form3Y pasaba
  -- el local en vez del numero de Y): aqui se usa la Y real.
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
                 where z.vta_localiz = 'FACO'
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
                 ' from VTA_FACOLIBVTA l, VTA_FACOZZZ r' ||
                 ' where l.vta_fecha_venta = :f and l.vta_local = :lo and l.vta_terminal = :te' ||
                 ' and l.vta_estado = ''A'' and l.vta_techkey = r.rec_techkey';
        v_sql := v_sql || ' and l.vta_tiporeg = ''Y'' and l.vta_secuencia = :y';
        execute immediate v_sql into v_f(k) using p_fecha, p_local, p_terminal, p_cierrey;
        v_f(k) := nvl(v_f(k), 0);
      end if;
    end loop;
    return round(v_f(7) - v_f(6) - v_f(5) - v_f(4) - v_f(3) - v_f(2) - v_f(1), fn_dec);
  end fn_zzz;

  -- ---------------------------------------------------------------
  -- Validaciones Y (orden de Form3Y.CierraTerminal; estado y DR se
  -- evaluan antes en el proceso, segun el diagrama del Proceso 2)
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
    if fn_param('CA_VAL_CHEQ', 'S') = 'S' then
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

    -- RY-06 formula ZZZ (opcion 103 del exe, aqui flag)
    if fn_param('CA_VAL_ZZZ', 'N') = 'S' then
      v_zzz := fn_zzz(p_fecha, p_local, p_terminal, p_cierrey);
      if v_zzz <> 0 then
        o_regla := 'RY-06';
        o_mensaje := 'Error, Y descuadrada, favor revisar... diferencia : ' || v_zzz;
        return;
      end if;
    end if;
  end pr_valida_y;

  -- ---------------------------------------------------------------
  -- Marca las filas pendientes de la cola para una caja
  -- ---------------------------------------------------------------
  procedure pr_marca_cola (p_fecha in date, p_local in number, p_terminal in number,
                           p_cierrey in number, p_estado in varchar2,
                           p_resultado in varchar2, p_mensaje in varchar2) is
  begin
    update VTA_FACOPRD_CIERRE q
       set q.pcr_estado    = p_estado,
           q.pcr_resultado = p_resultado,
           q.pcr_mensaje   = substr(p_mensaje, 1, 1000),
           q.pcr_fechaproc = sysdate,
           q.pcr_ejecucion = g_ejecucion,
           q.pcr_intentos  = q.pcr_intentos + 1
     where q.pcr_estado   = 'P'
       and q.prv_fechavta = p_fecha
       and q.prv_local    = p_local
       and q.prv_terminal = p_terminal
       and q.prv_cierrey  = p_cierrey;
  end pr_marca_cola;

  function fn_nota (p_nota_actual in varchar2) return varchar2 is
  begin
    -- CK: FSCC-12901 - la nota distingue el cierre desde Consultas de Cuadratura
    return substr(case when g_proceso = 'CC' then 'CIERRE CC FSCC-12901 ' else 'CIERRE AUTOMATICO FSCC-12958 ' end
                  || to_char(sysdate, 'dd-mm-yyyy hh24:mi')
                  || case when p_nota_actual is not null then ' | ' || p_nota_actual end, 1, 2500);
  end fn_nota;

  -- ---------------------------------------------------------------
  -- Proceso de una Y (Proceso 2 del diagrama). o_resultado = log_resultado
  -- (CERRADA_Y, YA_CERRADA, CON_DIFERENCIA, BLOQUEADA, SIN_LIBVTA, OCUPADA, ...)
  -- ---------------------------------------------------------------
  procedure pr_procesa_y (p_fecha in date, p_local in number, p_terminal in number, p_cierrey in number,
                          o_resultado out varchar2) is
    v_estado  number;
    v_notas   varchar2(2500);
    v_nota    varchar2(2500);   -- nota nueva (fn_nota es privada: no se puede usar dentro del UPDATE, PLS-00231)
    v_dr      number;
    v_regla   varchar2(10);
    v_msg     varchar2(1000);
  begin
    savepoint sp_y;

    begin
      select t.ter_estado, t.ter_notas
        into v_estado, v_notas
        from VTA_FACOTERMSTATY t
       where t.ter_fecha = p_fecha and t.ter_local = p_local
         and t.ter_terminal = p_terminal and t.ter_cierrey = p_cierrey
         for update nowait;
    exception
      when no_data_found then
        pr_marca_cola(p_fecha, p_local, p_terminal, p_cierrey, 'P', 'SIN_TERMSTAT', 'No existe el cierre Y en VTA_FACOTERMSTATY');
        commit;
        o_resultado := 'SIN_TERMSTAT';
        pr_log('Y', p_fecha, p_local, p_terminal, p_cierrey, null, 'SIN_TERMSTAT', 'RY-02', 'No existe el cierre Y en VTA_FACOTERMSTATY');
        return;
      when e_ocupada then
        pr_marca_cola(p_fecha, p_local, p_terminal, p_cierrey, 'P', 'OCUPADA', 'Caja bloqueada por otro usuario');
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
    v_dr := fn_dif_real(p_fecha, p_local, p_terminal, p_cierrey);
    if v_dr is null then
      rollback to sp_y;
      pr_marca_cola(p_fecha, p_local, p_terminal, p_cierrey, 'P', 'SIN_LIBVTA', 'No hay Z disponible (sin libro de ventas de la Y)');
      commit;
      o_resultado := 'SIN_LIBVTA';
      pr_log('Y', p_fecha, p_local, p_terminal, p_cierrey, null, 'SIN_LIBVTA', null, 'No hay Z disponible (sin libro de ventas de la Y)');
      return;
    elsif v_dr <> 0 then
      rollback to sp_y;
      pr_marca_cola(p_fecha, p_local, p_terminal, p_cierrey, 'P', 'CON_DIFERENCIA', 'Falta Monto por Compensar');
      commit;
      o_resultado := 'CON_DIFERENCIA';
      pr_log('Y', p_fecha, p_local, p_terminal, p_cierrey, v_dr, 'CON_DIFERENCIA', 'RY-05', 'Falta Monto por Compensar');
      return;
    end if;

    -- Validaciones de Cerrar Terminal
    pr_valida_y(p_fecha, p_local, p_terminal, p_cierrey, v_regla, v_msg);
    if v_regla is not null then
      rollback to sp_y;
      pr_marca_cola(p_fecha, p_local, p_terminal, p_cierrey, 'P', 'BLOQUEADA', v_regla || ' ' || v_msg);
      commit;
      o_resultado := 'BLOQUEADA';
      pr_log('Y', p_fecha, p_local, p_terminal, p_cierrey, v_dr, 'BLOQUEADA', v_regla, v_msg);
      return;
    end if;

    -- Cerrar el cierre Y: estado cerrado, usuario de proceso, fecha y nota.
    -- La nota se arma en PL/SQL antes del UPDATE: una funcion privada del
    -- paquete no puede llamarse desde SQL (PLS-00231, corregido 07-10-2026).
    v_nota := fn_nota(v_notas);
    update VTA_FACOTERMSTATY t
       set t.ter_estado     = 1,
           t.ter_cerradopor = g_usuario,
           t.ter_notas      = v_nota
     where t.ter_fecha = p_fecha and t.ter_local = p_local
       and t.ter_terminal = p_terminal and t.ter_cierrey = p_cierrey;

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
      pr_marca_cola(p_fecha, p_local, p_terminal, p_cierrey, 'P', 'ERROR', v_msg);
      commit;
      o_resultado := 'ERROR';
      pr_log('Y', p_fecha, p_local, p_terminal, p_cierrey, null, 'ERROR', null, v_msg);
  end pr_procesa_y;

  -- ---------------------------------------------------------------
  -- Punto de entrada del proceso automatico (T1 -> T2). Solo cierres Y.
  -- ---------------------------------------------------------------
  procedure prc_cierre_automatico (p_usuario   in varchar2 default 'PROC_CIERRE_AUTO',
                                   p_max_cajas in number   default null) is
    v_dias  number;
    v_n     number := 0;
    v_cerr  number := 0;
    v_nocer number := 0;
    v_res   varchar2(30);
  begin
    g_proceso := 'T2';   -- el estado del paquete persiste en la sesion
    g_usuario := nvl(substr(p_usuario, 1, 50), c_usuario_def);
    g_dec     := to_number(fn_param('CA_DECIMAL', '0'));
    v_dias    := to_number(fn_param('CA_DIAS', '30'));
    select SEQ_VTA_FACOLOG_CIERRE_AUTO.nextval into g_ejecucion from dual;

    -- Interruptores independientes: CA_DI_ACTIVO (T1) y CA_ACTIVO (T2).
    -- Si ambos estan apagados no se hace nada.
    if fn_param('CA_ACTIVO', 'N') <> 'S' and fn_param('CA_DI_ACTIVO', 'N') <> 'S' then
      pr_log('-', null, null, null, null, null, 'INACTIVO', null, 'Parametros 1502 CA_ACTIVO y CA_DI_ACTIVO distintos de S');
      return;
    end if;
    pr_log('-', null, null, null, null, null, 'INICIO', null, 'Usuario ' || g_usuario);

    -- Sobres sin cierre Y: no se pueden asociar a una caja.
    -- PRV_CIERREY es NUMBER(2) NOT NULL DEFAULT 0 en VTA_FACOPRD: 0 = sin Y.
    update VTA_FACOPRD_CIERRE q
       set q.pcr_estado = 'O', q.pcr_resultado = 'SIN_CIERREY',
           q.pcr_mensaje = 'Sobre sin numero de cierre Y', q.pcr_fechaproc = sysdate,
           q.pcr_ejecucion = g_ejecucion
     where q.pcr_estado = 'P' and nvl(q.prv_cierrey, 0) = 0;

    -- Pendientes mas antiguas que CA_DIAS: se dejan de reevaluar
    update VTA_FACOPRD_CIERRE q
       set q.pcr_estado = 'V', q.pcr_resultado = 'VENCIDA', q.pcr_fechaproc = sysdate,
           q.pcr_ejecucion = g_ejecucion
     where q.pcr_estado = 'P' and q.prv_fechavta < trunc(sysdate) - v_dias;
    commit;

    -- T1 (FSCC-12957): compensacion automatica de DI sobre las mismas cajas
    -- (VTA_FACOV_CAJAS_CIERRE), ANTES del cierre (diagrama general: T1 -> T2).
    -- T1 revisa su propio interruptor (CA_DI_ACTIVO) y registra en el mismo
    -- log con log_proceso = 'T1'. Un error en T1 no impide ejecutar T2.
    begin
      PKG_F8_FACO_COMPENSA_DI.prc_compensa_di(p_ejecucion => g_ejecucion,
                                              p_max_cajas => p_max_cajas);
    exception
      when others then
        pr_log('-', null, null, null, null, null, 'ERROR', null,
               'Fallo T1 (PKG_F8_FACO_COMPENSA_DI): ' || substr(sqlerrm, 1, 900));
    end;

    -- T2 apagado: solo corrio T1
    if fn_param('CA_ACTIVO', 'N') <> 'S' then
      pr_log('-', null, null, null, null, null, 'INACTIVO', null, 'Parametro 1502 CA_ACTIVO distinto de S: solo se ejecuto T1');
      return;
    end if;

    -- Cierres Y del universo (cola pendiente + cajas sin sobres del mismo
    -- local-dia; incluye las que ya tenian DR 0 y las compensadas por T1).
    -- CK: FSCC-12901 - antes recorria VTA_FACOPRD_CIERRE directamente.
    for c in (select v.cc_fecha f, v.cc_local l, v.cc_terminal t, v.cc_cierrey y
                from VTA_FACOV_CAJAS_CIERRE v
               where v.cc_fecha >= trunc(sysdate) - v_dias
               order by 1, 2, 3, 4) loop
      exit when p_max_cajas is not null and v_n >= p_max_cajas;
      v_n := v_n + 1;
      pr_procesa_y(c.f, c.l, c.t, c.y, v_res);
      if v_res = 'CERRADA_Y' then
        v_cerr := v_cerr + 1;
      elsif v_res <> 'YA_CERRADA' then
        v_nocer := v_nocer + 1;
      end if;
    end loop;

    -- FACO opera solo con cierre Y (07-10-2026): la Z (VTA_FACOTERMSTAT) no se toca.

    pr_log('-', null, null, null, null, null, 'FIN', null,
           'Cierres Y evaluados: ' || v_n || ' | Y cerradas: ' || v_cerr
           || ' | Y no cerradas: ' || v_nocer);
  exception
    when others then
      rollback;
      pr_log('-', null, null, null, null, null, 'ERROR', null, sqlerrm);
      raise;
  end prc_cierre_automatico;

  -- ---------------------------------------------------------------
  -- CK: FSCC-12901 - Punto de entrada de Consultas de Cuadratura (Form43,
  -- boton "Cerrar Terminal", FACO). DF-SCC fila 12: cerrar desde CC las cajas
  -- con Diferencia Real 0, incluidas las cajas sin movimiento, y evitar el
  -- archivo "dataload" de cierre de cajas. Solo cierres Y (07-10-2026).
  -- ---------------------------------------------------------------
  procedure prc_cierre_rango (p_fecha_ini   in  varchar2,
                              p_fecha_fin   in  varchar2,
                              p_local       in  number,
                              p_terminal    in  number,
                              p_usuario     in  varchar2,
                              o_ejecucion   out number,
                              o_cerradas    out number,
                              o_no_cerradas out number) is
    v_ini   date;
    v_fin   date;
    v_res   varchar2(30);
    v_n     number := 0;
  begin
    o_cerradas    := 0;
    o_no_cerradas := 0;
    g_proceso := 'CC';
    g_usuario := nvl(substr(trim(p_usuario), 1, 50), c_usuario_def);
    g_dec     := to_number(fn_param('CA_DECIMAL', '0'));
    select SEQ_VTA_FACOLOG_CIERRE_AUTO.nextval into g_ejecucion from dual;
    o_ejecucion := g_ejecucion;
    v_ini := to_date(p_fecha_ini, 'yyyymmdd');
    v_fin := to_date(p_fecha_fin, 'yyyymmdd');

    pr_log('-', null, p_local, nullif(p_terminal, 0), null, null, 'INICIO', null,
           'Consultas de Cuadratura ' || p_fecha_ini || '-' || p_fecha_fin || ' usuario ' || g_usuario);

    -- 1. Cierres Y abiertos con libro de ventas (mismo universo que Form43)
    for c in (select distinct t.ter_fecha f, t.ter_local l, t.ter_terminal te, t.ter_cierrey y
                from VTA_FACOTERMSTATY t, VTA_FACOLIBVTA l, VTA_FACOZZZ r
               where t.ter_fecha between v_ini and v_fin
                 and t.ter_local = p_local
                 and (nvl(p_terminal, 0) = 0 or t.ter_terminal = p_terminal)
                 and t.ter_estado <= 0
                 and l.vta_tiporeg = 'Y'
                 and l.vta_estado = 'A'
                 and l.vta_techkey = r.rec_techkey
                 and l.vta_fecha_venta = t.ter_fecha
                 and l.vta_local = t.ter_local
                 and l.vta_terminal = t.ter_terminal
                 and l.vta_secuencia = t.ter_cierrey
               order by 1, 2, 3, 4) loop
      v_n := v_n + 1;
      pr_procesa_y(c.f, c.l, c.te, c.y, v_res);
      if v_res = 'CERRADA_Y' then
        o_cerradas := o_cerradas + 1;
      elsif v_res <> 'YA_CERRADA' then
        o_no_cerradas := o_no_cerradas + 1;
      end if;
    end loop;

    -- FACO opera solo con cierre Y (07-10-2026): la Z (VTA_FACOTERMSTAT) no se toca.

    pr_log('-', null, p_local, nullif(p_terminal, 0), null, null, 'FIN', null,
           'Cierres Y evaluados: ' || v_n || ' | Y cerradas: ' || o_cerradas
           || ' | Y no cerradas: ' || o_no_cerradas);
    g_proceso := 'T2';
  exception
    when others then
      rollback;
      pr_log('-', null, p_local, nullif(p_terminal, 0), null, null, 'ERROR', null, sqlerrm);
      g_proceso := 'T2';
      raise;
  end prc_cierre_rango;

end PKG_F8_FACO_CIERRE_AUTO;
/
