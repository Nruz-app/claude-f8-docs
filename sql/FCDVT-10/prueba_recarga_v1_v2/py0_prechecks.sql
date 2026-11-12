-- =====================================================================
-- FCDVT-10 (HU-03) - Prueba "recarga v1 / v2" de la carga masiva de
-- Tottus Chile (SFCL) - py0: verificaciones de SOLO LECTURA.
-- xintec-nruz 12-11-2026
--
-- Misma prueba de FCDVT-14 sesion 7 (prueba_carga_y_compensa_di_s7),
-- sin DI ni sobres (en SFCL no estan habilitados): se cargan dos archivos
-- con la misma fecha, local y terminal y otro monto que cuadra (v1 y v2)
-- y se mira que monto queda al final.
--
-- Fecha de venta por defecto 11-11-2026. Las consultas que dependen del
-- local llevan el valor en una linea -- EDITAR.
-- Ejecutar conectado al usuario de test. Si las tablas no se ven sin
-- esquema:  alter session set current_schema = INTRANETTS;
-- =====================================================================

-- 1. Objetos de FCDVT-10. ESPERADO: los dos packages (PACKAGE y PACKAGE
--    BODY) y las tablas/secuencias VTA_SFCLCARGA_YZ_*, todo VALID. Si no
--    aparecen, falta INSTALAR.sql de docs/sql/FCDVT-10 (la prueba no se
--    puede hacer).
select owner, object_name, object_type, status
  from all_objects
 where object_name in ('PKG_F8_CARGA_MASIVA_YZ_SFCL', 'PKG_F8_GRABA_MASIVA_YZ_SFCL',
                       'VTA_SFCLCARGA_YZ_DET', 'VTA_SFCLCARGA_YZ_DETM',
                       'VTA_SFCLCARGA_YZ_RES', 'VTA_SFCLCARGA_YZ_LOG',
                       'SEQ_VTA_SFCLCARGA_YZ', 'SEQ_VTA_SFCLCARGA_YZ_LOG',
                       'TRG_VTA_SFCLZZZ_I')
 order by owner, object_name, object_type;

-- 2. Permiso 460 (submenu "Ingreso del YYY Masivo" del boton Y) en SFCL.
--    ESPERADO: fila 460 del MenuPrincipal y el perfil del usuario de
--    prueba con rel_estado -1. Si no, falta 01_menu_ingreso_masivo_y_sfcl.sql.
select p.per_codigo, p.mnu_codigo, m.mnu_descripcion, p.rel_estado
  from VTA_SFCLRELPERMEN p, VTA_SFCLMENU m
 where p.mnu_codigo = m.mnu_codigo
   and m.mnu_tipomenu = 'MenuPrincipal'
   and p.mnu_codigo in (15, 460)
 order by p.per_codigo, p.mnu_codigo;

-- 3. VTA_PAINT_Z de Tottus: ENTRADA DEL GENERADOR arma_prueba.py.
--    Exportar el resultado COMPLETO (todas las filas, tambien las de
--    vta_cmp_asoc nulo) a paint_z_sfcl.csv en esta carpeta: separador ;
--    con encabezado (DBeaver: Exportar datos > CSV; SQL Developer:
--    Exportar > csv con delimitador ;). Columnas, en este orden:
--    FILA;VTA_CMP_ASOC;VTA_POP_UP;VTA_VALIDADORZZZ;VTA_SIGNO;VTAGLOSA_Z
--    ESPERADO: filas 2 a 6 con vta_pop_up 0 y columna VTA_ (BOLETAS,
--    N.CREDITO, FACTURA, N.DEBITO, GUIA FACTURABLES) y fila 7 con
--    vta_pop_up 3 (TOTALES), como exige PKG_F8_CARGA_MASIVA_YZ_SFCL.
select rownum fila, x.vta_cmp_asoc, x.vta_pop_up, x.vta_validadorzzz, x.vta_signo,
       x.vtaglosa_z
  from (select vta_order_z, vtaglosa_z, vta_cmp_asoc, vta_pop_up, vta_validadorzzz, vta_signo
          from vta_paint_z
         where vta_localiz = 'SFCL'
         order by vta_order_z) x;

-- 4. Encabezado del CSV que espera Buscar. Guardar el texto (una sola
--    linea) en encabezado.txt: el generador lo compara con el que arma
--    desde paint_z_sfcl.csv y se detiene si no son iguales.
select PKG_F8_CARGA_MASIVA_YZ_SFCL.fn_encabezado('SFCL') encabezado from dual;

-- 5. Formula de validacion de la Z que usa Cargar (nulo = desactivada).
--    Solo informativo: el generador calcula la columna de pago para que
--    la Z cuadre con esta formula.
select PKG_F8_CARGA_MASIVA_YZ_SFCL.fn_sql_valida_z formula from dual;

-- 6. Locales de SFCL vigentes con al menos 4 terminales LIBRES el
--    11-11-2026 (vigentes, sin libvta F8/Y, sin termstat ni termstaty y
--    sin cargas masivas ese dia). Elegir uno para la prueba.
select t.ter_local, l.vta_alias, count(*) libres
  from VTA_SFCLTERMINALES t, VTA_SFCLLOCALES l
 where l.vta_cod_local = t.ter_local
   and l.vta_estado_local = 'V'
   and (t.ter_fechabaja >= to_date('20261111','yyyymmdd') or t.ter_fechabaja is null)
   and not exists (select 1 from VTA_SFCLLIBVTA v
                    where v.vta_fecha_venta = to_date('20261111','yyyymmdd')
                      and v.vta_local = t.ter_local and v.vta_terminal = t.ter_terminal
                      and v.vta_tiporeg in ('F8', 'Y'))
   and not exists (select 1 from VTA_SFCLTERMSTAT s
                    where s.ter_fecha = to_date('20261111','yyyymmdd')
                      and s.ter_local = t.ter_local and s.ter_terminal = t.ter_terminal)
   and not exists (select 1 from VTA_SFCLTERMSTATY y
                    where y.ter_fecha = to_date('20261111','yyyymmdd')
                      and y.ter_local = t.ter_local and y.ter_terminal = t.ter_terminal)
   and not exists (select 1 from VTA_SFCLCARGA_YZ_RES r
                    where r.res_fecha = to_date('20261111','yyyymmdd')
                      and r.res_local = t.ter_local and r.res_terminal = t.ter_terminal)
 group by t.ter_local, l.vta_alias
having count(*) >= 4
 order by t.ter_local;

-- 7. Terminales libres del local elegido (mismas condiciones, mas sin
--    VTA_SFCLTARJ 2001-2999 ni movimientos 'AL' ese dia: los crea
--    TRG_VTA_SFCLZZZ_I y py9 los borra). Tomar 4 para TA, TB, TC y TD.
select t.ter_terminal, t.ter_nombre, t.ter_estado, t.ter_fechabaja
  from VTA_SFCLTERMINALES t
 where t.ter_local = 0                                           -- EDITAR: local
   and (t.ter_fechabaja >= to_date('20261111','yyyymmdd') or t.ter_fechabaja is null)
   and not exists (select 1 from VTA_SFCLLIBVTA v
                    where v.vta_fecha_venta = to_date('20261111','yyyymmdd')
                      and v.vta_local = t.ter_local and v.vta_terminal = t.ter_terminal
                      and v.vta_tiporeg in ('F8', 'Y'))
   and not exists (select 1 from VTA_SFCLTERMSTAT s
                    where s.ter_fecha = to_date('20261111','yyyymmdd')
                      and s.ter_local = t.ter_local and s.ter_terminal = t.ter_terminal)
   and not exists (select 1 from VTA_SFCLTERMSTATY y
                    where y.ter_fecha = to_date('20261111','yyyymmdd')
                      and y.ter_local = t.ter_local and y.ter_terminal = t.ter_terminal)
   and not exists (select 1 from VTA_SFCLCARGA_YZ_RES r
                    where r.res_fecha = to_date('20261111','yyyymmdd')
                      and r.res_local = t.ter_local and r.res_terminal = t.ter_terminal)
   and not exists (select 1 from VTA_SFCLTARJ j
                    where j.vta_fecha = to_date('20261111','yyyymmdd')
                      and j.vta_local = t.ter_local and j.vta_terminal = t.ter_terminal
                      and j.vta_cod_tarj between 2001 and 2999)
   and not exists (select 1 from VTA_SFCLMOVDET m
                    where m.mov_fecha = to_date('20261111','yyyymmdd')
                      and m.mov_local = t.ter_local and m.mov_terminal = t.ter_terminal)
 order by t.ter_terminal;
