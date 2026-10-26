# FSCC-12901: índice y bitácora del trabajo (Falabella Colombia)

Punto de entrada para retomar el análisis y desarrollo de la historia **FSCC-12901**: compensación automática de DI y cierre de caja automático en Colombia (`Flg_Pais$ = "FACO"`). Reúne qué se hizo, dónde está cada cosa, qué se decidió, qué se verificó en la base y qué falta.

Última actualización: **20-10-2026**. **Estado vigente:** modelo COMPENSA_DI probado en test (pruebas 1 a 4 OK), paquete multipaís y `Form43` con TODOS (§5g, "Estado al 20-10"). **Cron de cierre diario listo para test (§5h)**; próximo paso: instalar y probar (pendientes 1p y 1q) y programarlo en nhal1 (1r). Antes, el 19-10: **Cambio de modelo (§5g):** la carga de sobres solo registra la DI automática y no cierra la Y; el cierre pasará a un cron diario. Scripts vigentes en `docs/sql/FSCC-12901_COMPENSA_DI/`. Antes, el 16-10, la prueba 3 en test había salido OK con el modelo anterior.

---

## 1. Requerimiento

| Ítem | Detalle |
|---|---|
| Historia | **FSCC-12901** [SCCFIN][F8] Compensación automática de Diferencia No Imputable dentro de un rango, Falabella Colombia (épica FSCC-12287) |
| T1 | **FSCC-12957** HU-01-T1: compensación automática de DI. Si −1.000 ≤ DR ≤ 20.000 (DR ≠ 0), registra una DI igual a la DR, con el mismo signo. No cierra cajas |
| T2 | **FSCC-12958** HU-01-T2: cierre de caja automático. Corre después de T1; cierra los **cierres Y** de la carga con DR = 0 que cumplen las validaciones de Cerrar Terminal. No compensa. **Colombia opera solo con cierre Y: la Z no se toca** (07-10) |
| Fuentes | `docs/Requeriemintos-FSCC-12901/`: subtareas `.doc` y diagramas BPMN (flujo general, proceso 1, proceso 2). El PDF de la historia estaba en Descargas. El Excel `DF-SCC-vf_Falabella CO (MEJORAS F8 y COMPENSACIONES MENORES).xlsx` y `PRD 3.xlsx` están en esa carpeta (agregados el 06-10) y **se analizaron el 06-10** (`FSCC-12901_Analisis.md` §3.13) |
| Doc. actualizada (07-10) | `docs/Requeriemintos-FSCC-12901/Doc-Actualizado/`: HU completa `FSCC-12901.doc` (ejecutar "al momento de la carga" en `Form133`, "Colombia opera con cierre Y", CA9 nuevo), subtareas sin cambios de texto, diagramas P1/P2 rediseñados y captura de `Form133`. Análisis en `FSCC-12901_Analisis.md` §3.14 |
| DF-SCC | Fila 12: Consultas de Cuadratura (`Form43`) debe mostrar las cajas sin movimiento (Dif. Real 0), como Chile, y cerrarlas, para **evitar el archivo "dataload" de cierre de cajas**. Fila 57: DI automática de −1.000 a 20.000 (= T1). Filas 34, 40, 46 y 52: fuera de alcance |

## 2. Estado

> **Estado vigente (20-10-2026):** ver §5g, "Estado al 20-10". La tabla de abajo es el historial de la v1 y la v2 (T1_T2, PROC_Y, PROC_YZ), reemplazadas por COMPENSA_DI el 19-10.

| Frente | Estado |
|---|---|
| Análisis del cierre manual de Colombia (VB6) | ✔ Completo |
| Análisis de la HU contra el código y la base | ✔ Completo |
| Documentos técnicos por subtarea (PDF) | ✔ T1 y T2 |
| **T2 implementado en base de datos** (tabla homóloga + trigger + paquete) | ✔ **Scripts listos y verificados contra la estructura de test. No compilados ni ejecutados** |
| **T1 implementado en base de datos** (`PKG_F8_FACO_COMPENSA_DI`, reutiliza cola, trigger, log y `fn_dif_real` de T2; T2 lo invoca primero) | ✔ **Scripts listos** en `docs/sql/FSCC-12957/`, verificados contra la estructura de test. No compilados ni ejecutados |
| **Flujo consolidado T1 + T2** (`docs/sql/FSCC-12901_T1_T2/`, con `INSTALAR.sql`) | ✔ Listo para instalar. Las 14 verificaciones previas dan lo esperado en test (07-10) |
| **Ajuste por DF-SCC y PRD 3** (cajas sin sobres, `Form43` FACO delega en la base, opción 1515) | ✔ Scripts de T1, T2 y la consolidada ajustados; `FTEPROD/Form43.frm` modificado (**no compilado**: no hay VB6 en el equipo). Ver §5c |
| **Reestructura "solo cierre Y"** (doc. actualizada 07-10) | ✔ Paquete de T2 sin Z (sin RZ, `pr_procesa_z`, `pr_valida_z`, `CA_VAL_USD`), `prc_cierre_rango` y `Form43` solo Y; `Form133` revisado (sin cambios). Ver §5d |
| **Estado congelado** | ✔ Manifiesto MD5 (`docs/MANIFIESTO_FSCC-12901.md5`) y respaldos ZIP `pre-pruebas`, `post-DF` y `solo-Y` (`docs/respaldos/`). Ver §10 |
| Instalación y pruebas en test | ⏳ Pendiente. **Ningún objeto creado en la base al 06-10-2026** |
| **Prueba manual por pantallas del cierre Y (sin paquete)** | ✔ **OK el 15-10-2026 en test**: Y 1 manual (`Form19Y`), 3 sobres por `Form133` (7.583.000), F8 Y con Diferencia Real 0 y Cerrar Terminal → Cerrada. Evidencia en `docs/sql/FSCC-12901_PROC_Y/prueba_manual_Y/` y `docs/PRUEBA_Manual_Y_FSCC-12901_2026-10-15.pdf`. Ver §9 fila 36 |
| **Prueba 3: flujo de cierre del paquete en test** (Y manual -> carga en `Form133` -> `prc_cierre_automatico`) | ✔ **OK el 16-10-2026 en test** (`PROC_Y` instalado; `Form133` llama al paquete al terminar la carga). Las 4 cajas dieron lo esperado: 1 cuadre exacto (T24) cerrada, 2 DI +500 (T41) cerrada, 3 faltante −1.500 (T31) y 4 sobrante +25.000 (T44) fuera de rango y abiertas. Ver §9 filas 39–40 |
| **Revisión de cumplimiento contra la HU** (16-10) | ✔ Cumple lo central de T1 y T2, incluido el CA5 (corregido: basta con `Form7`). Quedan abiertos con negocio el resumen en pantalla con los excluidos y su motivo, y el cierre de la Z (PROC_YZ apagado). La DI automática en el Envío Contable es opcional. Ver `FSCC-12901_Revision_Cumplimiento.md` |
| **`Form43` (DF-SCC fila 12)** | ✔ **Cambio mínimo aplicado el 16-10**: la grilla "Terminal" de FACO muestra también las cajas con DR 0, como en Chile (`Or Flg_Pais$ = "FACO"` en `SubBuscarOpcion`, marcas `xintec-nruz 16-10-2026`). Sin paquete ni cierre nuevo; la v2 se descartó. ⏳ **Falta compilar y probar en test** (pendiente 1b) |

## 3. Artefactos

| Archivo | Qué contiene |
|---|---|
| [`docs/GUIA_FSCC-12901_Flujo_y_cambios.pdf`](GUIA_FSCC-12901_Flujo_y_cambios.pdf) | **Guía del flujo completo**: mapa de piezas, recorrido de una carga paso a paso, reglas de T1/T2, parámetros, estados, front, instalación, consultas útiles y bitácora del trabajo. Fuente `docs/pdf/GUIA_FSCC-12901.html`. **Empezar por aquí para entender la solución** |
| [`docs/DIAGRAMA_Flujo_PKG_FSCC-12901.pdf`](DIAGRAMA_Flujo_PKG_FSCC-12901.pdf) | **Diagramas para explicar el flujo a negocio** (10 págs., v2 multipaís; la última es un BPMN horizontal con el flujo completo). Cada paso del paquete aparece junto a la pantalla y la función VB6 equivalente: mapa general, antes/ahora, el job en 7 pasos, cálculo de la DR (Label70), árboles de decisión de T1 y T2, `Form43` (`prc_cierre_dia`) y tabla de equivalencias. Fuente `docs/pdf/DIAGRAMA_PKG_FSCC-12901.html` (SVG en línea) |
| [`docs/CC_ConsultaCuadratura_FACO.md`](CC_ConsultaCuadratura_FACO.md) | Pantalla "Consultas de Cuadratura" (`Form43`) en Colombia. Hallazgo: su botón **Cerrar Terminal no cierra nada en FACO** (B1–B11) |
| [`docs/CierreCaja_FACO_Reglas.md`](CierreCaja_FACO_Reglas.md) | **Especificación completa del cierre manual**: fórmula de la diferencia real con SQL; reglas RY-01..08 (Y, `Form3Y.CierraTerminal`) y RZ-01..10 (Z, `Form3.CierraTerminal`; **no aplican a FACO desde el 07-10**); mensajes; comportamientos D1–D12; diseño de procedimiento; matriz de pruebas |
| [`docs/FSCC-12901_Analisis.md`](FSCC-12901_Analisis.md) | Análisis de la HU: veredicto, criterios de aceptación contra lo existente, hallazgos §3.1–§3.14 (carga `Form133`, base de test, BPMN, DF-SCC, doc. actualizada y solo Y), preguntas P1–P14, propuesta técnica, casos T1–T18 y comentario para Jira |
| [`docs/FSCC-12901_consultas.sql`](FSCC-12901_consultas.sql) | Consultas de solo lectura usadas para cerrar pendientes (parámetros, doble conteo, paquete de Chile, DI); desde la 8 a la 15, las validaciones del ajuste DF-SCC (cargas, universo SIN_SOBRE, consulta de `Form43`, opción 1515, perfiles); 16–18, las del modelo solo Y (estados de Y y Z) |
| [`docs/FSCC-12957_T1_Compensacion_DI_automatica.pdf`](FSCC-12957_T1_Compensacion_DI_automatica.pdf) | Documento de T1 (18 págs.): alcance, diseño en base de datos y VB6, algoritmo, pruebas, decisiones y diagramas |
| [`docs/FSCC-12958_T2_Cierre_caja_automatico.pdf`](FSCC-12958_T2_Cierre_caja_automatico.pdf) | Documento de T2: incluye la §12 con el enfoque aprobado en base de datos |
| `docs/pdf/` | Fuentes HTML de los PDF (`estilo.css`, `img/`). Se regeneran con Edge headless (§8) |
| [`docs/sql/FSCC-12958/`](sql/FSCC-12958/README.md) | **Scripts de T2** (ver §5) |
| [`docs/sql/FSCC-12957/`](sql/FSCC-12957/README.md) | **Scripts de T1** (ver §5b) |
| [`docs/sql/FSCC-12901_T1_T2/`](sql/FSCC-12901_T1_T2/README.md) | **Flujo completo T1 + T2, listo para instalar**: objetos paso a paso (00–10, 99), `INSTALAR.sql` y README con el flujo, los objetos, los parámetros, las reglas, la operación y una matriz de 20 casos. **Es la carpeta que se instala**; las otras dos sirven para revisar cada subtarea por separado |
| [`docs/sql/FSCC-12901_POC/`](sql/FSCC-12901_POC/00_LEEME.md) | **POC con datos reales en desarrollo** (`INTRANETDE`): (A) 714 cierres Y reales de 2026 copiados de test con `02g` (solo lectura) → `02_datos_test.sql`; (B) día PRD 3 (28-08-2026) con los 486 sobres reales y cajas por escenario (P0–P7). Simula `Form133`, ejecuta T1 → T2 y compara esperado frente a obtenido; `98` reinicia y `99` limpia. Guía en `00_LEEME.html` |
| [`docs/MANUAL_Prueba_FSCC-12901_por_pantallas.pdf`](MANUAL_Prueba_FSCC-12901_por_pantallas.pdf) | **Manual de prueba por pantallas** (14 págs.): carga de 29 sobres reales (locales 6 y 13, PRD 3) por `Form133` → job (script 06) → resultado en F8 (cierre Y) y en `Form43`; 23 cajas con resultado esperado; checklist y problemas frecuentes. Fuente `docs/pdf/MANUAL_PRUEBA_FSCC-12901.html`; scripts y Excel en `docs/sql/FSCC-12901_POC/manual/` (`M1` preparar, `M2` resultados, `M9` limpiar) |
| [`docs/PRUEBA_Manual_Y_FSCC-12901_2026-10-15.pdf`](PRUEBA_Manual_Y_FSCC-12901_2026-10-15.pdf) | **Evidencia de la prueba manual del cierre Y (15-10, OK)**: datos del Excel `PRD-LIST-TEST-V2`, 5 capturas (`Form19Y`, F8 Z, F8 Y con DR 0, Y cerrada), esperado frente a obtenido y lecciones. Fuente `docs/pdf/PRUEBA_MANUAL_Y_FSCC-12901.html`; guía, Excel, capturas y scripts opcionales `P0`/`P2`/`P9` en `docs/sql/FSCC-12901_PROC_Y/prueba_manual_Y/` |
| [`docs/SIMULACION_Prueba3_FSCC-12901.pdf`](SIMULACION_Prueba3_FSCC-12901.pdf) | **Simulacion en papel de la prueba 3** (paquete `PROC_Y` llamado despues de la carga): traza trigger -> `prc_cierre_automatico` -> T1 -> T2 con lineas de codigo, escenarios A/2a/2b, estado final esperado, hallazgos H1-H6, caso 2 despues de un descuadre y como retomar. Fuente `docs/sql/FSCC-12901_PROC_Y/prueba3_simulacion/SIMULACION_Prueba3.md` (HTML en `docs/pdf/SIMULACION_PRUEBA3_FSCC-12901.html`) |
| `FTEPROD/Form43.frm` | **Front VB6** (Consultas de Cuadratura). Desde el 16-10 es el **original con un cambio de una línea**: la grilla "Terminal" de FACO incluye las cajas con DR 0 (bloque `'---INI---- xintec-nruz 16-10-2026 FSCC-12901`, §9 fila 44). Respaldo del original: `FTEPROD/Form43.frm.bak_FSCC-12901` |
| `docs/pdf/img/DF-SCC_F8_*_CC.png` | Imágenes 6 y 7 del DF (Consultas de Cuadratura de Colombia y de Chile), citadas en la §12.5 del PDF de T2 |
| `docs/pdf/img/proceso1_T1_v2.png`, `proceso2_T2_v2.png`, `form133_carga.png` | Diagramas P1/P2 actualizados y captura de `Form133` (doc. del 07-10), en las §12.6 de los PDF |
| `CLAUDE.md` §5 y §9 | Referencias a estos documentos y convenciones de scripts |
| `docs/MANIFIESTO_FSCC-12901.md5` | Huellas MD5 de scripts y documentos, congeladas antes de las pruebas (§10) |
| `docs/respaldos/FSCC-12901_2026-10-0*_*.zip` | Respaldos `pre-pruebas`, `post-DF` y `solo-Y` (§10) |

## 4. Decisiones tomadas

| Fecha | Decisión | Motivo |
|---|---|---|
| 06-10 | T2 se resuelve **en Oracle**: tabla homóloga de `VTA_FACOPRD` + trigger `AFTER INSERT` + procedimiento ejecutado por un job externo | Pedido del usuario: desacoplarlo del exe |
| 06-10 | Validaciones que dependen del perfil (103 ZZZ, 109 dólares, exención del cheque a fecha para los perfiles 8/10/12) → **flags** en `VTA_FACOPARAM` tipo 1502 | Un proceso automático no tiene perfil |
| 06-10 | `ter_cerradopor = 'PROC_CIERRE_AUTO'` | Distinguirlo del `AUTOMATICO` existente (Autopago) |
| 06-10 | ~~La Z se cierra cuando todas sus Y están cerradas, con sus validaciones propias~~ (reemplazada el 07-10) | — |
| 06-10 | Fecha de cierre en `ter_notas` (sin cambios de estructura) | Las tablas de Colombia no tienen `ter_fechacierre` |
| 06-10 | Entregable: **solo scripts**, sin ejecutar en la base | Pedido del usuario |
| 06-10 | Scripts **sin prefijo de esquema**, en ASCII; el usuario de aplicación se pide con `accept` | Portabilidad entre esquemas y ambientes |
| 06-10 | Exponer las validaciones sueltas en la especificación del paquete | Poder probarlas por separado |
| 06-10 | T1 en un **paquete propio** (`PKG_F8_FACO_COMPENSA_DI`) que **T2 invoca al inicio** de `prc_cierre_automatico`; un solo job, en el orden T1 → T2 | Respeta el diagrama general y reutiliza la cola, el trigger, el log y `fn_dif_real` |
| 06-10 | Rango propio de T1: `CA_DI_MIN` = −1000 y `CA_DI_MAX` = 20000 (tipo 1502). No se toca 1500/1501 'DI' (DI manual, −500/20000) | No cambiar lo que el analista puede ingresar en `Form38` |
| 06-10 | DI manual previa en la Y: no se toca y queda para el analista (`DI_MANUAL_PREVIA`) | Una segunda DI con `mov_rol = 0` confundiría a `Form38` |
| 06-10 | DI automática: `mov_hechopor = 'PROC_DI_AUTO'`, glosa `'COMPENSACION AUTOMATICA DI'` en `VTA_FACOCOMPDES` | Distinguirla de T2 y de la DI manual en los informes |
| 06-10 | Interruptores independientes `CA_DI_ACTIVO` (T1) y `CA_ACTIVO` (T2); el log identifica el proceso con `log_proceso` | Poder correr cada subtarea por separado |
| 06-10 | DF-SCC: `Form43` en FACO **delega en la base**: sus columnas salen de `fn_dif_caja` / `fn_compensado` / `fn_dif_real` y "Cerrar Terminal" llama a `prc_cierre_rango` | Una sola lógica de cierre (la de T2) para el proceso automático y el analista |
| 06-10 | DF-SCC: **incluir las cajas sin sobres** del mismo local y fecha de venta de la carga (vista `VTA_FACOV_CAJAS_CIERRE`, interruptor `CA_SIN_SOBRE`) | Las cajas sin movimiento nunca entran a la cola del trigger |
| 06-10 | DF-SCC: **sin pantalla de resumen** nueva; el resultado se consulta por SQL en el log | Pedido del usuario |
| 06-10 | DF-SCC: filas 34, 40, 46 y 52 **solo se documentan** | Fuera de FSCC-12901 |
| 06-10 | `prc_cierre_rango` no ejecuta T1 ni depende de `CA_ACTIVO`; `ter_cerradopor` = usuario del analista; `log_proceso = 'CC'` | Es una acción manual, como el Cerrar Terminal de Chile |
| 06-10 | Opción 1515 de FACO se crea **deshabilitada** para todos los perfiles; negocio define a quién se habilita | No existía en `VTA_FACOMENU`; dar el permiso es decisión de negocio |
| 07-10 | **FACO solo cierre Y**: el proceso, `prc_cierre_rango` y `Form43` trabajan solo con `vta_FACOtermstaty`; la Z (`vta_FACOtermstat`) no se toca. Se eliminan las reglas RZ y `CA_VAL_USD` | Pedido del usuario; `Form3Y.CierraTerminal` solo cierra la Y y en test la Z de FACO no se gestiona (10.894 en −1, 6 cerradas desde el 24-08-2026) |
| 07-10 | Disparo: **se mantiene el job externo** (cola + trigger); `Form133` no llama al SP | Decisión del usuario, aunque la HU dice "al momento de la carga" (punto abierto con negocio) |
| 07-10 | **Sin resumen en pantalla**; se consulta el log por SQL | Decisión del usuario, aunque la HU pide "emitir un resumen" (punto abierto con negocio) |
| 07-10 | `Form133.AbrirTerminal` **no se toca** (sigue reabriendo la Z) | Decisión del usuario; una Y cerrada que recibe un sobre queda `YA_CERRADA` para el analista |

## 5. T2: objetos de base de datos (`docs/sql/FSCC-12958/`)

| Script | Objeto |
|---|---|
| `00_prechecks.sql` | 9 verificaciones de solo lectura; cada una indica el resultado esperado (sin la unicidad de `termstat` desde el 07-10) |
| `01_tabla_homologa.sql` | `VTA_FACOPRD_CIERRE` (cola) + `SEQ_VTA_FACOPRD_CIERRE` |
| `02_log.sql` | `VTA_FACOLOG_CIERRE_AUTO` + `SEQ_VTA_FACOLOG_CIERRE_AUTO` (`log_proceso` T1 / T2 / CC) |
| `03_parametros.sql` | `VTA_FACOPARAM` 1502: `CA_ACTIVO`=S, `CA_VAL_CHEQ`=S, `CA_VAL_ZZZ`=N, `CA_DECIMAL`=0, `CA_DIAS`=30, `CA_SIN_SOBRE`=S. Se cambian con `UPDATE`, sin recompilar |
| `03b_vista_cajas.sql` | Vista `VTA_FACOV_CAJAS_CIERRE`: universo común de T1 y T2 (COLA + SIN_SOBRE) |
| `03c_permiso_cc.sql` | Opción 1515 "Cerrar Terminal desde Consulta Cuadratura" en `VTA_FACOMENU` / `VTA_FACORELPERMEN`, deshabilitada |
| `04_trigger.sql` | `TRG_VTA_FACOPRD_CIERRE_AI` (F8 y DOL) |
| `05` / `06` | `PKG_F8_FACO_CIERRE_AUTO`: `prc_cierre_automatico` (job), `prc_cierre_rango` (`Form43`), `fn_dif_real`, `fn_dif_caja`, `fn_compensado` (las tres exigen la Y), `pr_valida_y`, `fn_param` y las validaciones sueltas de la Y (RY-01, RY-03, RY-06). Sin Z desde el 07-10 |
| `07_grants_sinonimos.sql` | Permisos (como dueño) y sinónimos (como DBA), incluida la vista. El usuario de `[CONNECT]` del exe también los necesita |
| `08_pruebas.sql` | Comparación de la DR con la F8, validaciones sueltas, conciliación del trigger, ejecución, vista, columnas de `Form43`, `prc_cierre_rango` y 24 casos |
| `99_rollback.sql` | Reabrir las Y de una ejecución y desinstalar (incluye vista, `CA_SIN_SOBRE` y opción 1515). Ya no reabre la Z |

**Instalación:** conectado como el **dueño** de las tablas `VTA_FACO*` (en test, `INTRANETTS`). Como el cuerpo de T2 llama a T1, se usa el **orden conjunto** del README de FSCC-12957.

## 5b. T1: objetos de base de datos (`docs/sql/FSCC-12957/`)

| Script | Objeto |
|---|---|
| `00_prechecks.sql` | 9 verificaciones de solo lectura (en test coinciden las 3–8; la 1 y la 9 se completan al instalar T2) |
| `01_ajuste_log.sql` | Agrega `LOG_PROCESO` al log (idempotente). La versión actual de `FSCC-12958/02_log.sql` ya la trae |
| `02_parametros.sql` | `CA_DI_ACTIVO`=S, `CA_DI_MIN`=−1000, `CA_DI_MAX`=20000 |
| `03` / `04` | `PKG_F8_FACO_COMPENSA_DI`: `prc_compensa_di` (entrada; T2 lo llama), `fn_evalua_caja` (simulación sin grabar), `fn_estado_di` |
| `05_grants_sinonimos.sql` | `EXECUTE` y sinónimo |
| `06_pruebas.sql` | Simulación de toda la cola, T1 solo, T1 + T2 y 14 casos (criterios de aceptación de FSCC-12901) |
| `99_rollback.sql` | Apagar T1 (recomendado: no afecta T2), revertir las DI de una ejecución o desinstalar |

**Cambios hechos en FSCC-12958 para integrar T1:**
- `02_log.sql`: columna `log_proceso`;
- `06_pkg_cierre_auto_body.sql`: llamada a T1 e interruptores independientes;
- `99_rollback.sql`: desinstalar T1 antes que T2;
- `README.md`: sección de integración.

**Ajuste DF-SCC:** `04_pkg_compensa_di_body.sql` recorre la vista `VTA_FACOV_CAJAS_CIERRE` (antes, la cola); `00`, `01` y `06` actualizados.

## 5c. Front VB6: `FTEPROD/Form43.frm` (Consultas de Cuadratura, solo FACO)

Ajuste pedido por el DF-SCC, fila 12. Cambios marcados con `'CK: FSCC-12901 - …` / `'CK: FSCC-12901 - FIN`; el código anterior queda comentado. El archivo sigue en Windows-1252 con CRLF y el código nuevo es ASCII. Respaldo: `Form43.frm.bak_FSCC-12901` (idéntico al original, MD5 `0e1bfd0c…`). **No se compiló.**

| # | Lugar | Cambio |
|---|---|---|
| B1 | `Form_Load` | FACO como Chile: combo Terminal visible; "Cerrar Terminal" solo con el permiso 1515 |
| B2 | `OptionInforme_Click`, `Case Else` | En FACO el botón ya no aparece sin permiso (antes se mostraba siempre: hallazgo B4 de `CC_ConsultaCuadratura_FACO.md`) |
| B3 | `Command2_Click` | FACO + informe "Terminal" → `SubBuscarOpcionFACO` |
| B4 | `SubBuscarOpcionFACO` (nuevo) | Cierres Y con libro de ventas en el rango, local y terminal (respeta `Combo3`); **sin filas Z desde el 07-10**; columnas con `fn_dif_caja`, `fn_compensado`, `fn_dif_real`. **Muestra todas las filas, incluidas las de Dif. Real 0** |
| B5 | `Command4_Click` | FACO sale de la rama `ARG/SFCL/FACO/HTPE` (línea original comentada) y llama a `CierreTerminalFACO` |
| B6 | `CierreTerminalFACO` (nuevo) | Confirmación → `ADODB.Command` → `BEGIN PKG_F8_FACO_CIERRE_AUTO.prc_cierre_rango(?,?,?,?,?,?,?,?); END;` (fechas `yyyymmdd`, local, terminal, `LOGINUSER`) → refresca la grilla → resumen "Cerrados / No cerrados / ejecución". Errores con `SystemMsg` + `frmLogOraError` |

Diff contra el respaldo: 267 líneas nuevas (277 el 06-10; el 07-10 se quitó la parte Z) y 2 líneas originales reemplazadas, que quedan comentadas. Otros países: sin cambios de comportamiento. Los informes "F8 General" y "Gral. Tesorería" de FACO no cambian.

**16-10-2026 (tarde): v1 y v2 descartadas.** El usuario definió que `Form43` solo debe mostrar en la grilla las cajas con DR 0, como en Chile, sin paquete ni cierre.
- `Form43.frm` volvió al original más una línea: `If DiferenciaReal <> 0 Or Flg_Pais$ = "ARG" Or Flg_Pais$ = "FACO" Then` en `SubBuscarOpcion`.
- El botón "Cerrar Terminal" queda como en el original: visible para todos en FACO. Con filas en 0, cerrará esas Y con `CierraTerminalYYY` del exe.
- Lo que sigue en esta sección es historia.

**16-10-2026: aplicada la v2** (después descartada).
- Mismos bloques B1–B6, pero con `PKG_F8_CIERRE_AUTO` (el país va primero) y `prc_cierre_dia` en lugar de `prc_cierre_rango`. El cierre exige un solo día: si las fechas difieren, muestra "Seleccione Día de Cierre de Terminal".
- Marcas `'---INI---- xintec-nruz 16-10-2026 FSCC-12901: … ----` / `'---FIN---- xintec-nruz 16-10-2026 ----`.
- Detalle en `docs/sql/FSCC-12901_PROC_Y/FORM43_cambios_v2.md`.
- Lo de abajo describe la v1.

**Despliegue del front:** primero la base (si no, la consulta de `Form43` en FACO falla con "Problemas de comunicación"), permisos del paso 09 para el usuario de `[CONNECT]` y la opción 1515 habilitada a los perfiles que defina negocio. Después, compilar `f8a.exe` y subir `Gversion` (`Módulo1.bas`) junto con `vta_parametros.vta_ultversion` de **todos** los países, porque el exe es único.

## 5d. Reestructura por la documentación actualizada (07-10-2026): FACO solo cierre Y

Detalle en `FSCC-12901_Analisis.md` §3.14 y en la §12.6 de los PDF.

| Capa | Cambio |
|---|---|
| `PKG_F8_FACO_CIERRE_AUTO` (`05`/`06`, copias `04`/`07`) | Se eliminan `pr_procesa_z`, `pr_procesa_terminales`, `pr_valida_z`, `fn_msg_z_suma_y` (RZ-06), `fn_msg_y_abiertas` (RZ-07), `fn_dif_dolares` (RZ-09) y el tipo `t_terminales`. `p_cierrey` es obligatorio en `fn_dif_real`, `fn_dif_caja` y `fn_compensado` (se quitó la rama "día completo/Z" de `pr_cuadratura`, `fn_concepto_pendiente` y `fn_zzz`). `prc_cierre_automatico` y `prc_cierre_rango` solo cierran Y; el log FIN informa "Y cerradas / Y no cerradas" |
| Parámetros | `CA_VAL_USD` eliminado (solo servía para RZ-09). El rollback lo sigue borrando por si quedó de una instalación anterior |
| Soporte | `00` sin unicidad de `termstat`; `VTA_PAINT_Z` se valida solo contra `libvta`/`zzz` (RY-06); `08`/`10` sin pruebas de la Z, con los casos CA9 (T25) y "la Z no cambia" (T26); `99` sin reapertura de la Z; `02_log` sin nivel Z |
| `Form43.frm` (FACO) | `SubBuscarOpcionFACO` sin la parte `union all` de `termstat`; `CierreTerminalFACO` con textos "cierres Y" |
| `Form133.frm` / `.frx` | Revisados, **sin cambios** al 07-10. `.frx` = ícono + 4 WMF de la cabecera. FACO inserta `F8`/`EFE` con la Y de la columna 7 y reabre la Z (`AbrirTerminal`). **16-10: `Form133.frm` sí cambia**: llama al paquete al terminar la carga (ver §9, fila 39) |
| T1 (`PKG_F8_FACO_COMPENSA_DI`) | Sin cambios de lógica (ya era por Y). CA9 cubierto por el orden T1 → T2 en la misma ejecución |

**Puntos abiertos con negocio** (la HU dice algo distinto a lo decidido):
1. Ejecutar el proceso "al momento de la carga" (hoy: un job externo, a agendar justo después de la carga).
2. "Emitir un resumen" (hoy: SQL del log).
3. El diagrama P2 dice "cerrar el terminal del día" (hoy no se hace).

## 5e. v2 multipaís (13-10-2026): `docs/sql/FSCC-12901_PROC_Y/` (antes `FSCC-12901_POC_v2`)

> **15-10-2026:** la carpeta se renombró de `FSCC-12901_POC_v2` a **`FSCC-12901_PROC_Y`**, sin cambiar ningún archivo por dentro. Los comentarios internos y el traspaso a test siguen diciendo `FSCC-12901_POC_v2`, que era su nombre cuando se generaron. Es la versión **solo Y** que se traspasa a test.

A pedido del usuario se reestructuraron los objetos para que sean **multipaís**, sin tocar v1. Solo está habilitado FACO, con la misma lógica. Índice: `docs/sql/FSCC-12901_PROC_Y/00_LEEME.md` (y `.html`).

| Tema | v2 |
|---|---|
| Paquetes | `PKG_F8_CIERRE_AUTO` y `PKG_F8_COMPENSA_DI_AUTO`, genéricos: primer parámetro `p_flg_pais` (= `Flg_Pais$`) |
| Tablas | SQL dinámico con el prefijo del país (`VTA_{P}…`), binds (`DBMS_SQL` por nombre) y lista blanca de países en `pr_config` (otro país → ORA-20001; Chile solo como ejemplo comentado) |
| Universo | "Carga del día": la ejecución toma la cola (`P` → `E`), la evalúa una vez y la deja en `C`. Sin `CA_DIAS` (modelo de Chile) y sin la vista `VTA_FACOV_CAJAS_CIERRE` (`fn_universo`) |
| Objetos de FACO | Los mismos de v1 (cola con estado `E` nuevo, log, trigger, parámetros sin `CA_DIAS`, opción 1515) |
| Instalación | `INSTALAR.sql` (base sin v1) o `MIGRAR_DESDE_V1.sql` (desarrollo; no borra v1, con su vuelta atrás) |
| POC | `poc/` adaptada (`01` ya no amplía `CA_DIAS`) |
| `Form43` | Solo documentado: `FORM43_cambios_v2.md` (país como primer argumento; el botón "Cerrar Terminal" llama a `prc_cierre_dia`, un solo día) |

**Hallazgo del 13-10:** `FTEPROD/Form43.frm` está en su versión **original** (MD5 igual a `.bak_FSCC-12901`), restaurado fuera de esta sesión. La versión con los cambios de FSCC-12901 (v1) está en el respaldo `FSCC-12901_2026-10-07_solo-Y.zip`.

## 5f. PROC_YZ (15-10-2026): cierre de la Z, `docs/sql/FSCC-12901_PROC_YZ/`

Se pidió dejarlo casi listo por si negocio confirma que la Z va; el usuario de negocio lo está averiguando. Es una copia de PROC_Y con el cierre de la Z agregado y **apagado por defecto** (`CA_CIERRA_Z = N`): instalarla produce el mismo resultado que PROC_Y. Índice: `docs/sql/FSCC-12901_PROC_YZ/00_LEEME.md`.

**Revisión del exe (15-10): ¿FACO cierra la Z?** El código sí lo tiene previsto:
- **`Form3.CierraTerminal`** (`Form3.frm:3439`, candado con la F8 de la Z activa) no excluye a FACO. Tiene condiciones que nombran FACO a propósito: cheques a fecha (`:3449`, `:3455`) y Z = suma de las Y junto con todas las Y cerradas (`:3628`).
- **`Form43`** (CC), para FACO, primero cierra las Y (`CierraTerminalYYY`) y después las Z (`CierraTerminal`), en `Form43.frm:2943-2961`. No llega a cerrar porque la grilla solo muestra filas con diferencia (B1).
- **`Form20`** reabre la Z junto con las Y.
- **`Form62`** (envío a FOSO) exige que todas las Z del local estén en estado 1 o 2 (`Form62.frm:1225`). SAP (`Form159`) no lo exige.
- **En test** (§6) hay Z de FACO cerradas por `AUTOMATICO` (`PKG_F8_FACO_CIERRE_TER_PM_AP`, Autopago).

Por eso, la frase "ninguna rama FACO usa `Form3.CierraTerminal`" de `CierreCaja_FACO_Reglas.md` se corrigió el 15-10.

**Hallazgo: en FACO `Form19` (ingreso manual de la Z) borra las Y.**
- `GrabarSegundaZZZ` (`Form19.frm:788`) borra el libro de ventas `'F8'` **y `'Y'`** del terminal y día.
- `GrabaZZZ` llama a `Func_Eliminar_TermStatY` con `vcierrey` sin declarar (`Form19.frm:395`; el archivo no tiene `Option Explicit`). Como llega vacía, borra **todas** las `TERMSTATY` del terminal y día.
- No se corrige (no se pidió), pero hay que avisar a los usuarios.

Otros datos del flujo de la Z:
- `Form133.AbrirTerminal` pone la Z en 0 en cada carga, aunque esté cerrada.
- `Form19Y` no deja ingresar Y si la Z está en estado 1 o 2.
- `Form52` (cierre general) en FACO solo revisa las Y.

**Respuestas del usuario (15-10):**
1. La Z y las Y llegan por un proceso externo y también se pueden ingresar a mano.
2. No se sabe si Colombia contabiliza por FOSO o por SAP.
3. El proceso corre después de cargar el sobre.
4. Para cerrar la Z deben estar cerradas todas las Y.

**Diseño:**
- **Paso nuevo:** `pr_procesa_z` al final de `prc_cierre_automatico` (terminal-día de las Y evaluadas) y de `prc_cierre_dia` (Z abiertas del día).
- **Orden de las reglas:** bloqueo, RZ-02, RZ-07 (todas las `TERMSTATY` en 1; sin Y no cierra, salvo `CA_Z_SIN_Y`), RZ-05 (DR del día; sin libro `'F8'` da `Z_SIN_LIBVTA`), y después RZ-01, RZ-03, RZ-06 (`CA_Z_VAL_SUMA`), RZ-08 (`CA_VAL_ZZZ`) y RZ-09 (`CA_Z_VAL_DOL`).
- **Cálculo:** son las mismas consultas de la Y, convertidas con `fn_rz` (libro `'F8'` y `alias.col = :b_y` reemplazado por `1 = 1`). El SQL de la Y no cambia.
- **Sin DDL nuevo:** el log usa `log_nivel = 'Z'`.
- **Sin cambios en el exe.**
- **Instalación:** en una base con PROC_Y, `ACTUALIZAR_DESDE_PROC_Y.sql` agrega 4 parámetros y recompila `PKG_F8_CIERRE_AUTO` (se vuelve con `VOLVER_A_PROC_Y.sql`). Hay también un traspaso único YZ en `traspaso_test/`.
- **No compilado en la base.**

## 5g. Modelo 19-10-2026: DI al cargar sobres + cierre por cron, `docs/sql/FSCC-12901_COMPENSA_DI/`

En la reunión del 19-10 con el usuario de negocio cambió el modelo. PROC_Y, PROC_YZ y el traspaso a test quedan **reemplazados**.

- **Carga de sobres (`Form133`):** ya **no cierra** la Y. Por cada caja cargada, si la DR (con todos los sobres) está entre −1.000 y +20.000, inclusive y distinta de 0, registra una **DI por el valor exacto y con el mismo signo**:
  - se graba como la manual de `Form38`: regularizada, en Compensado, y la DR queda en 0;
  - observación `COMPENSACION AUTOMATICA DI` (hasta el 20-10: `COMPENSACION AUTOMATICA DIFERENCIA DE DI`);
  - la caja queda **Pendiente**.
- **Cierre:** un **cron diario** cerrará las cajas sin diferencia, igual que "Cerrar Terminal" de `Form43`. Se aborda después.
- **Decisiones:**
  - si llega otra carga, se **recalcula**: se borra la DI automática anterior y se evalúa con todos los sobres;
  - la DI manual no se toca;
  - `Form133` llama al paquete **por caja**, sin cola ni trigger;
  - el borrado de la v2 **respalda** la cola y el log (`_BK`).
- **Objetos nuevos:**
  - `PKG_F8_COMPENSA_DI_CARGA` (`prc_compensa_caja`, `fn_evalua`, `fn_dif_real`, `fn_dif_real_sin_di`). La DR es la consulta de `pr_cuadratura` de la v2 con `VTA_FACO*` fijas;
  - `VTA_FACOLOG_COMPENSA_DI` + secuencia;
  - parámetros 1502 `CA_DI_ACTIVO`, `CA_DI_MIN`, `CA_DI_MAX` y `CA_DECIMAL`.
- **Borrado de la v2:** `01_DESINSTALAR_v2.sql`, idempotente. Borra trigger, paquetes, cola, log, secuencias, parámetros `CA_%` y opción 1515, y deja intactas las DI y las Y ya grabadas.
- **Exe:** `FORM133_cambios.md`, aplicado el 19-10 y compilado por el usuario para las pruebas. Índice y orden en `docs/sql/FSCC-12901_COMPENSA_DI/00_LEEME.md`.

### Estado al 20-10-2026

- **En test (lo ejecutó el usuario):** borrado de la v2, `PKG_F8_COMPENSA_DI_CARGA` (versión solo FACO), log, parámetros y grants. Exe con `Form133` (DI por caja) y `Form43` compilados.
- **Pruebas OK** (`COMPENSA_DI/prueba_test/`, local 6, 31-08-2026): 1 DI −800 (T29), 2 DI +15.000 (T40), 3 sin DI −5.000 `FUERA_RANGO` (T31), 4 cuadre `DR_CERO` (T24). Las cajas quedan Pendiente con Dif. Real 0, y "Cerrar Terminal" de CC las cierra.
- **Glosa:** `COMPENSACION AUTOMATICA DI` (pedido del usuario tras la prueba 1). `08_cambio_glosa_20-10.sql` convierte las ya grabadas. En el body, `c_glosa_ant` = `'COMPENSACION AUTOMATICA DE DI'`, como lo dejó el usuario.
- **CC (`Form43`):** `0-TODOS` como primera opción del combo Local (FACO, perfiles 9 y 10); confirmación al cerrar con TODOS; mensaje final del cierre corregido para FACO. Respaldo `.bak_FSCC-12901_TODOS`. Probado OK por el usuario.
- **Multipaís:** `PKG_F8_COMPENSA_DI_CARGA` recibe `p_flg_pais` primero (lista blanca `pr_config`, solo FACO), con firmas sin país por compatibilidad. `Form133` envía `Flg_Pais$` (respaldo `.bak_FSCC-12901_DIPAIS`). **Sin ejecutar en test ni compilar** (pendiente 1p). La versión probada está en `COMPENSA_DI/anterior_20-10/`.
- **Respaldo vigente:** `docs/respaldos/FSCC-12901_2026-10-20_multipais.zip` (§10). `Form133.frm.bak_FSCC-12901_DI` ya no está en disco; queda en el ZIP del 19-10.

### Antes del cron: lo que ya se sabe

Pedido de negocio (19-10): un proceso **diario** que cierre las cajas (Y de FACO) **sin diferencia**, igual que "Cerrar Terminal" de `Form43`. Puntos de partida:
- **Qué hace hoy "Cerrar Terminal" (`Form43.Command4_Click`, rama FACO):** recorre la grilla de la consulta y, para cada fila no "Cerrado" ni "Pendiente MP" con Dif. Real 0, llama a `CierraTerminalYYY(fecha, local, terminal, Y)` (`Form43.frm`, unas 200 líneas de validaciones con `MsgBox` por caja). La Dif. Real de la grilla viene de `SubBuscarOpcion` (≈10 consultas por fila).
- **Validaciones del cierre de la Y:** `Form3Y.CierraTerminal` (`:2801`) y `Form43.CierraTerminalYYY`. La v2 ya las replicó en PL/SQL: `PKG_F8_CIERRE_AUTO` (`docs/sql/FSCC-12901_PROC_Y/07_pkg_cierre_auto_body.sql`, reglas en `docs/CierreCaja_FACO_Reglas.md`), probada en test el 16-10 (prueba 3). Se borró de test el 19-10, pero el código sirve de base.
- **DR:** la misma de `PKG_F8_COMPENSA_DI_CARGA.fn_dif_real(pais, ...)`, que ya es multipaís. El cron debería reutilizarla en vez de repetir la cuadratura.
- **A definir con el usuario:**
  - universo: qué fechas toma (día anterior, ventana de N días, todas las Pendiente);
  - horario y mecanismo (`DBMS_JOB` o `DBMS_SCHEDULER` en Oracle 10.2, o tarea externa), y quién lo programa (DBA);
  - si cierra solo cajas con DR 0 o también las que quedaron en 0 por la DI automática (hoy son lo mismo);
  - log y resumen (tabla de log por país, como `VTA_<pfx>LOG_COMPENSA_DI`);
  - que sea multipaís desde el inicio (mismo patrón `pr_config` / `fn_r`);
  - qué pasa con las validaciones que hoy muestran `MsgBox` (en el cron, al log como motivo).

## 5h. Cron de cierre diario (20-10-2026), `docs/sql/FSCC-12901_CIERRE_DIARIO/`

Completa el modelo del 19-10. **nhal1** llama una vez al día a `PKG_F8_CIERRE_DIARIO.prc_cierre_diario(pais, fecha)`, que cierra las cajas de esa fecha de venta que quedaron sin diferencia. **Simula "Cerrar Terminal" de Consultas de Cuadratura** (`Form43.Command4_Click` → `CierraTerminalYYY`) para todos los locales de la fecha. El índice y el detalle están en el `00_LEEME.md` de la carpeta.

- **Análisis del botón:**
  - **Universo:** `FuncStrPivote` (Y con libro de ventas `'Y'`, estado `'A'`).
  - **Candidatas:** filas con Cierre Y ≠ 0, Dif. Real (de la grilla) = 0 y estado distinto de "Cerrado".
  - **Validaciones de `CierraTerminalYYY` en FACO:**
    - RY-01: cheque a fecha (gestión = tesorería, día-terminal);
    - RY-03: conceptos SN, AF, ND, FN, NP, BF, CR, CT, CA, DP sin regularizar en la Y;
    - RY-06: ZZZ, solo con la opción 103 y con bug.
  - **Cierre:** `ter_estado = 1` y `ter_cerradopor`.
  - **Dif. Real de la grilla:** se calcula distinto que la de la F8 de la Y. Usa sobres F8+DOL, euros, todas las tarjetas, `AL` en los regularizados y no suma `CA` de `MOVDET`.
- **Decisiones del usuario (20-10):**
  - cerrar solo si **las dos Dif. Real** (F8 de la Y y grilla de CC) son 0;
  - solo cajas **Pendientes** (`ter_estado <= 0`);
  - fecha nula = **día anterior**;
  - ZZZ con el parámetro `CD_VAL_ZZZ`, **N**;
  - multipaís desde el inicio (solo FACO habilitado);
  - la programación diaria la arma el usuario en nhal1.
- **Objetos:**
  - `PKG_F8_CIERRE_DIARIO`:
    - `prc_cierre_diario`, con sobrecarga que devuelve el resumen;
    - `fn_evalua_caja`, simulación sin grabar;
    - `fn_dif_real_cc`;
  - `VTA_FACOLOG_CIERRE_DIARIO` + secuencia;
  - parámetros 1502 `CD_ACTIVO`, `CD_VAL_CHEQ` y `CD_VAL_ZZZ`.
  
  Reutiliza las validaciones de `PKG_F8_CIERRE_AUTO` (v2) y la Dif. Real de `PKG_F8_COMPENSA_DI_CARGA`. **Requiere la versión multipaís de este último** (pendiente 1p).
- **Llamada de nhal1:** `begin PKG_F8_CIERRE_DIARIO.prc_cierre_diario('FACO', null); end;`. Commit por caja; un error general se propaga para que nhal1 lo vea.
- **Exe:** el cron no necesita cambios; el botón de CC sigue funcionando igual y convive con él. **Solo para probar sin nhal1** (20-10), el botón **Salir** de `Form174` (`Command3_Click` → `EjecutaCierreDiario`, marca `xintec-nruz 20-10-2026 FSCC-12901 ... (temporal)`) llama con `ADODB.Command` a la sobrecarga con resumen: `prc_cierre_diario('FACO', to_date(vFechaPrueba,'yyyymmdd'), 'PROC_CIERRE_DIARIO', OUT x3)`, con `vFechaPrueba = "20260831"`, y muestra ejecución, cerradas y no cerradas. Respaldo `FTEPROD/Form174.frm.bak_FSCC-12901_CIERRE_DIARIO`. **Antes de producción, Salir vuelve a ser solo `Unload Me`.**
- **Prueba en test** (`prueba_test/`), con los datos existentes del local 6:
  - 31-08: T24 y T40 → `CERRADA`; T31 → `CON_DIFERENCIA`;
  - 28-08: T31 y T44 → `CON_DIFERENCIA`.
- **Estado en test (20-10, en pausa):** se instaló, pero **solo quedó la spec** de `PKG_F8_CIERRE_DIARIO` (`USER_OBJECTS` la muestra `VALID`). Al pulsar Salir en `Form174`: `ORA-04067: package body "INTRANETTS.PKG_F8_CIERRE_DIARIO" does not exist`. El usuario cree que hubo un error al pasar `04_pkg_cierre_diario_body.sql`. **No se cerró ninguna caja** (el error es anterior al proceso). Pendiente 1q: rehacer el body y revisar. **Actualización:** 1q quedó resuelto el 20-10 (el body está instalado). El 22-10 el usuario instaló en test la versión con la etapa sin venta (FCDVT-56: `03`, `04` y los parámetros `CD_SIN_VENTA` y `CD_VAL_DOL`). Solo falta el cron en nhal1 (1r).
- **Parámetros (20-10):** `CIERRE_DIARIO/02_parametros.sql` y `COMPENSA_DI/03_parametros.sql` pasaron a `INSERT ... VALUES` simples, porque la app que ejecuta los scripts no acepta `INSERT ... SELECT`. **Ya no son idempotentes**: cada uno trae al inicio una consulta de los códigos que ya existen, para omitir esos inserts.

## 6. Hechos verificados en la base de test

| Tema | Dato |
|---|---|
| Base | Oracle **10.2.0.5**, `DB_NAME = sgfnprds` (la conexión se llama "sgfinperds-test"), esquema dueño `INTRANETTS`, usuario de aplicación `UINTRANETTS` (solo sinónimos, sin `CREATE`) |
| `VTA_FACOPRD` | 29 columnas, PK `prv_techkey`, **sin triggers**. `PRV_CIERREY` NUMBER(2) NOT NULL con default 0 (0 = sin Y) |
| `VTA_FACOPARAM` | 4 columnas (`VTA_DFECHAREG` NOT NULL con default `sysdate`). 1500 'DI' = −500 y 1501 'DI' = 20000 (rango de la DI manual). Tipo 1502 libre |
| Decimales | `vta_parametros` FACO: `VTA_NUMFORMAT = '#,#0'` (`gFormat` del exe, 0 decimales), `VTA_DECROUND = 2` |
| `VTA_PAINT_Z` FACO | 53 filas, signo siempre `+`. Los 47 campos existen, cada uno en una sola tabla (`libvta` / `zzz`). Grupos ZZZ: 1, 2, 3, 6, 7 |
| `VTA_FACOCONCEPDIF` | TC, SN, BF, NP, CA, CR, CT, DI (coddif 8), DN, DP, DT, VC. No existen ND, FN, AF, AL, TB, NC ni FT. **Sin doble conteo** |
| Estados | `ter_estado` NUMBER(1); `termstat` sin duplicados; una fila de `tesor` por Y |
| Volumen | Unas 2.180 Z precreadas por día en −1 (solo 0–10 con venta); unos 359 sobres F8 por día de depósito |
| Objetos existentes relevantes | `PKG_F8_FACO_CIERRE_TER_PM_AP` (2022): cierre `AUTOMATICO` de Colombia, sobre todo Autopago; 556 Y y 117 Z. `FUN_F8_COMPENSACION_DI_DR` (2025): DR en PL/SQL, versión Chile. `PKG_F8_COMPENSACION_DI` (Chile). **Cuerpos no visibles** con el usuario de test |
| Desarrollo (`intranetde`) | Sin datos recientes ni parámetros 1500/1501 |
| Opción 1515 (Cerrar Terminal CC) | Existe en `VTA_MENU`, `VTA_SOARMENU` y `VTA_SFCLMENU`; **no** en `VTA_FACOMENU` ni en `VTA_FACORELPERMEN` → la crea `03c_permiso_cc.sql` |
| Perfiles FACO | 0, 1, 6, 7 (Tesorería Analista), 8, 9, 10, 11 (`VTA_FACOPERFILES`) |
| `ter_cerradopor` | VARCHAR2(50) en `termstat` y `termstaty`: admite `LOGINUSER` |
| Datos de test (06-10) | `VTA_FACOTERMSTATY` y libro de ventas Y hasta el 23-09-2026; `VTA_FACOPRD` solo hasta 2022 (no hay cargas recientes). Para probar la rama SIN_SOBRE hay que cargar sobres (p. ej. `PRD 3.xlsx`) |
| Consulta de `SubBuscarOpcionFACO` | Validada en test sin las funciones del paquete: el 23-09-2026 devolvía 1 Y y 7 Z; desde el 07-10 (solo Y) devuelve 1 Y |
| Desarrollo `INTRANETDE` (07-10) | Misma base `sgfnprds`; **puede crear objetos** (vía roles) y tiene los 8 objetos de FSCC-12901 VALID; **casi sin datos** FACO (hasta el 15-03-2022; 0 recaudadoras; `VTA_PAINT_Z` FACO con 47 filas frente a 53 en test). **No ve las tablas de `INTRANETTS`**. Mismas columnas que test en las 15 tablas del flujo. Los techkey de test se solapan con los de desarrollo |
| Datos reales en test (07-10) | 714 cierres Y de 2026 con libro de ventas Y (446 abiertos, 55 local-día, sobre todo el 07-01-2026), 1.024 tarjetas, **sin** sobres, tesorería ni movimientos. **Sin** cajas el 28-08-2026 (fecha de PRD 3) |
| Z de FACO (07-10) | Con fecha de venta desde el 24-08-2026: `vta_FACOtermstat` 10.894 filas en −1 y 6 cerradas; Y: 7 en −1 y 6 cerradas por `AUTOMATICO`. La Z no se gestiona en Colombia |
| `Form133` (07-10) | FACO: `insert into vta_FACOprd` con `prv_tiporec` = F8, `prv_tiposobre` = EFE, Y = columna 7; `AbrirTerminal` reabre o crea solo la Z. `Form133.frx` = ícono + 4 WMF (sin lógica) |

## 7. Pendientes

| # | Pendiente | Responsable |
|---|---|---|
| 1 | Instalar en test con `docs/sql/FSCC-12901_T1_T2/INSTALAR.sql` y ejecutar `10_pruebas.sql`. Las 14 verificaciones previas deben dar lo esperado. Caso clave: la DR del paquete debe ser igual a la "Diferencia Real" de la F8 en 10 cajas | Equipo / usuario |
| 1b | Compilar `f8a.exe` con `Form43.frm` (cambio mínimo del 16-10) y probar en test, en FACO, informe "Terminal", local 6, 28-08-2026: deben aparecer T24 y T41 con DR 0 (Cerrado) junto a T31 y T44 con −1.500 y +25.000 (Pendiente). En otro país, la grilla igual que antes | Usuario |
| 1d | Confirmar con negocio los 3 puntos abiertos del 07-10 (§5d): ejecución "al momento de la carga" frente al job, resumen en pantalla frente a SQL, y "cerrar el terminal del día" del diagrama P2 frente a solo Y | Negocio |
| 1e | **Confirmar si la Z va** (PROC_YZ, §5f). Si va: precheck 20 (que existan libros `'F8'`), prueba 12 (la DR de la Z debe ser igual a la de la F8 de la Z), y activar `CA_CIERRA_Z`. Confirmar también si se contabiliza por FOSO (`Form62` exige la Z cerrada) o por SAP | Negocio / usuario |
| 1f | ~~Prueba 3 en test con el flujo del paquete~~ **Hecha el 16-10: OK** (§9 fila 40) | — |
| 1i | ~~Prueba 4 (demostración al usuario, `prueba4_test/`)~~ **Obsoleta**: probaba el cierre al cargar, que el modelo del 19-10 eliminó (§5g) | — |
| 1j | ~~Modelo 19-10 (§5g): en test, `COMPENSA_DI/00_prechecks.sql` → `01_DESINSTALAR_v2.sql` (parte 2 como DBA) → `INSTALAR.sql` → `06` → `07_pruebas.sql` ~~ **Hecho por el usuario** (pruebas OK el 20-10) | Usuario |
| 1k | ~~Aplicar y compilar `Form133`~~ **Hecho** (compilado por el usuario para las pruebas del 20-10) | Usuario |
| 1m | ~~Ejecutar la sesión de prueba `COMPENSA_DI/prueba_test/` en test (local 6, 31-08-2026: 1 DI negativa T29, 2 DI positiva T40, 3 sin DI T31, 4 caso normal T24), con el exe compilado ~~ **Hecho el 20-10: las 4 pruebas OK** | Usuario |
| 1n | Glosa nueva (20-10): ejecutar en test `COMPENSA_DI/04` → `05` → `08_cambio_glosa_20-10.sql` y revisar con `P2` | Usuario |
| 1o | ~~Compilar `Form43` con `0-TODOS` (FACO, perfiles 9 y 10) y probar: el combo, la consulta de varios locales y la confirmación de "Cerrar Terminal", y el mensaje final de cierre ~~ **Hecho el 20-10: OK** | Usuario |
| 1p | Multipaís (20-10): ejecutar en test `COMPENSA_DI/04` → `05` (paquete `VALID`) y el bloque 8 de `07_pruebas.sql`; repetir una carga con el exe actual (firma sin país) y, después de recompilar `Form133`, con la firma nueva | Usuario |
| 1l | ~~Diseñar el cron de cierre diario~~ **Hecho el 20-10**: scripts en `sql/FSCC-12901_CIERRE_DIARIO/` (§5h) | — |
| 1q | **Resuelto el 20-10:** el log `VTA_FACOLOG_CIERRE_DIARIO` muestra la corrida del 31-08 (6/24 y 6/40 `CERRADA`, 6/31 `CON_DIFERENCIA`), así que el body está instalado. Texto original: ~~ en test falta el **body** de `PKG_F8_CIERRE_DIARIO` (`ORA-04067`, §5h). Al retomar: 1) `user_objects` de `PKG_F8_CIERRE_DIARIO`, `PKG_F8_COMPENSA_DI_CARGA`, `VTA_FACOLOG_CIERRE_DIARIO`, `SEQ_VTA_FACOLOG_CIERRE_DIARIO`; 2) consulta 2 de `00_prechecks.sql` (COMPENSA_DI multipaís, si no `PLS-00306`); 3) ejecutar `04_pkg_cierre_diario_body.sql` entero como un script; 4) `user_errors`; 5) parámetros `CD_*`; 6) P0 consulta 2 (T24 y T40 `CERRABLE`); 7) Salir de `Form174` (fecha 31-08-2026): esperado cerradas 2, no cerradas 1; P2 para el log. Si la app de scripts no acepta el body, ver qué error da~~ | Usuario |
| 1s | Ejecutar en test la prueba con 6 locales `COMPENSA_DI/prueba_test_6locales/` (30-08-2026, locales 6, 18, 25, 35, 36 y 38; 24 cajas; límites −1.000/+20.000 y ±1 fuera): P0 → 6 Y en `Form19Y` + carga por prueba → P2 → CC con `0-TODOS` | Usuario |
| 1t | Ejecutar en test la sesión `COMPENSA_DI/prueba_test2/` (10-09-2026, un local por prueba: 1 local 5 T27 DI −800, 2 local 25 T12 DI +15.000, 3 local 18 T10 sin DI −5.000, 4 local 19 T5 DR 0): P0 → por prueba F8 + `Form19Y` + carga en `Form133` → P2 → `Form3Y`/`Form4`. P0 ya da lo esperado en test (20-10) | Usuario |
| 1u | **Demostración al usuario (21-10):** sesión `COMPENSA_DI/prueba_test3/` (17-09-2026). Antes: recompilar el exe con `Form174` (`vFechaPrueba = "20260917"`). Pasos: P0 → por prueba F8 (**cambiar el local**) + `Form19Y` + `Form133` → P2 → CC con 0-TODOS → botón **Salir** de `Form174` (esperado 3 cerradas, 1 no cerrada) | Usuario |
| 1r | Programar en **nhal1** la llamada diaria `begin PKG_F8_CIERRE_DIARIO.prc_cierre_diario('FACO', null); end;` (después de la carga de sobres; definir el usuario de conexión y, si no es el dueño, ejecutar `05_grants_sinonimos.sql`) | Usuario |
| 1h | Crear en Jira la subtarea **HU-01-T3** (`Form43`, DF-SCC fila 12, solo visualización) con el texto de `FSCC-12901_T3_Form43_propuesta_Jira.md` | Usuario |
| 1g | Llevar a Jira el comentario de `FSCC-12901_Revision_Cumplimiento.md` §4 y cerrar con negocio los 3 puntos abiertos: resumen detallado en pantalla, cierre de la Z y DI automática en el Envío Contable | Usuario / negocio |
| 1c | Definir a qué perfiles FACO se habilita la opción 1515 (hoy el botón aparece para todos sin hacer nada; con el cambio queda oculto hasta habilitarlo) | Negocio |
| 2 | Obtener del DBA el cuerpo de `PKG_F8_FACO_CIERRE_TER_PM_AP` y de `PKG_F8_COMPENSACION_DI`, y saber quién ejecuta el cierre `AUTOMATICO` (convivencia con T2) | DBA |
| 3 | Decisiones de negocio abiertas: P2 (rango DI), P3, P8 (DI manual previa), P9 (envío contable), P11, P12 (Y cerrada que recibe sobres), P13 (duplicados en la carga), N2/N3 (carga todo o nada; reabrir la Y: el 07-10 se decidió no tocar `Form133.AbrirTerminal`) | Negocio (ver `FSCC-12901_Analisis.md` §4 y §3.12) |
| 4 | Definir con Contabilidad si el Envío Contable (`Form62`) debe separar la DI automática (cambio en el exe) | Contabilidad |
| 5 | ~~Revisar el Excel DF-SCC y PRD 3~~ **Hecho el 06-10** (§3.13 del análisis). Queda: confirmar si "inferior a 20.000" de la fila 57 es exclusivo (hoy inclusivo, configurable con `CA_DI_MAX`) y tratar aparte las filas 34, 40, 46 y 52 del DF (ECOMPAY en la Y, cuenta bancaria, control de bancos, fecha contable del envío a SAP) | Negocio |
| 6 | Decidir si el trigger debe impedir la carga ante un error (hoy lo ignora y hay consulta de conciliación) | Negocio / DBA |
| 7 | Opcional: hacer que `fn_param` ignore mayúsculas (`upper(trim())`) | Desarrollo |

## 8. Cómo retomar

- **Conexión a test:** requiere la **VPN Fortinet** activa. Con la VPN caída aparece `ORA-12170` (timeout).
  - Cliente: `C:\Leonardo\ClienteOracle64\sqlplus.exe`.
  - Cadena EZConnect: `<usuario>/<clave>@//10.140.2.224:1531/sgfinperds`.
  - La clave no se guarda en este documento.
- **Ver como dueño desde el usuario de aplicación** (solo para pruebas de lectura): `alter session set current_schema = INTRANETTS;`.
- **Regenerar los PDF:**
  ```
  "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" --headless --disable-gpu --no-pdf-header-footer --print-to-pdf="docs\<salida>.pdf" "file:///C:/Repositorio-f8/F8/docs/pdf/<fuente>.html"
  ```
- **Leer fuentes VB6** (Windows-1252): `iconv -f CP1252 -t UTF-8 archivo | tr -d '\r'`; buscar con `rg --encoding latin1`.
- **Referencias clave del código:**
  - `Form3Y.frm:2801` (cierre de Y) y `Form3.frm:3439` (cierre de Z; también contempla FACO, ver §5f; lo replica PROC_YZ);
  - `Form19.frm:371` (`GrabaZZZ`, ingreso manual de la Z: en FACO borra las Y) y `Form62.frm:1225` (FOSO exige la Z cerrada);
  - `Form3Y.frm:2704` (`FormateaDatos`, DR);
  - `Módulo1.bas:2630` (`StrSumCompensado`);
  - `Form133.frm:1671` (`CargarArchivo`, carga de sobres de Colombia) y `:707` (`AbrirTerminal`, reabre la Z);
  - `Form38.frm:498` (DI manual de FACO);
  - `Módulo1.bas:3777` (`InsertarRegistroMovDet`);
  - `Form45.frm` (`GrabarObs`, observación de la compensación);
  - `Form43.frm`: `SubBuscarOpcionFACO` y `CierreTerminalFACO` (buscar `CK: FSCC-12901`);
  - `Form173.frm:779` (patrón `ADODB.Command` con parámetros OUT);
  - `Módulo1.bas:1111` (`FuncBuscarOpcionCompensa`, permiso 1515 = `OpcionPermiteCerrarTerminalCC`, `Modulo2.bas:253`).

## 9. Historial de cambios (bitácora)

Todo el trabajo se hizo desde el 05-10-2026, en el orden siguiente. El proyecto no usa git: este historial, el manifiesto y los respaldos de §10 reemplazan el control de versiones.

| # | Fecha | Qué se hizo | Resultado |
|---|---|---|---|
| 1 | 05-10 | Análisis de la pantalla Consultas de Cuadratura (`Form43`) para Colombia | `docs/CC_ConsultaCuadratura_FACO.md`. Hallazgo: su "Cerrar Terminal" no cierra nada en FACO |
| 2 | 05-10 | Catálogo de reglas del cierre manual de Y y Z (`Form3Y` / `Form3`) con SQL | `docs/CierreCaja_FACO_Reglas.md` |
| 3 | 05-10 | Análisis de la HU FSCC-12901 contra el código | `docs/FSCC-12901_Analisis.md` (§1–§7) |
| 4 | 06-10 | Carga de Colombia (`Form133`), identificación y contabilización, subtareas `.doc` | `FSCC-12901_Analisis.md` §3.8–§3.10 |
| 5 | 06-10 | Consultas de solo lectura en desarrollo y test | §3.11. Hallazgos: paquete de cierre `AUTOMATICO` existente, `FUN_F8_COMPENSACION_DI_DR`, sin doble conteo, rango DI −500/20000, sin `ter_fechacierre` |
| 6 | 06-10 | PDF por subtarea | `docs/FSCC-12957_T1_…pdf`, `docs/FSCC-12958_T2_…pdf` |
| 7 | 06-10 | Diagramas BPMN contra el código | `FSCC-12901_Analisis.md` §3.12 (N1–N5), sección 11 de los PDF |
| 8 | 06-10 | **T2 en base de datos** (cola + trigger + paquete), según la decisión del usuario | `docs/sql/FSCC-12958/` |
| 9 | 06-10 | Supuestos confirmados en test (estructura, `paint_z`, decimales); DR con el compensado redondeado antes, como el exe; `00_prechecks.sql` | Scripts de FSCC-12958 ajustados |
| 10 | 06-10 | Validaciones sueltas expuestas en la especificación de T2 | `05_pkg_cierre_auto_spec.sql` |
| 11 | 06-10 | **Quitar el prefijo de esquema** `INTRANETTS.` de todos los scripts; usuario de aplicación con `accept` | Scripts portables |
| 12 | 06-10 | **T1 en base de datos**, reutilizando cola, trigger, log y `fn_dif_real`; T2 lo invoca primero | `docs/sql/FSCC-12957/`; ajustes en FSCC-12958 (`log_proceso`, llamada a T1, interruptores independientes) |
| 13 | 06-10 | **Carpeta consolidada T1 + T2** con `INSTALAR.sql` | `docs/sql/FSCC-12901_T1_T2/` |
| 14 | 06-10 | Registro completo antes de las pruebas: historial, manifiesto MD5, respaldo ZIP, PDF actualizados, `CLAUDE.md` y memoria | Este documento, §10 |
| 15 | 06-10 | **Análisis del DF-SCC y de PRD 3** y ajuste de la base: vista `VTA_FACOV_CAJAS_CIERRE` (cajas sin sobres), `CA_SIN_SOBRE`, opción 1515 de FACO (no existía), `pr_cuadratura` + `fn_dif_caja` / `fn_compensado`, `prc_cierre_rango`, `log_proceso` CC; T1 recorre la vista | Scripts de FSCC-12957, FSCC-12958 y la consolidada (03b, 03c y 14 verificaciones previas). Copias de la consolidada verificadas con `diff` |
| 16 | 06-10 | **Front VB6**: `Form43.frm` en FACO delega en la base (B1–B6), con respaldo `.bak_FSCC-12901`; PDF de T2 §12.5 y de T1 §12.5 con las imágenes del DF; manifiesto y respaldo `post-DF` | §5c, §10 |
| 17 | 06-10 | Registro final del ajuste: consultas de validación del DF-SCC guardadas en `FSCC-12901_consultas.sql` (8–15); manifiesto regenerado y respaldo `post-DF` rehecho con ese archivo | §3, §10 |
| 18 | 07-10 | **Documentación actualizada** (`Doc-Actualizado/`): HU completa (ejecución en la carga, "Colombia opera con cierre Y", CA9), diagramas P1/P2 nuevos y captura de `Form133`. Revisión de `Form133.frm` y `Form133.frx` | `FSCC-12901_Analisis.md` §3.14; imágenes en `docs/pdf/img/` |
| 19 | 07-10 | **Reestructura "solo cierre Y"**: paquete de T2 sin Z (sin RZ, `pr_procesa_z`, `pr_valida_z`, `fn_msg_z_suma_y`, `fn_msg_y_abiertas`, `fn_dif_dolares`), Y obligatoria en las funciones de DR, sin `CA_VAL_USD`; soporte, pruebas (T25 CA9, T26) y rollback ajustados; `Form43` solo Y; PDF §12.6; 14 verificaciones previas OK en test; manifiesto y respaldo `solo-Y` | §5d, §10 |
| 20 | 07-10 | **Guía del flujo y de los cambios** (PDF): cómo encajan las piezas, recorrido paso a paso y bitácora; manifiesto y respaldo `solo-Y` rehechos | §3, §10 |
| 21 | 07-10 | **Corrección de compilación** reportada por el usuario al crear el paquete en desarrollo (`INTRANETDE`): `PLS-00231: function FN_NOTA may not be used in SQL` en `pr_procesa_y`. `fn_nota` es privada y estaba dentro del `UPDATE`; ahora la nota se arma antes en la variable `v_nota`. No había otros casos en T1 ni en T2 | `FSCC-12958/06_pkg_cierre_auto_body.sql` y copia `07` |
| 22 | 07-10 | **Pruebas sin variables `&`**: en DBeaver los bloques PL/SQL con `&fecha`, `&local`… fallaban (`PLS-00103`). Cada prueba trae ahora sus valores al inicio (variables `v_*` en los bloques, `with p as (…)` en las consultas, marcados EDITAR; ejemplo 15-03-2022). La prueba de la DR tiene una variante por fecha fija y otra de 60 días con el `rownum` corregido; `prc_cierre_rango` avisa que graba | `10_pruebas.sql`, `08_pruebas.sql`, `06_pruebas.sql` |
| 23 | 07-10 | **POC en SQL** del flujo completo: `docs/sql/FSCC-12901_POC/` (01 preparar con respaldos y `CA_DIAS` temporal, 02 cargar sobres como `Form133`, 03 simular, 04 ejecutar el proceso, 05 resultados OK/DIFERENTE, 06 opcional `Form43`, 99 limpiar). No ejecutado aquí (sin acceso a `INTRANETDE`) | `00_LEEME.md` |
| 24 | 07-10 | `00_LEEME.html` del POC: las mismas instrucciones en HTML autocontenido (inicio rápido, flujo, escenarios, pasos en tarjetas, reversión, cuidados y problemas frecuentes) | `docs/sql/FSCC-12901_POC/00_LEEME.html` |
| 25 | 07-10 | **POC con datos reales** (pedido del usuario: test tiene datos pero no permite crear; desarrollo permite crear pero no tiene datos). Generador `02g` (solo lectura en test) → `02_datos_test.sql` (714 Y reales, techkey + 900.000.000); `03_dia_prd3.sql` (486 sobres reales de PRD 3 y cajas por escenario P0–P7 sobre un molde real); `04` simula `Form133`; `05` previsión; `06` ejecución con duración; `07` esperado frente a obtenido y rendimiento; `98` reiniciar; `99` limpiar. Las pruebas `10`/`08`/`06` usan como ejemplo el 28-08-2026. Validado: generación contra test y clonado dinámico con SELECT; **no ejecutado en desarrollo** (decisión: solo scripts) | `docs/sql/FSCC-12901_POC/` |
| 26 | 08-10 | **Manual de prueba por pantallas** (PDF) y carpeta `POC/manual/`: Excel de prueba recortado del `PRD 3.xlsx` real (locales 6 y 13, 29 filas); `M1` (recaudador 00562, fila FACO del usuario copiada de otra localización sin escribir claves, opción 1515, respaldo de Y, tabla de esperados), `M2` (resultados por caja), `M9` (deshacer). Hallazgos: en desarrollo el usuario no tenía FACO y no hay recaudadoras; `Form133` en FACO exige al menos 2 filas; el menú es "Estado en línea" → "Carga Manual de Sobres" | §3 |
| 27 | 13-10 | **Comparación con `Onboarding_F8.html`** (documento detallado del requerimiento). Cumple: DR con paridad F8, rango y switch, DI con signo y fecha de venta, validaciones de Cerrar Terminal, sin sobre, sin segunda DI, error por terminal y `Form43` (HU-11). Brechas a decidir con negocio o PO: **B1** cierre de la Z (el documento dice "Y y terminal-día"; nosotros solo Y), **B2** reapertura de la Y si llega una carga posterior, **B3** disparo al terminar la carga en lugar de un job. Brechas menores: B4 usuario `C_DIAUTO`, B5 columnas del log (origen, DC, compensado, monto DI) y B6 terminales sin movimiento sin Y. Sin cambios de código | `FSCC-12901_Comparacion_Onboarding.md` |
| 28 | 13-10 | **v2 multipaís** en `docs/sql/FSCC-12901_POC_v2/` (v1 intacta): paquetes genéricos `PKG_F8_CIERRE_AUTO` / `PKG_F8_COMPENSA_DI_AUTO` con `p_flg_pais`, SQL dinámico por prefijo, configuración por país (solo FACO; Chile como ejemplo comentado), universo "carga del día" (cola P → E → C, sin `CA_DIAS`), migración desde v1, POC adaptada y cambios de `Form43` documentados. Revisión estática: ASCII, sin `&`, firmas spec/body y q-quote balanceados. **No compilado en la base** (lo hace el usuario). Se detectó `Form43.frm` restaurado al original fuera de la sesión. Manifiesto regenerado y respaldo `FSCC-12901_2026-10-13_v2-multipais.zip` | §5e |
| 29 | 13-10 | **`00b_DESINSTALAR_TODO.sql`** (v2), para reinstalar desde cero en desarrollo. Es idempotente y borra lo que exista: el trigger primero; los datos de la POC y de la prueba manual (`M1`/`Form133`); los efectos del proceso según el log (reabre las Y cerradas por T2/CC y borra las DI automáticas con su glosa); los paquetes v1 y v2, la vista, la cola, el log, las secuencias, las tablas `VTA_FACOPOC_*`, los parámetros 1502 (incluidos `CA_DIAS` y `CA_VAL_USD`) y la opción 1515. Los sinónimos se borran a mano como DBA. Tiene inventario antes y después. No ejecutado aquí | `FSCC-12901_POC_v2/00b_DESINSTALAR_TODO.sql` |
| 30 | 13-10 | **v2: `prc_cierre_rango` reemplazado por `prc_cierre_dia`** (pedido del usuario). El DF-SCC fila 12 no pide un rango de fechas; el `Command4_Click` original de `Form43` tenía comentado "Seleccione Día de Cierre de Terminal"; SFCL fuerza `DTPicker2 = DTPicker1`. Nueva firma: país, fecha `yyyymmdd`, local, terminal, usuario y 3 salidas; si falta la fecha da ORA-20002. Misma lógica (reglas RY, sin T1, log CC, sin tocar la Z). Se actualizaron `04`, `07`, `10` (bloque 11), `poc/08`, `FORM43_cambios_v2.md` (valida un solo día; salidas en los índices 5, 6 y 7) y los LEEME. v1 conserva `prc_cierre_rango` | `FSCC-12901_POC_v2/` |
| 31 | 13-10 | **Documento de diagramas** para explicar el flujo de los paquetes a negocio, porque la explicación por separado (primero el paquete y después VB6) resultó confusa. Se armó un solo documento en el que cada paso del paquete aparece junto a su equivalente en el exe (pantalla y función, con número de línea verificado). Ocho secciones, SVG generados con un script Node (scratchpad) y PDF con Edge headless. Ajuste pedido por el usuario: "proceso nocturno" pasa a "**proceso automático**", que por ahora se ejecuta **al terminar el botón "Cargar Archivo" de `Form133`** (ya no se presenta como job nocturno). Se agregó la **sección 9**: el flujo completo en BPMN, en una página A4 horizontal, al estilo de `Requeriemintos-FSCC-12901/Flujo general de la historia.png`. Tiene carriles Analista / F8 / proceso automático / T1 / T2 / Datos, decisiones "¿Carga correcta?", "¿Algún interruptor activo?", "¿T1 activa?", "¿T2 activa?" y "¿Hay pendientes?", y siete almacenes de datos. La llamada desde `Form133` figura como pendiente | `DIAGRAMA_Flujo_PKG_FSCC-12901.pdf` |
| 32 | 14-10 | **Archivo de traspaso a test (v2)**, pedido del usuario. `TRASPASO_TEST_FSCC-12901_v2.sql` es un script único que se ejecuta como `INTRANETTS`. Tiene las partes 0 (prechecks), 1 (cola, log, secuencias, parámetros 1502 y opción 1515), 2 (paquetes), 3 (trigger, al final), 4 (validación: 9 objetos VALID), 5 (grants y sinónimos completados para `UINTRANETTS`; los sinónimos los crea un DBA) y 6 (job `DBMS_JOB`, comentado). Las secciones son copia exacta de los scripts 00–08 (verificado con `diff`). Lo único agregado es la opción 1515 habilitada (−1) para los perfiles 7 y 9. Se acompaña con `ROLLBACK_TEST_FSCC-12901_v2.sql` (apagar, revertir una ejecución, desinstalar) y `LEEME.md`. **No ejecutado en la base** | `FSCC-12901_POC_v2/traspaso_test/` |
| 33 | 15-10 | **Análisis del flujo de la Z en el exe** (solo lectura). Hallazgos: `Form3.CierraTerminal`, `Form43` y `Form20` contemplan FACO; `Form62` (FOSO) exige la Z cerrada; `Form19` en FACO borra las Y del libro de ventas y todas las `TERMSTATY` (`vcierrey` sin declarar); `Form133` reabre la Z en cada carga; `Form19Y` no deja ingresar Y con la Z cerrada | §5f |
| 34 | 15-10 | **Carpeta `FSCC-12901_POC_v2` renombrada a `FSCC-12901_PROC_Y`** (pedido del usuario; solo el nombre, contenido sin cambios). Se actualizaron las referencias de este índice, del diagrama HTML, del manifiesto y de la memoria | §5e |
| 35 | 15-10 | **PROC_YZ**: copia de PROC_Y con el cierre de la Z (`pr_procesa_z`, `pr_valida_z`, `fn_z_suma_y`, `fn_dolares_z`, `pr_y_cerradas`, `fn_rz`; `p_cierrey` nulo = Z), 4 parámetros (`CA_CIERRA_Z` = N, `CA_Z_SIN_Y`, `CA_Z_VAL_SUMA`, `CA_Z_VAL_DOL`), prechecks 15–20, pruebas 12–15, rollback y desinstalador con la Z, `ACTUALIZAR_DESDE_PROC_Y.sql` / `VOLVER_A_PROC_Y.sql` y traspaso único YZ (generado desde el de PROC_Y; cambian las partes 0, 1c, 2a y 2d). Sin DDL nuevo ni cambios en el exe. Revisión estática: ASCII, firmas spec/body. **No compilado en la base** | `docs/sql/FSCC-12901_PROC_YZ/` |
| 36 | 15-10 | **Prueba manual "camino feliz" del cierre Y por pantallas: OK** (base de test, exe 3.4.9, sin paquete; reemplaza la del 14-10). Local 6, terminal 27, 28-08-2026: `Form19Y` con N° de Y 0, que al validar pasó a 1 (máximo + 1), EFECTIVO y BOLETAS 7.583.000 → `Form133` cargó 3 sobres EFE del Excel `PRD-LIST-TEST-V2` (Y 1) → F8 Y (doble clic en la Y 1 de la Z) con Dif. de Caja 0, Compensación 0 y **Diferencia Real 0** → primer candado del toolbar (Key `Cerrar`) → **Cerrada**. La Z quedó Pendiente con diferencia 7.583.000 (esperado en FACO). Hallazgos: `Form19Y.Oklt` valida la terminal con la fecha de la F8 abierta; `Form133` detecta duplicados por sobre + fecha (sin local). Los datos quedan en test (limpieza con `P9`, la ejecuta el usuario). Manifiesto regenerado y respaldo `prueba-manual-Y` | `FSCC-12901_PROC_Y/prueba_manual_Y/`, `PRUEBA_Manual_Y_FSCC-12901_2026-10-15.pdf` |
| 37 | 15-10 | **Prueba 3: simulación en papel del paquete PROC_Y después de la carga** (sin ejecutar nada). Excel `PRD-LIST-TEST-V3` (local 6, terminal 29, 28-08-2026, Y 1, 3 sobres, 8.344.000). Traza con línea de código de trigger → `prc_cierre_automatico` → T1 → T2. Escenario A (Y = sobres): T1 DR_CERO y T2 CERRADA_Y. Escenario B (Y con 500 menos): T1 DI_REGISTRADA +500 (`MOVDET` DI regul S, `COMPDES`) y T2 CERRADA_Y; en la F8, Dif. de Caja 500, Compensación 500 y DR 0. Sin errores de lógica. Hallazgos: **H1** `CA_SIN_SOBRE = S` incluye todas las Y abiertas del local-día (riesgo de tocar Y reales en test), H2 nada llama al paquete al terminar `Form133` (ejecutar a mano o por job), H3 el orden Y → carga importa (una Y ingresada después no vuelve a la cola), H4 trigger `when others null`, H5 `PKG_F8_FACO_CIERRE_TER_PM_AP` (Autopago) | `FSCC-12901_PROC_Y/prueba3_simulacion/SIMULACION_Prueba3.md` |
| 38 | 15-10 | **Prueba 3 lista para retomar en test** (el usuario pasa los objetos de `PROC_Y` a test). Se agrego a la simulacion: §10 plan con 3 cajas en terminales distintas (A feliz: terminal 29, Excel V3, 8.344.000 -> DR_CERO / CERRADA_Y; 2a: Y 500 menos -> DI +500 / CERRADA_Y; 2b: Y 1.500 mas -> FUERA_RANGO / CON_DIFERENCIA, queda abierta), ejecucion manual `begin PKG_F8_CIERRE_AUTO.prc_cierre_automatico('FACO'); end;`; §11 caso 2 tras un descuadre (el usuario compensa o corrige la Y y cierra con candado o CC; la cola queda C y no se reintenta sola; si la caja vuelve a entrar ya cerrada, T1 y T2 dan YA_CERRADA sin cambios ni DI; DI manual previa -> DI_MANUAL_PREVIA; brecha B2); §12 como retomar. PDF, manifiesto y respaldo `prueba3-simulada` | `prueba3_simulacion/`, `SIMULACION_Prueba3_FSCC-12901.pdf` |
| 39 | 16-10 | **Prueba 3 en test: archivos y llamada desde `Form133`** (comentario `xintec-nruz 16-10-2026`). (a) **4 pruebas distintas**, local 6, 28-08-2026, Y 1: 1 OK cuadre exacto (T29, 8.344.000, el V3 renombrado), 2 OK DI en rango (T40, sobres 5.856.000, Y 5.855.500 -> DI +500 y cierre), 3 NO OK faltante (T31, 2.670.000 en 2 sobres, Y 2.671.500 -> DR -1.500), 4 NO OK sobrante (T44, 875.000 en 2 sobres, Y 850.000 -> DR +25.000). Excel de carga y resumen 2x2 (`Prueba-Y_Resumen.xlsx`: bloque por prueba con lo que hay que digitar en `Form19Y` y lo esperado) en `prueba3_test/`. Las pruebas 3 y 4 llevan 2 sobres porque `Form133.Command4_Click` en FACO exige `Grid2.Rows > 2` (con 1 sobre responde "No existen Registros a Cargar"); los sobres 5998299901 y 6925299902 son números de prueba que no están en PRD 3. (b) **Brecha B3 / H2 resuelta en el front:** `Form133.CargarArchivo`, si `Flg_Pais$ = "FACO"` y se insertó al menos un sobre, llama a la sub nueva `EjecutaCierreAutomaticoFACO`: `ADODB.Command` `BEGIN PKG_F8_CIERRE_AUTO.prc_cierre_automatico(?); END;` con `'FACO'` (usuario por defecto `PROC_CIERRE_AUTO`) y después muestra la fila FIN/INACTIVO/ERROR de `VTA_FACOLOG_CIERRE_AUTO`. Si falla, `frmLogOraError` avisa que los sobres quedaron cargados (la cola los conserva). Otros países sin cambios. Respaldo `FTEPROD/Form133.frm.bak_FSCC-12901` (MD5 `26eeeb01…`); diff +67 líneas, CP1252 + CRLF. **No se compiló.** Requiere `execute` sobre el paquete y `select` sobre el log para el usuario de `[CONNECT]` (paso 09). Manifiesto y ZIP pendientes hasta cerrar la prueba. **Primera ejecución en test (16-10):** `Form133` cargó la T29 y llamó al paquete, que respondió `INACTIVO` porque los parámetros 1502 `CA_ACTIVO` y `CA_DI_ACTIVO` no estaban en S. Se activaron y se reprocesó con `prueba3_test/P3_activar_y_reprocesar.sql`, pero la prueba 1 quedó mal. **Se repite la prueba 1 con data nueva:** T24, sobres 6608295620 (2.000.000, de PRD 3) y 6608299903 (342.000, de prueba), total 2.342.000 = EFECTIVO y BOLETAS de la Y (`Prueba-1-OK-Cuadre_T24.xlsx` y el resumen actualizado). La T29 queda descartada. **Prueba 1 OK (11:20):** el mensaje fue "Sobres de la carga: 5 / Cierres Y evaluados: 2 / Y cerradas: 2 / Y no cerradas: 0": el paquete toma TODAS las filas P de la cola, y los 3 sobres de la T29 seguian en P desde el `INACTIVO` de las 09:52; se cerraron la Y 1 de la T24 y tambien la de la T29 (ambas DR 0, `PROC_CIERRE_AUTO`). La etiqueta "Sobres de la carga" cuenta la cola, no solo el ultimo Excel. **Prueba 2 movida a la T41:** en test la T40 ya tenia cargados los sobres 1354295629 y 1421295630 (5.856.000) y las Y 1 y 2 cerradas por un usuario; la T41 (tipo 0) no tiene sobres, Y ni Z el 28-08-2026. Sobres nuevos de prueba 4141295641 (1.934.000) y 4141299904 (3.922.000), sin cambios en montos ni en lo esperado (`Prueba-2-OK-DIenRango_T41.xlsx`, resumen actualizado). *Nota (16-10, después): "No se compiló" vale para el momento de la edición; luego el usuario compiló el exe con este `Form133` y lo usó en las pruebas de test* | `FTEPROD/Form133.frm`, `FSCC-12901_PROC_Y/prueba3_test/` |
| 40 | 16-10 | **Prueba 3 en test: OK** (informado por el usuario). Las 4 cajas del local 6, 28-08-2026, Y 1, cargadas por `Form133` con el proceso llamado al terminar la carga, dieron lo esperado: **1** T24 cuadre exacto → DR 0, CERRADA_Y; **2** T41 Y 500 menos que los sobres → DI +500 (`PROC_DI_AUTO`, glosa fija) y CERRADA_Y; **3** T31 faltante → DR −1.500, FUERA_RANGO, sin DI, Y abierta; **4** T44 sobrante → DR +25.000, FUERA_RANGO, sin DI, Y abierta | `prueba3_test/` |
| 41 | 16-10 | **Revisión de cumplimiento** contra la HU y las subtareas (exportaciones del 07-10; Jira no se consultó en línea). Cumple: DR, rango inclusivo y parametrizable, DI con signo y fecha de venta, identificación (`PROC_DI_AUTO` + glosa, visible en `Form7`), sin sobre, sin segunda DI, validaciones de Cerrar Terminal, CA9, ejecución en la carga. Abiertos: resumen con excluidos y su motivo (hoy solo totales en el `MsgBox`; el detalle está en el log), cierre de la Z (PROC_YZ apagado), DI automática en el Envío Contable, `Form43` (DF-SCC fila 12) sin aplicar. Decisión del usuario: **no ampliar el `MsgBox`**, solo documentar | `FSCC-12901_Revision_Cumplimiento.md` |
| 42 | 16-10 | **Corrección del CA5 y `Form43` v2 aplicado** (pedido del usuario). (a) CA5 pasa a ✔: dice "Informe de Diferencias **o** Envío Contable", y `Form7` ya muestra la glosa. El Envío Contable queda como mejora opcional (`Form159` agrupa por operación). (b) `FTEPROD/Form43.frm` = v1 del ZIP `solo-Y` + cambios de `FORM43_cambios_v2.md` (país primero en `fn_dif_caja` / `fn_compensado` / `fn_dif_real`, `prc_cierre_dia` de un solo día, log `VTA_<pais>LOG_CIERRE_AUTO`). Las marcas `'CK: FSCC-12901` se cambiaron por `'---INI---- xintec-nruz 16-10-2026 FSCC-12901: … ----` / `'---FIN---- xintec-nruz 16-10-2026 ----`, como en `Form133`. Edición binaria con Perl (CP1252 + CRLF, 5.297 líneas, todas CRLF); diff contra `.bak_FSCC-12901`: 267 líneas nuevas y 2 originales comentadas; sin restos de `PKG_F8_FACO_CIERRE_AUTO` ni `prc_cierre_rango`. MD5 `de76a2c3…`. **No compilado** (no hay VB6 en el equipo). Comentario para Jira con un 4.º punto (`Form43`) | `FTEPROD/Form43.frm`, `FSCC-12901_Revision_Cumplimiento.md`, `FORM43_cambios_v2.md` |
| 43 | 16-10 | **Propuesta de subtarea HU-01-T3** para `Form43`. Antes, la grilla de FACO solo mostraba las Y con DR distinta de 0 (`.bak`, `:1129`, hallazgo B1); ahora muestra todas, incluidas las de DR 0, y el botón cierra las de DR 0. Como el DF-SCC fila 12 no está en el texto de FSCC-12901/12957/12958, se redactaron la descripción, las reglas y 8 criterios de aceptación para crear la subtarea en Jira (pendiente 1h) | `FSCC-12901_T3_Form43_propuesta_Jira.md` |
| 44 | 16-10 | **`Form43`: cambio mínimo, v2 descartada** (definición del usuario: "solo la grilla de CC debe incorporar los que tengan diferencia 0 como en Chile; no debe llamar al pkg ni cerrar"). `Form43.frm` volvió al original (`.bak_FSCC-12901`) más una línea en `SubBuscarOpcion` (`:1129`), que es la ruta de FACO desde `Command2_Click`: `If DiferenciaReal <> 0 Or Flg_Pais$ = "ARG" Or Flg_Pais$ = "FACO" Then`, con la original comentada y marcas `xintec-nruz 16-10-2026`. Diff de 4 líneas; CP1252 + CRLF (5.033 líneas). MD5 `8b4f6e87…`. El botón "Cerrar Terminal" no se tocó (decisión del usuario): con filas en 0 cerrará esas Y con `CierraTerminalYYY`. T3, revisión y `FORM43_cambios_v2.md` ajustados. La v2 queda en el ZIP `form43-v2`. **No compilado** | `FTEPROD/Form43.frm` |
| 45 | 19-10 | **`CLAUDE.md` al día** (revisión con `/init`): §5 describía `Form43` como "cambio no aplicado, original"; ahora dice que es el original más una línea (DR 0 en FACO, `xintec-nruz 16-10-2026`, sin compilar) y que v1/v2 se descartaron. §9 suma FCDVT-14 a los requerimientos vigentes. Sin cambios en `FTEPROD` ni en la base. Manifiesto regenerado y respaldo `claude-md` | `CLAUDE.md` |
| 46 | 19-10 | **Prueba 4 en test (demostración al usuario)**: repite las 4 cajas de la prueba 3 con los mismos montos y lo mismo esperado. Cambian las terminales (T25 cuadre, T42 DI +500, T32 faltante −1.500, T45 sobrante +25.000) y la fecha de venta, **29-08-2026**, para que las Y abiertas de la T31 y la T44 del 28-08 no vuelvan a entrar por `CA_SIN_SOBRE = S` (H1). Sobres nuevos de prueba (terminal + `0829` + correlativo). Los Excel son copia de `prueba3_test` con solo la terminal, el sobre y la fecha cambiados. `P0_prechecks.sql` revisa parámetros, cola P/E, cajas libres, `ter_tipo = 0` y H1, y su consulta 9 lista las terminales libres; `P2_resultados.sql` muestra log, Y, DI y cola. **Pendiente de ejecutar** (P0 primero) | `FSCC-12901_PROC_Y/prueba4_test/` |
| 47 | 19-10 | **Cambio de modelo** (reunión con el usuario de negocio). La carga de sobres ya no cierra la Y: solo registra la DI automática por la DR exacta si está en [−1.000, +20.000]. Observación `COMPENSACION AUTOMATICA DIFERENCIA DE DI`; la caja queda Pendiente. El cierre pasa a un cron diario (después). Decisiones: recalcular en una recarga, no tocar la DI manual, `Form133` llama por caja y respaldo de cola y log al borrar. Carpeta nueva `FSCC-12901_COMPENSA_DI/`: `00_prechecks`, `01_DESINSTALAR_v2` (borra lo traspasado el 14-10 con respaldo `_BK`; idempotente), log `VTA_FACOLOG_COMPENSA_DI`, parámetros 1502, `PKG_F8_COMPENSA_DI_CARGA` (la DR es la de `pr_cuadratura` v2), grants, pruebas A–G, rollback, `INSTALAR.sql` y `FORM133_cambios.md` (no aplicado). PROC_Y, PROC_YZ y `prueba4_test` quedan reemplazadas. **Nada ejecutado ni compilado** | `FSCC-12901_COMPENSA_DI/` |
| 48 | 19-10 | **`Form133` aplicado** (los objetos nuevos ya se están pasando a test). Respaldo `FTEPROD/Form133.frm.bak_FSCC-12901_DI` (MD5 `d68736f8…`, incluye el cambio del 16-10); el nuevo tiene MD5 `5471c124…`, en CP1252 + CRLF, con 117 líneas más y sin borrar nada. `CargarArchivo` junta las cajas FACO con sobres insertados y Y > 0. La llamada a `EjecutaCierreAutomaticoFACO` y esa sub quedan comentadas. La nueva `EjecutaCompensaDIFACO` llama a `PKG_F8_COMPENSA_DI_CARGA.prc_compensa_caja` por caja (`ADODB.Command`, salidas `adVarChar`), sigue con la siguiente si una falla y muestra un resumen (con DI / sin DI / detalle). **Sesión de prueba** `COMPENSA_DI/prueba_test/`: local 6, 31-08-2026, Y 1, T24 DR 0, T27 +500, T29 −1.000, T31 −5.000 fuera de rango, T40 +15.000, T41 +20.000, T44 +25.000 fuera de rango, más la recarga de la T27 (+300 → DI 800). Incluye `Carga-1` (14 sobres), `Carga-2` (2), el resumen de 3 hojas, P0, P2 y P9. **No compilado** | `FTEPROD/Form133.frm`, `COMPENSA_DI/prueba_test/` |
| 49 | 19-10 | **`prueba_test` rehecha con el formato de `prueba4_test`** (pedido del usuario): un Excel por prueba y un resumen por bloques 2x2 como `Prueba-Y_Resumen.xlsx`. Cuatro pruebas, local 6, 31-08-2026, Y 1: **1** OK DI negativa (T29, sobres 2.670.000, Y 2.670.800 → DI −800); **2** OK DI positiva (T40, 875.000 / 860.000 → DI +15.000); **3** NO OK sin DI (T31, 2.670.000 / 2.675.000 → −5.000, `FUERA_RANGO`); **4** caso normal (T24, 2.342.000 / 2.342.000 → `DR_CERO`). Todas quedan Pendiente. Se quitaron la carga de 7 cajas y la recarga; la recarga sigue en `07_pruebas.sql` (G). P0, P2 y P9 quedan con las 4 terminales | `COMPENSA_DI/prueba_test/` |
| 50 | 19-10 | **Manifiesto y respaldo del modelo COMPENSA_DI.** Se regeneró `docs/MANIFIESTO_FSCC-12901.md5`: suma `sql/FSCC-12901_COMPENSA_DI/` (con `prueba_test/`), `PROC_Y/prueba4_test/` (obsoleta), `docs/sql/CLAUDE.md` y `FTEPROD/Form133.frm.bak_FSCC-12901_DI`, y actualiza `CLAUDE.md`, `Form133.frm` y los índices. Respaldo `docs/respaldos/FSCC-12901_2026-10-19_compensa-di.zip` (§10). Nada ejecutado en la base ni compilado | `MANIFIESTO_FSCC-12901.md5`, `respaldos/` |
| 51 | 20-10 | **Prueba 1 en test OK** (T29, DI −800, Dif. Real 0, Pendiente; CC permite cerrar la Y). A pedido del usuario, la observación de la DI pasa a `COMPENSACION AUTOMATICA DI`: `04` (`c_glosa`), `05` (`c_glosa_ant` = glosa del 19-10, que una recarga también borra), `08_cambio_glosa_20-10.sql` nuevo (actualiza las observaciones ya grabadas), `99_rollback`, `07_pruebas`, `prueba_test/P2`, `P9` (borra ambas glosas), `LEEME` y `Prueba-DI_Resumen.xlsx`. Sin ejecutar en la base. |
| 52 | 20-10 | **CC con "TODOS LOS LOCALES" (FACO).** Pedido del usuario: en `Form43` el combo Local tiene `0-TODOS LOS LOCALES` para los perfiles 9 (Administrador) y 10 (Super Administrador), solo FACO (`LeeLocales`). La consulta ya aceptaba el local 0 sin filtro (`FuncStrPivote`). "Cerrar Terminal" con TODOS pide confirmación con el número de cajas con Dif. Real 0 y de locales y el rango de fechas; sin tope de rango. Respaldo `FTEPROD/Form43.frm.bak_FSCC-12901_TODOS` (MD5 8b4f6e871a1aafe6b4e1eb6fbad7e2cb); nuevo MD5 a3196fe01170214a2109cc1beac6cd95; +53 líneas, solo agregadas, ASCII, CRLF. Sin compilar. También se corrigió el mensaje final de "Cerrar Terminal" en FACO: la rama no incrementaba `X` y siempre decía "No hay Terminales que Cumplan..."; ahora cuenta las filas "Cerrado" de la grilla antes y después del cierre (una caja que `CierraTerminalYYY` rechaza no cuenta) y, si cerró alguna, muestra "Proceso de Cierre Terminal Ejecutado Exitosamente". | **Ajuste del mismo día:** a pedido del usuario la opción se llama `0-TODOS` y va **primera** en el combo. El usuario movió el bloque antes del `For` que carga los locales desde el IDE de VB6, que además normalizó `index` → `Index` y el `Format` de los DTPicker (sin efecto). Después se cambió el nombre en binario. MD5 final de `Form43.frm`: ef03a18643b1b5b185af1bd173184a60 (reemplaza a a3196fe0...).
| 53 | 20-10 | **`PKG_F8_COMPENSA_DI_CARGA` multipaís.** Pedido del usuario, después de que las pruebas 1 a 4 salieran bien en test: misma lógica, pero el paquete recibe el país (`p_flg_pais` = `Flg_Pais$`) primero en sus cuatro rutinas públicas. Se reutiliza el patrón de la v2 (`pr_config` con lista blanca, `fn_r` con marcas `{P}`, `{EST}`, `{NIVEL}`, `{TMIN}`, `{TMAX}`, `{USD}`, `{SEQMOV}`, `{FVEN}`, y `fn_sql_nums` con DBMS_SQL); solo FACO habilitado, con un ejemplo comentado para otro país. Decisión del usuario: **sobrecarga**, las firmas sin país se mantienen y equivalen a FACO, así que el exe ya compilado sigue funcionando. La versión probada quedó en `COMPENSA_DI/anterior_20-10/`. `Form133.EjecutaCompensaDIFACO` envía `Flg_Pais$` como primer parámetro y lee las salidas en 6, 7 y 8 (respaldo `Form133.frm.bak_FSCC-12901_DIPAIS`, MD5 7f868d39c0a4b0363db7780dd1b6b418; nuevo 00abac131ef669946bfd9be12b8fe38f; sin compilar). `07_pruebas` (bloque 8 nuevo) y `P2` usan la firma con país. Sin ejecutar en la base. |
| 54 | 20-10 | **Manifiesto y respaldo del estado multipaís.** Se regeneró `docs/MANIFIESTO_FSCC-12901.md5`: suma `COMPENSA_DI/08_cambio_glosa_20-10.sql`, `COMPENSA_DI/anterior_20-10/`, `FTEPROD/Form43.frm.bak_FSCC-12901_TODOS` y `FTEPROD/Form133.frm.bak_FSCC-12901_DIPAIS`, y saca `Form133.frm.bak_FSCC-12901_DI`, que ya no está en disco (sigue en el ZIP del 19-10). Respaldo `docs/respaldos/FSCC-12901_2026-10-20_multipais.zip` (ver §10). |
| 55 | 20-10 | **Documentación previa al cron.** Encabezado y §2 con el estado vigente; §5g con "Estado al 20-10" y "Antes del cron: lo que ya se sabe" (qué hace hoy "Cerrar Terminal", validaciones a replicar desde `PKG_F8_CIERRE_AUTO` de la v2, DR desde `fn_dif_real`, preguntas para el usuario); pendientes 1j, 1k, 1m y 1o cerrados (pruebas OK); 1l marcado como próximo. `00_LEEME.md` de COMPENSA_DI y `CLAUDE.md` al día. Memoria del asistente actualizada. Manifiesto y respaldo `pre-cron` regenerados. |
| 56 | 20-10 | **Cron de cierre diario.** Análisis de "Cerrar Terminal" de CC (`Form43.Command4_Click`, `CierraTerminalYYY`, `FuncStrPivote`, `SubBuscarOpcion`/`StrSumCompensado`): la Dif. Real de la grilla se calcula distinto que la de la F8 de la Y. Decisiones del usuario: las dos Dif. Real en 0, solo Pendientes, fecha nula = día anterior, ZZZ por parámetro apagado. Carpeta nueva `sql/FSCC-12901_CIERRE_DIARIO/`: `PKG_F8_CIERRE_DIARIO` multipaís (FACO), log `VTA_FACOLOG_CIERRE_DIARIO`, parámetros `CD_*`, prechecks, pruebas, rollback y `prueba_test/` con los datos existentes (31-08 y 28-08). Lo llamará nhal1. Requiere `PKG_F8_COMPENSA_DI_CARGA` multipaís. Sin ejecutar en la base. Manifiesto regenerado y respaldo `FSCC-12901_2026-10-20_cierre-diario.zip`. |
| 57 | 20-10 | **Guía de prueba del cierre diario (PDF).** `docs/PRUEBA_Cierre_Diario_FSCC-12901.pdf` (fuente `docs/pdf/PRUEBA_CIERRE_DIARIO_FSCC-12901.html`): qué se prueba, instalación con controles, datos existentes (31-08 y 28-08), pasos P0, P1 (A a D), P2, verificación en CC, P9, pruebas negativas, qué hacer si algo falla y programación en nhal1, con la columna «Obtenido» para completar. Se agregó al manifiesto y al ZIP `cierre-diario`. |
| 58 | 20-10 | **Primera prueba del cierre diario en test (en pausa).** Sin acceso a nhal1, el botón Salir de `Form174` llama temporalmente al paquete con FACO y fecha fija 31-08-2026 (respaldo `Form174.frm.bak_FSCC-12901_CIERRE_DIARIO`, §5h). `CIERRE_DIARIO/02` y `COMPENSA_DI/03` pasaron a `INSERT ... VALUES` (la app de scripts no acepta `INSERT SELECT`). Al pulsar Salir: `ORA-04067`, porque en test solo está la spec del paquete; no se cerró nada. Queda en pausa hasta que el usuario revise el paso del body (pendiente 1q). Manifiesto **no** regenerado: `Form174.frm` y los dos scripts de parámetros ya no coinciden con él. |
| 59 | 20-10 | **Prueba con 6 locales por archivo.** El usuario vio `INVALID` en `USER_OBJECTS` para `PKG_F8_COMPENSA_DI_CARGA`: conectado como `uintranetts` esa fila es el **sinónimo**, que queda inválido al recompilar el paquete y se revalida en el primer uso. El paquete de `INTRANETTS` está `VALID` (spec y body con último DDL 20-10 14:56:29) y sin errores. En CC, local 6 del 31-08-2026, "Cerrar Terminal" cerró la T24 y la T40 (Dif. Real 0) y dejó Pendiente la T31 (−5.000). Carpeta nueva `COMPENSA_DI/prueba_test_6locales/`, con las mismas 4 pruebas en 6 locales (6, 18, 25, 35, 36, 38) el **30-08-2026**, fecha sin datos FACO en test. Montos variados para probar los límites: T29 −1…−1.000, T40 +1…+20.000, T31 −1.001/−5.000/−50.000/+20.001/+25.000/+100.000 y T24 0. Incluye 4 Excel de carga (12 sobres cada uno, generados desde la plantilla de `prueba_test`), `Prueba-DI_Resumen.xlsx` (Resumen, Pasos y Sobres), P0 (con la consulta 1b del paquete del dueño), P2, P9 y `LEEME.md`. P0 y P2 se corrieron en test en solo lectura: todo libre y sin errores de sintaxis. |
| 60 | 20-10 | **Manifiesto y respaldo `prueba-6locales`.** Se regeneró `docs/MANIFIESTO_FSCC-12901.md5` con la misma lista que el del cierre diario, más los 9 archivos de `COMPENSA_DI/prueba_test_6locales/` y `FTEPROD/Form174.frm`, `Form174.frx` y `Form174.frm.bak_FSCC-12901_CIERRE_DIARIO`. Así se absorben también los cambios de las filas 58 y 59 (`CIERRE_DIARIO/02`, `COMPENSA_DI/03`, los índices y `CLAUDE.md`). Respaldo `docs/respaldos/FSCC-12901_2026-10-20_prueba-6locales.zip` (§10). **Ajuste del mismo día**, a pedido del usuario: `Prueba-DI_Resumen.xlsx` trae, debajo de cada prueba, la tabla «Digitar en Form19Y» (local, terminal, fecha, N° de Y 0, EFECTIVO, BOLETAS y resto en 0). Se regeneraron el manifiesto y el ZIP. **Segundo ajuste:** el usuario prefirió el formato de `prueba_test`, así que la hoja Resumen volvió a los bloques 2x2 de 3 columnas. Cada bloque trae los datos, una línea por local con el EFECTIVO = BOLETAS a digitar (más los sobres y la DR) y el resultado esperado resumido. Se regeneraron otra vez el manifiesto y el ZIP. |
| 61 | 20-10 | **Sesión de prueba con un local por prueba.** A pedido del usuario, nueva carpeta `COMPENSA_DI/prueba_test2/`, copia de `prueba_test/` con los mismos 4 escenarios y montos, pero cada prueba en otro local y el **29-08-2026**: 1 local 5 T27 (−800), 2 local 25 T12 (+15.000), 3 local 18 T10 (−5.000), 4 local 19 T5 (0). Sobres `<local><terminal>0829<n>`. Verificado en test (solo lectura): locales vigentes en `vta_FACOlocales` (el 13 tiene terminales pero no está en `vta_FACOlocales`, por eso se descartó), terminales de tipo 0, nada cargado ese día. No usa el 30-08 para no cruzarse con `prueba_test_6locales/` (mismos locales 18 y 25; su "Cerrar Terminal" con TODOS cerraría también estas cajas). P0 agrega la consulta 1b (`fn_dif_real` sobre la prueba 1 ya hecha, para confirmar el body: con `uintranetts` el `PACKAGE BODY` no aparece en `all_objects`). P0, P2 y el control de P9 corridos en test: todo lo esperado. Nada ejecutado que modifique datos | `sql/FSCC-12901_COMPENSA_DI/prueba_test2/`, `00_LEEME.md` |
| 62 | 20-10 | **`prueba_test2/` pasa a septiembre.** A pedido del usuario (agosto ya tiene muchas pruebas: 28, 30 y 31), la fecha cambia del 29-08 al **10-09-2026**, que en test no tiene datos FACO en ningún local (septiembre sí tiene en los días 04, 07, 08, 15, 23 y 29). Sobres `<local><terminal>0910<n>` (p. ej. `527091001`). Se regeneraron los 5 Excel y se actualizaron P0, P2, P9 y `LEEME.md`. P0, P2 y el control de P9 corridos en test: todo lo esperado (la consulta 1b revalidó el sinónimo, que ahora figura `VALID`). Nada ejecutado que modifique datos | `sql/FSCC-12901_COMPENSA_DI/prueba_test2/` |
| 63 | 20-10 | **`prueba_test2/`: prueba 1 OK, prueba 2 `SIN_TERMSTAT`.** Prueba 1 (local 5 T27): `DI_REGISTRADA` −800 (log 6). Prueba 2 (local 25 T12): `SIN_TERMSTAT` (log 7). Diagnóstico en test (solo lectura): la Y se grabó en **local 5 / T12** (techkey 82060, `fn_dif_real` −860.000), porque la F8 seguía con el local 5 de la prueba 1 y `Form19Y` toma el local de la F8. No es un error del paquete. Nuevo `prueba_test2/P9b_rehacer_prueba2.sql` (borra esa Y, los 2 sobres y el log de 25/12; control corrido en test: 1/1/1/2/1). `LEEME`: aviso de cambiar el local en la F8 antes de cada prueba y cómo resolver `SIN_TERMSTAT`. Pendiente: el usuario ejecuta P9b y repite la prueba 2 | `sql/FSCC-12901_COMPENSA_DI/prueba_test2/` |
| 64 | 20-10 | **`prueba_test2/` lista para cerrar.** El usuario terminó las 4 pruebas (las diferencias de 5/12 y 25/12 son errores de digitación). Revisión de las dos formas de cierre: CC (`Form43.Command4_Click`) pide confirmación solo con `0-TODOS` (No por defecto; No = `Exit Sub`); el botón Salir de `Form174` llama a `PKG_F8_CIERRE_DIARIO` sin preguntar, con una fecha fija. Esa fecha pasa de 31-08-2026 a **10-09-2026** (`vFechaPrueba`; respaldo `FTEPROD/Form174.frm.bak_FSCC-12901_CD_1009`; sin compilar). Esperado: 3 cerradas (5/27, 19/5, 25/13), 2 no cerradas. Pendiente 1q resuelto (el cron ya corrió el 31-08). `LEEME` de `prueba_test2` con la sección "Cierre de las Y". Manifiesto MD5 desactualizado (cambió `Form174.frm`) | `FTEPROD/Form174.frm`, `prueba_test2/LEEME.md` |
| 65 | 20-10 | **Cierre del 10-09 OK y sesión `prueba_test3/` para la demostración.** El usuario cerró con el botón Salir de `Form174`: en test, 5/27, 19/5 y 25/13 con `ter_estado 1` y `PROC_CIERRE_DIARIO`; 5/12 y 25/12 abiertas (lo esperado). El primer intento no llegó al paquete (sin fila `INICIO` en el log): exe sin recompilar o ventana cerrada con la X. Se notó que el usuario editó `prueba_test2/Prueba-2-OK-DIPositiva_L25T12.xlsx` para repetir la prueba 2 (terminal 13, sobres 2512091003 y 25120910123). Nueva carpeta `COMPENSA_DI/prueba_test3/` (17-09-2026, día vacío en test): copia de `prueba_test2` con la fecha y los sobres cambiados; el Excel 2 vuelve a 25/12 con los sobres 2512091701 y 2512091702; sin `P9b`. `Form174`: `vFechaPrueba` pasa de 20260910 a **20260917** (respaldo `Form174.frm.bak_FSCC-12901_CD_1709`; sin compilar). P0, P2 y el control de P9 corridos en test: todo lo esperado. Manifiesto MD5 desactualizado | `prueba_test3/`, `FTEPROD/Form174.frm`, `00_LEEME.md` |
| 66 | 20-10 | **Manifiesto y respaldo `prueba-test3`.** Se regeneró `docs/MANIFIESTO_FSCC-12901.md5`: la misma lista que el de `prueba-6locales` (antes de regenerar solo fallaban `Form174.frm`, este índice y `COMPENSA_DI/00_LEEME.md`, por los cambios de hoy), más `COMPENSA_DI/prueba_test2/` (10 archivos, incluido `P9b` y el Excel 2 editado por el usuario), `COMPENSA_DI/prueba_test3/` (9 archivos) y `FTEPROD/Form174.frm.bak_FSCC-12901_CD_1009` y `.bak_FSCC-12901_CD_1709`. Respaldo `docs/respaldos/FSCC-12901_2026-10-20_prueba-test3.zip` (§10). Estado para la demostración del 21-10 (pendiente 1u): `Form174` con `vFechaPrueba = "20260917"`, sin compilar | `MANIFIESTO_FSCC-12901.md5`, `respaldos/` |
| 67 | 22-10 | **Paquete de paso a producción** en `docs/Cambios/` (`README.md`): comparación de la copia de producción (`Downloadsteprod`) con `fteprod`. por este ticket van `form133.frm` (compensación di) y `form43.frm` (dr 0, `0-todos`, confirmación y mensaje); también los prerrequisitos de `compensa_di`, copias exactas, originales prod, diffs y manifiesto. `form172`/`form173` tienen cambios sin marca y se documentan aparte |
| 68 | 22-10 | **Prueba 4 de COMPENSA_DI** (`sql/FSCC-12901_COMPENSA_DI/prueba_test4/`): réplica de `prueba_test3` el 20-08-2026, con los mismos 4 escenarios y sobres `…0820…`, y LEEME, P0, P2, P9, los 4 Excel y el resumen. La fecha no está verificada en la base (sin VPN). El botón Salir de `Form174` pasa a `vFechaPrueba = "20260820"` (antes 15-10-2026, FCDVT-56); respaldo `FTEPROD/Form174.frm.bak_FSCC-12901_CD_2008`. Sin compilar. Se regeneró la versión prod de `Form174` en `docs/Cambios/` |
| 69 | 22-10 | **Manifiesto regenerado** (`docs/MANIFIESTO_FSCC-12901.md5`, 306 archivos). Desde el 20-10 suma `CIERRE_DIARIO/anterior_2026-10-22/`, `prueba_test/P3_sin_venta.sql`, `COMPENSA_DI/prueba_test4/`, `prueba_test3/plantilla_carga_Y_FACO.csv` y `FTEPROD/Form174.frm.bak_FSCC-12901_CD_2008`. Saca los 2 Excel `DF-SCC-vf_Falabella CO (...)` de `Requeriemintos-FSCC-12901`, que ya no están en disco (siguen en el ZIP `FSCC-12901_2026-10-20_prueba-test3.zip`) . **Ese mismo día se restauraron** desde ese ZIP (MD5 `5b9fc1f9…`, igual que el 20-10) y volvieron al manifiesto, que queda en 308 archivos |
| 70 | 26-10 | **`CLAUDE.md` al día** (revisión con `/init`). §3 suma los artefactos que no son fuente (`recaudacion.vbw`, `Form*.log`, `*.bak_<ticket>`, `bash.exe.stackdump`). §5 y §9 advierten que el `Form174` local (Salir con `EjecutaCierreDiario`) no es el de producción. §6 suma `Credencial.txt` a la advertencia de credenciales. §7 agrega la marca `xintec-nruz dd-mm-yyyy`. §9 suma `docs/sql/CLAUDE.md` y el paquete `docs/Cambios/`. Sin cambios en `FTEPROD` ni en la base. En los cuatro manifiestos de `docs/` solo cambia el MD5 de `CLAUDE.md` (y el de cada índice que registra esta fila). Respaldo `FSCC-12901_2026-10-26_claude-md.zip` (§10) | `CLAUDE.md` |
| 71 | 26-10 | **Clon offline del esquema** en `docs/ddl/` (lectura, desa `INTRANETDE` con bodies y test `INTRANETTS`; ver `docs/ddl/README.md`). El clon confirma que `PKG_F8_CIERRE_DIARIO` está en test (`VALID`; lo instaló el usuario el 20-10, ver 1q). La spec se recompiló el 22-10 a las 17:52 y es igual a la de desa. Se corrigieron `CLAUDE.md` §9, `docs/sql/CLAUDE.md` y `CIERRE_DIARIO/00_LEEME.md`, que decían "sin ejecutar" o "solo spec". `CLAUDE.md` §4.6 suma la regla de consultar el clon y §8 aclara que existe `docs/.git`. Manifiesto `docs/ddl/MANIFIESTO_DDL.md5` y respaldo `docs/respaldos/DDL_2026-10-26_clon-desa-test.zip`. En los manifiestos de los tickets solo cambian los MD5 de `CLAUDE.md` y de este índice | `docs/ddl/`, `CLAUDE.md` |
| 72 | 26-10 | **Estado congelado**, a pedido del usuario ("graba todo"). El usuario confirma que instaló en test CIERRE_DIARIO (20-10) y la etapa sin venta de FCDVT-56 (22-10). Lo único pendiente es el cron en nhal1 (1r). Se actualizaron §5h, `CLAUDE.md` §9, `docs/sql/CLAUDE.md`, `CIERRE_DIARIO/00_LEEME.md` y `README_FCDVT-56.md`. Manifiestos de los cuatro tickets y de `docs/ddl/` al día. Respaldo `docs/respaldos/FSCC-12901_2026-10-26_cierre-diario-test.zip` (§10) | Índices, manifiestos |
| 73 | 26-10 | **Prueba 5 de COMPENSA_DI** (`sql/FSCC-12901_COMPENSA_DI/prueba_test5/`): réplica de `prueba_test4` el 15-09-2026, con los mismos 4 escenarios y sobres `…0915…`, y LEEME, P0, P2, P9, los 4 Excel y el resumen. El 15-09 ya tiene datos FACO en test y la fecha no se verificó (sin VPN): correr P0 antes. El botón Salir de `Form174` pasa a `vFechaPrueba = "20260915"` (antes 20-08-2026); respaldo `FTEPROD/Form174.frm.bak_FSCC-12901_CD_1509`. Sin compilar. La versión prod de `Form174` en `docs/Cambios/` no cambia. Manifiestos al día (FSCC-12901 suma `prueba_test5/` y el `.bak_FSCC-12901_CD_1509`; FCDVT-14 y FCDVT-56, solo MD5 de los archivos cambiados). Respaldo `docs/respaldos/FSCC-12901_2026-10-26_prueba-test5.zip` (§10) |

## 10. Estado congelado (vigente: `FSCC-12901_2026-10-20_prueba-test3.zip`)

**Situación en la base de datos:** no se creó ni se modificó **ningún objeto o dato** en desarrollo ni en test. Todas las consultas hechas fueron de solo lectura.

**Manifiesto de integridad:** `docs/MANIFIESTO_FSCC-12901.md5` (regenerado el 07-10 tras la reestructura "solo Y") guarda la huella MD5 de los scripts y README de las tres carpetas, los documentos de análisis, los dos PDF, sus fuentes HTML, CSS e imágenes, los archivos de `docs/Requeriemintos-FSCC-12901/` (incluida `Doc-Actualizado/`), `CLAUDE.md` y `FTEPROD/Form43.frm` con su respaldo `.bak_FSCC-12901` (el número exacto está en el propio manifiesto). Para saber si algo cambió después de esta fecha (desde `C:\Repositorio-f8\F8`, en Git Bash):

```
grep -v '^#' docs/MANIFIESTO_FSCC-12901.md5 | md5sum -c
```

Si un archivo cambió, aparece como `FAILED`: revisar el cambio y, si corresponde, regenerar el manifiesto y anotar el motivo en §9.

**Respaldos** (descomprimir sobre `C:\Repositorio-f8\F8` para volver a ese estado):
- `docs/respaldos/FSCC-12901_2026-10-06_pre-pruebas.zip`: `docs/` y `CLAUDE.md` antes del ajuste DF-SCC.
- `docs/respaldos/FSCC-12901_2026-10-06_post-DF.zip`: `docs/` (sin `respaldos/`), `CLAUDE.md`, `FTEPROD/Form43.frm` y `FTEPROD/Form43.frm.bak_FSCC-12901`, después del ajuste DF-SCC (con la Z todavía en el diseño).
- `docs/respaldos/FSCC-12901_2026-10-07_solo-Y.zip`: el mismo contenido después de la reestructura "solo cierre Y" (contiene el `Form43.frm` **modificado** de v1).
- `docs/respaldos/FSCC-12901_2026-10-13_v2-multipais.zip`: el mismo contenido con la carpeta v2 multipaís. Ojo: aquí `FTEPROD/Form43.frm` es el original, tal como estaba en disco el 13-10.
- `docs/respaldos/FSCC-12901_2026-10-15_proc-yz.zip`: `sql/FSCC-12901_PROC_Y` (renombrada), `sql/FSCC-12901_PROC_YZ` (nueva), este índice, `CierreCaja_FACO_Reglas.md`, el diagrama HTML y el manifiesto del 15-10 (manifiesto verificado OK).
- `docs/respaldos/FSCC-12901_2026-10-15_prueba-manual-Y.zip`: `docs/` (sin `respaldos/`) y `CLAUDE.md` después de la prueba manual del cierre Y por pantallas (OK), con la carpeta `prueba_manual_Y/` (guía, Excel, capturas y scripts), el PDF de evidencia y el manifiesto del 15-10 .
- `docs/respaldos/FSCC-12901_2026-10-15_prueba3-simulada.zip`: `docs/` (sin `respaldos/`) y `CLAUDE.md` con la simulacion de la prueba 3 (`prueba3_simulacion/`, Excel V3, PDF) lista para retomar en test.
- `docs/respaldos/FSCC-12901_2026-10-16_prueba3-test-OK.zip`: `docs/` (sin `respaldos/`), `CLAUDE.md`, `FTEPROD/Form133.frm` y `Form43.frm` con sus respaldos `.bak_FSCC-12901`, después de la prueba 3 OK en test y de la revisión de cumplimiento; manifiesto del 16-10.
- `docs/respaldos/FSCC-12901_2026-10-16_form43-v2.zip`: el mismo contenido con `Form43.frm` v2 aplicado (marcas xintec-nruz) y el CA5 corregido (v2 luego descartada).
- `docs/respaldos/FSCC-12901_2026-10-16_form43-minimo.zip`: `Form43.frm` con el cambio mínimo (grilla con DR 0) y la documentación ajustada .
- `docs/respaldos/FSCC-12901_2026-10-19_compensa-di.zip`: `docs/` (sin `respaldos/`), `CLAUDE.md`, `FTEPROD/Form133.frm`, `Form133.frx`, sus respaldos `.bak_FSCC-12901` y `.bak_FSCC-12901_DI`, y `Form43.frm` con su respaldo. Es el estado del modelo del 19-10: carpeta `sql/FSCC-12901_COMPENSA_DI/` (borrado de la v2, `PKG_F8_COMPENSA_DI_CARGA`, `prueba_test/` con 4 pruebas) y `Form133` aplicado sin compilar.
- `docs/respaldos/FSCC-12901_2026-10-20_multipais.zip`: `docs/` (sin `respaldos/`), `CLAUDE.md`, `FTEPROD/Form133.frm`, `Form133.frx`, `.bak_FSCC-12901`, `.bak_FSCC-12901_DIPAIS`, `Form43.frm`, `.bak_FSCC-12901` y `.bak_FSCC-12901_TODOS`. Estado del 20-10: pruebas 1 a 4 OK en test, glosa `COMPENSACION AUTOMATICA DI` (`08`), CC con `0-TODOS` y mensaje de cierre FACO (`Form43`), `PKG_F8_COMPENSA_DI_CARGA` multipaís con la versión probada en `anterior_20-10/`, y `Form133` con la llamada con país (sin compilar). `Form133.frm.bak_FSCC-12901_DI` ya no está en disco (se borró fuera de la sesión); queda en el ZIP del 19-10.
- `docs/respaldos/FSCC-12901_2026-10-20_pre-cron.zip`: el mismo contenido que `multipais`, con la documentación previa al cron (encabezado, §2, §5g "Estado al 20-10" y "Antes del cron", pendientes cerrados, fila 55).
- `docs/respaldos/FSCC-12901_2026-10-20_cierre-diario.zip`: el mismo contenido que `pre-cron` más la carpeta `sql/FSCC-12901_CIERRE_DIARIO/` (cron de cierre diario, §5h) y la documentación actualizada.
- `docs/respaldos/FSCC-12901_2026-10-20_prueba-6locales.zip`: el mismo contenido que `cierre-diario`, más `FTEPROD/Form174.frm`, `Form174.frx` y `Form174.frm.bak_FSCC-12901_CIERRE_DIARIO` (botón Salir temporal, fila 58), los parámetros en `INSERT ... VALUES` y la carpeta `sql/FSCC-12901_COMPENSA_DI/prueba_test_6locales/` (fila 59).
- `docs/respaldos/FSCC-12901_2026-10-20_prueba-test3.zip` (**estado vigente**): el mismo contenido que `prueba-6locales`, más `sql/FSCC-12901_COMPENSA_DI/prueba_test2/` (10-09-2026, probada OK con el cierre por Salir) y `prueba_test3/` (17-09-2026, para la demostración), y `FTEPROD/Form174.frm` con `vFechaPrueba = "20260917"` y sus respaldos `.bak_FSCC-12901_CD_1009` (fecha 31-08) y `.bak_FSCC-12901_CD_1709` (fecha 10-09) (filas 61 a 66).
- `docs/respaldos/FSCC-12901_2026-10-26_claude-md.zip`: el mismo conjunto que `FSCC-12901_2026-10-22_sin-venta-test4.zip`: `docs/` (sin `respaldos/`), `CLAUDE.md`, y `Form133`, `Form43` y `Form174` de `FTEPROD` con sus `.frx` y respaldos `.bak_FSCC-12901*`. Agrega `CLAUDE.md` revisado con `/init` y los manifiestos al día (fila 70). Nada compilado ni ejecutado.
- `docs/respaldos/FSCC-12901_2026-10-26_cierre-diario-test.zip`: el mismo conjunto que `claude-md` más `docs/ddl/`, el clon offline del esquema (fila 71). Registra que CIERRE_DIARIO y la etapa sin venta de FCDVT-56 están instalados en test (fila 72). Nada compilado.
- `docs/respaldos/FSCC-12901_2026-10-26_prueba-test5.zip` (**estado vigente**): el mismo conjunto que `cierre-diario-test` más `sql/FSCC-12901_COMPENSA_DI/prueba_test5/` (15-09-2026) y `FTEPROD/Form174.frm.bak_FSCC-12901_CD_1509`; `Form174.frm` con `vFechaPrueba = "20260915"` (fila 73). Nada compilado ni ejecutado.
- Para volver la fecha de prueba de `Form174` al 10-09 o al 31-08: copiar `Form174.frm.bak_FSCC-12901_CD_1709` o `.bak_FSCC-12901_CD_1009`, respectivamente, sobre `Form174.frm`.
- Para volver la fecha de prueba de `Form174` al 20-08-2026 (`prueba_test4`): copiar `Form174.frm.bak_FSCC-12901_CD_1509` sobre `Form174.frm`.
- Para deshacer solo el cambio de `Form133` del 19-10: copiar `Form133.frm.bak_FSCC-12901_DI` sobre `Form133.frm`. Así vuelve a llamar a `PKG_F8_CIERRE_AUTO`, el modelo del 16-10.
- Para deshacer solo el cambio multipaís de `Form133` (20-10): copiar `Form133.frm.bak_FSCC-12901_DIPAIS` sobre `Form133.frm` (vuelve a la llamada sin país, que el paquete sigue aceptando). Para el paquete: ejecutar `COMPENSA_DI/anterior_20-10/04` y `05`.
- Para deshacer solo TODOS y el mensaje de cierre de `Form43` (20-10): copiar `Form43.frm.bak_FSCC-12901_TODOS` sobre `Form43.frm` (queda con la línea del 16-10).
- Para deshacer solo el front: copiar `Form43.frm.bak_FSCC-12901` (original anterior a FSCC-12901) sobre `Form43.frm`.

**Checklist para la sesión de pruebas:**

| # | Paso | Script |
|---|---|---|
| 1 | Activar la VPN Fortinet y conectarse como el dueño de las tablas (o como DBA con `current_schema`) | — |
| 2 | Verificar que los scripts no cambiaron | `md5sum -c` (ver arriba) |
| 3 | Verificaciones previas: las 14 deben dar el resultado esperado | `FSCC-12901_T1_T2/00_prechecks.sql` |
| 4 | Instalar los pasos 00–08 (incluye 03b vista y 03c opción 1515) | `@INSTALAR.sql` |
| 5 | Permisos y sinónimos (dueño + DBA), también para el usuario de `[CONNECT]` del exe; habilitar la opción 1515 a los perfiles de prueba | `09_grants_sinonimos.sql`, `03c_permiso_cc.sql` (UPDATE) |
| 6 | Pruebas: compilación, DR contra la F8 en 10 cajas, simulación de T1, ejecución completa, vista, columnas de `Form43` y `prc_cierre_rango` | `10_pruebas.sql` |
| 6b | Compilar el exe con el nuevo `Form43` y probar Consultas de Cuadratura en FACO (casos T21–T26) | IDE VB6 |
| 7 | Registrar los resultados en §9 (nueva fila) y actualizar §2 y §7 | Este documento |
| 8 | Si algo sale mal: apagar (paso 1) o desinstalar (paso 3) | `99_rollback.sql` |
