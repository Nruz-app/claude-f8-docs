-- =====================================================================
-- POC FSCC-12901 - Manual M1: preparar la prueba por pantalla (DESARROLLO)
-- Requisitos: haber ejecutado 01_preparar, 02_datos_test y 03_dia_prd3
-- (NO ejecutar 04_cargar_sobres: los sobres se cargan por Form133).
-- Este script:
--   1) verifica que esten las cajas del 28-08-2026 de los locales 6 y 13
--      y que todavia no tengan sobres;
--   2) da de alta el recaudador 00562 PRUEBA (desarrollo no tiene ninguno);
--   3) habilita al usuario del aplicativo en Colombia (FACO) copiando su
--      fila de otra localizacion (NO se escribe ninguna clave);
--   4) habilita la opcion 1515 (Cerrar Terminal de Consultas de Cuadratura)
--      para el perfil del usuario;
--   5) respalda los cierres Y (para repetir con 98_reiniciar.sql);
--   6) muestra lo esperado por caja.
-- Todo lo que agrega queda anotado en VTA_FACOPOC_CTRL y lo quita M9.
-- =====================================================================

-- ---------------------------------------------------------------
-- 0. EDITAR: usuario del aplicativo (RUT con el que entra a F8) y perfil FACO
-- ---------------------------------------------------------------
delete from VTA_FACOPOC_CTRL where clave in ('M_LOGIN', 'M_PERFIL');
insert into VTA_FACOPOC_CTRL values ('M_LOGIN',  '16472091');   -- EDITAR
insert into VTA_FACOPOC_CTRL values ('M_PERFIL', '10');         -- EDITAR (10 = Super Administrador en FACO)
commit;

-- ---------------------------------------------------------------
-- 1. Verificaciones (esperado: cajas 23, sobres 0)
-- ---------------------------------------------------------------
select (select count(*) from VTA_FACOPOC_CASOS
         where c_origen = 'PRD3' and c_local in (6, 13)) cajas_locales_6_13,
       (select count(*) from VTA_FACOPRD
         where prv_fechavta = to_date('20260828','yyyymmdd') and prv_local in (6, 13)) sobres_ya_cargados
  from dual;

-- ---------------------------------------------------------------
-- 2..5. Altas
-- ---------------------------------------------------------------
declare
  v_login  varchar2(25);
  v_perfil varchar2(25);
  v_n      number;
  v_est    number;
begin
  select valor into v_login  from VTA_FACOPOC_CTRL where clave = 'M_LOGIN';
  select valor into v_perfil from VTA_FACOPOC_CTRL where clave = 'M_PERFIL';

  -- 2. Recaudador 00562 PRUEBA
  select count(*) into v_n from VTA_FACORECAUDADORA where trim(vta_cod_recaud) = '00562';
  if v_n = 0 then
    insert into VTA_FACORECAUDADORA (vta_cod_recaud, vta_rut_recaud, vta_nombre, vta_fechareg)
    values ('00562', '2136123', 'PRUEBA', sysdate);
    insert into VTA_FACOPOC_CTRL values ('M_RECAUD', 'INSERTADO');
    dbms_output.put_line('Recaudador 00562 PRUEBA: dado de alta');
  else
    dbms_output.put_line('Recaudador 00562: ya existia');
  end if;

  -- 3. Usuario en FACO (copia de su fila de otra localizacion, con su misma clave)
  select count(*) into v_n from vta_users where vta_loginname = v_login and vta_localiz = 'FACO';
  if v_n = 0 then
    insert into vta_users (vta_loginname, vta_alias, vta_perfil, vta_uslocal, vta_password,
                           vta_tienda, vta_cperfil_lv, vta_localiz)
    select vta_loginname, vta_alias, v_perfil, 0, vta_password, 0, vta_cperfil_lv, 'FACO'
      from vta_users
     where vta_loginname = v_login and vta_localiz <> 'FACO' and rownum = 1;
    if sql%rowcount = 1 then
      insert into VTA_FACOPOC_CTRL values ('M_USUARIO', 'INSERTADO');
      dbms_output.put_line('Usuario ' || v_login || ': habilitado en FACO con perfil ' || v_perfil);
    else
      dbms_output.put_line('ATENCION: el usuario ' || v_login || ' no existe en desarrollo; darlo de alta con Form151');
    end if;
  else
    dbms_output.put_line('Usuario ' || v_login || ': ya tenia FACO');
  end if;

  -- 4. Opcion 1515 (boton Cerrar Terminal de Form43) para el perfil
  select count(*) into v_n from VTA_FACOMENU where mnu_codigo = 1515;
  if v_n = 0 then
    insert into VTA_FACOMENU (mnu_codigo, mnu_descripcion, mnu_tipomenu, mnu_habilitar)
    values (1515, 'Cerrar Terminal desde Consulta Cuadratura', 'opcion', 1);
    insert into VTA_FACOPOC_CTRL values ('M_MENU1515', 'INSERTADO');
  end if;
  begin
    select rel_estado into v_est from VTA_FACORELPERMEN
     where per_codigo = to_number(v_perfil) and mnu_codigo = 1515;
    insert into VTA_FACOPOC_CTRL values ('M_REL1515', 'ESTADO:' || v_est);
    update VTA_FACORELPERMEN set rel_estado = -1
     where per_codigo = to_number(v_perfil) and mnu_codigo = 1515;
  exception
    when no_data_found then
      insert into VTA_FACORELPERMEN (per_codigo, mnu_codigo, rel_estado) values (to_number(v_perfil), 1515, -1);
      insert into VTA_FACOPOC_CTRL values ('M_REL1515', 'INSERTADO');
  end;
  dbms_output.put_line('Opcion 1515 habilitada para el perfil ' || v_perfil);

  commit;
end;
/

-- 5. Respaldo de los cierres Y (si no existe; lo usa 98_reiniciar.sql)
declare
  v_n number;
begin
  select count(*) into v_n from user_tables where table_name = 'VTA_FACOPOC_RESP_Y';
  if v_n = 0 then
    execute immediate 'create table VTA_FACOPOC_RESP_Y as'
      || ' select y.ter_fecha, y.ter_local, y.ter_terminal, y.ter_cierrey, y.ter_estado, y.ter_cerradopor, y.ter_notas'
      || ' from VTA_FACOTERMSTATY y, VTA_FACOPOC_DIAS d'
      || ' where y.ter_fecha = d.d_fecha and y.ter_local = d.d_local';
  end if;
end;
/

-- ---------------------------------------------------------------
-- 6. Lo esperado por caja (locales 6 y 13, 28-08-2026)
--    dr_hoy = DR antes de cargar los sobres (= -efectivo declarado)
--    dr_objetivo = DR despues de cargar el Excel por Form133
-- ---------------------------------------------------------------
select c.c_local local, c.c_terminal terminal, c.c_cierrey y, c.escenario,
       PKG_F8_FACO_CIERRE_AUTO.fn_dif_real(c.c_fecha, c.c_local, c.c_terminal, c.c_cierrey) dr_hoy,
       c.dr_objetivo, c.esperado_t1, c.esperado_t2
  from VTA_FACOPOC_CASOS c
 where c.c_origen = 'PRD3' and c.c_local in (6, 13)
 order by 1, 2, 3;

-- Resumen esperado: 19 CERRADA_Y (8 con DI), 2 CON_DIFERENCIA, 2 BLOQUEADA
select esperado_t2, count(*) cajas, sum(case when esperado_t1 = 'DI_REGISTRADA' then 1 else 0 end) con_di
  from VTA_FACOPOC_CASOS where c_origen = 'PRD3' and c_local in (6, 13)
 group by esperado_t2 order by 1;
