-- =====================================================================
-- FCDVT-10 (HU-03) - Paso 98: limpia en TEST lo que grabo Cargar (INGRESAR)
-- Tottus Chile (SFCL)
-- xintec-nruz 11-11-2026
-- Base: docs/sql/FCDVT-14/98_limpia_prueba.sql.
--
-- Por cada grupo GRABADO con TIPO_CARGA INGRESAR de la carga del bloque
-- EDITAR borra la zzz y la libvta 'F8' / 'Y' del terminal-dia, las
-- termstaty con la glosa de la carga (incluida la Y1 automatica) y la
-- termstat con la glosa de la carga (las precreadas se conservan). Deja el
-- grupo en CARGADO para volver a ejecutar Cargar.
--
-- OJO: Cargar REEMPLAZA. Lo que el terminal-dia tenia antes no se repone.
-- Los grupos MODIFICAR no se pueden deshacer con este script (no se guarda
-- el valor anterior): se informan y se saltan.
-- Tampoco revierte lo que TRG_VTA_SFCLZZZ_I creo al insertar las Y en zzz:
-- VTA_SFCLTARJ (codigos 2001 y 2002) y VTA_SFCLMOVDET tipo 'AL'. En test,
-- revisarlos y borrarlos a mano si molestan (consulta de ejemplo al final).
-- Primero con v_ejecutar = 'N' (solo cuenta) y despues con 'S'.
-- NO es para produccion.
-- =====================================================================
set serveroutput on

declare
  v_carga    number      := 0;     -- EDITAR: numero de carga (MsgBox de Form174)
  v_ejecutar varchar2(1) := 'N';   -- EDITAR: 'N' solo cuenta, 'S' borra
  v_n        number;
begin
  if v_carga = 0 then
    raise_application_error(-20001, 'Completar v_carga en el bloque EDITAR');
  end if;

  for g in (select res_fecha, res_local, res_terminal, res_tipo_carga
              from VTA_SFCLCARGA_YZ_RES
             where res_carga = v_carga and res_estado = 'GRABADO'
             order by 1, 2, 3) loop
    if nvl(g.res_tipo_carga, 'INGRESAR') <> 'INGRESAR' then
      dbms_output.put_line(to_char(g.res_fecha, 'dd-mm-yyyy') || ' L' || g.res_local
                           || ' T' || g.res_terminal || ': ' || g.res_tipo_carga
                           || ', no se limpia');
    else
      select count(*) into v_n
        from VTA_SFCLLIBVTA
       where vta_fecha_venta = g.res_fecha and vta_local = g.res_local
         and vta_terminal = g.res_terminal and vta_tiporeg in ('F8', 'Y');
      dbms_output.put_line(to_char(g.res_fecha, 'dd-mm-yyyy') || ' L' || g.res_local
                           || ' T' || g.res_terminal || ': ' || v_n || ' libvta F8/Y');

      if v_ejecutar = 'S' then
        delete from VTA_SFCLZZZ
         where rec_techkey in (select vta_techkey from VTA_SFCLLIBVTA
                                where vta_fecha_venta = g.res_fecha and vta_local = g.res_local
                                  and vta_terminal = g.res_terminal
                                  and vta_tiporeg in ('F8', 'Y')
                                  and vta_techkey is not null);
        delete from VTA_SFCLLIBVTA
         where vta_fecha_venta = g.res_fecha and vta_local = g.res_local
           and vta_terminal = g.res_terminal and vta_tiporeg in ('F8', 'Y');
        delete from VTA_SFCLTERMSTATY
         where ter_fecha = g.res_fecha and ter_local = g.res_local
           and ter_terminal = g.res_terminal
           and ter_notas = 'CARGA MASIVA DE CIERRE Y - CARGA ' || v_carga;
        delete from VTA_SFCLTERMSTAT
         where ter_fecha = g.res_fecha and ter_local = g.res_local
           and ter_terminal = g.res_terminal
           and ter_notas = 'CARGA MASIVA DE CIERRE Z - CARGA ' || v_carga;
        update VTA_SFCLCARGA_YZ_RES
           set res_estado = 'CARGADO', res_mensaje = 'Limpiado con 98_limpia_prueba.sql'
         where res_carga = v_carga and res_fecha = g.res_fecha
           and res_local = g.res_local and res_terminal = g.res_terminal;
      end if;
    end if;
  end loop;

  if v_ejecutar = 'S' then
    commit;
    dbms_output.put_line('Borrado y confirmado (commit).');
  else
    dbms_output.put_line('Solo conteo (v_ejecutar = N): no se borro nada.');
  end if;
end;
/

-- Lo que creo el trigger de zzz para un local y fecha (solo lectura; EDITAR)
select 'TARJ' origen, vta_terminal terminal, vta_cierrey cierrey, vta_cod_tarj codigo, vta_monto_z monto
  from VTA_SFCLTARJ
 where vta_fecha = to_date('01-01-2026', 'dd-mm-yyyy') and vta_local = 0
   and vta_cod_tarj in (2001, 2002)
union all
select 'MOVDET AL', mov_terminal, mov_cierrey, null, mov_monto
  from VTA_SFCLMOVDET
 where mov_fecha = to_date('01-01-2026', 'dd-mm-yyyy') and mov_local = 0
   and mov_tipomov = 'AL'
 order by 1, 2, 3;
