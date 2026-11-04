-- =====================================================================
-- FCDVT-14 - pruebas_cargar/c00: prechecks de SOLO LECTURA
-- xintec-nruz 04-11-2026
--
-- Antes de probar Cargar (Form174 + PKG_F8_GRABA_MASIVA_YZ) con los CSV de
-- esta carpeta: local 5, terminales 1 a 3, fechas 20, 21, 22 y 23-10-2026.
--   1) los terminales deben estar vigentes en esas fechas;
--   2) lo ideal es que esas fechas NO tengan cierres (libvta F8/Y, termstaty):
--      Cargar los REEMPLAZA. Si hay datos, elegir otras fechas (cambiar la
--      columna FECHA de los CSV) o aceptar que se reemplacen;
--   3) ninguna Z ni Y cerrada (estado 1/2): Cargar rechazaria el grupo.
-- =====================================================================

prompt === 1. Terminales del local 5 vigentes al 20..23-10-2026 (deben salir 1, 2 y 3)
select t.ter_local, t.ter_terminal, t.ter_fechabaja
  from VTA_FACOTERMINALES t
 where t.ter_local = 5
   and t.ter_terminal in (1, 2, 3)
   and (t.ter_fechabaja >= to_date('23-10-2026', 'dd-mm-yyyy') or t.ter_fechabaja is null)
 order by t.ter_terminal;

prompt === 2. Cierres que ya existen en esas fechas (lo ideal: ninguna fila)
select to_char(l.vta_fecha_venta, 'dd-mm-yyyy') fecha, l.vta_terminal, l.vta_tiporeg,
       count(*) filas, sum(l.vta_totalvta) total
  from VTA_FACOLIBVTA l
 where l.vta_fecha_venta between to_date('20-10-2026', 'dd-mm-yyyy')
                             and to_date('23-10-2026', 'dd-mm-yyyy')
   and l.vta_local = 5
   and l.vta_terminal in (1, 2, 3)
   and l.vta_tiporeg in ('F8', 'Y')
 group by l.vta_fecha_venta, l.vta_terminal, l.vta_tiporeg
 order by 1, 2, 3;

prompt === 3. Estados de Z (termstat) e Y (termstaty); 1 o 2 = cerrado (Cargar rechaza el grupo)
select 'Z' nivel, to_char(ter_fecha, 'dd-mm-yyyy') fecha, ter_terminal, null ter_cierrey,
       ter_estado, ter_notas
  from VTA_FACOTERMSTAT
 where ter_fecha between to_date('20-10-2026', 'dd-mm-yyyy') and to_date('23-10-2026', 'dd-mm-yyyy')
   and ter_local = 5
   and ter_terminal in (1, 2, 3)
union all
select 'Y', to_char(ter_fecha, 'dd-mm-yyyy'), ter_terminal, ter_cierrey, ter_estado, ter_notas
  from VTA_FACOTERMSTATY
 where ter_fecha between to_date('20-10-2026', 'dd-mm-yyyy') and to_date('23-10-2026', 'dd-mm-yyyy')
   and ter_local = 5
   and ter_terminal in (1, 2, 3)
 order by 2, 3, 1, 4;

prompt === 4. Packages instalados (los dos VALID)
select object_name, object_type, status
  from user_objects
 where object_name in ('PKG_F8_CARGA_MASIVA_YZ', 'PKG_F8_GRABA_MASIVA_YZ')
 order by 1, 2;
