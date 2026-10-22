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

**Sin nhal1 ni DBeaver para P1:** el botón **Salir** de `Form174` (cambio temporal del 20-10) hace la prueba **A**: FACO, 31-08-2026, usuario `PROC_CIERRE_DIARIO`, y muestra ejecución, cerradas y no cerradas. Una segunda pulsación equivale a la **C**.

## Si algo falla

- **`ORA-04067 ... package body ... does not exist`** (pasó el 20-10): solo está la spec. Volver a ejecutar `../04_pkg_cierre_diario_body.sql` entero y revisar `user_errors`.

- **`04` no compila (`PLS-00306`):** falta la versión multipaís de `PKG_F8_COMPENSA_DI_CARGA`.
- **`CON_DIFERENCIA_CC`:** la F8 de la Y da 0 pero la grilla de CC no. Comparar `dr_f8` y `dr_cc` en P0. Puede haber sobres `DOL`, euros, tarjetas o conceptos `AL`/`CA` (ver `../00_LEEME.md`).
- **`BLOQUEADA RY-01`:** la gestión de cheques a fecha no coincide con la tesorería del día-terminal. Es el mismo mensaje del botón.
- **`INACTIVO`:** el parámetro 1502 `CD_ACTIVO` no está en S.
