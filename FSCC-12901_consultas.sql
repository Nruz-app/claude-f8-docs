-- FSCC-12901: consultas de solo lectura para cerrar los pendientes del análisis
-- Uso: sqlplus usuario@ALIAS_TNS @FSCC-12901_consultas.sql
--      (sqlplus pide la clave; el resultado queda en FSCC-12901_resultado.txt)
set linesize 250 pagesize 500 long 100000 trimspool on feedback on
spool FSCC-12901_resultado.txt

prompt === 1. Rango actual de la DI manual (vta_FACOparam 1500/1501)
select vta_ccodtipo, vta_ccodigo, vta_xglosa
from   vta_FACOparam
where  vta_ccodtipo in (1500, 1501)
order  by vta_ccodtipo, vta_ccodigo;

prompt === 2. Posible doble conteo en la compensacion (D12): mas de una fila por rama?
select mov_tipomov, vta_coddif
from   vta_FACOconcepdif
where  mov_tipomov in ('NP','FT') or vta_coddif = 1
order  by mov_tipomov;

prompt === 3. Fuente del paquete de Chile (procedimiento cierre_terminal_di)
select type, line, text
from   all_source
where  name = 'PKG_F8_COMPENSACION_DI'
order  by type, line;

prompt === 4. Cuantas DI hay por Y (deberia ser una sola con mov_rol = 0)
select mov_fecha, mov_local, mov_terminal, mov_cierrey, mov_rol, count(*) cantidad
from   vta_FACOmovdet
where  mov_tipomov = 'DI'
and    mov_fecha >= trunc(sysdate) - 60
group  by mov_fecha, mov_local, mov_terminal, mov_cierrey, mov_rol
having count(*) > 1;

prompt === 5. Distribucion de la DI manual de los ultimos 60 dias (para dimensionar el rango)
select count(*) cantidad,
       min(mov_monto) minimo, max(mov_monto) maximo,
       sum(case when mov_monto between -1000 and 20000 then 1 else 0 end) en_rango
from   vta_FACOmovdet
where  mov_tipomov = 'DI'
and    mov_fecha >= trunc(sysdate) - 60;

prompt === 6. Sobres cargados sin cierre Y (afectan la DR de la Y)
select prv_fechavta, count(*) sobres_sin_y
from   vta_FACOprd
where  prv_fechavta >= trunc(sysdate) - 60
and    prv_tiporec = 'F8'
and   (prv_cierrey is null or prv_cierrey = 0)
group  by prv_fechavta
order  by prv_fechavta;

prompt === 7. Y cerradas cuya Z fue reabierta por la carga (riesgo P12)
select t.ter_fecha, t.ter_local, t.ter_terminal, y.ter_cierrey, y.ter_estado estado_y, t.ter_estado estado_z, t.ter_notas
from   vta_FACOtermstat t, vta_FACOtermstaty y
where  t.ter_fecha >= trunc(sysdate) - 60
and    t.ter_notas = 'CARGA MANUAL DE SOBRES'
and    t.ter_estado = 0
and    y.ter_fecha = t.ter_fecha and y.ter_local = t.ter_local and y.ter_terminal = t.ter_terminal
and    y.ter_estado = 1
order  by 1, 2, 3, 4;

-- =====================================================================
-- Ajuste DF-SCC (06-10-2026): consultas de validacion ejecutadas en test
-- (solo lectura; con el usuario de aplicacion, antes:
--  alter session set current_schema = <duenio>;). Resultados en
--  docs/README_FSCC-12901.md par. 6.
-- =====================================================================

prompt === 8. Cargas recientes en VTA_FACOPRD (test 06-10: la ultima es de 2022)
select * from (
select p.prv_fechavta, count(distinct p.prv_local) locales, count(*) sobres,
       count(distinct p.prv_local || '-' || p.prv_terminal || '-' || p.prv_cierrey) cajas
  from vta_FACOprd p where p.prv_tiporec = 'F8'
 group by p.prv_fechavta order by 1 desc) where rownum <= 5;

prompt === 9. Ultima fecha con cierres Y y libro de ventas Y (test 06-10: 23-09-2026)
select max(t.ter_fecha) ultima_y, count(*) from vta_FACOtermstaty t;
select max(l.vta_fecha_venta) ultima_libvta_y from vta_FACOlibvta l where l.vta_tiporeg = 'Y';

prompt === 10. Rama SIN_SOBRE de la vista simulada (cola = VTA_FACOPRD F8), ultima fecha cargada
select count(*) cajas_sin_sobre, sum(case when y.ter_estado <= 0 then 1 else 0 end) abiertas
  from vta_FACOtermstaty y
 where y.ter_fecha = (select max(prv_fechavta) from vta_FACOprd where prv_tiporec = 'F8')
   and exists (select 1 from vta_FACOprd q where q.prv_tiporec = 'F8'
                and q.prv_fechavta = y.ter_fecha and q.prv_local = y.ter_local)
   and not exists (select 1 from vta_FACOprd q where q.prv_tiporec = 'F8'
                and q.prv_fechavta = y.ter_fecha and q.prv_local = y.ter_local
                and q.prv_terminal = y.ter_terminal and q.prv_cierrey = y.ter_cierrey)
   and exists (select 1 from vta_FACOlibvta l, vta_FACOzzz r
                where l.vta_tiporeg = 'Y' and l.vta_techkey = r.rec_techkey and l.vta_estado = 'A'
                  and l.vta_fecha_venta = y.ter_fecha and l.vta_local = y.ter_local
                  and l.vta_terminal = y.ter_terminal and l.vta_secuencia = y.ter_cierrey);

prompt === 11. Universo de SubBuscarOpcionFACO (Form43) para un dia (test 23-09-2026: 1 Y y 7 Z)
select case when x.ter_cierrey = 0 then 'Z' else 'Y' end tipo, x.ter_estado, count(*) from (
 select distinct t.ter_fecha, t.ter_local, t.ter_terminal, t.ter_cierrey, t.ter_estado
   from vta_FACOtermstaty t, vta_FACOlibvta l, vta_FACOzzz r
  where t.ter_fecha = to_date('2026/09/23','yyyy/mm/dd')
    and l.vta_tiporeg = 'Y' and l.vta_estado = 'A' and l.vta_techkey = r.rec_techkey
    and l.vta_fecha_venta = t.ter_fecha and l.vta_local = t.ter_local
    and l.vta_terminal = t.ter_terminal and l.vta_secuencia = t.ter_cierrey
 union all
 select distinct t.ter_fecha, t.ter_local, t.ter_terminal, 0, t.ter_estado
   from vta_FACOtermstat t, vta_FACOlibvta l, vta_FACOzzz r
  where t.ter_fecha = to_date('2026/09/23','yyyy/mm/dd')
    and l.vta_tiporeg = 'F8' and l.vta_estado = 'A' and l.vta_techkey = r.rec_techkey
    and l.vta_fecha_venta = t.ter_fecha and l.vta_local = t.ter_local
    and l.vta_terminal = t.ter_terminal
 ) x group by case when x.ter_cierrey = 0 then 'Z' else 'Y' end, x.ter_estado order by 1, 2;

prompt === 12. Largo de TER_CERRADOPOR (test: VARCHAR2(50), admite LOGINUSER)
select table_name, column_name, data_type, data_length from all_tab_columns
 where table_name in ('VTA_FACOTERMSTAT','VTA_FACOTERMSTATY')
   and column_name in ('TER_CERRADOPOR','TER_ESTADO','TER_NOTAS','TER_CIERREY');

prompt === 13. Opcion 1515 Cerrar Terminal CC por pais (test: existe en VTA_MENU, SOAR y SFCL; no en FACO)
select 'VTA_MENU' t, m.* from vta_menu m where m.mnu_codigo in (1514, 1515);
select 'VTA_SOARMENU' t, m.* from vta_SOARmenu m where m.mnu_codigo in (1514, 1515);
select 'VTA_SFCLMENU' t, m.* from vta_SFCLmenu m where m.mnu_codigo in (1514, 1515);
select 'VTA_FACOMENU' t, m.* from vta_FACOmenu m where m.mnu_codigo in (1514, 1515);
select r.per_codigo, r.rel_estado from vta_FACOrelpermen r where r.mnu_codigo = 1515;

prompt === 14. Perfiles FACO (test: 0, 1, 6, 7, 8, 9, 10, 11)
select * from vta_FACOperfiles order by 1;

prompt === 15. Estructura de menu y permisos FACO
select table_name, column_name, data_type, data_length, nullable
  from all_tab_columns
 where table_name in ('VTA_FACOMENU','VTA_FACORELPERMEN')
 order by table_name, column_id;

-- =====================================================================
-- Modelo "solo cierre Y" (07-10-2026): consultas de validacion en test
-- =====================================================================

prompt === 16. Universo de SubBuscarOpcionFACO solo Y (test 23-09-2026: 1 Y cerrada)
select x.ter_estado, count(*) from (
 select distinct t.ter_fecha, t.ter_local, t.ter_terminal, t.ter_cierrey, t.ter_estado
   from vta_FACOtermstaty t, vta_FACOlibvta l, vta_FACOzzz r
  where t.ter_fecha = to_date('2026/09/23','yyyy/mm/dd')
    and l.vta_tiporeg = 'Y' and l.vta_estado = 'A' and l.vta_techkey = r.rec_techkey
    and l.vta_fecha_venta = t.ter_fecha and l.vta_local = t.ter_local
    and l.vta_terminal = t.ter_terminal and l.vta_secuencia = t.ter_cierrey
 ) x group by x.ter_estado order by 1;

prompt === 17. Cierres Y FACO por estado y quien los cerro (desde el 24-08-2026 = sysdate - 44; test 07-10: 7 en -1, 6 AUTOMATICO)
select ter_estado, nvl(ter_cerradopor,'(null)') cerrado_por, count(*) from vta_FACOtermstaty
 where ter_fecha >= trunc(sysdate) - 44 group by ter_estado, nvl(ter_cerradopor,'(null)') order by 3 desc;

prompt === 18. Z FACO por estado (desde el 24-08-2026; test 07-10: 10.894 en -1, 6 cerradas => la Z no se gestiona)
select ter_estado, count(*) from vta_FACOtermstat where ter_fecha >= trunc(sysdate) - 44 group by ter_estado order by 1;

spool off
exit
