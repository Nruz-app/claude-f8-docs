-- =====================================================================
-- FCDVT-14 - pruebas_descargar/d03: validacion de SOLO LECTURA de lo que
-- descarga Form174 (PKG_F8_EXPORTA_MASIVA_YZ.fn_lineas / fn_resumen)
-- xintec-nruz 16-11-2026
--
-- Datos: local 5, 27-10-2026 (d01 grabado y, segun el paso, d02 aplicado)
-- y 28-10-2026 (dia vacio). Si se cambiaron las fechas, EDITAR cada consulta.
-- Lo que debe salir en cada paso esta en README.md de esta carpeta.
-- =====================================================================

prompt === 1. Lineas que descarga Form174 (hoja Carga, desde la fila 2)
prompt     ESPERADO: 9 lineas; por terminal la Z y despues sus Y por numero.
prompt     Despues de d02, la Z del terminal 2 es ARMADA:
prompt     27-10-2026;5;2;;20:15;2713;271388;71003;4202;Z;INGRESAR;1305500;-30000;104500;730000;35000;0;0;420000;0;230000;0;0;0;0;0;200000;-200000;35000;0;...;0
select rownum n, column_value linea
  from table(PKG_F8_EXPORTA_MASIVA_YZ.fn_lineas('FACO', 5, to_date('27-10-2026', 'dd-mm-yyyy')));

prompt === 2. Resumen (hoja Resumen): TERMINAL;CANT_Y;TOTAL_Y;TOTAL_Z;DIFERENCIA;ESTADO_Z;Y_CERRADAS;Z_ARMADA
prompt     ESPERADO antes de d02:  1;2;800000;800000;0;-1;0;N  2;3;1380000;1380000;0;-1;0;N  3;1;150000;150000;0;-1;0;N
prompt     ESPERADO despues de d02: la fila 2 pasa a 2;3;1380000;0;-1380000;-1;0;S
select rownum n, column_value resumen
  from table(PKG_F8_EXPORTA_MASIVA_YZ.fn_resumen('FACO', 5, to_date('27-10-2026', 'dd-mm-yyyy')));

prompt === 3. Control automatico: en cada terminal, cada monto de la Z = suma de sus Y
prompt     (columnas 12 a 56; vale para la Z grabada y para la armada). ESPERADO: ninguna fila
with l as (select rownum rn, ';' || column_value || ';' x
             from table(PKG_F8_EXPORTA_MASIVA_YZ.fn_lineas('FACO', 5, to_date('27-10-2026', 'dd-mm-yyyy')))),
     e as (select ';' || PKG_F8_EXPORTA_MASIVA_YZ.fn_encabezado('FACO') || ';' x from dual),
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

prompt === 4. Una Z por terminal y las Y de libvta (ESPERADO: Z_EXCEL = 1 en los 3; Y_EXCEL = Y_LIBVTA: 2, 3 y 1)
with l as (select ';' || column_value || ';' x
             from table(PKG_F8_EXPORTA_MASIVA_YZ.fn_lineas('FACO', 5, to_date('27-10-2026', 'dd-mm-yyyy')))),
     v as (select to_number(substr(l.x, instr(l.x, ';', 1, 3) + 1, instr(l.x, ';', 1, 4) - instr(l.x, ';', 1, 3) - 1)) term,
                  substr(l.x, instr(l.x, ';', 1, 10) + 1, instr(l.x, ';', 1, 11) - instr(l.x, ';', 1, 10) - 1) tipo
             from l)
select v.term,
       sum(case when v.tipo = 'Z' then 1 else 0 end) z_excel,
       sum(case when v.tipo = 'Y' then 1 else 0 end) y_excel,
       (select count(*) from VTA_FACOLIBVTA b
         where b.vta_fecha_venta = to_date('27-10-2026', 'dd-mm-yyyy') and b.vta_local = 5
           and b.vta_terminal = v.term and b.vta_tiporeg = 'Y' and b.vta_estado = 'A') y_libvta,
       (select count(*) from VTA_FACOLIBVTA b
         where b.vta_fecha_venta = to_date('27-10-2026', 'dd-mm-yyyy') and b.vta_local = 5
           and b.vta_terminal = v.term and b.vta_tiporeg = 'F8' and b.vta_estado = 'A') z_libvta
  from v
 group by v.term
 order by 1;

prompt === 5. Identificacion: HORA..CONT_REPOSICION de la Z contra la ultima Y de cada terminal
prompt     ESPERADO despues de d02: terminal 2 IGUAL = S (Z armada con la identificacion de la Y3: 20:15;2713;271388;71003;4202)
prompt     Terminales 1 y 3 (Z grabada, con la identificacion propia del CSV): IGUAL = N.
prompt     Antes de d02 los tres salen N (la Z del terminal 2 era 21:30;2719;271399;71009;4209).
with l as (select rownum rn, ';' || column_value || ';' x
             from table(PKG_F8_EXPORTA_MASIVA_YZ.fn_lineas('FACO', 5, to_date('27-10-2026', 'dd-mm-yyyy')))),
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

prompt === 6. Dia sin cierres, 28-10-2026 (ESPERADO: ninguna fila en las dos consultas)
select column_value linea
  from table(PKG_F8_EXPORTA_MASIVA_YZ.fn_lineas('FACO', 5, to_date('28-10-2026', 'dd-mm-yyyy')));
select column_value resumen
  from table(PKG_F8_EXPORTA_MASIVA_YZ.fn_resumen('FACO', 5, to_date('28-10-2026', 'dd-mm-yyyy')));

prompt === 7. Pais no habilitado (ESPERADO: ORA-20001 PKG_F8_EXPORTA_MASIVA_YZ: pais no habilitado (ARG))
select column_value linea
  from table(PKG_F8_EXPORTA_MASIVA_YZ.fn_lineas('ARG', 5, to_date('27-10-2026', 'dd-mm-yyyy')));
