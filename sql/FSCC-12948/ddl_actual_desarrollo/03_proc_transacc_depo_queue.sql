-- FSCC-12948 - Procedimiento PROC_TRANSACC_DEPO_QUEUE (cron)
-- Fuente: INTRANETDE (desarrollo), extraido de USER_SOURCE el 2026-10-14. Solo referencia (linea base); no ejecutar.
-- ASCII: se quitaron las tildes de comentarios y mensajes.

CREATE OR REPLACE PROCEDURE PROC_TRANSACC_DEPO_QUEUE
IS

    v_barcode	     PROSEGUR_TRANSACTIONS.BARCODE%TYPE;
    v_vta_local      PROSEGUR_TRANSACTIONS.SERVICE_POINT_CODE%TYPE;
    v_vta_terminal   PROSEGUR_TRANSACTIONS.DEVICE_ID%TYPE;
    v_vta_fecha      PROSEGUR_TRANSACTIONS.ACCOUNTING_DATE%TYPE;
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
		pt.ACCOUNTING_DATE
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
