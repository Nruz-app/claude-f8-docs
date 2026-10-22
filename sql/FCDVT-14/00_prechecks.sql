-- =====================================================================
-- FCDVT-14 Carga masiva de cierres F8 (Z / Y) via Excel
-- 00 - Verificaciones previas (SOLO LECTURA). Ejecutar en test para
--      contrastar el template Excel del DF-SCC con la estructura real.
--      Empresas en alcance: '' / CHI (Falabella Chile, solo Z),
--      SFCL (Tottus Chile, Z e Y), FACO (Falabella Colombia, Z e Y).
-- =====================================================================
set linesize 250 pagesize 1000 feedback on

prompt === 1. Conceptos de la Z por empresa (columnas del template = vtaglosa_z)
prompt ===    pop_up: 0 editable, 1 titulo, 2 separador, 3 total calculado
select z.vta_localiz, z.vta_order_z, z.vtaglosa_z, z.vta_cmp_asoc,
       nvl(z.vta_pop_up,0) pop_up, z.vta_validadorzzz, z.vta_signo
  from vta_paint_z z
 where z.vta_localiz in ('CHI','SFCL','FACO')
 order by z.vta_localiz, z.vta_order_z;

prompt === 2. Cantidad de conceptos y editables por empresa
select z.vta_localiz, count(*) total,
       sum(decode(nvl(z.vta_pop_up,0),0,1,0)) editables,
       sum(decode(nvl(z.vta_pop_up,0),3,1,0)) calculados
  from vta_paint_z z
 where z.vta_localiz in ('CHI','SFCL','FACO')
 group by z.vta_localiz;

prompt === 3. Glosas repetidas dentro de una empresa (afecta mapeo por glosa)
select z.vta_localiz, trim(upper(z.vtaglosa_z)) glosa, count(*) veces
  from vta_paint_z z
 where z.vta_localiz in ('CHI','SFCL','FACO')
   and nvl(z.vta_pop_up,0) in (0,3)
 group by z.vta_localiz, trim(upper(z.vtaglosa_z))
having count(*) > 1
 order by 1, 2;

prompt === 4. Campos de paint_z que no existen en libvta/zzz de la empresa (esperado: 0 filas)
select z.vta_localiz, z.vta_cmp_asoc
  from vta_paint_z z
 where z.vta_localiz in ('CHI','SFCL','FACO')
   and nvl(z.vta_pop_up,0) in (0,3)
   and z.vta_cmp_asoc is not null
   and not exists (
         select 1 from all_tab_columns c
          where c.column_name = upper(trim(z.vta_cmp_asoc))
            and c.table_name in (
                  decode(z.vta_localiz,'CHI','VTA_LIBVTA','VTA_'||z.vta_localiz||'LIBVTA'),
                  decode(z.vta_localiz,'CHI','VTA_ZZZ','VTA_'||z.vta_localiz||'ZZZ')));

prompt === 5. Columnas de libvta / zzz / termstat / termstaty por empresa
select c.table_name, c.column_id, c.column_name, c.data_type, c.data_length,
       c.data_precision, c.data_scale, c.nullable
  from all_tab_columns c
 where c.table_name in ('VTA_LIBVTA','VTA_ZZZ','VTA_TERMSTAT',
                        'VTA_SFCLLIBVTA','VTA_SFCLZZZ','VTA_SFCLTERMSTAT','VTA_SFCLTERMSTATY',
                        'VTA_FACOLIBVTA','VTA_FACOZZZ','VTA_FACOTERMSTAT','VTA_FACOTERMSTATY')
 order by c.table_name, c.column_id;

prompt === 6. Secuencias de techkey usadas por Form19/Form19Y
select sequence_owner, sequence_name, last_number
  from all_sequences
 where sequence_name in ('VTA_TEC_SEC','SEQ_VTA_SFCLTEC','SEQ_VTA_FACOTEC');

prompt === 7. Tablas de log existentes reutilizables (VTA_LOG_ING_ZLV, VTA_LOG_SISTEMA)
select c.table_name, c.column_id, c.column_name, c.data_type, c.data_length
  from all_tab_columns c
 where c.table_name in ('VTA_LOG_ING_ZLV','VTA_LOG_SISTEMA','VTA_LOG_MODULO')
 order by c.table_name, c.column_id;

prompt === 8. Ultimo id de modulo de log (codigo indica 70 = MANTUSUA)
select max(vta_modulo_id) from vta_log_modulo;

prompt === 9. Opciones de menu del boton 16 (Ingreso Z) y codigos libres
select 'CHI' pais, m.mnu_codigo, m.mnu_descripcion, m.mnu_tipomenu from vta_menu m where m.mnu_codigo in (15,16)
union all
select 'SFCL', m.mnu_codigo, m.mnu_descripcion, m.mnu_tipomenu from vta_sfclmenu m where m.mnu_codigo in (15,16)
union all
select 'FACO', m.mnu_codigo, m.mnu_descripcion, m.mnu_tipomenu from vta_facomenu m where m.mnu_codigo in (15,16);

prompt === 10. Volumen de Z / Y del ultimo mes (orden de magnitud de una carga)
select 'CHI' pais, vta_tiporeg, count(*) from vta_libvta
 where vta_fecha_venta >= trunc(sysdate) - 30 and vta_tiporeg in ('F8','Y') group by vta_tiporeg
union all
select 'SFCL', vta_tiporeg, count(*) from vta_sfcllibvta
 where vta_fecha_venta >= trunc(sysdate) - 30 and vta_tiporeg in ('F8','Y') group by vta_tiporeg
union all
select 'FACO', vta_tiporeg, count(*) from vta_facolibvta
 where vta_fecha_venta >= trunc(sysdate) - 30 and vta_tiporeg in ('F8','Y') group by vta_tiporeg;

prompt === 11. Submenu de Y (FACO): codigo 460 libre (esperado: 0 filas en ambas)
select m.mnu_codigo, m.mnu_descripcion, m.mnu_tipomenu from vta_facomenu m where m.mnu_codigo = 460;
select r.per_codigo, r.rel_estado from vta_facorelpermen r where r.mnu_codigo = 460;

prompt === 12. Perfiles FACO con permiso 15 (Ingreso de Y); 01 les copia el estado al 460
select r.per_codigo, r.rel_estado from vta_facorelpermen r where r.mnu_codigo = 15 order by 1;
