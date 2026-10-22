-- =====================================================================
-- FSCC-12901 COMPENSA_DI - Prueba en test con 6 locales - P0: verificaciones
-- SOLO LECTURA. xintec-nruz 20-10-2026
--
-- Misma prueba que ../prueba_test, con 6 locales por archivo (24 cajas).
-- Fecha de venta 30-08-2026, Y 1. Locales 6, 18, 25, 35, 36 y 38.
-- Pruebas (una terminal por prueba, la misma en los 6 locales):
--   1 T29 DI negativa (-1 a -1.000), 2 T40 DI positiva (+1 a +20.000),
--   3 T31 fuera de rango (-1.001, -5.000, -50.000, +20.001, +25.000,
--   +100.000), 4 T24 caso normal (DR 0).
-- Sobres de prueba: <terminal>0830<local 3 digitos><1|2> (48 en total, ver
-- Prueba-DI_Resumen.xlsx, hoja Sobres).
-- Ejecutar conectado al usuario de test. Si las tablas no se ven sin
-- esquema:  alter session set current_schema = INTRANETTS;
-- Cada consulta indica su resultado ESPERADO.
-- =====================================================================

-- 1. Objetos. ESPERADO: PKG_F8_COMPENSA_DI_CARGA (PACKAGE y PACKAGE BODY)
--    VALID, VTA_FACOLOG_COMPENSA_DI y su secuencia; PKG_F8_CIERRE_AUTO y
--    PKG_F8_COMPENSA_DI_AUTO NO deben aparecer (01_DESINSTALAR_v2.sql).
--    OJO: conectado como uintranetts, USER_OBJECTS muestra los SINONIMOS (no
--    el paquete). El sinonimo puede salir INVALID despues de recompilar el
--    paquete: es normal, Oracle lo revalida en el primer uso. Lo que importa
--    es el paquete del duenio (consulta 1b).
select object_name, object_type, status
  from user_objects
 where object_name in ('PKG_F8_COMPENSA_DI_CARGA', 'VTA_FACOLOG_COMPENSA_DI',
                       'SEQ_VTA_FACOLOG_COMPENSA_DI', 'PKG_F8_CIERRE_AUTO',
                       'PKG_F8_COMPENSA_DI_AUTO', 'TRG_VTA_FACOPRD_CIERRE_AI')
 order by object_name, object_type;

-- 1b. El paquete en el esquema duenio. ESPERADO: INTRANETTS PACKAGE VALID
--     (el PACKAGE BODY solo aparece si se ejecuta como el duenio).
select owner, object_name, object_type, status, last_ddl_time
  from all_objects
 where object_name = 'PKG_F8_COMPENSA_DI_CARGA' and object_type like 'PACKAGE%'
 order by owner, object_type;

-- 2. Parametros 1502. ESPERADO: CA_DECIMAL 0, CA_DI_ACTIVO S,
--    CA_DI_MAX 20000, CA_DI_MIN -1000 (los CD_ son del cron diario).
select trim(vta_ccodigo) codigo, '[' || vta_xglosa || ']' glosa
  from VTA_FACOPARAM where vta_ccodtipo = 1502 order by 1;

-- 3. Y ya existentes del dia en las 24 cajas. ESPERADO: sin filas.
--    Si hay una Y, Form19Y asigna max+1 (no 1) y no cuadra con el Excel.
select 'TERMSTATY' origen, y.ter_local local, y.ter_terminal terminal, y.ter_cierrey y,
       to_char(y.ter_estado) estado, y.ter_cerradopor detalle
  from vta_FACOtermstaty y
 where y.ter_fecha = to_date('20260830','yyyymmdd')
   and y.ter_local in (6, 18, 25, 35, 36, 38)
   and y.ter_terminal in (29, 40, 31, 24)
union all
select 'LIBVTA_Y', l.vta_local, l.vta_terminal, l.vta_secuencia, l.vta_estado, 'techkey ' || l.vta_techkey
  from vta_FACOlibvta l
 where l.vta_tiporeg = 'Y' and l.vta_fecha_venta = to_date('20260830','yyyymmdd')
   and l.vta_local in (6, 18, 25, 35, 36, 38) and l.vta_terminal in (29, 40, 31, 24)
order by 1, 2, 3, 4;

-- 4. Z cerrada (Form19Y no deja ingresar la Y). ESPERADO: sin filas con
--    ter_estado 1 o 2 (en FACO la Z puede estar precreada en -1).
select ter_local, ter_terminal, ter_estado, ter_notas
  from vta_FACOtermstat
 where ter_fecha = to_date('20260830','yyyymmdd')
   and ter_local in (6, 18, 25, 35, 36, 38)
   and ter_terminal in (29, 40, 31, 24)
 order by 1, 2;

-- 5. Sobres de la prueba ya cargados (Form133 compara numero + fecha de
--    venta y salta los que existen). ESPERADO: sin filas.
select prv_local, prv_terminal, prv_sobre, prv_montosobre, prv_cierrey
  from vta_FACOprd
 where prv_fechavta = to_date('20260830','yyyymmdd')
   and length(to_char(prv_sobre)) = 10
   and substr(to_char(prv_sobre), 1, 6) in ('290830', '400830', '310830', '240830')
 order by 1, 2, 3;

-- 5b. Otros sobres F8 de las cajas ese dia (se sumarian a la DR). ESPERADO: sin filas.
select prv_local, prv_terminal, count(*) sobres, sum(prv_montosobre + nvl(prv_montodif, 0)) monto
  from vta_FACOprd
 where prv_fechavta = to_date('20260830','yyyymmdd')
   and prv_local in (6, 18, 25, 35, 36, 38)
   and prv_terminal in (29, 40, 31, 24) and prv_tiporec = 'F8'
 group by prv_local, prv_terminal
 order by 1, 2;

-- 6. Terminales vigentes y tipo. ESPERADO: 24 filas, ter_tipo 0
--    (2 = Autopago, 1 = POS Mobile).
select ter_local, ter_terminal, nvl(ter_tipo, 0) ter_tipo, ter_fechabaja
  from vta_FACOterminales
 where ter_local in (6, 18, 25, 35, 36, 38) and ter_terminal in (29, 40, 31, 24)
   and (ter_fechabaja >= to_date('20260830','yyyymmdd') or ter_fechabaja is null)
 order by ter_local, ter_terminal;

-- 6b. Locales vigentes. ESPERADO: 6 filas, estado V.
select vta_cod_local, vta_alias, vta_estado_local, vta_fechabaja
  from vta_FACOlocales
 where vta_cod_local in (6, 18, 25, 35, 36, 38)
 order by 1;

-- 7. Movimientos ya registrados en las cajas (DI, compensaciones, cartas
--    aviso, tarjetas, dolares) que cambiarian la DR esperada. ESPERADO: sin filas.
select 'MOVDET' fuente, mov_local local, mov_terminal terminal, mov_tipomov tipo, count(*) filas, sum(mov_monto) monto
  from vta_FACOmovdet
 where mov_fecha = to_date('20260830','yyyymmdd')
   and mov_local in (6, 18, 25, 35, 36, 38) and mov_terminal in (29, 40, 31, 24)
 group by mov_local, mov_terminal, mov_tipomov
union all
select 'CARTAAVISO', mov_local, mov_terminal, mov_tipomov, count(*), sum(mov_monto)
  from vta_FACOcartaaviso
 where mov_fecha = to_date('20260830','yyyymmdd')
   and mov_local in (6, 18, 25, 35, 36, 38) and mov_terminal in (29, 40, 31, 24)
 group by mov_local, mov_terminal, mov_tipomov
union all
select 'TARJETAS 2000-2999', vta_local, vta_terminal, null, count(*), sum(vta_monto_inf)
  from vta_FACOtarj
 where vta_fecha = to_date('20260830','yyyymmdd')
   and vta_local in (6, 18, 25, 35, 36, 38) and vta_terminal in (29, 40, 31, 24)
   and vta_cod_tarj between 2000 and 2999
 group by vta_local, vta_terminal
union all
select 'USD recmex 305', mex_local, mex_terminal, null, count(*), sum(mex_monto)
  from vta_FACOrecmex
 where mex_fecha = to_date('20260830','yyyymmdd')
   and mex_local in (6, 18, 25, 35, 36, 38) and mex_terminal in (29, 40, 31, 24)
   and id_mdareg = 305
 group by mex_local, mex_terminal;

-- 8. Log del dia. ESPERADO: sin filas (si hay, la prueba ya se ejecuto:
--    usar P9_limpiar.sql para repetirla).
select log_id, log_local, log_terminal, log_cierrey, log_resultado, log_fechahora
  from VTA_FACOLOG_COMPENSA_DI
 where log_fecha_vta = to_date('20260830','yyyymmdd')
   and log_local in (6, 18, 25, 35, 36, 38)
 order by log_id;

-- 9. Terminales libres de los 6 locales el 30-08-2026 (por si hay que
--    cambiar alguna): vigentes, tipo 0, sin Y, sin Z cerrada y sin sobres.
select t.ter_local, t.ter_terminal
  from vta_FACOterminales t
 where t.ter_local in (6, 18, 25, 35, 36, 38)
   and nvl(t.ter_tipo, 0) = 0
   and (t.ter_fechabaja >= to_date('20260830','yyyymmdd') or t.ter_fechabaja is null)
   and not exists (select 1 from vta_FACOtermstaty y
                    where y.ter_fecha = to_date('20260830','yyyymmdd')
                      and y.ter_local = t.ter_local and y.ter_terminal = t.ter_terminal)
   and not exists (select 1 from vta_FACOtermstat z
                    where z.ter_fecha = to_date('20260830','yyyymmdd')
                      and z.ter_local = t.ter_local and z.ter_terminal = t.ter_terminal
                      and z.ter_estado in (1, 2))
   and not exists (select 1 from vta_FACOprd p
                    where p.prv_fechavta = to_date('20260830','yyyymmdd')
                      and p.prv_local = t.ter_local and p.prv_terminal = t.ter_terminal)
 order by t.ter_local, t.ter_terminal;
