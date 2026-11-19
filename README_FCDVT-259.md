# FCDVT-259 · HU02-EXT: exportar los cierres Y y Z en el formato de la plantilla de carga

> **Estado (16-11-2026): implementado.** El exe sigue sin compilar; en base, la primera instalación en desarrollo dejó el body INVALID y ya está corregido — reinstalar `03` (ver Historial).
> - **Exe:** se crearon `Form176.frm` y `Form176.frx` (Exportar Cierres Y y Z). En `MDIForm1.frm` se agregaron el submenú `EXPYZ` del botón Y y el permiso 461, y en `recaudacion.vbp` la línea `Form=Form176.frm`. `Form174.frm` volvió a la versión anterior al Descargar Excel. Todo está sincronizado en `docs/Cambios/`, sin compilar.
> - **Base:** `docs/sql/FCDVT-259/` (menú 461 y `PKG_F8_EXPORTA_MASIVA_YZ` solo FACO). Escrito y revisado con `sql-lint`. Instalado el 16-11 en desarrollo: spec VALID, body INVALID (declaraciones de datos entre subprogramas, que 10.2 no acepta) y corregido en `03`.
> - En Jira: *Refining*, FCDVT Sprint 3, 3 story points.
>
> Fuente: `docs/Requerimiento-FCDVT-259/` (`FCDVT-259.doc` es la exportación HTML de Jira; `image-20261116-123023.png` es la maqueta). Relacionado con la carga masiva de **FCDVT-14** (`docs/README_FCDVT-14.md`; Form174 vuelve a cargar el CSV exportado).

## 1. Qué pide

> Como analista de Control de Venta o de Tesorería, quiero exportar a un archivo CSV los cierres Y y Z de una fecha, local y terminal con la misma estructura de la plantilla de carga masiva, para bajar esa información y volver a cargarla en la carga masiva de cierres sin armar el archivo a mano.

**Pantalla** (maqueta "Exportar Cierres Y y Z (plantilla de carga)"): filtros Local (0 = todos los locales del negocio), Terminal (0 = todos los terminales del local), Fecha Inicio y Fecha Fin; botones Exportar y Salir; recuadro "Resultado de la exportación" con el archivo y la cantidad de cierres ("12 filas (6 terminales · 6 Y y 6 Z)").

| Escenario | Dado | Entonces |
|---|---|---|
| Exportar los cierres de un local y un día | Local 5, terminales 1 a 6 con una Y y su Z cada uno; Local 5, Terminal 0, un día | CSV con la fila de títulos de la plantilla y 12 filas (6 Y y 6 Z), identificación (`FECHA` a `TIPO_CARGA`) y montos en el orden de la plantilla |
| El archivo exportado se puede volver a cargar | Archivo exportado sin cambios | La carga masiva no informa diferencias de formato |
| Filtros sin cierres | Terminal sin cierres | «No existen cierres Y/Z para los filtros seleccionados» y no se genera archivo |
| Rango de fechas inválido | Fecha Inicio posterior a la Fecha Fin | Aviso de que la Fecha Fin no puede ser anterior a la Fecha Inicio; no se genera archivo |
| Negocio que solo trabaja con Z | Falabella Chile | **Fuera de alcance** (decisión del usuario: por ahora solo Colombia) |

## 2. Decisiones del usuario (16-11-2026)

1. **Pantalla propia, `Form176`**, igual a la maqueta pero sin el recuadro "PROPUESTA". El "Descargar Excel" que se había agregado a Form174 ese mismo día (FCDVT-14 §5.10) **se revierte**: no corresponde a ese formulario.
2. **Solo Colombia (FACO)**: el package deja de ser multipaís.
3. **Fechas:** Fecha Inicio ≥ hoy − 2 días, Fecha Fin ≤ ayer y Fecha Fin ≥ Fecha Inicio. Hoy es la fecha del servidor. (Se pidió Fecha Fin ≤ hoy; tras la revisión quedó **hasta ayer**, porque Buscar de Form174 rechaza las fechas de hoy y el CSV no se podría volver a cargar.)
   - **Modificado el 17-11-2026 a pedido del usuario:** los calendarios abren con **ayer por defecto** y solo tienen tope superior ayer (**sin `MinDate`**), y el botón Exportar valida un **rango máximo de 3 días incluidos** entre Fecha Inicio y Fecha Fin (`Fin − Inicio ≤ 2`); se **quitó** el límite "Fecha Inicio ≥ hoy − 2". El mismo día se restauró el bloque de fechas del servidor que estaba comentado en la copia de `FTEPROD/` (con `mHoy` en 0, Exportar mostraba "hoy (30-12-1899)" y rechazaba todo). Ver `docs/Cambios/README.md` §2.7.
4. **El botón Exportar llama a `PKG_F8_EXPORTA_MASIVA_YZ`**, ajustado a los filtros de la pantalla. Los scripts se trasladan de `docs/sql/FCDVT-14/` (04d/04e, nunca instalados) a `docs/sql/FCDVT-259/`.
5. **Z armada:** se mantiene. Un terminal-día con Y y sin Z en libvta (FACO cerrado solo con Y) sale con una Z = suma de sus Y, para que el CSV se pueda volver a cargar.
6. **Menú:** permiso **461**, submenú "Exportar Cierres Y y Z" del botón Y (junto a "Ingreso del YYY Masivo"), con los mismos perfiles que el 460 (10 y 11).

## 3. Artefactos

| Artefacto | Qué es |
|---|---|
| `FTEPROD/Form176.frm` + `Form176.frx` | Pantalla nueva (detalle en §4). El `.frx` es una copia binaria de `Form174.frx`, como `Form175` |
| `FTEPROD/MDIForm1.frm` | `Button15` con un tercer `ButtonMenu` `EXPYZ`; rama `numero = 461` (solo FACO) en `SubBuscarOpcionMenu`; `Case "EXPYZ"` → `Form176.Show 1`. Respaldo `MDIForm1.frm.bak_FCDVT-259` |
| `FTEPROD/recaudacion.vbp` | `Form=Form176.frm`. Respaldo `recaudacion.vbp.bak_FCDVT-259` |
| `FTEPROD/Form174.frm` | Revertido a `Form174.frm.bak_FCDVT-14_Descargar` (md5 `8027c571…`). La versión con Descargar quedó en `Form174.frm.bak_FCDVT-259_Descargar` |
| `docs/sql/FCDVT-259/` | `00_prechecks`, `01_menu_exporta_yz` (461), `02`/`03` package, `04_grants_sinonimos`, `05_pruebas`, `99_rollback`, `INSTALAR.sql`, `00_LEEME.md` y `pruebas/` (prueba de punta a punta en test) |
| `docs/Cambios/` | `archivos/` y `diffs/` de Form176, MDIForm1 y Form174; README §1, §2.3, §2.4, §2.5, §2.7 y §3 |

## 4. Diseño

### 4.1 Form176

- **Criterio:**
  - Local (`Combo1`/`Combo2`): `ProLeeLocales` según el perfil; si el perfil ve más de un local, "0-TODOS LOS LOCALES" al comienzo, como Form43.
  - Terminal (`Combo3`): 0 + los vigentes del local a la Fecha Inicio (como `Form43.LeeTerminales`); con local 0 solo 0.
  - Fecha Inicio y Fecha Fin (`DTPicker1`/`DTPicker2`): por defecto **ayer**, limitadas con `MaxDate = ayer`; **sin `MinDate`** desde el 17-11-2026 (antes `MinDate = hoy − 2`).
- **Exportar:**
  - valida las fechas (§2, punto 3) aunque los calendarios ya las limiten;
  - lee el encabezado y las líneas del package. Con local 0 y perfil de grupo (1 o 5), pasa `p_grupo = LOCALUSER` para no exportar locales de otros grupos;
  - sin líneas, muestra el mensaje de la HU y no genera archivo;
  - con líneas, abre "Guardar como" (`carga_Y_compensa_<ddmmyyyy>_<ddmmyyyy>.csv`, el nombre de la maqueta) y escribe el encabezado y una línea por cierre (`;`, CRLF, `Print #`);
  - en "Resultado" muestra la ruta en `lblArchivo` (la ruta completa también en su `ToolTipText`), el formato en `lblFormato` y el conteo en `lblCierres`: "N filas (T terminales · Y Y y Z Z)". T cuenta local-terminal distintos.
- **Otros países:** avisa y deja Exportar deshabilitado. El menú, además, solo existe en FACO.

### 4.2 `PKG_F8_EXPORTA_MASIVA_YZ` (solo FACO)

- `fn_encabezado` = `PKG_F8_CARGA_MASIVA_YZ.c_encabezado` (56 columnas).
- `fn_lineas(p_local, p_terminal, p_fecha_ini, p_fecha_fin, p_grupo default null)`:
  - *pipelined*, sobre `VTA_FACOLIBVTA` (`'F8'`/`'Y'`, `vta_estado = 'A'`) + `VTA_FACOZZZ`;
  - local 0 = todos, terminal 0 = todos; el grupo filtra por `VTA_FACOLOCALES.vta_grupo`;
  - orden: fecha, local, terminal, Z, Y; la Z armada se corta por fecha-local-terminal;
  - fin < inicio → ORA-20004.
- Cambios respecto del 04e de FCDVT-14: sin `p_flg_pais` ni lista blanca (tablas `VTA_FACO*` fijas), filtros de rango, terminal y grupo, y sin `fn_resumen` (Form176 cuenta las líneas).
- La regla de fechas (rango máximo de 3 días incluidos y Fecha Fin hasta ayer) está en el exe, no en el package (así `05_pruebas.sql` puede consultar cualquier fecha). Hasta el 16-11 era "2 días hacia atrás"; el 17-11-2026 se cambió a rango máximo 3 días sin límite hacia atrás.
- **Fecha Fin hasta ayer (revisión del 16-11):** Buscar de Form174 rechaza las fechas de hoy ("La fecha debe ser anterior a hoy"), así que Form176 no deja exportar cierres de hoy: todo CSV exportado se puede volver a cargar.

## 5. Pendientes

1. **Reinstalar en desarrollo el `03` corregido e instalar en test:**
   - `docs/sql/FCDVT-259/00_prechecks.sql` → `INSTALAR.sql` (02 y 03); requiere `PKG_F8_CARGA_MASIVA_YZ` de FCDVT-14;
   - `01_menu_exporta_yz.sql` (permiso 461) **solo junto con el exe nuevo**: con el exe anterior corta la carga de los permisos siguientes;
   - `04` si el exe usa otro usuario;
   - `05_pruebas.sql`.
2. **Compilar** el exe con Form176 y MDIForm1. Form176 es nuevo y se escribió a mano: revisar en el IDE que el diseño cargue sin `Form176.log` y se vea como la maqueta.
3. **Probar** con `docs/sql/FCDVT-259/pruebas/sesion_2026-11-07/README.md` (sesión del 19-11-2026, fecha 07-11-2026 y día sin cierres 08-11-2026; no hay que cambiar fechas). La sesión original del 27-10 (`pruebas/README.md`) también sirve: desde el 17-11-2026 Form176 no tiene límite hacia atrás, solo Fecha Fin hasta ayer y un rango máximo de 3 días.
4. **Producción:** `01` (permiso 461) solo junto con el exe nuevo, igual que el 460. Ver `docs/Cambios/README.md` §3.
5. **Abierto con negocio:** Chile solo Z (fuera de alcance por ahora) y el nombre de archivo de la maqueta (`carga_Y_compensa_…`).

## 6. Cómo retomar

Leer `docs/SESION_2026-11-19.md` (última sesión: prueba con fecha 07-11 e inconsistencias abiertas del manifiesto de este ticket, §5), este archivo, `docs/sql/FCDVT-259/00_LEEME.md` y `docs/Cambios/README.md` §2.3, §2.4 y §2.7. La prueba a ejecutar es `docs/sql/FCDVT-259/pruebas/sesion_2026-11-07/README.md`. El diseño anterior (Descargar Excel en Form174, multipaís) está en `docs/README_FCDVT-14.md` §5.10 como registro.

## 7. Historial

| Fecha | Qué |
|---|---|
| 16-11-2026 | Fuente del requerimiento movida de `docs/sql/FCDVT-259/` a `docs/Requerimiento-FCDVT-259/`. README con el análisis inicial (comparación con el Descargar Excel de FCDVT-14 §5.10 y preguntas abiertas). |
| 16-11-2026 | **Implementación.** Form174 revertido al 11-11 (sin Descargar; respaldo `Form174.frm.bak_FCDVT-259_Descargar`). `Form176.frm` + `.frx` nuevos, `MDIForm1.frm` (`EXPYZ`, 461) y `recaudacion.vbp` (`Form=Form176.frm`), con respaldos `.bak_FCDVT-259`. `docs/sql/FCDVT-259/` con el package solo FACO (filtros de Form176), el menú 461, grants, pruebas, rollback e `INSTALAR`; se sacaron 04d/04e de FCDVT-14 y `pruebas_descargar/` pasó a `pruebas/`. `docs/Cambios` sincronizado (`cambios check` OK). Sin compilar ni ejecutar. |
| 16-11-2026 | Revisión de `f8-revisor`, corregido: el permiso 461 sale de `INSTALAR.sql` (con el exe anterior corta la carga de permisos, como el 460); `00_prechecks` lee `c_encabezado` con `dbms_output` (en SQL da PLS-221) y verifica 4 columnas más; Form176 recarga los terminales al cambiar la Fecha Inicio y avisa los errores del diálogo de guardar distintos de Cancelar. Documentado como límite: Fecha Fin = hoy no se puede recargar en Buscar. |
| 16-11-2026 | Corrección pendiente del revisor aplicada: Form176 limita la Fecha Fin a **ayer** (`MaxDate` y validación "La Fecha Fin debe ser anterior a hoy"), para que el CSV siempre se pueda recargar en Buscar. Fechas de prueba: 27-10 → anteayer, 28-10 → ayer. `docs/Cambios` sincronizado. |
| 16-11-2026 | **Estado congelado**: manifiesto `docs/MANIFIESTO_FCDVT-259.md5` (52 archivos: Form176, MDIForm1, vbp, Form174 revertido y sus respaldos, `docs/sql/FCDVT-259/`, `docs/Requerimiento-FCDVT-259/`, lo tocado en FCDVT-14/FCDVT-10 y `docs/Cambios`) y respaldo `docs/respaldos/FCDVT-259_2026-11-16_form176-exportar-yz.zip`. Sin compilar ni ejecutar en la base. |
| 16-11-2026 | **Instalación en desarrollo** (`INTRANETDE`): spec `02` VALID, body `03` **INVALID** (`PLS-00103` en la línea de `c_id`). El source en la base era idéntico al script: el body declaraba `c_id`, `c_n_id` y `t_buf` **después** de `fn_expr`, y el parser de 10.2 no acepta declaraciones de datos entre subprogramas. Corregido en `03` moviendo el bloque al tope del body (nada más cambió); `00_LEEME.md` y `MANIFIESTO_FCDVT-259.md5` regenerados. Pendiente: reinstalar `03` en desarrollo y en test. |
| 17-11-2026 | **Regla de fechas nueva (pedido del usuario)**: calendarios de Form176 con **ayer por defecto** y tope ayer, **sin `MinDate`**; Exportar valida **rango máximo de 3 días incluidos** entre Fecha Inicio y Fecha Fin y se quitó el límite "Fecha Inicio ≥ hoy − 2". El mismo día se restauró el bloque de fechas (`mHoy = FechaServidor()`, `MaxDate`, valores) que estaba **comentado en la copia de `FTEPROD/`** — desvío posterior al freeze del 16-11: con `mHoy` en 0, Exportar mostraba "hoy (30-12-1899)" y rechazaba todo rango. Estado previo: `FTEPROD/Form176.frm.bak_FCDVT-259_fechas` (`822c2761…`). `docs/Cambios` sincronizado (README §2.7, diff y manifiestos regenerados). Sin compilar. |
| 18-11-2026 | **Bloque "Resultado de la exportación" (pedido del usuario)**: con rutas largas el texto se partía en 3 líneas y la tercera quedaba tapada por "Cierres exportados". `Frame2` crece de 1815 a 2490 twips y el form de 5520 a 6180; `lblArchivo` (615) queda solo con la ruta, la frase de formato pasa a `lblFormato` (nuevo, TabIndex 19), `lblCierres` baja a 1530, `lblNota` a 1950 y los botones a 5460. La ruta completa también queda en `ToolTipText`. Sin cambios en `.frx`. `docs/Cambios` sincronizado (archivos, diff y manifiesto). Sin compilar. |
| 19-11-2026 | **Sesión de prueba con fecha 07-11-2026** (`docs/sql/FCDVT-259/pruebas/sesion_2026-11-07/`): copia de `d00`, `d01`, `d02`, `d03` y `d09` con 27-10 → 07-11 y 28-10 → 08-11 (mismos montos e identificación) y `README.md` propio, con las validaciones de fechas vigentes de Form176 (rango 07 a 09-11 exporta; 07 a 10-11 da el aviso de 3 días). La sesión del 27-10 queda igual, con una nota. Sin ejecutar. |
| 19-11-2026 (2) | Traspaso documentado en `docs/SESION_2026-11-19.md` (§5: entradas de `MANIFIESTO_FCDVT-259.md5` que no coinciden desde antes de esta sesión, incluidos `PROD/MDIForm1.frm` y `PROD/recaudacion.vbp` de `docs/Cambios`: confirmar con el usuario antes de recalcular). Respaldo `docs/respaldos/FCDVT-10_2026-11-19_reglas-colombia.zip`. |
