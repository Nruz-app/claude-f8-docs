-- FSCC-12948 - 01: PROC_TRANSACC_DEPO_QUEUE solo procesa transacciones NO MATCH (VALIDA = 0).
-- Base: ddl_actual_desarrollo/03_proc_transacc_depo_queue.sql (INTRANETDE 14-10-2026).
-- Cambio: antes de llamar a EXISTE_VTA_TEMPESC se revalidan las mismas condiciones del
-- trigger TRG_TRANSACC_DEPO_QUEUE contra la venta encolada (VTA_IDTRX): VALIDA = 0,
-- BARCODE informado, VTA_TEMP_CAB tipo 53 con mismo local/terminal y fecha de venta
-- (TRANSACTION_DATE; antes se usaba ACCOUNTING_DATE y no calzaba con VTA_FECHA) del
-- mismo dia, y VTA_TEMPESC corr 8 que contiene el barcode. Si no cumple, la fila de la
-- cola queda PROCESADO con mensaje OMITIDO y NO se llama al package (que devolveria
-- una transaccion ya cuadrada a VALIDA = 0).
-- Ejecutar conectado como el dueno de las tablas. Rollback: 99_rollback.sql.

CREATE OR REPLACE PROCEDURE PROC_TRANSACC_DEPO_QUEUE
IS

    v_barcode	     PROSEGUR_TRANSACTIONS.BARCODE%TYPE;
    v_vta_local      PROSEGUR_TRANSACTIONS.SERVICE_POINT_CODE%TYPE;
    v_vta_terminal   PROSEGUR_TRANSACTIONS.DEVICE_ID%TYPE;
    v_vta_fecha      PROSEGUR_TRANSACTIONS.TRANSACTION_DATE%TYPE;  -- FSCC-12948: fecha de venta (antes ACCOUNTING_DATE)
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

	    SELECT
		pt.BARCODE,
		pt.SERVICE_POINT_CODE,
		pt.DEVICE_ID,
		pt.TRANSACTION_DATE  -- FSCC-12948: fecha de venta, la que graba el POST en VTA_FECHA
	    INTO
		v_barcode,
		v_vta_local,
		v_vta_terminal,
		v_vta_fecha
	    FROM PROSEGUR_TRANSACTIONS pt,
		 VTA_TEMP_CAB c
	    WHERE pt.ID = r.ID_PROSEGUR
	      /* FSCC-12948: revalidar al momento del cron las mismas condiciones
		 del trigger TRG_TRANSACC_DEPO_QUEUE: solo NO MATCH (VALIDA = 0) */
	      AND pt.VALIDA = 0
	      AND pt.BARCODE IS NOT NULL
	      /* la venta POST encolada (VTA_IDTRX de la cola) */
	      AND c.VTA_IDTRX = r.VTA_IDTRX
	      AND c.VTA_TIPO = 53
	      AND pt.SERVICE_POINT_CODE = TO_CHAR(c.VTA_LOCAL)
	      AND pt.DEVICE_ID = TO_CHAR(c.VTA_TERMINAL)
	      /* FSCC-12948: el POST graba en VTA_FECHA la fecha de venta = TRANSACTION_DATE */
	      AND pt.TRANSACTION_DATE >=
		  CAST(
		      TRUNC(c.VTA_FECHA)
		      AS TIMESTAMP
		  )
	      AND pt.TRANSACTION_DATE <
		  CAST(
		      TRUNC(c.VTA_FECHA + 1)
		      AS TIMESTAMP
		  )
	      /* Validar VTA_TEMPESC */
	      AND EXISTS (
		   SELECT 1
		     FROM VTA_TEMPESC s
		    WHERE s.VTA_IDTRX = r.VTA_IDTRX
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
	      AND ROWNUM = 1;

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
	    /* FSCC-12948: ya no cumple las condiciones -> no se llama al package */
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

END;
/
show errors procedure PROC_TRANSACC_DEPO_QUEUE
