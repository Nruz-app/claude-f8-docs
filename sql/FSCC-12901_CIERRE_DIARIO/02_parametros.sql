-- =====================================================================
-- FSCC-12901 CIERRE_DIARIO - Paso 02: parametros (VTA_FACOPARAM tipo 1502)
-- xintec-nruz 20-10-2026
-- 21-10-2026: INSERT ... VALUES simples (antes INSERT ... SELECT ... WHERE
-- NOT EXISTS), porque la app que ejecuta los scripts no reconoce el
-- INSERT SELECT. Ya NO es idempotente: ejecutar la consulta de abajo
-- ANTES y omitir el insert de los codigos que ya existan (si no, quedan
-- duplicados o da ORA-00001).
-- Para cambiar un valor, update directo (se lee en cada ejecucion, sin
-- recompilar).
-- Prefijo CD_ (cierre diario) para no mezclarse con los CA_DI_* de la
-- compensacion de DI. CA_DECIMAL (decimales) ya existe: lo creo
-- FSCC-12901_COMPENSA_DI/03_parametros.sql y se reutiliza.
-- =====================================================================

-- ANTES: codigos CD_* que ya existen (insertar solo los que no aparecen)
select trim(vta_ccodigo) codigo, vta_xglosa
  from VTA_FACOPARAM where vta_ccodtipo = 1502 and trim(vta_ccodigo) like 'CD\_%' escape '\' order by 1;

-- S/N cierre diario activo
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CD_ACTIVO', 'S', sysdate);

-- S/N RY-01 cheque a fecha (gestion = tesoreria)
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CD_VAL_CHEQ', 'S', sysdate);

-- S/N RY-06 / RZ-03 formula ZZZ de la Y y de la Z (opcion 103 del exe)
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CD_VAL_ZZZ', 'N', sysdate);

-- 22-10-2026 FCDVT-56 (nuevos). Si los tres de arriba ya se insertaron,
-- ejecutar solo estos dos.
-- S/N etapa SIN VENTA: cerrar la Z de los terminales sin venta ni Y creada
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CD_SIN_VENTA', 'S', sysdate);

-- S/N RZ-04 dolares declarados contra Prosegur (opcion Btovalidacionprddolar del exe)
insert into VTA_FACOPARAM (vta_ccodtipo, vta_ccodigo, vta_xglosa, vta_dfechareg)
values (1502, 'CD_VAL_DOL', 'N', sysdate);

commit;

-- ESPERADO: CA_DECIMAL 0, CA_DI_ACTIVO S, CA_DI_MAX 20000, CA_DI_MIN -1000,
--           CD_ACTIVO S, CD_SIN_VENTA S, CD_VAL_CHEQ S, CD_VAL_DOL N,
--           CD_VAL_ZZZ N (cada codigo una sola vez)
select trim(vta_ccodigo) codigo, vta_xglosa
  from VTA_FACOPARAM where vta_ccodtipo = 1502 order by 1;
