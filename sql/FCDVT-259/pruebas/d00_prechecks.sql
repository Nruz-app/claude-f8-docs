-- =====================================================================
-- FCDVT-259 - pruebas/d00: prechecks de SOLO LECTURA
-- xintec-nruz 16-11-2026 (antes FCDVT-14/pruebas_descargar, Descargar Excel)
--
-- Antes de probar Exportar de Form176 (PKG_F8_EXPORTA_MASIVA_YZ, pasos
-- 02 / 03) con los datos de esta carpeta:
--   - 27-10-2026, local 5, terminales 1 a 3: dia CON cierres (d01 los carga);
--   - 28-10-2026, local 5: dia SIN cierres.
-- OJO: Form176 solo deja exportar de hoy - 2 a ayer. Para probar la
-- pantalla, reemplazar 27-10-2026 por ANTEAYER y 28-10-2026 por AYER en el CSV
-- (columna FECHA) y en d00, d02, d03 y d09 (ver README.md). El package
-- no tiene esa regla: con las fechas originales las consultas igual sirven.
-- 1) los terminales 1, 2 y 3 deben estar vigentes;
-- 2) esas fechas NO deben tener cierres en el local 5 (libvta F8/Y): d01 los
--    REEMPLAZARIA y el dia vacio dejaria de estarlo;
-- 3) ninguna Z ni Y cerrada (estado 1/2);
-- 4) los tres packages VALID y sin user_errors.
-- =====================================================================

prompt === 1. Terminales del local 5 vigentes al 28-10-2026 (deben salir 1, 2 y 3)
select t.ter_local, t.ter_terminal, t.ter_fechabaja
  from VTA_FACOTERMINALES t
 where t.ter_local = 5
   and t.ter_terminal in (1, 2, 3)
   and (t.ter_fechabaja >= to_date('28-10-2026', 'dd-mm-yyyy') or t.ter_fechabaja is null)
 order by t.ter_terminal;

prompt === 2. Cierres del local 5 el 27 y 28-10-2026 (ESPERADO: ninguna fila)
select to_char(l.vta_fecha_venta, 'dd-mm-yyyy') fecha, l.vta_terminal, l.vta_tiporeg,
       l.vta_estado, count(*) filas, sum(l.vta_totalvta) total
  from VTA_FACOLIBVTA l
 where l.vta_fecha_venta between to_date('27-10-2026', 'dd-mm-yyyy')
                             and to_date('28-10-2026', 'dd-mm-yyyy')
   and l.vta_local = 5
   and l.vta_tiporeg in ('F8', 'Y')
 group by l.vta_fecha_venta, l.vta_terminal, l.vta_tiporeg, l.vta_estado
 order by 1, 2, 3;

prompt === 3. Estados de Z (termstat) e Y (termstaty) de esas fechas; 1 o 2 = cerrado
select 'Z' nivel, to_char(ter_fecha, 'dd-mm-yyyy') fecha, ter_terminal, null ter_cierrey,
       ter_estado, ter_notas
  from VTA_FACOTERMSTAT
 where ter_fecha between to_date('27-10-2026', 'dd-mm-yyyy') and to_date('28-10-2026', 'dd-mm-yyyy')
   and ter_local = 5
union all
select 'Y', to_char(ter_fecha, 'dd-mm-yyyy'), ter_terminal, ter_cierrey, ter_estado, ter_notas
  from VTA_FACOTERMSTATY
 where ter_fecha between to_date('27-10-2026', 'dd-mm-yyyy') and to_date('28-10-2026', 'dd-mm-yyyy')
   and ter_local = 5
 order by 2, 3, 1, 4;

prompt === 4. Packages (ESPERADO: los tres con PACKAGE y PACKAGE BODY VALID)
select object_name, object_type, status
  from user_objects
 where object_name in ('PKG_F8_CARGA_MASIVA_YZ', 'PKG_F8_GRABA_MASIVA_YZ', 'PKG_F8_EXPORTA_MASIVA_YZ')
 order by 1, 2;

prompt === 5. Errores de compilacion (ESPERADO: ninguna fila)
select name, type, line, position, text
  from user_errors
 where name = 'PKG_F8_EXPORTA_MASIVA_YZ'
 order by type, sequence;

prompt === 6. El package responde (ESPERADO: el encabezado de 56 columnas que empieza con FECHA;LOCAL;TERMINAL)
select PKG_F8_EXPORTA_MASIVA_YZ.fn_encabezado encabezado from dual;
