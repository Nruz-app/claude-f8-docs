-- =====================================================================
-- FSCC-12901 COMPENSA_DI - Paso 08: cambio de glosa de la DI automatica
-- xintec-nruz 20-10-2026
-- Pedido del usuario tras la prueba 1 en test: la observacion pasa de
--   'COMPENSACION AUTOMATICA DIFERENCIA DE DI'
-- a
--   'COMPENSACION AUTOMATICA DI'
-- ANTES: recompilar 04 (spec) y 05 (body), en ese orden; al cambiar la
-- spec el body queda invalido hasta ejecutar 05. Despues revisar:
--   select object_type, status from user_objects
--    where object_name = 'PKG_F8_COMPENSA_DI_CARGA';      -- 2 VALID
--   select * from user_errors where name = 'PKG_F8_COMPENSA_DI_CARGA';  -- sin filas
-- Este script actualiza las observaciones ya grabadas con la glosa vieja
-- (solo las de DI automaticas). MODIFICA DATOS. Sin commit automatico.
-- =====================================================================

-- 1. Control previo: observaciones con la glosa vieja
select c.cpd_fecha, c.cpd_local, c.cpd_terminal, c.cpd_cierrey, c.cpd_obs
  from VTA_FACOCOMPDES c
 where c.cpd_tipmov = 'DI'
   and c.cpd_obs = 'COMPENSACION AUTOMATICA DIFERENCIA DE DI'
 order by c.cpd_fecha, c.cpd_local, c.cpd_terminal, c.cpd_cierrey;

-- 2. Cambio (solo cajas con DI automatica)
update VTA_FACOCOMPDES c
   set c.cpd_obs = 'COMPENSACION AUTOMATICA DI'
 where c.cpd_tipmov = 'DI'
   and c.cpd_obs = 'COMPENSACION AUTOMATICA DIFERENCIA DE DI'
   and exists (select 1 from VTA_FACOMOVDET m
                where m.mov_fecha = c.cpd_fecha and m.mov_local = c.cpd_local
                  and m.mov_terminal = c.cpd_terminal and m.mov_cierrey = c.cpd_cierrey
                  and m.mov_tipomov = 'DI' and m.mov_hechopor = 'PROC_DI_AUTO');

-- 3. Control posterior. ESPERADO: la consulta 1 sin filas y estas con la glosa nueva
select c.cpd_fecha, c.cpd_local, c.cpd_terminal, c.cpd_cierrey, c.cpd_obs
  from VTA_FACOCOMPDES c
 where c.cpd_tipmov = 'DI'
   and c.cpd_obs = 'COMPENSACION AUTOMATICA DI'
 order by c.cpd_fecha, c.cpd_local, c.cpd_terminal, c.cpd_cierrey;

-- commit;
-- rollback;
