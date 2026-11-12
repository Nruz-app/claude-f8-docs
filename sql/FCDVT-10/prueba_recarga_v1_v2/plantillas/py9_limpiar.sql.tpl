-- =====================================================================
-- FCDVT-10 (HU-03) - Prueba "recarga v1 / v2" de la carga masiva de
-- Tottus Chile (SFCL) - py9: limpiar para repetir la prueba.
-- MODIFICA DATOS: lo ejecuta el usuario, en TEST, revisando antes el
-- conteo (v_ejecutar = 'N'). xintec-nruz 12-11-2026
-- GENERADO por arma_prueba.py desde plantillas/py9_limpiar.sql.tpl.
--
-- Fecha {FECHA_DMY}, local {LOCAL}, terminales {TERMS}. Borra lo que
-- grabo Cargar (v1 y v2) en esas terminales ese dia:
--   1) la zzz de los techkeys de la libvta 'F8'/'Y' y esa libvta;
--   2) todas las termstaty del dia (las terminales eran libres: py0 7);
--   3) la termstat con la glosa 'CARGA MASIVA DE CIERRE Z - CARGA <n>'
--      (una precreada sin glosa se conserva);
--   4) lo que creo TRG_VTA_SFCLZZZ_I: VTA_SFCLTARJ 2001-2999 y
--      movimientos 'AL' del dia (py0 7 exigia que no hubiera);
--   5) deja los grupos GRABADO de las cargas del dia en CARGADO.
-- Para repetir conviene hacer de nuevo Buscar + Cargar con v1 y despues
-- con v2 (numeros de carga nuevos).
-- Primero con v_ejecutar = 'N' (solo cuenta) y despues con 'S'.
-- NO es para produccion.
-- =====================================================================
set serveroutput on

declare
  v_fecha    date        := to_date('{FECHA}', 'yyyymmdd');
  v_local    number      := {LOCAL};
  v_ejecutar varchar2(1) := 'N';                       -- EDITAR: 'N' solo cuenta, 'S' borra
  v_n        number;

  procedure say (p_txt in varchar2) is
  begin
    dbms_output.put_line(p_txt);
  end;
begin
  select count(*) into v_n from VTA_SFCLLIBVTA
   where vta_fecha_venta = v_fecha and vta_local = v_local
     and vta_terminal in ({TERMS}) and vta_tiporeg in ('F8', 'Y');
  say('LIBVTA F8/Y:        ' || v_n);
  select count(*) into v_n from VTA_SFCLTERMSTATY
   where ter_fecha = v_fecha and ter_local = v_local and ter_terminal in ({TERMS});
  say('TERMSTATY:          ' || v_n);
  select count(*) into v_n from VTA_SFCLTERMSTAT
   where ter_fecha = v_fecha and ter_local = v_local and ter_terminal in ({TERMS})
     and ter_notas like 'CARGA MASIVA DE CIERRE Z - CARGA %';
  say('TERMSTAT (carga):   ' || v_n);
  select count(*) into v_n from VTA_SFCLTARJ
   where vta_fecha = v_fecha and vta_local = v_local and vta_terminal in ({TERMS})
     and vta_cod_tarj between 2001 and 2999;
  say('TARJ 2001-2999:     ' || v_n);
  select count(*) into v_n from VTA_SFCLMOVDET
   where mov_fecha = v_fecha and mov_local = v_local and mov_terminal in ({TERMS})
     and mov_tipomov = 'AL';
  say('MOVDET AL:          ' || v_n);
  select count(*) into v_n from VTA_SFCLCARGA_YZ_RES
   where res_fecha = v_fecha and res_local = v_local and res_terminal in ({TERMS})
     and res_estado = 'GRABADO';
  say('Grupos GRABADO:     ' || v_n);
  say('--------------------------------------------------');

  if v_ejecutar <> 'S' then
    say('v_ejecutar = N: solo conteo, no se borro nada.');
    return;
  end if;

  delete from VTA_SFCLZZZ
   where rec_techkey in (select vta_techkey from VTA_SFCLLIBVTA
                          where vta_fecha_venta = v_fecha and vta_local = v_local
                            and vta_terminal in ({TERMS})
                            and vta_tiporeg in ('F8', 'Y')
                            and vta_techkey is not null);
  say('1. ZZZ borradas: ' || sql%rowcount);

  delete from VTA_SFCLLIBVTA
   where vta_fecha_venta = v_fecha and vta_local = v_local
     and vta_terminal in ({TERMS}) and vta_tiporeg in ('F8', 'Y');
  say('   LIBVTA borradas: ' || sql%rowcount);

  delete from VTA_SFCLTERMSTATY
   where ter_fecha = v_fecha and ter_local = v_local and ter_terminal in ({TERMS});
  say('2. TERMSTATY borradas: ' || sql%rowcount);

  delete from VTA_SFCLTERMSTAT
   where ter_fecha = v_fecha and ter_local = v_local and ter_terminal in ({TERMS})
     and ter_notas like 'CARGA MASIVA DE CIERRE Z - CARGA %';
  say('3. TERMSTAT borradas: ' || sql%rowcount);

  delete from VTA_SFCLTARJ
   where vta_fecha = v_fecha and vta_local = v_local and vta_terminal in ({TERMS})
     and vta_cod_tarj between 2001 and 2999;
  say('4. TARJ borradas: ' || sql%rowcount);

  delete from VTA_SFCLMOVDET
   where mov_fecha = v_fecha and mov_local = v_local and mov_terminal in ({TERMS})
     and mov_tipomov = 'AL';
  say('   MOVDET AL borradas: ' || sql%rowcount);

  update VTA_SFCLCARGA_YZ_RES
     set res_estado  = 'CARGADO',
         res_mensaje = 'Limpiado con py9_limpiar.sql'
   where res_fecha = v_fecha and res_local = v_local and res_terminal in ({TERMS})
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
