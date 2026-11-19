-- =====================================================================
-- FCDVT-10 (HU-03) - Paso 00: prechecks (SOLO LECTURA)
-- Carga masiva de cierres Y / Z, Tottus Chile (SFCL)
-- xintec-nruz 11-11-2026 / 19-11-2026 (reglas de Colombia)
-- Ejecutar conectado como el duenio de las tablas VTA_* (test: INTRANETTS).
-- No modifica nada. Guardar la salida en el README del ticket.
-- =====================================================================
set pagesize 200 linesize 220 feedback on
column vtaglosa_z format a30
column vta_cmp_asoc format a28
column object_name format a32

-- xintec-nruz 19-11-2026: mismas reglas que Colombia. El package ya no lee
-- VTA_PAINT_Z: los 63 conceptos son la lista fija de
-- PKG_F8_CARGA_MASIVA_YZ_SFCL.c_encabezado. Las secciones 1 a 3 verifican que
-- esa lista existe en las tablas de Tottus y la comparan con VTA_PAINT_Z
-- (antes: forma de VTA_PAINT_Z y formula de la Z, anterior_2026-11-19/).

prompt ===== 1) Lista fija de conceptos (63) que NO existe en VTA_SFCLLIBVTA (5 de venta) / VTA_SFCLZZZ (58) (ESPERADO: 0 filas) =====
with l as (
  select 'VTA_MONTOBOL;VTA_MONTONCR;VTA_MONTOFAC;VTA_MMONTONDB;VTA_MONTOGUIA;REC_MEFECTIVO'
      || ';REC_MCHKDIA;REC_MCHKFECHA;REC_MTRANSBANK;REC_MSODIMAC;REC_MCMR;REC_MTREGALO'
      || ';REC_MTOTCONVENIO;REC_MCHKFALA;REC_MTOTFACXCOB;REC_MNCREDITO;REC_MTDE;REC_TARJEDENRED'
      || ';REC_TARJAMIPASS;REC_TARJSODEXO;REC_MCANJEPUNTOS;MTOTGIFTCORP;REC_MFPAY;REC_MDOTACIONES'
      || ';REC_MRETIROS;REC_MATESORAMIENTO;REC_MABONOCMR;REC_MTOTSIF;REC_MAVANCECMR;REC_MINTERESES'
      || ';REC_MTRANSFERENCIA;REC_MRETIROTRANS;REC_MTRANSFERENCIAINT;REC_MREVERSATRANSINT;REC_MRETIROTRANSINT;REC_MTOTATRF'
      || ';REC_MTOTALREVTRF;REC_MABONOTDE;REC_MREVABONOTDE;REC_MSELLOSVRD;REC_MTOTRECAUDA;R_RECTELEFONO'
      || ';R_RECINTERNET;R_RECARGABIP;R_JUEGOSAZAR;R_PAGOSERVICIOS;R_SEGUROS;REC_MTOTREVRECAUDA'
      || ';REV_RECTELEFONO;REV_RECINTERNET;REV_RECARGABIP;REV_JUEGOSAZAR;REV_PAGOSERVICIOS;REV_SEGUROS'
      || ';REC_MREVCANJEPUNTOS;MQUICKPAY;QUICKPAYDEBIDTOBF;REC_MTOTALPESO;REC_LINIO;REC_ECOM'
      || ';REC_PLUXEE_JUNAEB;REC_EDENRED_JUNAEB;REC_EDENRED_PRIVADO' lista from dual
), c as (
  select level pos, regexp_substr(l.lista, '[^;]+', 1, level) col
    from l
 connect by level <= 63
)
select c.pos, c.col
  from c
 where not exists (select 1 from user_tab_columns t
                    where t.table_name = case when c.pos <= 5 then 'VTA_SFCLLIBVTA' else 'VTA_SFCLZZZ' end
                      and t.column_name = c.col)
 order by c.pos;

prompt ===== 2) Conceptos editables de VTA_PAINT_Z de SFCL que NO estan en la lista fija (concepto nuevo: agregarlo a 02, 03, 04 y 04c) =====
with l as (
  select 'VTA_MONTOBOL;VTA_MONTONCR;VTA_MONTOFAC;VTA_MMONTONDB;VTA_MONTOGUIA;REC_MEFECTIVO'
      || ';REC_MCHKDIA;REC_MCHKFECHA;REC_MTRANSBANK;REC_MSODIMAC;REC_MCMR;REC_MTREGALO'
      || ';REC_MTOTCONVENIO;REC_MCHKFALA;REC_MTOTFACXCOB;REC_MNCREDITO;REC_MTDE;REC_TARJEDENRED'
      || ';REC_TARJAMIPASS;REC_TARJSODEXO;REC_MCANJEPUNTOS;MTOTGIFTCORP;REC_MFPAY;REC_MDOTACIONES'
      || ';REC_MRETIROS;REC_MATESORAMIENTO;REC_MABONOCMR;REC_MTOTSIF;REC_MAVANCECMR;REC_MINTERESES'
      || ';REC_MTRANSFERENCIA;REC_MRETIROTRANS;REC_MTRANSFERENCIAINT;REC_MREVERSATRANSINT;REC_MRETIROTRANSINT;REC_MTOTATRF'
      || ';REC_MTOTALREVTRF;REC_MABONOTDE;REC_MREVABONOTDE;REC_MSELLOSVRD;REC_MTOTRECAUDA;R_RECTELEFONO'
      || ';R_RECINTERNET;R_RECARGABIP;R_JUEGOSAZAR;R_PAGOSERVICIOS;R_SEGUROS;REC_MTOTREVRECAUDA'
      || ';REV_RECTELEFONO;REV_RECINTERNET;REV_RECARGABIP;REV_JUEGOSAZAR;REV_PAGOSERVICIOS;REV_SEGUROS'
      || ';REC_MREVCANJEPUNTOS;MQUICKPAY;QUICKPAYDEBIDTOBF;REC_MTOTALPESO;REC_LINIO;REC_ECOM'
      || ';REC_PLUXEE_JUNAEB;REC_EDENRED_JUNAEB;REC_EDENRED_PRIVADO' lista from dual
)
select z.vta_order_z, z.vtaglosa_z, z.vta_cmp_asoc
  from vta_paint_z z, l
 where z.vta_localiz = 'SFCL'
   and nvl(z.vta_pop_up, 0) = 0
   and z.vta_cmp_asoc is not null
   and instr(';' || l.lista || ';', ';' || upper(trim(z.vta_cmp_asoc)) || ';') = 0
 order by z.vta_order_z;

prompt ===== 3) Conceptos de VTA_PAINT_Z de SFCL (referencia: glosas de la plantilla) =====
select rownum fila, x.*
  from (select vta_order_z, vtaglosa_z, vta_cmp_asoc, vta_pop_up
          from vta_paint_z
         where vta_localiz = 'SFCL'
         order by vta_order_z) x;

prompt ===== 4) Objetos nuevos (ESPERADO antes de instalar: 0 filas) =====
select object_name, object_type, status
  from user_objects
 where object_name in ('VTA_SFCLCARGA_YZ_DET', 'VTA_SFCLCARGA_YZ_RES',
                       'VTA_SFCLCARGA_YZ_LOG', 'SEQ_VTA_SFCLCARGA_YZ', 'SEQ_VTA_SFCLCARGA_YZ_LOG',
                       'PKG_F8_CARGA_MASIVA_YZ_SFCL', 'PKG_F8_GRABA_MASIVA_YZ_SFCL',
                       'IND_VTA_SFCLCARGA_YZ_LOG_01');

prompt ===== 5) Objetos que usan los packages (ESPERADO: todos VALID) =====
select object_name, object_type, status
  from user_objects
 where object_name in ('VTA_SFCLLIBVTA', 'VTA_SFCLZZZ', 'VTA_SFCLTERMSTAT',
                       'VTA_SFCLTERMSTATY', 'VTA_SFCLTERMINALES', 'SEQ_VTA_SFCLTEC',
                       'TRG_VTA_SFCLZZZ_I')
 order by object_type, object_name;

prompt ===== 6) Codigo de menu 460 en SFCL (ESPERADO: 0 filas) =====
select * from VTA_SFCLMENU where mnu_codigo = 460;
select * from VTA_SFCLRELPERMEN where mnu_codigo = 460;

prompt ===== 7) Perfiles SFCL con el ingreso de Y (permiso 15): candidatos para el 460 =====
select p.per_codigo, p.rel_estado, m.mnu_descripcion
  from VTA_SFCLRELPERMEN p, VTA_SFCLMENU m
 where p.mnu_codigo = m.mnu_codigo
   and m.mnu_tipomenu = 'MenuPrincipal'
   and p.mnu_codigo = 15
 order by p.per_codigo;

prompt ===== 8) Volumen: Z e Y por dia de los ultimos 7 dias =====
select vta_fecha_venta, vta_tiporeg, count(*) cierres, count(distinct vta_local) locales
  from VTA_SFCLLIBVTA
 where vta_fecha_venta >= trunc(sysdate) - 7
   and vta_tiporeg in ('F8', 'Y')
 group by vta_fecha_venta, vta_tiporeg
 order by 1, 2;
