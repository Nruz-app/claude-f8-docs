-- FSCC-12948 - 99: rollback de 01, 02 y 03.
-- Vuelve a crear PROC_TRANSACC_DEPO_QUEUE (SP suelto) y TRG_TRANSACC_DEPO_QUEUE tal como estaban
-- en INTRANETDE el 14-10-2026 (copia de ddl_actual_desarrollo/03 y 02) y al final borra el
-- package PKG_TRANSACC_DEPO_QUEUE (el trigger de la linea base ya no lo usa).
-- Ejecutar conectado como el dueno de las tablas.

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
show errors procedure PROC_TRANSACC_DEPO_QUEUE

CREATE OR REPLACE TRIGGER TRG_TRANSACC_DEPO_QUEUE
AFTER INSERT ON VTA_TEMP_CAB
FOR EACH ROW
DECLARE

    v_id_pt NUMBER := 0;

BEGIN

    /* Solo procesar ventas tipo 53 */
    IF :NEW.VTA_TIPO = 53 THEN

	/*  Buscar la transaccion Prosegur correspondiente */
	SELECT NVL(MAX(pt.ID), 0)
	  INTO v_id_pt
	  FROM PROSEGUR_TRANSACTIONS pt
	 WHERE pt.VALIDA = 0
	   AND pt.SERVICE_POINT_CODE = TO_CHAR(:NEW.VTA_LOCAL)
	   AND pt.DEVICE_ID = TO_CHAR(:NEW.VTA_TERMINAL)
	   AND pt.ACCOUNTING_DATE >=
	       CAST(
		   TRUNC(:NEW.VTA_FECHA)
		   AS TIMESTAMP
	       )
	   AND pt.ACCOUNTING_DATE <
	       CAST(
		   TRUNC(:NEW.VTA_FECHA + 1)
		   AS TIMESTAMP
	       )
	   /*  Validar VTA_TEMPESC */
	   AND EXISTS (
		SELECT 1
		  FROM VTA_TEMPESC s
		 WHERE s.VTA_IDTRX = :NEW.VTA_IDTRX
		   AND s.VTA_CORR = 8
		   AND s.VTA_MSG_DATA LIKE
		       '%' ||
		       SUBSTR(
			   pt.BARCODE,
			   1,
			   LENGTH(pt.BARCODE) - 1
		       ) ||
		       '%'
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

-- 19-10-2026: el package reemplazo al SP suelto; se borra al volver a la linea base.
DROP PACKAGE PKG_TRANSACC_DEPO_QUEUE;
