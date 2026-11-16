# FCDVT-14: prueba de Descargar Excel en test (Form174)

Creada el 16-11-2026. Prueba de punta a punta del botón **Descargar Excel** de Form174 (local + fecha → `PKG_F8_EXPORTA_MASIVA_YZ`, pasos `04d`/`04e`; diseño en `docs/README_FCDVT-14.md` §5.10). Cubre la Z grabada, la **Z armada con la suma de las Y** (terminal FACO cerrado solo con Y), el día sin cierres y la recarga del Excel descargado.

- **Datos:** local 5, terminales 1 a 3, **27-10-2026** con cierres y **28-10-2026** sin cierres. Esas fechas no las usa otra prueba.
- **Esta prueba graba en test** (paso 1 y paso 5, con Cargar; paso 2 borra la Z del terminal 2). Al terminar, limpiar con `d09_limpia.sql`.
- Los `.sql` se ejecutan conectado como el dueño de las tablas (test: `INTRANETTS`), en SQL*Plus o DBeaver.

| Archivo | Qué es |
|---|---|
| `d00_prechecks.sql` | Solo lectura: terminales vigentes, fechas sin cierres, nada cerrado, packages VALID y que `fn_encabezado` responda |
| `d01_carga_27-10.csv` | 56 columnas, `;`, ASCII, CRLF. Por terminal una Z = suma de sus Y concepto a concepto (generado con un script) |
| `d02_simula_solo_y.sql` | **Solo test.** Borra la Z (libvta `'F8'` + zzz) del terminal 2: queda como un terminal FACO cerrado solo con Y |
| `d03_valida.sql` | Solo lectura: lo que descarga Form174 (`fn_lineas`, `fn_resumen`) y controles automáticos |
| `d09_limpia.sql` | **Solo test.** Borra lo que dejó la prueba en el 27-10 (libvta, zzz, termstat/termstaty de la carga masiva) |

## Contenido de `d01_carga_27-10.csv`

| Terminal | Z (hora; secuencia; boleta; vendedor; reposición) | Y | Total Y = Total Z | Conceptos con monto en la Z |
|---|---|---|---|---|
| 1 | 21:00; 2709; 270199; 71001; 4101 | 2 | 800.000 | BOLETAS 850.000, N.CRÉDITO −50.000, EFECTIVO 400.000, TARJETA 400.000 |
| 2 | 21:30; 2719; 271399; 71009; 4209 | 3 | 1.380.000 | BOLETAS 1.305.500, N.CRÉDITO −30.000, FACTURA 104.500, EFECTIVO 730.000, EFECT. RECAUDACIÓN 35.000, TARJETA 420.000, CMR 230.000, DOTACIONES 200.000, RETIROS −200.000, ABONO CMR 35.000 |
| 3 | 21:10; 2729; 272199; 71004; 4301 | 1 | 150.000 | BOLETAS 150.000, EFECTIVO 150.000 |

La última Y del terminal 2 es la Y3: `20:15; 2713; 271388; 71003; 4202`.

## Antes de empezar

1. En test: `04d` y `04e` (o `../INSTALAR.sql`), y `../05_grants_sinonimos.sql` si el exe usa otro usuario. Compilar el exe con el Form174 del 16-11.
2. `d00_prechecks.sql`: terminales 1, 2 y 3 vigentes; **ninguna fila** en la consulta 2 (si hay, cambiar las fechas: columna FECHA del CSV y fechas `EDITAR` de d02, d03 y d09); nada cerrado; los tres packages VALID; el encabezado sale.

## Paso 1. Grabar el día con la carga masiva

F8 ▸ botón Y ▸ "Ingreso del YYY Masivo" ▸ **Buscar** `d01_carga_27-10.csv` ▸ **Cargar**.

- Buscar: carga N° *n*, 3 grupos cargados, 0 con error.
- Cargar: 3 grupos grabados (verde en la grilla).

## Paso 2. Descargar con todas las Z grabadas

1. `d03_valida.sql`:
   - consulta 1: 9 líneas, por terminal la Z y sus Y (T1: Z, Y1, Y2; T2: Z, Y1, Y2, Y3; T3: Z, Y1);
   - consulta 2: `1;2;800000;800000;0;-1;0;N`, `2;3;1380000;1380000;0;-1;0;N`, `3;1;150000;150000;0;-1;0;N`;
   - consulta 3: ninguna fila (cada monto de la Z = suma de sus Y);
   - consulta 4: Z_EXCEL = 1 y Z_LIBVTA = 1 en los tres; Y_EXCEL = Y_LIBVTA (2, 3, 1);
   - consulta 5: IGUAL = N en los tres.
2. En Form174 (al abrir, la fecha es ayer y el combo trae los locales del perfil): local **5**, fecha **27-10-2026** ▸ **Descargar Excel**. El nombre sugerido es `cierres_YZ_FACO_L5_20261027.xlsx`.
   - Mensaje: "9 cierre(s) Z e Y de 3 terminal(es) del local 5 del 27-10-2026".
   - Hoja **Carga**: las 9 líneas de la consulta 1, desde la fila 2. FECHA y HORA como texto (`27-10-2026`, `21:00`), los montos como números.
   - Hoja **Resumen**: 3 filas con "GRABADA" en "Z en el Excel", diferencia 0 y la fila Total: total Y 2.330.000 y total Z 2.330.000.
   - Hoja **Instrucciones**: la línea 2 dice local 5, fecha 27-10-2026, 9 cierres.

## Paso 3. Terminal solo con Y: Z armada

1. `d02_simula_solo_y.sql` con `v_ejecutar = 'N'` (libvta F8 = 1, Y = 3) y después con `'S'`.
2. `d03_valida.sql`:
   - consulta 1: siguen 9 líneas; la Z del terminal 2 es ahora la **armada**:
     `27-10-2026;5;2;;20:15;2713;271388;71003;4202;Z;INGRESAR;1305500;-30000;104500;730000;35000;0;0;420000;0;230000;0;0;0;0;0;200000;-200000;35000;0;…;0`
     (mismos montos que la Z que se borró; identificación de la Y3);
   - consulta 2: la fila del terminal 2 pasa a `2;3;1380000;0;-1380000;-1;0;S`;
   - consulta 3: ninguna fila;
   - consulta 4: terminal 2 con Z_EXCEL = 1 y Z_LIBVTA = 0;
   - consulta 5: terminal 2 con IGUAL = **S**.
3. Form174: local 5, 27-10-2026 ▸ Descargar Excel.
   - Hoja **Carga**: igual que en el paso 2, salvo la fila Z del terminal 2 (hora 20:15, secuencia 2713, boleta 271388, vendedor 71003, reposición 4202).
   - Hoja **Resumen**: el terminal 2 con Monto Total Z 0, diferencia −1.380.000, "Z en el Excel" = **ARMADA (SUMA DE LAS Y)** y la fila en amarillo. Los terminales 1 y 3, GRABADA.
   - Instrucciones: la línea 2 (la misma en todas las descargas) explica que la Z de un terminal sin Z grabada se arma con la suma de sus Y.

## Paso 4. Día sin cierres

Form174: local 5, fecha **28-10-2026** ▸ Descargar Excel.
- Mensaje: "El local 5 no tiene cierres Z ni Y el 28-10-2026: se guardó como plantilla vacía."
- Hoja Carga solo con el encabezado (y sus validaciones); Resumen con "Sin cierres Z ni Y para el local y la fecha."
- `d03_valida.sql` consulta 6: ninguna fila en las dos.

## Paso 5. Recargar el Excel descargado (con la Z armada)

1. Abrir el Excel del paso 3, hoja **Carga** activa ▸ Archivo ▸ Guardar como ▸ "CSV (delimitado por comas)". Aceptar que solo se guarda la hoja activa.
2. Form174 ▸ **Buscar** con ese CSV: 3 grupos **CARGADO**, 0 con error (la Z armada cuadra con sus Y).
3. **Cargar**: 3 grupos GRABADO. El terminal 2 vuelve a tener la Z en libvta (`../06_pruebas.sql` consultas 6 y 8 con 27-10-2026 y local 5).
4. `d03_valida.sql` consulta 2: los tres terminales con Z_ARMADA = `N` y diferencia 0. Consulta 5: terminal 2 con IGUAL = S (la Z grabada ahora tiene la identificación de la Y3).

Si Excel guardó el CSV con `,` en vez de `;` (configuración regional), Buscar rechaza el encabezado: es la misma condición de la plantilla de siempre (`../FORMATO_CARGA_Y_FACO.md`).

## Paso 6. Otros controles

- Form174 sin elegir local ▸ Descargar Excel: "Seleccione el local." y no pide ruta.
- Cancelar el diálogo de guardar: no pasa nada.
- `d03_valida.sql` consulta 7: `ORA-20001 ... pais no habilitado (ARG)`.
- Con un usuario de **SFCL** (si `docs/sql/FCDVT-10/` está instalado): Descargar con un local y fecha de Tottus con cierres. La hoja Carga trae las columnas de `VTA_PAINT_Z` y la consulta 3 de `d03_valida.sql` (cambiando `'FACO'` por `'SFCL'` y la fecha y el local) no muestra filas.

## Limpieza

`d09_limpia.sql` con `v_ejecutar = 'N'` (cuenta) y después `'S'`. Deja el 27-10-2026 del local 5 sin libvta, zzz, termstat ni termstaty de la carga masiva. Las cargas quedan en `VTA_FACOCARGA_YZ_*` como historial.

## Resultado (completar en test)

| Paso | Resultado | Fecha | Observaciones |
|---|---|---|---|
| d00 | | | |
| 1 | | | |
| 2 | | | |
| 3 | | | |
| 4 | | | |
| 5 | | | |
| 6 | | | |
| d09 | | | |
