-- =====================================================================
-- FCDVT-14 - Paso 98: limpia en TEST lo que grabo Cargar (PKG_F8_GRABA_MASIVA_YZ.prc_graba)
-- xintec-nruz 04-11-2026
--
-- Para repetir una prueba de Cargar. Por cada grupo GRABADO de la carga
-- del bloque EDITAR (fecha / local / terminal de VTA_<pfx>CARGA_YZ_RES)
-- borra:
--   - la zzz de los techkeys de la libvta 'F8' / 'Y' del terminal-dia;
--   - la libvta 'F8' / 'Y' del terminal-dia;
--   - las termstaty del dia con la glosa 'CARGA MASIVA DE CIERRE Y - CARGA <n>';
--   - la termstat con la glosa 'CARGA MASIVA DE CIERRE Z - CARGA <n>'
--     (las precreadas en -1 no tienen esa glosa y se conservan).
-- Y deja el grupo en CARGADO, para poder volver a ejecutar Cargar.
--
-- OJO: Cargar REEMPLAZA. Si el terminal-dia tenia una Z o unas Y antes de
-- Cargar, ya no estan (las borro el grabado) y este script no las repone.
-- Usarlo solo con terminales que estaban sin cierres (por ejemplo, el local
-- 5 del 16-10-2026 de ejemplo_carga_Y_FACO_20.csv).
--
-- Primero con v_ejecutar = 'N' (solo cuenta) y despues con 'S'.
-- NO es para produccion.
-- =====================================================================
set serveroutput on

declare
  v_prefijo  varchar2(10) := 'FACO';   -- EDITAR: prefijo del pais
  v_carga    number       := 0;        -- EDITAR: numero de carga (MsgBox de Form174)
  v_ejecutar varchar2(1)  := 'N';      -- EDITAR: 'N' solo cuenta, 'S' borra
  v_p        varchar2(10) := upper(trim(v_prefijo));

  type t_fec is table of date index by pls_integer;
  type t_num is table of number index by pls_integer;
  v_fechas  t_fec;
  v_locales t_num;
  v_terms   t_num;
  v_n       number;

  function r (p_sql in varchar2) return varchar2 is
  begin
    return replace(p_sql, '{P}', v_p);
  end r;
begin
  if v_carga = 0 then
    raise_application_error(-20001, 'Completar v_carga en el bloque EDITAR');
  end if;

  execute immediate r(
    q'[select res_fecha, res_local, res_terminal
         from VTA_{P}CARGA_YZ_RES
        where res_carga = :1 and res_estado = 'GRABADO'
        order by 1, 2, 3]')
    bulk collect into v_fechas, v_locales, v_terms using v_carga;
  dbms_output.put_line('Carga ' || v_carga || ': ' || v_fechas.count || ' grupo(s) GRABADO');

  for g in 1 .. v_fechas.count loop
    execute immediate r(
      q'[select count(*) from VTA_{P}LIBVTA
          where vta_fecha_venta = :1 and vta_local = :2 and vta_terminal = :3
            and vta_tiporeg in ('F8', 'Y')]')
      into v_n using v_fechas(g), v_locales(g), v_terms(g);
    dbms_output.put_line(to_char(v_fechas(g), 'dd-mm-yyyy') || ' L' || v_locales(g)
                         || ' T' || v_terms(g) || ': ' || v_n || ' libvta F8/Y');

    if v_ejecutar = 'S' then
      execute immediate r(
        q'[delete from VTA_{P}ZZZ
            where rec_techkey in (select vta_techkey from VTA_{P}LIBVTA
                                   where vta_fecha_venta = :1 and vta_local = :2
                                     and vta_terminal = :3 and vta_tiporeg in ('F8', 'Y')
                                     and vta_techkey is not null)]')
        using v_fechas(g), v_locales(g), v_terms(g);
      execute immediate r(
        q'[delete from VTA_{P}LIBVTA
            where vta_fecha_venta = :1 and vta_local = :2 and vta_terminal = :3
              and vta_tiporeg in ('F8', 'Y')]')
        using v_fechas(g), v_locales(g), v_terms(g);
      execute immediate r(
        q'[delete from VTA_{P}TERMSTATY
            where ter_fecha = :1 and ter_local = :2 and ter_terminal = :3
              and ter_notas = :4]')
        using v_fechas(g), v_locales(g), v_terms(g),
              'CARGA MASIVA DE CIERRE Y - CARGA ' || v_carga;
      execute immediate r(
        q'[delete from VTA_{P}TERMSTAT
            where ter_fecha = :1 and ter_local = :2 and ter_terminal = :3
              and ter_notas = :4]')
        using v_fechas(g), v_locales(g), v_terms(g),
              'CARGA MASIVA DE CIERRE Z - CARGA ' || v_carga;
      execute immediate r(
        q'[update VTA_{P}CARGA_YZ_RES
              set res_estado = 'CARGADO',
                  res_mensaje = 'Limpiado con 98_limpia_prueba.sql'
            where res_carga = :1 and res_fecha = :2
              and res_local = :3 and res_terminal = :4]')
        using v_carga, v_fechas(g), v_locales(g), v_terms(g);
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
