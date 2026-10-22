-- =====================================================================
-- FSCC-12901 T1 + T2 (carpeta consolidada) - Paso 03b
-- Vista VTA_FACOV_CAJAS_CIERRE: universo comun de cajas de T1 y T2
-- Fuente: docs/sql/FSCC-12958/03b_vista_cajas.sql (mantener ambas copias iguales)
-- =====================================================================

-- =====================================================================
-- FSCC-12958 (HU-01-T2) Cierre de caja automatico - Falabella Colombia
-- 03b - Vista VTA_FACOV_CAJAS_CIERRE: universo de cajas (cierres Y) que
--       evaluan T1 (compensacion DI) y T2 (cierre) en cada ejecucion.
--
--   COLA      : cierres Y con sobres pendientes en VTA_FACOPRD_CIERRE.
--   SIN_SOBRE : cierres Y abiertos del mismo local y fecha de venta de la
--               carga que no recibieron sobres ("cajas sin movimiento",
--               DF-SCC fila 12 / CA8 de FSCC-12901). Solo si el parametro
--               1502 CA_SIN_SOBRE = 'S' y si la Y tiene libro de ventas.
--
-- Requiere: VTA_FACOPRD_CIERRE (01), parametros (03). Va antes de los paquetes.
-- =====================================================================

create or replace view VTA_FACOV_CAJAS_CIERRE
  (cc_fecha, cc_local, cc_terminal, cc_cierrey, cc_origen)
as
select q.prv_fechavta, q.prv_local, q.prv_terminal, q.prv_cierrey, 'COLA'
  from VTA_FACOPRD_CIERRE q
 where q.pcr_estado = 'P'
   and q.prv_cierrey <> 0
 group by q.prv_fechavta, q.prv_local, q.prv_terminal, q.prv_cierrey
union all
select y.ter_fecha, y.ter_local, y.ter_terminal, y.ter_cierrey, 'SIN_SOBRE'
  from VTA_FACOTERMSTATY y
 where y.ter_estado <= 0
   and exists (select 1 from VTA_FACOPARAM p
                where p.vta_ccodtipo = 1502
                  and trim(p.vta_ccodigo) = 'CA_SIN_SOBRE'
                  and upper(trim(p.vta_xglosa)) = 'S')
   -- mismo local y fecha de venta que una carga pendiente
   and exists (select 1 from VTA_FACOPRD_CIERRE q
                where q.pcr_estado = 'P'
                  and q.prv_fechavta = y.ter_fecha
                  and q.prv_local = y.ter_local)
   -- que la Y no este ya en la cola (evita duplicar con COLA)
   and not exists (select 1 from VTA_FACOPRD_CIERRE q
                    where q.pcr_estado = 'P'
                      and q.prv_fechavta = y.ter_fecha
                      and q.prv_local = y.ter_local
                      and q.prv_terminal = y.ter_terminal
                      and q.prv_cierrey = y.ter_cierrey)
   -- con libro de ventas de la Y (sin Y declarada no hay diferencia real)
   and exists (select 1 from VTA_FACOLIBVTA l, VTA_FACOZZZ r
                where l.vta_tiporeg = 'Y'
                  and l.vta_techkey = r.rec_techkey
                  and l.vta_estado = 'A'
                  and l.vta_fecha_venta = y.ter_fecha
                  and l.vta_local = y.ter_local
                  and l.vta_terminal = y.ter_terminal
                  and l.vta_secuencia = y.ter_cierrey);

comment on table VTA_FACOV_CAJAS_CIERRE is 'FSCC-12901 Universo de cajas (cierres Y) para T1 compensacion DI y T2 cierre automatico F8 Colombia';
