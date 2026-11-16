-- =====================================================================
-- FCDVT-259 - pruebas/d02: SOLO TEST. Deja el terminal 2 del
-- 27-10-2026 (local 5) como un terminal FACO cerrado solo con Y
-- xintec-nruz 16-11-2026
--
-- Despues de grabar d01_carga_27-10.csv (Buscar + Cargar), borra la Z de
-- la libvta del terminal 2 ('F8') y su zzz. Las tres Y quedan y la termstat
-- de la Z queda en -1, como en un terminal FACO que se cierra solo con Y
-- (la Z precreada y sin fila 'F8'). Asi Form176 (Exportar) debe ARMAR la Z
-- del terminal 2 con la suma de sus Y.
--
-- Primero con v_ejecutar = 'N' (solo cuenta) y despues con 'S'.
-- NO es para produccion.
-- =====================================================================
set serveroutput on

declare
  v_fecha    date         := to_date('27-10-2026', 'dd-mm-yyyy');  -- EDITAR si se cambio la fecha
  v_local    number       := 5;
  v_terminal number       := 2;
  v_ejecutar varchar2(1)  := 'N';      -- EDITAR: 'N' solo cuenta, 'S' borra
  v_n        number;
begin
  select count(*)
    into v_n
    from VTA_FACOLIBVTA
   where vta_fecha_venta = v_fecha and vta_local = v_local
     and vta_terminal = v_terminal and vta_tiporeg = 'F8';
  dbms_output.put_line('libvta F8 del terminal ' || v_terminal || ': ' || v_n || ' (esperado 1)');

  select count(*)
    into v_n
    from VTA_FACOLIBVTA
   where vta_fecha_venta = v_fecha and vta_local = v_local
     and vta_terminal = v_terminal and vta_tiporeg = 'Y';
  dbms_output.put_line('libvta Y del terminal ' || v_terminal || ': ' || v_n || ' (esperado 3; no se tocan)');

  if v_ejecutar = 'S' then
    delete from VTA_FACOZZZ
     where rec_techkey in (select vta_techkey from VTA_FACOLIBVTA
                            where vta_fecha_venta = v_fecha and vta_local = v_local
                              and vta_terminal = v_terminal and vta_tiporeg = 'F8'
                              and vta_techkey is not null);
    dbms_output.put_line('zzz de la Z borrada: ' || sql%rowcount);
    delete from VTA_FACOLIBVTA
     where vta_fecha_venta = v_fecha and vta_local = v_local
       and vta_terminal = v_terminal and vta_tiporeg = 'F8';
    dbms_output.put_line('libvta F8 borrada: ' || sql%rowcount);
    commit;
    dbms_output.put_line('Confirmado (commit). La termstat de la Z queda como estaba (-1).');
  else
    dbms_output.put_line('Solo conteo (v_ejecutar = N): no se borro nada.');
  end if;
end;
/
