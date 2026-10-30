# CLAUDE.md — Contexto del requerimiento FCDVT-14 / Carga masiva de cierres F8

> Archivo de contexto para futuras sesiones de IA (Claude, opencode u otra).
> Léelo completo antes de analizar, diseñar, estimar o modificar código de este requerimiento.
> Última actualización: 2026-10-28.
> Carpeta: `C:\FALABELLA\F8\F8NK\claude-f8-docs\Requerimiento-FCDVT-14`.
> Estado del requerimiento: **Refining** (sin sprint, sin estimación, subtareas sin iniciar).

---

## 0. Cómo usar este archivo

1. Este archivo es un **resumen de contexto**, no la fuente de verdad. Ante cualquier duda, prevalecen los archivos fuente de la carpeta.
2. No asumir que **FCDVT-14 = toda la iniciativa**. FCDVT-14 es solo la historia de **Falabella Colombia (HU-04)**. El documento funcional (DF) y el mapa BPMN cubren también **Falabella Chile (HU-02)** y **Tottus Chile (HU-03)**.
3. Distinguir siempre:
   - **AS-IS**: lo que hace hoy el código VB6 de F8.
   - **TO-BE**: la propuesta del mapa BPMN, que **no está aprobada**.
   - **Requerimiento**: lo que pide el DF y el ticket.
   - **Decisión abierta**: puntos marcados como DUD, PEN o “por confirmar”.
4. No inventar tablas, columnas, secuencias ni reglas. Si un dato no está en las fuentes, marcarlo como supuesto.
5. Si hay conflicto entre fuentes, **registrarlo**; no resolverlo silenciosamente.
6. No modificar los archivos fuente: son evidencia. Los entregables nuevos deben ir aparte o acordarse con el usuario.

### Leyenda de etiquetas usada en este documento

| Etiqueta | Significado |
|---|---|
| `[CÓDIGO]` | Visto en el código VB6 / estructura Oracle (AS-IS) |
| `[DF]` | Documento funcional `DF-SCC-vf_24.03.2025 Ingreso Cierre de caja F8.xlsx` |
| `[BPMN]` | Mapa `Mapa BPMN · Carga masiva de cierres.html` |
| `[TICKET]` | Jira `FCDVT-14.doc` (HU-04) |
| `[DEC]` | Decisión de negocio ya tomada |
| `[DUD]` | Duda abierta |
| `[PEN]` | Pendiente técnico/configuración |
| `[SUPUESTO]` | Inferencia de quien escribió este archivo, no confirmada |

### Jerarquía recomendada de fuentes

1. Código VB6 y estructura Oracle (comportamiento real).
2. DF aprobado (qué se pide).
3. Ticket FCDVT-14 (alcance de Colombia).
4. Mapa BPMN (interpretación y propuesta).
5. Este CLAUDE.md (resumen).

---

## 1. Resumen ejecutivo

La iniciativa **“CARGA MASIVA CIERRES F8”** busca reemplazar la digitación manual de cierres de caja **Z e Y** en F8 (`Form19` y `Form19Y`) por una carga masiva desde Excel, con validaciones, rechazo por fila, transacción por fila, log de auditoría y reflejo en el Libro de Ventas (LVTA).

Aplica a:

| Historia | Negocio | País | Alcance |
|---|---|---|---|
| HU-02 | Falabella | Chile | Solo Z |
| HU-03 | Tottus | Chile | Z e Y |
| HU-04 | Falabella | Colombia | Z e Y (ticket FCDVT-14) |

Sistemas marcados como impactados en el DF: **F8, LV (Libro de Ventas) y Tesorería**. **CMP y SCC están marcados como no impactados**, aunque el texto del DF y el mapa BPMN sí exigen reflejo en LVTA/CMP; es una inconsistencia abierta.

El AS-IS tiene deuda técnica relevante: **no usa transacciones**, deja filas huérfanas en `ZZZ`, un Z nuevo **borra todas las Y del día** (`LIBVTA` + `TERMSTATY`), el descuadre **no bloquea** (solo queda en `rec_mdiferenciaz`), el usuario solo queda en `TERMSTAT.ter_cerradopor` y **no refleja en LVTA/CMP**. El TO-BE propone corregir esto con transacción por fila, borrado también de `ZZZ`, rechazo individual (`DEC-023`) y marca `C_MASIVA`.

El punto más importante a aclarar antes de construir: **el ticket HU-04 dice que el Z se calcula a partir de las Y, pero el BPMN TO-BE carga Z e Y desde el archivo y solo recalcula totales/cuadratura**. Son dos diseños distintos.

---

## 2. Inventario de la carpeta y cómo leer cada archivo

| Archivo | Tipo real | Contenido | Cómo leerlo |
|---|---|---|---|
| `FCDVT-14.doc` | **HTML UTF-8**, no Word binario | Export de Jira del ticket HU-04 (Falabella CO): datos, historia, escenarios, criterios, tablas, subtareas, imágenes | Copiarlo a `.html` y leerlo como texto/HTML. **No abrir con Word COM** (falla con `RPC_E_CALL_REJECTED` por Protected View/Zone.Identifier) |
| `DF-SCC-vf_24.03.2025 Ingreso Cierre de caja F8.xlsx` | XLSX (ZIP + XML) | DF de la iniciativa: antecedentes, impacto, criterios, plantillas Excel por país, hoja SCC genérica, diccionario CMP (Backbone) | Parsear el ZIP: `xl/workbook.xml`, `xl/_rels/workbook.xml.rels`, `xl/sharedStrings.xml`, `xl/worksheets/sheetN.xml`. Excel COM puede fallar a mitad de recorrido; el XML es más confiable |
| `Mapa BPMN · Carga masiva de cierres.html` | HTML autocontenido (242 KB) | AS-IS/TO-BE de HU-02/03/04, detalle por nodo (qué valida, lee y graba), comparativa y 8 decisiones abiertas | El objeto JS `var D={...}` contiene 9 escenarios con `xml` (BPMN) y `docs` (detalle por nodo). Extraer entre `var D=` y `var HU=` y parsear como JSON |
| `image-20261013-192154.png` | PNG | Árbol HU-04 padre + 3 historias hijas | Leer como imagen |
| `image-20261013-192234.png` | PNG | Flujo BPMN TO-BE (plantilla → carga → validación → rechazos → grabar Y/Z → calcular Z → LVTA → log → informe) | Leer como imagen |

### 2.1 Recetas de extracción (aprendidas en esta sesión)

- `FCDVT-14.doc` empieza con `<!DOCTYPE html>` y declara `charset=UTF-8`. Es un export de Jira, no un `.doc` real. El nombre puede engañar.
- El archivo tiene `Zone.Identifier` (fue descargado). `Unblock-File` no resuelve el fallo de Word COM; no insistir con Word.
- Para el XLSX, la hoja `F8-LV-CMP-TES` tiene **celdas combinadas y muchas columnas**; Excel COM reportó solo 59 filas, pero el XML contiene datos hasta la fila 60 y 8 hojas. Parsear XML.
- En PowerShell, **no nombrar una función `RD`**: el alias `rd` (Remove-Item) tiene precedencia y rompe la lectura del ZIP. Usar `ReadZipEntry`.
- El HTML del mapa BPMN tiene el objeto `D` con estos escenarios:
  - `HU02_asisZ`, `HU02_tobe`
  - `HU03_asisZ`, `HU03_asisY`, `HU03_tobe`
  - `HU04_asisZ`, `HU04_asisY`, `HU04_tobe`
- Cada escenario tiene `hu`, `kind`, `title`, `xml` (BPMN) y `docs` (por nodo: `kind`, `ev`, `t`, `lines`, `reads`, `writes`).
- El HTML también contiene `HU`, `VIEWS`, `CMP` (comparativa por historia) y `DEC` (8 decisiones).
- Codificación: UTF-8 con acentos; respetar tildes y “ñ”.

---

## 3. Contexto de negocio, alcance y actores

### 3.1 Datos de la iniciativa `[DF]`

| Campo | Valor |
|---|---|
| Nombre | CARGA MASIVA CIERRES F8 |
| Tipo de solicitud | Nuevo |
| Negocio | Falabella retail - Tottus |
| País | Chile - Colombia |
| Solicitante | Paulo Arrieta |
| Gerente de área | Cristian Zuñiga |
| Gerencia / Dpto | Pablo Alfredo Aguirre Rigo-Righi |
| Fecha de solicitud | En blanco en el DF |
| Sistemas impactados | F8 = sí, LV = sí, CMP = no, Tesorería = sí, SCC = no |
| Versión del DF | 24.03.2025 |

### 3.2 Datos del ticket `[TICKET]`

| Campo | Valor |
|---|---|
| Clave | FCDVT-14 |
| Título | `[SCCFIN][F8] HU04- Ingreso masivo de cierres de caja F8 — Falabella CO` |
| Proyecto | Finance Control Ventas - Recaudacion (id 12126) |
| Componente / etiqueta | SCCFIN |
| Padre | FSCC-13183 — `[SCCFIN] Mejoras Legado F8 y Control de Ventas` |
| Tipo | Historia |
| Prioridad | Medium |
| Estado | Refining |
| Resolución | Sin resolver |
| Creada | 07/oct/26 |
| Actualizada | 27/oct/26 |
| Informador / asignado | ext_lcalderonn |
| Sprint | Vacío |
| Votos | 0 |
| Estimaciones | Desconocidas |
| Subtareas | FCDVT-15 (HU-04.1), FCDVT-16 (HU-04.2), FCDVT-17 (HU-04.3), todas “Tareas por hacer” |

### 3.3 Alcance funcional

- **HU-02 — Falabella Chile:** solo Z. Un archivo con muchos Z; plantilla generada desde `VTA_PAINT_Z` con `vta_localiz = 'CHI'`.
- **HU-03 — Tottus Chile:** Z e Y. Un archivo con Z e Y; la columna “N° de Cierre de Y” distingue el tipo.
- **HU-04 — Falabella Colombia:** Z e Y. Misma lógica que HU-03, más configuración de cuadratura para `FACO`.

### 3.4 Actores

- Analistas de Control de Venta.
- Tesorería.
- Usuarios operativos responsables de la gestión y regularización de cierres en F8.
- Soporte / TI (dependencia que se busca reducir).

---

## 4. Glosario

| Término | Significado |
|---|---|
| **Z** | Cierre diario de caja del terminal. En `LIBVTA`: `vta_tiporeg = 'F8'`, `vta_secuencia = 99`. |
| **Y** | Cierre parcial del día. En `LIBVTA`: `vta_tiporeg = 'Y'`, `vta_secuencia = N° de Y`. |
| **Terminal** | Caja o punto de venta dentro de un local. |
| **Local** | Sucursal / tienda. |
| **Cuadratura** | Diferencia entre formas de pago, recaudaciones y ventas. Se calcula con `vta_validadorzzz` y `vta_signo` de `VTA_PAINT_Z`. |
| **Descuadre** | Resultado distinto de cero en la cuadratura. En el AS-IS no bloquea; queda en `ZZZ.rec_mdiferenciaz`. |
| **Techkey** | Clave técnica que une `LIBVTA` con `ZZZ` (`vta_techkey` / `rec_techkey`). Se genera desde una secuencia por país. |
| **LVTA / LV** | Libro de Ventas. |
| **CMP** | Conciliación / módulo CMP referido en el DF y en el diccionario “Backbone”. |
| **SCC** | Módulo de conciliación. En esta iniciativa está marcado como no impactado. |
| **SRX** | Sistema de origen de ventas mencionado en el DF. |
| **TERMSTAT** | Estado del terminal por día. `ter_estado` 1 o 2 = cerrado (bloquea); `-1` = creado por ingreso manual. |
| **TERMSTATY** | Estado de cada cierre Y. `ter_cierrey = N° de Y`. |
| **PAINT_Z** | Tabla única de conceptos de cierre para todos los negocios, filtrada por `vta_localiz`. |
| **`vta_pop_up`** | `0` = monto editable; `1` y `2` = títulos sin monto; `3` = total calculado. |
| **`C_MASIVA`** | Usuario/marca propuesto para identificar cargas masivas en `ter_cerradopor`. |
| **DEC / DUD / PEN** | Decisión tomada / duda abierta / pendiente. |

---

## 5. Modelo de datos

### 5.1 `VTA_PAINT_Z` — tabla única de conceptos `[CÓDIGO]`

- Una sola tabla para todos los negocios; se filtra por `vta_localiz`:
  - `'CHI'` = Falabella Chile.
  - `'SFCL'` = Tottus Chile.
  - `'FACO'` = Falabella Colombia.
- El código **no** usa `VTA_FACOPAINT_Z` ni `VTA_SFCLPAINT_Z`.
- Columnas semánticas:
  - `vtaglosa_z`: texto de la fila.
  - `vta_cmp_asoc`: columna destino en `LIBVTA`/`ZZZ`.
  - `vta_pop_up`: `0` monto, `1`-`2` título, `3` total.
  - `vta_order_z`: orden de la grilla/plantilla.
  - `vta_validadorzzz` y `vta_signo`: arman la fórmula de cuadratura.
- Los conceptos cuya columna destino empieza con `VTA_` se graban en `LIBVTA`, no en `ZZZ`.

### 5.2 Tablas por país

| Concepto | Falabella Chile (`CHI`) | Tottus Chile (`SFCL`) | Falabella Colombia (`FACO`) |
|---|---|---|---|
| Terminales | `VTA_TERMINALES` | `VTA_SFCLTERMINALES` | `VTA_FACOTERMINALES` |
| Estado terminal/día | `VTA_TERMSTAT` | `VTA_SFCLTERMSTAT` | `VTA_FACOTERMSTAT` |
| Estado de Y | No aplica (solo Z) | `VTA_SFCLTERMSTATY` | `VTA_FACOTERMSTATY` |
| Cierres | `VTA_LIBVTA` | `VTA_SFCLLIBVTA` | `VTA_FACOLIBVTA` |
| Montos por concepto | `VTA_ZZZ` | `VTA_SFCLZZZ` | `VTA_FACOZZZ` |
| Estado del local/día | `VTA_ESTATUS` | No listada en el BPMN | `VTA_FACOESTATUS` (solo en el ticket; el BPMN no la usa) |
| Secuencia techkey | `VTA_TEC_SEC` | `SEQ_VTA_SFCLTEC` | `SEQ_VTA_FACOTEC` |
| Locales | No listada | No listada | `VTA_FACOLOCALES` (solo en el ticket) |
| `vta_localiz` | `'CHI'` | `'SFCL'` | `'FACO'` |

Notas:
- La ventana de Tottus dice **“HTCL”**, pero el código usa **“SFCL”**. Confirmar instancia y tablas reales (`DUD` / ver sección 10).
- `VTA_FACOESTATUS` aparece en la lista de tablas del ticket, pero el BPMN de Colombia no la usa. La única referencia a `ESTATUS` en el BPMN es `VTA_ESTATUS` para Falabella Chile.
- `SEQ_VTA_FACOTEC` está confirmada en `Form19` según el ticket.

### 5.3 `LIBVTA` — un registro por cierre `[CÓDIGO]`

- Z: `vta_tiporeg = 'F8'`, `vta_secuencia = 99`.
- Y: `vta_tiporeg = 'Y'`, `vta_secuencia = N° de Y`.
- `vta_techkey` une con `ZZZ`.
- Campos que se graban en el alta:
  - Techkey nuevo desde la secuencia del país.
  - `vta_estado = 'A'`.
  - `vta_tipof8 = 'N'`.
  - `vta_hora`, `vta_vendedor`.
  - `vta_secuencia_srx` = secuencia ingresada.
  - `vta_bolinicial` sale del Z anterior.
  - `vta_bolfinal` = N° de boleta.
  - `vta_cantbol = vta_bolfinal - vta_bolinicial + 1`.
  - Contador de reposición en `vta_crepo_inicial` y `vta_crepo_final`.
  - `vta_traspasado_por` queda **vacío** (está comentado en el código).

### 5.4 `ZZZ` — montos por concepto `[CÓDIGO]`

- Una columna por concepto; se une a `LIBVTA` por `rec_techkey`.
- Guarda `rec_techkey` y `rec_fechaproceso`.
- Los conceptos con columna destino `VTA_*` van a `LIBVTA`, no a `ZZZ`.
- Cuadratura:
  - `rec_mprepclaro = rec_mdiferenciaz` anterior.
  - `rec_mdiferenciaz =` diferencia calculada.
- Falabella Colombia ejecuta un `DELETE` de `ZZZ` con el techkey recién creado antes de insertar; no tiene efecto práctico (code smell).

### 5.5 `TERMSTAT` / `TERMSTATY` `[CÓDIGO]`

- `TERMSTAT`: estado del terminal por día.
  - `ter_estado` 1 o 2 = cerrado (bloquea).
  - `ter_estado = -1` = creado por ingreso manual.
  - `ter_cerradopor` = usuario conectado.
- `TERMSTATY`: estado de cada Y.
  - `ter_cierrey` = N° de Y.
  - `ter_estado = -1` = creado por ingreso manual.
  - `ter_cerradopor` = usuario conectado.
- En el AS-IS, **es el único lugar donde queda el usuario** que ingresó el cierre.

### 5.6 `ESTATUS` `[CÓDIGO]`

- Estado del local/día.
- `vta_strecauda = 1` si la recaudación del Z cuadra con la del Libro de Ventas.
- En el AS-IS de Falabella Chile, tras insertar el Z se compara la recaudación contra el Libro de Ventas y se actualiza `vta_strecauda` (1 cuadra, 0 no).

---

## 6. AS-IS — cómo funciona hoy

Fuentes: código VB6 `Form19.frm`, `Form19Y.frm`, `Módulo1.bas`, `Modulo2.bas` (FTEPROD); respaldo de estructura Oracle del 06-10-2026 (FTE-025). El DF es de 24.03.2025, por lo que puede haber deriva entre documento y código.

### 6.1 Ingreso manual del Z (`Form19`)

1. **Identificación** `[CÓDIGO]`
   - Fecha, local y terminal vienen de la pantalla principal.
   - Se ingresan: hora, secuencia, N° de boleta, vendedor y contador de reposición.

2. **Validación de identificación** `[CÓDIGO]`
   - La fecha debe ser **anterior a hoy** (fecha del servidor).
   - El terminal debe existir y estar vigente en `VTA_*TERMINALES` (`ter_fechabaja`).
     - **Atención:** usa la fecha de la pantalla principal, no la del diálogo.
   - El terminal no debe estar cerrado ese día: `TERMSTAT.ter_estado` distinto de `1` y `2`.
   - Hora, secuencia, N° de boleta, vendedor y contador de reposición son obligatorios.

3. **Grilla de conceptos** `[CÓDIGO]`
   - Lee `VTA_PAINT_Z` por `vta_localiz` del país, ordenado por `vta_order_z`.
   - Precarga los montos del Z existente (`LIBVTA` + `ZZZ` + `TERMSTAT` del día).
   - Solo las filas con `vta_pop_up = 0` son editables; `1` y `2` son títulos; `3` son totales.

4. **Montos** `[CÓDIGO]`
   - Solo números; el signo menos invierte el valor.
   - Los totales se recalculan por **número de fila fijo**, distinto por país (frágil).

5. **Confirmación** `[CÓDIGO]`
   - “¿Incorporar el nuevo cierre?”.
   - Al aceptar se repiten las validaciones de identificación y de terminal no cerrado.

6. **Borrado del Z anterior** `[CÓDIGO]`
   - `DELETE` en `LIBVTA` por fecha de venta, local, terminal y `tiporeg 'F8'`.
   - **No borra** las filas de `ZZZ` de lo eliminado.
   - Ningún paso usa transacción: si uno falla, lo anterior queda grabado.

7. **Inserción del Z en `LIBVTA`** `[CÓDIGO]`
   - Techkey nuevo desde la secuencia del país.
   - `vta_tiporeg 'F8'`, `vta_secuencia 99`, `vta_estado 'A'`, `vta_tipof8 'N'`, `vta_hora`, `vta_vendedor`, `vta_secuencia_srx`.
   - `vta_bolinicial` del Z anterior; `vta_bolfinal` = N° de boleta; `vta_cantbol`; contador de reposición.
   - `vta_traspasado_por` vacío.
   - En Falabella Chile, después compara recaudación con el Libro de Ventas y actualiza `VTA_ESTATUS.vta_strecauda`.

8. **Inserción de montos en `ZZZ`** `[CÓDIGO]`
   - `rec_techkey`, `rec_fechaproceso` y una columna por concepto con `vta_pop_up` 0 o 3.
   - Los conceptos `VTA_*` van a `LIBVTA`.

9. **Creación del estado del terminal** `[CÓDIGO]`
   - Si no hay fila del día en `TERMSTAT`: inserta `ter_estado -1`, nota “INGRESO MANUAL DE CIERRE” y `ter_cerradopor = usuario conectado`.

10. **Registro de cuadratura en `ZZZ`** `[CÓDIGO]`
    - Fórmula: formas de pago − activación gift − envío de dinero − otras operaciones − recaudaciones − ventas, usando `vta_validadorzzz` y `vta_signo`.
    - `UPDATE ZZZ`: `rec_mprepclaro = rec_mdiferenciaz` anterior; `rec_mdiferenciaz =` diferencia calculada.
    - **Aunque haya diferencia, el Z queda grabado.**

### 6.2 Ingreso manual de la Y (`Form19Y`, Tottus y Colombia)

1. **Identificación y N° de cierre Y** `[CÓDIGO]`
   - Hora, secuencia, N° de boleta, vendedor, contador de reposición y N° de cierre de Y.
   - Botón “Validar Identificación”.

2. **Validación** `[CÓDIGO]`
   - Fecha anterior a hoy; terminal vigente; terminal no cerrado ese día (`TERMSTAT`); todos los campos obligatorios, incluido el N° de Y.

3. **Resolución del N° de Y** `[CÓDIGO]`
   - Si ya existe una Y con ese N° (`LIBVTA` + `ZZZ` + `TERMSTATY`): queda en modo **modificar**.
   - Si no existe: propone el mayor N° de Y del día + 1.

4. **Grilla: Monto, Valor Z, S(Y), Diferencia** `[CÓDIGO]`
   - Conceptos de `VTA_PAINT_Z`.
   - Valor Z = monto del Z del día.
   - S(Y) = suma de las otras Y (excluye la actual).
   - Diferencia = Z − S(Y) − monto de la Y.

5. **Confirmación** `[CÓDIGO]`
   - Revalida terminal no cerrado y que esa Y no esté cerrada (`TERMSTATY`).
   - La validación que bloquea por venta distinta de formas de pago existe **solo para Argentina**; en estos negocios **no bloquea**, aunque la Diferencia no sea 0.

6. **Grabación** `[CÓDIGO]`
   - `DELETE` de esa Y en `LIBVTA` por fecha, local, terminal, `vta_tiporeg 'Y'` y `vta_secuencia = N° de Y`.
   - **No borra** su fila anterior en `ZZZ`. Sin transacción.
   - Inserta la Y en `LIBVTA` con techkey de la secuencia del país, `vta_tiporeg 'Y'`, `vta_secuencia = N° de Y`.
   - Inserta montos en `ZZZ`.
   - Crea `TERMSTATY` si no existe: `ter_cierrey = N° de Y`, `ter_estado -1`, nota “INGRESO MANUAL POR CIERRE DE Y”, `ter_cerradopor = usuario conectado`.

### 6.3 Particularidades por país

**Falabella Chile (`CHI`)**
- Solo Z; no hay Y ni `TERMSTATY`.
- Tras insertar el Z, actualiza `VTA_ESTATUS.vta_strecauda`.
- No se listan `VTA_FACOLOCALES` ni `VTA_FACOESTATUS` para este país.

**Tottus Chile (`SFCL`)**
- El Z **borra todas las Y del día**:
  - `DELETE` en `VTA_SFCLLIBVTA` por fecha, local, terminal, `tiporeg 'F8'` y también `'Y'`.
  - `DELETE` en `VTA_SFCLTERMSTATY` de todas las Y del terminal ese día.
  - No borra las filas de `ZZZ` de lo eliminado.
- **Genera la Y1 automática** al grabar el Z:
  - Copia el Z como Y con `vta_secuencia = 1` (techkey nuevo).
  - Crea su estado en `TERMSTATY` (`estado -1`).
  - Mensaje: “Éxito en la grabación del Z e Y1”.
- Secuencia: `SEQ_VTA_SFCLTEC`.
- Prefijo: la ventana dice “HTCL”, el código usa “SFCL”.

**Falabella Colombia (`FACO`)**
- El Z **borra todas las Y del día** (igual que Tottus).
- Secuencia: `SEQ_VTA_FACOTEC` (confirmada en `Form19`).
- **No valida cuadratura del Z** contra formas de pago: falta configurar `vta_validadorzzz` para `'FACO'` en `VTA_PAINT_Z` (`PEN-035`).
- `DELETE` de `ZZZ` con el techkey recién creado antes de insertar; sin efecto práctico.
- `VTA_FACOESTATUS` aparece en el ticket, pero el BPMN no la usa.

### 6.4 Deuda técnica y comportamientos de atención (AS-IS)

1. **Sin transacciones:** si falla un paso, lo anterior queda grabado.
2. **Filas huérfanas en `ZZZ`:** al borrar/reemplazar `LIBVTA` no se borra su `ZZZ`.
3. **Un Z nuevo borra todas las Y del día** (`LIBVTA` + `TERMSTATY`), lo que es peligroso en cargas masivas y obliga a ordenar Z antes que Y.
4. **El descuadre no bloquea:** el Z se graba igual; solo queda la diferencia en `rec_mdiferenciaz`.
5. **Usuario solo en `TERMSTAT.ter_cerradopor`:** no hay trazabilidad del archivo ni del proceso.
6. **Validación de terminal con fecha de la pantalla principal**, no la del diálogo.
7. **Totales por número de fila fijo**, distinto por país; cualquier cambio de orden en `VTA_PAINT_Z` rompe el cálculo.
8. **`vta_traspasado_por` comentado/vacío**, por lo que el “Informe por Conceptos de Compensación” no se alimenta en el ingreso manual.
9. **No refleja en LVTA/CMP** según el código actual, aunque el DF lo exige.
10. **Y1 automática en Tottus** puede duplicar Y si además se cargan Ys desde archivo.

---

## 7. TO-BE — propuesta de carga masiva `[BPMN]`

> Importante: es una **propuesta**, no un diseño aprobado. Varias partes están marcadas “por confirmar”.

### 7.1 Plantilla

- Se genera desde `VTA_PAINT_Z` del negocio:
  - Una columna por concepto con `vta_pop_up = 0`, en el orden `vta_order_z`.
  - Los títulos (`vta_pop_up` 1 y 2) quedan como encabezados de grupo.
  - Los totales (`vta_pop_up = 3`) no se piden: los calcula el sistema.
- Esto resuelve qué columnas son títulos y cuáles montos (`DUD-045`).
- Una fila por Z; una fila por cada Y donde aplique.
- La columna **“N° de Cierre de Y”** distingue:
  - Vacía = Z.
  - Con número = Y.
- Los conceptos sin monto se dejan vacíos y valen 0: **no hay conceptos obligatorios** (`DEC-024`).

### 7.2 Validaciones

**Del archivo:**
- Formato y columnas iguales a la plantilla vigente.
- Montos numéricos.
- Fechas válidas.

**Por fila:**
- Reutiliza las reglas del ingreso manual `[CÓDIGO]`:
  - Fecha anterior a hoy.
  - Terminal vigente.
  - Terminal no cerrado ese día.
  - Si es Y, esa Y no cerrada en `TERMSTATY`.
  - Identificación completa.
- Nuevo `[BPMN]`:
  - Recalcula los totales **por concepto** (no por número de fila).
  - Calcula la cuadratura con `vta_validadorzzz` y `vta_signo` de `VTA_PAINT_Z`.
  - Una fila descuadrada o con error se **rechaza sola** y el resto sigue (`DEC-023`).
  - Filas repetidas en el archivo (mismo local, terminal, fecha y N° de Y) se rechazan.
  - Una Y necesita su Z en el mismo archivo o ya grabado.
  - `[Por confirmar]` Si se exige que la suma de las Y cuadre con el Z y con qué tolerancia.
  - `[Por confirmar, PEN-035]` En Colombia, configurar `vta_validadorzzz` para `'FACO'` en `VTA_PAINT_Z`; hoy el Z no valida cuadratura.

### 7.3 Vista previa y orden

- **Vista previa:** filas OK y filas rechazadas con motivo y celda. Todavía no se graba nada.
- **Orden:** por terminal y día, grabar el Z antes que sus Y.
- Propuesta: el Z de la carga **no borra** las Y que vienen en el mismo archivo.
- `[DUD-039]` Definir si un Z nuevo debe seguir borrando las Y ya grabadas, como hace hoy el ingreso manual.
- `[Por confirmar]` No generar la Y1 automática cuando el archivo trae Y del terminal (Tottus).

### 7.4 Grabación (transacción por fila)

Por cada fila:

1. Techkey nuevo desde la secuencia del país.
2. Si el cierre ya existía (Modificar): borrar su registro en `LIBVTA` **y también su fila en `ZZZ`**.
3. Insertar `LIBVTA` (Z: `'F8'` / `99`; Y: `'Y'` / `N° de Y`) con los mismos campos del ingreso manual.
4. Insertar `ZZZ` con los montos.
5. Crear o actualizar `TERMSTAT` / `TERMSTATY` con nota “CARGA MASIVA” y `ter_cerradopor = 'C_MASIVA'`.
6. `[DUD-047]` Grabar también `'C_MASIVA'` en `LIBVTA.vta_traspasado_por` (`VARCHAR2(10)`, hoy vacío) para el Informe por Conceptos de Compensación.
7. Registrar la diferencia en `ZZZ.rec_mdiferenciaz` y `VTA_ESTATUS.vta_strecauda`, como hoy.
8. **Commit por fila**; si algo falla, **rollback solo de esa fila** y queda rechazada.
9. `[Por confirmar]` Reflejo en el Libro de Ventas (LVTA) y en CMP que pide el DF: el ingreso manual actual no lo hace.

### 7.5 Log y resumen

- **Log de la carga:** usuario que ejecutó, archivo, fecha y hora, filas grabadas y rechazadas.
- `[Por confirmar]` Tabla nueva de log o `VTA_LOG_ING_ZLV` (hoy existe solo en Falabella Chile).
- **Resumen:** archivo con las filas rechazadas y su motivo, listo para corregir y volver a subir.

### 7.6 Comparativa AS-IS vs TO-BE por historia `[BPMN]`

#### HU-02 — Falabella Chile (solo Z)

| Tema | Hoy (AS-IS) | Carga masiva (TO-BE) |
|---|---|---|
| Ingreso | Un Z por terminal, a mano, en `Form19` | Un archivo con muchos Z; plantilla generada desde `VTA_PAINT_Z` |
| Validaciones | Fecha anterior a hoy, terminal vigente, terminal no cerrado, campos obligatorios | Las mismas por fila, más cuadratura y filas repetidas |
| Descuadre | Se graba igual; la diferencia queda en `ZZZ.rec_mdiferenciaz` | La fila descuadrada se rechaza sola y el resto se graba (`DEC-023`) |
| Totales | Calculados por número de fila fijo de la grilla | Calculados por concepto (`vta_pop_up = 3`) |
| Usuario | `ter_cerradopor = usuario`, solo si se crea el estado del día | `'C_MASIVA'` en `TERMSTAT`; en `LIBVTA` por confirmar (`DUD-047`) |
| Consistencia | Sin transacción; la fila de `ZZZ` del Z anterior no se borra | Transacción por fila; al reemplazar se borra también su `ZZZ` |
| Trazabilidad | Ninguna para este ingreso | Log de la carga y archivo de rechazados |

#### HU-03 — Tottus Chile (Z e Y)

| Tema | Hoy (AS-IS) | Carga masiva (TO-BE) |
|---|---|---|
| Ingreso | Z en `Form19` e Y en `Form19Y`, uno a uno | Un archivo con Z e Y; la columna N° de Y distingue el tipo |
| Validaciones | Fecha, terminal vigente, terminal e Y no cerrados, obligatorios | Las mismas por fila; una Y necesita su Z |
| Z borra las Y | Un Z nuevo borra todas las Y del día en `LIBVTA` y `TERMSTATY` | Se graba el Z antes que sus Y y no borra las del mismo archivo (`DUD-039`) |
| Y1 automática | Al grabar el Z se crea la Y1 copia del Z | Por confirmar: no crearla si el archivo trae Y |
| Descuadre | Z: avisa “Z descuadrada” después de grabar. Y: no bloquea | La fila descuadrada se rechaza sola (`DEC-023`) |
| Usuario | `ter_cerradopor = usuario` al crear el estado | `'C_MASIVA'` en `TERMSTAT` y `TERMSTATY`; `LIBVTA` por confirmar |
| Consistencia | Sin transacción; `ZZZ` de lo borrado queda | Transacción por fila; borra también su `ZZZ` |

#### HU-04 — Falabella Colombia (Z e Y)

| Tema | Hoy (AS-IS) | Carga masiva (TO-BE) |
|---|---|---|
| Ingreso | Z en `Form19` e Y en `Form19Y`, uno a uno | Un archivo con Z e Y |
| Validaciones | Fecha, terminal vigente, terminal e Y no cerrados, obligatorios | Las mismas por fila; una Y necesita su Z |
| Z borra las Y | Un Z nuevo borra todas las Y del día | Igual que HU-03 (`DUD-039`) |
| Cuadratura | El Z no se valida contra las formas de pago | Validar con `VTA_PAINT_Z`; requiere configurar `vta_validadorzzz` para `'FACO'` |
| Usuario | `ter_cerradopor = usuario` al crear el estado | `'C_MASIVA'`; `LIBVTA` por confirmar |
| Consistencia | Sin transacción; `ZZZ` de lo borrado queda | Transacción por fila |

---

## 8. Ticket FCDVT-14 — HU-04 Falabella Colombia `[TICKET]`

### 8.1 Historia

> Como tesorería de Falabella Colombia, quiero cargar y corregir en forma masiva los cierres Y de varios terminales desde un archivo, para dejar de ingresarlos uno a uno.

### 8.2 Criterios de aceptación

- Los registros deben validarse en cuanto a **formato y totales**.
- Se debe dejar **log de carga**.

### 8.3 Escenarios

1. **Y de Falabella Colombia cargadas y Z calculado**
   - Dado un archivo con las Y de varios terminales de Falabella Colombia.
   - Cuando el analista confirma el ingreso.
   - Entonces se graban las Y y **el Z de cada terminal-día se calcula a partir de ellas**.

2. **Conceptos de Falabella Colombia**
   - Dado un archivo con un concepto que no existe en los parámetros de Falabella Colombia.
   - Cuando se valida.
   - Entonces se informa como error con su **fila, campo y motivo**.

3. **Corrección de una Y de Colombia**
   - Dada una Y existente de Falabella Colombia.
   - Cuando el analista carga una Modificación con algunos conceptos.
   - Entonces **cambian solo los conceptos que vienen en el archivo**.

### 8.4 Historias hijas / subtareas

| Clave | Historia | Estado |
|---|---|---|
| FCDVT-15 | HU-04.1 · Habilitar la carga masiva para Falabella Colombia con sus conceptos y su cuadratura | Tareas por hacer |
| FCDVT-16 | HU-04.2 · Ingresar las Y de Falabella Colombia y calcular el Z | Tareas por hacer |
| FCDVT-17 | HU-04.3 · Modificar conceptos de una Y existente de Falabella Colombia | Tareas por hacer |

### 8.5 Tablas y objetos listados en el ticket

- `VTA_FACOLIBVTA`
- `VTA_FACOZZZ`
- `VTA_PAINT_Z` con `vta_localiz = 'FACO'` (mapeo de conceptos; el código no usa `VTA_FACOPAINT_Z`)
- `VTA_FACOTERMSTAT`
- `VTA_FACOTERMSTATY`
- `VTA_FACOESTATUS`
- `VTA_FACOTERMINALES`
- `VTA_FACOLOCALES`
- Sequencia del techkey: `SEQ_VTA_FACOTEC` (confirmada en `Form19`)

### 8.6 Adjuntos del ticket

- `image-20261013-192154.png`: árbol HU-04 padre + 3 historias hijas.
- `image-20261013-192234.png`: flujo BPMN TO-BE.
- `Mapa BPMN · Carga masiva de cierres.html`: mapa interactivo AS-IS/TO-BE.
- El `.doc` es el export HTML del ticket; las imágenes se referencian por URL de Atlassian, pero están adjuntas en la carpeta.

---

## 9. Documento funcional (DF) — puntos clave `[DF]`

### 9.1 Antecedentes

- “Es programa”: marcado `0`.
- Nombre: **CARGA MASIVA CIERRES F8**.
- Tipo: Nuevo.
- Negocio: Falabella retail - Tottus.
- País: Chile - Colombia.
- Sistemas impactados: **F8, LV y Tesorería = sí; CMP y SCC = no**.
- Breve descripción:
  > Cargar de forma masiva los cierres de caja en F8 mediante Excel, automatizando totales por tipo de documento y medios de pago, para reemplazar el proceso manual repetitivo, lento y propenso a errores; agilizar la regularización, reducir dependencia de soporte, mejorar consistencia con SRX y LVTA, y optimizar tiempos y reportabilidad.

### 9.2 Hoja `F8-LV-CMP-TES`

- Perfil: **Analista de control venta**.
- Perfil F8: Analistas de Control de Venta, Tesorería y usuarios operativos responsables de la gestión y regularización de cierres.
- Descripción F8:
  > Implementar en F8 la carga masiva de cierres mediante Excel, con totales por tipo de documento y medios de pago, validaciones automáticas e inserción/actualización. Los cierres cargados deben tener la misma funcionalidad que los provenientes de caja y **reflejarse en el LVTA**.
- Objetivo: reducir tiempos y digitación manual, minimizar errores y descuadraturas, reducir dependencia de soporte y mejorar calidad, oportunidad y confiabilidad.
- Pantallas/reportes:
  - Pantalla de ingreso masivo vía Excel.
  - Pantalla de actualización de cierres (update masivo).
  - Mensajes de alerta por descuadraturas similares a F8 actual cuando el medio de pago no cuadra con el total de documentos.
  - Posible reporte de auditoría con logs de cargas masivas.

### 9.3 Criterios de aceptación del DF

1. Crear un **template Excel** con toda la información de venta y recaudaciones y sus formas de pago, para cargarlo en F8 y que los campos se completen (insert).
2. Tener una opción para **actualizar montos** de un cierre en F8 sin cargarlo desde cero (update).
3. Tener un sistema de validación que evite errores, igual que F8, que alerte la descuadratura y **no genere la actualización o ingreso**.
4. Tener un **switch u opción habilitable** para discernir si se carga solo una Z o si además se carga la Y, en los negocios/países que lo necesiten.
5. Al final de cada carga, generar un **log** para auditoría y control interno.

### 9.4 Consideraciones del DF

- **Falabella Colombia y Tottus Chile:** deben permitir subir o actualizar **Y y Z**.
- **Falabella Chile:** solo **ingresar Z**.

### 9.5 Plantillas Excel del DF

Las plantillas están en la hoja `F8-LV-CMP-TES`:

| Bloque | Filas | Columnas de identificación | Conceptos |
|---|---|---|---|
| Tottus Chile (insert) | R33-R35 | Fecha, Local, Terminal, **N° de Cierre de Y**, Hora, Secuencia, N° Boleta, Vendedor, Cont. Reposición, Tipo, **Tipo_carga** | Hasta columna `CL` (≈90 columnas) |
| Falabella Colombia (insert) | R37-R40 | Fecha, Local, Terminal, **N° de Cierre de Y**, Hora, Secuencia, N° Boleta, Vendedor, Cont. Reposición, Tipo | Hasta columna `BI` (≈61 columnas) |
| Falabella Chile (insert) | R42-R43 | Fecha, Local, Terminal, Hora, Secuencia, N° Boleta, Vendedor, Cont. Reposición, Tipo | Hasta columna `DA` (≈105 columnas) |
| Tottus Chile (update) | R48-R50 | Igual que Tottus insert | Mismos conceptos; `Tipo_carga = Modificar` |
| Falabella Colombia (update) | R52-R55 | Igual que Colombia insert | Mismos conceptos; las filas usan `K = Modificar` |
| Falabella Chile (update) | R59-R60 | Igual que Chile insert | Mismos conceptos; la fila usa `K = Modificar` |

**Filas de ejemplo:** fecha `46294` (serial Excel), local `216`, terminal `6`.
- Tottus: un Z y una Y con los mismos montos.
- Colombia: un Z y dos Y; el Z trae `BA = 50000`.
- Chile: un Z en local `7200`, terminal `1621`.

**Familias de conceptos** (no exhaustivo; la lista completa está en el XLSX):
- Ventas y documentos: `VENTAS`, `BOLETAS`, `N.CREDITO`, `FACTURA`, `N.DEBITO`, `GUIA FACTURABLES`, `TOTALES`.
- Formas de pago: `EFECTIVO`, `CHEQUES AL DIA`, `CHEQUES A FECHA`, `TRANSBANK`, `TARJETA DEBITO`, `CMR`, `GIFT CARD`, `TARJETA EMPRESA`, `VALE CREDITO`, `FACTURAS X COBRAR`, `NOTA CREDITO`, `TDE`, `TARJETA ALIMENTO EDE/AMI/SOD`, `GUIA CANJE DE PUNT`, `GIFT CORP`.
- Otros ingresos/egresos: `OTROS INGRESOS Y EGR`, `DOTACIONES`, `RETIROS`, `ATESORAMIENTO`, `PAGO CMR`, `PAGO FACTURAS`, `AVANCE CMR`, `FPAY`, Western Union, `ACT. GIFT CARD`.
- Recaudación: `RECAUDACION`, `REC TELEF`, `REC INTERNET`, `REC BIP`, `JUEGOS DE AZ`, `PAGO SERVICI`, `SEGUROS`, `PREPAGO MOVISTAR`, `REVERSA RECAUDACI`, `CANJE DE PUNTOS`, `REV. CANJE DE PUNT`, `QUICKPAYCMR`, `QUICKPAYDEBITO`, `AJUSTE LEY 29650`, `LINIO`, `FCOM`, `PLUXEE JUNAEB`, `EDENRED JUNAEB`, `EDENRED PRIVADO`.

**Inconsistencias de plantilla detectadas:**
- Tottus trae `Tipo_carga` en el encabezado; Colombia y Chile **no** lo traen, pero sus filas de ejemplo usan `K = Modificar`.
- Chile no trae columna “N° de Cierre de Y” (correcto para solo Z), pero tampoco una forma explícita de distinguir insert vs update.
- La primera plantilla de Colombia no trae `Tipo_carga`; la segunda usa `K = Modificar` sin encabezado.
- Las plantillas no documentan el switch pedido en el criterio 4 del DF.

### 9.6 Hoja `SCC`

- Contiene preguntas genéricas de conciliación (llaves de pareo, archivos de venta/liquidación, enriquecimiento, etc.).
- Casi todo está en `0` / `N/A`.
- Nota: “ESTE DESARROLLO YA EXISTE EN KIOSKO CL, LA IDEA ES HOMOLOGARLO PARA KIOSKO PE”.
- **No aporta al alcance F8**; parece plantilla reutilizada de otra iniciativa. SCC está marcado como no impactado.

### 9.7 Hoja `Backbone`

- Diccionario de campos CMP para archivos de venta/liquidación y campos internos de CMP.
- Referencia de conciliación, **no de F8**.
- No usar como especificación de las tablas `VTA_*`.

---

## 10. Inconsistencias, decisiones abiertas y riesgos

### 10.1 Decisiones abiertas `[BPMN]`

| # | Tema | Pregunta | Historias | Referencia |
|---|---|---|---|---|
| 1 | Z nuevo y Y existentes | ¿La carga de un Z debe seguir borrando las Y ya grabadas del día? | HU-03, HU-04 | `DUD-039` |
| 2 | Dónde queda `C_MASIVA` | `TERMSTAT`/`TERMSTATY.ter_cerradopor` ya existe; ¿también `LIBVTA.vta_traspasado_por`? | HU-02, 03, 04 | `DUD-047` |
| 3 | Y1 automática de Tottus | ¿Se omite cuando el archivo trae las Y del terminal? | HU-03 | — |
| 4 | Suma de Y contra el Z | ¿Se exige que S(Y) cuadre con el Z y con qué tolerancia? | HU-03, HU-04 | — |
| 5 | Cuadratura en Colombia | Configurar `vta_validadorzzz` para `'FACO'` en `VTA_PAINT_Z` | HU-04 | `PEN-035` |
| 6 | Log de cargas | ¿Tabla nueva o `VTA_LOG_ING_ZLV` (hoy solo Falabella Chile)? | HU-02, 03, 04 | — |
| 7 | Libro de Ventas y CMP | El DF pide reflejo en LVTA y CMP; el ingreso manual actual no lo hace en este código | HU-02, 03, 04 | — |
| 8 | Prefijo de Tottus | La ventana dice “HTCL”; el código usa “SFCL”. Confirmar instancia y tablas | HU-03 | — |

### 10.2 Inconsistencias entre fuentes (priorizadas)

1. **Z derivado vs Z cargado (crítica).**
   - `[TICKET]` HU-04.2 y el escenario 1: las Y se graban y **el Z se calcula a partir de ellas**.
   - `[BPMN]` TO-BE: se carga una fila Z y filas Y desde el archivo; solo se recalculan totales y cuadratura.
   - No está definido quién/ cómo se calcula el Z ni qué pasa al modificar una Y.
2. **Alcance del rechazo por descuadre.**
   - `[DF]`: “no debe generar la actualización o ingreso” (parece abortar todo).
   - `[BPMN]`: `DEC-023` rechaza solo la fila y sigue con el resto.
   - Definir si es por fila o por archivo.
3. **Modificación parcial de una Y.**
   - `[TICKET]` HU-04.3: “cambian solo los conceptos que vienen en el archivo”.
   - `[BPMN]`: el guardado borra `LIBVTA` + `ZZZ` y reinserta todo con techkey nuevo, lo que no es un update parcial y pierde el vínculo histórico.
4. **CMP marcado como no impactado, pero se exige reflejo en CMP/LVTA.**
   - `[DF]` antecedentes: CMP = 0.
   - `[DF]` descripción y `[BPMN]` decisión 7: reflejo en LVTA y CMP.
   - Aclarar alcance real de CMP.
5. **LV y Tesorería impactados sin especificación.**
   - `[DF]` los marca `1`, pero la hoja `F8-LV-CMP-TES` solo desarrolla F8; no hay descripción de cambios en LV ni Tesorería.
6. **Plantillas inconsistentes.**
   - Ver sección 9.5: `Tipo_carga` sin encabezado, Chile sin N° de Y, falta de switch insert/update.
7. **`VTA_FACOESTATUS` vs `VTA_ESTATUS`.**
   - El ticket lista `VTA_FACOESTATUS`; el BPMN de Colombia no la usa. El único `ESTATUS` del BPMN es `VTA_ESTATUS` para Chile.
8. **“HTCL” vs “SFCL”.**
   - La ventana de Tottus dice HTCL; el código usa SFCL. Riesgo de apuntar a tablas/instancia equivocadas.
9. **Y1 automática vs carga de Y.**
   - Tottus genera Y1 al grabar Z; si el archivo trae Ys, puede duplicar o chocar.
10. **`vta_traspasado_por` vacío.**
    - El Informe por Conceptos de Compensación no se alimenta en el ingreso manual; el TO-BE propone `'C_MASIVA'`, pero está por confirmar (`DUD-047`).
11. **Log no definido.**
    - Nueva tabla vs `VTA_LOG_ING_ZLV` (solo Chile); impacto en auditoría y multi-país.
12. **`VTA_FACOLOCALES` solo en ticket**, no usada por el BPMN; confirmar si se requiere validar local.
13. **Fecha de vigencia del terminal.**
    - El AS-IS usa la fecha de la pantalla principal, no la del diálogo; posible bug a replicar o corregir.

### 10.3 Riesgos técnicos del AS-IS que el TO-BE debe resolver

- Escrituras parciales por falta de transacción.
- `ZZZ` huérfano al borrar `LIBVTA`.
- Borrado masivo de Y al grabar un Z.
- Descuadre silencioso (no bloquea).
- Totales acoplados a la posición de fila.
- Falta de trazabilidad de usuario/archivo.
- Duplicidad al reintentar cargas.
- Diferencias de configuración por país (`vta_validadorzzz`, secuencias, prefijos).

---

## 11. Preguntas que hay que llevar a negocio / TI

1. ¿El Z de Colombia se **envía** en el archivo o se **calcula** desde las Y? Si se calcula, ¿con qué reglas y qué pasa al modificar una Y?
2. Si una fila está descuadrada, ¿se rechaza solo esa fila o se aborta todo el archivo?
3. ¿La modificación de una Y debe ser **parcial** (solo conceptos del archivo) o **reemplazo total** de la Y?
4. ¿Se debe seguir borrando las Y existentes al cargar un Z (`DUD-039`)?
5. ¿Dónde se registra `C_MASIVA` (`DUD-047`)? ¿Solo `TERMSTAT`/`TERMSTATY` o también `LIBVTA.vta_traspasado_por`?
6. ¿Se exige que la suma de las Y cuadre con el Z? ¿Con qué tolerancia?
7. ¿Se omite la Y1 automática de Tottus cuando el archivo trae Ys?
8. ¿Qué tabla se usa para el log: nueva o `VTA_LOG_ING_ZLV`? ¿Debe ser multi-país?
9. ¿Cuál es el alcance real en LVTA y CMP? ¿Quién lo implementa?
10. ¿Qué cambios se requieren en LV y Tesorería, que están marcados como impactados pero no especificados?
11. ¿La instancia de Tottus es HTCL o SFCL? ¿Qué tablas usa realmente?
12. ¿Falabella Chile permite solo insertar Z o también actualizar? El DF dice “solo ingresar Z”, pero el criterio 2 pide update.
13. ¿Se valida el local (`VTA_FACOLOCALES`) además del terminal?
14. ¿Qué pasa con los cierres ya cerrados (`ter_estado` 1/2) y con las Y cerradas?
15. ¿Cómo se manejan los reintentos y la idempotencia de una carga?

---

## 12. Próximos pasos sugeridos

1. **Cerrar la decisión Z derivado vs Z cargado** con negocio y TI; es la contradicción de mayor impacto.
2. Definir el alcance exacto del rechazo (fila vs archivo) y de la modificación parcial.
3. Completar el DF en las hojas de LV y Tesorería; aclarar CMP.
4. Corregir y homologar las plantillas Excel:
   - Agregar `Tipo_carga` en Colombia y Chile.
   - Definir el switch Z-only / Z+Y.
   - Alinear encabezados con filas de ejemplo.
5. Cerrar `DUD-039`, `DUD-047`, `PEN-035`, log y Y1.
6. Confirmar HTCL vs SFCL y las tablas/instancia de Tottus.
7. Especificar el cálculo/diagnóstico de cuadratura para `FACO`.
8. Diseñar el log y la idempotencia de cargas.
9. Acordar el reflejo en LVTA/CMP y su responsable.
10. Convertir los criterios de aceptación en casos de prueba verificables (archivo válido, fila descuadrada, concepto inexistente, Y sin Z, duplicados, reemplazo, etc.).

---

## 13. Trazabilidad de fuentes

| Fuente | Ubicación / referencia |
|---|---|
| Ticket FCDVT-14 | `FCDVT-14.doc` (HTML), datos en líneas 77-232; descripción 362-391; tablas 394-439; imágenes 444-450 |
| DF antecedentes | XLSX hoja `Antecedentes generales`, filas 3-25 |
| DF F8 | XLSX hoja `F8-LV-CMP-TES`, filas 3-60; plantillas R33-60 |
| DF SCC | XLSX hoja `SCC`, filas 3-61 (genérica, no aplica) |
| DF Backbone | XLSX hoja `Backbone`, filas 3-126 (diccionario CMP, no F8) |
| Mapa AS-IS/TO-BE | `Mapa BPMN · Carga masiva de cierres.html`, objeto `D` (9 escenarios), `CMP` y `DEC` |
| Evidencia de código | VB6 FTEPROD: `Form19.frm`, `Form19Y.frm`, `Módulo1.bas`, `Modulo2.bas` (citados en el mapa; no están en la carpeta) |
| Estructura Oracle | Respaldo del 06-10-2026 (FTE-025), citado en el mapa |
| Decisiones | `DEC-023`, `DEC-024`; dudas `DUD-039`, `DUD-045`, `DUD-047`; pendiente `PEN-035` |

> Nota: los archivos `.bpmn` individuales no están en la carpeta; el mapa HTML los embebe como XML dentro del objeto `D`. Cuando se incorporen, priorizarlos sobre el HTML.

---

## 14. Changelog

| Fecha | Cambio |
|---|---|
| 2026-10-28 | Creación de este archivo tras leer y analizar los 5 archivos de la carpeta. Se documentan inventario, AS-IS, TO-BE, alcance por país, modelo de datos, ticket, DF, decisiones abiertas, riesgos y próximos pasos. |
