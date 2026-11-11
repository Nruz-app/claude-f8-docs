-- =====================================================================
-- FCDVT-14 + FSCC-12901 - Sesion "crear Y con la carga masiva y
-- compensarla con DI" - py0: verificaciones de SOLO LECTURA.
-- xintec-nruz 06-11-2026
--
-- Fecha de venta 06-11-2026 (fecha libre; ninguna otra sesion la usa),
-- local 5, terminales 1 a 4, Y 1 en cada caja. Orden de la sesion:
--   1) Form174 (Ingreso del YYY Masivo): Buscar + Cargar el CSV
--      carga_Y_compensa.csv -> crea la Z y la Y 1 de las 4 cajas
--      (PKG_F8_GRABA_MASIVA_YZ REEMPLAZA lo que el terminal-dia tenga);
--   2) Form133 (Carga Manual de Sobres) por caja -> evalua la DI
--      automatica (PKG_F8_COMPENSA_DI_CARGA, rango -1.000 a +20.000).
-- Sobres de prueba: 501110601/02 (T1), 502110601/02 (T2), 503110601/02
-- (T3) y 504110601/02 (T4), ver LEEME.md.
-- Ejecutar conectado al usuario de test. Si las tablas no se ven sin
-- esquema:  alter session set current_schema = INTRANETTS;
-- Cada consulta indica su resultado ESPERADO.
-- =====================================================================

-- 1. Objetos de los tres paquetes. ESPERADO: PKG_F8_CARGA_MASIVA_YZ y
--    PKG_F8_GRABA_MASIVA_YZ (FCDVT-14), PKG_F8_COMPENSA_DI_CARGA
--    (FSCC-12901) en PACKAGE y PACKAGE BODY VALID del duenio; sus tablas
--    (VTA_FACOCARGA_YZ_DET/RES/LOG con sus secuencias,
--    VTA_FACOLOG_COMPENSA_DI con la suya). PKG_F8_CIERRE_AUTO y
--    PKG_F8_COMPENSA_DI_AUTO NO deben aparecer (desinstalados).
--    Con el usuario de aplicacion el PACKAGE BODY no aparece con este
--    select: la consulta 1b confirma que existe (si falta, da ORA-04067).
--    Un SYNONYM INVALID del usuario de aplicacion es normal (Oracle lo
--    revalida en el primer uso).
select owner, object_name, object_type, status
  from all_objects
 where object_name in ('PKG_F8_CARGA_MASIVA_YZ', 'PKG_F8_GRABA_MASIVA_YZ',
                       'PKG_F8_COMPENSA_DI_CARGA',
                       'VTA_FACOCARGA_YZ_DET', 'VTA_FACOCARGA_YZ_RES',
                       'VTA_FACOCARGA_YZ_LOG', 'SEQ_VTA_FACOCARGA_YZ',
                       'SEQ_VTA_FACOCARGA_YZ_LOG',
                       'VTA_FACOLOG_COMPENSA_DI', 'SEQ_VTA_FACOLOG_COMPENSA_DI',
                       'PKG_F8_CIERRE_AUTO', 'PKG_F8_COMPENSA_DI_AUTO')
 order by owner, object_name, object_type;

-- 1b. Body del paquete de compensacion. ESPERADO: 0 si la caja 5/1 del
--     06-11-2026 esta vacia (todavia no se crea la Y). Lo que importa:
--     que NO de ORA-04067 (falta el body) ni otros errores.
select PKG_F8_COMPENSA_DI_CARGA.fn_dif_real('FACO', to_date('20261106','yyyymmdd'), 5, 1, 1) dr
  from dual;

-- 2. Parametros 1502. ESPERADO: CA_DECIMAL 0, CA_DI_ACTIVO S, CA_DI_MAX
--    20000, CA_DI_MIN -1000 (los CD_ son del cron de cierre diario: no
--    ejecutarlo sobre el 06-11-2026 durante la prueba).
select trim(vta_ccodigo) codigo, '[' || vta_xglosa || ']' glosa
  from VTA_FACOPARAM where vta_ccodtipo = 1502 order by 1;

-- 3. Permiso 460 de la carga masiva (FCDVT-14). ESPERADO: fila 460 del
--    MenuPrincipal (VTA_FACOMENU) y filas por perfil en el 460 (10 y 11
--    en test). El usuario de prueba debe ver el submenu "Ingreso del YYY
--    Masivo" del boton Y: si no, falta la fila de su perfil (o el exe no
--    tiene la rama 460 de MDIForm1). El 15 es el permiso de ingreso de Y.
--    Misma union que SubBuscarOpcionMenu (MDIForm1).
select p.per_codigo, p.mnu_codigo, m.mnu_descripcion, p.rel_estado
  from VTA_FACORELPERMEN p, VTA_FACOMENU m
 where p.mnu_codigo = m.mnu_codigo
   and m.mnu_tipomenu = 'MenuPrincipal'
   and p.mnu_codigo in (15, 460)
 order by p.per_codigo, p.mnu_codigo;

-- 4. Cargas previas del dia en las tablas de carga masiva. ESPERADO:
--    sin filas (si hay, la prueba ya se ejecuto: usar py9_limpiar.sql).
select res_carga, to_char(res_fecha, 'dd-mm-yyyy') fecha, res_local, res_terminal,
       res_cant_y, res_total_y, res_cant_z, res_total_z, res_lin_error,
       res_estado, res_mensaje, res_usuario
  from VTA_FACOCARGA_YZ_RES
 where res_fecha = to_date('20261106','yyyymmdd')
   and res_local in (5)
 order by res_carga, res_terminal;

-- 5. Y ya existentes del dia en las 4 cajas. ESPERADO: sin filas.
--    Cargar REEMPLAZA: si hay una Y, se pierde (con su termstaty) y la
--    nueva queda con la numeracion del CSV.
select 'TERMSTATY' origen, y.ter_local local, y.ter_terminal terminal, y.ter_cierrey y,
       to_char(y.ter_estado) estado, y.ter_notas detalle
  from vta_FACOtermstaty y
 where y.ter_fecha = to_date('20261106','yyyymmdd')
   and y.ter_local = 5 and y.ter_terminal in (1, 2, 3, 4)
 union all
 select 'LIBVTA_Y', l.vta_local, l.vta_terminal, l.vta_secuencia, l.vta_estado,
        'techkey ' || l.vta_techkey
  from vta_FACOlibvta l
 where l.vta_tiporeg = 'Y' and l.vta_fecha_venta = to_date('20261106','yyyymmdd')
   and l.vta_local = 5 and l.vta_terminal in (1, 2, 3, 4)
 order by 1, 2, 3, 4;

-- 6. Estado de la Z (termstat) de las 4 cajas. ESPERADO: sin filas con
--    ter_estado 1 o 2 (Cargar rechaza el grupo; una precreada en -1 esta
--    bien: se conserva y no se borra al limpiar).
select ter_local, ter_terminal, ter_estado, ter_notas
  from vta_FACOtermstat
 where ter_fecha = to_date('20261106','yyyymmdd')
   and ter_local = 5 and ter_terminal in (1, 2, 3, 4);

-- 7. Sobres de la prueba ya cargados (Form133 compara numero + fecha de
--    venta y salta los que existen) y otros sobres F8 de las cajas ese
--    dia (se sumarian a la DR). ESPERADO: sin filas en las dos consultas.
select prv_local, prv_terminal, prv_sobre, prv_montosobre, prv_cierrey
  from vta_FACOprd
 where prv_fechavta = to_date('20261106','yyyymmdd')
   and prv_sobre in (501110601, 501110602, 502110601, 502110602,
                     503110601, 503110602, 504110601, 504110602);

select prv_local, prv_terminal, count(*) sobres, sum(prv_montosobre + nvl(prv_montodif, 0)) monto
  from vta_FACOprd
 where prv_fechavta = to_date('20261106','yyyymmdd')
   and prv_local = 5 and prv_terminal in (1, 2, 3, 4)
   and prv_tiporec = 'F8'
 group by prv_local, prv_terminal;

-- 8. Terminales vigentes y su tipo. ESPERADO: 4 filas (1, 2, 3 y 4 del
--    local 5), local en estado V y ter_tipo 0 (2 = Autopago, 1 = POS
--    Mobile). La T4 es la unica que no se uso en pruebas_cargar: si no
--    sale, reemplazarla con la consulta 10 en CSV + Excels + scripts.
select t.ter_local, l.vta_alias, l.vta_estado_local, t.ter_terminal,
       nvl(t.ter_tipo, 0) ter_tipo, t.ter_fechabaja
  from vta_FACOterminales t, vta_FACOlocales l
 where l.vta_cod_local = t.ter_local
   and t.ter_local = 5 and t.ter_terminal in (1, 2, 3, 4)
   and (t.ter_fechabaja >= to_date('20261106','yyyymmdd') or t.ter_fechabaja is null)
 order by t.ter_terminal;

-- 9. Movimientos ya registrados en las cajas (DI, compensaciones, cartas
--    aviso) que cambiarian la DR esperada. ESPERADO: sin filas.
select 'MOVDET' fuente, mov_local local, mov_terminal terminal, mov_tipomov tipo,
       count(*) filas, sum(mov_monto) monto
  from vta_FACOmovdet
 where mov_fecha = to_date('20261106','yyyymmdd')
   and mov_local = 5 and mov_terminal in (1, 2, 3, 4)
 group by mov_local, mov_terminal, mov_tipomov
 union all
 select 'CARTAAVISO', mov_local, mov_terminal, mov_tipomov, count(*), sum(mov_monto)
  from vta_FACOcartaaviso
 where mov_fecha = to_date('20261106','yyyymmdd')
   and mov_local = 5 and mov_terminal in (1, 2, 3, 4)
 group by mov_local, mov_terminal, mov_tipomov
 union all
 select 'TARJETAS 2000-2999', vta_local, vta_terminal, null, count(*), sum(vta_monto_inf)
  from vta_FACOtarj
 where vta_fecha = to_date('20261106','yyyymmdd')
   and vta_local = 5 and vta_terminal in (1, 2, 3, 4)
   and vta_cod_tarj between 2000 and 2999
 group by vta_local, vta_terminal
 union all
 select 'USD recmex 305', mex_local, mex_terminal, null, count(*), sum(mex_monto)
  from vta_FACOrecmex
 where mex_fecha = to_date('20261106','yyyymmdd')
   and mex_local = 5 and mex_terminal in (1, 2, 3, 4)
   and id_mdareg = 305
 group by mex_local, mex_terminal;

-- 10. Log de la DI del dia en el local 5. ESPERADO: sin filas (si hay,
--     la prueba ya se ejecuto: usar py9_limpiar.sql).
select log_id, log_local, log_terminal, log_cierrey, log_resultado, log_fechahora
  from VTA_FACOLOG_COMPENSA_DI
 where log_fecha_vta = to_date('20261106','yyyymmdd')
   and log_local = 5
 order by log_id;

-- 11. Terminales libres del local 5 el 06-11-2026 (por si hay que
--     reemplazar alguna): vigentes, tipo 0, sin Y, sin Z cerrada, sin
--     sobres F8 y sin movimientos ese dia.
select t.ter_terminal
  from vta_FACOterminales t
 where t.ter_local = 5
   and nvl(t.ter_tipo, 0) = 0
   and (t.ter_fechabaja >= to_date('20261106','yyyymmdd') or t.ter_fechabaja is null)
   and not exists (select 1 from vta_FACOtermstaty y
                    where y.ter_fecha = to_date('20261106','yyyymmdd')
                      and y.ter_local = t.ter_local and y.ter_terminal = t.ter_terminal)
   and not exists (select 1 from vta_FACOtermstat z
                    where z.ter_fecha = to_date('20261106','yyyymmdd')
                      and z.ter_local = t.ter_local and z.ter_terminal = t.ter_terminal
                      and z.ter_estado in (1, 2))
   and not exists (select 1 from vta_FACOprd p
                    where p.prv_fechavta = to_date('20261106','yyyymmdd')
                      and p.prv_local = t.ter_local and p.prv_terminal = t.ter_terminal)
   and not exists (select 1 from vta_FACOmovdet m
                    where m.mov_fecha = to_date('20261106','yyyymmdd')
                      and m.mov_local = t.ter_local and m.mov_terminal = t.ter_terminal)
 order by t.ter_terminal;
