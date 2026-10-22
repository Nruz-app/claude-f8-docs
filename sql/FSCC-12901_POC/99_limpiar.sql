-- =====================================================================
-- POC FSCC-12901 - 99 Limpiar (DESARROLLO): deja el ambiente como antes del POC
-- Borra TODO lo cargado (datos de TEST copiados, dia PRD 3, sobres, cola,
-- DI, conceptos, log), restaura CA_DIAS y borra las tablas VTA_FACOPOC_*.
-- Los local-dia del POC (2026) no existian en desarrollo (01 lo verifica),
-- por eso se borran completos.
-- Revisar 07_resultados.sql ANTES: este script borra la evidencia.
-- =====================================================================

declare
  procedure borra (p_desc varchar2, p_sql varchar2) is
  begin
    execute immediate p_sql;
    dbms_output.put_line(rpad(p_desc, 34) || sql%rowcount);
  end borra;
begin
  -- Log: ejecuciones del POC y cualquier fila de los local-dia del POC
  borra('Log', 'delete from VTA_FACOLOG_CIERRE_AUTO l where l.log_ejecucion in'
     || ' (select to_number(valor) from VTA_FACOPOC_CTRL where clave in (''EJECUCION_AUTO'', ''EJECUCION_CC''))'
     || ' or exists (select 1 from VTA_FACOPOC_DIAS d where d.d_fecha = l.log_fecha_vta and d.d_local = l.log_local)');

  -- Cola y sobres
  borra('Cola', 'delete from VTA_FACOPRD_CIERRE q where q.prv_techkey in'
     || ' (select prv_techkey from VTA_FACOPRD where prv_modifpor = ''POC_FSCC12901'')');
  borra('Sobres (VTA_FACOPRD)', 'delete from VTA_FACOPRD where prv_modifpor = ''POC_FSCC12901''');

  -- DI, conceptos (SN) y glosas de los local-dia del POC
  borra('Movimientos (VTA_FACOMOVDET)', 'delete from VTA_FACOMOVDET m where exists'
     || ' (select 1 from VTA_FACOPOC_DIAS d where d.d_fecha = m.mov_fecha and d.d_local = m.mov_local)');
  borra('Glosas (VTA_FACOCOMPDES)', 'delete from VTA_FACOCOMPDES c where exists'
     || ' (select 1 from VTA_FACOPOC_DIAS d where d.d_fecha = c.cpd_fecha and d.d_local = c.cpd_local)');

  -- Datos de venta copiados / creados
  borra('Tarjetas (VTA_FACOTARJ)', 'delete from VTA_FACOTARJ t where exists'
     || ' (select 1 from VTA_FACOPOC_DIAS d where d.d_fecha = t.vta_fecha and d.d_local = t.vta_local)');
  borra('Detalle Z (VTA_FACOZZZ)', 'delete from VTA_FACOZZZ where rec_techkey between 900000000 and 999999999');
  borra('Libro de ventas (VTA_FACOLIBVTA)', 'delete from VTA_FACOLIBVTA where vta_techkey between 900000000 and 999999999');
  borra('Cierres Y (VTA_FACOTERMSTATY)', 'delete from VTA_FACOTERMSTATY y where exists'
     || ' (select 1 from VTA_FACOPOC_DIAS d where d.d_fecha = y.ter_fecha and d.d_local = y.ter_local)');

  -- CA_DIAS original
  borra('CA_DIAS restaurado', 'update VTA_FACOPARAM set vta_xglosa ='
     || ' (select valor from VTA_FACOPOC_CTRL where clave = ''CA_DIAS_ORIG'')'
     || ' where vta_ccodtipo = 1502 and trim(vta_ccodigo) = ''CA_DIAS'''
     || ' and exists (select 1 from VTA_FACOPOC_CTRL where clave = ''CA_DIAS_ORIG'')');
  commit;
end;
/

-- Verificacion (esperado: todo en 0 y CA_DIAS con su valor original, normalmente 30)
select (select count(*) from VTA_FACOPRD where prv_modifpor = 'POC_FSCC12901') sobres,
       (select count(*) from VTA_FACOPRD_CIERRE) cola,
       (select count(*) from VTA_FACOTERMSTATY where ter_fecha >= to_date('20260101','yyyymmdd')) y_2026,
       (select count(*) from VTA_FACOLIBVTA where vta_techkey between 900000000 and 999999999) libvta,
       (select count(*) from VTA_FACOZZZ where rec_techkey between 900000000 and 999999999) zzz,
       (select max(vta_xglosa) from VTA_FACOPARAM where vta_ccodtipo = 1502 and trim(vta_ccodigo) = 'CA_DIAS') ca_dias
  from dual;

-- Borrar las tablas del POC (despues de ver la verificacion)
drop table VTA_FACOPOC_RESP_Y;
drop table VTA_FACOPOC_PRD3;
drop table VTA_FACOPOC_CASOS;
drop table VTA_FACOPOC_DIAS;
drop table VTA_FACOPOC_CTRL;
