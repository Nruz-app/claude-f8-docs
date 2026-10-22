-- =====================================================================
-- FSCC-12901 v2 MULTIPAIS - Paso 03c (objeto POR PAIS: FACO)
-- Opcion 1515 Cerrar Terminal desde Consultas de Cuadratura (Form43 FACO).
-- Identico a v1 (FSCC-12901_T1_T2/03c_permiso_cc.sql); idempotente.
-- OTRO PAIS: VTA_<pfx>MENU / VTA_<pfx>RELPERMEN / VTA_<pfx>PERFILES.
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
