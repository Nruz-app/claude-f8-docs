-- ============================================================================
-- SOPORTE Permiso boton "Cambiar Cierre Y" (Command8) de Form5
--   (Detalle de Conteo de Sobres)
-- Paso   : 01 (revision). SOLO LECTURA: solo SELECT, no modifica nada.
-- Exe    : Form5.frm :3009-3015
--            If FuncBuscarOpcionCompensa(PERFILUSER, btoBotonCambiarYprd) Then Command8.Visible = True
--          btoBotonCambiarYprd = 85                (Modulo2.bas :220)
--          FuncBuscarOpcionCompensa                (Modulo1.bas :1111)
--            select p.mnu_codigo, p.rel_estado
--              from VTA_<pfx>relpermen p, VTA_<pfx>menu m
--             where p.mnu_codigo = m.mnu_codigo
--               and p.per_codigo = <PERFILUSER> and p.mnu_codigo = 85
--            -> visible solo si devuelve rel_estado = -1
--          PERFILUSER = vta_users.vta_perfil del login (form1.frm :282 / Form87).
-- Ademas el exe solo evalua el permiso si la F8 activa es Form3Y o Form104
-- (cuadratura por operador) y hay una Y elegida en la pantalla.
-- Ejecutar conectado como el dueno de las tablas VTA_* (sin prefijo de esquema).
--
-- -- EDITAR ------------------------------------------------------------------
-- Reemplazar en TODO el archivo (buscar/reemplazar):
--   12345678-9  -> login (RUT) del usuario, como en vta_users.vta_loginname
--   VTA_FACO    -> VTA_<prefijo del pais> (el prefijo sale en Q1, columna
--                  VTA_PREFIJO). Chile ('CHI' o vacio): VTA_MENU / VTA_RELPERMEN /
--                  VTA_PERFILES, es decir reemplazar 'VTA_FACO' por 'VTA_'.
--   10          -> codigo de perfil del usuario (columna VTA_PERFIL de Q1)
-- ----------------------------------------------------------------------------
-- Tablas (clon docs/ddl 26-10-2026):
--   VTA_<pfx>MENU      PK (MNU_CODIGO); MNU_TIPOMENU, MNU_HABILITAR (-2..2)
--   VTA_<pfx>RELPERMEN PK (PER_CODIGO, MNU_CODIGO); REL_ESTADO (-1 visible, 0 no)
-- ============================================================================


-- ----------------------------------------------------------------------------
-- Q1. Usuario: perfil(es), localizacion y prefijo de tablas del pais.
--     Si trae mas de una fila, el usuario elige el perfil al entrar (Form87):
--     el permiso debe estar en el perfil con que entra.
-- ----------------------------------------------------------------------------
select u.vta_loginname,
       u.vta_alias,
       u.vta_perfil,
       u.vta_uslocal,
       u.vta_localiz,
       a.vta_prefijo
  from vta_users u, vta_parametros a
 where a.vta_localiz = u.vta_localiz
   and u.vta_loginname = '12345678-9';


-- ----------------------------------------------------------------------------
-- Q2. Descripcion del perfil en la tabla de perfiles del pais.
-- ----------------------------------------------------------------------------
select e.per_codigo, e.per_sistema
  from VTA_FACOperfiles e
 where e.per_codigo = 10;


-- ----------------------------------------------------------------------------
-- Q3. Existe la opcion 85 en el menu del pais?
--     0 filas            -> falta el INSERT en VTA_<pfx>MENU.
--     tipomenu 'MenuPrincipal' -> el 85 tambien es indice de boton de toolbar
--                           (SubBuscarOpcionMenu); revisar antes de tocarlo.
-- ----------------------------------------------------------------------------
select m.mnu_codigo, m.mnu_descripcion, m.mnu_tipomenu, m.mnu_habilitar
  from VTA_FACOmenu m
 where m.mnu_codigo = 85;


-- ----------------------------------------------------------------------------
-- Q4. Todos los perfiles que tienen la opcion 85 (y si esta activa).
--     Sirve para ver que perfiles ya ven el boton y copiar el criterio.
-- ----------------------------------------------------------------------------
select p.per_codigo,
       p.mnu_codigo,
       p.rel_estado,
       decode(p.rel_estado, -1, 'VISIBLE', 'OCULTO') as estado
  from VTA_FACOrelpermen p
 where p.mnu_codigo = 85
 order by p.per_codigo;


-- ----------------------------------------------------------------------------
-- Q5. Misma consulta que hace el exe (FuncBuscarOpcionCompensa).
--     Resultado esperado para ver el boton: 1 fila con REL_ESTADO = -1.
--     0 filas o REL_ESTADO = 0 -> el boton queda oculto.
-- ----------------------------------------------------------------------------
select p.mnu_codigo, p.rel_estado
  from VTA_FACOrelpermen p, VTA_FACOmenu m
 where p.mnu_codigo = m.mnu_codigo
   and p.per_codigo = 10
   and p.mnu_codigo = 85
 order by 1, 2;


-- ----------------------------------------------------------------------------
-- Q6. Permisos "hermanos" de Form5 para el mismo perfil (comparacion).
--     Si el usuario ve "Fecha Contable" / "Fecha Venta" pero no "Cambiar Cierre Y",
--     estas filas existen y la del 85 no.
--       85  btoBotonCambiarYprd        Cambiar Cierre Y   (Command8)
--       87  btoBotoneFcontableprd      Fecha Contable     (Command9)
--       105 BtoACTUALIZACIONMASIVAPRD  Masivo (comentado en el exe)
--       113 btoBotoneFventaprd         Fecha Venta        (Command10)
-- ----------------------------------------------------------------------------
select m.mnu_codigo, m.mnu_descripcion, m.mnu_tipomenu, p.per_codigo, p.rel_estado
  from VTA_FACOmenu m, VTA_FACOrelpermen p
 where p.mnu_codigo (+) = m.mnu_codigo
   and p.per_codigo (+) = 10
   and m.mnu_codigo in (85, 87, 105, 113)
 order by m.mnu_codigo;


-- ============================================================================
-- REFERENCIA (NO es parte de la revision; descomentar solo para dar el permiso)
-- Mismos reemplazos de EDITAR. No duplica filas si ya existen.
-- ============================================================================
-- insert into VTA_FACOmenu (mnu_codigo, mnu_descripcion, mnu_tipomenu, mnu_habilitar)
-- select 85, 'Boton Cambiar Cierre Y (Form5)', 'opcion', -1 from dual
--  where not exists (select 1 from VTA_FACOmenu where mnu_codigo = 85);
--
-- insert into VTA_FACOrelpermen (per_codigo, mnu_codigo, rel_estado)
-- select 10, 85, -1 from dual
--  where not exists (select 1 from VTA_FACOrelpermen
--                     where per_codigo = 10 and mnu_codigo = 85);
--
-- update VTA_FACOrelpermen set rel_estado = -1
--  where per_codigo = 10 and mnu_codigo = 85;
--
-- commit;
--
-- Rollback:
-- delete from VTA_FACOrelpermen where per_codigo = 10 and mnu_codigo = 85;
-- delete from VTA_FACOmenu where mnu_codigo = 85;   -- solo si lo creo el insert de arriba
-- commit;
