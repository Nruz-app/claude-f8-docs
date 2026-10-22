# POC FSCC-12901: prueba del flujo completo con datos reales (desarrollo)

POC para ver cómo se comporta el flujo **T1 (DI automática) → T2 (cierre automático de cierres Y)** desde SQL, sin pasar por el exe, con **datos reales** y con **volumen de una carga real**.

## Ambientes

| Ambiente | Usuario | Puede crear objetos | Datos FACO | Uso en la POC |
|---|---|---|---|---|
| **Test** | usuario de solo lectura de test | No | Sí: cajas reales de 2026 | Solo se **lee**, con `02g`, para generar los datos |
| **Desarrollo** | `INTRANETDE` | Sí; los objetos de FSCC-12901 ya están instalados | Casi nada (hasta 2022) | Aquí se **carga y se ejecuta** todo |

Los dos esquemas están en la misma base (`sgfnprds`), pero desarrollo no puede leer las tablas de test. Por eso los datos pasan como un script de INSERTs (`02_datos_test.sql`), generado desde test con `02g_generar_datos_test.sql`. Las claves de acceso no se guardan en estos archivos.

## Qué se prueba

**A. Cajas reales de test.** 714 cierres Y de 2026 (446 abiertos) en 55 local-día, sobre todo del 07-01-2026. Se copian con su libro de ventas, el detalle `zzz` y las tarjetas reales. En test esas cajas no tienen sobres, así que la POC los genera simulando `Form133`:

| Escenario | Sobre | Esperado T1 | Esperado T2 |
|---|---|---|---|
| R0 | Depósito = efectivo declarado (como haría la tienda) | El que den sus datos (prevision de `05`) | El que den sus datos |
| E1 | Calculado para DR −800 | `DI_REGISTRADA` | `CERRADA_Y` |
| E2 | Calculado para DR 0 | `DR_CERO` | `CERRADA_Y` |
| E3 | Calculado para DR −30000 | `FUERA_RANGO` | `CON_DIFERENCIA` |
| S0 | Sin sobre (entra como `SIN_SOBRE`) | Prevision de `05` | Prevision de `05` |

E1, E2 y E3 solo se asignan a cajas sin DI previa y sin reglas que las bloqueen; si una caja no califica, pasa a R0.

**B. Día PRD 3 (28-08-2026).** Los **486 sobres reales** de `PRD 3.xlsx` (357 cajas, 27 locales, $992.569.000). En test no hay cajas de ese día, así que se crean los cierres Y y el libro de ventas usando como molde una fila real copiada de test. El efectivo declarado se calcula para que, con los sobres reales, la DR quede en el valor del escenario:

| Escenario | Cajas | DR | Esperado T1 | Esperado T2 | Criterio |
|---|---|---|---|---|---|
| P0 | ~50% | 0 | `DR_CERO` | `CERRADA_Y` | — |
| P1 | ~15% | −800 | `DI_REGISTRADA` | `CERRADA_Y` | CA1, CA9 |
| P2 | ~15% | +3000 | `DI_REGISTRADA` | `CERRADA_Y` | CA1 |
| P3 | 2 | −1000 y +20000 (límites) | `DI_REGISTRADA` | `CERRADA_Y` | CA2 |
| P4 | ~10% | −30000 y +25000 | `FUERA_RANGO` | `CON_DIFERENCIA` | CA3 |
| P5 | ~10% | 0 + sobre no enviado (SN) sin regularizar | `DR_CERO` | `BLOQUEADA` RY-03 | CA4 |
| P6 | 1 por local (27) | Y 2 sin sobres y sin venta (DR 0) | `DR_CERO` | `CERRADA_Y` | DF-SCC fila 12 |
| P7 | 1 cada 3 locales (9) | Y 3 sin sobres, venta 5000 (DR −5000) | `FUERA_RANGO` | `CON_DIFERENCIA` | CA8 |

## Orden

| Paso | Script | Dónde | Graba | Qué hace |
|---|---|---|---|---|
| 0 | `02g_generar_datos_test.sql` | **Test** (SQL*Plus) | No | Regenera `02_datos_test.sql`. **Opcional**: ya viene generado (07-10-2026) |
| 1 | `01_preparar.sql` | Desarrollo | Sí | Verifica los 8 objetos y los parámetros, y que no haya datos de 2026. Crea las tablas `VTA_FACOPOC_*`. Sube `CA_DIAS` a 4000 (lo restaura 99) |
| 2 | `02_datos_test.sql` | Desarrollo | Sí | Carga las cajas reales de test (unos 3.200 INSERTs). Al final compara cargado con esperado |
| 3 | `03_dia_prd3.sql` | Desarrollo | Sí | Carga PRD 3 y crea las cajas del 28-08-2026 con sus escenarios |
| 4 | `04_cargar_sobres.sql` | Desarrollo | Sí | Simula `Form133`: carga los sobres (los reales de PRD 3 y los calculados para test). El trigger los encola. Verifica que la DR quede en el objetivo |
| 5 | `05_simular.sql` | Desarrollo | Solo la previsión | Anticipa, caja por caja, qué harán T1 y T2 |
| 6 | `06_ejecutar_proceso.sql` | Desarrollo | Sí | Ejecuta el proceso como el job y mide la duración |
| 7 | `07_resultados.sql` | Desarrollo | No | Esperado frente a obtenido por escenario (OK / diferentes), DI (monto, fecha contable, glosa), cierres, cola, Z sin cambios y rendimiento |
| 8 | `08_opcional_form43.sql` | Desarrollo | Sí | El botón "Cerrar Terminal" de `Form43` (`prc_cierre_rango`) sobre un local del día PRD 3 |
| — | `98_reiniciar.sql` | Desarrollo | Revierte | Deshace solo lo que hizo el proceso, para ejecutar `06` de nuevo |
| — | `99_limpiar.sql` | Desarrollo | Revierte | Borra todo lo del POC, restaura `CA_DIAS` y borra las tablas POC |

**Cómo ejecutar:**
- **DBeaver:** abrir cada script y usar **Ejecutar script (Alt+X)**, con la salida del servidor activada (Ctrl+Shift+O). `02_datos_test.sql` pesa 2 MB y tarda unos minutos.
- **SQL*Plus:** `@01_preparar.sql`, etc., con `set serveroutput on`.

## Qué mirar en `07_resultados.sql`

1. **Bloque 2:** la columna `diferentes` debe ser **0** en todos los escenarios.
2. **Bloque 3:** detalle de cualquier diferencia, con la regla y el mensaje.
3. **Bloque 4 (DI):**
   - `monto_igual_dr` = `di` en P1, P2, P3 y E1;
   - `fecha_contable_ok` = `di`;
   - `glosa_ok` = `di`.
   En R0, `monto_igual_dr` puede ser 0, porque su DR no es fija.
4. **Bloque 7:** `z_cerradas_por_el_proceso` = **0** (FACO solo cierre Y).
5. **Bloque 8:** segundos por caja (rendimiento con volumen real).

## Marcas para deshacer

| Qué | Cómo se identifica |
|---|---|
| Sobres | `prv_modifpor = 'POC_FSCC12901'` |
| Libro de ventas / `zzz` copiados de test | techkey entre 900.000.000 y 989.999.999 |
| Libro de ventas / `zzz` del día PRD 3 | techkey desde 990.000.000 |
| Local-día cargados | tabla `VTA_FACOPOC_DIAS` (origen TEST / PRD3) |

## Prueba por pantalla (aplicativo F8)

Para probar el mismo flujo cargando el archivo con `Form133` (Carga Manual de Sobres) en lugar de `04`, seguir el manual `docs/MANUAL_Prueba_FSCC-12901_por_pantallas.pdf`. Usa la carpeta `manual/`:
- `PRD3_locales_6_13_prueba_manual.xlsx`: 29 sobres reales;
- `M1_preparar_prueba_manual.sql`;
- `M2_resultados_prueba_manual.sql`;
- `M9_limpiar_prueba_manual.sql`.

Orden: `01` → `02` → `03` → `M1` → carga por pantalla → `06` → `M2`. Para limpiar: `M9` → `99`.

## Cuidados

- Ejecutar en **desarrollo**, nunca en producción.
- **Revisar `07` antes de `98` o `99`**: borran la evidencia.
- Si `01` muestra datos de 2026 o la cola con pendientes, ejecutar antes `99_limpiar.sql`.
- `03` depende de `02`: usa una fila real copiada de test como molde.
- Para repetir la ejecución con los mismos datos: `98_reiniciar.sql` → `06` → `07`.
