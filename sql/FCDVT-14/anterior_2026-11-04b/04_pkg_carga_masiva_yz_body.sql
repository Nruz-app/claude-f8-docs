-- =====================================================================
-- FCDVT-14 - Paso 04
-- Cuerpo de PKG_F8_CARGA_MASIVA_YZ   (Oracle 10.2)
-- MULTIPAIS (habilitado: FACO)
-- xintec-nruz 30-10-2026 / 03-11-2026 (multipais y estado CARGADO)
-- xintec-nruz 04-11-2026: prc_graba (boton Cargar) y estado GRABADO
-- Versiones anteriores:
--   anterior_2026-11-04/04_pkg_carga_masiva_yz_body.sql (multipais sin prc_graba)
--   anterior_2026-11-03/04_pkg_carga_masiva_yz_body.sql (solo FACO, SQL
--   estatico, la instalada en test el 30-10)
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
-- Grabado (prc_graba, boton Cargar, etapa GRABADO del log), por grupo
-- CARGADO y con commit / rollback por grupo:
--   - rechaza el grupo si la Z (termstat) o alguna Y (termstaty) del
--     terminal-dia esta cerrada (estado 1 o 2), o si un numero de Y queda
--     fuera de 1..98 (vacio = siguiente al mayor informado del grupo);
--   - REEMPLAZA como Form19: borra la zzz de los techkeys, la libvta
--     'F8'/'Y' y todas las termstaty del dia;
--   - inserta la Z (libvta 'F8'/99 + zzz; termstat -1 si no existe) y cada
--     Y (libvta 'Y'/N + zzz + termstaty -1), con la glosa
--     'CARGA MASIVA DE CIERRE Z|Y - CARGA <n>' y el usuario;
--   - deja el grupo en GRABADO, o en ERROR con el motivo;
--   - si dos ejecuciones de Cargar coinciden, cada grupo lo graba una sola
--     (la otra lo omite y lo deja en el log).
-- VENDEDOR: maximo 10 digitos (vta_vendedor NUMBER(10)), validado en Buscar.
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

    -- xintec-nruz 04-11-2026: vta_<pfx>libvta.vta_vendedor es NUMBER(10); sin
    -- este control la linea pasaba Buscar y fallaba recien en Cargar (ORA-01438)
    if v_vend is not null and abs(v_vend) > 9999999999 then
      prc_log(p_carga, p_linea, 'LECTURA', 'VENDEDOR', to_char(v_vend),
              'Maximo 10 digitos (vta_vendedor es NUMBER(10))');
      v_err := true;
    end if;

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
  -- Etapa 2: boton Cargar (xintec-nruz 04-11-2026)
  -- ------------------------------------------------------------------

  -- Inserta una fila de VTA_{P}LIBVTA a partir de la linea de DET.
  -- Columnas como Form19.GrabarTerceraZZZ (rama FACO, :495), pero con cada
  -- campo de identificacion en su columna (FORMATO_CARGA_Y_FACO.md 3.1):
  -- bolfinal = NUM_BOLETA, crepo = CONT_REPOSICION, secuencia_srx =
  -- SECUENCIA, vendedor = VENDEDOR, hora = HHMM.
  procedure pr_ins_libvta (p_carga   in number,
                           p_linea   in number,
                           p_tiporeg in varchar2,
                           p_sec     in number,
                           p_boli    in number,
                           p_nrollo  in number,
                           p_tk      in number) is
  begin
    execute immediate fn_r(
      q'[insert into VTA_{P}LIBVTA
           (vta_fecha, vta_local, vta_terminal, vta_tiporeg, vta_secuencia, vta_fecha_venta,
            vta_montobol, vta_montofac, vta_montoncr, vta_totalvta,
            vta_numbol, vta_numfac, vta_numncr, vta_monbol_iva,
            vta_monbol_ad, vta_monbol_ex, vta_moniva, vta_monadic,
            vta_bolinicial, vta_bolfinal, vta_cantbol, vta_nrollo,
            vta_crepo_inicial, vta_crepo_final, vta_estado, vta_tipof8,
            vta_secuencia_srx, vta_hora, vta_vendedor, vta_techkey,
            vta_mmontobolper, vta_mmontotkruc, vta_mmontondb, vta_mnetotkt)
         select d.det_fecha, d.det_local, d.det_terminal, :1, :2, d.det_fecha,
                d.vta_montobol, d.vta_montofac, d.vta_montoncr, d.det_total,
                0, 0, 0, 0,
                0, 0, 0, 0,
                :3, d.det_num_boleta, d.det_num_boleta - :4 + 1, :5,
                d.det_cont_repo, d.det_cont_repo, 'A', 'N',
                d.det_secuencia, to_number(replace(d.det_hora, ':')), d.det_vendedor, :6,
                0, 0, 0, 0
           from VTA_{P}CARGA_YZ_DET d
          where d.det_carga = :7
            and d.det_linea = :8]')
      using p_tiporeg, p_sec, p_boli, p_boli, p_nrollo, p_tk, p_carga, p_linea;
    if sql%rowcount <> 1 then
      raise_application_error(-20012, 'No se encontro la linea ' || p_linea || ' en el detalle');
    end if;
  end pr_ins_libvta;

  -- Inserta la fila de VTA_{P}ZZZ (columnas 15 a 56 del CSV) como
  -- Form19Y.arma_query_rec. REC_MTOTATRF = suma de las columnas 35 a 39
  -- (Form19Y la recalcula, fila 29). Los triggers TRG_VTA_<pfx>ZZZ_I
  -- completan REC_MCMRREVCMP y REC_TARJEXTERNA.
  procedure pr_ins_zzz (p_carga in number,
                        p_linea in number,
                        p_tk    in number) is
  begin
    execute immediate fn_r(
      q'[insert into VTA_{P}ZZZ
           (rec_techkey, rec_fechaproceso,
            rec_mefectivo, rec_mrecaudaefec, rec_mchkdia, rec_mchkfecha, rec_mtarj,
            rec_msodimac, rec_mcmr, rec_mtregalo, rec_mtotconvenio, rec_mtraspasotde,
            rec_mrenueva, rec_mtotfacxcob, rec_mdotaciones, rec_mretiros, rec_mabonocmr,
            rec_mavancecmr, rec_mtotpreprenueva, rec_mtransferencia, rec_mreversatrans, rec_mretirotrans,
            rec_matrfefec, rec_matrfchk, rec_matrfcmr, rec_matrfdeb, rec_matrfcre,
            rec_mrevatottrf, rec_mrevatrfefec, rec_mrevatrfcmr, rec_mabonotde, rec_mtde,
            rec_msellosvrd, rec_mtotrecauda, rec_mtotrevrecauda, rec_mcanjepuntos, rec_mrevcanjepuntos,
            rec_mtotsif, rec_mrectercero, rec_mdevtercero, rec_mquickpaycmr, rec_mquickpaybco,
            rec_ecompay, rec_mpagopuntos, rec_mtotatrf)
         select :1, d.det_fecha,
                d.rec_mefectivo, d.rec_mrecaudaefec, d.rec_mchkdia, d.rec_mchkfecha, d.rec_mtarj,
                d.rec_msodimac, d.rec_mcmr, d.rec_mtregalo, d.rec_mtotconvenio, d.rec_mtraspasotde,
                d.rec_mrenueva, d.rec_mtotfacxcob, d.rec_mdotaciones, d.rec_mretiros, d.rec_mabonocmr,
                d.rec_mavancecmr, d.rec_mtotpreprenueva, d.rec_mtransferencia, d.rec_mreversatrans, d.rec_mretirotrans,
                d.rec_matrfefec, d.rec_matrfchk, d.rec_matrfcmr, d.rec_matrfdeb, d.rec_matrfcre,
                d.rec_mrevatottrf, d.rec_mrevatrfefec, d.rec_mrevatrfcmr, d.rec_mabonotde, d.rec_mtde,
                d.rec_msellosvrd, d.rec_mtotrecauda, d.rec_mtotrevrecauda, d.rec_mcanjepuntos, d.rec_mrevcanjepuntos,
                d.rec_mtotsif, d.rec_mrectercero, d.rec_mdevtercero, d.rec_mquickpaycmr, d.rec_mquickpaybco,
                d.rec_ecompay, d.rec_mpagopuntos,
                d.rec_matrfefec + d.rec_matrfchk + d.rec_matrfcmr + d.rec_matrfdeb + d.rec_matrfcre
           from VTA_{P}CARGA_YZ_DET d
          where d.det_carga = :2
            and d.det_linea = :3]')
      using p_tk, p_carga, p_linea;
  end pr_ins_zzz;

  function fn_techkey return number is
    v_tk number;
  begin
    -- Form19 / Form19Y: SEQ_VTA_<pfx>TEC fuera de Chile y Peru
    execute immediate fn_r('select SEQ_VTA_{P}TEC.nextval from dual') into v_tk;
    return v_tk;
  end fn_techkey;

  -- Graba un grupo (fecha / local / terminal). No hace commit ni rollback:
  -- lo hace prc_graba. Un error de negocio sale con ORA-20010..20012.
  -- Devuelve en o_msg el resumen para res_mensaje.
  procedure pr_graba_grupo (p_carga   in  number,
                            p_fecha   in  date,
                            p_local   in  number,
                            p_term    in  number,
                            p_usuario in  varchar2,
                            o_msg     out varchar2) is
    type t_num is table of number index by pls_integer;
    v_lin_y   t_num;          -- lineas Y del archivo, en orden
    v_nro_y   t_num;          -- NRO_Y informado (o nulo)
    v_lin_z   number;
    v_n       number;
    v_max     number;
    v_tk      number;
    v_boli    number;
    v_nrollo  number;
    v_ant_y   number;
    v_ant_z   number;
    type t_txt is table of varchar2(3) index by pls_integer;
    v_tiporeg t_txt;
    v_min     number;
    v_sec_ant t_num;
    v_boli_a  t_num;
    v_roll_a  t_num;
    v_boli_y  t_num;          -- bolinicial anterior de la Y, por numero
    v_roll_y  t_num;
    v_boli_z  number := 0;
    v_roll_z  number := 0;
    v_glosa_z varchar2(100) := 'CARGA MASIVA DE CIERRE Z - CARGA ' || p_carga;
    v_glosa_y varchar2(100) := 'CARGA MASIVA DE CIERRE Y - CARGA ' || p_carga;
  begin
    -- 1) Revalidacion contra la base (pudo cambiar desde Buscar)
    execute immediate fn_r(
      q'[select count(*)
           from VTA_{P}TERMSTAT
          where ter_local    = :1
            and ter_terminal = :2
            and ter_fecha    = :3
            and ter_estado in (1, 2)]')
      into v_n using p_local, p_term, p_fecha;
    if v_n > 0 then
      raise_application_error(-20010,
        'La Z del terminal esta cerrada (termstat estado 1 o 2); no se reemplaza');
    end if;

    execute immediate fn_r(
      q'[select count(*)
           from VTA_{P}TERMSTATY
          where ter_local    = :1
            and ter_terminal = :2
            and ter_fecha    = :3
            and ter_estado in (1, 2)]')
      into v_n using p_local, p_term, p_fecha;
    if v_n > 0 then
      raise_application_error(-20010,
        'El terminal tiene ' || v_n || ' cierre(s) Y cerrado(s) (termstaty estado 1 o 2); no se reemplaza');
    end if;

    -- Lineas del grupo: la Z y las Y en el orden del archivo
    execute immediate fn_r(
      q'[select max(det_linea)
           from VTA_{P}CARGA_YZ_DET
          where det_carga = :1 and det_fecha = :2 and det_local = :3
            and det_terminal = :4 and det_tipo = 'Z' and det_estado = 'OK']')
      into v_lin_z using p_carga, p_fecha, p_local, p_term;
    execute immediate fn_r(
      q'[select det_linea, det_nro_y
           from VTA_{P}CARGA_YZ_DET
          where det_carga = :1 and det_fecha = :2 and det_local = :3
            and det_terminal = :4 and det_tipo = 'Y' and det_estado = 'OK'
          order by det_linea]')
      bulk collect into v_lin_y, v_nro_y using p_carga, p_fecha, p_local, p_term;
    if v_lin_z is null or v_lin_y.count = 0 then
      raise_application_error(-20011, 'El grupo no tiene su Z y sus Y en el detalle');
    end if;

    -- Numero de Y: el informado, o el siguiente al mayor informado del grupo
    v_max := 0;
    for i in 1 .. v_lin_y.count loop
      if v_nro_y(i) is not null and v_nro_y(i) > v_max then
        v_max := v_nro_y(i);
      end if;
    end loop;
    for i in 1 .. v_lin_y.count loop
      if v_nro_y(i) is null then
        v_max      := v_max + 1;
        v_nro_y(i) := v_max;
      end if;
      if v_nro_y(i) < 1 or v_nro_y(i) > 98 then
        raise_application_error(-20011,
          'Linea ' || v_lin_y(i) || ': numero de Y ' || v_nro_y(i)
          || ' fuera de rango (1 a 98; el 99 es la Z)');
      end if;
    end loop;

    -- 2) Datos de los cierres anteriores (Form19.LeeZactual / Form19Y.LeeZactual)
    execute immediate fn_r(
      q'[select vta_tiporeg, vta_secuencia, nvl(vta_bolinicial, 0), nvl(vta_nrollo, 0)
           from VTA_{P}LIBVTA
          where vta_fecha_venta = :1 and vta_local = :2 and vta_terminal = :3
            and vta_tiporeg in ('F8', 'Y')]')
      bulk collect into v_tiporeg, v_sec_ant, v_boli_a, v_roll_a
      using p_fecha, p_local, p_term;
    v_ant_y := 0;
    v_ant_z := 0;
    for i in 1 .. v_tiporeg.count loop
      if v_tiporeg(i) = 'F8' then
        v_ant_z := v_ant_z + 1;
        if v_sec_ant(i) = 99 then
          v_boli_z := v_boli_a(i);
          v_roll_z := v_roll_a(i);
        end if;
      else
        v_ant_y := v_ant_y + 1;
        v_boli_y(v_sec_ant(i)) := v_boli_a(i);
        v_roll_y(v_sec_ant(i)) := v_roll_a(i);
      end if;
    end loop;

    -- 3) Reemplazo (como Form19.GrabarSegundaZZZ + Func_Eliminar_TermStatY),
    --    borrando ademas la zzz de los techkeys (Form19 la deja huerfana)
    execute immediate fn_r(
      q'[delete from VTA_{P}ZZZ
          where rec_techkey in (select l.vta_techkey
                                  from VTA_{P}LIBVTA l
                                 where l.vta_fecha_venta = :1
                                   and l.vta_local       = :2
                                   and l.vta_terminal    = :3
                                   and l.vta_tiporeg in ('F8', 'Y')
                                   and l.vta_techkey is not null)]')
      using p_fecha, p_local, p_term;
    execute immediate fn_r(
      q'[delete from VTA_{P}LIBVTA
          where vta_fecha_venta = :1 and vta_local = :2 and vta_terminal = :3
            and vta_tiporeg in ('F8', 'Y')]')
      using p_fecha, p_local, p_term;
    execute immediate fn_r(
      q'[delete from VTA_{P}TERMSTATY
          where ter_fecha = :1 and ter_local = :2 and ter_terminal = :3]')
      using p_fecha, p_local, p_term;

    -- 4) Z: libvta 'F8' / 99 + zzz; termstat -1 solo si no existe
    v_tk := fn_techkey;
    pr_ins_libvta(p_carga, v_lin_z, 'F8', 99, v_boli_z, v_roll_z, v_tk);
    pr_ins_zzz(p_carga, v_lin_z, v_tk);
    execute immediate fn_r(
      q'[insert into VTA_{P}TERMSTAT
           (ter_local, ter_terminal, ter_fecha, ter_estado, ter_notas, ter_cerradopor)
         select :1, :2, :3, -1, :4, :5 from dual
          where not exists (select 1 from VTA_{P}TERMSTAT
                             where ter_local = :6 and ter_terminal = :7 and ter_fecha = :8)]')
      using p_local, p_term, p_fecha, v_glosa_z, p_usuario, p_local, p_term, p_fecha;

    -- 5) Cada Y: libvta 'Y' / N + zzz + termstaty -1
    for i in 1 .. v_lin_y.count loop
      v_boli   := 0;
      v_nrollo := 0;
      if v_boli_y.exists(v_nro_y(i)) then
        v_boli   := v_boli_y(v_nro_y(i));
        v_nrollo := v_roll_y(v_nro_y(i));
      end if;
      v_tk := fn_techkey;
      pr_ins_libvta(p_carga, v_lin_y(i), 'Y', v_nro_y(i), v_boli, v_nrollo, v_tk);
      pr_ins_zzz(p_carga, v_lin_y(i), v_tk);
      execute immediate fn_r(
        q'[insert into VTA_{P}TERMSTATY
             (ter_local, ter_terminal, ter_fecha, ter_cierrey, ter_estado, ter_notas, ter_cerradopor)
           values (:1, :2, :3, :4, -1, :5, :6)]')
        using p_local, p_term, p_fecha, v_nro_y(i), v_glosa_y, p_usuario;
      -- El numero asignado queda en el detalle (Form175 lo muestra)
      execute immediate fn_r(
        q'[update VTA_{P}CARGA_YZ_DET
              set det_nro_y = :1
            where det_carga = :2 and det_linea = :3]')
        using v_nro_y(i), p_carga, v_lin_y(i);
    end loop;

    v_min := v_nro_y(1);
    v_max := v_nro_y(1);
    for i in 2 .. v_lin_y.count loop
      v_min := least(v_min, v_nro_y(i));
      v_max := greatest(v_max, v_nro_y(i));
    end loop;
    o_msg := 'Grabado: Z + ' || v_lin_y.count || ' Y (numeros '
             || v_min || ' a ' || v_max || ')';
    if v_ant_z + v_ant_y > 0 then
      o_msg := o_msg || '. Reemplazo lo anterior: ' || v_ant_z || ' Z y ' || v_ant_y || ' Y';
    end if;
  end pr_graba_grupo;

  procedure prc_graba (p_flg_pais     in  varchar2,
                       p_carga        in  number,
                       p_usuario      in  varchar2,
                       o_grupos_ok    out number,
                       o_grupos_error out number) is
    type t_fec is table of date index by pls_integer;
    type t_num is table of number index by pls_integer;
    v_fechas  t_fec;
    v_locales t_num;
    v_terms   t_num;
    v_usuario varchar2(50);
    v_msg     varchar2(1000);
    v_grupo   varchar2(200);
    e_tomado  exception;   -- otra sesion ya grabo (o esta grabando) el grupo
  begin
    o_grupos_ok    := 0;
    o_grupos_error := 0;
    pr_config(p_flg_pais);
    v_usuario := nvl(p_usuario, fn_usuario(p_carga));
    commit;   -- nada pendiente de la sesion antes del primer grupo

    -- Los grupos se leen antes del bucle: hay commit por grupo
    execute immediate fn_r(
      q'[select res_fecha, res_local, res_terminal
           from VTA_{P}CARGA_YZ_RES
          where res_carga  = :1
            and res_estado = :2
          order by res_fecha, res_local, res_terminal]')
      bulk collect into v_fechas, v_locales, v_terms
      using p_carga, c_estado_ok;

    prc_log(p_carga, null, 'GRABADO', 'INICIO', to_char(v_fechas.count),
            'Inicio de Cargar: ' || v_fechas.count || ' grupo(s) ' || c_estado_ok, v_usuario);

    for g in 1 .. v_fechas.count loop
      v_grupo := to_char(v_fechas(g), 'dd-mm-yyyy') || ' L' || v_locales(g) || ' T' || v_terms(g);
      begin
        -- Toma el grupo: bloquea su fila de RES y confirma que sigue CARGADO.
        -- Si dos sesiones ejecutan Cargar sobre la misma carga, la segunda
        -- espera aqui hasta el commit de la primera y despues lo salta.
        execute immediate fn_r(
          q'[update VTA_{P}CARGA_YZ_RES
                set res_fechahora = sysdate
              where res_carga = :1 and res_fecha = :2
                and res_local = :3 and res_terminal = :4
                and res_estado = :5]')
          using p_carga, v_fechas(g), v_locales(g), v_terms(g), c_estado_ok;
        if sql%rowcount = 0 then
          raise e_tomado;
        end if;
        pr_graba_grupo(p_carga, v_fechas(g), v_locales(g), v_terms(g), v_usuario, v_msg);
        execute immediate fn_r(
          q'[update VTA_{P}CARGA_YZ_RES
                set res_estado = :1, res_mensaje = :2, res_fechahora = sysdate
              where res_carga = :3 and res_fecha = :4
                and res_local = :5 and res_terminal = :6]')
          using c_estado_grabado, substr(v_msg, 1, 1000),
                p_carga, v_fechas(g), v_locales(g), v_terms(g);
        commit;
        o_grupos_ok := o_grupos_ok + 1;
        prc_log(p_carga, null, 'GRABADO', 'GRUPO', v_grupo, v_msg, v_usuario);
      exception
        when e_tomado then
          rollback;
          prc_log(p_carga, null, 'GRABADO', 'GRUPO', v_grupo,
                  'Se omite: ya no estaba ' || c_estado_ok || ' (lo grabo otra ejecucion de Cargar)',
                  v_usuario);
        when others then
          if sqlcode between -20999 and -20000 then
            v_msg := 'No se grabo: ' || substr(sqlerrm, 12);   -- sin "ORA-200nn: "
          else
            v_msg := 'No se grabo (error Oracle): ' || sqlerrm;
          end if;
          rollback;   -- deshace todo lo del grupo (borrado e inserciones)
          execute immediate fn_r(
            q'[update VTA_{P}CARGA_YZ_RES
                  set res_estado = 'ERROR', res_mensaje = :1, res_fechahora = sysdate
                where res_carga = :2 and res_fecha = :3
                  and res_local = :4 and res_terminal = :5]')
            using substr(v_msg, 1, 1000), p_carga, v_fechas(g), v_locales(g), v_terms(g);
          commit;
          o_grupos_error := o_grupos_error + 1;
          prc_log(p_carga, null, 'GRABADO', 'GRUPO', v_grupo, v_msg, v_usuario);
      end;
    end loop;

    prc_log(p_carga, null, 'GRABADO', 'FIN', null,
            'Fin de Cargar. Grupos ' || c_estado_grabado || ': ' || o_grupos_ok
            || ', ERROR: ' || o_grupos_error, v_usuario);
  exception
    when others then
      rollback;
      if g_cfg.pais = upper(trim(p_flg_pais)) then
        prc_log(p_carga, null, 'ERROR', null, null, 'prc_graba: ' || sqlerrm, v_usuario);
      end if;
      raise;
  end prc_graba;

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
