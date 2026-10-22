# Prueba 3: simulación en papel del paquete PROC_Y después de la carga

Fecha: 15-10-2026. **Es solo una traza en papel**: no se ejecutó nada ni se creó ningún objeto.

Objetivo: comprobar, antes de pasar los objetos de `docs/sql/FSCC-12901_PROC_Y` a test, qué haría el paquete si se lo llama al terminar la carga de `Form133`. La llamada sería `PKG_F8_CIERRE_AUTO.prc_cierre_automatico('FACO')`, que ejecuta primero T1 (`PKG_F8_COMPENSA_DI_AUTO`) y después T2.

Referencias:
- `07` = `07_pkg_cierre_auto_body.sql`
- `06` = `06_pkg_compensa_di_body.sql`
- `08` = `08_trigger_FACO.sql`
- `03` = parámetros

## 1. Datos: Excel `PRD-LIST-TEST-V3.xlsx`

| Local | Terminal | Sobre | Monto | Dif. | Fecha venta | Y |
|---|---|---|---|---|---|---|
| 6 | 29 | 3007295625 | 4.000.000 | 0 | 20260828 | 1 |
| 6 | 29 | 3110295626 | 4.000.000 | 0 | 20260828 | 1 |
| 6 | 29 | 3111295627 | 344.000 | 0 | 20260828 | 1 |
| | | | **8.344.000** | | | |

Es una sola caja (6 / 29 / 28-08-2026 / Y 1). Se simulan dos variantes de la Y manual sobre esa caja:

| Escenario | EFECTIVO de la Y | BOLETAS + FACTURA | DR esperada | Qué debería pasar |
|---|---|---|---|---|
| **A, feliz** | 8.344.000 | 8.344.000 (p. ej. 8.000.000 + 344.000) | 0 | T1 no hace nada, T2 cierra |
| **B, DI** | 8.343.500 | 8.343.500 (p. ej. 8.000.000 + 343.500) | **+500** (sobrante) | T1 registra una DI de +500 y T2 cierra |

La DR se calcula como sobres EFE − efectivo de la Y = 8.344.000 − efectivo (`07:578`). En B, +500 cae dentro del rango [−1.000, 20.000] (`CA_DI_MIN` / `CA_DI_MAX` en `03`).

Parámetros supuestos (los de `03`): `CA_ACTIVO = S`, `CA_DI_ACTIVO = S`, `CA_VAL_CHEQ = S`, `CA_VAL_ZZZ = N`, `CA_DECIMAL = 0`, `CA_SIN_SOBRE = S`.

## 2. Pantallas (igual que la prueba 2)

1. F8 con fecha 28-08-2026, local 6 y terminal 29 (que la Y 1 no exista).
2. `Form19Y`: N° de Y 0, que pasa a 1 al validar. EFECTIVO y BOLETAS + FACTURA según el escenario, el resto en 0. Graba:
   - `VTA_FACOLIBVTA` (tiporeg Y, secuencia 1, estado A);
   - `VTA_FACOZZZ` (`rec_mefectivo`);
   - `VTA_FACOTERMSTATY` (estado **−1**).
3. `Form133` con el Excel v3. Inserta 3 filas en `VTA_FACOPRD`: `prv_tiporec = 'F8'`, `prv_tiposobre = 'EFE'`, `prv_cierrey = 1`. Además reabre la Z.

## 3. Trigger (`08`)

`TRG_VTA_FACOPRD_CIERRE_AI` se dispara por cada sobre insertado con `prv_tiporec` en ('F8', 'DOL') y copia el sobre a `VTA_FACOPRD_CIERRE` en estado **P** con `pcr_intentos = 0`.

**Cola después de la carga:** 3 filas en P (6 / 29 / 28-08 / Y 1).

## 4. `prc_cierre_automatico('FACO')` (`07:946`)

| # | Paso | Línea | Efecto |
|---|---|---|---|
| 1 | `pr_config('FACO')`, `g_proceso = 'T2'`, `g_usuario = 'PROC_CIERRE_AUTO'` | 960 | — |
| 2 | `fn_nueva_ejecucion` | 964 | Toma el número de ejecución **N** de `SEQ_VTA_FACOLOG_CIERRE_AUTO` |
| 3 | Interruptores: `CA_ACTIVO` y `CA_DI_ACTIVO` en S | 968 | Continúa |
| 4 | Log | 972 | T2, `-`, **INICIO** |
| 5 | Sobres con Y = 0 pasan a O | 976 | 0 filas |
| 6 | Cola P → E con la ejecución N, commit | 987 | **3 filas en E**, `v_carga = 3` |
| 7 | T1 `prc_compensa_di('FACO', N)` | 1000 | Ver §5 |
| 8 | `CA_ACTIVO = S` | 1011 | Sigue con T2 |
| 9 | `fn_universo('FACO', N)` | 1025 | Ver §4.1. Universo: **1 Y** (6 / 29 / Y 1) |
| 10 | `pr_procesa_y` por cada Y | 1031 | Ver §6 |
| 11 | Lo que quede en E vuelve a P | 1041 | 0 filas |
| 12 | Log | 1050 | T2, `-`, **FIN**: "Sobres de la carga: 3 \| Cierres Y evaluados: 1 \| Y cerradas: 1 \| Y no cerradas: 0" |

### 4.1 Universo (`07:281`)

- **Rama COLA:** filas E de la ejecución N con `prv_cierrey <> 0`. Da 3 filas iguales (6 / 29 / 28-08 / 1), que el `UNION` reduce a **1**.
- **Rama SIN_SOBRE** (`CA_SIN_SOBRE = S`): toma **todas** las Y de `TERMSTATY` con `ter_estado <= 0` del mismo **local y fecha** de la carga (local 6, 28-08-2026) que tengan libro de ventas Y, **aunque no tengan sobres**.
  - La Y 1 de la terminal 27 (prueba 2) está cerrada (estado 1), así que no entra.
  - **Si existe otra Y abierta del local 6 ese día, entra al universo** (ver hallazgo H1).

## 5. T1: `prc_compensa_di` (`06`)

- Log T1 **INICIO**: "rango [-1000, 20000] | usuario PROC_DI_AUTO".
- Abre el mismo universo (`fn_universo` con N) y, por cada caja, ejecuta `pr_procesa_caja`:

| Paso | Escenario A | Escenario B |
|---|---|---|
| `savepoint sp_di` y `TERMSTATY` `for update nowait` | estado −1 (bloquea la fila) | ídem |
| `v_estado > 0` | no | no |
| `fn_evalua_caja` → `fn_dif_real` (`07:589` → `pr_cuadratura`) | Y: efectivo 8.344.000. Sobres EFE 8.344.000. Tesorería, tarjetas, USD y compensado 0 → **DR = 0** | Y: efectivo 8.343.500 → **DR = +500** |
| Resultado | **DR_CERO**: `rollback to sp_di`, log T1 "Diferencia real 0: sin DI, pasa al cierre (T2)" | Dentro de [−1.000, 20.000]. `fn_estado_di`: no hay DI previa → **COMPENSABLE** |
| `pr_registra_di` | — | INSERT en `VTA_FACOMOVDET`: `mov_tipomov 'DI'`, `mov_monto +500`, `mov_hechopor 'PROC_DI_AUTO'`, `mov_regul 'S'`, `mov_fecha = mov_fechareg = 28-08-2026`, `mov_cierrey 1`, techkey de `SEQ_VTA_FACOVEN`. UPDATE (o INSERT) de `VTA_FACOCOMPDES` DI con la glosa "COMPENSACION AUTOMATICA DI" |
| Recálculo de la DR | — | El compensado toma la DI en la rama "conceptos regularizados" (`07:495`; DI existe en `VTA_FACOCONCEPDIF`). DR = round(500 − 500) = **0**, commit |
| Log T1 | DR_CERO (dif 0) | **DI_REGISTRADA** (dif 500): "DI automatica por 500; diferencia real queda en 0" |

- Log T1 **FIN**: "Cajas evaluadas: 1".
- T1 no toca la cola: siguen 3 filas en E.

## 6. T2: `pr_procesa_y` (`07:835`)

| Paso | Línea | A y B |
|---|---|---|
| `savepoint sp_y`, `TERMSTATY` `for update nowait` | 846 | Estado −1 |
| RY-02: `v_estado > 0` | 875 | No |
| DR (`fn_dif_real`) | 885 | A: 0. B: 500 − 500 (DI) = **0** |
| RY-01 cheque a fecha (`CA_VAL_CHEQ = S`) | 760 | Gestión de cheques 0 = tesorería 0 → pasa |
| RY-03 conceptos SN…DP sin regularizar en la Y | 766 | B: la DI no está en la lista y además tiene `mov_regul 'S'` → pasa |
| RY-06 ZZZ (`CA_VAL_ZZZ = N`) | 776 | No se evalúa |
| UPDATE `TERMSTATY` | 915 | `ter_estado = 1`, `ter_cerradopor = 'PROC_CIERRE_AUTO'`, `ter_notas` = "CIERRE AUTOMATICO FSCC-12958 dd-mm-yyyy hh24:mi \| INGRESO MANUAL POR CIERRE DE Y" |
| Cola | 924 | 3 filas pasan a **C**, `pcr_resultado = 'CERRADA_Y'`, `pcr_intentos = 1`, `pcr_ejecucion = N` |
| commit y log T2 | 925 | **CERRADA_Y** (dif 0) |

## 7. Estado final esperado

| Objeto | Escenario A | Escenario B |
|---|---|---|
| `VTA_FACOTERMSTATY` 6 / 29 / Y 1 | estado **1**, `PROC_CIERRE_AUTO`, nota CIERRE AUTOMATICO | ídem |
| `VTA_FACOMOVDET` | sin cambios | +1 fila DI de **+500** (`PROC_DI_AUTO`, regul S) |
| `VTA_FACOCOMPDES` | sin cambios | DI con la glosa "COMPENSACION AUTOMATICA DI" |
| `VTA_FACOPRD_CIERRE` | 3 filas C / CERRADA_Y | ídem |
| `VTA_FACOLOG_CIERRE_AUTO` (ejecución N), en orden | T2 INICIO, T1 INICIO, T1 DR_CERO, T1 FIN, T2 CERRADA_Y, T2 FIN | T2 INICIO, T1 INICIO, **T1 DI_REGISTRADA (500)**, T1 FIN, T2 CERRADA_Y, T2 FIN |
| Z (`VTA_FACOTERMSTAT`) | no se toca (estado 0 por `Form133`) | ídem |
| **F8 Y en el exe** | Dif. de Caja 0, Compensación 0, DR 0, **Cerrado** | Dif. de Caja **500**, Compensación **500**, DR 0, **Cerrado** |

**Conclusión:** con estos datos los dos escenarios terminan bien. La lógica de T1 y T2 coincide con el cierre manual de la prueba 2: mismas fórmulas de `Form3Y` y la misma DR que mostró la pantalla. No se encontraron errores de lógica que impidan pasar los objetos. Sí hay que tener en cuenta los hallazgos de abajo.

## 8. Hallazgos de la simulación

| # | Hallazgo | Impacto | Recomendación |
|---|---|---|---|
| **H1** | Con `CA_SIN_SOBRE = S` el universo incluye **todas las Y abiertas del mismo local y fecha** con libro de ventas, aunque no tengan sobres (`07:300`). | En test, T1 podría registrar una DI y T2 cerrar Y **reales** del local 6 del 28-08-2026, si las hay. Según los datos del 07-10 no había cajas ese día, pero las pruebas 2 y 3 ya agregaron Y. | Antes de ejecutar, revisar que el local 6 del 28-08-2026 no tenga otras Y abiertas, o poner `CA_SIN_SOBRE = N` durante la prueba. |
| **H2** | Nada llama al paquete al terminar `Form133`: la decisión vigente es un job externo, y la llamada desde `Form133` está pendiente (B3). | En test hay que ejecutarlo a mano: `begin PKG_F8_CIERRE_AUTO.prc_cierre_automatico('FACO'); end;` como dueño o con sinónimo. | Ejecutarlo a mano en la prueba, o activar el job comentado del traspaso. |
| **H3** | **Orden:** si los sobres se cargan **antes** de ingresar la Y, T2 registra SIN_TERMSTAT o SIN_LIBVTA y deja la cola en C. Ingresar la Y después **no** vuelve a poner la caja en la cola; solo lo hace un sobre nuevo. | La caja quedaría abierta hasta otra carga o hasta cerrarla desde CC o a mano. | En la prueba, primero la Y y después la carga, como está previsto. Para producción, decidirlo con negocio (relacionado con B2). |
| **H4** | El trigger tiene `when others then null`. | Si la copia a la cola falla, el sobre se graba pero la caja no se evalúa, sin aviso. | Decisión ya documentada. Para revisarlo existe la consulta de conciliación de sobres sin fila en la cola. |
| **H5** | El objeto existente `PKG_F8_FACO_CIERRE_TER_PM_AP` también cierra Y con `AUTOMATICO` (Autopago). | Si cierra la Y antes, T2 registra YA_CERRADA. No es un error. | Usar una terminal que no sea de Autopago (revisar que la 29 no lo sea). |
| H6 | `pr_cuadratura` suma `tes_chefecha` y el exe toma la primera fila. | Ninguno: en test hay una fila de tesorería por Y. | Ya documentado (D6). |

## 9. Si después se prueba en test

1. Ejecutar el traspaso de `PROC_Y` (lo ejecuta el usuario o el DBA), incluyendo el trigger.
2. Revisar H1 y H5.
3. Repetir los pasos de pantalla del §2: Y primero, después la carga.
4. Ejecutar `prc_cierre_automatico('FACO')` a mano.
5. Abrir la F8 Y de la terminal 29 y comparar con el §7.
6. Para el escenario B se necesita **otra caja** (otra terminal, sobres nuevos y efectivo de la Y con 500 menos que los sobres), porque la terminal 29 ya quedaría cerrada con A.

## 10. Plan de la prueba 3 en test (flujo de cierre del paquete)

Requisito: los objetos de `PROC_Y` instalados en test (traspaso `traspaso_test/TRASPASO_TEST_FSCC-12901_v2.sql`, trigger incluido, 9 objetos VALID).

Se prueban 3 cajas en **terminales distintas**. Todas son del local 6, fecha 28-08-2026, Y 1, y cada una tiene **sobres con números nuevos**, porque `Form133` compara número de sobre + fecha.

| Caja | Terminal | Sobres | Efectivo de la Y (= BOLETAS + FACTURA) | DR | T1 esperado | T2 esperado | Estado final |
|---|---|---|---|---|---|---|---|
| **A, feliz** | 29 (Excel V3) | 8.344.000 | 8.344.000 | 0 | DR_CERO | CERRADA_Y | **Cerrada** |
| **2a, DI en rango** | otra (p. ej. 30) | Excel nuevo, total T | T − 500 | +500 | DI_REGISTRADA (+500) | CERRADA_Y | **Cerrada**; F8: Compensación 500 |
| **2b, fuera de rango** | otra (p. ej. 31) | Excel nuevo, total T | T + 1.500 | −1.500 | FUERA_RANGO | CON_DIFERENCIA (RY-05) | **Abierta**; F8: DR −1.500 |

Rango de la DI automática: de **−1.000** (faltante) a **+20.000** (sobrante), con los límites incluidos. DR = sobres − efectivo de la Y.

Orden por caja, o para todas juntas:
1. `Form19Y` (la Y primero).
2. `Form133` con el Excel. Se pueden poner las 3 cajas en un mismo Excel.
3. Ejecutar el paquete en SQL: `begin PKG_F8_CIERRE_AUTO.prc_cierre_automatico('FACO'); end;`
4. Revisar la F8 de cada Y.
5. Revisar el log: `select * from VTA_FACOLOG_CIERRE_AUTO where log_ejecucion = (select max(log_ejecucion) from VTA_FACOLOG_CIERRE_AUTO) order by log_id;`

Antes de ejecutar el paquete:
- **H1**: confirmar que el local 6 del 28-08-2026 no tenga **otras Y abiertas** con libro de ventas, o poner `CA_SIN_SOBRE = N` durante la prueba.
- **H5**: confirmar que las terminales no son de Autopago (`PKG_F8_FACO_CIERRE_TER_PM_AP`).

## 11. Caso 2: qué pasa después de un descuadre

- **Fuera de rango**: el paquete deja la Y abierta y registra en el log `FUERA_RANGO` (T1) y `CON_DIFERENCIA` (T2).
  - Los sobres de esa caja quedan en la cola en **C**: la caja **no se vuelve a intentar sola**.
  - El usuario la resuelve a mano:
    - **compensa** la diferencia (lo normal), o **corrige la Y** en `Form19Y` si se digitó mal (la Y sigue abierta);
    - después la **cierra** con el candado (`Form3Y.CierraTerminal`) o desde Consultas de Cuadratura (`Form43`, opción 1515, `prc_cierre_dia`, que cierra solo si la DR es 0).
- La caja **vuelve a entrar** al paquete solo en dos casos:
  - llega **otro sobre de esa misma caja**, que el trigger pone en P;
  - llega una carga de otra terminal del mismo local y día con `CA_SIN_SOBRE = S`. Esta rama solo toma Y **abiertas**.
- **Si el usuario ya la cerró a mano** y la caja vuelve a entrar:
  - T1 registra `YA_CERRADA`, porque el estado es mayor a 0 (`06`), y **no graba DI**;
  - T2 registra `YA_CERRADA` (`07:875`) y **no modifica** la Y (ni el usuario de cierre ni la nota);
  - la cola queda en C / YA_CERRADA. No hay doble cierre ni doble compensación.
- **DI manual previa** con la caja abierta: T1 registra `DI_MANUAL_PREVIA` y no agrega otra DI. Si la DI es de una carga anterior, registra `DI_AUTO_PREVIA`.
- **Otro usuario con la F8 abierta**: no bloquea, porque el exe no deja la fila bloqueada. Si la fila estuviera tomada, el paquete registra `OCUPADA` y la caja vuelve a P para la siguiente ejecución.
- **Brecha B2 (pendiente con negocio)**: una caja que el usuario **compensó pero no cerró** no se cierra sola. Queda abierta hasta que alguien la cierre (candado o CC) o llegue un sobre nuevo de esa caja.

## 12. Cómo retomar (el día de la prueba)

1. Leer este documento (§10 y §11) y la fila 38 del historial en `docs/README_FSCC-12901.md`.
2. Verificar el manifiesto: `grep -v '^#' docs/MANIFIESTO_FSCC-12901.md5 | md5sum -c`.
3. Confirmar con el usuario que el traspaso a test terminó y que los 9 objetos están VALID. Los sinónimos para `UINTRANETTS` los crea el DBA.
4. Revisar H1 y H5. Armar los Excel de 2a y 2b con sobres y terminales nuevos.
5. Guiar al usuario **por pantallas**, como en la prueba 2: Y, después carga, después ejecutar el paquete, después F8 Y. Comparar con la tabla del §10 y con el log.
6. Registrar el resultado: capturas, historial, manifiesto y ZIP.
