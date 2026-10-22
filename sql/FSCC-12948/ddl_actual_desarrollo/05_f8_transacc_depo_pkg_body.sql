-- FSCC-12948 - Package F8_TRANSACC_DEPO_PKG (body)
-- Fuente: INTRANETDE (desarrollo), extraido de USER_SOURCE el 2026-10-14. Solo referencia (linea base); no ejecutar.
-- ASCII: se quitaron las tildes de comentarios y mensajes.

CREATE OR REPLACE PACKAGE BODY		  F8_TRANSACC_DEPO_PKG AS

  PROCEDURE FN_SIG_DIA_HABIL(P_FECHA IN VARCHAR2, SRV_MESSAGE OUT VARCHAR2) IS
    V_FECHA DATE;
    V_DUMMY NUMBER;
  BEGIN

    V_FECHA := TRUNC(TO_DATE(P_FECHA, 'YYYY-MM-DD'));

    LOOP

      V_FECHA := V_FECHA + 1;

      IF TO_CHAR(V_FECHA, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH') NOT IN
	 ('SAT', 'SUN') THEN

	SELECT COUNT(*)
	  INTO V_DUMMY
	  FROM FERIADOS_CHILE
	 WHERE TRUNC(FECHA) = V_FECHA;

	-- Si no es feriado, devuelve la fecha y termina
	IF V_DUMMY = 0 THEN
	  SRV_MESSAGE := TO_CHAR(V_FECHA, 'YYYY-MM-DD');
	  EXIT;
	END IF;

      END IF;

    END LOOP;

  END FN_SIG_DIA_HABIL;

  PROCEDURE EXISTE_VTA_TEMPESC(VTA_ID	    IN NUMBER,
			       VTA_LOCAL    IN NUMBER,
			       VTA_TERMINAL IN NUMBER,
			       VTA_FECHA    IN VARCHAR2,
			       CODIGO_BARRA IN VARCHAR2,
			       FLG_PAIS     IN VARCHAR2,
			       SRV_MESSAGE  OUT VARCHAR2) AS

    v_vta_idtrx       NUMBER := NULL;
    v_fecha	      DATE;
    v_valida	      NUMBER := 0;
    v_rows_insert_prd NUMBER := 0;

    v_tabla_tempesc VARCHAR2(100);
    v_tabla_cab     VARCHAR2(100);
    v_tabla_prd     VARCHAR2(100);

    v_flg_pais		       VARCHAR2(10);
    v_match_status	       VARCHAR2(10);
    v_vta_id		       NUMBER;
    v_barcode		       VARCHAR2(100);
    v_monto		       NUMBER := 0;
    v_amount_difference        NUMBER;
    v_document_difference_type VARCHAR2(1);
    v_monto_prosegur	       NUMBER := 0;

  BEGIN

    v_vta_id := VTA_ID;

    BEGIN
      v_barcode := SUBSTR(CODIGO_BARRA, 1, LENGTH(CODIGO_BARRA) - 1);
      -- Extraer monto (9 caracteres desde la posicion 2)
      v_monto := TO_NUMBER(SUBSTR(v_barcode, 2, 8));

    EXCEPTION
      WHEN OTHERS THEN
	NULL;
    END;

    /*IF FLG_PAIS IS NULL OR TRIM(FLG_PAIS) = '' THEN
      v_flg_pais := NULL;
    ELSE
      v_flg_pais := LOWER(TRIM(FLG_PAIS));
    END IF;*/
    IF TRIM(FLG_PAIS) IS NULL THEN
      v_flg_pais := NULL;
    ELSE
      v_flg_pais := LOWER(TRIM(FLG_PAIS));
    END IF;

    IF v_flg_pais IS NULL THEN
      v_tabla_tempesc := 'vta_tempesc';
      v_tabla_cab     := 'vta_temp_cab';
      v_tabla_prd     := 'vta_prd';
    ELSE
      v_tabla_tempesc := 'vta_' || v_flg_pais || 'tempesc';
      v_tabla_cab     := 'vta_' || v_flg_pais || 'temp_cab';
      v_tabla_prd     := 'vta_' || v_flg_pais || 'prd';
    END IF;

    ------------------------------------------------
    -- Convertir fecha
    ------------------------------------------------
    BEGIN
      v_fecha := TO_DATE(VTA_FECHA, 'YYYY-MM-DD');
    EXCEPTION
      WHEN OTHERS THEN
	SRV_MESSAGE := 'ERROR -> Fecha invalida';
	RETURN;
    END;

    ------------------------------------------------
    -- Buscar trx (dinamico)
    ------------------------------------------------
    BEGIN
      EXECUTE IMMEDIATE '
	    SELECT s.vta_idtrx
	    FROM ' || v_tabla_tempesc || ' s
	    JOIN ' || v_tabla_cab || ' c
	      ON c.vta_idtrx = s.vta_idtrx
	    WHERE s.vta_corr = 8
	      AND s.vta_msg_data LIKE ''%'' || :1 || ''%''
	      AND c.vta_fecha = :2
	      AND c.vta_local = :3
	      AND c.vta_terminal = :4
	      AND c.vta_tipo = 53
	      AND ROWNUM = 1
	'
	INTO v_vta_idtrx
	USING v_barcode, v_fecha, VTA_LOCAL, VTA_TERMINAL;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
	v_vta_idtrx := NULL;
    END;

    IF v_vta_idtrx IS NOT NULL THEN

      BEGIN
	EXECUTE IMMEDIATE '
      INSERT INTO ' || v_tabla_tempesc || ' (
	 vta_idtrx,
	 vta_msg_data,
	 vta_fechareg,
	 vta_usuario,
	 vta_corr
      )
      SELECT :1, :2, SYSDATE, ''API PSG'', -2
      FROM dual
      WHERE NOT EXISTS (
	 SELECT 1
	 FROM ' || v_tabla_tempesc || '
	 WHERE vta_idtrx = :3
	   AND vta_corr = -2
      )'
	  USING v_vta_idtrx, CODIGO_BARRA, v_vta_idtrx;
      EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
	  NULL;
      END;
      ------------------------------------------------
      -- Obtener monto real procesado Prosegur
      ------------------------------------------------

      SELECT NVL(TOTAL, 0)
	INTO v_monto_prosegur
	FROM PROSEGUR_TRANSACTIONS
       WHERE ID = v_vta_id;
      v_amount_difference := v_monto_prosegur - v_monto;

      IF v_amount_difference < 0 then
	v_document_difference_type := 'F';
      END IF;

      IF v_amount_difference > 0 then
	v_document_difference_type := 'S';
      END IF;

      IF v_amount_difference = 0 then
	v_document_difference_type := 'C';
      END IF;

      ------------------------------------------------
      -- Update estado
      ------------------------------------------------
      UPDATE PROSEGUR_TRANSACTIONS
	 SET BARCODE		= CODIGO_BARRA,
	     SERVICE_POINT_CODE = VTA_LOCAL,
	     DEVICE_ID		= VTA_TERMINAL,
	     TRANSACTION_DATE	= v_fecha
      --       TOTAL		  = v_monto
       WHERE ID = v_vta_id;

      ------------------------------------------------
      -- INSERT dinamico PRD
      ------------------------------------------------
      EXECUTE IMMEDIATE '
	    INSERT INTO ' || v_tabla_prd || ' (
		PRV_TECHKEY,
		PRV_FECHADEP,
		PRV_LOCAL,
		PRV_TERMINAL,
		PRV_TIPOREC,
		PRV_PRSCLI,
		PRV_SERVICIO,
		PRV_SOBRE,
		PRV_PRSLOC,
		PRV_PRSCAJERO,
		PRV_TIPOSOBRE,
		PRV_CTACTE,
		PRV_NOMCTA,
		PRV_TOTDOCS,
		PRV_TIPODIFDOC,
		PRV_NUMDIFDOC,
		PRV_CODDIFDOC,
		PRV_NOMDIFDOC,
		PRV_MONTOSOBRE,
		PRV_TIPODIFMON,
		PRV_MONTODIF,
		PRV_CODDIFMON,
		PRV_NOMDIFMON,
		PRV_SERV2,
		PRV_NUMREC,
		PRV_FECHAVTA,
		PRV_SOBRE_ANT,
		PRV_SERIEDEPOSITO,
		PRV_NUMDEPOSITO,
		PRV_NUMDEPOSITO2,
		PRV_FECHAREG,
		PRV_NOMBREARCH,
		PRV_USUARIOREG,
		SOB_REMITO,
		SOB_CODIGOBARRA,
				PRV_FECHACONTABLE
	    )
	    SELECT
		vta_prs_sec.NEXTVAL,
		TRUNC(NVL(PT.TRANSACTION_DATE, SYSDATE)),
		NVL(PT.SERVICE_POINT_CODE, 0),
		NVL(PT.DEVICE_ID, 0),
		''F8'',
		NVL(TO_NUMBER(PT.CENTER_CODE),0),
		''E'',
				NVL(TO_NUMBER(PT.PRV_SOBRE),0),
		NVL(TO_NUMBER(PT.CENTER_CODE),0),
		NVL(TO_NUMBER(PT.TELLER_LOGIN), 0),
		''EFE'',
		''0'',
		''0'',
		0,
		NVL(PT.DOCUMENT_DIFFERENCE_TYPE,''S''),
		0,
		''0'',
		'' '',
		:1,
		:2,
		:3,
		''0'',
		'' '',
		''SCL'',
		0,
		TRUNC(NVL(PT.TRANSACTION_DATE, SYSDATE)),
		0,
		''CSS'',
		NVL(PT.DEPOSIT_NUMBER, 0),
		0,
		SYSDATE,
		''API PSG'',
		''interfaz'',
		NVL(PT.REMITTANCE_CODE,''0''),
		NVL(PT.BARCODE, ''0''),
				TRUNC(NVL(PT.ACCOUNTING_DATE, SYSDATE))
	    FROM PROSEGUR_TRANSACTIONS PT
	    WHERE PT.ID = :4
			AND NOT EXISTS (
		  SELECT 1
		  FROM ' || v_tabla_prd || ' p
		  WHERE p.sob_codigobarra = PT.BARCODE
		)
	'
	--USING v_vta_id, v_document_difference_type, v_amount_difference;
	USING
	v_monto,
	v_document_difference_type,
	v_amount_difference,
	v_vta_id;

      v_rows_insert_prd := SQL%ROWCOUNT;

      /*BEGIN
	INSERT INTO vta_param
	  (VTA_CCODTIPO, VTA_CCODIGO, VTA_XGLOSA, VTA_DFECHAREG)
	VALUES
	  (v_vta_id, 'DBGRC', 'ROWCOUNT=' || v_rows_insert_prd, SYSDATE);
      EXCEPTION
	WHEN OTHERS THEN
	  NULL;
      END;*/

      ------------------------------------------------
      -- DEBUG 2: Estado de PROSEGUR_TRANSACTIONS
      ------------------------------------------------
      /*	DECLARE
	  v_dbg_valida NUMBER;
	  v_dbg_barcode VARCHAR2(60);
      BEGIN
	  SELECT VALIDA,
		 BARCODE
	  INTO v_dbg_valida,
	       v_dbg_barcode
	  FROM PROSEGUR_TRANSACTIONS
	  WHERE ID = v_vta_id;

      EXCEPTION
      WHEN OTHERS THEN
	  NULL;
      END;*/

      ------------------------------------------------
      -- DEBUG 3: Ya existe en PRD?
      ------------------------------------------------
      /*	DECLARE
	  v_dbg_count NUMBER;
      BEGIN
	  EXECUTE IMMEDIATE '
	      SELECT COUNT(*)
	      FROM ' || v_tabla_prd || '
	      WHERE sob_codigobarra = :1'
	  INTO v_dbg_count
	  USING CODIGO_BARRA;

      EXCEPTION
      WHEN OTHERS THEN
	  NULL;
      END;*/

      ------------------------------------------------
      -- DEBUG 4: Cuantas filas cumple el SELECT?
      ------------------------------------------------
      /*DECLARE
	  v_dbg_count NUMBER;
      BEGIN
	  SELECT COUNT(*)
	  INTO v_dbg_count
	  FROM PROSEGUR_TRANSACTIONS PT
	  WHERE PT.ID = v_vta_id
	    AND PT.VALIDA = 0
	    AND NOT EXISTS (
		  SELECT 1
		  FROM vta_prd p
		  WHERE p.sob_codigobarra = PT.BARCODE
	    );
      EXCEPTION
      WHEN OTHERS THEN
	  NULL;
      END;*/

      v_valida	     := 1;
      v_match_status := 'MATCHED';
      --v_amount_difference := 0;

      IF v_rows_insert_prd = 0 THEN
	SRV_MESSAGE    := 'ERROR -> INSERT PRD NO GENERO FILAS (ID: ' ||
			  v_vta_id || ')';
	v_valida       := 0;
	v_match_status := 'NO_MATCHED';
	-- v_amount_difference := null;

	BEGIN
	  INSERT INTO PROSEGUR_TRANSACTION_LOG
	    (ID, TRANSACTION_ID, LOG_TYPE, MESSAGE, CREATED_AT, CREATED_BY)
	  VALUES
	    (SEQ_PROSEGUR_TRANSACTION_LOG.NEXTVAL,
	     v_vta_id,
	     'INSERT_PRD_FAILED',
	     'INSERT PRD no genero filas. VTA_IDTRX=' || v_vta_idtrx ||
	     ', BARCODE=' || CODIGO_BARRA,
	     SYSDATE,
	     'F8_TRANSACC_DEPO_PKG');
	EXCEPTION
	  WHEN OTHERS THEN
	    NULL;
	END;

	EXECUTE IMMEDIATE '
			    DELETE FROM ' || v_tabla_tempesc || '
			    WHERE vta_idtrx = :1
			      AND vta_msg_data = :2
			      AND vta_corr = -2'
	  USING v_vta_idtrx, CODIGO_BARRA;

      END IF;

    END IF;

    ------------------------------------------------
    -- Update validacion
    ------------------------------------------------
    IF v_valida = 1 THEN
      UPDATE PROSEGUR_TRANSACTIONS
	 SET VALIDA		      = 1,
	     MATCH_STATUS	      = v_match_status,
	     UPDATED_AT 	      = SYSTIMESTAMP,
	     MATCH_DATE 	      = SYSTIMESTAMP,
	     AMOUNT_DIFFERENCE	      = v_amount_difference,
	     DOCUMENT_DIFFERENCE_TYPE = v_document_difference_type
       WHERE ID = v_vta_id;

      EXECUTE IMMEDIATE 'UPDATE ' || v_tabla_prd || '
		     SET PRV_TIPODIFDOC = :1,
			 PRV_MONTODIF = :2
		     WHERE SOB_CODIGOBARRA = :3'
	USING v_document_difference_type, v_amount_difference, CODIGO_BARRA;

    ELSE
      UPDATE PROSEGUR_TRANSACTIONS
	 SET VALIDA	  = 0,
	     MATCH_STATUS = v_match_status,
	     UPDATED_AT   = SYSTIMESTAMP
       WHERE ID = v_vta_id;
    END IF;

    ------------------------------------------------
    -- Mensaje OK
    ------------------------------------------------
    IF v_valida = 1 THEN

      SRV_MESSAGE := 'PKG OK -> LOCAL: ' || VTA_LOCAL || ' ID: ' ||
		     v_vta_id || ' TERMINAL: ' || VTA_TERMINAL ||
		     ' FECHA: ' || VTA_FECHA || ' CODIGO: ' || CODIGO_BARRA ||
		     ' PAIS: ' || NVL(v_flg_pais, 'BASE');

    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      SRV_MESSAGE := 'ERROR -> ' || SUBSTR(SQLERRM, 1, 200);
  END EXISTE_VTA_TEMPESC;

END F8_TRANSACC_DEPO_PKG;
/
