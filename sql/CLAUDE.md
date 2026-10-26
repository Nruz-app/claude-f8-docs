# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Complementa `../../CLAUDE.md` (sobre todo §9, que se aplica completo). Aquí solo va lo propio de `docs/sql/`.

## Ejecución

- No hay build ni tests. Los scripts los ejecuta el usuario; Claude solo hace consultas de lectura (test requiere VPN Fortinet).
- SQL*Plus, desde la carpeta del ticket y conectado como dueño de las tablas `VTA_*`: `sqlplus <usuario>@<base> @INSTALAR.sql`. En DBeaver se ejecuta cada script en orden con Alt+X.
- `INSTALAR.sql`: `set echo on`, `whenever sqlerror exit failure rollback`, los `@NN_...` en orden y al final una consulta a `user_objects` (todo `VALID`) y `user_errors`. FSCC-12948 no usa `whenever sqlerror`.
- `00_prechecks.sql` es solo lectura. En `FSCC-12901_PROC_Y/` y `PROC_YZ/` va **sin `SET` ni `PROMPT`** para que corra en DBeaver; en las demás carpetas usa `prompt`.
- Grants y sinónimos (`09_grants_sinonimos.sql` o equivalente) se ejecutan aparte; hay que reemplazar `USUARIO_APP` / `DUENIO`.

## Convenciones observadas

- Los `.sql` son ASCII puro (sin tildes: "duenio", "Instalacion"). Los índices `.md` (`README.md`, `00_LEEME.md`, `traspaso_test/LEEME.md`) sí están en UTF-8 con tildes.
- Desde v2 (FSCC-12901 PROC_Y en adelante) no se usan variables de sustitución `&`: los valores que hay que completar a mano van en un bloque `declare` marcado `-- EDITAR`. Los scripts v1 (`FSCC-12957`, `FSCC-12958`, `T1_T2`) todavía usan `&ejecucion`, `&usuario_app`.
- SQL dinámico con binds por nombre (`DBMS_SQL`) y q-quote `q'[...]'`, ambos válidos en Oracle 10.2. En PROC_Y las tablas por país se escriben con marcas `VTA_{P}...`, `{NIVEL}`, `{USD}`, etc., que `FN_R` reemplaza según `pr_config` (`07_pkg_cierre_auto_body.sql`).
- Encabezado de cada script: bloque `-- ====` con ticket, versión, número de paso, objeto, fuente si es copia y referencias al exe con línea (`Form3Y.CierraTerminal :2801`).
- Numeración de archivos: `00_prechecks`, `00b_DESINSTALAR_TODO`, `01..08` (objetos por país con sufijo `_FACO`; genéricos, uno por base, sin sufijo), `09_grants_sinonimos`, `10_pruebas`, `99_rollback`. `99_rollback.sql` se ejecuta **por partes**: 1) apagar con los parámetros tipo 1502 de `VTA_<pfx>PARAM` (`CA_ACTIVO`, `CA_DI_ACTIVO` = `'N'`), 2) revertir una ejecución, 3) desinstalar.
- Subcarpetas recurrentes:
  - `traspaso_test/`: un único `TRASPASO_TEST_*.sql` + `ROLLBACK_TEST_*.sql` + `LEEME.md` para entregar a test;
  - `poc/`, `manual/` (`M1`/`M2`/`M9`), `prueba*/`: escenarios de prueba y evidencias en Excel;
  - `ddl_actual_desarrollo/` y `anterior_<fecha>/`: línea base o versión congelada. **No se ejecutan**; sirven para comparar y para armar el rollback.

## Carpetas y vigencia (al 20-10-2026)

| Carpeta | Qué es | Estado |
|---|---|---|
| `FSCC-12957/`, `FSCC-12958/` | v1 FACO, T1 (DI) y T2 (cierre) por separado | Histórico, no tocar |
| `FSCC-12901_T1_T2/` | v1 FACO consolidada (`PKG_F8_FACO_*`) | Histórico, no tocar |
| `FSCC-12901_COMPENSA_DI/` | Modelo 19-10: DI automática al cargar sobres, sin cierre (`PKG_F8_COMPENSA_DI_CARGA`, multipaís desde el 20-10 con marcas `{P}` como PROC_Y), y borrado de la v2 | **Vigente**, probado en test (versión solo FACO); la multipaís, sin ejecutar |
| `FSCC-12901_CIERRE_DIARIO/` | Cron de cierre diario (`PKG_F8_CIERRE_DIARIO`, lo llama nhal1; simula "Cerrar Terminal" de CC), multipaís (FACO) | **Vigente**, instalado en test por el usuario el 20-10 (spec recompilada el 22-10); cron en nhal1 pendiente; requiere COMPENSA_DI multipaís |
| `FSCC-12901_PROC_Y/` | v2 multipaís, solo cierre Y (en test desde el 14-10) | Reemplazada por COMPENSA_DI |
| `FSCC-12901_PROC_YZ/` | Copia de PROC_Y con la Z apagada | Reemplazada |
| `FSCC-12901_POC/` | POC con datos reales en INTRANETDE | Referencia |
| `FSCC-12948/` | `PKG_TRANSACC_DEPO_QUEUE` + trigger (cola Prosegur) | Listo, sin ejecutar |
| `FCDVT-14/` | Carga masiva Z/Y: `00_prechecks.sql`, `01_menu_ingreso_masivo_y.sql` (permiso 460 del submenú de Y en FACO), `99_rollback.sql`, `00_LEEME.md` y copias de la plantilla CSV y su `FORMATO` | En desarrollo; `01` ejecutado en test el 20-10 (falta producción) |

Antes de editar, leer `docs/README_<ticket>.md` y el `README.md` / `00_LEEME.md` de la carpeta: ahí están el orden de ejecución y lo que ya se probó.

## Copias

Un mismo script vive en varias carpetas (`PROC_Y` ↔ `PROC_YZ` ↔ `traspaso_test/` ↔ `poc/`). Al cambiar uno, actualizar todas las copias, su encabezado de fuente y la tabla del índice; si hay un hito cerca, regenerar el manifiesto MD5 (ver §9 de la raíz).
