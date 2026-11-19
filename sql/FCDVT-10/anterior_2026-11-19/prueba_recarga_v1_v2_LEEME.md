# FCDVT-10 (HU-03): prueba de recarga v1 / v2 — carga masiva de Tottus Chile (SFCL)

Armada el 12-11-2026. Es **la misma prueba que la sesión 7 de FACO** (`docs/sql/FCDVT-14/prueba_carga_y_compensa_di_s7/`, pruebas 5 y 6), adaptada a Tottus. Se cargan **dos archivos** en Form174 con la misma fecha, local y terminal y **otro monto que también cuadra** (`carga_v1.csv` y después `carga_v2.csv`), para saber **qué monto queda al final**.

Diferencias con la sesión 7 de FACO:
- **Sin DI ni sobres.** En SFCL la compensación automática no está habilitada (`PKG_F8_COMPENSA_DI_CARGA.pr_config` tiene SFCL comentado y `Form133` la llama solo con FACO), así que la prueba es solo la recarga.
- **Los CSV no vienen hechos.** El encabezado de Tottus sale de `VTA_PAINT_Z` (unas 80 columnas), que no está en el clon offline, y Buscar rechaza la carga si no es idéntico. Por eso la carpeta trae un **generador** (`arma_prueba.py`) que arma los CSV con el `VTA_PAINT_Z` real exportado de test.

## Respuesta esperada (según el código)

`PKG_F8_GRABA_MASIVA_YZ_SFCL.pr_graba_ingresar` (`../04c_pkg_f8_graba_masiva_yz_sfcl_body.sql`), para un grupo INGRESAR:

- **Reemplaza**: borra la zzz de los techkeys, la libvta `F8`/`Y` y **todas** las termstaty del terminal-día, y graba lo del archivo nuevo (las Y quedan en −1).
- Si el grupo **no trae Y**, crea la **Y1 como copia de la Z** (`Form19.GrabaYprima`).
- Solo rechaza si la Z o alguna Y del día está **cerrada** (estado 1 o 2), tanto en Buscar como en Cargar.
- El mensaje agrega `. Reemplazo lo anterior: n Z y m Y`.
- La termstat de la Z solo se inserta si no existe, así que conserva la glosa de la carga v1.
- `TRG_VTA_SFCLZZZ_I`: al insertar la zzz de la Z borra las `VTA_SFCLTARJ` 2001–2999 y los movimientos 'AL' del terminal-día; cada Y los vuelve a crear. Por eso no deberían quedar filas huérfanas de una Y que v2 no trae.

Por lo tanto **queda el monto del último archivo (v2)**, en la Z y en las Y. Las Y de v1 que v2 no trae se borran.

## Escenarios (4 terminales libres del mismo local, TA a TD)

| # | T | v1 (`carga_v1.csv`) | v2 (`carga_v2.csv`) | Esperado al final |
|---|---|---|---|---|
| 1 | TA | Z + Y1 = 1.000.000 | Z + Y1 = 1.200.000 | Z y Y1 = **1.200.000**. Mensaje v2: `Grabado: Z + 1 Y (numeros 1 a 1). Reemplazo lo anterior: 1 Z y 1 Y` |
| 2 | TB | Z 1.000.000 + Y1 600.000 + Y2 400.000 | Z + Y1 = 1.150.000 | Z y Y1 = **1.150.000**; **la Y2 desaparece**. `Grabado: Z + 1 Y (numeros 1 a 1). Reemplazo lo anterior: 1 Z y 2 Y` |
| 3 | TC | Z sin Y = 800.000 (Y1 automática) | Z sin Y = 950.000 | Y1 automática con **950.000**. `Grabado: Z + Y1 automatica (copia de la Z). Reemplazo lo anterior: 1 Z y 1 Y` |
| 4 | TD | Z 800.000 + Y1 500.000 + Y2 300.000 | Z sin Y = 900.000 | Se borran las 2 Y de v1 y queda la Y1 automática con **900.000**. `Grabado: Z + Y1 automatica (copia de la Z). Reemplazo lo anterior: 1 Z y 2 Y` |

En v2 también cambian la hora, la secuencia, la boleta y el contador de reposición, para ver en la libvta que la identificación es la de v2. La venta va en BOLETAS. Una columna de pago (EFECTIVO, si está en la fórmula) lleva el mismo monto para que la Z cumpla la fórmula de `VTA_PAINT_Z`. Todas las cajas quedan abiertas (−1).

## Prerrequisitos

FCDVT-10 **todavía no está instalado ni compilado en test** (ver `docs/README_FCDVT-10.md` §5). Antes de esta prueba hay que tener:

1. `../INSTALAR.sql` ejecutado en test, con los dos packages `VALID` y sin `user_errors`;
2. el exe compilado con `Form174` y `MDIForm1` de FCDVT-10;
3. `../01_menu_ingreso_masivo_y_sfcl.sql` ejecutado (permiso 460 de SFCL), y un usuario de Tottus con ese perfil.

Además hacen falta Python 3 y `openpyxl` (este último solo para el Excel de resumen).

## Pasos

1. **`py0_prechecks.sql`** (solo lectura):
   - consultas 1 y 2: objetos de FCDVT-10 y permiso 460;
   - **consulta 3**: exportar el resultado completo a **`paint_z_sfcl.csv`** en esta carpeta, con separador `;` y encabezado (`FILA;VTA_CMP_ASOC;VTA_POP_UP;VTA_VALIDADORZZZ;VTA_SIGNO;VTAGLOSA_Z`);
   - **consulta 4**: guardar el texto en **`encabezado.txt`** (una línea). El generador lo compara con el que arma;
   - consultas 6 y 7: elegir un local y **4 terminales libres** el 11-11-2026 (en la 7, completar el local en la línea `-- EDITAR`).
2. **Generar** (desde esta carpeta):
   ```
   python -I arma_prueba.py --local <local> --terminales <TA>,<TB>,<TC>,<TD>
   ```
   Opciones:
   - `--fecha dd-mm-yyyy`: por defecto 11-11-2026. Si se cambia, también hay que cambiar la fecha en las consultas 6 y 7 de py0;
   - `--col-pago COL`: fuerza la columna de pago de la fórmula;
   - `--paint` y `--encabezado`: otras rutas para los dos archivos de entrada.

   Genera `carga_v1.csv`, `carga_v2.csv`, `py2_resultados.sql`, `py9_limpiar.sql` y `Prueba-Recarga-SFCL_Resumen.xlsx`. Se detiene con un error si:
   - el encabezado no coincide con `encabezado.txt`;
   - `VTA_PAINT_Z` no tiene la forma que exige el package (filas 2 a 6 de venta y fila 7 de total);
   - no puede cuadrar la fórmula de la Z.
3. F8 con el usuario de Tottus: local elegido, fecha 11-11-2026.
4. **Carga v1**: botón Y ▸ "Ingreso del YYY Masivo" (`Form174`) ▸ **Buscar** `carga_v1.csv` ▸ 4 grupos `CARGADO` (1.000.000, 1.000.000, 800.000 y 800.000) ▸ **Cargar** ▸ anotar el número de carga v1.
5. **`py2_resultados.sql`**: lo que dejó v1. En los ESPERADO va entre paréntesis.
6. **Carga v2**: **Buscar** `carga_v2.csv` ▸ 4 grupos `CARGADO` (1.200.000, 1.150.000, 950.000 y 900.000) ▸ **Cargar** ▸ cada mensaje termina en `Reemplazo lo anterior: 1 Z y n Y`.
7. **`py2_resultados.sql`** de nuevo. **E1 es la respuesta**: total de la Z, cantidad y suma de las Y, y la carga que dejó la Y. Además:
   - B2: 2 filas por terminal, sin restos de v1;
   - C1: una sola termstaty por terminal;
   - D1: `VTA_SFCLTARJ` solo con cierrey 1.
8. En pantalla (F8 / Form19Y): la Z y la Y1 de cada terminal con el monto de v2.
9. Para repetir: **`py9_limpiar.sql`**. Primero con `v_ejecutar = 'N'`, que solo cuenta; con `'S'` borra y hace commit al final. Después, Buscar + Cargar v1 y v2 de nuevo.

## Archivos

| Archivo | Qué es |
|---|---|
| `py0_prechecks.sql` | Verificaciones previas (solo lectura) y las dos exportaciones que necesita el generador |
| `arma_prueba.py` | Generador. Replica `prc_config` de `PKG_F8_CARGA_MASIVA_YZ_SFCL` (encabezado y fórmula) y verifica cada CSV antes de grabarlo: 11 + n columnas, Z = ΣY y fórmula de la Z en 0 |
| `plantillas/py2_resultados.sql.tpl` | Plantilla de los resultados (A: cargas y log; B: libvta, filas y columna de pago; C: termstat(y); D: TARJ y 'AL'; E: monto final) |
| `plantillas/py9_limpiar.sql.tpl` | Plantilla de la limpieza |
| `paint_z_sfcl.csv`, `encabezado.txt` | Entradas, exportadas de test por el usuario (paso 1) |
| `carga_v1.csv`, `carga_v2.csv`, `py2_resultados.sql`, `py9_limpiar.sql`, `Prueba-Recarga-SFCL_Resumen.xlsx` | Salidas del generador (paso 2). No se editan a mano: se vuelve a correr el generador. El Excel tiene las hojas Resumen (un bloque por prueba con el MONTO FINAL resaltado), Recarga v1-v2 y Pasos |

## Si algo falla

- **Buscar rechaza la carga por encabezado:** `paint_z_sfcl.csv` está incompleto (se exportó sin las filas de `vta_cmp_asoc` nulo o en otro orden) o no es del mismo ambiente. Exportar de nuevo la consulta 3, guardar `encabezado.txt` y volver a generar: si no coinciden, el generador lo dice.
- **Grupo en ERROR "Z descuadrada según la fórmula":** la columna de pago elegida no es la que corresponde, o una columna de la fórmula no existe y el package la desactiva (consulta 5 de `../00_prechecks.sql`). Probar con `--col-pago`.
- **ERROR "Local / terminal no existe o no está vigente":** la terminal no está en `VTA_SFCLTERMINALES` o está dada de baja; elegir otra en py0 consulta 7.
- **Cargar v2 da ERROR por Y cerrada:** alguien cerró la caja entre v1 y v2. Es el comportamiento correcto (no se reemplaza); limpiar con py9 y empezar de nuevo.
- **B2 muestra más de 2 filas por terminal después de v2:** Cargar no reemplazó. Revisar el mensaje en `Form175` y la parte A.
- **D1 muestra cierrey 2 con `y_existe = NO`:** quedó una `VTA_SFCLTARJ` huérfana de la Y2 de v1. El trigger no se comportó como se esperaba; anotarlo como hallazgo.
