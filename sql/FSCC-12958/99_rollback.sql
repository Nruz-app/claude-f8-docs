-- =====================================================================
-- FSCC-12958 (HU-01-T2) Cierre de caja automatico - Falabella Colombia
-- 99 - Vuelta atras
-- =====================================================================

-- 1) (Opcional) Reabrir lo cerrado por una ejecucion, si no hubo envio contable.
--    Reemplazar &ejecucion por el log_ejecucion a revertir.
--    Nota: ter_notas queda con el prefijo "CIERRE AUTOMATICO FSCC-12958 ..."
--    (o "CIERRE CC FSCC-12901 ..." si se cerro desde Form43, log_proceso CC).
update VTA_FACOTERMSTATY y
   set y.ter_estado = 0, y.ter_cerradopor = null
 where exists (select 1 from VTA_FACOLOG_CIERRE_AUTO l
                where l.log_ejecucion = &ejecucion and l.log_resultado = 'CERRADA_Y'
                  and l.log_fecha_vta = y.ter_fecha and l.log_local = y.ter_local
                  and l.log_terminal = y.ter_terminal and l.log_cierrey = y.ter_cierrey);

-- (FACO solo cierre Y: el proceso no cierra la Z, no hay nada que reabrir en VTA_FACOTERMSTAT)
commit;

-- 2) Desinstalar (primero el trigger, para no afectar la carga de sobres)
drop trigger  TRG_VTA_FACOPRD_CIERRE_AI;
-- Si T1 (FSCC-12957) esta instalado, su paquete usa fn_dif_real/fn_param de
-- este paquete: desinstalar tambien T1 (FSCC-12957/99_rollback.sql paso 3).
drop package  PKG_F8_FACO_COMPENSA_DI;
drop package  PKG_F8_FACO_CIERRE_AUTO;
drop view     VTA_FACOV_CAJAS_CIERRE;

-- Sinonimos del usuario de aplicacion (DBA o el propio usuario de aplicacion)
accept usuario_app char prompt 'Usuario de aplicacion que recibe permisos y sinonimos (ej. el usuario del exe o del job): '
drop synonym  &usuario_app..PKG_F8_FACO_CIERRE_AUTO;
drop synonym  &usuario_app..VTA_FACOPRD_CIERRE;
drop synonym  &usuario_app..VTA_FACOLOG_CIERRE_AUTO;
drop synonym  &usuario_app..VTA_FACOV_CAJAS_CIERRE;

drop table    VTA_FACOPRD_CIERRE;
drop table    VTA_FACOLOG_CIERRE_AUTO;
drop sequence SEQ_VTA_FACOPRD_CIERRE;
drop sequence SEQ_VTA_FACOLOG_CIERRE_AUTO;

delete from VTA_FACOPARAM
 where vta_ccodtipo = 1502
   and vta_ccodigo in ('CA_ACTIVO','CA_VAL_CHEQ','CA_VAL_ZZZ','CA_VAL_USD','CA_DECIMAL','CA_DIAS','CA_SIN_SOBRE');
commit;

-- Opcion 1515 de FACO (03c_permiso_cc.sql). Sin ella Form43 oculta el boton Cerrar Terminal.
delete from VTA_FACORELPERMEN where mnu_codigo = 1515;
delete from VTA_FACOMENU      where mnu_codigo = 1515;
commit;
