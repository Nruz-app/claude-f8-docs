# FCDVT-10 (HU-03): scripts de base de datos — carga masiva Y/Z de Tottus Chile (SFCL)

Índice del requerimiento: `docs/README_FCDVT-10.md`. Fuentes del requerimiento: `docs/Requerimiento-FCDVT-10/`. Los scripts no llevan prefijo de esquema; se ejecutan conectado como el dueño de las tablas `VTA_*` (test: `INTRANETTS`). Son Oracle 10.2 y ASCII.

## Decisión del 19-11-2026: las mismas reglas que Colombia

A pedido del usuario, la carga de Tottus quedó **igual a la de Colombia (FCDVT-14)** y solo cambian los campos de concepto:

- solo **INGRESAR** (MODIFICAR da "MODIFICAR todavia no esta habilitado; solo INGRESAR");
- cada terminal-día lleva **1 Z y al menos 1 Y** (sin Y1 automática);
- Buscar valida **Z = suma de las Y** (sin la fórmula de la Z de `VTA_PAINT_Z`);
- los **cierres cerrados** y el `NRO_Y` fuera de 1..98 se rechazan **en Cargar** (no en Buscar);
- los **63 conceptos son una lista fija** (`c_encabezado` en la spec), como los 45 de FACO; el package ya no lee `VTA_PAINT_Z`.

Se mantienen los **packages propios** `PKG_F8_CARGA_MASIVA_YZ_SFCL` / `PKG_F8_GRABA_MASIVA_YZ_SFCL` (decisión del 11-11-2026): FACO no se toca ni hay que volver a probarlo. Su código es una copia de los de FACO con SQL estático sobre las tablas `VTA_SFCL*`. La versión anterior (con `VTA_PAINT_Z`, MODIFICAR, Y1 y fórmula) está en `anterior_2026-11-19/`.

## Orden

| Orden | Script | Qué hace | Estado |
|---|---|---|---|
| 0 | `00_prechecks.sql` | Solo lectura. §1 la lista fija existe en `VTA_SFCLLIBVTA` / `VTA_SFCLZZZ`; §2 conceptos de `VTA_PAINT_Z` que no están en la lista; §3 `VTA_PAINT_Z` de referencia; §4 objetos nuevos; §5 dependencias; §6 y §7 menú 460 y perfiles con el 15; §8 volumen | Versión anterior ejecutada en test el 18-11-2026 |
| 1 | `01_menu_ingreso_masivo_y_sfcl.sql` | Permiso 460 en `VTA_SFCLMENU` + `VTA_SFCLRELPERMEN` con `INSERT` explícitos, como FACO (perfiles activos 9, 10 y 12). No reejecutable (ORA-00001). **Solo junto con el exe nuevo** | Sin ejecutar |
| 2 | `02_tablas_carga_yz_sfcl.sql` | `VTA_SFCLCARGA_YZ_DET` (identificación + una columna por concepto, como `VTA_FACOCARGA_YZ_DET`), `VTA_SFCLCARGA_YZ_RES` y `VTA_SFCLCARGA_YZ_LOG` (como FACO) y `SEQ_VTA_SFCLCARGA_YZ[_LOG]`. DDL estático, no reejecutable (ORA-00955) | Ver "Estado en test" |
| 2b | `07_migra_det_ancha.sql` | **Solo para un ambiente con la `02` del 11-11** (DET corta + `DETM`): recrea `VTA_SFCLCARGA_YZ_DET` con el DDL de `02` (sin copiar filas) y borra `DETM`. Después, recompilar 03, 04, 04b y 04c | Sin ejecutar |
| 3 | `03_pkg_carga_masiva_yz_sfcl_spec.sql` | Spec de `PKG_F8_CARGA_MASIVA_YZ_SFCL` (Buscar): `c_encabezado` (74 columnas), `c_campos`, `c_estado_ok`, `fn_encabezado`, `prc_inicia`, `prc_inserta_linea`, `prc_procesa` (mismas firmas que FACO) | Reescrita el 19-11-2026 |
| 4 | `04_pkg_carga_masiva_yz_sfcl_body.sql` | Copia de `FCDVT-14/04`: lectura, terminal vigente, `NRO_Y` repetido y resumen (1 Z, al menos 1 Y, Z = ΣY) | Reescrito el 19-11-2026 |
| 4b | `04b_pkg_f8_graba_masiva_yz_sfcl_spec.sql` | Spec de `PKG_F8_GRABA_MASIVA_YZ_SFCL.prc_graba` (Cargar), misma firma que FACO | Comentarios del 19-11-2026 |
| 4c | `04c_pkg_f8_graba_masiva_yz_sfcl_body.sql` | Copia de `FCDVT-14/04c`: revalida cerrados, numera las Y, reemplaza como Form19 y graba libvta (con N.DEBITO y GUIA), zzz y termstat(y); commit o rollback por grupo → GRABADO / ERROR | Reescrito el 19-11-2026 |
| 5 | `05_grants_sinonimos.sql` | Solo si el exe usa otro usuario (bloques `EDITAR`) | — |
| 6 | `06_pruebas.sql` | Solo lectura: encabezado, cargas, resumen, log, detalle y lo grabado (`EDITAR`) | — |
| 98 | `98_limpia_prueba.sql` | **Solo test.** Deshace los grupos GRABADO de una carga y los deja en CARGADO | — |
| 99 | `99_rollback.sql` | A: menú 460. B: packages (comentado). C: tablas y secuencias (comentado) | — |
| — | `08_verifica_carga_sfcl.sql` | Solo lectura, después de recompilar 03, 04, 04b y 04c: estado de los dos packages, `user_errors`, largo y campos de `fn_encabezado` (1031 / 74), control del orden de las 63 columnas de concepto contra `VTA_SFCLCARGA_YZ_DET` y la última carga del log | Nuevo 21-11-2026 |
| — | `INSTALAR.sql` | 02, 03, 04, 04b y 04c; verifica `user_objects` / `user_errors` y muestra el encabezado | — |
| — | `FORMATO_CARGA_YZ_SFCL.md` | Columnas, reglas y ejemplo del CSV | — |
| — | `pruebas_cargar/` | CSV para Buscar/Cargar (`s01` a `s09`, `s10_y_cerrada.sql`), con los resultados esperados de las reglas de Colombia en su `LEEME.md` | CSV sin cambios; esperados actualizados el 19-11 |
| — | `prueba_recarga_v1_v2/` | Prueba de recarga v1/v2 (escenarios TA y TB siguen valiendo; TC y TD, Z sin Y, ahora dan ERROR) | Sin ejecutar |
| — | `anterior_2026-11-19/` | Respaldo de la versión anterior (no se ejecuta) | — |

## Estado en test

Según `docs/README_FCDVT-10.md`, en test quedó instalada la versión del 11-11 (DET corta + `DETM`, packages VALID). Para pasar a esta versión: `07_migra_det_ancha.sql` (partes A y B) y después `03`, `04`, `04b` y `04c` (no `02`: daría ORA-00955). Si se corrió `05_grants_sinonimos.sql`, repetirlo. La columna `res_tipo_carga` de `VTA_SFCLCARGA_YZ_RES` que haya quedado en test ya no se usa y no molesta (la `02` nueva no la crea).

**21-11-2026: el primer Buscar en test daba ORA-06502 (corregido).** `c_encabezado` de la spec `03` estaba declarado `varchar2(1000)` y su literal mide **1031** caracteres (74 columnas): el package compilaba VALID pero reventaba al instanciarse, en la primera llamada (`prc_inicia`), con `ORA-06502: character string buffer too small` en la línea del `constant`, y `Form174` lo mostraba como "(PKG_F8_CARGA_MASIVA_YZ_SFCL, carga 0)". FACO no lo ve porque su encabezado mide 760. Quedó `varchar2(4000)` en `03_pkg_carga_masiva_yz_sfcl_spec.sql`: hay que recompilar `03` y `04` en test (no `INSTALAR.sql`, el paso `02` daría ORA-00955) y después correr `08_verifica_carga_sfcl.sql`.

## Diferencias con FACO (FCDVT-14): solo los campos

| Tema | FACO | Tottus (SFCL) |
|---|---|---|
| Conceptos | 45 columnas fijas | 63 columnas fijas (`c_encabezado`) |
| Total de venta | BOLETAS + N.CREDITO + FACTURA | + N.DEBITO + GUIA FACTURABLES (`vta_mmontondb`, `vta_montoguia`) |
| libvta | `vta_mmontondb` = 0 | `vta_mmontondb` y `vta_montoguia` del archivo (Form19 rama SFCL) |
| zzz | 45 columnas de FACO + `rec_mtotatrf` calculada | 58 columnas de Tottus, tal cual vienen |
| Package | Multipaís con `{P}` (`PKG_F8_CARGA_MASIVA_YZ`) | Propio, SQL estático sobre `VTA_SFCL*` |
| Reglas | — | Las mismas |

## Riesgos y pendientes

- **Conceptos nuevos:** si Tottus agrega un concepto a `VTA_PAINT_Z`, la carga no lo trae hasta sumarlo a la lista fija (`02`, `03`, `04`, `04c`), como en Colombia. `00_prechecks.sql` §2 lo detecta.
- `TRG_VTA_SFCLZZZ_I` (before insert en zzz) busca la Y en libvta por techkey para `VTA_SFCLTARJ`: Cargar inserta libvta antes que zzz, como Form19Y.
- `98_limpia_prueba.sql` no revierte `VTA_SFCLTARJ` ni los movimientos 'AL' (trae la consulta para verlos) y no borra la `termstat` de la Z cuando el terminal-día ya venía cargado por otra carga.
- Ningún script purga `DET` / `LOG` (igual que FACO).
- Pendientes del DF que no se implementan (tampoco en FACO): `vta_traspasado_por = 'C_MASIVA'` (DUD-047) y el reflejo en LVTA / CMP.
- La HU-03 pedía "Z calculada a partir de las Y" y MODIFICAR (HU-03.3); se siguió la regla de Colombia por decisión del usuario (19-11-2026).

## Prueba en test

**Ambiente con la versión del 11-11:** `07_migra_det_ancha.sql` → `03`, `04`, `04b`, `04c` → compilar el exe (Form174 del 19-11) → `01_menu_ingreso_masivo_y_sfcl.sql` si falta → Form174 con un usuario SFCL: Exportar Excel, Buscar y Cargar con `pruebas_cargar/` → `06_pruebas.sql` → `98_limpia_prueba.sql`. Regresión FACO con sus CSV de `docs/sql/FCDVT-14/pruebas_cargar/`.

**Instalación limpia:** `00_prechecks.sql` → `INSTALAR.sql` → lo mismo desde "compilar el exe".
