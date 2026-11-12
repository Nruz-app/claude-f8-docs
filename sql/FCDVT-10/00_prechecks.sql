-- =====================================================================
-- FCDVT-10 (HU-03) - Paso 00: prechecks (SOLO LECTURA)
-- Carga masiva de cierres Y / Z, Tottus Chile (SFCL)
-- xintec-nruz 11-11-2026
-- Ejecutar conectado como el duenio de las tablas VTA_* (test: INTRANETTS).
-- No modifica nada. Guardar la salida en el README del ticket.
-- =====================================================================
set pagesize 200 linesize 220 feedback on
column vtaglosa_z format a30
column vta_cmp_asoc format a28
column object_name format a32

prompt ===== 1) Conceptos de Tottus en VTA_PAINT_Z (orden = filas de la grilla de Form19 / Form19Y) =====
prompt ESPERADO: filas 2 a 6 con vta_pop_up 0 y columna VTA_ (BOLETAS, N.CREDITO, FACTURA, N.DEBITO,
prompt GUIA FACTURABLES) y fila 7 con vta_pop_up 3 (TOTALES). Si no, PKG_F8_CARGA_MASIVA_YZ_SFCL da ORA-20002.
select rownum fila, x.*
  from (select vta_order_z, vtaglosa_z, vta_cmp_asoc, vta_pop_up, vta_validadorzzz, vta_signo
          from vta_paint_z
         where vta_localiz = 'SFCL'
         order by vta_order_z) x;

prompt ===== 2) Conceptos editables (vta_pop_up 0) que NO existen en VTA_SFCLZZZ (ESPERADO: 0 filas) =====
select z.vta_order_z, z.vtaglosa_z, z.vta_cmp_asoc
  from vta_paint_z z
 where z.vta_localiz = 'SFCL'
   and nvl(z.vta_pop_up, 0) = 0
   and z.vta_cmp_asoc is not null
   and (upper(z.vta_cmp_asoc) not like 'VTA\_%' escape '\' or upper(z.vta_cmp_asoc) like 'MVTA\_%' escape '\')
   and not exists (select 1 from user_tab_columns c
                    where c.table_name = 'VTA_SFCLZZZ'
                      and c.column_name = upper(trim(z.vta_cmp_asoc)));

prompt ===== 3) vta_cmp_asoc repetido entre conceptos editables (ESPERADO: 0 filas) =====
select upper(trim(vta_cmp_asoc)) columna, count(*) veces
  from vta_paint_z
 where vta_localiz = 'SFCL'
   and nvl(vta_pop_up, 0) = 0
   and vta_cmp_asoc is not null
 group by upper(trim(vta_cmp_asoc))
having count(*) > 1;

prompt ===== 4) Conceptos VTA_ editables fuera de las filas 2 a 6 (Form19Y no los graba; no van en el CSV) =====
select fila, vtaglosa_z, vta_cmp_asoc
  from (select rownum fila, x.*
          from (select vta_order_z, vtaglosa_z, vta_cmp_asoc, vta_pop_up
                  from vta_paint_z
                 where vta_localiz = 'SFCL'
                 order by vta_order_z) x)
 where nvl(vta_pop_up, 0) = 0
   and fila not between 2 and 6
   and upper(vta_cmp_asoc) like 'VTA\_%' escape '\';

prompt ===== 5) Columnas de la formula de validacion de la Z que no existen (ESPERADO: 0 filas; si hay, la formula se desactiva) =====
select z.vta_validadorzzz, z.vtaglosa_z, z.vta_cmp_asoc
  from vta_paint_z z
 where z.vta_localiz = 'SFCL'
   and z.vta_validadorzzz between 1 and 7
   and z.vta_cmp_asoc is not null
   and not exists (select 1 from user_tab_columns c
                    where c.table_name in ('VTA_SFCLLIBVTA', 'VTA_SFCLZZZ')
                      and c.column_name = upper(trim(z.vta_cmp_asoc)));

prompt ===== 6) Objetos nuevos (ESPERADO antes de instalar: 0 filas) =====
select object_name, object_type, status
  from user_objects
 where object_name in ('VTA_SFCLCARGA_YZ_DET', 'VTA_SFCLCARGA_YZ_DETM', 'VTA_SFCLCARGA_YZ_RES',
                       'VTA_SFCLCARGA_YZ_LOG', 'SEQ_VTA_SFCLCARGA_YZ', 'SEQ_VTA_SFCLCARGA_YZ_LOG',
                       'PKG_F8_CARGA_MASIVA_YZ_SFCL', 'PKG_F8_GRABA_MASIVA_YZ_SFCL',
                       'IND_VTA_SFCLCARGA_YZ_LOG_01');

prompt ===== 7) Objetos que usan los packages (ESPERADO: todos VALID) =====
select object_name, object_type, status
  from user_objects
 where object_name in ('VTA_PAINT_Z', 'VTA_SFCLLIBVTA', 'VTA_SFCLZZZ', 'VTA_SFCLTERMSTAT',
                       'VTA_SFCLTERMSTATY', 'VTA_SFCLTERMINALES', 'SEQ_VTA_SFCLTEC',
                       'TRG_VTA_SFCLZZZ_I')
 order by object_type, object_name;

prompt ===== 8) Codigo de menu 460 en SFCL (ESPERADO: 0 filas) =====
select * from VTA_SFCLMENU where mnu_codigo = 460;
select * from VTA_SFCLRELPERMEN where mnu_codigo = 460;

prompt ===== 9) Perfiles SFCL con el ingreso de Y (permiso 15): candidatos para el 460 =====
select p.per_codigo, p.rel_estado, m.mnu_descripcion
  from VTA_SFCLRELPERMEN p, VTA_SFCLMENU m
 where p.mnu_codigo = m.mnu_codigo
   and m.mnu_tipomenu = 'MenuPrincipal'
   and p.mnu_codigo = 15
 order by p.per_codigo;

prompt ===== 10) Volumen: Z e Y por dia de los ultimos 7 dias =====
select vta_fecha_venta, vta_tiporeg, count(*) cierres, count(distinct vta_local) locales
  from VTA_SFCLLIBVTA
 where vta_fecha_venta >= trunc(sysdate) - 7
   and vta_tiporeg in ('F8', 'Y')
 group by vta_fecha_venta, vta_tiporeg
 order by 1, 2;
