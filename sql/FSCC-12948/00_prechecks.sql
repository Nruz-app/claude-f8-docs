-- FSCC-12948 - Prechecks (SOLO LECTURA)
-- Ejecutar conectado como el dueno de las tablas (INTRANETDE en desarrollo).
-- Compatible con Oracle 10.2.
set lines 220 pages 200 trimspool on feedback on

prompt == 1. Objetos del requerimiento y su estado
col object_name for a32
select object_name, object_type, status, to_char(last_ddl_time,'yyyy-mm-dd hh24:mi') last_ddl
  from user_objects
 where object_name in ('PROSEGUR_TRANSACTIONS','PROSEGUR_TRANSACTIONS_QUEUE','PROSEGUR_TRANSACTION_LOG',
                       'TRG_PROSEGUR_TRANSACTIONS','TRG_TRANSACC_DEPO_QUEUE','PROC_TRANSACC_DEPO_QUEUE','PKG_TRANSACC_DEPO_QUEUE',
                       'F8_TRANSACC_DEPO_PKG','SEQ_PROS_TRANS_QUEUE','SEQ_PROS_TRIG_QUEUE',
                       'SEQ_PROSEGUR_TRANSACTIONS','SEQ_PROSEGUR_TRANSACTION_LOG','VTA_TEMP_CAB','VTA_TEMPESC','VTA_PRD')
 order by object_name, object_type;

prompt == 2. Triggers sobre VTA_TEMP_CAB
col trigger_name for a30
col triggering_event for a16
select trigger_name, trigger_type, triggering_event, status from user_triggers where table_name = 'VTA_TEMP_CAB';

prompt == 3. Cola por estado
select estado, count(*) n, min(fecha_creacion) desde, max(fecha_creacion) hasta
  from prosegur_transactions_queue group by estado;

prompt == 4. Duplicados en cola (mismo ID_PROSEGUR mas de una vez)
select id_prosegur, count(*) n, min(estado) est_min, max(estado) est_max
  from prosegur_transactions_queue group by id_prosegur having count(*) > 1;

prompt == 5. Cola apuntando a PT que ya esta VALIDA = 1 (riesgo de deshacer el match)
select q.id_queue, q.id_prosegur, q.estado, pt.valida, pt.match_status
  from prosegur_transactions_queue q join prosegur_transactions pt on pt.id = q.id_prosegur
 where q.estado = 'PENDIENTE' and pt.valida = 1;

prompt == 6. PROSEGUR_TRANSACTIONS por VALIDA / MATCH_STATUS
select valida, match_status, count(*) n from prosegur_transactions group by valida, match_status;

prompt == 7. Sin match y sin cola: tiene ya la venta (POST) en VTA_TEMP_CAB/VTA_TEMPESC?
col barcode for a32
col local_ for a6
col term for a6
select pt.id, pt.service_point_code local_, pt.device_id term, pt.barcode,
       to_char(pt.accounting_date,'yyyy-mm-dd') f_contable, to_char(pt.transaction_date,'yyyy-mm-dd') f_trx,
       (select count(*) from vta_temp_cab c, vta_tempesc s
         where s.vta_idtrx = c.vta_idtrx and s.vta_corr = 8 and c.vta_tipo = 53
           and c.vta_local = to_number(pt.service_point_code) and c.vta_terminal = to_number(pt.device_id)
           and c.vta_fecha = trunc(pt.accounting_date)
           and s.vta_msg_data like '%' || substr(pt.barcode, 1, length(pt.barcode) - 1) || '%') venta_post
  from prosegur_transactions pt
 where pt.valida = 0
   and not exists (select 1 from prosegur_transactions_queue q where q.id_prosegur = pt.id and q.estado = 'PENDIENTE');

prompt == 8. Job del cron (DBMS_JOB / Scheduler)
col what for a60
select job, what, interval, next_date, broken, failures from user_jobs where upper(what) like '%DEPO_QUEUE%';
select job_name, repeat_interval, enabled, state from user_scheduler_jobs where upper(job_action) like '%DEPO_QUEUE%';

prompt == 9. Log de fallas del package
col message for a90
select id, transaction_id, log_type, message, created_at from prosegur_transaction_log order by id;
