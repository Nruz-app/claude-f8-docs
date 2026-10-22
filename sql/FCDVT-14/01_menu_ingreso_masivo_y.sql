-- =====================================================================
-- FCDVT-14 Carga masiva de cierres F8 (Z / Y) via Excel
-- 01 - Permiso de menu 460 "Ingreso de cierre de terminal Y masivo" (FACO)
--      MDIForm1.SubBuscarOpcionMenu: rama ElseIf (FACO And numero = 460)
--      muestra el submenu INGYMA del boton Y (Button15) -> Form174.
--      Solo INSERT explicitos (mismos para test y produccion):
--        1 fila en VTA_FACOMENU + 1 fila en VTA_FACORELPERMEN por cada
--        perfil que debe VER la opcion. Un perfil sin fila no la ve.
--      No es reejecutable: una segunda vez da ORA-00001 (PK), esperado.
--      Requiere el exe nuevo (MDIForm1 con la rama 460).
--      Revertir con 99_rollback.sql.
-- =====================================================================

-- 1) Opcion de menu (SubBuscarOpcionMenu filtra mnu_tipomenu = 'MenuPrincipal')
insert into VTA_FACOMENU (mnu_codigo, mnu_descripcion, mnu_tipomenu, mnu_habilitar)
values (460, 'Ingreso de cierre de terminal Y masivo', 'MenuPrincipal', -1);

-- 2) Perfiles que ven el item (rel_estado -1 = visible). Agregar o quitar lineas segun negocio.
insert into VTA_FACORELPERMEN (per_codigo, mnu_codigo, rel_estado) values (10, 460, -1);
insert into VTA_FACORELPERMEN (per_codigo, mnu_codigo, rel_estado) values (11, 460, -1);
-- En test los perfiles 0 y 1 tambien tienen el permiso 15 (Ingreso de Y):
-- insert into VTA_FACORELPERMEN (per_codigo, mnu_codigo, rel_estado) values (0, 460, -1);
-- insert into VTA_FACORELPERMEN (per_codigo, mnu_codigo, rel_estado) values (1, 460, -1);

commit;

-- Verificacion: misma union que SubBuscarOpcionMenu (MDIForm1)
select p.per_codigo, p.mnu_codigo, m.mnu_descripcion, p.rel_estado
  from VTA_FACORELPERMEN p, VTA_FACOMENU m
 where p.mnu_codigo = m.mnu_codigo
   and m.mnu_tipomenu = 'MenuPrincipal'
   and p.mnu_codigo in (15, 460)
 order by p.per_codigo, p.mnu_codigo;
