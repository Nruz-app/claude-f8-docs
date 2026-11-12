-- =====================================================================
-- FCDVT-10 (HU-03) - Paso 01: permiso de menu 460 en Tottus Chile (SFCL)
-- "Ingreso de cierre de terminal Y masivo" (submenu INGYMA del boton Y)
-- xintec-nruz 11-11-2026
-- Base: docs/sql/FCDVT-14/01_menu_ingreso_masivo_y.sql (FACO).
--
-- REQUIERE el exe con MDIForm1 que atiende el 460 tambien en SFCL. Con un
-- exe anterior, SubBuscarOpcionMenu manda el 460 al Else, Buttons(460) da
-- error y el On Error corta los permisos que quedaban por cargar. Ejecutar
-- en cada base SOLO cuando ahi se use el exe nuevo.
--
-- Antes: 00_prechecks.sql seccion 8 (460 libre) y 9 (perfiles con el
-- permiso 15, ingreso de Y). Por defecto el 460 se da a los MISMOS perfiles
-- que tienen el 15 habilitado; para otra lista, comentar el insert-select
-- y usar los insert explicitos.
-- No es reejecutable (PK). Revertir con 99_rollback.sql, parte A.
-- =====================================================================

-- 1) Opcion de menu (SubBuscarOpcionMenu filtra mnu_tipomenu = 'MenuPrincipal')
insert into VTA_SFCLMENU (mnu_codigo, mnu_descripcion, mnu_tipomenu, mnu_habilitar)
values (460, 'Ingreso de cierre de terminal Y masivo', 'MenuPrincipal', -1);

-- 2) Perfiles que ven el item (rel_estado -1 = visible)
insert into VTA_SFCLRELPERMEN (per_codigo, mnu_codigo, rel_estado)
select p.per_codigo, 460, -1
  from VTA_SFCLRELPERMEN p
 where p.mnu_codigo = 15
   and p.rel_estado = -1;
-- Alternativa (lista explicita):
-- insert into VTA_SFCLRELPERMEN (per_codigo, mnu_codigo, rel_estado) values (10, 460, -1);
-- insert into VTA_SFCLRELPERMEN (per_codigo, mnu_codigo, rel_estado) values (11, 460, -1);

commit;

-- Verificacion: misma union que SubBuscarOpcionMenu (MDIForm1)
select p.per_codigo, p.mnu_codigo, m.mnu_descripcion, p.rel_estado
  from VTA_SFCLRELPERMEN p, VTA_SFCLMENU m
 where p.mnu_codigo = m.mnu_codigo
   and m.mnu_tipomenu = 'MenuPrincipal'
   and p.mnu_codigo in (15, 460)
 order by p.per_codigo, p.mnu_codigo;
