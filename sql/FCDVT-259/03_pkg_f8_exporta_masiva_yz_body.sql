-- =====================================================================
-- FCDVT-259 - Paso 03
-- Cuerpo de PKG_F8_EXPORTA_MASIVA_YZ   (Oracle 10.2)
-- SOLO FALABELLA COLOMBIA (FACO)
-- xintec-nruz 16-11-2026
--
-- Boton "Exportar" de Form176: Z y Y grabadas de un rango de fechas,
-- local (0 = todos) y terminal (0 = todos), con el formato del CSV de
-- carga de Form174 (ver la spec, 02). Solo lectura.
--
-- Tablas fijas VTA_FACOLIBVTA, VTA_FACOZZZ y VTA_FACOLOCALES (ya no es
-- multipais: sin lista blanca ni marcas {P}).
-- El select se arma con SQL dinamico porque las columnas salen del
-- encabezado de la plantilla: cada columna de montos se valida contra
-- user_tab_columns de VTA_FACOLIBVTA y VTA_FACOZZZ antes de concatenarla;
-- un nombre que no existe en ninguna de las dos sale como 0 y nunca entra
-- al SQL. Los filtros van como binds.
-- Mapeo de identificacion: inverso de PKG_F8_GRABA_MASIVA_YZ.pr_ins_libvta
-- (docs/sql/FCDVT-14/04c_pkg_f8_graba_masiva_yz_body.sql).
-- Solo filas vigentes (vta_estado = 'A'), como el resto del F8.
-- Terminal-dia con Y y sin Z vigente (FACO cerrado solo con Y: Z precreada
-- en termstat, sin libvta 'F8'): fn_lineas agrega una Z armada con la suma
-- de sus Y (fn_z_armada). Limite conocido: montos con decimales salen con
-- decimales y Buscar de Form174 los rechaza.
-- Origen: docs/sql/FCDVT-14/04e (16-11-2026, multipais, nunca instalado).
-- =====================================================================

create or replace package body PKG_F8_EXPORTA_MASIVA_YZ as

  c_libvta constant varchar2(30) := 'VTA_FACOLIBVTA';
  c_zzz    constant varchar2(30) := 'VTA_FACOZZZ';

  -- ORA-06548 (el SELECT dejo de pedir filas). NO_DATA_NEEDED es predefinida
  -- recien en 11g; en 10.2 se declara aqui para no depender de STANDARD.
  e_no_data_needed exception;
  pragma exception_init(e_no_data_needed, -6548);

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
    elsif v_col like 'VTA\_%' escape '\' and fn_existe_col(c_libvta, v_col) then
      return fn_num('l.' || v_col);
    elsif fn_existe_col(c_zzz, v_col) then
      return fn_num('z.' || v_col);
    elsif fn_existe_col(c_libvta, v_col) then
      return fn_num('l.' || v_col);
    end if;
    return q'['0']';
  end fn_expr;

  -- ------------------------------------------------------------------
  -- Z armada con la suma de las Y: un terminal-dia con Y vigentes y sin Z
  -- vigente en libvta (FACO cerrado solo con Y: la Z esta precreada en
  -- termstat) sale con una Z armada, para que el archivo se pueda volver
  -- a cargar con Buscar de Form174.
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

  -- Clave terminal-dia de una linea: FECHA;LOCAL;TERMINAL (campos 1 a 3)
  function fn_clave (p_txt in varchar2) return varchar2 is
  begin
    return fn_campo(p_txt, 1) || ';' || fn_campo(p_txt, 2) || ';' || fn_campo(p_txt, 3);
  end fn_clave;

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
  -- Encabezado del CSV de carga de FACO
  -- ------------------------------------------------------------------
  function fn_encabezado return varchar2 is
  begin
    return PKG_F8_CARGA_MASIVA_YZ.c_encabezado;
  end fn_encabezado;

  -- ------------------------------------------------------------------
  -- Lineas de la Z y las Y de los filtros de Form176 (formato del CSV)
  -- ------------------------------------------------------------------
  function fn_lineas (p_local     in number,
                      p_terminal  in number,
                      p_fecha_ini in date,
                      p_fecha_fin in date,
                      p_grupo     in number default null) return t_lineas pipelined is
    v_encab  varchar2(4000);
    v_resto  varchar2(4000);
    v_col    varchar2(4000);
    v_pos    pls_integer;
    v_sel    varchar2(32767);
    v_sql    varchar2(32767);
    v_cur    sys_refcursor;
    v_linea  varchar2(4000);
    v_buf    t_buf;                     -- Y de un terminal-dia sin Z
    v_nbuf   pls_integer := 0;
    v_clave  varchar2(200);             -- terminal-dia en curso (campos 1 a 3)
    v_k      varchar2(200);
    v_con_z  boolean := false;          -- el terminal-dia en curso tiene Z vigente
    v_local  number := nvl(p_local, 0);
    v_term   number := nvl(p_terminal, 0);
  begin
    if p_fecha_ini is null or p_fecha_fin is null then
      raise_application_error(-20005,
        'PKG_F8_EXPORTA_MASIVA_YZ: falta la fecha de inicio o la fecha de fin');
    end if;
    if trunc(p_fecha_fin) < trunc(p_fecha_ini) then
      raise_application_error(-20004,
        'PKG_F8_EXPORTA_MASIVA_YZ: la fecha fin no puede ser anterior a la fecha inicio');
    end if;

    v_encab := fn_encabezado;
    if v_encab is null then
      raise_application_error(-20002,
        'PKG_F8_EXPORTA_MASIVA_YZ: no se pudo leer el encabezado de FACO');
    end if;
    -- fn_z_armada supone las 11 columnas de identificacion al comienzo
    if upper(substr(v_encab, 1, length(c_id))) <> c_id then
      raise_application_error(-20003,
        'PKG_F8_EXPORTA_MASIVA_YZ: el encabezado de FACO no empieza con ' || c_id);
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

    -- Binds posicionales: cada marca recibe su propio valor (:3 y :4 son el
    -- mismo local, :5 y :6 el mismo terminal, :7 y :8 el mismo grupo)
    v_sql :=
      'select ' || v_sel || q'[
         from VTA_FACOLIBVTA l, VTA_FACOZZZ z
        where l.vta_fecha_venta between :1 and :2
          and (:3 = 0 or l.vta_local = :4)
          and (:5 = 0 or l.vta_terminal = :6)
          and (:7 is null
               or l.vta_local in (select c.vta_cod_local
                                    from VTA_FACOLOCALES c
                                   where c.vta_grupo = :8))
          and l.vta_tiporeg in ('F8', 'Y')
          and l.vta_estado = 'A'
          and z.rec_techkey (+) = l.vta_techkey
        order by l.vta_fecha_venta, l.vta_local, l.vta_terminal,
                 decode(l.vta_tiporeg, 'F8', 0, 1), l.vta_secuencia]';

    -- Por terminal-dia llega primero la Z (si existe) y despues las Y. Si la
    -- primera linea del terminal-dia es una Y, no hay Z: se guardan sus Y y
    -- al cambiar de terminal-dia se emite la Z armada y despues las Y.
    open v_cur for v_sql
      using trunc(p_fecha_ini), trunc(p_fecha_fin),
            v_local, v_local, v_term, v_term, p_grupo, p_grupo;
    loop
      fetch v_cur into v_linea;
      exit when v_cur%notfound;
      v_k := fn_clave(v_linea);
      if v_clave is null or v_k <> v_clave then
        if v_nbuf > 0 then
          pipe row (fn_z_armada(v_buf, v_nbuf));
          for i in 1 .. v_nbuf loop
            pipe row (v_buf(i));
          end loop;
          v_buf.delete;
          v_nbuf := 0;
        end if;
        v_clave := v_k;
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

end PKG_F8_EXPORTA_MASIVA_YZ;
/
