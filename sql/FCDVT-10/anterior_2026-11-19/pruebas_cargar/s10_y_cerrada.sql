-- =====================================================================
-- FCDVT-10 (HU-03) - pruebas_cargar/s10: Cargar con una Y cerrada (SOLO TEST)
-- Tottus Chile (SFCL)
-- xintec-nruz 18-11-2026
-- Base: docs/sql/FCDVT-14/pruebas_cargar/c05_y_cerrada.sql.
--
-- Prueba que Cargar NO reemplaza un terminal-dia con una Y cerrada.
-- Requiere haber grabado antes s04_reemplazo_v1.csv y s05_reemplazo_v2.csv
-- (17-11-2026, local 116, terminal 7: Y 1 y 2 en -1).
--
-- Se recomienda usar la PARTE 1 de este script, que marca la Y cerrada a
-- mano, y despues de la prueba la PARTE 2, que la reabre. Cerrarla desde la
-- F8 (Form3Y, Cerrar Terminal) tambien sirve, pero lo que grabe ese cierre
-- ademas de termstaty no lo revierte este script ni 98_limpia_prueba.sql
-- (la PARTE 2 si reabre la Y en termstaty).
--
--   1) PARTE 1 (v_parte = 1): Y 1 del 17-11 L116 T7 -> ter_estado = 1
--   2) Form174: Buscar s05_reemplazo_v2.csv (o s04_reemplazo_v1.csv)
--      Esperado en Buscar: ERROR "El terminal tiene 1 cierre(s) Y cerrado(s)
--      ese dia; INGRESAR los reemplazaria."
--      Esperado en Cargar: "No se grabo: El terminal tiene 1 cierre(s) Y
--      cerrado(s) (termstaty estado 1 o 2); no se reemplaza". En la base,
--      17-11 L116 T7 queda igual que antes.
--   3) PARTE 2 (v_parte = 2): vuelve la Y 1 a -1 (este o un cierre desde la F8)
-- =====================================================================
set serveroutput on

declare
  v_parte number := 0;   -- EDITAR: 1 = cerrar la Y 1, 2 = reabrirla
  v_n     number;
begin
  if v_parte = 1 then
    update VTA_SFCLTERMSTATY
       set ter_estado = 1,
           ter_notas  = ter_notas || ' | PRUEBA s10 FCDVT-10 (cerrada a mano)'
     where ter_fecha    = to_date('17-11-2026', 'dd-mm-yyyy')
       and ter_local    = 116
       and ter_terminal = 7
       and ter_cierrey  = 1
       and ter_estado   = -1;
    v_n := sql%rowcount;
  elsif v_parte = 2 then
    update VTA_SFCLTERMSTATY
       set ter_estado = -1,
           ter_notas  = replace(ter_notas, ' | PRUEBA s10 FCDVT-10 (cerrada a mano)')
     where ter_fecha    = to_date('17-11-2026', 'dd-mm-yyyy')
       and ter_local    = 116
       and ter_terminal = 7
       and ter_cierrey  = 1
       and ter_estado in (1, 2);
    v_n := sql%rowcount;
  else
    raise_application_error(-20001, 'Completar v_parte (1 o 2) en el bloque EDITAR');
  end if;
  commit;
  dbms_output.put_line('Parte ' || v_parte || ': ' || v_n || ' fila(s) actualizada(s)');
end;
/

select ter_cierrey, ter_estado, ter_notas
  from VTA_SFCLTERMSTATY
 where ter_fecha    = to_date('17-11-2026', 'dd-mm-yyyy')
   and ter_local    = 116
   and ter_terminal = 7
 order by ter_cierrey;

select vta_tiporeg, vta_secuencia, vta_montobol, vta_totalvta
  from VTA_SFCLLIBVTA
 where vta_fecha_venta = to_date('17-11-2026', 'dd-mm-yyyy')
   and vta_local       = 116
   and vta_terminal    = 7
 order by vta_tiporeg, vta_secuencia;
