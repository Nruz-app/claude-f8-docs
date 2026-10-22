-- =====================================================================
-- FSCC-12901 v2 MULTIPAIS - Paso 03 (objeto POR PAIS: FACO)
-- Parametros de T1 y T2 en VTA_FACOPARAM (tipo 1502). Se leen en cada
-- ejecucion con PKG_F8_CIERRE_AUTO.fn_param('FACO', codigo, default).
-- Cambio frente a v1: SIN CA_DIAS. Colombia procesa solo la carga del dia
-- (una ejecucion por carga); la ventana de dias es del modelo de Chile.
-- El rango de la DI manual (1500/1501 'DI', -500 / 20000) NO se toca.
-- OTRO PAIS: los mismos codigos en VTA_<pfx>PARAM (Chile: VTA_PARAM).
-- Si v1 ya esta instalado NO ejecutar: usar MIGRAR_DESDE_V1.sql.
-- =====================================================================

-- Verificar tipo 1502 libre (esperado: 0)
select count(*) from VTA_FACOPARAM where vta_ccodtipo = 1502;

-- ---- T1: compensacion automatica de DI (FSCC-12957) ----
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_DI_ACTIVO', 'S',     sysdate);  -- S/N T1 activa (switch del negocio)
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_DI_MIN',    '-1000', sysdate);  -- limite inferior DR (inclusive)
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_DI_MAX',    '20000', sysdate);  -- limite superior DR (inclusive)

-- ---- T2: cierre de caja automatico (FSCC-12958) ----
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_ACTIVO',    'S',     sysdate);  -- S/N T2 activa (switch del negocio)
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_VAL_CHEQ',  'S',     sysdate);  -- S/N cheque a fecha (RY-01)
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_VAL_ZZZ',   'N',     sysdate);  -- S/N formula ZZZ (RY-06, opcion 103)

-- ---- Comunes ----
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_DECIMAL',   '0',     sysdate);  -- decimales: gFormat FACO '#,#0'
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_SIN_SOBRE', 'S',     sysdate);  -- S/N incluir cajas sin sobres del mismo local-dia (DF fila 12)
commit;

select vta_ccodigo, vta_xglosa from VTA_FACOPARAM where vta_ccodtipo = 1502 order by 1;
