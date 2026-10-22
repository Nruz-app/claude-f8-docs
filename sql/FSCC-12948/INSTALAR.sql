-- FSCC-12948 - Instalacion: package PKG_TRANSACC_DEPO_QUEUE (01), trigger TRG_TRANSACC_DEPO_QUEUE (02)
-- y borrado del SP suelto PROC_TRANSACC_DEPO_QUEUE (03).
-- Ejecutar en SQL*Plus conectado como el dueno de las tablas, desde esta carpeta.
-- El package F8_TRANSACC_DEPO_PKG no cambia. Rollback: @99_rollback.sql
set echo on
@01_pkg_transacc_depo_queue.sql
@02_trg_transacc_depo_queue.sql
@03_drop_proc_transacc_depo_queue.sql
set echo off
prompt == Estado de los objetos (PACKAGE, PACKAGE BODY y TRIGGER VALID; PROC_TRANSACC_DEPO_QUEUE suelto no debe aparecer)
select object_name, object_type, status from user_objects
 where object_name in ('PKG_TRANSACC_DEPO_QUEUE','TRG_TRANSACC_DEPO_QUEUE','PROC_TRANSACC_DEPO_QUEUE')
 order by object_name, object_type;
select trigger_name, status from user_triggers where trigger_name = 'TRG_TRANSACC_DEPO_QUEUE';
