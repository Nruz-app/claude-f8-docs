# FSCC-12901 COMPENSA_DI: sesión de prueba 4 en test

Réplica de `../prueba_test3/` (17-09-2026, la demostración al usuario de negocio, que a su vez replica `../prueba_test2/`) en otra fecha, el **20-08-2026**. Se generó el 22-10-2026. Son los mismos 4 escenarios, locales, terminales y montos; solo cambian la fecha y los números de sobre.

Modelo del 19-10-2026: la carga de sobres (`Form133`) **no cierra la Y**. Por cada caja cargada:
- si la diferencia real (DR = sobres − efectivo de la Y) está entre **−1.000 y +20.000** (límites incluidos) y no es 0, registra una **DI automática** por el valor exacto y con el mismo signo;
- la DI lleva la observación `COMPENSACION AUTOMATICA DI`;
- la caja queda **Pendiente**.

Después, el cierre diario (`PKG_F8_CIERRE_DIARIO`, que en producción llamará nhal1) cierra las Y con Dif. Real 0.

Requisitos:
- en test, `PKG_F8_COMPENSA_DI_CARGA` y `PKG_F8_CIERRE_DIARIO` instalados y funcionando (los dos se usaron el 20-10);
- el exe compilado con `FTEPROD/Form133.frm` (`EjecutaCompensaDIFACO`) y con `FTEPROD/Form174.frm` con `vFechaPrueba = "20260820"`. La fecha se cambió el 22-10 (antes 15-10-2026, la prueba de FCDVT-56): **hay que recompilar**.

## Datos (fecha 20-08-2026, Y 1)

**El 20-08-2026 no está verificado como fecha limpia**: esta carpeta se armó sin acceso a la base. En test hay datos FACO de agosto al menos el 28-08 y el 31-08 (local 6), y en septiembre los días 04, 07, 08, 10, 15, 17, 23 y 29. Antes de empezar hay que correr **`P0_prechecks.sql`**: las consultas 3 a 8 deben dar sin filas para las 4 cajas. Si una caja no sirve, la consulta 9 lista las terminales libres de los 4 locales ese día; en ese caso cambiar la terminal en el Excel, el resumen y los scripts.

| # | Escenario | Local | Terminal | Archivo | Sobres | Total sobres | EFECTIVO = BOLETAS en Form19Y | DR | Esperado |
|---|---|---|---|---|---|---|---|---|---|
| 1 | OK: **DI negativa** | **5** Unicentro Cali | 27 | `Prueba-1-OK-DINegativa_L5T27.xlsx` | 527082001 (2.000.000), 527082002 (670.000) | 2.670.000 | **2.670.800** | −800 | `DI_REGISTRADA` −800; Dif. Real 0; Pendiente |
| 2 | OK: **DI positiva** | **25** Fontanar Chía | 12 | `Prueba-2-OK-DIPositiva_L25T12.xlsx` | 2512082001 (500.000), 2512082002 (375.000) | 875.000 | **860.000** | +15.000 | `DI_REGISTRADA` +15.000; Dif. Real 0; Pendiente |
| 3 | NO OK: **no se crea la DI** | **18** Villa Country | 10 | `Prueba-3-NoOK-SinDI_L18T10.xlsx` | 1810082001 (2.000.000), 1810082002 (670.000) | 2.670.000 | **2.675.000** | −5.000 | `FUERA_RANGO`, sin DI; Dif. Real −5.000; Pendiente |
| 4 | **Caso normal** (cuadre) | **19** Buenavista | 5 | `Prueba-4-Normal-Cuadre_L19T5.xlsx` | 1905082001 (2.000.000), 1905082002 (342.000) | 2.342.000 | **2.342.000** | 0 | `DR_CERO`, sin DI; Dif. Real 0; Pendiente |

- Cada caja lleva 2 sobres porque `Form133` en FACO exige al menos 2 filas.
- Número de sobre: `<local><terminal en 2 dígitos>0820<n>` (en `prueba_test3`, `0917`).

`Prueba-DI_Resumen.xlsx` tiene tres hojas:
- **Resumen**: un bloque por prueba, con el local y la terminal, lo que hay que digitar y lo esperado;
- **Pasos**: el paso a paso;
- **Sobres**: los 8 sobres.

## Orden

1. **`P0_prechecks.sql`** (solo lectura). Revisa:
   - los paquetes y los parámetros 1502;
   - que los 4 locales estén vigentes y que las 4 cajas sean de `ter_tipo = 0` y no tengan Y, Z cerrada ni sobres ese día.
   
   Si una caja no sirve, la consulta 9 lista las terminales libres de los 4 locales.
2. Por cada prueba, de a una y siempre **primero la Y y después la carga**:
   1. F8 con el **local de la prueba**, fecha 20-08-2026 y la terminal (dejarla abierta). **Antes de cada prueba hay que cambiar el local en la F8**: `Form19Y` graba la Y en el local de la F8 abierta. Si queda el local de la prueba anterior, la carga responde `SIN_TERMSTAT`, como pasó en `prueba_test2` el 20-10;
   2. `Form19Y` con N° de Y 0, que pasa a 1 al validar. EFECTIVO y BOLETAS según la tabla; todo lo demás en 0;
   3. `Form133` (Carga Manual de Sobres): cargar el Excel de la prueba. Sale "Se Cargaron 2 Registros" y después **"Compensacion automatica de DI"**, con la línea `Local L Terminal N Y 1: RESULTADO por MONTO`.
3. **`P2_resultados.sql`** (solo lectura): log, estado de las Y (abiertas) con su DR actual, DI y observación.
4. En pantalla:
   - `Form3Y`: doble clic en la Y 1 y comparar Dif. de Caja, Compensación, Dif. Real y Estado (**Pendiente**);
   - `Form4`: en las pruebas 1 y 2, la fila "Diferencia no Imputable" con el monto en Compensado y la observación automática;
   - CC (`Form43`), local `0-TODOS`, del 20-08 al 20-08: las 4 cajas Pendientes; Dif. Real 0 en 5/27, 25/12 y 19/5, y −5.000 en 18/10.
5. **Cierre** (ver la sección siguiente).
6. Para repetir: **`P9_limpiar.sql`** (modifica datos y no hace commit solo).

## Cierre de las Y (después de las 4 pruebas)

Solo se cierran las cajas Pendientes con **Dif. Real 0**: **5/27, 25/12 y 19/5**. La 18/10 (−5.000, prueba 3) queda Pendiente para que la gestione la tienda.

Hay dos formas; conviene usar **una sola**, porque las cajas ya cerradas no vuelven a contarse:
- **Botón Salir de `Form174`** (Ingreso masivo de Y; simula el cron diario mientras no se programe nhal1):
  - no pregunta; ejecuta `PKG_F8_CIERRE_DIARIO.prc_cierre_diario('FACO', 20-08-2026)` sobre **todos los locales de esa fecha**;
  - resultado esperado: "Cajas cerradas: 3", "Cajas no cerradas: 1" (`CON_DIFERENCIA` en 18/10, "Falta Monto por Compensar"); detalle en `VTA_FACOLOG_CIERRE_DIARIO`;
  - **Etapa sin venta (FCDVT-56):** si en test está compilado el body nuevo de `PKG_F8_CIERRE_DIARIO` y el parámetro 1502 `CD_SIN_VENTA` está en S, el mismo Salir también cierra la **Z de los terminales sin venta de todos los locales del 20-08-2026**. Entonces "Cajas cerradas" será 3 + N, y "no cerradas" puede subir. Para obtener exactamente 3 / 1, poner antes `CD_SIN_VENTA = N`. Si no, mirar la fila `FIN` del log: la parte de las Y debe decir "cerradas: 3 | con diferencia: 1";
  - se presiona el botón **Salir**: cerrar la ventana con la X no ejecuta el cierre.
- **CC, botón "Cerrar Terminal"** (`Form43`), con local `0-TODOS` (FACO, perfiles 9 y 10):
  - pregunta "Se cerraran 3 caja(s) con Dif. Real 0 de 3 local(es)… ¿Desea continuar?", con **No** marcado por defecto; si se responde **No**, no cierra nada;
  - con un local específico no pregunta y cierra directamente.

Para verificar el cierre: CC con 0-TODOS (5/27, 25/12 y 19/5 `Cerrado`; 18/10 `Pendiente`) y P2 consulta 2 (`ter_estado = 1`, `ter_cerradopor = PROC_CIERRE_DIARIO` si se cerró con Salir).

## Archivos

| Archivo | Qué es |
|---|---|
| `Prueba-1..4-*_L<local>T<terminal>.xlsx` | Excel de carga para `Form133`, copia de los de `../prueba_test3/` con la fecha y los sobres cambiados |
| `Prueba-DI_Resumen.xlsx` | Resumen por bloques, pasos y sobres |
| `P0_prechecks.sql` | Verificaciones previas (solo lectura) |
| `P2_resultados.sql` | Resultados (solo lectura) |
| `P9_limpiar.sql` | Deshacer la prueba (modifica datos, sin commit) |

## Si algo falla

- **No aparece el mensaje de compensación:** el exe no tiene el `Form133` nuevo, o la carga insertó 0 sobres ("Ya existen los registros").
- **`SIN_TERMSTAT` o `SIN_LIBVTA`:** la Y no se ingresó antes de la carga, o se ingresó en otro local. Consultar `vta_FACOtermstaty` del 20-08-2026 sin filtro de local; borrar esa Y y los sobres (si los sobres quedan, `Form133` inserta 0 registros y no llama al paquete) y repetir. Para hacerlo, adaptar `../prueba_test2/P9b_rehacer_prueba2.sql`.
- **Salir no cierra nada y no aparece el mensaje "Cierre diario FACO del 20-08-2026":** el exe no tiene el `Form174` nuevo (en el IDE, volver a abrir el proyecto para que relea el archivo) o se cerró con la X.
- **`ERROR ADO`:** faltan permisos o sinónimos para el usuario de la aplicación (`../06_grants_sinonimos.sql`).
- **`INACTIVO`:** el parámetro 1502 `CA_DI_ACTIVO` (o `CD_ACTIVO`, para el cierre) no está en S.
- **El local no aparece en la F8:** el usuario de prueba no tiene acceso a ese local. Usar un perfil con todos los locales (9 o 10).
