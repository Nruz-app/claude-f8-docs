# FSCC-12901: revisión de cumplimiento (16-10-2026)

Compara lo implementado con la HU **FSCC-12901** y sus subtareas **FSCC-12957** (T1) y **FSCC-12958** (T2).

- **Fuente de los requisitos:** las exportaciones del 07-10 en `docs/Requeriemintos-FSCC-12901/Doc-Actualizado/`. Jira no se consultó en línea; si los tickets cambiaron después de esa fecha, esos cambios no están cubiertos.
- **Implementación revisada:**
  - `docs/sql/FSCC-12901_PROC_Y/` (`PKG_F8_COMPENSA_DI_AUTO`, `PKG_F8_CIERRE_AUTO`);
  - `FTEPROD/Form133.frm` (llamada al terminar la carga);
  - `FTEPROD/Form7.frm` y `FTEPROD/Form43.frm` (este último modificado el 16-10, ver §3).
- **Pruebas en test:** la prueba 3 del 16-10 dio OK en las 4 cajas (`README_FSCC-12901.md` §9, filas 39 y 40).

## 1. Criterios de aceptación de la HU

| CA | Pide | Estado | Cómo se cumple |
|---|---|---|---|
| 1 | DR −800 → DI, DR 0 y cierre con usuario de proceso y fecha | ✔ | T1 + T2 en la misma ejecución. `ter_cerradopor = PROC_CIERRE_AUTO`, fecha en `ter_notas`. Prueba 2 (DI +500 y cierre) |
| 2 | Límites −1.000 y 20.000 se compensan | ✔ | `06_pkg_compensa_di_body.sql:114`: compara con `<` y `>`, así que los límites quedan incluidos |
| 3 | −1.001 / 20.001: sin DI, Pendiente y **en el resumen como excluido por rango** | ◐ | Sin DI y Pendiente: ✔ (pruebas 3 y 4). Resumen: el `MsgBox` de `Form133` muestra solo totales; el motivo `FUERA_RANGO` está en `VTA_FACOLOG_CIERRE_AUTO` |
| 4 | Concepto pendiente: no cierra y **el resumen indica el concepto** | ◐ | No cierra: ✔ (RY-03, con el mensaje de `Form3Y`). El concepto está en el log, no en pantalla |
| 5 | DI identificada como automática en el Informe de Diferencias **o** en el Envío Contable | ✔ | Basta con uno de los dos. Informe de Diferencias (`Form7`, FACO, `Form7.frm:9386`): muestra la glosa `COMPENSACION AUTOMATICA DI` de `COMPDES`, y `mov_hechopor = PROC_DI_AUTO`. El Envío Contable (`Form62` / `Form159`) agrupa por operación y no separa la DI automática de la manual: es una **mejora opcional** que decide Contabilidad, no un requisito de la HU. *(Corregido el 16-10: antes figuraba como parcial)* |
| 6 | Cambio de límites sin cambio de código | ✔ | `CA_DI_MIN` / `CA_DI_MAX` en `VTA_FACOPARAM` tipo 1502 |
| 7 | Fecha contable = fecha de venta | ✔ | `mov_fechareg = mov_fecha` = fecha de venta |
| 8 | Terminal sin sobres con DR en rango se compensa | ✔ | `CA_SIN_SOBRE = S`: las Y del mismo local y día de la carga entran al universo (`fn_universo`) |
| 9 | DR 0 tras la imputación automática → validación y cierre | ✔ | Orden T1 → T2 en `prc_cierre_automatico` |

## 2. Reglas de la HU y de las subtareas

| Regla | Estado | Nota |
|---|---|---|
| DR = Dif. de Caja − Compensación, la misma de la F8 | ✔ | `fn_dif_real` replica `Label70` de `Form3Y` |
| DI = DR con el mismo signo (T1) | ✔ | |
| DR ≠ 0 | ✔ | `DR_CERO` no genera DI |
| Fuera de rango: queda pendiente para tiendas | ✔ | |
| Usuario de proceso y glosa fija (DUD-052) | ✔ | |
| Segunda carga: sin segunda DI, queda para el analista (DUD-050) | ✔ | `DI_AUTO_PREVIA`; además `DI_MANUAL_PREVIA` |
| Se ejecuta al cargar el archivo de recaudación | ✔ | `Form133.CargarArchivo` → `EjecutaCierreAutomaticoFACO` (16-10) |
| T2: cierra con DR 0 y las validaciones de Cerrar Terminal, incluidas las cajas ya cuadradas; no compensa | ✔ | RY-01, RY-02, RY-03, RY-05 y RY-06 (RY-06 por flag, porque un proceso no tiene perfil) |
| "Colombia opera con cierre Y: la evaluación se hace por cierre Y **y por Z**" | ◐ | Solo Y. El cierre de la Z está listo y apagado en `FSCC-12901_PROC_YZ` (`CA_CIERRA_Z = N`), a la espera de negocio |
| Emite un resumen con los compensados, los cerrados y **los excluidos con su motivo** | ◐ | Totales en pantalla y detalle por SQL en el log (decisión del 07-10, ratificada el 16-10) |

## 3. Fuera del texto de la HU

- **DF-SCC fila 12 (`Form43`, Consultas de Cuadratura):** el usuario definió el alcance el 16-10. **Solo** la grilla del informe "Terminal" de Colombia debe mostrar también las cajas con Diferencia Real 0, como en Chile, sin llamar al paquete ni cerrar.
  - **Aplicado** en `FTEPROD/Form43.frm` con un cambio de una línea: en `SubBuscarOpcion`, `If DiferenciaReal <> 0 Or Flg_Pais$ = "ARG" Or Flg_Pais$ = "FACO" Then`, con la línea original comentada y marcas `xintec-nruz 16-10-2026`.
  - El botón "Cerrar Terminal" no se tocó (decisión del usuario). Con filas en 0, ese botón cerrará esas Y con la lógica actual del exe (`CierraTerminalYYY`).
  - La v2 con paquete y opción 1515 se descartó (queda en el ZIP `form43-v2`).

  **Falta compilar el exe y probarlo en test.** Como no está en ninguna de las tres tareas, se propone registrarlo como subtarea **HU-01-T3**; el texto está en `FSCC-12901_T3_Form43_propuesta_Jira.md`.
- **Envío Contable:** ver CA5. Separar la DI automática es una mejora opcional que decide Contabilidad.

## 4. Comentario propuesto para Jira

```
Desarrollo FSCC-12901 (T1 FSCC-12957 + T2 FSCC-12958) probado en test el 16-10-2026: OK.

Implementado:
- Paquetes PKG_F8_COMPENSA_DI_AUTO (T1) y PKG_F8_CIERRE_AUTO (T2), con cola VTA_FACOPRD_CIERRE,
  trigger sobre VTA_FACOPRD y log VTA_FACOLOG_CIERRE_AUTO.
- El proceso se ejecuta al terminar la carga de sobres (Form133, Carga Manual de Sobres).
- T1: DI automatica si -1.000 <= DR <= 20.000 (limites incluidos, DR <> 0), monto y signo de la DR,
  fecha contable = fecha de venta, usuario PROC_DI_AUTO y glosa "COMPENSACION AUTOMATICA DI".
  Rango en VTA_FACOPARAM (1502: CA_DI_MIN / CA_DI_MAX). No crea una segunda DI si ya existe una.
- T2: cierra los cierres Y con DR 0 que cumplen las validaciones de Cerrar Terminal
  (usuario PROC_CIERRE_AUTO). Incluye las cajas sin sobre del mismo local y dia.

Pruebas en test (local 6, 28-08-2026):
1 cuadre exacto -> cerrada | 2 DR +500 -> DI +500 y cerrada |
3 DR -1.500 -> fuera de rango, abierta | 4 DR +25.000 -> fuera de rango, abierta.

Puntos para confirmar con negocio:
1. Resumen: en pantalla se muestran los totales (Y evaluadas, cerradas, no cerradas). El detalle
   de las excluidas y su motivo (fuera de rango, concepto pendiente) queda en el log y se consulta
   por SQL. Confirmar si basta o si se requiere en pantalla.
2. Cierre de la Z: hoy solo se cierra la Y. El cierre de la Z esta desarrollado y apagado
   (parametro CA_CIERRA_Z); se activa si negocio lo confirma.
3. (Opcional) Envio Contable: la DI automatica se identifica en el Informe de Diferencias
   (glosa), con lo que se cumple el CA5. En el Envio Contable sale junto con la DI manual en
   "Diferencia no Imputable". Confirmar con Contabilidad si se quiere separar.
4. Consultas de Cuadratura (DF-SCC fila 12): en Colombia la grilla del informe "Terminal"
   muestra ahora tambien las cajas con Diferencia Real 0, como en Chile (solo visualizacion,
   sin cambios en el cierre). Pendiente compilar y probar en test. Como no esta en el texto de
   la HU ni de T1/T2, se propone crear la subtarea
   HU-01-T3 · Consultas de Cuadratura Colombia: mostrar las cajas con Diferencia Real 0.
```
