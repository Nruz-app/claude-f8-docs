# Cambios para producción: FSCC-12901, FCDVT-14 y FCDVT-56

Generado el 22-10-2026, comparando la copia de producción `C:\Users\NRUZ\Downloads\FTEPROD` (**PROD**) con `D:\Fala\F8\FTEPROD` (**LOCAL**).

Contenido de esta carpeta:

| Carpeta | Qué contiene |
|---|---|
| `archivos/` | Archivos listos para llevar a producción: copias binarias exactas, en Windows-1252 con CRLF. `Form174.frm` es la **versión de producción**, ver §2.4 |
| `archivos/otros/` | `Form172.frm` y `Form173.frm`: tienen cambios que **no** son de estos requerimientos (§4) |
| `PROD/` | Los originales de producción de cada archivo que cambia. Sirven para el rollback y para comparar |
| `diffs/` | Un `diff -u` por archivo, de PROD al nuevo, convertido a UTF-8 para leerlo |
| `MANIFIESTO.md5` | MD5 de todo lo anterior. Se verifica desde esta carpeta con `md5sum -c MANIFIESTO.md5` |

## 1. Resumen: qué archivos se llevan

| # | Archivo | Requerimiento | Tipo | Líneas (+ / −) | MD5 PROD | MD5 nuevo |
|---|---|---|---|---|---|---|
| 1 | `Form133.frm` | FSCC-12901 | Modificado | +136 / −10 | `26eeeb01…` | `00abac13…` |
| 2 | `Form43.frm` | FSCC-12901 + FCDVT-56 | Modificado | +119 / −27 | `0e1bfd0c…` | `48ad588f…` |
| 3 | `MDIForm1.frm` | FCDVT-14 | Modificado | +52 / −0 | `ee06d78d…` | `9d032f55…` |
| 4 | `Form174.frm` + `Form174.frx` | FCDVT-14 | **Nuevo** | +438 | — | `958dd200…` / `cc816b30…` |
| 5 | `recaudacion.vbp` | FCDVT-14 | Agregar una línea | +1 útil | `d986352f…` | (no se copia, §2.5) |
| — | `Módulo1.bas` | Versión | **Falta hacerlo** | — | — | Subir `Gversion` (§3) |

**No se llevan:**
- `recaudacion.vbw`: son posiciones de ventanas del IDE.
- `Form174.log`: es del 20-10 a las 13:57, de cuando se creó el formulario y hubo un conflicto con el nombre `Form1722`. Está obsoleto.
- `*.bak_*` y `bash.exe.stackdump`: no son fuente.

Las copias PROD de `Form43.frm` y `Form133.frm` son idénticas, byte a byte, a los respaldos `FTEPROD/Form43.frm.bak_FSCC-12901` y `Form133.frm.bak_FSCC-12901`. Esto confirma que los cambios se hicieron sobre la versión de producción.

**Cambios cosméticos del IDE** (aparecen en los diffs y no hacen nada):
- mayúsculas en identificadores (`index` → `Index` en `Form43`; `Sql` → `sql` y `cells` → `Cells` en `Form133`);
- el número `Format` de los DTPicker de `Form43`.

VB6 no distingue mayúsculas, así que no cambian el comportamiento.

## 2. Análisis por archivo

### 2.1 `Form133.frm`: carga manual de sobres (FSCC-12901)

En FACO, la carga de sobres registra automáticamente la **DI** (diferencia no imputable) de cada caja cargada. **No cierra la Y**: la caja queda Pendiente y el cierre lo hace el cron diario o "Cerrar Terminal" de CC.

| Bloque (marca `xintec-nruz`) | Dónde | Qué hace |
|---|---|---|
| 19-10 · cajas de la carga | `CargarArchivo`, declaraciones y bucle de inserción | Arma la lista `|local;terminal;fecha;Y|`, sin repetir, de las filas FACO con Y > 0 que se insertaron |
| 19-10 · la carga ya no cierra la Y | `CargarArchivo`, después del mensaje "Se Cargaron N Registros" | Si es FACO y hay cajas, llama a `EjecutaCompensaDIFACO` |
| 19-10 / 20-10 · `EjecutaCompensaDIFACO` (sub nueva) | Antes de `Form_Load` | Por cada caja llama con `ADODB.Command` a `PKG_F8_COMPENSA_DI_CARGA.prc_compensa_caja(Flg_Pais$, fecha, local, terminal, Y, …)`. La versión multipaís del 20-10 pasa el país como primer parámetro. Un error en una caja no corta las demás. Al final muestra un resumen: cajas con DI, sin DI y el detalle |

- **Otros países:** sin cambios, porque todo está condicionado a `Flg_Pais$ = "FACO"`.
- **Prerrequisitos en la base de producción** (`docs/sql/FSCC-12901_COMPENSA_DI/`, ver su `00_LEEME.md`):
  - `02_log_compensa_di.sql` (log y secuencia);
  - `03_parametros.sql` (1502 `CA_DI_ACTIVO`, `CA_DI_MIN`, `CA_DI_MAX`, `CA_DECIMAL`);
  - `04` y `05` (`PKG_F8_COMPENSA_DI_CARGA` **multipaís**);
  - `06_grants_sinonimos.sql`: `execute` sobre el paquete para el usuario de `[CONNECT]`.

  `01_DESINSTALAR_v2.sql` solo hace falta donde se instaló la v2, es decir, en test. **Si el paquete no está, cada carga FACO muestra un error de Oracle después de grabar los sobres**: los sobres quedan cargados, pero no se registra la DI.
- **Qué probar:** cargar un Excel FACO con una caja cuya Dif. Real esté en [−1.000, +20.000]. Debe registrar la DI y la caja tiene que quedar Pendiente con Dif. Real 0.

### 2.2 `Form43.frm`: Consultas de Cuadratura, CC (FSCC-12901 + FCDVT-56)

| Bloque | Ticket | Dónde | Qué hace |
|---|---|---|---|
| 16-10 · cajas con DR 0 | FSCC-12901 | `SubBuscarOpcion` | La grilla "Terminal" de FACO muestra también las cajas con Diferencia Real 0, como Chile, para poder cerrarlas |
| 20-10 · `0-TODOS` | FSCC-12901 | `LeeLocales` | Agrega `0-TODOS` como primera opción del combo Local. Solo FACO y perfiles 9 y 10 |
| 20-10 · confirmación con TODOS | FSCC-12901 | `Command4_Click` (Cerrar Terminal) | Con `0-TODOS` pide confirmar el número de cajas con DR 0, los locales y el rango de fechas |
| 20-10 · mensaje final | FSCC-12901 | `Command4_Click` | En FACO cuenta las filas "Cerrado" antes y después del cierre. Antes siempre decía "No hay Terminales que Cumplan…" |
| 22-10 · filtro de Terminal | FCDVT-56 | `FuncStrPivote` | En FACO, con la opción Terminal, el combo Terminal filtra cuando es distinto de 0 |
| 22-10 · terminales sin movimiento | FCDVT-56 | `FuncStrPivote` | En FACO, con la opción Terminal (con un local elegido o, desde el 28-10, con `0-TODOS`), agrega con un `UNION` los terminales vigentes que tienen la Z pero no libro de ventas Y. Salen con Cierre Y 0 y el estado de la Z. "Cerrar Terminal" ya los cerraba con `CierraTerminal`, que deja la Z en estado 1 |

- **Prerrequisitos en la base:** ninguno. Usa tablas existentes.
- **Qué probar:**
  1. CC, FACO, local con un terminal sin venta (por ejemplo local 5, T2): se ve con Cierre Y 0 y "Pendiente"; "Cerrar Terminal" lo pasa a "Cerrado".
  2. Con `0-TODOS` (perfil 9 o 10) y Terminal 0 aparecen también los terminales sin venta de todos los locales, y al cerrar aparece la confirmación.
  3. Otro país: sin cambios.
- **Riesgo:** con un local grande la consulta tarda más, porque cada fila hace unas 10 consultas. Desde el 28-10, a pedido del usuario, con `0-TODOS` también se agregan los terminales sin venta: con un rango de varios días la consulta puede tardar bastante.

### 2.3 `MDIForm1.frm`: submenú del botón Y (FCDVT-14)

| Bloque | Dónde | Qué hace |
|---|---|---|
| Diseño | `Toolbar1`, `Button15` | Dos `ButtonMenus` ocultos: `INGY` "Ingreso del YYY" e `INGYMA` "Ingreso del YYY Masivo" |
| 20-10 · permiso 460 | `SubBuscarOpcionMenu` | En FACO, con el permiso 460, el botón 15 pasa a dropdown y muestra `INGYMA` |
| 20-10 · botón Y a submenú | `SubBuscarOpcionMenu` | En FACO, el permiso 15 muestra `INGY` dentro del dropdown |
| 20-10 · sin permiso 15 | `Toolbar1_ButtonClick` (`YYYY`) | En FACO, si solo tiene el masivo, pide usar la flecha en vez de abrir `Form19Y` |
| 20-10 · `INGY` / `INGYMA` | `Toolbar1_ButtonMenuClick` | `INGY` abre `Form19Y`; `INGYMA` abre `Form174` (solo FACO). Después refresca la F8 activa |

- **Prerrequisitos en la base:** `docs/sql/FCDVT-14/01_menu_ingreso_masivo_y.sql`, que crea el menú 460 para los perfiles 10 y 11. **Hay que ejecutarlo en producción solo junto con el exe nuevo.** Un exe anterior no ignora las filas 460: corta la carga de los permisos siguientes (ver `docs/sql/FCDVT-14/00_LEEME.md`).
- **Dependencia:** `Form174` tiene que estar en el proyecto (§2.4 y §2.5). Si no, no compila.
- **Qué probar:** en FACO el botón Y muestra la flecha, con "Ingreso" (permiso 15) y "Masivo" (permiso 460). En otro país el botón Y no cambia.

### 2.4 `Form174.frm` + `Form174.frx`: Ingreso de Cierres de Terminal Y Masivo (FCDVT-14), nuevo

| Control o rutina | Estado | Qué hace |
|---|---|---|
| Buscar (`Command1`) | Programado | Elige el CSV y muestra la ruta. **Carga la grilla** `Grid1` (22-10) con Local, Terminal, Fecha Venta y Monto Total (BOLETAS + N.CREDITO + FACTURA). Si el encabezado no es el de la plantilla, avisa |
| Exportar Excel (`Command2`) | Programado | Guarda una plantilla CSV con las 54 columnas |
| Cargar (`Command4`) | **Sin código** | El botón existe, pero todavía no hace nada (diseño en `docs/README_FCDVT-14.md` §5.4) |
| Salir (`Command3`) | **Versión prod** | En LOCAL, Salir ejecuta la **prueba temporal** del cierre diario (`EjecutaCierreDiario`, que llama a `PKG_F8_CIERRE_DIARIO` con una fecha fija). La copia de `archivos/` lo deja **solo con `Unload Me`**: la llamada queda comentada con la marca `xintec-nruz 22-10-2026 FCDVT-14: version prod`. Esa es la única diferencia con `FTEPROD/Form174.frm` (MD5 `a61757ca…`, con la fecha de prueba 20-08-2026 desde el 22-10) |

- **OCX:** `COMDLG32.OCX` y `MSFLXGRD.OCX`. Los dos ya están en el `.vbp` de producción.
- **Prerrequisitos en la base:** ninguno para Buscar y Exportar. `EjecutaCierreDiario` queda en el código, pero no se llama.
- **Decisión pendiente:** como Cargar todavía no hace nada, la opción "Ingreso del YYY Masivo" mostraría una pantalla que no graba. Se puede dejar el permiso 460 sin ejecutar en producción hasta que Cargar esté listo; el submenú aparece solo con ese permiso.

### 2.5 `recaudacion.vbp`

La única diferencia útil es una línea nueva, `Form=Form174.frm`. En LOCAL está después de `Form=Form173.frm` (ver `diffs/recaudacion.vbp.diff`).

Las demás diferencias son de ambiente y **no se llevan**:
- las rutas relativas de las 4 `Reference` (`..\Windows` contra `..\..\..\WINDOWS`);
- `MSCOMCTL.OCX` en minúsculas.

Por eso el `.vbp` no se copia entero: **en producción hay que agregar solo esa línea**. También se puede agregar el formulario desde el IDE con Proyecto → Agregar formulario.

## 3. Pasos sugeridos para el paso a producción

1. **Base de producción, antes del exe:**
   - FSCC-12901: `docs/sql/FSCC-12901_COMPENSA_DI/` (02 a 06). Lo requiere `Form133`.
   - FCDVT-14: `docs/sql/FCDVT-14/01_menu_ingreso_masivo_y.sql`. Va **junto con** el exe nuevo; o se posterga, ver §2.4.
   - El cron de cierre diario (`docs/sql/FSCC-12901_CIERRE_DIARIO/`, que con FCDVT-56 incluye la etapa sin venta) **no depende del exe** y puede ir aparte. Todavía no está probado en test.
2. **Fuentes:** copiar desde `archivos/` a la carpeta del proyecto de producción `Form133.frm`, `Form43.frm`, `MDIForm1.frm`, `Form174.frm` y `Form174.frx`, y agregar `Form=Form174.frm` al `.vbp`. No convertir la codificación: los archivos van en Windows-1252 con CRLF.
3. **Versión:** subir `Global Const Gversion` en `Módulo1.bas` (hoy `"3.4.9"`) y `vta_parametros.vta_ultversion` de cada país (CLAUDE.md §2). Si no se hace, el exe no arranca o se autoactualiza a otra versión.
4. **Compilar** `f8a.exe`. El IDE no debe generar ningún `Form*.log`.
5. **Probar en producción:** los puntos "Qué probar" de §2.1 a §2.4.
6. **Rollback:**
   - volver a copiar los archivos de `PROD/`;
   - quitar `Form174` del `.vbp`;
   - recompilar, o usar el exe anterior (`f8a <fecha>.exe`);
   - en la base, los `99_rollback.sql` de cada carpeta.

## 4. Otros cambios, sin marca: `Form172.frm` y `Form173.frm`

Pantallas de la cuadratura de efectivo de la depositaria API contra la cartola (Prosegur, botón `CECB`).
- **No tienen marcas `xintec-nruz` ni respaldos.** `docs/README_FSCC-12948.md` dice que esas pantallas **no** cambian en FSCC-12948.
- **Fechas en LOCAL:** `Form172` es del 20-10 a las 14:06 y `Form173` del 09-10 a las 11:46.
- Se incluyen **aparte** (`archivos/otros/`, `PROD/otros/`, `diffs/otros/`) para decidir si van en este paso.

**`Form172.frm`** (+119 / −73):
- **Diseño:** algunas grillas pasan de 10575 a 10695 de ancho, y cambia el número de formato de los DTPicker.
- **Al consultar:** calcula la diferencia depositaria − banco a partir de la consulta. Antes la leía de `BuscarProsegurTransSum`. La graba con `GrabarProsegurTransSum`.
- **Edición del monto de banco** (`txtEdit`):
  - valida que el monto sea numérico y avisa;
  - quita los separadores de miles;
  - recalcula la diferencia y la graba;
  - corrige el nombre de la variable "Despitaria".
- **`GrabarProsegurTransSum`:** el `MERGE INTO PROSEGUR_TRANS_SUM` cruza por `ID_PRO_TRANS_SUM`, antes por `SERVICE_POINT_CODE` + `ACCOUNTING_DATE`. Usa `TO_DATE(…,'YYYYMMDD')` en vez de `TO_TIMESTAMP` y actualiza también el local y la fecha.
- **Exportar a Excel:** la fecha va como fecha y los montos como números.

**`Form173.frm`** (+271 / −120):
- **Diseño:** etiqueta nueva "V 0.2" (`Label2(0)`).
- **Rematch** (`txtEdit`): repone `mEjecutando = False` al empezar y al terminar `ExisteVtaTempEsc`. Así corrige el defecto conocido, que salteaba en silencio las llamadas después de un error (CLAUDE.md §4.8). Si sale bien, avisa con el código de barra, el local, el terminal y la fecha.
- **Exportar a Excel:** reescrito con dos secciones, DEPOSITADOS y NO DEPOSITADOS, con formato de fecha y montos. Función nueva `ConvertirFechaExcel`.
- **Prerrequisitos en la base:** `Form172` usa la columna `ID_PRO_TRANS_SUM` de `PROSEGUR_TRANS_SUM` como clave del `MERGE`. Hay que confirmar que en producción exista y sea única.
