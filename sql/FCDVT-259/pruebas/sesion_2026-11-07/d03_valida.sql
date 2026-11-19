-- =====================================================================
-- FCDVT-259 - pruebas/d03: validacion de SOLO LECTURA de lo que exporta
-- Form176 (PKG_F8_EXPORTA_MASIVA_YZ.fn_lineas)
-- xintec-nruz 16-11-2026 (antes FCDVT-14/pruebas_descargar)
-- xintec-nruz 19-11-2026 FCDVT-259: sesion 07-11-2026 (copia de pruebas/d03_valida.sql con las fechas cambiadas)
--
-- Datos: local 5, 07-11-2026 (d01 grabado y, segun el paso, d02 aplicado)
-- y 08-11-2026 (dia vacio).
-- Filtros de Form176 = local 5, terminal 0, inicio = fin = 07-11-2026.
-- Lo que debe salir en cada paso esta en README.md de esta carpeta.
-- =====================================================================

prompt === 1. Lineas que exporta Form176 (el CSV sin el encabezado)
prompt     ESPERADO: 9 lineas; por terminal la Z y despues sus Y por numero.
prompt     Despues de d02, la Z del terminal 2 es ARMADA:
prompt     07-11-2026;5;2;;20:15;2713;271388;71003;4202;Z;INGRESAR;1305500;-30000;104500;730000;35000;0;0;420000;0;230000;0;0;0;0;0;200000;-200000;35000;0;...;0
select rownum n, column_value linea
  from table(PKG_F8_EXPORTA_MASIVA_YZ.fn_lineas(5, 0, to_date('07-11-2026', 'dd-mm-yyyy'),
                                                to_date('07-11-2026', 'dd-mm-yyyy')));

prompt === 2. Conteo que muestra Form176 en "Resultado de la exportacion"
prompt     ESPERADO: 9 filas, 3 terminales, 6 Y y 3 Z (antes y despues de d02)
with l as (select ';' || column_value || ';' x
             from table(PKG_F8_EXPORTA_MASIVA_YZ.fn_lineas(5, 0, to_date('07-11-2026', 'dd-mm-yyyy'),
                                                           to_date('07-11-2026', 'dd-mm-yyyy')))),
     v as (select substr(x, 2, instr(x, ';', 1, 4) - 2) clave,
                  substr(x, instr(x, ';', 1, 10) + 1, instr(x, ';', 1, 11) - instr(x, ';', 1, 10) - 1) tipo
             from l)
select count(*) filas,
       count(distinct clave) terminales,
       sum(case when tipo = 'Y' then 1 else 0 end) y,
       sum(case when tipo = 'Z' then 1 else 0 end) z
  from v;

prompt === 3. Control automatico: en cada terminal, cada monto de la Z = suma de sus Y
prompt     (columnas 12 a 56; vale para la Z grabada y para la armada). ESPERADO: ninguna fila
with l as (select rownum rn, ';' || column_value || ';' x
             from table(PKG_F8_EXPORTA_MASIVA_YZ.fn_lineas(5, 0, to_date('07-11-2026', 'dd-mm-yyyy'),
                                                           to_date('07-11-2026', 'dd-mm-yyyy')))),
     e as (select ';' || PKG_F8_EXPORTA_MASIVA_YZ.fn_encabezado || ';' x from dual),
     c as (select level + 11 n from dual connect by level <= 45),
     v as (select substr(l.x, instr(l.x, ';', 1, 3) + 1, instr(l.x, ';', 1, 4) - instr(l.x, ';', 1, 3) - 1) term,
                  substr(l.x, instr(l.x, ';', 1, 10) + 1, instr(l.x, ';', 1, 11) - instr(l.x, ';', 1, 10) - 1) tipo,
                  c.n,
                  to_number(nvl(substr(l.x, instr(l.x, ';', 1, c.n) + 1,
                                       instr(l.x, ';', 1, c.n + 1) - instr(l.x, ';', 1, c.n) - 1), '0'),
                            '999999999999999999D9999', 'NLS_NUMERIC_CHARACTERS=''.,''') monto
             from l, c)
select v.term, v.n columna,
       (select substr(e.x, instr(e.x, ';', 1, v.n) + 1, instr(e.x, ';', 1, v.n + 1) - instr(e.x, ';', 1, v.n) - 1)
          from e) concepto,
       sum(case when v.tipo = 'Z' then v.monto else 0 end) monto_z,
       sum(case when v.tipo = 'Y' then v.monto else 0 end) suma_y
  from v
 group by v.term, v.n
having sum(case when v.tipo = 'Z' then v.monto else -v.monto end) <> 0
 order by 1, 2;

prompt === 4. Una Z por terminal y las Y de libvta (ESPERADO: Z_CSV = 1 en los 3; Y_CSV = Y_LIBVTA: 2, 3 y 1)
with l as (select ';' || column_value || ';' x
             from table(PKG_F8_EXPORTA_MASIVA_YZ.fn_lineas(5, 0, to_date('07-11-2026', 'dd-mm-yyyy'),
                                                           to_date('07-11-2026', 'dd-mm-yyyy')))),
     v as (select to_number(substr(l.x, instr(l.x, ';', 1, 3) + 1, instr(l.x, ';', 1, 4) - instr(l.x, ';', 1, 3) - 1)) term,
                  substr(l.x, instr(l.x, ';', 1, 10) + 1, instr(l.x, ';', 1, 11) - instr(l.x, ';', 1, 10) - 1) tipo
             from l)
select v.term,
       sum(case when v.tipo = 'Z' then 1 else 0 end) z_csv,
       sum(case when v.tipo = 'Y' then 1 else 0 end) y_csv,
       (select count(*) from VTA_FACOLIBVTA b
         where b.vta_fecha_venta = to_date('07-11-2026', 'dd-mm-yyyy') and b.vta_local = 5
           and b.vta_terminal = v.term and b.vta_tiporeg = 'Y' and b.vta_estado = 'A') y_libvta,
       (select count(*) from VTA_FACOLIBVTA b
         where b.vta_fecha_venta = to_date('07-11-2026', 'dd-mm-yyyy') and b.vta_local = 5
           and b.vta_terminal = v.term and b.vta_tiporeg = 'F8' and b.vta_estado = 'A') z_libvta
  from v
 group by v.term
 order by 1;

prompt === 5. Identificacion: HORA..CONT_REPOSICION de la Z contra la ultima Y de cada terminal
prompt     ESPERADO despues de d02: terminal 2 IGUAL = S (Z armada con la identificacion de la Y3: 20:15;2713;271388;71003;4202)
prompt     Terminales 1 y 3 (Z grabada, con la identificacion propia del CSV): IGUAL = N.
prompt     Antes de d02 los tres salen N (la Z del terminal 2 era 21:30;2719;271399;71009;4209).
with l as (select rownum rn, ';' || column_value || ';' x
             from table(PKG_F8_EXPORTA_MASIVA_YZ.fn_lineas(5, 0, to_date('07-11-2026', 'dd-mm-yyyy'),
                                                           to_date('07-11-2026', 'dd-mm-yyyy')))),
     v as (select rn,
                  substr(x, instr(x, ';', 1, 3) + 1, instr(x, ';', 1, 4) - instr(x, ';', 1, 3) - 1) term,
                  substr(x, instr(x, ';', 1, 10) + 1, instr(x, ';', 1, 11) - instr(x, ';', 1, 10) - 1) tipo,
                  substr(x, instr(x, ';', 1, 5) + 1, instr(x, ';', 1, 10) - instr(x, ';', 1, 5) - 1) ident
             from l)
select z.term, z.ident ident_z, y.ident ident_ultima_y,
       case when z.ident = y.ident then 'S' else 'N' end igual
  from v z, v y
 where z.tipo = 'Z'
   and y.tipo = 'Y'
   and y.term = z.term
   and y.rn = (select max(y2.rn) from v y2 where y2.term = z.term and y2.tipo = 'Y')
 order by 1;

prompt === 6. Filtro por terminal: solo el terminal 2 (ESPERADO: 4 lineas, la Z y sus 3 Y)
select rownum n, column_value linea
  from table(PKG_F8_EXPORTA_MASIVA_YZ.fn_lineas(5, 2, to_date('07-11-2026', 'dd-mm-yyyy'),
                                                to_date('07-11-2026', 'dd-mm-yyyy')));

prompt === 7. Terminal sin cierres (9) y dia sin cierres (08-11-2026) (ESPERADO: ninguna fila en las dos)
select column_value linea
  from table(PKG_F8_EXPORTA_MASIVA_YZ.fn_lineas(5, 9, to_date('07-11-2026', 'dd-mm-yyyy'),
                                                to_date('07-11-2026', 'dd-mm-yyyy')));
select column_value linea
  from table(PKG_F8_EXPORTA_MASIVA_YZ.fn_lineas(5, 0, to_date('08-11-2026', 'dd-mm-yyyy'),
                                                to_date('08-11-2026', 'dd-mm-yyyy')));

prompt === 8. Rango 07 a 08-11-2026 (ESPERADO: las mismas 9 lineas de la consulta 1)
select count(*) lineas
  from table(PKG_F8_EXPORTA_MASIVA_YZ.fn_lineas(5, 0, to_date('07-11-2026', 'dd-mm-yyyy'),
                                                to_date('08-11-2026', 'dd-mm-yyyy')));

prompt === 9. Fecha fin anterior a la de inicio (ESPERADO: ORA-20004 ... la fecha fin no puede ser anterior a la fecha inicio)
select column_value linea
  from table(PKG_F8_EXPORTA_MASIVA_YZ.fn_lineas(5, 0, to_date('08-11-2026', 'dd-mm-yyyy'),
                                                to_date('07-11-2026', 'dd-mm-yyyy')));
