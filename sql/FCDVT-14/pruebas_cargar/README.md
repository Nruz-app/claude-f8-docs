# FCDVT-14: archivos de prueba de Cargar (Form174)

Creados el 04-11-2026. Prueban el botón **Cargar** de Form174 (`PKG_F8_GRABA_MASIVA_YZ.prc_graba`, pasos `04b`/`04c`) de punta a punta. La etapa Buscar se prueba con `../pruebas/`, que no graba.

- **Formato:** el de `../FORMATO_CARGA_Y_FACO.md`: 56 columnas, `;`, ASCII y CRLF.
- **Datos:** local 5, terminales 1 a 3, fechas del 20 al 23-10-2026. Esas fechas no las usan los otros CSV.
- **Cuadratura:** en los grupos correctos, la Z es la suma de sus Y concepto a concepto, así que total Z = Σ total Y. Se verificó con un script antes de entregarlos.
- **Esta prueba graba en test.** Cargar **reemplaza** la Z y las Y de cada terminal-día. Al terminar, limpiar con `../98_limpia_prueba.sql`.

## Antes de empezar

1. `INSTALAR.sql` en test (con los dos packages) y compilar el exe.
2. `c00_prechecks.sql`, que es solo lectura:
   - los terminales 1, 2 y 3 deben estar vigentes;
   - lo ideal es que esas fechas no tengan cierres. Si los tienen, Cargar los reemplaza; para no perderlos, cambiar la columna FECHA de los CSV;
   - no debe haber ninguna Z ni Y cerrada;
   - los dos packages deben estar en VALID.

Cómo se prueba cada archivo: F8 ▸ botón Y ▸ "Ingreso del YYY Masivo" ▸ **Buscar** con el CSV ▸ revisar la grilla ▸ **Cargar** ▸ revisar la grilla y el mensaje. El mensaje de Buscar y el de Cargar informan el número de carga.

Para revisar la base, usar `../06_pruebas.sql` con la fecha y el local 5:
- la consulta 6 muestra libvta y zzz por terminal;
- la 7, la identificación grabada;
- la 8, los estados;
- la 9, las huérfanas y Z = ΣY.

Un clic en una fila de la grilla abre Form175 con el log del grupo, incluida la línea GRABADO.

## Resumen

| Orden | Archivo | Buscar (grupos OK / error / líneas con error) | Cargar (grabados / no grabados) |
|---|---|---|---|
| 1 | `c01_ok.csv` | 2 / 0 / 0 | 2 / 0 |
| 2 | `c02_mixto.csv` | 2 / 2 / 1 | 1 / 1 |
| 3 | `c03_reemplazo.csv` (después de c01) | 1 / 0 / 0 | 1 / 0, y reemplaza |
| 4 | `c04_numeracion.csv` | 1 / 0 / 0 | 1 / 0 |
| 5 | `c05_y_cerrada.sql` + `c01_ok.csv` | 2 / 0 / 0 | 1 / 1 |

## c01_ok.csv: dos terminal-día correctos (20-10-2026)

| Grupo | Filas | Total Z = ΣY | Después de Cargar |
|---|---|---|---|
| T1 | 3 Y sin `NRO_Y` + Z | 2.050.000 | GRABADO, "Grabado: Z + 3 Y (numeros 1 a 3)" |
| T2 | Y `NRO_Y` 1 y 2 + Z | 890.000 | GRABADO, "Grabado: Z + 2 Y (numeros 1 a 2)" |

En la base (`06`, consultas 6 a 8, fecha 20-10-2026):
- **libvta:** T1 tiene 1 `F8`/99 y 3 `Y` (1-3); T2 tiene 1 `F8`/99 y 2 `Y` (1-2). `sin_zzz` debe dar 0.
- **Identificación** (consulta 7), cada campo en su columna. Por ejemplo, en T1 Y1:
  - `vta_hora` = 1015;
  - `vta_secuencia_srx` = 2101;
  - `vta_bolfinal` = 300120;
  - `vta_vendedor` = 71001;
  - `vta_crepo_inicial` = `vta_crepo_final` = 4101;
  - `vta_totalvta` = 800.000.
- **termstaty:** 5 filas en −1 con `CARGA MASIVA DE CIERRE Y - CARGA <n>`.
- **termstat:** la precreada en −1 se conserva. Si no existía, se crea con `CARGA MASIVA DE CIERRE Z - CARGA <n>`.
- En la F8 (Form3Y) del 20-10, local 5, se ven las Y. En Form19Y, la columna "Valor Z" muestra la Z.

## c02_mixto.csv: un caso por resultado (21 y 22-10-2026)

| Grupo | Caso | Buscar | Cargar |
|---|---|---|---|
| 21-10 T1 | Correcto, 2 Y | CARGADO (1.250.000) | GRABADO |
| 21-10 T2 | Z = ΣY + 1.000 (BOLETAS y EFECTIVO) | ERROR: "Total Z (741000) distinto de la suma de las Y (740000)." | No se toca (no está CARGADO) |
| 21-10 T3 | La 2.ª Y tiene VENDEDOR `12345678901` (11 dígitos) | ERROR: "1 fila(s) con error (ver log)." En el log: LECTURA, VENDEDOR, "Maximo 10 digitos (vta_vendedor es NUMBER(10))" | No se toca |
| 22-10 T1 | Y con `NRO_Y` = 99 | CARGADO (350.000), porque Buscar no limita el número | ERROR: "No se grabo: Linea 11: numero de Y 99 fuera de rango (1 a 98; el 99 es la Z)". En la base no se graba nada del 22-10 |

## c03_reemplazo.csv: reemplazo de lo grabado por c01 (20-10-2026, T1)

Ejecutarlo **después** de grabar c01. Trae una Z y 2 Y con otros montos (total 1.860.000).
- **Cargar:** GRABADO, con el mensaje "Grabado: Z + 2 Y (numeros 1 a 2). Reemplazo lo anterior: 1 Z y 3 Y".
- **En la base,** 20-10 T1:
  - 1 `F8`/99 con 1.860.000 y 2 `Y` (1 y 2). La Y 3 de c01 desaparece, junto con su termstaty;
  - la consulta 9 da la misma cantidad de zzz huérfanas que antes de Cargar, porque el reemplazo borra las zzz viejas;
  - T2 (de c01) no cambia.

## c04_numeracion.csv: numeración de Y (23-10-2026, T1)

Tres Y con `NRO_Y` [vacío, vacío, 1] y la Z (680.000). Cargar asigna a cada Y vacía el siguiente al mayor informado, en el orden del archivo (FORMATO §3.1):

| Línea | `NRO_Y` en el archivo | Y grabada | Total |
|---|---|---|---|
| 2 | vacío | 2 | 210.000 |
| 3 | vacío | 3 | 320.000 |
| 4 | 1 | 1 | 150.000 |

Form175 muestra el número asignado en la columna "N° Y".

## c05: Y cerrada (20-10-2026, T2)

Ver `c05_y_cerrada.sql`. Hay dos formas de dejar cerrada la Y 1 del T2 grabada por c01:
- usar la parte 1 del script (recomendado);
- cerrarla desde la F8. La parte 2 la reabre igual, pero lo que haya grabado ese cierre además de la termstaty no lo revierten ni el script ni `98_limpia_prueba.sql`.

Después:
1. Buscar y Cargar con `c01_ok.csv`. T1 queda en GRABADO (reemplaza). T2 queda en **ERROR**, con el mensaje "El terminal tiene 1 cierre(s) Y cerrado(s) (termstaty estado 1 o 2); no se reemplaza", y en la base queda igual.
2. Reabrir la Y con la parte 2 del script.

## Limpieza

Por cada carga que haya grabado algo, ejecutar `../98_limpia_prueba.sql` con su número: primero con `v_ejecutar = 'N'`, que solo cuenta, y después con `'S'`.
- **Orden:** empezar por la última carga. Si se limpia una carga anterior a un reemplazo, también se borran los cierres que grabó la carga siguiente sobre ese terminal-día.
- **termstat:** la de la Z se borra solo si la creó la carga, es decir, si tiene su glosa. Las precreadas en −1 se conservan.
- **c05:** reabrir la Y (parte 2) **antes** de limpiar; `98` borra las termstaty con la glosa de la carga sin mirar el estado.

## Validaciones de tamaño (Buscar)

Desde el 04-11, Buscar marca ERROR de LECTURA, antes de llegar a Cargar, en dos casos:
- VENDEDOR de más de 10 dígitos (`vta_vendedor NUMBER(10)`). Se prueba en c02, 21-10 T3;
- un monto de más de 12 dígitos (columnas `NUMBER(15,2)`). Para probarlo, poner `1234567890123` en un monto de cualquier línea.
