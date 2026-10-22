-- =====================================================================
-- FSCC-12901 COMPENSA_DI - Paso 03: parametros (VTA_FACOPARAM tipo 1502)
-- xintec-nruz 19-10-2026
-- 21-10-2026: INSERT ... VALUES simples (antes INSERT ... SELECT ... WHERE
-- NOT EXISTS), porque la app que ejecuta los scripts no reconoce el
-- INSERT SELECT. Ya NO es idempotente: ejecutar la consulta de abajo
-- ANTES y omitir el insert de los codigos que ya existan (si no, quedan
-- duplicados o da ORA-00001).
-- Para cambiar un valor, update directo (se lee en cada llamada, sin
-- recompilar).
-- El rango de la DI MANUAL (1500/1501 'DI') no se toca.
-- =====================================================================

-- ANTES: codigos que ya existen (insertar solo los que no aparecen)
select trim(vta_ccodigo) codigo, vta_xglosa
  from VTA_FACOPARAM
 where vta_ccodtipo = 1502
   and trim(vta_ccodigo) in ('CA_DI_ACTIVO', 'CA_DI_MIN', 'CA_DI_MAX', 'CA_DECIMAL')
 order by 1;

-- S/N compensacion automatica activa
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_DI_ACTIVO', 'S', sysdate);

-- limite inferior de la DR (inclusive)
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_DI_MIN', '-1000', sysdate);

-- limite superior de la DR (inclusive)
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_DI_MAX', '20000', sysdate);

-- decimales (gFormat FACO '#,#0')
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CA_DECIMAL', '0', sysdate);

commit;

-- ESPERADO: 4 filas (cada codigo una sola vez)
select trim(vta_ccodigo) codigo, vta_xglosa
  from VTA_FACOPARAM where vta_ccodtipo = 1502 order by 1;
