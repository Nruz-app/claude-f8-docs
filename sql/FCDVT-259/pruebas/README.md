# FCDVT-259: prueba de Exportar Cierres Y y Z en test (Form176)

> **19-11-2026:** hay una sesión nueva con fecha **07-11-2026** en `sesion_2026-11-07/` (mismos datos y pasos, fechas fijas). La nota de abajo sobre cambiar las fechas a anteayer/ayer quedó obsoleta: desde el 17-11-2026 Form176 no tiene límite hacia atrás (Fecha Fin hasta ayer y rango máximo de 3 días), así que esta sesión del 27-10 también se puede usar con sus fechas originales.

Creada el 16-11-2026 a partir de la prueba de Descargar Excel de FCDVT-14 (`docs/sql/FCDVT-14/pruebas_descargar/`, que se trasladó aquí cuando el Descargar de Form174 se revirtió). Es la prueba de punta a punta de **Form176** (Exportar → `PKG_F8_EXPORTA_MASIVA_YZ.fn_lineas`, pasos `02`/`03`; diseño en `docs/README_FCDVT-259.md`). Cubre la Z grabada, la **Z armada con la suma de las Y** (terminal FACO cerrado solo con Y), los filtros sin cierres, las validaciones de fechas y la recarga del CSV exportado en Form174.

- **Datos:** local 5, terminales 1 a 3, un día **con** cierres (el CSV `d01`) y el día siguiente **sin** cierres.
- **Fechas:** los archivos traen **27-10-2026** (con cierres) y **28-10-2026** (sin cierres). Form176 solo deja exportar desde hoy − 2 días hasta ayer, así que para probar la pantalla hay que **reemplazar 27-10-2026 por anteayer (hoy − 2) y 28-10-2026 por ayer** en `d01_carga_27-10.csv` (columna FECHA de las 9 filas) y en `d00`, `d02`, `d03` y `d09`. Las consultas del package (`d03`) funcionan con cualquier fecha.
- **Esta prueba graba en test** (paso 1 y paso 5, con Cargar de Form174; el paso 3 borra la Z del terminal 2). Al terminar, limpiar con `d09_limpia.sql`.
- Los `.sql` se ejecutan conectado como el dueño de las tablas (test: `INTRANETTS`), en SQL*Plus o DBeaver.

| Archivo | Qué es |
|---|---|
| `d00_prechecks.sql` | Solo lectura: terminales vigentes, fechas sin cierres, nada cerrado, packages VALID y que `fn_encabezado` responda |
| `d01_carga_27-10.csv` | 56 columnas, `;`, ASCII, CRLF. Por terminal una Z = suma de sus Y concepto a concepto |
| `d02_simula_solo_y.sql` | **Solo test.** Borra la Z (libvta `'F8'` + zzz) del terminal 2: queda como un terminal FACO cerrado solo con Y |
| `d03_valida.sql` | Solo lectura: lo que exporta Form176 (`fn_lineas`), el conteo de la pantalla y controles automáticos |
| `d09_limpia.sql` | **Solo test.** Borra lo que dejó la prueba en el día con cierres (libvta, zzz, termstat/termstaty de la carga masiva) |

## Contenido de `d01_carga_27-10.csv`

| Terminal | Z (hora; secuencia; boleta; vendedor; reposición) | Y | Total Y = Total Z | Conceptos con monto en la Z |
|---|---|---|---|---|
| 1 | 21:00; 2709; 270199; 71001; 4101 | 2 | 800.000 | BOLETAS 850.000, N.CRÉDITO −50.000, EFECTIVO 400.000, TARJETA 400.000 |
| 2 | 21:30; 2719; 271399; 71009; 4209 | 3 | 1.380.000 | BOLETAS 1.305.500, N.CRÉDITO −30.000, FACTURA 104.500, EFECTIVO 730.000, EFECT. RECAUDACIÓN 35.000, TARJETA 420.000, CMR 230.000, DOTACIONES 200.000, RETIROS −200.000, ABONO CMR 35.000 |
| 3 | 21:10; 2729; 272199; 71004; 4301 | 1 | 150.000 | BOLETAS 150.000, EFECTIVO 150.000 |

La última Y del terminal 2 es la Y3: `20:15; 2713; 271388; 71003; 4202`.

## Antes de empezar

1. En test: `../INSTALAR.sql` (permiso 461 y el package) y `../04_grants_sinonimos.sql` si el exe usa otro usuario. Compilar el exe con Form176 y el MDIForm1 de FCDVT-259. Usuario FACO con perfil 10 u 11.
2. Cambiar las fechas (ver arriba).
3. `d00_prechecks.sql`: terminales 1, 2 y 3 vigentes; **ninguna fila** en la consulta 2; nada cerrado; los tres packages VALID; el encabezado sale.

## Paso 1. Grabar el día con la carga masiva

F8 ▸ botón Y ▸ "Ingreso del YYY Masivo" (Form174) ▸ **Buscar** `d01_carga_27-10.csv` ▸ **Cargar**.

- Buscar: 3 grupos cargados, 0 con error.
- Cargar: 3 grupos grabados.

## Paso 2. Exportar con todas las Z grabadas

1. `d03_valida.sql`:
   - consulta 1: 9 líneas, por terminal la Z y sus Y (T1: Z, Y1, Y2; T2: Z, Y1, Y2, Y3; T3: Z, Y1);
   - consulta 2: 9 filas, 3 terminales, 6 Y y 3 Z;
   - consulta 3: ninguna fila (cada monto de la Z = suma de sus Y);
   - consulta 4: Z_CSV = 1 y Z_LIBVTA = 1 en los tres; Y_CSV = Y_LIBVTA (2, 3, 1);
   - consulta 5: IGUAL = N en los tres;
   - consulta 6: 4 líneas (terminal 2); consulta 7: ninguna fila; consulta 8: 9.
2. F8 ▸ botón Y ▸ **Exportar Cierres Y y Z** (Form176): local **5**, terminal **0**, Fecha Inicio = Fecha Fin = el día con cierres ▸ **Exportar**. El nombre sugerido es `carga_Y_compensa_<ddmmyyyy>_<ddmmyyyy>.csv`.
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

En Form176:
- Local 5, terminal **9** (o uno sin cierres), el día con cierres ▸ Exportar: «No existen cierres Y/Z para los filtros seleccionados» y **no** pide ruta.
- Local 5, terminal 0, el día **sin** cierres: el mismo mensaje.
- Fecha Inicio posterior a la Fecha Fin: «La Fecha Fin no puede ser anterior a la Fecha Inicio» y no genera archivo.
- Fecha Fin igual o posterior a hoy, o Fecha Inicio anterior a hoy − 2 días: el calendario no deja elegirlas (`MinDate`/`MaxDate`); si llegaran, Exportar avisa y no genera archivo.
- Terminal 2 solo: 4 filas (1 terminal · 3 Y y 1 Z).
- Local **0** (TODOS LOS LOCALES, solo si el perfil ve más de un local): incluye las 9 filas del local 5 y las de los demás locales con cierres ese día; el combo de terminal solo ofrece 0.
- Cancelar el diálogo de guardar: no pasa nada.

## Paso 5. Recargar el CSV exportado (con la Z armada)

1. Form174 ▸ **Buscar** con el CSV del paso 3, **sin abrirlo ni cambiarlo**: 3 grupos **CARGADO**, 0 con error (la estructura es la de la plantilla y la Z armada cuadra con sus Y).
2. **Cargar**: 3 grupos GRABADO. El terminal 2 vuelve a tener la Z en libvta (`docs/sql/FCDVT-14/06_pruebas.sql` consultas 6 y 8 con la fecha y el local 5).
3. `d03_valida.sql` consulta 4: Z_LIBVTA = 1 en los tres. Consulta 5: terminal 2 con IGUAL = S (la Z grabada ahora tiene la identificación de la Y3).

## Limpieza

`d09_limpia.sql` con `v_ejecutar = 'N'` (cuenta) y después `'S'`. Deja el día con cierres del local 5 sin libvta, zzz, termstat ni termstaty de la carga masiva. Las cargas quedan en `VTA_FACOCARGA_YZ_*` como historial.

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
