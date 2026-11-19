# FCDVT-10 (HU-03): scripts de base de datos — carga masiva Y/Z de Tottus Chile (SFCL)

Índice del requerimiento: `docs/README_FCDVT-10.md`. Fuentes del requerimiento: `docs/Requerimiento-FCDVT-10/`. Los scripts no llevan prefijo de esquema; se ejecutan conectado como el dueño de las tablas `VTA_*` (test: `INTRANETTS`). Son Oracle 10.2 y ASCII.

## Decisión: packages nuevos, no reutilizar los de FACO

`PKG_F8_CARGA_MASIVA_YZ` / `PKG_F8_GRABA_MASIVA_YZ` (FCDVT-14) son multipaís solo en el prefijo de tabla: las columnas de conceptos están fijas con las de FACO (`VTA_FACOCARGA_YZ_DET`, el INSERT de `prc_inserta_linea`, `pr_ins_libvta` y `pr_ins_zzz`). En el clon de test, `VTA_SFCLZZZ` no tiene 12 columnas de FACO y tiene unas 40 propias, y `VTA_SFCLLIBVTA` agrega `vta_montoguia`. Además Tottus suma 5 conceptos de venta, tiene MODIFICAR y la Y1 automática. Generalizarlos obligaba a cambiar y volver a probar lo que ya está en test, así que el usuario eligió (11-11-2026) **packages nuevos con las mismas firmas**: Form174 solo elige el nombre según `Flg_Pais$`. FACO no se toca.

Lo que no se pudo cerrar sin conexión (no hay datos de `VTA_PAINT_Z` en el clon) se resolvió leyendo los conceptos **en tiempo de ejecución** desde `VTA_PAINT_Z`, como hacen Form19 y Form19Y. Ver `FORMATO_CARGA_YZ_SFCL.md`. Desde el 18-11-2026 el detalle sigue el esquema de Colombia (una columna por concepto en `VTA_SFCLCARGA_YZ_DET`): los nombres y el orden se siguen tomando de `VTA_PAINT_Z`, pero el DDL está fijo a la lista exportada de test (63 conceptos) y `prc_config` valida que coincida (ORA-20002). Agregar un concepto exige recrear la tabla con la lista nueva y recompilar `04`.

## Orden

| Orden | Script | Qué hace | Estado |
|---|---|---|---|
| 0 | `00_prechecks.sql` | Solo lectura. §1 conceptos de `VTA_PAINT_Z` (filas 2 a 6 = venta, 7 = total); §2 a §5 columnas inexistentes, repetidas, ignoradas y de la fórmula; §6 nombres libres; §7 dependencias (incluido `TRG_VTA_SFCLZZZ_I`); §8 y §9 menú 460 y perfiles con el 15; §10 volumen | Sin ejecutar |
| 1 | `01_menu_ingreso_masivo_y_sfcl.sql` | Permiso 460 en `VTA_SFCLMENU` + `VTA_SFCLRELPERMEN` con `INSERT` explícitos, igual que el de FACO (`FCDVT-14`): 1 fila de menú + 1 fila por perfil (activos 9, 10 y 12; el resto de los que tienen el 15 quedan comentados). No reejecutable (ORA-00001). **Solo junto con el exe nuevo** (MDIForm1 con SFCL) | Sin ejecutar |
| 2 | `02_tablas_carga_yz_sfcl.sql` | `VTA_SFCLCARGA_YZ_DET` (identificación + **una columna por concepto**, como `VTA_FACOCARGA_YZ_DET`: las 63 de `VTA_PAINT_Z` de test), `VTA_SFCLCARGA_YZ_RES` (como FACO + `res_tipo_carga`), `VTA_SFCLCARGA_YZ_LOG` (como FACO) y `SEQ_VTA_SFCLCARGA_YZ[_LOG]`. DDL estático, no reejecutable (ORA-00955; reinstalar con `99_rollback.sql` parte C) | Sin ejecutar |
| 2b | `07_migra_det_ancha.sql` | **Solo para un ambiente ya instalado con la versión anterior de `02`** (DET corta + `DETM`): recrea `VTA_SFCLCARGA_YZ_DET` con el DDL de `02` (las filas de prueba **no** se copian: los montos vivían en `DETM`), borra `VTA_SFCLCARGA_YZ_DETM` y verifica. Después recompilar `03`, `04`, `04b` y `04c`. Para instalación limpia no se usa | Sin ejecutar |
| 3 | `03_pkg_carga_masiva_yz_sfcl_spec.sql` | Spec de `PKG_F8_CARGA_MASIVA_YZ_SFCL` (Buscar): `fn_encabezado`, `prc_inicia`, `prc_inserta_linea`, `prc_procesa` (mismas firmas que FACO), y para el package de Cargar `prc_config`, `fn_col_venta`, `fn_sql_ins_zzz`, `fn_sql_upd_zzz`, `fn_cant_conceptos`, `fn_sql_valida_z` | Sin ejecutar |
| 4 | `04_pkg_carga_masiva_yz_sfcl_body.sql` | Lee `VTA_PAINT_Z` (ORA-20002 si no tiene la forma de Form19Y), valida líneas (INGRESAR / MODIFICAR) y la base (terminal vigente y no cerrado, `NRO_Y` repetido, MODIFICAR sobre cierres existentes y abiertos) y arma el resumen (1 Z, Z = ΣY, fórmula de la Z) | Sin ejecutar |
| 4b | `04b_pkg_f8_graba_masiva_yz_sfcl_spec.sql` | Spec de `PKG_F8_GRABA_MASIVA_YZ_SFCL.prc_graba` (Cargar), misma firma que FACO | Sin ejecutar |
| 4c | `04c_pkg_f8_graba_masiva_yz_sfcl_body.sql` | INGRESAR: reemplaza como Form19 y crea la Y1 si no hay Y. MODIFICAR: `update` de lo informado. Revalida en la base y hace commit o rollback por grupo → GRABADO / ERROR | Sin ejecutar |
| 5 | `05_grants_sinonimos.sql` | Solo si el exe usa otro usuario (bloques `EDITAR`) | — |
| 6 | `06_pruebas.sql` | Solo lectura: encabezado, fórmula, cargas, resumen, log, detalle y lo grabado en libvta / termstat(y) / zzz (`EDITAR`) | — |
| 98 | `98_limpia_prueba.sql` | **Solo test.** Deshace los grupos INGRESAR GRABADO de una carga y los deja en CARGADO. MODIFICAR no se puede deshacer | — |
| 99 | `99_rollback.sql` | A: menú 460. B: packages (comentado). C: tablas y secuencias (comentado) | — |
| — | `INSTALAR.sql` | 02, 03, 04, 04b y 04c; verifica `user_objects` / `user_errors` y muestra el encabezado (si `VTA_PAINT_Z` no está configurada, ORA-20002 solo informa: no cierra la instalación) | — |
| — | `FORMATO_CARGA_YZ_SFCL.md` | Columnas, reglas y ejemplo del CSV | — |
| — | `prueba_recarga_v1_v2/` | Prueba de recarga v1/v2 (misma de FCDVT-14 sesión 7, sin DI): `py0` exporta `VTA_PAINT_Z`, `arma_prueba.py` genera los CSV, `py2`/`py9` y el resumen. Índice en su `LEEME.md` | Sin ejecutar |
| — | `pruebas_cargar/` | CSV listos para Buscar/Cargar (equivalente a los de FCDVT-14): `s01_ok` a `s09_errores` (INGRESAR y MODIFICAR: reemplazo, numeración, Z sin Y, fórmula descuadrada, Y inexistente y mezcla) y `s10_y_cerrada.sql`, con el encabezado real exportado de test (`encabezado.txt`, `paint_z_sfcl.csv`) y el generador `arma_csv.ps1`. Índice en su `LEEME.md` | Generados; sin cargar |

## Diferencias con FACO (FCDVT-14)

| Tema | FACO | Tottus (SFCL) |
|---|---|---|
| Conceptos | 45 columnas fijas | Los nombres y el orden salen de `VTA_PAINT_Z` en cada carga (hoy 63; el DDL está fijo a esa lista) |
| Detalle | Una columna por concepto en DET | Igual: una columna por concepto en DET, con el nombre de `vta_cmp_asoc`. Nulo = concepto no informado en el CSV (en INGRESAR se graba 0; en MODIFICAR no se cambia), 0 = informado en 0 |
| Total de venta | BOLETAS + N.CREDITO + FACTURA | + N.DEBITO + GUIA FACTURABLES (filas 2 a 6, Form19Y) |
| Z sin Y | Error | Válido: Cargar crea la Y1 (Form19.GrabaYprima) |
| Fórmula de la Z | No | Sí (`vta_validadorzzz` / `vta_signo`, Form19.FuncMontoValidaZZZ) |
| MODIFICAR | Rechazado | Habilitado (HU-03.3) |
| Cerrados | Solo en Cargar | En Buscar y en Cargar |

## Riesgos y pendientes

- **`VTA_PAINT_Z` de SFCL no está en el clon.** La carga supone que las filas 2 a 6 son los conceptos de venta y la 7 el total, como asume Form19Y. Correr `00_prechecks.sql` §1 a §5 antes de instalar; si no se cumple, el package da ORA-20002 y lo dice.
- **Las columnas de concepto de DET son fijas y van en el orden del encabezado** (`column_id` 15 a 77). Agregar o reordenar un concepto en `VTA_PAINT_Z` obliga a **recrear** la tabla con la lista nueva (un `alter table ... add` deja la columna al final y `prc_config` la rechaza con ORA-20002, que es lo que pide el requerimiento) y reinstalar `04`; `07_migra_det_ancha.sql` es el ejemplo con la lista actual. `06_pruebas.sql` consulta 6c hace el mismo control en solo lectura (nombre y posición). El `04c` lee las columnas por nombre, así que no depende del orden.
- **MODIFICAR valida la Z = ΣY sobre todo el día.** Si el terminal-día ya estaba descuadrado, un MODIFICAR de una sola Y queda en ERROR hasta que el archivo traiga también la corrección de la Z.
- **La Y1 automática** se crea solo cuando el grupo INGRESAR no trae Y (decisión del 11-11-2026: "crear Y1 como Form19", sin duplicar las Y del archivo).
- `TRG_VTA_SFCLZZZ_I` (before insert en zzz) busca la Y en libvta por techkey para `VTA_SFCLTARJ`: Cargar inserta libvta antes que zzz, como Form19Y.
- Pendientes del DF que no se implementan: `vta_traspasado_por = 'C_MASIVA'` (DUD-047) y el reflejo en LVTA / CMP.
- **Decisiones de negocio a confirmar (revisión estática del 18-11-2026, no cambian el código):** (1) `vta_secuencia_srx` = campo SECUENCIA del CSV; la Z de Form19 graba ahí SECUENCIA y la Y de Form19Y (rama SFCL) graba ahí la hora (HHMM), con la secuencia en `vta_secuencia`. (2) `vta_bolfinal` sale de NUM_BOLETA (y `vta_cantbol` = NUM_BOLETA - boli + 1), mientras el VB toma `vta_bolfinal` de `Grid0(6,1)` (SECUENCIA) y `vta_vendedor` / `vta_crepo` de las filas 7 y 8, que la propia pantalla rotula N° BOLETA y VENDEDOR: a confirmar cuál es el dato correcto. (3) los totales de zzz (`vta_pop_up` 3) se graban en 0; FACO calculaba algunos y Form19Y graba lo que trae la grilla. Las tres están anotadas en la cabecera de `04`/`04c` y en `FORMATO_CARGA_YZ_SFCL.md`.
- `pr_valida_base` (`04c`) trata como "cuadra" una fórmula cuyo resultado es NULL (Z sin fila en `VTA_SFCLZZZ` o sin `VTA_SFCLLIBVTA` 'A' ese día): es el mismo comportamiento de `FuncMontoValidaZZZ`, pero un `if v_dif is null then raise_application_error` avisaría en vez de dejar pasar el grupo.
- **Detalles operativos conocidos (18-11-2026, sin cambio de código):** el grupo queda en `MIXTO` también cuando ninguna línea trae un TIPO_CARGA válido (el mensaje "Mezcla INGRESAR y MODIFICAR" es engañoso, el grupo igual es ERROR); las validaciones 4 y 5 vuelven a registrar en el log líneas que ya venían en ERROR; el rechazo del encabezado solo queda en `VTA_SFCLCARGA_YZ_LOG` y Form175 no lo muestra; `98_limpia_prueba.sql` no borra la `termstat` de la Z cuando el terminal-día ya venía cargado por otra carga (la glosa trae el número de la primera); y ningún script purga `DET`/`LOG` (falta un depurador por antigüedad, como en FACO).
- Los CSV de prueba dependen del encabezado real (prechecks §1): `prueba_recarga_v1_v2/arma_prueba.py` y `pruebas_cargar/arma_csv.ps1` los generan desde `VTA_PAINT_Z` exportado. `pruebas_cargar/` trae nueve CSV armados con el encabezado de test del 18-11-2026 (`s01` a `s09`): INGRESAR correcto, `NRO_Y` vacío, Z ≠ ΣY, VENDEDOR de 11 dígitos, `NRO_Y` 99, reemplazo de un terminal-día, numeración de Y, Z sin Y (Y1 automática), MODIFICAR correcto (Y y Z), MODIFICAR de una Y inexistente, mezcla INGRESAR + MODIFICAR y fórmula de la Z descuadrada, más `s10_y_cerrada.sql` para el caso de Y cerrada. Queda como pendiente la regresión FACO (no es un archivo de esta carpeta).

## Prueba en test

**Instalación limpia:** `00_prechecks.sql` → `INSTALAR.sql` → compilar el exe (Form174 y MDIForm1 de FCDVT-10) → `01_menu_ingreso_masivo_y_sfcl.sql` → Form174 con un usuario SFCL: Exportar Excel, Buscar y Cargar → `06_pruebas.sql` → `98_limpia_prueba.sql`.

**Ambiente ya instalado con la versión anterior de `02`** (DET corta + `DETM`): `07_migra_det_ancha.sql` (partes A y B), después recompilar `03`, `04`, `04b` y `04c` (no `02`: daría ORA-00955), y seguir con `06_pruebas.sql`. El `07` **recrea** `DET` (no `alter table`: Oracle solo agrega al final y los conceptos tienen que quedar en las posiciones 15 a 77), así que se pierden las líneas ya cargadas con sus montos: hay que volver a subir esos CSV con Form174. Si se corrió `05_grants_sinonimos.sql`, repetirlo (los grants y sinónimos de `DET` se pierden al recrear la tabla).

## Descargar Excel por local y fecha (16-11-2026, revertido)

El botón **Descargar Excel** de Form174 (que también funcionaba para SFCL) se revirtió el 16-11. La exportación pasó a **Form176** (FCDVT-259), **solo para Colombia (FACO)**: SFCL ya no tiene exportación de cierres. `PKG_F8_EXPORTA_MASIVA_YZ` está ahora en `docs/sql/FCDVT-259/` y no tiene la rama SFCL.
