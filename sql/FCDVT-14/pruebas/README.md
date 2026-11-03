# FCDVT-14: archivos de prueba de Buscar (Form174)

Creados el 03-11-2026. Complementan `../ejemplo_carga_Y_FACO_20.csv` (todo cuadra) y `../ejemplo_carga_YZ_FACO_errores.csv` (mezcla). Cada archivo prueba **un tipo de caso**, y cada caso usa una fecha o un terminal distinto, así que cada fila de la grilla de Form174 corresponde a un solo motivo.

- Formato: el de `../FORMATO_CARGA_Y_FACO.md` (56 columnas, `;`, ASCII, CRLF).
- Datos: local 5, terminales 1 a 3 (vigentes en test) y fechas anteriores al 03-11-2026. En las filas que no prueban un campo, los montos están en 0, salvo BOLETAS y EFECTIVO.
- Los resultados esperados se verificaron reproduciendo las reglas de `PKG_F8_CARGA_MASIVA_YZ` (`../04_pkg_carga_masiva_yz_body.sql`) sobre cada archivo.
- Cómo comparar: F8 ▸ botón Y ▸ "Ingreso del YYY Masivo" ▸ Buscar con el archivo. Después, `../06_pruebas.sql` con el número de carga que muestra el mensaje: la consulta 2 da el resumen (la grilla) y la consulta 3, el log.
- "Líneas con error" del mensaje de Form174 = líneas en ERROR, con grupo o sin él.

## Resumen

| Archivo | Filas | Mensaje de Form174 (grupos OK / con error / líneas con error) |
|---|---|---|
| `p01_campos_malos.csv` | 35 | 1 / 14 / 19 |
| `p02_falta_z.csv` | 16 | 3 / 3 / 0 |
| `p03_cuadratura.csv` | 10 | 3 / 1 / 0 |
| `p04_nro_y.csv` | 10 | 2 / 1 / 1 |
| `p05_estructura.csv` | 9 | 1 / 1 / 4 |
| `p06_encabezado_54.csv` | 3 | Carga rechazada: grilla vacía y aviso "el archivo no generó ningún resumen" |
| `p07_solo_encabezado.csv` | 0 | Grilla vacía, mismo aviso |
| `p08_volumen.csv` | 630 | 90 / 0 / 0 |

Un archivo de 0 bytes da "El archivo esta vacio" antes de llamar a la base. No se incluye: basta con crear un `.csv` vacío.

## p01: campos malos

Un grupo por campo malo. El terminal 2 tiene su Z correcta y una Y con un solo campo malo, en una fecha distinta en cada caso. Cada grupo queda en ERROR con "1 fila(s) con error (ver log)." y una sola línea en el log (etapa LECTURA).

| Línea | Fecha / terminal | Campo malo | Motivo en el log |
|---|---|---|---|
| 2-4 | 01-10 T1 | — (control: Z + 2 Y) | PROCESADO, total 300.000 |
| 6 | 02-10 T2 | `HORA = 25:00` | Hora fuera de rango (00:00 a 23:59) |
| 8 | 03-10 T2 | `HORA = 1800` | Formato distinto de HH:MM |
| 10 | 04-10 T2 | `SECUENCIA` vacía | Campo obligatorio vacio |
| 12 | 05-10 T2 | `NUM_BOLETA = 5O01` (letra O) | No es un numero entero |
| 14 | 06-10 T2 | `VENDEDOR` vacío | Campo obligatorio vacio |
| 16 | 07-10 T2 | `CONT_REPOSICION = -` | No es un numero entero |
| 18 | 08-10 T2 | `NRO_Y = 1.5` | No es un numero entero |
| 20 | 09-10 T2 | `TIPO` vacío | Debe ser Y o Z. El grupo dice además "Sin filas Y.", porque la línea no cuenta como Y |
| 22 | 10-10 T2 | `TIPO_CARGA = MODIFICAR` | MODIFICAR todavia no esta habilitado; solo INGRESAR |
| 24 | 11-10 T2 | `TIPO_CARGA = INSERTAR` | Debe ser INGRESAR |
| 26 | 12-10 T2 | `REC_MEFECTIVO = 1.200.000` | No es un numero entero (separador de miles) |
| 28 | 13-10 T2 | `REC_MEFECTIVO = 100,50` | No es un numero entero (decimales) |
| 30 | 17-10 T2 | `REC_MTARJ = abc` | No es un numero entero |
| 31-32 | 31-12-2099 T3 | `FECHA` futura, en la Z y en la Y | La fecha debe ser anterior a hoy (2 líneas). Grupo: "2 fila(s) con error (ver log)." |

**Líneas sin grupo** (no aparecen en la grilla; solo en el log y en "Líneas con error"):

| Línea | Campo malo | Motivo |
|---|---|---|
| 33 | `FECHA = 2026-10-01` | Formato distinto de dd-mm-yyyy |
| 34 | `FECHA = 31-09-2026` | Fecha inexistente |
| 35 | `LOCAL = 5a` | No es un numero entero |
| 36 | `TERMINAL` vacío | Campo obligatorio vacio |

## p02: falta la Z (y otros conteos de Z e Y)

Sin errores de campo: todo depende del resumen.

| Fecha / terminal | Contenido | Estado | `res_mensaje` |
|---|---|---|---|
| 20-10 T1 | Z + 2 Y (550.000) | PROCESADO | Total Z = suma de las Y |
| 20-10 T2 | **3 Y sin Z** (350.000) | ERROR | Sin fila Z. |
| 20-10 T3 | Z + 1 Y (400.000) | PROCESADO | |
| 21-10 T1 | **Z sin Y** (500.000) | ERROR | Sin filas Y. |
| 21-10 T2 | **2 Z** (las dos de 300.000) + 2 Y | ERROR | Tiene 2 filas Z; debe ser 1. (en la grilla, Monto Total Z = 600.000) |
| 21-10 T3 | Z + 2 Y (150.000) | PROCESADO | |

## p03: cuadratura (total Z contra la suma de las Y)

| Fecha / terminal | Caso | Estado | `res_mensaje` |
|---|---|---|---|
| 22-10 T1 | Z = 500.001, Y = 300.000 + 200.000 (**diferencia de 1 peso**) | ERROR | Total Z (500001) distinto de la suma de las Y (500000). |
| 22-10 T2 | Con N.CREDITO negativo (−30.000) y FACTURA (50.000): Z 400.000 − 30.000 + 50.000 = 420.000; Y (250.000 − 30.000) + (150.000 + 50.000) = 420.000 | PROCESADO | |
| 22-10 T3 | Z con BOLETAS 100.000 + FACTURA 50.000; Y con BOLETAS 150.000. Los conceptos no coinciden, pero el total sí | PROCESADO. Solo se compara el total; la consulta 5 de `06_pruebas.sql` muestra la diferencia por concepto |
| 23-10 T1 | Montos vacíos (= 0): solo BOLETAS informado (90.000) | PROCESADO | |

## p04: NRO_Y

| Fecha / terminal | Caso | Estado |
|---|---|---|
| 24-10 T1 | Dos Y con `NRO_Y = 1` | ERROR: "1 fila(s) con error (ver log).". Log: línea 4, etapa VALIDACION, campo NRO_Y, "NRO_Y repetido en el archivo para el mismo terminal y fecha" |
| 24-10 T2 | Y 1 e Y 2: los mismos números que T1, en otro terminal | PROCESADO |
| 24-10 T3 | `NRO_Y` vacío, 2 y vacío: dos vacíos no cuentan como repetidos | PROCESADO |

## p05: estructura de la línea

| Línea | Caso | Resultado |
|---|---|---|
| 1 | Encabezado con `;` final | Se acepta |
| 2 | Z con `;` final (57 campos, el último vacío) | Se acepta |
| 3 | Y con un espacio inicial, `TIPO = " y "` y `TIPO_CARGA = " ingresar "` | Se acepta (sin distinguir mayúsculas y sin espacios) |
| 4 y 5 | Línea vacía y línea `;;;;` | Form174 no las envía |
| 6 | Y con `y` / `Ingresar` y el monto `" 50000 "` con espacios | Se acepta |
| 7 | 55 campos | Sin grupo. Log LINEA: "La linea tiene 55 campos; deben ser 56" |
| 8 | 57 campos con dato en el último | Sin grupo. Log LINEA: 57 campos |
| 9-10 | Terminal 99 (Z + Y cuadradas) | Grupo 25-10 T99 en ERROR, "2 fila(s) con error". Log VALIDACION TERMINAL: "Local / terminal no existe o no esta vigente al 25-10-2026" |

Grilla: 25-10 T1 PROCESADO (150.000) y 25-10 T99 ERROR.

## p06 y p07: encabezado

- `p06_encabezado_54.csv`: encabezado anterior de **54 columnas** (sin `TIPO` ni `TIPO_CARGA`) y filas de 54 campos. El package registra la línea 1 en el log (campo ENCABEZADO) y `prc_procesa` termina con "Carga rechazada: el encabezado no es el de la plantilla". Las filas quedan en `VTA_FACOCARGA_YZ_DET` como líneas de 54 campos.
- `p07_solo_encabezado.csv`: encabezado correcto y ninguna fila. Sin grupos ni errores.

## p08: volumen

Del 01-09 al 30-09-2026, terminales 1 a 3, cada uno con 1 Z y 6 Y cuadradas: 630 filas y 90 grupos PROCESADO. Sirve para medir cuánto tarda Buscar, porque Form174 hace una llamada a la base por línea. Supone que los terminales 1 a 3 del local 5 estaban vigentes en septiembre (`ter_fechabaja` nula o posterior); si no, esos grupos salen con el error de terminal.
