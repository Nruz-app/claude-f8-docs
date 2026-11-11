# FCDVT-14 + FSCC-12901: sesión de prueba 2 — crear Y con la carga masiva y compensar con DI (test)

Armada el 06-11-2026. **Réplica de `../prueba_carga_y_compensa_di/`** (la sesión del 29-10-2026, que encadena los dos requerimientos) **en otra fecha, el 28-10-2026** (fecha libre: ninguna sesión la usa; la sesión 1 usa el 29-10 y los scripts de ambas filtran por fecha, así que no se pisan). Mismos 4 escenarios, cajas, horas y montos; solo cambian la fecha y los números de sobre.

La Y se crea con la **carga masiva** (Form174, FCDVT-14) y después se **compensa con la DI automática** (Form133, FSCC-12901). Son dos pasos por caja y siempre en este orden: **primero la Y (Form174) y después los sobres (Form133)**.

Modelo del 19-10-2026: la carga de sobres **no cierra la Y**. Por cada caja cargada:
- si la diferencia real (DR = sobres − efectivo de la Y) está entre **−1.000 y +20.000** (límites incluidos) y no es 0, registra una **DI automática** por el valor exacto y con el mismo signo;
- la DI lleva la observación `COMPENSACION AUTOMATICA DI`;
- la caja queda **Pendiente** (el cierre diario `PKG_F8_CIERRE_DIARIO`, o el cierre con CC, cierra las de Dif. Real 0).

Y el modelo de FCDVT-14: **Cargar** (`PKG_F8_GRABA_MASIVA_YZ`) graba la Z (libvta `F8`/99 + zzz + termstat −1 si falta) y la Y (libvta `Y`/1 + zzz + **termstaty −1** con glosa `CARGA MASIVA DE CIERRE Y - CARGA <n>`), con cada campo en su columna. Tampoco cierra nada: la Y queda en estado −1, apta para que Form133 la evalúe. **OJO: Cargar REEMPLAZA** la Z y las Y de cada terminal-día, por eso el día tiene que estar limpio (py0).

## Requisitos (iguales a la sesión 1)

- en test, `PKG_F8_CARGA_MASIVA_YZ`, `PKG_F8_GRABA_MASIVA_YZ` y `PKG_F8_COMPENSA_DI_CARGA` instalados y funcionando (los tres se validan en py0);
- permiso 460 (`Ingreso de cierre de terminal Y masivo`) para el perfil del usuario de prueba, y el exe compilado con los cambios del exe de la sesión 1: no hay que recompilar nada para esta fecha;
- **`Form174` no se cambió para esta fecha**: el botón Salir sigue con `vFechaPrueba = "20261102"` (sesiones 7 a 10 de FSCC-12901). Por eso **el cierre se hace con CC** ("Cerrar Terminal", ver la sección de cierre) y **no hay que presionar Salir durante la prueba** (actuaría sobre las sesiones 7 a 10). Para cerrar el 28-10 con Salir habría que cambiar `vFechaPrueba` a `"20261028"` en `FTEPROD/Form174.frm` (con respaldo `.bak`) y recompilar, como siempre.

## Datos (fecha 28-10-2026, Y 1, local 5)

**Ojo: no se verificó en test.** Esta carpeta se armó sin acceso a la base. Antes de empezar hay que correr **`py0_prechecks.sql`**: las consultas 4 a 9 deben dar sin filas para las 4 cajas, y la 8 debe mostrar las terminales 1 a 4 vigentes y de tipo 0. Si una caja no sirve, la consulta final lista las terminales libres del local 5; en ese caso cambiarla en el CSV, los 2 Excel de la prueba, el resumen y los scripts (igual que en la sesión 1).

| # | Escenario | Terminal | Archivo de sobres | Sobres | Total sobres | EFECTIVO = BOLETAS de la Y (CSV) | DR | Esperado |
|---|---|---|---|---|---|---|---|---|
| 1 | OK: **DI negativa** | **1** | `Prueba-1-OK-DINegativa_L5T1.xlsx` | 501102801 (2.000.000), 501102802 (670.000) | 2.670.000 | **2.670.800** | −800 | `DI_REGISTRADA` −800; Dif. Real 0; Pendiente |
| 2 | OK: **DI positiva** | **2** | `Prueba-2-OK-DIPositiva_L5T2.xlsx` | 502102801 (500.000), 502102802 (375.000) | 875.000 | **860.000** | +15.000 | `DI_REGISTRADA` +15.000; Dif. Real 0; Pendiente |
| 3 | NO OK: **no se crea la DI** | **3** | `Prueba-3-NoOK-SinDI_L5T3.xlsx` | 503102801 (2.000.000), 503102802 (670.000) | 2.670.000 | **2.675.000** | −5.000 | `FUERA_RANGO`, sin DI; Dif. Real −5.000; Pendiente |
| 4 | **Caso normal** (cuadre) | **4** | `Prueba-4-Normal-Cuadre_L5T4.xlsx` | 504102801 (2.000.000), 504102802 (342.000) | 2.342.000 | **2.342.000** | 0 | `DR_CERO`, sin DI; Dif. Real 0; Pendiente |

- El EFECTIVO objetivo de cada Y lo trae el **CSV de carga masiva**: una fila Y con `NRO_Y` 1 (`VTA_MONTOBOL` = `REC_MEFECTIVO` = monto de la tabla) y una fila Z = ΣY para pasar la cuadratura de FCDVT-14. Cargar debe responder por grupo `GRABADO: Z + 1 Y (numeros 1 a 1)`.
- Cada caja lleva 2 sobres porque `Form133` en FACO exige al menos 2 filas.
- Número de sobre: `<local><terminal en 2 dígitos>1028<n>` (mes y día; en la sesión 1, `1029`; en `prueba_test9`, `1103`).

`Prueba-Y-DI_Resumen.xlsx` (mismo diseño de `../../FSCC-12901_COMPENSA_DI/prueba_test9/Prueba-DI_Resumen.xlsx`) tiene tres hojas:
- **Resumen**: un bloque por prueba, con el local y la terminal, lo que crea la Y (el CSV), lo que hay que cargar y lo esperado;
- **Pasos**: el paso a paso;
- **Sobres**: los 8 sobres.

## Orden

1. **`py0_prechecks.sql`** (solo lectura). Revisa:
   - los tres paquetes y sus tablas de carga masiva (VALID), el permiso 460 y los parámetros 1502;
   - que las 4 cajas no tengan cargas previas del día, Y, Z cerrada ni sobres el 28-10-2026, y que los 8 sobres no estén cargados.
2. **Carga masiva (una vez, para las 4 pruebas)**: F8 con el **local 5**, fecha 28-10-2026 (dejarla abierta) ▸ botón Y ▸ "Ingreso del YYY Masivo" (`Form174`) ▸ **Buscar** con `carga_Y_compensa.csv` ▸ revisar la grilla (4 grupos `CARGADO`: 2.670.800, 860.000, 2.675.000 y 2.342.000) ▸ **Cargar** ▸ anotar el **número de carga**: el mensaje de cada grupo es `Grabado: Z + 1 Y (numeros 1 a 1)`. Ver también `Form175` y `../06_pruebas.sql` (consultas 6 a 9, fecha 28-10-2026 local 5).
3. Por cada prueba, de a una:
   1. F8 con el local 5, fecha 28-10-2026 (dejarla abierta: Form133 valida con esta pantalla);
   2. `Form133` (Carga Manual de Sobres): Recaudador + el Excel de la prueba. Sale "Se Cargaron 2 Registros" y después **"Compensacion automatica de DI"**, con la línea `Local 5 Terminal N Y 1: RESULTADO por MONTO`.
4. **`py2_resultados.sql`** (solo lectura): parte A, la carga masiva; parte B, log de la DI, estado de las Y (abiertas) con su DR actual, DI, observación y sobres.
5. En pantalla:
   - `Form3Y`: doble clic en la Y 1 y comparar Dif. de Caja, Compensación, Dif. Real y Estado (**Pendiente**);
   - `Form4`: en las pruebas 1 y 2, la fila "Diferencia no Imputable" con el monto en Compensado y la observación automática;
   - CC (`Form43`), fecha del 28-10 al 28-10: las 4 cajas Pendientes; Dif. Real 0 en T1, T2 y T4, y −5.000 en T3.
6. **Cierre** (ver la sección siguiente).
7. Para repetir: **`py9_limpiar.sql`** (modifica datos y no hace commit solo).

## Cierre de las Y (después de las 4 pruebas)

Solo se cierran las cajas Pendientes con **Dif. Real 0**: **5/1, 5/2 y 5/4**. La 5/3 (−5.000, prueba 3) queda Pendiente para que la gestione la tienda.

**Con CC, botón "Cerrar Terminal"** (`Form43`), fecha del 28-10 al 28-10:
- con local `0-TODOS` (FACO, perfiles 9 y 10) pregunta "¿Desea continuar?" con **No** marcado por defecto; si se responde No, no cierra nada. Si el 28-10-2026 tiene otras Y Pendientes con Dif. Real 0 (carga real del día), el número será mayor y también se cerrarán: en ese caso conviene cerrar eligiendo el local 5;
- con el local 5 no pregunta y cierra directamente.

**El botón Salir de `Form174` no sirve para esta sesión** (y no hay que presionarlo en ningún momento de la carga): cierra el 02-11-2026 (fecha fija `vFechaPrueba`), no el 28-10-2026.

Para verificar el cierre: CC (5/1, 5/2 y 5/4 `Cerrado`; 5/3 `Pendiente`) y py2 consulta B2 (`ter_estado = 1` en las tres; la 5/3 sigue abierta).

## Archivos

| Archivo | Qué es |
|---|---|
| `carga_Y_compensa.csv` | CSV de carga masiva (56 columnas, `;`, CRLF, ANSI) con la Z y la Y 1 de las 4 cajas del 28-10-2026: T1 2.670.800, T2 860.000, T3 2.675.000 y T4 2.342.000. Copia de `../prueba_carga_y_compensa_di/` con la fecha cambiada |
| `Prueba-1..4-*_L5T<n>.xlsx` | Excel de sobres para `Form133`, con la fecha y los sobres cambiados (formato de `../../FSCC-12901_COMPENSA_DI/prueba_test9/`) |
| `Prueba-Y-DI_Resumen.xlsx` | Resumen por bloques, pasos y sobres |
| `py0_prechecks.sql` | Verificaciones previas de los dos requerimientos (solo lectura) |
| `py2_resultados.sql` | Resultados de la carga masiva y de la DI (solo lectura) |
| `py9_limpiar.sql` | Deshacer la prueba (modifica datos, sin commit) |

## Si algo falla

Igual que en la sesión 1 (ver `../prueba_carga_y_compensa_di/LEEME.md`), con la fecha cambiada:

- **No aparece la carga masiva en el botón Y:** falta el permiso 460 para el perfil (py0 consulta 3) o el exe no tiene la rama 460 de `MDIForm1`.
- **`Buscar`/`Cargar` da error de Oracle:** falta instalar `PKG_F8_CARGA_MASIVA_YZ` o `PKG_F8_GRABA_MASIVA_YZ`; correr `../INSTALAR.sql`.
- **Grupo en `ERROR` por cuadratura o montos:** releer el CSV (56 columnas, `;`, montos enteros); el motivo está en la grilla y en `VTA_FACOCARGA_YZ_LOG`.
- **`Cargar` ERROR "tiene cierre(s) Y cerrado(s)" o "no se reemplaza":** alguna Y o Z del día está cerrada; py0 consultas 5 y 6 lo muestran antes.
- **No aparece el mensaje de compensación:** el exe no tiene el `Form133` con `EjecutaCompensaDIFACO`, o la carga insertó 0 sobres ("Ya existen los registros": py0 consultas 7).
- **`SIN_TERMSTAT` o `SIN_LIBVTA`:** la Y no se creó antes de los sobres (paso 2), la carga masiva dio `ERROR` para esa terminal, o la F8 estaba con otra fecha/local. Revisar la carga en `Form175` y repetir.
- **`ERROR ADO`:** faltan permisos o sinónimos para el usuario de la aplicación (`../05_grants_sinonimos.sql` y `../../FSCC-12901_COMPENSA_DI/06_grants_sinonimos.sql`).
- **`INACTIVO`:** el parámetro 1502 `CA_DI_ACTIVO` (o `CD_ACTIVO`, para el cierre) no está en S (py0 consulta 2).
- **La F8/CC no muestran las cajas:** el usuario de prueba no tiene acceso al local 5, o el perfil no tiene el permiso 15 (ingreso de Y). Usar un perfil con todos los locales (9 o 10).
- **Se presionó Salir por error:** cierra las Y del 02-11-2026 (sesiones 7 y 8). Verlos con la P2/P0 de esas sesiones; esta sesión no se ve afectada (los scripts filtran por la fecha 28-10).
