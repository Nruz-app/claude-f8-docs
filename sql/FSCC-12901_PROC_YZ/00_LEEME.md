# FSCC-12901 PROC_YZ: cierre automático de la Y **y de la Z** (FACO)

Creada el 15-10-2026 a partir de `docs/sql/FSCC-12901_PROC_Y/` (la v2 multipaís, antes `FSCC-12901_POC_v2`), que queda intacta y sigue siendo la versión **solo Y** que se traspasa a test.

PROC_YZ agrega el cierre de la **Z** (`VTA_FACOTERMSTAT`), por si negocio confirma que va. La Z queda **apagada por defecto** (`CA_CIERRA_Z = N`). Así, instalar PROC_YZ produce el mismo resultado que PROC_Y hasta que se active la Z con un `update`.

## Por qué la Z

El exe sí tiene previsto cerrar la Z en Colombia:
- **`Form3.CierraTerminal`** (candado con la F8 de la Z activa) tiene condiciones que nombran FACO a propósito: cheques a fecha, Z = suma de las Y y todas las Y cerradas.
- **`Form43`** (botón Cerrar Terminal) primero cierra las Y y después las Z.
- **`Form62`** (envío a FOSO) exige que las Z del local estén cerradas, en estado 1 o 2.

Hoy el usuario de negocio está averiguando si la Z se gestiona. Ver `docs/README_FSCC-12901.md` §5f.

## Qué cambia frente a PROC_Y

| Archivo | Cambio |
|---|---|
| `07_pkg_cierre_auto_body.sql` | Cierre de la Z: `pr_procesa_z`, `pr_valida_z`, `fn_z_suma_y`, `fn_dolares_z`, `pr_y_cerradas`; `fn_rz` (SQL de la Y → SQL de la Z); `p_cierrey` nulo = Z en `pr_cuadratura`, `fn_concepto_pendiente` y `fn_zzz`; llamada a la Z al final de `prc_cierre_automatico` y de `prc_cierre_dia` |
| `04_pkg_cierre_auto_spec.sql` | Publica `fn_z_suma_y`, `fn_dolares_z` y `pr_valida_z`. Documenta que `p_cierrey` nulo significa Z. **Las firmas existentes no cambian**: siguen sirviendo el job, `Form43` y T1 |
| `03_parametros_FACO.sql` | 4 parámetros nuevos (12 en total) |
| `00_prechecks.sql` | Verificaciones 15 a 20, propias de la Z |
| `10_pruebas.sql` | Pruebas 12 a 15 y la matriz Z0 a Z11 |
| `99_rollback.sql`, `00b_DESINSTALAR_TODO.sql` | Reabren las Z cerradas por el proceso y borran los parámetros nuevos |
| `INSTALAR.sql` | Solo textos |
| **Nuevos** `ACTUALIZAR_DESDE_PROC_Y.sql` / `VOLVER_A_PROC_Y.sql` | Pasan de PROC_Y a PROC_YZ en una base que ya tiene PROC_Y (y vuelven) |
| `traspaso_test/` | Traspaso único YZ, generado desde el de PROC_Y: cambian solo las partes 0, 1c, 2a y 2d |

No cambian (copias idénticas a PROC_Y): `01`, `02`, `03c`, `05`, `06`, `08`, `09`. No se crean tablas ni columnas: el log ya admite `log_nivel = 'Z'` y `log_cierrey` nulo. Tampoco hay cambios en el exe: `Form43` ya llama a `prc_cierre_dia`, que ahora también cierra las Z.

## Parámetros nuevos (1502)

| Código | Valor inicial | Uso |
|---|---|---|
| `CA_CIERRA_Z` | **N** | Interruptor de la Z. Con N la Z no se toca |
| `CA_Z_SIN_Y` | N | Un terminal sin ninguna Y **no** cierra la Z. El exe sí la deja cerrar (D2) |
| `CA_Z_VAL_SUMA` | S | RZ-06: la Z debe ser igual a la suma de las Y, campo por campo según `VTA_PAINT_Z` |
| `CA_Z_VAL_DOL` | N | RZ-09: dólares declarados = dólares de la transportadora (opción 109 del exe) |

La Z reutiliza `CA_VAL_CHEQ` (RZ-01) y `CA_VAL_ZZZ` (RZ-08).

Para activar la Z: `update VTA_FACOPARAM set vta_xglosa = 'S' where vta_ccodtipo = 1502 and vta_ccodigo = 'CA_CIERRA_Z'; commit;`

## Flujo con la Z activa

1. Se carga un sobre (`Form133` u otra vía). `Form133` además **reabre la Z** (la pone en `ter_estado = 0`). El trigger deja el sobre en la cola en estado P.
2. `prc_cierre_automatico('FACO')`: toma la carga, ejecuta T1 (DI) y T2 (cierre de las Y), sin cambios respecto de PROC_Y.
3. **Paso nuevo:** se evalúa la Z de cada terminal y día cuyas Y se evaluaron (`pr_procesa_z`), en este orden. La primera regla que falla queda en el log y la Z sigue abierta:

| Paso | Regla | Resultado en el log si falla |
|---|---|---|
| Bloqueo de la fila (`FOR UPDATE NOWAIT`) | — | `OCUPADA` / `Z_SIN_TERMSTAT` |
| Estado de la Z (1, 2 o 3 = ya cerrada) | RZ-02 | `Z_YA_CERRADA` |
| **Todas las Y del terminal-día en 1** (todas las filas de `TERMSTATY`; sin Y no cierra) | RZ-07 | `Z_Y_ABIERTAS` / `Z_SIN_Y` |
| Existe libro de ventas `'F8'` | RZ-05 | `Z_SIN_LIBVTA` |
| Diferencia real del día = 0 | RZ-05 | `Z_CON_DIFERENCIA` |
| Cheques a fecha: gestión = tesorería | RZ-01 | `Z_BLOQUEADA` |
| Conceptos sin regularizar en todo el día | RZ-03 | `Z_BLOQUEADA` |
| Z = suma de las Y | RZ-06 | `Z_BLOQUEADA` |
| Fórmula ZZZ de la Z (si `CA_VAL_ZZZ = S`) | RZ-08 | `Z_BLOQUEADA` |
| Dólares (si `CA_Z_VAL_DOL = S`) | RZ-09 | `Z_BLOQUEADA` |
| `UPDATE VTA_FACOTERMSTAT` (estado 1, `PROC_CIERRE_AUTO`, nota `CIERRE AUTOMATICO Z FSCC-12901 …`) | — | `CERRADA_Z` |

4. El log `FIN` agrega "Z evaluadas / cerradas / no cerradas". La Z no cambia la cola, que es por Y.
5. **CC (`Form43`, `prc_cierre_dia`):** después de las Y, evalúa las Z abiertas del día, local y terminal, incluidas las de terminales cuyas Y ya estaban cerradas. Los contadores de salida siguen siendo de Y.

### Cómo se calcula la Z

Se usan las mismas consultas de la Y (`pr_cuadratura`, compensado, conceptos, ZZZ) con dos cambios, igual que en el exe:
- **Libro de ventas `'F8'`** en lugar de `'Y'`.
- **Sin filtro de número de Y.** `fn_rz` reemplaza cada `alias.columna = :b_y` por `1 = 1`.

Con `p_z = FALSE`, `fn_rz` es exactamente `fn_r`, así que **el SQL de la Y no cambia**. Una consecuencia, igual que en `Form3`: en la Z cuentan también los sobres con `prv_cierrey = 0`.

## Diferencias con el exe (decididas)

| Tema | Exe (`Form3`) | PROC_YZ |
|---|---|---|
| Terminal sin ninguna Y | Avisa y deja cerrar la Z (D2) | No cierra (`Z_SIN_Y`), salvo `CA_Z_SIN_Y = S` |
| Qué Y revisa RZ-07 | Solo las que tienen libro de ventas | Todas las filas de `TERMSTATY` del terminal-día (más estricto, igual que el cierre general de `Form52`) |
| Orden de las reglas | RZ-01, 02, 03, 05, 06, 07, 08, 09 | 02, 07, 05, y después 01, 03, 06, 08, 09. Es el mismo conjunto; RZ-07 va primero porque es el requisito del negocio |
| Perfiles exentos de RZ-01 (8, 10, 12) | Sí | No aplica: el proceso no tiene perfil. Se controla con `CA_VAL_CHEQ` |
| Concurrencia | Sin bloqueo | `FOR UPDATE NOWAIT` sobre la fila de la Z (D5) |

## Cuidados

- **`Form19` (ingreso manual de la Z) borra las Y en FACO.** Borra el libro de ventas `'Y'` y todas las `TERMSTATY` del terminal y día; ver `docs/README_FSCC-12901.md` §5f. Si la Z llega por el proceso externo no hay problema, pero conviene avisar a los usuarios que no la ingresen a mano.
- **Con la Z cerrada, `Form19Y` no deja ingresar Y nuevas.** Para eso hay que reabrir con `Form20`. Una carga de sobres por `Form133` también la reabre.
- **Sin libro de ventas `'F8'` la Z nunca cierra.** Revisarlo con el precheck 20 antes de activar.
- **No probado en la base.** Se entrega como scripts; compilar y probar lo hace el usuario.

## Archivos y orden

| Escenario | Qué ejecutar |
|---|---|
| Base **sin** FSCC-12901 | `INSTALAR.sql` (00 → 08) y luego `09` |
| Base **con PROC_Y** (test después del traspaso) | `ACTUALIZAR_DESDE_PROC_Y.sql`. Para volver: `VOLVER_A_PROC_Y.sql` |
| Test, archivo único | `traspaso_test/TRASPASO_TEST_FSCC-12901_YZ.sql`, solo si test **no** tiene PROC_Y |
| Desarrollo, reinstalar desde cero | `00b_DESINSTALAR_TODO.sql` y luego `INSTALAR.sql` |

Después de instalar o actualizar:
1. `10_pruebas.sql`, bloques 1 a 11 (son los mismos de PROC_Y y deben dar lo mismo).
2. Bloques 12 y 13, con `CA_CIERRA_Z = N`, que no graban nada.
3. Recién después activar la Z (bloque 14) y revisar el resultado (bloque 15).

Convenciones: scripts en ASCII, sin prefijo de esquema, sin `&` y compatibles con Oracle 10.2 (`REGEXP_REPLACE`, `DBMS_SQL` y q-quote existen en 10g). No se guardan claves.
