-- =====================================================================
-- FCDVT-259 - pruebas/d09: SOLO TEST. Limpia lo que dejo la
-- prueba de Exportar (Form176) en el local 5 del 27-10-2026 (terminales 1 a 3)
-- xintec-nruz 16-11-2026
--
-- Borra:
--   - la zzz de los techkeys de la libvta 'F8' / 'Y' de esos terminal-dia;
--   - la libvta 'F8' / 'Y' de esos terminal-dia;
--   - las termstaty y la termstat con glosa 'CARGA MASIVA DE CIERRE Y|Z - CARGA %'
--     (las que creo Cargar; otras se conservan).
-- Sirve despues de d02 (terminal 2 sin Z) y despues de la recarga (paso 5).
-- Usarlo solo si d00 mostro esas fechas sin cierres antes de la prueba.
-- No toca VTA_FACOCARGA_YZ_* (el historial de las cargas queda).
--
-- Primero con v_ejecutar = 'N' (solo cuenta) y despues con 'S'.
-- NO es para produccion.
-- =====================================================================
set serveroutput on

declare
  v_fecha    date         := to_date('27-10-2026', 'dd-mm-yyyy');  -- EDITAR si se cambio la fecha
  v_local    number       := 5;
  v_ejecutar varchar2(1)  := 'N';      -- EDITAR: 'N' solo cuenta, 'S' borra
  v_n        number;
begin
  select count(*) into v_n
    from VTA_FACOLIBVTA
   where vta_fecha_venta = v_fecha and vta_local = v_local
     and vta_terminal in (1, 2, 3) and vta_tiporeg in ('F8', 'Y');
  dbms_output.put_line('libvta F8/Y: ' || v_n);
  select count(*) into v_n
    from VTA_FACOTERMSTATY
   where ter_fecha = v_fecha and ter_local = v_local and ter_terminal in (1, 2, 3)
     and ter_notas like 'CARGA MASIVA DE CIERRE Y - CARGA %';
  dbms_output.put_line('termstaty de la carga masiva: ' || v_n);
  select count(*) into v_n
    from VTA_FACOTERMSTAT
   where ter_fecha = v_fecha and ter_local = v_local and ter_terminal in (1, 2, 3)
     and ter_notas like 'CARGA MASIVA DE CIERRE Z - CARGA %';
  dbms_output.put_line('termstat de la carga masiva: ' || v_n);

  if v_ejecutar = 'S' then
    delete from VTA_FACOZZZ
     where rec_techkey in (select vta_techkey from VTA_FACOLIBVTA
                            where vta_fecha_venta = v_fecha and vta_local = v_local
                              and vta_terminal in (1, 2, 3) and vta_tiporeg in ('F8', 'Y')
                              and vta_techkey is not null);
    dbms_output.put_line('zzz borradas: ' || sql%rowcount);
    delete from VTA_FACOLIBVTA
     where vta_fecha_venta = v_fecha and vta_local = v_local
       and vta_terminal in (1, 2, 3) and vta_tiporeg in ('F8', 'Y');
    dbms_output.put_line('libvta borradas: ' || sql%rowcount);
    delete from VTA_FACOTERMSTATY
     where ter_fecha = v_fecha and ter_local = v_local and ter_terminal in (1, 2, 3)
       and ter_notas like 'CARGA MASIVA DE CIERRE Y - CARGA %';
    dbms_output.put_line('termstaty borradas: ' || sql%rowcount);
    delete from VTA_FACOTERMSTAT
     where ter_fecha = v_fecha and ter_local = v_local and ter_terminal in (1, 2, 3)
       and ter_notas like 'CARGA MASIVA DE CIERRE Z - CARGA %';
    dbms_output.put_line('termstat borradas: ' || sql%rowcount);
    commit;
    dbms_output.put_line('Confirmado (commit).');
  else
    dbms_output.put_line('Solo conteo (v_ejecutar = N): no se borro nada.');
  end if;
end;
/
