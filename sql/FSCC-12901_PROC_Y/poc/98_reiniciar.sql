-- =====================================================================
-- POC FSCC-12901 v2 (multipais, FACO) - 98 Reiniciar (DESARROLLO)
-- Deshace SOLO lo que hizo el proceso (06 / 08) para poder ejecutarlo otra
-- vez sobre los mismos datos: borra las DI y glosas automaticas, restaura los
-- cierres Y desde VTA_FACOPOC_RESP_Y, devuelve los sobres de la cola a 'P' y
-- borra el log de las ejecuciones. Los datos cargados (02, 03, 04) quedan.
-- Despues: 05_simular.sql (opcional) -> 06_ejecutar_proceso.sql -> 07.
-- =====================================================================

declare
  v_n number;
begin
  -- 1. DI automaticas y sus glosas en los local-dia del POC
  delete from VTA_FACOMOVDET m
   where m.mov_tipomov = 'DI' and m.mov_hechopor = 'PROC_DI_AUTO'
     and exists (select 1 from VTA_FACOPOC_DIAS d where d.d_fecha = m.mov_fecha and d.d_local = m.mov_local);
  dbms_output.put_line('DI borradas: ' || sql%rowcount);
  delete from VTA_FACOCOMPDES c
   where c.cpd_tipmov = 'DI' and c.cpd_obs = 'COMPENSACION AUTOMATICA DI'
     and exists (select 1 from VTA_FACOPOC_DIAS d where d.d_fecha = c.cpd_fecha and d.d_local = c.cpd_local);
  dbms_output.put_line('Glosas borradas: ' || sql%rowcount);

  -- 2. Cierres Y como estaban despues de cargar los datos (04)
  update VTA_FACOTERMSTATY y
     set (y.ter_estado, y.ter_cerradopor, y.ter_notas) =
         (select r.ter_estado, r.ter_cerradopor, r.ter_notas from VTA_FACOPOC_RESP_Y r
           where r.ter_fecha = y.ter_fecha and r.ter_local = y.ter_local
             and r.ter_terminal = y.ter_terminal and r.ter_cierrey = y.ter_cierrey)
   where exists (select 1 from VTA_FACOPOC_RESP_Y r
                  where r.ter_fecha = y.ter_fecha and r.ter_local = y.ter_local
                    and r.ter_terminal = y.ter_terminal and r.ter_cierrey = y.ter_cierrey);
  dbms_output.put_line('Cierres Y restaurados: ' || sql%rowcount);

  -- 3. Cola: los sobres del POC vuelven a pendiente
  update VTA_FACOPRD_CIERRE q
     set q.pcr_estado = 'P', q.pcr_resultado = null, q.pcr_mensaje = null,
         q.pcr_fechaproc = null, q.pcr_ejecucion = null, q.pcr_intentos = 0
   where q.prv_techkey in (select prv_techkey from VTA_FACOPRD where prv_modifpor = 'POC_FSCC12901');
  dbms_output.put_line('Cola reiniciada: ' || sql%rowcount);

  -- 4. Log de las ejecuciones del POC
  delete from VTA_FACOLOG_CIERRE_AUTO
   where log_ejecucion in (select to_number(valor) from VTA_FACOPOC_CTRL
                            where clave in ('EJECUCION_AUTO', 'EJECUCION_CC'));
  dbms_output.put_line('Log borrado: ' || sql%rowcount);
  delete from VTA_FACOPOC_CTRL where clave in ('EJECUCION_AUTO', 'EJECUCION_CC', 'DURACION_SEG');

  commit;
end;
/

-- Control (esperado: 0 DI automaticas, 0 Y cerradas por el proceso)
select (select count(*) from VTA_FACOMOVDET m, VTA_FACOPOC_DIAS d
         where m.mov_tipomov = 'DI' and m.mov_hechopor = 'PROC_DI_AUTO'
           and m.mov_fecha = d.d_fecha and m.mov_local = d.d_local) di_automaticas,
       (select count(*) from VTA_FACOTERMSTATY y, VTA_FACOPOC_DIAS d
         where y.ter_fecha = d.d_fecha and y.ter_local = d.d_local
           and y.ter_cerradopor in ('PROC_CIERRE_AUTO', 'POC_ANALISTA')) y_cerradas_proceso
  from dual;
