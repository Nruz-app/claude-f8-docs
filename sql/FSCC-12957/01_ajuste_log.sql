-- =====================================================================
-- FSCC-12957 (HU-01-T1) Compensacion automatica de DI - Falabella Colombia
-- 01 - Ajuste del log de FSCC-12958: columna LOG_PROCESO (T1 / T2 / CC).
-- Idempotente: si la tabla ya se creo con la version actual de
-- FSCC-12958/02_log.sql (que ya trae la columna), no hace nada.
-- =====================================================================
declare
  v_cnt number;
begin
  select count(*)
    into v_cnt
    from user_tab_columns
   where table_name = 'VTA_FACOLOG_CIERRE_AUTO'
     and column_name = 'LOG_PROCESO';

  if v_cnt = 0 then
    execute immediate
      'alter table VTA_FACOLOG_CIERRE_AUTO add (log_proceso varchar2(2) default ''T2'' not null)';
    dbms_output.put_line('Columna LOG_PROCESO agregada');
  else
    dbms_output.put_line('Columna LOG_PROCESO ya existe: sin cambios');
  end if;
end;
/
