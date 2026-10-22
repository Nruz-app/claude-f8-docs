-- =====================================================================
-- FSCC-12901 PROC_YZ (v2 multipais + cierre Z) - Paso 99 (instalacion nueva, pais FACO)
-- Vuelta atras. Conectado como el duenio. Sin variables de sustitucion:
-- ejecutar por partes. (Si se actualizo desde PROC_Y con
-- ACTUALIZAR_DESDE_PROC_Y.sql y solo se quiere volver a PROC_Y, usar
-- VOLVER_A_PROC_Y.sql.)
-- Opcion recomendada para detener el proceso sin desinstalar: parte 1.
-- =====================================================================

-- 1) Apagar el proceso del pais (sin recompilar): T1 y/o T2
update VTA_FACOPARAM set vta_xglosa = 'N'
 where vta_ccodtipo = 1502 and vta_ccodigo in ('CA_DI_ACTIVO', 'CA_ACTIVO');
commit;

-- 1b) PROC_YZ: apagar SOLO el cierre de la Z (las Y siguen cerrandose)
-- update VTA_FACOPARAM set vta_xglosa = 'N' where vta_ccodtipo = 1502 and vta_ccodigo = 'CA_CIERRA_Z';
-- commit;

-- 2) (Opcional) Revertir UNA ejecucion, si las cajas no fueron enviadas a contabilidad.
--    EDITAR v_ejecucion (log_ejecucion a revertir).
declare
  v_ejecucion number := 0;   -- EDITAR
begin
  -- 2a. Reabrir las Y que cerro T2 (o Cerrar Terminal de Form43, log_proceso CC)
  update VTA_FACOTERMSTATY y
     set y.ter_estado = 0, y.ter_cerradopor = null
   where exists (select 1 from VTA_FACOLOG_CIERRE_AUTO l
                  where l.log_ejecucion = v_ejecucion and l.log_proceso in ('T2', 'CC')
                    and l.log_resultado = 'CERRADA_Y'
                    and l.log_fecha_vta = y.ter_fecha and l.log_local = y.ter_local
                    and l.log_terminal = y.ter_terminal and l.log_cierrey = y.ter_cierrey);
  dbms_output.put_line('Y reabiertas: ' || sql%rowcount);
  -- 2a-Z. PROC_YZ: reabrir las Z que cerro el proceso (log_nivel Z, CERRADA_Z)
  update VTA_FACOTERMSTAT z
     set z.ter_estado = 0, z.ter_cerradopor = null
   where exists (select 1 from VTA_FACOLOG_CIERRE_AUTO l
                  where l.log_ejecucion = v_ejecucion and l.log_proceso in ('T2', 'CC')
                    and l.log_nivel = 'Z' and l.log_resultado = 'CERRADA_Z'
                    and l.log_fecha_vta = z.ter_fecha and l.log_local = z.ter_local
                    and l.log_terminal = z.ter_terminal);
  dbms_output.put_line('Z reabiertas: ' || sql%rowcount);
  -- 2b. Borrar las DI que registro T1 (solo en cajas abiertas)
  delete from VTA_FACOCOMPDES c
   where c.cpd_tipmov = 'DI' and c.cpd_obs = 'COMPENSACION AUTOMATICA DI'
     and exists (select 1 from VTA_FACOLOG_CIERRE_AUTO l
                  where l.log_ejecucion = v_ejecucion and l.log_proceso = 'T1'
                    and l.log_resultado = 'DI_REGISTRADA'
                    and l.log_fecha_vta = c.cpd_fecha and l.log_local = c.cpd_local
                    and l.log_terminal = c.cpd_terminal and l.log_cierrey = c.cpd_cierrey);
  delete from VTA_FACOMOVDET m
   where m.mov_tipomov = 'DI' and m.mov_hechopor = 'PROC_DI_AUTO'
     and exists (select 1 from VTA_FACOLOG_CIERRE_AUTO l
                  where l.log_ejecucion = v_ejecucion and l.log_proceso = 'T1'
                    and l.log_resultado = 'DI_REGISTRADA'
                    and l.log_fecha_vta = m.mov_fecha and l.log_local = m.mov_local
                    and l.log_terminal = m.mov_terminal and l.log_cierrey = m.mov_cierrey)
     and exists (select 1 from VTA_FACOTERMSTATY y
                  where y.ter_fecha = m.mov_fecha and y.ter_local = m.mov_local
                    and y.ter_terminal = m.mov_terminal and y.ter_cierrey = m.mov_cierrey
                    and y.ter_estado <= 0);
  dbms_output.put_line('DI borradas: ' || sql%rowcount);
  -- 2c. La carga de esa ejecucion vuelve a pendiente (para reprocesarla)
  update VTA_FACOPRD_CIERRE q
     set q.pcr_estado = 'P'
   where q.pcr_ejecucion = v_ejecucion and q.pcr_estado in ('E', 'C');
  dbms_output.put_line('Cola a pendiente: ' || sql%rowcount);
  commit;
end;
/

-- 3) Desinstalar todo (primero el trigger para no afectar la carga).
--    Los paquetes son comunes a todos los paises: borrarlos solo si ningun
--    otro pais los usa.
drop trigger  TRG_VTA_FACOPRD_CIERRE_AI;
drop package  PKG_F8_CIERRE_AUTO;
drop package  PKG_F8_COMPENSA_DI_AUTO;

-- Sinonimos (como DBA; EDITAR USUARIO_APP)
-- drop synonym USUARIO_APP.PKG_F8_CIERRE_AUTO;
-- drop synonym USUARIO_APP.PKG_F8_COMPENSA_DI_AUTO;
-- drop synonym USUARIO_APP.VTA_FACOPRD_CIERRE;
-- drop synonym USUARIO_APP.VTA_FACOLOG_CIERRE_AUTO;

drop table    VTA_FACOPRD_CIERRE;
drop table    VTA_FACOLOG_CIERRE_AUTO;
drop sequence SEQ_VTA_FACOPRD_CIERRE;
drop sequence SEQ_VTA_FACOLOG_CIERRE_AUTO;

delete from VTA_FACOPARAM
 where vta_ccodtipo = 1502
   and vta_ccodigo in ('CA_DI_ACTIVO','CA_DI_MIN','CA_DI_MAX','CA_ACTIVO','CA_VAL_CHEQ',
                       'CA_VAL_ZZZ','CA_DECIMAL','CA_SIN_SOBRE',
                       'CA_CIERRA_Z','CA_Z_SIN_Y','CA_Z_VAL_SUMA','CA_Z_VAL_DOL');
commit;

-- Opcion 1515 de FACO (03c_permiso_FACO.sql). Sin ella Form43 oculta el boton Cerrar Terminal.
delete from VTA_FACORELPERMEN where mnu_codigo = 1515;
delete from VTA_FACOMENU      where mnu_codigo = 1515;
commit;
