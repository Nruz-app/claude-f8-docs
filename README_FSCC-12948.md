# FSCC-12948: índice y bitácora del trabajo (rematch automático de la depositaria Prosegur)

Punto de entrada para retomar **FSCC-12948**: hacer match automático de las transacciones de la depositaria (`PROSEGUR_TRANSACTIONS`) que quedaron en `VALIDA = 0` porque, cuando llegaron, el POS todavía no había enviado la venta (proceso **POST**, que inserta en `VTA_TEMP_CAB` / `VTA_TEMPESC`).

Última actualización: **19-10-2026**. Diseño **1 trigger + 1 package**: el SP suelto pasó al package `PKG_TRANSACC_DEPO_QUEUE` (`PROC_TRANSACC_DEPO_QUEUE` + `FN_VALIDA_MATCH`, la validación común que usan el trigger y el cron). Scripts `01` (package), `02` (trigger) y `03` (drop del SP suelto) listos y **sin ejecutar**: los instala el usuario con `INSTALAR.sql`. El paso siguiente es la prueba en test (§9).

---

## 1. Requerimiento

| Ítem | Detalle |
|---|---|
| Problema | La API de Prosegur inserta la transacción en `PROSEGUR_TRANSACTIONS` e intenta el match con la venta del POS. Si el POST aún no llegó, queda `VALIDA = 0` / `MATCH_STATUS = 'NO_MATCH'` y nadie la vuelve a intentar |
| Hoy | Solo hay rematch manual: `Form172` (toolbar `CECB`) → `Form173` → `ExisteVtaTempEsc` → `F8_TRANSACC_DEPO_PKG.EXISTE_VTA_TEMPESC` |
| Solución propuesta | Cuando llega el POST, el trigger `TRG_TRANSACC_DEPO_QUEUE` (sobre `VTA_TEMP_CAB`) encola el par venta/transacción en `PROSEGUR_TRANSACTIONS_QUEUE`; un job (cron) ejecuta `PROC_TRANSACC_DEPO_QUEUE`, que llama al mismo `EXISTE_VTA_TEMPESC` |
| Alcance de esta etapa | Entender el flujo, corregir el SP y el trigger con scripts (los ejecuta el usuario) y validar con consultas de **solo lectura** en desarrollo y test. El package `F8_TRANSACC_DEPO_PKG` y el exe (`Form173`) **no cambian** (decisión del usuario del 14-10: "SP + trigger") |

## 2. Estado

| Frente | Estado |
|---|---|
| Lectura de objetos en desarrollo (`INTRANETDE`) | ✔ Completo (14-10) |
| Línea base del DDL actual | ✔ `docs/sql/FSCC-12948/ddl_actual_desarrollo/` |
| Prechecks de solo lectura | ✔ `docs/sql/FSCC-12948/00_prechecks.sql` (probado en desarrollo) |
| Job del cron | ✘ No existe en desarrollo (`USER_JOBS` y `USER_SCHEDULER_JOBS` vacíos) |
| Corrección del hallazgo 1 (duplicados / `VALIDA = 1`) | ✔ Scripts `01` (SP) y `02` (trigger) + `99_rollback.sql`; **sin ejecutar** (14-10) |
| Corrección del hallazgo 5 (fecha `TRANSACTION_DATE`) | ✔ En `01` y `02`; validada como consulta en test (14-10); **sin ejecutar** |
| Instalador | ✔ `INSTALAR.sql`: `@01`, `@02`, `@03` y estado de los objetos (19-10) |
| Reordenamiento en package (validación única) | ✔ `01_pkg_transacc_depo_queue.sql` + trigger `02` que llama a `FN_VALIDA_MATCH` + `03` drop del SP suelto; rollback ajustado; **sin ejecutar** (19-10) |
| Instalación y prueba en test (`INTRANETTS`) | ⏳ Pendiente: la ejecuta el usuario (checklist en §9) |
| Resto de correcciones | Pendiente de decisión (§8) |

## 3. Artefactos

| Ruta | Qué es |
|---|---|
| `docs/README_FSCC-12948.md` | Este índice |
| `docs/sql/FSCC-12948/README.md` | Qué contiene la carpeta de scripts |
| `docs/sql/FSCC-12948/00_prechecks.sql` | Solo lectura: objetos, cola por estado, duplicados, cola sobre transacciones ya cuadradas, pendientes con/sin venta POST, job, log |
| `docs/sql/FSCC-12948/01_pkg_transacc_depo_queue.sql` | Package `PKG_TRANSACC_DEPO_QUEUE`. `FN_VALIDA_MATCH(idtrx, local, terminal, fecha [, id_prosegur, id_queue])`: la validación del match (`VALIDA = 0`, barcode informado, local/terminal, `TRANSACTION_DATE` del día de `VTA_FECHA`, `VTA_TEMPESC` corr 8, sin otra fila viva en la cola); devuelve el ID o 0, no lee `VTA_TEMP_CAB` (evita tabla mutante) ni hace DML. `PROC_TRANSACC_DEPO_QUEUE`: el SP del cron de antes, que lee la venta encolada, valida con la función (0 → `OMITIDO -> …`, sin llamar al package) y le pasa `TRANSACTION_DATE` a `EXISTE_VTA_TEMPESC` |
| `docs/sql/FSCC-12948/02_trg_transacc_depo_queue.sql` | Trigger: si es tipo 53 llama a `FN_VALIDA_MATCH` y encola PENDIENTE si devuelve un ID |
| `docs/sql/FSCC-12948/03_drop_proc_transacc_depo_queue.sql` | Borra el SP suelto `PROC_TRANSACC_DEPO_QUEUE` |
| `docs/sql/FSCC-12948/INSTALAR.sql` | Ejecuta `01`, `02` y `03` y muestra el estado (package y body `VALID`, trigger `ENABLED`, SP suelto inexistente) |
| `docs/sql/FSCC-12948/99_rollback.sql` | Vuelve el SP suelto y el trigger a la línea base y borra el package |
| `docs/sql/FSCC-12948/anterior_2026-10-15/` | Versión del 15-10 (SP y trigger con la validación repetida). Referencia |
| `docs/MANIFIESTO_FSCC-12948.md5` | Huellas MD5 del estado congelado (19-10) |
| `docs/respaldos/FSCC-12948_2026-10-19_pkg-cola.zip` | Respaldo de `docs/` (sin `respaldos/`) y `CLAUDE.md` (19-10). El anterior, `FSCC-12948_2026-10-15_scripts-listos.zip`, tiene la versión SP + trigger |
| `docs/sql/FSCC-12948/ddl_actual_desarrollo/01…05` | Fuente tal como está en `INTRANETDE` (tabla cola, trigger, SP, package spec/body). Referencia, **no para ejecutar** |
| `FTEPROD/Form172.frm`, `FTEPROD/Form173.frm` | Pantallas de cuadratura API vs cartola y rematch manual |

## 4. Objetos

| Objeto | Tipo | Rol |
|---|---|---|
| `PROSEGUR_TRANSACTIONS` | Tabla | Transacciones de la depositaria (API). `VALIDA` 0/1, `MATCH_STATUS`, `BARCODE`, `SERVICE_POINT_CODE` (local), `DEVICE_ID` (terminal), `ACCOUNTING_DATE`, `TRANSACTION_DATE`, `TOTAL` |
| `TRG_PROSEGUR_TRANSACTIONS` | Trigger | `BEFORE INSERT`: ID con `SEQ_PROSEGUR_TRANSACTIONS` |
| `PROSEGUR_TRANSACTIONS_QUEUE` | Tabla (nueva) | Cola: `ID_QUEUE` (PK), `VTA_IDTRX`, `ID_PROSEGUR`, `ESTADO` (PENDIENTE / PROCESANDO / PROCESADO / ERROR), `FECHA_CREACION`, `FECHA_PROCESO`, `INTENTOS`, `ERROR_MESSAGE`. Sin FK ni clave única |
| `SEQ_PROS_TRANS_QUEUE` | Secuencia | ID de la cola (la usa el trigger). `SEQ_PROS_TRIG_QUEUE` existe pero no se usa |
| `TRG_TRANSACC_DEPO_QUEUE` | Trigger (nuevo) | `AFTER INSERT ON VTA_TEMP_CAB FOR EACH ROW`: encola si corresponde |
| `PROC_TRANSACC_DEPO_QUEUE` | Procedimiento (nuevo) | Procesa la cola (cron). **Desde el script `03` (19-10) se borra**: pasa al package |
| `PKG_TRANSACC_DEPO_QUEUE` | Package (nuevo, 19-10) | `PROC_TRANSACC_DEPO_QUEUE` (cron) y `FN_VALIDA_MATCH` (validación común del trigger y del cron) |
| `F8_TRANSACC_DEPO_PKG.EXISTE_VTA_TEMPESC` | Package | Match: marca la venta, inserta en `VTA_PRD`, actualiza `VALIDA`. Lo usan el SP y `Form173` |
| `PROSEGUR_TRANSACTION_LOG` | Tabla | Log de fallas del package (`INSERT_PRD_FAILED`) |

Los mismos objetos están en test (`INTRANETTS`) con el mismo tamaño de fuente (spec y trigger difieren en 1 carácter).

## 5. Flujo

Este es el flujo **tal como está instalado hoy** (línea base). Los scripts `01` y `02` cambian tres cosas:
- el trigger y el SP cruzan por `TRANSACTION_DATE` en lugar de `ACCOUNTING_DATE`;
- el trigger no encola si ya hay una fila PENDIENTE/PROCESANDO para la transacción;
- el SP revalida las condiciones del trigger antes de llamar al package. Si no se cumplen, deja la fila `PROCESADO` / `OMITIDO -> …`.

Desde el 19-10 esa validación está en un solo lugar, `PKG_TRANSACC_DEPO_QUEUE.FN_VALIDA_MATCH`, y el SP pasa al package:

```
POST --> VTA_TEMP_CAB --> TRG_TRANSACC_DEPO_QUEUE
    si tipo 53: FN_VALIDA_MATCH(:NEW.idtrx, local, terminal, fecha) > 0 --> INSERT cola PENDIENTE
cron --> PKG_TRANSACC_DEPO_QUEUE.PROC_TRANSACC_DEPO_QUEUE
    por fila: lee la venta en VTA_TEMP_CAB -> FN_VALIDA_MATCH(..., id_prosegur, id_queue)
      = 0 (o sin venta) -> PROCESADO 'OMITIDO -> ...'
      > 0 -> EXISTE_VTA_TEMPESC(..., TRANSACTION_DATE, ...) -> PROCESADO / ERROR
```

Únicos cambios de comportamiento: el trigger también exige `BARCODE` informado (hallazgo 7) y el cron deja OMITIDO una fila si hay **otra** viva para la misma transacción.

```
API Prosegur --INSERT--> PROSEGUR_TRANSACTIONS            (VALIDA=0, 'NO_MATCH' si no hay venta)

POST (POS) --INSERT--> VTA_TEMP_CAB --AFTER INSERT ROW--> TRG_TRANSACC_DEPO_QUEUE
    si VTA_TIPO = 53, busca MAX(ID) de PROSEGUR_TRANSACTIONS con:
      VALIDA = 0, SERVICE_POINT_CODE = VTA_LOCAL, DEVICE_ID = VTA_TERMINAL,
      ACCOUNTING_DATE del mismo dia que VTA_FECHA,
      y VTA_TEMPESC (mismo VTA_IDTRX, VTA_CORR = 8) cuyo VTA_MSG_DATA contiene BARCODE sin el ultimo digito
    si encuentra --> INSERT PROSEGUR_TRANSACTIONS_QUEUE (PENDIENTE)

cron --> PROC_TRANSACC_DEPO_QUEUE   (hasta 500 PENDIENTE, por ID_QUEUE)
    por fila: PROCESANDO, INTENTOS+1 -> lee la transaccion ->
      EXISTE_VTA_TEMPESC(id, local, terminal, ACCOUNTING_DATE 'YYYY-MM-DD', barcode, FLG_PAIS = NULL)
      -> PROCESADO + mensaje   |   excepcion -> ERROR + SQLERRM
    un solo COMMIT al final del lote

EXISTE_VTA_TEMPESC (FLG_PAIS NULL = tablas de Chile sin prefijo)
    1. busca VTA_IDTRX: VTA_TEMPESC corr 8 LIKE barcode + VTA_TEMP_CAB (fecha = ACCOUNTING_DATE, local, terminal, tipo 53)
    2. si existe: INSERT VTA_TEMPESC corr -2 'API PSG' (marca de match)
    3. diferencia = TOTAL - monto del barcode (pos. 2-9) -> 'F' faltante / 'S' sobrante / 'C' cuadra
    4. UPDATE PROSEGUR_TRANSACTIONS (barcode, local, terminal, TRANSACTION_DATE := fecha contable)
    5. INSERT VTA_PRD (F8 / EFE, 'API PSG') si no existe ese SOB_CODIGOBARRA
    6. si inserto PRD: VALIDA = 1, MATCHED, diferencia; UPDATE VTA_PRD con la diferencia
       si no inserto:  VALIDA = 0, NO_MATCHED, log INSERT_PRD_FAILED, borra la marca -2
    errores: WHEN OTHERS -> SRV_MESSAGE 'ERROR -> ...' (no relanza)
```

## 6. Hallazgos (riesgos de la solución actual)

1. **Una fila duplicada en la cola deshace el match.** El trigger no evita encolar dos veces la misma transacción, y en desarrollo ya pasó: hay 2 filas PENDIENTE para el ID 121, probablemente porque el POST se reinsertó. El SP tampoco revisa `VALIDA` antes de llamar al package. La segunda fila encuentra la venta, pero el INSERT en `VTA_PRD` da 0 filas porque el sobre ya está. Entonces el package deja `VALIDA = 0` / `NO_MATCHED` y borra la marca -2. Pasa lo mismo si alguien pulsa el rematch manual de `Form173` sobre una transacción ya cuadrada.
   **Corrección (14-10, decisión del usuario):** antes de llamar al package, el SP revalida contra la venta encolada (`VTA_IDTRX`) las mismas condiciones del trigger: `VALIDA = 0` (solo NO MATCH), `BARCODE` informado, `VTA_TEMP_CAB` tipo 53 con mismo local/terminal y fecha del mismo día (desde la corrección del hallazgo 5 es `TRANSACTION_DATE`), y `VTA_TEMPESC` corr 8 con el barcode. Si no cumple marca la fila `PROCESADO` / `OMITIDO -> …` sin llamar al package (`01`). Además el trigger no encola si ya hay una fila PENDIENTE o PROCESANDO (`02`). Las filas duplicadas de un mismo lote también quedan cubiertas: la primera deja `VALIDA = 1` en la misma sesión y la segunda ya no la encuentra. El botón de `Form173` no cambia, pero solo lista transacciones con `VALIDA = 0`.
2. **PROCESADO no significa MATCH, y no hay reintentos.** Si no encuentra la venta, el package devuelve `SRV_MESSAGE` NULL y la cola queda PROCESADO con el mensaje vacío. `INTENTOS` se cuenta pero no se usa, y las filas en ERROR no se reprocesan.
3. **No hay rollback por fila.** El `WHEN OTHERS` del package absorbe el error y el SP hace COMMIT al final del lote. Si falla a mitad, quedan cambios parciales (por ejemplo, la transacción ya actualizada en el paso 4 pero sin fila en `VTA_PRD`).
4. **El trigger no maneja errores.** Si falla (secuencia, permisos, datos), aborta el INSERT del POST en `VTA_TEMP_CAB`: un problema de la cola bloquearía la carga de ventas.
5. **Fecha usada para el cruce.** El trigger y el package comparan `ACCOUNTING_DATE` con `VTA_FECHA`. En el ID 2447 la fecha contable es 18-09 y el POST está con `VTA_FECHA` 21-09, que es su `TRANSACTION_DATE`; además ese POST no tiene `VTA_TEMPESC` corr 8. Hay que confirmar con negocio qué fecha corresponde a `VTA_FECHA`. El package además sobrescribe `TRANSACTION_DATE` con la fecha contable.
   **Confirmado en test (14-10):** la prueba del usuario (ID 103249, IDTRX 31254814615) no se encoló solo por esto: `ACCOUNTING_DATE` = 15-10 09:00 y `VTA_FECHA` = 14-10 = `TRANSACTION_DATE`. Las otras condiciones se cumplían. De las 50 transacciones que hoy tienen match en test, las 50 tienen `VTA_FECHA = TRANSACTION_DATE` y solo 2 coinciden con la contable. La fecha contable va de −4 a +2 días respecto de la de transacción. `Form173` ya usaba la fecha de venta, que saca del código de barras.
   **Corrección:** `01` y `02` cruzan por `TRANSACTION_DATE`, y el SP le pasa esa fecha al package. Validado como consulta en test: el trigger actual devuelve 0 y el nuevo devuelve 103249; la revalidación del SP devuelve 1 fila con la fecha 2026-10-14.
6. **Solo cubre Chile.** El trigger está solo en `VTA_TEMP_CAB` (sin prefijo) y el SP pasa `FLG_PAIS = NULL`. Las tablas de otras empresas (`VTA_SOCOTEMP_CAB`, `VTA_SFCLTEMP_CAB`, …) no encolan. `Form173` sí pasa `Flg_Pais$`.
7. **El trigger depende de un orden en el POST.** El `EXISTS` sobre `VTA_TEMPESC` exige que el detalle (corr 8) ya esté insertado cuando se inserta la cabecera. En los datos de desarrollo el detalle se registró antes que la cabecera (2 de 2 casos), pero conviene confirmar el orden real del POST: si la cabecera llega primero, nunca se encola. Además, con `BARCODE` NULL el `LIKE '%%'` calza con cualquier venta del local, terminal y día; y `MAX(ID)` toma una sola transacción aunque haya varias.
8. **Restos.** La secuencia `SEQ_PROS_TRIG_QUEUE` no se usa, aunque la PK se llama `PK_PROS_TRIG_QUEUE`. `MATCH_STATUS` mezcla `NO_MATCH` (API) con `NO_MATCHED` (package). No existe el job del cron.

## 7. Hechos verificados en desarrollo (14-10-2026)

- Todos los objetos están `VALID`; el trigger está `ENABLED`.
- `PROSEGUR_TRANSACTIONS`: 2 filas, ambas `VALIDA = 0` / `NO_MATCH`. `PROSEGUR_TRANSACTION_LOG`: vacío.
- Cola: 2 filas PENDIENTE (06-10), las dos para `ID_PROSEGUR = 121` / `VTA_IDTRX = 31250780039`. Esa venta existe hoy en `VTA_TEMP_CAB` (local 3790, terminal 6852, 24-09, tipo 53) y en `VTA_TEMPESC` corr 8 con el barcode, y el sobre no está en `VTA_PRD`. Si el SP corre, la primera fila haría el match y **la segunda lo desharía** (hallazgo 1).
- ID 2447 (local 882, terminal 7010): sin cola; el POST existe con fecha 21-09, distinta de la contable 18-09, y sin `VTA_TEMPESC`.
- `VTA_TEMP_CAB.VTA_FECHA` no tiene componente horario (tipo 53, últimos 60 días).

### 7b. Hechos verificados en test (`INTRANETTS`, 14-10-2026)

- Mismos objetos que en desarrollo, `VALID` / `ENABLED`; tampoco existe el job.
- Prueba del usuario: transacción **ID 103249**, `VTA_IDTRX` **31254814615**, local **307**, terminal **3852**, `VTA_FECHA` **14-10-2026**, tipo 53, con `VTA_TEMPESC` corr 8 que contiene el barcode.
  - En la base quedó `VALIDA = 0` / `NO_MATCH`, aunque el INSERT que pegó el usuario decía `1` / `MATCHED`.
  - `TRANSACTION_DATE` = 14-10; `ACCOUNTING_DATE` = 15-10 09:00. Por eso el trigger actual no la encoló.
- De las 50 transacciones con match en test, las 50 tienen `VTA_FECHA = TRANSACTION_DATE`; solo 2 coinciden con `ACCOUNTING_DATE` (que va de −4 a +2 días).
- La columna `SALE_DATE` (texto ddmmyy) existe solo en test; por eso los scripts usan `TRANSACTION_DATE`, que está en ambos ambientes.
- Validación como consulta (con los valores de la prueba en lugar de `:NEW`): trigger actual → 0 filas; trigger nuevo → 103249; revalidación del SP → 1 fila con fecha 2026-10-14.

## 8. Pendientes / preguntas

1. ~~¿Qué fecha del POST (`VTA_FECHA`) corresponde?~~ Respondido con los datos de test: es la de transacción (`TRANSACTION_DATE`). Ver hallazgo 5.
2. ¿En qué orden inserta el POST: `VTA_TEMPESC` antes que `VTA_TEMP_CAB`?
3. ¿Qué países o empresas entran en el alcance (solo Chile o también las tablas con prefijo)?
4. ¿Cómo se agenda el cron (DBMS_JOB en Oracle 10.2, Scheduler o cron del SO) y cada cuánto? Desde el 19-10 el job debe llamar a `PKG_TRANSACC_DEPO_QUEUE.PROC_TRANSACC_DEPO_QUEUE` (el SP suelto se borra).
5. Correcciones: ya hay scripts para la guarda de duplicados en el trigger y para que el SP salte `VALIDA <> 0` (`01`, `02`). Faltan por decidir:
   - distinguir "sin match" de "procesado" y reintentar hasta N veces;
   - `SAVEPOINT` / rollback por fila;
   - manejo de excepciones en el trigger que no bloquee el POST;
   - script del job.

## 9. Cómo retomar

- **Conexión a desarrollo:** requiere la VPN Fortinet. Cliente `C:\Leonardo\ClienteOracle64\sqlplus.exe`; EZConnect `<usuario>/<clave>@//10.140.2.224:1531/sgfinperds`, usuario `INTRANETDE`. La clave no se guarda en este documento.
- Desde Git Bash, llamar a sqlplus con `MSYS_NO_PATHCONV=1` (si no, `/nolog` se convierte en una ruta).
- **Regla:** en desarrollo y test solo consultas de lectura; los scripts que crean o modifican objetos los ejecuta el usuario.
- **Conexión a test:** misma EZConnect, usuario `UINTRANETTS` y, después de conectar, `alter session set current_schema = INTRANETTS`. Las claves están en los INI de `FTEPROD/` (`Setup_NK_DESA.ini` y `Setup_NK_TEST.ini`, sección `[CONNECT]`, codificadas con `Passwords()`); no se copian a ningún documento.
- En sqlplus, una línea en blanco dentro de una sentencia la corta: los scripts no las tienen.
- Empezar por `docs/sql/FSCC-12948/00_prechecks.sql` y comparar con §7 / §7b.
- Abrir `docs/MANIFIESTO_FSCC-12948.md5` y comprobar que los scripts no cambiaron desde el 15-10: `grep -v '^#' docs/MANIFIESTO_FSCC-12948.md5 | md5sum -c` (desde `C:\Repositorio-f8\F8`).

### 9b. Checklist de instalación y prueba en test (la ejecuta el usuario)

Conectado como el dueño de las tablas y parado en `docs/sql/FSCC-12948/`:

1. `@00_prechecks.sql` (solo lectura) y guardar la salida.
2. `@INSTALAR.sql` → el package (spec y body) y el trigger deben quedar `VALID` / `ENABLED`, `show errors` sin errores y el SP suelto `PROC_TRANSACC_DEPO_QUEUE` ya no debe existir.
   Prueba de solo lectura de la validación: `select PKG_TRANSACC_DEPO_QUEUE.FN_VALIDA_MATCH(31254814615, 307, 3852, date '2026-10-14') from dual;` → 103249 mientras siga en `VALIDA = 0` y sin fila viva en la cola (0 en caso contrario).
3. El trigger solo se dispara en INSERT, así que hay que reinsertar la cabecera de la prueba:
   ```sql
   DELETE FROM VTA_TEMP_CAB WHERE VTA_IDTRX = 31254814615;
   INSERT INTO VTA_TEMP_CAB (...) VALUES (TIMESTAMP '2026-10-14 00:00:00', 307, 3852, 53, 31254814615, 'Intranetde', '.', TIMESTAMP '2026-10-14 11:26:51');
   COMMIT;
   ```
   (con la misma lista de columnas del INSERT original del usuario).
4. `SELECT * FROM PROSEGUR_TRANSACTIONS_QUEUE WHERE ID_PROSEGUR = 103249;` → se espera **1 fila PENDIENTE**.
5. `exec PKG_TRANSACC_DEPO_QUEUE.PROC_TRANSACC_DEPO_QUEUE;` → se espera:
   - la 103249 con `VALIDA = 1` / `MATCHED`;
   - la fila de la cola `PROCESADO`, con el mensaje del package;
   - el sobre insertado en `VTA_PRD` con 'API PSG'.
6. Prueba de duplicados: reinsertar otra vez la cabecera. No debe encolarse nada, porque ya hay `VALIDA = 1`. Si se fuerza una fila PENDIENTE, el SP debe dejarla `PROCESADO` / `OMITIDO -> …`, y la 103249 debe seguir en `VALIDA = 1`.
7. Si algo falla: `@99_rollback.sql` (vuelve a la línea base) y anotar el resultado en §10.

## 10. Historial de cambios (bitácora)

| # | Fecha | Qué se hizo | Resultado |
|---|---|---|---|
| 1 | 14-10 | Lectura en `INTRANETDE` de la cola, el trigger, el SP y el package; revisión de los datos de la cola y de las transacciones sin match; comparación con `INTRANETTS` | §4–§7 |
| 2 | 14-10 | Carpeta `docs/sql/FSCC-12948/` con la línea base del DDL (ASCII, sin esquema) y `00_prechecks.sql` probado en desarrollo | §3 |
| 3 | 14-10 | Propuesta del usuario: el SP debe tomar solo `VALIDA = 0`, como el trigger. Scripts `01` (SP con `VALIDA = 0` y `NO_DATA_FOUND` → OMITIDO), `02` (trigger con `NOT EXISTS` en la cola) y `99_rollback.sql`. `diff` contra la línea base: solo esos cambios. **Sin ejecutar** | §6 hallazgo 1 |
| 4 | 14-10 | A pedido del usuario, el `SELECT` del SP (`01`) revalida **todas** las condiciones del trigger (no solo `VALIDA = 0`) contra el `VTA_IDTRX` de la cola, más `BARCODE IS NOT NULL` y `ROWNUM = 1`. Probado como consulta en desarrollo: ID 121 → 1 fila; ID 2447 → 0 filas | §6 hallazgo 1 |
| 5 | 14-10 | El usuario reportó que su prueba en test no se encoló. Diagnóstico de solo lectura, condición por condición: solo fallaba la fecha (contable 15-10 contra venta 14-10). `01` y `02` pasan a cruzar por `TRANSACTION_DATE`. Validado como consulta en test (actual 0, nuevo 103249) | §6 hallazgo 5, §7b |
| 6 | 14-10 | El usuario pidió los cambios del package y del trigger. Respuestas: "solo dejar los scripts" (no tocar la base) y "SP + trigger" (el package no cambia). Se agregó `INSTALAR.sql`. Todo en ASCII | §2, §3 |
| 7 | 15-10 | "Graba todo": índice actualizado (estado, §7b test, §9b checklist), memoria, manifiesto `MANIFIESTO_FSCC-12948.md5` y respaldo `FSCC-12948_2026-10-15_scripts-listos.zip`. **Nada ejecutado en la base** | §9b |
| 8 | 19-10 | **Reordenamiento en package** (pedido del usuario: "1 trigger y 1 pkg con 2 funciones, la SP y la de validación"). `01_pkg_transacc_depo_queue.sql`: `PKG_TRANSACC_DEPO_QUEUE` con `FN_VALIDA_MATCH` (el `SELECT` del trigger tal cual, más `BARCODE IS NOT NULL`, filtro opcional por `ID_PROSEGUR` y exclusión de la propia fila de la cola) y `PROC_TRANSACC_DEPO_QUEUE` (mismo loop, mensajes y COMMIT; lee la venta de `VTA_TEMP_CAB` y valida con la función). `02`: el trigger llama a la función. `03`: drop del SP suelto (ningún job lo llama). `99_rollback.sql` recrea la línea base y borra el package. La versión del 15-10 queda en `anterior_2026-10-15/`. Verificación estática: ASCII, sin `&`, firmas spec/body iguales, la función y el trigger no leen `VTA_TEMP_CAB`, diff del `SELECT` contra el trigger anterior = solo los tres agregados. Manifiesto regenerado y respaldo `pkg-cola`. **Sin ejecutar en la base** | §3, §5 |
