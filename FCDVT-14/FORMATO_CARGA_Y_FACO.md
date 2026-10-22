# FCDVT-14: formato del archivo de carga masiva de Y (inserción, FACO)

Plantilla: [`plantilla_carga_Y_FACO.csv`](plantilla_carga_Y_FACO.csv). Índice del ticket: [`../README_FCDVT-14.md`](../README_FCDVT-14.md).

**Alcance:** solo **inserción** de cierres Y de **Falabella Colombia (FACO)**. Update, Z y otros países quedan fuera.

## 1. Por qué no se usa la grilla del DF-SCC

La hoja F8-LV-CMP-TES del Excel del requerimiento no sirve para cargarla desde VB6:

- trae un bloque por empresa en la misma hoja, con títulos y celdas intermedias;
- usa glosas repetidas como encabezado (EFECTIVO ×3, CMR ×3), así que no se puede saber a qué columna de la base corresponde cada valor;
- la fecha es el serial de Excel (46294) y algunos montos vienen como `-`;
- mezcla columnas de cabecera (Tipo, Tipo_carga) con columnas de conceptos.

El CSV propuesto contiene **lo mismo que la pantalla `Form19Y`** (identificación + detalle de montos). Cada encabezado de monto es el **nombre técnico** de la columna destino (`vta_paint_z.vta_cmp_asoc`), que es único y es justo lo que necesita el INSERT.

## 2. Reglas del archivo

| Regla | Valor |
|---|---|
| Tipo | Texto CSV |
| Separador | `;` (es el que usa Excel en español al guardar "CSV (delimitado por comas)") |
| Codificación | ANSI / Windows-1252. El contenido es solo ASCII |
| Fin de línea | CRLF |
| Encabezado | Obligatorio en la línea 1, con los nombres exactos de la §3. Se compara sin distinguir mayúsculas |
| Filas | **Una fila por Y.** Las filas en blanco se ignoran |
| Fecha | `dd-mm-yyyy` (ej. `30-09-2026`) |
| Hora | `HH:MM`, 24 horas (ej. `18:05`) |
| Montos | Enteros (FACO usa 0 decimales), sin separador de miles ni símbolo; negativos con `-`. **Vacío = 0** |
| Columnas | Las 54, siempre, en el orden de la §3, aunque estén en 0 |

## 3. Columnas

### 3.1 Identificación (columnas 1 a 9)

| # | Columna | Obligatoria | Pantalla Form19Y | Uso al insertar |
|---|---|---|---|---|
| 1 | `FECHA` | Sí | FECHA | `vta_fecha`, `vta_fecha_venta`, `rec_fechaproceso`, `ter_fecha`. Debe ser anterior a hoy |
| 2 | `LOCAL` | Sí | LOCAL | `vta_local`, `ter_local` |
| 3 | `TERMINAL` | Sí | TERMINAL | `vta_terminal`, `ter_terminal` |
| 4 | `NRO_Y` | No | N° DE CIERRE DE Y | **Vacío:** la carga asigna `max(vta_secuencia)+1` del terminal-día, en el orden del archivo, igual que Form19Y. **Informado:** ese número no debe existir; si existe, se rechaza la fila (esta carga no modifica) |
| 5 | `HORA` | Sí | HORA | `vta_hora` como HHMM |
| 6 | `SECUENCIA` | Sí | SECUENCIA | `vta_secuencia_srx` |
| 7 | `NUM_BOLETA` | Sí | N° BOLETA | `vta_bolfinal` (y cálculo de `vta_cantbol`) |
| 8 | `VENDEDOR` | Sí | VENDEDOR | `vta_vendedor` |
| 9 | `CONT_REPOSICION` | Sí | CONT. REPOSICION | `vta_crepo_inicial` / `vta_crepo_final` |

> Form19Y graba hoy estos campos **corridos** (`bolfinal` ← SECUENCIA, `crepo` ← VENDEDOR, `vendedor` ← N° BOLETA) y nunca graba CONT. REPOSICION (ver README §4.4). La carga masiva debe grabar cada campo en su columna correcta, como indica esta tabla.

### 3.2 Montos (columnas 10 a 54)

El orden es el de `vta_paint_z.vta_order_z` de FACO. Tabla: `libvta` = `vta_FACOlibvta` (fila Y); `zzz` = `vta_FACOzzz`.

| # | Columna (`vta_cmp_asoc`) | Glosa en pantalla | Tabla | Sección |
|---|---|---|---|---|
| 10 | `VTA_MONTOBOL` | BOLETAS | libvta | Ventas |
| 11 | `VTA_MONTONCR` | N.CREDITO (va en negativo) | libvta | Ventas |
| 12 | `VTA_MONTOFAC` | FACTURA | libvta | Ventas |
| 13 | `REC_MEFECTIVO` | EFECTIVO | zzz | Formas de pago |
| 14 | `REC_MRECAUDAEFEC` | EFECT.RECAUDACION | zzz | Formas de pago |
| 15 | `REC_MCHKDIA` | CHEQUES AL DIA | zzz | Formas de pago |
| 16 | `REC_MCHKFECHA` | CHEQUE POSFECHADO | zzz | Formas de pago |
| 17 | `REC_MTARJ` | TARJETA CREDITO | zzz | Formas de pago |
| 18 | `REC_MSODIMAC` | TARJETA DEBITO | zzz | Formas de pago |
| 19 | `REC_MCMR` | CMR | zzz | Formas de pago |
| 20 | `REC_MTREGALO` | GIFT CARD | zzz | Formas de pago |
| 21 | `REC_MTOTCONVENIO` | TARJETA EMPRESA / GIFT CARD EMPRESA | zzz | Formas de pago |
| 22 | `REC_MTRASPASOTDE` | TDE | zzz | Formas de pago |
| 23 | `REC_MRENUEVA` | RENUEVA CMR | zzz | Formas de pago |
| 24 | `REC_MTOTFACXCOB` | FACTURAS X COBRAR | zzz | Formas de pago |
| 25 | `REC_MDOTACIONES` | DOTACIONES | zzz | Otros ingresos y egresos |
| 26 | `REC_MRETIROS` | RETIROS (va en negativo) | zzz | Otros ingresos y egresos |
| 27 | `REC_MABONOCMR` | ABONO CMR | zzz | Otros ingresos y egresos |
| 28 | `REC_MAVANCECMR` | AVANCE CMR | zzz | Otros ingresos y egresos |
| 29 | `REC_MTOTPREPRENUEVA` | PREPAGO RENUEVA | zzz | Otros ingresos y egresos |
| 30 | `REC_MTRANSFERENCIA` | ENVIO DINERO NACIONAL | zzz | Envío de dinero |
| 31 | `REC_MREVERSATRANS` | REV. TRANS. GIRO EFEC. | zzz | Envío de dinero |
| 32 | `REC_MRETIROTRANS` | RETIRO DINERO NACIONAL | zzz | Envío de dinero |
| 33 | `REC_MATRFEFEC` | ACT. GIFT CARD › EFECTIVO | zzz | Activación gift card |
| 34 | `REC_MATRFCHK` | ACT. GIFT CARD › CHEQUE | zzz | Activación gift card |
| 35 | `REC_MATRFCMR` | ACT. GIFT CARD › CMR | zzz | Activación gift card |
| 36 | `REC_MATRFDEB` | ACT. GIFT CARD › TARJETA DEBITO | zzz | Activación gift card |
| 37 | `REC_MATRFCRE` | ACT. GIFT CARD › TARJETA CREDITO | zzz | Activación gift card |
| 38 | `REC_MREVATOTTRF` | REVERSA ACTIVACION | zzz | Activación gift card |
| 39 | `REC_MREVATRFEFEC` | REVERSA ACTIVACION › EFECTIVO | zzz | Activación gift card |
| 40 | `REC_MREVATRFCMR` | REVERSA ACTIVACION › CMR | zzz | Activación gift card |
| 41 | `REC_MABONOTDE` | ABONO TDE | zzz | Otros |
| 42 | `REC_MTDE` | TRASPASO TDE | zzz | Otros |
| 43 | `REC_MSELLOSVRD` | SELLOS VERDES | zzz | Otros |
| 44 | `REC_MTOTRECAUDA` | RECAUDACION | zzz | Recaudación |
| 45 | `REC_MTOTREVRECAUDA` | REVERSA RECAUDACION | zzz | Recaudación |
| 46 | `REC_MCANJEPUNTOS` | CANJE DE PUNTOS | zzz | Otros |
| 47 | `REC_MREVCANJEPUNTOS` | REV. CANJE DE PUNTOS | zzz | Otros |
| 48 | `REC_MTOTSIF` | PAGO FACTURAS | zzz | Otros |
| 49 | `REC_MRECTERCERO` | REC. A TERCEROS | zzz | Otros |
| 50 | `REC_MDEVTERCERO` | REV. REC. A TERCEROS | zzz | Otros |
| 51 | `REC_MQUICKPAYCMR` | QUICKPAYCMR | zzz | Otros |
| 52 | `REC_MQUICKPAYBCO` | QUICKPAYDEBITO | zzz | Otros |
| 53 | `REC_ECOMPAY` | ECOMPAY | zzz | Otros |
| 54 | `REC_MPAGOPUNTOS` | PUNTOS+PESOS | zzz | Otros |

- **Confirmado en test el 20-10-2026:** `vta_paint_z` FACO tiene 53 filas: 46 con `pop_up = 0`, 1 total (`vta_totalvta`, pop 3) y el resto títulos o separadores.
  - Las 45 columnas de montos del archivo son exactamente las filas pop 0, en el mismo orden `vta_order_z`, sin `rec_mtotatrf` (ver §3.3).
  - Las columnas 1 a 3 de montos existen en `VTA_FACOLIBVTA` y las demás en `VTA_FACOZZZ`. Esto incluye las 50 a 54, que en desarrollo no estaban en `paint_z`.
- `REC_MREVATOTTRF` (REVERSA ACTIVACION, col. 38) **se informa en el archivo**: es pop 0 y Form19Y la deja digitar sin recalcularla.
- La sección es orientativa. La que vale para la cuadratura es `vta_paint_z.vta_validadorzzz`.

### 3.3 Columnas que **no** van en el archivo

| Columna | Glosa | Cómo se obtiene |
|---|---|---|
| `VTA_TOTALVTA` | TOTALES | La calcula la carga: BOLETAS + N.CREDITO + FACTURA (igual que Form19Y, fila 5) |
| `REC_MTOTATRF` | ACT. GIFT CARD | Es pop 0 en `paint_z`, pero Form19Y la recalcula: la carga la calcula como la suma de las columnas 33 a 37 (igual que Form19Y, fila 29) |
| — | VENTAS, FORMAS DE PAGO, OTROS INGRESOS Y EGRESOS, separadores | Son títulos sin columna destino |

## 4. Ejemplo

La plantilla trae 3 filas con montos inventados, pero con **fecha, local y terminal válidos en test**. Al 20-10-2026, el local 5 tiene los terminales 1 y 2 vigentes y la Z del 16-10-2026 abierta (−1), sin ninguna Y. Sirven para probar Form174.

| Fila | Y | Qué muestra |
|---|---|---|
| 2 | 16-10-2026, local 5, terminal 1, `NRO_Y` vacío | Boletas 1.500.000 y NC −50.000 (total 1.450.000) = efectivo 900.000 + crédito 350.000 + débito 200.000. Retiro −800.000. Se le asigna la Y 1 |
| 3 | Mismo terminal y día, `NRO_Y` vacío | Boletas 842.000 = efectivo 542.000 + CMR 300.000. Segunda Y del día: se le asigna la Y 2 |
| 4 | 16-10-2026, local 5, terminal 2, `NRO_Y = 1` | Factura 300.000 + activación de gift card en efectivo 50.000 = efectivo 150.000 + CMR 150.000 + canje de puntos 50.000 |

Las filas de ejemplo **graban** si se cargan en test. Después de probar, se borran con un rollback (libvta, zzz y termstaty de esas Y) o se reabre la Z.

## 5. Cómo lo prepara el usuario

0. La plantilla vacía se baja desde F8 ▸ botón Y ▸ "Ingreso del YYY Masivo" (Form174) ▸ **Exportar Excel**. Trae el encabezado y una fila con la fecha de ayer, la identificación vacía y los montos en 0. Se copia esa fila una vez por cada Y.
1. Abrir `plantilla_carga_Y_FACO.csv` en Excel. Con configuración regional en español separa por `;`.
2. Borrar las filas de ejemplo y completar una fila por Y. Si hay que pegar desde el reporte del POS, pegar **solo valores**.
3. Dar a las columnas `FECHA` y `HORA` formato **Texto** antes de escribir, para que Excel no las convierta. No usar separador de miles.
4. Guardar como **"CSV (delimitado por comas) (*.csv)"**. En Excel en español queda con `;`. No guardar como "CSV UTF-8".

## 6. Validaciones que debe hacer la carga (por fila)

Son las mismas que hace hoy Form19Y, más las que pide el requerimiento. La fila que falle no se graba y queda en el log.

1. Número de campos = 54 y encabezado idéntico al de la §3. Si hay un `;` al final de la línea (55 campos con el último vacío), se tolera.
2. `FECHA` válida y anterior a la fecha del servidor (`LeeFechaServidor`).
3. Local y terminal vigentes en `vta_FACOterminales` (como `Oklt`).
4. La Z del terminal-día no está cerrada: `vta_FACOtermstat.ter_estado` distinto de 1 y 2 (`Est_TermStat`).
5. Si viene `NRO_Y`, que esa Y no exista (`FuncValidNumY`), porque esta carga solo inserta.
6. Campos obligatorios presentes; `HORA` en `HH:MM`; números enteros.
7. **Cuadratura** (pedida por el requerimiento; Form19Y no la hace en FACO): regla a definir. Puede ser la fórmula ZZZ por grupos `vta_validadorzzz` (F7 − F6 − … − F1 = 0) o "total documentos = total formas de pago".
8. Sin duplicados dentro del archivo: misma fecha, local, terminal y `NRO_Y` informado.

### 6.1 Diferencias con Form19Y (revisado el 20-10-2026)

| Tema | Form19Y | Carga masiva (CSV / Form174) |
|---|---|---|
| Fecha con que se valida el terminal | `Oklt` usa la fecha de la F8 (`FormVariable.DTPicker1`), no la de la Y | La `FECHA` de cada fila |
| HORA | Hora actual, no editable | La hora real de la Y, informada en el archivo |
| N° de Y nueva | Siempre `max(vta_secuencia)+1` (`FuncBuscaNumSecY`). Si la consulta falla, devuelve **−1** | Vacío: `max+1`, en el orden del archivo. Informado: debe no existir. Si la consulta del máximo falla, se rechaza la fila, nunca se graba −1 |
| N° de Y existente | Modifica (borra la libvta y vuelve a insertar) | Rechaza la fila: solo inserta |
| Columnas de identificación | Grabadas corridas; CONT. REPOSICION no se graba (README §4.4) | Cada campo en su columna (§3.1) |
| Cuadratura | No valida en FACO | Regla pendiente (§6.7) |
| Obligatorios, fecha < servidor, Z no cerrada | Sí | Igual |

## 7. Qué inserta la carga por cada fila (referencia para el desarrollo)

Mismo efecto que Form19Y en una Y nueva, con los campos en su columna correcta:

1. Techkey: `SEQ_VTA_FACOTEC.nextval`.
2. `insert vta_FACOlibvta`:
   - `tiporeg 'Y'`, `vta_secuencia = NRO_Y`, `estado 'A'`, `tipof8 'N'`;
   - columnas 10-12 y `VTA_TOTALVTA` calculado;
   - identificación según la §3.1;
   - techkey.
3. `insert vta_FACOzzz`: `rec_techkey`, `rec_fechaproceso`, columnas 13-54 y `REC_MTOTATRF` calculado.
4. `insert vta_FACOtermstaty`: `ter_cierrey = NRO_Y`, `ter_estado = -1`, `ter_notas` = glosa de carga masiva (por definir; Form19Y usa 'INGRESO MANUAL POR CIERRE DE Y'), `ter_cerradopor = LOGINUSER`. Solo si no existe la fila.

## 8. Pendientes

- ~~Confirmar las columnas 50 a 54 en test~~: confirmadas el 20-10-2026 (§3.2).
- ~~`REC_MREVATOTTRF` informada o calculada~~: se informa (§3.2).
- Definir la regla de cuadratura (§6.7) y la glosa de `ter_notas`.
- Confirmar el nombre y la ubicación del archivo, y si se acepta más de un local por archivo.
