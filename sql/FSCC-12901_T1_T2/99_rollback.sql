-- =====================================================================
-- FSCC-12901 T1 + T2 (carpeta consolidada) - Paso 99
-- Vuelta atras. Conectado como el duenio (sinonimos: DBA).
-- Opcion recomendada para detener el proceso sin desinstalar: paso 1.
-- =====================================================================

-- 1) Apagar el proceso (sin recompilar): T1 y/o T2
update VTA_FACOPARAM set vta_xglosa = 'N'
 where vta_ccodtipo = 1502 and vta_ccodigo in ('CA_DI_ACTIVO', 'CA_ACTIVO');
commit;

-- 2) (Opcional) Revertir una ejecucion, si las cajas no fueron enviadas a contabilidad.
--    Reemplazar &ejecucion por el log_ejecucion a revertir.
-- 2a. Reabrir las Y que cerro T2 (o el boton Cerrar Terminal de Form43, log_proceso CC).
--     FACO solo cierre Y: el proceso no cierra la Z, no hay nada que reabrir en VTA_FACOTERMSTAT.
update VTA_FACOTERMSTATY y
   set y.ter_estado = 0, y.ter_cerradopor = null
 where exists (select 1 from VTA_FACOLOG_CIERRE_AUTO l
                where l.log_ejecucion = &ejecucion and l.log_proceso in ('T2', 'CC')
                  and l.log_resultado = 'CERRADA_Y'
                  and l.log_fecha_vta = y.ter_fecha and l.log_local = y.ter_local
                  and l.log_terminal = y.ter_terminal and l.log_cierrey = y.ter_cierrey);
-- 2b. Borrar las DI que registro T1 (solo en cajas abiertas)
delete from VTA_FACOCOMPDES c
 where c.cpd_tipmov = 'DI' and c.cpd_obs = 'COMPENSACION AUTOMATICA DI'
   and exists (select 1 from VTA_FACOLOG_CIERRE_AUTO l
                where l.log_ejecucion = &ejecucion and l.log_proceso = 'T1'
                  and l.log_resultado = 'DI_REGISTRADA'
                  and l.log_fecha_vta = c.cpd_fecha and l.log_local = c.cpd_local
                  and l.log_terminal = c.cpd_terminal and l.log_cierrey = c.cpd_cierrey);
delete from VTA_FACOMOVDET m
 where m.mov_tipomov = 'DI' and m.mov_hechopor = 'PROC_DI_AUTO'
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

-- 3) Desinstalar todo (orden inverso: primero el trigger para no afectar la carga)
drop trigger  TRG_VTA_FACOPRD_CIERRE_AI;
drop package  PKG_F8_FACO_CIERRE_AUTO;
drop package  PKG_F8_FACO_COMPENSA_DI;
drop view     VTA_FACOV_CAJAS_CIERRE;

accept usuario_app char prompt 'Usuario de aplicacion con sinonimos: '
drop synonym  &usuario_app..PKG_F8_FACO_CIERRE_AUTO;
drop synonym  &usuario_app..PKG_F8_FACO_COMPENSA_DI;
drop synonym  &usuario_app..VTA_FACOPRD_CIERRE;
drop synonym  &usuario_app..VTA_FACOLOG_CIERRE_AUTO;
drop synonym  &usuario_app..VTA_FACOV_CAJAS_CIERRE;

drop table    VTA_FACOPRD_CIERRE;
drop table    VTA_FACOLOG_CIERRE_AUTO;
drop sequence SEQ_VTA_FACOPRD_CIERRE;
drop sequence SEQ_VTA_FACOLOG_CIERRE_AUTO;

delete from VTA_FACOPARAM
 where vta_ccodtipo = 1502
   and vta_ccodigo in ('CA_DI_ACTIVO','CA_DI_MIN','CA_DI_MAX','CA_ACTIVO','CA_VAL_CHEQ',
                       'CA_VAL_ZZZ','CA_VAL_USD','CA_DECIMAL','CA_DIAS','CA_SIN_SOBRE');
commit;

-- Opcion 1515 de FACO (03c_permiso_cc.sql). Sin ella Form43 oculta el boton Cerrar Terminal.
delete from VTA_FACORELPERMEN where mnu_codigo = 1515;
delete from VTA_FACOMENU      where mnu_codigo = 1515;
commit;
