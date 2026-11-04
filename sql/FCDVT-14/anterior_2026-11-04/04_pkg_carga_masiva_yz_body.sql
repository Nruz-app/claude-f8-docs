-- =====================================================================
-- FCDVT-14 - Paso 04
-- Cuerpo de PKG_F8_CARGA_MASIVA_YZ   (Oracle 10.2)
-- MULTIPAIS (habilitado: FACO)
-- xintec-nruz 30-10-2026 / 03-11-2026 (multipais y estado CARGADO)
-- Version anterior (solo FACO, SQL estatico, la instalada en test el 30-10):
--   anterior_2026-11-03/04_pkg_carga_masiva_yz_body.sql
--
-- Misma logica, mismas validaciones y mismos mensajes que la version
-- anterior. Cambia:
--   * el pais llega por parametro (P_FLG_PAIS = Flg_Pais$ del exe) y
--     PR_CONFIG fija su configuracion desde una LISTA BLANCA (el texto
--     recibido nunca se concatena en el SQL);
--   * el SQL de las tablas del pais se escribe con la marca {P}, que FN_R
--     reemplaza por el prefijo:  VTA_{P}CARGA_YZ_DET -> VTA_FACOCARGA_YZ_DET,
--     SEQ_VTA_{P}CARGA_YZ, VTA_{P}TERMINALES;
--   * lecturas y escrituras con EXECUTE IMMEDIATE ... USING (binds) y
--     cursores dinamicos (OPEN ... FOR ... USING);
--   * el estado final de un grupo correcto es CARGADO (c_estado_ok; antes
--     PROCESADO).
-- Patron tomado de PKG_F8_COMPENSA_DI_CARGA (pr_config / fn_r,
-- docs/sql/FSCC-12901_COMPENSA_DI/05_pkg_compensa_di_carga_body.sql).
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
--     Form19Y.Oklt sobre vta_<pfx>terminales);
--   - NRO_Y repetido dentro del archivo para el mismo terminal-dia.
-- Resumen por fecha / local / terminal (prc_procesa, etapa RESUMEN):
--   ERROR si tiene filas con error, si no tiene exactamente 1 Z, si no tiene
--   Y o si el TOTAL de la Z (BOLETAS + N.CREDITO + FACTURA) es distinto de la
--   suma de los TOTALES de las Y. En otro caso, CARGADO.
-- Fuera de alcance (lo hara Cargar): Z cerrada (Est_TermStat), NRO_Y ya
-- existente en la base y el grabado en libvta / zzz / termstat(y).
--
-- Para habilitar otro pais ver 00_LEEME.md ("Multipais").
-- =====================================================================

create or replace package body PKG_F8_CARGA_MASIVA_YZ as

  c_pais_compat constant varchar2(10) := 'FACO';   -- firmas sin pais (compatibilidad)

  type t_montos is table of number index by pls_integer;
  type t_cur    is ref cursor;

  -- ------------------------------------------------------------------
  -- Configuracion del pais
  -- ------------------------------------------------------------------
  type t_cfg is record (
    pais        varchar2(10),     -- valor de Flg_Pais$ recibido (normalizado)
    prefijo     varchar2(10),     -- prefijo de tablas VTA_<prefijo>... (Chile: vacio)
    encabezado  varchar2(1000),   -- encabezado obligatorio del CSV
    campos      pls_integer       -- numero de campos por linea
  );
  g_cfg t_cfg;

  -- ------------------------------------------------------------------
  -- Paises habilitados. Es la UNICA fuente del prefijo que se concatena
  -- en el SQL dinamico (lista blanca: nunca se usa el texto recibido).
  -- ------------------------------------------------------------------
  procedure pr_config (p_flg_pais in varchar2) is
    v_pais varchar2(10) := upper(trim(p_flg_pais));
    v_cfg  t_cfg;
  begin
    if g_cfg.pais is not null and g_cfg.pais = v_pais then
      return;   -- ya configurado
    end if;

    if v_pais = 'FACO' then
      -- Falabella Colombia: Y + Z por terminal-dia (Form19Y / Form3Y)
      v_cfg.pais       := 'FACO';
      v_cfg.prefijo    := 'FACO';
      v_cfg.encabezado := c_encabezado;
      v_cfg.campos     := c_campos;

    -- -------------------------------------------------------------
    -- EJEMPLO (NO HABILITADO): como se agregaria otro pais, p. ej. Tottus
    -- Chile (Flg_Pais$ = "SFCL") o Falabella Chile (Flg_Pais$ = "CHI",
    -- tablas sin prefijo). Antes de habilitarlo (00_LEEME.md, "Multipais"):
    --   1. crear sus tablas con 02_tablas_carga_yz.sql (v_prefijo);
    --   2. comparar su vta_<pfx>paint_z con el de FACO: si sus conceptos
    --      son otros, definir su encabezado y agregar las columnas que
    --      falten en VTA_<pfx>CARGA_YZ_DET (y el INSERT de prc_inserta_linea);
    --   3. en el exe: abrir Form174 tambien para ese pais (MDIForm1,
    --      INGYMA) y crear su permiso 460 (01_menu_ingreso_masivo_y.sql).
    -- elsif v_pais = 'SFCL' then
    --   v_cfg.pais       := 'SFCL';
    --   v_cfg.prefijo    := 'SFCL';
    --   v_cfg.encabezado := c_encabezado;   -- o el encabezado propio
    --   v_cfg.campos     := c_campos;
    -- elsif v_pais = 'CHI' then
    --   v_cfg.pais       := 'CHI';
    --   v_cfg.prefijo    := null;           -- Chile: VTA_CARGA_YZ_*, VTA_TERMINALES
    --   v_cfg.encabezado := ...;            -- Chile carga solo Z
    --   v_cfg.campos     := ...;
    -- -------------------------------------------------------------
    else
      raise_application_error(-20001,
        'PKG_F8_CARGA_MASIVA_YZ: pais no habilitado (' || nvl(p_flg_pais, '(nulo)') || ')');
    end if;

    g_cfg := v_cfg;
  end pr_config;

  -- Reemplaza la marca {P} con el prefijo del pais configurado
  function fn_r (p_sql in varchar2) return varchar2 is
  begin
    return replace(p_sql, '{P}', g_cfg.prefijo);
  end fn_r;

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
      execute immediate fn_r(
        q'[select max(log_usuario)
             from VTA_{P}CARGA_YZ_LOG
            where log_carga = :1
              and log_etapa = 'INICIO']')
        into v_usuario using p_carga;
    end if;
    execute immediate fn_r(
      q'[insert into VTA_{P}CARGA_YZ_LOG
           (log_id, log_carga, log_linea, log_etapa, log_campo, log_valor,
            log_motivo, log_usuario, log_fechahora)
         values
           (SEQ_VTA_{P}CARGA_YZ_LOG.nextval, :1, :2, :3, :4, :5, :6, :7, sysdate)]')
      using p_carga, p_linea, p_etapa,
            substr(p_campo, 1, 30), substr(p_valor, 1, 200),
            substr(p_motivo, 1, 1000), v_usuario;
    commit;
  end prc_log;

  function fn_usuario (p_carga in number) return varchar2 is
    v_usuario varchar2(50);
  begin
    execute immediate fn_r(
      q'[select max(log_usuario)
           from VTA_{P}CARGA_YZ_LOG
          where log_carga = :1
            and log_etapa = 'INICIO']')
      into v_usuario using p_carga;
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

  -- Nombre de la columna n del encabezado del pais
  function fn_nombre (p_n in pls_integer) return varchar2 is
  begin
    return fn_campo(g_cfg.encabezado, p_n);
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
    pr_config(p_flg_pais);
    execute immediate fn_r('select SEQ_VTA_{P}CARGA_YZ.nextval from dual') into o_carga;
    prc_log(o_carga, null, 'INICIO', null, g_cfg.pais,
            'Archivo: ' || p_archivo, p_usuario);
  end prc_inicia;

  procedure prc_inserta_linea (p_flg_pais in varchar2,
                               p_carga    in number,
                               p_linea    in number,
                               p_texto    in varchar2) is
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
    v_estado  varchar2(10);
    m         t_montos;
  begin
    pr_config(p_flg_pais);

    -- Se tolera un ; final
    if substr(v_txt, -1) = ';' and fn_ncampos(v_txt) = g_cfg.campos + 1 then
      v_txt := substr(v_txt, 1, length(v_txt) - 1);
    end if;

    -- Linea 1: encabezado de la plantilla (vacia tambien es error)
    if p_linea = 1 then
      if nvl(upper(trim(v_txt)), '-') <> upper(g_cfg.encabezado) then
        prc_log(p_carga, p_linea, 'LECTURA', 'ENCABEZADO', substr(v_txt, 1, 200),
                'El encabezado no es el de la plantilla de carga masiva ('
                || g_cfg.campos || ' columnas, ver FORMATO_CARGA_Y_FACO.md)');
      end if;
      return;
    end if;

    -- Lineas vacias (o solo ;) se ignoran
    if trim(replace(v_txt, ';')) is null then
      return;
    end if;

    v_n := fn_ncampos(v_txt);
    if v_n <> g_cfg.campos then
      prc_log(p_carga, p_linea, 'LECTURA', 'LINEA', to_char(v_n),
              'La linea tiene ' || v_n || ' campos; deben ser ' || g_cfg.campos);
      execute immediate fn_r(
        q'[insert into VTA_{P}CARGA_YZ_DET (det_carga, det_linea, det_texto, det_estado)
           values (:1, :2, :3, 'ERROR')]')
        using p_carga, p_linea, substr(p_texto, 1, 4000);
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

    if v_err then
      v_estado := 'ERROR';
    else
      v_estado := 'OK';
    end if;

    execute immediate fn_r(
      q'[insert into VTA_{P}CARGA_YZ_DET
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
           (:1, :2, :3, :4, :5, :6,
            :7, :8, :9, :10, :11,
            :12, :13, :14,
            :15, :16, :17, :18, :19,
            :20, :21, :22, :23, :24,
            :25, :26, :27, :28, :29,
            :30, :31, :32, :33, :34,
            :35, :36, :37, :38, :39,
            :40, :41, :42, :43, :44,
            :45, :46, :47, :48, :49,
            :50, :51, :52, :53, :54,
            :55, :56, :57, :58, :59,
            :60, :61, sysdate)]')
      using p_carga, p_linea, substr(p_texto, 1, 4000), v_fecha, v_local, v_term,
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
            v_total, v_estado;
    commit;
  exception
    when others then
      -- Solo si el pais quedo configurado (si pr_config lo rechazo, no hay tabla de log)
      if g_cfg.pais = upper(trim(p_flg_pais)) then
        prc_log(p_carga, p_linea, 'ERROR', null, null, 'prc_inserta_linea: ' || sqlerrm);
      end if;
      raise;
  end prc_inserta_linea;

  procedure prc_procesa (p_flg_pais     in  varchar2,
                         p_carga        in  number,
                         o_grupos_ok    out number,
                         o_grupos_error out number,
                         o_lin_error    out number) is
    v_usuario  varchar2(50);
    v_n        number;
    v_sin_grp  number;
    v_msg      varchar2(1000);
    v_err      varchar2(1000);
    c          t_cur;
    v_linea    number;
    v_fecha    date;
    v_local    number;
    v_term     number;
    v_nroy     number;
    v_cant_y   number;
    v_total_y  number;
    v_cant_z   number;
    v_total_z  number;
    v_lin_err  number;
  begin
    o_grupos_ok    := 0;
    o_grupos_error := 0;
    o_lin_error    := 0;
    pr_config(p_flg_pais);
    v_usuario      := fn_usuario(p_carga);

    -- Encabezado rechazado: no se procesa nada
    execute immediate fn_r(
      q'[select count(*)
           from VTA_{P}CARGA_YZ_LOG
          where log_carga = :1
            and log_linea = 1
            and log_campo = 'ENCABEZADO']')
      into v_n using p_carga;
    if v_n > 0 then
      prc_log(p_carga, null, 'FIN', null, null,
              'Carga rechazada: el encabezado no es el de la plantilla', v_usuario);
      return;
    end if;

    -- VALIDACION 1: local y terminal vigentes a la fecha (Form19Y.Oklt)
    open c for fn_r(
      q'[select d.det_linea, d.det_fecha, d.det_local, d.det_terminal
           from VTA_{P}CARGA_YZ_DET d
          where d.det_carga = :1
            and d.det_fecha is not null
            and d.det_local is not null
            and d.det_terminal is not null
            and not exists (select 1
                              from VTA_{P}TERMINALES t
                             where t.ter_local    = d.det_local
                               and t.ter_terminal = d.det_terminal
                               and (t.ter_fechabaja >= d.det_fecha
                                    or t.ter_fechabaja is null))]')
      using p_carga;
    loop
      fetch c into v_linea, v_fecha, v_local, v_term;
      exit when c%notfound;
      prc_log(p_carga, v_linea, 'VALIDACION', 'TERMINAL',
              v_local || '-' || v_term,
              'Local / terminal no existe o no esta vigente al '
              || to_char(v_fecha, 'dd-mm-yyyy'), v_usuario);
      execute immediate fn_r(
        q'[update VTA_{P}CARGA_YZ_DET
              set det_estado = 'ERROR'
            where det_carga = :1
              and det_linea = :2]')
        using p_carga, v_linea;
    end loop;
    close c;

    -- VALIDACION 2: NRO_Y repetido en el archivo (mismo terminal-dia)
    open c for fn_r(
      q'[select det_linea, det_nro_y
           from (select d.det_linea, d.det_nro_y,
                        row_number() over (partition by d.det_fecha, d.det_local,
                                                        d.det_terminal, d.det_nro_y
                                               order by d.det_linea) rn
                   from VTA_{P}CARGA_YZ_DET d
                  where d.det_carga = :1
                    and d.det_tipo  = 'Y'
                    and d.det_nro_y is not null
                    and d.det_fecha is not null
                    and d.det_local is not null
                    and d.det_terminal is not null)
          where rn > 1]')
      using p_carga;
    loop
      fetch c into v_linea, v_nroy;
      exit when c%notfound;
      prc_log(p_carga, v_linea, 'VALIDACION', 'NRO_Y', to_char(v_nroy),
              'NRO_Y repetido en el archivo para el mismo terminal y fecha', v_usuario);
      execute immediate fn_r(
        q'[update VTA_{P}CARGA_YZ_DET
              set det_estado = 'ERROR'
            where det_carga = :1
              and det_linea = :2]')
        using p_carga, v_linea;
    end loop;
    close c;
    commit;

    -- RESUMEN: un grupo por fecha / local / terminal, en PENDIENTE
    execute immediate fn_r('delete from VTA_{P}CARGA_YZ_RES where res_carga = :1')
      using p_carga;
    execute immediate fn_r(
      q'[insert into VTA_{P}CARGA_YZ_RES
           (res_carga, res_fecha, res_local, res_terminal,
            res_cant_y, res_total_y, res_cant_z, res_total_z, res_lin_error,
            res_estado, res_mensaje, res_usuario, res_fechahora)
         select :1, d.det_fecha, d.det_local, d.det_terminal,
                sum(case when d.det_tipo = 'Y' then 1 else 0 end),
                sum(case when d.det_tipo = 'Y' then d.det_total end),
                sum(case when d.det_tipo = 'Z' then 1 else 0 end),
                sum(case when d.det_tipo = 'Z' then d.det_total end),
                sum(case when d.det_estado = 'ERROR' then 1 else 0 end),
                'PENDIENTE', null, :2, sysdate
           from VTA_{P}CARGA_YZ_DET d
          where d.det_carga = :3
            and d.det_fecha is not null
            and d.det_local is not null
            and d.det_terminal is not null
          group by d.det_fecha, d.det_local, d.det_terminal]')
      using p_carga, v_usuario, p_carga;
    commit;   -- si lo que sigue falla, los grupos quedan PENDIENTE

    -- Estado de cada grupo
    open c for fn_r(
      q'[select res_fecha, res_local, res_terminal, res_cant_y, res_total_y,
                res_cant_z, res_total_z, res_lin_error
           from VTA_{P}CARGA_YZ_RES
          where res_carga = :1]')
      using p_carga;
    loop
      fetch c into v_fecha, v_local, v_term, v_cant_y, v_total_y,
                   v_cant_z, v_total_z, v_lin_err;
      exit when c%notfound;
      v_msg := null;
      if v_lin_err > 0 then
        v_msg := v_msg || v_lin_err || ' fila(s) con error (ver log). ';
      end if;
      if v_cant_z = 0 then
        v_msg := v_msg || 'Sin fila Z. ';
      elsif v_cant_z > 1 then
        v_msg := v_msg || 'Tiene ' || v_cant_z || ' filas Z; debe ser 1. ';
      end if;
      if v_cant_y = 0 then
        v_msg := v_msg || 'Sin filas Y. ';
      end if;
      if v_cant_z = 1 and v_cant_y > 0
         and v_lin_err = 0
         and (v_total_z is null or v_total_y is null
              or v_total_z <> v_total_y) then
        v_msg := v_msg || 'Total Z (' || v_total_z || ') distinto de la suma de las Y ('
                       || v_total_y || '). ';
      end if;

      if v_msg is null then
        execute immediate fn_r(
          q'[update VTA_{P}CARGA_YZ_RES
                set res_estado  = :1,
                    res_mensaje = 'Total Z = suma de las Y'
              where res_carga    = :2
                and res_fecha    = :3
                and res_local    = :4
                and res_terminal = :5]')
          using c_estado_ok, p_carga, v_fecha, v_local, v_term;
      else
        v_msg := rtrim(v_msg);
        execute immediate fn_r(
          q'[update VTA_{P}CARGA_YZ_RES
                set res_estado  = 'ERROR',
                    res_mensaje = :1
              where res_carga    = :2
                and res_fecha    = :3
                and res_local    = :4
                and res_terminal = :5]')
          using v_msg, p_carga, v_fecha, v_local, v_term;
        prc_log(p_carga, null, 'RESUMEN', 'GRUPO',
                to_char(v_fecha, 'dd-mm-yyyy') || ' L' || v_local || ' T' || v_term,
                v_msg, v_usuario);
      end if;
    end loop;
    close c;

    execute immediate fn_r(
      q'[select nvl(sum(case when res_estado = :1      then 1 else 0 end), 0),
                nvl(sum(case when res_estado = 'ERROR' then 1 else 0 end), 0)
           from VTA_{P}CARGA_YZ_RES
          where res_carga = :2]')
      into o_grupos_ok, o_grupos_error using c_estado_ok, p_carga;

    execute immediate fn_r(
      q'[select nvl(sum(case when det_estado = 'ERROR' then 1 else 0 end), 0),
                nvl(sum(case when det_estado = 'ERROR'
                              and (det_fecha is null or det_local is null or det_terminal is null)
                             then 1 else 0 end), 0)
           from VTA_{P}CARGA_YZ_DET
          where det_carga = :1]')
      into o_lin_error, v_sin_grp using p_carga;

    prc_log(p_carga, null, 'FIN', null, null,
            'Grupos ' || c_estado_ok || ': ' || o_grupos_ok || ', ERROR: ' || o_grupos_error
            || '. Lineas con error: ' || o_lin_error || ' (sin grupo: ' || v_sin_grp || ')',
            v_usuario);
    commit;
  exception
    when others then
      v_err := sqlerrm;
      if c%isopen then
        close c;
      end if;
      rollback;
      if g_cfg.pais = upper(trim(p_flg_pais)) then
        prc_log(p_carga, null, 'ERROR', null, null, 'prc_procesa: ' || v_err, v_usuario);
      end if;
      raise;
  end prc_procesa;

  -- ------------------------------------------------------------------
  -- Compatibilidad: firmas del 30-10 (exe anterior), con FACO
  -- ------------------------------------------------------------------
  procedure prc_inserta_linea (p_carga in number,
                               p_linea in number,
                               p_texto in varchar2) is
  begin
    prc_inserta_linea(c_pais_compat, p_carga, p_linea, p_texto);
  end prc_inserta_linea;

  procedure prc_procesa (p_carga        in  number,
                         o_grupos_ok    out number,
                         o_grupos_error out number,
                         o_lin_error    out number) is
  begin
    prc_procesa(c_pais_compat, p_carga, o_grupos_ok, o_grupos_error, o_lin_error);
  end prc_procesa;

end PKG_F8_CARGA_MASIVA_YZ;
/
