-- =====================================================================
-- FSCC-12957 (HU-01-T1) Compensacion automatica de DI - Falabella Colombia
-- 99 - Vuelta atras
-- IMPORTANTE: el cuerpo de PKG_F8_FACO_CIERRE_AUTO (T2) llama a
-- PKG_F8_FACO_COMPENSA_DI. Para dejar de usar T1 SIN afectar T2, basta con
-- apagar el interruptor (paso 1). Borrar el paquete (paso 3) invalida T2
-- hasta que se reinstale su cuerpo sin la llamada a T1.
-- =====================================================================

-- 1) Apagar T1 (recomendado, sin recompilar nada)
update VTA_FACOPARAM set vta_xglosa = 'N'
 where vta_ccodtipo = 1502 and vta_ccodigo = 'CA_DI_ACTIVO';
commit;

-- 2) (Opcional) Revertir las DI automaticas de una ejecucion, si las cajas
--    siguen abiertas y no hubo envio contable de esas fechas.
--    Reemplazar &ejecucion por el log_ejecucion a revertir.
delete from VTA_FACOCOMPDES c
 where c.cpd_tipmov = 'DI'
   and c.cpd_obs = 'COMPENSACION AUTOMATICA DI'
   and exists (select 1 from VTA_FACOLOG_CIERRE_AUTO l
                where l.log_ejecucion = &ejecucion and l.log_proceso = 'T1'
                  and l.log_resultado = 'DI_REGISTRADA'
                  and l.log_fecha_vta = c.cpd_fecha and l.log_local = c.cpd_local
                  and l.log_terminal = c.cpd_terminal and l.log_cierrey = c.cpd_cierrey);

delete from VTA_FACOMOVDET m
 where m.mov_tipomov = 'DI'
   and m.mov_hechopor = 'PROC_DI_AUTO'
   and exists (select 1 from VTA_FACOLOG_CIERRE_AUTO l
                where l.log_ejecucion = &ejecucion and l.log_proceso = 'T1'
                  and l.log_resultado = 'DI_REGISTRADA'
                  and l.log_fecha_vta = m.mov_fecha and l.log_local = m.mov_local
                  and l.log_terminal = m.mov_terminal and l.log_cierrey = m.mov_cierrey)
   and exists (select 1 from VTA_FACOTERMSTATY y
                where y.ter_fecha = m.mov_fecha and y.ter_local = m.mov_local
                  and y.ter_terminal = m.mov_terminal and y.ter_cierrey = m.mov_cierrey
                  and y.ter_estado <= 0);
commit;

-- 3) (Solo si se desinstala T1 por completo) reinstalar antes el cuerpo de
--    PKG_F8_FACO_CIERRE_AUTO sin el bloque "T1 (FSCC-12957)" y luego:
-- accept usuario_app char prompt 'Usuario de aplicacion: '
-- drop synonym &usuario_app..PKG_F8_FACO_COMPENSA_DI;
-- drop package PKG_F8_FACO_COMPENSA_DI;
-- delete from VTA_FACOPARAM where vta_ccodtipo = 1502
--    and vta_ccodigo in ('CA_DI_ACTIVO', 'CA_DI_MIN', 'CA_DI_MAX');
-- commit;
