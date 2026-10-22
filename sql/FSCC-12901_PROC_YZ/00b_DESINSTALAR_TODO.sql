-- =====================================================================
-- FSCC-12901 PROC_YZ - 00b DESINSTALAR TODO (dejar la base como antes de FSCC-12901)
--
-- Borra de la base TODO lo creado hasta ahora por FSCC-12901, para volver a
-- instalar v2 desde cero:
--   * v1  : PKG_F8_FACO_CIERRE_AUTO, PKG_F8_FACO_COMPENSA_DI, vista
--           VTA_FACOV_CAJAS_CIERRE
--   * v2  : PKG_F8_CIERRE_AUTO, PKG_F8_COMPENSA_DI_AUTO (si se compilaron)
--   * comunes FACO: trigger TRG_VTA_FACOPRD_CIERRE_AI, cola VTA_FACOPRD_CIERRE,
--           log VTA_FACOLOG_CIERRE_AUTO, sus secuencias, parametros 1502 y
--           opcion 1515
--   * POC : tablas VTA_FACOPOC_* y los datos que cargo (02, 03, 04, M1, Form133)
--   * efectos del proceso fuera de la POC: DI automaticas y cierres Y hechos
--     por el proceso (segun el log), antes de borrar el log
--
-- Uso: DESARROLLO, conectado como el duenio de las tablas VTA_FACO*.
-- DBeaver: ejecutar como script (Alt+X) con la salida del servidor activada
-- (Ctrl+Shift+O). SQL*Plus: set serveroutput on y luego @00b_DESINSTALAR_TODO.sql
-- Es idempotente: lo que no existe se informa como "no existe" y se sigue.
--
-- Despues, instalar desde cero en este orden (DBeaver, uno por uno):
--   00_prechecks -> 01_cola_FACO -> 02_log_FACO -> 03_parametros_FACO ->
--   03c_permiso_FACO -> 04 -> 05 -> 06 -> 07 -> 08_trigger_FACO -> 09 -> 10
--   (o INSTALAR.sql en SQL*Plus). NO usar MIGRAR_DESDE_V1.sql.
-- =====================================================================

-- ---------------------------------------------------------------
-- 0. Inventario ANTES (lo que existe hoy). Revisar antes de seguir.
-- ---------------------------------------------------------------
select object_name, object_type, status
  from user_objects
 where object_name in ('PKG_F8_FACO_CIERRE_AUTO', 'PKG_F8_FACO_COMPENSA_DI',
                       'PKG_F8_CIERRE_AUTO', 'PKG_F8_COMPENSA_DI_AUTO',
                       'VTA_FACOV_CAJAS_CIERRE', 'TRG_VTA_FACOPRD_CIERRE_AI',
                       'VTA_FACOPRD_CIERRE', 'SEQ_VTA_FACOPRD_CIERRE',
                       'VTA_FACOLOG_CIERRE_AUTO', 'SEQ_VTA_FACOLOG_CIERRE_AUTO')
    or object_name like 'VTA_FACOPOC%'
 order by object_type, object_name;

select trim(vta_ccodigo) parametro_1502, vta_xglosa
  from VTA_FACOPARAM where vta_ccodtipo = 1502 order by 1;

select (select count(*) from VTA_FACOMENU      where mnu_codigo = 1515) menu_1515,
       (select count(*) from VTA_FACORELPERMEN where mnu_codigo = 1515) relpermen_1515
  from dual;

-- Sinonimos que apuntan a estos objetos (si hay, se borran como DBA: ver punto 6)
select owner, synonym_name, table_owner, table_name
  from all_synonyms
 where table_name in ('PKG_F8_FACO_CIERRE_AUTO', 'PKG_F8_FACO_COMPENSA_DI',
                      'PKG_F8_CIERRE_AUTO', 'PKG_F8_COMPENSA_DI_AUTO',
                      'VTA_FACOV_CAJAS_CIERRE', 'VTA_FACOPRD_CIERRE', 'VTA_FACOLOG_CIERRE_AUTO');

-- ---------------------------------------------------------------
-- 1 a 5. Desinstalacion
-- ---------------------------------------------------------------
declare
  -- EDITAR si se quiere conservar algo ('S' = hacerlo / 'N' = no)
  v_borrar_poc      varchar2(1) := 'S';   -- datos y tablas de la POC (02, 03, 04, M1, Form133)
  v_revertir_efecto varchar2(1) := 'S';   -- DI automaticas y cierres Y del proceso (segun el log)

  v_n      number;
  v_login  varchar2(50);
  v_perfil varchar2(50);
  v_rel    varchar2(200);

  function existe (p_nombre in varchar2) return boolean is
    v_c number;
  begin
    select count(*) into v_c from user_objects where object_name = p_nombre;
    return v_c > 0;
  end existe;

  function ctrl (p_clave in varchar2) return varchar2 is
    v varchar2(200);
  begin
    execute immediate 'select max(valor) from VTA_FACOPOC_CTRL where clave = :1' into v using p_clave;
    return v;
  exception
    when others then return null;
  end ctrl;

  -- Ejecuta una sentencia e informa filas; si falla, informa y sigue
  procedure ej (p_desc in varchar2, p_sql in varchar2) is
  begin
    execute immediate p_sql;
    dbms_output.put_line(rpad(p_desc, 50, '.') || ' ' || sql%rowcount);
  exception
    when others then
      dbms_output.put_line(rpad(p_desc, 50, '.') || ' NO: ' || substr(sqlerrm, 1, 120));
  end ej;

  -- DROP solo si el objeto existe
  procedure dr (p_tipo in varchar2, p_nombre in varchar2) is
  begin
    if existe(p_nombre) then
      execute immediate 'drop ' || p_tipo || ' ' || p_nombre;
      dbms_output.put_line(rpad('drop ' || lower(p_tipo) || ' ' || p_nombre, 50, '.') || ' borrado');
    else
      dbms_output.put_line(rpad('drop ' || lower(p_tipo) || ' ' || p_nombre, 50, '.') || ' no existe');
    end if;
  exception
    when others then
      dbms_output.put_line(rpad('drop ' || lower(p_tipo) || ' ' || p_nombre, 50, '.') || ' ERROR: ' || substr(sqlerrm, 1, 120));
  end dr;

begin
  -- 1. Primero el trigger: desde aqui la carga de sobres ya no alimenta la cola
  dbms_output.put_line('=== 1. Trigger');
  dr('TRIGGER', 'TRG_VTA_FACOPRD_CIERRE_AI');

  -- 2. Datos de la POC (mientras existan las tablas de control)
  if v_borrar_poc = 'S' and existe('VTA_FACOPOC_DIAS') then
    dbms_output.put_line('=== 2. Datos de la POC');

    -- 2a. Prueba manual (M1 / Form133), igual que M9
    v_login  := ctrl('M_LOGIN');
    v_perfil := ctrl('M_PERFIL');
    ej('Sobres Form133 28-08-2026 locales 6 y 13',
       q'[delete from VTA_FACOPRD p where p.prv_fechavta = to_date('20260828','yyyymmdd')
           and p.prv_local in (6, 13) and nvl(p.prv_modifpor, '-') <> 'POC_FSCC12901']');
    ej('Z creadas por Form133 (CARGA MANUAL DE SOBRES)',
       q'[delete from VTA_FACOTERMSTAT t where t.ter_fecha = to_date('20260828','yyyymmdd')
           and t.ter_local in (6, 13) and t.ter_notas = 'CARGA MANUAL DE SOBRES']');
    if ctrl('M_RECAUD') = 'INSERTADO' then
      ej('Recaudador 00562 (M1)', q'[delete from VTA_FACORECAUDADORA where trim(vta_cod_recaud) = '00562']');
    end if;
    if ctrl('M_USUARIO') = 'INSERTADO' and v_login is not null then
      execute immediate q'[delete from vta_users where vta_loginname = :1 and vta_localiz = 'FACO']' using v_login;
      dbms_output.put_line(rpad('Fila FACO del usuario (M1)', 50, '.') || ' ' || sql%rowcount);
    end if;
    v_rel := ctrl('M_REL1515');
    if v_rel like 'ESTADO:%' and v_perfil is not null then
      -- la 1515 existia antes de M1: se deja como estaba (de todos modos el punto 5 la borra)
      execute immediate 'update VTA_FACORELPERMEN set rel_estado = :1 where per_codigo = :2 and mnu_codigo = 1515'
        using to_number(substr(v_rel, 8)), to_number(v_perfil);
    end if;

    -- 2b. Datos de la POC (igual que 99_limpiar)
    ej('Sobres POC (VTA_FACOPRD)', q'[delete from VTA_FACOPRD where prv_modifpor = 'POC_FSCC12901']');
    ej('Movimientos dias POC (VTA_FACOMOVDET)',
       'delete from VTA_FACOMOVDET m where exists (select 1 from VTA_FACOPOC_DIAS d'
       || ' where d.d_fecha = m.mov_fecha and d.d_local = m.mov_local)');
    ej('Glosas dias POC (VTA_FACOCOMPDES)',
       'delete from VTA_FACOCOMPDES c where exists (select 1 from VTA_FACOPOC_DIAS d'
       || ' where d.d_fecha = c.cpd_fecha and d.d_local = c.cpd_local)');
    ej('Tarjetas dias POC (VTA_FACOTARJ)',
       'delete from VTA_FACOTARJ t where exists (select 1 from VTA_FACOPOC_DIAS d'
       || ' where d.d_fecha = t.vta_fecha and d.d_local = t.vta_local)');
    ej('Detalle Z POC (VTA_FACOZZZ)', 'delete from VTA_FACOZZZ where rec_techkey between 900000000 and 999999999');
    ej('Libro de ventas POC (VTA_FACOLIBVTA)', 'delete from VTA_FACOLIBVTA where vta_techkey between 900000000 and 999999999');
    ej('Cierres Y dias POC (VTA_FACOTERMSTATY)',
       'delete from VTA_FACOTERMSTATY y where exists (select 1 from VTA_FACOPOC_DIAS d'
       || ' where d.d_fecha = y.ter_fecha and d.d_local = y.ter_local)');
    commit;
  else
    dbms_output.put_line('=== 2. Datos de la POC: no se borran (v_borrar_poc = N o no hay POC)');
  end if;

  -- 3. Efectos del proceso fuera de la POC (pruebas con 10_pruebas.sql, Form43...)
  if v_revertir_efecto = 'S' and existe('VTA_FACOLOG_CIERRE_AUTO') then
    dbms_output.put_line('=== 3. Efectos del proceso segun el log');
    ej('Y reabiertas (cerradas por T2 o CC)',
       q'[update VTA_FACOTERMSTATY y set y.ter_estado = 0, y.ter_cerradopor = null
           where y.ter_estado = 1
             and exists (select 1 from VTA_FACOLOG_CIERRE_AUTO l
                          where l.log_proceso in ('T2', 'CC') and l.log_resultado = 'CERRADA_Y'
                            and l.log_fecha_vta = y.ter_fecha and l.log_local = y.ter_local
                            and l.log_terminal = y.ter_terminal and l.log_cierrey = y.ter_cierrey
                            and l.log_usuario = y.ter_cerradopor)]');
    ej('Z reabiertas (cerradas por T2 o CC, PROC_YZ)',
       q'[update VTA_FACOTERMSTAT z set z.ter_estado = 0, z.ter_cerradopor = null
           where z.ter_estado = 1
             and exists (select 1 from VTA_FACOLOG_CIERRE_AUTO l
                          where l.log_proceso in ('T2', 'CC') and l.log_nivel = 'Z'
                            and l.log_resultado = 'CERRADA_Z'
                            and l.log_fecha_vta = z.ter_fecha and l.log_local = z.ter_local
                            and l.log_terminal = z.ter_terminal
                            and l.log_usuario = z.ter_cerradopor)]');
    ej('Glosas de DI automatica (VTA_FACOCOMPDES)',
       q'[delete from VTA_FACOCOMPDES c
           where c.cpd_tipmov = 'DI' and c.cpd_obs = 'COMPENSACION AUTOMATICA DI'
             and exists (select 1 from VTA_FACOLOG_CIERRE_AUTO l
                          where l.log_proceso = 'T1' and l.log_resultado = 'DI_REGISTRADA'
                            and l.log_fecha_vta = c.cpd_fecha and l.log_local = c.cpd_local
                            and l.log_terminal = c.cpd_terminal and l.log_cierrey = c.cpd_cierrey)]');
    ej('DI automaticas (VTA_FACOMOVDET)',
       q'[delete from VTA_FACOMOVDET m
           where m.mov_tipomov = 'DI' and m.mov_hechopor = 'PROC_DI_AUTO'
             and exists (select 1 from VTA_FACOLOG_CIERRE_AUTO l
                          where l.log_proceso = 'T1' and l.log_resultado = 'DI_REGISTRADA'
                            and l.log_fecha_vta = m.mov_fecha and l.log_local = m.mov_local
                            and l.log_terminal = m.mov_terminal and l.log_cierrey = m.mov_cierrey)]');
    commit;
  else
    dbms_output.put_line('=== 3. Efectos del proceso: no se revierten');
  end if;

  -- 4. Objetos: paquetes (v2 y v1), vista, tablas y secuencias
  dbms_output.put_line('=== 4. Objetos');
  dr('PACKAGE', 'PKG_F8_CIERRE_AUTO');
  dr('PACKAGE', 'PKG_F8_COMPENSA_DI_AUTO');
  dr('PACKAGE', 'PKG_F8_FACO_CIERRE_AUTO');
  dr('PACKAGE', 'PKG_F8_FACO_COMPENSA_DI');
  dr('VIEW',    'VTA_FACOV_CAJAS_CIERRE');
  dr('TABLE',   'VTA_FACOPRD_CIERRE');
  dr('TABLE',   'VTA_FACOLOG_CIERRE_AUTO');
  dr('SEQUENCE','SEQ_VTA_FACOPRD_CIERRE');
  dr('SEQUENCE','SEQ_VTA_FACOLOG_CIERRE_AUTO');
  if v_borrar_poc = 'S' then
    dr('TABLE', 'VTA_FACOPOC_RESP_Y');
    dr('TABLE', 'VTA_FACOPOC_PRD3');
    dr('TABLE', 'VTA_FACOPOC_CASOS');
    dr('TABLE', 'VTA_FACOPOC_DIAS');
    dr('TABLE', 'VTA_FACOPOC_CTRL');
  end if;

  -- 5. Datos de configuracion: parametros 1502 (v1 y v2, incluye CA_DIAS y
  --    CA_VAL_USD) y opcion 1515 (la vuelve a crear 03c_permiso_FACO.sql)
  dbms_output.put_line('=== 5. Configuracion');
  ej('Parametros 1502 (VTA_FACOPARAM)',
     q'[delete from VTA_FACOPARAM where vta_ccodtipo = 1502
         and trim(vta_ccodigo) in ('CA_DI_ACTIVO','CA_DI_MIN','CA_DI_MAX','CA_ACTIVO','CA_VAL_CHEQ',
                                   'CA_VAL_ZZZ','CA_VAL_USD','CA_DECIMAL','CA_DIAS','CA_SIN_SOBRE',
                                   'CA_CIERRA_Z','CA_Z_SIN_Y','CA_Z_VAL_SUMA','CA_Z_VAL_DOL')]');
  ej('Opcion 1515 (VTA_FACORELPERMEN)', 'delete from VTA_FACORELPERMEN where mnu_codigo = 1515');
  ej('Opcion 1515 (VTA_FACOMENU)',      'delete from VTA_FACOMENU where mnu_codigo = 1515');
  commit;

  dbms_output.put_line('=== Fin. Revisar el inventario DESPUES (esperado: sin filas / ceros).');
end;
/

-- ---------------------------------------------------------------
-- 6. Sinonimos (solo si el inventario del punto 0 mostro alguno).
--    Como DBA; EDITAR USUARIO_APP por el owner que mostro la consulta.
-- ---------------------------------------------------------------
-- drop synonym USUARIO_APP.PKG_F8_FACO_CIERRE_AUTO;
-- drop synonym USUARIO_APP.PKG_F8_FACO_COMPENSA_DI;
-- drop synonym USUARIO_APP.PKG_F8_CIERRE_AUTO;
-- drop synonym USUARIO_APP.PKG_F8_COMPENSA_DI_AUTO;
-- drop synonym USUARIO_APP.VTA_FACOV_CAJAS_CIERRE;
-- drop synonym USUARIO_APP.VTA_FACOPRD_CIERRE;
-- drop synonym USUARIO_APP.VTA_FACOLOG_CIERRE_AUTO;

-- ---------------------------------------------------------------
-- 7. Inventario DESPUES (esperado: 0 filas, 0 parametros 1502, 0 y 0 en la 1515)
-- ---------------------------------------------------------------
select object_name, object_type, status
  from user_objects
 where object_name in ('PKG_F8_FACO_CIERRE_AUTO', 'PKG_F8_FACO_COMPENSA_DI',
                       'PKG_F8_CIERRE_AUTO', 'PKG_F8_COMPENSA_DI_AUTO',
                       'VTA_FACOV_CAJAS_CIERRE', 'TRG_VTA_FACOPRD_CIERRE_AI',
                       'VTA_FACOPRD_CIERRE', 'SEQ_VTA_FACOPRD_CIERRE',
                       'VTA_FACOLOG_CIERRE_AUTO', 'SEQ_VTA_FACOLOG_CIERRE_AUTO')
    or object_name like 'VTA_FACOPOC%';

select (select count(*) from VTA_FACOPARAM     where vta_ccodtipo = 1502) parametros_1502,
       (select count(*) from VTA_FACOMENU      where mnu_codigo = 1515)   menu_1515,
       (select count(*) from VTA_FACORELPERMEN where mnu_codigo = 1515)   relpermen_1515,
       (select count(*) from VTA_FACOMOVDET    where mov_tipomov = 'DI' and mov_hechopor = 'PROC_DI_AUTO') di_automaticas,
       (select count(*) from VTA_FACOTERMSTATY where ter_cerradopor in ('PROC_CIERRE_AUTO', 'POC_ANALISTA', 'PRUEBA_CC')) y_cerradas_proceso,
       (select count(*) from VTA_FACOTERMSTAT  where ter_cerradopor in ('PROC_CIERRE_AUTO', 'PRUEBA_CC')) z_cerradas_proceso
  from dual;

-- Objetos del esquema que quedaron INVALIDOS por los drops (esperado: ninguno nuevo)
select object_name, object_type from user_objects where status = 'INVALID' order by 2, 1;
