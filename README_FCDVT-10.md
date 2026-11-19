# FCDVT-10 — HU-03: ingreso masivo de cierres de caja F8, Tottus Chile (SFCL)

Historia padre: FSCC-13183 ([SCCFIN] Mejoras Legado F8 y Control de Ventas). Subtareas: FCDVT-11 (habilitar con sus conceptos), FCDVT-12 (ingresar las Y y la Z), FCDVT-13 (modificar conceptos de una Y). Estado en Jira: Refining.

## 1. Estado (11-11-2026)

| Parte | Estado |
|---|---|
| Scripts de base (`docs/sql/FCDVT-10/`) | Escritos y revisados con `sql-lint`; **sin compilar ni ejecutar** (no hubo conexión a test) |
| Exe: `MDIForm1.frm`, `Form174.frm` | Editados (respaldos `.bak_FCDVT-10`), sincronizados en `docs/Cambios/`; **18-11-2026:** el bloque de SFCL se volvió a aplicar sobre el `Form174` rediseñado el 17-11 (el rediseño lo había perdido) y `Form174` y `MDIForm1` quedan sincronizados; **sin compilar** |
| Form175.frm | Sin cambios de código: lee `VTA_<pfx>CARGA_YZ_LOG/DET` con columnas que también tienen las tablas de SFCL. La copia viva se rediseñó el 17-11 (diseño distinto al de `docs/Cambios/archivos/`; ver Historial) |
| CSV de prueba | **18-11-2026:** `docs/sql/FCDVT-10/pruebas_cargar/` trae `s01_ok.csv` a `s09_errores.csv` (INGRESAR y MODIFICAR: reemplazo, numeración, Z sin Y, fórmula descuadrada, Y inexistente y mezcla) y `s10_y_cerrada.sql`, armados con el encabezado real de test (`fn_encabezado`, 74 columnas) y el generador `arma_csv.ps1`; **pendiente cargarlos**. La prueba de recarga v1/v2 se sigue generando con `prueba_recarga_v1_v2/arma_prueba.py` |

## 2. Artefactos

- Fuentes del requerimiento: `docs/Requerimiento-FCDVT-10/` (`FCDVT-10.doc` es la exportación HTML de Jira; BPMN AS-IS/TO-BE de HU-03; captura de Form19Y en Tottus). El DF con la plantilla de Tottus está en `docs/Requerimiento-FCDVT-14/DF-SCC-vf_24.03.2025 Ingreso Cierre de caja F8.xlsx` (hoja F8-LV-CMP-TES, filas 31 a 35 y 47 a 50).
- Scripts: `docs/sql/FCDVT-10/` (índice `00_LEEME.md`, formato `FORMATO_CARGA_YZ_SFCL.md`).
- Prueba de recarga v1/v2: `docs/sql/FCDVT-10/prueba_recarga_v1_v2/` (índice `LEEME.md`). Generador `arma_prueba.py` + plantillas de `py2`/`py9`; ver §7.
- CSV de prueba de Buscar/Cargar: `docs/sql/FCDVT-10/pruebas_cargar/` (índice `LEEME.md`): `s01_ok.csv` a `s09_errores.csv`, `s10_y_cerrada.sql`, `encabezado.txt`, `paint_z_sfcl.csv` y `arma_csv.ps1`.
- Exe: `FTEPROD/MDIForm1.frm`, `FTEPROD/Form174.frm`; detalle en `docs/Cambios/README.md` §2.3 y §2.4.

## 3. Decisiones del usuario (11-11-2026)

1. **Packages nuevos para SFCL** (`PKG_F8_CARGA_MASIVA_YZ_SFCL`, `PKG_F8_GRABA_MASIVA_YZ_SFCL`) con las mismas firmas que los de FACO; FACO no se toca. Motivo: los packages de FCDVT-14 tienen las columnas de conceptos de FACO fijas, y `VTA_SFCLZZZ` / `VTA_SFCLLIBVTA` tienen otras.
2. **La Z viene en el archivo** (como FACO y la plantilla del DF) y se valida Z = ΣY. La HU decía "el Z se calcula a partir de las Y"; se siguió el DF.
3. **MODIFICAR entra en esta entrega** (HU-03.3): vacío = no cambia.
4. **Y1 automática como Form19**: se crea cuando el grupo INGRESAR trae la Z sin Y.

Decisión técnica (sin conexión para leer `VTA_PAINT_Z`): los conceptos se leen de `VTA_PAINT_Z` en tiempo de ejecución, igual que Form19Y. El encabezado del CSV lo da `fn_encabezado` y Form174 lo pide a la base. El detalle (`VTA_SFCLCARGA_YZ_DET`) sigue el esquema de Colombia desde el 18-11-2026: una columna por concepto, con esos mismos nombres y orden (ver §4.2).

## 4. Diseño

- Buscar: `PKG_F8_CARGA_MASIVA_YZ_SFCL` (`prc_inicia` → `prc_inserta_linea` → `prc_procesa`) sobre `VTA_SFCLCARGA_YZ_DET/RES/LOG`. `VTA_SFCLCARGA_YZ_DET` tiene una columna por concepto, con el nombre y el orden de `VTA_PAINT_Z` (como `VTA_FACOCARGA_YZ_DET`; 63 columnas en test) y `prc_config` valida que coincidan (ORA-20002). Valida líneas, terminal vigente y no cerrado, `NRO_Y` repetido, MODIFICAR sobre cierres existentes y abiertos, y por grupo: 1 Z, Z = ΣY (venta = filas 2 a 6 de `VTA_PAINT_Z`), fórmula de la Z (`vta_validadorzzz`), sin Y cerradas en INGRESAR, sin mezcla INGRESAR/MODIFICAR.
- Cargar: `PKG_F8_GRABA_MASIVA_YZ_SFCL.prc_graba`. INGRESAR reemplaza como Form19 (rama SFCL) e inserta la Y1 si no hay Y; MODIFICAR hace `update` de lo informado y recalcula `vta_totalvta`. Revalida en la base y hace commit o rollback por grupo.
- Exe: `MDIForm1` habilita el submenú del botón Y y `INGYMA` → `Form174` también en SFCL; `Form174` elige el package con `PaqueteCargaYZ()` / `PaqueteGrabaYZ()` y en SFCL lee el encabezado y las glosas de la base.

### Revisión del 11-11-2026 (`f8-revisor`, sin errores de compilación)

Se corrigieron:
- **Salir de Form174** ejecutaba el cierre diario de prueba de FACO también con usuarios de Tottus; ahora solo con `Flg_Pais$ = "FACO"`.
- **MODIFICAR y `TRG_VTA_SFCLZZZ_I`** (solo BEFORE INSERT): la fila zzz de una Y modificada se borra y se reinserta igual para que el trigger actualice `VTA_SFCLTARJ` (2001/2002) y el movimiento 'AL'. La de la Z queda con UPDATE, porque su insert borra los de todo el día.
- **Y ilegible + Z sin Y:** si la carga tiene líneas con error sin grupo, un grupo INGRESAR sin Y queda en ERROR (antes Cargar habría creado la Y1 y perdido la Y real).
- `vta_pop_up` nulo = 0, como Form19 / Form19Y (package y prechecks).
- Solo se valida el nombre de las filas de `VTA_PAINT_Z` que se usan; la fila 1 no se graba (como `arma_query_rec`).
- MODIFICAR solo recalcula `vta_totalvta` si viene algún concepto de venta.
- `98_limpia_prueba.sql` avisa que no revierte `VTA_SFCLTARJ` / 'AL' y trae la consulta para verlos.

Quedan como diferencias conocidas: `vta_secuencia_srx` de las Y = SECUENCIA (Form19Y graba la hora); el ejemplo de la hoja Instrucciones trae solo las primeras 4 columnas de concepto (Buscar lo rechaza por número de campos) y no trae formas de pago, así que copiado tal cual queda descuadrado por la fórmula de la Z.

### Revisión estática del 18-11-2026

Segunda pasada sobre `docs/sql/FCDVT-10/` contra los packages de FACO y el VB6, sin compilar ni ejecutar: no aparecieron errores de compilación (10.2), ni firmas/columnas desalineadas con `Form174`/`Form175`, ni `&` o prefijos de esquema. Quedan **tres decisiones de negocio por confirmar** (anotadas en `docs/sql/FCDVT-10/00_LEEME.md` §Riesgos): `vta_secuencia_srx` = SECUENCIA en el package, SECUENCIA en la Z de Form19 y hora en la Y de Form19Y; `vta_bolfinal` / `vta_vendedor` / `vta_crepo` desde NUM_BOLETA y las columnas 8 y 9 del CSV, mientras el VB los toma de las filas 6/7/8 de `Grid0` (rotuladas SECUENCIA / N° BOLETA / VENDEDOR); y los totales de zzz (`vta_pop_up` 3) en 0. Además, `pr_valida_base` acepta como "cuadra" una fórmula que devuelve NULL (Z sin fila en `VTA_SFCLZZZ` o sin `VTA_SFCLLIBVTA` 'A'): igual que `FuncMontoValidaZZZ`, pero convendría un `raise_application_error`. En `00_LEEME.md` quedaron también los detalles operativos menores (estado `MIXTO` engañoso con TIPO_CARGA nulo, log duplicado de líneas ya en ERROR, encabezado rechazado visible solo en el log, alcance de `98_limpia_prueba.sql` y falta de purga de `DET`/`DETM`/`LOG`).

## 4.1 Prechecks en test (18-11-2026)

Ejecutado contra `sgfinperds` con el usuario de aplicación `UINTRANETTS` (solo lectura) y `alter session set current_schema = INTRANETTS`. Como `user_objects` / `user_tab_columns` no ven los objetos del dueño, esa corrida usó una copia de `00_prechecks.sql` con `all_objects` / `all_tab_columns` filtrados por `sys_context('USERENV','CURRENT_SCHEMA')`; el script del repo queda igual y se ejecuta como dueño (`INTRANETTS`).

| Sección | Resultado |
|---|---|
| 1) Conceptos de `VTA_PAINT_Z` | **81 filas** para `SFCL`. Filas 1 a 7: `VENTAS` (título), `BOLETAS`=`vta_montobol`, `N.CREDITO`=`vta_montoncr`, `FACTURA`=`vta_montofac`, `N.DEBITO`=`VTA_MMONTONDB`, `GUIA FACTURABLES`=`VTA_MONTOGUIA` (las 5 con `vta_pop_up` 0 y validador 1) y `TOTALES`=`vta_totalvta` (`vta_pop_up` 3). El resto son formas de pago / zzz (validadores 7, 3, 2, 6 y 0) y filas de título (`vta_pop_up` 1). Las 5 columnas de venta existen en `VTA_SFCLLIBVTA`. |
| 2) Editables que faltan en `VTA_SFCLZZZ` | 0 filas |
| 3) `vta_cmp_asoc` repetido | 0 filas |
| 4) Conceptos `VTA_` editables fuera de las filas 2 a 6 | 0 filas |
| 5) Columnas de la fórmula de la Z inexistentes | 0 filas (fórmula completa) |
| 6) Objetos nuevos | 0 filas (instalación limpia) |
| 7) Objetos que usan los packages | 7 VALID (`VTA_PAINT_Z`, `VTA_SFCLLIBVTA`, `VTA_SFCLZZZ`, `VTA_SFCLTERMSTAT`, `VTA_SFCLTERMSTATY`, `VTA_SFCLTERMINALES`, `SEQ_VTA_SFCLTEC`). `TRG_VTA_SFCLZZZ_I` no aparece en `all_objects` con el usuario de aplicación; en `all_triggers` está **BEFORE EACH ROW INSERT, ENABLED**. |
| 8) Menú 460 | 0 filas en `VTA_SFCLMENU` y `VTA_SFCLRELPERMEN` |
| 9) Perfiles con el permiso 15 | `0, 1, 3, 6, 7, 8, 9, 10, 11, 12, 13`; con `rel_estado` −1 (visibles) solo **9, 10 y 12**, que son los que tomaría el `insert-select` de `01_menu_ingreso_masivo_y_sfcl.sql` |
| 10) Cierres Y/Z en SFCL, últimos 7 días | 0 filas: Buscar parte sin datos; para probarlo hay que Cargar primero |

Con esto `prc_config` de `PKG_F8_CARGA_MASIVA_YZ_SFCL` debería cargar sin ORA-20002. Falta ejecutar `INSTALAR.sql` conectado como dueño (`INTRANETTS`), que es DDL y no lo corre el agente.

## 4.2 Detalle ancho: DET con una columna por concepto (18-11-2026)

La primera versión guardaba en `VTA_SFCLCARGA_YZ_DET` solo la identificación y el total, y los montos en `VTA_SFCLCARGA_YZ_DETM` (una fila por concepto informado). A pedido del usuario se pasó al **mismo esquema que Colombia** (`VTA_FACOCARGA_YZ_DET`): `VTA_SFCLCARGA_YZ_DET` tiene las 14 columnas de identificación (`column_id` 1 a 14), las **63 columnas de concepto** (`column_id` 15 a 77, nombre = `vta_cmp_asoc` y en el orden de `VTA_PAINT_Z` / del encabezado exportado el 18-11-2026) y `det_total`, `det_estado` y `det_fechahora` (78 a 80). `VTA_SFCLCARGA_YZ_DETM` desaparece.

- **Semántica:** columna `NULL` = concepto no informado en el CSV; `0` = informado en 0. En INGRESAR el nulo se graba 0 en libvta / zzz; en MODIFICAR no se toca la columna (`fn_sql_upd_zzz` arma el `update` solo con las informadas). `det_total` sigue nulo en MODIFICAR.
- **`VTA_PAINT_Z` sigue mandando:** `prc_config` arma el encabezado, las glosas y las validaciones desde esa tabla, y además exige que cada concepto tenga su columna en DET en la posición que corresponde (ORA-20002 con el número de columna y la glosa si falta o cambió el orden). El INSERT de `prc_inserta_linea` quedó estático (63 binds `v_vals(1..63)`), como el de FACO.
- **Lectura de montos unificada:** `prc_config` arma `g_sql_conc` (un `select 'COLUMNA', COLUMNA … where COLUMNA is not null` por concepto, unidos con `union all`) y `pr_montos_linea` lo lee con `execute immediate … bulk collect into` sobre arrays asociativos; lo usan `fn_sql_upd_zzz`, `fn_dif_valida_archivo` y la nueva `fn_cant_conceptos` (conteo del MODIFICAR en `04c`).
- **Migración de test:** `07_migra_det_ancha.sql` **recrea** `VTA_SFCLCARGA_YZ_DET` con este DDL (no `alter table`: Oracle solo agrega columnas al final y los conceptos tienen que quedar en las posiciones 15 a 77, que es lo que valida `prc_config`) y borra `DETM`; las líneas de prueba se descartan y se vuelven a subir con Form174. Para instalación limpia basta el `02` corregido. En un ambiente migrado los packages quedan `INVALID` hasta recompilar `03`, `04`, `04b` y `04c`, y hay que repetir `05_grants_sinonimos.sql` si se había corrido.
- **Riesgo:** agregar o reordenar un concepto en `VTA_PAINT_Z` exige recrear la tabla con la lista nueva y reinstalar `04` (el `04c` lee la columna por nombre). Lo detectan `prc_config` y la consulta 6c de `06_pruebas.sql`.
- **Sin cambio de exe:** `Form174`, `Form175` y `Form176` no leen `DETM` ni las columnas de concepto (leen `RES`, `LOG` y las columnas `det_*`), así que `FTEPROD/` no se toca.

## 5. Pendientes

1. ~~Ejecutar `docs/sql/FCDVT-10/00_prechecks.sql` en test y guardar la salida aquí.~~ Hecho el 18-11-2026 (§4.1).
2. En test: `INSTALAR.sql` si la instalación es limpia, o `07_migra_det_ancha.sql` + recompilar `03`, `04`, `04b` y `04c` si ya estaba la versión anterior de `02` (compilación de los dos packages; sin `user_errors`).
3. Compilar el exe y probar en test (casos en `docs/sql/FCDVT-10/00_LEEME.md`), más la regresión FACO.
4. ~~Armar los CSV de prueba con el encabezado real: exportar `VTA_PAINT_Z` (py0 consulta 3 de `prueba_recarga_v1_v2/`) y correr `arma_prueba.py`.~~ **18-11-2026:** exportados `encabezado.txt` y `paint_z_sfcl.csv` de test (74 columnas, 81 conceptos) y generados los CSV de `pruebas_cargar/` con `arma_csv.ps1`. Falta cargarlos en Form174. La prueba de recarga v1/v2 (`arma_prueba.py`) sigue sin correr. **18-11-2026 (2):** el set se completó con `s04` a `s10` (reemplazo, numeración, MODIFICAR, Z sin Y, fórmula descuadrada, Y inexistente, mezcla de INGRESAR/MODIFICAR y Y cerrada); ver §7 Historial (7).
5. Confirmar con negocio: perfiles del permiso 460 en SFCL (hoy, los mismos que el 15); DUD-047 (`vta_traspasado_por = 'C_MASIVA'`) y el reflejo en LVTA / CMP, que no se implementan.
6. Paso a producción: ver `docs/Cambios/README.md` §3 (incluye `Gversion`).

## 6. Cómo retomar

Leer este archivo, `docs/sql/FCDVT-10/00_LEEME.md` y `docs/Cambios/README.md` §2.3 y §2.4. Los packages de FACO quedan en `docs/sql/FCDVT-14/` y no se tocan.

## 7. Historial

| Fecha | Cambio |
|---|---|
| 11-11-2026 | Scripts de `docs/sql/FCDVT-10/` (packages `_SFCL`, tablas, menú 460, pruebas, limpieza y rollback), `Form174` y `MDIForm1` (respaldos `.bak_FCDVT-10`, `docs/Cambios/` sincronizado) y revisión de `f8-revisor` (§4). Sin compilar ni ejecutar. |
| 12-11-2026 | **Prueba de recarga v1/v2** (`docs/sql/FCDVT-10/prueba_recarga_v1_v2/`), la misma de FCDVT-14 sesión 7 sin DI ni sobres (en SFCL la DI automática no está habilitada). Como el encabezado depende de `VTA_PAINT_Z`, el usuario eligió un **generador**: `py0` exporta `VTA_PAINT_Z` y `fn_encabezado`, y `arma_prueba.py` replica `prc_config`, arma `carga_v1.csv`/`carga_v2.csv` (venta en BOLETAS y una columna de pago que cuadra la fórmula de la Z), `py2`/`py9` y el Excel de resumen. Escenarios: INGRESAR v1 → INGRESAR v2 (TA: Z + Y1; TB: 2 Y → 1 Y) y Z sin Y con Y1 automática (TC: Z sin Y → Z sin Y; TD: 2 Y → Z sin Y). Esperado según `pr_graba_ingresar`: queda v2 y las Y de v1 que v2 no trae se borran. Verificado en el trigger `TRG_VTA_SFCLZZZ_I`: el insert de la zzz de la Z borra `VTA_SFCLTARJ` 2001-2999 y los 'AL' del terminal-día, y cada Y los recrea (no deberían quedar huérfanas; `py2` D1 lo comprueba). Generador probado offline con un `VTA_PAINT_Z` ficticio; sin ejecutar en test. |
| 18-11-2026 | **Resincronización del exe vivo.** `FTEPROD/Form174.frm` había quedado rediseñado el 17-11 (layout más alto, `Picture1`/`Image1`/`Image2`, `Grid1.Row`/`.Col`) y en ese rediseño se había perdido todo el bloque FCDVT-10 de SFCL, además de quedar 46 acentos como U+FFFD. Se volvió a aplicar el bloque sobre el fuente vivo (`PaqueteCargaYZ`/`PaqueteGrabaYZ`, `EncabezadoBase`, `GlosaPaintZ`, `ColumnaExcel`, `EjemploSFCL`, rama SFCL de `EncabezadoCsvY`, rangos por país en Exportar Excel, MODIFICAR y avisos de Cargar) y se restauraron los acentos en Windows-1252. `Salir` queda solo `Unload Me` (el rediseño ya había quitado la prueba `EjecutaCierreDiario`). `docs/Cambios/archivos/Form174.frm` y su diff quedan idénticos al fuente vivo. `Form175.frm` no se toca (sin cambios de código). Sin compilar ni ejecutar. |
| 18-11-2026 (2) | **`INSTALAR.sql` no cierra en "failure" por la verificación de `VTA_PAINT_Z`.** La última consulta (`fn_encabezado('SFCL')`) lanza ORA-20002 cuando `VTA_PAINT_Z` no tiene aún la forma esperada, y con el `whenever sqlerror exit failure rollback` de la cabecera eso marcaba la instalación como fallida aunque los objetos ya estaban creados. Se agregó `whenever sqlerror continue` antes de esa verificación (que sigue siendo informativa) y un comentario que remite a `00_prechecks.sql` §6. Sin ejecutar en la base. |
| 18-11-2026 | **Revisión estática de los scripts** (§4): sin errores de compilación; se documentan las tres decisiones de negocio a confirmar y el caso NULL de `pr_valida_base` en `docs/sql/FCDVT-10/00_LEEME.md`, y se corrigen las contradicciones de redacción de `FORMATO_CARGA_YZ_SFCL.md` y del comentario de `02_tablas_carga_yz_sfcl.sql` (`res_tipo_carga`). Además se corrigieron dos marcas de comentario de `FTEPROD/MDIForm1.frm` (`----INI/FIN----` → `---INI/FIN----`), con lo que queda byte a byte igual a `docs/Cambios/archivos/MDIForm1.frm`. Manifiestos recalculados. Sin ejecutar en la base. |
| 18-11-2026 (3) | **Prechecks ejecutados en test** (§4.1), con el usuario de aplicación `UINTRANETTS` en solo lectura y una copia local con `all_*` (el script del repo no cambia). `VTA_PAINT_Z` de SFCL tiene la forma que espera `prc_config` (81 filas; filas 1 a 7 con los 5 conceptos de venta y `TOTALES`) y no hay columnas faltantes, duplicados ni conceptos `VTA_` fuera de las filas 2 a 6; los 7 objetos base están VALID y `TRG_VTA_SFCLZZZ_I` está BEFORE INSERT ENABLED. No hay menú 460 ni cierres Y/Z en SFCL en los últimos 7 días. Falta `INSTALAR.sql` como dueño (DDL): no lo ejecuta el agente. |
| 18-11-2026 (4) | **`02_tablas_carga_yz_sfcl.sql` en DDL estático.** Se quitó el bloque PL/SQL con `execute immediate` / `user_objects` que creaba "solo lo que falta" y quedó como la versión FACO del 30-10: `create table` / `create index` / `create sequence` / `comment on table`, con comentarios por columna. Consecuencia: ya no es reejecutable (ORA-00955 si los objetos existen; se reinstala con `99_rollback.sql` parte C), igual que el resto de los scripts de instalación. Columnas y tipos idénticos, así que los packages no cambian. `INSTALAR.sql` y `00_LEEME.md` actualizados. En test los objetos están libres (prechecks §6). |
| 18-11-2026 (5) | **`01_menu_ingreso_masivo_y_sfcl.sql` con `INSERT` explícitos, igual que FACO.** Se alineó con `docs/sql/FCDVT-14/01_menu_ingreso_masivo_y.sql`: 1 `insert` a `VTA_SFCLMENU` y 1 `insert` a `VTA_SFCLRELPERMEN` por perfil, sin `select` ni `where not exists`. Quedan activos los perfiles que en test tienen el permiso 15 (Ingreso de Y) visible —9, 10 y 12— y comentadas las líneas de los que lo tienen oculto (0, 1, 3, 6, 7, 8, 11 y 13), para agregar o quitar según negocio. No es reejecutable: una segunda ejecución da ORA-00001 (PK), esperado. `00_LEEME.md` y `Cambios/README.md` §2.3 actualizados. Sin ejecutar en la base. |
| 18-11-2026 (6) | **CSV de prueba listos** (`docs/sql/FCDVT-10/pruebas_cargar/`, equivalente a `FCDVT-14/pruebas_cargar`). Exportados de test en solo lectura `encabezado.txt` (`fn_encabezado('SFCL')`, 74 columnas = 11 + 63 conceptos) y `paint_z_sfcl.csv` (81 filas de `VTA_PAINT_Z`), y generados con `arma_csv.ps1` `s01_ok.csv` (17-11-2026, local 116 T1: Z + 2 Y), `s02_dos_terminales.csv` (17-11, T5 con 3 Y y `NRO_Y` vacío + T6) y `s03_mixto.csv` (16-11, T1 correcto y T4 descuadre, T5 VENDEDOR de 11 dígitos y T6 `NRO_Y` 99). Solo `INGRESAR`; montos en BOLETAS y EFECTIVO, con Z = ΣY y la fórmula de la Z en 0 verificadas por el generador. Local 116 HUECHURABA y terminales elegidos por estar libres esos días (16-11: T1, T4, T5, T6; 17-11: T1, T5, T6). Los packages `_SFCL` están VALID en test, así que solo falta cargarlos con el exe compilado. En SFCL `NRO_Y` 99 se rechaza en Buscar (en FACO recién en Cargar). Sin ejecutar en la base. |
| 18-11-2026 (7) | **Set de prueba completo, con paridad con Colombia y MODIFICAR.** Se agregaron a `docs/sql/FCDVT-10/pruebas_cargar/` `s04_reemplazo_v1.csv` y `s05_reemplazo_v2.csv` (17-11 T7: 3 Y sin `NRO_Y` y después reemplazo a 2 Y), `s06_numeracion.csv` (17-11 T8: `NRO_Y` [vacío, vacío, 1] → 2, 3 y 1), `s07_modificar.csv` (16-11 T1, después de `s03`: MODIFICAR la Y1 a 700.000 y la Z a 1.150.000), `s08_z_sin_y.csv` (16-11 T7: Y1 automática), `s09_errores.csv` (17-11 T5 MODIFICAR de la Y 7 inexistente, 17-11 T6 mezcla INGRESAR/MODIFICAR y 16-11 T8 fórmula de la Z con diferencia 50.000) y `s10_y_cerrada.sql` (DML por partes para cerrar y reabrir la Y1 de 17-11 T7). `arma_csv.ps1` genera y valida los nueve CSV (74 campos, CRLF, ASCII, Z = ΣY, fórmula en 0 salvo el caso a propósito, y la Z modificada de `s07` contra la Y1 + la Y2 de `s03`); los CSV ya entregados (`s01` a `s03`) salen byte a byte iguales. `LEEME.md` con el orden, dependencias y mensajes esperados. `00_LEEME.md` actualizado. Los terminales nuevos (T7 y T8) estaban libres en test el 18-11-2026; ese día no hubo VPN para re-verificarlos. `MANIFIESTO_FCDVT-14.md5` actualizado (11 entradas: 4 hashes reemplazados y 7 archivos nuevos, comentario «18-11-2026 (7)»). Sin compilar ni ejecutar en la base. |
| 18-11-2026 (8) | **`VTA_SFCLCARGA_YZ_DET` pasa al esquema ancho de Colombia y se elimina `VTA_SFCLCARGA_YZ_DETM`** (§4.2). Se reescribió `02_tablas_carga_yz_sfcl.sql` (identificación + las 63 columnas de concepto de `VTA_PAINT_Z` de test, en el orden de `encabezado.txt` / `paint_z_sfcl.csv`, + `det_total`/`det_estado`/`det_fechahora`); `prc_config` valida nombre y orden de cada columna (ORA-20002) y arma `g_sql_conc`; `prc_inserta_linea` usa un INSERT estático de 63 binds con `v_nconc` (columna nula = no informado); la lectura de montos se unificó en `pr_montos_linea` (usada por `fn_sql_upd_zzz`, `fn_dif_valida_archivo` y la nueva `fn_cant_conceptos`) y `04c` (`fn_venta`) lee la columna de DET por `execute immediate`. Nuevo `07_migra_det_ancha.sql` para el ambiente ya instalado (recrea `DET` con el DDL de `02`, descarta las líneas de prueba y borra `DETM`; después recompilar `03`, `04`, `04b` y `04c`). Actualizados `00_prechecks.sql`, `INSTALAR.sql` («3 tablas»), `06_pruebas.sql` (consulta 6 con los conceptos de venta, 6b `select *` de la línea, 6c control de nombre y orden con `row_number()`), `99_rollback.sql`, `03` (spec) y `prueba_recarga_v1_v2/py0_prechecks.sql`; documentación en `00_LEEME.md`, `FORMATO_CARGA_YZ_SFCL.md`, `sql/CLAUDE.md` y `README_FCDVT-10.md`. **Sin cambio de exe** (ni `Form174`, ni `Form175`, ni `Form176` leen `DETM` o las columnas de concepto) y sin compilar ni ejecutar en la base. `MANIFIESTO_FCDVT-14.md5` recalculado (comentario «2026-11-18 (8)»). |
