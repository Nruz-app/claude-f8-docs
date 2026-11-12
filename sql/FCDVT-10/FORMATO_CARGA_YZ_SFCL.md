# Formato del CSV de carga masiva de cierres Y / Z — Tottus Chile (SFCL)

FCDVT-10 (HU-03). Base: `docs/sql/FCDVT-14/FORMATO_CARGA_Y_FACO.md`. Separador `;`, una fila por cierre, fila 1 = encabezado.

## 1. Encabezado

El encabezado **no es fijo**: lo arma `PKG_F8_CARGA_MASIVA_YZ_SFCL.fn_encabezado('SFCL')` desde `VTA_PAINT_Z` (`vta_localiz = 'SFCL'`, orden `vta_order_z`), igual que la grilla de Form19 / Form19Y. Para verlo: `06_pruebas.sql`, consulta 1, o Exportar Excel de Form174.

- Columnas 1 a 11: identificación, iguales a FACO.
- Columnas 12 en adelante: un monto por concepto editable (`vta_pop_up = 0`), con el nombre de `vta_cmp_asoc`.
- No van: títulos (`vta_pop_up` 1 y 2), totales (`vta_pop_up` 3, los calcula el sistema) ni conceptos `VTA_` editables fuera de las filas 2 a 6 (Form19Y no los graba; `00_prechecks.sql` §4 los lista).

La plantilla del DF (hoja F8-LV-CMP-TES, fila 33) muestra unos 80 conceptos de Tottus. El número exacto de columnas depende de `VTA_PAINT_Z` de la base y se confirma con los prechecks §1.

## 2. Identificación (columnas 1 a 11)

| # | Columna | INGRESAR | MODIFICAR | Uso al grabar |
|---|---|---|---|---|
| 1 | `FECHA` | Obligatoria, dd-mm-yyyy, anterior a hoy | Igual | `vta_fecha`, `vta_fecha_venta`, `rec_fechaproceso`, `ter_fecha` |
| 2 | `LOCAL` | Obligatorio | Obligatorio | `vta_local` |
| 3 | `TERMINAL` | Obligatorio, vigente a la fecha | Igual | `vta_terminal` |
| 4 | `NRO_Y` | Opcional (vacío = siguiente al mayor informado); 1 a 98. En la Z se ignora | **Obligatorio en la Y** (la Y que se modifica) | `vta_secuencia` |
| 5 | `HORA` | Obligatoria, HH:MM | Se valida si viene; no se usa | `vta_hora` (HHMM) |
| 6 | `SECUENCIA` | Obligatoria | Ídem | `vta_secuencia_srx` |
| 7 | `NUM_BOLETA` | Obligatorio | Ídem | `vta_bolfinal`, `vta_cantbol` |
| 8 | `VENDEDOR` | Obligatorio, ≤ 10 dígitos | Ídem | `vta_vendedor` |
| 9 | `CONT_REPOSICION` | Obligatorio | Ídem | `vta_crepo_inicial` / `vta_crepo_final` |
| 10 | `TIPO` | `Y` o `Z` | Igual | `F8`/99 (Z) o `Y`/N |
| 11 | `TIPO_CARGA` | `INGRESAR` | `MODIFICAR` | — |

Igual que en FACO, cada campo va a su columna correcta (Form19Y de SFCL graba `vta_secuencia_srx` = hora).

## 3. Montos (columnas 12 en adelante)

- Enteros, sin separador de miles ni decimales, con signo menos si corresponde; hasta 12 dígitos.
- **INGRESAR:** vacío = 0. **MODIFICAR:** vacío = no cambia; al menos un monto informado.
- Filas 2 a 6 de `VTA_PAINT_Z` (conceptos de venta) → `VTA_SFCLLIBVTA`: BOLETAS → `vta_montobol`, N.CREDITO → `vta_montoncr`, FACTURA → `vta_montofac`, N.DEBITO → `vta_mmontondb`, GUIA FACTURABLES → `vta_montoguia`; `vta_totalvta` = su suma (fila 7, como Form19Y).
- Resto → la columna `vta_cmp_asoc` de `VTA_SFCLZZZ`. Los totales de zzz (`vta_pop_up` 3) se graban en 0.

## 4. Reglas por terminal-día

| | INGRESAR | MODIFICAR |
|---|---|---|
| Filas | 1 Z y 0 o más Y | 0 o 1 Z y cualquier número de Y; todas deben existir |
| Sin Y | Cargar crea la **Y1** copiando la Z (Form19.GrabaYprima) | — |
| Cuadratura | Total de venta Z = suma de las Y (si hay Y) y fórmula de `VTA_PAINT_Z` de la Z (`vta_validadorzzz` / `vta_signo`, como `FuncMontoValidaZZZ`). Buscar la valida con el archivo y Cargar de nuevo en la base | Cargar la valida sobre el resultado (base + cambios): Z = suma de **todas** las Y del día; la fórmula, si se modificó la Z |
| Cerrados | Rechaza si la Z o alguna Y del día está cerrada (estado 1 o 2) | Rechaza si la Z del día o la Y modificada está cerrada |
| Grabado | Reemplaza la Z y todas las Y del día (como Form19) | `update` de las columnas informadas en libvta y zzz; no crea ni borra filas ni toca termstat(y) |
| Mezcla | Un terminal-día no puede mezclar INGRESAR y MODIFICAR | |

## 5. Ejemplo (primeras 15 columnas)

```
FECHA;LOCAL;TERMINAL;NRO_Y;HORA;SECUENCIA;NUM_BOLETA;VENDEDOR;CONT_REPOSICION;TIPO;TIPO_CARGA;<BOLETAS>;<N.CREDITO>;<FACTURA>;<N.DEBITO>
10-11-2026;216;6;;21:00;102;5002;93343;2918;Z;INGRESAR;300000;0;0;0
10-11-2026;216;6;1;12:00;101;5001;93343;2918;Y;INGRESAR;100000;0;0;0
10-11-2026;216;6;2;18:00;102;5002;93343;2918;Y;INGRESAR;200000;0;0;0
```

`<BOLETAS>` etc. son los `vta_cmp_asoc` reales de `VTA_PAINT_Z` (prechecks §1). Un MODIFICAR de la Y 2:

```
10-11-2026;216;6;2;;;;;;Y;MODIFICAR;150000;;;
```

(y la Z con BOLETAS 250000 en otra fila MODIFICAR, para que la Z siga igual a la suma de las Y).
