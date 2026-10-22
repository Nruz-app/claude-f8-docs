-- =====================================================================
-- POC FSCC-12901 - 02g Generador de datos reales (SE EJECUTA EN TEST)
-- Lee (solo SELECT) las cajas reales de 2026 de test y escribe el script
-- 02_datos_test.sql con INSERTs listos para cargar en DESARROLLO.
--
-- Que copia (cierres Y de 2026 que tienen libro de ventas Y valido):
--   VTA_FACOTERMSTATY  (las Y)
--   VTA_FACOLIBVTA     (registro Y de cada una)
--   VTA_FACOZZZ        (detalle del libro de ventas)
--   VTA_FACOTARJ       (tarjetas informadas de esas Y)
-- Techkey remapeados (+900000000) porque los de test chocan con los de
-- desarrollo. Textos con caracteres fuera de ASCII se escriben con chr(n)
-- (mismo juego de caracteres WE8ISO8859P1 en ambos esquemas).
--
-- Uso (SQL*Plus, conectado al usuario de test, desde esta carpeta):
--   sqlplus <usuario_test>@<base> @02g_generar_datos_test.sql
-- Genera 02_datos_test.sql en la carpeta actual.
-- =====================================================================
set serveroutput on size unlimited format wrapped
set linesize 32767 trimspool on feedback off heading off pagesize 0 echo off verify off termout off
alter session set current_schema = INTRANETTS;
spool 02_datos_test.sql

declare
  c_off   constant number := 900000000;     -- desplazamiento de techkey
  c_desde constant date   := to_date('20260101', 'yyyymmdd');
  c_dueno constant varchar2(30) := sys_context('USERENV', 'CURRENT_SCHEMA');

  -- Cierres Y a copiar: 2026, con libro de ventas Y valido (alias y)
  c_y constant varchar2(1000) :=
       'y.ter_fecha >= to_date(''20260101'',''yyyymmdd'')'
    || ' and exists (select 1 from VTA_FACOLIBVTA l, VTA_FACOZZZ r'
    || '  where l.vta_tiporeg = ''Y'' and l.vta_estado = ''A'' and l.vta_techkey = r.rec_techkey'
    || '    and l.vta_fecha_venta = y.ter_fecha and l.vta_local = y.ter_local'
    || '    and l.vta_terminal = y.ter_terminal and l.vta_secuencia = y.ter_cierrey)';

  v_w_y    varchar2(2000);
  v_w_lib  varchar2(2000);
  v_w_zzz  varchar2(2000);
  v_w_tarj varchar2(2000);
  v_n1 number; v_n2 number; v_n3 number; v_n4 number;

  procedure p (s in varchar2) is
  begin
    dbms_output.put_line(s);
  end p;

  function lit_txt (v in varchar2) return varchar2 is
    r  varchar2(32767) := '''';
    ch varchar2(1);
    n  number;
  begin
    for i in 1 .. length(v) loop
      ch := substr(v, i, 1);
      n  := ascii(ch);
      if n = 39 then
        r := r || '''''';
      elsif n < 32 or n > 126 or n = 38 then   -- 38 = ampersand (evita la sustitucion de SQL*Plus)
        r := r || '''||chr(' || n || ')||''';
      else
        r := r || ch;
      end if;
    end loop;
    return r || '''';
  end lit_txt;

  -- Escribe un INSERT por fila de p_tabla (alias t) que cumpla p_where.
  -- p_remap: columnas NUMBER a las que se suma c_off (separadas por coma).
  procedure emitir (p_tabla in varchar2, p_where in varchar2, p_remap in varchar2) is
    type t_txt is table of varchar2(30) index by pls_integer;
    v_nom  t_txt;
    v_tip  t_txt;
    k      pls_integer := 0;
    v_cols varchar2(32767);
    v_sel  varchar2(32767);
    v_cur  integer;
    v_n    integer;
    v_val  varchar2(4000);
    v_ins  varchar2(32767);
    v_cnt  number := 0;
  begin
    for c in (select column_name, data_type from all_tab_columns
               where owner = c_dueno and table_name = p_tabla order by column_id) loop
      k := k + 1;
      v_nom(k) := c.column_name;
      v_tip(k) := c.data_type;
      v_cols := v_cols || case when k > 1 then ', ' end || lower(c.column_name);
      v_sel  := v_sel  || case when k > 1 then ', ' end ||
        case
          when c.data_type = 'DATE' then
            'to_char(t.' || c.column_name || ', ''yyyymmddhh24miss'')'
          when c.data_type = 'NUMBER' then
            'to_char(t.' || c.column_name ||
            case when instr(',' || p_remap || ',', ',' || c.column_name || ',') > 0 then ' + ' || c_off end ||
            ', ''TM9'', ''NLS_NUMERIC_CHARACTERS=''''.,'''''')'
          else
            't.' || c.column_name
        end;
    end loop;

    v_cur := dbms_sql.open_cursor;
    dbms_sql.parse(v_cur, 'select ' || v_sel || ' from ' || p_tabla || ' t where ' || p_where, dbms_sql.native);
    for i in 1 .. k loop
      dbms_sql.define_column(v_cur, i, v_val, 4000);
    end loop;
    v_n := dbms_sql.execute(v_cur);

    p('-- ' || p_tabla);
    while dbms_sql.fetch_rows(v_cur) > 0 loop
      v_ins := 'insert into ' || p_tabla || ' (' || v_cols || ') values (';
      for i in 1 .. k loop
        dbms_sql.column_value(v_cur, i, v_val);
        v_ins := v_ins || case when i > 1 then ', ' end ||
          case
            when v_val is null then 'null'
            when v_tip(i) = 'DATE' then 'to_date(''' || v_val || ''', ''yyyymmddhh24miss'')'
            when v_tip(i) = 'NUMBER' then v_val
            else lit_txt(v_val)
          end;
      end loop;
      p(v_ins || ');');
      v_cnt := v_cnt + 1;
    end loop;
    dbms_sql.close_cursor(v_cur);
    p('-- ' || p_tabla || ': ' || v_cnt || ' filas');
    p('');
  end emitir;

  procedure conteo (p_tabla in varchar2, p_where in varchar2, o_n out number) is
  begin
    execute immediate 'select count(*) from ' || p_tabla || ' t where ' || p_where into o_n;
  end conteo;

begin
  v_w_y   := replace(c_y, 'y.', 't.');
  v_w_lib := 't.vta_tiporeg = ''Y'' and t.vta_estado = ''A'''
          || ' and exists (select 1 from VTA_FACOZZZ r where r.rec_techkey = t.vta_techkey)'
          || ' and exists (select 1 from VTA_FACOTERMSTATY y where ' || c_y
          || '   and y.ter_fecha = t.vta_fecha_venta and y.ter_local = t.vta_local'
          || '   and y.ter_terminal = t.vta_terminal and y.ter_cierrey = t.vta_secuencia)';
  v_w_zzz := 't.rec_techkey in (select t.vta_techkey from VTA_FACOLIBVTA t where ' || v_w_lib || ')';
  v_w_tarj:= 'exists (select 1 from VTA_FACOTERMSTATY y where ' || c_y
          || '   and y.ter_fecha = t.vta_fecha and y.ter_local = t.vta_local'
          || '   and y.ter_terminal = t.vta_terminal and y.ter_cierrey = t.vta_cierrey)';

  conteo('VTA_FACOTERMSTATY', v_w_y, v_n1);
  conteo('VTA_FACOLIBVTA', v_w_lib, v_n2);
  conteo('VTA_FACOZZZ', v_w_zzz, v_n3);
  conteo('VTA_FACOTARJ', v_w_tarj, v_n4);

  p('-- =====================================================================');
  p('-- POC FSCC-12901 - 02 Datos reales de TEST para DESARROLLO');
  p('-- GENERADO por 02g_generar_datos_test.sql el ' || to_char(sysdate, 'dd-mm-yyyy hh24:mi') || ' (no editar a mano).');
  p('-- Cierres Y de 2026 con libro de ventas Y: ' || v_n1 || ' Y, ' || v_n2 || ' libvta, '
    || v_n3 || ' zzz, ' || v_n4 || ' tarjetas. Techkey + ' || c_off || '.');
  p('-- Ejecutar en DESARROLLO despues de 01_preparar.sql (en DBeaver: Ejecutar script, Alt+X).');
  p('-- =====================================================================');
  -- sin comandos SET: el script corre igual en DBeaver y en SQL*Plus
  p('');

  emitir('VTA_FACOTERMSTATY', v_w_y, null);
  emitir('VTA_FACOLIBVTA', v_w_lib, 'VTA_TECHKEY');
  emitir('VTA_FACOZZZ', v_w_zzz, 'REC_TECHKEY');
  emitir('VTA_FACOTARJ', v_w_tarj, null);

  -- Local-dia cargados (los usa el resto del POC y 99_limpiar.sql)
  p('-- Registro de local-dia del POC');
  for d in (select distinct t.ter_fecha f, t.ter_local l from VTA_FACOTERMSTATY t
             where t.ter_fecha >= c_desde
               and exists (select 1 from VTA_FACOLIBVTA l2, VTA_FACOZZZ r
                            where l2.vta_tiporeg = 'Y' and l2.vta_estado = 'A' and l2.vta_techkey = r.rec_techkey
                              and l2.vta_fecha_venta = t.ter_fecha and l2.vta_local = t.ter_local
                              and l2.vta_terminal = t.ter_terminal and l2.vta_secuencia = t.ter_cierrey)
             order by 1, 2) loop
    p('insert into VTA_FACOPOC_DIAS (d_origen, d_fecha, d_local) values (''TEST'', to_date('''
      || to_char(d.f, 'yyyymmdd') || ''', ''yyyymmdd''), ' || d.l || ');');
  end loop;
  p('commit;');
  p('');
  p('-- Verificacion: cargado vs esperado (control = OK)');
  p('select ''TERMSTATY'' tabla, count(*) cargado, ' || v_n1 || ' esperado, case when count(*) = ' || v_n1
    || ' then ''OK'' else ''REVISAR'' end control from VTA_FACOTERMSTATY y, VTA_FACOPOC_DIAS d'
    || ' where d.d_origen = ''TEST'' and y.ter_fecha = d.d_fecha and y.ter_local = d.d_local');
  p('union all select ''LIBVTA'', count(*), ' || v_n2 || ', case when count(*) = ' || v_n2
    || ' then ''OK'' else ''REVISAR'' end from VTA_FACOLIBVTA where vta_techkey between ' || c_off
    || ' and ' || (c_off + 89999999));
  p('union all select ''ZZZ'', count(*), ' || v_n3 || ', case when count(*) = ' || v_n3
    || ' then ''OK'' else ''REVISAR'' end from VTA_FACOZZZ where rec_techkey between ' || c_off
    || ' and ' || (c_off + 89999999));
  p('union all select ''TARJ'', count(*), ' || v_n4 || ', case when count(*) = ' || v_n4
    || ' then ''OK'' else ''REVISAR'' end from VTA_FACOTARJ t, VTA_FACOPOC_DIAS d'
    || ' where d.d_origen = ''TEST'' and t.vta_fecha = d.d_fecha and t.vta_local = d.d_local;');
end;
/

spool off
set termout on
prompt 02_datos_test.sql generado.
exit
