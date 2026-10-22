# FSCC-12901 COMPENSA_DI: prueba en test con 6 locales por archivo

Repite la prueba de `../prueba_test` (aprobada el 20-10-2026), pero cada Excel trae **6 locales** (24 cajas en total) y los montos varían para probar **los límites** del rango. El modelo es el mismo: la carga de sobres (`Form133`) **no cierra la Y**. Por cada caja cargada:
- si la diferencia real (DR = sobres − efectivo de la Y) está entre **−1.000 y +20.000** (límites incluidos) y no es 0, registra una **DI automática** por el valor exacto y con el mismo signo, con la observación `COMPENSACION AUTOMATICA DI`;
- la caja queda **Pendiente**.

`Form133` acepta varios locales en un mismo archivo: graba cada fila con su local y llama a `PKG_F8_COMPENSA_DI_CARGA.prc_compensa_caja` una vez por caja (local, terminal, fecha, Y). El mensaje final muestra hasta 20 líneas; con 6 cajas por archivo se ven todas.

Requisitos: los mismos de `../prueba_test` (paquete instalado en test y el exe con el `Form133` del 19-10/20-10).

## Datos (30-08-2026, Y 1, 2 sobres por caja)

En test, el **30-08-2026** no tenía ningún dato FACO (verificado el 20-10). Los locales **6 PARQUE ARBOLEDA, 18 VILLA COUNTRY, 25 FONTANAR CHIA, 35 WORLD TRADE CENTER, 36 SAN DIEGO y 38 CENTRO MAYOR** están vigentes y tienen las terminales 24, 29, 31 y 40 de tipo 0.

| # | Escenario | Terminal | Archivo | DR por local (6 / 18 / 25 / 35 / 36 / 38) | Esperado |
|---|---|---|---|---|---|
| 1 | OK: **DI negativa** | 29 | `Prueba-1-OK-DINegativa_T29.xlsx` | −1 / −100 / −500 / −800 / −999 / **−1.000** | 6 × `DI_REGISTRADA`; Dif. Real 0; Pendiente |
| 2 | OK: **DI positiva** | 40 | `Prueba-2-OK-DIPositiva_T40.xlsx` | +1 / +500 / +5.000 / +15.000 / +19.999 / **+20.000** | 6 × `DI_REGISTRADA`; Dif. Real 0; Pendiente |
| 3 | NO OK: **no se crea la DI** | 31 | `Prueba-3-NoOK-SinDI_T31.xlsx` | **−1.001** / −5.000 / −50.000 / **+20.001** / +25.000 / +100.000 | 6 × `FUERA_RANGO`, sin DI; Dif. Real = DR; Pendiente |
| 4 | **Caso normal** (cuadre) | 24 | `Prueba-4-Normal-Cuadre_T24.xlsx` | 0 en los 6 | 6 × `DR_CERO`, sin DI; Dif. Real 0; Pendiente |

- Número de sobre: `<terminal>0830<local de 3 dígitos><1|2>`; por ejemplo, `2908300061` y `2908300062` son los dos sobres de la caja 29 del local 6.
- En cada caja, EFECTIVO = BOLETAS = total de sobres − DR. Los montos para digitar están en el bloque «Digitar en Form19Y» de cada prueba, en la hoja **Resumen** de `Prueba-DI_Resumen.xlsx`.

| Prueba | Local | Total sobres | EFECTIVO = BOLETAS |
|---|---|---|---|
| 1 (T29) | 6 / 18 / 25 / 35 / 36 / 38 | 1.451.000 / 1.552.000 / 1.653.000 / 1.754.000 / 1.855.000 / 1.956.000 | 1.451.001 / 1.552.100 / 1.653.500 / 1.754.800 / 1.855.999 / 1.957.000 |
| 2 (T40) | 6 / 18 / 25 / 35 / 36 / 38 | 1.501.000 / 1.602.000 / 1.703.000 / 1.804.000 / 1.905.000 / 2.006.000 | 1.500.999 / 1.601.500 / 1.698.000 / 1.789.000 / 1.885.001 / 1.986.000 |
| 3 (T31) | 6 / 18 / 25 / 35 / 36 / 38 | 1.551.000 / 1.652.000 / 1.753.000 / 1.854.000 / 1.955.000 / 2.056.000 | 1.552.001 / 1.657.000 / 1.803.000 / 1.833.999 / 1.930.000 / 1.956.000 |
| 4 (T24) | 6 / 18 / 25 / 35 / 36 / 38 | 1.601.000 / 1.702.000 / 1.803.000 / 1.904.000 / 2.005.000 / 2.106.000 | iguales al total de sobres |

`Prueba-DI_Resumen.xlsx` tiene tres hojas:
- **Resumen**: un bloque por prueba en 2x2, como el de `../prueba_test`: los datos, el EFECTIVO = BOLETAS que se digita para cada local (con sus sobres y su DR) y el resultado esperado;
- **Pasos**: el paso a paso;
- **Sobres**: los 48 sobres.

## Orden

1. **`P0_prechecks.sql`** (solo lectura). Revisa:
   - el paquete `VALID` y los parámetros 1502;
   - que las 24 cajas no tengan Y, Z cerrada, sobres ni movimientos ese día, y que sean de `ter_tipo = 0`;
   - que los 6 locales estén vigentes y que el log del día esté vacío.

   Conectado como `uintranetts`, la consulta 1 muestra los **sinónimos**: el de `PKG_F8_COMPENSA_DI_CARGA` puede salir `INVALID` después de recompilar el paquete. Es normal, porque Oracle lo revalida en el primer uso. Lo que cuenta es la consulta 1b. Esto explica el `INVALID` del 20-10.
2. Por cada prueba, de a una, **primero las 6 Y y después la carga**:
   1. F8 con el local, la fecha 30-08-2026 y la terminal (dejarla abierta);
   2. `Form19Y`: N° de Y 0, que pasa a 1 al validar. EFECTIVO y BOLETAS según la tabla y todo lo demás en 0. Repetir 1 y 2 en los 6 locales;
   3. `Form133` (Carga Manual de Sobres): cargar el Excel de la prueba. Sale "Se Cargaron 12 Registros" y después **"Compensacion automatica de DI"**, con 6 cajas evaluadas y una línea por local.
3. **`P2_resultados.sql`** (solo lectura): log (detalle y resumen), estado de las Y (abiertas) con su DR actual, DI, observaciones y sobres por caja.
4. En pantalla:
   - Consultas de Cuadratura (`Form43`), con local `0-TODOS` (perfiles 9 y 10) y fecha 30-08-2026: las 24 cajas, con la Dif. de Caja, la Compensación, la Dif. Real y el Estado (**Pendiente**);
   - `Form4`: en las pruebas 1 y 2, la fila "Diferencia no Imputable" con el monto en Compensado y la observación automática. Basta revisar algunas cajas, incluidas las de los límites (local 38).
5. Opcional, para probar `Cerrar Terminal` con TODOS: la confirmación debe decir **18 caja(s) de 6 local(es)**. Se cierran las de las pruebas 1, 2 y 4, y las 6 de la prueba 3 quedan Pendientes.
6. Para repetir: **`P9_limpiar.sql`** (modifica datos y no hace commit solo).

## Archivos

| Archivo | Qué es |
|---|---|
| `Prueba-1..4-*.xlsx` | Excel de carga para `Form133` (12 filas: 6 locales × 2 sobres), con el mismo formato que los de `../prueba_test` |
| `Prueba-DI_Resumen.xlsx` | Resumen por prueba, pasos y sobres |
| `P0_prechecks.sql` | Verificaciones previas (solo lectura) |
| `P2_resultados.sql` | Resultados (solo lectura) |
| `P9_limpiar.sql` | Deshacer la prueba (modifica datos, sin commit) |

## Si algo falla

- **No aparece el mensaje de compensación:** el exe no tiene el `Form133` nuevo, o la carga insertó 0 sobres ("Ya existen los registros").
- **Solo algunas cajas con `SIN_TERMSTAT` o `SIN_LIBVTA`:** falta la Y de ese local. Se puede ingresar la Y y llamar al paquete a mano para esa caja (`../07_pruebas.sql`, bloque 3), o limpiar con `P9` y repetir la prueba.
- **`ERROR ADO`:** faltan permisos o sinónimos para el usuario de la aplicación (`../06_grants_sinonimos.sql`).
- **`INACTIVO`:** el parámetro 1502 `CA_DI_ACTIVO` no está en S.
- **Un límite (−1.000 o +20.000) sale `FUERA_RANGO`:** revisar la comparación del paquete (debe ser `>=` / `<=`) y los parámetros `CA_DI_MIN` / `CA_DI_MAX`.
