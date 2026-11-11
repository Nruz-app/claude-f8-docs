-- =====================================================================
-- FCDVT-14 + FSCC-12901 - Sesion "crear Y con la carga masiva y
-- compensarla con DI" - py9: limpiar para repetir la prueba.
-- MODIFICA DATOS: lo ejecuta el usuario, en TEST, revisando antes el
-- SELECT de control. xintec-nruz 10-11-2026
--
-- Fecha 09-11-2026, local 5, terminales 1 a 4. Borra:
--   1) los sobres de prueba (los 8 numeros del LEEME);
--   2) las DI automaticas y su observacion;
--   3) lo que grabo Cargar (Form174) en los grupos GRABADO del dia:
--      la zzz de los techkeys de la libvta 'F8'/'Y', esa libvta, las
--      termstaty del dia y la termstat con la glosa 'CARGA MASIVA DE
--      CIERRE Z - CARGA <n>' (las precreadas en -1 se conservan);
--   4) el log de la DI del dia;
-- y deja los grupos de la carga en CARGADO, para poder volver a
-- ejecutar Cargar (o correr de nuevo Buscar + Cargar, que genera otro
-- numero de carga).
--
-- OJO: Cargar REEMPLAZA, asi que lo que habia antes en cada terminal-dia
-- NO se repone (igual que 98_limpia_prueba.sql). Usar solo con
-- terminales exclusivas de la prueba (py0 sin filas al empezar).
-- Primero con v_ejecutar = 'N' (solo cuenta) y despues con 'S'.
-- NO es para produccion.
-- =====================================================================
set serveroutput on

declare
  v_fecha    date   := to_date('20261109', 'yyyymmdd');  -- EDITAR: fecha de la prueba
  v_local    number := 5;                                -- EDITAR: local de la prueba
  v_ejecutar varchar2(1) := 'N';                          -- EDITAR: 'N' solo cuenta, 'S' borra

  type t_num is table of number index by pls_integer;
  v_terms t_num;

  v_n number;

  procedure say (p_txt in varchar2) is
  begin
    dbms_output.put_line(p_txt);
  end;
begin
  v_terms := t_num(1, 2, 3, 4);                           -- EDITAR: terminales de la prueba

  -- Control previo (repetir los conteos al final: todo 0)
  select count(*) into v_n from vta_FACOprd p
   where p.prv_fechavta = v_fecha and p.prv_local = v_local
     and p.prv_terminal member of v_terms
     and p.prv_tiporec = 'F8';
  say('PRD      (sobres F8 del dia):      ' || v_n);
  select count(*) into v_n from vta_FACOmovdet
   where mov_fecha = v_fecha and mov_local = v_local
     and mov_terminal member of v_terms
     and mov_tipomov = 'DI' and mov_hechopor = 'PROC_DI_AUTO';
  say('MOVDET   (DI automaticas):        ' || v_n);
  select count(*) into v_n from vta_FACOcompdes
   where cpd_fecha = v_fecha and cpd_local = v_local
     and cpd_terminal member of v_terms
     and cpd_tipmov = 'DI';
  say('COMPDES  (observaciones):         ' || v_n);
  select count(*) into v_n from vta_FACOlibvta
   where vta_fecha_venta = v_fecha and vta_local = v_local
     and vta_terminal member of v_terms
     and vta_tiporeg in ('F8', 'Y');
  say('LIBVTA   (F8/Y del dia):          ' || v_n);
  select count(*) into v_n from vta_FACOtermstaty
   where ter_fecha = v_fecha and ter_local = v_local
     and ter_terminal member of v_terms;
  say('TERMSTATY (del dia):              ' || v_n);
  select count(*) into v_n from vta_FACOLOG_COMPENSA_DI
   where log_fecha_vta = v_fecha and log_local = v_local
     and log_terminal member of v_terms;
  say('LOG DI   (compensacion):          ' || v_n);

  say('--------------------------------------------------');
  if v_ejecutar <> 'S' then
    say('v_ejecutar = N: solo conteo, no se borro nada.');
    return;
  end if;

  -- 1. Sobres de la prueba (los 8 numeros del LEEME)
  delete from vta_FACOprd
   where prv_fechavta = v_fecha and prv_local = v_local
     and prv_terminal member of v_terms
     and prv_sobre in (501110901, 501110902, 502110901, 502110902,
                       503110901, 503110902, 504110901, 504110902);
  say('1. Sobres borrados: ' || sql%rowcount);

  -- 2. DI automaticas y su observacion
  delete from vta_FACOmovdet
   where mov_fecha = v_fecha and mov_local = v_local
     and mov_terminal member of v_terms
     and mov_tipomov = 'DI' and mov_hechopor = 'PROC_DI_AUTO';
  say('2. DI borradas: ' || sql%rowcount);

  delete from vta_FACOcompdes
   where cpd_fecha = v_fecha and cpd_local = v_local
     and cpd_terminal member of v_terms
     and cpd_tipmov = 'DI'
     and cpd_obs in ('COMPENSACION AUTOMATICA DI',
                     'COMPENSACION AUTOMATICA DIFERENCIA DE DI');
  say('   Observaciones borradas: ' || sql%rowcount);

  -- 3. Lo grabado por Cargar (Form174): primero la zzz, por techkey
  delete from vta_FACOzzz
   where rec_techkey in (select vta_techkey from vta_FACOlibvta
                          where vta_fecha_venta = v_fecha
                            and vta_local = v_local
                            and vta_terminal member of v_terms
                            and vta_tiporeg in ('F8', 'Y')
                            and vta_techkey is not null);
  say('3. ZZZ borradas: ' || sql%rowcount);

  delete from vta_FACOlibvta
   where vta_fecha_venta = v_fecha and vta_local = v_local
     and vta_terminal member of v_terms
     and vta_tiporeg in ('F8', 'Y');
  say('   LIBVTA F8/Y borradas: ' || sql%rowcount);

  -- Las termstaty del dia se borran todas (la caja era exclusiva de la
  -- prueba; py0 consulta 5 tenia que dar sin filas al empezar)
  delete from vta_FACOtermstaty
   where ter_fecha = v_fecha and ter_local = v_local
     and ter_terminal member of v_terms;
  say('   TERMSTATY borradas: ' || sql%rowcount);

  -- La termstat solo si la CREO la carga (glosa con el numero); las
  -- precreadas en -1, sin glosa, se conservan
  delete from vta_FACOtermstat
   where ter_fecha = v_fecha and ter_local = v_local
     and ter_terminal member of v_terms
     and ter_notas like 'CARGA MASIVA DE CIERRE Z - CARGA %';
  say('   TERMSTAT (creadas por la carga) borradas: ' || sql%rowcount);

  -- 4. Log de la DI del dia
  delete from VTA_FACOLOG_COMPENSA_DI
   where log_fecha_vta = v_fecha and log_local = v_local
     and log_terminal member of v_terms;
  say('4. LOG DI borradas: ' || sql%rowcount);

  -- 5. Los grupos GRABADO quedan en CARGADO (como 98_limpia_prueba.sql)
  update VTA_FACOCARGA_YZ_RES
     set res_estado  = 'CARGADO',
         res_mensaje = 'Limpiado con py9_limpiar.sql'
   where res_fecha = v_fecha and res_local = v_local
     and res_terminal member of v_terms
     and res_estado = 'GRABADO';
  say('5. Grupos pasados a CARGADO: ' || sql%rowcount);

  commit;
  say('Borrado y confirmado (commit).');
exception
  when others then
    dbms_output.put_line('ERROR: ' || sqlerrm);
    raise;
end;
/
