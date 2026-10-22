-- FSCC-12948 - 02: TRG_TRANSACC_DEPO_QUEUE con guarda contra duplicados en la cola.
-- Base: ddl_actual_desarrollo/02_trg_transacc_depo_queue.sql (INTRANETDE 14-10-2026).
-- Cambios: (1) NOT EXISTS sobre PROSEGUR_TRANSACTIONS_QUEUE (PENDIENTE/PROCESANDO);
-- (2) cruce por TRANSACTION_DATE (fecha de venta) en vez de ACCOUNTING_DATE (contable).
-- Ejecutar conectado como el dueno de las tablas. Rollback: 99_rollback.sql.

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
	   /* FSCC-12948: fecha de venta (TRANSACTION_DATE), no la contable: el POST graba en VTA_FECHA la fecha de venta */
	   AND pt.TRANSACTION_DATE >=
	       CAST(
		   TRUNC(:NEW.VTA_FECHA)
		   AS TIMESTAMP
	       )
	   AND pt.TRANSACTION_DATE <
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
	   )
	   /* FSCC-12948: no encolar si ya hay una fila viva en la cola para esa transaccion */
	   AND NOT EXISTS (
		SELECT 1
		  FROM PROSEGUR_TRANSACTIONS_QUEUE q
		 WHERE q.ID_PROSEGUR = pt.ID
		   AND q.ESTADO IN ('PENDIENTE', 'PROCESANDO')
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
