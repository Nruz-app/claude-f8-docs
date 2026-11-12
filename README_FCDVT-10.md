# FCDVT-10 — HU-03: ingreso masivo de cierres de caja F8, Tottus Chile (SFCL)

Historia padre: FSCC-13183 ([SCCFIN] Mejoras Legado F8 y Control de Ventas). Subtareas: FCDVT-11 (habilitar con sus conceptos), FCDVT-12 (ingresar las Y y la Z), FCDVT-13 (modificar conceptos de una Y). Estado en Jira: Refining.

## 1. Estado (11-11-2026)

| Parte | Estado |
|---|---|
| Scripts de base (`docs/sql/FCDVT-10/`) | Escritos y revisados con `sql-lint`; **sin compilar ni ejecutar** (no hubo conexión a test) |
| Exe: `MDIForm1.frm`, `Form174.frm` | Editados (respaldos `.bak_FCDVT-10`), sincronizados en `docs/Cambios/`; **sin compilar** |
| `Form175.frm` | Sin cambios: lee `VTA_<pfx>CARGA_YZ_LOG/DET` con columnas que también tienen las tablas de SFCL |
| CSV de prueba | Se generan con `docs/sql/FCDVT-10/prueba_recarga_v1_v2/arma_prueba.py` a partir de `VTA_PAINT_Z` exportado de test (prueba de recarga v1/v2, 12-11-2026); pendiente correrlo |

## 2. Artefactos

- Fuentes del requerimiento: `docs/Requerimiento-FCDVT-10/` (`FCDVT-10.doc` es la exportación HTML de Jira; BPMN AS-IS/TO-BE de HU-03; captura de Form19Y en Tottus). El DF con la plantilla de Tottus está en `docs/Requerimiento-FCDVT-14/DF-SCC-vf_24.03.2025 Ingreso Cierre de caja F8.xlsx` (hoja F8-LV-CMP-TES, filas 31 a 35 y 47 a 50).
- Scripts: `docs/sql/FCDVT-10/` (índice `00_LEEME.md`, formato `FORMATO_CARGA_YZ_SFCL.md`).
- Prueba de recarga v1/v2: `docs/sql/FCDVT-10/prueba_recarga_v1_v2/` (índice `LEEME.md`). Generador `arma_prueba.py` + plantillas de `py2`/`py9`; ver §7.
- Exe: `FTEPROD/MDIForm1.frm`, `FTEPROD/Form174.frm`; detalle en `docs/Cambios/README.md` §2.3 y §2.4.

## 3. Decisiones del usuario (11-11-2026)

1. **Packages nuevos para SFCL** (`PKG_F8_CARGA_MASIVA_YZ_SFCL`, `PKG_F8_GRABA_MASIVA_YZ_SFCL`) con las mismas firmas que los de FACO; FACO no se toca. Motivo: los packages de FCDVT-14 tienen las columnas de conceptos de FACO fijas, y `VTA_SFCLZZZ` / `VTA_SFCLLIBVTA` tienen otras.
2. **La Z viene en el archivo** (como FACO y la plantilla del DF) y se valida Z = ΣY. La HU decía "el Z se calcula a partir de las Y"; se siguió el DF.
3. **MODIFICAR entra en esta entrega** (HU-03.3): vacío = no cambia.
4. **Y1 automática como Form19**: se crea cuando el grupo INGRESAR trae la Z sin Y.

Decisión técnica (sin conexión para leer `VTA_PAINT_Z`): los conceptos se leen de `VTA_PAINT_Z` en tiempo de ejecución, igual que Form19Y. El encabezado del CSV lo da `fn_encabezado` y Form174 lo pide a la base.

## 4. Diseño

- Buscar: `PKG_F8_CARGA_MASIVA_YZ_SFCL` (`prc_inicia` → `prc_inserta_linea` → `prc_procesa`) sobre `VTA_SFCLCARGA_YZ_DET/DETM/RES/LOG`. Valida líneas, terminal vigente y no cerrado, `NRO_Y` repetido, MODIFICAR sobre cierres existentes y abiertos, y por grupo: 1 Z, Z = ΣY (venta = filas 2 a 6 de `VTA_PAINT_Z`), fórmula de la Z (`vta_validadorzzz`), sin Y cerradas en INGRESAR, sin mezcla INGRESAR/MODIFICAR.
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

Quedan como diferencias conocidas: `vta_secuencia_srx` de las Y = SECUENCIA (Form19Y graba la hora); el ejemplo de la hoja Instrucciones no trae formas de pago, así que copiado tal cual queda descuadrado por la fórmula de la Z.

## 5. Pendientes

1. Ejecutar `docs/sql/FCDVT-10/00_prechecks.sql` en test y guardar la salida aquí (sobre todo §1: conceptos y filas 2 a 7).
2. `INSTALAR.sql` en test (compilación de los dos packages; sin `user_errors`).
3. Compilar el exe y probar en test (casos en `docs/sql/FCDVT-10/00_LEEME.md`), más la regresión FACO.
4. Armar los CSV de prueba con el encabezado real: exportar `VTA_PAINT_Z` (py0 consulta 3 de `prueba_recarga_v1_v2/`) y correr `arma_prueba.py`. Esa carpeta trae la prueba de recarga v1/v2 (misma de FCDVT-14 sesión 7, sin DI): INGRESAR v1 > INGRESAR v2 y Z sin Y (Y1 automática) v1 > v2.
5. Confirmar con negocio: perfiles del permiso 460 en SFCL (hoy, los mismos que el 15); DUD-047 (`vta_traspasado_por = 'C_MASIVA'`) y el reflejo en LVTA / CMP, que no se implementan.
6. Paso a producción: ver `docs/Cambios/README.md` §3 (incluye `Gversion`).

## 6. Cómo retomar

Leer este archivo, `docs/sql/FCDVT-10/00_LEEME.md` y `docs/Cambios/README.md` §2.3 y §2.4. Los packages de FACO quedan en `docs/sql/FCDVT-14/` y no se tocan.

## 7. Historial

| Fecha | Cambio |
|---|---|
| 11-11-2026 | Scripts de `docs/sql/FCDVT-10/` (packages `_SFCL`, tablas, menú 460, pruebas, limpieza y rollback), `Form174` y `MDIForm1` (respaldos `.bak_FCDVT-10`, `docs/Cambios/` sincronizado) y revisión de `f8-revisor` (§4). Sin compilar ni ejecutar. |
| 12-11-2026 | **Prueba de recarga v1/v2** (`docs/sql/FCDVT-10/prueba_recarga_v1_v2/`), la misma de FCDVT-14 sesión 7 sin DI ni sobres (en SFCL la DI automática no está habilitada). Como el encabezado depende de `VTA_PAINT_Z`, el usuario eligió un **generador**: `py0` exporta `VTA_PAINT_Z` y `fn_encabezado`, y `arma_prueba.py` replica `prc_config`, arma `carga_v1.csv`/`carga_v2.csv` (venta en BOLETAS y una columna de pago que cuadra la fórmula de la Z), `py2`/`py9` y el Excel de resumen. Escenarios: INGRESAR v1 → INGRESAR v2 (TA: Z + Y1; TB: 2 Y → 1 Y) y Z sin Y con Y1 automática (TC: Z sin Y → Z sin Y; TD: 2 Y → Z sin Y). Esperado según `pr_graba_ingresar`: queda v2 y las Y de v1 que v2 no trae se borran. Verificado en el trigger `TRG_VTA_SFCLZZZ_I`: el insert de la zzz de la Z borra `VTA_SFCLTARJ` 2001-2999 y los 'AL' del terminal-día, y cada Y los recrea (no deberían quedar huérfanas; `py2` D1 lo comprueba). Generador probado offline con un `VTA_PAINT_Z` ficticio; sin ejecutar en test. |
