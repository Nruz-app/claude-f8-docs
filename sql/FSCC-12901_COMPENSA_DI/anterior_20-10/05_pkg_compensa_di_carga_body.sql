-- =====================================================================
-- FSCC-12901 COMPENSA_DI - Paso 05
-- Cuerpo de PKG_F8_COMPENSA_DI_CARGA   (Oracle 10.2, solo FACO)
-- xintec-nruz 19-10-2026
--
-- Fuentes:
--   * pr_cuadratura: PKG_F8_CIERRE_AUTO.pr_cuadratura
--     (docs/sql/FSCC-12901_PROC_Y/07_pkg_cierre_auto_body.sql:354) con
--     {P} = FACO, {NIVEL} = Y, tarjetas 2000-2999, dolar 305. Mismas
--     consultas; aqui en SQL estatico.
--   * pr_registra_di: PKG_F8_COMPENSA_DI_AUTO.pr_registra_di
--     (docs/sql/FSCC-12901_PROC_Y/06_pkg_compensa_di_body.sql) con la glosa nueva.
-- Referencias al exe VB6 (FTEPROD/):
--   Form3Y.FormateaDatos :2704 (DR = sumaBZ - compensado redondeado)
--   Modulo1.StrSumCompensado :2630   Modulo1.InsertarRegistroMovDet :3777
--   Form38 (DI manual)   Form45.GrabarObs (observacion en VTA_FACOCOMPDES)
-- =====================================================================

create or replace package body PKG_F8_COMPENSA_DI_CARGA as

  c_tipo_param constant number       := 1502;
  c_glosa_ant  constant varchar2(60) := 'COMPENSACION AUTOMATICA DE DI';  -- glosa del 19-10 (ya grabada en test); xintec-nruz 20-10-2026

  e_ocupada exception;
  pragma exception_init(e_ocupada, -54);   -- ORA-00054 resource busy (NOWAIT)

  -- ---------------------------------------------------------------
  -- Parametros VTA_FACOPARAM tipo 1502
  -- ---------------------------------------------------------------
  function fn_param (p_codigo in varchar2, p_default in varchar2) return varchar2 is
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
    insert into VTA_FACOLOG_COMPENSA_DI
      (log_id, log_fecha_vta, log_local, log_terminal, log_cierrey, log_sobres,
       log_dif_real, log_di_anterior, log_monto_di, log_resultado, log_mensaje,
       log_usuario, log_fechahora)
    values
      (SEQ_VTA_FACOLOG_COMPENSA_DI.nextval, p_fecha, p_local, p_terminal, nvl(p_cierrey, 0),
       p_sobres, p_dif_real, p_di_anterior, p_monto_di, p_resultado,
       substr(p_mensaje, 1, 1000), substr(p_usuario, 1, 50), sysdate);
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
    v_monto number;
  begin
    select nvl(sum(m.mov_monto), 0)
      into v_monto
      from VTA_FACOMOVDET m
     where m.mov_fecha    = p_fecha
       and m.mov_local    = p_local
       and m.mov_terminal = p_terminal
       and m.mov_cierrey  = p_cierrey
       and m.mov_tipomov  = 'DI'
       and m.mov_hechopor = c_usuario
       and m.mov_regul    = 'S'
       and m.mov_fechareg is not null;
    return v_monto;
  end fn_di_auto;

  -- DI registradas por un usuario (Form38) en la Y
  function fn_di_manual (p_fecha in date, p_local in number, p_terminal in number,
                         p_cierrey in number) return number is
    v_n number;
  begin
    select count(*)
      into v_n
      from VTA_FACOMOVDET m
     where m.mov_fecha    = p_fecha
       and m.mov_local    = p_local
       and m.mov_terminal = p_terminal
       and m.mov_cierrey  = p_cierrey
       and m.mov_tipomov  = 'DI'
       and nvl(m.mov_hechopor, '-') <> c_usuario;
    return v_n;
  end fn_di_manual;

  -- ---------------------------------------------------------------
  -- Cuadratura de la Y (Form3Y.FormateaDatos):
  --   o_sobres     = sobres F8 de la Y (EFE + CHE)
  --   o_dif_caja   = sumaBZ (Dif. de Caja)
  --   o_compensado = Compensacion (StrSumCompensado, Gopcion = "T")
  --   o_dif_real   = round(sumaBZ - round(compensado))  (Label70)
  -- sumaBZ = (prsefe-totefe)+(prschd-totchd)+totDol+(teschf-totchf)+(tesTarjeta-totTarjeta)
  -- Sin libro de ventas de la Y las salidas de cuadratura quedan en NULL.
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
    v_cnt     number;
    v_totefe  number; v_totchd number; v_totchf number; v_tottarj number;
    v_prsefe  number; v_prschd number;
    v_teschf  number; v_testarj number; v_totdol number;
    v_comp    number;
  begin
    o_dif_caja := null; o_compensado := null; o_dif_real := null;

    -- Sobres de la transportadora (LeeProsegur): tiporec F8, EFE / CHE
    select nvl(sum(case when p.prv_tiposobre = 'EFE' then nvl(p.prv_montosobre,0) + nvl(p.prv_montodif,0) end), 0),
           nvl(sum(case when p.prv_tiposobre = 'CHE' then nvl(p.prv_montosobre,0) + nvl(p.prv_montodif,0) end), 0)
      into v_prsefe, v_prschd
      from VTA_FACOPRD p
     where p.prv_fechavta = p_fecha
       and p.prv_local    = p_local
       and p.prv_terminal = p_terminal
       and p.prv_tiporec  = 'F8'
       and p.prv_cierrey  = p_cierrey;
    o_sobres := v_prsefe + v_prschd;

    -- Declarado en la Y (LeeZ + ARMA_QUERY_Z)
    select count(*),
           nvl(sum(r.rec_mefectivo), 0),
           nvl(sum(r.rec_mchkdia), 0),
           nvl(sum(r.rec_mchkfecha), 0),
           nvl(sum(r.rec_mtarj), 0) + nvl(sum(r.rec_msodimac), 0)
      into v_cnt, v_totefe, v_totchd, v_totchf, v_tottarj
      from VTA_FACOLIBVTA l, VTA_FACOZZZ r
     where l.vta_tiporeg     = 'Y'
       and l.vta_fecha_venta = p_fecha
       and l.vta_local       = p_local
       and l.vta_terminal    = p_terminal
       and l.vta_estado      = 'A'
       and l.vta_techkey     = r.rec_techkey
       and l.vta_secuencia   = p_cierrey;

    if nvl(v_cnt, 0) = 0 then
      return;   -- sin libro de ventas: el exe muestra "No hay Z disponible"
    end if;

    -- Cheque a fecha en tesoreria (LeeTes)
    select nvl(sum(t.tes_chefecha), 0)
      into v_teschf
      from VTA_FACOTESOR t
     where t.tes_fecha    = p_fecha
       and t.tes_local    = p_local
       and t.tes_terminal = p_terminal
       and t.tes_cierrey  = p_cierrey;

    -- Tarjetas recaudadas (FuncLeeTarjeta CTARJ, rango FACO 2000-2999)
    select nvl(sum(t.vta_monto_inf), 0)
      into v_testarj
      from VTA_FACOTARJ t
     where t.vta_fecha    = p_fecha
       and t.vta_local    = p_local
       and t.vta_terminal = p_terminal
       and t.vta_cod_tarj between 2000 and 2999
       and t.vta_cierrey  = p_cierrey;

    -- Dolares recaudados (FunConsRecMon 305). FACO: totDol = tesDol
    select nvl(sum(x.mex_monto), 0)
      into v_totdol
      from VTA_FACORECMEX x
     where x.mex_fecha    = p_fecha
       and x.mex_local    = p_local
       and x.mex_terminal = p_terminal
       and x.id_mdareg    = 305
       and x.mex_cierrey  = p_cierrey;

    -- Compensado (Modulo1.StrSumCompensado, Gopcion = "T").
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
        -- Conceptos regularizados (incluye CA y DI)
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
        -- AL (cruce con libro de ventas de la Y)
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
           and l.vta_tiporeg = 'Y'
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
    -- El exe redondea el compensado ANTES de restarlo (Form3Y.FormateaDatos)
    o_dif_real   := round(o_dif_caja - round(v_comp, v_dec), v_dec);
  end pr_cuadratura;

  -- ---------------------------------------------------------------
  -- Funciones publicas de solo lectura
  -- ---------------------------------------------------------------
  function fn_dif_real (p_fecha    in date,
                        p_local    in number,
                        p_terminal in number,
                        p_cierrey  in number) return number is
    v_sob number; v_caja number; v_comp number; v_dr number;
  begin
    pr_cuadratura(p_fecha, p_local, p_terminal, p_cierrey, v_sob, v_caja, v_comp, v_dr);
    return v_dr;
  end fn_dif_real;

  function fn_dif_real_sin_di (p_fecha    in date,
                               p_local    in number,
                               p_terminal in number,
                               p_cierrey  in number) return number is
    v_sob number; v_caja number; v_comp number; v_dr number;
  begin
    pr_cuadratura(p_fecha, p_local, p_terminal, p_cierrey, v_sob, v_caja, v_comp, v_dr);
    if v_dr is null then
      return null;
    end if;
    -- la DI automatica es parte del compensado: se descuenta
    return round(v_caja - round(v_comp - fn_di_auto(p_fecha, p_local, p_terminal, p_cierrey),
                                fn_num('CA_DECIMAL', 0)),
                 fn_num('CA_DECIMAL', 0));
  end fn_dif_real_sin_di;

  function fn_evalua (p_fecha    in date,
                      p_local    in number,
                      p_terminal in number,
                      p_cierrey  in number) return varchar2 is
    v_estado number;
    v_dr     number;
  begin
    if fn_param('CA_DI_ACTIVO', 'N') <> 'S' then
      return 'INACTIVO';
    elsif nvl(p_cierrey, 0) = 0 then
      return 'SIN_Y';
    end if;

    begin
      select t.ter_estado
        into v_estado
        from VTA_FACOTERMSTATY t
       where t.ter_fecha = p_fecha and t.ter_local = p_local
         and t.ter_terminal = p_terminal and t.ter_cierrey = p_cierrey;
    exception
      when no_data_found then
        return 'SIN_TERMSTAT';
    end;
    if v_estado > 0 then
      return 'YA_CERRADA';
    elsif fn_di_manual(p_fecha, p_local, p_terminal, p_cierrey) > 0 then
      return 'DI_MANUAL_PREVIA';
    end if;

    v_dr := fn_dif_real_sin_di(p_fecha, p_local, p_terminal, p_cierrey);
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
    v_monto number;
  begin
    select nvl(sum(m.mov_monto), 0)
      into v_monto
      from VTA_FACOMOVDET m
     where m.mov_fecha    = p_fecha
       and m.mov_local    = p_local
       and m.mov_terminal = p_terminal
       and m.mov_cierrey  = p_cierrey
       and m.mov_tipomov  = 'DI'
       and m.mov_hechopor = c_usuario;

    delete from VTA_FACOMOVDET m
     where m.mov_fecha    = p_fecha
       and m.mov_local    = p_local
       and m.mov_terminal = p_terminal
       and m.mov_cierrey  = p_cierrey
       and m.mov_tipomov  = 'DI'
       and m.mov_hechopor = c_usuario;

    -- Solo la observacion automatica (actual o la del 19-10; la v2 ya usaba la actual)
    delete from VTA_FACOCOMPDES c
     where c.cpd_fecha    = p_fecha
       and c.cpd_local    = p_local
       and c.cpd_terminal = p_terminal
       and c.cpd_cierrey  = p_cierrey
       and c.cpd_tipmov   = 'DI'
       and c.cpd_obs in (c_glosa, c_glosa_ant);

    return v_monto;
  end fn_borra_di_auto;

  -- ---------------------------------------------------------------
  -- Registro de la DI (replica InsertarRegistroMovDet + Form45.GrabarObs)
  -- ---------------------------------------------------------------
  procedure pr_registra_di (p_fecha in date, p_local in number, p_terminal in number,
                            p_cierrey in number, p_monto in number) is
  begin
    -- Modulo1.InsertarRegistroMovDet: mov_rol 0, mov_nombre ' ', mov_secuencia 0,
    -- mov_numero 0, monto redondeado a 2, MOV_REGUL 'S' (regularizada: se ve
    -- en Compensado), MOV_FECHAREG = fecha de venta, techkey SEQ_VTA_FACOVEN.
    insert into VTA_FACOMOVDET
      (mov_fecha, mov_local, mov_terminal, mov_tipomov, mov_rol, mov_nombre,
       mov_secuencia, mov_numero, mov_monto, mov_hechopor, mov_regul,
       mov_fechareg, mov_techkey, mov_cierrey)
    values
      (p_fecha, p_local, p_terminal, 'DI', 0, ' ',
       0, 0, round(p_monto, 2), c_usuario, 'S',
       p_fecha, SEQ_VTA_FACOVEN.nextval, p_cierrey);

    -- Observacion (Form45: una por caja / concepto / Y)
    update VTA_FACOCOMPDES c
       set c.cpd_obs = c_glosa
     where c.cpd_fecha    = p_fecha
       and c.cpd_local    = p_local
       and c.cpd_terminal = p_terminal
       and c.cpd_tipmov   = 'DI'
       and c.cpd_cierrey  = p_cierrey;

    if sql%rowcount = 0 then
      -- cpd_secuencia la asigna el trigger TRG_VTA_FACOCOMPDES_I_SEQ
      insert into VTA_FACOCOMPDES
        (cpd_fecha, cpd_local, cpd_terminal, cpd_tipmov, cpd_obs, cpd_cierrey)
      values
        (p_fecha, p_local, p_terminal, 'DI', c_glosa, p_cierrey);
    end if;
  end pr_registra_di;

  -- ---------------------------------------------------------------
  -- Compensacion automatica de una caja (cierre Y)
  -- ---------------------------------------------------------------
  procedure prc_compensa_caja (p_fecha     in  date,
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
      select t.ter_estado
        into v_estado
        from VTA_FACOTERMSTATY t
       where t.ter_fecha = v_fecha and t.ter_local = p_local
         and t.ter_terminal = p_terminal and t.ter_cierrey = p_cierrey
         for update nowait;
    exception
      when no_data_found then
        o_resultado := 'SIN_TERMSTAT';
        o_mensaje   := 'No existe el cierre Y en VTA_FACOTERMSTATY (ingresar la Y antes de cargar los sobres)';
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
      v_dr := fn_dif_real(v_fecha, p_local, p_terminal, p_cierrey);
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
    v_dr2 := fn_dif_real(v_fecha, p_local, p_terminal, p_cierrey);
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

end PKG_F8_COMPENSA_DI_CARGA;
/
