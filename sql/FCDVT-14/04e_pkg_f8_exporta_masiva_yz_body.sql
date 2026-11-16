-- =====================================================================
-- FCDVT-14 - Paso 04e
-- Cuerpo de PKG_F8_EXPORTA_MASIVA_YZ   (Oracle 10.2)
-- MULTIPAIS (habilitado: FACO y SFCL)
-- xintec-nruz 16-11-2026
--
-- Boton "Descargar Excel" de Form174: Z y Y grabadas de un local y una
-- fecha, con el formato del CSV de carga (ver la spec, 04d). Solo lectura.
--
-- SQL dinamico con la marca {P} (prefijo de tablas), que sale solo de la
-- lista blanca de pr_config (mismo patron que PKG_F8_GRABA_MASIVA_YZ).
-- Las columnas de montos del encabezado se validan contra user_tab_columns
-- de VTA_{P}LIBVTA y VTA_{P}ZZZ antes de concatenarlas: un nombre que no
-- existe en ninguna de las dos sale como 0 y nunca entra al SQL.
-- Mapeo de identificacion: inverso de PKG_F8_GRABA_MASIVA_YZ.pr_ins_libvta
-- (04c_pkg_f8_graba_masiva_yz_body.sql, "Inserta una fila de VTA_{P}LIBVTA").
-- Solo filas vigentes (vta_estado = 'A'), como el resto del F8 (Form19, Form3).
-- Terminal con Y y sin Z vigente (FACO cerrado solo con Y: Z precreada en
-- termstat, sin libvta 'F8'): fn_lineas agrega una Z armada con la suma de
-- sus Y (fn_z_armada, 16-11-2026). Limite conocido (README_FCDVT-14 5.10):
-- montos con decimales salen con decimales y Buscar los rechaza.
-- =====================================================================

create or replace package body PKG_F8_EXPORTA_MASIVA_YZ as

  -- ------------------------------------------------------------------
  -- Configuracion del pais (lista blanca: UNICA fuente del prefijo que se
  -- concatena en el SQL dinamico; nunca se usa el texto recibido)
  -- ------------------------------------------------------------------
  type t_cfg is record (
    pais    varchar2(10),     -- valor de Flg_Pais$ recibido (normalizado)
    prefijo varchar2(10)      -- prefijo de tablas VTA_<prefijo>...
  );
  g_cfg t_cfg;

  -- ORA-06548 (el SELECT dejo de pedir filas). NO_DATA_NEEDED es predefinida
  -- recien en 11g; en 10.2 se declara aqui para no depender de STANDARD.
  e_no_data_needed exception;
  pragma exception_init(e_no_data_needed, -6548);

  procedure pr_config (p_flg_pais in varchar2) is
    v_pais varchar2(10) := upper(trim(p_flg_pais));
    v_cfg  t_cfg;
  begin
    if g_cfg.pais is not null and g_cfg.pais = v_pais then
      return;   -- ya configurado
    end if;

    if v_pais = 'FACO' then
      v_cfg.pais    := 'FACO';      -- Falabella Colombia (FCDVT-14)
      v_cfg.prefijo := 'FACO';
    elsif v_pais = 'SFCL' then
      v_cfg.pais    := 'SFCL';      -- Tottus Chile (FCDVT-10)
      v_cfg.prefijo := 'SFCL';
    else
      raise_application_error(-20001,
        'PKG_F8_EXPORTA_MASIVA_YZ: pais no habilitado (' || nvl(p_flg_pais, '(nulo)') || ')');
    end if;

    g_cfg := v_cfg;
  end pr_config;

  -- Reemplaza la marca {P} con el prefijo del pais configurado
  function fn_r (p_sql in varchar2) return varchar2 is
  begin
    return replace(p_sql, '{P}', g_cfg.prefijo);
  end fn_r;

  -- true si la columna existe en la tabla (del duenio del package)
  function fn_existe_col (p_tabla in varchar2, p_col in varchar2) return boolean is
    v_n number;
  begin
    select count(*)
      into v_n
      from user_tab_columns
     where table_name  = upper(p_tabla)
       and column_name = upper(p_col);
    return v_n > 0;
  end fn_existe_col;

  -- Monto como texto con punto decimal, sin separador de miles (nulo = 0)
  function fn_num (p_expr in varchar2) return varchar2 is
  begin
    return 'to_char(nvl(' || p_expr || q'[, 0), 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''')]';
  end fn_num;

  -- Expresion SQL (sobre libvta l y zzz z) de una columna del encabezado
  function fn_expr (p_col in varchar2) return varchar2 is
    v_col varchar2(30) := upper(trim(p_col));
  begin
    if v_col = 'FECHA' then
      return q'[to_char(l.vta_fecha_venta, 'dd-mm-yyyy')]';
    elsif v_col = 'LOCAL' then
      return 'to_char(l.vta_local)';
    elsif v_col = 'TERMINAL' then
      return 'to_char(l.vta_terminal)';
    elsif v_col = 'NRO_Y' then
      return q'[case when l.vta_tiporeg = 'Y' then to_char(l.vta_secuencia) end]';
    elsif v_col = 'HORA' then
      return q'[case when l.vta_hora is not null then substr(lpad(to_char(l.vta_hora), 4, '0'), 1, 2) || ':' || substr(lpad(to_char(l.vta_hora), 4, '0'), 3, 2) end]';
    elsif v_col = 'SECUENCIA' then
      return 'to_char(l.vta_secuencia_srx)';
    elsif v_col = 'NUM_BOLETA' then
      return 'to_char(l.vta_bolfinal)';
    elsif v_col = 'VENDEDOR' then
      return 'to_char(l.vta_vendedor)';
    elsif v_col = 'CONT_REPOSICION' then
      return 'to_char(l.vta_crepo_final)';
    elsif v_col = 'TIPO' then
      return q'[case when l.vta_tiporeg = 'F8' then 'Z' else 'Y' end]';
    elsif v_col = 'TIPO_CARGA' then
      return q'['INGRESAR']';
    end if;

    -- Montos: VTA_* primero en libvta; el resto primero en zzz
    if v_col is null or length(v_col) > 30 then
      return q'['0']';
    elsif v_col like 'VTA\_%' escape '\' and fn_existe_col(fn_r('VTA_{P}LIBVTA'), v_col) then
      return fn_num('l.' || v_col);
    elsif fn_existe_col(fn_r('VTA_{P}ZZZ'), v_col) then
      return fn_num('z.' || v_col);
    elsif fn_existe_col(fn_r('VTA_{P}LIBVTA'), v_col) then
      return fn_num('l.' || v_col);
    end if;
    return q'['0']';
  end fn_expr;

  -- ------------------------------------------------------------------
  -- Z armada con la suma de las Y (16-11-2026, pedido del usuario): un
  -- terminal con Y vigentes y sin Z vigente en libvta (FACO cerrado solo
  -- con Y: la Z esta precreada en termstat) sale en el Excel con una Z
  -- armada, para que el archivo se pueda volver a cargar con Buscar.
  --   - montos (columnas 12 en adelante): suma de las Y, columna a columna;
  --   - HORA, SECUENCIA, NUM_BOLETA, VENDEDOR y CONT_REPOSICION: los de la
  --     ultima Y (la de mayor numero), como el ejemplo de la plantilla;
  --   - NRO_Y vacio, TIPO = Z, TIPO_CARGA = INGRESAR.
  -- Trabaja sobre las lineas ya armadas (columnas 1 a 11 = c_id).
  -- ------------------------------------------------------------------
  c_id   constant varchar2(200) :=
    'FECHA;LOCAL;TERMINAL;NRO_Y;HORA;SECUENCIA;NUM_BOLETA;VENDEDOR;CONT_REPOSICION;TIPO;TIPO_CARGA';
  c_n_id constant pls_integer := 11;

  type t_buf is table of varchar2(4000) index by pls_integer;

  -- Cantidad de campos de una linea separada por ;
  function fn_ncampos (p_txt in varchar2) return pls_integer is
  begin
    return nvl(length(p_txt), 0) - nvl(length(replace(p_txt, ';')), 0) + 1;
  end fn_ncampos;

  -- Campo n (desde 1) de una linea separada por ;
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
      v_fin := length(p_txt) + 1;
    end if;
    return substr(p_txt, v_ini, v_fin - v_ini);
  end fn_campo;

  -- Texto con punto decimal (salida de fn_num) a numero; vacio = 0
  function fn_a_num (p_txt in varchar2) return number is
  begin
    if trim(p_txt) is null then
      return 0;
    end if;
    return to_number(trim(p_txt), '999999999999999999999D9999999999',
                     'NLS_NUMERIC_CHARACTERS=''.,''');
  end fn_a_num;

  -- Linea Z armada con las Y del buffer (p_buf(1..p_n), ordenadas por numero de Y)
  function fn_z_armada (p_buf in t_buf, p_n in pls_integer) return varchar2 is
    v_ult  varchar2(4000) := p_buf(p_n);
    v_nc   pls_integer    := fn_ncampos(p_buf(p_n));
    v_val  varchar2(4000);
    v_sum  number;
    v_out  varchar2(4000);
  begin
    for c in 1 .. v_nc loop
      if c = 4 then
        v_val := null;                       -- NRO_Y
      elsif c = 10 then
        v_val := 'Z';                        -- TIPO
      elsif c <= c_n_id then
        v_val := fn_campo(v_ult, c);         -- identificacion de la ultima Y
      else
        v_sum := 0;
        for i in 1 .. p_n loop
          v_sum := v_sum + fn_a_num(fn_campo(p_buf(i), c));
        end loop;
        v_val := to_char(v_sum, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''');
      end if;
      if c = 1 then
        v_out := v_val;
      else
        v_out := v_out || ';' || v_val;
      end if;
    end loop;
    return v_out;
  end fn_z_armada;

  -- ------------------------------------------------------------------
  -- Encabezado del CSV de carga del pais
  -- ------------------------------------------------------------------
  function fn_encabezado (p_flg_pais in varchar2) return varchar2 is
    v_encab varchar2(4000);
  begin
    pr_config(p_flg_pais);
    if g_cfg.pais = 'SFCL' then
      -- dinamico: compila aunque PKG_F8_CARGA_MASIVA_YZ_SFCL no este instalado
      execute immediate 'begin :r := PKG_F8_CARGA_MASIVA_YZ_SFCL.fn_encabezado(:p); end;'
        using out v_encab, in g_cfg.pais;
    else
      v_encab := PKG_F8_CARGA_MASIVA_YZ.c_encabezado;
    end if;
    return v_encab;
  end fn_encabezado;

  -- ------------------------------------------------------------------
  -- Lineas de la Z y las Y del local y la fecha (formato del CSV)
  -- ------------------------------------------------------------------
  function fn_lineas (p_flg_pais in varchar2,
                      p_local    in number,
                      p_fecha    in date) return t_lineas pipelined is
    v_encab varchar2(4000);
    v_resto varchar2(4000);
    v_col   varchar2(4000);
    v_pos   pls_integer;
    v_sel   varchar2(32767);
    v_sql   varchar2(32767);
    v_cur   sys_refcursor;
    v_linea varchar2(4000);
    v_buf   t_buf;                      -- Y de un terminal sin Z
    v_nbuf  pls_integer := 0;
    v_term  varchar2(100);              -- terminal en curso (campo 3)
    v_t     varchar2(100);
    v_con_z boolean := false;           -- el terminal en curso tiene Z vigente
  begin
    v_encab := fn_encabezado(p_flg_pais);   -- tambien configura el pais
    if v_encab is null then
      raise_application_error(-20002,
        'PKG_F8_EXPORTA_MASIVA_YZ: no se pudo leer el encabezado de ' || g_cfg.pais);
    end if;
    -- fn_z_armada supone las 11 columnas de identificacion al comienzo
    if upper(substr(v_encab, 1, length(c_id))) <> c_id then
      raise_application_error(-20003,
        'PKG_F8_EXPORTA_MASIVA_YZ: el encabezado de ' || g_cfg.pais
        || ' no empieza con ' || c_id);
    end if;

    -- Una expresion por columna del encabezado, unidas con ;
    v_resto := v_encab;
    loop
      v_pos := instr(v_resto, ';');
      if v_pos = 0 then
        v_col   := v_resto;
        v_resto := null;
      else
        v_col   := substr(v_resto, 1, v_pos - 1);
        v_resto := substr(v_resto, v_pos + 1);
      end if;
      if v_sel is null then
        v_sel := fn_expr(v_col);
      else
        v_sel := v_sel || q'[ || ';' || ]' || fn_expr(v_col);
      end if;
      exit when v_resto is null;
    end loop;

    v_sql := fn_r(
      'select ' || v_sel || q'[
         from VTA_{P}LIBVTA l, VTA_{P}ZZZ z
        where l.vta_fecha_venta = :1
          and l.vta_local = :2
          and l.vta_tiporeg in ('F8', 'Y')
          and l.vta_estado = 'A'
          and z.rec_techkey (+) = l.vta_techkey
        order by l.vta_terminal, decode(l.vta_tiporeg, 'F8', 0, 1), l.vta_secuencia]');

    -- Por terminal llega primero la Z (si existe) y despues las Y. Si la
    -- primera linea del terminal es una Y, no hay Z: se guardan sus Y y al
    -- cambiar de terminal se emite la Z armada y despues las Y.
    open v_cur for v_sql using trunc(p_fecha), p_local;
    loop
      fetch v_cur into v_linea;
      exit when v_cur%notfound;
      v_t := fn_campo(v_linea, 3);
      if v_term is null or v_t <> v_term then
        if v_nbuf > 0 then
          pipe row (fn_z_armada(v_buf, v_nbuf));
          for i in 1 .. v_nbuf loop
            pipe row (v_buf(i));
          end loop;
          v_buf.delete;
          v_nbuf := 0;
        end if;
        v_term  := v_t;
        v_con_z := (fn_campo(v_linea, 10) = 'Z');
      end if;
      if v_con_z then
        pipe row (v_linea);
      else
        v_nbuf := v_nbuf + 1;
        v_buf(v_nbuf) := v_linea;
      end if;
    end loop;
    close v_cur;
    if v_nbuf > 0 then
      pipe row (fn_z_armada(v_buf, v_nbuf));
      for i in 1 .. v_nbuf loop
        pipe row (v_buf(i));
      end loop;
    end if;
    return;
  exception
    when e_no_data_needed then
      if v_cur%isopen then
        close v_cur;
      end if;
      return;
    when others then
      if v_cur%isopen then
        close v_cur;
      end if;
      raise;
  end fn_lineas;

  -- ------------------------------------------------------------------
  -- Resumen por terminal del local y la fecha
  -- ------------------------------------------------------------------
  function fn_resumen (p_flg_pais in varchar2,
                       p_local    in number,
                       p_fecha    in date) return t_lineas pipelined is
    v_sql   varchar2(32767);
    v_cur   sys_refcursor;
    v_linea varchar2(4000);
  begin
    pr_config(p_flg_pais);

    v_sql := fn_r(
      q'[select to_char(g.term)
                || ';' || to_char(g.cant_y)
                || ';' || ]' || fn_num('g.total_y') || q'[
                || ';' || ]' || fn_num('g.total_z') || q'[
                || ';' || ]' || fn_num('g.total_z - g.total_y') || q'[
                || ';' || (select to_char(max(t.ter_estado))
                             from VTA_{P}TERMSTAT t
                            where t.ter_local = g.loc
                              and t.ter_terminal = g.term
                              and t.ter_fecha = g.fec)
                || ';' || (select to_char(count(*))
                             from VTA_{P}TERMSTATY t
                            where t.ter_local = g.loc
                              and t.ter_terminal = g.term
                              and t.ter_fecha = g.fec
                              and t.ter_estado in (1, 2))
                || ';' || case when g.cant_z = 0 and g.cant_y > 0 then 'S' else 'N' end
           from (select l.vta_local loc, l.vta_fecha_venta fec, l.vta_terminal term,
                        sum(case when l.vta_tiporeg = 'Y' then 1 else 0 end) cant_y,
                        sum(case when l.vta_tiporeg = 'F8' then 1 else 0 end) cant_z,
                        sum(case when l.vta_tiporeg = 'Y' then nvl(l.vta_totalvta, 0) else 0 end) total_y,
                        sum(case when l.vta_tiporeg = 'F8' then nvl(l.vta_totalvta, 0) else 0 end) total_z
                   from VTA_{P}LIBVTA l
                  where l.vta_fecha_venta = :1
                    and l.vta_local = :2
                    and l.vta_tiporeg in ('F8', 'Y')
                    and l.vta_estado = 'A'
                  group by l.vta_local, l.vta_fecha_venta, l.vta_terminal) g
          order by g.term]');

    open v_cur for v_sql using trunc(p_fecha), p_local;
    loop
      fetch v_cur into v_linea;
      exit when v_cur%notfound;
      pipe row (v_linea);
    end loop;
    close v_cur;
    return;
  exception
    when e_no_data_needed then
      if v_cur%isopen then
        close v_cur;
      end if;
      return;
    when others then
      if v_cur%isopen then
        close v_cur;
      end if;
      raise;
  end fn_resumen;

end PKG_F8_EXPORTA_MASIVA_YZ;
/
