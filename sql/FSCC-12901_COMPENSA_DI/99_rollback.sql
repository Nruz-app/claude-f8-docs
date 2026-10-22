-- =====================================================================
-- FSCC-12901 COMPENSA_DI - Paso 99: vuelta atras (ejecutar POR PARTES)
-- xintec-nruz 19-10-2026
-- Conectado como el duenio. Sin variables de sustitucion: los valores a
-- completar estan marcados con EDITAR.
-- =====================================================================

-- 1) Apagar la compensacion automatica (sin desinstalar). Form133 seguira
--    llamando al paquete, que respondera INACTIVO.
update VTA_FACOPARAM set vta_xglosa = 'N'
 where vta_ccodtipo = 1502 and trim(vta_ccodigo) = 'CA_DI_ACTIVO';
commit;

-- 2) (Opcional) Borrar las DI automaticas de un rango de fechas de venta,
--    solo en cajas ABIERTAS (una caja cerrada pudo haberse contabilizado).
declare
  v_desde date := to_date('20260101','yyyymmdd');   -- EDITAR
  v_hasta date := to_date('20261231','yyyymmdd');   -- EDITAR
begin
  delete from VTA_FACOCOMPDES c
   where c.cpd_fecha between v_desde and v_hasta
     and c.cpd_tipmov = 'DI'
     and c.cpd_obs in ('COMPENSACION AUTOMATICA DI', 'COMPENSACION AUTOMATICA DIFERENCIA DE DI')
     and exists (select 1 from VTA_FACOTERMSTATY y
                  where y.ter_fecha = c.cpd_fecha and y.ter_local = c.cpd_local
                    and y.ter_terminal = c.cpd_terminal and y.ter_cierrey = c.cpd_cierrey
                    and y.ter_estado <= 0);
  dbms_output.put_line('Observaciones borradas: ' || sql%rowcount);

  delete from VTA_FACOMOVDET m
   where m.mov_fecha between v_desde and v_hasta
     and m.mov_tipomov = 'DI'
     and m.mov_hechopor = 'PROC_DI_AUTO'
     and exists (select 1 from VTA_FACOTERMSTATY y
                  where y.ter_fecha = m.mov_fecha and y.ter_local = m.mov_local
                    and y.ter_terminal = m.mov_terminal and y.ter_cierrey = m.mov_cierrey
                    and y.ter_estado <= 0);
  dbms_output.put_line('DI borradas: ' || sql%rowcount);
  commit;
end;
/

-- 3) Desinstalar los objetos nuevos.
--    OJO: si el exe ya llama a PKG_F8_COMPENSA_DI_CARGA, cada carga FACO
--    mostrara un error (los sobres igual quedan cargados).
-- 3a. Sinonimos (como DBA)
-- drop synonym UINTRANETTS.PKG_F8_COMPENSA_DI_CARGA;
-- drop synonym UINTRANETTS.VTA_FACOLOG_COMPENSA_DI;

-- 3b. Paquete, log y secuencia
drop package  PKG_F8_COMPENSA_DI_CARGA;
drop table    VTA_FACOLOG_COMPENSA_DI;
drop sequence SEQ_VTA_FACOLOG_COMPENSA_DI;

-- 3c. Parametros
delete from VTA_FACOPARAM
 where vta_ccodtipo = 1502
   and trim(vta_ccodigo) in ('CA_DI_ACTIVO', 'CA_DI_MIN', 'CA_DI_MAX', 'CA_DECIMAL');
commit;

-- 3d. (Opcional, cuando ya no hagan falta) respaldos de la v2 creados por 01
-- drop table VTA_FACOPRD_CIERRE_BK;
-- drop table VTA_FACOLOG_CIERRE_AUTO_BK;

-- 3e. Verificacion (ESPERADO: sin filas)
select object_name, object_type from user_objects
 where object_name in ('PKG_F8_COMPENSA_DI_CARGA', 'VTA_FACOLOG_COMPENSA_DI',
                       'SEQ_VTA_FACOLOG_COMPENSA_DI');
