# FSCC-12901 COMPENSA_DI: sesión de prueba 2 en test (un local por prueba)

Repite la sesión de `../prueba_test/` (local 6, 31-08-2026, OK el 20-10-2026) con los **mismos 4 escenarios y montos**, pero cada prueba en un **local distinto** y en una fecha nueva, el **10-09-2026**. `prueba_test/` queda intacta como evidencia.

Modelo del 19-10-2026: la carga de sobres (`Form133`) **no cierra la Y**. Por cada caja cargada:
- si la diferencia real (DR = sobres − efectivo de la Y) está entre **−1.000 y +20.000** (límites incluidos) y no es 0, registra una **DI automática** por el valor exacto y con el mismo signo;
- la DI lleva la observación `COMPENSACION AUTOMATICA DI`;
- la caja queda **Pendiente**.

Requisitos:
- en test, `PKG_F8_COMPENSA_DI_CARGA` instalado y `VALID` (al 20-10 está la versión multipaís, reinstalada ese día a las 14:56);
- el exe compilado con el `FTEPROD/Form133.frm` del 19-10 (`EjecutaCompensaDIFACO`).

## Datos (fecha 10-09-2026, Y 1)

Locales y terminales verificados en test el 20-10: local vigente en `vta_FACOlocales`, terminal de tipo 0 y nada cargado ese día (sin Y, Z cerrada, sobres, movimientos, tarjetas ni log).

La fecha está en septiembre a pedido del usuario, porque agosto ya tiene muchas pruebas: 28-08 y 31-08 (`../prueba_test/`) y 30-08 (`../prueba_test_6locales/`, que también usa los locales 18 y 25). En septiembre, test tiene datos FACO los días 04, 07, 08, 15, 23 y 29; el **10-09-2026** no tiene nada en ningún local (sin Y, libro de ventas, sobres, movimientos, Z, tarjetas, cartas aviso ni log DI; verificado el 20-10). Con una fecha propia, el "Cerrar Terminal" con `0-TODOS` de otras sesiones no toca estas cajas.

| # | Escenario | Local | Terminal | Archivo | Sobres | Total sobres | EFECTIVO = BOLETAS en Form19Y | DR | Esperado |
|---|---|---|---|---|---|---|---|---|---|
| 1 | OK: **DI negativa** | **5** Unicentro Cali | 27 | `Prueba-1-OK-DINegativa_L5T27.xlsx` | 527091001 (2.000.000), 527091002 (670.000) | 2.670.000 | **2.670.800** | −800 | `DI_REGISTRADA` −800; Dif. Real 0; Pendiente |
| 2 | OK: **DI positiva** | **25** Fontanar Chía | 12 | `Prueba-2-OK-DIPositiva_L25T12.xlsx` | 2512091001 (500.000), 2512091002 (375.000) | 875.000 | **860.000** | +15.000 | `DI_REGISTRADA` +15.000; Dif. Real 0; Pendiente |
| 3 | NO OK: **no se crea la DI** | **18** Villa Country | 10 | `Prueba-3-NoOK-SinDI_L18T10.xlsx` | 1810091001 (2.000.000), 1810091002 (670.000) | 2.670.000 | **2.675.000** | −5.000 | `FUERA_RANGO`, sin DI; Dif. Real −5.000; Pendiente |
| 4 | **Caso normal** (cuadre) | **19** Buenavista | 5 | `Prueba-4-Normal-Cuadre_L19T5.xlsx` | 1905091001 (2.000.000), 1905091002 (342.000) | 2.342.000 | **2.342.000** | 0 | `DR_CERO`, sin DI; Dif. Real 0; Pendiente |

- Cada caja lleva 2 sobres porque `Form133` en FACO exige al menos 2 filas.
- Número de sobre: `<local><terminal en 2 dígitos>0910<n>`.
- El local 13 no sirve: tiene terminales en `vta_FACOterminales`, pero no existe en `vta_FACOlocales`.

`Prueba-DI_Resumen.xlsx` tiene tres hojas:
- **Resumen**: un bloque por prueba, con el local y la terminal, lo que hay que digitar y lo esperado;
- **Pasos**: el paso a paso;
- **Sobres**: los 8 sobres.

## Orden

1. **`P0_prechecks.sql`** (solo lectura). Revisa:
   - que el paquete esté `VALID` (el `PACKAGE` del dueño `INTRANETTS`; el sinónimo de `UINTRANETTS` puede figurar `INVALID` tras reinstalar el paquete, y Oracle lo revalida en el primer uso) y los parámetros 1502;
   - que `PKG_F8_CIERRE_AUTO` ya no exista;
   - que los 4 locales estén vigentes y que las 4 cajas sean de `ter_tipo = 0` y no tengan Y, Z cerrada ni sobres ese día.
   
   Si una caja no sirve, la consulta 9 lista las terminales libres de los 4 locales y se regenera ese Excel.
2. Por cada prueba, de a una y siempre **primero la Y y después la carga**:
   1. F8 con el **local de la prueba**, fecha 10-09-2026 y la terminal (dejarla abierta). **Antes de cada prueba hay que cambiar el local en la F8**: `Form19Y` graba la Y en el local de la F8 abierta. Si queda el local de la prueba anterior, la Y se graba ahí y la carga responde `SIN_TERMSTAT`, como pasó en la prueba 2 el 20-10;
   2. `Form19Y` con N° de Y 0, que pasa a 1 al validar. EFECTIVO y BOLETAS según la tabla; todo lo demás en 0;
   3. `Form133` (Carga Manual de Sobres): cargar el Excel de la prueba. Sale "Se Cargaron 2 Registros" y después **"Compensacion automatica de DI"**, con la línea `Local L Terminal N Y 1: RESULTADO por MONTO`.
3. **`P2_resultados.sql`** (solo lectura): log, estado de las Y (abiertas) con su DR actual, DI y observación. Las consultas filtran por los pares (local, terminal) de la prueba.
4. En pantalla:
   - `Form3Y`: doble clic en la Y 1 y comparar Dif. de Caja, Compensación, Dif. Real y Estado (**Pendiente**);
   - `Form4`: en las pruebas 1 y 2, la fila "Diferencia no Imputable" con el monto en Compensado y la observación automática.
5. Para repetir: **`P9_limpiar.sql`** (modifica datos y no hace commit solo).

**Cron de cierre diario:** en test ya están la especificación de `PKG_F8_CIERRE_DIARIO` y los parámetros `CD_*` (`CD_ACTIVO = S`); al 20-10 falta su body (pendiente 1q). Cuando esté instalado, si se ejecuta `prc_cierre_diario('FACO', 10-09-2026)` durante la prueba, puede cerrar las Y 1, 2 y 4 (Dif. Real 0) y cambiar el estado esperado. No ejecutarlo sobre esa fecha hasta revisar P2 y las pantallas.

## Cierre de las Y (después de las 4 pruebas)

Solo se cierran las cajas Pendientes con **Dif. Real 0**. Con los datos que quedaron el 20-10 (incluidos los errores de digitación) son 3: **5/27, 19/5 y 25/13**. No se cierran 5/12 (−860.000) ni 25/12 (+15.000).

Hay dos formas; conviene usar **una sola**, porque las cajas ya cerradas no vuelven a contarse:
- **CC, botón "Cerrar Terminal"** (`Form43`), con local `0-TODOS` (FACO, perfiles 9 y 10):
  - pregunta "Se cerraran 3 caja(s) con Dif. Real 0 de 3 local(es)… ¿Desea continuar?", con **No** marcado por defecto;
  - si se responde **No**, no cierra nada;
  - con un local específico no pregunta y cierra directamente;
  - cada caja pasa por `CierraTerminalYYY`, que puede rechazarla con un mensaje (cheques, conceptos).
- **Botón Salir de `Form174`** (Ingreso masivo de Y; cambio temporal mientras no se programe nhal1):
  - no pregunta; ejecuta `PKG_F8_CIERRE_DIARIO.prc_cierre_diario('FACO', 10-09-2026)` sobre **todos los locales de esa fecha**;
  - desde el 20-10 la fecha fija es `vFechaPrueba = "20260910"` (antes 31-08-2026; respaldo `FTEPROD/Form174.frm.bak_FSCC-12901_CD_1009`); **hay que recompilar**;
  - resultado esperado: "Cajas cerradas: 3", "Cajas no cerradas: 2" (`CON_DIFERENCIA` en 5/12 y 25/12); detalle en `VTA_FACOLOG_CIERRE_DIARIO`.

## Archivos

| Archivo | Qué es |
|---|---|
| `Prueba-1..4-*_L<local>T<terminal>.xlsx` | Excel de carga para `Form133`, copia de los de `../prueba_test/` con local, terminal, sobres y fecha cambiados |
| `Prueba-DI_Resumen.xlsx` | Resumen por bloques, pasos y sobres |
| `P0_prechecks.sql` | Verificaciones previas (solo lectura) |
| `P2_resultados.sql` | Resultados (solo lectura) |
| `P9_limpiar.sql` | Deshacer la prueba (modifica datos, sin commit) |
| `P9b_rehacer_prueba2.sql` | Deshace solo el intento fallido de la prueba 2 del 20-10: la Y grabada en local 5 / T12, los sobres y el log de 25 / T12 (modifica datos, sin commit) |

## Si algo falla

- **No aparece el mensaje de compensación:** el exe no tiene el `Form133` nuevo, o la carga insertó 0 sobres ("Ya existen los registros").
- **`ERROR ADO`:** faltan permisos o sinónimos para el usuario de la aplicación (`../06_grants_sinonimos.sql`).
- **`SIN_TERMSTAT` o `SIN_LIBVTA`:** la Y no se ingresó antes de la carga, o se ingresó en otro local porque la F8 seguía con el local de la prueba anterior. Para encontrarla, consultar `vta_FACOtermstaty` del 10-09-2026 sin filtro de local. Hay que borrar esa Y y los sobres (si los sobres quedan, `Form133` inserta 0 registros y no llama al paquete) y repetir. Para la prueba 2 del 20-10 ya existe `P9b_rehacer_prueba2.sql`; para otro caso, adaptarlo.
- **`INACTIVO`:** el parámetro 1502 `CA_DI_ACTIVO` no está en S.
- **El local no aparece en la F8:** el usuario de prueba no tiene acceso a ese local (perfil de tesorería local). Usar un perfil con todos los locales (9 o 10) o cambiar de local con la consulta 9 de P0.
- **Recarga** (otra carga sobre una caja que ya tiene DI automática): no está en esta sesión. Escenario G de `../07_pruebas.sql`.
