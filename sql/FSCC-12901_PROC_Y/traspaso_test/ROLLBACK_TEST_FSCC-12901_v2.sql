-- =====================================================================
-- FSCC-12901 v2 MULTIPAIS - ROLLBACK DEL TRASPASO A TEST
-- Deshace TRASPASO_TEST_FSCC-12901_v2.sql. Base: test (sgfnprds).
-- Conectado como INTRANETTS (los sinonimos de la parte 3, como DBA).
-- Fuente: docs/sql/FSCC-12901_POC_v2/99_rollback.sql, con USUARIO_APP =
-- UINTRANETTS y el retiro del job agregado.
-- NO ejecutar entero: ejecutar SOLO la parte que corresponda.
--   Parte 1: detener el proceso sin desinstalar (recomendada).
--   Parte 2: revertir UNA ejecucion (EDITAR v_ejecucion).
--   Parte 3: desinstalar todo (tambien sirve si el traspaso fallo a mitad;
--            los DROP de objetos que no alcanzaron a crearse dan ORA-04043 /
--            ORA-00942 / ORA-02289 y se pueden ignorar).
-- Convenciones: ASCII, sin prefijo de esquema (salvo sinonimos), Oracle 10.2.
-- =====================================================================
set define off
set serveroutput on

-- =====================================================================
-- PARTE 1) Apagar el proceso del pais (sin recompilar): T1 y/o T2
-- =====================================================================
update VTA_FACOPARAM set vta_xglosa = 'N'
 where vta_ccodtipo = 1502 and vta_ccodigo in ('CA_DI_ACTIVO', 'CA_ACTIVO');
commit;

-- =====================================================================
-- PARTE 2) (Opcional) Revertir UNA ejecucion, si las cajas no fueron
--          enviadas a contabilidad. EDITAR v_ejecucion (log_ejecucion).
-- =====================================================================
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

-- =====================================================================
-- PARTE 3) Desinstalar todo. Primero el job y el trigger para no afectar
--          la carga de sobres.
-- =====================================================================
-- 3a. Job (solo si se creo la PARTE 6 del traspaso). EDITAR el numero:
-- select job, what from user_jobs where upper(what) like '%PKG_F8_CIERRE_AUTO%';
-- begin dbms_job.remove(0); commit; end;   -- EDITAR 0 = numero de job
-- /

-- 3b. Trigger y paquetes
drop trigger  TRG_VTA_FACOPRD_CIERRE_AI;
drop package  PKG_F8_CIERRE_AUTO;
drop package  PKG_F8_COMPENSA_DI_AUTO;

-- 3c. Sinonimos de UINTRANETTS (como DBA)
drop synonym UINTRANETTS.PKG_F8_CIERRE_AUTO;
drop synonym UINTRANETTS.PKG_F8_COMPENSA_DI_AUTO;
drop synonym UINTRANETTS.VTA_FACOPRD_CIERRE;
drop synonym UINTRANETTS.VTA_FACOLOG_CIERRE_AUTO;

-- 3d. Tablas y secuencias (los grants se van con el objeto)
drop table    VTA_FACOPRD_CIERRE;
drop table    VTA_FACOLOG_CIERRE_AUTO;
drop sequence SEQ_VTA_FACOPRD_CIERRE;
drop sequence SEQ_VTA_FACOLOG_CIERRE_AUTO;

-- 3e. Parametros 1502
delete from VTA_FACOPARAM
 where vta_ccodtipo = 1502
   and vta_ccodigo in ('CA_DI_ACTIVO','CA_DI_MIN','CA_DI_MAX','CA_ACTIVO','CA_VAL_CHEQ',
                       'CA_VAL_ZZZ','CA_DECIMAL','CA_SIN_SOBRE');
commit;

-- 3f. Opcion 1515 de FACO. Sin ella Form43 oculta el boton Cerrar Terminal.
delete from VTA_FACORELPERMEN where mnu_codigo = 1515;
delete from VTA_FACOMENU      where mnu_codigo = 1515;
commit;

-- 3g. Verificacion (esperado: 0 filas en las tres consultas)
select object_name, object_type from user_objects
 where object_name in ('VTA_FACOPRD_CIERRE','SEQ_VTA_FACOPRD_CIERRE','VTA_FACOLOG_CIERRE_AUTO',
                       'SEQ_VTA_FACOLOG_CIERRE_AUTO','PKG_F8_CIERRE_AUTO',
                       'PKG_F8_COMPENSA_DI_AUTO','TRG_VTA_FACOPRD_CIERRE_AI');
select vta_ccodigo from VTA_FACOPARAM where vta_ccodtipo = 1502;
select mnu_codigo from VTA_FACOMENU where mnu_codigo = 1515;
