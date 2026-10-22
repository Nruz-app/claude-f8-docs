-- FSCC-12948 - 02: TRG_TRANSACC_DEPO_QUEUE valida con PKG_TRANSACC_DEPO_QUEUE.FN_VALIDA_MATCH.
-- Base: ddl_actual_desarrollo/02_trg_transacc_depo_queue.sql (INTRANETDE 14-10-2026).
-- Version anterior (15-10): anterior_2026-10-15/02_trg_transacc_depo_queue.sql.
-- Cambios respecto de la base: (1) no encola si ya hay fila PENDIENTE/PROCESANDO para la
-- transaccion; (2) cruce por TRANSACTION_DATE (fecha de venta) en vez de ACCOUNTING_DATE;
-- (3) 19-10: el SELECT de busqueda pasa a FN_VALIDA_MATCH (misma validacion que el cron),
-- que ademas exige BARCODE informado.
-- Ejecutar conectado como el dueno de las tablas, despues de 01. Rollback: 99_rollback.sql.

CREATE OR REPLACE TRIGGER TRG_TRANSACC_DEPO_QUEUE
AFTER INSERT ON VTA_TEMP_CAB
FOR EACH ROW
DECLARE

    v_id_pt NUMBER := 0;

BEGIN

    /* Solo procesar ventas tipo 53 */
    IF :NEW.VTA_TIPO = 53 THEN

        /*  Buscar la transaccion Prosegur correspondiente (validacion comun con el cron) */
        v_id_pt := PKG_TRANSACC_DEPO_QUEUE.FN_VALIDA_MATCH(
                       :NEW.VTA_IDTRX,
                       :NEW.VTA_LOCAL,
                       :NEW.VTA_TERMINAL,
                       :NEW.VTA_FECHA
                   );

        IF v_id_pt > 0 THEN

            INSERT INTO PROSEGUR_TRANSACTIONS_QUEUE (
                ID_QUEUE,
                VTA_IDTRX,
                ID_PROSEGUR,
                ESTADO,
                FECHA_CREACION
            )
            VALUES (
                SEQ_PROS_TRANS_QUEUE.NEXTVAL,
                :NEW.VTA_IDTRX,
                v_id_pt,
                'PENDIENTE',
                SYSTIMESTAMP
            );

        END IF;

    END IF;

END;
/
show errors trigger TRG_TRANSACC_DEPO_QUEUE
