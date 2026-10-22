# FSCC-12901: flujo completo T1 + T2 (compensación automática de DI + cierre de caja automático, Falabella Colombia)

Esta carpeta reúne en **un solo flujo instalable** las dos subtareas de la historia FSCC-12901:

| Subtarea | Qué hace | Carpeta individual |
|---|---|---|
| **T1, FSCC-12957** | Registra automáticamente una **DI** por la diferencia real de cada cierre Y de la carga, si está entre −1.000 y 20.000 (DR ≠ 0). No cierra | `../FSCC-12957/` |
| **T2, FSCC-12958** | **Cierra** automáticamente los cierres Y (la Z no se toca: FACO solo cierre Y) que quedan con DR = 0 y cumplen las validaciones de Cerrar Terminal. No compensa | `../FSCC-12958/` |

Las carpetas individuales se mantienen para revisar cada requerimiento por separado. **Esta carpeta es la que se instala.** Los scripts 01, 02, 03b, 03c y 04–08 son copias de las fuentes individuales (lo indica su encabezado; el resto del archivo es idéntico a la fuente); los scripts 00, 03, 09, 10, 99 e `INSTALAR.sql` están combinados. **Si cambias un script, actualiza también su fuente** (o al revés).

> **Solo cierre Y (07-10-2026).** La documentación actualizada (`docs/Requeriemintos-FSCC-12901/Doc-Actualizado/`) indica que Colombia opera con cierre Y. El proceso, `prc_cierre_rango` y `Form43` trabajan solo con `VTA_FACOTERMSTATY`; se eliminaron las reglas RZ, las funciones de la Z y `CA_VAL_USD`. `Form133` se revisó y no cambia. Detalle en `docs/README_FSCC-12901.md` §5d.

> **Ajuste DF-SCC (06-10-2026).** El DF *Mejoras F8 y compensaciones menores* (fila 12) pide que Consultas de Cuadratura (`Form43`) muestre y cierre las cajas sin movimiento (Dif. Real 0), como en Chile, para evitar el "dataload" de cierre de cajas. Se agregaron:
> - la vista `VTA_FACOV_CAJAS_CIERRE` (cajas sin sobres del mismo local-día, interruptor `CA_SIN_SOBRE`), que T1 y T2 recorren;
> - `prc_cierre_rango`, `fn_dif_caja` y `fn_compensado` en el paquete de T2 (para `Form43`);
> - la opción 1515 de FACO (`03c`);
> - el front `FTEPROD/Form43.frm` (ver `docs/README_FSCC-12901.md` §5c).

---

## 1. Flujo completo

```
 Analista: carga el Excel de recaudación (Form133 "Interfaz de Carga Manual de Sobres")
   │  (también Form21, Form124 y cualquier INSERT de sobres)
   ▼
 VTA_FACOPRD ──► TRG_VTA_FACOPRD_CIERRE_AI (por cada sobre F8 / DOL)
                   │
                   ▼
            VTA_FACOPRD_CIERRE   ← cola: "cajas de la carga" (estado P)
                   │  + cierres Y abiertos sin sobres del mismo local-día   [CA_SIN_SOBRE = S]
                   ▼
            VTA_FACOV_CAJAS_CIERRE   ← vista: universo de T1 y T2 (origen COLA / SIN_SOBRE)
                   │
 job externo ──► PKG_F8_FACO_CIERRE_AUTO.PRC_CIERRE_AUTOMATICO
                   │
                   ├─ 1. Cola: sobres sin Y → O (omitida); más antiguos que CA_DIAS → V (vencida)
                   │
                   ├─ 2. T1  PKG_F8_FACO_COMPENSA_DI.PRC_COMPENSA_DI        [CA_DI_ACTIVO = S]
                   │       por cada cierre Y de la vista:
                   │         caja abierta → DR (fn_dif_real) → DR = 0? → rango? → ¿DI previa?
                   │         → registra DI = DR (mismo signo) → control DR = 0
                   │
                   └─ 3. T2  cierre                                           [CA_ACTIVO = S]
                           por cada cierre Y de la vista:
                             caja abierta → DR = 0 → validaciones RY → cierra la Y
                           (la Z / VTA_FACOTERMSTAT no se toca: FACO solo cierre Y)
                   ▼
 VTA_FACOMOVDET (DI) · VTA_FACOCOMPDES (glosa) · VTA_FACOTERMSTATY (cierres Y)
 VTA_FACOLOG_CIERRE_AUTO (resumen: log_proceso T1 / T2) ──► el analista revisa y gestiona las excepciones a mano

 Analista en Consultas de Cuadratura (Form43, FACO; botón visible con la opción 1515):
   grilla: Dif. de Caja / Compensación / Dif. Real ← fn_dif_caja / fn_compensado / fn_dif_real (todas las cajas, también DR 0)
   "Cerrar Terminal" ──► PKG_F8_FACO_CIERRE_AUTO.PRC_CIERRE_RANGO(fechas, local, terminal, LOGINUSER)
                           mismas reglas RY, solo Y, sin T1 → log_proceso CC, ter_cerradopor = analista
```

Corresponde al diagrama general de FSCC-12901 (`docs/Requeriemintos-FSCC-12901/`): cargar → validar y grabar → T1 → T2 → consolidar → resumen → el analista gestiona las excepciones.

---

## 2. Objetos a crear (paso a paso)

Todo en el **esquema dueño** de las tablas `VTA_FACO*`, **sin prefijo de esquema**, compatible con Oracle 10.2 y en ASCII.

| Paso | Script | Objeto | Tipo | Para qué | Subtarea |
|---|---|---|---|---|---|
| 00 | `00_prechecks.sql` | — | Solo lectura | 14 verificaciones del ambiente, cada una con su resultado esperado | Ambas |
| 01 | `01_tabla_homologa.sql` | `VTA_FACOPRD_CIERRE` | Tabla | Cola: copia de cada sobre (columnas `prv_*` heredadas de `VTA_FACOPRD`) más control `pcr_*` (estado P/C/O/V, ejecución, resultado, intentos) | Ambas |
| 01 | ″ | `SEQ_VTA_FACOPRD_CIERRE` | Secuencia | `pcr_id` | Ambas |
| 01 | ″ | `PK_VTA_FACOPRD_CIERRE`, `CK_VTA_FACOPRD_CIERRE_EST`, `IND_VTA_FACOPRD_CIERRE_01/02` | PK, check, índices | Integridad y acceso por estado o caja | Ambas |
| 02 | `02_log.sql` | `VTA_FACOLOG_CIERRE_AUTO` | Tabla | Registro de ejecución: proceso T1/T2/CC, nivel Y (o "-" para inicio/fin), DR, resultado, regla y mensaje | Ambas |
| 02 | ″ | `SEQ_VTA_FACOLOG_CIERRE_AUTO` | Secuencia | `log_id` y número de ejecución | Ambas |
| 02 | ″ | `IND_VTA_FACOLOG_CIERRE_AUTO_01/02` | Índices | Por ejecución y por caja | Ambas |
| 03 | `03_parametros.sql` | 9 filas en `VTA_FACOPARAM` tipo 1502 (`CA_VAL_USD` eliminado el 07-10) | Datos | Interruptores, rango, validaciones opcionales, decimales, días y cajas sin sobres (§4) | Ambas |
| 03b | `03b_vista_cajas.sql` | `VTA_FACOV_CAJAS_CIERRE` | Vista | Universo común de T1 y T2: COLA + SIN_SOBRE (columnas `cc_fecha`, `cc_local`, `cc_terminal`, `cc_cierrey`, `cc_origen`) | Ambas |
| 03c | `03c_permiso_cc.sql` | Opción 1515 en `VTA_FACOMENU` / `VTA_FACORELPERMEN` | Datos | Botón "Cerrar Terminal" de `Form43` en FACO (no existía); se crea deshabilitada | T2 (front) |
| 04 | `04_pkg_cierre_auto_spec.sql` | `PKG_F8_FACO_CIERRE_AUTO` (especificación) | Paquete | Entradas `prc_cierre_automatico` (job) y `prc_cierre_rango` (`Form43`); `fn_dif_real`, `fn_dif_caja`, `fn_compensado`, `pr_valida_y`, `pr_valida_z`, `fn_param` y validaciones sueltas | T2 |
| 05 | `05_pkg_compensa_di_spec.sql` | `PKG_F8_FACO_COMPENSA_DI` (especificación) | Paquete | `prc_compensa_di`, `fn_evalua_caja` (simulación), `fn_estado_di` | T1 |
| 06 | `06_pkg_compensa_di_body.sql` | `PKG_F8_FACO_COMPENSA_DI` (cuerpo) | Paquete | Lógica de T1; usa `fn_dif_real` y `fn_param` de T2 | T1 |
| 07 | `07_pkg_cierre_auto_body.sql` | `PKG_F8_FACO_CIERRE_AUTO` (cuerpo) | Paquete | Lógica de T2; **llama a T1 al inicio** | T2 |
| 08 | `08_trigger.sql` | `TRG_VTA_FACOPRD_CIERRE_AI` | Trigger `AFTER INSERT` por fila en `VTA_FACOPRD` | Encola cada sobre F8/DOL. **Va al final**, para no encolar antes de que los paquetes estén compilados | Ambas |
| 09 | `09_grants_sinonimos.sql` | Grants y 5 sinónimos | DCL / DDL | `EXECUTE` y `SELECT` (incluida la vista) para el usuario de aplicación o del job (el script lo pide con `accept`). **El usuario de `[CONNECT]` del exe también los necesita** para `Form43` | Ambas |
| 10 | `10_pruebas.sql` | — | Pruebas | Compilación, DR contra la F8, validaciones, cola, simulación, ejecución completa, resumen, vista, columnas de `Form43` y `prc_cierre_rango` | Ambas |
| 99 | `99_rollback.sql` | — | Reversión | Apagar, revertir una ejecución o desinstalar todo | Ambas |
| — | `INSTALAR.sql` | — | Maestro | Ejecuta 00 a 08 en orden y muestra el estado final | Ambas |

**Por qué este orden.** Las dos especificaciones van antes que los dos cuerpos, porque el cuerpo de T1 usa la especificación de T2 y el cuerpo de T2 usa la especificación de T1. El trigger va al final, cuando los paquetes ya están compilados.

**Objetos existentes que se usan, sin modificarlos:**
- `VTA_FACOPRD`, `VTA_FACOTERMSTAT[Y]`, `VTA_FACOLIBVTA`, `VTA_FACOZZZ`, `VTA_FACOTESOR`, `VTA_FACOTARJ`, `VTA_FACORECMEX`, `VTA_FACOMOVDET`, `VTA_FACOCARTAAVISO`, `VTA_FACODIFVEND`, `VTA_FACOCONCEPDIF`, `VTA_FACOCHEQUES`, `VTA_FACOCOMPDES`, `VTA_FACOPARAM`, `VTA_PAINT_Z`;
- `SEQ_VTA_FACOVEN` (techkey de la DI) y `TRG_VTA_FACOCOMPDES_I_SEQ` (numera las observaciones).

---

## 3. Instalación

| Paso | Quién / cómo |
|---|---|
| 1 | Conectarse como el **dueño** de las tablas `VTA_FACO*` (en test, el dueño de `VTA_FACOPRD`; se averigua con `select owner from all_tables where table_name = 'VTA_FACOPRD'`). Si instala el DBA con su usuario: `alter session set current_schema = <dueño>` |
| 2 | Ejecutar `00_prechecks.sql` y comparar con los resultados esperados |
| 3 | Desde esta carpeta: `@INSTALAR.sql` (pasos 00 a 08; se detiene ante el primer error). También se pueden ejecutar los scripts uno a uno, en el orden de §2 |
| 4 | `09_grants_sinonimos.sql`: Parte A como dueño; Parte B como DBA |
| 5 | `10_pruebas.sql`, en test. Antes de activar en producción, la DR de `fn_dif_real` debe coincidir con la "Diferencia Real" de la F8 en al menos 10 cajas |
| 6 | Agendar el job (fuera de alcance): `begin PKG_F8_FACO_CIERRE_AUTO.prc_cierre_automatico; end;` |
| 7 | Habilitar la opción 1515 a los perfiles que defina negocio (`Form47` o el `UPDATE` comentado en `03c_permiso_cc.sql`) |
| 8 | Publicar el exe con el nuevo `Form43.frm`: compilar, subir `Gversion` y `vta_parametros.vta_ultversion` de todos los países. **Después** de instalar la base |

**Derechos del dueño.** Los paquetes y su SQL dinámico se ejecutan con los privilegios del dueño. Si alguna tabla no es del mismo esquema, el dueño necesita un **grant directo** (no a través de un rol).

---

## 4. Parámetros (`VTA_FACOPARAM`, tipo 1502)

Se leen en cada ejecución y se cambian con `UPDATE … set vta_xglosa = … where vta_ccodtipo = 1502 and vta_ccodigo = …`.

| Código | Inicial | Proceso | Uso | Si no existe |
|---|---|---|---|---|
| `CA_DI_ACTIVO` | S | T1 | T1 activa | N (apagada) |
| `CA_DI_MIN` | −1000 | T1 | Límite inferior de la DR (inclusive) | −1000 |
| `CA_DI_MAX` | 20000 | T1 | Límite superior de la DR (inclusive) | 20000 |
| `CA_ACTIVO` | S | T2 | T2 activa | N (apagada) |
| `CA_VAL_CHEQ` | S | T2 | Valida cheque a fecha (RY-01) | S |
| `CA_VAL_ZZZ` | N | T2 | Valida la fórmula ZZZ de la Y (RY-06; opción 103 del exe) | N |
| `CA_DECIMAL` | 0 | Ambos | Decimales de la DR (`gFormat` de Colombia `'#,#0'`) | 0 |
| `CA_DIAS` | 30 | Ambos | Días que una caja pendiente se reevalúa | 30 |
| `CA_SIN_SOBRE` | S | Ambos | Incluye los cierres Y abiertos sin sobres del mismo local y día de la carga (vista, origen SIN_SOBRE) | N (solo la cola) |

Los interruptores son independientes: se puede correr solo T1, solo T2 o ambos. El rango de la **DI manual** (1500/1501 'DI', −500 / 20.000, que usa `Form38`) no se modifica.

---

## 5. Reglas

### 5.1 T1: compensación automática de DI (`PKG_F8_FACO_COMPENSA_DI`)

Replica la DI manual del exe: `Form4` → `Form38` → `Módulo1.InsertarRegistroMovDet` (`FTEPROD/Módulo1.bas:3777`) y `Form45.GrabarObs`.

| # | Regla | Resultado en el log |
|---|---|---|
| 1 | Cierre Y existente y abierto (bloqueo `NOWAIT`) | `SIN_TERMSTAT` · `OCUPADA` · `YA_CERRADA` |
| 2 | DR = diferencia real de la F8, después de las compensaciones previas | `SIN_LIBVTA` si no hay libro de ventas de la Y |
| 3 | DR = 0 → sin DI, pasa a T2 | `DR_CERO` |
| 4 | Fuera de [`CA_DI_MIN`, `CA_DI_MAX`] → pendiente para gestión de tiendas | `FUERA_RANGO` |
| 5 | Ya tiene una DI automática (segunda carga, DUD-050) | `DI_AUTO_PREVIA` |
| 6 | Ya tiene una DI manual → no se toca | `DI_MANUAL_PREVIA` |
| 7 | Registra la DI y verifica que la DR quede en 0 (si no, revierte) | `DI_REGISTRADA` · `ERROR` |

Registro:

```
VTA_FACOMOVDET:  mov_tipomov 'DI', mov_rol 0, mov_nombre ' ', mov_secuencia 0, mov_numero 0,
                 mov_monto = round(DR,2) (mismo signo), mov_hechopor 'PROC_DI_AUTO', mov_regul 'S',
                 mov_fecha = mov_fechareg = fecha de venta (fecha contable), mov_techkey SEQ_VTA_FACOVEN, mov_cierrey = Y
VTA_FACOCOMPDES: cpd_tipmov 'DI', cpd_obs 'COMPENSACION AUTOMATICA DI', cpd_cierrey = Y (UPDATE si existe)
```

### 5.2 T2: cierre de caja automático (`PKG_F8_FACO_CIERRE_AUTO`)

Replica `Form3Y.CierraTerminal` (Y, `FTEPROD/Form3Y.frm:2801`). La primera regla que falla bloquea. **FACO opera solo con cierre Y** (07-10-2026): las reglas de la Z de `Form3.CierraTerminal` no se aplican y `VTA_FACOTERMSTAT` no se toca.

| Nivel | Secuencia |
|---|---|
| Y | Bloqueo (`OCUPADA`) → RY-02 estado (`YA_CERRADA`, no se reabre) → libro de ventas (`SIN_LIBVTA`) → RY-05 DR = 0 (`CON_DIFERENCIA`) → RY-01 cheque a fecha* → RY-03 conceptos SN, AF, ND, FN, NP, BF, CR, CT, CA, DP → RY-06 ZZZ* → **cierra la Y** (`CERRADA_Y`) |

\* Según parámetro. Un cierre graba `ter_estado = 1`, `ter_cerradopor = 'PROC_CIERRE_AUTO'` y `ter_notas = 'CIERRE AUTOMATICO FSCC-12958 dd-mm-yyyy hh24:mi | <nota anterior>'`.

**Desde `Form43` (`prc_cierre_rango`):** mismas reglas, sin T1 y sin depender de `CA_ACTIVO`. Universo: cierres Y abiertos con libro de ventas del rango, local y terminal (la Z no se toca). Graba `ter_cerradopor` = usuario del analista y `ter_notas = 'CIERRE CC FSCC-12901 …'`; en el log, `log_proceso = 'CC'`.

### 5.3 Diferencia real (común a T1 y T2: `fn_dif_real`)

```
DR = (sobres EFE − REC_MEFECTIVO) + (sobres CHE − REC_MCHKDIA) + USD recaudados
   + (tesorería cheque a fecha − REC_MCHKFECHA) + (tarjetas 2000–2999 − (REC_MTARJ + REC_MSODIMAC))
   − round(compensado)          (13 ramas de Módulo1.StrSumCompensado; incluye la DI)
redondeado a CA_DECIMAL         (igual que Label70 de Form3Y)
```

Detalle y SQL en `docs/CierreCaja_FACO_Reglas.md` §2. El cálculo está en el privado `pr_cuadratura`, que también entrega las columnas de `Form43`: `fn_dif_caja` (sumaBZ) y `fn_compensado` (compensado), ambas sin redondear.

---

## 6. Estados de la cola (`VTA_FACOPRD_CIERRE.pcr_estado`)

| Estado | Significado | Lo asigna |
|---|---|---|
| `P` | Pendiente. Se reevalúa en cada ejecución (con diferencia, bloqueada, fuera de rango, ocupada, error…) | Trigger / T2 |
| `C` | Terminada: Y cerrada por el proceso, o ya estaba cerrada | T2 |
| `O` | Omitida: sobre sin número de Y | T2 (paso 1) |
| `V` | Vencida: fecha de venta más antigua que `CA_DIAS` | T2 (paso 1) |

T1 no modifica la cola: lee las cajas de la vista. Las cajas SIN_SOBRE no tienen filas en la cola: su resultado queda solo en el log, y se reevalúan mientras su local-día tenga carga pendiente.

---

## 7. Operación

| Acción | Cómo |
|---|---|
| Ejecutar todo | `begin PKG_F8_FACO_CIERRE_AUTO.prc_cierre_automatico; end;` |
| Solo T1 | `begin PKG_F8_FACO_COMPENSA_DI.prc_compensa_di; end;`, o `CA_ACTIVO = 'N'` y ejecutar todo |
| Solo T2 | `CA_DI_ACTIVO = 'N'` y ejecutar todo |
| Apagar todo | `CA_DI_ACTIVO = 'N'` y `CA_ACTIVO = 'N'` (`99_rollback.sql`, paso 1) |
| Simular T1 sin grabar | `PKG_F8_FACO_COMPENSA_DI.fn_evalua_caja(fecha, local, terminal, y, :dr)` |
| Ver la DR de una caja | `select PKG_F8_FACO_CIERRE_AUTO.fn_dif_real(fecha, local, terminal, y) from dual` |
| Resumen de la última ejecución | Consulta 8 de `10_pruebas.sql` (agrupa por `log_proceso` y `log_resultado`) |
| Lo hecho por el proceso | DI: `mov_hechopor = 'PROC_DI_AUTO'`. Cierres: `ter_cerradopor = 'PROC_CIERRE_AUTO'` (o el usuario del analista con `log_proceso = 'CC'`) |
| Cerrar desde la pantalla | `Form43` → informe "Terminal" → Consulta → Cerrar Terminal (FACO, opción 1515) |
| Ver el universo | `select cc_origen, count(*) from VTA_FACOV_CAJAS_CIERRE group by cc_origen` |

**Excepciones para el analista** (en el log): `FUERA_RANGO`, `DI_AUTO_PREVIA`, `DI_MANUAL_PREVIA`, `CON_DIFERENCIA`, `BLOQUEADA` (con regla y mensaje), `SIN_LIBVTA`, `ERROR`. Se gestionan con las pantallas de siempre:
- reabrir: `Form20`;
- compensar: `Form4` → `Form38`;
- cerrar: `Form3Y` / `Form3`.

---

## 8. Matriz de pruebas del flujo completo

| # | Escenario | T1 | T2 | Criterio |
|---|---|---|---|---|
| 1 | Y con DR −800, sin pendientes | `DI_REGISTRADA` (−800) | `CERRADA_Y` (la Z no cambia) | CA1 |
| 2 | DR −1000 / 20000 | `DI_REGISTRADA` | Se cierra | CA2 |
| 3 | DR −1001 / 20001 | `FUERA_RANGO` | `CON_DIFERENCIA` (queda pendiente) | CA3 |
| 4 | DR en rango + SN pendiente | `DI_REGISTRADA` | `BLOQUEADA` RY-03 (mensaje del concepto) | CA4 |
| 5 | Identificación de la DI | `mov_hechopor` + glosa | — | CA5 |
| 6 | Cambio de `CA_DI_MIN` / `CA_DI_MAX` | Usa el nuevo rango | — | CA6 |
| 7 | Venta del 28-09 cargada otro día | `mov_fechareg` = 28-09 | — | CA7 |
| 8 | Caja sin sobres con DR en rango | `DI_REGISTRADA` | Se cierra | CA8 |
| 9 | Y ya en DR 0 | `DR_CERO` | `CERRADA_Y` | — |
| 10 | Segunda ejecución con DI automática previa y DR ≠ 0 | `DI_AUTO_PREVIA` | `CON_DIFERENCIA` | DUD-050 |
| 11 | DI manual del analista | `DI_MANUAL_PREVIA` | Según DR | Decisión 06-10 |
| 12 | Terminal con 3 Y, una fuera de rango | 2 `DI_REGISTRADA` | 2 `CERRADA_Y`, 1 `CON_DIFERENCIA`; la Z no cambia | — |
| 13 | (eliminado 07-10: no hay cierre de la Z) | — | — | — |
| 14 | Cheque a fecha gestión ≠ tesorería | Puede registrar DI | `BLOQUEADA` RY-01 | — |
| 15 | Caja abierta por un analista (bloqueo) | `OCUPADA` | `OCUPADA` | — |
| 16 | `CA_DI_ACTIVO = N` | `INACTIVO` | Corre normal | — |
| 17 | `CA_ACTIVO = N` | Corre normal | `INACTIVO` | — |
| 18 | Ejecutar dos veces seguidas | Sin DI duplicada | Sin cambios en lo cerrado | — |
| 19 | Terminal Autopago (cierre `AUTOMATICO` existente) | — | Mismo resultado que el cierre actual | Convivencia |
| 20 | DR de `fn_dif_real` contra la F8 en 10 cajas | Igual | Igual | Precondición |
| 21 | Caja sin sobres, mismo local-día de una carga, DR 0 (`CA_SIN_SOBRE = S`) | `DR_CERO` | `CERRADA_Y` | DF-SCC fila 12 |
| 22 | Igual que 21 con `CA_SIN_SOBRE = N` | No se evalúa | No se evalúa | — |
| 23 | `Form43` FACO: la grilla muestra también las cajas con DR 0; el botón aparece solo con la opción 1515 | — | — | DF-SCC fila 12 |
| 24 | `Form43` FACO: Cerrar Terminal con DR 0 y con DR ≠ 0 | No corre | `CERRADA_Y` / `CON_DIFERENCIA`, `log_proceso` CC, resumen en pantalla | DF-SCC fila 12 |
| 25 | Y con DR −22: T1 registra DI −22 y la DR queda en 0 | `DI_REGISTRADA` | `CERRADA_Y` en la misma ejecución | **CA9** (HU 07-10) |
| 26 | Cualquier ejecución (job o `Form43`) | — | `VTA_FACOTERMSTAT` sin cambios (`ter_cerradopor` de proceso = 0 filas) | Solo Y (07-10) |

---

## 9. Decisiones de diseño (06 y 07-10-2026)

1. Todo en **Oracle**, con un único punto de entrada (`prc_cierre_automatico`) y el orden T1 → T2 del diagrama.
2. **Cola compartida** alimentada por trigger: "cajas de la carga" = cierres Y con sobres nuevos.
3. Validaciones que dependen del perfil → **parámetros**.
4. **Rango propio** de T1; la DI manual no cambia.
5. **DI manual previa:** no se toca.
6. **Usuarios de proceso:** `PROC_DI_AUTO` (T1) y `PROC_CIERRE_AUTO` (T2).
7. ~~La Z se cierra con sus validaciones propias~~ → **07-10: FACO solo cierre Y, la Z no se toca.** La fecha de cierre va en `ter_notas` (no existe la columna).
8. Scripts **sin prefijo de esquema**, en ASCII, para Oracle 10.2.
9. **DF-SCC:** las cajas sin sobres del mismo local-día entran al universo (vista + `CA_SIN_SOBRE`); `Form43` FACO delega en el paquete de T2 (columnas y Cerrar Terminal); sin pantalla de resumen; la opción 1515 se crea deshabilitada.
10. **07-10-2026:** se mantiene el job externo (`Form133` no llama al SP), no hay resumen en pantalla y `Form133.AbrirTerminal` no se toca.

## 10. Riesgos y pendientes

- **Compilar y probar en test** (no se ha hecho). Prueba clave: la DR del paquete contra la F8.
- **El trigger ignora sus propios errores** para no frenar la carga; `10_pruebas.sql` trae una consulta de conciliación.
- **Convivencia con `PKG_F8_FACO_CIERRE_TER_PM_AP`**, el cierre `AUTOMATICO` de Autopago: coordinar horarios; su cuerpo lo tiene el DBA.
- **Envío Contable (`Form62`):** suma la DI por fecha y local. Separar la DI automática requiere un cambio en el exe, si Contabilidad lo pide.
- **Y cerrada que recibe un sobre:** no se reabre (`YA_CERRADA`): `Form133.AbrirTerminal` solo reabre la Z. La reapertura de la Y es manual (`Form20`).
- **Puntos abiertos con negocio (07-10):** la HU pide ejecutar "al momento de la carga" y "emitir un resumen", y el diagrama P2 dice "cerrar el terminal del día". Se resolvió con el job, el SQL del log y solo Y.
- **`Form38`** puede modificar una DI automática (actualiza la DI con `mov_rol = 0`); es una corrección manual consciente.
- **`Form43` no compilado:** se compila y prueba en el IDE de VB6. Si se publica el exe antes de instalar la base, la consulta de FACO falla ("Problemas de comunicación").
- **Rendimiento de `Form43`:** tres funciones PL/SQL por fila. Con rangos largos o todos los locales puede ser lento (ver `FSCC-12901_Analisis.md` §3.13).
- **Datos de test:** no hay cargas PRD recientes (`VTA_FACOPRD` llega a 2022); para probar la rama SIN_SOBRE hay que cargar sobres (p. ej. `PRD 3.xlsx`).

## 11. Documentación relacionada

- Índice del requerimiento: `docs/README_FSCC-12901.md`.
- Reglas del cierre manual con SQL: `docs/CierreCaja_FACO_Reglas.md`.
- Análisis de la historia: `docs/FSCC-12901_Analisis.md`.
- PDF por subtarea: `docs/FSCC-12957_T1_Compensacion_DI_automatica.pdf` y `docs/FSCC-12958_T2_Cierre_caja_automatico.pdf`.
- Diagramas BPMN: `docs/Requeriemintos-FSCC-12901/`.
