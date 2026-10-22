-- =====================================================================
-- FSCC-12957 (HU-01-T1) Compensacion automatica de DI - Falabella Colombia
-- 06 - Pruebas (ambiente de TEST). Ejecutar paso a paso.
-- Sin variables de sustitucion de SQL*Plus: cada prueba trae al inicio los valores
-- de la caja a probar, marcados EDITAR (fecha dd-mm-yyyy, local, terminal,
-- cierre Y). Asi funciona igual en SQL*Plus y en DBeaver (07-10-2026).
-- Ejemplo: 28-08-2026, local 6, terminal 4, Y 1 = primera caja del dia PRD 3 que
-- crea la POC en desarrollo (docs/sql/FSCC-12901_POC/). Cambiar por una caja real.
-- =====================================================================
set serveroutput on size 100000
set linesize 220 pagesize 200

-- 0. Compilacion (esperado: VALID en ambos paquetes)
select object_name, object_type, status from all_objects
 where owner = sys_context('USERENV','CURRENT_SCHEMA')
   and object_name in ('PKG_F8_FACO_COMPENSA_DI', 'PKG_F8_FACO_CIERRE_AUTO');
select name, line, position, text from all_errors
 where owner = sys_context('USERENV','CURRENT_SCHEMA')
   and name in ('PKG_F8_FACO_COMPENSA_DI', 'PKG_F8_FACO_CIERRE_AUTO') order by name, sequence;

-- 1. Simulacion sin grabar: que haria T1 con cada caja pendiente de la cola
declare
  v_dr  number;
  v_res varchar2(30);
begin
  for c in (select cc_fecha f, cc_local l, cc_terminal t, cc_cierrey y
              from VTA_FACOV_CAJAS_CIERRE   -- FSCC-12901: universo comun (cola + sin sobres)
             order by 1, 2, 3, 4) loop
    v_res := PKG_F8_FACO_COMPENSA_DI.fn_evalua_caja(c.f, c.l, c.t, c.y, v_dr);
    dbms_output.put_line(to_char(c.f, 'dd-mm-yyyy') || ' ' || c.l || '/' || c.t || ' Y' || c.y ||
                         ' DR=' || nvl(to_char(v_dr), 'null') || ' -> ' || v_res);
  end loop;
end;
/

-- 2. Una caja puntual
declare
  v_dr  number;
  -- EDITAR: caja a probar (tomar una fila del resultado de la prueba de la DR)
  v_fecha    date   := to_date('28-08-2026','dd-mm-yyyy');
  v_local    number := 6;
  v_terminal number := 4;
  v_cierrey  number := 1;
begin
  dbms_output.put_line(PKG_F8_FACO_COMPENSA_DI.fn_evalua_caja(
      v_fecha, v_local, v_terminal, v_cierrey, v_dr) || ' DR=' || v_dr);
  dbms_output.put_line('DI existentes: ' || PKG_F8_FACO_COMPENSA_DI.fn_estado_di(
      v_fecha, v_local, v_terminal, v_cierrey));
end;
/

-- 3. Ejecutar solo T1 (sin cierre)
begin
  PKG_F8_FACO_COMPENSA_DI.prc_compensa_di;
end;
/

-- 4. Ejecutar T1 + T2 (flujo completo, como lo hara el job)
begin
  PKG_F8_FACO_CIERRE_AUTO.prc_cierre_automatico;
end;
/

-- 5. Resumen de la ultima ejecucion (T1 y T2)
select l.log_proceso, l.log_nivel, l.log_fecha_vta, l.log_local, l.log_terminal, l.log_cierrey,
       l.log_dif_real, l.log_resultado, l.log_regla, l.log_mensaje
  from VTA_FACOLOG_CIERRE_AUTO l
 where l.log_ejecucion = (select max(log_ejecucion) from VTA_FACOLOG_CIERRE_AUTO)
 order by l.log_id;

select log_proceso, log_resultado, count(*)
  from VTA_FACOLOG_CIERRE_AUTO
 where log_ejecucion = (select max(log_ejecucion) from VTA_FACOLOG_CIERRE_AUTO)
 group by log_proceso, log_resultado order by 1, 2;

-- 6. DI automaticas registradas y su glosa
select m.mov_fecha, m.mov_local, m.mov_terminal, m.mov_cierrey, m.mov_monto, m.mov_hechopor,
       m.mov_regul, m.mov_fechareg, m.mov_techkey,
       (select c.cpd_obs from VTA_FACOCOMPDES c
         where c.cpd_fecha = m.mov_fecha and c.cpd_local = m.mov_local and c.cpd_terminal = m.mov_terminal
           and c.cpd_tipmov = 'DI' and c.cpd_cierrey = m.mov_cierrey and rownum = 1) glosa
  from VTA_FACOMOVDET m
 where m.mov_tipomov = 'DI' and m.mov_hechopor = 'PROC_DI_AUTO'
 order by m.mov_fecha desc, m.mov_local, m.mov_terminal, m.mov_cierrey;

-- 7. Verificacion contra la F8: abrir la caja en Form3Y; la DI aparece en
--    Compensacion -> Diferencia No Imputable, y "Diferencia Real" = 0.

-- 8. Matriz de casos (criterios de aceptacion FSCC-12901 / reglas FSCC-12957)
-- C01 DR = -800                         -> DI_REGISTRADA monto -800; luego T2 la cierra (CA1)
-- C02 DR = -1000 y DR = 20000           -> DI_REGISTRADA (limites inclusivos, CA2)
-- C03 DR = -1001 y DR = 20001           -> FUERA_RANGO, sin DI (CA3)
-- C04 DR = 0                            -> DR_CERO, sin DI; T2 la evalua (CA9)
-- C05 caja sin sobres con DR en rango   -> DI_REGISTRADA igual (CA8)
-- C06 segunda corrida sobre la misma caja con DI automatica -> DI_AUTO_PREVIA (DUD-050)
-- C07 caja con DI manual del analista   -> DI_MANUAL_PREVIA, DI manual intacta
-- C08 caja cerrada                      -> YA_CERRADA, sin DI
-- C09 caja abierta por un analista (bloqueo) -> OCUPADA
-- C10 CA_DI_ACTIVO = N                  -> log T1 INACTIVO; T2 corre igual si CA_ACTIVO = S
-- C11 cambiar CA_DI_MIN / CA_DI_MAX     -> la siguiente corrida usa el nuevo rango (CA6)
-- C12 fecha contable                    -> mov_fechareg = mov_fecha = fecha de venta (CA7)
-- C13 identificacion                    -> mov_hechopor = PROC_DI_AUTO y glosa COMPENSACION AUTOMATICA DI (CA5)
-- C14 DI manual en Form38 sobre caja con DI automatica -> Form38 actualiza la DI (mov_rol 0) existente
