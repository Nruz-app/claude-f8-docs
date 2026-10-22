-- =====================================================================
-- FSCC-12901 COMPENSA_DI - Paso 01: DESINSTALAR la v2 (y restos de v1/YZ)
-- xintec-nruz 19-10-2026
--
-- Borra de la base lo que se traspaso a test el 14-10-2026
-- (FSCC-12901_PROC_Y/traspaso_test/TRASPASO_TEST_FSCC-12901_v2.sql), que
-- responde al modelo anterior (cierre de la Y al cargar los sobres):
--   trigger TRG_VTA_FACOPRD_CIERRE_AI, paquetes PKG_F8_CIERRE_AUTO y
--   PKG_F8_COMPENSA_DI_AUTO, cola VTA_FACOPRD_CIERRE, log
--   VTA_FACOLOG_CIERRE_AUTO, sus secuencias, parametros 1502 (CA_*) y
--   opcion 1515. Tambien los nombres de v1 (PKG_F8_FACO_*, vista
--   VTA_FACOV_CAJAS_CIERRE) si existieran.
-- Antes de borrar, RESPALDA la cola y el log (historial de las pruebas
-- 1 a 3) en VTA_FACOPRD_CIERRE_BK y VTA_FACOLOG_CIERRE_AUTO_BK.
--
-- NO toca datos de negocio: las DI ya registradas por PROC_DI_AUTO
-- (VTA_FACOMOVDET / VTA_FACOCOMPDES) y las Y cerradas por PROC_CIERRE_AUTO
-- quedan como estan.
--
-- OJO: Form133 (exe actual de test) llama a PKG_F8_CIERRE_AUTO al terminar
-- una carga FACO. Despues de este script esa llamada falla con un mensaje
-- (los sobres SI quedan cargados) hasta compilar el exe con el cambio de
-- FORM133_cambios.md.
--
-- Uso: conectado como el duenio (test: INTRANETTS). Idempotente: lo que no
-- existe se informa como "no existe" y se sigue.
-- DBeaver: ejecutar como script (Alt+X) con la salida del servidor activada.
-- SQL*Plus: set serveroutput on y luego @01_DESINSTALAR_v2.sql
-- =====================================================================

-- ---------------------------------------------------------------------
-- (a) Job (solo si 00_prechecks consulta 3 devolvio filas). EDITAR:
-- begin dbms_job.remove(0); commit; end;   -- EDITAR 0 = numero de job
-- /
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- PARTE 1: como el duenio
-- ---------------------------------------------------------------------
declare
  function existe (p_nombre in varchar2) return boolean is
    v_c number;
  begin
    select count(*) into v_c from user_objects where object_name = p_nombre;
    return v_c > 0;
  end existe;

  -- Ejecuta una sentencia e informa filas; si falla, informa y sigue
  procedure ej (p_desc in varchar2, p_sql in varchar2) is
  begin
    execute immediate p_sql;
    dbms_output.put_line(rpad(p_desc, 55, '.') || ' ' || sql%rowcount);
  exception
    when others then
      dbms_output.put_line(rpad(p_desc, 55, '.') || ' NO: ' || substr(sqlerrm, 1, 120));
  end ej;

  -- DROP solo si el objeto existe
  procedure dr (p_tipo in varchar2, p_nombre in varchar2) is
  begin
    if existe(p_nombre) then
      execute immediate 'drop ' || p_tipo || ' ' || p_nombre;
      dbms_output.put_line(rpad('drop ' || lower(p_tipo) || ' ' || p_nombre, 55, '.') || ' borrado');
    else
      dbms_output.put_line(rpad('drop ' || lower(p_tipo) || ' ' || p_nombre, 55, '.') || ' no existe');
    end if;
  exception
    when others then
      dbms_output.put_line(rpad('drop ' || lower(p_tipo) || ' ' || p_nombre, 55, '.') || ' ERROR: ' || substr(sqlerrm, 1, 120));
  end dr;

begin
  -- (b) Respaldo de la cola y el log (solo si existen y no hay respaldo previo)
  dbms_output.put_line('=== (b) Respaldo');
  if existe('VTA_FACOPRD_CIERRE') and not existe('VTA_FACOPRD_CIERRE_BK') then
    ej('create VTA_FACOPRD_CIERRE_BK',
       'create table VTA_FACOPRD_CIERRE_BK as select * from VTA_FACOPRD_CIERRE');
  else
    dbms_output.put_line(rpad('VTA_FACOPRD_CIERRE_BK', 55, '.') || ' sin cola o respaldo ya existe');
  end if;
  if existe('VTA_FACOLOG_CIERRE_AUTO') and not existe('VTA_FACOLOG_CIERRE_AUTO_BK') then
    ej('create VTA_FACOLOG_CIERRE_AUTO_BK',
       'create table VTA_FACOLOG_CIERRE_AUTO_BK as select * from VTA_FACOLOG_CIERRE_AUTO');
  else
    dbms_output.put_line(rpad('VTA_FACOLOG_CIERRE_AUTO_BK', 55, '.') || ' sin log o respaldo ya existe');
  end if;

  -- (c) Primero el trigger: desde aqui la carga de sobres ya no alimenta la cola
  dbms_output.put_line('=== (c) Trigger');
  dr('TRIGGER', 'TRG_VTA_FACOPRD_CIERRE_AI');

  -- (d) Paquetes (v2 y v1) y vista de v1
  dbms_output.put_line('=== (d) Paquetes y vista');
  dr('PACKAGE', 'PKG_F8_CIERRE_AUTO');
  dr('PACKAGE', 'PKG_F8_COMPENSA_DI_AUTO');
  dr('PACKAGE', 'PKG_F8_FACO_CIERRE_AUTO');
  dr('PACKAGE', 'PKG_F8_FACO_COMPENSA_DI');
  dr('VIEW',    'VTA_FACOV_CAJAS_CIERRE');

  -- (e) Tablas y secuencias (los grants se van con el objeto)
  dbms_output.put_line('=== (e) Tablas y secuencias');
  dr('TABLE',    'VTA_FACOPRD_CIERRE');
  dr('TABLE',    'VTA_FACOLOG_CIERRE_AUTO');
  dr('SEQUENCE', 'SEQ_VTA_FACOPRD_CIERRE');
  dr('SEQUENCE', 'SEQ_VTA_FACOLOG_CIERRE_AUTO');

  -- (f) Parametros 1502 del modelo anterior (v1, v2 y YZ). Los de la DI
  --     (CA_DI_*, CA_DECIMAL) se vuelven a crear en 03_parametros.sql.
  dbms_output.put_line('=== (f) Parametros 1502');
  ej('delete VTA_FACOPARAM 1502 CA_%',
     q'[delete from VTA_FACOPARAM where vta_ccodtipo = 1502 and trim(vta_ccodigo) like 'CA\_%' escape '\']');

  -- (g) Opcion 1515 (Cerrar Terminal desde Form43 de la v2). El Form43
  --     vigente (original + una linea) no la usa.
  dbms_output.put_line('=== (g) Opcion 1515');
  ej('delete VTA_FACORELPERMEN 1515', 'delete from VTA_FACORELPERMEN where mnu_codigo = 1515');
  ej('delete VTA_FACOMENU 1515',      'delete from VTA_FACOMENU where mnu_codigo = 1515');

  commit;
  dbms_output.put_line('=== Fin parte 1 (commit)');
end;
/

-- ---------------------------------------------------------------------
-- PARTE 2: sinonimos de UINTRANETTS (como DBA). Ejecutar solo los que
-- aparecieron en 00_prechecks consulta 4. Los que no existen dan ORA-01434
-- y se pueden ignorar.
-- ---------------------------------------------------------------------
-- drop synonym UINTRANETTS.PKG_F8_CIERRE_AUTO;
-- drop synonym UINTRANETTS.PKG_F8_COMPENSA_DI_AUTO;
-- drop synonym UINTRANETTS.VTA_FACOPRD_CIERRE;
-- drop synonym UINTRANETTS.VTA_FACOLOG_CIERRE_AUTO;

-- ---------------------------------------------------------------------
-- (i) Verificacion. ESPERADO:
--   consulta 1: solo VTA_FACOPRD_CIERRE_BK y VTA_FACOLOG_CIERRE_AUTO_BK
--   consulta 2: sin filas con CA_
--   consulta 3: 0 y 0
-- ---------------------------------------------------------------------
select object_name, object_type
  from user_objects
 where object_name in ('PKG_F8_FACO_CIERRE_AUTO', 'PKG_F8_FACO_COMPENSA_DI',
                       'PKG_F8_CIERRE_AUTO', 'PKG_F8_COMPENSA_DI_AUTO',
                       'VTA_FACOV_CAJAS_CIERRE', 'TRG_VTA_FACOPRD_CIERRE_AI',
                       'VTA_FACOPRD_CIERRE', 'SEQ_VTA_FACOPRD_CIERRE',
                       'VTA_FACOLOG_CIERRE_AUTO', 'SEQ_VTA_FACOLOG_CIERRE_AUTO',
                       'VTA_FACOPRD_CIERRE_BK', 'VTA_FACOLOG_CIERRE_AUTO_BK')
 order by object_name;

select trim(vta_ccodigo) parametro_1502, vta_xglosa
  from VTA_FACOPARAM where vta_ccodtipo = 1502 order by 1;

select (select count(*) from VTA_FACOMENU      where mnu_codigo = 1515) menu_1515,
       (select count(*) from VTA_FACORELPERMEN where mnu_codigo = 1515) relpermen_1515
  from dual;
