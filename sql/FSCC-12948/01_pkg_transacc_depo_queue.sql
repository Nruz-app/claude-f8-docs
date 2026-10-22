-- FSCC-12948 - 01: package PKG_TRANSACC_DEPO_QUEUE (reemplaza al SP suelto PROC_TRANSACC_DEPO_QUEUE).
-- Base: anterior_2026-10-15/01_proc_transacc_depo_queue.sql y 02_trg_transacc_depo_queue.sql.
-- Contenido:
--   FN_VALIDA_MATCH          validacion del match, unica para el trigger y el cron. Es el SELECT
--                            que antes estaba repetido en TRG_TRANSACC_DEPO_QUEUE y en el SP:
--                            VALIDA = 0, BARCODE informado, mismo local/terminal, TRANSACTION_DATE
--                            del dia de VTA_FECHA, VTA_TEMPESC corr 8 con el barcode y sin fila
--                            viva (PENDIENTE/PROCESANDO) en la cola. Devuelve el ID de
--                            PROSEGUR_TRANSACTIONS o 0. No lee VTA_TEMP_CAB (lo llama el trigger
--                            de esa tabla: evita ORA-04091) y no hace DML (se puede usar en un SELECT).
--   PROC_TRANSACC_DEPO_QUEUE el SP del cron, igual que antes, pero validando con FN_VALIDA_MATCH.
-- Cambios de comportamiento respecto del 15-10:
--   * El trigger tambien exige BARCODE informado (con barcode nulo el LIKE '%%' calzaba con cualquier venta).
--   * El cron omite (OMITIDO) una fila si hay OTRA fila viva en la cola para la misma transaccion.
-- Ejecutar conectado como el dueno de las tablas, ANTES de 02 (el trigger usa la funcion).
-- Rollback: 99_rollback.sql.

CREATE OR REPLACE PACKAGE PKG_TRANSACC_DEPO_QUEUE
IS

    /* Devuelve el ID de PROSEGUR_TRANSACTIONS que hace match con la venta POST, o 0.
       p_id_prosegur: NULL = cualquiera (trigger, toma el MAX); informado = solo esa transaccion (cron).
       p_id_queue:    fila de la cola que no se cuenta como duplicado (la que procesa el cron). */
    FUNCTION FN_VALIDA_MATCH (
        p_vta_idtrx     IN VTA_TEMP_CAB.VTA_IDTRX%TYPE,
        p_vta_local     IN VTA_TEMP_CAB.VTA_LOCAL%TYPE,
        p_vta_terminal  IN VTA_TEMP_CAB.VTA_TERMINAL%TYPE,
        p_vta_fecha     IN VTA_TEMP_CAB.VTA_FECHA%TYPE,
        p_id_prosegur   IN PROSEGUR_TRANSACTIONS.ID%TYPE DEFAULT NULL,
        p_id_queue      IN PROSEGUR_TRANSACTIONS_QUEUE.ID_QUEUE%TYPE DEFAULT NULL
    ) RETURN NUMBER;

    /* Cron: procesa hasta 500 filas PENDIENTE de PROSEGUR_TRANSACTIONS_QUEUE. */
    PROCEDURE PROC_TRANSACC_DEPO_QUEUE;

END PKG_TRANSACC_DEPO_QUEUE;
/
show errors package PKG_TRANSACC_DEPO_QUEUE

CREATE OR REPLACE PACKAGE BODY PKG_TRANSACC_DEPO_QUEUE
IS

    /*****************************************************************
     * Validacion del match (antes repetida en el trigger y en el SP)
     *****************************************************************/
    FUNCTION FN_VALIDA_MATCH (
        p_vta_idtrx     IN VTA_TEMP_CAB.VTA_IDTRX%TYPE,
        p_vta_local     IN VTA_TEMP_CAB.VTA_LOCAL%TYPE,
        p_vta_terminal  IN VTA_TEMP_CAB.VTA_TERMINAL%TYPE,
        p_vta_fecha     IN VTA_TEMP_CAB.VTA_FECHA%TYPE,
        p_id_prosegur   IN PROSEGUR_TRANSACTIONS.ID%TYPE DEFAULT NULL,
        p_id_queue      IN PROSEGUR_TRANSACTIONS_QUEUE.ID_QUEUE%TYPE DEFAULT NULL
    ) RETURN NUMBER
    IS

        v_id_pt NUMBER := 0;

    BEGIN

        SELECT NVL(MAX(pt.ID), 0)
          INTO v_id_pt
          FROM PROSEGUR_TRANSACTIONS pt
         WHERE pt.VALIDA = 0
           AND pt.BARCODE IS NOT NULL
           /* cron: solo la transaccion encolada; trigger: cualquiera */
           AND (p_id_prosegur IS NULL OR pt.ID = p_id_prosegur)
           AND pt.SERVICE_POINT_CODE = TO_CHAR(p_vta_local)
           AND pt.DEVICE_ID = TO_CHAR(p_vta_terminal)
           /* fecha de venta (TRANSACTION_DATE): el POST graba en VTA_FECHA la fecha de venta */
           AND pt.TRANSACTION_DATE >=
               CAST(
                   TRUNC(p_vta_fecha)
                   AS TIMESTAMP
               )
           AND pt.TRANSACTION_DATE <
               CAST(
                   TRUNC(p_vta_fecha + 1)
                   AS TIMESTAMP
               )
           /*  Validar VTA_TEMPESC */
           AND EXISTS (
                SELECT 1
                  FROM VTA_TEMPESC s
                 WHERE s.VTA_IDTRX = p_vta_idtrx
                   AND s.VTA_CORR = 8
                   AND s.VTA_MSG_DATA LIKE
                       '%' ||
                       SUBSTR(
                           pt.BARCODE,
                           1,
                           LENGTH(pt.BARCODE) - 1
                       ) ||
                       '%'
           )
           /* sin otra fila viva en la cola para esa transaccion (el cron excluye la propia) */
           AND NOT EXISTS (
                SELECT 1
                  FROM PROSEGUR_TRANSACTIONS_QUEUE q
                 WHERE q.ID_PROSEGUR = pt.ID
                   AND q.ESTADO IN ('PENDIENTE', 'PROCESANDO')
                   AND q.ID_QUEUE <> NVL(p_id_queue, -1)
           );

        RETURN v_id_pt;

    END FN_VALIDA_MATCH;


    /*****************************************************************
     * Cron (antes el SP suelto PROC_TRANSACC_DEPO_QUEUE)
     *****************************************************************/
    PROCEDURE PROC_TRANSACC_DEPO_QUEUE
    IS

        v_barcode        PROSEGUR_TRANSACTIONS.BARCODE%TYPE;
        v_vta_local      PROSEGUR_TRANSACTIONS.SERVICE_POINT_CODE%TYPE;
        v_vta_terminal   PROSEGUR_TRANSACTIONS.DEVICE_ID%TYPE;
        v_vta_fecha      PROSEGUR_TRANSACTIONS.TRANSACTION_DATE%TYPE;  -- fecha de venta
        v_cab_local      VTA_TEMP_CAB.VTA_LOCAL%TYPE;
        v_cab_terminal   VTA_TEMP_CAB.VTA_TERMINAL%TYPE;
        v_cab_fecha      VTA_TEMP_CAB.VTA_FECHA%TYPE;
        v_srv_message    VARCHAR2(4000);
        v_error_message  VARCHAR2(4000);

    BEGIN

        /***************************************************
         * Procesar maximo 500 registros por ejecucion.
         ***************************************************/
        FOR r IN (
            SELECT ID_QUEUE,
                   VTA_IDTRX,
                   ID_PROSEGUR
            FROM (
                SELECT ID_QUEUE,
                       VTA_IDTRX,
                       ID_PROSEGUR
                FROM PROSEGUR_TRANSACTIONS_QUEUE
                WHERE ESTADO = 'PENDIENTE'
                ORDER BY ID_QUEUE
            )
            WHERE ROWNUM <= 500
        )
        LOOP

            BEGIN

                UPDATE PROSEGUR_TRANSACTIONS_QUEUE
                   SET ESTADO = 'PROCESANDO',
                       INTENTOS = INTENTOS + 1
                 WHERE ID_QUEUE = r.ID_QUEUE;

                /* la venta POST encolada (VTA_IDTRX de la cola); si no existe -> NO_DATA_FOUND */
                SELECT c.VTA_LOCAL,
                       c.VTA_TERMINAL,
                       c.VTA_FECHA
                  INTO v_cab_local,
                       v_cab_terminal,
                       v_cab_fecha
                  FROM VTA_TEMP_CAB c
                 WHERE c.VTA_IDTRX = r.VTA_IDTRX
                   AND c.VTA_TIPO = 53
                   AND ROWNUM = 1;

                /* revalidar al momento del cron las mismas condiciones del trigger */
                IF FN_VALIDA_MATCH(r.VTA_IDTRX,
                                   v_cab_local,
                                   v_cab_terminal,
                                   v_cab_fecha,
                                   r.ID_PROSEGUR,
                                   r.ID_QUEUE) = 0 THEN
                    RAISE NO_DATA_FOUND;
                END IF;

                SELECT
                    pt.BARCODE,
                    pt.SERVICE_POINT_CODE,
                    pt.DEVICE_ID,
                    pt.TRANSACTION_DATE  -- fecha de venta, la que graba el POST en VTA_FECHA
                INTO
                    v_barcode,
                    v_vta_local,
                    v_vta_terminal,
                    v_vta_fecha
                FROM PROSEGUR_TRANSACTIONS pt
                WHERE pt.ID = r.ID_PROSEGUR;

                F8_TRANSACC_DEPO_PKG.EXISTE_VTA_TEMPESC(
                    r.ID_PROSEGUR,
                    TO_NUMBER(v_vta_local),
                    TO_NUMBER(v_vta_terminal),
                    TO_CHAR(
                        v_vta_fecha,
                        'YYYY-MM-DD'
                    ),
                    v_barcode,
                    NULL,
                    v_srv_message
                );


                UPDATE PROSEGUR_TRANSACTIONS_QUEUE
                   SET ESTADO = 'PROCESADO',
                       FECHA_PROCESO = SYSTIMESTAMP,
                       ERROR_MESSAGE = SUBSTR(
                           v_srv_message,
                           1,
                           4000
                       )
                 WHERE ID_QUEUE = r.ID_QUEUE;


            EXCEPTION
                /* ya no cumple las condiciones -> no se llama al package */
                WHEN NO_DATA_FOUND THEN

                    UPDATE PROSEGUR_TRANSACTIONS_QUEUE
                       SET ESTADO = 'PROCESADO',
                           FECHA_PROCESO = SYSTIMESTAMP,
                           ERROR_MESSAGE = 'OMITIDO -> transaccion ' || r.ID_PROSEGUR ||
                                           ' / VTA_IDTRX ' || r.VTA_IDTRX ||
                                           ' no cumple condiciones de match (VALIDA <> 0, venta' ||
                                           ' POST distinta o sin VTA_TEMPESC corr 8)'
                     WHERE ID_QUEUE = r.ID_QUEUE;

                WHEN OTHERS THEN

                    v_error_message := SQLERRM;

                    UPDATE PROSEGUR_TRANSACTIONS_QUEUE
                       SET ESTADO = 'ERROR',
                           FECHA_PROCESO = SYSTIMESTAMP,
                           ERROR_MESSAGE = SUBSTR(
                               v_error_message,
                               1,
                               4000
                           )
                     WHERE ID_QUEUE = r.ID_QUEUE;

            END;

        END LOOP;


        /******************************************
         * Confirmar lote
         ******************************************/
        COMMIT;

    END PROC_TRANSACC_DEPO_QUEUE;

END PKG_TRANSACC_DEPO_QUEUE;
/
show errors package body PKG_TRANSACC_DEPO_QUEUE
