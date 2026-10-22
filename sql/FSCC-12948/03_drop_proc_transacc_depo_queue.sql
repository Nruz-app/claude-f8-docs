-- FSCC-12948 - 03: borra el SP suelto PROC_TRANSACC_DEPO_QUEUE.
-- Lo reemplaza PKG_TRANSACC_DEPO_QUEUE.PROC_TRANSACC_DEPO_QUEUE (01). Ningun job lo llama
-- (USER_JOBS y USER_SCHEDULER_JOBS vacios en desarrollo y test). El job futuro debe llamar al package.
-- Ejecutar conectado como el dueno de las tablas, despues de 01 y 02.
-- Rollback: 99_rollback.sql (lo vuelve a crear desde la linea base).

DROP PROCEDURE PROC_TRANSACC_DEPO_QUEUE;
