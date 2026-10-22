-- =====================================================================
-- FSCC-12901 CIERRE_DIARIO - Paso 99: vuelta atras (ejecutar POR PARTES)
-- xintec-nruz 20-10-2026
-- Conectado como el duenio. Sin variables de sustitucion: los valores a
-- completar estan marcados con EDITAR.
-- =====================================================================

-- 1) Apagar el cierre diario (sin desinstalar). Si nhal1 lo sigue llamando,
--    el proceso deja una fila INACTIVO en el log y no cierra nada.
update VTA_FACOPARAM set vta_xglosa = 'N'
 where vta_ccodtipo = 1502 and trim(vta_ccodigo) = 'CD_ACTIVO';
commit;

-- 1b. (FCDVT-56) Apagar solo la etapa SIN VENTA: las Y se siguen cerrando.
-- update VTA_FACOPARAM set vta_xglosa = 'N'
--  where vta_ccodtipo = 1502 and trim(vta_ccodigo) = 'CD_SIN_VENTA';
-- commit;

-- 2) (Opcional) Reabrir los cierres Y que cerro el proceso en un rango de
--    fechas de venta (vuelven a Pendiente, estado 0). Revisar ANTES con el
--    control: una caja cerrada pudo haberse contabilizado despues.
-- 2a. Control
select t.ter_fecha, t.ter_local, t.ter_terminal, t.ter_cierrey, t.ter_estado, t.ter_cerradopor
  from VTA_FACOTERMSTATY t
 where t.ter_fecha between to_date('20260101','yyyymmdd') and to_date('20261231','yyyymmdd')  -- EDITAR
   and t.ter_cerradopor = 'PROC_CIERRE_DIARIO'
   and t.ter_estado = 1
 order by 1, 2, 3, 4;

-- 2b. Reapertura (sin commit automatico)
update VTA_FACOTERMSTATY t
   set t.ter_estado = 0, t.ter_cerradopor = null
 where t.ter_fecha between to_date('20260101','yyyymmdd') and to_date('20261231','yyyymmdd')  -- EDITAR
   and t.ter_cerradopor = 'PROC_CIERRE_DIARIO'
   and t.ter_estado = 1;
-- commit;
-- rollback;

-- 2c. (Opcional, FCDVT-56) Reabrir las Z de terminales sin venta que cerro
--     el proceso (vuelven a Pendiente, estado -1, como la Z precreada; el
--     estado anterior exacto esta en el log: 'Z cerrada (estado anterior N)').
--     Control:
select t.ter_fecha, t.ter_local, t.ter_terminal, t.ter_estado, t.ter_cerradopor
  from VTA_FACOTERMSTAT t
 where t.ter_fecha between to_date('20260101','yyyymmdd') and to_date('20261231','yyyymmdd')  -- EDITAR
   and t.ter_cerradopor = 'PROC_CIERRE_DIARIO'
   and t.ter_estado = 1
 order by 1, 2, 3;

update VTA_FACOTERMSTAT t
   set t.ter_estado = -1, t.ter_cerradopor = null
 where t.ter_fecha between to_date('20260101','yyyymmdd') and to_date('20261231','yyyymmdd')  -- EDITAR
   and t.ter_cerradopor = 'PROC_CIERRE_DIARIO'
   and t.ter_estado = 1;
-- commit;
-- rollback;

-- 3) Desinstalar los objetos nuevos (antes, quitar la tarea de nhal1).
-- 3a. Sinonimos (como DBA, solo si se crearon con 05)
-- drop synonym UINTRANETTS.PKG_F8_CIERRE_DIARIO;
-- drop synonym UINTRANETTS.VTA_FACOLOG_CIERRE_DIARIO;

-- 3b. Paquete, log y secuencia
drop package  PKG_F8_CIERRE_DIARIO;
drop table    VTA_FACOLOG_CIERRE_DIARIO;
drop sequence SEQ_VTA_FACOLOG_CIERRE_DIARIO;

-- 3c. Parametros
delete from VTA_FACOPARAM
 where vta_ccodtipo = 1502
   and trim(vta_ccodigo) in ('CD_ACTIVO', 'CD_VAL_CHEQ', 'CD_VAL_ZZZ', 'CD_SIN_VENTA', 'CD_VAL_DOL');
commit;

-- 3d. Verificacion (ESPERADO: sin filas)
select object_name, object_type from user_objects
 where object_name in ('PKG_F8_CIERRE_DIARIO', 'VTA_FACOLOG_CIERRE_DIARIO',
                       'SEQ_VTA_FACOLOG_CIERRE_DIARIO');
