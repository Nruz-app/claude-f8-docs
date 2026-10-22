-- =====================================================================
-- FSCC-12958 (HU-01-T2) Cierre de caja automatico - Falabella Colombia
-- 03 - Parametros del proceso en VTA_FACOPARAM (tipo 1502)
-- Las validaciones que en el exe dependen del perfil del usuario
-- (opciones 103 ZZZ, 109 dolares y exencion de cheque a fecha para los
-- perfiles 8/10/12) quedan como flags de negocio.
--
-- Estructura verificada en test (06-10-2026):
--   VTA_CCODTIPO  NUMBER        NOT NULL
--   VTA_CCODIGO   VARCHAR2(15)  NOT NULL
--   VTA_XGLOSA    VARCHAR2(128)
--   VTA_DFECHAREG DATE          NOT NULL DEFAULT sysdate
-- Tipo 1502 libre en test. Rango DI manual vigente: 1500 'DI' = -500,
-- 1501 'DI' = 20000 (no se tocan aqui).
-- =====================================================================

-- 1) Verificar que el tipo 1502 este libre en el ambiente destino (0 filas).
select vta_ccodtipo, vta_ccodigo, vta_xglosa
from   VTA_FACOPARAM
where  vta_ccodtipo = 1502;

-- 2) Parametros
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_ACTIVO',   'S',  sysdate);  -- S/N proceso activo ("T2 activa")
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_VAL_CHEQ', 'S',  sysdate);  -- S/N valida cheque a fecha (RY-01)
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_VAL_ZZZ',  'N',  sysdate);  -- S/N formula ZZZ (RY-06, opcion 103 del exe)
-- CA_VAL_USD (dolares vs Prosegur, RZ-09) eliminado el 07-10-2026: FACO solo cierre Y.
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_DECIMAL',  '0',  sysdate);  -- decimales de redondeo: gFormat FACO = '#,#0' (vta_parametros.vta_numformat)
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_DIAS',     '30', sysdate);  -- dias maximos para reevaluar una caja pendiente
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_SIN_SOBRE','S',  sysdate);  -- S/N incluir cajas sin sobres del mismo local-dia de la carga (DF fila 12)
commit;
