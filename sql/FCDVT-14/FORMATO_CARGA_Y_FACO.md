# FCDVT-14: formato del archivo de carga masiva de Y y Z (inserción, FACO)

Plantilla: [`plantilla_carga_Y_FACO.csv`](plantilla_carga_Y_FACO.csv). Índice del ticket: [`../README_FCDVT-14.md`](../README_FCDVT-14.md).

**Alcance:** solo **inserción** (`TIPO_CARGA = INGRESAR`) de cierres Y y de su Z de **Falabella Colombia (FACO)**. Update (`MODIFICAR`) y otros países quedan fuera.

> 30-10-2026: el archivo pasa de 54 a **56 columnas** (se agregan `TIPO` y `TIPO_CARGA` después de `CONT_REPOSICION`, como en el DF-SCC) y lleva, por cada terminal-día, sus Y **y una fila Z**. El botón Buscar de Form174 lo valida con `PKG_F8_CARGA_MASIVA_YZ` (§6.2).

## 1. Por qué no se usa la grilla del DF-SCC

La hoja F8-LV-CMP-TES del Excel del requerimiento no sirve para cargarla desde VB6:

- trae un bloque por empresa en la misma hoja, con títulos y celdas intermedias;
- usa glosas repetidas como encabezado (EFECTIVO ×3, CMR ×3), así que no se puede saber a qué columna de la base corresponde cada valor;
- la fecha es el serial de Excel (46294) y algunos montos vienen como `-`;
- mezcla columnas de cabecera (Tipo, Tipo_carga) con columnas de conceptos. En el CSV, `TIPO` y `TIPO_CARGA` se mantienen como columnas 10 y 11.

El CSV propuesto contiene **lo mismo que la pantalla `Form19Y`** (identificación + detalle de montos). Cada encabezado de monto es el **nombre técnico** de la columna destino (`vta_paint_z.vta_cmp_asoc`), que es único y es justo lo que necesita el INSERT.

## 2. Reglas del archivo

| Regla | Valor |
|---|---|
| Tipo | Texto CSV |
| Separador | `;` (es el que usa Excel en español al guardar "CSV (delimitado por comas)") |
| Codificación | ANSI / Windows-1252. El contenido es solo ASCII |
| Fin de línea | CRLF |
| Encabezado | Obligatorio en la línea 1, con los nombres exactos de la §3. Se compara sin distinguir mayúsculas |
| Filas | **Una fila por Y y una fila Z por terminal-día.** Las filas en blanco se ignoran |
| Fecha | `dd-mm-yyyy` (ej. `30-09-2026`) |
| Hora | `HH:MM`, 24 horas (ej. `18:05`) |
| Montos | Enteros (FACO usa 0 decimales), sin separador de miles ni símbolo; negativos con `-`. **Vacío = 0** |
| Columnas | Las 56, siempre, en el orden de la §3, aunque estén en 0 |

## 3. Columnas

### 3.1 Identificación (columnas 1 a 11)

| # | Columna | Obligatoria | Pantalla Form19Y | Uso al insertar |
|---|---|---|---|---|
| 1 | `FECHA` | Sí | FECHA | `vta_fecha`, `vta_fecha_venta`, `rec_fechaproceso`, `ter_fecha`. Debe ser anterior a hoy |
| 2 | `LOCAL` | Sí | LOCAL | `vta_local`, `ter_local` |
| 3 | `TERMINAL` | Sí | TERMINAL | `vta_terminal`, `ter_terminal` |
| 4 | `NRO_Y` | No | N° DE CIERRE DE Y | **Informado:** se usa ese número (1 a 98). **Vacío:** Cargar asigna el siguiente al mayor `NRO_Y` informado del grupo, recorriendo las Y vacías en el orden del archivo. Por ejemplo, con [vacío, vacío, 1] quedan las Y 2, 3 y 1. Como Cargar **reemplaza** las Y que ya tenga el terminal-día (§7), un número que ya existe en la base no rechaza la fila (desde el 04-11-2026; antes se rechazaba) |
| 5 | `HORA` | Sí | HORA | `vta_hora` como HHMM |
| 6 | `SECUENCIA` | Sí | SECUENCIA | `vta_secuencia_srx` |
| 7 | `NUM_BOLETA` | Sí | N° BOLETA | `vta_bolfinal` (y cálculo de `vta_cantbol`) |
| 8 | `VENDEDOR` | Sí | VENDEDOR | `vta_vendedor` |
| 9 | `CONT_REPOSICION` | Sí | CONT. REPOSICION | `vta_crepo_inicial` / `vta_crepo_final` |
| 10 | `TIPO` | Sí | — | `Y` = cierre Y; `Z` = cierre Z del terminal-día (uno solo, con `NRO_Y` vacío; se ignora si viene) |
| 11 | `TIPO_CARGA` | Sí | — | `INGRESAR`. `MODIFICAR` (criterio 2 del requerimiento) todavía no se habilita: la fila se rechaza |

> Form19Y graba hoy estos campos **corridos** (`bolfinal` ← SECUENCIA, `crepo` ← VENDEDOR, `vendedor` ← N° BOLETA) y nunca graba CONT. REPOSICION (ver README §4.4). La carga masiva debe grabar cada campo en su columna correcta, como indica esta tabla.

### 3.2 Montos (columnas 12 a 56)

El orden es el de `vta_paint_z.vta_order_z` de FACO. Tabla: `libvta` = `vta_FACOlibvta` (fila Y); `zzz` = `vta_FACOzzz`.

| # | Columna (`vta_cmp_asoc`) | Glosa en pantalla | Tabla | Sección |
|---|---|---|---|---|
| 12 | `VTA_MONTOBOL` | BOLETAS | libvta | Ventas |
| 13 | `VTA_MONTONCR` | N.CREDITO (va en negativo) | libvta | Ventas |
| 14 | `VTA_MONTOFAC` | FACTURA | libvta | Ventas |
| 15 | `REC_MEFECTIVO` | EFECTIVO | zzz | Formas de pago |
| 16 | `REC_MRECAUDAEFEC` | EFECT.RECAUDACION | zzz | Formas de pago |
| 17 | `REC_MCHKDIA` | CHEQUES AL DIA | zzz | Formas de pago |
| 18 | `REC_MCHKFECHA` | CHEQUE POSFECHADO | zzz | Formas de pago |
| 19 | `REC_MTARJ` | TARJETA CREDITO | zzz | Formas de pago |
| 20 | `REC_MSODIMAC` | TARJETA DEBITO | zzz | Formas de pago |
| 21 | `REC_MCMR` | CMR | zzz | Formas de pago |
| 22 | `REC_MTREGALO` | GIFT CARD | zzz | Formas de pago |
| 23 | `REC_MTOTCONVENIO` | TARJETA EMPRESA / GIFT CARD EMPRESA | zzz | Formas de pago |
| 24 | `REC_MTRASPASOTDE` | TDE | zzz | Formas de pago |
| 25 | `REC_MRENUEVA` | RENUEVA CMR | zzz | Formas de pago |
| 26 | `REC_MTOTFACXCOB` | FACTURAS X COBRAR | zzz | Formas de pago |
| 27 | `REC_MDOTACIONES` | DOTACIONES | zzz | Otros ingresos y egresos |
| 28 | `REC_MRETIROS` | RETIROS (va en negativo) | zzz | Otros ingresos y egresos |
| 29 | `REC_MABONOCMR` | ABONO CMR | zzz | Otros ingresos y egresos |
| 30 | `REC_MAVANCECMR` | AVANCE CMR | zzz | Otros ingresos y egresos |
| 31 | `REC_MTOTPREPRENUEVA` | PREPAGO RENUEVA | zzz | Otros ingresos y egresos |
| 32 | `REC_MTRANSFERENCIA` | ENVIO DINERO NACIONAL | zzz | Envío de dinero |
| 33 | `REC_MREVERSATRANS` | REV. TRANS. GIRO EFEC. | zzz | Envío de dinero |
| 34 | `REC_MRETIROTRANS` | RETIRO DINERO NACIONAL | zzz | Envío de dinero |
| 35 | `REC_MATRFEFEC` | ACT. GIFT CARD › EFECTIVO | zzz | Activación gift card |
| 36 | `REC_MATRFCHK` | ACT. GIFT CARD › CHEQUE | zzz | Activación gift card |
| 37 | `REC_MATRFCMR` | ACT. GIFT CARD › CMR | zzz | Activación gift card |
| 38 | `REC_MATRFDEB` | ACT. GIFT CARD › TARJETA DEBITO | zzz | Activación gift card |
| 39 | `REC_MATRFCRE` | ACT. GIFT CARD › TARJETA CREDITO | zzz | Activación gift card |
| 40 | `REC_MREVATOTTRF` | REVERSA ACTIVACION | zzz | Activación gift card |
| 41 | `REC_MREVATRFEFEC` | REVERSA ACTIVACION › EFECTIVO | zzz | Activación gift card |
| 42 | `REC_MREVATRFCMR` | REVERSA ACTIVACION › CMR | zzz | Activación gift card |
| 43 | `REC_MABONOTDE` | ABONO TDE | zzz | Otros |
| 44 | `REC_MTDE` | TRASPASO TDE | zzz | Otros |
| 45 | `REC_MSELLOSVRD` | SELLOS VERDES | zzz | Otros |
| 46 | `REC_MTOTRECAUDA` | RECAUDACION | zzz | Recaudación |
| 47 | `REC_MTOTREVRECAUDA` | REVERSA RECAUDACION | zzz | Recaudación |
| 48 | `REC_MCANJEPUNTOS` | CANJE DE PUNTOS | zzz | Otros |
| 49 | `REC_MREVCANJEPUNTOS` | REV. CANJE DE PUNTOS | zzz | Otros |
| 50 | `REC_MTOTSIF` | PAGO FACTURAS | zzz | Otros |
| 51 | `REC_MRECTERCERO` | REC. A TERCEROS | zzz | Otros |
| 52 | `REC_MDEVTERCERO` | REV. REC. A TERCEROS | zzz | Otros |
| 53 | `REC_MQUICKPAYCMR` | QUICKPAYCMR | zzz | Otros |
| 54 | `REC_MQUICKPAYBCO` | QUICKPAYDEBITO | zzz | Otros |
| 55 | `REC_ECOMPAY` | ECOMPAY | zzz | Otros |
| 56 | `REC_MPAGOPUNTOS` | PUNTOS+PESOS | zzz | Otros |

- **Confirmado en test el 20-10-2026:** `vta_paint_z` FACO tiene 53 filas: 46 con `pop_up = 0`, 1 total (`vta_totalvta`, pop 3) y el resto títulos o separadores.
  - Las 45 columnas de montos del archivo son exactamente las filas pop 0, en el mismo orden `vta_order_z`, sin `rec_mtotatrf` (ver §3.3).
  - Las columnas 1 a 3 de montos existen en `VTA_FACOLIBVTA` y las demás en `VTA_FACOZZZ`. Esto incluye las 52 a 56, que en desarrollo no estaban en `paint_z`.
- `REC_MREVATOTTRF` (REVERSA ACTIVACION, col. 40) **se informa en el archivo**: es pop 0 y Form19Y la deja digitar sin recalcularla.
- La sección es orientativa. La que vale para la cuadratura es `vta_paint_z.vta_validadorzzz`.

### 3.3 Columnas que **no** van en el archivo

| Columna | Glosa | Cómo se obtiene |
|---|---|---|
| `VTA_TOTALVTA` | TOTALES | La calcula la carga: BOLETAS + N.CREDITO + FACTURA (igual que Form19Y, fila 5) |
| `REC_MTOTATRF` | ACT. GIFT CARD | Es pop 0 en `paint_z`, pero Form19Y la recalcula: la carga la calcula como la suma de las columnas 35 a 39 (igual que Form19Y, fila 29) |
| — | VENTAS, FORMAS DE PAGO, OTROS INGRESOS Y EGRESOS, separadores | Son títulos sin columna destino |

## 4. Ejemplo

Archivos en `docs/sql/FCDVT-14/`:

| Archivo | Qué muestra |
|---|---|
| `plantilla_carga_Y_FACO.csv` | Encabezado de 56 columnas y 4 filas: 16-10-2026, local 5. Terminal 1: Z (2.292.000) + 2 Y (1.450.000 y 842.000); terminal 2: 1 Y (300.000), **sin Z** (Buscar la marca en ERROR) |
| `ejemplo_carga_Y_FACO_20.csv` | 23 filas del 16-10-2026, local 5: por terminal, 1 Z + sus Y (T1 7 Y, T2 7 Y, T3 6 Y). Cada concepto de la Z es la suma de las Y. Buscar: **3 grupos CARGADO** (9.400.000, 7.435.000 y 9.490.000; en total 26.325.000) |
| `ejemplo_carga_YZ_FACO_errores.csv` | Un caso por resultado: 15-10 T1 cuadrado (CARGADO); 15-10 T2 con Z 425.000 y Y 420.000; 15-10 T3 sin Z; 14-10 T1 con `REC_MEFECTIVO = 12a00` y `TIPO = X`; terminal 99 no vigente (4 ERROR); y una línea con 50 campos (solo log) |

Fecha, local y terminales son válidos en test (local 5, terminales 1 a 3). En esta etapa Buscar **no graba** Y ni Z: solo llena las tablas `VTA_FACOCARGA_YZ_*`.

Hay más casos de prueba, uno por tipo de validación (campos malos, falta de Z, cuadratura, `NRO_Y`, estructura de la línea, encabezado y volumen), en `docs/sql/FCDVT-14/pruebas/`. El resultado esperado de cada uno está en su `README.md`.

## 5. Cómo lo prepara el usuario

**Con la plantilla Excel (desde el 03-11-2026, recomendado):**

1. F8 ▸ botón Y ▸ "Ingreso del YYY Masivo" (Form174) ▸ **Exportar Excel**. Se guarda un `.xlsx` (por defecto `plantilla_carga_YZ_FACO.xlsx`; requiere Excel 2007 o posterior) con tres hojas:
   - **Carga**:
     - la fila 1 trae el encabezado de las 56 columnas, cada una con un comentario que explica qué dato va;
     - FECHA y HORA ya tienen formato texto;
     - identificaciones y montos aceptan solo enteros (Excel rechaza decimales al escribirlos);
     - TIPO (Y/Z) y TIPO_CARGA (INGRESAR) se eligen de una lista;
     - la fila 1 y las columnas A:C quedan inmovilizadas.
   - **Instrucciones**: los pasos y un ejemplo (Z + 2 Y) que no se carga.
   - **Listas**: oculta; tiene los valores de las listas.
2. Completar la hoja Carga desde la fila 2: una fila por Y y una Z por terminal-día. Los montos que no aplican se dejan vacíos (= 0).
3. Con la hoja Carga activa: Archivo ▸ Guardar como ▸ **"CSV (delimitado por comas) (*.csv)"**, y aceptar el aviso de que solo se guarda la hoja activa.
4. En Form174, **Buscar** ese `.csv`.

**Con un Excel armado a mano o con el CSV `plantilla_carga_Y_FACO.csv`** (forma anterior):

0. La versión anterior de Exportar Excel guardaba un CSV con el encabezado y una fila con la fecha de ayer, la identificación vacía, `TIPO = Y`, `TIPO_CARGA = INGRESAR` y los montos en 0. Hay que copiar esa fila una vez por cada Y y una vez más para la Z del terminal-día (con `TIPO = Z`).
1. Abrir `plantilla_carga_Y_FACO.csv` en Excel. Con configuración regional en español separa por `;`.
2. Borrar las filas de ejemplo y completar una fila por Y y una fila Z por terminal-día, cuyo TOTAL (BOLETAS + N.CREDITO + FACTURA) debe ser la suma de los de sus Y. Si hay que pegar desde el reporte del POS, pegar **solo valores**.
3. Dar a las columnas `FECHA` y `HORA` formato **Texto** antes de escribir, para que Excel no las convierta. No usar separador de miles.
4. Guardar como **"CSV (delimitado por comas) (*.csv)"**. En Excel en español queda con `;`. No guardar como "CSV UTF-8".

## 6. Validaciones que debe hacer la carga (por fila)

Son las mismas que hace hoy Form19Y, más las que pide el requerimiento. La fila que falle no se graba y queda en el log.

1. Número de campos = 56 y encabezado idéntico al de la §3. Si hay un `;` al final de la línea (57 campos con el último vacío), se tolera.
2. `FECHA` válida y anterior a la fecha del servidor (`LeeFechaServidor`).
3. Local y terminal vigentes en `vta_FACOterminales` (como `Oklt`).
4. La Z del terminal-día no está cerrada: `vta_FACOtermstat.ter_estado` distinto de 1 y 2 (`Est_TermStat`).
5. ~~Si viene `NRO_Y`, que esa Y no exista (`FuncValidNumY`)~~: desde el 04-11-2026 no aplica, porque Cargar reemplaza las Y del terminal-día (§7). Ninguna Y del día debe estar cerrada.
6. Campos obligatorios presentes; `HORA` en `HH:MM`; números enteros.
7. **Cuadratura** (pedida por el requerimiento; Form19Y no la hace en FACO). **Definida el 30-10-2026:** por terminal-día, el TOTAL de la Z (BOLETAS + N.CREDITO + FACTURA) debe ser igual a la suma de los TOTALES de las Y. La regla "documentos = formas de pago" de cada Y (o la fórmula ZZZ por grupos `vta_validadorzzz`) sigue pendiente de negocio.
8. Sin duplicados dentro del archivo: misma fecha, local, terminal y `NRO_Y` informado.
9. Por terminal-día: exactamente una fila Z y al menos una Y.
10. `TIPO` = Y o Z; `TIPO_CARGA` = INGRESAR.

### 6.2 Qué valida hoy el botón Buscar (30-10-2026)

Form174 envía cada línea a `PKG_F8_CARGA_MASIVA_YZ` (`docs/sql/FCDVT-14/02` a `04`), que valida 1, 2, 3, 6, 7, 8, 9 y 10 y arma el resumen por terminal-día:

| Estado | Cuándo |
|---|---|
| PENDIENTE | Recién creado. Si queda así, el proceso se cayó (ver log, etapa ERROR) |
| ERROR | Hay filas con error, no hay exactamente 1 Z, no hay Y, o el total de la Z es distinto de la suma de las Y. El motivo queda en `res_mensaje` (doble clic en la grilla) |
| CARGADO | 1 Z, al menos 1 Y, sin errores y total Z = suma total Y (hasta el 03-11-2026 se llamaba PROCESADO) |

Cada error queda en `VTA_FACOCARGA_YZ_LOG` con su línea, campo, valor y motivo. Las validaciones que dependen del estado de la base al grabar las hace Cargar (§7, desde el 04-11-2026): la 4 (Z no cerrada) y, además, que ninguna Y del terminal-día esté cerrada. La 5 (`NRO_Y` ya existente) ya no aplica, porque Cargar **reemplaza** lo que el terminal-día tenga.

### 6.1 Diferencias con Form19Y (revisado el 20-10-2026)

| Tema | Form19Y | Carga masiva (CSV / Form174) |
|---|---|---|
| Fecha con que se valida el terminal | `Oklt` usa la fecha de la F8 (`FormVariable.DTPicker1`), no la de la Y | La `FECHA` de cada fila |
| HORA | Hora actual, no editable | La hora real de la Y, informada en el archivo |
| N° de Y nueva | Siempre `max(vta_secuencia)+1` (`FuncBuscaNumSecY`). Si la consulta falla, devuelve **−1** | Vacío: `max+1`, en el orden del archivo. Informado: debe no existir. Si la consulta del máximo falla, se rechaza la fila, nunca se graba −1 |
| N° de Y existente | Modifica (borra la libvta y vuelve a insertar) | Rechaza la fila: solo inserta |
| Columnas de identificación | Grabadas corridas; CONT. REPOSICION no se graba (README §4.4) | Cada campo en su columna (§3.1) |
| Cuadratura | No valida en FACO | Total Z = suma de los totales de las Y del terminal-día (§6.7) |
| Obligatorios, fecha < servidor, Z no cerrada | Sí | Igual |

## 7. Qué graba Cargar (`PKG_F8_GRABA_MASIVA_YZ.prc_graba`, 04-11-2026)

Por cada grupo CARGADO (terminal-día), en una sola transacción: si algo falla, no queda nada a medias y el grupo pasa a ERROR con el motivo.

1. **Revalida:**
   - la Z (`vta_FACOtermstat`) no está cerrada (estado 1/2);
   - ninguna Y del día (`vta_FACOtermstaty`) está cerrada;
   - el N° de cada Y queda entre 1 y 98, porque `vta_secuencia` es `NUMBER(2)` y el 99 es la Z. Una Y sin `NRO_Y` recibe el siguiente al mayor informado del grupo, en el orden del archivo.
2. **Reemplaza, como Form19:** borra la zzz de los techkeys de la libvta `'F8'`/`'Y'` del terminal-día (Form19 la deja huérfana), esa libvta y **todas** las termstaty del día. La termstat no se borra.
3. **Z**, con la rama FACO de `Form19.GrabarTerceraZZZ`:
   - techkey `SEQ_VTA_FACOTEC.nextval`;
   - `insert vta_FACOlibvta`:
     - `tiporeg 'F8'`, `vta_secuencia 99`, `estado 'A'`, `tipof8 'N'`;
     - columnas 12-14 y `VTA_TOTALVTA` calculado;
     - identificación según la §3.1;
     - `vta_bolinicial` y `vta_nrollo` de la Z anterior (0 si no había), y `vta_cantbol` = NUM_BOLETA − bolinicial + 1;
   - `insert vta_FACOzzz`: `rec_techkey`, `rec_fechaproceso`, columnas 15-56 y `REC_MTOTATRF` = Σ 35-39;
   - `insert vta_FACOtermstat` solo si no existe, con `ter_estado = -1`, `ter_notas = 'CARGA MASIVA DE CIERRE Z - CARGA <n>'` y el usuario.
4. **Cada Y**, igual que Form19Y en una Y nueva pero con los campos en su columna:
   - `insert vta_FACOlibvta`: `tiporeg 'Y'`, `vta_secuencia` = N° de Y, mismas columnas que la Z. VENDEDOR admite hasta 10 dígitos (`vta_vendedor NUMBER(10)`) y Buscar ya lo valida;
   - `insert vta_FACOzzz`;
   - `insert vta_FACOtermstaty` con `ter_cierrey` = N° de Y, `ter_estado = -1`, `ter_notas = 'CARGA MASIVA DE CIERRE Y - CARGA <n>'` y `ter_cerradopor = LOGINUSER`.
   - El N° asignado queda en `det_nro_y`, y Form175 lo muestra.
5. El grupo pasa a **GRABADO** (`res_mensaje`: cantidad de Y, rango de números y lo que reemplazó), con commit, y una fila en el log en la etapa GRABADO.

## 8. Pendientes

- ~~Confirmar las columnas 50 a 54 en test~~: confirmadas el 20-10-2026 (§3.2).
- ~~`REC_MREVATOTTRF` informada o calculada~~: se informa (§3.2).
- ~~Definir la regla de cuadratura (§6.7)~~: total Z = suma de las Y (30-10-2026).
- ~~Glosa de `ter_notas` y qué graba Cargar con la fila Z~~: definidos el 04-11-2026 (§7).
- Confirmar el nombre y la ubicación del archivo, y si se acepta más de un local por archivo.
