# FSCC-12948 - Rematch automatico depositaria Prosegur (scripts)

Indice y analisis del requerimiento: `docs/README_FSCC-12948.md`.

Estado (19-10-2026): scripts 01, 02 y 03 listos, **no ejecutados** (los ejecuta el usuario). Instalar con `@INSTALAR.sql` (01 + 02 + 03 + estado); antes `00_prechecks.sql`; para volver `99_rollback.sql`.

Diseno: **1 trigger + 1 package**. La validacion del match, que antes estaba repetida en el trigger y en el SP, vive en `PKG_TRANSACC_DEPO_QUEUE.FN_VALIDA_MATCH`, y la usan los dos:

```
INSERT VTA_TEMP_CAB (POST, tipo 53)
  -> TRG_TRANSACC_DEPO_QUEUE -> FN_VALIDA_MATCH(idtrx, local, terminal, fecha) > 0 -> INSERT cola PENDIENTE
cron -> PKG_TRANSACC_DEPO_QUEUE.PROC_TRANSACC_DEPO_QUEUE (hasta 500 PENDIENTE)
  -> lee la venta en VTA_TEMP_CAB -> FN_VALIDA_MATCH(..., id_prosegur, id_queue)
       = 0 -> PROCESADO "OMITIDO -> ..." (no llama al package)
       > 0 -> F8_TRANSACC_DEPO_PKG.EXISTE_VTA_TEMPESC -> PROCESADO / ERROR
```

| Archivo | Contenido |
|---|---|
| `00_prechecks.sql` | SOLO LECTURA. Objetos y estado, cola por estado, duplicados en cola, cola sobre transacciones ya cuadradas (VALIDA = 1), pendientes sin cola con o sin venta POST, job del cron, log del package |
| `01_pkg_transacc_depo_queue.sql` | Package `PKG_TRANSACC_DEPO_QUEUE`: `FN_VALIDA_MATCH` (VALIDA = 0, barcode informado, local/terminal, `TRANSACTION_DATE` del dia de `VTA_FECHA`, VTA_TEMPESC corr 8 con el barcode, sin otra fila viva en la cola; devuelve el ID o 0; no lee VTA_TEMP_CAB ni hace DML) y `PROC_TRANSACC_DEPO_QUEUE` (el SP del cron, igual que antes, validando con la funcion) |
| `02_trg_transacc_depo_queue.sql` | Trigger: si la venta es tipo 53 y `FN_VALIDA_MATCH` devuelve un ID, encola PENDIENTE |
| `03_drop_proc_transacc_depo_queue.sql` | `DROP PROCEDURE PROC_TRANSACC_DEPO_QUEUE` (el SP suelto; ningun job lo llama) |
| `INSTALAR.sql` | `@01`, `@02`, `@03` y consulta de estado (package y body `VALID`, trigger `VALID`/`ENABLED`, SP suelto inexistente) |
| `99_rollback.sql` | Vuelve el SP suelto y el trigger a la linea base de `ddl_actual_desarrollo/` y borra el package |
| `anterior_2026-10-15/` | Version congelada el 15-10 (SP `01_proc_...` y trigger `02_trg_...` con la validacion repetida). Referencia; no se ejecuta |
| `ddl_actual_desarrollo/01..05` | Linea base en INTRANETDE el 14-10-2026: tabla cola, trigger, SP, spec y body de F8_TRANSACC_DEPO_PKG |

Cambios de comportamiento respecto del 15-10 (unicos):
- El trigger tambien exige `BARCODE` informado. Antes, con barcode nulo, el `LIKE '%%'` calzaba con cualquier venta.
- El cron deja OMITIDO una fila si hay **otra** fila viva (PENDIENTE/PROCESANDO) en la cola para la misma transaccion (duplicados anteriores al anti-duplicados del trigger, precheck 4).

Nota: se cruza por `TRANSACTION_DATE` porque el POST graba en `VTA_TEMP_CAB.VTA_FECHA` la fecha de venta (verificado en test, 50 de 50 matches). El cron tambien pasa esa fecha al package. El package `F8_TRANSACC_DEPO_PKG` no cambia.

Prueba rapida sin escribir (despues de instalar): `select PKG_TRANSACC_DEPO_QUEUE.FN_VALIDA_MATCH(<vta_idtrx>, <local>, <terminal>, to_date('<yyyymmdd>','yyyymmdd')) from dual;` con un caso de la consulta 7 de los prechecks (devuelve el ID de PROSEGUR_TRANSACTIONS o 0).

Checklist de prueba en test: `docs/README_FSCC-12948.md` seccion 9b. El job del cron (pendiente) debe llamar a `PKG_TRANSACC_DEPO_QUEUE.PROC_TRANSACC_DEPO_QUEUE`.

ATENCION: `ddl_actual_desarrollo/` es la linea base tal como esta en INTRANETDE el 14-10-2026: sirve para comparar y para el rollback. No se ejecuta.

Convenciones: sin prefijo de esquema, solo ASCII, compatible con Oracle 10.2.
