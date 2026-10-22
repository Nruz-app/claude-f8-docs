-- =====================================================================
-- FSCC-12901 COMPENSA_DI - Paso 00: verificaciones previas
-- SOLO LECTURA (sin SET ni PROMPT: sirve en DBeaver). xintec-nruz 19-10-2026
--
-- Modelo 19-10-2026: la carga de sobres (Form133) ya no cierra la Y; solo
-- registra la DI automatica si la diferencia real esta en el rango. El
-- cierre pasa a un cron diario (pendiente). Antes de instalar se borra lo
-- de la v2 (01_DESINSTALAR_v2.sql).
-- Ejecutar conectado como el duenio de las tablas VTA_FACO* (test: INTRANETTS).
-- =====================================================================

-- 1. Objetos de FSCC-12901 (v1, v2, YZ, POC) que existen hoy.
--    Test al 14-10: se traspaso la v2 (7 objetos). Todo lo que aparezca
--    aqui lo borra 01_DESINSTALAR_v2.sql.
select object_name, object_type, status
  from user_objects
 where object_name in ('PKG_F8_FACO_CIERRE_AUTO', 'PKG_F8_FACO_COMPENSA_DI',
                       'PKG_F8_CIERRE_AUTO', 'PKG_F8_COMPENSA_DI_AUTO',
                       'VTA_FACOV_CAJAS_CIERRE', 'TRG_VTA_FACOPRD_CIERRE_AI',
                       'VTA_FACOPRD_CIERRE', 'SEQ_VTA_FACOPRD_CIERRE',
                       'VTA_FACOLOG_CIERRE_AUTO', 'SEQ_VTA_FACOLOG_CIERRE_AUTO')
    or object_name like 'VTA_FACOPOC%'
 order by object_type, object_name;

-- 2. Objetos nuevos y respaldos. ESPERADO: sin filas (si hay, ya se instalo
--    antes: revisar antes de seguir).
select object_name, object_type, status
  from user_objects
 where object_name in ('PKG_F8_COMPENSA_DI_CARGA', 'VTA_FACOLOG_COMPENSA_DI',
                       'SEQ_VTA_FACOLOG_COMPENSA_DI',
                       'VTA_FACOPRD_CIERRE_BK', 'VTA_FACOLOG_CIERRE_AUTO_BK');

-- 3. Jobs que llaman a los paquetes de la v2. ESPERADO: sin filas.
--    Si hay, anotar el numero y quitarlo en el paso (a) de 01.
select job, what, next_date, broken
  from user_jobs
 where upper(what) like '%PKG_F8_CIERRE_AUTO%'
    or upper(what) like '%PKG_F8_COMPENSA_DI_AUTO%'
    or upper(what) like '%PKG_F8_FACO_CIERRE_AUTO%';

-- 4. Sinonimos que apuntan a esos objetos (se borran como DBA, parte 2 de 01).
select owner, synonym_name, table_owner, table_name
  from all_synonyms
 where table_name in ('PKG_F8_FACO_CIERRE_AUTO', 'PKG_F8_FACO_COMPENSA_DI',
                      'PKG_F8_CIERRE_AUTO', 'PKG_F8_COMPENSA_DI_AUTO',
                      'VTA_FACOV_CAJAS_CIERRE', 'VTA_FACOPRD_CIERRE',
                      'VTA_FACOLOG_CIERRE_AUTO', 'PKG_F8_COMPENSA_DI_CARGA',
                      'VTA_FACOLOG_COMPENSA_DI');

-- 5. Parametros 1502 y opcion 1515 actuales.
select trim(vta_ccodigo) parametro_1502, vta_xglosa
  from VTA_FACOPARAM where vta_ccodtipo = 1502 order by 1;

select (select count(*) from VTA_FACOMENU      where mnu_codigo = 1515) menu_1515,
       (select count(*) from VTA_FACORELPERMEN where mnu_codigo = 1515) relpermen_1515
  from dual;

-- 6. Objetos que usa el paquete nuevo. ESPERADO: SEQ_VTA_FACOVEN (techkey de
--    VTA_FACOMOVDET) y TRG_VTA_FACOCOMPDES_I_SEQ (secuencia de VTA_FACOCOMPDES).
select object_name, object_type, status
  from user_objects
 where object_name in ('SEQ_VTA_FACOVEN', 'TRG_VTA_FACOCOMPDES_I_SEQ');

-- 7. Rango de la DI MANUAL (Form38, parametros 1500/1501 'DI'). Solo como
--    referencia: el rango automatico es el de 1502 CA_DI_MIN / CA_DI_MAX.
select vta_ccodtipo, trim(vta_ccodigo) codigo, vta_xglosa
  from VTA_FACOPARAM
 where vta_ccodtipo in (1500, 1501) and trim(vta_ccodigo) = 'DI';

-- 8. Datos que dejaron las pruebas de la v2 (NO se borran: son movimientos
--    y cierres reales de test). Solo para saber que existen.
select 'DI PROC_DI_AUTO' dato, count(*) filas, nvl(sum(mov_monto), 0) monto
  from VTA_FACOMOVDET
 where mov_tipomov = 'DI' and mov_hechopor = 'PROC_DI_AUTO'
union all
select 'Y cerradas PROC_CIERRE_AUTO', count(*), null
  from VTA_FACOTERMSTATY
 where ter_cerradopor = 'PROC_CIERRE_AUTO';
