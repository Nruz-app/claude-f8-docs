# FSCC-12958 (HU-01-T2): cierre de caja automático, Falabella Colombia (scripts de base de datos)

> **Para instalar T1 + T2 juntos usar la carpeta consolidada [`../FSCC-12901_T1_T2/`](../FSCC-12901_T1_T2/README.md).** Esta carpeta documenta solo esta subtarea; sus scripts son la fuente de las copias de la carpeta consolidada (mantener ambas iguales).

Este enfoque resuelve el cierre automático completo en Oracle: una cola alimentada por un trigger sobre `VTA_FACOPRD` y un procedimiento que se ejecuta aparte. El proceso automático no depende del exe. **Ajuste DF-SCC (06-10-2026):** la vista `VTA_FACOV_CAJAS_CIERRE` agrega a la cola las cajas sin sobres del mismo local y día, y `Form43` (Consultas de Cuadratura, FACO) usa el mismo paquete para sus columnas y su botón "Cerrar Terminal" (`prc_cierre_rango`). Ver la sección "Ajuste DF-SCC".

> **07-10-2026: FACO opera solo con cierre Y.** El paquete cierra únicamente cierres Y (`VTA_FACOTERMSTATY`), igual que `Form3Y.CierraTerminal`, y **no toca la Z** (`VTA_FACOTERMSTAT`). Se eliminaron las reglas RZ, `pr_procesa_z`, `pr_valida_z`, `fn_msg_z_suma_y`, `fn_msg_y_abiertas`, `fn_dif_dolares` y el parámetro `CA_VAL_USD`. Ver la sección "Solo cierre Y".

```
Form133 / Form21 / Form124 …  ──INSERT──▶ VTA_FACOPRD
                                              │ TRG_VTA_FACOPRD_CIERRE_AI (F8, DOL)
                                              ▼
                                     VTA_FACOPRD_CIERRE  (cola, estado P)
                                              │
     job externo ──▶ PKG_F8_FACO_CIERRE_AUTO.PRC_CIERRE_AUTOMATICO
                                              │  por cada cierre Y de VTA_FACOV_CAJAS_CIERRE:
                                              │   estado → DR = 0 → validaciones RY → cierra la Y
                                              │  (la Z no se toca: FACO solo cierre Y)
                                              ▼
                        VTA_FACOTERMSTATY  +  VTA_FACOLOG_CIERRE_AUTO
```

## Orden de ejecución

**Ningún script tiene el esquema escrito fijo.** Los objetos se crean y se referencian por nombre (`VTA_FACOPRD_CIERRE`, no `<esquema>.VTA_FACOPRD_CIERRE`), así que se resuelven en el esquema de la sesión. Por eso:

- **Los scripts 00 a 06 y 08 se ejecutan conectado como el dueño del esquema** donde están las tablas `VTA_FACO*`. En test es el dueño de `VTA_FACOPRD`; se averigua con `select owner from all_tables where table_name = 'VTA_FACOPRD'`. El usuario de aplicación no sirve para instalar: no tiene privilegios `CREATE`.
- Si el DBA instala con su propio usuario, debe ejecutar antes `alter session set current_schema = <dueño>`.
- **El script 07** toma el dueño de la sesión (`sys_context('USERENV','CURRENT_SCHEMA')`) y **pide** el usuario de aplicación (`accept`). Los permisos los da el dueño; los sinónimos, el DBA (`CREATE ANY SYNONYM`).
- **Derechos del dueño (definer rights).** El paquete y su SQL dinámico se ejecutan con los privilegios del dueño. Si alguna tabla `VTA_FACO*` o `VTA_PAINT_Z` no fuera del mismo esquema, el dueño necesita un **grant directo** (no a través de un rol) sobre ella. En test, todas son del mismo esquema.

| # | Script | Contenido |
|---|---|---|
| 0 | `00_prechecks.sql` | Verificaciones previas de solo lectura en el ambiente destino; cada consulta indica el resultado esperado |
| 1 | `01_tabla_homologa.sql` | Tabla `VTA_FACOPRD_CIERRE` (tipos heredados de `VTA_FACOPRD`), índices y `SEQ_VTA_FACOPRD_CIERRE` |
| 2 | `02_log.sql` | `VTA_FACOLOG_CIERRE_AUTO` + secuencia (el "Registro de ejecución" del diagrama) |
| 3 | `03_parametros.sql` | Flags en `VTA_FACOPARAM` tipo 1502. **Ejecutar antes las dos consultas de verificación** |
| 3b | `03b_vista_cajas.sql` | Vista `VTA_FACOV_CAJAS_CIERRE` (universo de T1 y T2: COLA + SIN_SOBRE). Necesita 01 y 03 |
| 3c | `03c_permiso_cc.sql` | Opción 1515 de FACO (botón Cerrar Terminal de `Form43`), deshabilitada para todos los perfiles |
| 4 | `05_pkg_cierre_auto_spec.sql` | Especificación del paquete. Públicas: `prc_cierre_automatico`, `prc_cierre_rango` (`Form43`), `fn_dif_real`, `fn_dif_caja`, `fn_compensado` (las tres exigen la Y), `pr_valida_y`, `fn_param` y cada validación de la Y por separado (`fn_msg_cheque_fecha`, `fn_concepto_pendiente`, `fn_zzz`). Privadas (dependen del estado de la ejecución): `pr_log`, `fn_dec`, `fn_conceptos`, `pr_cuadratura`, `pr_marca_cola`, `fn_nota`, `pr_procesa_y` |
| 5 | `06_pkg_cierre_auto_body.sql` | Cuerpo del paquete. **Llama a T1** (`PKG_F8_FACO_COMPENSA_DI.prc_compensa_di`, FSCC-12957) antes de cerrar: **instalar antes la especificación y el cuerpo de T1** (orden conjunto en `../FSCC-12957/README.md`) |
| 6 | `04_trigger.sql` | Trigger. **Va al final**, para no encolar sobres antes de que el proceso esté compilado |
| 7 | `07_grants_sinonimos.sql` | Permisos (como dueño) y sinónimos (como DBA) para el usuario de aplicación o del job, que el script pide al ejecutarse |
| 8 | `08_pruebas.sql` | Pruebas en test |
| — | `99_rollback.sql` | Reapertura opcional de una ejecución y desinstalación |

**Llamada del job:**

```sql
-- como dueño, o como usuario de aplicación a través del sinónimo
begin PKG_F8_FACO_CIERRE_AUTO.prc_cierre_automatico('PROC_CIERRE_AUTO'); end;
```

Cómo se agenda (DBMS_JOB, cron o un orquestador) está fuera del alcance.

## Integración con T1 (FSCC-12957, compensación automática de DI)

`prc_cierre_automatico` es el único punto de entrada del job y sigue el orden del diagrama general:

1. Marca en la cola los sobres sin Y (`O`) y los vencidos (`V`).
2. Llama a `PKG_F8_FACO_COMPENSA_DI.prc_compensa_di`, que registra la DI de las cajas con DR en el rango (si `CA_DI_ACTIVO = S`).
3. Si `CA_ACTIVO = S`, cierra las Y (T2). La Z no se toca.

Los interruptores son independientes: si los dos están en `N`, no se hace nada. El log distingue cada proceso con `log_proceso` (`T1`, `T2` o `CC` para el botón de `Form43`). Un error en T1 se registra y no detiene T2. Detalle en [`../FSCC-12957/README.md`](../FSCC-12957/README.md).

## Parámetros (`VTA_FACOPARAM`, tipo 1502)

| Código | Valor inicial | Uso | Equivalente en el exe |
|---|---|---|---|
| `CA_ACTIVO` | S | Proceso activo ("T2 activa" del diagrama general) | — |
| `CA_VAL_CHEQ` | S | Valida cheque a fecha: gestión = tesorería | RY-01 |
| `CA_VAL_ZZZ` | N | Valida la fórmula ZZZ | Opción de perfil 103 |
| `CA_DECIMAL` | 0 | Decimales para redondear la DR y las comparaciones | `gFormat` de Colombia (**verificar** `vta_parametros`) |
| `CA_DIAS` | 30 | Días que una caja pendiente se sigue reevaluando | — |
| `CA_SIN_SOBRE` | S | Incluye en el universo los cierres Y abiertos sin sobres del mismo local y fecha de venta de la carga (DF-SCC fila 12) | — |

## Ajuste DF-SCC (06-10-2026): cajas sin movimiento y Consultas de Cuadratura

**Universo.** `prc_cierre_automatico` y T1 ya no leen la cola directamente sino la vista `VTA_FACOV_CAJAS_CIERRE`:

| Origen | Filas |
|---|---|
| `COLA` | Cierres Y (`prv_cierrey <> 0`) con sobres en estado P en `VTA_FACOPRD_CIERRE` |
| `SIN_SOBRE` | Cierres Y abiertos (`ter_estado <= 0`) con libro de ventas Y, del mismo `ter_fecha` y `ter_local` que una carga pendiente, que no están en la cola. Solo si `CA_SIN_SOBRE = S` |

Columnas: `cc_fecha`, `cc_local`, `cc_terminal`, `cc_cierrey`, `cc_origen`. Para las cajas SIN_SOBRE `pr_marca_cola` no actualiza filas (no tienen sobres); su resultado queda solo en el log. Se reevalúan mientras su local-día tenga carga pendiente en la cola.

**Funciones para `Form43`.** El cálculo se separó en el privado `pr_cuadratura`, sin cambiar la fórmula (`fn_dif_real` devuelve lo mismo). `fn_dif_caja` = sumaBZ y `fn_compensado` = compensado, ambos sin redondear; `fn_dif_real = round(fn_dif_caja − round(fn_compensado))`, como `Label70` de `Form3Y`.

**`prc_cierre_rango`** (botón Cerrar Terminal de `Form43`, FACO):

```sql
declare v_e number; v_c number; v_n number;
begin
  PKG_F8_FACO_CIERRE_AUTO.prc_cierre_rango('20260923', '20260923', 6, 0, 'RUT_ANALISTA', v_e, v_c, v_n);
end;
```

- Universo: cierres Y abiertos con libro de ventas en el rango, local y terminal (0 = todos). La Z no se toca.
- Mismas reglas RY y flags que el proceso automático. No ejecuta T1 ni depende de `CA_ACTIVO`.
- `ter_cerradopor` = `p_usuario` (el exe pasa `LOGINUSER`); nota `CIERRE CC FSCC-12901 …`; `log_proceso = 'CC'`.
- Devuelve el número de ejecución y los totales de cierres Y cerrados / no cerrados; el detalle queda en el log.

**Opción 1515.** `Form43` muestra el botón solo si `FuncBuscarOpcionCompensa(PERFILUSER, 1515)`. En test la opción no existía para FACO: `03c_permiso_cc.sql` la crea con `rel_estado = 0` y se habilita por perfil (`Form47` o `UPDATE`).

**Front.** Los cambios de `FTEPROD/Form43.frm` están en `docs/README_FSCC-12901.md` §5c.

## Solo cierre Y (07-10-2026)

Documentación actualizada en `docs/Requeriemintos-FSCC-12901/Doc-Actualizado/` ("Colombia opera con cierre Y") y decisión del usuario.

| Antes (06-10) | Ahora (07-10) |
|---|---|
| Y y luego la Z del terminal-día con RZ-01..09 | Solo Y (RY). `VTA_FACOTERMSTAT` no se lee ni se actualiza |
| `fn_dif_real(..., p_cierrey default null)`: null = Z | `p_cierrey` obligatorio en `fn_dif_real`, `fn_dif_caja` y `fn_compensado` |
| `pr_valida_z`, `fn_msg_z_suma_y`, `fn_msg_y_abiertas`, `fn_dif_dolares`, `pr_procesa_z`, `pr_procesa_terminales` | Eliminados |
| `CA_VAL_USD` | Eliminado (`99_rollback` lo borra igual, por si quedó) |
| `prc_cierre_rango`: Y + Z del rango | Solo Y del rango |
| Log: nivel Y / Z, `CERRADA_Z`, reglas RZ | Log: nivel Y / '-'; reglas RY |
| Rollback reabre Y y Z | Rollback reabre solo las Y |

`fn_zzz` (RY-06) y `VTA_PAINT_Z` se mantienen: la fórmula ZZZ también se aplica a la Y.

## Reglas implementadas

Se evalúan en orden; la primera que falla bloquea la caja.

**Cierre de la Y** (`Form3Y.CierraTerminal`, `FTEPROD/Form3Y.frm:2801`). El orden sigue el diagrama del proceso 2: estado → DR → validaciones.

| Regla | Qué valida | Resultado en el log |
|---|---|---|
| Bloqueo | `FOR UPDATE NOWAIT` sobre `termstaty` | `OCUPADA` |
| RY-02 | `ter_estado > 0`. **No se reabren** Y cerradas, impresas ni sin datos | `YA_CERRADA` |
| — | Sin libro de ventas de la Y | `SIN_LIBVTA` |
| RY-05 | Diferencia real ≠ 0 (`fn_dif_real`) | `CON_DIFERENCIA` |
| RY-01 | Cheque a fecha (si `CA_VAL_CHEQ = S`) | `BLOQUEADA` |
| RY-03 | Conceptos sin regularizar en la Y: SN, AF, ND, FN, NP, BF, CR, CT, CA (cartaaviso), DP | `BLOQUEADA` |
| RY-06 | Fórmula ZZZ (si `CA_VAL_ZZZ = S`) | `BLOQUEADA` |
| Cierre | `ter_estado = 1`, `ter_cerradopor = PROC_CIERRE_AUTO`, `ter_notas = 'CIERRE AUTOMATICO FSCC-12958 dd-mm-yyyy hh24:mi | <nota anterior>'` | `CERRADA_Y` |

**Cierre de la Z: no aplica** (07-10-2026). FACO opera solo con cierre Y; el paquete no evalúa ni cierra `VTA_FACOTERMSTAT`. Las reglas RZ de `Form3.CierraTerminal` quedan documentadas en `docs/CierreCaja_FACO_Reglas.md` §4 como referencia.

**Diferencia real.** Es la de la F8 (`Label70`):

```
(prsefe − totefe) + (prschd − totchd) + USD + (teschf − totchf) + (tarjetas 2000–2999 − (rec_mtarj + rec_msodimac)) − compensado
```

El compensado son las 13 ramas de `Módulo1.StrSumCompensado`, con `UNION` como en el exe. Detalle en `docs/CierreCaja_FACO_Reglas.md` §2.

## Estados de la cola (`pcr_estado`)

| Estado | Significado |
|---|---|
| `P` | Pendiente. Se reevalúa en cada ejecución: `CON_DIFERENCIA`, `BLOQUEADA`, `SIN_LIBVTA`, `OCUPADA`, `ERROR`. Si el analista compensa o regulariza, el siguiente ciclo la cierra |
| `C` | Terminada: `CERRADA_Y` o `YA_CERRADA` |
| `O` | Omitida: el sobre no tiene cierre Y |
| `V` | Vencida: la fecha de venta es más antigua que `CA_DIAS` |

## Diferencias deliberadas con el exe

1. **Bug D1 corregido.** El exe pasa el local en lugar del número de Y a la ZZZ de la Y, así que en la práctica no valida. El paquete usa la Y real, y solo si `CA_VAL_ZZZ = S`.
2. **La Z no se cierra** (07-10-2026): Colombia opera solo con cierre Y.
3. **Cheque a fecha y perfiles.** Las validaciones que dependen del perfil pasan a flags.
4. **Tesorería en la Y.** `Form3Y.LeeTes` toma la primera fila de la Y; el paquete suma. Es equivalente si hay una fila por Y.
5. **Tarjetas.** No se valida el total de tarjetas, igual que el exe para Colombia, aunque el diagrama lo mencione.
6. **Errores.** Si una consulta falla, la caja queda en `ERROR` y se reintenta. En el exe algunas validaciones fallidas dejaban pasar.

## Supuestos verificados en la base de test (`sgfnprds`, 06-10-2026)

| Supuesto | Resultado | Impacto en los scripts |
|---|---|---|
| Estructura de `VTA_FACOPRD` | 29 columnas, PK en `prv_techkey`, **sin triggers**. `PRV_CIERREY` es `NUMBER(2)` NOT NULL con default 0 | 0 = sobre sin Y; queda en estado `O` |
| `VTA_PAINT_Z.vta_signo` | `CHAR(1)`, siempre `'+'` en FACO | El armado `signo || '1'` es correcto |
| Campos dinámicos de `VTA_PAINT_Z` (47 en FACO) | Todos existen, cada uno en **una sola** tabla (`libvta` o `zzz`) | El SQL dinámico sin prefijo de tabla funciona |
| Grupos ZZZ de FACO | 1 ventas; 2 abono/avance CMR, reversa recaudación, pago facturas; 3 recaudación; 6 gift card; 7 formas de pago | Fórmula F7−F6−…−F1 |
| `VTA_FACOPARAM` | 4 columnas; `VTA_DFECHAREG` NOT NULL con default `sysdate`; tipo 1502 libre | Los INSERT informan `vta_dfechareg` |
| Decimales | `vta_parametros` FACO: `VTA_NUMFORMAT = '#,#0'` (el `gFormat` del exe) y `VTA_DECROUND = 2` | `CA_DECIMAL = 0`. El compensado también se redondea **antes** de restarlo, como hace el exe |
| Tesorería | Una fila por Y en `VTA_FACOTESOR` | Sumar es equivalente a "primera fila" |
| `VTA_FACOTERMSTAT` (07-10) | 10.894 filas en −1 y 6 cerradas desde el 24-08-2026 | La Z no se gestiona en FACO: el paquete no la toca |
| Columnas de las tablas que lee el paquete (54 revisadas) | Todas existen | — |

### Revisión final (06-10-2026)

| Verificación | Resultado | Conclusión |
|---|---|---|
| Conceptos en `VTA_FACOCONCEPDIF` | Existen TC, SN, BF, NP, CA, CR, CT, DI, DN, DP, DT y VC. **No existen** ND, FN, AF, AL, TB, NC ni FT | Las ramas del compensado sin concepto no aportan, igual que en el exe. Las validaciones de pendientes de AF, ND y FN se buscan igual en `movdet`, como hace el exe |
| Acceso del usuario de aplicación | Accede a las tablas por sinónimos y no tiene privilegios `CREATE` | Instala el dueño o el DBA; los sinónimos los crea el DBA (script 07) |
| Tipos de `termstat` / `termstaty` | `ter_estado` NUMBER(1), `ter_cierrey` NUMBER(2), `ter_cerradopor` VARCHAR2(50), `ter_notas` VARCHAR2(2500) | Compatibles con lo que graba el paquete |
| Volumen | Unos 359 sobres F8 por día de depósito (test) | Trigger por fila liviano |
| Prefijo de esquema | 0 ocurrencias en los `.sql` | Portable a cualquier esquema |

## Riesgos y supuestos a revisar antes de producción

- **Trigger.** Hoy ignora sus propios errores para no frenar la carga de sobres. Ver el comentario en `04_trigger.sql` y la consulta de conciliación en `08_pruebas.sql`.
- **Convivencia con `PKG_F8_FACO_CIERRE_TER_PM_AP`.** Es el cierre `AUTOMATICO` de Autopago, que ya existe. Las dos rutas solo cierran cajas con estado ≤ 0 y este paquete bloquea con `NOWAIT`, pero conviene coordinar los horarios.
- **Producción puede diferir de test.** Ejecutar `00_prechecks.sql` en el ambiente destino; cada consulta indica el resultado esperado.
- **`CA_DECIMAL = 0`.** Una diferencia de 0,4 cuenta como 0, igual que en la F8 (`Format` con `'#,#0'`).
- **Y cerrada que recibe un sobre (P12).** No se reabre: queda `YA_CERRADA` en el log (`Form133.AbrirTerminal` solo reabre la Z, y se decidió no tocarlo). La reapertura de la Y sigue siendo manual (`Form20`).
- **Disparo y resumen (07-10).** La HU pide ejecutar "al momento de la carga" (`Form133`) y emitir un resumen; se decidió mantener el job externo y consultar el log por SQL. Punto abierto con negocio.
- **Sin transacción con la carga.** La cola se llena en la misma transacción del insert del sobre. Si la carga hace rollback, la fila de la cola también se revierte.
