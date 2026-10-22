-- =====================================================================
-- FSCC-12901 T1 + T2 (carpeta consolidada) - Paso 03c
-- Opcion 1515 Cerrar Terminal desde Consultas de Cuadratura (Form43 FACO)
-- Fuente: docs/sql/FSCC-12958/03c_permiso_cc.sql (mantener ambas copias iguales)
-- =====================================================================

-- =====================================================================
-- FSCC-12958 (HU-01-T2) Cierre de caja automatico - Falabella Colombia
-- 03c - Opcion 1515 "Cerrar Terminal desde Consulta Cuadratura" para FACO
--       (ajuste FSCC-12901 DF-SCC fila 12).
--
-- Form43 (Consultas de Cuadratura) muestra el boton "Cerrar Terminal" solo si
-- FuncBuscarOpcionCompensa(PERFILUSER, OpcionPermiteCerrarTerminalCC = 1515)
-- encuentra rel_estado = -1 en VTA_FACORELPERMEN (Modulo1.bas:1111).
-- Verificado en test (06-10-2026): la opcion existe en VTA_MENU, VTA_SOARMENU
-- y VTA_SFCLMENU, pero NO en VTA_FACOMENU ni en VTA_FACORELPERMEN.
--
-- Se crea deshabilitada (rel_estado 0) para todos los perfiles FACO; se
-- habilita por perfil desde la pantalla de perfiles del exe (Form47) o con
-- el UPDATE del final, segun lo que defina negocio.
-- Idempotente: no duplica si ya existe.
-- =====================================================================

insert into VTA_FACOMENU (mnu_codigo, mnu_descripcion, mnu_tipomenu, mnu_habilitar)
select 1515, 'Cerrar Terminal desde Consulta Cuadratura', 'opcion', 1
  from dual
 where not exists (select 1 from VTA_FACOMENU m where m.mnu_codigo = 1515);

insert into VTA_FACORELPERMEN (per_codigo, mnu_codigo, rel_estado)
select p.per_codigo, 1515, 0
  from VTA_FACOPERFILES p
 where not exists (select 1 from VTA_FACORELPERMEN r
                    where r.per_codigo = p.per_codigo and r.mnu_codigo = 1515);
commit;

-- Habilitar para los perfiles que defina negocio (-1 = habilitado).
-- Ejemplo (perfiles de test: 7 Tesoreria Analista, 9 Administrador):
-- update VTA_FACORELPERMEN set rel_estado = -1 where mnu_codigo = 1515 and per_codigo in (7, 9);
-- commit;

select r.per_codigo, r.rel_estado from VTA_FACORELPERMEN r where r.mnu_codigo = 1515 order by 1;
