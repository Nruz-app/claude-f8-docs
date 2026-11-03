# FCDVT-14: scripts de base de datos

Índice del requerimiento: `docs/README_FCDVT-14.md`. Los scripts no llevan prefijo de esquema; se ejecutan conectado como el dueño de las tablas `VTA_*`.

| Orden | Script | Qué hace | Estado |
|---|---|---|---|
| 0 | `00_prechecks.sql` | Solo lectura: conceptos de `vta_paint_z`, columnas, secuencias, log, menú y volumen. §11-12: código 460 libre y perfiles con permiso 15 | Sin ejecutar |
| 1 | `01_menu_ingreso_masivo_y.sql` | Permiso 460 "Ingreso de cierre de terminal Y masivo" (FACO): 3 INSERT explícitos (los mismos para test y producción): 1 en `VTA_FACOMENU` (`MenuPrincipal`) y 1 en `VTA_FACORELPERMEN` por perfil que ve la opción (10 y 11; 0 y 1 comentados). No es reejecutable (PK) | **Ejecutado en test** el 20-10-2026 (perfiles 10 y 11); falta producción |
| 2 | `02_tablas_carga_yz.sql` | Carga masiva Y/Z, etapa Buscar (30-10-2026): tablas `VTA_FACOCARGA_YZ_DET` (líneas del CSV tipadas), `VTA_FACOCARGA_YZ_RES` (resumen por fecha, local y terminal: la grilla de Form174) y `VTA_FACOCARGA_YZ_LOG` (errores por línea, campo y motivo), y las secuencias `SEQ_VTA_FACOCARGA_YZ` y `SEQ_VTA_FACOCARGA_YZ_LOG` | Sin ejecutar |
| 3 | `03_pkg_carga_masiva_yz_spec.sql` | Spec de `PKG_F8_CARGA_MASIVA_YZ`: `prc_inicia`, `prc_inserta_linea` (separa y valida cada línea) y `prc_procesa` (terminal vigente, `NRO_Y` repetido, resumen PENDIENTE → PROCESADO / ERROR). Tiene el encabezado de 56 columnas, que debe coincidir con `Form174.EncabezadoCsvY` | Sin ejecutar |
| 4 | `04_pkg_carga_masiva_yz_body.sql` | Body del package. Cuadratura: total Z (BOLETAS + N.CREDITO + FACTURA) = suma de los totales de las Y del terminal-día. No graba libvta, zzz ni termstat(y) | Sin ejecutar |
| 5 | `05_grants_sinonimos.sql` | Solo si el exe se conecta con un usuario distinto del dueño: execute del package, select de las 3 tablas y sinónimos (`EDITAR`) | Sin ejecutar |
| 6 | `06_pruebas.sql` | Solo lectura: últimas cargas, resumen, errores y detalle de una carga (`EDITAR` el número), con el resultado esperado de los CSV de ejemplo | — |
| — | `INSTALAR.sql` | Ejecuta 02, 03 y 04 y verifica `user_objects` / `user_errors` | — |
| 99 | `99_rollback.sql` | Por partes. A: borra el permiso 460 de `VTA_FACORELPERMEN` y `VTA_FACOMENU`. B: desinstala la carga Y/Z (package, tablas y secuencias) | — |

Archivos de carga (CSV, formato `FORMATO_CARGA_Y_FACO.md`):

| Archivo | Qué es |
|---|---|
| `plantilla_carga_Y_FACO.csv` | Plantilla con el encabezado de **56 columnas** (con `TIPO` y `TIPO_CARGA`) y 4 filas de ejemplo: T1 con Z + 2 Y y T2 con 1 Y sin Z. Es una copia de `docs/FCDVT-14/` |
| `ejemplo_carga_Y_FACO_20.csv` | 30-10-2026: 23 filas del 16-10-2026, local 5. Por terminal, 1 Z (cada concepto = suma de sus Y) y sus Y: T1 7 Y (9.400.000), T2 7 Y (7.435.000) y T3 6 Y (9.490.000); en total 26.325.000. Buscar: 3 grupos PROCESADO. La versión del 22-10 (20 Y sin Z, 56 columnas) quedó en `.bak_FCDVT-14_Z` |
| `pruebas/` | 03-11-2026: 8 CSV de prueba de Buscar, uno por tipo de caso: campos malos (`p01`), falta de Z, Z sin Y y 2 Z (`p02`), cuadratura (`p03`), `NRO_Y` repetido (`p04`), estructura de la línea (`p05`), encabezado de 54 columnas (`p06`), solo encabezado (`p07`) y volumen de 630 filas (`p08`). El resultado esperado de cada uno está en `pruebas/README.md` |
| `ejemplo_carga_YZ_FACO_errores.csv` | 30-10-2026: un caso por resultado. Buscar: 1 PROCESADO (15-10 T1) y 4 ERROR (15-10 T2 Z ≠ ΣY, 15-10 T3 sin Z, 14-10 T1 monto `12a00` y `TIPO X`, terminal 99 no vigente), más una línea de 50 campos que solo queda en el log |

Notas:
- Antes de `01`, confirmar con los prechecks §11 que el 460 está libre en la base de destino. Si está ocupado, hay que cambiar el código en el script **y** en `MDIForm1.SubBuscarOpcionMenu` (rama `numero = 460`).
- El submenú solo aparece con el exe que trae el cambio de `MDIForm1.frm` (README §5.2). Un exe anterior **no** ignora las filas 460: `SubBuscarOpcionMenu` las manda al `Else`, `Buttons(460)` da error y el `On Error GoTo salir` corta los permisos que quedaban por cargar (códigos mayores que 460) a los perfiles que tengan esa fila. Por eso, **ejecutar `01` en cada base solo cuando ahí se use el exe nuevo**.
- **Carga Y/Z (02 a 04):** antes de instalar, correr los prechecks §13 (nombres libres) y §14 (terminales del local 5). Después, compilar el exe con el `Form174` nuevo (Buscar llama al package) y probar con los dos CSV de ejemplo; revisar con `06_pruebas.sql`. Si el package no está instalado, Buscar muestra el error de Oracle.
