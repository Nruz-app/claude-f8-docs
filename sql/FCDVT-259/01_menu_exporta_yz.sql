-- =====================================================================
-- FCDVT-259 - Paso 01: permiso de menu 461 "Exportar cierres Y y Z" (FACO)
-- xintec-nruz 16-11-2026
--
-- MDIForm1.SubBuscarOpcionMenu: rama ElseIf (FACO And numero = 461)
-- muestra el submenu EXPYZ del boton Y (Button15, ButtonMenus(3))
-- -> Form176 (Exportar Cierres Y y Z, plantilla de carga).
-- Mismo patron que docs/sql/FCDVT-14/01_menu_ingreso_masivo_y.sql (460).
-- Solo INSERT explicitos (mismos para test y produccion):
--   1 fila en VTA_FACOMENU + 1 fila en VTA_FACORELPERMEN por cada perfil
--   que debe VER la opcion. Un perfil sin fila no la ve.
-- No es reejecutable: una segunda vez da ORA-00001 (PK), esperado.
-- EJECUTAR SOLO JUNTO CON EL EXE NUEVO (MDIForm1 con la rama 461 y Form176).
-- Con el exe anterior la fila 461 cae en el Else de SubBuscarOpcionMenu
-- (Buttons(461) no existe): da error y corta la carga de los permisos
-- siguientes del perfil. Por eso no esta en INSTALAR.sql.
-- Revertir con 99_rollback.sql, parte A.
-- =====================================================================

-- 1) Opcion de menu (SubBuscarOpcionMenu filtra mnu_tipomenu = 'MenuPrincipal')
insert into VTA_FACOMENU (mnu_codigo, mnu_descripcion, mnu_tipomenu, mnu_habilitar)
values (461, 'Exportar cierres Y y Z', 'MenuPrincipal', -1);

-- 2) Perfiles que ven el item (rel_estado -1 = visible): los mismos del 460.
--    Agregar o quitar lineas segun negocio.
insert into VTA_FACORELPERMEN (per_codigo, mnu_codigo, rel_estado) values (10, 461, -1);
insert into VTA_FACORELPERMEN (per_codigo, mnu_codigo, rel_estado) values (11, 461, -1);
-- En test los perfiles 0 y 1 tambien tienen el permiso 15 (Ingreso de Y):
-- insert into VTA_FACORELPERMEN (per_codigo, mnu_codigo, rel_estado) values (0, 461, -1);
-- insert into VTA_FACORELPERMEN (per_codigo, mnu_codigo, rel_estado) values (1, 461, -1);

commit;

-- Verificacion: misma union que SubBuscarOpcionMenu (MDIForm1)
select p.per_codigo, p.mnu_codigo, m.mnu_descripcion, p.rel_estado
  from VTA_FACORELPERMEN p, VTA_FACOMENU m
 where p.mnu_codigo = m.mnu_codigo
   and m.mnu_tipomenu = 'MenuPrincipal'
   and p.mnu_codigo in (15, 460, 461)
 order by p.per_codigo, p.mnu_codigo;
