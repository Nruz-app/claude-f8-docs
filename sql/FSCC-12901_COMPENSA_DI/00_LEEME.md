# FSCC-12901 COMPENSA_DI: compensación automática de DI al cargar sobres (multipaís; habilitado: Colombia, FACO)

Creada el 19-10-2026. Reemplaza el modelo de `FSCC-12901_PROC_Y` (v2, traspasada a test el 14-10), en el que la carga de sobres además cerraba la Y.

## Modelo (reunión con el usuario de negocio, 19-10-2026)

1. **Carga de sobres (`Form133`)**: no cierra la caja. Por cada caja (fecha de venta, local, terminal, Y) del Excel, se calcula la **diferencia real** de la F8 de la Y con **todos** sus sobres.
   - Si está entre **−1.000 y +20.000** (límites incluidos) y no es 0, se registra una **DI (Diferencia No Imputable)** por el **valor exacto y con el mismo signo** (+500 → DI +500; +15.000 → DI +15.000).
   - La DI se graba igual que la manual (`Form38`): regularizada, se ve en "Compensado" de `Form4` y la Dif. Real queda en 0.
   - Observación: `COMPENSACION AUTOMATICA DI` (en mayúsculas, como la guarda `Form45`). Hasta el 20-10 era `COMPENSACION AUTOMATICA DIFERENCIA DE DI`.
   - La caja queda **Pendiente**: no se cierra.
2. **Cierre**: un **cron diario** cerrará las cajas sin diferencia, igual que "Cerrar Terminal" de `Form43`. **Pendiente**: se diseña después.

Reglas decididas:

| Caso | Qué hace |
|---|---|
| Recarga: la caja ya tiene DI automática y llega otra carga | Se **recalcula**: borra la DI automática anterior y su observación, evalúa de nuevo con todos los sobres y, si sigue en el rango, registra la DI nueva |
| La caja tiene una DI manual (`Form38`) | No se toca (`DI_MANUAL_PREVIA`) |
| Caja cerrada | No se toca (`YA_CERRADA`) |
| Y no ingresada todavía | `SIN_TERMSTAT` / `SIN_LIBVTA`, sin DI. Ingresar la Y **antes** de cargar |
| Sobre sin Y (`prv_cierrey = 0`) | `SIN_Y` |

## Archivos

| Script | Tipo | Qué hace |
|---|---|---|
| `00_prechecks.sql` | Lectura | Objetos de v1/v2/YZ existentes, jobs, sinónimos, parámetros 1502, opción 1515, objetos que usa el paquete y datos que dejaron las pruebas |
| `01_DESINSTALAR_v2.sql` | Borrado | **Respalda** la cola y el log (`VTA_FACOPRD_CIERRE_BK`, `VTA_FACOLOG_CIERRE_AUTO_BK`). Después borra el trigger, los paquetes v2/v1, la vista v1, la cola, el log, las secuencias, los parámetros 1502 `CA_%` y la opción 1515. Es idempotente. Parte 2: sinónimos (DBA). No toca DI ni Y ya grabadas |
| `02_log_compensa_di.sql` | Objeto | `VTA_FACOLOG_COMPENSA_DI` + secuencia: una fila por caja evaluada |
| `03_parametros.sql` | Datos | 1502: `CA_DI_ACTIVO` S, `CA_DI_MIN` −1000, `CA_DI_MAX` 20000, `CA_DECIMAL` 0 |
| `04` / `05` | Paquete | `PKG_F8_COMPENSA_DI_CARGA` (spec / body). Multipaís desde el 20-10 |
| `anterior_20-10/` | Referencia | `04` y `05` del 19-10 (solo FACO, SQL estático), la versión probada en test. No se ejecutan: sirven para comparar o volver atrás |
| `06_grants_sinonimos.sql` | Permisos | `UINTRANETTS` (parte B como DBA) |
| `07_pruebas.sql` | Pruebas | Escenarios A–G, simulación sin grabar y llamada manual por caja |
| `08_cambio_glosa_20-10.sql` | Datos | 20-10: pasa las observaciones ya grabadas a la glosa nueva `COMPENSACION AUTOMATICA DI`. Ejecutar después de recompilar 04 y 05. Sin commit automático |
| `99_rollback.sql` | Reversión | 1 apagar, 2 borrar las DI automáticas de un rango (solo cajas abiertas), 3 desinstalar |
| `INSTALAR.sql` | — | 02 → 05 + estado (SQL*Plus) |
| `FORM133_cambios.md` | Documento | Cambio del exe para llamar al paquete por caja (aplicado el 19-10; el 20-10 se agregó el país en la llamada, **sin compilar**) |
| `prueba_test/` | Prueba | Sesión de prueba en test: local 6, 31-08-2026. Cuatro pruebas: 1 DI negativa (T29, −800), 2 DI positiva (T40, +15.000), 3 sin DI fuera de rango (T31, −5.000) y 4 caso normal (T24, DR 0). Un Excel por prueba, el resumen por bloques, P0, P2 y P9 (ver su `LEEME.md`) |
| `prueba_test_6locales/` | Prueba | Las mismas 4 pruebas con 6 locales por archivo (6, 18, 25, 35, 36 y 38; 24 cajas), el 30-08-2026, con montos que prueban los límites (−1.000 y +20.000 dentro; −1.001 y +20.001 fuera). Un Excel de 12 sobres por prueba, el resumen, P0, P2 y P9 (ver su `LEEME.md`) |
| `prueba_test2/` | Prueba | Las mismas 4 pruebas y montos de `prueba_test/`, pero **cada prueba en otro local** y el 10-09-2026 (agosto ya tenía muchas pruebas): 1 DI negativa (local 5, T27, −800), 2 DI positiva (local 25, T12, +15.000), 3 sin DI (local 18, T10, −5.000) y 4 caso normal (local 19, T5, DR 0). Ese día test no tiene datos FACO. Un Excel por prueba, el resumen, P0, P2 y P9 (ver su `LEEME.md`) |
| `prueba_test3/` | Prueba | Réplica de `prueba_test2/` para la demostración al usuario, el **17-09-2026**: mismos locales, terminales y montos (1 local 5 T27 −800, 2 local 25 T12 +15.000, 3 local 18 T10 −5.000, 4 local 19 T5 DR 0), sobres `<local><terminal>0917<n>`. Incluye el cierre con el botón Salir de `Form174` (`vFechaPrueba = "20260917"`): esperado 3 cerradas y 1 no cerrada (18/10). Excel, resumen, P0, P2 y P9 (ver su `LEEME.md`) |
| `prueba_test4/` | Prueba | Del 22-10-2026: réplica de `prueba_test3/` el **20-08-2026**, con los mismos 4 escenarios y sobres `<local><terminal>0820<n>`. Salir de `Form174` usó `vFechaPrueba = "20260820"` hasta el 26-10. La fecha **no está verificada como limpia**: correr antes P0. Con `CD_SIN_VENTA = S` el cierre también cierra las Z sin venta del día (ver su `LEEME.md`) |
| `prueba_test5/` | Prueba | Del 26-10-2026: réplica de `prueba_test4/` el **15-09-2026**, con los mismos 4 escenarios y sobres `<local><terminal>0915<n>`. Salir de `Form174` usa `vFechaPrueba = "20260915"`. **El 15-09 ya tiene datos FACO en test**: correr antes P0; el cierre con Salir puede contar también otras Y del día (ver su `LEEME.md`) |
| `prueba_test6/` | Prueba | Del 28-10-2026: réplica de `prueba_test5/` el **14-10-2026**, con los mismos 4 escenarios y sobres `<local><terminal>1014<n>`. Salir de `Form174` usa `vFechaPrueba = "20261014"`. **No se verificó si el 14-10 tiene datos FACO en test** (sin VPN): correr antes P0; el cierre con Salir puede contar también otras Y del día (ver su `LEEME.md`) |

## `PKG_F8_COMPENSA_DI_CARGA`

| Rutina | Uso |
|---|---|
| `prc_compensa_caja(pais, fecha, local, terminal, Y, usuario, OUT resultado, OUT monto_di, OUT mensaje)` | La llama `Form133` por caja. Hace commit. No propaga errores (`ERROR` + mensaje) |
| `fn_evalua(pais, fecha, local, terminal, Y)` | Resultado que daría, sin grabar (se puede usar en un `SELECT`) |
| `fn_dif_real(pais, ...)` / `fn_dif_real_sin_di(pais, ...)` | DR actual / DR sin la DI automática (la que se compensaría) |
| Las mismas sin `pais` | Compatibilidad: equivalen a `'FACO'` |

- La DR es la misma consulta de `PKG_F8_CIERRE_AUTO.pr_cuadratura` (v2), validada en las pruebas 1 a 3 de test, con las tablas del país (`VTA_<pfx>*`).
- La DI replica `Modulo1.InsertarRegistroMovDet`: `mov_regul` S, `mov_fechareg` = fecha de venta, secuencia del país (FACO: `SEQ_VTA_FACOVEN`), `mov_hechopor` = `PROC_DI_AUTO`.
- Después de grabar, controla que la DR quede en 0; si no, deshace todo (`ERROR`).

Resultados posibles: `DI_REGISTRADA`, `DR_CERO`, `FUERA_RANGO`, `DI_MANUAL_PREVIA`, `SIN_LIBVTA`, `SIN_TERMSTAT`, `YA_CERRADA`, `OCUPADA`, `SIN_Y`, `INACTIVO`, `ERROR`.

## Multipaís (20-10-2026)

El paquete recibe el país primero (`p_flg_pais` = `Flg_Pais$` del exe) en las cuatro rutinas públicas: `prc_compensa_caja`, `fn_evalua`, `fn_dif_real` y `fn_dif_real_sin_di`.

- **Lista blanca:** `pr_config` (body) define cada país habilitado con su prefijo de tablas y sus literales: tabla de estado (`TERMSTATY`), nivel del libro de ventas (`Y`), rango de tarjetas (2000-2999), moneda dólar (305), secuencia del techkey (`SEQ_VTA_FACOVEN`) y filtro de `DIFVEND`. El texto recibido nunca se concatena en el SQL. Un país no habilitado da `ORA-20001`; en `prc_compensa_caja` vuelve como `ERROR`, sin log.
- **SQL dinámico:** las consultas son las mismas que antes, escritas con marcas (`VTA_{P}MOVDET`, `{EST}`, `{NIVEL}`, `{TMIN}`, `{TMAX}`, `{USD}`, `{SEQMOV}`, `{FVEN}`) que `fn_r` reemplaza. Lecturas con `DBMS_SQL` y binds por nombre; escrituras con `execute immediate ... using`. Es el patrón de la v2 (`FSCC-12901_PROC_Y/07_pkg_cierre_auto_body.sql`).
- **Habilitado:** solo FACO.
- **Compatibilidad:** se mantienen las firmas sin país, que equivalen a `'FACO'`. El exe compilado antes del 20-10 y los scripts viejos siguen funcionando.
- **Efecto del SQL dinámico:** el paquete ya no depende de las tablas al compilar. Si falta una tabla o un permiso, el error aparece al ejecutar (`ERROR` en el log), no como paquete `INVALID`.

**Para habilitar otro país** (hay un ejemplo comentado en `pr_config`):
1. Crear `VTA_<pfx>LOG_COMPENSA_DI` y `SEQ_VTA_<pfx>LOG_COMPENSA_DI` (`02` con el prefijo) y los parámetros 1502 en `VTA_<pfx>PARAM` (`03`).
2. Revisar contra el exe sus diferencias de cuadratura (`Form3Y`, `Modulo1.StrSumCompensado`): tarjetas, moneda, filtro de `DIFVEND` y conceptos del compensado.
3. Confirmar la secuencia del techkey (`Modulo1.InsertarRegistroMovDet`) y el trigger de `VTA_<pfx>COMPDES`.
4. Agregar la rama en `pr_config`, recompilar `05` y, en `Form133`, llamar también para ese `Flg_Pais$`.

**Actualizar test con la versión multipaís** (el paquete ya instalado): ejecutar `04` y después `05`, revisar `user_errors` (paquete `VALID`) y correr el bloque 8 de `07_pruebas.sql`. No volver a correr `INSTALAR.sql`.

## Orden (test, conectado como `INTRANETTS`)

1. `00_prechecks.sql`: revisar qué existe y si hay un job (consulta 3).
2. `01_DESINSTALAR_v2.sql`: parte 1 como dueño y parte 2 (sinónimos) como DBA. Verificación (i).
3. `INSTALAR.sql`, o en DBeaver 02 → 03 → 04 → 05. Revisar `user_errors`.
4. `06_grants_sinonimos.sql`.
5. `07_pruebas.sql`: sin el cambio de `Form133`, cargar el Excel y llamar al paquete a mano (bloque 3).

**Cambio de glosa (20-10-2026), con el paquete ya instalado:** ejecutar `04` y después `05` (al cambiar la spec el body queda inválido), revisar `user_errors` y luego `08_cambio_glosa_20-10.sql`. No volver a correr `INSTALAR.sql`: el 02 crea la tabla de log y fallaría.

**Atención:** entre el paso 2 y la compilación del exe con `FORM133_cambios.md`, toda carga FACO en test muestra el error de `PKG_F8_CIERRE_AUTO`. Los sobres sí quedan cargados.

## Pendiente

- ~~Aplicar y compilar el cambio de `Form133`~~: hecho. La versión solo FACO está instalada en test y las pruebas 1 a 4 dieron OK el 20-10.
- Pasar a test la versión **multipaís** (`04` → `05`, bloque 8 de `07_pruebas.sql`) y recompilar `Form133` con la llamada con país.
- El **cron de cierre diario** está en `../FSCC-12901_CIERRE_DIARIO/` (20-10) y usa `fn_dif_real(pais, ...)` de este paquete: por eso necesita la versión multipaís.
- Convenciones: ASCII, sin prefijo de esquema, sin `&`, Oracle 10.2. Los scripts los compila y ejecuta el usuario.
