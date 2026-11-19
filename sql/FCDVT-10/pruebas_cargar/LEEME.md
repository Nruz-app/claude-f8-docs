# FCDVT-10: archivos de prueba de Cargar (Form174) — Tottus Chile (SFCL)

Creados el 18-11-2026. Son el equivalente para Tottus de `docs/sql/FCDVT-14/pruebas_cargar/`: CSV listos para **Buscar** y **Cargar** en `Form174` ("Ingreso del YYY Masivo").

**19-11-2026: la carga de Tottus sigue las reglas de Colombia** (solo INGRESAR, 1 Z y al menos 1 Y, Z = ΣY, sin fórmula de la Z, cerrados y `NRO_Y` 99 recién en Cargar). Los CSV no cambian; cambian los resultados esperados de `s03` (T6), `s07`, `s08`, `s09` y `s10`, que ahora sirven como casos de error. La versión anterior de este índice está en `../anterior_2026-11-19/pruebas_cargar/`.

- **Formato:** el de `../FORMATO_CARGA_YZ_SFCL.md`: 74 columnas (11 de identificación + 63 conceptos), separador `;`, ASCII y CRLF.
- **Encabezado:** fijo, como en Colombia: `PKG_F8_CARGA_MASIVA_YZ_SFCL.c_encabezado` (desde el 19-11-2026). `encabezado.txt` es esa misma lista (exportada de test el 18-11-2026, cuando salía de `VTA_PAINT_Z`) y `paint_z_sfcl.csv` el `VTA_PAINT_Z` completo (81 filas), que queda solo como referencia de las glosas.
- **Datos:** local **116 – HUECHURABA** (activo y el de más movimiento en la base de test). Fechas **17-11-2026** (`s01`, `s02`, `s04`, `s05`, `s06`, `s09`) y **16-11-2026** (`s03`, `s07`, `s08`, `s09`, `s10`). La data histórica de SFCL llega al 15-10-2026, así que esos días están libres.
- **Terminales:** verificados sin `VTA_SFCLLIBVTA` (F8/Y de ese día), sin `termstat`/`termstaty` y sin cargas masivas previas: 17-11 → T1, T5, T6, T7 y T8; 16-11 → T1, T4, T5, T6, T7 y T8. Si la base cambió desde el 18-11-2026, revisarlos con `../06_pruebas.sql` antes de cargar.
- **Cuadratura:** en los grupos correctos la Z es la suma de sus Y concepto a concepto (solo se usa BOLETAS como venta y EFECTIVO como pago, con el mismo monto). Lo verifica `arma_csv.ps1` antes de escribir cada archivo (también revisa la fórmula de la Z de `VTA_PAINT_Z`, que el package ya no valida).

## Antes de empezar

1. `INSTALAR.sql` ejecutado en test: los dos packages `PKG_F8_CARGA_MASIVA_YZ_SFCL` y `PKG_F8_GRABA_MASIVA_YZ_SFCL` en **VALID** (al 18-11-2026 lo están).
2. Exe compilado con `Form174` y `MDIForm1` de FCDVT-10 (bloque SFCL del 18-11-2026).
3. `01_menu_ingreso_masivo_y_sfcl.sql` ejecutado y un usuario de Tottus con el permiso 460.
4. Entrar a F8 con el usuario de Tottus, **local 116**, y la fecha del archivo.

Cómo se prueba cada archivo: botón **Y** ▸ "Ingreso del YYY Masivo" ▸ **Buscar** con el CSV ▸ revisar la grilla (Local, Terminal, Fecha, Cant. Y, Monto Total Y, Monto Total Z, Estado) ▸ **Cargar** ▸ revisar la grilla y el mensaje. Un clic en una fila abre `Form175` con el log del grupo, incluida la línea `GRABADO`.

## Resumen

| Orden | Archivo | Fecha | Terminales | Requiere | Resultado esperado |
|---|---|---|---|---|---|
| 1 | `s01_ok.csv` | 17-11-2026 | T1 | — | 1 grupo GRABADO |
| 2 | `s02_dos_terminales.csv` | 17-11-2026 | T5 y T6 | — | 2 grupos GRABADOS |
| 3 | `s03_mixto.csv` | 16-11-2026 | T1, T4, T5 y T6 | — | Buscar: 2 CARGADO y 2 ERROR; Cargar: 1 GRABADO y 1 ERROR (T6, Y 99) |
| 4 | `s04_reemplazo_v1.csv` | 17-11-2026 | T7 | — | 1 GRABADO (Z + 3 Y) |
| 5 | `s05_reemplazo_v2.csv` | 17-11-2026 | T7 | `s04` | 1 GRABADO, reemplaza lo de `s04` |
| 6 | `s06_numeracion.csv` | 17-11-2026 | T8 | — | 1 GRABADO (Y 2, 3 y 1) |
| 7 | `s07_modificar.csv` | 16-11-2026 | T1 | — | 1 grupo ERROR (MODIFICAR no habilitado) |
| 8 | `s08_z_sin_y.csv` | 16-11-2026 | T7 | — | 1 grupo ERROR ("Sin filas Y.") |
| 9 | `s09_errores.csv` | 17-11-2026 y 16-11-2026 | T5, T6 y T8 | — | 2 ERROR (MODIFICAR) y 1 CARGADO → GRABADO (T8) |
| 10 | `s10_y_cerrada.sql` + `s05` | 17-11-2026 | T7 | `s04` y `s05` | Buscar CARGADO; Cargar ERROR (Y cerrada) |

`s05` va después de `s04` y `s10` después de `s05`. El resto se puede cargar en cualquier orden (los casos de error no graban nada).

## s01_ok.csv: un terminal-día correcto (17-11-2026, T1)

| Fila | Tipo | `NRO_Y` | Hora | Monto | Total |
|---|---|---|---|---|---|
| 2 | Z | vacío | 21:00 | 890.000 | 890.000 |
| 3 | Y | 1 | 12:00 | 500.000 | 500.000 |
| 4 | Y | 2 | 18:00 | 390.000 | 390.000 |

- **Buscar:** grupo `CARGADO` (Total Y = Total Z = 890.000), mensaje "Total Z = suma de las Y".
- **Cargar:** GRABADO, "Grabado: Z + 2 Y (numeros 1 a 2)".
- **En la base:** 1 `F8`/99 y 2 `Y` (1 y 2) en `VTA_SFCLLIBVTA`; 3 `VTA_SFCLTERMSTATY` en −1; la `termstat` de la Z se crea en −1 si no existía.

## s02_dos_terminales.csv: dos terminal-día correctos (17-11-2026, T5 y T6)

| Grupo | Filas | Total Z = ΣY | Mensaje de Cargar |
|---|---|---|---|
| T5 | Z + 3 Y con `NRO_Y` **vacío** | 2.000.000 (700.000 + 650.000 + 650.000) | "Grabado: Z + 3 Y (numeros 1 a 3)" |
| T6 | Z + Y1 + Y2 | 1.120.000 (600.000 + 520.000) | "Grabado: Z + 2 Y (numeros 1 a 2)" |

En T5 Cargar asigna a las tres Y los números 1, 2 y 3 en el orden del archivo (no hay `NRO_Y` informado). `Form175` muestra el número asignado en la columna "N° Y".

## s03_mixto.csv: un caso por resultado (16-11-2026)

| Grupo | Caso | Buscar | Cargar |
|---|---|---|---|
| T1 | Correcto, 2 Y (Z 1.250.000 = 800.000 + 450.000) | CARGADO | GRABADO, "Grabado: Z + 2 Y (numeros 1 a 2)" |
| T4 | Z 741.000 contra Y 400.000 + 340.000 = 740.000 | ERROR: "Total Z (741000) distinto de la suma de las Y (740000)." | No se toca (no está CARGADO) |
| T5 | La Y2 trae `VENDEDOR` `12345678901` (11 dígitos) | ERROR: "1 fila(s) con error (ver log)." En el log: LECTURA, VENDEDOR, "Maximo 10 digitos (vta_vendedor es NUMBER(10))" | No se toca |
| T6 | Y con `NRO_Y` = 99 | CARGADO (Total Z = suma de las Y = 350.000) | ERROR: "No se grabo: Linea 12: numero de Y 99 fuera de rango (1 a 98; el 99 es la Z)"; no graba nada del grupo |

Igual que Colombia (FCDVT-14): Buscar no limita `NRO_Y` y el 99 se rechaza recién en Cargar.

## s04_reemplazo_v1.csv: primera carga de un terminal-día (17-11-2026, T7)

Z 1.750.000 con 3 Y sin `NRO_Y` (600.000 + 550.000 + 600.000).

- **Buscar:** CARGADO (Total Y = Total Z = 1.750.000).
- **Cargar:** "Grabado: Z + 3 Y (numeros 1 a 3)". **No** trae el aviso de reemplazo porque el terminal-día estaba vacío.
- Deja la base para `s05`: la Z pasa a 1.750.000 y quedan las Y 1, 2 y 3.

## s05_reemplazo_v2.csv: reemplazo de lo grabado por s04 (17-11-2026, T7)

Z 1.860.000 con Y1 900.000 e Y2 960.000.

- **Cargar después de `s04`:** "Grabado: Z + 2 Y (numeros 1 a 2). Reemplazo lo anterior: 1 Z y 3 Y".
- **En la base:** la Z y las Y del día se borran y se vuelven a insertar (como Form19), así que **la Y3 de `s04` desaparece con su `termstaty`**; quedan las Y 1 y 2. La `termstat` de la Z en −1 se conserva (la creó `s04`).
- Si se corre `s05` dos veces seguidas, la segunda informa "Reemplazo lo anterior: 1 Z y 2 Y".

## s06_numeracion.csv: numeración de Y (17-11-2026, T8)

Tres Y con `NRO_Y` [vacío, vacío, 1] y la Z (680.000). Cargar asigna a cada Y vacía el siguiente al mayor informado, en el orden del archivo (ver `../FORMATO_CARGA_YZ_SFCL.md` §4):

| Línea | `NRO_Y` en el archivo | Y grabada | Total |
|---|---|---|---|
| 2 | vacío | 2 | 210.000 |
| 3 | vacío | 3 | 320.000 |
| 4 | 1 | 1 | 150.000 |

- **Buscar:** CARGADO (Total Y = Total Z = 680.000).
- **Cargar:** "Grabado: Z + 3 Y (numeros 1 a 3)". `Form175` muestra el número asignado en la columna "N° Y".

## s07_modificar.csv: MODIFICAR no habilitado (16-11-2026, T1)

Dos filas con `TIPO_CARGA = MODIFICAR` (la Z y la Y1), con la identificación vacía salvo fecha, local, terminal y `NRO_Y`.

- **Buscar:** grupo ERROR, "2 fila(s) con error (ver log)." En el log, por cada fila: LECTURA, TIPO_CARGA, "MODIFICAR todavia no esta habilitado; solo INGRESAR", y "Campo obligatorio vacio" en HORA, SECUENCIA, NUM_BOLETA, VENDEDOR y CONT_REPOSICION.
- **Cargar:** no hay grupos CARGADO; la base no cambia.

## s08_z_sin_y.csv: Z sin Y (16-11-2026, T7)

Una sola fila: la Z del terminal por 400.000.

- **Buscar:** grupo ERROR, "Sin filas Y." (igual que Colombia: cada terminal-día lleva 1 Z y al menos 1 Y; ya no hay Y1 automática).
- **Cargar:** no hay grupos CARGADO; la base no cambia.

## s09_errores.csv: MODIFICAR y un grupo correcto (17-11-2026 y 16-11-2026)

| Grupo | Caso | Buscar | Cargar |
|---|---|---|---|
| 17-11 T5 | `MODIFICAR` de la Y 7 | ERROR: "1 fila(s) con error (ver log). Sin fila Z." En el log: TIPO_CARGA, "MODIFICAR todavia no esta habilitado; solo INGRESAR" | No se toca |
| 17-11 T6 | Una Y `INGRESAR` y una Y `MODIFICAR` | ERROR: "1 fila(s) con error (ver log). Sin fila Z." | No se toca |
| 16-11 T8 | Z 500.000 = Y1 500.000, con TRANSBANK 50.000 de más en la Z | CARGADO, "Total Z = suma de las Y" | GRABADO, "Grabado: Z + 1 Y (numeros 1 a 1)" |

El grupo de T8 era el caso de la fórmula de la Z descuadrada: como Colombia no valida esa fórmula, ahora pasa. Si no se quiere grabar, no usar Cargar con este archivo, o limpiarlo después con `98_limpia_prueba.sql`.

## s10_y_cerrada.sql: Y cerrada (17-11-2026, T7)

Requiere `s04` y `s05` grabados (T7 con las Y 1 y 2 en −1). El script es DML y se ejecuta a mano, por partes (`v_parte`):

1. `v_parte = 1` cierra a mano la Y 1 (`VTA_SFCLTERMSTATY.ter_estado = 1`).
2. **Buscar** `s05_reemplazo_v2.csv` (o `s04`): CARGADO (igual que Colombia, Buscar no revisa los cierres).
3. **Cargar** ese mismo archivo: no graba nada. En la grilla el grupo queda en ERROR con "No se grabo: El terminal tiene 1 cierre(s) Y cerrado(s) (termstaty estado 1 o 2); no se reemplaza", y la base del 17-11 T7 queda igual que antes.
4. `v_parte = 2` reabre la Y 1 (`ter_estado = -1`).

Cerrarla desde la F8 (Form3Y) también sirve, pero lo que grabe ese cierre además de `termstaty` no lo revierte ni este script ni `98_limpia_prueba.sql`.

## Verificar en la base

`../06_pruebas.sql` (solo lectura; completar fecha y local 116 en las líneas `-- EDITAR`):

- consulta 1: encabezado que espera Buscar;
- consultas 3 a 5: cargas, resumen por grupo y log;
- consulta 6: libvta y zzz por terminal (1 `F8`/99 y las `Y`);
- consulta 7: identificación grabada (hora, secuencia, boleta, vendedor, contador de reposición);
- consulta 8: estados de `termstat` / `termstaty`;
- consulta 9: huérfanas y Z = ΣY.

Para el detalle de una carga, `Form175` (clic en la fila de la grilla).

## Limpieza

`../98_limpia_prueba.sql` con el número de carga que informó Cargar: primero con `v_ejecutar = 'N'` (solo cuenta) y después con `'S'` (borra y hace commit).
- Deshace los grupos que quedaron **GRABADO** y los deja en `CARGADO`; los grupos en ERROR no se tocan.
- Empezar por la última carga. Si se limpia una carga anterior a un reemplazo, también se borran los cierres que grabó la carga siguiente sobre ese terminal-día.
- Antes de limpiar, reabrir la Y que haya cerrado `s10` (parte 2).
- No revierte `VTA_SFCLTARJ` ni los movimientos 'AL'; el script trae la consulta para verlos.

## Regenerar o cambiar local / fecha / montos

`arma_csv.ps1` arma los nueve CSV desde `encabezado.txt` y `paint_z_sfcl.csv`, y se detiene si:

- el encabezado no coincide con el que sale de `VTA_PAINT_Z`;
- alguna línea no tiene 74 campos;
- en un grupo correcto la Z no es igual a la suma de las Y;
- la fórmula de la Z da distinto de 0 (salvo en el grupo de `s09` que la descuadra a propósito);
- en `s07` la Z modificada no cuadra con la Y1 modificada más la Y2 que deja `s03`.

(Los dos últimos controles vienen de la versión anterior y se dejaron: no afectan a los CSV.)

```
powershell -NoProfile -ExecutionPolicy Bypass -File .\arma_csv.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\arma_csv.ps1 -Local 116 `
    -FechaA 17-11-2026 -TermA 1,5,6 -FechaB 16-11-2026 -TermB 1,4,5,6 `
    -TermReemp 7 -TermNum 8 -TermZSinY 7 -TermErr 8
```

`TermA` son los terminales de `s01` y `s02` (3), `TermReemp` el de `s04`/`s05`, `TermNum` el de `s06`, `TermB` los 4 de `s03` (el primero también es el de `s07`), `TermZSinY` el de `s08` y `TermErr` el de `s09`.

Si se cambia el local o las fechas, antes hay que confirmar que los terminales estén libres (consultas 6 y 7 de `../prueba_recarga_v1_v2/py0_prechecks.sql`, cambiando la fecha). Si Tottus agrega un concepto, primero hay que sumarlo a la lista fija (`02`, `03`, `04` y `04c`), después actualizar `encabezado.txt` y correr el generador: Buscar compara el encabezado completo.

## Archivos

| Archivo | Qué es |
|---|---|
| `encabezado.txt` | Encabezado de 74 columnas (= `c_encabezado`) |
| `paint_z_sfcl.csv` | `VTA_PAINT_Z` de SFCL en orden `vta_order_z` (81 filas; glosas en Windows-1252) |
| `s01_ok.csv` | Un terminal-día correcto |
| `s02_dos_terminales.csv` | Dos terminal-día correctos, uno con `NRO_Y` vacío |
| `s03_mixto.csv` | Un grupo correcto y tres con error esperado |
| `s04_reemplazo_v1.csv` | Primera carga de un terminal-día (3 Y sin `NRO_Y`) |
| `s05_reemplazo_v2.csv` | Reemplazo de `s04` (de 3 Y a 2 Y) |
| `s06_numeracion.csv` | Numeración automática de las Y |
| `s07_modificar.csv` | MODIFICAR (rechazado: no habilitado) |
| `s08_z_sin_y.csv` | Z sin Y (rechazado) |
| `s09_errores.csv` | Dos grupos con MODIFICAR (rechazados) y uno correcto |
| `s10_y_cerrada.sql` | Cierra y reabre una Y para probar el rechazo de Cargar |
| `arma_csv.ps1` | Generador y validador de los nueve CSV |
