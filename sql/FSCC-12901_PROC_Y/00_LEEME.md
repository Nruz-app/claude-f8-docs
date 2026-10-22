# FSCC-12901 v2: cierre automático y DI automática multipaís

Versión **multipaís** de los objetos de FSCC-12901, creada el 13-10-2026. Colombia (`FACO`) es el único país habilitado y conserva **la misma lógica** que v1. La versión 1 queda intacta en:
- `docs/sql/FSCC-12957/`, `docs/sql/FSCC-12958/` y `docs/sql/FSCC-12901_T1_T2/` (scripts de instalación);
- `docs/sql/FSCC-12901_POC/` (prueba de concepto).

## Qué cambia frente a v1

| Tema | v1 | v2 |
|---|---|---|
| Paquetes | `PKG_F8_FACO_CIERRE_AUTO`, `PKG_F8_FACO_COMPENSA_DI` | `PKG_F8_CIERRE_AUTO`, `PKG_F8_COMPENSA_DI_AUTO` (uno por base, para todos los países). Se eligió un nombre distinto del `PKG_F8_COMPENSACION_DI` de Chile para no chocar. |
| País | Fijo (FACO) | Primer parámetro **`p_flg_pais`** de todas las rutinas públicas: el mismo valor que `Flg_Pais$` del exe |
| Tablas | `VTA_FACO*` fijas en el SQL | `VTA_{P}…` con el prefijo del país, en SQL dinámico con binds, igual que `"vta_" & Flg_Pais$ & "…"` en VB6 |
| Particularidades del país | Fijas en el código | `pr_config`: prefijo, `vta_localiz`, nivel de cierre (Y), rango de tarjetas (2000–2999), dólar (305), secuencia de `MOVDET`, modo del universo |
| País no configurado | — | ORA-20001 "Pais no habilitado para cierre automatico" |
| Universo | Vista `VTA_FACOV_CAJAS_CIERRE` + ventana `CA_DIAS` (30 días, la caja se reevalúa en cada ejecución) | **Carga del día**: cada ejecución toma la cola (`P` → `E`), la evalúa una vez y la deja en `C`. Sin `CA_DIAS` y sin vista: el universo lo arma `fn_universo` |
| Estados de la cola | P / C / O / V | P / **E** / C / O (V solo en las filas históricas si se migra desde v1) |
| Cálculo de la DR, compensado, reglas RY, registro de la DI, log y savepoints | — | **Sin cambios** (se copiaron línea a línea; solo cambian las tablas) |

### Una ejecución por carga (Colombia)
1. Un sobre cargado con `Form133` (u otra vía) pasa al trigger, que lo deja en la cola `VTA_FACOPRD_CIERRE` en estado **P**.
2. El job ejecuta `PKG_F8_CIERRE_AUTO.prc_cierre_automatico('FACO')`:
   - marca los sobres sin cierre Y como **O**;
   - **toma la carga**: lo que está en P (o quedó en E por una ejecución interrumpida) pasa a **E**, con el número de esta ejecución. Lo que llegue mientras corre queda en P para la próxima;
   - T1 (DI) y T2 (cierre Y) evalúan las cajas de esa carga, más las cajas sin sobre del mismo local y día (`CA_SIN_SOBRE`);
   - cada caja evaluada queda en **C** con su resultado. Hay dos excepciones: `OCUPADA` (bloqueada por un usuario) vuelve a P, y lo que no alcanzó a evaluarse por `p_max_cajas` vuelve a P;
   - si T2 está apagado, la carga queda en C con el resultado `SOLO_T1`.
3. Una segunda ejecución sin carga nueva no evalúa nada. La caja vuelve a evaluarse solo si recibe un sobre nuevo.

El botón "Cerrar Terminal" de `Form43` llama a `prc_cierre_dia`, que cierra **un solo día**: la fecha de venta, el local y el terminal elegidos en la pantalla. Reemplaza al `prc_cierre_rango` de v1, porque el DF-SCC no pide un rango de fechas y `Form43` ya esperaba un día por vez ("Seleccione Día de Cierre de Terminal").

## Cómo se agregaría otro país (ejemplo: Chile, NO habilitado)
Para Chile no se crea nada. Si en el futuro se quisiera habilitarlo:
1. **Configuración:** en `07_pkg_cierre_auto_body.sql` → `pr_config`, descomentar y completar el bloque de ejemplo (prefijo vacío → `VTA_TERMSTATY`, `VTA_PRD`…).
2. **Comparar con el exe:** revisar sus diferencias de cuadratura (consulta del compensado, tarjetas, Z/Y). Si cierra por Z, agregar `pr_procesa_z`. Si usa una ventana de días, implementar el modo `DIAS` en `fn_universo` (fecha de proceso − `CA_DIAS`).
3. **Objetos del país:** crearlos copiando `01_cola_FACO.sql`, `02_log_FACO.sql`, `03_parametros_FACO.sql`, `03c_permiso_FACO.sql` y `08_trigger_FACO.sql`, con FACO reemplazado por su prefijo.
4. **Exe:** extender en `Form43` la condición `Flg_Pais$ = "FACO"` (ver `FORM43_cambios_v2.md`).

## Archivos

| Script | Tipo | Qué hace |
|---|---|---|
| `00_prechecks.sql` | Lectura | Verificaciones (sin SET ni PROMPT, sirve en DBeaver) |
| `00b_DESINSTALAR_TODO.sql` | Reversion | Borra TODO lo de FSCC-12901 en la base (v1, v2, POC, efectos del proceso, parametros 1502, opcion 1515) para instalar v2 desde cero |
| `01_cola_FACO.sql` | País | Cola + secuencia (estados P/E/C/O) |
| `02_log_FACO.sql` | País | Log + secuencia (igual que v1) |
| `03_parametros_FACO.sql` | País | Parámetros 1502 **sin `CA_DIAS`** |
| `03c_permiso_FACO.sql` | País | Opción 1515 (igual que v1) |
| `04` / `05` | Genérico | Especificaciones de `PKG_F8_CIERRE_AUTO` y `PKG_F8_COMPENSA_DI_AUTO` |
| `06` / `07` | Genérico | Cuerpos (06 T1, 07 T2; 07 llama a T1) |
| `08_trigger_FACO.sql` | País | Trigger de la cola (igual que v1) |
| `09_grants_sinonimos.sql` | — | Permisos; reemplazar `USUARIO_APP` / `DUENIO` |
| `10_pruebas.sql` | Pruebas | Incluye paridad v1 = v2 y "segunda ejecución no evalúa nada" |
| `99_rollback.sql` | Reversión | Apagar, revertir una ejecución (bloque EDITAR) o desinstalar |
| `INSTALAR.sql` | — | Instalación en una base **sin v1** (SQL*Plus) |
| `MIGRAR_DESDE_V1.sql` | — | Base **con v1** (desarrollo): agrega el estado E y compila 04–07. No borra nada de v1 |
| `MIGRAR_99_volver_v1.sql` | Reversión | Deshace la migración |
| `FORM43_cambios_v2.md` | Documento | Cambios VB de `Form43` para v2 (no aplicados) |
| `poc/` | POC | Copia de la POC adaptada a v2 (mismo orden y escenarios; `01` ya no toca `CA_DIAS`) |
| `prueba4_test/` | Prueba | Demostración al usuario: las 4 cajas de `prueba3_test` en T25/T42/T32/T45, 29-08-2026. `P0_prechecks.sql`, Excel de carga, resumen y `P2_resultados.sql` (ver su `LEEME.md`) |

## Orden

**Desarrollo (v1 ya instalado), en DBeaver con Alt+X:**
1. `00_prechecks.sql`: los objetos de FACO aparecen como existentes; es lo esperado.
2. `MIGRAR_DESDE_V1.sql`, y luego `04` → `05` → `06` → `07`. Revisar `user_errors`.
3. `10_pruebas.sql`, bloques 1 a 7. La prueba **3b** debe dar 0 filas: la DR de v1 y la de v2 coinciden.
4. POC: `poc/01` → `02` → `03` → `04` → `05` → `06` → `07` (columna "diferentes" en 0). Prueba manual: `poc/manual/M1` → carga por `Form133` → `poc/06` → `M2`.
5. `10_pruebas.sql` bloques 9b y 9c: la cola de la carga queda en C y una segunda ejecución evalúa 0 cajas.

**Base nueva (sin v1):** `INSTALAR.sql` y después el paso 09.

**Reinstalar desde cero (desarrollo):** primero `00b_DESINSTALAR_TODO.sql`. Después: `00` → `01` → `02` → `03` → `03c` → `04` → `05` → `06` → `07` → `08` (o `INSTALAR.sql`). En este camino **no** se usa `MIGRAR_DESDE_V1.sql`.

## Cuidados
- No ejecutar a la vez el job de v1 (`PKG_F8_FACO_CIERRE_AUTO`) y el de v2 sobre la misma cola.
- El job pasa a ser: `begin PKG_F8_CIERRE_AUTO.prc_cierre_automatico(p_flg_pais => 'FACO'); end;`
- Se mantienen las convenciones: scripts en ASCII, sin prefijo de esquema, sin `&`, compatibles con Oracle 10.2 (q-quote `q'[...]'` y `DBMS_SQL`, ambos disponibles en 10g). No se guardan claves.
- **No probado en la base:** todo esto se entrega como scripts. Compilar y ejecutar lo hace el usuario en desarrollo.
