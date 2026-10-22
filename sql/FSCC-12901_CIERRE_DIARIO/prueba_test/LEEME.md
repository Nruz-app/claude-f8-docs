# FSCC-12901 CIERRE_DIARIO: sesión de prueba en test

Usa las cajas que ya existen en test, en el local 6, sin cargar nada nuevo:
- **31-08-2026:** las de las pruebas de COMPENSA_DI;
- **28-08-2026:** las de la prueba 3 de la v2.

Guía imprimible: `docs/PRUEBA_Cierre_Diario_FSCC-12901.pdf`.

Requisitos:
- `PKG_F8_COMPENSA_DI_CARGA` en la versión multipaís;
- `PKG_F8_CIERRE_DIARIO` instalado (`../00_LEEME.md`, "Orden").

## Datos y resultado esperado

| Fecha | Terminal | Y | Hoy | Dif. Real | Esperado |
|---|---|---|---|---|---|
| 31-08-2026 | 24 | 1 | Pendiente | 0 (cuadre) | `CERRADA` |
| 31-08-2026 | 40 | 1 | Pendiente | 0 (DI automática +15.000) | `CERRADA` |
| 31-08-2026 | 31 | 1 | Pendiente | −5.000 | `CON_DIFERENCIA` (RY-05) |
| 31-08-2026 | 29 | 1 | Cerrado | 0 | No entra: ya está cerrada |
| 28-08-2026 | 31 | 1 | Pendiente | −1.500 | `CON_DIFERENCIA` |
| 28-08-2026 | 44 | 1 | Pendiente | +25.000 | `CON_DIFERENCIA` |
| 28-08-2026 | 24, 27, 29, 40 (Y1 y Y2), 41 | — | Cerrado | 0 | No entran |

## Orden

1. **`P0_simulacion.sql`** (solo lectura):
   - estado actual;
   - `fn_evalua_caja` de cada caja, que debe dar el "Esperado" (T24 y T40 del 31-08 `CERRABLE`);
   - otros locales con cajas Pendientes esas fechas: el proceso toma **todos** los locales.
2. **`P1_ejecutar.sql`** (cierra):
   - **A**, 31-08: 2 cerradas y 1 no cerrada;
   - **B**, 28-08: 0 cerradas y 2 no cerradas;
   - **C**, repetir el 31-08: 0 cerradas y 1 no cerrada (T31);
   - **D**, opcional: la llamada sin fecha, como nhal1.
3. **`P2_resultados.sql`** (solo lectura): log por ejecución y estado de las Y.
4. **En pantalla:** Consultas de Cuadratura, local 6, del 28-08-2026 al 31-08-2026. T24 y T40 del 31-08 deben verse **Cerrado**.
5. Para repetir: **`P9_reabrir.sql`** vuelve a Pendiente lo que cerró el proceso. Modifica datos y no hace commit solo.
6. **`P3_sin_venta.sql`** (FCDVT-56, 22-10): la etapa que cierra la **Z** de los terminales sin venta, como "Cerrar Terminal" de CC con la fila "Cierre Y 0". El caso es el de la captura del usuario: local 5, T2, 15-10-2026, todo en 0, Pendiente en rojo.
   - Primero la simulación (bloque 1) y el volumen (bloque 2). La ejecución (bloque 3) cierra los terminales sin venta de **todos** los locales de la fecha.
   - El bloque 5 los reabre en −1.

**Con `CD_SIN_VENTA = S`**, las pruebas A, B y C de P1 también cierran las Z sin venta del 31-08 y del 28-08, y suman esos terminales a "cerradas" y "no cerradas". Para obtener exactamente los números de arriba, ponga antes `CD_SIN_VENTA = N`; si no, compare solo la parte de las Y en la fila `FIN` del log.

**Sin nhal1 ni DBeaver:** el botón **Salir** de `Form174` (cambio temporal del 20-10) ejecuta el proceso para FACO con una fecha fija y el usuario `PROC_CIERRE_DIARIO`, y muestra la ejecución, las cerradas y las no cerradas.
- **La fecha fue el 15-10-2026** (equivalía al bloque 3 de **P3**) y **desde el 22-10 es el 20-08-2026**, para `../../FSCC-12901_COMPENSA_DI/prueba_test4/`. Para probar la etapa sin venta con Salir, vuelva a poner `vFechaPrueba = "20261015"` y recompile, o use el bloque 3 de P3.
- Para repetir la prueba **A** (31-08) hay que volver a poner `vFechaPrueba = "20260831"` y recompilar.

## Si algo falla

- **`ORA-04067 ... package body ... does not exist`** (pasó el 20-10): solo está la spec. Volver a ejecutar `../04_pkg_cierre_diario_body.sql` entero y revisar `user_errors`.

- **`04` no compila (`PLS-00306`):** falta la versión multipaís de `PKG_F8_COMPENSA_DI_CARGA`.
- **`CON_DIFERENCIA_CC`:** la F8 de la Y da 0 pero la grilla de CC no. Comparar `dr_f8` y `dr_cc` en P0. Puede haber sobres `DOL`, euros, tarjetas o conceptos `AL`/`CA` (ver `../00_LEEME.md`).
- **`BLOQUEADA RY-01`:** la gestión de cheques a fecha no coincide con la tesorería del día-terminal. Es el mismo mensaje del botón.
- **`INACTIVO`:** el parámetro 1502 `CD_ACTIVO` no está en S.
- **`INACTIVO SIN_VENTA`** (P3): falta el parámetro `CD_SIN_VENTA` o no está en S. Está en `../02_parametros.sql`.
- **Sin venta `CON_DIFERENCIA_CC`:** ese día el terminal tiene sobres, retiros, dólares, tarjetas o compensaciones, así que la fila "Cierre Y 0" de CC no da 0. Es el mismo criterio del botón.
- **`ESPERA_SOBRES`:** el terminal ya tiene una Y creada en `VTA_FACOTERMSTATY`. La etapa sin venta no lo toma (decisión del 22-10).
