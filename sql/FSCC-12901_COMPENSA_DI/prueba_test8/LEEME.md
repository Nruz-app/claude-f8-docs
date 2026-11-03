# FSCC-12901 COMPENSA_DI: sesión de prueba 8 en test

Réplica de `../prueba_test7/` en la **misma fecha, el 02-11-2026**, con **otras cajas** (local o terminal distinto), para poder correrla además de la 7 o en su lugar. Se generó el 03-11-2026. Son los mismos 4 escenarios y montos; cambian las cajas y los números de sobre.

| # | Caja en `prueba_test7` | Caja en `prueba_test8` |
|---|---|---|
| 1 | local 5 / T27 | **local 5 / T3** |
| 2 | local 25 / T12 | **local 25 / T40** |
| 3 | local 18 / T10 | **local 18 / T31** |
| 4 | local 19 / T5 | **local 6 / T24** (Parque Arboleda) |

Las terminales se eligieron entre las ya vistas en test como vigentes y de tipo 0: local 5 T1 a T3 (FCDVT-14), locales 6, 18 y 25 con T24, T29, T31 y T40 (`../prueba_test_6locales/`, verificado el 20-10). Del local 19 solo se conocía la T5 (ya usada en la 7), por eso la prueba 4 pasa al local 6.

Modelo del 19-10-2026: la carga de sobres (`Form133`) **no cierra la Y**. Por cada caja cargada:
- si la diferencia real (DR = sobres − efectivo de la Y) está entre **−1.000 y +20.000** (límites incluidos) y no es 0, registra una **DI automática** por el valor exacto y con el mismo signo;
- la DI lleva la observación `COMPENSACION AUTOMATICA DI`;
- la caja queda **Pendiente**.

Después, el cierre diario (`PKG_F8_CIERRE_DIARIO`, que en producción llamará nhal1) cierra las Y con Dif. Real 0.

Requisitos:
- en test, `PKG_F8_COMPENSA_DI_CARGA` y `PKG_F8_CIERRE_DIARIO` instalados y funcionando;
- el exe compilado con `FTEPROD/Form133.frm` (`EjecutaCompensaDIFACO`) y con `FTEPROD/Form174.frm` con `vFechaPrueba = "20261102"`. Es la misma fecha de `prueba_test7`: si ya se compiló para la 7, **no hay que recompilar**.

## Datos (fecha 02-11-2026, Y 1)

**Ojo: no se verificó en test.** Esta carpeta se armó sin acceso a la base (sin VPN) y el clon `docs/ddl/` solo tiene la estructura, no datos: no se sabe si las 4 cajas existen y están libres el 02-11-2026 (fecha reciente; puede haber carga real o haber corrido el cron). Antes de empezar hay que correr **`P0_prechecks.sql`**: la consulta 6 debe dar 4 filas y las consultas 3 a 5b, 7 y 8, sin filas para las 4 cajas. Si una caja no sirve, la consulta 9 lista las terminales libres de los locales 5, 25, 18 y 6 ese día; en ese caso cambiar la terminal en el Excel, el resumen y los scripts.

| # | Escenario | Local | Terminal | Archivo | Sobres | Total sobres | EFECTIVO = BOLETAS en Form19Y | DR | Esperado |
|---|---|---|---|---|---|---|---|---|---|
| 1 | OK: **DI negativa** | **5** Unicentro Cali | 3 | `Prueba-1-OK-DINegativa_L5T3.xlsx` | 503110201 (2.000.000), 503110202 (670.000) | 2.670.000 | **2.670.800** | −800 | `DI_REGISTRADA` −800; Dif. Real 0; Pendiente |
| 2 | OK: **DI positiva** | **25** Fontanar Chía | 40 | `Prueba-2-OK-DIPositiva_L25T40.xlsx` | 2540110201 (500.000), 2540110202 (375.000) | 875.000 | **860.000** | +15.000 | `DI_REGISTRADA` +15.000; Dif. Real 0; Pendiente |
| 3 | NO OK: **no se crea la DI** | **18** Villa Country | 31 | `Prueba-3-NoOK-SinDI_L18T31.xlsx` | 1831110201 (2.000.000), 1831110202 (670.000) | 2.670.000 | **2.675.000** | −5.000 | `FUERA_RANGO`, sin DI; Dif. Real −5.000; Pendiente |
| 4 | **Caso normal** (cuadre) | **6** Parque Arboleda | 24 | `Prueba-4-Normal-Cuadre_L6T24.xlsx` | 624110201 (2.000.000), 624110202 (342.000) | 2.342.000 | **2.342.000** | 0 | `DR_CERO`, sin DI; Dif. Real 0; Pendiente |

- Cada caja lleva 2 sobres porque `Form133` en FACO exige al menos 2 filas.
- Número de sobre: `<local><terminal en 2 dígitos>1102<n>`, igual que en `prueba_test7`; como cambian las cajas, los sobres no se repiten con los de la 7.

`Prueba-DI_Resumen.xlsx` tiene tres hojas:
- **Resumen**: un bloque por prueba, con el local y la terminal, lo que hay que digitar y lo esperado;
- **Pasos**: el paso a paso;
- **Sobres**: los 8 sobres.

## Convivencia con `prueba_test7` (misma fecha)

Las dos sesiones usan el 02-11-2026, así que lo que trabaja "por fecha" ve las dos:
- **Salir de `Form174`** cierra las Y Pendientes con Dif. Real 0 de **todos** los locales del día. Si las dos sesiones están cargadas, el resultado será "Cajas cerradas: 6", "no cerradas: 2" (18/10 y 18/31), más cualquier otra Y del día y los sin venta (ver abajo).
- **CC con `0-TODOS`** muestra y cierra las cajas de las dos sesiones (los locales 5, 25 y 18 son los mismos).
- Los scripts P0, P2 y P9 de cada carpeta filtran por sus cajas, así que no se pisan: `P9_limpiar.sql` de esta carpeta **no** borra lo de la 7, ni al revés.

Para ver solo la sesión 8: cerrar en CC eligiendo cada local (5, 25 y 6) o revisar en `VTA_FACOLOG_CIERRE_DIARIO` solo las filas de 5/3, 25/40, 18/31 y 6/24. Ojo: en CC por local se ven también las cajas de la 7 del mismo local (5 y 25).

## Orden

1. **`P0_prechecks.sql`** (solo lectura). Revisa:
   - los paquetes y los parámetros 1502;
   - que los 4 locales estén vigentes y que las 4 cajas sean de `ter_tipo = 0` y no tengan Y, Z cerrada ni sobres ese día.
   
   Si una caja no sirve, la consulta 9 lista las terminales libres de los 4 locales.
2. Por cada prueba, de a una y siempre **primero la Y y después la carga**:
   1. F8 con el **local de la prueba**, fecha 02-11-2026 y la terminal (dejarla abierta). **Antes de cada prueba hay que cambiar el local en la F8**: `Form19Y` graba la Y en el local de la F8 abierta. Si queda el local de la prueba anterior, la carga responde `SIN_TERMSTAT`, como pasó en `prueba_test2` el 20-10;
   2. `Form19Y` con N° de Y 0, que pasa a 1 al validar. EFECTIVO y BOLETAS según la tabla; todo lo demás en 0;
   3. `Form133` (Carga Manual de Sobres): cargar el Excel de la prueba. Sale "Se Cargaron 2 Registros" y después **"Compensacion automatica de DI"**, con la línea `Local L Terminal N Y 1: RESULTADO por MONTO`.
3. **`P2_resultados.sql`** (solo lectura): log, estado de las Y (abiertas) con su DR actual, DI y observación.
4. En pantalla:
   - `Form3Y`: doble clic en la Y 1 y comparar Dif. de Caja, Compensación, Dif. Real y Estado (**Pendiente**);
   - `Form4`: en las pruebas 1 y 2, la fila "Diferencia no Imputable" con el monto en Compensado y la observación automática;
   - CC (`Form43`), local `0-TODOS`, del 02-11 al 02-11: las 4 cajas Pendientes; Dif. Real 0 en 5/3, 25/40 y 6/24, y −5.000 en 18/31 (más las de la 7 si también se cargó).
5. **Cierre** (ver la sección siguiente).
6. Para repetir: **`P9_limpiar.sql`** (modifica datos y no hace commit solo).

## Cierre de las Y (después de las 4 pruebas)

Solo se cierran las cajas Pendientes con **Dif. Real 0**: **5/3, 25/40 y 6/24**. La 18/31 (−5.000, prueba 3) queda Pendiente para que la gestione la tienda.

Hay dos formas; conviene usar **una sola**, porque las cajas ya cerradas no vuelven a contarse:
- **Botón Salir de `Form174`** (Ingreso masivo de Y; simula el cron diario mientras no se programe nhal1):
  - no pregunta; ejecuta `PKG_F8_CIERRE_DIARIO.prc_cierre_diario('FACO', 02-11-2026)` sobre **todos los locales de esa fecha**;
  - resultado esperado solo con esta sesión: "Cajas cerradas: 3", "Cajas no cerradas: 1" (`CON_DIFERENCIA` en 18/31, "Falta Monto por Compensar"); con la 7 también cargada, 6 / 2 (ver "Convivencia"). Detalle en `VTA_FACOLOG_CIERRE_DIARIO`;
  - si hay otras Y Pendientes del 02-11-2026 (en cualquier local) también se cuentan. Si no se quiere tocar otras cajas, cerrar con CC eligiendo cada local (5, 25 y 6);
  - **Etapa sin venta (FCDVT-56):** si en test está compilado el body nuevo de `PKG_F8_CIERRE_DIARIO` y el parámetro 1502 `CD_SIN_VENTA` está en S, el mismo Salir también cierra la **Z de los terminales sin venta de todos los locales del 02-11-2026**. Entonces "Cajas cerradas" será mayor. Para no contarlos, poner antes `CD_SIN_VENTA = N`; si no, mirar la fila `FIN` del log (parte de las Y);
  - se presiona el botón **Salir**: cerrar la ventana con la X no ejecuta el cierre.
- **CC, botón "Cerrar Terminal"** (`Form43`), con local `0-TODOS` (FACO, perfiles 9 y 10):
  - pregunta "Se cerraran N caja(s) con Dif. Real 0 de M local(es)… ¿Desea continuar?", con **No** marcado por defecto; si se responde **No**, no cierra nada. Solo con esta sesión, N = 3 y M = 3;
  - con un local específico no pregunta y cierra directamente.

Para verificar el cierre: CC con 0-TODOS (5/3, 25/40 y 6/24 `Cerrado`; 18/31 `Pendiente`) y P2 consulta 2 (`ter_estado = 1`, `ter_cerradopor = PROC_CIERRE_DIARIO` si se cerró con Salir).

## Archivos

| Archivo | Qué es |
|---|---|
| `Prueba-1..4-*_L<local>T<terminal>.xlsx` | Excel de carga para `Form133`, copia de los de `../prueba_test7/` con local, terminal y sobres cambiados |
| `Prueba-DI_Resumen.xlsx` | Resumen por bloques, pasos y sobres |
| `P0_prechecks.sql` | Verificaciones previas (solo lectura) |
| `P2_resultados.sql` | Resultados (solo lectura) |
| `P9_limpiar.sql` | Deshacer la prueba (modifica datos, sin commit; solo las 4 cajas de esta carpeta) |

## Si algo falla

- **No aparece el mensaje de compensación:** el exe no tiene el `Form133` nuevo, o la carga insertó 0 sobres ("Ya existen los registros").
- **`SIN_TERMSTAT` o `SIN_LIBVTA`:** la Y no se ingresó antes de la carga, o se ingresó en otro local. Consultar `vta_FACOtermstaty` del 02-11-2026 sin filtro de local; borrar esa Y y los sobres (si los sobres quedan, `Form133` inserta 0 registros y no llama al paquete) y repetir. Para hacerlo, adaptar `../prueba_test2/P9b_rehacer_prueba2.sql`.
- **La terminal no aparece en la F8 o `Form19Y` la rechaza:** no existe o está dada de baja en ese local; usar la consulta 9 de P0 y cambiar la terminal en el Excel, el resumen y los scripts.
- **Salir no cierra nada y no aparece el mensaje "Cierre diario FACO del 02-11-2026":** el exe no tiene el `Form174` nuevo (en el IDE, volver a abrir el proyecto para que relea el archivo) o se cerró con la X.
- **`ERROR ADO`:** faltan permisos o sinónimos para el usuario de la aplicación (`../06_grants_sinonimos.sql`).
- **`INACTIVO`:** el parámetro 1502 `CA_DI_ACTIVO` (o `CD_ACTIVO`, para el cierre) no está en S.
- **El local no aparece en la F8:** el usuario de prueba no tiene acceso a ese local. Usar un perfil con todos los locales (9 o 10).
