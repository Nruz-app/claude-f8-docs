# FSCC-12901: comparación con Onboarding_F8.html (13-10-2026)

Fuente: `Onboarding_F8.html` (HU-01, HU-11, HU-13, HU-14, HU-15; control de cambios 29-09 / 01-10 / 02-10; Guía del equipo).

## Veredicto
**La base va bien:**
- T1 cumple casi todas las reglas de HU-01;
- T2 cumple la parte "cierre Y" de HU-14;
- `Form43` cumple HU-11.

**Hay 3 brechas de fondo**, todas originadas en decisiones nuestras que el documento contradice:
1. el documento sí espera cerrar la Z (terminal-día);
2. espera que una carga posterior reabra lo que se cerró;
3. pide disparar el proceso al terminar la carga y no con un job.

**Hay 3 brechas menores:** el nombre del usuario de proceso, las columnas del log y los terminales sin movimiento que no tienen Y.

## Lo que ya cumple (✔)
| Regla del documento | Nuestra solución |
|---|---|
| DR = Dif. Caja − compensación, con la lógica vigente de F8 (paridad con Cuadratura por caja) | `fn_dif_real` replica `Form3Y` Label70; `Form43` usa el mismo paquete |
| Rango inclusivo −1.000..+20.000, DR ≠ 0, parámetros y switch en `VTA_FACOPARAM` | 1502 `CA_DI_MIN`, `CA_DI_MAX`, `CA_DI_ACTIVO` y `CA_ACTIVO`; DR 0 → `DR_CERO` |
| DI por el monto de la DR, mismo signo, fecha contable = fecha de venta | Sí (se verifica en el bloque 4 de la POC `07`) |
| Fuera de rango: sin DI, queda Pendiente | `FUERA_RANGO` → T2 `CON_DIFERENCIA` |
| Actúa sobre la DR remanente si hubo compensaciones manuales | Sí: `fn_compensado` |
| Validaciones de Cerrar Terminal (SN, AF, ND, FN, NP, BF, CR, CT, CA, DP, DE, tarjetas, por compensar, cheques); si fallan, la DI se mantiene y queda Pendiente con el motivo | `pr_valida_y` / `fn_conceptos` → `BLOQUEADA` con regla y mensaje |
| Sin sobres de retiro se compensa igual | Origen `SIN_SOBRE` (con `CA_SIN_SOBRE`) |
| No crea una segunda DI si ya hay una automática | `DI_AUTO_PREVIA` (y `DI_MANUAL_PREVIA`) |
| Error técnico: se revierte solo ese terminal, se registra ERROR y se sigue | `savepoint sp_di` / `sp_y` + log autónomo |
| Lo que hace el analista después no vuelve a disparar el proceso | Solo encola el trigger de `VTA_FACOPRD` (una carga nueva) |
| Glosa identificable | `'COMPENSACION AUTOMATICA DI'` (en mayúsculas por la convención de `Form45`) |
| HU-11: `Form43` como Chile, respaldo manual con Cerrar Terminal | `SubBuscarOpcionFACO` + `CierreTerminalFACO` (`prc_cierre_rango`) |

## Brechas
| # | El documento dice | Nosotros | Impacto | Propuesta |
|---|---|---|---|---|
| **B1** | HU-14 CA2: "se cierran ambos cierres Y **y el terminal-día**"; HU-01: "suma de Y = Z sin Y abiertos"; la tabla de negocios dice FACO "Z e Y"; HU-13: "aplica por cierre Y y por Z" | Solo Y; la Z no se toca (decisión del 07-10, por la doc actualizada) | **Alto**: contradicción entre las dos fuentes | **Confirmar con negocio o PO** cuál manda. Si piden la Z: agregar `pr_procesa_z` (todas las Y cerradas + ΣY = Z) después de T2. Ya existía antes de la reestructuración |
| **B2** | HU-13/14: "si llega después una Z o recaudación, **la carga reabre** el terminal" y vuelve a evaluarlo | Una Y cerrada que recibe un sobre nuevo da `YA_CERRADA`; `Form133.AbrirTerminal` solo reabre la Z | Medio | Que el trigger (o el proceso, al leer la cola) reabra la Y cerrada por el proceso (`ter_cerradopor` = usuario de proceso) y la vuelva a evaluar. Requiere acuerdo (antes se decidió no tocar `AbrirTerminal`) |
| **B3** | "Se gatilla **al terminar la carga**", "una ejecución por carga"; `comp`: "PKG_F8_COMPENSACION_DI **o módulo VB**"; HU-13: al final de la interfaz nocturna (shell), fecha de proceso − 1 | Job externo que lee la cola | Medio: `Form133` inserta fila a fila sin transacción y el job podría tomar una carga a medias | Opción a: llamar `prc_cierre_automatico` desde `Form133` al terminar `CargarArchivo` (rama FACO). Opción b: mantener el job pero procesar solo las colas sin inserciones en los últimos N minutos. Recomiendo **a** porque es lo que pide el documento |
| B4 | Usuario de proceso **`C_DIAUTO`** | `PROC_DI_AUTO` / `PROC_CIERRE_AUTO` | Bajo: los informes filtran por usuario | Cambiar las constantes de las specs `04`/`05`, las pruebas, `fn_estado_di`, `07_resultados` y los PDF. Confirmar si T2 también usa `C_DIAUTO` |
| B5 | Log por terminal con: ID de ejecución, **carga de origen**, fecha de venta, local, terminal, Y, **DC**, **compensaciones previas**, DR, **acción**, **monto DI**, motivo, usuario y hora | Tenemos ejecución, proceso, fecha, local, terminal, Y, DR, resultado, regla, mensaje, usuario y hora | Bajo | Agregar `log_origen` (COLA / SIN_SOBRE / CC + recaudador), `log_dif_caja`, `log_compensado` y `log_monto_di` (con ALTER en `02` y en el rollback) |
| B6 | HU-11/14: un terminal **activo sin movimiento** (sin venta) se lista y se cierra con DR 0; se excluyen los dados de baja (`ter_fechabaja`) | `SIN_SOBRE` exige una Y con libro de ventas; un terminal sin ninguna Y no tiene nada que cerrar en el nivel Y | Depende de B1: sin Z, "terminal sin movimiento" no tiene registro | Se resuelve junto con B1 (cerrar la Z de los terminales activos sin Y). Verificar el filtro `ter_fechabaja` en `Form43` |

## A verificar (sin cambio previsto)
- **Reapertura de Cierres (`Form20`)**: que permita reabrir una Y cerrada por el proceso y eliminar la DI (HU-01 CA "queda trazado").
- **Informes**: que la DI automática aparezca identificada en el Informe de Diferencias de Compensaciones (`Form7`) y en el Envío Contable, y que el terminal aparezca en verde en Estado General (`Form2`).
- **Caso de prueba del documento**: local 6, terminal 95, 08-04-2025, Y 1, DC −22 → DI −22. Agregarlo a `10_pruebas.sql` o a la POC si hay datos en test.
- **"Antes de dar una historia por terminada"**: otros negocios intactos (todo es `VTA_FACO*`) ✔; switch apagado = flujo actual ✔.

## Próximo paso propuesto
1. Llevar **B1, B2 y B3** a negocio o PO: son decisiones, no errores de código. Si se confirma "Z e Y", se revierte en parte la reestructuración del 07-10.
2. Con la aprobación del usuario, aplicar **B4 y B5** de inmediato (son bajos y no dependen de nadie), en `FSCC-12957`, `FSCC-12958` y la carpeta consolidada `FSCC-12901_T1_T2`, la POC y la documentación, y regenerar el manifiesto y el respaldo.
3. Dejar la comparación como documento en `docs/` (`FSCC-12901_Comparacion_Onboarding.md`) y agregar una fila al historial del README.

