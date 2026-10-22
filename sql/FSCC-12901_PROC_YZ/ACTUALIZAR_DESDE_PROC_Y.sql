-- =====================================================================
-- FSCC-12901 PROC_YZ - Actualizacion de una base que YA tiene PROC_Y
-- (docs/sql/FSCC-12901_PROC_Y instalado, por ejemplo test tras el traspaso).
-- Ejecutar desde esta carpeta, conectado como el DUENIO de las tablas VTA_*:
--   sqlplus <usuario>@<base> @ACTUALIZAR_DESDE_PROC_Y.sql
-- En DBeaver: ejecutar el bloque 1 y luego 04 y 07 de esta carpeta (Alt+X).
--
-- Que hace:
--   1. agrega los 4 parametros 1502 de la Z (si no existen), con
--      CA_CIERRA_Z = N: el proceso sigue igual que PROC_Y hasta activarla;
--   2. recompila PKG_F8_CIERRE_AUTO (04 especificacion y 07 cuerpo).
-- No cambia tablas, cola, log, trigger, permisos ni PKG_F8_COMPENSA_DI_AUTO
-- (05/06 son identicos en PROC_Y y PROC_YZ). La firma de las rutinas que ya
-- usan Form43 y el job no cambia.
-- Vuelta atras: VOLVER_A_PROC_Y.sql.
-- =====================================================================
set echo on feedback on serveroutput on
whenever sqlerror exit failure rollback

prompt ===== 1. Parametros 1502 de la Z =====
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
select 1502, x.cod, x.val, sysdate
  from (select 'CA_CIERRA_Z'   cod, 'N' val from dual union all
        select 'CA_Z_SIN_Y',        'N'     from dual union all
        select 'CA_Z_VAL_SUMA',     'S'     from dual union all
        select 'CA_Z_VAL_DOL',      'N'     from dual) x
 where not exists (select 1 from VTA_FACOPARAM p
                    where p.vta_ccodtipo = 1502 and trim(p.vta_ccodigo) = x.cod);
commit;
select vta_ccodigo, vta_xglosa from VTA_FACOPARAM where vta_ccodtipo = 1502 order by 1;

prompt ===== 2. PKG_F8_CIERRE_AUTO con cierre de la Z =====
@04_pkg_cierre_auto_spec.sql
@07_pkg_cierre_auto_body.sql

prompt ===== Estado (esperado: VALID y sin errores) =====
select object_name, object_type, status from user_objects
 where object_name in ('PKG_F8_CIERRE_AUTO', 'PKG_F8_COMPENSA_DI_AUTO')
 order by object_name, object_type;
select name, type, line, position, text from user_errors
 where name in ('PKG_F8_CIERRE_AUTO', 'PKG_F8_COMPENSA_DI_AUTO')
 order by name, type, sequence;
