-- =====================================================================
-- FSCC-12901 COMPENSA_DI - Sesion de prueba en test - P0: verificaciones
-- SOLO LECTURA. xintec-nruz 19-10-2026
--
-- Local 6, fecha de venta 31-08-2026, Y 1, 4 pruebas (una por terminal, ya
-- existen en test): 1 T29 DI negativa (-800), 2 T40 DI positiva (+15.000),
-- 3 T31 sin DI (-5.000, fuera de rango), 4 T24 caso normal (DR 0). Sobres
-- de prueba <terminal>0831000n (8 en total, ver Prueba-DI_Resumen.xlsx).
-- Ejecutar conectado al usuario de test. Si las tablas no se ven sin
-- esquema:  alter session set current_schema = INTRANETTS;
-- Cada consulta indica su resultado ESPERADO.
-- =====================================================================

-- 1. Objetos. ESPERADO: PKG_F8_COMPENSA_DI_CARGA (PACKAGE y PACKAGE BODY)
--    VALID, VTA_FACOLOG_COMPENSA_DI y su secuencia; PKG_F8_CIERRE_AUTO y
--    PKG_F8_COMPENSA_DI_AUTO NO deben aparecer (01_DESINSTALAR_v2.sql).
select object_name, object_type, status
  from user_objects
 where object_name in ('PKG_F8_COMPENSA_DI_CARGA', 'VTA_FACOLOG_COMPENSA_DI',
                       'SEQ_VTA_FACOLOG_COMPENSA_DI', 'PKG_F8_CIERRE_AUTO',
                       'PKG_F8_COMPENSA_DI_AUTO', 'TRG_VTA_FACOPRD_CIERRE_AI')
 order by object_name, object_type;

-- 2. Parametros 1502. ESPERADO: CA_DECIMAL 0, CA_DI_ACTIVO S,
--    CA_DI_MAX 20000, CA_DI_MIN -1000 (y ningun otro CA_).
select trim(vta_ccodigo) codigo, '[' || vta_xglosa || ']' glosa
  from VTA_FACOPARAM where vta_ccodtipo = 1502 order by 1;

-- 3. Y ya existentes del dia en las 4 cajas. ESPERADO: sin filas.
--    Si hay una Y, Form19Y asigna max+1 (no 1) y no cuadra con el Excel.
select 'TERMSTATY' origen, y.ter_terminal terminal, y.ter_cierrey y,
       to_char(y.ter_estado) estado, y.ter_cerradopor detalle
  from vta_FACOtermstaty y
 where y.ter_fecha = to_date('20260831','yyyymmdd') and y.ter_local = 6
   and y.ter_terminal in (29, 40, 31, 24)
union all
select 'LIBVTA_Y', l.vta_terminal, l.vta_secuencia, l.vta_estado, 'techkey ' || l.vta_techkey
  from vta_FACOlibvta l
 where l.vta_tiporeg = 'Y' and l.vta_fecha_venta = to_date('20260831','yyyymmdd')
   and l.vta_local = 6 and l.vta_terminal in (29, 40, 31, 24)
order by 1, 2, 3;

-- 4. Z cerrada (Form19Y no deja ingresar la Y). ESPERADO: sin filas con
--    ter_estado 1 o 2 (en FACO la Z puede estar precreada en -1).
select ter_terminal, ter_estado, ter_notas
  from vta_FACOtermstat
 where ter_fecha = to_date('20260831','yyyymmdd') and ter_local = 6
   and ter_terminal in (29, 40, 31, 24);

-- 5. Sobres de la prueba ya cargados (Form133 compara numero + fecha de
--    venta y salta los que existen). ESPERADO: sin filas.
select prv_local, prv_terminal, prv_sobre, prv_montosobre, prv_cierrey
  from vta_FACOprd
 where prv_fechavta = to_date('20260831','yyyymmdd')
   and prv_sobre in (2908310001, 2908310002, 4008310001, 4008310002,
                     3108310001, 3108310002, 2408310001, 2408310002);

-- 5b. Otros sobres F8 de las cajas ese dia (se sumarian a la DR). ESPERADO: sin filas.
select prv_terminal, count(*) sobres, sum(prv_montosobre + nvl(prv_montodif, 0)) monto
  from vta_FACOprd
 where prv_fechavta = to_date('20260831','yyyymmdd') and prv_local = 6
   and prv_terminal in (29, 40, 31, 24) and prv_tiporec = 'F8'
 group by prv_terminal;

-- 6. Terminales vigentes y tipo. ESPERADO: 4 filas, ter_tipo 0
--    (2 = Autopago, 1 = POS Mobile).
select ter_terminal, nvl(ter_tipo, 0) ter_tipo, ter_fechabaja
  from vta_FACOterminales
 where ter_local = 6 and ter_terminal in (29, 40, 31, 24)
   and (ter_fechabaja >= to_date('20260831','yyyymmdd') or ter_fechabaja is null)
 order by ter_terminal;

-- 7. Movimientos ya registrados en las cajas (DI, compensaciones, cartas
--    aviso) que cambiarian la DR esperada. ESPERADO: sin filas.
select 'MOVDET' fuente, mov_terminal terminal, mov_tipomov tipo, count(*) filas, sum(mov_monto) monto
  from vta_FACOmovdet
 where mov_fecha = to_date('20260831','yyyymmdd') and mov_local = 6
   and mov_terminal in (29, 40, 31, 24)
 group by mov_terminal, mov_tipomov
union all
select 'CARTAAVISO', mov_terminal, mov_tipomov, count(*), sum(mov_monto)
  from vta_FACOcartaaviso
 where mov_fecha = to_date('20260831','yyyymmdd') and mov_local = 6
   and mov_terminal in (29, 40, 31, 24)
 group by mov_terminal, mov_tipomov
union all
select 'TARJETAS 2000-2999', vta_terminal, null, count(*), sum(vta_monto_inf)
  from vta_FACOtarj
 where vta_fecha = to_date('20260831','yyyymmdd') and vta_local = 6
   and vta_terminal in (29, 40, 31, 24) and vta_cod_tarj between 2000 and 2999
 group by vta_terminal
union all
select 'USD recmex 305', mex_terminal, null, count(*), sum(mex_monto)
  from vta_FACOrecmex
 where mex_fecha = to_date('20260831','yyyymmdd') and mex_local = 6
   and mex_terminal in (29, 40, 31, 24) and id_mdareg = 305
 group by mex_terminal;

-- 8. Log del dia. ESPERADO: sin filas (si hay, la prueba ya se ejecuto:
--    usar P9_limpiar.sql para repetirla).
select log_id, log_terminal, log_cierrey, log_resultado, log_fechahora
  from VTA_FACOLOG_COMPENSA_DI
 where log_fecha_vta = to_date('20260831','yyyymmdd') and log_local = 6
 order by log_id;

-- 9. Terminales libres del local 6 el 31-08-2026 (por si hay que cambiar
--    alguna): vigentes, tipo 0, sin Y, sin Z cerrada y sin sobres.
select t.ter_terminal
  from vta_FACOterminales t
 where t.ter_local = 6
   and nvl(t.ter_tipo, 0) = 0
   and (t.ter_fechabaja >= to_date('20260831','yyyymmdd') or t.ter_fechabaja is null)
   and not exists (select 1 from vta_FACOtermstaty y
                    where y.ter_fecha = to_date('20260831','yyyymmdd')
                      and y.ter_local = t.ter_local and y.ter_terminal = t.ter_terminal)
   and not exists (select 1 from vta_FACOtermstat z
                    where z.ter_fecha = to_date('20260831','yyyymmdd')
                      and z.ter_local = t.ter_local and z.ter_terminal = t.ter_terminal
                      and z.ter_estado in (1, 2))
   and not exists (select 1 from vta_FACOprd p
                    where p.prv_fechavta = to_date('20260831','yyyymmdd')
                      and p.prv_local = t.ter_local and p.prv_terminal = t.ter_terminal)
 order by t.ter_terminal;
