# FSCC-12957 (HU-01-T1): compensación automática de DI, Falabella Colombia (scripts de base de datos)

> **Para instalar T1 + T2 juntos usar la carpeta consolidada [`../FSCC-12901_T1_T2/`](../FSCC-12901_T1_T2/README.md).** Esta carpeta documenta solo esta subtarea; sus scripts son la fuente de las copias de la carpeta consolidada (mantener ambas iguales).

T1 registra automáticamente una **DI (Diferencia No Imputable)** por el monto de la Diferencia Real de cada cierre Y de la carga, si −1.000 ≤ DR ≤ 20.000 y DR ≠ 0. **No cierra cajas**: eso lo hace T2 (FSCC-12958), que llama a T1 al inicio de la misma ejecución.

> **07-10-2026:** con la documentación actualizada, Colombia opera **solo con cierre Y**. T1 ya trabajaba por Y y no cambia su lógica; T2 deja de cerrar la Z. El criterio **CA9** de la HU (DR = 0 por la imputación automática → validar y cerrar) se cumple porque T1 y T2 corren en la misma ejecución. `fn_dif_real` de T2 ahora exige el número de Y.

## Qué se reutiliza de FSCC-12958 (`docs/sql/FSCC-12958/`)

| Objeto | Uso en T1 |
|---|---|
| `VTA_FACOPRD_CIERRE` + `TRG_VTA_FACOPRD_CIERRE_AI` | **Mismas "cajas de la carga"**: los cierres Y pendientes (`pcr_estado = 'P'`) que dejó el trigger. T1 **no modifica** la cola; el estado lo maneja T2 |
| `VTA_FACOV_CAJAS_CIERRE` (vista, ajuste DF-SCC) | **Universo que recorre T1**: la cola + los cierres Y abiertos sin sobres del mismo local y día (`CA_SIN_SOBRE`). Así una caja sin movimiento con DR en rango también recibe la DI. Es el mismo universo que cierra T2 |
| `PKG_F8_FACO_CIERRE_AUTO.fn_dif_real` | Misma Diferencia Real que la F8 (`Label70` de `Form3Y`): una sola fórmula para T1 y T2 |
| `PKG_F8_FACO_CIERRE_AUTO.fn_param` | Lectura de parámetros tipo 1502 |
| `VTA_FACOLOG_CIERRE_AUTO` | Mismo registro de ejecución, con `log_proceso = 'T1'` |
| `CA_DECIMAL`, `CA_DIAS` | Parámetros comunes |

## Conexión con el SP de cierre (diagrama general: T1 → T2)

```
job --> PKG_F8_FACO_CIERRE_AUTO.prc_cierre_automatico
          1. marca omitidas (sin Y) y vencidas en la cola
          2. PKG_F8_FACO_COMPENSA_DI.prc_compensa_di(g_ejecucion)     <-- T1 (si CA_DI_ACTIVO = S)
                 por cada Y pendiente: DR -> rango -> DI previa -> registra DI -> DR = 0
          3. si CA_ACTIVO = S: cierre de las Y (T2; la Z no se toca), que recalcula la DR
             e incluye las cajas recién compensadas por T1
```

- Los interruptores son **independientes**: `CA_DI_ACTIVO` (T1) y `CA_ACTIVO` (T2). Se puede correr solo T1, solo T2 o ambos.
- Un error en T1 se registra y **no impide** que corra T2.
- T1 también se puede ejecutar solo: `begin PKG_F8_FACO_COMPENSA_DI.prc_compensa_di; end;`
- El botón "Cerrar Terminal" de `Form43` (FACO) llama a `PKG_F8_FACO_CIERRE_AUTO.prc_cierre_rango`, que **no** ejecuta T1: la DI automática solo la registra el proceso agendado.
- DF-SCC fila 57 ("hasta −1.000 faltante e inferior a 20.000 sobrante") = esta subtarea. Se mantiene el rango inclusivo (respuesta de negocio del 01-10); si negocio confirma "inferior" como exclusivo, basta con `CA_DI_MAX = 19999`.

## Reglas implementadas (FSCC-12957 + diagrama del proceso 1)

Por cada cierre Y de la vista `VTA_FACOV_CAJAS_CIERRE` (cola pendiente + cajas sin sobres del mismo local-día), en este orden:

| # | Regla | Resultado en el log (`log_proceso = 'T1'`) |
|---|---|---|
| 1 | La caja debe existir y estar abierta (`termstaty.ter_estado ≤ 0`), con bloqueo `NOWAIT`. `Form38` tampoco permite DI en una caja cerrada | `SIN_TERMSTAT`, `OCUPADA`, `YA_CERRADA` |
| 2 | **Base:** DR = Diferencia de caja − Compensación, igual que la F8, después de las compensaciones manuales previas | — |
| 3 | Sin libro de ventas de la Y | `SIN_LIBVTA` |
| 4 | DR = 0 → sin DI, pasa a T2 | `DR_CERO` |
| 5 | **Rango** `CA_DI_MIN` ≤ DR ≤ `CA_DI_MAX` (inclusive). Fuera de rango → pendiente para gestión de tiendas | `FUERA_RANGO` |
| 6 | **Segunda carga:** si la Y ya tiene una DI automática, no se crea otra (DUD-050) | `DI_AUTO_PREVIA` |
| 7 | Si la Y ya tiene una DI **manual**, no se toca | `DI_MANUAL_PREVIA` |
| 8 | **Registrar DI = DR, mismo signo** (DR −22 → DI −22) | — |
| 9 | Control: recalcula la DR; si no quedó en 0, revierte la DI | `ERROR` |
| 10 | OK | `DI_REGISTRADA` |

**Cómo se graba la DI** (igual que el exe, `Módulo1.InsertarRegistroMovDet`, `FTEPROD/Módulo1.bas:3777`):

```
VTA_FACOMOVDET: mov_tipomov 'DI', mov_rol 0, mov_nombre ' ', mov_secuencia 0, mov_numero 0,
                mov_monto = round(DR,2), mov_hechopor = 'PROC_DI_AUTO', mov_regul 'S',
                mov_fechareg = mov_fecha = fecha de venta  (fecha contable = fecha de venta),
                mov_techkey = SEQ_VTA_FACOVEN.nextval, mov_cierrey = Y
VTA_FACOCOMPDES: cpd_tipmov 'DI', cpd_obs 'COMPENSACION AUTOMATICA DI', cpd_cierrey = Y
                (UPDATE si ya existe, como Form45; cpd_secuencia por TRG_VTA_FACOCOMPDES_I_SEQ)
```

**Identificación** (CA5 / DUD-052): `mov_hechopor = 'PROC_DI_AUTO'` y la glosa fija. El Informe de Diferencias (`Form7`) ya muestra `mov_hechopor`. El Envío Contable (`Form62`) suma la DI por fecha y local: separar la DI automática ahí requiere un cambio en el exe, que queda fuera de estos scripts.

## Parámetros nuevos (`VTA_FACOPARAM`, tipo 1502)

| Código | Valor inicial | Uso |
|---|---|---|
| `CA_DI_ACTIVO` | S | T1 activa |
| `CA_DI_MIN` | −1000 | Límite inferior de la DR (inclusive) |
| `CA_DI_MAX` | 20000 | Límite superior de la DR (inclusive) |

El rango de la **DI manual** (`1500`/`1501` `'DI'`, hoy −500 / 20.000, que usa `Form38`) **no se modifica**.

## Orden de instalación (T1 + T2 juntos)

Todo conectado como el **dueño** de las tablas `VTA_FACO*`. Los scripts no llevan prefijo de esquema.

| Paso | Script |
|---|---|
| 1 | `FSCC-12958/00_prechecks.sql`, `01_tabla_homologa.sql`, `02_log.sql`, `03_parametros.sql`, `03b_vista_cajas.sql`, `03c_permiso_cc.sql`, `05_pkg_cierre_auto_spec.sql` |
| 2 | `FSCC-12957/00_prechecks.sql` (los ítems 1 y 9 pueden estar incompletos hasta el paso 4) |
| 3 | `FSCC-12957/01_ajuste_log.sql` (idempotente), `02_parametros.sql`, `03_pkg_compensa_di_spec.sql`, `04_pkg_compensa_di_body.sql` |
| 4 | `FSCC-12958/06_pkg_cierre_auto_body.sql` (llama a T1), `04_trigger.sql`, `07_grants_sinonimos.sql` |
| 5 | `FSCC-12957/05_grants_sinonimos.sql` |
| 6 | Pruebas: `FSCC-12958/08_pruebas.sql` y `FSCC-12957/06_pruebas.sql` |

Dependencias: el cuerpo de T1 usa la especificación de T2 (`fn_dif_real`, `fn_param`), y el cuerpo de T2 usa la especificación de T1 (`prc_compensa_di`). Las dos especificaciones van antes que los dos cuerpos.

## Scripts

| Script | Contenido |
|---|---|
| `00_prechecks.sql` | 9 verificaciones de solo lectura, cada una con el resultado esperado |
| `01_ajuste_log.sql` | Agrega `LOG_PROCESO` al log si FSCC-12958 se instaló con la versión anterior |
| `02_parametros.sql` | `CA_DI_ACTIVO`, `CA_DI_MIN`, `CA_DI_MAX` |
| `03` / `04` | `PKG_F8_FACO_COMPENSA_DI`: `prc_compensa_di` (entrada), `fn_evalua_caja` (simulación sin grabar), `fn_estado_di` |
| `05_grants_sinonimos.sql` | `EXECUTE` y sinónimo para el usuario de aplicación (lo pide con `accept`) |
| `06_pruebas.sql` | Compilación, simulación de todo el universo (vista), caja puntual, T1 solo, T1 + T2, resumen, DI registradas y 14 casos |
| `99_rollback.sql` | Apagar T1 (recomendado), revertir las DI de una ejecución o desinstalar |

## Supuestos verificados en test (06-10-2026)

| Supuesto | Resultado |
|---|---|
| Concepto `DI` en `VTA_FACOCONCEPDIF` | Existe (coddif 8, "Diferencia no Imputable") |
| `SEQ_VTA_FACOVEN` | Existe; es la que usa el exe para el `mov_techkey` |
| `VTA_FACOCOMPDES` | `cpd_secuencia` la asigna `TRG_VTA_FACOCOMPDES_I_SEQ`; `cpd_obs` VARCHAR2(1024) |
| `VTA_FACOMOVDET` | `MOV_NOMEMPLEADO`, `MOV_EMPEMPLEADO`, `MOV_REGUL` y `MOV_CIERREY` tienen default. PK solo en `mov_techkey`, así que **la base no impide duplicar DI**: lo controla el paso 6/7 |
| DI con `mov_rol ≠ 0` | Existen en datos históricos. Por eso la DI previa se busca en **todas** las DI de la Y |
| `mov_hechopor` | VARCHAR2(50); `PROC_DI_AUTO` cabe |

## Riesgos y notas

- **Interacción con `Form38`.** Si el analista abre la DI de una caja con DI automática, `Form38` la muestra y puede **modificarla** (actualiza la DI con `mov_rol = 0`, sin cambiar `mov_hechopor`). Se acepta: es una corrección manual consciente.
- **Envío Contable:** ver "Identificación" (cambio en el exe pendiente de definir con Contabilidad).
- **Cajas fuera de rango** quedan en la cola (`P`) y T2 las reevalúa en cada ejecución hasta `CA_DIAS`. T1 también las reevalúa; si el analista compensa una parte y la DR entra en el rango, la siguiente ejecución registra la DI.
