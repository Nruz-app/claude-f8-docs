-- FSCC-12948 - Trigger TRG_TRANSACC_DEPO_QUEUE (AFTER INSERT ON VTA_TEMP_CAB)
-- Fuente: INTRANETDE (desarrollo), extraido de USER_SOURCE el 2026-10-14. Solo referencia (linea base); no ejecutar.
-- ASCII: se quitaron las tildes de comentarios y mensajes.

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
