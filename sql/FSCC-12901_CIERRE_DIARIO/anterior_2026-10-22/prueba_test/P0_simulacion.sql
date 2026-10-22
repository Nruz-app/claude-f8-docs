-- =====================================================================
-- FSCC-12901 CIERRE_DIARIO - Sesion de prueba en test - P0: simulacion
-- SOLO LECTURA. xintec-nruz 20-10-2026
-- Local 6, fechas 31-08-2026 (pruebas de COMPENSA_DI) y 28-08-2026
-- (prueba 3 de la v2). Ejecutar DESPUES de instalar y ANTES de P1.
-- =====================================================================

-- 1. Estado actual de las Y del local 6 en las dos fechas (lo que muestra CC).
--    ESPERADO (20-10):
--      31-08: T24 Y1 Pendiente, T29 Y1 Cerrado, T31 Y1 Pendiente, T40 Y1 Pendiente
--      28-08: T31 Y1 y T44 Y1 Pendiente; el resto Cerrado
select t.ter_fecha, t.ter_terminal, t.ter_cierrey, t.ter_estado, t.ter_cerradopor
  from VTA_FACOTERMSTATY t
 where t.ter_fecha in (to_date('20260831','yyyymmdd'), to_date('20260828','yyyymmdd'))
   and t.ter_local = 6
 order by 1 desc, 2, 3;

-- 2. Simulacion de lo que hara el proceso (sin grabar). ESPERADO:
--      31-08 T24 Y1 -> CERRABLE (DR 0 / 0)
--      31-08 T40 Y1 -> CERRABLE (DI automatica +15.000, DR 0 / 0)
--      31-08 T31 Y1 -> CON_DIFERENCIA -5000
--      28-08 T31 Y1 -> CON_DIFERENCIA -1500
--      28-08 T44 Y1 -> CON_DIFERENCIA 25000
--    (T29 del 31-08 y las cerradas del 28-08 no aparecen: no estan Pendientes)
select t.ter_fecha, t.ter_terminal, t.ter_cierrey,
       PKG_F8_COMPENSA_DI_CARGA.fn_dif_real('FACO', t.ter_fecha, t.ter_local, t.ter_terminal, t.ter_cierrey) dr_f8,
       PKG_F8_CIERRE_DIARIO.fn_dif_real_cc('FACO', t.ter_fecha, t.ter_local, t.ter_terminal, t.ter_cierrey) dr_cc,
       PKG_F8_CIERRE_DIARIO.fn_evalua_caja('FACO', t.ter_fecha, t.ter_local, t.ter_terminal, t.ter_cierrey) resultado
  from (select distinct t.ter_fecha, t.ter_local, t.ter_terminal, t.ter_cierrey
          from VTA_FACOLIBVTA l, VTA_FACOZZZ r, VTA_FACOTERMSTATY t
         where l.vta_tiporeg     = 'Y'
           and t.ter_fecha in (to_date('20260831','yyyymmdd'), to_date('20260828','yyyymmdd'))
           and l.vta_estado      = 'A'
           and l.vta_techkey     = r.rec_techkey
           and l.vta_fecha_venta = t.ter_fecha
           and l.vta_local       = t.ter_local
           and l.vta_terminal    = t.ter_terminal
           and l.vta_secuencia   = t.ter_cierrey
           and t.ter_cierrey    <> 0
           and t.ter_estado     <= 0) t
 where t.ter_local = 6
 order by 1 desc, 2, 3;

-- 3. Otros locales con cajas Pendientes en esas fechas (el proceso toma
--    TODOS los locales de la fecha). ESPERADO: solo el local 6; si aparecen
--    otros, revisar la consulta 2 sin el filtro de local antes de ejecutar P1.
select t.ter_fecha, t.ter_local, count(*) cajas_pendientes
  from VTA_FACOTERMSTATY t
 where t.ter_fecha in (to_date('20260831','yyyymmdd'), to_date('20260828','yyyymmdd'))
   and t.ter_estado <= 0 and t.ter_cierrey <> 0
 group by t.ter_fecha, t.ter_local
 order by 1 desc, 2;
