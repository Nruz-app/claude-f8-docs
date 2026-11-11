-- =====================================================================
-- FCDVT-14 - Prueba de estres de la carga masiva (Form174).
-- e0: verificaciones de SOLO LECTURA antes de la corrida.
-- xintec-nruz 10-11-2026
--
-- Dos series de archivos CSV (6 en total, generados con genera_csv.py):
--   Serie A (profundidad): 1 grupo = fecha 07-11-2026, local 5,
--     terminal 1. Archivos a01_1000 / a02_2000 / a03_5000.
--   Serie B (anchura): 112 grupos = 28 fechas de agosto 2026 (sin los
--     dias 13, 14 y 29, que estan ocupados) x terminales 1 a 4.
--     Archivos b01_1000 / b02_2000 / b03_5000.
-- Cargar REEMPLAZA cada grupo: si la fecha esta limpia al empezar, las
-- tres etapas de cada serie se pueden correr seguidas sin limpiar.
-- Ejecutar conectado al usuario de test. Si las tablas no se ven sin
-- esquema:  alter session set current_schema = INTRANETTS;
-- Cada consulta indica su resultado ESPERADO.
--
-- Nota: si sqlplus reclama "SP2-1502: HTTP proxy setting..." al lanzar,
-- es la variable NO_PROXY del equipo: lanzarlo con  set NO_PROXY=  y
-- despues sqlplus.
-- =====================================================================

-- 1. Objetos del paquete de carga masiva. ESPERADO: PKG_F8_CARGA_MASIVA_YZ
--    y PKG_F8_GRABA_MASIVA_YZ en PACKAGE VALID del duenio, sus tablas
--    (VTA_FACOCARGA_YZ_DET/RES/LOG con las secuencias
--    SEQ_VTA_FACOCARGA_YZ y SEQ_VTA_FACOCARGA_YZ_LOG). Con el usuario de
--    aplicacion los PACKAGE BODY pueden no aparecer con este select: la
--    consulta 2 cuenta los body (puede dar 0 sin que eso sea un error,
--    ver su comentario). Un SYNONYM INVALID del usuario de aplicacion
--    es normal (Oracle lo revalida en el primer uso).
select owner, object_name, object_type, status
  from all_objects
 where object_name in ('PKG_F8_CARGA_MASIVA_YZ', 'PKG_F8_GRABA_MASIVA_YZ',
                       'VTA_FACOCARGA_YZ_DET', 'VTA_FACOCARGA_YZ_RES',
                       'VTA_FACOCARGA_YZ_LOG',
                       'SEQ_VTA_FACOCARGA_YZ', 'SEQ_VTA_FACOCARGA_YZ_LOG')
 order by owner, object_name, object_type;

-- 2. PACKAGE BODY de los dos paquetes. ESPERADO: 1 y 1 (como duenio del
--    esquema). Con el usuario de aplicacion pueden dar 0 aunque los
--    bodies existan (no se ven en all_objects si solo le dieron EXECUTE
--    del package): en ese caso el verdadero chequeo es el propio Buscar
--    y Cargar de Form174.
select object_name, count(*) bodies
  from all_objects
 where object_name in ('PKG_F8_CARGA_MASIVA_YZ', 'PKG_F8_GRABA_MASIVA_YZ')
   and object_type = 'PACKAGE BODY'
 group by object_name;

-- 3. Parametros 1502. ESPERADO: la misma lista de siempre (CA_DECIMAL 0,
--    CA_DI_ACTIVO S, CA_DI_MAX 20000, CA_DI_MIN -1000, entre otros).
--    En esta prueba NO se usa Form133 ni la compensacion: solo se mide
--    el Buscar + Cargar de Form174.
select trim(vta_ccodigo) codigo, '[' || vta_xglosa || ']' glosa
  from VTA_FACOPARAM where vta_ccodtipo = 1502 order by 1;

-- 4. Permiso 460 de la carga masiva. ESPERADO: fila 460 del
--    MenuPrincipal (VTA_FACOMENU) y filas por perfil en el 460. El
--    usuario de prueba debe ver el submenu "Ingreso del YYY Masivo" del
--    boton Y. El 15 es el permiso de ingreso de Y.
select p.per_codigo, p.mnu_codigo, m.mnu_descripcion, p.rel_estado
  from VTA_FACORELPERMEN p, VTA_FACOMENU m
 where p.mnu_codigo = m.mnu_codigo
   and m.mnu_tipomenu = 'MenuPrincipal'
   and p.mnu_codigo in (15, 460)
 order by p.per_codigo, p.mnu_codigo;

-- 5. Terminales vigentes del local 5. ESPERADO: 1 a 28, 30 y 90 a 97,
--    todas con ter_fechabaja 31-12-5000 (35 filas). La serie A usa la
--    terminal 1; la B, las 1 a 4.
select t.ter_terminal, nvl(t.ter_tipo, 0), to_char(t.ter_fechabaja, 'dd-mm-yyyy')
  from vta_FACOterminales t
 where t.ter_local = 5
 order by t.ter_terminal;

-- 6. Fechas objetivo: cargas previas en las tablas de carga masiva.
--    ESPERADO: sin filas (si hay, correr e9_limpia.sql primero, con
--    v_ejecutar = 'N' para contar).
with fechas as (
  select to_date('20260801','yyyymmdd') + level - 1 d
    from dual
   where level not in (13, 14, 29)   -- dias ocupados de agosto en test
  connect by level <= 31
  union all
  select to_date('20261107','yyyymmdd') from dual
)
select to_char(r.res_fecha, 'dd-mm-yyyy') fecha, count(*) filas
  from VTA_FACOCARGA_YZ_RES r
 where r.res_fecha in (select f.d from fechas f)
   and r.res_local = 5
 group by r.res_fecha
 order by r.res_fecha;

-- 7. Fechas objetivo: Y/Z ya grabadas en el libro de ventas. ESPERADO:
--    sin filas (agosto y el 07-11 de local 5 estan limpios; en el mes de
--    agosto solo existe una Y el 29-08, fecha excluida de la prueba).
with fechas as (
  select to_date('20260801','yyyymmdd') + level - 1 d
    from dual
   where level not in (13, 14, 29)
  connect by level <= 31
  union all
  select to_date('20261107','yyyymmdd') from dual
)
select to_char(l.vta_fecha_venta, 'dd-mm-yyyy') fecha, l.vta_terminal,
       l.vta_tiporeg, count(*) filas
  from vta_FACOlibvta l
 where l.vta_fecha_venta in (select f.d from fechas f)
   and l.vta_local = 5 and l.vta_tiporeg in ('F8', 'Y')
 group by l.vta_fecha_venta, l.vta_terminal, l.vta_tiporeg
 order by l.vta_fecha_venta, l.vta_terminal;

-- 8. Fechas objetivo: termstaty y termstat cerradas (estado 1 o 2).
--    ESPERADO: sin filas; en los dias livianos de agosto hay termstat en
--    estado 0 (precreadas) que se conservan y no molestan a Cargar.
with fechas as (
  select to_date('20260801','yyyymmdd') + level - 1 d
    from dual
   where level not in (13, 14, 29)
  connect by level <= 31
  union all
  select to_date('20261107','yyyymmdd') from dual
)
select 'TERMSTATY' tabla, to_char(t.ter_fecha, 'dd-mm-yyyy') fecha,
       t.ter_terminal, t.ter_estado, t.ter_cierrey
  from VTA_FACOTERMSTATY t
 where t.ter_fecha in (select f.d from fechas f) and t.ter_local = 5
 union all
 select 'TERMSTAT', to_char(s.ter_fecha, 'dd-mm-yyyy'), s.ter_terminal,
        s.ter_estado, null
  from vta_FACOtermstat s
 where s.ter_fecha in (select f.d from fechas f) and s.ter_local = 5
   and s.ter_estado in (1, 2)
 order by 1, 2, 3;

-- 9. Fechas objetivo: sobres y movimientos. ESPERADO: sin filas (no hay
--    que compensar nada en esta prueba; si hay, son de otra sesion:
--    no tocarlas, avisar).
with fechas as (
  select to_date('20260801','yyyymmdd') + level - 1 d
    from dual
   where level not in (13, 14, 29)
  connect by level <= 31
  union all
  select to_date('20261107','yyyymmdd') from dual
)
select 'PRD' tabla, to_char(p.prv_fechavta, 'dd-mm-yyyy') fecha, count(*) filas
  from vta_FACOprd p
 where p.prv_fechavta in (select f.d from fechas f) and p.prv_local = 5
 group by p.prv_fechavta
 union all
 select 'MOV', to_char(m.mov_fecha, 'dd-mm-yyyy'), count(*)
  from VTA_FACOMOVDET m
 where m.mov_fecha in (select f.d from fechas f) and m.mov_local = 5
 group by m.mov_fecha
 order by 1, 2;

exit
