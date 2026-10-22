-- =====================================================================
-- POC FSCC-12901 v2 (multipais, FACO) - 06 Ejecutar el proceso, como el job (DESARROLLO)
-- PKG_F8_CIERRE_AUTO.prc_cierre_automatico('FACO'): toma la carga (cola P -> E),
-- T1 (DI) y luego T2 (cierre Y) sobre ella (dia PRD 3 + cajas de TEST), y la
-- deja procesada (C). Una segunda ejecucion sin carga nueva no evalua nada.
-- GRABA: DI, glosas, cierres Y, cola y log. Repetir con 98_reiniciar.sql;
-- deshacer todo con 99_limpiar.sql.
-- =====================================================================

declare
  v_ini  date := sysdate;
  v_ejec number;
begin
  PKG_F8_CIERRE_AUTO.prc_cierre_automatico(p_flg_pais => 'FACO');   -- usuario por defecto PROC_CIERRE_AUTO

  select max(log_ejecucion) into v_ejec
    from VTA_FACOLOG_CIERRE_AUTO
   where log_proceso = 'T2' and log_resultado = 'INICIO';

  delete from VTA_FACOPOC_CTRL where clave in ('EJECUCION_AUTO', 'DURACION_SEG');
  insert into VTA_FACOPOC_CTRL values ('EJECUCION_AUTO', to_char(v_ejec));
  insert into VTA_FACOPOC_CTRL values ('DURACION_SEG', to_char(round((sysdate - v_ini) * 86400)));
  commit;
  dbms_output.put_line('Ejecucion ' || v_ejec || ' terminada en ' || round((sysdate - v_ini) * 86400) || ' segundos');
end;
/

-- Resumen rapido
select log_proceso, log_resultado, count(*) filas
  from VTA_FACOLOG_CIERRE_AUTO
 where log_ejecucion = (select to_number(valor) from VTA_FACOPOC_CTRL where clave = 'EJECUCION_AUTO')
 group by log_proceso, log_resultado
 order by 1, 2;
