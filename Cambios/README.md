# Cambios para producción: FSCC-12901, FCDVT-14, FCDVT-56, FCDVT-10 y FCDVT-259

Generado el 22-10-2026, comparando la copia de producción `C:\Users\NRUZ\Downloads\FTEPROD` (**PROD**) con `D:\Fala\F8\FTEPROD` (**LOCAL**). Actualizado el 02-11-2026: `Form43.frm`, `Form133.frm` y `Form174.frm` se sincronizaron con LOCAL (cambios del 30-10 y 02-11). Actualizado el 03-11-2026: `Form174.frm` (fecha de prueba de Salir 02-11-2026 y clic en la grilla que abre Form175), `Form175.frm` + `.frx` nuevos y la línea `Form=Form175.frm` del `.vbp`. Más tarde el mismo día, `Form174.frm` con Exportar Excel como plantilla `.xlsx` (§2.4), y `Form174.frm` / `Form175.frm` con el estado CARGADO y el package multipaís. Actualizado el 04-11-2026: `Form174.frm` con el botón **Cargar** (`Command4_Click` → `PKG_F8_GRABA_MASIVA_YZ.prc_graba`, package propio, estado GRABADO) y `Form175.frm` con el log de la etapa GRABADO. Actualizado el 11-11-2026 (FCDVT-10): `MDIForm1.frm` y `Form174.frm` habilitan la carga masiva también para Tottus Chile (`SFCL`), con sus propios packages `PKG_F8_CARGA_MASIVA_YZ_SFCL` / `PKG_F8_GRABA_MASIVA_YZ_SFCL` (§2.3 y §2.4). Actualizado el 16-11-2026 (FCDVT-14): `Form174.frm` con **local, fecha y Descargar Excel** en la franja superior (antes Exportar Excel abajo), que descarga la Z y las Y grabadas con `PKG_F8_EXPORTA_MASIVA_YZ` (§2.4). Actualizado el 16-11-2026 (FCDVT-259): ese Descargar Excel **se revirtió** y `Form174.frm` volvió a la versión del 11-11 (`FTEPROD/Form174.frm.bak_FCDVT-14_Descargar`); la exportación pasa a **`Form176.frm` + `.frx`, nuevo** (Exportar Cierres Y y Z a CSV, solo FACO, §2.7), con el submenú `EXPYZ` del botón Y y el permiso 461 en `MDIForm1.frm` (§2.3) y la línea `Form=Form176.frm` del `.vbp` (§2.5). Actualizado el 17-11-2026 (FCDVT-259): `Form176.frm` con la **regla de fechas nueva** — calendarios con ayer por defecto y tope ayer (sin límite hacia atrás, se quitó `MinDate`) y en Exportar un **rango máximo de 3 días incluidos** entre Fecha Inicio y Fecha Fin (se quitó el límite "Fecha Inicio ≥ hoy − 2") —, que restaura el bloque de fechas del servidor que estaba comentado en la copia de `FTEPROD/` (era el motivo del aviso "hoy (30-12-1899)"), §2.7. Actualizado el 18-11-2026 (FCDVT-259): bloque "Resultado de la exportación" de `Form176.frm` reordenado (ruta, formato y conteo en renglones separados, con más alto) para que no se superponga el texto cuando la ruta es larga; sin cambios en `.frx`. Actualizado el 19-11-2026 (FCDVT-10): `Form174.frm` con las **reglas de Colombia también para Tottus** (solo INGRESAR, sin Y1 automática ni MODIFICAR en la plantilla y en el aviso de Cargar), §2.4.

**Regla:** esta carpeta siempre refleja `FTEPROD/`. Todo cambio en un fuente de `FTEPROD/` se lleva aquí en la misma tarea (copia en `archivos/`, diff, este README y `MANIFIESTO.md5`). Ver CLAUDE.md §9.

Contenido de esta carpeta:

| Carpeta | Qué contiene |
|---|---|
| `archivos/` | Archivos listos para llevar a producción: copias binarias exactas de `FTEPROD/`, en Windows-1252 con CRLF |
| `archivos/otros/` | `Form172.frm` y `Form173.frm`: tienen cambios que **no** son de estos requerimientos (§4) |
| `PROD/` | Los originales de producción de cada archivo que cambia. Sirven para el rollback y para comparar |
| `diffs/` | Un `diff -u` por archivo, de PROD al nuevo, convertido a UTF-8 para leerlo |
| `MANIFIESTO.md5` | MD5 de todo lo anterior. Se verifica desde esta carpeta con `md5sum -c MANIFIESTO.md5` |

## 1. Resumen: qué archivos se llevan

| # | Archivo | Requerimiento | Tipo | Líneas (+ / −) | MD5 PROD | MD5 nuevo |
|---|---|---|---|---|---|---|
| 1 | `Form133.frm` | FSCC-12901 | Modificado | +120 / −10 | `26eeeb01…` | `ed11df46…` |
| 2 | `Form43.frm` | FSCC-12901 + FCDVT-56 | Modificado | +113 / −27 | `0e1bfd0c…` | `07270ede…` |
| 3 | `MDIForm1.frm` | FCDVT-14 + FCDVT-10 + FCDVT-259 | Modificado | +80 / −0 | `ee06d78d…` | `61c1c0de…` |
| 4 | `Form174.frm` + `Form174.frx` | FCDVT-14 + FCDVT-10 | **Nuevo** | +1133 | — | `c787725e…` / `cc816b30…` |
| 4b | `Form175.frm` + `Form175.frx` | FCDVT-14 | **Nuevo** | +260 | — | `b5e227e7…` / `cc816b30…` (el `.frx` es copia de `Form174.frx`) |
| 4c | `Form176.frm` + `Form176.frx` | FCDVT-259 | **Nuevo** | +628 | — | `b14ace09…` / `cc816b30…` (el `.frx` es copia de `Form174.frx`) |
| 5 | `recaudacion.vbp` | FCDVT-14 + FCDVT-259 | Agregar tres líneas (`Form174`, `Form175`, `Form176`) | +3 útiles | `d986352f…` | (no se copia, §2.5) |
| — | `Módulo1.bas` | Versión | **Falta hacerlo** | — | — | Subir `Gversion` (§3) |

**No se llevan:**
- `recaudacion.vbw`: son posiciones de ventanas del IDE.
- `Form174.log`: es del 20-10 a las 13:57, de cuando se creó el formulario y hubo un conflicto con el nombre `Form1722`. Está obsoleto.
- `*.bak_*` y `bash.exe.stackdump`: no son fuente.
- `Form133.frx`, `Form43.frx` y `MDIForm1.frx`: tienen fecha reciente en `FTEPROD/` (`MDIForm1.frx` 20-10; `Form133.frx` y `Form43.frx` 30-10) porque el IDE los vuelve a grabar al guardar el formulario, pero estos requerimientos no cambian el diseño de esas pantallas (los diffs de sus `.frm` no tocan offsets `.frx`). Se deja el `.frx` de producción. No se pudieron comparar byte a byte (nota del 16-11-2026): la copia de producción `C:\Users\NRUZ\Downloads\FTEPROD` ya no existe. Si al compilar en producción aparece un error de carga del `.frx`, copiar también el de `FTEPROD/`.

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
| 19-10 / 20-10 · `EjecutaCompensaDIFACO` (sub nueva) | Antes de `Form_Load` | Por cada caja llama con `ADODB.Command` a `PKG_F8_COMPENSA_DI_CARGA.prc_compensa_caja(Flg_Pais$, fecha, local, terminal, Y, …)`. La versión multipaís del 20-10 pasa el país como primer parámetro. Un error en una caja no corta las demás. **Desde el 30-10 no muestra el resumen final** (cajas con DI, sin DI y detalle): la versión LOCAL ya no tiene ese `MsgBox` ni las líneas comentadas de la llamada anterior sin país |

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
| 22-10 · terminales sin movimiento | FCDVT-56 | `FuncStrPivote` | En FACO, con la opción Terminal y **un local elegido** (no con `0-TODOS`), agrega con un `UNION` los terminales vigentes que tienen la Z pero no libro de ventas Y. Salen con Cierre Y 0 y el estado de la Z. "Cerrar Terminal" ya los cerraba con `CierraTerminal`, que deja la Z en estado 1. El cambio del 28-10, que lo extendía a `0-TODOS`, **no está** en la versión LOCAL del 30-10 |
| 20-10 · nombre de `0-TODOS` | FSCC-12901 | `LeeLocales` | La opción se muestra como "TODOS LOS LOCALES" (la versión del 28-10 decía "TODOS") |

- **Prerrequisitos en la base:** ninguno. Usa tablas existentes.
- **Qué probar:**
  1. CC, FACO, local con un terminal sin venta (por ejemplo local 5, T2): se ve con Cierre Y 0 y "Pendiente"; "Cerrar Terminal" lo pasa a "Cerrado".
  2. Con `0-TODOS LOS LOCALES` (perfil 9 o 10) aparecen las cajas con DR 0 de todos los locales (sin los terminales sin venta), y al cerrar aparece la confirmación.
  3. Otro país: sin cambios.
- **Riesgo:** con un local grande la consulta tarda más, porque cada fila hace unas 10 consultas.

### 2.3 `MDIForm1.frm`: submenú del botón Y (FCDVT-14)

| Bloque | Dónde | Qué hace |
|---|---|---|
| Diseño | `Toolbar1`, `Button15` | `ButtonMenus` ocultos: `INGY` "Ingreso del YYY", `INGYMA` "Ingreso del YYY Masivo" y, desde el 16-11 (FCDVT-259), `EXPYZ` "Exportar Cierres Y y Z" (el tercero, al final: no desplaza índices) |
| 20-10 · permiso 460 | `SubBuscarOpcionMenu` | En FACO, con el permiso 460, el botón 15 pasa a dropdown y muestra `INGYMA` |
| 20-10 · botón Y a submenú | `SubBuscarOpcionMenu` | En FACO, el permiso 15 muestra `INGY` dentro del dropdown |
| 20-10 · sin permiso 15 | `Toolbar1_ButtonClick` (`YYYY`) | En FACO, si solo tiene el masivo, pide usar la flecha en vez de abrir `Form19Y` |
| 20-10 · `INGY` / `INGYMA` | `Toolbar1_ButtonMenuClick` | `INGY` abre `Form19Y`; `INGYMA` abre `Form174` (solo FACO). Después refresca la F8 activa |
| 16-11 · permiso 461 (FCDVT-259) | `SubBuscarOpcionMenu` | Solo FACO: con el permiso 461 el botón 15 pasa a dropdown y muestra `EXPYZ` (`ButtonMenus(3)`) |
| 16-11 · `EXPYZ` (FCDVT-259) | `Toolbar1_ButtonMenuClick` | Abre `Form176` (solo FACO). No refresca la F8: Form176 no graba |

- **Prerrequisitos en la base:** `docs/sql/FCDVT-14/01_menu_ingreso_masivo_y.sql`, que crea el menú 460 para los perfiles 10 y 11. **Hay que ejecutarlo en producción solo junto con el exe nuevo.** Un exe anterior no ignora las filas 460: corta la carga de los permisos siguientes (ver `docs/sql/FCDVT-14/00_LEEME.md`).
- **Dependencia:** `Form174` tiene que estar en el proyecto (§2.4 y §2.5). Si no, no compila.
- **Qué probar:** en FACO el botón Y muestra la flecha, con "Ingreso" (permiso 15) y "Masivo" (permiso 460). En otro país el botón Y no cambia.
- **FCDVT-10 (11-11-2026):** los cuatro bloques de FACO (permiso 460, botón Y a submenú, botón Y sin permiso 15 e `INGYMA` → `Form174`) valen también para **Tottus Chile (`SFCL`)**: cada condición `Flg_Pais$ = "FACO"` pasa a `FACO Or SFCL`, con la línea anterior comentada. Prerrequisito en la base de SFCL: `docs/sql/FCDVT-10/01_menu_ingreso_masivo_y_sfcl.sql` (permiso 460 en `VTA_SFCLMENU` / `VTA_SFCLRELPERMEN`; `INSERT` explícitos como el de FACO: 1 fila de menú + 1 fila por perfil, hoy 9, 10 y 12, y el resto comentado), **solo junto con este exe**, por la misma razón que en FACO. Qué probar: en SFCL el botón Y muestra la flecha con "Ingreso" y "Masivo"; "Ingreso" sigue abriendo `Form19Y`. Respaldo: `FTEPROD/MDIForm1.frm.bak_FCDVT-10`.
- **FCDVT-259 (16-11-2026):** permiso 461 y submenú `EXPYZ` → `Form176`, **solo FACO** (en SFCL no se agrega). Un perfil con 461 y sin 15 ve el botón Y como menú; al hacer clic en el botón (no en la flecha) recibe el aviso "Use la flecha del botón…" del bloque `YYYY`, que no cambia. Prerrequisito en la base: `docs/sql/FCDVT-259/01_menu_exporta_yz.sql` (perfiles 10 y 11), **solo junto con este exe** (mismo motivo que el 460). Dependencia: `Form176` en el proyecto (§2.5 y §2.7). Qué probar: en FACO el botón Y muestra "Exportar Cierres Y y Z" a los perfiles con 461 y abre Form176; en SFCL y otros países no aparece. Respaldo: `FTEPROD/MDIForm1.frm.bak_FCDVT-259`.

### 2.4 `Form174.frm` + `Form174.frx`: Ingreso de Cierres de Terminal Y Masivo (FCDVT-14), nuevo

| Control o rutina | Estado | Qué hace |
|---|---|---|
| Buscar (`Command1`) | Programado | Elige el CSV de cierres **Y y Z** y lo valida en la base (30-10 / 02-11): `PKG_F8_CARGA_MASIVA_YZ.prc_inicia` abre la carga, `prc_inserta_linea` envía cada línea con su número y `prc_procesa` valida y arma el resumen. La grilla (`LlenaGrillaResumen`) muestra el resumen por terminal-día desde `vta_<pfx>carga_yz_res`: Local, Terminal, Fecha, Cant. Y, Monto Total Y, Monto Total Z y Estado (ERROR en rojo, PENDIENTE en amarillo). Un clic en una fila abre **`Form175`** con el log del grupo (desde el 03-11; antes un `MsgBox` con doble clic, que queda comentado), ver §2.6. Al final avisa grupos cargados, grupos y líneas con error; el detalle queda en `VTA_<pfx>CARGA_YZ_LOG`. **Desde el 03-11:** el estado correcto de un grupo es **CARGADO** (antes PROCESADO) y las llamadas pasan `Flg_Pais$` como primer parámetro a `prc_inserta_linea` y `prc_procesa` (package multipaís). Las tablas se arman con `PrefijoCargaYZ()`, que usa el prefijo del país y deja a Chile sin prefijo |
| Exportar Excel (`Command2`) | Programado (03-11) | Desde el 03-11 guarda una **plantilla Excel `.xlsx` con formato** (antes un CSV, que queda comentado). Tiene tres hojas: **Carga**, **Instrucciones** (pasos y un ejemplo de Z + 2 Y que no se carga) y **Listas**, oculta. En la hoja Carga:<br>• encabezado de 56 columnas (`EncabezadoCsvY`, igual a `PKG_F8_CARGA_MASIVA_YZ.c_encabezado`), con la glosa de Form19Y en un comentario;<br>• FECHA y HORA con formato texto;<br>• validación de número entero en las identificaciones y los montos;<br>• listas en TIPO (Y/Z) y TIPO_CARGA (INGRESAR);<br>• fila 1 y columnas A:C inmovilizadas.<br>El usuario la completa y la guarda como "CSV (delimitado por comas)" para elegirla en Buscar, que no cambia. Usa Excel por automatización (`CreateObject`, como `Form171`), así que **requiere Excel 2007 o posterior** en el equipo |
| Cargar (`Command4`) | Programado (04-11) | Solo se habilita después de un Buscar con grupos CARGADO. Pide confirmación (avisa que **reemplaza** la Z y las Y que el terminal-día ya tenga) y llama a `PKG_F8_GRABA_MASIVA_YZ.prc_graba(Flg_Pais$, mCarga, LOGINUSER, ok, error)`, un package propio separado del de Buscar desde el 04-11. El package graba cada grupo CARGADO como Form19 (Z: libvta `'F8'`/99 + zzz, termstat −1 si falta) y Form19Y (Y: libvta `'Y'` + zzz + termstaty −1), con los campos en su columna, commit por grupo y estado **GRABADO** (verde en la grilla). Un grupo con la Z o alguna Y cerrada, o que falla, queda en ERROR con el motivo y sin cambios. Detalle en `docs/README_FCDVT-14.md` §5.9 |
| Salir (`Command3`) | Producción (18-11) | `Unload Me` (sin llamada a la base). El bloque de prueba `EjecutaCierreDiario` del 02-11 ya no está en el fuente vivo desde el rediseño del 17-11; ver el bloque del 18-11 |

- **Descargar Excel (16-11), revertido:** el 16-11 se agregó arriba un local, una fecha y el botón Descargar Excel (`PKG_F8_EXPORTA_MASIVA_YZ`). Ese mismo día, a pedido del usuario, se revirtió: `Form174.frm` volvió **byte a byte** a `FTEPROD/Form174.frm.bak_FCDVT-14_Descargar` (11-11, con FCDVT-10) y la versión con Descargar quedó en `Form174.frm.bak_FCDVT-259_Descargar`. La exportación pasó a `Form176` (§2.7).
- **OCX:** `COMDLG32.OCX` y `MSFLXGRD.OCX`, que ya están en el `.vbp` de producción.
- **Prerrequisitos en la base:**
  - Buscar y Cargar: `docs/sql/FCDVT-14/` 02, 03, 04, 04b, 04c y 05 (tablas `VTA_FACOCARGA_YZ_*`, `PKG_F8_CARGA_MASIVA_YZ` para Buscar, `PKG_F8_GRABA_MASIVA_YZ` para Cargar y grants; o `INSTALAR.sql`), en su versión **del 04-11**. Sin `PKG_F8_GRABA_MASIVA_YZ`, Buscar funciona pero Cargar da error de Oracle. Si el package no está, Buscar muestra el error de Oracle. **Este Form174 necesita el package multipaís**, porque llama a las firmas con país. Con el package anterior (`anterior_2026-11-03/`), Buscar da "número o tipos de argumentos erróneos". Al revés sí funciona: el package nuevo mantiene las firmas anteriores, así que acepta también el exe anterior.
  - Salir: `PKG_F8_CIERRE_DIARIO` (`docs/sql/FSCC-12901_CIERRE_DIARIO/`).
- **Salir ya no ejecuta el cierre diario (18-11-2026):** el `FTEPROD/Form174.frm` vivo (rediseñado el 17-11) quedó con `Command3_Click` solo `Unload Me`, sin `EjecutaCierreDiario`, y esta carpeta se sincronizó con él. Por lo tanto el exe **ya no depende** de `PKG_F8_CIERRE_DIARIO` para cerrar la pantalla y desaparece el riesgo anterior (cada Salir de FACO ejecutaba el cierre de la fecha fija 02-11-2026).
- **Riesgo de Cargar:** reemplaza las Y **abiertas** del terminal-día (las cerradas lo bloquean). Si alguna tenía compensaciones (`movdet` con `mov_cierrey`), quedan apuntando al número de Y del archivo. Probar en test con un caso así antes de producción.
- **Qué probar (Cargar):** Buscar con `docs/sql/FCDVT-14/ejemplo_carga_Y_FACO_20.csv` → 3 CARGADO → Cargar → 3 GRABADO; revisar con `06_pruebas.sql` (consultas 6 a 9) y limpiar con `98_limpia_prueba.sql`.
- **FCDVT-10 (11-11-2026), Tottus Chile (`SFCL`):** respaldo previo `FTEPROD/Form174.frm.bak_FCDVT-10`.

  | Bloque | Qué hace |
  |---|---|
  | `PaqueteCargaYZ()` / `PaqueteGrabaYZ()` (nuevas) | Devuelven el package del país: en SFCL `PKG_F8_CARGA_MASIVA_YZ_SFCL` / `PKG_F8_GRABA_MASIVA_YZ_SFCL` y en el resto los de FACO. Buscar (`prc_inicia`, `prc_inserta_linea`, `prc_procesa`), Cargar (`prc_graba`) y sus `SystemMsg` los usan en vez del nombre fijo. Las firmas son las mismas |
  | `EncabezadoCsvY` + `EncabezadoBase()` (nueva) | En SFCL el encabezado se lee de la base (`fn_encabezado`, conceptos de `VTA_PAINT_Z`); en FACO sigue fijo |
  | Exportar Excel | Nombre `plantilla_carga_YZ_<pfx>.xlsx`; rangos hasta la última columna del país (`ColumnaExcel`, antes `BD` fijo); en SFCL la glosa de cada monto sale de `VTA_PAINT_Z` (`GlosaPaintZ`), la lista TIPO_CARGA agrega MODIFICAR, los textos de Instrucciones explican la cuadratura de Tottus, la Y1 automática y MODIFICAR, y el ejemplo usa sus columnas (`EjemploSFCL`) |
  | Cargar | El aviso de confirmación en SFCL explica INGRESAR (reemplaza; sin Y crea la Y1) y MODIFICAR (solo los montos informados) |
  | Salir | Con el rediseño del 17-11 el form quedó solo con `Unload Me` (sin `EjecutaCierreDiario`); la condición `FACO` del 11-11 deja de aplicar |

  FACO no cambia de comportamiento: todas las ramas nuevas están condicionadas a `Flg_Pais$ = "SFCL"` y las funciones nuevas devuelven para FACO lo mismo que antes.
  - **Prerrequisitos en la base de SFCL:** `docs/sql/FCDVT-10/` (`INSTALAR.sql`: 02, 03, 04, 04b y 04c; `05` si corresponde; `01` junto con el exe).
  - **Qué probar:** en SFCL, Exportar Excel genera la plantilla con las 74 columnas de Tottus; Buscar y Cargar con los casos de `docs/sql/FCDVT-10/pruebas_cargar/LEEME.md`. Regresión FACO: Exportar, Buscar y Cargar con `docs/sql/FCDVT-14/pruebas_cargar/c01_ok.csv` dan lo mismo que antes.
- **FCDVT-10 (19-11-2026), Tottus con las reglas de Colombia:** a pedido del usuario la carga de Tottus quedó igual a la de FACO y solo cambian los campos de concepto (packages `_SFCL` reescritos en `docs/sql/FCDVT-10/`, lista fija de 63 conceptos). En `Form174` (marcas `19-11-2026 FCDVT-10`, código anterior comentado; respaldo `FTEPROD/Form174.frm.bak_FCDVT-10_ReglasFACO`):

  | Bloque | Antes (11-11) | Ahora |
  |---|---|---|
  | Lista TIPO_CARGA de la plantilla | SFCL: INGRESAR y MODIFICAR | Todos: solo INGRESAR |
  | Comentario de los montos (SFCL) | INGRESAR: vacío = 0. MODIFICAR: vacío = no cambia | Vacío = 0 |
  | Mensaje de validación y glosa de TIPO_CARGA | SFCL: INGRESAR o MODIFICAR | "Debe ser INGRESAR." / "TIPO_CARGA. INGRESAR." |
  | Instrucciones (SFCL) | Y1 automática y MODIFICAR | 1 Z y al menos 1 Y; total Z (5 conceptos de venta) = suma de las Y; puntos 4 y 5 iguales a FACO |
  | Aviso de Cargar | SFCL: INGRESAR (con Y1) y MODIFICAR | El mismo de FACO |

  Sin cambio: `PaqueteCargaYZ` / `PaqueteGrabaYZ`, `EncabezadoBase` (ahora `fn_encabezado` devuelve la lista fija), `GlosaPaintZ`, `ColumnaExcel`, `EjemploSFCL`. FACO no cambia de comportamiento (los textos que se unificaron ya eran los de FACO).
  - **Prerrequisitos en la base de SFCL:** los packages `_SFCL` del 19-11 (`docs/sql/FCDVT-10/`; en test, `07_migra_det_ancha.sql` + 03, 04, 04b y 04c). Con los packages del 11-11 el exe también funciona (mismas firmas), pero la base seguiría aceptando MODIFICAR y la Z sin Y.
  - **Qué probar:** `docs/sql/FCDVT-10/pruebas_cargar/LEEME.md` (s01–s06 GRABADO; s07, s08 y s09 con MODIFICAR o sin Y en ERROR; s03 T6 y s10 rechazados en Cargar).
- **18-11-2026, resincronización con el form vivo:** `FTEPROD/Form174.frm` se rediseñó el 17-11 (form de 9015 a 7200, `Picture1`/`Image1`/`Image2` reubicados, `Grid1` más chico, `Grid1.Row`/`.Col` con mayúscula) y en ese rediseño **se perdió todo el bloque FCDVT-10 de SFCL**: el form volvió a llamar a los packages fijos de FACO y a la plantilla de 56 columnas. El 18-11 se volvió a aplicar el bloque sobre la versión viva (marcas `11-11-2026 FCDVT-10`): `PaqueteCargaYZ()`, `PaqueteGrabaYZ()`, `EncabezadoBase()`, `GlosaPaintZ()`, `ColumnaExcel()`, `EjemploSFCL()`, la rama SFCL de `EncabezadoCsvY`, los rangos hasta la última columna del país en Exportar Excel, la lista MODIFICAR, los textos de Instrucciones y los avisos de Cargar. También se restauraron los **46 caracteres acentuados** que el rediseño había dejado como U+FFFD (`extensi?n`, `N?mero`, `vac?o`, `d?a`, …): el archivo vuelve a ser Windows-1252 con CRLF (46 bytes altos, sin U+FFFD). Estado previo del disco: 43746 bytes, md5 `1941950c782174ac60031f9e36ad66fa`; no se guardó `.bak` porque no había otra copia en disco. Después de este cambio `archivos/Form174.frm` es **idéntica** a `FTEPROD/Form174.frm`.
- **`Form175.frm`:** la copia viva también se rediseñó el 17-11 y difiere en diseño de `archivos/Form175.frm`, pero el código es el mismo (lee `vta_<pfx>carga_yz_log` y `..._det`, sin rama SFCL). No se tocó: si se quiere llevar el diseño nuevo a producción, copiar `FTEPROD/Form175.frm`.

### 2.5 `recaudacion.vbp`

Las únicas diferencias útiles son **tres líneas nuevas**, `Form=Form174.frm`, `Form=Form175.frm` (desde el 03-11) y `Form=Form176.frm` (desde el 16-11, FCDVT-259). En LOCAL van después de `Form=Form173.frm` (ver `diffs/recaudacion.vbp.diff`). Respaldo antes de la de Form176: `FTEPROD/recaudacion.vbp.bak_FCDVT-259`.

Las demás diferencias son de ambiente y **no se llevan**:
- las rutas relativas de las 4 `Reference` (`..\Windows` contra `..\..\..\WINDOWS`);
- `MSCOMCTL.OCX` en minúsculas.

Por eso el `.vbp` no se copia entero: **en producción hay que agregar solo esas tres líneas**. También se pueden agregar los formularios desde el IDE con Proyecto → Agregar formulario.

### 2.6 `Form175.frm` + `Form175.frx`: Detalle del Log de la Carga Masiva de Y y Z (FCDVT-14), nuevo

Se abre con un clic en una fila de la grilla de `Form174` (`Grid1_Click`; el clic en el encabezado no abre nada), que llama a `Form175.MuestraLog(carga, fecha, local, terminal, estado, mensaje)`. Es modal y tiene el mismo aspecto que Form174: el `.frx` es una copia binaria de `Form174.frx` (mismas imágenes y offsets).

| Control o rutina | Qué hace |
|---|---|
| `lblGrupo` / `lblMensaje` | Carga, fecha, local, terminal y estado del grupo, y su `res_mensaje` |
| `Grid1` (`LlenaGrillaLog`) | Todo el log del grupo, desde `vta_<pfx>carga_yz_log`. Muestra las líneas del archivo que forman el grupo (según `vta_<pfx>carga_yz_det`) y los mensajes RESUMEN y, desde el 04-11, GRABADO (resultado de Cargar) del grupo, que no tienen línea. Columnas: Línea, Tipo (Y/Z), N° Y, Etapa, Campo, Valor y Motivo; con motivos largos la fila se hace más alta. Si el grupo no tiene log (CARGADO), lo indica en una fila. Desde el 03-11 las tablas se arman con `PrefijoCargaYZ()` (multipaís; Chile sin prefijo) |
| Salir (`Command3`) | `Unload Me` |

- **OCX:** `MSFLXGRD.OCX`, que ya está en el `.vbp`.
- **Prerrequisitos en la base:** los mismos de Buscar (§2.4). Solo lee, con el patrón de Recordset de solo lectura.
- **No muestra** las líneas que no pertenecen a ningún grupo (fecha, local o terminal ilegibles, o número de campos distinto de 56), porque no tienen fila en la grilla de Form174. Se ven en `VTA_FACOCARGA_YZ_LOG` (consulta 3 de `docs/sql/FCDVT-14/06_pruebas.sql`).
- **Qué probar:** Buscar con `docs/sql/FCDVT-14/pruebas/p01_campos_malos.csv`, clic en 02-10 T2: línea 6, LECTURA, HORA, `25:00`, "Hora fuera de rango". En 09-10 T2: la línea del TIPO vacío y la fila RESUMEN. En 01-10 T1 (CARGADO): "Sin errores registrados para este grupo".

### 2.7 `Form176.frm` + `Form176.frx`: Exportar Cierres Y y Z (plantilla de carga) (FCDVT-259), nuevo

Se abre desde el botón Y ▸ "Exportar Cierres Y y Z" (`EXPYZ`, permiso 461, §2.3). Solo FACO: en otro país avisa y deja Exportar deshabilitado. Mismo aspecto que Form174: el `.frx` es una copia binaria de `Form174.frx` (mismas imágenes y offsets). Tiene `Option Explicit`.

| Control o rutina | Qué hace |
|---|---|
| `Frame1` "Criterio" | `Combo1` Local (llenado con `ProLeeLocales` según el perfil; si ve más de un local, "0-TODOS LOS LOCALES" al comienzo, como Form43), `Combo3` Terminal (`LeeTerminales`: 0 + los vigentes del local a la Fecha Inicio; con local 0 solo 0), `DTPicker1` Fecha Inicio y `DTPicker2` Fecha Fin, y la ayuda "Local 0 = todos… · Terminal 0 = todos…" |
| Fechas | Hoy = fecha del servidor (`LeeFechaServidor`; si falla, la del equipo). Por defecto **ayer** en las dos. Los calendarios no dejan elegir después de ayer (`MaxDate`); **sin límite hacia atrás** (17-11-2026: se quitó el `MinDate = hoy − 2` anterior) |
| Exportar (`Command1`) | Valida: local elegido; Fecha Fin ≥ Fecha Inicio ("La Fecha Fin no puede ser anterior a la Fecha Inicio"); Fecha Fin ≤ ayer ("La Fecha Fin debe ser anterior a hoy": Buscar no acepta cierres del día); **rango Fecha Fin − Fecha Inicio ≤ 2 días, es decir hasta 3 días incluidos** ("El rango entre Fecha Inicio y Fecha Fin no puede superar 3 dias (dias incluidos)"; 17-11-2026: reemplaza el "Fecha Inicio ≥ hoy − 2" anterior y **no hay límite hacia atrás**). Lee `PKG_F8_EXPORTA_MASIVA_YZ.fn_encabezado` y `fn_lineas(local, terminal, inicio, fin, grupo)` (`grupo` = `LOCALUSER` solo si el local es 0 y el perfil es de grupo, 1 o 5). Sin líneas: «No existen cierres Y/Z para los filtros seleccionados» y no pide ruta. Con líneas: "Guardar como" con `carga_Y_compensa_<ddmmyyyy>_<ddmmyyyy>.csv`, escribe el encabezado y una línea por cierre (`;`, CRLF) y muestra en `Frame2` el archivo y "N filas (T terminales · Y Y y Z Z)" |
| Salir (`Command3`) | `Unload Me` |

- **OCX:** `mscomct2.ocx` (DTPicker) y `COMDLG32.OCX`, que ya están en el `.vbp`. No usa Excel.
- **Prerrequisitos en la base:** `docs/sql/FCDVT-259/INSTALAR.sql` (02/03 `PKG_F8_EXPORTA_MASIVA_YZ` solo FACO), `04` si el exe usa otro usuario y `01` (menú 461) junto con el exe. El package usa `PKG_F8_CARGA_MASIVA_YZ.c_encabezado` (FCDVT-14). Sin el package, Exportar muestra el error de Oracle.
- **Qué probar:** `docs/sql/FCDVT-259/pruebas/README.md` (graba un día con Form174, exporta, Z armada, filtros sin cierres, validaciones de fechas y recarga del CSV en Form174 ▸ Buscar sin cambios: grupos CARGADO).
- **Límites:** un terminal-día FACO con Y y sin Z en libvta sale con una **Z armada** con la suma de sus Y (identificación de la última Y), para que el CSV se pueda volver a cargar. Montos con decimales o identificación nula en libvta salen tal cual y Buscar los rechaza. Form176 no exporta cierres de hoy (Fecha Fin hasta ayer), porque Buscar rechaza las fechas de hoy. Desde el 17-11-2026 el rango exportable es de hasta **3 días incluidos** terminando ayer.
- **17-11-2026 (regla de fechas):** los calendarios quedan con **ayer por defecto** y tope ayer, **sin `MinDate`** (se eliminó el límite "hoy − 2"), y Exportar valida un **rango máximo de 3 días incluidos** entre Fecha Inicio y Fecha Fin (`DateDiff("d", vIni, vFin) > 2`). El mismo día se detectó que la copia de `FTEPROD/Form176.frm` en disco tenía **todo el bloque de fechas comentado** (prueba local: sin `mHoy`, el aviso de Exportar mostraba "hoy (30-12-1899)" y no dejaba exportar nada); el cambio lo restaura junto con la regla nueva. Estado previo: `FTEPROD/Form176.frm.bak_FCDVT-259_fechas` (md5 `822c2761…`). Nota: la copia congelada del 16-11 (`6d52d22b…`) tenía el bloque activo, así que ese comentado era un desvío posterior del disco.
- **18-11-2026 (bloque "Resultado de la exportación"):** `Frame2` pasa de 1815 a 2490 twips y el form de 5520 a 6180; `lblArchivo` (615 de alto) queda solo con la ruta, la frase de formato se separó en `lblFormato` (nuevo, gris, TabIndex 19), `lblCierres` bajó a 1530, `lblNota` a 1950 y los botones a 5460. Antes la ruta con el texto de formato se partía en 3 líneas y la tercera quedaba tapada por "Cierres exportados" (`lblArchivo` terminaba en 1095 y `lblCierres` empezaba en 1080). La ruta completa queda además en el `ToolTipText` de `lblArchivo`. Sin cambios en `.frx`.

## 3. Pasos sugeridos para el paso a producción

1. **Base de producción, antes del exe:**
   - FSCC-12901: `docs/sql/FSCC-12901_COMPENSA_DI/` (02 a 06). Lo requiere `Form133`.
   - FCDVT-14: `docs/sql/FCDVT-14/01_menu_ingreso_masivo_y.sql`. Va **junto con** el exe nuevo; o se posterga, ver §2.4. Además 02, 03, 04, 04b, 04c y 05 (carga Y/Z, versión del 04-11: `PKG_F8_CARGA_MASIVA_YZ` y `PKG_F8_GRABA_MASIVA_YZ`), que los usan Buscar y Cargar de `Form174`. Para FACO, `02` no crea nada si las tablas ya existen.
   - FCDVT-259 (FACO): `docs/sql/FCDVT-259/INSTALAR.sql` (02 y 03, `PKG_F8_EXPORTA_MASIVA_YZ`), después de FCDVT-14, y `04` si el exe usa otro usuario. Lo usa `Form176`. Aparte, **junto con** el exe nuevo, `01_menu_exporta_yz.sql` (permiso 461).
   - FCDVT-10 (Tottus Chile, base de SFCL): `docs/sql/FCDVT-10/INSTALAR.sql` (02, 03, 04, 04b y 04c, versión del 19-11-2026 con las reglas de Colombia), `05` si el exe usa otro usuario y `01_menu_ingreso_masivo_y_sfcl.sql` **junto con** el exe nuevo.
   - El cron de cierre diario (`docs/sql/FSCC-12901_CIERRE_DIARIO/`, que con FCDVT-56 incluye la etapa sin venta). Desde el 18-11 `Form174` ya no lo llama desde Salir (§2.4), así que el exe **no** depende de él; el cron se programa aparte (nhal1).
2. **Fuentes:** copiar desde `archivos/` a la carpeta del proyecto de producción `Form133.frm`, `Form43.frm`, `MDIForm1.frm`, `Form174.frm`, `Form174.frx`, `Form175.frm`, `Form175.frx`, `Form176.frm` y `Form176.frx`, y agregar `Form=Form174.frm`, `Form=Form175.frm` y `Form=Form176.frm` al `.vbp`. No convertir la codificación: los archivos van en Windows-1252 con CRLF.
3. **Versión:** subir `Global Const Gversion` en `Módulo1.bas` (hoy `"3.4.9"`) y `vta_parametros.vta_ultversion` de cada país (CLAUDE.md §2). Si no se hace, el exe no arranca o se autoactualiza a otra versión.
4. **Compilar** `f8a.exe`. El IDE no debe generar ningún `Form*.log`.
5. **Probar en producción:** los puntos "Qué probar" de §2.1 a §2.4 y §2.7.
6. **Rollback:**
   - volver a copiar los archivos de `PROD/`;
   - quitar `Form174`, `Form175` y `Form176` del `.vbp`;
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
