# FSCC-12901 COMPENSA_DI: sesión de prueba en test

Prueba del modelo del 19-10-2026. La carga de sobres (`Form133`) **no cierra la Y**. Por cada caja cargada:
- si la diferencia real (DR = sobres − efectivo de la Y) está entre **−1.000 y +20.000** (límites incluidos) y no es 0, registra una **DI automática** por el valor exacto y con el mismo signo;
- la DI lleva la observación `COMPENSACION AUTOMATICA DI`;
- la caja queda **Pendiente**.

Requisitos:
- en test: `../00_prechecks` → `../01_DESINSTALAR_v2` → `../INSTALAR.sql` → `../06_grants_sinonimos`;
- el exe compilado con el `FTEPROD/Form133.frm` del 19-10 (`EjecutaCompensaDIFACO`).

## Datos (local 6, 31-08-2026, Y 1)

Son las terminales de la prueba 3, que ya existen en test, en una fecha nueva.

| # | Escenario | Terminal | Archivo | Sobres | Total sobres | EFECTIVO = BOLETAS en Form19Y | DR | Esperado |
|---|---|---|---|---|---|---|---|---|
| 1 | OK: **DI negativa** | 29 | `Prueba-1-OK-DINegativa_T29.xlsx` | 2908310001 (2.000.000), 2908310002 (670.000) | 2.670.000 | **2.670.800** | −800 | `DI_REGISTRADA` −800; Dif. Real 0; Pendiente |
| 2 | OK: **DI positiva** | 40 | `Prueba-2-OK-DIPositiva_T40.xlsx` | 4008310001 (500.000), 4008310002 (375.000) | 875.000 | **860.000** | +15.000 | `DI_REGISTRADA` +15.000; Dif. Real 0; Pendiente |
| 3 | NO OK: **no se crea la DI** | 31 | `Prueba-3-NoOK-SinDI_T31.xlsx` | 3108310001 (2.000.000), 3108310002 (670.000) | 2.670.000 | **2.675.000** | −5.000 | `FUERA_RANGO`, sin DI; Dif. Real −5.000; Pendiente |
| 4 | **Caso normal** (cuadre) | 24 | `Prueba-4-Normal-Cuadre_T24.xlsx` | 2408310001 (2.000.000), 2408310002 (342.000) | 2.342.000 | **2.342.000** | 0 | `DR_CERO`, sin DI; Dif. Real 0; Pendiente |

Cada caja lleva 2 sobres porque `Form133` en FACO exige al menos 2 filas.

`Prueba-DI_Resumen.xlsx` tiene tres hojas:
- **Resumen**: un bloque por prueba, en 2x2 como `Prueba-Y_Resumen.xlsx`, con lo que hay que digitar y lo esperado;
- **Pasos**: el paso a paso;
- **Sobres**: los 8 sobres.

## Orden

1. **`P0_prechecks.sql`** (solo lectura). Revisa:
   - el paquete `VALID` y los parámetros 1502;
   - que `PKG_F8_CIERRE_AUTO` ya no exista;
   - que las 4 cajas no tengan Y, Z cerrada ni sobres ese día y que sean de `ter_tipo = 0`.
   
   Si una terminal no sirve, la consulta 9 lista las libres y se regenera ese Excel.
2. Por cada prueba, de a una y siempre **primero la Y y después la carga**:
   1. F8 con local 6, fecha 31-08-2026 y la terminal (dejarla abierta);
   2. `Form19Y` con N° de Y 0, que pasa a 1 al validar. EFECTIVO y BOLETAS según la tabla; todo lo demás en 0;
   3. `Form133` (Carga Manual de Sobres): cargar el Excel de la prueba. Sale "Se Cargaron 2 Registros" y después **"Compensacion automatica de DI"**, con la línea `Local 6 Terminal N Y 1: RESULTADO por MONTO`.
3. **`P2_resultados.sql`** (solo lectura): log, estado de las Y (abiertas) con su DR actual, DI y observación.
4. En pantalla:
   - `Form3Y`: doble clic en la Y 1 y comparar Dif. de Caja, Compensación, Dif. Real y Estado (**Pendiente**);
   - `Form4`: en las pruebas 1 y 2, la fila "Diferencia no Imputable" con el monto en Compensado y la observación automática.
5. Para repetir: **`P9_limpiar.sql`** (modifica datos y no hace commit solo).

## Archivos

| Archivo | Qué es |
|---|---|
| `Prueba-1..4-*.xlsx` | Excel de carga para `Form133`, en el mismo formato que los de `FSCC-12901_PROC_Y/prueba3_test` |
| `Prueba-DI_Resumen.xlsx` | Resumen por bloques, pasos y sobres |
| `P0_prechecks.sql` | Verificaciones previas (solo lectura) |
| `P2_resultados.sql` | Resultados (solo lectura) |
| `P9_limpiar.sql` | Deshacer la prueba (modifica datos, sin commit) |

## Si algo falla

- **No aparece el mensaje de compensación:** el exe no tiene el `Form133` nuevo, o la carga insertó 0 sobres ("Ya existen los registros").
- **`ERROR ADO`:** faltan permisos o sinónimos para el usuario de la aplicación (`../06_grants_sinonimos.sql`).
- **`SIN_TERMSTAT` o `SIN_LIBVTA`:** la Y no se ingresó antes de la carga. Limpiar con `P9` y repetir, o llamar al paquete a mano (`../07_pruebas.sql`, bloque 3).
- **`INACTIVO`:** el parámetro 1502 `CA_DI_ACTIVO` no está en S.
- **Recarga** (otra carga sobre una caja que ya tiene DI automática): no está en esta sesión. Escenario G de `../07_pruebas.sql`.
