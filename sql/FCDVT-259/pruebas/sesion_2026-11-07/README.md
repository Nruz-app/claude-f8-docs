# FCDVT-259: sesión de prueba de Exportar Cierres Y y Z (Form176) — 07-11-2026

Creada el 19-11-2026. Es la misma prueba de punta a punta de `../README.md` (sesión del 27-10-2026), con las fechas cambiadas a **07-11-2026** (día con cierres) y **08-11-2026** (día sin cierres). Con la regla de fechas de Form176 del 17-11-2026 (Fecha Fin hasta ayer, sin límite hacia atrás y un rango máximo de 3 días incluidos), estas fechas se usan **tal cual**: no hay que cambiar nada en los archivos.

Cubre la Z grabada, la **Z armada con la suma de las Y** (terminal FACO cerrado solo con Y), los filtros sin cierres, las validaciones de fechas y la recarga del CSV exportado en Form174. Diseño en `docs/README_FCDVT-259.md`.

- **Datos:** local 5 (FACO), terminales 1 a 3. Mismos montos e identificación que la sesión del 27-10; solo cambia la FECHA.
- **Esta prueba graba en test** (paso 1 y paso 5, con Cargar de Form174; el paso 3 borra la Z del terminal 2). Al terminar, limpiar con `d09_limpia.sql`.
- Los `.sql` se ejecutan conectado como el dueño de las tablas (test: `INTRANETTS`), en SQL*Plus o DBeaver.

| Archivo | Qué es |
|---|---|
| `d00_prechecks.sql` | Solo lectura: terminales vigentes, 07 y 08-11 sin cierres, nada cerrado, packages VALID y que `fn_encabezado` responda |
| `d01_carga_07-11.csv` | 56 columnas, `;`, ASCII, CRLF. Por terminal una Z = suma de sus Y concepto a concepto |
| `d02_simula_solo_y.sql` | **Solo test.** Borra la Z (libvta `'F8'` + zzz) del terminal 2 del 07-11: queda como un terminal FACO cerrado solo con Y |
| `d03_valida.sql` | Solo lectura: lo que exporta Form176 (`fn_lineas`) para el 07-11, el conteo de la pantalla y controles automáticos |
| `d09_limpia.sql` | **Solo test.** Borra lo que dejó la prueba el 07-11 en el local 5 (libvta, zzz, termstat/termstaty de la carga masiva) |

## Contenido de `d01_carga_07-11.csv`

| Terminal | Z (hora; secuencia; boleta; vendedor; reposición) | Y | Total Y = Total Z | Conceptos con monto en la Z |
|---|---|---|---|---|
| 1 | 21:00; 2709; 270199; 71001; 4101 | 2 | 800.000 | BOLETAS 850.000, N.CRÉDITO −50.000, EFECTIVO 400.000, TARJETA 400.000 |
| 2 | 21:30; 2719; 271399; 71009; 4209 | 3 | 1.380.000 | BOLETAS 1.305.500, N.CRÉDITO −30.000, FACTURA 104.500, EFECTIVO 730.000, EFECT. RECAUDACIÓN 35.000, TARJETA 420.000, CMR 230.000, DOTACIONES 200.000, RETIROS −200.000, ABONO CMR 35.000 |
| 3 | 21:10; 2729; 272199; 71004; 4301 | 1 | 150.000 | BOLETAS 150.000, EFECTIVO 150.000 |

La última Y del terminal 2 es la Y3: `20:15; 2713; 271388; 71003; 4202`.

## Antes de empezar

1. En test: `../../INSTALAR.sql` (permiso 461 y el package) y `../../04_grants_sinonimos.sql` si el exe usa otro usuario. Exe compilado con Form176 (regla de fechas del 17-11) y el MDIForm1 de FCDVT-259. Usuario FACO con perfil 10 u 11.
2. `d00_prechecks.sql`: terminales 1, 2 y 3 vigentes; **ninguna fila** en la consulta 2 (07 y 08-11 sin cierres en el local 5); nada cerrado; los tres packages VALID; el encabezado sale. Si el 07 o el 08-11 ya tienen cierres, no seguir: Cargar los **reemplazaría** y `d09` los borraría.

## Paso 1. Grabar el 07-11 con la carga masiva

F8 ▸ botón Y ▸ "Ingreso del YYY Masivo" (Form174) ▸ **Buscar** `d01_carga_07-11.csv` ▸ **Cargar**.

- Buscar: 3 grupos CARGADO, 0 con error.
- Cargar: 3 grupos GRABADO.

## Paso 2. Exportar con todas las Z grabadas

1. `d03_valida.sql`:
   - consulta 1: 9 líneas, por terminal la Z y sus Y (T1: Z, Y1, Y2; T2: Z, Y1, Y2, Y3; T3: Z, Y1);
   - consulta 2: 9 filas, 3 terminales, 6 Y y 3 Z;
   - consulta 3: ninguna fila (cada monto de la Z = suma de sus Y);
   - consulta 4: Z_CSV = 1 y Z_LIBVTA = 1 en los tres; Y_CSV = Y_LIBVTA (2, 3, 1);
   - consulta 5: IGUAL = N en los tres;
   - consulta 6: 4 líneas (terminal 2); consulta 7: ninguna fila; consulta 8: 9.
2. F8 ▸ botón Y ▸ **Exportar Cierres Y y Z** (Form176): local **5**, terminal **0**, Fecha Inicio = Fecha Fin = **07-11-2026** ▸ **Exportar**. El nombre sugerido es `carga_Y_compensa_07112026_07112026.csv`.
   - "Resultado de la exportación": el archivo y "Cierres exportados: 9 filas (3 terminales · 6 Y y 3 Z)".
   - El CSV, abierto con el Bloc de notas: línea 1 = encabezado de 56 columnas; después las 9 líneas de la consulta 1, separadas por `;`.

## Paso 3. Terminal solo con Y: Z armada

1. `d02_simula_solo_y.sql` con `v_ejecutar = 'N'` (libvta F8 = 1, Y = 3) y después con `'S'`.
2. `d03_valida.sql`:
   - consulta 1: siguen 9 líneas; la Z del terminal 2 es ahora la **armada** (mismos montos que la Z borrada; identificación de la Y3: hora 20:15, secuencia 2713, boleta 271388, vendedor 71003, reposición 4202);
   - consulta 3: ninguna fila;
   - consulta 4: terminal 2 con Z_CSV = 1 y Z_LIBVTA = 0;
   - consulta 5: terminal 2 con IGUAL = **S**.
3. Form176, mismos filtros ▸ Exportar: el CSV es igual al del paso 2, salvo la línea Z del terminal 2. El resultado sigue diciendo 9 filas (3 terminales · 6 Y y 3 Z).

## Paso 4. Filtros sin cierres y validaciones de la pantalla

En Form176 (regla de fechas del 17-11-2026):
- Local 5, terminal **9** (o uno sin cierres), 07-11-2026 ▸ Exportar: «No existen cierres Y/Z para los filtros seleccionados» y **no** pide ruta.
- Local 5, terminal 0, **08-11-2026** (día sin cierres): el mismo mensaje.
- Rango **07-11-2026 a 09-11-2026** (3 días incluidos): exporta; las 9 filas del 07-11 más lo que haya el 09-11 en el local 5 (con d00 limpio en el 08-11, el 08 no aporta filas).
- Rango **07-11-2026 a 10-11-2026** (4 días): «El rango entre Fecha Inicio y Fecha Fin no puede superar 3 dias (dias incluidos).» y no genera archivo.
- Fecha Inicio posterior a la Fecha Fin (por ejemplo 08-11 a 07-11): «La Fecha Fin no puede ser anterior a la Fecha Inicio» y no genera archivo.
- Los calendarios abren en ayer y no dejan elegir hoy ni días posteriores (`MaxDate` = ayer); hacia atrás no tienen límite (sin `MinDate`), así que el 07-11 se elige sin problema.
- Terminal 2 solo, 07-11: 4 filas (1 terminal · 3 Y y 1 Z).
- Local **0** (TODOS LOS LOCALES, solo si el perfil ve más de un local), 07-11: incluye las 9 filas del local 5 y las de los demás locales con cierres ese día; el combo de terminal solo ofrece 0.
- Cancelar el diálogo de guardar: no pasa nada.

## Paso 5. Recargar el CSV exportado (con la Z armada)

1. Form174 ▸ **Buscar** con el CSV del paso 3, **sin abrirlo ni cambiarlo**: 3 grupos **CARGADO**, 0 con error (la estructura es la de la plantilla y la Z armada cuadra con sus Y).
2. **Cargar**: 3 grupos GRABADO. El terminal 2 vuelve a tener la Z en libvta (`docs/sql/FCDVT-14/06_pruebas.sql` consultas 6 y 8 con la fecha 07-11-2026 y el local 5).
3. `d03_valida.sql` consulta 4: Z_LIBVTA = 1 en los tres. Consulta 5: terminal 2 con IGUAL = S (la Z grabada ahora tiene la identificación de la Y3).

## Limpieza

`d09_limpia.sql` con `v_ejecutar = 'N'` (cuenta) y después `'S'`. Deja el 07-11-2026 del local 5 sin libvta, zzz, termstat ni termstaty de la carga masiva. Las cargas quedan en `VTA_FACOCARGA_YZ_*` como historial.

## Resultado (completar en test)

| Paso | Resultado | Fecha | Observaciones |
|---|---|---|---|
| d00 | | | |
| 1 | | | |
| 2 | | | |
| 3 | | | |
| 4 | | | |
| 5 | | | |
| d09 | | | |
