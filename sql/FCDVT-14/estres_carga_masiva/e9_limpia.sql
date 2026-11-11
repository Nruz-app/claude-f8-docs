-- =====================================================================
-- FCDVT-14 - Prueba de estres de la carga masiva (Form174).
-- e9: limpiar lo que la prueba grabo. MODIFICA DATOS: lo ejecuta el
-- usuario, en TEST, revisando antes el conteo de control.
-- xintec-nruz 10-11-2026
--
-- Borra, de las fechas objetivo (agosto 2026 sin los dias 13, 14 y 29,
-- y el 07-11-2026; local 5):
--   1) las filas de las tablas de carga (CARGA_YZ_LOG, _DET y _RES);
--   2) lo que grabo Cargar (Form174) en esas fechas: la zzz por techkey,
--      la libvta 'F8'/'Y', las termstaty del dia y la termstat con la
--      glosa 'CARGA MASIVA DE CIERRE Z - CARGA <n>' (las precreadas en
--      -1, sin glosa, se conservan).
-- El 07-11-2026 solo toca la terminal 1; en agosto, las terminales
-- 1 a 4 (igual que la prueba). Cargar REEMPLAZA cada grupo, asi que lo
-- que habia antes en cada terminal-dia NO se repone (igual que
-- py9_limpiar.sql de la s5): usar solo si e0 dio las fechas limpias al
-- empezar la prueba.
-- Primero con v_ejecutar = 'N' (solo cuenta) y despues con 'S'.
-- NO es para produccion. Ejecutar con usuario con DML en estas tablas
-- (el usuario de aplicacion de test puede modificar).
-- =====================================================================
set serveroutput on
set linesize 90

declare
  v_ejecutar varchar2(1) := 'N';   -- EDITAR: 'N' solo cuenta, 'S' borra
  v_local    number      := 5;

  type t_dates is table of date;
  v_fechas t_dates;

  v_fecha date;
  v_n     number;
  v_tmin  number;
  v_tmax  number;

  -- Totales acumulados (control y borrado)
  v_res   number := 0;
  v_det   number := 0;
  v_log   number := 0;
  v_zzz   number := 0;
  v_lib   number := 0;
  v_tsy   number := 0;
  v_ts    number := 0;

  procedure say (p_txt in varchar2) is
  begin
    dbms_output.put_line(p_txt);
  end;
begin
  -- Las mismas fechas que e0_prechecks.sql: agosto sin 13/14/29 + 07-11
  select to_date('20260801','yyyymmdd') + level - 1
    bulk collect into v_fechas
    from dual
   where level not in (13, 14, 29)
  connect by level <= 31;
  v_fechas.extend;
  v_fechas(v_fechas.count) := to_date('20261107','yyyymmdd');

  -- Control previo: una vez por fecha (los terminal 1 a 4)
  for i in 1 .. v_fechas.count loop
    select count(*) into v_n from VTA_FACOCARGA_YZ_RES
     where res_fecha = v_fechas(i) and res_local = v_local
       and res_terminal in (1, 2, 3, 4);
    v_res := v_res + v_n;
  end loop;
  say('RES       (cargas de la prueba):     ' || v_res);
  for i in 1 .. v_fechas.count loop
    select count(*) into v_n from VTA_FACOCARGA_YZ_DET
     where det_fecha = v_fechas(i) and det_local = v_local
       and det_terminal in (1, 2, 3, 4);
    v_det := v_det + v_n;
  end loop;
  say('DET       (lineas de carga):         ' || v_det);
  for i in 1 .. v_fechas.count loop
    select count(*) into v_n from VTA_FACOCARGA_YZ_LOG
     where log_carga in (select res_carga from VTA_FACOCARGA_YZ_RES
                          where res_fecha = v_fechas(i)
                            and res_local = v_local
                            and res_terminal in (1, 2, 3, 4));
    v_log := v_log + v_n;
  end loop;
  say('LOG       (log de las cargas):       ' || v_log);
  for i in 1 .. v_fechas.count loop
    select count(*) into v_n from vta_FACOlibvta
     where vta_fecha_venta = v_fechas(i) and vta_local = v_local
       and vta_terminal in (1, 2, 3, 4) and vta_tiporeg in ('F8', 'Y');
    v_lib := v_lib + v_n;
  end loop;
  say('LIBVTA    (F8/Y del estres):         ' || v_lib);
  for i in 1 .. v_fechas.count loop
    select count(*) into v_n from vta_FACOzzz
     where rec_techkey in (select vta_techkey from vta_FACOlibvta
                            where vta_fecha_venta = v_fechas(i)
                              and vta_local = v_local
                              and vta_terminal in (1, 2, 3, 4)
                              and vta_tiporeg in ('F8', 'Y')
                              and vta_techkey is not null);
    v_zzz := v_zzz + v_n;
  end loop;
  say('ZZZ       (de los techkeys):         ' || v_zzz);
  for i in 1 .. v_fechas.count loop
    select count(*) into v_n from vta_FACOtermstaty
     where ter_fecha = v_fechas(i) and ter_local = v_local
       and ter_terminal in (1, 2, 3, 4);
    v_tsy := v_tsy + v_n;
  end loop;
  say('TERMSTATY (del estres):              ' || v_tsy);

  say('--------------------------------------------------');
  if v_ejecutar <> 'S' then
    say('v_ejecutar = N: solo conteo, no se borro nada.');
    return;
  end if;

  -- Reinicia los acumuladores: ahora van a llevar lo borrado
  v_res := 0; v_det := 0; v_log := 0; v_zzz := 0;
  v_lib := 0; v_tsy := 0; v_ts := 0;

  -- Borra fecha por fecha (el 07-11 solo toca la terminal 1)
  for i in 1 .. v_fechas.count loop
    v_fecha := v_fechas(i);
    if v_fecha = to_date('20261107','yyyymmdd') then
      v_tmin := 1; v_tmax := 1;
    else
      v_tmin := 1; v_tmax := 4;
    end if;

    -- 1. Tablas de carga: primero el log (por res_carga), luego DET y RES
    delete from VTA_FACOCARGA_YZ_LOG
     where log_carga in (select res_carga from VTA_FACOCARGA_YZ_RES
                          where res_fecha = v_fecha and res_local = v_local
                            and res_terminal between v_tmin and v_tmax);
    v_log := v_log + sql%rowcount;

    delete from VTA_FACOCARGA_YZ_DET
     where det_fecha = v_fecha and det_local = v_local
       and det_terminal between v_tmin and v_tmax;
    v_det := v_det + sql%rowcount;

    delete from VTA_FACOCARGA_YZ_RES
     where res_fecha = v_fecha and res_local = v_local
       and res_terminal between v_tmin and v_tmax;
    v_res := v_res + sql%rowcount;

    -- 2. Lo grabado por Cargar (Form174): primero la zzz, por techkey
    delete from vta_FACOzzz
     where rec_techkey in (select vta_techkey from vta_FACOlibvta
                            where vta_fecha_venta = v_fecha
                              and vta_local = v_local
                              and vta_terminal between v_tmin and v_tmax
                              and vta_tiporeg in ('F8', 'Y')
                              and vta_techkey is not null);
    v_zzz := v_zzz + sql%rowcount;

    delete from vta_FACOlibvta
     where vta_fecha_venta = v_fecha and vta_local = v_local
       and vta_terminal between v_tmin and v_tmax and vta_tiporeg in ('F8', 'Y');
    v_lib := v_lib + sql%rowcount;

    -- Las termstaty del dia se borran todas (la caja es exclusiva de la
    -- prueba; e0 consultas 7 y 8 tenian que dar sin filas al empezar)
    delete from vta_FACOtermstaty
     where ter_fecha = v_fecha and ter_local = v_local
       and ter_terminal between v_tmin and v_tmax;
    v_tsy := v_tsy + sql%rowcount;

    -- La termstat solo si la CREO la carga (glosa con el numero); las
    -- precreadas en -1, sin glosa, se conservan
    delete from vta_FACOtermstat
     where ter_fecha = v_fecha and ter_local = v_local
       and ter_terminal between v_tmin and v_tmax
       and ter_notas like 'CARGA MASIVA DE CIERRE Z - CARGA %';
    v_ts := v_ts + sql%rowcount;
  end loop;

  say('Borrado:');
  say('  RES       : ' || v_res);
  say('  DET       : ' || v_det);
  say('  LOG       : ' || v_log);
  say('  ZZZ       : ' || v_zzz);
  say('  LIBVTA    : ' || v_lib);
  say('  TERMSTATY : ' || v_tsy);
  say('  TERMSTAT  : ' || v_ts);
  say('Fechas procesadas: ' || v_fechas.count);

  commit;
  say('Borrado y confirmado (commit).');
exception
  when others then
    dbms_output.put_line('ERROR: ' || sqlerrm);
    raise;
end;
/

exit
