-- =====================================================================
-- FSCC-12901 T1 + T2 (carpeta consolidada) - Paso 03
-- Parametros de T1 y T2 en VTA_FACOPARAM (tipo 1502).
-- Fuentes: FSCC-12958/03_parametros.sql + FSCC-12957/02_parametros.sql
-- Se leen en cada ejecucion: se cambian con UPDATE, sin recompilar.
-- Estructura (test): VTA_CCODTIPO NUMBER, VTA_CCODIGO VARCHAR2(15),
--   VTA_XGLOSA VARCHAR2(128), VTA_DFECHAREG DATE NOT NULL DEFAULT sysdate.
-- El rango de la DI manual (1500/1501 'DI', -500 / 20000) NO se toca.
-- =====================================================================

-- Verificar tipo 1502 libre (esperado: 0)
select count(*) from VTA_FACOPARAM where vta_ccodtipo = 1502;

-- ---- T1: compensacion automatica de DI (FSCC-12957) ----
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_DI_ACTIVO', 'S',     sysdate);  -- S/N T1 activa
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_DI_MIN',    '-1000', sysdate);  -- limite inferior DR (inclusive)
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_DI_MAX',    '20000', sysdate);  -- limite superior DR (inclusive)

-- ---- T2: cierre de caja automatico (FSCC-12958) ----
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_ACTIVO',    'S',     sysdate);  -- S/N T2 activa
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_VAL_CHEQ',  'S',     sysdate);  -- S/N cheque a fecha (RY-01)
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_VAL_ZZZ',   'N',     sysdate);  -- S/N formula ZZZ (RY-06, opcion 103)
-- CA_VAL_USD (dolares vs Prosegur, RZ-09) eliminado el 07-10-2026: FACO solo cierre Y.

-- ---- Comunes ----
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_DECIMAL',   '0',     sysdate);  -- decimales: gFormat FACO '#,#0'
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_DIAS',      '30',    sysdate);  -- dias maximos para reevaluar una caja
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_SIN_SOBRE', 'S',     sysdate);  -- S/N incluir cajas sin sobres del mismo local-dia (DF fila 12)
commit;
