-- =====================================================================
-- POC FSCC-12901 v2 (multipais, FACO) - Manual M9: deshacer la prueba por pantalla (DESARROLLO)
-- Quita lo propio de la prueba manual, que 99 no conoce:
--   - los sobres cargados por Form133 (locales 6 y 13, 28-08-2026) y su cola;
--   - las Z que creo Form133 ('CARGA MANUAL DE SOBRES');
--   - el recaudador, la fila FACO del usuario y la opcion 1515 (solo si los
--     agrego M1, segun VTA_FACOPOC_CTRL).
-- Despues:
--   - para REPETIR la prueba: 98_reiniciar.sql y luego M1 otra vez;
--   - para TERMINAR: 99_limpiar.sql (borra el resto del POC).
-- =====================================================================

declare
  v_login  varchar2(25);
  v_perfil varchar2(25);
  v_rel    varchar2(200);
  v_n      number;
  function ctrl (p varchar2) return varchar2 is
    v varchar2(200);
  begin
    select max(valor) into v from VTA_FACOPOC_CTRL where clave = p;
    return v;
  end ctrl;
begin
  v_login  := ctrl('M_LOGIN');
  v_perfil := ctrl('M_PERFIL');

  -- Sobres de Form133 (no traen la marca POC) y su cola
  delete from VTA_FACOPRD_CIERRE q
   where q.prv_fechavta = to_date('20260828','yyyymmdd') and q.prv_local in (6, 13);
  dbms_output.put_line('Cola: ' || sql%rowcount);
  delete from VTA_FACOPRD p
   where p.prv_fechavta = to_date('20260828','yyyymmdd') and p.prv_local in (6, 13)
     and nvl(p.prv_modifpor, '-') <> 'POC_FSCC12901';
  dbms_output.put_line('Sobres Form133: ' || sql%rowcount);

  -- Z creadas o reabiertas por Form133.AbrirTerminal
  delete from VTA_FACOTERMSTAT t
   where t.ter_fecha = to_date('20260828','yyyymmdd') and t.ter_local in (6, 13)
     and t.ter_notas = 'CARGA MANUAL DE SOBRES';
  dbms_output.put_line('Z de Form133: ' || sql%rowcount);

  -- Altas de M1
  if ctrl('M_RECAUD') = 'INSERTADO' then
    delete from VTA_FACORECAUDADORA where trim(vta_cod_recaud) = '00562';
    dbms_output.put_line('Recaudador 00562 quitado');
  end if;
  if ctrl('M_USUARIO') = 'INSERTADO' then
    delete from vta_users where vta_loginname = v_login and vta_localiz = 'FACO';
    dbms_output.put_line('Usuario ' || v_login || ': FACO quitado');
  end if;
  v_rel := ctrl('M_REL1515');
  if v_rel = 'INSERTADO' then
    delete from VTA_FACORELPERMEN where per_codigo = to_number(v_perfil) and mnu_codigo = 1515;
  elsif v_rel like 'ESTADO:%' then
    update VTA_FACORELPERMEN set rel_estado = to_number(substr(v_rel, 8))
     where per_codigo = to_number(v_perfil) and mnu_codigo = 1515;
  end if;
  if ctrl('M_MENU1515') = 'INSERTADO' then
    select count(*) into v_n from VTA_FACORELPERMEN where mnu_codigo = 1515;
    if v_n = 0 then
      delete from VTA_FACOMENU where mnu_codigo = 1515;
    end if;
  end if;

  delete from VTA_FACOPOC_CTRL
   where clave in ('M_RECAUD', 'M_USUARIO', 'M_REL1515', 'M_MENU1515');
  commit;
end;
/

select (select count(*) from VTA_FACOPRD where prv_fechavta = to_date('20260828','yyyymmdd') and prv_local in (6, 13)) sobres,
       (select count(*) from VTA_FACOTERMSTAT where ter_fecha = to_date('20260828','yyyymmdd') and ter_local in (6, 13)
                                              and ter_notas = 'CARGA MANUAL DE SOBRES') z_form133
  from dual;
