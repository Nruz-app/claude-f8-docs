# FSCC-12901 — Prueba 4 en test (demostración al usuario)

> **OBSOLETA desde el 19-10-2026.** El modelo cambió: la carga de sobres ya no cierra la Y y solo registra la DI automática. Ver `docs/sql/FSCC-12901_COMPENSA_DI/`. Los Excel de esta carpeta se pueden reutilizar para probar el modelo nuevo.

Repite la prueba 3 (`../prueba3_test/`, OK el 16-10-2026) con **terminales y fecha nuevas**, para mostrar al usuario el cierre automático de la Y en Colombia (`FACO`): `Form133` carga los sobres y llama a `PKG_F8_CIERRE_AUTO.prc_cierre_automatico('FACO')`.

Los montos y el resultado esperado son los mismos que en la prueba 3. Cambian:
- las terminales: 24 → 25, 41 → 42, 31 → 32 y 44 → 45;
- los números de sobre: son nuevos, todos de prueba, con el patrón terminal + `0829` + correlativo;
- la fecha de venta: 28-08-2026 → **29-08-2026**. Las Y de la T31 y la T44 siguen abiertas el 28-08, y con `CA_SIN_SOBRE = S` el paquete las volvería a evaluar en la demostración (hallazgo H1).

## Datos (local 6, 29-08-2026, Y 1)

| # | Escenario | Terminal | Archivo | Sobres | Total sobres | EFECTIVO = BOLETAS en Form19Y | Esperado |
|---|---|---|---|---|---|---|---|
| 1 | OK cuadre exacto | 25 | `Prueba-1-OK-Cuadre_T25.xlsx` | 2508290001 (2.000.000), 2508290002 (342.000) | 2.342.000 | 2.342.000 | DR 0 → `DR_CERO` / `CERRADA_Y` |
| 2 | OK DI en rango | 42 | `Prueba-2-OK-DIenRango_T42.xlsx` | 4208290001 (1.934.000), 4208290002 (3.922.000) | 5.856.000 | **5.855.500** | DI +500 → `DI_REGISTRADA` / `CERRADA_Y` |
| 3 | NO OK faltante | 32 | `Prueba-3-NoOK-Faltante_T32.xlsx` | 3208290001 (2.000.000), 3208290002 (670.000) | 2.670.000 | 2.671.500 | DR −1.500 → `FUERA_RANGO` / `CON_DIFERENCIA`, Y abierta |
| 4 | NO OK sobrante | 45 | `Prueba-4-NoOK-Sobrante_T45.xlsx` | 4508290001 (500.000), 4508290002 (375.000) | 875.000 | 850.000 | DR +25.000 → `FUERA_RANGO` / `CON_DIFERENCIA`, Y abierta |

Rango de la DI automática: de −1.000 a +20.000, límites incluidos. DR = sobres − efectivo de la Y. Cada caja lleva 2 sobres porque `Form133` en FACO exige `Grid2.Rows > 2`.

`Prueba-Y_Resumen.xlsx` tiene tres hojas:
- **Resumen**: un bloque por prueba, con lo que hay que digitar y lo esperado;
- **Pasos**: el paso a paso;
- **Sobres**: los 8 sobres.

## Orden

1. **`P0_prechecks.sql`** (solo lectura), antes de digitar nada:
   - parámetros 1502 en S;
   - cola sin filas P/E;
   - sin Y, Z cerrada ni sobres en las 4 cajas;
   - terminales vigentes y de `ter_tipo = 0` (no Autopago);
   - sin otras Y abiertas del local 6 el 29-08.
   
   Si alguna terminal no sirve, la consulta 9 lista las libres y hay que regenerar ese Excel.
2. Por cada caja, siempre **primero la Y y después la carga**:
   1. F8 con local 6, fecha 29-08-2026 y la terminal (dejarla abierta);
   2. `Form19Y` con N° de Y 0, que pasa a 1 al validar. EFECTIVO y BOLETAS según la tabla; todo lo demás en 0;
   3. `Form133` (Carga Manual de Sobres): cargar el Excel de la caja.
   
   Al terminar, `Form133` muestra el resumen del paquete (Y cerradas / no cerradas).
3. **`P2_resultados.sql`** (solo lectura): log, estado de las Y, DI de la T42 y cola.
4. `Form3Y`: doble clic en la Y 1 y comparar Dif. de Caja, Compensación, Dif. Real y Estado.

Mensaje del paquete:
- si se digitan las 4 Y y después se cargan los 4 Excel, cada carga evalúa también las otras Y abiertas del local y el día (`CA_SIN_SOBRE = S`). Las T32 y T45 aparecerán como "no cerradas" en cada ejecución, sin cambios;
- para una demostración más limpia, hacer las cajas de a una (Y → carga): orden 1, 2, 3 y 4.

Si `Form133` no pudo llamar al paquete, se ejecuta a mano: `begin PKG_F8_CIERRE_AUTO.prc_cierre_automatico('FACO'); end;`

## Archivos

| Archivo | Qué es |
|---|---|
| `Prueba-1..4-*.xlsx` | Excel de carga para `Form133`: los de `prueba3_test` con la terminal, los sobres y la fecha cambiados |
| `Prueba-Y_Resumen.xlsx` | Resumen 2x2, pasos y sobres |
| `P0_prechecks.sql` | Verificaciones previas (solo lectura) |
| `P2_resultados.sql` | Resultados (solo lectura) |
