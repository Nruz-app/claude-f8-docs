# FCDVT-10 (HU-03): scripts de base de datos — carga masiva Y/Z de Tottus Chile (SFCL)

Índice del requerimiento: `docs/README_FCDVT-10.md`. Fuentes del requerimiento: `docs/Requerimiento-FCDVT-10/`. Los scripts no llevan prefijo de esquema; se ejecutan conectado como el dueño de las tablas `VTA_*` (test: `INTRANETTS`). Son Oracle 10.2 y ASCII.

## Decisión: packages nuevos, no reutilizar los de FACO

`PKG_F8_CARGA_MASIVA_YZ` / `PKG_F8_GRABA_MASIVA_YZ` (FCDVT-14) son multipaís solo en el prefijo de tabla: las columnas de conceptos están fijas con las de FACO (`VTA_FACOCARGA_YZ_DET`, el INSERT de `prc_inserta_linea`, `pr_ins_libvta` y `pr_ins_zzz`). En el clon de test, `VTA_SFCLZZZ` no tiene 12 columnas de FACO y tiene unas 40 propias, y `VTA_SFCLLIBVTA` agrega `vta_montoguia`. Además Tottus suma 5 conceptos de venta, tiene MODIFICAR y la Y1 automática. Generalizarlos obligaba a cambiar y volver a probar lo que ya está en test, así que el usuario eligió (11-11-2026) **packages nuevos con las mismas firmas**: Form174 solo elige el nombre según `Flg_Pais$`. FACO no se toca.

Lo que no se pudo cerrar sin conexión (no hay datos de `VTA_PAINT_Z` en el clon) se resolvió leyendo los conceptos **en tiempo de ejecución** desde `VTA_PAINT_Z`, como hacen Form19 y Form19Y. Ver `FORMATO_CARGA_YZ_SFCL.md`.

## Orden

| Orden | Script | Qué hace | Estado |
|---|---|---|---|
| 0 | `00_prechecks.sql` | Solo lectura. §1 conceptos de `VTA_PAINT_Z` (filas 2 a 6 = venta, 7 = total); §2 a §5 columnas inexistentes, repetidas, ignoradas y de la fórmula; §6 nombres libres; §7 dependencias (incluido `TRG_VTA_SFCLZZZ_I`); §8 y §9 menú 460 y perfiles con el 15; §10 volumen | Sin ejecutar |
| 1 | `01_menu_ingreso_masivo_y_sfcl.sql` | Permiso 460 en `VTA_SFCLMENU` + `VTA_SFCLRELPERMEN`, por defecto para los perfiles que tienen el 15 habilitado. **Solo junto con el exe nuevo** (MDIForm1 con SFCL) | Sin ejecutar |
| 2 | `02_tablas_carga_yz_sfcl.sql` | `VTA_SFCLCARGA_YZ_DET` (identificación), `VTA_SFCLCARGA_YZ_DETM` (montos informados, uno por concepto), `VTA_SFCLCARGA_YZ_RES` (como FACO + `res_tipo_carga`), `VTA_SFCLCARGA_YZ_LOG` (como FACO) y `SEQ_VTA_SFCLCARGA_YZ[_LOG]`. Solo crea lo que falta | Sin ejecutar |
| 3 | `03_pkg_carga_masiva_yz_sfcl_spec.sql` | Spec de `PKG_F8_CARGA_MASIVA_YZ_SFCL` (Buscar): `fn_encabezado`, `prc_inicia`, `prc_inserta_linea`, `prc_procesa` (mismas firmas que FACO), y para el package de Cargar `prc_config`, `fn_col_venta`, `fn_sql_ins_zzz`, `fn_sql_upd_zzz`, `fn_sql_valida_z` | Sin ejecutar |
| 4 | `04_pkg_carga_masiva_yz_sfcl_body.sql` | Lee `VTA_PAINT_Z` (ORA-20002 si no tiene la forma de Form19Y), valida líneas (INGRESAR / MODIFICAR) y la base (terminal vigente y no cerrado, `NRO_Y` repetido, MODIFICAR sobre cierres existentes y abiertos) y arma el resumen (1 Z, Z = ΣY, fórmula de la Z) | Sin ejecutar |
| 4b | `04b_pkg_f8_graba_masiva_yz_sfcl_spec.sql` | Spec de `PKG_F8_GRABA_MASIVA_YZ_SFCL.prc_graba` (Cargar), misma firma que FACO | Sin ejecutar |
| 4c | `04c_pkg_f8_graba_masiva_yz_sfcl_body.sql` | INGRESAR: reemplaza como Form19 y crea la Y1 si no hay Y. MODIFICAR: `update` de lo informado. Revalida en la base y hace commit o rollback por grupo → GRABADO / ERROR | Sin ejecutar |
| 5 | `05_grants_sinonimos.sql` | Solo si el exe usa otro usuario (bloques `EDITAR`) | — |
| 6 | `06_pruebas.sql` | Solo lectura: encabezado, fórmula, cargas, resumen, log, detalle y lo grabado en libvta / termstat(y) / zzz (`EDITAR`) | — |
| 98 | `98_limpia_prueba.sql` | **Solo test.** Deshace los grupos INGRESAR GRABADO de una carga y los deja en CARGADO. MODIFICAR no se puede deshacer | — |
| 99 | `99_rollback.sql` | A: menú 460. B: packages (comentado). C: tablas y secuencias (comentado) | — |
| — | `INSTALAR.sql` | 02, 03, 04, 04b y 04c; verifica `user_objects` / `user_errors` y muestra el encabezado | — |
| — | `FORMATO_CARGA_YZ_SFCL.md` | Columnas, reglas y ejemplo del CSV | — |
| — | `prueba_recarga_v1_v2/` | Prueba de recarga v1/v2 (misma de FCDVT-14 sesión 7, sin DI): `py0` exporta `VTA_PAINT_Z`, `arma_prueba.py` genera los CSV, `py2`/`py9` y el resumen. Índice en su `LEEME.md` | Sin ejecutar |

## Diferencias con FACO (FCDVT-14)

| Tema | FACO | Tottus (SFCL) |
|---|---|---|
| Conceptos | 45 columnas fijas | Desde `VTA_PAINT_Z` en cada carga |
| Detalle | Una columna por concepto en DET | `DETM` (fila por concepto informado: distingue vacío de 0) |
| Total de venta | BOLETAS + N.CREDITO + FACTURA | + N.DEBITO + GUIA FACTURABLES (filas 2 a 6, Form19Y) |
| Z sin Y | Error | Válido: Cargar crea la Y1 (Form19.GrabaYprima) |
| Fórmula de la Z | No | Sí (`vta_validadorzzz` / `vta_signo`, Form19.FuncMontoValidaZZZ) |
| MODIFICAR | Rechazado | Habilitado (HU-03.3) |
| Cerrados | Solo en Cargar | En Buscar y en Cargar |

## Riesgos y pendientes

- **`VTA_PAINT_Z` de SFCL no está en el clon.** La carga supone que las filas 2 a 6 son los conceptos de venta y la 7 el total, como asume Form19Y. Correr `00_prechecks.sql` §1 a §5 antes de instalar; si no se cumple, el package da ORA-20002 y lo dice.
- **MODIFICAR valida la Z = ΣY sobre todo el día.** Si el terminal-día ya estaba descuadrado, un MODIFICAR de una sola Y queda en ERROR hasta que el archivo traiga también la corrección de la Z.
- **La Y1 automática** se crea solo cuando el grupo INGRESAR no trae Y (decisión del 11-11-2026: "crear Y1 como Form19", sin duplicar las Y del archivo).
- `TRG_VTA_SFCLZZZ_I` (before insert en zzz) busca la Y en libvta por techkey para `VTA_SFCLTARJ`: Cargar inserta libvta antes que zzz, como Form19Y.
- Pendientes del DF que no se implementan: `vta_traspasado_por = 'C_MASIVA'` (DUD-047) y el reflejo en LVTA / CMP.
- Los CSV de prueba dependen del encabezado real (prechecks §1): `prueba_recarga_v1_v2/arma_prueba.py` los genera desde `VTA_PAINT_Z` exportado (por ahora, los de la prueba de recarga). Casos a cubrir: INGRESAR correcto; Z ≠ ΣY; fórmula de la Z descuadrada; Z sin Y (Y1); MODIFICAR correcto (Y y Z); MODIFICAR sobre una Y inexistente; Y cerrada; mezcla INGRESAR + MODIFICAR; regresión FACO.

## Prueba en test

`00_prechecks.sql` → `INSTALAR.sql` → compilar el exe (Form174 y MDIForm1 de FCDVT-10) → `01_menu_ingreso_masivo_y_sfcl.sql` → Form174 con un usuario SFCL: Exportar Excel, Buscar y Cargar → `06_pruebas.sql` → `98_limpia_prueba.sql`.
