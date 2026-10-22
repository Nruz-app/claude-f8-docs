-- =====================================================================
-- FSCC-12901 CIERRE_DIARIO - Paso 00: verificaciones previas
-- SOLO LECTURA (sin SET ni PROMPT: sirve en DBeaver). xintec-nruz 20-10-2026
-- Ejecutar conectado como el duenio de las tablas VTA_FACO* (test: INTRANETTS).
-- =====================================================================

-- 1. Dependencia: PKG_F8_COMPENSA_DI_CARGA instalado y VALID.
--    ESPERADO: PACKAGE y PACKAGE BODY, VALID.
select object_name, object_type, status
  from user_objects
 where object_name = 'PKG_F8_COMPENSA_DI_CARGA'
 order by object_type;

-- 2. Dependencia: version MULTIPAIS de PKG_F8_COMPENSA_DI_CARGA (20-10),
--    es decir fn_dif_real con P_FLG_PAIS. ESPERADO: 1 fila o mas.
--    Sin filas: primero pasar FSCC-12901_COMPENSA_DI/04 y 05 (pendiente 1p);
--    si no, 04_pkg_cierre_diario_body.sql no compila (PLS-00306).
select object_name, argument_name, position, data_type
  from user_arguments
 where package_name  = 'PKG_F8_COMPENSA_DI_CARGA'
   and object_name   = 'FN_DIF_REAL'
   and argument_name = 'P_FLG_PAIS';

-- 3. Objetos nuevos. ESPERADO: sin filas (si hay, ya se instalo antes).
select object_name, object_type, status
  from user_objects
 where object_name in ('PKG_F8_CIERRE_DIARIO', 'VTA_FACOLOG_CIERRE_DIARIO',
                       'SEQ_VTA_FACOLOG_CIERRE_DIARIO');

-- 4. Parametros 1502. ESPERADO hoy: CA_DECIMAL 0, CA_DI_ACTIVO S, CA_DI_MAX
--    20000, CA_DI_MIN -1000. Los CD_* los agrega 02_parametros.sql.
select trim(vta_ccodigo) codigo, vta_xglosa
  from VTA_FACOPARAM where vta_ccodtipo = 1502 order by 1;

-- 5. Tablas que usa el paquete. ESPERADO: 17 filas.
--    (22-10 FCDVT-56: + VTA_FACOTERMSTAT y VTA_FACOTERMINALES, etapa SIN VENTA)
select table_name
  from user_tables
 where table_name in ('VTA_FACOTERMSTATY', 'VTA_FACOLIBVTA', 'VTA_FACOZZZ', 'VTA_FACOPRD',
                      'VTA_FACORECMEX', 'VTA_FACOTESOR', 'VTA_FACOTARJ', 'VTA_FACOMOVDET',
                      'VTA_FACOCONCEPDIF', 'VTA_FACODIFVEND', 'VTA_FACOCARTAAVISO',
                      'VTA_FACOCHEQUES', 'VTA_FACOPARAM', 'VTA_PAINT_Z',
                      'VTA_FACOLOG_COMPENSA_DI', 'VTA_FACOTERMSTAT', 'VTA_FACOTERMINALES')
 order by 1;

-- 6. ter_cerradopor admite el usuario del proceso (PROC_CIERRE_DIARIO, 18
--    caracteres) en la Y y en la Z. ESPERADO: largo de TER_CERRADOPOR >= 18.
select table_name, column_name, data_type, data_length
  from user_tab_columns
 where table_name in ('VTA_FACOTERMSTATY', 'VTA_FACOTERMSTAT')
   and column_name in ('TER_ESTADO', 'TER_CERRADOPOR')
 order by 1, 2;

-- 7. Universo de una fecha (EDITAR la fecha): cierres Y Pendientes con libro
--    de ventas, por local. Es lo que tomaria el proceso.
select t.ter_local, count(*) cajas
  from (select distinct t.ter_fecha, t.ter_local, t.ter_terminal, t.ter_cierrey
          from VTA_FACOLIBVTA l, VTA_FACOZZZ r, VTA_FACOTERMSTATY t
         where l.vta_tiporeg     = 'Y'
           and t.ter_fecha       = to_date('20260831','yyyymmdd')   -- EDITAR
           and l.vta_estado      = 'A'
           and l.vta_techkey     = r.rec_techkey
           and l.vta_fecha_venta = t.ter_fecha
           and l.vta_local       = t.ter_local
           and l.vta_terminal    = t.ter_terminal
           and l.vta_secuencia   = t.ter_cierrey
           and t.ter_cierrey    <> 0
           and t.ter_estado     <= 0) t
 group by t.ter_local
 order by 1;

-- 8. Formula ZZZ (solo si se activara CD_VAL_ZZZ): filas de VTA_PAINT_Z FACO
--    por validador. Informativo.
select vta_validadorzzz, count(*) campos
  from VTA_PAINT_Z
 where vta_localiz = 'FACO' and vta_validadorzzz is not null
 group by vta_validadorzzz
 order by 1;
