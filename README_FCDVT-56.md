# FCDVT-56 · HU-14.2: cerrar automáticamente los terminales activos sin movimiento (Falabella Colombia, FACO)

> **Estado (22-10-2026):**
> - **CC manual hecho** (§4b): `Form43` muestra en FACO los terminales vigentes sin movimiento y "Cerrar Terminal" cierra su Z, como en Chile. Está aplicado **sin compilar**.
> - **Cierre automático (cron) programado sin ejecutar (§7):** es la etapa "sin venta" de `PKG_F8_CIERRE_DIARIO`, que cierra la Z como CC. Se programó el 22-10 con las respuestas a P1, P3 y P4. Siguen abiertas P2 y P7.
> Fuente: `docs/sql/FCDVT-56/FCDVT-56.doc` (export de Jira). Historia padre: **FCDVT-54**, "HU-14 · Cierre automático de terminales con DR 0", que es el trabajo de FSCC-12901 (`docs/README_FSCC-12901.md`).

## 1. Qué pide

> Como tesorería de Falabella Colombia, quiero que el cierre automático también cierre los terminales activos que no tuvieron venta, para no tener que cerrarlos con el archivo «dataload».

| Escenario | Dado | Entonces |
|---|---|---|
| Terminal sin venta | Terminal activo de Colombia sin movimiento en la fecha de proceso − 1, al terminar la carga nocturna | Queda **Cerrado** con Diferencia Real 0 |
| Terminal dado de baja | Terminal dado de baja | No se considera |
| Terminal esperando sobres | Terminal sin venta que espera la carga de sobres de retiro | Queda **abierto** |

- Pantallas: Cuadratura por caja (`Form3Y`), Consultas de Cuadratura (`Form43`) y Estado General de Terminales (`Form2`).
- Tablas: `VTA_FACOTERMSTAT`, `VTA_FACOTERMSTATY`, `VTA_FACOTERMINALES` y `VTA_FACOESTATUS`.

## 2. Qué es hoy un "terminal abierto sin venta" en FACO

**"Sin Datos" en la F8 de la Y** (por ejemplo, local 6, T1, 31-08-2026) no es un estado guardado en la base:
- `Form3Y.LeeTerminales` (`Form3Y.frm:1808-1830`) lista **todos** los terminales vigentes del local (filtro `ter_fechabaja`), vendan o no.
- `LeeCierrey` (`:3415-3470`) llena el combo de Y desde `LIBVTA` (tiporeg `'Y'`, estado `'A'`) ⋈ `ZZZ` ⋈ `TERMSTATY`. Sin venta no encuentra nada, y deja Y = 0.
- `VeEstado` (`:3000-3023`) busca `ter_estado` en `VTA_FACOTERMSTATY` con Y = 0. No hay fila, así que salta al manejo de error (`:3159`), que fija `estado = 3` y muestra **"Sin Datos"** en negro (`:3127-3130`).
- Los demás estados: −1 Pendiente (rojo), 0 Pendiente (amarillo), 1 Cerrado, 2 Impreso, −2 naranjo.

**Lo que está "abierto" es la Z, no la Y:**
- En FACO, el exe solo crea `TERMSTATY` junto al libro de ventas Y (`Form19Y.GrabaZZZ` → `GrabarQuintoZZZ`, `Form19Y.frm:452-477, 610`). **Un terminal sin venta no tiene Y.**
- Lo que existe es la **Z precreada en −1** en `VTA_FACOTERMSTAT`. Hay unas 2.180 por día, y solo de 0 a 10 tienen venta (`README_FSCC-12901.md` §6). La crea un proceso de base; ninguna línea del exe la inserta en −1.
- `Form133.AbrirTerminal` (`Form133.frm:707-760`), en la carga de sobres, reabre o crea la Z en **0** con `ter_notas = 'CARGA MANUAL DE SOBRES'`.
- `Form20` (reapertura) pone Z e Y en 0 (`Form20.frm:445-468`), pero solo si la fila ya existe.

**Foto del usuario de negocio (21-10-2026): local 11 "VENTA EMPRESA", T1, 19-10-2026, todo en 0, "Pendiente" en rojo.** El usuario la describe como "cerrar terminal de Y que no presenten movimientos", pero la pantalla es la **F8 de la Z (`Form3`)**, no la de la Y:
- `Form3` no tiene combo de N° de Y (`Form3Y` sí, `Combo4`). En FACO muestra el rótulo "Cierre de Y" (`LabelCierrey`) y la grilla `Grid2` con las Y del terminal (`Form3.frm:4331-4338`). En la foto la grilla solo tiene el encabezado "Y", sin columnas: **el terminal no tiene ninguna Y**.
- El estado lo lee `Form3.VeEstado` de `VTA_FACOTERMSTAT`, es decir, de la **Z** (`Form3.frm:3714-3737`). Rojo es `ter_estado = -1`, la Z precreada. Si no hay fila, muestra "Sin Datos" (estado 3).
- Si hubiera Y, el doble clic en `Grid2` abriría `Form3Y` (`Form3.frm:4509-4521`).
- **En test (consultado el 21-10)** el local 11 / T1 está vigente (`ter_tipo` 0, baja 31-12-5000) y no tiene Y, libro de ventas ni sobres el 19-10. Tampoco tiene Z ese día: la última fecha con Z en test es el 16-10, y del 16-10 hacia atrás todas sus Z están en −1. La foto, por lo tanto, es de otro ambiente (probablemente producción); en test esa pantalla mostraría "Sin Datos".

## 3. ¿Lo cubre `PKG_F8_CIERRE_DIARIO`? **No**

- **Universo:** `LIBVTA (Y, 'A') ⋈ ZZZ ⋈ TERMSTATY`, con `ter_cierrey <> 0` y `ter_estado <= 0` (`sql/FSCC-12901_CIERRE_DIARIO/04_pkg_cierre_diario_body.sql:781-795`). Un terminal sin venta no tiene libro de ventas ni Y, así que nunca entra.
- **Dif. Real:** `fn_dif_real` y `fn_dif_real_cc` devuelven **NULL**, no 0, cuando no hay libro de ventas (`sql/FSCC-12901_COMPENSA_DI/05_pkg_compensa_di_carga_body.sql:344-346`, `04:293-295`).
- **Bajas:** no cruza con `VTA_FACOTERMINALES`, así que tampoco filtra los terminales dados de baja.
- **Sobres:** no tiene el concepto "esperando sobres".
- **Z:** no toca `VTA_FACOTERMSTAT`, por la decisión del 07-10 de cerrar solo la Y.
- **Ya estaba identificado:** brecha **B6** (terminal activo sin movimiento) y **B1** (HU-14 pide cerrar "Y y terminal-día", es decir, también la Z) en `docs/FSCC-12901_Comparacion_Onboarding.md:37,42`.
- **Versiones anteriores:** la lógica de "sin sobre" de la v2 (`FSCC-12901_PROC_Y`, `CA_SIN_SOBRE`, `fn_universo :300-317`) y de la v1 (`VTA_FACOV_CAJAS_CIERRE`, `prc_cierre_rango`, cuyo comentario dice "evitar el dataload") **también exigía libro de ventas Y**.

## 4. ¿Los muestran las pantallas?

| Pantalla | ¿Muestra el terminal sin venta? | Detalle |
|---|---|---|
| **CC (`Form43`)** | **No** en FACO hasta el 22-10 (**sí desde el cambio de §4b**) | `FuncStrPivote` (`Form43.frm:2081-2127`) usa el mismo join con libro de ventas. Para terminales sin venta existe un `UNION ... from vta_<pfx>termstat t where not exists (libvta)`, pero **solo para SFCL/HTPE** (`:2140-2175`) y **ARG** (`:2177-2205`). Ese es el precedente para FACO. "Cerrar Terminal" (`Command4_Click :2915`) solo actúa sobre filas de la grilla con Y ≠ 0 |
| **Form3Y** | Sí, como "Sin Datos" | Ver §2 |
| **Form2** | Sí, en **rojo (−1)** | Lee solo la Z (`VTA_FACOTERMSTAT` + terminales vigentes, `Form2.frm:546-556, 731-745`). Como en FACO la Z no se gestiona, nunca pasa a verde. Un terminal sin fila queda como celda vacía |

## 4b. Cambio en CC (22-10-2026): FACO como Chile

**Por qué Chile sí los muestra:**
- `Command2_Click` envía Chile (`""`/`CHI`) a `SubBuscarOpcionSOAR_SOUY` → `FuncStrPivoteSOAR_SOUY`.
- Esa consulta tiene un segundo `UNION`: `vta_termstat` (la Z) ⋈ `vta_terminales` con un `LEFT JOIN` a libvta. Trae los terminales sin venta con `ter_cierrey = 0` y el estado de la Z.
- FACO va a `SubBuscarOpcion` → `FuncStrPivote`, que solo hace `libvta Y ⋈ zzz ⋈ termstaty`.

**Cambio** (`FTEPROD/Form43.frm`, `FuncStrPivote`, antes del `Order by`, marca `xintec-nruz 22-10-2026 FCDVT-56`, respaldo `Form43.frm.bak_FCDVT-56`): `UNION` para FACO.
- **Origen:** filas de `vta_FACOtermstat` de terminales vigentes en la fecha (`ter_fechabaja is null or >= ter_fecha`) **sin** libro de ventas Y `'A'`, con Y = 0 y el estado de la Z.
- **Solo** con la opción "Terminal" (`VF_NumInforme = 0`) y con **un local elegido**: con `0-TODOS` todo queda igual, por volumen (decisión del usuario del 22-10). "Gral. Tesorería" no cambia.
- **No se tocó nada más.**
  - `SubBuscarOpcion` ya muestra en FACO todas las filas.
  - Con Y = 0, la Z da 0 y la recaudación suma **todos** los sobres del terminal-día. Si llegaron sobres, la Dif. Real queda ≠ 0 y el terminal no se cierra.
  - "Cerrar Terminal" (`Command4_Click`, rama FACO, segundo bucle) cierra las filas con Y = 0 y Dif. Real 0 con `CierraTerminal`: `vta_FACOtermstat.ter_estado = 1`, `ter_cerradopor = usuario`. Sus validaciones pasan sin Y (`FuncValidarZSumaY` con 0 = 0; `FuncValidadCierreyyyy` sin filas → True).
- **Decisión (usuario, 22-10):** en el cierre **manual** desde CC, un terminal sin venta se cierra cerrando su **Z**, como en Chile. Es una excepción a la regla del 07-10 de cerrar solo la Y, porque estos terminales no tienen Y. El cron sigue pendiente de P1.
- **Verificado en test (solo lectura, SQL del `UNION` a mano):**
  - local 11, 15 y 16-10: 6 terminales por día en −1;
  - local 183, 16-10: 104 terminales sin venta en −1, y el terminal 953 (con Y 1) sale **una sola vez**, con su Y.
  - Un local grande puede tardar en CC: cada fila hace unas 10 consultas.
- **Filtro de Terminal (22-10, a pedido del usuario):**
  - Antes, en FACO, el combo Terminal (`Combo3`) se veía pero no filtraba: `FuncStrPivote` solo filtraba para SFCL/ARG.
  - Ahora, con la opción Terminal (`VF_NumInforme = 0`), Terminal = 0 muestra todo y Terminal ≠ 0 filtra, tanto la parte con Y (`l.vta_terminal`) como el `UNION` sin venta (`t.ter_terminal`).
  - Se usa `Val(Trim(Combo3.Text))`, así que un combo vacío no rompe el SQL.
  - "Gral. Tesorería" no filtra aunque el combo oculto conserve un valor.
  - "Cerrar Terminal" cierra solo el terminal elegido.
  - Verificado en test (solo lectura): local 183, 16-10; T953 → solo 953 con Y 1; T5 → solo 5 con Y 0.

## 5. Conceptos del requerimiento contra la base

- **Dado de baja:**
  - El único indicador es `VTA_FACOTERMINALES.ter_fechabaja`. El terminal está vigente en la fecha D si `ter_fechabaja is null or ter_fechabaja >= D`; es el mismo filtro que usan unas 145 consultas del exe, por ejemplo `Form3Y.frm:1820` y `Form2.frm:553`.
  - `ter_tipo` es el tipo de terminal (0 normal, 1 Autopago, 2 POS Mobile; `Form50.frm:220-307`), no la baja.
- **`VTA_FACOESTATUS`:** es por **local-día** (`vta_stlocal`, `vta_stfecha`, `vta_estadof8`; cierre general del local, `Módulo1.bas:822, 3649`), no por terminal. El cierre general solo se bloquea si hay una `TERMSTATY` con estado distinto de 1 (`Est_TermStatPorlocal`, `Módulo1.bas:5854-5885`), así que los terminales sin fila no lo bloquean.
- **"Esperando sobres de retiro":** en FACO **no existe** esa regla. Hay tres señales posibles:
  - sobres del terminal-día en `VTA_FACOPRD` (`prv_tiporec = 'F8'`);
  - retiros declarados en `VTA_FACORETIROS` (`ret_coddenom <> 88`), que es lo que leen `LeeProsegur` y `LeeRetiros` de `Form3Y` (`:2401`, `:2319`);
  - una Z en 0 con `'CARGA MANUAL DE SOBRES'`.

  Lo que define cuándo un terminal "espera" sobres (por cuántos días y con qué dato) tiene que venir de negocio.
- **Proceso existente parecido:** `PKG_F8_FACO_CIERRE_TER_PM_AP` (2022; su cuerpo no es visible con el usuario de test). Cierra con `AUTOMATICO` Y y Z de montos en 0, sobre todo Autopago y POS Mobile: 556 Y y 117 Z (`docs/FSCC-12901_Analisis.md:31, 211`). Hay que ver si se solapa con este requerimiento.

## 6. Preguntas abiertas (negocio / usuario)

| # | Pregunta | Por qué importa |
|---|---|---|
| P1 | ¿Qué es "cerrar" un terminal sin venta en FACO? (a) cerrar la **Z precreada** (`TERMSTAT` −1/0 → 1); (b) **crear** una `TERMSTATY` con Y 0 en estado 1; (c) ambas | La historia dice "cerrar el terminal", no "la Z"; que lo abierto sea la Z es una deducción del modelo de datos. Con (a) Form2 pasa a verde, pero **Form3Y sigue en "Sin Datos"** y se contradice la decisión del 07-10 de no tocar la Z. Con (b) Form3Y mostraría "Cerrado" con Y 0. Hoy no hay nada en la Y que cerrar. **21-10:** el usuario de negocio habla de "terminal de Y", pero en su foto lo abierto es la Z (`Form3`, ver §2); hay que confirmárselo al responder P1 |
| | **P1, resuelta el 22-10 (usuario):** (a), cerrar la Z **igual que CC** | Ver §7 |
| P2 | ¿Qué hace exactamente el "dataload" de hoy: qué tabla, qué estado y qué `ter_cerradopor`? | Es la referencia del resultado esperado |
| P3 | ¿Cuándo "espera sobres" un terminal? ¿Por sobres o retiros del terminal-día todavía sin cargar? ¿Cuántos días se espera? | **Resuelta el 22-10 (usuario): cuando ya se creó la Y.** Un terminal con fila en `TERMSTATY` no se toca en la etapa sin venta |
| P4 | ¿Entran Autopago y POS Mobile (`ter_tipo` 1/2) o siguen con `PKG_F8_FACO_CIERRE_TER_PM_AP`? | **Resuelta el 22-10 (usuario): no se toca ningún paquete salvo `PKG_F8_CIERRE_DIARIO`.** No hay filtro por `ter_tipo`, como en CC. Lo que `PM_AP` ya cerró tiene la Z en 1 y no entra |
| P5 | ¿CC debe mostrar estos terminales en FACO, agregando el `UNION` como en SFCL? | **Resuelta 22-10: sí** (§4b), solo con un local elegido |
| P6 | ¿Va como segunda etapa de `PKG_F8_CIERRE_DIARIO` (mismo cron de nhal1) o como proceso aparte? | Diseño y prueba |
| P7 | "Fecha de proceso − 1": ¿es el mismo día que ya toma el cron (`fecha` nula = día anterior)? | Alinear con `prc_cierre_diario` |

## 7. Etapa sin venta en `PKG_F8_CIERRE_DIARIO` (22-10-2026, implementada sin ejecutar)

Detalle en `docs/sql/FSCC-12901_CIERRE_DIARIO/00_LEEME.md`, sección "Etapa sin venta". Respaldo de la versión anterior en `anterior_2026-10-22/`.
- **Qué hace:** después de las Y, simula el segundo recorrido de "Cerrar Terminal" de CC (`Command4_Click` → `CierraTerminal`) para todos los locales de la fecha.
- **Universo:**
  - Z Pendiente (`ter_estado <= 0`) de un terminal vigente;
  - sin libro de ventas Y `'A'`;
  - **sin ninguna Y creada** (P3).
- **Condición:** la Dif. Real de la fila "Cierre Y 0" de CC (todo el terminal en el día) debe ser 0. Si llegaron sobres, retiros o compensaciones, el resultado es `CON_DIFERENCIA_CC`.
- **Validaciones de `CierraTerminal`:**
  - RZ-01: conceptos del día sin regularizar;
  - RZ-02: la Z contra la suma de las Y;
  - RZ-03: fórmula ZZZ (`CD_VAL_ZZZ`, en N);
  - RZ-04: dólares contra Prosegur (`CD_VAL_DOL`, en N).
- **Cierre:** `VTA_FACOTERMSTAT.ter_estado = 1` con `ter_cerradopor = 'PROC_CIERRE_DIARIO'`, commit por terminal y `CERRADA_SIN_VENTA` en el log.
- **Encendido:** parámetro 1502 `CD_SIN_VENTA` en S. Es una inserción nueva en `02_parametros.sql`.
- **Prueba:** `prueba_test/P3_sin_venta.sql`, con el caso de la captura (local 5, T2, 15-10-2026). Simulación sin grabar: `fn_evalua_caja('FACO', fecha, local, terminal, 0)`.
- **Siguen abiertas:**
  - P2: qué hace el "dataload", para comparar el resultado;
  - P7: si "fecha de proceso − 1" es el día anterior que ya toma el cron.

### 7a. Propuesta original (antes de las respuestas del 22-10)

- **Segunda etapa "SIN_VENTA" en `PKG_F8_CIERRE_DIARIO`**, en la misma llamada de nhal1 y detrás del parámetro 1502 `CD_SIN_VENTA` (S/N):
  - **Universo:** terminales vigentes de `VTA_{P}TERMINALES` en la fecha (`ter_fechabaja`; `ter_tipo` según P4) **sin** libro de ventas Y `'A'` y sin Y abierta.
  - **Excluir los que esperan sobres** (P3): sobres en `PRD` o retiros del terminal-día. Esos quedan con el resultado `ESPERA_SOBRES`.
  - **Acción según P1:** `update` de la Z (y/o `insert` de la `TERMSTATY` Y 0) con estado 1 y `ter_cerradopor = 'PROC_CIERRE_DIARIO'`; commit por terminal; resultado `CERRADA_SIN_VENTA`.
  - **Multipaís** con el mismo `pr_config`, y el mismo log (`VTA_FACOLOG_CIERRE_DIARIO`).
- **Opcional (P5):** agregar a `Form43.FuncStrPivote` el `UNION` de terminales sin venta para FACO, como el de SFCL (`:2140-2175`).
- **Volumen:** alrededor de 2.180 terminales vigentes por día. El universo debe ser una sola consulta por fecha, sin recorrer local por local.

## 8. Consultas de verificación en test (solo lectura)

```sql
-- 1. Local 6, 31-08-2026: terminales vigentes, si tienen Y con venta y estado de Z/Y
select t.ter_terminal, t.ter_tipo, t.ter_fechabaja,
       (select count(*) from VTA_FACOLIBVTA l
         where l.vta_tiporeg = 'Y' and l.vta_estado = 'A' and l.vta_fecha_venta = d.f
           and l.vta_local = t.ter_local and l.vta_terminal = t.ter_terminal) libvta_y,
       (select max(z.ter_estado) from VTA_FACOTERMSTAT z
         where z.ter_fecha = d.f and z.ter_local = t.ter_local and z.ter_terminal = t.ter_terminal) estado_z,
       (select max(z.ter_notas) from VTA_FACOTERMSTAT z
         where z.ter_fecha = d.f and z.ter_local = t.ter_local and z.ter_terminal = t.ter_terminal) notas_z,
       (select count(*) from VTA_FACOTERMSTATY y
         where y.ter_fecha = d.f and y.ter_local = t.ter_local and y.ter_terminal = t.ter_terminal) filas_y,
       (select count(*) from VTA_FACOPRD p
         where p.prv_fechavta = d.f and p.prv_local = t.ter_local and p.prv_terminal = t.ter_terminal) sobres
  from VTA_FACOTERMINALES t, (select to_date('20260831','yyyymmdd') f from dual) d
 where t.ter_local = 6
   and (t.ter_fechabaja is null or t.ter_fechabaja >= d.f)
 order by t.ter_terminal;
-- ESPERADO: T1 con libvta_y 0, filas_y 0 y estado_z -1 (si existe la Z).

-- 2. Volumen del dia: Z sin venta por estado
select z.ter_estado, count(*)
  from VTA_FACOTERMSTAT z
 where z.ter_fecha = to_date('20260831','yyyymmdd')
   and not exists (select 1 from VTA_FACOLIBVTA l
                    where l.vta_tiporeg = 'Y' and l.vta_estado = 'A'
                      and l.vta_fecha_venta = z.ter_fecha and l.vta_local = z.ter_local
                      and l.vta_terminal = z.ter_terminal)
 group by z.ter_estado;

-- 3. Quien cierra hoy esas Z (dataload / AUTOMATICO / otros)
select z.ter_cerradopor, count(*)
  from VTA_FACOTERMSTAT z
 where z.ter_fecha >= to_date('20260801','yyyymmdd') and z.ter_estado = 1
 group by z.ter_cerradopor order by 2 desc;
```

La consulta 3 ayuda a responder P2 (qué deja el dataload).

## 9. Pendientes

| # | Pendiente | Responsable |
|---|---|---|
| 1 | Responder P1–P7 | Negocio / usuario |
| 2 | Ejecutar las consultas de §8 en test | Usuario (o Claude con la clave, solo lectura) |
| 3 | Con P1–P7 respondidas: diseño y scripts en `docs/sql/FCDVT-56/` (etapa SIN_VENTA del paquete) | Claude |
| 4 | Compilar `Form43` y probar en test (§4b): local 11 o 183, fecha ≤ 16-10, fila Y 0 en rojo; con `0-TODOS` igual que antes; "Cerrar Terminal" deja la Z en 1; un terminal con sobres no se cierra; Terminal ≠ 0 filtra (con Y y sin venta) y "Cerrar Terminal" cierra solo ese terminal | Usuario |

## 10. Historial

| # | Fecha | Qué se hizo |
|---|---|---|
| 1 | 20-10-2026 | Análisis inicial: el requerimiento contra el exe (`Form3Y`, `Form43`, `Form2`, `Form133`, `Form19Y`) y contra `PKG_F8_CIERRE_DIARIO`. Conclusión: el paquete no lo cubre y CC no muestra estos terminales en FACO. Preguntas P1–P7 |
| 2 | 21-10-2026 | Foto del usuario de negocio (local 11, T1, 19-10, "cerrar terminal de Y"): es la F8 de la **Z** (`Form3`, `VeEstado` lee `TERMSTAT`, `Grid2` sin Y). Confirmado en test, solo lectura: el terminal no tiene Y, libro de ventas ni sobres; en test no hay Z del 19-10 (la última es del 16-10) y sus Z anteriores están en −1. Anotado en §2 y P1 |
| 3 | 22-10-2026 | Caso del usuario: en Chile un terminal sin movimiento (local 12, T8100, 02-10) se ve y se cierra en CC, y en FACO no. Causa: el `UNION` de Z sin venta de `FuncStrPivoteSOAR_SOUY`. Se agregó un `UNION` equivalente para FACO en `Form43.FuncStrPivote` (§4b; solo opción Terminal y con un local; cierra la Z). SQL verificado en test (solo lectura). Sin compilar |
| 4 | 22-10-2026 | Filtro de Terminal en CC para FACO (§4b): con 0 muestra todo; con otro valor filtra la parte con Y y el `UNION` sin venta. Solo opción Terminal. Verificado en test (solo lectura). Sin compilar |
| 5 | 22-10-2026 | Respuestas del usuario: P1 cerrar la Z igual que CC; P3 "espera sobres" significa que ya tiene la Y creada; P4 solo se toca `PKG_F8_CIERRE_DIARIO`. Se agregó la **etapa sin venta** a `PKG_F8_CIERRE_DIARIO` (§7): universo de Z Pendientes sin libro de ventas Y ni Y creada, Dif. Real de CC con Y 0, validaciones RZ-01 a RZ-05 de `CierraTerminal`, parámetros `CD_SIN_VENTA` y `CD_VAL_DOL`, `P3_sin_venta.sql` y rollback 1b/2c. Versión anterior en `CIERRE_DIARIO/anterior_2026-10-22/`. Sin compilar ni ejecutar (sin VPN) |
| 6 | 22-10-2026 | Estado congelado: manifiesto `docs/MANIFIESTO_FCDVT-56.md5` (`Form43` con los cambios de §4b, su respaldo, `CIERRE_DIARIO` completo con `anterior_2026-10-22/` y los índices) y respaldo `docs/respaldos/FCDVT-56_2026-10-22_cierre-sin-venta.zip`. `docs/MANIFIESTO_FSCC-12901.md5` no se regeneró: ya no coincide en `CIERRE_DIARIO` ni en `Form43.frm` |
