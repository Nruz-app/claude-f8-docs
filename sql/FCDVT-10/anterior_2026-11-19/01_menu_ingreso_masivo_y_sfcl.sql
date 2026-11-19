-- =====================================================================
-- FCDVT-10 Carga masiva de cierres F8 (Z / Y) via Excel - Tottus Chile
-- 01 - Permiso de menu 460 "Ingreso de cierre de terminal Y masivo" (SFCL)
--      MDIForm1.SubBuscarOpcionMenu: rama ElseIf (FACO Or SFCL And numero = 460)
--      muestra el submenu INGYMA del boton Y (Button15) -> Form174.
--      Mismo criterio que docs/sql/FCDVT-14/01_menu_ingreso_masivo_y.sql
--      (FACO): solo INSERT explicitos.
--        1 fila en VTA_SFCLMENU + 1 fila en VTA_SFCLRELPERMEN por cada
--        perfil que debe VER la opcion. Un perfil sin fila no la ve.
--      No es reejecutable: una segunda vez da ORA-00001 (PK), esperado.
--      Requiere el exe nuevo (MDIForm1 con la rama 460 para SFCL).
--      Antes: 00_prechecks.sql seccion 8 (460 libre) y 9 (perfiles con el 15).
--      Revertir con 99_rollback.sql, parte A.
-- xintec-nruz 11-11-2026 / 18-11-2026 (inserts explicitos, como FCDVT-14)
-- =====================================================================

-- 1) Opcion de menu (SubBuscarOpcionMenu filtra mnu_tipomenu = 'MenuPrincipal')
insert into VTA_SFCLMENU (mnu_codigo, mnu_descripcion, mnu_tipomenu, mnu_habilitar)
values (460, 'Ingreso de cierre de terminal Y masivo', 'MenuPrincipal', -1);

-- 2) Perfiles que ven el item (rel_estado -1 = visible). Agregar o quitar lineas segun negocio.
--    En test estos son los perfiles con el permiso 15 (Ingreso de Y) VISIBLE:
insert into VTA_SFCLRELPERMEN (per_codigo, mnu_codigo, rel_estado) values (9, 460, -1);
insert into VTA_SFCLRELPERMEN (per_codigo, mnu_codigo, rel_estado) values (10, 460, -1);
insert into VTA_SFCLRELPERMEN (per_codigo, mnu_codigo, rel_estado) values (12, 460, -1);
-- En test los perfiles 0, 1, 3, 6, 7, 8, 11 y 13 tambien tienen el permiso 15, pero oculto:
-- insert into VTA_SFCLRELPERMEN (per_codigo, mnu_codigo, rel_estado) values (0, 460, -1);
-- insert into VTA_SFCLRELPERMEN (per_codigo, mnu_codigo, rel_estado) values (1, 460, -1);
-- insert into VTA_SFCLRELPERMEN (per_codigo, mnu_codigo, rel_estado) values (3, 460, -1);
-- insert into VTA_SFCLRELPERMEN (per_codigo, mnu_codigo, rel_estado) values (6, 460, -1);
-- insert into VTA_SFCLRELPERMEN (per_codigo, mnu_codigo, rel_estado) values (7, 460, -1);
-- insert into VTA_SFCLRELPERMEN (per_codigo, mnu_codigo, rel_estado) values (8, 460, -1);
-- insert into VTA_SFCLRELPERMEN (per_codigo, mnu_codigo, rel_estado) values (11, 460, -1);
-- insert into VTA_SFCLRELPERMEN (per_codigo, mnu_codigo, rel_estado) values (13, 460, -1);

commit;

-- Verificacion: misma union que SubBuscarOpcionMenu (MDIForm1)
select p.per_codigo, p.mnu_codigo, m.mnu_descripcion, p.rel_estado
  from VTA_SFCLRELPERMEN p, VTA_SFCLMENU m
 where p.mnu_codigo = m.mnu_codigo
   and m.mnu_tipomenu = 'MenuPrincipal'
   and p.mnu_codigo in (15, 460)
 order by p.per_codigo, p.mnu_codigo;
