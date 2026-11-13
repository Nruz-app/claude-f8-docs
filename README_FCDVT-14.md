# FCDVT-14: carga masiva de cierres F8 (Z / Y) desde Excel

Índice del requerimiento. Para retomar, empezar por aquí.

## 1. Requerimiento

- **Fuente**: [`Requerimiento-FCDVT-14/DF-SCC-vf_24.03.2025 Ingreso Cierre de caja F8.xlsx`](Requerimiento-FCDVT-14/) (DF-SCC del 24-03-2025).
- **Iniciativa**: "CARGA MASIVA CIERRES F8". Tipo Nuevo. Negocio Falabella Retail y Tottus. Países Chile y Colombia.
- **Personas**: solicitante Paulo Arrieta; gerente de área Cristian Zúñiga; gerencia Pablo Aguirre Rigo-Righi.
- **Sistemas impactados**: F8, LV y Tesorería = sí; CMP y SCC = no.
  - Las hojas SCC, Estructura venta/liquid, Archivo de salida, Backbone y Enriquecimiento son la plantilla genérica de conciliación y no aplican.
  - Única nota a respetar (comentario de J. Carrillo): **no se debe modificar la llave de pareo de conciliación**.
- **Qué se pide**: una pantalla en F8 que cargue cierres de caja desde un Excel, con totales por tipo de documento y por medio de pago. Reemplaza la digitación manual de la Z (`Form19`) y de la Y (`Form19Y`).
- **Criterios de aceptación**:
  1. Template Excel con la venta y las formas de pago → **INSERT** del cierre.
  2. Opción de **UPDATE** de montos de un cierre existente, sin cargarlo de cero.
  3. Validación igual que en F8: alerta de descuadratura (documentos ≠ medios de pago) y **no graba** lo descuadrado.
  4. Switch para cargar solo la Z o también la Y, según negocio y país.
  5. **Log de auditoría** al final de cada carga. Extra posible: un reporte de auditoría.
  6. Los cierres cargados deben comportarse igual que los que vienen de la caja y reflejarse en el **LVTA**.
- **Alcance por empresa**:

  | Empresa | `Flg_Pais$` | Z | Y | Columnas de concepto en el template |
  |---|---|---|---|---|
  | Falabella Chile | `""` / `CHI` | Sí | No | ~110 |
  | Tottus Chile | `SFCL` | Sí | Sí | ~80 |
  | Falabella Colombia | `FACO` | Sí | Sí | ~50 |

- **Template** (hoja F8-LV-CMP-TES, filas 30-60). Tiene un bloque de "ingreso" y otro de "update" por empresa.
  - Columnas fijas: Fecha (serial Excel; 46294 = 30-09-2026), Local, Terminal, N° de cierre de Y, Hora, Secuencia, N° Boleta, Vendedor, Cont. Reposición, Tipo (`Z`/`Y`) y Tipo_carga (`INGRESAR`/`Modificar`).
  - El resto de las columnas son los conceptos de la Z, con las glosas de `vta_paint_z.vtaglosa_z` del país.
  - El bloque update trae solo Fecha, Local, Terminal, Tipo, Tipo_carga y los montos.
  - **Inconsistencias del template** (confirmar con negocio):
    - En FACO, el bloque de ingreso no tiene la columna `Tipo_carga`.
    - En el update de FACO, las filas Y no traen fecha, local ni terminal.
    - En FACO, el N° de Y viene vacío aunque haya dos filas Y.
    - Hay glosas repetidas en distintas secciones (EFECTIVO, CMR, TRANSBANK, REC TELEF, ENTRADAS…), así que mapear por glosa es ambiguo.
    - Algunas celdas traen `-` en vez de 0.

## 2. Estado

**Análisis** (16-10-2026). Faltan las respuestas de negocio (§7) y correr los prechecks en test.

**Al 03-11-2026 (congelado, manifiesto y ZIP en §9):** primera subtarea, **carga masiva de Y y Z para FACO**, etapa Buscar terminada. El usuario la probó en test con la versión del 30-10 y "funciona bien". Lo que se hizo después del 30-10 está **sin compilar ni ejecutar**.

**04-11-2026:** el botón **Cargar** está programado (§5.9): `Command4_Click` en Form174 llama a `PKG_F8_GRABA_MASIVA_YZ.prc_graba`, un package propio separado del de Buscar. Hay pruebas en `docs/sql/FCDVT-14/pruebas_cargar/`. Está sin compilar ni ejecutar.

| Pieza | Estado |
|---|---|
| Submenú del botón Y (`MDIForm1.frm`, §5.2) | Implementado. Solo FACO: `INGY` → Form19Y con el permiso 15; `INGYMA` → Form174 con el permiso 460. El usuario lo compiló y lo vio funcionar en test |
| Permiso 460 (`docs/sql/FCDVT-14/01_menu_ingreso_masivo_y.sql`) | **Ejecutado en test** por el usuario con los perfiles 10 y 11. Falta llevarlo a producción con los mismos 3 INSERT |
| `Form174` Buscar (§5.5, §5.8) | Valida el CSV con `PKG_F8_CARGA_MASIVA_YZ` y muestra el resumen por terminal-día. Estados **PENDIENTE / ERROR / CARGADO** (CARGADO antes se llamaba PROCESADO). Pasa `Flg_Pais$` al package. La versión del 30-10 está probada en test; la del 03-11, sin compilar |
| `Form174` clic en la grilla (§5.6) | Un **solo clic** en una fila abre `Form175` con el log del grupo |
| `Form175` (nuevo, §5.6) | Detalle del log de un grupo. Está en el `.vbp`. Sin compilar |
| `Form174` Exportar Excel (§5.7) | Genera una plantilla `.xlsx` con formato: hojas Carga, Instrucciones y Listas (oculta). El usuario la completa y la **guarda como CSV**; Buscar solo lee CSV, por decisión del usuario. Sin compilar |
| `Form174` Cargar (`Command4`) | **Programado el 04-11** (§5.9), sin compilar. Llama a `PKG_F8_GRABA_MASIVA_YZ.prc_graba` (package propio, `04b`/`04c`), que graba cada grupo CARGADO (Z como Form19, Y como Form19Y), **reemplaza** lo que el terminal-día ya tenga, hace commit por grupo y lo deja en **GRABADO** (o ERROR con el motivo) |
| `Form174` Salir | Ejecuta la **prueba temporal** del cierre diario (`EjecutaCierreDiario`, FSCC-12901, fecha fija `vFechaPrueba`). La copia de producción (`docs/Cambios/`) es idéntica, por decisión del usuario; está marcada como riesgo |
| Packages y tablas (`docs/sql/FCDVT-14/02`-`06`, §5.8, §5.9) | **Multipaís** con tablas por prefijo `VTA_<pfx>CARGA_YZ_*`, solo FACO habilitado. Son dos packages: `PKG_F8_CARGA_MASIVA_YZ` (Buscar, `03`/`04`) y, desde el 04-11, `PKG_F8_GRABA_MASIVA_YZ` (Cargar, `04b`/`04c`). En test está instalada la **versión del 30-10** (solo FACO, respaldada en `anterior_2026-11-03/`). La multipaís sin `prc_graba` está respaldada en `anterior_2026-11-04/`. Falta ejecutar `INSTALAR.sql`, porque el exe nuevo lo necesita |
| Archivos de prueba (`docs/sql/FCDVT-14/pruebas/`) | 8 CSV (`p01`-`p08`) con el resultado esperado en su `README.md` |
| Sesiones de prueba Y + DI (`docs/sql/FCDVT-14/prueba_carga_y_compensa_di_s1`..`s8`) | Carga masiva (Form174) + DI automática al cargar sobres (Form133, FSCC-12901), local 5. **Sesión 7** (11-11-2026, armada el 12-11) suma la **recarga v1/v2** del mismo terminal-día (T5 y T6): queda el monto del último archivo; si la recarga va después de los sobres, la DI de v1 no se recalcula. **Sesión 8** (12-11-2026, armada el 13-11) es la 7 repetida tal cual con otra fecha y sobres `5TT1211nn`. Sin ejecutar |
| Cuadratura | Total Z = suma de los totales de las Y (§5.5). "Documentos = formas de pago" por Y, pendiente de negocio |
| Update (`MODIFICAR`), SFCL y Chile | Pendientes (§7). Cargar ya reemplaza los cierres existentes. Para otro país, ver "Multipaís" en `docs/sql/FCDVT-14/00_LEEME.md` |
| Paso a producción | `docs/Cambios/` está sincronizado con `FTEPROD` (regla permanente de CLAUDE.md §9). Falta subir `Gversion` |

## 3. Artefactos

| Archivo | Qué es |
|---|---|
| `docs/Requerimiento-FCDVT-14/DF-SCC-vf_24.03.2025 Ingreso Cierre de caja F8.xlsx` | Especificación funcional (fuente) |
| `docs/README_FCDVT-14.md` | Este índice |
| `docs/FCDVT-14/plantilla_carga_Y_FACO.csv` | Plantilla CSV (`;`, 54 columnas, una fila por Y) para la carga masiva de **inserción** de Y de FACO, con 3 filas ilustrativas |
| `docs/FCDVT-14/FORMATO_CARGA_Y_FACO.md` | Especificación del CSV: reglas, columna por columna con su `vta_cmp_asoc` y tabla destino, validaciones, qué inserta y pendientes |
| `docs/sql/FCDVT-14/00_prechecks.sql` | Consultas de solo lectura: `vta_paint_z` por empresa, glosas duplicadas, columnas de libvta/zzz/termstat(y), secuencias, tablas de log, menú, volumen; §11-12: código 460 libre y perfiles con permiso 15 |
| `docs/sql/FCDVT-14/00_LEEME.md` | Índice y orden de ejecución de los scripts |
| `docs/sql/FCDVT-14/01_menu_ingreso_masivo_y.sql` | Inserta el permiso 460 "Ingreso de cierre de terminal Y masivo" en `VTA_FACOMENU` (`MenuPrincipal`) y `VTA_FACORELPERMEN` (perfiles 10 y 11) con INSERT explícitos, los mismos para test y producción |
| `docs/sql/FCDVT-14/99_rollback.sql` | Por partes: A borra el permiso 460; B desinstala la carga Y/Z |
| `docs/sql/FCDVT-14/02` a `06`, `INSTALAR.sql` | Carga Y/Z, etapa Buscar (§5.5): tablas, `PKG_F8_CARGA_MASIVA_YZ`, grants y consultas de prueba |
| `docs/sql/FCDVT-14/ejemplo_carga_Y_FACO_20.csv` | 23 filas (3 Z + 20 Y) del 16-10-2026, local 5; todo cuadra. Versión del 22-10 sin Z en `.bak_FCDVT-14_Z` |
| `docs/sql/FCDVT-14/ejemplo_carga_YZ_FACO_errores.csv` | Un caso por resultado de Buscar (1 PROCESADO, 4 ERROR, 1 línea sin grupo) |
| `FTEPROD/Form175.frm` (+ `.frx`) | Detalle del log de un grupo de la carga masiva; se abre con un clic en la grilla de Form174 (§5.6) |
| `FTEPROD/Form174.frm.bak_FCDVT-14_Log`, `recaudacion.vbp.bak_FCDVT-14_Form175` | Respaldos antes de Form175 (03-11) |
| `FTEPROD/Form174.frm.bak_FCDVT-14_Clic`, `Form174.frm.bak_FCDVT-14_Plantilla` | Respaldos antes del clic simple y antes de la plantilla .xlsx de Exportar Excel (03-11) |
| `docs/sql/FCDVT-14/anterior_2026-11-03/`, `FTEPROD/Form174.frm.bak_FCDVT-14_Multipais`, `Form175.frm.bak_FCDVT-14_Multipais` | Respaldo de la versión solo FACO (scripts y exe) antes del package multipaís (§5.8) |
| `docs/sql/FCDVT-14/pruebas/` | 8 CSV de prueba de Buscar, uno por tipo de caso (campos malos, falta de Z, cuadratura, `NRO_Y`, estructura de la línea, encabezado, volumen), con el resultado esperado en su `README.md` (03-11) |
| `docs/sql/FCDVT-14/prueba_carga_y_compensa_di_s7/` | Sesión 7 (12-11): las 4 pruebas de DI de la sesión 6 con fecha 11-11-2026 más la recarga v1/v2 (`carga_Y_compensa_v1.csv` y `_v2.csv`, T5 y T6), `py0`/`py2` (parte C: monto final)/`py9`, Excel de sobres y `Prueba-Y-DI_Resumen.xlsx` con la hoja "Recarga v1-v2" |
| `docs/sql/FCDVT-14/prueba_carga_y_compensa_di_s8/` | Sesión 8 (13-11): réplica exacta de la sesión 7 con fecha de venta 12-11-2026 y sobres `5TT1211nn` (mismas 6 pruebas, montos, recarga v1/v2 en T5/T6 y resultados esperados), con sus `py0`/`py2`/`py9`, CSV v1/v2 y Excel |
| `FTEPROD/Form174.frm.bak_FCDVT-14_Resumen` | Respaldo de Form174 antes del Buscar con el package (30-10) |
| `FTEPROD/MDIForm1.frm` | Submenú del botón Y solo en FACO (marcas `xintec-nruz 20-10-2026 FCDVT-14`), sin compilar |
| `FTEPROD/Form174.frm` (+ `.frx`) | Pantalla "Ingreso de Cierres de Terminal Y Masivo" (la creó el usuario, en el `.vbp`). Programado: botón Buscar (§5.3) |
| `FTEPROD/Form174.frm.bak_FCDVT-14` | Respaldo de Form174 antes de programar Buscar (solo el diseño) |
| `FTEPROD/Form174.frm.bak_FCDVT-14_Exportar` | Respaldo de Form174 antes de programar Exportar Excel (ya con el botón Cargar del usuario) |
| `docs/sql/FCDVT-14/plantilla_carga_Y_FACO.csv`, `FORMATO_CARGA_Y_FACO.md` | Copias idénticas de las de `docs/FCDVT-14/`, que el usuario dejó junto a los scripts |
| `FTEPROD/MDIForm1.frm.bak_FCDVT-14_Form174` | Respaldo antes de conectar `INGYMA` a `Form174` |
| `FTEPROD/MDIForm1.frm.bak_FCDVT-14` | Respaldo antes del cambio (incluye los dos ButtonMenus que el usuario agregó y guardó desde el IDE) |

## 4. Cómo funciona hoy (verificado en el código)

### 4.1 Pantallas y menú

- **Z**: `Form19.frm`. Se abre con el botón `zz` (Button16) en `MDIForm1.frm:1640`. Perú usa `Form19_2` y Argentina `Form19_3`.
- **Y**: `Form19Y.frm`. Se abre con el botón `YYYY` (Button15) en `MDIForm1.frm:1633`. Solo existe para ARG, SFCL, FACO y HTPE.
- **Contexto**: local y terminal se toman de `FormVariable.Combo2/Combo3`; la fecha, de `FormVariable.DTPicker1`. No usan `Gfecha`/`Glocal`.
- **Menú propuesto**: un `ButtonMenu2` en Button16, al final de la colección, para no mover `ZLV`.
  - Necesita un `Case` en `Toolbar1_ButtonMenuClick` y una rama `ElseIf numero = <código>` en `SubBuscarOpcionMenu` **antes** del `Else` de `MDIForm1.frm:1459`.
  - Si el código cae en el `Else` genérico con `numero > 42`, se dispara un error que corta el bucle de permisos.
  - Hoy el dropdown de Button16 solo se activa en MAPE/MPAM/SPOR, así que hay que habilitarlo también en CHI, SFCL y FACO.

### 4.2 Conceptos de la Z / Y

```sql
select z.vtaglosa_z, z.vta_cmp_asoc, decode(z.vta_pop_up,null,0,z.vta_pop_up) pop_up
  from vta_paint_z z where z.vta_localiz = '<Flg_Pais$ | CHI>' order by z.vta_order_z
```

- `vta_cmp_asoc` es la columna destino. Si contiene `VTA_`, va a `vta_<pfx>libvta`; si no, va a `vta_<pfx>zzz`.
- `pop_up`: 0 = editable; 1 = título; 2 = separador; 3 = total calculado (se graba).
- **Los documentos de libvta se toman por posición fija de fila, y esa posición varía por país.**
  - Chile (Form19): fila 2 = boletas, 3 = NC, 4 = factura, 5 = ND, 6 = guías, 7 = total.
  - FACO: total en la fila 5.
  - SFCL (Form19Y): total en la fila 7.
  - Recaudación Chile: filas 58+96 y 59+97. Hay una inconsistencia con `KeyPress`, que usa las filas 62 y 75.
- Los totales calculados se recalculan en `Grid1_KeyPress` (Form19 :1998-2065; Form19Y :2552-2567).

### 4.3 Qué graba la Z (`Form19.GrabaZZZ`, :371)

No distingue alta de modificación: siempre borra y vuelve a insertar. Todo se confirma solo (no hay `BeginTrans`).

1. `LeeZactual`: conserva `bolinicial`, `nrollo` y `crepo_inicial` de la Z anterior.
2. Techkey: `VTA_TEC_SEC.nextval` en Chile; `SEQ_VTA_<pfx>TEC.nextval` en SFCL y FACO.
3. `delete vta_<pfx>libvta where fecha/local/terminal and vta_tiporeg in ('F8'[, 'Y' fuera de Chile])`. **En SFCL y FACO esto borra todas las Y del terminal-día.**
4. `insert vta_<pfx>libvta` con `tiporeg='F8'`, `vta_secuencia=99`, `estado='A'`, `tipof8='N'`, documentos, hora, secuencia SRX, boleta final, vendedor, contador de reposición y techkey. No graba el usuario.
5. `insert vta_<pfx>zzz (rec_techkey, rec_fechaproceso, <cmp_asoc pop_up 0/3 sin VTA_>)`. La zzz anterior queda huérfana.
6. Si no existe `termstat`: `insert ... ter_estado=-1, 'INGRESO MANUAL DE CIERRE', LOGINUSER`. En SFCL, FACO y HTPE además se borran todas las `termstaty` del terminal-día.
7. Validador ZZZ (`FuncMontoValidaZZZ`, `Módulo1.bas:4105`):
   - Chile: `update zzz set rec_mdiferenciaz=<dif>`.
   - SFCL: muestra "Z descuadrada" **después** de grabar.
8. Solo SFCL: `GrabaYprima` crea automáticamente la Y1 (libvta 'Y'/1 y termstaty).

### 4.4 Ingreso de Y: `Form19Y.frm` en detalle

Archivo real `FTEPROD/Form19Y.frm` (2.646 líneas, `VB_Name` Form19Y). Análisis del 16-10-2026, sin cambios.

**Apertura.** Botón `YYYY` (`MDIForm1.frm:1633`), solo en ARG, SFCL, FACO y HTPE; se abre modal. Al cerrar, si el terminal no está cerrado (`lblEstado.Tag <> 1`) y la ventana activa es Form3/Form3Y, ejecuta `FormVariable.ProcesoConsulta`. La única variable del módulo es `VF_ExisteTerminaY` (True = modificar una Y existente).

**Grid0, IDENTIFICACION** (`definegrid`, :291):

| Fila | Concepto | Valor inicial |
|---|---|---|
| 1 | FECHA | `DTPicker1` = `FormVariable.DTPicker1` |
| 2 | LOCAL | `FormVariable.Combo2` |
| 3 | TERMINAL | `FormVariable.Combo3` |
| 4 | N° DE CIERRE DE Y | 0 |
| 5 | HORA | Hora actual `hh:mm` (no editable) |
| 6-9 | SECUENCIA, N° BOLETA, VENDEDOR, CONT. REPOSICION | Vacíos |

- `Grid0_KeyPress` (:1897) acepta solo dígitos, `:` y retroceso. LOCAL y TERMINAL se pueden editar. Cualquier tecla limpia Grid1 y vuelve a habilitar "Validar Identificación".
- Defecto visual: `DTPicker1` tiene posición fija y, como `definegrid1` pone `Grid0.row = 2`, la grilla se desplaza una fila. El picker queda **tapando la fila LOCAL** y la fila FECHA queda oculta.

**Grid1, DETALLE DE MONTOS** (`definegrid1`, :335). Columnas: 0 Concepto, 1 Monto, 2 pop_up (oculta), 3 `vta_cmp_asoc` (oculta), 4 Valor Z, 5 Sumatoria S(Y), 6 Diferencia (Z − S(Y)).

**"Validar Identificación"** (`Command3_Click`, :1595):
1. La fecha debe ser menor que `LeeFechaServidor` ("no se puede generar un Z"). También se valida en `DTPicker1_LostFocus`.
2. `Oklt` (:370): terminal vigente en `vta_<pfx>terminales`. Usa `FormVariable.DTPicker1`, no el picker propio. MAPE/MPAM/SPOR usan `LeeVendedor`.
3. `Est_TermStat(…, "")`: la **Z** (`termstat`) no debe estar en estado 1/2.
4. Obligatorios: N° Y, Hora, Secuencia, Boleta, Vendedor, Cont. Reposición.
5. `FuncValidNumY` (:1691) cuenta `libvta 'Y'` (estado 'A') unida a `zzz` y `termstaty` (`ter_cierrey = vta_secuencia`) para el N° Y.
   - Si existe → **modificación**, se mantiene el número.
   - Si no → **alta**, y el número se **reemplaza** por `FuncBuscaNumSecY` (:1743) = `max(vta_secuencia)+1`. El usuario no puede elegir el número de una Y nueva. Si la consulta falla, devuelve **−1** y se grabaría así.
   - Una Y en `libvta` sin `zzz` o sin `termstaty` no cuenta como existente.
6. Llena Grid1 (`SubDefineDetalleMonto`), habilita Aceptar y deshabilita Validar.

**Origen de los valores** (`SubDefineDetalleMonto`, :969). Una fila de Grid1 por fila de `vta_paint_z` del país, en orden `vta_order_z`:
- pop_up 1/2 (título/separador): Monto en blanco.
- pop_up 0/3:
  - **Monto:** si se modifica, `FuncValorDelCampo(campo,'Y',n)` (:1843) = `sum(campo)` de `libvta 'Y'` + `zzz` + `termstaty` con secuencia n. Si es alta, 0.
  - **Valor Z:** `FuncBuscaValorCampo(campo,'F8')` (:1789) = `sum(campo)` de `libvta 'F8'` + `zzz` + `termstat`. Da 0 si la Z no está cargada.
  - **Σ Y:** en modificación, las otras Y (`termstaty`, secuencia ≠ n). En alta, todas las Y del día unidas a `termstat` de la Z, que debe existir.
  - **Diferencia** = Z − (ΣY + Monto). Solo informativa.
- Colores: pop_up 1 beige (`&HD0EDFB`), pop_up 3 verde (`&HA4E8CB`).

**Edición** (`Grid1_KeyPress`, :1928). Solo la columna 1 de filas con pop_up 0. Acepta dígitos, una coma decimal, retroceso y `-` (cambia el signo). Recalcula la diferencia de la fila editada. Totales por posición fija:
- FACO: fila 5 (TOTALES) = 2+3+4; fila 29 = 30..34.
- SFCL: fila 7 = 2..6.
- La diferencia de una fila total no se recalcula cuando el total cambia.

**Aceptar** (`Command1_Click`, :1430):
1. `revisa_grid`: los vacíos pasan a 0.
2. Repite `Oklt`, `Est_TermStat` de la Z y los obligatorios.
3. `Est_TermStat(…, N°Y)`: la **Y** (`termstaty` + `ter_cierrey`) no debe estar cerrada.
4. **Solo ARG valida cuadratura** (venta contra formas de pago, y tarjeta contra administradoras). **En FACO y SFCL no hay ninguna validación de cuadratura**, ni documentos contra formas de pago ni Z = ΣY.
5. Confirmación "¿Esta seguro de Incorporar el Nuevo cierre de y para este Terminal?" → `GrabaZZZ`.

**Grabado** (`GrabaZZZ`, :452). Sin transacción y sin mensaje de éxito; al terminar se cierra el formulario.
1. `LeeZactual` (:419): `bolinicial`, `nrollo` y `crepo_inicial` de la Y n (0 si es nueva). `qbol = N°Boleta − boli + 1`.
2. Techkey `SEQ_VTA_<pfx>TEC.nextval` (:540).
3. `delete vta_<pfx>libvta where … tiporeg='Y' and secuencia=n` (:568). **No borra la `zzz` vieja** (queda huérfana) y no toca `termstaty`.
4. `insert vta_<pfx>libvta` (:628), una rama por país:
   - **FACO** (`Else`, :910): `montobol` = fila 2, `montofac` = 4, `montoncr` = 3, `totalvta` = 5; `estado 'A'`, `tipof8 'N'`, `hora` = HHMM.
   - **SFCL** (:865): igual, más `totalvta` = 7, `mmontondb` = 5, `montoguia` = 6.
   - **Columnas corridas en ambas ramas:**

     | Columna de `libvta` | Recibe |
     |---|---|
     | `bolfinal` | SECUENCIA |
     | `crepo_inicial` / `crepo_final` | VENDEDOR |
     | `secuencia_srx` | SECUENCIA (en SFCL, la HORA) |
     | `vendedor` | N° BOLETA |

     **CONT. REPOSICION no se graba nunca.**
5. `insert vta_<pfx>zzz` con `arma_query_rec` (:229): `rec_techkey`, `rec_fechaproceso` y las columnas `cmp_asoc` de las filas pop_up 0/3 (sin `VTA_`, o con `MVTA_`). En FACO hay antes un `delete zzz` del techkey nuevo, que no tiene efecto.
6. Si `termstaty` no existe (`FuncExisteEst_TermStatY`): `insert termstaty (…, n, -1, 'INGRESO MANUAL POR CIERRE DE Y', LOGINUSER)`.
7. No toca `termstat` (Z), `estatus`, el validador ZZZ ni el cierre automático de FACO.

**Implicancias para la carga masiva:**
- Por cada Y hay que repetir: borrar `libvta` 'Y' n, insertar `libvta`, insertar `zzz` e insertar `termstaty` con −1 si falta. Conviene además borrar la `zzz` vieja y no copiar el corrimiento de columnas.
- Si el Excel no trae el N° de Y (template FACO), se asigna max+1 como hace el formulario.
- La cuadratura que pide el requerimiento no existe hoy para FACO ni SFCL: hay que construirla.
- Para que la Y se vea en la F8 debe quedar unida a `zzz` y `termstaty`, y la Z debe tener `termstat`.

### 4.5 Validaciones actuales

- La fecha debe ser menor que la del servidor (`LeeFechaServidor`).
- El local y el terminal deben existir y estar vigentes en `vta_<pfx>terminales` (`Oklt`).
- El terminal no debe estar cerrado: `Est_TermStat` (`Modulo2.bas:1347`) bloquea los estados 1 y 2 y muestra un MsgBox. Para una carga masiva conviene una variante sin MsgBox.
- Son obligatorios Hora, Secuencia, N° Boleta, Vendedor y Cont. Reposición.
- **Cuadratura**: la calcula `FuncMontoValidaZZZ` con los grupos `vta_paint_z.vta_validadorzzz` 1..7 y su signo (1 venta, 2 recaudación, 3 recaudación 3, 4 otras operaciones, 5 envío de dineros, 6 activación gift card, 7 formas de pago).
  - Se bloquea al **cerrar** el terminal (Form3 :3647, opción de perfil 103).
  - Solo Argentina bloquea antes de grabar.
- No existe validación de período cerrado.

### 4.6 LVTA

La Z es la fila `vta_<pfx>libvta` con `tiporeg='F8'` y `vta_secuencia=99`, en la misma tabla que las filas `LV` del libro. `Form33.DetalleBoletas` compara ambas. Si se graba libvta y zzz igual que Form19/Form19Y, se cumple el criterio "reflejarse en el LVTA".

### 4.7 Patrones reutilizables para la carga Excel

| Patrón | Formulario |
|---|---|
| `Workbooks.Open`, última fila con `End(xlUp)`, mapeo por columna, borrar e insertar | `Form171` (carga masiva de compensaciones) |
| Preview en grilla, filas inválidas en rojo, botón Grabar deshabilitado | `Form133` |
| Validar todo antes de grabar; compensación manual si falla | `Form81` |
| Nombre de archivo y usuario en cada registro | `Form155` |

### 4.8 Log de auditoría

- `InsertaLogSistema` (`LogSistemaF8.bas`) **no se llama en ningún lado**. El próximo ID de módulo libre es el 71.
- No existe log de cargas masivas.
- Modelos para el log nuevo:
  - `VTA_LOG_ING_ZLV` (`Form19_2` :628): usuario, sysdate, acción y documento.
  - `VTA_FACOLOG_CIERRE_AUTO` (`docs/sql/FSCC-12958/02_log.sql`): una ejecución, N filas y un resultado por fila.

## 5. Decisiones de diseño (propuestas, sin confirmar)

- Formulario nuevo (por ejemplo `Form174`), agregado a `recaudacion.vbp`, con el flujo: elegir archivo → preview → validar todo → grabar las filas válidas → log.
- Mapear las columnas del Excel contra `vta_paint_z` del país, por posición del encabezado o por `vta_cmp_asoc` y no por glosa, porque hay glosas duplicadas.
- Grabar con la misma secuencia de sentencias que Form19/Form19Y, para que el cierre sea igual al manual. Corregir en la carga los defectos conocidos: zzz huérfanas y columnas corridas.
- Log en una tabla nueva por ejecución y fila (estilo `VTA_FACOLOG_CIERRE_AUTO`), en todos los prefijos en alcance (`""`, SFCL, FACO).

### 5.1 Submenú de Y: "Ingreso" + "Ingreso masivo" (análisis del 19-10-2026, sin cambios)

**Qué pide el usuario.** Que el menú de Y tenga dos opciones: "Ingreso de cierre de terminal Y" (pantalla actual, `Form19Y`) e "Ingreso de cierre de terminal Y masivo" (pantalla nueva que carga el CSV de `docs/FCDVT-14/`).

**Dónde está el menú de Y.**
- El cuadro "Y" de "Cierre de Y" en la F8 (`Form3Y`) **no es un menú**: es el `Combo4` que elige qué N° de Y se consulta.
- El menú es el botón **`Button15`** de la barra de `MDIForm1.frm` (:522-528):
  - Key/Description `YYYY`, tooltip "Ingreso del YYY".
  - `Toolbar1_ButtonClick`, `Case "YYYY"` (:1633), abre `Form19Y.Show 1` solo en ARG, SFCL, FACO y HTPE y, al volver, refresca la F8 con `ProcesoConsulta`.
  - Permiso: `mnu_codigo = 15` ("Ingreso de Y", `MenuPrincipal`). Cae en el `Else` genérico de `SubBuscarOpcionMenu` (:1459): `Buttons(15).Visible = valor`.
  - En desarrollo, FACO lo tiene habilitado para los perfiles 10 y 11.

**¿Lo ven todos los países?** Solo si se programa así.
- Hay un único `MDIForm1.frm` y un único exe para todos los países. Los submenús definidos en el diseñador existen para todos, pero lo que se ve **se decide al iniciar sesión**, por país y perfil.
- **Precedente en el código:** el botón vecino `Button16` (Z) tiene el submenú `ZLV` con `Visible = 0` en el diseñador. `SubBuscarOpcionMenu` (:1462-1472) solo lo activa para MAPE, MPAM y SPOR (`Style = tbrDropdown` y `ButtonMenus(1).Visible = valor`). El resto de los países ve el botón Z normal.

**Recomendación:**

| Quién | Qué ve |
|---|---|
| Todos los países | El botón Y igual que hoy: un clic abre `Form19Y` |
| FACO | El botón Y con flecha (`tbrDropdown`). Un clic en el botón sigue abriendo `Form19Y`; la flecha muestra 1) "Ingreso de cierre de terminal Y" → `Form19Y`, con el permiso 15, y 2) "Ingreso de cierre de terminal Y masivo" → pantalla nueva, con un **permiso propio** (`mnu_codigo` nuevo en `vta_FACOmenu`/`vta_FACOrelpermen`) |

**Cuidados al programarlo:**
- Los submenús se agregan **al final** de la colección del botón (`ButtonMenu1`, `ButtonMenu2`), para no mover índices.
- El código nuevo necesita una rama `ElseIf (Flg_Pais$ = "FACO" And numero = <nuevo>)` **antes** del `Else` de :1459. Si cae en el `Else`, `Buttons(numero)` con un número mayor que 42 da error y el `On Error` corta el resto de los permisos.
- Esa rama debe dejar visible el botón 15 con estilo dropdown, para el caso de un perfil que tenga el masivo pero no el ingreso unitario. Los permisos se recorren ordenados por `mnu_codigo`, así que el 15 se procesa antes.
- El `mnu_codigo` libre se elige en test o producción. En desarrollo `vta_FACOmenu` no tiene códigos de 400 o más, pero en test se usa el 422.

**Archivos a modificar (magnitud):**

| Archivo | Cambio | Magnitud |
|---|---|---|
| `FTEPROD/MDIForm1.frm` | (a) Diseñador: `ButtonMenus` en `Button15` con 2 ítems (por ejemplo `YING` y `YMAS`), `Visible = 0`. (b) `Toolbar1_ButtonMenuClick`: 2 `Case` (`YING` → `Form19Y` con la misma restricción de países y refresco que `YYYY`; `YMAS` → pantalla nueva). (c) `SubBuscarOpcionMenu`: dropdown en FACO para `numero = 15` y rama nueva del permiso masivo | Chico, ~40 líneas. No toca `MDIForm1.frx` |
| `FTEPROD/Form174.frm` (+ `.frx`) | **Nuevo**: pantalla de carga masiva (elegir CSV, validar, preview, grabar, log y resumen). `Form174` está libre en el `.vbp` | **Lo grueso**, ~800-1.200 líneas |
| `FTEPROD/recaudacion.vbp` | `Form=Form174.frm` | 1 línea |
| `FTEPROD/Módulo1.bas` | Subir `Gversion` (obligatorio para publicar); opcionalmente una constante | 1-3 líneas |
| `FTEPROD/Modulo2.bas` (opcional) | Variante de `Est_TermStat` sin MsgBox, para validar en lote. También puede quedar privada en `Form174` | 0-40 líneas |
| `docs/sql/FCDVT-14/` | Menú y permiso del masivo, parámetro de máximo de filas en `vta_FACOparam`, tabla y secuencia de log, `vta_parametros.vta_ultversion`, `99_rollback.sql` | Chico |

**No se tocan:** `Form19Y.frm`, `Form3Y.frm`, `Form3.frm`, `Form19.frm` ni otros países.

Antes de editar: respaldar `MDIForm1.frm` como `MDIForm1.frm.bak_FCDVT-14` y editarlo en binario (Windows-1252 + CRLF).

### 5.2 Submenú de Y: implementación (20-10-2026, sin compilar)

El usuario agregó desde el IDE, en `Button15`, dos ButtonMenus (`INGY` "Ingreso del  YYY" e `INGYMA` "Ingreso del  YYY Masivo") con `Style = 5`, y guardó el formulario. Sobre esa versión (respaldada en `MDIForm1.frm.bak_FCDVT-14`) se hicieron estos cambios, editando en binario (CP1252 + CRLF):

| Dónde (`MDIForm1.frm`) | Cambio | Por qué |
|---|---|---|
| Diseñador, `Button15` (:522) | Se quita `Style = 5` y los dos ButtonMenus quedan con `Object.Visible = 0` | El `.frm` es único para todos los países. Con dropdown desde el diseño, ARG, SFCL y HTPE verían la flecha con una lista vacía. El estilo y los ítems se activan por código solo en FACO, como `ZLV` |
| `SubBuscarOpcionMenu`, rama nueva antes del `Else` (:1466) | `ElseIf (Flg_Pais$ = "FACO" And numero = 460)`: si `valor`, deja visible el botón 15, lo pone en `tbrDropdown` y muestra `ButtonMenus(2)` (`INGYMA`) | Permiso propio del masivo. Va antes del `Else` porque `Buttons(460)` daría error y cortaría el resto de los permisos. Solo actúa si el permiso está habilitado, para no ocultar el botón que ya activó el 15 |
| `SubBuscarOpcionMenu`, dentro del `Else` (:1496) | Si `numero = 15` y FACO: `Style = tbrDropdown` y `ButtonMenus(1).Visible = valor` (`INGY`) | El permiso 15 de siempre controla el ítem del ingreso unitario |
| `Toolbar1_ButtonClick`, `Case "YYYY"` (:1663) | En FACO, si `INGY` no está visible (el perfil solo tiene el 460), el clic en el cuerpo del botón no abre `Form19Y` y pide usar la flecha | Con dropdown, el cuerpo del botón sigue disparando `YYYY`; sin esta guarda, un perfil con solo el masivo entraría al ingreso unitario |
| `Toolbar1_ButtonMenuClick` (:1919) | `Case "INGY"` → `Form19Y.Show 1` y refresco `ProcesoConsulta`. `Case "INGYMA"` → `Form174.Show 1` (solo si `Flg_Pais$ = "FACO"`) y refresco `ProcesoConsulta`; el `MsgBox` "en construcción" del primer cambio queda comentado (respaldo `MDIForm1.frm.bak_FCDVT-14_Form174`) | Abre la pantalla masiva |

**Permiso 460** (`docs/sql/FCDVT-14/01_menu_ingreso_masivo_y.sql`):
- **Por qué 460:** está libre en el código. `SubBuscarOpcionMenu` ya usa 3, 16, 27, 32, 100, 104, 106, 116-120, 152-155, 281, 331-346, 421, 422 y 450-455. En desarrollo el máximo de `VTA_FACOMENU` es 83. En test se confirma con los prechecks §11.
- **Qué inserta:**
  - `VTA_FACOMENU (460, 'Ingreso de cierre de terminal Y masivo', 'MenuPrincipal', -1)`. `mnu_tipomenu = 'MenuPrincipal'` es lo que filtra la query de `SubBuscarOpcionMenu`.
  - `VTA_FACORELPERMEN (10, 460, -1)` y `(11, 460, -1)`, los perfiles que tienen el permiso 15 en desarrollo y en test. Los perfiles 0 y 1, que en test también tienen el 15, quedan como líneas comentadas.
  - Son INSERT con `VALUES` explícitos, los mismos para producción. Solo se crean filas para los perfiles que **ven** la opción: la query de `SubBuscarOpcionMenu` es un join y un perfil sin fila no la ve.
- **Ajustes y rollback:** otros perfiles se agregan con un INSERT más o desde Mantención de Perfiles (`Form47.SubInsertarOpcMenu`). Rollback: `99_rollback.sql`. Sin filas 460, la rama nunca se ejecuta.

**Resultado esperado:**

| Perfil | Ve |
|---|---|
| FACO con 15 y 460 en −1 | Botón Y con flecha: los dos ítems; un clic en el botón abre `Form19Y` |
| FACO solo con 15 | Flecha solo con "Ingreso del YYY" |
| FACO solo con 460 | Flecha solo con el masivo; el clic en el botón muestra un aviso |
| ARG, SFCL, HTPE, etc. | Botón Y sin flecha, como siempre |

**Pendiente:** compilar, correr `00_prechecks.sql` y `01` en test, y programar la lógica de `Form174` (lectura del CSV, validación, grabado y log). Si se vuelve a guardar `MDIForm1` desde el IDE, se conservan estos cambios solo si el IDE tenía cargada la versión nueva: hay que cerrar y reabrir el proyecto antes de seguir editando.

### 5.3 Form174: pantalla de carga masiva de Y (en construcción, sin compilar)

**Controles del diseño (usuario):** `Command1` Buscar, `Command2` Exportar Excel, `Command3` Salir, el TextBox `NombreArchivo` (en `Frame1`) y `lblLoad` ("Cargando Espere por Favor ...", oculto).

**20-10-2026: botón Buscar.** Basado en `Form133.Command3_Click` (:447). Marcas `xintec-nruz 20-10-2026 FCDVT-14`; respaldo `Form174.frm.bak_FCDVT-14`.
- **Encabezado:** se agregó el OCX `COMDLG32.OCX`, el mismo de Form133, y el control `MSComDlg.CommonDialog CmDlog`.
- **`Form_Load`:** limpia `NombreArchivo` y lo deja con `Locked = True`, para que solo se llene con Buscar. También oculta `lblLoad`.
- **`Command1_Click`:** abre el diálogo con el filtro `Archivos CSV (*.csv)` y los flags de archivo y ruta existentes. Después valida que haya un archivo y que la extensión sea `.csv`. Por último deja la ruta en `NombreArchivo.Text` y en su `ToolTipText`, y en la variable del formulario `mArchivoCsv`, que usará el botón de carga.
- **Cancelar** (`cdlCancel`) deja la selección anterior sin mensaje. Form133, en cambio, borra el archivo elegido y avisa.

**20-10-2026: el usuario agrega el botón Cargar** (`Command4`, todavía sin código).

**20-10-2026: botón Exportar Excel** (`Command2`). Respaldo `Form174.frm.bak_FCDVT-14_Exportar`; código agregado dentro del mismo bloque `xintec-nruz`.
- **`EncabezadoCsvY()`:** devuelve el encabezado fijo de 54 columnas, idéntico a la línea 1 de `plantilla_carga_Y_FACO.csv`. Es el contrato del archivo, no se lee de `vta_paint_z`, y lo reutilizará Cargar para validar.
- **`Command2_Click`:**
  - abre "Guardar como" con `CmDlog.ShowSave`: filtro CSV, nombre sugerido `plantilla_carga_Y_FACO.csv`, confirmación si el archivo ya existe y sin acción si se cancela;
  - escribe con `Open … For Output` y `Print #` (CRLF). Primero el encabezado; después una fila con FECHA = día anterior a `LeeFechaServidor` en formato `dd-mm-yyyy`, identificación vacía y los 45 montos en 0 (54 campos, separados por `;`);
  - pregunta si se abre en Excel (`Shell explorer.exe`). No depende de que Excel esté instalado para generarla.

**22-10-2026: grilla con los registros del CSV** (pedido del usuario). Respaldo `Form174.frm.bak_FCDVT-14_Grilla`; marcas `xintec-nruz 22-10-2026 FCDVT-14`.
- **Diseño:**
  - el formulario crece de 5205 a 7200 de alto;
  - Exportar Excel y Salir bajan a `Top` 5640;
  - entre `Frame1` y los botones va la grilla nueva `Grid1` (MSFlexGrid, OCX `MSFLXGRD.OCX`, con los colores y la fuente de `Form133.Grid2`), del mismo ancho que `Frame1`.
- **Columnas:** Local, Terminal, Fecha Venta y Monto Total. Una fila por cada fila (Y) del CSV. **Monto Total = TOTALES de la Y** = BOLETAS + N.CREDITO + FACTURA (columnas 10 a 12): es el `vta_totalvta` de Form19Y, por decisión del usuario.
- **Cuándo se llena:** al elegir el archivo con Buscar (`CargaGrillaCsv`).
  - Si la línea 1 no es el encabezado de la plantilla (`EncabezadoCsvY()`, sin distinguir mayúsculas y con un `;` final tolerado), avisa y deja la grilla vacía.
  - Ignora las líneas vacías.
  - Las filas con menos de 12 campos no se muestran; al final se informa cuántas fueron.
- **Alcance:** solo muestra; no valida ni graba. Cancelar en el diálogo no cambia la grilla.
- **Esperado con la plantilla:** 3 filas, todas del 16-10-2026 en el local 5: T1 con 1.450.000, T1 con 842.000 y T2 con 300.000.
- Sin compilar.

**Pendiente:** Cargar (`Command4`: leer el CSV, validar e insertar según `docs/FCDVT-14/FORMATO_CARGA_Y_FACO.md`; puede recorrer la misma lectura de `CargaGrillaCsv`). Salir sigue con la prueba temporal del cierre diario (FSCC-12901 / FCDVT-56).

### 5.4 Diseño propuesto del botón Cargar de Form174 (sin programar)

> 30-10-2026: Cargar partirá de la carga validada por Buscar (§5.5). Grabará solo los grupos PROCESADO de `VTA_FACOCARGA_YZ_DET` (`mCarga`), sin volver a leer el archivo, y les dará un estado nuevo (por ejemplo CARGADO). Falta definir qué se graba con la fila Z. Lo que sigue es el diseño anterior, con lectura directa del CSV.

Fuentes: `docs/FCDVT-14/FORMATO_CARGA_Y_FACO.md`, §6 (validaciones), §6.1 (diferencias con Form19Y) y §7 (qué inserta); y la §4.4 de este índice (`Form19Y.GrabaZZZ`).

1. **Requisitos previos:** que haya un archivo (`mArchivoCsv`, lo llena Buscar) y que `Flg_Pais$ = "FACO"`. Mostrar `lblLoad` y el cursor de espera.
2. **Leer el archivo** con `Open … For Input` + `Line Input` y `Split(linea, ";")`:
   - línea 1 = `EncabezadoCsvY()`, sin distinguir mayúsculas;
   - 54 campos por línea, aceptando un `;` final;
   - las líneas vacías se ignoran;
   - tope de filas, unas 1.000 (idealmente por parámetro en `vta_FACOparam`).
3. **Validar todo antes de grabar** y armar la lista de errores por fila:
   - formato: fecha `dd-mm-yyyy` anterior a `LeeFechaServidor`, hora `HH:MM`, números enteros, obligatorios;
   - terminal vigente con la fecha de la fila (consulta de `Oklt`);
   - la Z no cerrada: `Est_TermStat` tiene MsgBox, así que hace falta una versión silenciosa;
   - si viene NRO_Y, que no exista (`FuncValidNumY`) y que no se repita en el archivo;
   - cuadratura, cuando negocio defina la regla.
4. **Grabar cada fila válida** con la secuencia de `Form19Y.GrabaZZZ`, sin copiar sus defectos (§4.4):
   - `SEQ_VTA_FACOTEC.nextval`;
   - N° de Y = NRO_Y o `max+1` en el orden del archivo (nunca −1);
   - `insert vta_FACOlibvta` (tipo `'Y'`, estado `'A'`, `tipof8 'N'`, con cada campo de identificación en su columna y `vta_totalvta` calculado);
   - `insert vta_FACOzzz` (`rec_mtotatrf` calculado);
   - `insert vta_FACOtermstaty` en −1 si no existe.
   - No hay transacciones: si falla a mitad de una fila, informarlo para borrar lo que quedó a medias.
5. **Resultado:** mostrar un resumen (leídas, grabadas, rechazadas con su motivo) y ofrecer exportar los errores. Guardar el log en la tabla que se defina (§7, pregunta 7).
6. **Al cerrar:** igual que Form19Y. `MDIForm1` ya ejecuta `FormVariable.ProcesoConsulta` después de `Form174.Show 1`.

### 5.5 Buscar con validación en la base: Y + Z y grilla de resumen (30-10-2026, sin compilar ni ejecutar)

**Pedido del usuario.** El archivo trae, por terminal-día, varias Y y **una Z** cuyo monto es la suma de las Y. Al presionar Buscar, la grilla muestra **una fila por local, terminal y fecha** con la cantidad de Y, el monto total de las Y, el monto total de la Z y el estado (pendiente, error o procesado). Un package carga el archivo en una tabla, arma el resumen, valida Z = ΣY y registra los errores en un log. Esta etapa **no** crea Y ni Z.

**Decisiones del usuario (30-10):**
- el package separa y valida cada línea; Form174 solo la envía;
- estados: PROCESADO si cuadra, ERROR si no cuadra, PENDIENTE como estado inicial (si queda así, el proceso se cayó);
- la cuadratura compara los TOTALES (BOLETAS + N.CREDITO + FACTURA);
- se agrega un CSV con casos de error.

**Archivo (56 columnas).** `TIPO` (Y/Z) y `TIPO_CARGA` (INGRESAR; MODIFICAR se rechaza por ahora) van después de `CONT_REPOSICION`, como en el DF-SCC. Detalle en `FORMATO_CARGA_Y_FACO.md` §3.1, §6 y §6.2.

**Base de datos** (`docs/sql/FCDVT-14/02` a `06`, `INSTALAR.sql`; índice en `00_LEEME.md`):

| Objeto | Qué es |
|---|---|
| `VTA_FACOCARGA_YZ_DET` | Una fila por línea: la línea cruda, la identificación tipada, las 45 columnas de montos con su nombre `vta_cmp_asoc` (listas para el INSERT de Cargar), `det_total` y `det_estado` OK/ERROR |
| `VTA_FACOCARGA_YZ_RES` | Resumen por fecha, local y terminal: cantidad y total de Y y de Z, líneas con error, estado y motivo |
| `VTA_FACOCARGA_YZ_LOG` | INICIO (archivo y usuario), errores con línea, campo, valor y motivo (etapas LECTURA, VALIDACION, RESUMEN), FIN con los conteos, y ERROR si el proceso se cae. El log es autónomo: queda aunque haya rollback |
| `PKG_F8_CARGA_MASIVA_YZ` | `prc_inicia` (solo FACO) → `prc_inserta_linea` (una por línea; la 1 debe ser el encabezado `c_encabezado`) → `prc_procesa` (terminal vigente a la fecha de la fila como `Oklt`, `NRO_Y` repetido, resumen PENDIENTE, después PROCESADO o ERROR) |

ERROR si el grupo tiene líneas con error, si no tiene exactamente 1 Z, si no tiene Y o si el total de la Z es distinto de la suma de las Y. Quedan para Cargar: Z cerrada (`Est_TermStat`), `NRO_Y` ya existente en la base y el grabado.

**Form174** (respaldo `Form174.frm.bak_FCDVT-14_Resumen`; marcas `xintec-nruz 30-10-2026 FCDVT-14`; la versión del 22-10 queda comentada):
- `EncabezadoCsvY()` pasa a 56 columnas y Exportar Excel genera la fila de ejemplo con `Y;INGRESAR`.
- `CargaGrillaCsv`: primero lee todo el archivo; después llama `prc_inicia`, `prc_inserta_linea` por cada línea (con su número en el archivo) y `prc_procesa`, con `ADODB.Command` parametrizado, como `EjecutaCierreDiario`. Al final muestra un MsgBox con el número de carga y los conteos. Si Oracle falla: `SystemMsg` + `frmLogOraError` y, si el resumen alcanzó a crearse, muestra los grupos PENDIENTE.
- `LlenaGrillaResumen`: columnas Local, Terminal, Fecha, Cant. Y, Monto Total Y, Monto Total Z y Estado (más una columna oculta con el motivo). Las filas ERROR van en rojo, como en Form133, y las PENDIENTE en amarillo. Doble clic en una fila muestra el motivo.
- `mCarga` guarda el número de la carga para Cargar.

**Resultado esperado:** `ejemplo_carga_Y_FACO_20.csv` → 3 PROCESADO; `ejemplo_carga_YZ_FACO_errores.csv` → 1 PROCESADO y 4 ERROR. Consultas en `06_pruebas.sql`.

**Para probar:** prechecks §13-14 → `INSTALAR.sql` en test (y `05` si el exe usa otro usuario) → compilar → Form174 ▸ Buscar con los dos CSV.

### 5.6 Form175: detalle del log de un grupo (03-11-2026, sin compilar)

**Qué pide el usuario.** Que el doble clic en una fila de la grilla de Form174, en vez del `MsgBox` con el motivo, abra una pantalla con todo el log de esa fila (fecha, local y terminal), para saber qué falló en el archivo.

**Form175** (nuevo, `FTEPROD/Form175.frm` + `.frx`; marcas `xintec-nruz 03-11-2026 FCDVT-14`):
- Mismo aspecto que Form174. El `.frx` es una copia binaria de `Form174.frx` (mismas imágenes y offsets).
- Entrada: `Public Sub MuestraLog(vCarga, vFecha, vLocal, vTerminal, vEstado, vMensaje)`. Guarda los datos, llena la grilla y hace `Me.Show 1`. No se usan globales nuevas ni se toca `Módulo1.bas`.
- `LlenaGrillaLog`: lee `vta_<pfx>carga_yz_log` y agrega el tipo y el N° Y de cada línea desde `vta_<pfx>carga_yz_det` (outer join `(+)`). Trae:
  - las líneas del archivo cuyo detalle es de esa fecha, local y terminal;
  - el mensaje RESUMEN del grupo (`log_valor = 'dd-mm-yyyy L<local> T<terminal>'`).
  
  Orden: línea (nulas al final) y `log_id`. Columnas: Línea, Tipo, N° Y, Etapa, Campo, Valor y Motivo. Con motivos largos la fila se hace más alta (hasta 6 renglones). Si no hay log (grupo CARGADO; antes PROCESADO), lo indica en una fila.
- Las líneas sin grupo (fecha, local o terminal ilegibles, o campos distintos de 56) no tienen fila en Form174, así que no se ven aquí; están en la consulta 3 de `06_pruebas.sql`.

**Form174** (respaldo `Form174.frm.bak_FCDVT-14_Log`): `Grid1_DblClick` pasa a `Grid1_Click` (un solo clic, pedido del usuario; respaldo `Form174.frm.bak_FCDVT-14_Clic`; el clic en el encabezado no abre nada), deja comentado el `MsgBox` y llama a `Form175.MuestraLog` con la carga (`mCarga`) y las columnas Fecha, Local, Terminal, Estado y Motivo de la fila. El mensaje final de Buscar dice "Clic en una fila para ver el detalle del log.".

**`recaudacion.vbp`** (respaldo `recaudacion.vbp.bak_FCDVT-14_Form175`): `Form=Form175.frm` después de `Form=Form174.frm`.

**Para probar:** compilar (y revisar que no aparezca `Form175.log`) → Buscar con `docs/sql/FCDVT-14/pruebas/p01_campos_malos.csv` → clic en 02-10 T2 (línea 6, HORA `25:00`), en 09-10 T2 (TIPO vacío y fila RESUMEN) y en 01-10 T1 ("Sin errores registrados para este grupo").

### 5.7 Exportar Excel: plantilla .xlsx con formato (03-11-2026, sin compilar)

**Qué pide el usuario.** Que Exportar Excel descargue un Excel con el formato correcto, para que el usuario no tenga que armarlo y solo escriba los valores. **Decisión del usuario:** Buscar no cambia. El usuario completa el `.xlsx` y lo guarda como "CSV (delimitado por comas)".

**Form174** (respaldo `Form174.frm.bak_FCDVT-14_Plantilla`; la versión CSV de `Command2_Click` queda comentada):
- `Command2_Click` arma con Excel por automatización (`CreateObject`, enlace tardío, como `Form171`) un libro de tres hojas y lo guarda como `.xlsx` (`SaveAs`, formato 51). Nombre sugerido: `plantilla_carga_YZ_FACO.xlsx`.
  - **Carga** es la hoja que se guarda como CSV.
    - Fila 1: el encabezado de 56 columnas de `EncabezadoCsvY()`, con un comentario por columna (`GlosaColumnaCsv`, nueva, con las glosas de FORMATO §3), en negrita y con el color de la grilla.
    - Filas 2 a 2000: FECHA (A) y HORA (E) con formato texto `@` y mensaje de ingreso.
    - Validación de número entero en B-D, F-I y L-BD.
    - Listas en TIPO (J, `ListaTipo`) y TIPO_CARGA (K, `ListaTipoCarga`). Son nombres definidos sobre la hoja Listas, así funcionan en Excel 2007 y no dependen del separador de lista regional.
    - La fila 1 y las columnas A:C quedan inmovilizadas; si Excel no da la ventana, se sigue sin inmovilizar.
  - **Instrucciones** trae 9 pasos y un ejemplo de Z + 2 Y.
  - **Listas** queda oculta.
- Por qué así: la hoja Carga tiene solo las 56 columnas, así que el CSV sale con 56 campos. Las filas que solo tienen formato o validación salen como `;;;;` y Buscar ya las ignora. El formato de los montos es General: Excel no redondea al mostrar, así que un decimal que se cuele llega al package y se rechaza.
- Si Excel no está instalado o falla, se muestra `MsgBox` con el error y se cierra Excel.

**Para probar:**
1. Exportar Excel y abrir el archivo: 3 hojas (Listas oculta), comentarios en el encabezado, listas en J/K, rechazo de `100,5` en un monto y FECHA que no se convierte.
2. Completar una Z y 2 Y y guardar como CSV (delimitado por comas).
3. Buscar con ese CSV: 1 grupo CARGADO.

### 5.8 Estado CARGADO y package multipaís (03-11-2026, sin compilar ni ejecutar)

**Qué pide el usuario.**
1. Que el estado de un grupo correcto se llame **CARGADO** en vez de PROCESADO.
2. Que `PKG_F8_CARGA_MASIVA_YZ` no tenga FACO fijo y sea **multipaís**, para pedirlo más adelante para Chile u otro país. Elige **tablas por país, con prefijo**, como el resto del F8.
3. Que lo actual quede como respaldo.

**Base** (`docs/sql/FCDVT-14/`; detalle en su `00_LEEME.md`, secciones "Multipaís" y "Respaldo"):
- `02` crea, para el prefijo del bloque `EDITAR`, `VTA_<pfx>CARGA_YZ_DET/_RES/_LOG` y `SEQ_VTA_<pfx>CARGA_YZ[_LOG]`, solo si no existen. FACO conserva los nombres del 30-10, así que en test no crea nada.
- `03`/`04`:
  - `pr_config` con lista blanca (solo `FACO`) y SQL dinámico con `{P}` + `fn_r`, el patrón de `PKG_F8_COMPENSA_DI_CARGA`;
  - `prc_inserta_linea(p_flg_pais, …)` y `prc_procesa(p_flg_pais, …)`; las firmas sin país se mantienen y usan FACO;
  - `c_estado_ok = 'CARGADO'`. Misma lógica y mismos mensajes que la versión del 30-10.
- `05` y `99` (partes B y C) trabajan por prefijo. Las cargas viejas de test conservan PROCESADO.
- **Respaldo:** `anterior_2026-11-03/` con la versión solo FACO. Para volver atrás: `99_rollback.sql` parte C y los `.bak_FCDVT-14_Multipais` del exe.

**Exe:**
- `Form174`: las llamadas pasan `Flg_Pais$` primero; la grilla y los mensajes usan `PrefijoCargaYZ()`, que arma el prefijo del país y deja a Chile (`CHI`) sin prefijo; el color compara con CARGADO y el mensaje dice "Grupos cargados".
- `Form175`: lee con `PrefijoCargaYZ()`.
- Respaldos: `Form174.frm.bak_FCDVT-14_Multipais` y `Form175.frm.bak_FCDVT-14_Multipais`.
- **Compatibilidad:** el exe nuevo requiere el package nuevo. El package nuevo acepta también el exe anterior.

**Limitación:** los 56 campos (`c_encabezado`, columnas de DET, Exportar Excel y `EncabezadoCsvY`) son los de `vta_paint_z` de FACO. Otro país puede necesitar otro encabezado y otras columnas; los pasos están en `00_LEEME.md`, sección "Multipaís".

**Para probar:** `INSTALAR.sql` en test → compilar → Buscar con `pruebas/p02_falta_z.csv` → 3 CARGADO y 3 ERROR → clic en un grupo → Form175 con su log.

### 5.9 Botón Cargar: `PKG_F8_GRABA_MASIVA_YZ.prc_graba` (04-11-2026, sin compilar ni ejecutar)

> **04-11, más tarde:** a pedido del usuario, el grabado se **separó** en su propio package, `PKG_F8_GRABA_MASIVA_YZ` (`04b` spec y `04c` body), con el mismo código. `PKG_F8_CARGA_MASIVA_YZ` (`03`/`04`) volvió a la versión del 03-11, que solo valida y llena la grilla, con dos controles de LECTURA nuevos, para que el error no aparezca recién al grabar: VENDEDOR de más de 10 dígitos y montos de más de 12 dígitos (columnas `NUMBER(15,2)`). En el rollback, la parte C (volver a solo FACO) exige ejecutar antes la D, que borra el package de grabado. La versión con `prc_graba` dentro del package de carga quedó en `anterior_2026-11-04b/`. Form174 llama al package nuevo (respaldo `Form174.frm.bak_FCDVT-14_Paquete`). Las pruebas están en `docs/sql/FCDVT-14/pruebas_cargar/`, con el resultado esperado en su `README.md`.

**Decisiones del usuario (04-11):**
- la fila Z se graba como en `Form19`: libvta `'F8'`/99 + zzz, y termstat en −1 solo si no existe;
- el grabado va en la base, en un package propio (`PKG_F8_GRABA_MASIVA_YZ`), con commit o rollback **por grupo**;
- si el terminal-día ya tiene una Z o unas Y, se **reemplazan** como hace `Form19`;
- la glosa de `ter_notas` es propia: `CARGA MASIVA DE CIERRE Z - CARGA <n>` y `CARGA MASIVA DE CIERRE Y - CARGA <n>`.

**Package** `PKG_F8_GRABA_MASIVA_YZ` (`docs/sql/FCDVT-14/04b` y `04c`). Tiene sus copias privadas de `pr_config` (la misma lista blanca), `fn_r` y `prc_log` (escribe en `VTA_{P}CARGA_YZ_LOG`), y toma `c_estado_ok` de la spec de `PKG_F8_CARGA_MASIVA_YZ`:

`prc_graba(p_flg_pais, p_carga, p_usuario, o_grupos_ok, o_grupos_error)` lee los grupos CARGADO de `VTA_{P}CARGA_YZ_RES` antes del bucle y, para cada uno, ejecuta `pr_graba_grupo`:

1. **Revalida:**
   - la Z (`termstat`) no está en estado 1 ni 2, como `Est_TermStat`;
   - ninguna `termstaty` del día está cerrada. Esta guarda no está en Form19, que borra las Y igual;
   - el N° de cada Y queda entre 1 y 98. Una Y sin `NRO_Y` recibe el siguiente al mayor informado del grupo.
2. Lee `vta_bolinicial` y `vta_nrollo` de la Z y de las Y anteriores (`LeeZactual` de Form19 y Form19Y).
3. **Borra**, en este orden:
   - la zzz de los techkeys de la libvta `'F8'`/`'Y'`;
   - esa libvta;
   - todas las termstaty del día (`Func_Eliminar_TermStatY` con `vcierrey` vacío, como lo llama Form19).
4. **Inserta la Z** con `pr_ins_libvta` (columnas de `Form19.GrabarTerceraZZZ`, rama FACO, con cada campo en su columna) y `pr_ins_zzz` (columnas 15 a 56 + `rec_mtotatrf`). Si no existe la termstat, la inserta en −1.
5. **Inserta cada Y**: libvta `'Y'`/N, zzz y termstaty en −1. El N° asignado queda en `det_nro_y`.
6. Pasa el grupo a **GRABADO** (`c_estado_grabado`) con commit. Antes de grabarlo lo toma con un `update` de su fila de RES condicionado a CARGADO: si dos ejecuciones de Cargar coinciden, la segunda espera y después lo omite, dejándolo en el log. Ante cualquier error, hace rollback del grupo, lo deja en ERROR con el motivo (`res_mensaje`) y sigue con el siguiente.

Cada grupo deja su fila en el log (etapa `GRABADO`), además de INICIO y FIN. Una carga sin grupos CARGADO devuelve 0/0.

Ajustes de la revisión de `f8-revisor` (04-11):
- Buscar rechaza VENDEDOR de más de 10 dígitos (`vta_vendedor NUMBER(10)`). Antes la línea pasaba Buscar y fallaba recién en Cargar.
- Se agregó la toma del grupo contra la doble ejecución.
- Se corrigieron textos (FORMATO §3.1 `NRO_Y`, encabezados de `INSTALAR` y `02`, `00_LEEME`, `06` y `docs/Cambios/README.md` §3).

Verificado en el clon de test:
- no hay triggers sobre `VTA_FACOLIBVTA` ni sobre `termstat(y)`;
- los triggers de `VTA_FACOZZZ` solo completan `REC_MCMRREVCMP` y `REC_TARJEXTERNA`;
- las 42 columnas `REC_*` existen;
- `vta_secuencia` es `NUMBER(2)`;
- la PK de libvta es (`fecha`, `local`, `terminal`, `tiporeg`, `secuencia`, `fecha_venta`).

**Exe** (marcas `xintec-nruz 04-11-2026 FCDVT-14`; respaldos `.bak_FCDVT-14_Cargar`):
- **`Form174`:**
  - `Command4_Click` es nuevo: exige un Buscar previo con grupos CARGADO, pide confirmación avisando que reemplaza, llama a `PKG_F8_GRABA_MASIVA_YZ.prc_graba` con `ADODB.Command` y refresca la grilla;
  - Cargar se habilita solo después de un Buscar con grupos CARGADO (`Form_Load` y `CargaGrillaCsv`);
  - en la grilla, GRABADO va en verde.
- **`Form175`:** el log del grupo incluye la etapa GRABADO (antes solo RESUMEN).

**Scripts:**
- `06_pruebas.sql`, consultas 6 a 9: lo grabado en libvta, zzz y termstat(y), y las zzz huérfanas;
- `98_limpia_prueba.sql`, nuevo y **solo para test**: borra lo grabado por una carga;
- `99_rollback.sql`, parte D: `drop package PKG_F8_GRABA_MASIVA_YZ`;
- `pruebas_cargar/` (c00 a c05): prechecks, 4 CSV (correcto, mixto, reemplazo y numeración), una Y cerrada y el `README.md` con el resultado esperado.

**Riesgo:** el reemplazo borra las Y abiertas del día. Si tenían compensaciones (`movdet` con `mov_cierrey`), estas quedan apuntando al número de Y del archivo. Hay que probarlo en test con un caso así.

**Para probar en test:**
1. `INSTALAR.sql` y compilar.
2. Buscar con `ejemplo_carga_Y_FACO_20.csv` → 3 CARGADO → Cargar → 3 GRABADO.
3. `06_pruebas.sql`, consultas 6 a 9: 3 libvta `'F8'`/99, 20 `'Y'`, 23 zzz, 20 termstaty en −1 con la glosa y 0 zzz huérfanas.
4. En la F8 (`Form3Y`) se ven las Y. En `Form19Y`, la columna "Valor Z" muestra la Z.
5. Repetir Buscar + Cargar: los conteos quedan iguales.
6. Cerrar una Y y volver a cargar ese terminal: el grupo queda en ERROR y no cambia nada.
7. `98_limpia_prueba.sql`.

## 6. Hechos verificados en la base de test

Pendiente: correr `docs/sql/FCDVT-14/00_prechecks.sql`. Referencia previa (FSCC-12901): `VTA_PAINT_Z` de FACO tiene 53 filas en test, 47 campos, signo siempre `+`, grupos ZZZ 1, 2, 3, 6 y 7.

**20-10-2026, consultas de solo lectura en test (`uintranetts`):**
- **`vta_paint_z` FACO, 53 filas:**
  - 46 con `pop_up = 0` y 1 total, `vta_totalvta` (pop 3). El resto son títulos o separadores.
  - Las 45 columnas de montos del CSV coinciden con las pop 0 en el mismo orden. Queda fuera `rec_mtotatrf`, que Form19Y recalcula.
  - Las columnas 50 a 54 (`REC_MDEVTERCERO`, `REC_MQUICKPAYCMR`, `REC_MQUICKPAYBCO`, `REC_ECOMPAY`, `rec_mpagopuntos`) existen y van a `VTA_FACOZZZ`.
- **Menú:** `VTA_FACOMENU`, máximo `mnu_codigo` = 422 antes del 460. El permiso 15 está en −1 para los perfiles 0, 1, 10 y 11.
- **Datos para probar la carga:**
  - El 16-10-2026, el local 5 tiene los terminales 1, 2 y 3 vigentes, con la Z en −1 y sin ninguna Y ni libvta.
  - El local 216 con los terminales 6 y 7, que usaba el ejemplo anterior, no existe en `vta_FACOterminales`.
  - La única Y del 16-10 es la del local 183, terminal 953. Muestra el corrimiento de Form19Y: `bolfinal` y `crepo` en 0, `vendedor` = N° de boleta.

## 7. Preguntas abiertas para negocio

1. **UPDATE**: ¿se conservan Hora, Secuencia, Boleta, Vendedor y Cont. Reposición de la Z existente? En SFCL/FACO, ¿un update de la Z debe **conservar las Y**? Hoy Form19 las borra.
2. **Terminal cerrado** (estado 1/2): ¿se rechaza la fila, o se permite con un perfil especial reabriendo el terminal?
3. **Descuadratura**: ¿qué fórmula se usa, la de grupos ZZZ o la de venta total contra formas de pago? ¿Se rechaza solo la fila o el archivo completo?
4. **Y (SFCL/FACO)**: ¿el N° de Y viene en el Excel o se asigna como max+1? ¿Se valida Z = ΣY?
5. **SFCL**: ¿cargar una Z debe seguir creando la Y1 automática?
6. **Template**: ¿hay un formato oficial por país con encabezados exactos? ¿Qué pasa con las glosas repetidas y con las celdas `-`?
7. **Log**: ¿tabla en la base o archivo? ¿Qué campos? ¿Hace falta la pantalla de reporte de auditoría?
8. **Permisos**: ¿qué perfiles usan la carga?
9. **Falabella Chile**: ¿hay que validar la recaudación contra LV (`VerificaCuadraturaREC`) como hace Form19?
10. **Recarga después de los sobres** (hallazgo del 12-11-2026, sesión 7): Cargar reemplaza la Y de un terminal-día abierto aunque ya tenga sobres y una DI automática; la DI calculada con el monto anterior queda y la caja se descuadra (ejemplo: v1 1.500.800, sobres 1.500.000, DI −800; v2 1.490.000 → Dif. Real +10.800). ¿Se bloquea o se advierte la recarga cuando la Y tiene sobres o DI, o se recalcula la DI al grabar?

## 8. Cómo retomar

1. Correr `docs/sql/FCDVT-14/00_prechecks.sql` en test (VPN Fortinet; ver `README_FSCC-12901.md` §8) y anotar los resultados en §6.
2. Comparar las columnas del template con `vta_paint_z` de cada empresa (consultas 1 a 4 de los prechecks).
3. Con las respuestas de §7, escribir el diseño detallado (`docs/FCDVT-14_Analisis.md`) y los scripts de log (`docs/sql/FCDVT-14/01..`, `99_rollback.sql`).
4. Antes de tocar `.frm`: respaldo `.bak_FCDVT-14` y edición binaria (Windows-1252 + CRLF).
5. ~~Submenú de Y y permiso 460 en test~~: hecho el 20-10-2026 (§5.2).

**Para retomar (desde el 03-11-2026):**
1. Verificar que nada cambió desde que se congeló: `grep -v '^#' docs/MANIFIESTO_FCDVT-14.md5 | md5sum -c`. Si un `.frm` no coincide, el usuario lo editó en el IDE: leerlo antes de tocarlo y sincronizar `docs/Cambios/` (regla de CLAUDE.md §9).
2. **El usuario edita en el IDE.** Antes de editar un `.frm`, pedirle que guarde y cierre el proyecto, y después que lo vuelva a abrir. Edición binaria CP1252 + CRLF (script Perl/Python, nunca Edit/Write directo), respaldo `.bak_FCDVT-14_<paso>`, marcas `xintec-nruz dd-mm-yyyy FCDVT-14`, lo anterior comentado. **Nunca** poner un comentario dentro de una sentencia continuada con `_`.
3. Pendiente inmediato del usuario, en test:
   1. ejecutar `docs/sql/FCDVT-14/INSTALAR.sql` (package multipaís; `02` no crea nada para FACO);
   2. compilar;
   3. probar con `pruebas/p02_falta_z.csv` (3 CARGADO, 3 ERROR), el clic que abre Form175 y Exportar Excel → CSV → Buscar.
   
   Si el multipaís falla: `99_rollback.sql` parte C y `FTEPROD/Form17[45].frm.bak_FCDVT-14_Multipais`.
4. ~~Siguiente desarrollo: **Cargar**~~: programado el 04-11 (§5.9). Pendiente del usuario en test:
   - `INSTALAR.sql`, que ahora instala los dos packages;
   - compilar;
   - la prueba de `docs/sql/FCDVT-14/pruebas_cargar/README.md`;
   - `98_limpia_prueba.sql`.

   Si falla: `99_rollback.sql` parte D y `FTEPROD/Form17[45].frm.bak_FCDVT-14_Cargar`.
5. Prueba pendiente del usuario en test: la sesión 8 (`docs/sql/FCDVT-14/prueba_carga_y_compensa_di_s8/LEEME.md`, fecha 12-11-2026): `py0` → v1 → sobres de T1 a T4 y T6 → v2 → sobres de T5 → `py2` → cierre con CC del local 5. No presionar Salir de Form174 ni correr el cron de cierre diario sobre el 12-11.
6. Antes de producción: decidir qué hacer con la prueba del cierre diario en Salir (§2), subir `Gversion` y ejecutar `01` junto con el exe.

## 9. Historial

| Fecha | Hito |
|---|---|
| 16-10-2026 | Recepción del DF-SCC. Análisis del requerimiento y del flujo actual de Z/Y (Form19, Form19Y, cargas Excel, menú, log). README y prechecks creados. |
| 16-10-2026 | Análisis detallado de `Form19Y.frm` (ingreso de Y) agregado en §4.4: validaciones, origen de los valores, grabado y defectos (columnas corridas, CONT. REPOSICION no se graba, zzz huérfana, número −1 si falla max+1). |
| 16-10-2026 | Primera tarea acotada: **carga masiva de inserción de Y para FACO**. Se diseña el CSV (`docs/FCDVT-14/`). Las columnas salen de `vta_paint_z` FACO leída en desarrollo (47 filas); 5 conceptos del template quedan por confirmar en test. Sin cambios en formularios ni en la base. |
| 19-10-2026 | `CLAUDE.md` §9 incluye FCDVT-14 entre los requerimientos vigentes (estado: en análisis). Sin otros cambios. |
| 19-10-2026 | Análisis del submenú de Y en §5.1: botón `YYYY` con dropdown solo en FACO ("Ingreso" + "Ingreso masivo", con permiso propio), siguiendo el precedente `ZLV`; lista de archivos a modificar y su magnitud (`MDIForm1.frm`, `Form174.frm` nuevo, `.vbp`, `Gversion`, scripts). Sin cambios en VB6. |
| 20-10-2026 | Submenú de Y implementado en `MDIForm1.frm` (§5.2, sin compilar; respaldo `.bak_FCDVT-14`): `Button15` sin `Style = 5` y con `INGY`/`INGYMA` ocultos; dropdown solo en FACO por el permiso 15 (`INGY`) y el nuevo 460 (`INGYMA`); guarda en `YYYY`; `INGYMA` muestra "en construcción". Scripts `01_menu_ingreso_masivo_y.sql`, `99_rollback.sql`, `00_LEEME.md` y prechecks §11-12, sin ejecutar. |
| 20-10-2026 | El usuario crea `Form174.frm` (diseño de la pantalla masiva) y lo agrega al `.vbp`. `INGYMA` pasa a abrir `Form174.Show 1` (solo FACO); el `MsgBox` provisorio queda comentado. Respaldo `MDIForm1.frm.bak_FCDVT-14_Form174`. Sin compilar. |
| 20-10-2026 | `01_menu_ingreso_masivo_y.sql` reescrito con INSERT explícitos para llevar a producción: menú 460 y perfiles 10 y 11. Antes copiaba con `insert … select` el estado del 15 a todos los perfiles. Al revisar test, no había filas 460 (no se había ejecutado o faltó el commit). |
| 20-10-2026 | El usuario confirma que el ítem masivo se ve y que abre Form174. Se programa el botón **Buscar** de Form174 (§5.3): CommonDialog con filtro CSV y la ruta en `NombreArchivo`. Respaldo `Form174.frm.bak_FCDVT-14`. Sin compilar. |
| 20-10-2026 | Validación del CSV contra Form19Y y la base de test: **sirve para la carga masiva**. Se confirman las columnas 50 a 54 y que `REC_MREVATOTTRF` se informa. La plantilla queda con 54 campos (antes tenía un `;` final, 55) y con filas de ejemplo válidas en test (16-10-2026, local 5, terminales 1 y 2). `FORMATO` §6.1 nueva con las diferencias respecto de Form19Y (fecha de `Oklt`, hora, N° Y, −1). |
| 20-10-2026 | Form174: el usuario agrega el botón Cargar. Se programa **Exportar Excel** (§5.3): guarda una plantilla CSV con el encabezado de 54 columnas y una fila con la fecha de ayer y los montos en 0. Se verificó que el encabezado es idéntico a la plantilla. Respaldo `Form174.frm.bak_FCDVT-14_Exportar`. Sin compilar. |
| 20-10-2026 | **Estado congelado** ("graba todo"): §2 Estado, §5.4 diseño de Cargar, §8 guía para retomar, `CLAUDE.md` (§5 Form174 y §9 FCDVT-14), memoria. Manifiesto `docs/MANIFIESTO_FCDVT-14.md5` y respaldo `docs/respaldos/FCDVT-14_2026-10-20_form174-buscar-exportar.zip`. |
| 22-10-2026 | Form174: **grilla con los registros del CSV** (§5.3). Al elegir el archivo con Buscar muestra Local, Terminal, Fecha Venta y Monto Total (TOTALES = BOLETAS + N.CREDITO + FACTURA). El formulario crece a 7200 de alto y los botones de abajo bajan. Respaldo `Form174.frm.bak_FCDVT-14_Grilla`. Sin compilar. Entretanto, por FCDVT-56, Salir pasó a la fecha de prueba 15-10-2026 (respaldo `.bak_FCDVT-56`). Se regeneró el manifiesto. |
| 22-10-2026 | CSV de prueba de la grilla: `docs/sql/FCDVT-14/ejemplo_carga_Y_FACO_20.csv`. Tiene el formato de la plantilla y 20 Y del 16-10-2026 en el local 5 (T1 ×7, T2 ×7, T3 ×6), con las formas de pago cuadradas contra los TOTALES; la suma es 26.325.000. La plantilla no cambia. Se regeneró el manifiesto. |
| 22-10-2026 | **Paquete de paso a producción** en `docs/Cambios/`: `MDIForm1.frm`, `Form174.frm` (versión prod, con Salir solo `Unload Me`) + `.frx` y la línea `Form=Form174.frm` del `.vbp`. El permiso 460 va junto con el exe, o se posterga mientras Cargar no esté programado |
| 26-10-2026 | `CLAUDE.md` al día (`/init`): §5 y §9 advierten que el `Form174` local no es el de producción, que está en `docs/Cambios/archivos/`. En `docs/MANIFIESTO_FCDVT-14.md5` solo cambian los MD5 de `CLAUDE.md` y de este índice. Respaldo `docs/respaldos/FSCC-12901_2026-10-26_claude-md.zip` |
| 30-10-2026 | **Buscar con validación en la base (Y + Z)** (§5.5). El CSV pasa a 56 columnas (`TIPO`, `TIPO_CARGA`). `ejemplo_carga_Y_FACO_20.csv` queda con una Z por terminal (23 filas; respaldo `.bak_FCDVT-14_Z`) y se agrega `ejemplo_carga_YZ_FACO_errores.csv`. Scripts `02` a `06`, `INSTALAR.sql`, prechecks §13-14 y rollback parte B: `PKG_F8_CARGA_MASIVA_YZ` y tablas `VTA_FACOCARGA_YZ_DET` / `_RES` / `_LOG`, sin ejecutar. Form174: Buscar llama al package y la grilla muestra el resumen por terminal-día con su estado (respaldo `.bak_FCDVT-14_Resumen`, sin compilar). Plantilla y `FORMATO` actualizados (cuadratura §6.7 definida: total Z = ΣY). |
| 30-10-2026 | **Estado congelado** antes de probar Buscar en test: manifiesto `docs/MANIFIESTO_FCDVT-14.md5` regenerado (agrega `02`-`06`, `INSTALAR.sql`, el CSV de errores, el respaldo del CSV de 20 Y y `Form174.frm.bak_FCDVT-14_Resumen`) y respaldo `docs/respaldos/FCDVT-14_2026-10-30_buscar-resumen-yz.zip`. Nada ejecutado en la base ni compilado. |
| 02-11-2026 | Revisión: Buscar (`Command1_Click`) ya llamaba a `CargaGrillaCsv`, que usa `PKG_F8_CARGA_MASIVA_YZ` (30-10). Solo se cambia el título del diálogo a "cierres Y y Z" y se marca el llamado. Respaldo `Form174.frm.bak_FCDVT-14_Buscar`. Sin compilar. |
| 03-11-2026 | El usuario confirma que Buscar funciona en test con los dos CSV de ejemplo. Se agregan 8 CSV de prueba en `docs/sql/FCDVT-14/pruebas/` (`p01` a `p08`): campos malos, falta de Z, Z sin Y, 2 Z, cuadratura, `NRO_Y` repetido, estructura de la línea, encabezado de 54 columnas, solo encabezado y volumen. El resultado esperado de cada uno está en `pruebas/README.md`, verificado reproduciendo las reglas del package. Sin cambios en el exe ni en la base. |
| 03-11-2026 | **Form175** (§5.6): el doble clic en la grilla de Form174 abre el detalle del log del grupo (antes, un `MsgBox`). `Form175.frm` + `.frx` (copia de `Form174.frx`), `Form174.Grid1_DblClick` y `Form=Form175.frm` en el `.vbp`. Respaldos `Form174.frm.bak_FCDVT-14_Log` y `recaudacion.vbp.bak_FCDVT-14_Form175`. Sin compilar. Se sincronizó `docs/Cambios/`, que también recibe el cambio de `Form174` del 03-11 a las 10:02 (fecha de prueba 02-11-2026 de Salir) que no estaba. |
| 03-11-2026 | Form174: Form175 se abre con **un solo clic** (`Grid1_Click`, antes `Grid1_DblClick`), a pedido del usuario. Un clic en el encabezado no abre nada (`MouseRow < 1`). El mensaje final de Buscar dice "Clic en una fila…". Respaldo `Form174.frm.bak_FCDVT-14_Clic`. Sin compilar. `docs/Cambios/` sincronizado. |
| 03-11-2026 | Form174: **Exportar Excel genera una plantilla `.xlsx` con formato** (§5.7): hojas Carga (encabezado con comentarios, FECHA y HORA texto, enteros validados, listas en TIPO y TIPO_CARGA), Instrucciones y Listas oculta. El usuario la guarda como CSV para Buscar, que no cambia. Respaldo `Form174.frm.bak_FCDVT-14_Plantilla`. `FORMATO` §5 actualizado (2 copias). Sin compilar. `docs/Cambios/` sincronizado. |
| 03-11-2026 | **Estado CARGADO y package multipaís** (§5.8). El estado de un grupo correcto pasa de PROCESADO a CARGADO. `PKG_F8_CARGA_MASIVA_YZ` recibe el país (lista blanca, solo FACO; SQL `{P}`) con tablas por prefijo `VTA_<pfx>CARGA_YZ_*`; FACO conserva sus nombres. `02`, `03`, `04`, `05`, `06`, `INSTALAR` y `99` (parte C: volver a la versión anterior) actualizados; respaldo en `anterior_2026-11-03/`. Form174/Form175 pasan el país y usan `PrefijoCargaYZ()` (respaldos `.bak_FCDVT-14_Multipais`). Pruebas y `FORMATO` con CARGADO. Sin compilar ni ejecutar. `docs/Cambios/` sincronizado. |
| 03-11-2026 | **Estado congelado** ("documenta todo"): §2 Estado y §8 Cómo retomar al día; memoria del proyecto; `docs/MANIFIESTO_FCDVT-14.md5` verificado; respaldo `docs/respaldos/FCDVT-14_2026-11-03_multipais-cargado.zip`. Nada ejecutado en la base ni compilado después del 30-10. |
| 04-11-2026 | **Botón Cargar** (§5.9). `PKG_F8_CARGA_MASIVA_YZ.prc_graba` graba los grupos CARGADO: Z como Form19 (libvta `'F8'`/99 + zzz, termstat −1 si falta) e Y como Form19Y (libvta + zzz + termstaty −1), con los campos en su columna. Antes de grabar revalida que la Z y las Y no estén cerradas y que el N° de Y quede entre 1 y 98; después **reemplaza** lo que el terminal-día tenía (sin dejar zzz huérfanas). Hace commit o rollback por grupo y deja el estado nuevo GRABADO. Glosas `CARGA MASIVA DE CIERRE Z/Y - CARGA <n>`. Form174: `Command4_Click`. Form175: log de la etapa GRABADO. `06` (consultas 6 a 9), `98_limpia_prueba.sql` nuevo, `99` parte D, `00_LEEME`, `FORMATO` §7-8 (2 copias), `CLAUDE.md` y `docs/sql/CLAUDE.md`. Respaldos en `anterior_2026-11-04/` y `.bak_FCDVT-14_Cargar`. `docs/Cambios/` sincronizado. Sin compilar ni ejecutar. |
| 04-11-2026 | **Estado congelado** antes de pasar a test el botón Cargar: `docs/MANIFIESTO_FCDVT-14.md5` regenerado (agrega `98_limpia_prueba.sql`, `anterior_2026-11-04/` y los `.bak_FCDVT-14_Cargar` de Form174 y Form175) y respaldo `docs/respaldos/FCDVT-14_2026-11-04_cargar-grabado.zip`. Nada ejecutado en la base ni compilado después del 30-10. |
| 04-11-2026 | **Grabado separado en su propio package**, a pedido del usuario. `PKG_F8_GRABA_MASIVA_YZ` (`04b` spec y `04c` body nuevos) tiene el mismo código de `prc_graba`, con copias privadas de `pr_config`, `fn_r` y `prc_log`. `PKG_F8_CARGA_MASIVA_YZ` vuelve a la del 03-11 más el control de VENDEDOR (se verificó con un diff). `INSTALAR`, `05`, `99` parte D (`drop package`), `06` y `98` actualizados. Form174 llama al package nuevo (respaldo `.bak_FCDVT-14_Paquete`; `docs/Cambios` sincronizado). Carpeta nueva `pruebas_cargar/` (c00 a c05 + `README.md`). Después de la revisión de `f8-revisor`: tope de montos de 12 dígitos en Buscar, aviso en la parte C del rollback, sinónimos en las partes B y D, y la parte 2 de `c05` reabre la Y aunque se haya cerrado desde la F8. La versión anterior quedó en `anterior_2026-11-04b/`. Sin compilar ni ejecutar. |
| 04-11-2026 | **Estado congelado** con los packages separados (`PKG_F8_CARGA_MASIVA_YZ` para Buscar y `PKG_F8_GRABA_MASIVA_YZ` para Cargar) y la carpeta `pruebas_cargar/`. `docs/MANIFIESTO_FCDVT-14.md5` regenerado (agrega `04b`, `04c`, `anterior_2026-11-04b/`, `pruebas_cargar/` y `Form174.frm.bak_FCDVT-14_Paquete`) y respaldo `docs/respaldos/FCDVT-14_2026-11-04_packages-separados.zip`. Nada ejecutado en la base ni compilado después del 30-10. |
| 12-11-2026 | **Sesión de prueba 7** (`docs/sql/FCDVT-14/prueba_carga_y_compensa_di_s7/`): réplica de la sesión 6 con fecha 11-11-2026 y sobres `5TT1111nn`, más la **recarga v1/v2** pedida por el usuario: dos archivos con la misma fecha, local y terminal y otro monto que cuadra. Según `PKG_F8_GRABA_MASIVA_YZ` (reemplaza por terminal-día, no toca prd/movdet/compdes, la termstat de la Z conserva la glosa de v1), **queda el monto del último archivo**. T5 (v1 1.000.000 → v2 1.200.000 → sobres 1.199.500): DI −500 calculada con v2. T6 (v1 1.500.800 → sobres 1.500.000, DI −800 → v2 1.490.000): la DI de v1 queda, Dif. Real +10.800 (pregunta 10 de §7). `py2` parte C, hoja "Recarga v1-v2" del resumen. Sin ejecutar en test. La misma prueba para Tottus está en `docs/sql/FCDVT-10/prueba_recarga_v1_v2/`. |
| 13-11-2026 | **Sesión de prueba 8** (`docs/sql/FCDVT-14/prueba_carga_y_compensa_di_s8/`): a pedido del usuario, la sesión 7 repetida tal cual con fecha de venta 12-11-2026 (libre; el package exige fecha anterior a hoy) y sobres `5TT1211nn`. Mismas cajas (local 5, T1 a T6), montos, orden v1 → sobres → v2 → sobres de T5 y resultados esperados. Sin ejecutar en test. |
