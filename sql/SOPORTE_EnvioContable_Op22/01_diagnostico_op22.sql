-- ============================================================================
-- SOPORTE Envio Contable (Form159) - Chile (Flg_Pais$ = '')
-- Operacion 22 Recaudaciones, estado POR ENVIAR, sin registros en la grilla.
-- Paso   : 01 (diagnostico). SOLO LECTURA: solo SELECT / WITH, no modifica nada.
-- Objeto : PKG_FR_F8_INT_SAP.PRC_INS_SEL_DOC_CONTAB7, rama ID_OPERACION = 22 / 'POR ENVIAR'
--          (body de desa: docs/ddl/desa_2026-10-26/objetos/PACKAGE_BODY/PKG_FR_F8_INT_SAP.sql:186-289)
-- Exe    : Form159.listarAsociacion :1342 -> cargarTabla :1852 -> select vta_envioContab_fr :1700
--          mensaje "No Existe Registros para estas Fechas" (:1787) = el pkg corrio OK e inserto 0 filas.
-- Ejecutar conectado como el dueno de las tablas VTA_* (sin prefijo de esquema).
--
-- -- EDITAR ------------------------------------------------------------------
-- Cada consulta trae su propio bloque "par" con los mismos valores.
-- Reemplazar en TODO el archivo (buscar/reemplazar):
--   22-10-2026  -> fecha desde (dd-mm-yyyy)
--   23-10-2026  -> fecha hasta (dd-mm-yyyy) (mismo dia que desde si se busca un solo dia)
--   0 as loc    -> codigo de local (0 = TODOS, como en la pantalla)
--   294523      -> c_idbusqueda de la busqueda (solo Q9; es el primer parametro del pkg)
-- ----------------------------------------------------------------------------
-- Nota: el pkg compara "fecha between desde and hasta" SIN truncar; si las fechas
-- de vta_prd tienen hora, un registro del dia "hasta" con hora > 00:00 queda fuera.
-- Por eso en este script "hasta" se trata igual que en el pkg (between exacto) y
-- aparte se informa cuantas filas tienen hora.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- Q1. El package en esta base: estado, fecha de compilacion y la rama 22.
--     Confirmar que el texto coincide con el de desa (filtros de vta_prd y tes_ccheque).
-- ----------------------------------------------------------------------------
select object_name, object_type, status, created, last_ddl_time
  from user_objects
 where object_name = 'PKG_FR_F8_INT_SAP';

select s.line, s.text
  from user_source s
 where s.name = 'PKG_FR_F8_INT_SAP'
   and s.type = 'PACKAGE BODY'
   and s.line between (select min(x.line) from user_source x
                        where x.name = 'PKG_FR_F8_INT_SAP' and x.type = 'PACKAGE BODY'
                          and upper(x.text) like '%FUNCTION PRC_INS_SEL_DOC_CONTAB7%')
                  and (select min(x.line) + 130 from user_source x
                        where x.name = 'PKG_FR_F8_INT_SAP' and x.type = 'PACKAGE BODY'
                          and upper(x.text) like '%FUNCTION PRC_INS_SEL_DOC_CONTAB7%')
 order by s.line;


-- ----------------------------------------------------------------------------
-- Q2. NLS de la sesion. El exe manda la fecha como texto 'dd/MMMM/yyyy' en espanol
--     (p. ej. '22/octubre/2026') y el pkg la vuelve a concatenar como texto.
--     Comparar con lo que tiene la sesion del exe (idioma SPANISH esperado).
-- ----------------------------------------------------------------------------
select parameter, value
  from nls_session_parameters
 where parameter in ('NLS_DATE_FORMAT', 'NLS_DATE_LANGUAGE', 'NLS_LANGUAGE', 'NLS_TERRITORY');


-- ----------------------------------------------------------------------------
-- Q3. Universo de vta_prd por FECHA CONTABLE en el rango, sin los filtros del pkg.
--     Si sale vacio: no hay carga PRD con esa fecha contable (causa a).
--     Mirar prv_tiporec / prv_tiposobre: el pkg solo toma 'F8' y 'CHE','EFE'.
-- ----------------------------------------------------------------------------
with par as (select to_date('22-10-2026','dd-mm-yyyy') as desde,
                    to_date('23-10-2026','dd-mm-yyyy') as hasta,
                    0 as loc from dual)
select trunc(p.prv_fechacontable) as fecha_contable,
       p.prv_tiporec,
       p.prv_tiposobre,
       count(*)                                         as filas,
       count(distinct p.prv_local)                      as locales,
       sum(p.prv_montosobre + p.prv_montodif)           as monto,
       sum(case when p.prv_fechacontable <> trunc(p.prv_fechacontable)
                then 1 else 0 end)                      as filas_con_hora,
       sum(case when p.prv_fechacontable between par.desde and par.hasta
                then 1 else 0 end)                      as filas_en_between_pkg
  from vta_prd p, par
 where p.prv_fechacontable >= par.desde
   and p.prv_fechacontable <  par.hasta + 1
   and (par.loc = 0 or p.prv_local = par.loc)
 group by trunc(p.prv_fechacontable), p.prv_tiporec, p.prv_tiposobre
 order by 1, 2, 3;


-- ----------------------------------------------------------------------------
-- Q4. vta_prd F8 CHE/EFE por FECHA DE VENTA en el rango: que fecha contable tienen.
--     Si la venta existe pero prv_fechacontable es nula u otra fecha, la busqueda
--     por "Fecha Contable" no la encuentra (probar en pantalla con "Fecha Venta").
-- ----------------------------------------------------------------------------
with par as (select to_date('22-10-2026','dd-mm-yyyy') as desde,
                    to_date('23-10-2026','dd-mm-yyyy') as hasta,
                    0 as loc from dual)
select trunc(p.prv_fechavta)                  as fecha_venta,
       nvl(to_char(trunc(p.prv_fechacontable),'dd-mm-yyyy'),'(NULA)') as fecha_contable,
       p.prv_tiposobre,
       count(*)                               as filas,
       count(distinct p.prv_local)            as locales,
       sum(p.prv_montosobre + p.prv_montodif) as monto,
       max(p.prv_fechareg)                   as ult_registro
  from vta_prd p, par
 where p.prv_fechavta >= par.desde
   and p.prv_fechavta <  par.hasta + 1
   and p.prv_tiporec = 'F8'
   and p.prv_tiposobre in ('CHE', 'EFE')
   and (par.loc = 0 or p.prv_local = par.loc)
 group by trunc(p.prv_fechavta), trunc(p.prv_fechacontable), p.prv_tiposobre
 order by 1, 2, 3;


-- ----------------------------------------------------------------------------
-- Q5. Rama 1 del pkg (vta_prd) rearmada tal cual, con la clave de paquete, contra
--     sap_enviados_fr. YA_ENVIADO = 'S' -> el pkg la excluye de POR ENVIAR (causa b):
--     buscar en pantalla con el estado que muestra A_ESTADO_ENVIADO.
-- ----------------------------------------------------------------------------
with par as (select to_date('22-10-2026','dd-mm-yyyy') as desde,
                    to_date('23-10-2026','dd-mm-yyyy') as hasta,
                    0 as loc from dual),
cand as (
  select 'REC-' || to_char(p.prv_fechavta,'YYYYMMDD') || '-' ||
         to_char(p.prv_fechacontable,'YYYYMMDD') || '-' || p.prv_tiposobre ||
         '-16900-' || nvl(pkg_fr_f8_int_sap.obtiene_rutbp(p.prv_local, 22), '0') as numero_paquete,
         nvl(pkg_fr_f8_int_sap.obtiene_rutbp(p.prv_local, 22), '0') as bp,
         p.prv_fechavta, p.prv_fechacontable, p.prv_tiposobre,
         sum(p.prv_montosobre + p.prv_montodif) as monto,
         max(p.prv_local) as max_local,
         count(*) as filas_prd
    from vta_prd p, par
   where p.prv_fechacontable between par.desde and par.hasta
     and p.prv_tiporec = 'F8'
     and p.prv_tiposobre in ('CHE', 'EFE')
     and (par.loc = 0 or p.prv_local = par.loc)
   group by nvl(pkg_fr_f8_int_sap.obtiene_rutbp(p.prv_local, 22), '0'),
            p.prv_fechacontable, p.prv_fechavta, p.prv_tiposobre,
            'REC-' || to_char(p.prv_fechavta,'YYYYMMDD') || '-' ||
            to_char(p.prv_fechacontable,'YYYYMMDD') || '-' || p.prv_tiposobre ||
            '-16900-' || nvl(pkg_fr_f8_int_sap.obtiene_rutbp(p.prv_local, 22), '0'))
select c.numero_paquete, c.bp, c.prv_fechavta, c.prv_fechacontable, c.prv_tiposobre,
       c.monto, c.max_local, c.filas_prd,
       case when e.a_numero_paquete is null then 'N' else 'S' end as ya_enviado,
       e.a_estado          as a_estado_enviado,
       e.d_fecha_insercion,
       e.d_fecha_update,
       e.c_reintentos
  from cand c
  left join sap_enviados_fr e on e.a_numero_paquete = c.numero_paquete
 order by c.prv_fechacontable, c.bp, c.prv_tiposobre;


-- ----------------------------------------------------------------------------
-- Q6. Rama 2 del pkg (tes_ccheque): cuantas filas pasan cada filtro, paso a paso.
--     La rama solo aporta cheques con d_fecvencto en el rango (ignora el tipo de fecha).
-- ----------------------------------------------------------------------------
with par as (select to_date('22-10-2026','dd-mm-yyyy') as desde,
                    to_date('23-10-2026','dd-mm-yyyy') as hasta,
                    0 as loc from dual)
select count(*)                                                    as f1_vencto_en_rango,
       sum(case when s.c_estado = 3 then 1 else 0 end)             as f2_estado_3,
       sum(case when s.c_estado = 3 and s.a_pais = 'CL' then 1 else 0 end) as f3_pais_cl,
       sum(case when s.c_estado = 3 and s.a_pais = 'CL'
                 and s.c_idempresa = 971878 then 1 else 0 end)     as f4_empresa_971878,
       sum(case when s.c_estado = 3 and s.a_pais = 'CL'
                 and s.c_idempresa = 971878
                 and s.a_codmoneda = 'CLP' then 1 else 0 end)      as f5_clp_pasa_pkg
  from tes_ccheque s, par
 where s.d_fecvencto between par.desde and par.hasta
   and (par.loc = 0 or s.c_local_srx = par.loc);

-- Q6b. Cheques que pasan los filtros, con su clave y si ya estan en sap_enviados_fr.
with par as (select to_date('22-10-2026','dd-mm-yyyy') as desde,
                    to_date('23-10-2026','dd-mm-yyyy') as hasta,
                    0 as loc from dual),
cand as (
  select 'REC-' || to_char(s.d_fecvencto,'YYYYMMDD') || '-' ||
         to_char(s.d_fecvencto,'YYYYMMDD') || '-CHEF-16900-' ||
         nvl(pkg_fr_f8_int_sap.obtiene_rutbp(s.c_local_srx, 22), '0') as numero_paquete,
         s.d_fecvencto, sum(s.m_monto) as monto, count(*) as cheques
    from tes_ccheque s, par
   where s.d_fecvencto between par.desde and par.hasta
     and s.c_estado = 3
     and s.a_pais = 'CL'
     and s.c_idempresa = 971878
     and s.a_codmoneda = 'CLP'
     and (par.loc = 0 or s.c_local_srx = par.loc)
   group by nvl(pkg_fr_f8_int_sap.obtiene_rutbp(s.c_local_srx, 22), '0'), s.d_fecvencto)
select c.*, case when e.a_numero_paquete is null then 'N' else 'S' end as ya_enviado,
       e.a_estado as a_estado_enviado, e.d_fecha_insercion
  from cand c
  left join sap_enviados_fr e on e.a_numero_paquete = c.numero_paquete
 order by c.d_fecvencto;


-- ----------------------------------------------------------------------------
-- Q7. Lo que ya esta en sap_enviados_fr para recaudacion (REC-) en el rango,
--     por estado. Indica con que estado buscar en la pantalla.
-- ----------------------------------------------------------------------------
with par as (select to_date('22-10-2026','dd-mm-yyyy') as desde,
                    to_date('23-10-2026','dd-mm-yyyy') as hasta,
                    0 as loc from dual)
select trunc(e.d_fecha_contable) as fecha_contable,
       e.a_estado,
       count(*)              as paquetes,
       sum(e.n_monto)        as monto,
       min(e.d_fecha_insercion) as primera_insercion,
       max(e.d_fecha_update)    as ultima_actualizacion
  from sap_enviados_fr e, par
 where e.a_numero_paquete like 'REC-%'
   and e.d_fecha_contable >= par.desde
   and e.d_fecha_contable <  par.hasta + 1
   and (par.loc = 0 or e.n_mlocal = par.loc)
 group by trunc(e.d_fecha_contable), e.a_estado
 order by 1, 2;


-- ----------------------------------------------------------------------------
-- Q8. Locales con PRD F8 en el rango sin BP para la operacion 22
--     (sap_asociacion_tienda_fr / sap_transportadora_fr). No filtra en el pkg
--     (queda BP '0'), pero el envio a SAP con BP '0' no sirve.
-- ----------------------------------------------------------------------------
with par as (select to_date('22-10-2026','dd-mm-yyyy') as desde,
                    to_date('23-10-2026','dd-mm-yyyy') as hasta,
                    0 as loc from dual)
select p.prv_local, count(*) as filas_prd,
       nvl(pkg_fr_f8_int_sap.obtiene_rutbp(p.prv_local, 22), '0') as bp
  from vta_prd p, par
 where p.prv_fechacontable between par.desde and par.hasta
   and p.prv_tiporec = 'F8'
   and p.prv_tiposobre in ('CHE', 'EFE')
   and (par.loc = 0 or p.prv_local = par.loc)
   and not exists (select 1
                     from sap_asociacion_tienda_fr ti, sap_transportadora_fr t
                    where t.sap_rut_empresa = ti.sap_rut_empresa
                      and ti.sap_codigo_local = p.prv_local
                      and ti.sap_coddif = 22)
 group by p.prv_local
 order by p.prv_local;


-- ----------------------------------------------------------------------------
-- Q9. Lo que dejo el pkg en la tabla de trabajo. Si la busqueda de la pantalla ya
--     se cerro puede haberse borrado (FNC_BORRA_BUSQUEDA, Form159 :2429).
-- ----------------------------------------------------------------------------
select e.c_idbusqueda, e.a_numero_paquete, e.a_estado, e.d_fecha_contable, e.n_monto, e.a_bp
  from vta_envioContab_fr e
 where e.c_idbusqueda = '294523';

with par as (select to_date('22-10-2026','dd-mm-yyyy') as desde,
                    to_date('23-10-2026','dd-mm-yyyy') as hasta,
                    0 as loc from dual)
select e.c_idbusqueda, e.a_operacion, e.a_estado, count(*) as filas, sum(e.n_monto) as monto
  from vta_envioContab_fr e, par
 where e.d_fecha_contable >= par.desde
   and e.d_fecha_contable <  par.hasta + 1
 group by e.c_idbusqueda, e.a_operacion, e.a_estado
 order by 1;
