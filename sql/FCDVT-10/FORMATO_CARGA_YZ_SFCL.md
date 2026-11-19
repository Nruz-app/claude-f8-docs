# Formato del CSV de carga masiva de cierres Y / Z — Tottus Chile (SFCL)

FCDVT-10 (HU-03). **Desde el 19-11-2026 tiene las mismas reglas que Colombia** (`docs/sql/FCDVT-14/FORMATO_CARGA_Y_FACO.md`); solo cambian las columnas de concepto. Separador `;`, una fila por cierre, fila 1 = encabezado. La versión anterior (encabezado desde `VTA_PAINT_Z`, MODIFICAR, Y1 automática y fórmula de la Z) está en `anterior_2026-11-19/FORMATO_CARGA_YZ_SFCL.md`.

## 1. Encabezado

Fijo, como en Colombia: es `PKG_F8_CARGA_MASIVA_YZ_SFCL.c_encabezado` (74 columnas) y lo devuelve `fn_encabezado('SFCL')`, que es lo que usa Exportar Excel de Form174. Copia: `pruebas_cargar/encabezado.txt`.

- Columnas 1 a 11: identificación, iguales a FACO.
- Columnas 12 a 16: los 5 conceptos de venta de Tottus (`VTA_MONTOBOL`, `VTA_MONTONCR`, `VTA_MONTOFAC`, `VTA_MMONTONDB`, `VTA_MONTOGUIA`), que van a `VTA_SFCLLIBVTA`.
- Columnas 17 a 74: los 58 conceptos de pago y otros de Tottus, que van a `VTA_SFCLZZZ` con el mismo nombre.

La lista sale de `VTA_PAINT_Z` de test (18-11-2026: conceptos editables, en `vta_order_z`), pero el package **ya no lee esa tabla**. Si Tottus agrega un concepto hay que sumarlo a la lista fija (`02`, `03`, `04` y `04c`), igual que en Colombia. `00_prechecks.sql` §2 avisa si `VTA_PAINT_Z` tiene un concepto editable que no está en la lista.

## 2. Identificación (columnas 1 a 11)

| # | Columna | Regla | Uso al grabar |
|---|---|---|---|
| 1 | `FECHA` | Obligatoria, dd-mm-yyyy, anterior a hoy | `vta_fecha`, `vta_fecha_venta`, `rec_fechaproceso`, `ter_fecha` |
| 2 | `LOCAL` | Obligatorio, entero | `vta_local` |
| 3 | `TERMINAL` | Obligatorio, entero, vigente a la fecha | `vta_terminal` |
| 4 | `NRO_Y` | Opcional (vacío = siguiente al mayor informado del grupo). En la Z se ignora. Debe quedar entre 1 y 98 (lo revisa Cargar) | `vta_secuencia` |
| 5 | `HORA` | Obligatoria, HH:MM | `vta_hora` (HHMM) |
| 6 | `SECUENCIA` | Obligatoria, entero | `vta_secuencia_srx` |
| 7 | `NUM_BOLETA` | Obligatorio, entero | `vta_bolfinal`, `vta_cantbol` |
| 8 | `VENDEDOR` | Obligatorio, entero, ≤ 10 dígitos | `vta_vendedor` |
| 9 | `CONT_REPOSICION` | Obligatorio, entero | `vta_crepo_inicial` / `vta_crepo_final` |
| 10 | `TIPO` | `Y` o `Z` | Z: `F8`/99; Y: `Y`/N |
| 11 | `TIPO_CARGA` | `INGRESAR` (MODIFICAR no está habilitado, igual que en Colombia) | — |

Cada campo va a su columna, igual que en FACO y que Form19 para la Z (Grid0: SECUENCIA, N° BOLETA, VENDEDOR, CONT. REPOSICION). Form19Y de Tottus graba esos datos corridos una fila (boleta = secuencia, vendedor = N° boleta, `vta_secuencia_srx` = hora); es un desfase del legado y no se copia.

## 3. Montos (columnas 12 a 74)

- Enteros, sin separador de miles ni decimales, con signo menos si corresponde; hasta 12 dígitos.
- **Vacío = 0**, como en Colombia.
- Venta → `VTA_SFCLLIBVTA`: `vta_montobol`, `vta_montoncr`, `vta_montofac`, `vta_mmontondb`, `vta_montoguia`; `vta_totalvta` = su suma (como `Form19.GrabarTerceraZZZ` rama SFCL).
- El resto → la columna del mismo nombre de `VTA_SFCLZZZ`. El trigger `TRG_VTA_SFCLZZZ_I` actualiza `VTA_SFCLTARJ` y el movimiento 'AL' (Cargar inserta la libvta antes de la zzz).

## 4. Reglas por terminal-día (las de Colombia)

| Etapa | Regla |
|---|---|
| Buscar (LECTURA) | 74 campos; formato de cada campo; TIPO Y/Z; TIPO_CARGA = INGRESAR |
| Buscar (VALIDACION) | Local / terminal vigente a la fecha; `NRO_Y` repetido en el archivo |
| Buscar (RESUMEN) | ERROR si hay filas con error, si no hay exactamente **1 Z**, si **no hay Y** o si el **total de venta de la Z ≠ suma de las Y** (total = BOLETAS + N.CREDITO + FACTURA + N.DEBITO + GUIA FACTURABLES). Si no, CARGADO |
| Cargar | Rechaza el grupo si la Z o alguna Y del día está cerrada (estado 1 o 2) o si un `NRO_Y` queda fuera de 1..98. **Reemplaza** la Z y todas las Y del día (como Form19) y deja termstat (si falta) y termstaty en −1. Commit o rollback por grupo → GRABADO / ERROR |

No hay MODIFICAR, ni Y1 automática, ni fórmula de la Z de `VTA_PAINT_Z`.

## 5. Ejemplo (primeras 15 columnas)

```
FECHA;LOCAL;TERMINAL;NRO_Y;HORA;SECUENCIA;NUM_BOLETA;VENDEDOR;CONT_REPOSICION;TIPO;TIPO_CARGA;VTA_MONTOBOL;VTA_MONTONCR;VTA_MONTOFAC;VTA_MMONTONDB
10-11-2026;216;6;;21:00;102;5002;93343;2918;Z;INGRESAR;300000;0;0;0
10-11-2026;216;6;1;12:00;101;5001;93343;2918;Y;INGRESAR;100000;0;0;0
10-11-2026;216;6;2;18:00;102;5002;93343;2918;Y;INGRESAR;200000;0;0;0
```

Cada línea real lleva las 74 columnas (vacío = 0).
