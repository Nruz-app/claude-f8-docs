# FCDVT-259: scripts de Exportar Cierres Y y Z (Form176), solo Colombia (FACO)

Creada el 16-11-2026. Índice del requerimiento: `docs/README_FCDVT-259.md`. La primera instalación en desarrollo (16-11) dejó el body INVALID y se corrigió: ver la bitácora al pie.

`PKG_F8_EXPORTA_MASIVA_YZ` nació en FCDVT-14 (`04d`/`04e`, botón "Descargar Excel" de Form174, multipaís FACO/SFCL, nunca instalado). El 16-11 ese botón se revirtió en Form174 y la exportación pasó a Form176. El package se trasladó aquí, **solo para FACO** y con los filtros de Form176.

| Paso | Archivo | Qué hace | Estado |
|---|---|---|---|
| 0 | `00_prechecks.sql` | Solo lectura: código 461 libre, perfiles con el 460, `PKG_F8_CARGA_MASIVA_YZ` válido, encabezado, columnas y cierres de los últimos 3 días | Sin ejecutar |
| 1 | `01_menu_exporta_yz.sql` | Permiso **461** "Exportar cierres Y y Z" en `VTA_FACOMENU` y `VTA_FACORELPERMEN` (perfiles 10 y 11, los mismos del 460; 0 y 1 comentados). Muestra el submenú `EXPYZ` del botón Y → Form176. No es reejecutable (ORA-00001). **Va aparte, solo junto con el exe nuevo:** con el exe anterior corta la carga de los permisos siguientes. No está en `INSTALAR.sql` | Sin ejecutar |
| 2 | `02_pkg_f8_exporta_masiva_yz_spec.sql` | Spec: `fn_encabezado` y `fn_lineas(local, terminal, fecha_ini, fecha_fin, grupo)` *pipelined* | VALID en desarrollo (16-11) |
| 3 | `03_pkg_f8_exporta_masiva_yz_body.sql` | Body solo FACO (`VTA_FACOLIBVTA` + `VTA_FACOZZZ`, `VTA_FACOLOCALES` para el grupo). Una línea `;` por cierre con el formato del CSV de carga; Z armada con la suma de las Y si el terminal-día no tiene Z | INVALID en desarrollo; corregido el 16-11, reinstalar |
| 4 | `04_grants_sinonimos.sql` | Grant y sinónimo del package para el usuario del exe (`EDITAR`) | — |
| 5 | `05_pruebas.sql` | Solo lectura: encabezado, un local, comparación con libvta, un terminal, todos los locales, grupo y fecha fin < inicio (ORA-20004) | — |
| — | `INSTALAR.sql` | Ejecuta 02 y 03 (no el 01) y verifica `user_objects` / `user_errors` | — |
| 99 | `99_rollback.sql` | A: borra el permiso 461. B (comentada): `drop package` y sinónimo | — |
| — | `pruebas/` | Prueba de punta a punta en test (graba con Form174 y limpia con `d09`). Pasos y resultado esperado en `pruebas/README.md` | Sin ejecutar |
| — | `pruebas/sesion_2026-11-07/` | La misma prueba con fecha **07-11-2026** (día sin cierres 08-11-2026), con la regla de fechas del 17-11 (rango de 3 días, sin límite hacia atrás). Pasos en su `README.md` | Creada el 19-11-2026; sin ejecutar |

## `PKG_F8_EXPORTA_MASIVA_YZ`

- `fn_encabezado`: `PKG_F8_CARGA_MASIVA_YZ.c_encabezado` (56 columnas; requiere los scripts `03`/`04` de `docs/sql/FCDVT-14/`).
- `fn_lineas(p_local, p_terminal, p_fecha_ini, p_fecha_fin, p_grupo default null)`:
  - filtros: `vta_fecha_venta` entre las dos fechas; local 0 = todos; terminal 0 = todos; `p_grupo` (opcional) limita a los locales de `VTA_FACOLOCALES.vta_grupo`. Form176 lo manda solo cuando un usuario de grupo elige "TODOS LOS LOCALES";
  - orden: fecha, local, terminal, la Z y las Y por número;
  - identificación: el inverso de `pr_ins_libvta` (`docs/sql/FCDVT-14/04c`). Montos: cada columna del encabezado se busca en libvta o zzz (`user_tab_columns`);
  - **Z armada**: un terminal-día con Y y sin Z vigente (FACO cerrado solo con Y) sale con una Z = suma de sus Y columna a columna e identificación de la última Y, para que Buscar de Form174 la acepte;
  - solo filas `vta_estado = 'A'`. Fecha fin < inicio → ORA-20004.
- La regla de "inicio ≥ hoy − 2 días y fin ≤ ayer" la valida **Form176**, no el package.
- Cambios respecto del 04e de FCDVT-14: sin `p_flg_pais` ni lista blanca (tablas `VTA_FACO*` fijas), filtros de rango, terminal y grupo, corte de la Z armada por fecha-local-terminal y sin `fn_resumen` (el conteo lo hace Form176).

## Orden de instalación

1. `00_prechecks.sql`.
2. `INSTALAR.sql` (o 02 y 03 en DBeaver).
3. `04_grants_sinonimos.sql`, si el exe usa otro usuario.
4. `05_pruebas.sql`.
5. Exe con `Form176` y el `MDIForm1` de FCDVT-259 (`docs/Cambios/README.md`) y, **junto con él**, `01_menu_exporta_yz.sql`. El permiso 461 con el exe anterior corta la carga de los permisos siguientes del perfil (mismo caso que el 460); el exe nuevo sin el package muestra el error de Oracle al exportar.

**Fecha Fin hasta ayer:** Buscar de Form174 rechaza fechas de hoy ("La fecha debe ser anterior a hoy", `docs/sql/FCDVT-14/04`), por eso Form176 no deja exportar cierres de hoy.

## Bitácora

| Fecha | Qué |
|---|---|
| 16-11-2026 | **Primera instalación en desarrollo** (`INTRANETDE`, 14:59/15:04): spec `02` **VALID**, body `03` **INVALID** con `PLS-00103` en la línea de `c_id` (más `END` de cierre en cascada). El source cargado en la base era idéntico al script: el propio script no compilaba. Causa: el body declaraba los datos (`c_id`, `c_n_id`, `t_buf`) **después de la primera rutina** (`end fn_expr;`) y el parser de 10.2 solo acepta ahí `begin/end/function/package/pragma/procedure`; en todo el esquema no hay ningún body VALID con declaraciones entre subprogramas. Corregido en `03` (único archivo del ticket tocado): el bloque comentario + `c_id` + `c_n_id` + `type t_buf` se movió al tope del body, antes de `fn_existe_col`, como en el body VALID de `PKG_F8_CARGA_MASIVA_YZ`. Sin otros cambios de código; la spec `02` quedó igual. `MANIFIESTO_FCDVT-259.md5` regenerado. Pendiente: reinstalar `03` en desarrollo y en test |
