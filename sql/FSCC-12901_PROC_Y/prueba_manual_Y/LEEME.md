# Prueba manual "camino feliz" del cierre Y (FACO), por pantallas

**Resultado: OK (15-10-2026, base de test `sgfinperds`, exe 3.4.9).** La Y 1 de la terminal 27 del local 6 (fecha de venta 28-08-2026) quedó **Cerrada** con Diferencia Real 0.

Se probó solo la lógica de la Y desde el aplicativo, **sin el paquete** (`PKG_F8_CIERRE_AUTO` todavía no está instalado en test):

1. Y manual (`Form19Y`).
2. Carga de sobres desde Excel (`Form133`).
3. F8 por cierre Y (`Form3Y`) con Diferencia Real 0.
4. Cerrar Terminal.

Esta prueba reemplaza a la del 14-10, que no salió por el camino correcto.

## Contenido de la carpeta

| Archivo | Qué es |
|---|---|
| `PRD-LIST-TEST-V2.xlsx` | Excel cargado: 3 sobres EFE, local 6, terminal 27, fecha de venta 20260828, Y 1 |
| `capturas/01..05_*.png` | Evidencia de cada paso (ver abajo) |
| `P0_prechecks.sql` | (Opcional, solo lectura) Verificaciones previas para repetir la prueba |
| `P2_resultados.sql` | (Opcional, solo lectura) Diferencia Real por componente y estado de la Y |
| `P9_limpiar.sql` | (Opcional, modifica datos; lo ejecuta el usuario) Borra los sobres y la Y para repetir |
| PDF | `docs/PRUEBA_Manual_Y_FSCC-12901_2026-10-15.pdf` |

Los SQL no se usaron en esta prueba, que se hizo solo por pantallas. Quedan para repetirla.

## Datos

| Sobre | Monto | Dif. | Recuento | Fecha venta | Y |
|---|---|---|---|---|---|
| 3404295622 | 846.000 | 0 | 123 | 20260828 | 1 |
| 3476295623 | 4.000.000 | 0 | 123 | 20260828 | 1 |
| 3482295624 | 2.737.000 | 0 | 123 | 20260828 | 1 |
| **Total** | **7.583.000** | | | | |

## Pasos realizados en el aplicativo

1. **F8** (toolbar) con Local 6, Fecha 28-08-2026 y Terminal 27. Se deja abierta: `Form19Y.Oklt` valida la terminal con la fecha de esta pantalla (`FormVariable.DTPicker1`), no con la suya.
2. **Ingreso del YYY** (toolbar, botón Y; `Form19Y`). Captura 01.
   - Identificación: Fecha 28-08-2026, Local 6, Terminal 27, N° de cierre de Y **0**, Hora 12:00, Secuencia 1, N° Boleta 1, Vendedor 1 y Cont. Reposición 1.
   - **Validar Identificación**: el N° de Y pasa solo a **1** (`FuncBuscaNumSecY` = máximo del día + 1).
   - Detalle de Montos (captura 02): **EFECTIVO 7.583.000** y **BOLETAS 7.583.000**, para que TOTALES de ventas sea igual a las formas de pago. Todo lo demás en 0.
   - **Aceptar** y "Sí". Graba `vta_FACOzzz`, `vta_FACOlibvta` (tiporeg Y, secuencia 1) y `vta_FACOtermstaty` (estado −1, "INGRESO MANUAL POR CIERRE DE Y").
3. **Estado en línea → Carga Manual de Sobres** (`Form133`): recaudador, Excel, desplegar y **Cargar Archivo**. Inserta 3 filas `F8`/`EFE` en `vta_FACOprd` con `prv_cierrey = 1` y reabre la Z (`AbrirTerminal`).
3b. Resultado en la F8 de la Z (captura 03):
   - aparece el recuadro "Cierre de Y: Y 1";
   - la recaudación del banco es 7.583.000;
   - la Diferencia de Caja de la Z es 7.583.000, lo que es **esperado**: en FACO la Z no se ingresa.
4. **Doble clic en la Y 1** abre la F8 por cierre Y (`Form3Y`). Captura 04:
   - recaudación del banco 7.583.000 = efectivo de la Y 7.583.000;
   - Diferencias (B−Y) 0;
   - **Diferencia de Caja 0, Compensación 0, Diferencia Real 0**;
   - Estado *Pendiente*.
5. Con la F8 de la Y activa, se pulsa el **primer candado** del toolbar, junto a la impresora (Button5, Key `Cerrar`, tooltip "Cerrar Terminal", que llama a `Form3Y.CierraTerminal`), y se responde "Sí". El otro candado, cerca de "FH", es otra opción. Captura 05: Estado **Cerrado** y Diferencia Real 0.

## Resultado esperado y obtenido

| Control | Esperado | Obtenido |
|---|---|---|
| N° de Y asignado al validar | 1 | 1 |
| Registros cargados por `Form133` | 3 | 3 (recaudación 7.583.000 en la F8) |
| Diferencia (B−Y) del efectivo | 0 | 0 |
| Diferencia Real de la Y | 0 | 0 |
| Estado de la Y después de Cerrar Terminal | Cerrado (`ter_estado = 1`) | Cerrado |
| Z de la terminal | Pendiente, sin tocar | Pendiente (Dif. de Caja 7.583.000, esperado en FACO) |

## Lecciones (para repetirla)

- El **N° de Y se deja en 0**: el sistema lo calcula. Si la caja ya tiene una Y ese día, saldrá 2 o más y no cuadrará con la columna H del Excel. Hay que usar otra caja o fecha, o limpiar con `P9`.
- **Abrir primero la F8 con la fecha de la prueba**. Si no, sale "Relacion Local /Terminal no existe".
- **Poner BOLETAS igual al efectivo.** Para una Y nueva no se valida que venta = pago, pero la validación ZZZ (perfiles con la opción 103) podría marcar "Y descuadrada".
- `Form133` detecta duplicados por **número de sobre + fecha de venta**, sin mirar el local. Para repetir con el mismo Excel, primero hay que borrar los sobres (`P9`).
- La columna "Diferencia (Z − S(Y))" de `Form19Y` y la diferencia de la Z en la F8 no aplican a FACO (no hay Z ingresada).
- Cerrar desde la pantalla de la **Y**, no desde la Z.

## Estado de los datos que quedan en test

La Y 1 cerrada, los 3 sobres y la fila de la Z en estado 0 ("CARGA MANUAL DE SOBRES") **quedan en la base de test**. Para repetir la prueba en la misma caja hay que ejecutar `P9_limpiar.sql` (lo ejecuta el usuario; no borra la fila de la Z).
