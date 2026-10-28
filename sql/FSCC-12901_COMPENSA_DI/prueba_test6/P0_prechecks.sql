-- =====================================================================
-- FSCC-12901 COMPENSA_DI - Sesion de prueba 6 en test - P0: verificaciones
-- SOLO LECTURA. xintec-nruz 28-10-2026
-- Copia de ../prueba_test5/P0_prechecks.sql (misma prueba, fecha 14-10-2026).
--
-- Fecha de venta 14-10-2026, Y 1, 4 pruebas (cada una en otro local):
--   1 local 5  T27 DI negativa (-800)
--   2 local 25 T12 DI positiva (+15.000)
--   3 local 18 T10 sin DI (-5.000, fuera de rango)
--   4 local 19 T5  caso normal (DR 0)
-- Sobres de prueba <local><terminal 2 dig>1014<n> (8 en total, ver
-- Prueba-DI_Resumen.xlsx).
-- Ejecutar conectado al usuario de test. Si las tablas no se ven sin
-- esquema:  alter session set current_schema = INTRANETTS;
-- Cada consulta indica su resultado ESPERADO.
-- =====================================================================

-- 1. Objetos. ESPERADO: PKG_F8_COMPENSA_DI_CARGA (PACKAGE y PACKAGE BODY)
--    VALID, VTA_FACOLOG_COMPENSA_DI y su secuencia; PKG_F8_CIERRE_AUTO y
--    PKG_F8_COMPENSA_DI_AUTO NO deben aparecer (01_DESINSTALAR_v2.sql).
--    Con el usuario de aplicacion se ven tambien sus sinonimos: un SYNONYM
--    INVALID despues de reinstalar el paquete es normal (Oracle lo
--    revalida en el primer uso); lo que importa es el PACKAGE del duenio.
--    El PACKAGE BODY no aparece para el usuario de aplicacion: para
--    confirmar que existe, la consulta 1b debe devolver un numero (si falta
--    el body da ORA-04067).
select owner, object_name, object_type, status
  from all_objects
 where object_name in ('PKG_F8_COMPENSA_DI_CARGA', 'VTA_FACOLOG_COMPENSA_DI',
                       'SEQ_VTA_FACOLOG_COMPENSA_DI', 'PKG_F8_CIERRE_AUTO',
                       'PKG_F8_COMPENSA_DI_AUTO', 'TRG_VTA_FACOPRD_CIERRE_AI')
 order by owner, object_name, object_type;

-- 1b. Body del paquete (prueba 1 de ../prueba_test, ya ejecutada). ESPERADO: 0.
select PKG_F8_COMPENSA_DI_CARGA.fn_dif_real('FACO', to_date('20260831','yyyymmdd'), 6, 29, 1) dr
  from dual;

-- 2. Parametros 1502. ESPERADO: CA_DECIMAL 0, CA_DI_ACTIVO S,
--    CA_DI_MAX 20000, CA_DI_MIN -1000 (los CD_ son del cron de cierre
--    diario: no ejecutarlo sobre el 14-10-2026 durante la prueba).
select trim(vta_ccodigo) codigo, '[' || vta_xglosa || ']' glosa
  from VTA_FACOPARAM where vta_ccodtipo = 1502 order by 1;

-- 3. Y ya existentes del dia en las 4 cajas. ESPERADO: sin filas.
--    Si hay una Y, Form19Y asigna max+1 (no 1) y no cuadra con el Excel.
select 'TERMSTATY' origen, y.ter_local local, y.ter_terminal terminal, y.ter_cierrey y,
       to_char(y.ter_estado) estado, y.ter_cerradopor detalle
  from vta_FACOtermstaty y
 where y.ter_fecha = to_date('20261014','yyyymmdd')
   and (y.ter_local, y.ter_terminal) in ((5, 27), (25, 12), (18, 10), (19, 5))
union all
select 'LIBVTA_Y', l.vta_local, l.vta_terminal, l.vta_secuencia, l.vta_estado, 'techkey ' || l.vta_techkey
  from vta_FACOlibvta l
 where l.vta_tiporeg = 'Y' and l.vta_fecha_venta = to_date('20261014','yyyymmdd')
   and (l.vta_local, l.vta_terminal) in ((5, 27), (25, 12), (18, 10), (19, 5))
order by 1, 2, 3, 4;

-- 4. Z cerrada (Form19Y no deja ingresar la Y). ESPERADO: sin filas con
--    ter_estado 1 o 2 (en FACO la Z puede estar precreada en -1).
select ter_local, ter_terminal, ter_estado, ter_notas
  from vta_FACOtermstat
 where ter_fecha = to_date('20261014','yyyymmdd')
   and (ter_local, ter_terminal) in ((5, 27), (25, 12), (18, 10), (19, 5));

-- 5. Sobres de la prueba ya cargados (Form133 compara numero + fecha de
--    venta y salta los que existen). ESPERADO: sin filas.
select prv_local, prv_terminal, prv_sobre, prv_montosobre, prv_cierrey
  from vta_FACOprd
 where prv_fechavta = to_date('20261014','yyyymmdd')
   and prv_sobre in (527101401, 527101402, 2512101401, 2512101402,
                     1810101401, 1810101402, 1905101401, 1905101402);

-- 5b. Otros sobres F8 de las cajas ese dia (se sumarian a la DR). ESPERADO: sin filas.
select prv_local, prv_terminal, count(*) sobres, sum(prv_montosobre + nvl(prv_montodif, 0)) monto
  from vta_FACOprd
 where prv_fechavta = to_date('20261014','yyyymmdd')
   and (prv_local, prv_terminal) in ((5, 27), (25, 12), (18, 10), (19, 5))
   and prv_tiporec = 'F8'
 group by prv_local, prv_terminal;

-- 6. Locales vigentes y terminales con su tipo. ESPERADO: 4 filas,
--    estado de local V y ter_tipo 0 (2 = Autopago, 1 = POS Mobile).
select t.ter_local, l.vta_alias, l.vta_estado_local, t.ter_terminal,
       nvl(t.ter_tipo, 0) ter_tipo, t.ter_fechabaja
  from vta_FACOterminales t, vta_FACOlocales l
 where l.vta_cod_local = t.ter_local
   and (t.ter_local, t.ter_terminal) in ((5, 27), (25, 12), (18, 10), (19, 5))
   and (t.ter_fechabaja >= to_date('20261014','yyyymmdd') or t.ter_fechabaja is null)
 order by t.ter_local, t.ter_terminal;

-- 7. Movimientos ya registrados en las cajas (DI, compensaciones, cartas
--    aviso) que cambiarian la DR esperada. ESPERADO: sin filas.
select 'MOVDET' fuente, mov_local local, mov_terminal terminal, mov_tipomov tipo, count(*) filas, sum(mov_monto) monto
  from vta_FACOmovdet
 where mov_fecha = to_date('20261014','yyyymmdd')
   and (mov_local, mov_terminal) in ((5, 27), (25, 12), (18, 10), (19, 5))
 group by mov_local, mov_terminal, mov_tipomov
union all
select 'CARTAAVISO', mov_local, mov_terminal, mov_tipomov, count(*), sum(mov_monto)
  from vta_FACOcartaaviso
 where mov_fecha = to_date('20261014','yyyymmdd')
   and (mov_local, mov_terminal) in ((5, 27), (25, 12), (18, 10), (19, 5))
 group by mov_local, mov_terminal, mov_tipomov
union all
select 'TARJETAS 2000-2999', vta_local, vta_terminal, null, count(*), sum(vta_monto_inf)
  from vta_FACOtarj
 where vta_fecha = to_date('20261014','yyyymmdd')
   and (vta_local, vta_terminal) in ((5, 27), (25, 12), (18, 10), (19, 5))
   and vta_cod_tarj between 2000 and 2999
 group by vta_local, vta_terminal
union all
select 'USD recmex 305', mex_local, mex_terminal, null, count(*), sum(mex_monto)
  from vta_FACOrecmex
 where mex_fecha = to_date('20261014','yyyymmdd')
   and (mex_local, mex_terminal) in ((5, 27), (25, 12), (18, 10), (19, 5))
   and id_mdareg = 305
 group by mex_local, mex_terminal;

-- 8. Log del dia en los 4 locales. ESPERADO: sin filas (si hay, la prueba
--    ya se ejecuto: usar P9_limpiar.sql para repetirla).
select log_id, log_local, log_terminal, log_cierrey, log_resultado, log_fechahora
  from VTA_FACOLOG_COMPENSA_DI
 where log_fecha_vta = to_date('20261014','yyyymmdd')
   and log_local in (5, 25, 18, 19)
 order by log_id;

-- 9. Terminales libres de los locales 5, 25, 18 y 19 el 14-10-2026 (por si
--    hay que cambiar alguna): vigentes, tipo 0, sin Y, sin Z cerrada y sin sobres.
select t.ter_local, t.ter_terminal
  from vta_FACOterminales t
 where t.ter_local in (5, 25, 18, 19)
   and nvl(t.ter_tipo, 0) = 0
   and (t.ter_fechabaja >= to_date('20261014','yyyymmdd') or t.ter_fechabaja is null)
   and not exists (select 1 from vta_FACOtermstaty y
                    where y.ter_fecha = to_date('20261014','yyyymmdd')
                      and y.ter_local = t.ter_local and y.ter_terminal = t.ter_terminal)
   and not exists (select 1 from vta_FACOtermstat z
                    where z.ter_fecha = to_date('20261014','yyyymmdd')
                      and z.ter_local = t.ter_local and z.ter_terminal = t.ter_terminal
                      and z.ter_estado in (1, 2))
   and not exists (select 1 from vta_FACOprd p
                    where p.prv_fechavta = to_date('20261014','yyyymmdd')
                      and p.prv_local = t.ter_local and p.prv_terminal = t.ter_terminal)
 order by t.ter_local, t.ter_terminal;
