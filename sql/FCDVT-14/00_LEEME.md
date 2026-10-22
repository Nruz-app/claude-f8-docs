# FCDVT-14: scripts de base de datos

Índice del requerimiento: `docs/README_FCDVT-14.md`. Los scripts no llevan prefijo de esquema; se ejecutan conectado como el dueño de las tablas `VTA_*`.

| Orden | Script | Qué hace | Estado |
|---|---|---|---|
| 0 | `00_prechecks.sql` | Solo lectura: conceptos de `vta_paint_z`, columnas, secuencias, log, menú y volumen. §11-12: código 460 libre y perfiles con permiso 15 | Sin ejecutar |
| 1 | `01_menu_ingreso_masivo_y.sql` | Permiso 460 "Ingreso de cierre de terminal Y masivo" (FACO): 3 INSERT explícitos (los mismos para test y producción): 1 en `VTA_FACOMENU` (`MenuPrincipal`) y 1 en `VTA_FACORELPERMEN` por perfil que ve la opción (10 y 11; 0 y 1 comentados). No es reejecutable (PK) | **Ejecutado en test** el 20-10-2026 (perfiles 10 y 11); falta producción |
| 99 | `99_rollback.sql` | Borra el permiso 460 de `VTA_FACORELPERMEN` y `VTA_FACOMENU` | — |

Archivos de carga (CSV, formato `FORMATO_CARGA_Y_FACO.md`):

| Archivo | Qué es |
|---|---|
| `plantilla_carga_Y_FACO.csv` | Plantilla con el encabezado de 54 columnas y 3 filas de ejemplo. Es una copia de `docs/FCDVT-14/` |
| `ejemplo_carga_Y_FACO_20.csv` | Del 22-10-2026, para probar la grilla de `Form174` (Buscar): 20 Y del 16-10-2026, local 5, terminales 1 (7 filas), 2 (7) y 3 (6), con `NRO_Y` vacío. Las formas de pago suman los TOTALES. La suma de los Monto Total es 26.325.000. **Si se usa con Cargar en test, graba** esas 20 Y |

Notas:
- Antes de `01`, confirmar con los prechecks §11 que el 460 está libre en la base de destino. Si está ocupado, hay que cambiar el código en el script **y** en `MDIForm1.SubBuscarOpcionMenu` (rama `numero = 460`).
- El submenú solo aparece con el exe que trae el cambio de `MDIForm1.frm` (README §5.2). Un exe anterior **no** ignora las filas 460: `SubBuscarOpcionMenu` las manda al `Else`, `Buttons(460)` da error y el `On Error GoTo salir` corta los permisos que quedaban por cargar (códigos mayores que 460) a los perfiles que tengan esa fila. Por eso, **ejecutar `01` en cada base solo cuando ahí se use el exe nuevo**.
