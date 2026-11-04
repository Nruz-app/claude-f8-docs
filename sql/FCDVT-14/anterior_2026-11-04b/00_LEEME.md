# FCDVT-14: scripts de base de datos

Índice del requerimiento: `docs/README_FCDVT-14.md`. Los scripts no llevan prefijo de esquema; se ejecutan conectado como el dueño de las tablas `VTA_*`.

| Orden | Script | Qué hace | Estado |
|---|---|---|---|
| 0 | `00_prechecks.sql` | Solo lectura: conceptos de `vta_paint_z`, columnas, secuencias, log, menú y volumen. §11-12: código 460 libre y perfiles con permiso 15 | Sin ejecutar |
| 1 | `01_menu_ingreso_masivo_y.sql` | Permiso 460 "Ingreso de cierre de terminal Y masivo" (FACO): 3 INSERT explícitos (los mismos para test y producción): 1 en `VTA_FACOMENU` (`MenuPrincipal`) y 1 en `VTA_FACORELPERMEN` por perfil que ve la opción (10 y 11; 0 y 1 comentados). No es reejecutable (PK) | **Ejecutado en test** el 20-10-2026 (perfiles 10 y 11); falta producción |
| 2 | `02_tablas_carga_yz.sql` | Carga masiva Y/Z, etapa Buscar. **Multipaís desde el 03-11**: para el prefijo de su bloque `EDITAR` (`FACO`) crea `VTA_<pfx>CARGA_YZ_DET` (líneas del CSV tipadas), `VTA_<pfx>CARGA_YZ_RES` (resumen por fecha, local y terminal: la grilla de Form174), `VTA_<pfx>CARGA_YZ_LOG` (errores por línea, campo y motivo) y las secuencias `SEQ_VTA_<pfx>CARGA_YZ` y `SEQ_VTA_<pfx>CARGA_YZ_LOG`. **Solo crea lo que no existe**: en test (FACO, instalado el 30-10) no hace nada | Versión FACO del 30-10 **ejecutada en test**; la multipaís, sin ejecutar |
| 3 | `03_pkg_carga_masiva_yz_spec.sql` | Spec de `PKG_F8_CARGA_MASIVA_YZ`: `prc_inicia`, `prc_inserta_linea` (separa y valida cada línea), `prc_procesa` (terminal vigente, `NRO_Y` repetido, resumen PENDIENTE → **CARGADO** / ERROR; antes PROCESADO). **Multipaís desde el 03-11**: `prc_inserta_linea` y `prc_procesa` reciben el país primero. Las firmas anteriores, sin país, se mantienen y usan FACO. Tiene el encabezado de 56 columnas de FACO, que debe coincidir con `Form174.EncabezadoCsvY`. **Desde el 04-11**, `prc_graba` (botón Cargar) y el estado **GRABADO** | Sin ejecutar (la del 30-10 está en test) |
| 4 | `04_pkg_carga_masiva_yz_body.sql` | Body del package. Cuadratura: total Z (BOLETAS + N.CREDITO + FACTURA) = suma de los totales de las Y del terminal-día. Buscar no graba cierres. **Multipaís desde el 03-11**: `pr_config` con lista blanca (solo `FACO`) y SQL dinámico con la marca `{P}`, el mismo patrón que `PKG_F8_COMPENSA_DI_CARGA`. **Desde el 04-11**, `prc_graba`: por grupo CARGADO revalida que la Z y las Y no estén cerradas, **reemplaza** como Form19 (borra zzz, libvta `'F8'`/`'Y'` y termstaty del terminal-día), inserta la Z (libvta 99 + zzz + termstat −1 si falta) y cada Y (libvta + zzz + termstaty −1), con commit o rollback por grupo → GRABADO o ERROR. Buscar rechaza VENDEDOR de más de 10 dígitos (`vta_vendedor NUMBER(10)`) | Sin ejecutar (la del 30-10 está en test) |
| 5 | `05_grants_sinonimos.sql` | Solo si el exe se conecta con un usuario distinto del dueño: execute del package, select de las 3 tablas del prefijo y sinónimos (bloques `EDITAR`: prefijo, usuario y dueño) | Sin ejecutar |
| 6 | `06_pruebas.sql` | Solo lectura: últimas cargas, resumen, errores y detalle de una carga (`EDITAR` el número), con el resultado esperado de los CSV de ejemplo. Consultas 6 a 9 (04-11): lo que grabó Cargar en libvta, zzz y termstat(y) para una fecha y un local (`EDITAR`) | — |
| 98 | `98_limpia_prueba.sql` | **Solo test.** Borra lo que grabó Cargar en los grupos GRABADO de una carga (`EDITAR` prefijo, carga y `v_ejecutar`; primero con `N`, que solo cuenta) y los deja en CARGADO. No repone lo que Cargar reemplazó | — |
| — | `INSTALAR.sql` | Ejecuta 02, 03 y 04 y verifica `user_objects` / `user_errors` | — |
| 99 | `99_rollback.sql` | Por partes. A: borra el permiso 460 de `VTA_FACORELPERMEN` y `VTA_FACOMENU`. B: desinstala las tablas y secuencias de **un prefijo** (`EDITAR`). C: **vuelve a la versión solo FACO** (compila `anterior_2026-11-03/03` y `04`). D (04-11): vuelve al package multipaís **sin `prc_graba`** (`anterior_2026-11-04/03` y `04`) | — |
| — | `anterior_2026-11-04/` | **Respaldo** de la versión multipaís del 03-11, sin `prc_graba` (`02`-`06`, `INSTALAR`, `99`, prechecks y este índice). No se ejecuta, salvo la parte D del rollback | — |
| — | `anterior_2026-11-03/` | **Respaldo** de la versión solo FACO del 30-10 (`02`-`06`, `INSTALAR`, `99`, prechecks y este índice), la que está instalada en test. No se ejecuta, salvo la parte C del rollback | — |

Archivos de carga (CSV, formato `FORMATO_CARGA_Y_FACO.md`):

| Archivo | Qué es |
|---|---|
| `plantilla_carga_Y_FACO.csv` | Plantilla con el encabezado de **56 columnas** (con `TIPO` y `TIPO_CARGA`) y 4 filas de ejemplo: T1 con Z + 2 Y y T2 con 1 Y sin Z. Es una copia de `docs/FCDVT-14/` |
| `ejemplo_carga_Y_FACO_20.csv` | 30-10-2026: 23 filas del 16-10-2026, local 5. Por terminal, 1 Z (cada concepto = suma de sus Y) y sus Y: T1 7 Y (9.400.000), T2 7 Y (7.435.000) y T3 6 Y (9.490.000); en total 26.325.000. Buscar: 3 grupos CARGADO. La versión del 22-10 (20 Y sin Z, 56 columnas) quedó en `.bak_FCDVT-14_Z` |
| `pruebas/` | 03-11-2026: 8 CSV de prueba de Buscar, uno por tipo de caso: campos malos (`p01`), falta de Z, Z sin Y y 2 Z (`p02`), cuadratura (`p03`), `NRO_Y` repetido (`p04`), estructura de la línea (`p05`), encabezado de 54 columnas (`p06`), solo encabezado (`p07`) y volumen de 630 filas (`p08`). El resultado esperado de cada uno está en `pruebas/README.md` |
| `ejemplo_carga_YZ_FACO_errores.csv` | 30-10-2026: un caso por resultado. Buscar: 1 CARGADO (15-10 T1) y 4 ERROR (15-10 T2 Z ≠ ΣY, 15-10 T3 sin Z, 14-10 T1 monto `12a00` y `TIPO X`, terminal 99 no vigente), más una línea de 50 campos que solo queda en el log |

Notas:
- Antes de `01`, confirmar con los prechecks §11 que el 460 está libre en la base de destino. Si está ocupado, hay que cambiar el código en el script **y** en `MDIForm1.SubBuscarOpcionMenu` (rama `numero = 460`).
- El submenú solo aparece con el exe que trae el cambio de `MDIForm1.frm` (README §5.2). Un exe anterior **no** ignora las filas 460: `SubBuscarOpcionMenu` las manda al `Else`, `Buttons(460)` da error y el `On Error GoTo salir` corta los permisos que quedaban por cargar (códigos mayores que 460) a los perfiles que tengan esa fila. Por eso, **ejecutar `01` en cada base solo cuando ahí se use el exe nuevo**.
- **Carga Y/Z (02 a 04):** antes de instalar, correr los prechecks §13 (nombres libres) y §14 (terminales del local 5). Después, compilar el exe con el `Form174` nuevo (Buscar llama al package) y probar con los dos CSV de ejemplo; revisar con `06_pruebas.sql`. Si el package no está instalado, Buscar muestra el error de Oracle.
- **Estado CARGADO (03-11-2026):** el estado de un grupo correcto pasó de PROCESADO a CARGADO. Las cargas anteriores de test conservan PROCESADO; no se migran.

## Multipaís (03-11-2026)

`PKG_F8_CARGA_MASIVA_YZ` recibe el país (`Flg_Pais$`) y arma el SQL con su prefijo: `VTA_{P}CARGA_YZ_*`, `SEQ_VTA_{P}CARGA_YZ[_LOG]` y `VTA_{P}TERMINALES`. El prefijo sale solo de la lista blanca de `pr_config`, nunca del texto recibido; un país que no está en la lista da ORA-20001. Hoy está habilitado **solo FACO**, con los mismos nombres de tablas que ya existían. Form174 y Form175 arman el nombre de la tabla con `PrefijoCargaYZ()`: el `Flg_Pais$`, salvo Chile (`CHI`), que no lleva prefijo.

Para habilitar otro país (por ejemplo `SFCL`, o Chile con tablas `VTA_CARGA_YZ_*`):
1. `02_tablas_carga_yz.sql` con `v_prefijo` del país, y `05` si corresponde.
2. Comparar su `vta_<pfx>paint_z` con el de FACO (`FORMATO_CARGA_Y_FACO.md` §3). Si sus conceptos son otros, hay que definir su encabezado en `pr_config` y agregar las columnas que falten en `VTA_<pfx>CARGA_YZ_DET` y en el INSERT de `prc_inserta_linea`. Chile carga solo Z, así que su archivo es distinto.
3. En `04`, descomentar o agregar la rama del país en `pr_config` y recompilar.
4. En el exe: Form174 (Exportar Excel y `EncabezadoCsvY`) tiene el encabezado de FACO, y `MDIForm1` abre `Form174` solo para FACO (`INGYMA`). Además hay que crear el permiso 460 del país (`01`, con sus tablas de menú).

## Respaldo y vuelta atrás

Si el multipaís no funciona:
1. **Base:** `99_rollback.sql`, parte C. Recompila la versión solo FACO de `anterior_2026-11-03/`; las tablas FACO son las mismas, así que no se pierde nada.
2. **Exe:** volver a `FTEPROD/Form174.frm.bak_FCDVT-14_Multipais` y `Form175.frm.bak_FCDVT-14_Multipais`, que llaman a las firmas sin país, y sincronizar `docs/Cambios/`.

El package multipaís conserva las firmas sin país, así que también funciona con el exe anterior. El exe nuevo, en cambio, **no** funciona con el package anterior.

## Cargar (04-11-2026)

`prc_graba(p_flg_pais, p_carga, p_usuario, o_grupos_ok, o_grupos_error)` lo llama el botón Cargar de Form174 después de un Buscar. Graba solo los grupos **CARGADO** de esa carga y los deja en **GRABADO**. Un grupo que no se puede grabar queda en **ERROR** con el motivo, y los demás siguen. El detalle está en `FORMATO_CARGA_Y_FACO.md` §7 y en `docs/README_FCDVT-14.md` §5.9.

- **Reemplaza** la Z y las Y que el terminal-día ya tenga (decisión del usuario, como Form19). Las bloquea solo si la Z o alguna Y está cerrada.
- Glosas en `ter_notas`: `CARGA MASIVA DE CIERRE Z - CARGA <n>` y `CARGA MASIVA DE CIERRE Y - CARGA <n>`.
- **Compatibilidad:** el Form174 del 04-11 necesita este package. Con el del 03-11, Buscar funciona y Cargar da error de Oracle. Para volver atrás: `99_rollback.sql` parte D y `FTEPROD/Form17[45].frm.bak_FCDVT-14_Cargar`.
- **Para probar en test:** `INSTALAR.sql` → compilar → Buscar con `ejemplo_carga_Y_FACO_20.csv` (3 CARGADO) → Cargar (3 GRABADO) → `06_pruebas.sql` consultas 6 a 9 → `98_limpia_prueba.sql`.
