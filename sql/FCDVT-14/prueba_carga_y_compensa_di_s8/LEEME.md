# FCDVT-14 + FSCC-12901: sesión de prueba 8 — carga masiva de Y, DI y **recarga v1/v2 del mismo terminal-día** (test)

Armada el 13-11-2026 sobre la fecha de venta **12-11-2026**, que está libre: ninguna otra sesión la usa (la 1 usa el 29-10, la 2 el 28-10, la 3 el 06-11, la 4 el 05-11, la 5 el 09-11, la 6 el 10-11 y la 7 el 11-11; la de FSCC-12901 llega hasta el 04-11). Los scripts de todas las sesiones filtran por fecha, así que no se pisan. Es una **réplica exacta de `../prueba_carga_y_compensa_di_s7/`** (mismas 6 pruebas, cajas, horas, montos y resultados esperados; solo cambian la fecha y los números de sobre):

- **Pruebas 1 a 4**: los mismos escenarios, cajas, horas y montos de las sesiones 1 a 7. Solo cambian la fecha y los números de sobre.
- **Pruebas 5 y 6 (las de la sesión 7)**: se cargan **dos archivos** en Form174 con la misma fecha, local y terminal y **otro monto que también cuadra** (Z = ΣY). El primero es `carga_Y_compensa_v1.csv` y el segundo `carga_Y_compensa_v2.csv`. La pregunta es **qué monto queda al final**. La 5 hace la recarga antes de cargar los sobres y la 6 después.

## Respuesta esperada (según el código)

`PKG_F8_GRABA_MASIVA_YZ.pr_graba_grupo` (`../04c_pkg_f8_graba_masiva_yz_body.sql`) **reemplaza** por terminal-día:

- Borra la zzz de los techkeys, la libvta `F8`/`Y` y **todas** las termstaty del día, y vuelve a grabar lo del archivo nuevo (la Y queda en −1).
- Solo rechaza el grupo si la Z o alguna Y del día está **cerrada** (estado 1 o 2), con el mensaje "no se reemplaza".
- El mensaje del grupo agrega `. Reemplazo lo anterior: 1 Z y 1 Y`.
- **No toca** los sobres (`prd`), la DI (`movdet`) ni la observación (`compdes`).
- La termstat de la Z solo se inserta si no existe, así que conserva la glosa de la carga v1.
- Buscar no rechaza un terminal-día que ya se grabó en otra carga. Las filas de v1 en `VTA_FACOCARGA_YZ_RES` quedan en `GRABADO`, como historia.

Por lo tanto **queda el monto del último archivo (v2)** en la Z y en la Y. Lo único que no se ajusta solo es la **DI**, cuando los sobres se cargaron antes de la recarga (prueba 6): la DI calculada con v1 sigue ahí y la caja queda descuadrada.

## Modelo (igual que en las sesiones 6 y 7)

La Y se crea con la **carga masiva** (Form174, FCDVT-14) y después se **compensa con la DI automática** (Form133, FSCC-12901). La carga de sobres **no cierra la Y**. Por cada caja cargada:
- si la diferencia real (DR = sobres − efectivo de la Y) está entre **−1.000 y +20.000** (límites incluidos) y no es 0, se registra una **DI automática** por el valor exacto y con el mismo signo;
- la DI lleva la observación `COMPENSACION AUTOMATICA DI`;
- la caja queda **Pendiente**. El cierre diario o el cierre con CC cierran las que tienen Dif. Real 0.

En Form3Y, Dif. Real = Dif. de Caja − Compensación (`pr_cuadratura` de `PKG_F8_COMPENSA_DI_CARGA`).

## Requisitos (iguales a la sesión 7)

- En test, `PKG_F8_CARGA_MASIVA_YZ`, `PKG_F8_GRABA_MASIVA_YZ` y `PKG_F8_COMPENSA_DI_CARGA` instalados y funcionando (py0 valida los tres).
- Permiso 460 para el perfil del usuario de prueba. El exe ya tiene los cambios: no hay que recompilar.
- **`Form174` no se cambió**: el botón Salir sigue con `vFechaPrueba = "20261102"`. **No hay que presionar Salir** durante la prueba; el cierre se hace con CC.
- **No ejecutar el cron de cierre diario** (FSCC-12901) sobre el 12-11-2026 durante la prueba.

## Datos (fecha 12-11-2026, Y 1, local 5)

**Ojo: no se verificó en test.** Antes de empezar hay que correr **`py0_prechecks.sql`**:
- las consultas 4 a 7, 9 y 10 deben salir sin filas para las 6 cajas;
- la 8 debe mostrar las terminales 1 a 6 vigentes y de tipo 0. T5 y T6 ya se usaron en la sesión 7 (con el 11-11), sin efecto sobre esta fecha. Si alguna no sirve, la consulta 11 lista las libres; en ese caso hay que cambiarla en los 2 CSV, el Excel de la prueba, el resumen y los scripts.

| # | Escenario | T | Excel de sobres | Sobres | Total | Y v1 | Y v2 | Cuándo va v2 | Esperado al final |
|---|---|---|---|---|---|---|---|---|---|
| 1 | OK: DI negativa | 1 | `Prueba-1-OK-DINegativa_L5T1.xlsx` | 501121101 (2.000.000), 501121102 (670.000) | 2.670.000 | 2.670.800 | — | — | `DI_REGISTRADA` −800; Dif. Real 0 |
| 2 | OK: DI positiva | 2 | `Prueba-2-OK-DIPositiva_L5T2.xlsx` | 502121101 (500.000), 502121102 (375.000) | 875.000 | 860.000 | — | — | `DI_REGISTRADA` +15.000; Dif. Real 0 |
| 3 | NO OK: sin DI | 3 | `Prueba-3-NoOK-SinDI_L5T3.xlsx` | 503121101 (2.000.000), 503121102 (670.000) | 2.670.000 | 2.675.000 | — | — | `FUERA_RANGO`; Dif. Real −5.000 |
| 4 | Caso normal | 4 | `Prueba-4-Normal-Cuadre_L5T4.xlsx` | 504121101 (2.000.000), 504121102 (342.000) | 2.342.000 | 2.342.000 | — | — | `DR_CERO`; Dif. Real 0 |
| 5 | **Recarga antes de los sobres** | 5 | `Prueba-5-Recarga-v2-antes_L5T5.xlsx` | 505121101 (1.000.000), 505121102 (199.500) | 1.199.500 | 1.000.000 | **1.200.000** | v1 → v2 → sobres | Queda **1.200.000**; `DI_REGISTRADA` −500 (calculada con v2; con v1 habría sido +199.500 `FUERA_RANGO`); Dif. Real 0 |
| 6 | **Recarga después de los sobres** | 6 | `Prueba-6-Recarga-v2-despues_L5T6.xlsx` | 506121101 (1.000.000), 506121102 (500.000) | 1.500.000 | 1.500.800 | **1.490.000** | v1 → sobres → v2 | Queda **1.490.000**; la DI −800 de v1 **sigue**; Dif. de Caja +10.000, Compensación −800, **Dif. Real +10.800** |

Todas quedan **Pendientes**. En cada CSV, por caja, hay una fila Y con `NRO_Y` 1 (`VTA_MONTOBOL` = `REC_MEFECTIVO` = el monto) y una fila Z = ΣY.

En v2 también cambian los campos de identificación, para ver en la libvta que quedó v2:

| T | Archivo | Hora Y | Secuencia Y / Z | Boleta | Vendedor | Cont. reposición |
|---|---|---|---|---|---|---|
| 5 | v1 | 15:30 | 2109 / 2110 | 6105000 | 71005 | 4501 |
| 5 | v2 | 19:30 | 2209 / 2210 | 6105500 | 71005 | 4502 |
| 6 | v1 | 12:15 | 2111 / 2112 | 6106000 | 71006 | 4601 |
| 6 | v2 | 20:10 | 2211 / 2212 | 6106500 | 71006 | 4602 |

Número de sobre: `<local><terminal en 2 dígitos>1211<n>` (MMDD `1211`). Cada caja lleva 2 sobres porque `Form133` en FACO exige al menos 2 filas.

`Prueba-Y-DI_Resumen.xlsx` tiene cuatro hojas:
- **Resumen**: un bloque por prueba. Las 5 y 6 tienen además las secciones "Recarga de la Y (v1 y v2)", "Al cargar los sobres" y "Resultado final", con el **MONTO FINAL** resaltado;
- **Recarga v1-v2**: la tabla comparativa de las pruebas 5 y 6, la regla de reemplazo y la respuesta;
- **Pasos**: el paso a paso, con el orden v1 → sobres → v2 → sobres de T5;
- **Sobres**: los 12 sobres.

## Orden (importa: v2 va entre los sobres de T6 y los de T5)

1. **`py0_prechecks.sql`** (solo lectura).
2. **Carga v1**: F8 con el **local 5** y fecha 12-11-2026 (dejarla abierta) ▸ botón Y ▸ "Ingreso del YYY Masivo" (`Form174`) ▸ **Buscar** `carga_Y_compensa_v1.csv` ▸ 6 grupos `CARGADO` (2.670.800, 860.000, 2.675.000, 2.342.000, 1.000.000 y 1.500.800) ▸ **Cargar** ▸ anotar el **número de carga v1**. Cada grupo responde `Grabado: Z + 1 Y (numeros 1 a 1)`.
3. **Sobres de T1, T2, T3, T4 y T6** (`Form133`, una caja por vez): Recaudador + el Excel de la prueba. Sale "Se Cargaron 2 Registros" y "Compensacion automatica de DI". **Todavía no se cargan los sobres de T5.**
   - Esperado: T1 `DI_REGISTRADA` −800, T2 `DI_REGISTRADA` 15000, T3 `FUERA_RANGO`, T4 `DR_CERO`, T6 `DI_REGISTRADA` −800 (contra v1).
4. **Carga v2**: `Form174` ▸ **Buscar** `carga_Y_compensa_v2.csv` ▸ 2 grupos `CARGADO` (1.200.000 y 1.490.000) ▸ **Cargar** ▸ anotar el **número de carga v2**. Cada grupo responde `Grabado: Z + 1 Y (numeros 1 a 1). Reemplazo lo anterior: 1 Z y 1 Y`. No debe dar ERROR: la Y de T6 sigue abierta (−1), aunque ya tenga sobres y DI.
5. **Sobres de T5**: `Prueba-5-Recarga-v2-antes_L5T5.xlsx` ▸ `Local 5 Terminal 5 Y 1: DI_REGISTRADA por -500`. Si sale `FUERA_RANGO` por 199.500, la Y todavía tenía el monto de v1.
6. **`py2_resultados.sql`** (solo lectura):
   - parte A: las dos cargas, la libvta y la zzz con los montos finales;
   - parte B: DI, estado de las Y y sobres;
   - **parte C**: C1 las dos cargas de T5/T6 lado a lado, **C2 el monto final y la cuadratura**, C3 que no quedaron filas de v1.
7. En pantalla:
   - `Form3Y`: doble clic en la Y 1. En T5 y T6 el efectivo debe ser el de v2. En T6: Dif. de Caja +10.000, Compensación −800, Dif. Real +10.800;
   - `Form4`: en las pruebas 1, 2, 5 y 6, la fila "Diferencia no Imputable" con el monto (−800, 15.000, −500 y −800) y la observación automática;
   - CC (`Form43`), del 12-11 al 12-11: las 6 cajas Pendientes; Dif. Real 0 en T1, T2, T4 y T5, −5.000 en T3 y +10.800 en T6.
8. **Cierre** (ver la sección siguiente).
9. Para repetir: **`py9_limpiar.sql`** (modifica datos y no hace commit solo).

## Cierre de las Y (después de las 6 pruebas)

Solo se cierran las cajas Pendientes con **Dif. Real 0: 5/1, 5/2, 5/4 y 5/5**. Quedan Pendientes la 5/3 (−5.000) y la 5/6 (+10.800), para que las gestione la tienda.

Con CC, botón **"Cerrar Terminal"** (`Form43`), fecha del 12-11 al 12-11, **eligiendo el local 5** (con el local 5 no pregunta y cierra directamente). Con `0-TODOS` pregunta "¿Desea continuar?" con **No** marcado por defecto, y también cerraría otras Y del día con Dif. Real 0.

Para verificar: en CC, 5/1, 5/2, 5/4 y 5/5 `Cerrado` y 5/3 y 5/6 `Pendiente`; en py2 consulta B2, `ter_estado = 1` en T1, T2, T4 y T5.

**Opcional, después de cerrar:** volver a cargar `carga_Y_compensa_v2.csv` (Buscar + Cargar). En T5 debe dar ERROR "El terminal tiene 1 cierre(s) Y cerrado(s) ... no se reemplaza", y el monto sigue en 1.200.000. Esto confirma que una Y cerrada no se reemplaza. T6, que sigue abierta, se graba de nuevo con el mismo monto.

## Archivos

| Archivo | Qué es |
|---|---|
| `carga_Y_compensa_v1.csv` | Primera carga masiva (56 columnas, `;`, CRLF, ANSI): Z + Y 1 de las 6 cajas del 12-11-2026 (T1 2.670.800, T2 860.000, T3 2.675.000, T4 2.342.000, T5 1.000.000, T6 1.500.800). Son las filas de la sesión 7 con la fecha cambiada |
| `carga_Y_compensa_v2.csv` | Segunda carga: solo T5 (1.200.000) y T6 (1.490.000), con la misma fecha, local, terminal y `NRO_Y` 1, y otra hora, secuencia, boleta y contador |
| `Prueba-1..6-*_L5T<n>.xlsx` | Excel de sobres para `Form133` (formato de `../../FSCC-12901_COMPENSA_DI/prueba_test9/`), fecha `20261112` |
| `Prueba-Y-DI_Resumen.xlsx` | Resumen por bloques, recarga v1-v2, pasos y sobres |
| `py0_prechecks.sql` | Verificaciones previas (solo lectura), terminales 1 a 6 y 12 sobres |
| `py2_resultados.sql` | Resultados (solo lectura); parte C: recarga v1/v2 y monto final |
| `py9_limpiar.sql` | Deshacer la prueba (modifica datos, sin commit), T1 a T6, deja los grupos de las dos cargas en `CARGADO` |

## Si algo falla

Lo mismo que en las sesiones 6 y 7 (ver `../prueba_carga_y_compensa_di_s6/LEEME.md` y `../prueba_carga_y_compensa_di_s7/LEEME.md`), con la fecha 12-11-2026, más lo propio de la recarga:

- **Cargar v2 da ERROR "tiene cierre(s) Y cerrado(s)" o "La Z del terminal esta cerrada":** alguien cerró la caja entre v1 y v2 (CC, cron o Salir de Form174). Es el comportamiento correcto: una caja cerrada no se reemplaza. Para seguir hay que reabrirla o limpiar con py9 y empezar de nuevo.
- **py2 C3 muestra 4 filas por terminal:** Cargar v2 no reemplazó. Revisar el mensaje del grupo en `Form175` y la parte A.
- **T5 da `FUERA_RANGO` por 199.500:** se cargaron los sobres de T5 antes que v2 (paso 5 antes del 4). Limpiar T5 con py9 y repetir en orden.
- **T6 da Dif. Real 0 después de v2:** se cargó v2 antes que los sobres de T6, lo que en la práctica es la prueba 5. Repetir respetando el orden del paso 3.
- **Para repetir:** py9 deja en `CARGADO` los grupos de las dos cargas. Lo más simple es volver a hacer Buscar + Cargar con v1 y después con v2 (números de carga nuevos), en el mismo orden.
