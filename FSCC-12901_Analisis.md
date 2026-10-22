# Análisis de FSCC-12901: compensación automática de DI y cierre automático (Falabella Colombia)

| | |
|---|---|
| **Historia** | FSCC-12901 · [SCCFIN][F8] Compensación automática de Diferencia No Imputable dentro de un rango, Falabella Colombia |
| **Épica** | FSCC-12287 · Evolutivos y mejoras funcionales Legados C2-2026 |
| **Subtareas** | FSCC-12957 (T1 Compensación automática), FSCC-12958 (T2 Cierre de caja automático) |
| **Estado del ticket** | Refining (05-10-2026) |
| **Base del análisis** | Código fuente VB6 (`FTEPROD/`) y los documentos [CierreCaja_FACO_Reglas.md](CierreCaja_FACO_Reglas.md) y [CC_ConsultaCuadratura_FACO.md](CC_ConsultaCuadratura_FACO.md). **No** se revisó el Excel adjunto `DF-SCC-vf_Falabella CO (MEJORAS F8 y COMPENSACIONES MENORES).xlsx` (no está disponible localmente) ni el fuente de `PKG_F8_COMPENSACION_DI` (está solo en la base) |
| **Índice y bitácora** | [README_FSCC-12901.md](README_FSCC-12901.md): estado, artefactos, decisiones, datos verificados, pendientes y cómo retomar |
| **T2 en base de datos (aprobado 06-10-2026)** | Tabla homóloga `VTA_FACOPRD_CIERRE` + trigger sobre `VTA_FACOPRD` + paquete `PKG_F8_FACO_CIERRE_AUTO`. Scripts y README en [`docs/sql/FSCC-12958/`](sql/FSCC-12958/README.md) |
| **Documentos por subtarea** | [FSCC-12957_T1_Compensacion_DI_automatica.pdf](FSCC-12957_T1_Compensacion_DI_automatica.pdf) y [FSCC-12958_T2_Cierre_caja_automatico.pdf](FSCC-12958_T2_Cierre_caja_automatico.pdf) (fuentes HTML en `docs/pdf/`) |
| **Actualizado** | 06-10-2026: se agregan la carga de Colombia (§3.8), la identificación y contabilización (§3.9), las subtareas FSCC-12957/12958 (§3.10), la verificación en la base de test (§3.11), los diagramas BPMN contra el código (§3.12, N1–N5), P12–P14 y los casos T16–T18 |

---

## 1. Veredicto

**La historia tiene sentido y es viable.** Lo que pide coincide con cómo funciona hoy el cierre en Colombia, y gran parte de las piezas ya existen:

- **Precedente para Chile.** Después de cargar el PRD, `Form130` ya llama a `pkg_f8_compensacion_di.cierre_terminal_di(fecha)`, un procedimiento almacenado de "cierre de terminal con DI". FSCC-12901 es, en esencia, **la versión para Colombia de ese proceso**.
- **Rango de la DI.** La DI manual de Colombia ya se valida contra un rango parametrizado en `vta_FACOparam` (tipos 1500/1501, código `'DI'`).
- **Registro de la DI.** La forma de grabar una DI (tabla, campos, fecha contable = fecha de venta) ya está definida y se puede reproducir.
- **Validaciones de cierre.** Las de "Cerrar Terminal" para la Y y la Z ya están especificadas, con su SQL, en `CierreCaja_FACO_Reglas.md` (RY-01..06, RZ-01..09).

Antes de pasar a desarrollo hay que **corregir o precisar varios puntos de la historia** (§4): el signo del criterio 1, en qué nivel se registra la DI (Y o Z), qué parámetro se usa, la "fecha de cierre", el perfil del proceso y la identificación en el envío contable.

El disparador ya está claro por el código: la carga del día en Colombia es `Form133` (§3.8). Esa misma revisión mostró un riesgo que la historia no contempla: la carga reabre la Z pero no las Y ya cerradas (P12).

**La base de test (§3.11) confirma que el desarrollo puede apoyarse en piezas que ya están en la base:**
- **`PKG_F8_FACO_CIERRE_TER_PM_AP`** (2022) es un cierre automático **de Colombia, por Y**. Ya cerró 556 Y y 117 Z con `ter_cerradopor = 'AUTOMATICO'`, sobre todo terminales Autopago y Y sin movimiento. **T2 es, en la práctica, extender ese paquete a todas las cajas de la carga.**
- **`FUN_F8_COMPENSACION_DI_DR`** (actualizada en agosto de 2025) calcula en PL/SQL la misma diferencia real que la F8, pero para Chile. Es la base para la función de diferencia real de Colombia que necesita T1.
- **El cuerpo de los dos paquetes no es visible** con el usuario de test: hay que pedírselo al DBA antes de estimar.

---

## 2. Criterios de aceptación frente a lo que existe

Leyenda: ✔ ya existe · ⚠ existe, pero hay que ajustar o precisar · ✖ es nuevo.

| # | Criterio | Estado | Comentario |
|---|---|---|---|
| — | Proceso automático tras la carga del día | ⚠ | Existe para Chile (`Form130.frm:586` → `CargarCierre :1192`). En Colombia la carga del día es `Form133.CargarArchivo` (§3.8): el proceso se engancharía al final de esa rutina |
| — | DR = Dif. de caja − Compensación | ✔ | Igual que `Label70` de la F8 (`CierreCaja_FACO_Reglas.md` §2) |
| — | Rango parametrizable en `VTA_FACOPARAM` | ⚠ | Ya existen `vta_FACOparam` 1500/1501 `'DI'` para la DI manual (`Form38.frm:498`). Falta decidir si se reutilizan (P2) |
| — | Respeta todas las validaciones de Cerrar Terminal | ✔ | RY-01..06 y RZ-01..09. Falta definir el perfil del proceso (P5) |
| — | Evaluación por Y y por Z | ⚠ | En Colombia la DI **solo se graba por Y** (`Form38.frm:462`, `:650`); la Z no tiene DI propia (P3) |
| 1 | DR −800 → DI por 800, DR = 0, Cerrado con usuario de proceso y fecha de cierre | ⚠ | **Signo:** la DI tiene que ser −800 (P1). **Fecha de cierre:** hoy no se graba en Colombia (P4) |
| 2 | Límites −1.000 y 20.000 se compensan | ✔ | `Form38` ya usa `<` y `>` para rechazar, es decir, límites inclusivos |
| 3 | −1.001 / 20.001 → no se compensa, queda en el resumen | ✖ | Tabla de log/resumen nueva |
| 4 | Conceptos pendientes → no cierra; el resumen indica cuál | ✔/✖ | La regla existe (RY-03/RZ-03 con su mensaje); el resumen es nuevo |
| 5 | DI identificada como automática en el Informe de Diferencias y en el Envío Contable | ⚠ | **Informe de Diferencias:** el detalle por concepto de `Form7` ya muestra `mov_hechopor` (`Form7.frm:13484`), así que con un usuario de proceso propio la DI queda identificada. **Envío contable:** `Form62` suma la DI por fecha y local (`Form62.frm:4391`), así que en el asiento no se puede distinguir automática de manual. Hay que definir qué se espera ahí (§3.9, P9) |
| 6 | Cambiar los límites sin tocar código | ✔ | Con `vta_FACOparam` |
| 7 | Fecha contable = fecha de venta | ✔ | `InsertarRegistroMovDet` ya graba `MOV_FECHAREG = fecha de venta` (`Módulo1.bas:3777`) |
| 8 | Terminal sin sobres con DR en el rango → se compensa igual | ✔ | La DR no depende de que haya sobres; sin sobres, la DR = −(lo declarado en la Y) |
| 9 | "Se registra DR = 0 (se ingresa diferencia imputable) por proceso de imputación automática…" | ⚠ | La redacción es confusa (P7). Se interpreta así: si la Y ya tiene DR = 0, no se compensa y se intenta cerrar directamente. El diagrama del proceso 2 lo confirma ("incluye los que ya tenían DR 0") |

---

## 3. Hallazgos en el código

### 3.1 Precedente en Chile: `pkg_f8_compensacion_di`

- `Form130` ("Interfaz de Validación", toolbar `MantValidacion`) → `Command3_Click` (`:586`) carga el PRD (`CargarPRD`, que hace `insert into vta_prd` en `:493`). Después llama a:
  - `pkg_f8_compensacion_di.CARGA_BILLETE_FALSO(fecha)` (`:1221`);
  - `pkg_f8_compensacion_di.cierre_terminal_di(fecha)` (`:1192`, `:605`).
- **Solo sirve para Chile:** usa `vta_prd` y `update vta_termstat` (`:738`) sin prefijo de país.
- Los errores del paquete **se ignoran sin aviso** (`On Error GoTo salir` sin mensaje).
- **El código fuente del paquete no está en el repositorio.** Hay que obtenerlo de la base antes de diseñar:
  ```sql
  select type, line, text from all_source
  where  name = 'PKG_F8_COMPENSACION_DI' order by type, line;
  ```
  Ahí se verá qué validaciones de cierre replica Chile, cómo registra la DI y si deja log. Eso puede ahorrar buena parte del desarrollo.

### 3.2 Rango ya parametrizado para la DI manual de Colombia

`Form38.CommandAceptar_Click`, rama `FACO` (`Form38.frm:498`):

```vb
If CDbl(txt_monto.Text) < CDbl(Fuctiondatoparam(1500, "DI")) Then  ' "no Puede ser inferior a…"
If CDbl(txt_monto.Text) > CDbl(Fuctiondatoparam(1501, "DI")) Then  ' "no Puede mayor a…"
```

- Antes eran valores fijos (−500 / 20.000, hoy comentados).
- Valores actuales: `select * from vta_FACOparam where vta_ccodtipo in (1500,1501) and vta_ccodigo = 'DI'`.
- Si los valores actuales ya son −1.000 / 20.000, la historia puede **reutilizarlos**, y así el analista y el proceso automático usan el mismo rango.

### 3.3 La DI se registra por Y; la Z no tiene DI propia

- En la F8 por terminal (`Form3`, Z), `Form38` deshabilita la DI para Colombia (`Form38.frm:462` y `:650`). Solo se puede registrar en `Form3Y`, con `mov_cierrey`.
- La compensación de la Z es la **suma** de las compensaciones del día (`StrSumCompensado` sin filtro de Y).
- **Consecuencia para la historia:**
  - la compensación automática se hace **en cada Y**;
  - la Z **no se compensa**: se recalcula y, si da DR = 0, se cierra.
  - Si la Z queda con DR ≠ 0 aunque todas sus Y estén en 0 (por ejemplo, sobres PRD sin `prv_cierrey` o diferencias entre la Z y la suma de las Y), el terminal queda **Pendiente con motivo**. No se crea una DI a nivel de Z.

### 3.4 Cómo se graba una DI (lo que el proceso tiene que replicar)

`InsertarRegistroMovDet` (`Módulo1.bas:3777`):

```sql
insert into vta_FACOmovdet
  (mov_fecha, mov_local, mov_terminal, mov_tipomov, mov_rol, mov_nombre, mov_secuencia,
   mov_numero, mov_monto, mov_hechopor, mov_regul, mov_fechareg, mov_techkey, mov_cierrey)
values
  (:fecha_venta, :local, :terminal, 'DI', 0, ' ', 0,
   0, round(:monto,2), :usuario, 'S', :fecha_venta, SEQ_VTA_FACOVEN.nextval, :cierrey);
```

- **Una DI por Y:** si ya existe un registro `DI` con `mov_rol = 0` para esa fecha, local, terminal e Y, `Form38` hace un `UPDATE` del monto (`ActualizarRegistroMovDet`, `:399`) en lugar de insertar.
- **Observación:** se guarda en `vta_FACOcompdes.cpd_obs` (`SubUpdateObs`, `Módulo1.bas`). `Form7` la muestra en el informe de Colombia.
- **Fecha contable = fecha de venta:** ya es así (criterio 7).

### 3.5 Signo de la compensación

DR = Dif. de caja − Σ`mov_monto` de las compensaciones (la rama 7 de `StrSumCompensado` incluye `'DI'`). Para que la DR quede en 0, el monto de la DI tiene que ser **igual a la DR, con el mismo signo**:

| DR | DI a grabar | DR después |
|---|---|---|
| −800 (faltante) | **−800** | 0 |
| 15.000 (sobrante) | 15.000 | 0 |

El diagrama del proceso 1 lo dice bien ("Registrar DI = DR con el mismo signo"). El **criterio 1 ("DI por 800") se contradice** con eso (P1).

### 3.6 Validaciones de cierre que aplicaría el proceso 2

Las mismas que documenta `CierreCaja_FACO_Reglas.md`:
- **Y:** RY-01 cheque a fecha, RY-02 estado, RY-03 conceptos pendientes, RY-05 DR = 0, RY-06 ZZZ (opción 103).
- **Z:** RZ-01..09 (incluye Z = ΣY, todas las Y cerradas y dólares con la opción 109).

Precisiones respecto al diagrama del ticket:
- El diagrama menciona "**tarjetas**". La validación de total de tarjetas **no aplica a Colombia** (RY-04/RZ-04 son de ARG/SOAR/SOUY/CHI/CMCL).
- Las validaciones dependen del **perfil**: RZ-01 exime a los perfiles 8, 10 y 12, y RY-06/RZ-08/RZ-09 dependen de las opciones 103/109. Un proceso automático no tiene perfil: **hay que definirlo** (P5).
- Hoy no se graba `ter_fechacierre` para Colombia (solo para Chile). El criterio 1 lo pide: es un cambio de alcance pequeño, pero hay que explicitarlo (P4).

### 3.7 Riesgos heredados del cierre actual (ver `CierreCaja_FACO_Reglas.md` §8)

| Ref. | Riesgo | Impacto en FSCC-12901 |
|---|---|---|
| D1 | La ZZZ de la Y no valida nada (se pasa el local como número de Y) | El cierre automático de Y descuadradas por fórmula ZZZ pasaría. Decidir si se corrige en el proceso |
| D2 | La Z sin Y en `libvta` se deja cerrar | Igual en el proceso automático, si se replica tal cual |
| D7 | El cheque a fecha se compara para todo el día, también al cerrar una Y | Una Y puede quedar bloqueada por cheques de otra Y |
| D12 | Posible doble conteo en `StrSumCompensado` (ramas NP/FT y vendedor-cajero) | **Descartado en test** (§3.11): hay un solo `NP` y un solo `coddif = 1`. Volver a verificarlo en producción |
| — | Sobres PRD sin `prv_cierrey` | La Y queda descuadrada (fuera de rango o compensada con una DI incorrecta) y la Z no |

### 3.8 Cómo se carga hoy la recaudación de Colombia (responde a P6)

La carga del día en Colombia es **`Form133` "Interfaz de Carga Manual de Sobres"** (toolbar `CargaManual`, `MDIForm1.frm:1840`). El analista elige un Excel y presiona Cargar; `Command4_Click` llama a `CargarArchivo` (`Form133.frm:1671`). Para FACO entra por la rama `Else`, que usa la secuencia fija `SEQ_VTA_FACOPRS` (`:1823`). La otra carga, `Form155` ("cargaLGS"), usa `vta_prs_sec` y no graba la Y, así que no es la de Colombia.

**Columnas del Excel** que usa la rama de Colombia (`Grid2`):

| Col. | Dato | Campo en `vta_FACOprd` |
|---|---|---|
| 0 | Local | `prv_local` |
| 1 | Terminal | `prv_terminal` |
| 2 | N° de sobre | `prv_sobre` |
| 3 | Monto del sobre | `prv_montosobre` |
| 4 | Diferencia | `prv_montodif` |
| 5 | N° de recibo | `prv_numrec` |
| 6 | Fecha de venta (`yyyymmdd`) | `prv_fechavta` |
| 7 | **N° de cierre Y** | `prv_cierrey` |

Valores fijos: `prv_tiporec = 'F8'`, `prv_tiposobre = 'EFE'` (todo se carga como efectivo), `prv_fechadep = hoy` y `prv_cod_recaud` = el recaudador elegido en el combo.

**Comportamientos que afectan a la historia:**

| # | Hoy | Consecuencia para FSCC-12901 |
|---|---|---|
| C1 | Por cada sobre cargado, `AbrirTerminal` (`:707`) pone la **Z** en `ter_estado = 0` con `ter_notas = 'CARGA MANUAL DE SOBRES'` (o crea la fila en `termstat`). **No toca `termstaty`** | **Riesgo nuevo (P12):** si una Y ya estaba cerrada y llega un sobre de esa Y, la Y queda Cerrada con DR ≠ 0. El proceso automático solo recorre las Y pendientes, así que no la compensa, y la Z queda bloqueada por RZ-05 (DR de la Z ≠ 0) |
| C2 | El control de duplicados (`existe`, `:777`) busca por `prv_fechavta` + `prv_sobre`, **sin local** | Un sobre con el mismo número en otro local, el mismo día, se descarta sin aviso, y la DR de ese terminal queda mal |
| C3 | El `On Error` está fuera del ciclo: un error a mitad del archivo deja la carga parcial y avisa con un mensaje genérico | El proceso automático tiene que correr **solo si la carga terminó bien**, y sobre lo efectivamente cargado |
| C4 | La carga la ejecuta un analista con sesión abierta (`LOGINUSER`, `PERFILUSER`) | Responde en parte a P5: el proceso puede usar un usuario de proceso fijo (para identificar la DI) y, aun así, registrar quién lanzó la carga |
| C5 | "Terminales de la carga" = las combinaciones (fecha de venta, local, terminal, Y) de las filas de `Grid2` | Es el universo natural que debe recorrer el proceso (o, de forma equivalente, `vta_FACOprd` con `prv_fechadep = hoy` y `prv_cod_recaud` de la carga) |

**Punto de enganche propuesto:** al final de `CargarArchivo`, si `X > 0` y no hubo error, llamar al procedimiento PL/SQL con la lista de (fecha, local, terminal, Y) cargados, o con la fecha de carga. Después, mostrar el resumen. Es el mismo patrón que usa Chile en `Form130`, pero sin silenciar los errores.

### 3.9 Identificación como "automática" y contabilización (responde a P9)

- **Informe de Diferencias (`Form7`):** los listados por concepto leen `mov_hechopor` (`Form7.frm:13484`, `:13992`, `:14124`, `:15251`). Si el proceso graba la DI con un usuario propio (por ejemplo `PROC_DI_AUTO`), **ya queda identificada sin cambiar el informe**.
- **Observación «Compensación automática DI»:** se graba en `vta_FACOcompdes` con `SubInsertarObs` (`Módulo1.bas:3998`), con `cpd_cierrey`. `Form7` la lee con `rownum = 1` y **sin filtrar por Y** (`Form7.frm:9386`, sección vendedor-cajero). Si el terminal tiene observaciones en varias Y, el informe muestra una cualquiera.
- **Envío contable (`Form62`, `LECTURATCOMPEZTXS`, `:3231`):** la DI se lee de `vta_FACOmovdet` agrupando por `mov_fecha` y `mov_local` (`Form62.frm:4391`) y se contabiliza con la fecha de venta. Consecuencias:
  - la DI automática **ya se contabiliza** sin cambios (y con la fecha correcta, criterio 7);
  - pero se **suma** con la DI manual en el mismo asiento. Para "identificarla" en el envío contable hay que cambiar `Form62`: separar la suma por `mov_hechopor`, o usar una glosa o cuenta distinta. Eso tiene impacto contable y hay que acordarlo con Contabilidad (P9).

### 3.10 Lo que agregan las subtareas (FSCC-12957 T1 y FSCC-12958 T2)

| Subtarea | Regla | Contraste con el código / el análisis |
|---|---|---|
| T1 | Base: la DR que muestra hoy la F8, después de las compensaciones manuales ya hechas (dotaciones, billetes falsos, etc.) | ✔ Es exactamente `Label70` de `Form3Y` (`CierreCaja_FACO_Reglas.md` §2). Ojo con D12 (posible doble conteo) |
| T1 | Rango −1.000 ≤ DR ≤ 20.000, inclusivo, DR ≠ 0, parametrizable ("DF fila 57") | ✔ Coincide con la validación de `Form38` sobre 1500/1501 (P2 sigue abierta: ¿mismos parámetros?) |
| T1 | DI = DR con el mismo signo (DR −22 → DI −22) | ✔ Resuelve P1 |
| T1 | Fecha contable = fecha de venta | ✔ Ya es así (`MOV_FECHAREG = mov_fecha`) |
| T1 | Fuera de rango: sin DI, la caja queda pendiente | ✔ |
| T1 | Usuario de proceso + glosa fija, para distinguirla en informes y en el Envío Contable (DUD-052) | ⚠ Informe: ✔ con `mov_hechopor`. Envío contable: requiere cambiar `Form62` (§3.9) |
| T1 | Segunda carga del día: si ya hay DI automática, no se crea otra; queda para el analista (DUD-050) | ⚠ Cubre la DI automática; la DI manual previa sigue abierta (P8) |
| T1 | "No cierra cajas" | ✔ Separación clara: T1 solo graba la DI |
| T2 | Corre después de T1; no crea compensaciones | ✔ |
| T2 | Recorre **cada caja abierta de la carga, incluidas las que ya estaban cuadradas**; cierra solo si DR = 0 y cumple las validaciones de Cerrar Terminal | ✔ Coincide con RY-01..06 / RZ-01..09. Abierto: el perfil para las validaciones que dependen de él (P5) y las Y ya cerradas que reciben sobres (P12) |

**Conclusión:** las subtareas confirman la interpretación del análisis y resuelven P1. P8 y P9 quedan resueltas en parte. Siguen abiertas P2, P3, P4, P5, P9 (envío contable), P11, P12 y P13.

### 3.11 Verificación en la base de test (06-10-2026)

Base `sgfnprds` (Oracle 10.2.0.5), esquema `INTRANETTS`, consultado con el usuario de test y **solo con consultas de lectura**. La base de desarrollo (`intranetde`) no tiene datos recientes ni los parámetros 1500/1501.

**a) Piezas PL/SQL existentes**

| Objeto | Qué es | Uso para FSCC-12901 |
|---|---|---|
| `PKG_F8_FACO_CIERRE_TER_PM_AP` (2022-02-09) | Paquete de Colombia: `CIERRE_TERMINAL(FECHA_PROCESO)`, `VALOR_COMPENSADO(fecha, local, terminal, COD_SECY)` y `VALIDA_CONCEPTO(fecha, local, terminal, tipo, COD_SECY)`. Trabaja **por Y** (`COD_SECY`). No lo llama el exe; se ejecuta desde fuera (no hay jobs visibles para este usuario) | **Base de T2.** Ya cierra Y y Z con `ter_cerradopor = 'AUTOMATICO'`: 556 Y y 117 Z desde 2022 hasta el 23-09-2026. De los terminales Autopago (`ter_tipo = 2`), 166 de 187 tienen cierres automáticos; también el terminal 3016 de muchos locales. Las Y que cierra en test tienen montos en 0. **Su cuerpo no es visible: pedírselo al DBA** |
| `FUN_F8_COMPENSACION_DI_DR` (2025-08-12) | Calcula la diferencia real (`sumaBZ − compensado`) en PL/SQL. Si falla, devuelve 1 (para no cerrar). Usa `FUN_F8_COMPENSACION_DI_PRD` para los sobres | **Plantilla de la función de diferencia real de T1.** Es la versión de **Chile**: hay que adaptarla a Colombia (ver tabla b) |
| `FUN_F8_COMPENSACION_DI_PRD` (2019) | Suma de `prv_montosobre + prv_montodif` de `vta_prd` (`F8`, por tipo de sobre) | Adaptar a `vta_FACOprd` + `prv_cierrey` |
| `FUN_F8_COMPENSACION_DI` (2019) | Diferencia de dólares (`recmex` 305 contra `prd` DOL), igual que RZ-09 | Referencia para RZ-09 |
| `PKG_F8_COMPENSACION_DI` (2019) | Chile: `CIERRE_TERMINAL_DI`, `CARGA_BILLETE_FALSO`, `VALIDA_LOCAL`, `VALIDA_MOVDET` | Precedente funcional. Cuerpo no visible |

**b) Qué hay que cambiar en `FUN_F8_COMPENSACION_DI_DR` para Colombia** (comparada con `CierreCaja_FACO_Reglas.md` §2):

| Aspecto | Versión actual (Chile) | Lo que necesita Colombia |
|---|---|---|
| Tablas | `vta_movdet`, `vta_libvta`, `vta_prd`, … | `vta_FACO*` |
| Nivel | Z (`vta_tiporeg = 'F8'`, sin Y) | **Y** (`'Y'` + `vta_secuencia` / `*_cierrey`) y, aparte, Z |
| Tarjetas | `vta_tarj` sin filtro de código | Códigos **2000–2999** |
| Tarjetas declaradas | `rec_mtarj` | `rec_mtarj + rec_msodimac` |
| Vendedor-cajero | `VEN_REGUL = 'S'` (regla de Chile) | **Sin** `VEN_REGUL` |
| `CA` en `movdet` | Excluido | **Incluido** (Colombia sí lo suma, además de `cartaaviso`) |
| Rama `AL` | Sin cruce con `libvta` | Cruce con `libvta`/`zzz` por `mov_secuencia` |
| Dólares | Calcula `tesDol` pero suma `totDol = 0` (**no** suma los USD) | Sumar los USD de `recmex` 305 (`+ totDol = tesDol`), como la F8 |
| Redondeo | Sin redondeo | `round(…, decimales de gFormat)` |

**c) Datos y estructura**

| Tema | Resultado | Impacto |
|---|---|---|
| Rango DI (P2) | `vta_FACOparam` 1500 `DI` = **−500**, 1501 `DI` = **20.000** | La historia pide −1.000. Reutilizar el parámetro **cambia también el límite de la DI manual**. Si no se quiere, crear códigos nuevos (por ejemplo 1500/1501 con código `'DIA'`) |
| Doble conteo D12 | Un solo `NP` (sin `FT`) y un solo `coddif = 1` (`VC`) | **Descartado** |
| Concepto DI | `vta_FACOconcepdif`: coddif 8, "Diferencia no Imputable" | Se usa tal cual |
| Varias DI por Y | Hay DI con `mov_rol` 45 a 62, además de `mov_rol = 0` | La "única" DI es la de `mov_rol = 0`. Para P8, revisar **todas** las DI de la Y, no solo `mov_rol = 0` |
| Columnas NOT NULL de `movdet` | `MOV_NOMEMPLEADO` y `MOV_EMPEMPLEADO` tienen default; `MOV_REGUL` default `'N'` y `MOV_CIERREY` default 0 | El INSERT de §3.4 funciona. Hay que informar **siempre** `mov_cierrey` (si no, queda en 0 y la DI no cuenta para la Y) |
| Fecha de cierre (P4) | `vta_FACOtermstat` y `vta_FACOtermstaty` **no tienen** `ter_fechacierre` (solo `ter_notas` 2500 y `ter_cerradopor` 50) | El criterio 1 ("fecha de cierre") requiere **DDL** (columna nueva en ambas tablas), o bien usar `ter_notas` |
| Observación | `vta_FACOcompdes.cpd_obs` VARCHAR2(1024) con `cpd_cierrey` | Sirve para la glosa fija «Compensación automática DI» |
| Universo de Z | Cada día hay unas **2.180 Z** precreadas en `-1`, pero solo 0 a 10 con libro de ventas | El proceso tiene que recorrer **solo las cajas con venta o de la carga**, nunca todas las pendientes |
| Y sin libro de ventas | Hay Y pendientes sin fila en `libvta` (por ejemplo 23-09: 19/12, 2000/3462, 3000/3001) | Sin Y declarada no hay diferencia real: excluir y registrar "sin datos de la Y" |
| Prueba de la fórmula | Y pendientes de 183/953 (04 y 07-09-2026), sin sobres cargados: diferencias de −4.218.659, +1.417.438, +4.041.760 y −678.030 | Coincide con el negocio: sin sobres, la diferencia queda fuera de rango. La fórmula del documento se puede ejecutar en la base tal cual |
| Carga de sobres | En test, la última carga es de 2022 (recaudador `00234`), y todos los sobres tienen `prv_cierrey` | Para probar T1/T2 en test hay que **cargar sobres nuevos** con `Form133` (o insertarlos para la prueba) |

### 3.12 Diagramas BPMN del requerimiento contra el código

Fuente: `docs/Requeriemintos-FSCC-12901/` (Flujo general, Proceso 1 y Proceso 2).

**Flujo general.** Tiene cinco carriles: el analista de tesorería, la carga del archivo, T1, T2 y los datos.

| Paso del diagrama | ¿Existe hoy? | Comentario / qué hay que hacer |
|---|---|---|
| Analista: "Cargar el archivo de recaudación del día" | ✔ `Form133` (Excel) | Punto de inicio confirmado (§3.8) |
| "Validar y grabar la recaudación" → **¿Carga correcta? No → carga rechazada: no se ejecutan las tareas** | ⚠ Parcial | Hoy `CargarArchivo` graba sobre por sobre, y un error a mitad del archivo deja una **carga parcial** (§3.8, C3). Para cumplir el diagrama hay que **validar todo el archivo antes de grabar** (o grabar en una sola transacción) y no lanzar T1/T2 si hubo error (**N2**) |
| "Recalcular la cuadratura y **reabrir las cajas que cambian** (vigente)" | ⚠ **No coincide** | El diagrama lo marca como comportamiento vigente, pero `AbrirTerminal` (`Form133.frm:707`) solo reabre la **Z** (`termstat`), **no las Y** (`termstaty`). La cuadratura no se guarda: se calcula al vuelo. Una Y cerrada que recibe un sobre queda cerrada con diferencia (P12). Si negocio confirma "reabrir las cajas que cambian", **hay que modificar la carga para reabrir también la Y del sobre** (**N3**) |
| "Iniciar las tareas con el alcance de la carga" | ✖ Nuevo | Universo = cajas de la carga (§5 de los PDF) |
| T1: "Leer configuración: **T1 activa** y rango" → ¿T1 activa? | ✖ Nuevo | **Interruptor nuevo** por parámetro: T1 se puede apagar sin cambiar código (**N1**) |
| T2: "¿**T2 activa**?" | ✖ Nuevo | Segundo interruptor, independiente (**N1**). Si T1 está apagada, T2 igual puede correr |
| "Consolidar: compensadas, cerradas, pendientes y errores" → "Mostrar el resumen" | ✖ Nuevo | Tabla de log ("Registro de ejecución (nuevo)", confirmado en el diagrama) + formulario de resumen |
| Analista: "Revisar el resumen" → ¿excepciones? → "Gestionar a mano: reabrir, compensar, Cerrar Terminal" | ✔ Pantallas existentes | Reabrir: `Form20`; compensar: `Form4` → `Form38`; cerrar: `Form3Y`/`Form3`. El resumen tiene que dar fecha, local, terminal, Y y motivo para poder ir a esas pantallas |
| Datos: Recaudación, Configuración del negocio, Cuadratura de cajas, Compensaciones, Estado de cajas, Registro de ejecución (nuevo) | ✔ / ✖ | `vta_FACOprd`; `vta_FACOparam`; cálculo de DR; `vta_FACOmovdet`/`compdes`; `vta_FACOtermstat[y]`; **tabla nueva** de log |

**Proceso 1 (T1).** Coincide con el diseño de §5. Precisiones:

| Elemento del diagrama | Observación |
|---|---|
| Inicio "Terminal-día **o** cierre Y" | En Colombia siempre es **cierre Y**: la DI no se registra a nivel Z (§3.3). Conviene ajustar el texto del diagrama (P3) |
| ¿DR = 0? Sí → "Sin DI: pasa al Proceso 2" | ✔ (log `DR_CERO`) |
| ¿−1.000 ≤ DR ≤ 20.000? (VTA_FACOPARAM) No → "Log: fuera de rango" → "Pendiente: gestión de tiendas" | ✔ |
| ¿Ya tiene DI automática de una carga anterior? Sí → "Pendiente: revisión (DUD-050)" | ✔ Detectar por `mov_hechopor = usuario de proceso` |
| "Registrar DI = DR con el mismo signo; fecha contable = fecha de venta; usuario de proceso" → "Log: compensado" | ✔ (§3.4) |
| **Ramas que faltan en el diagrama** | (a) **DI manual previa** en la Y (P8): hoy grabar otra DI con `mov_rol = 0` la sobrescribiría; (b) **Y sin libro de ventas**: no hay DR calculable; (c) **error técnico** al grabar o recalcular. Proponemos agregarlas (**N4**) |

**Proceso 2 (T2).** Coincide con el diseño de §5. Precisiones:

| Elemento del diagrama | Observación |
|---|---|
| Inicio "incluye los que ya tenían DR 0" | ✔ Universo T2 = todas las cajas abiertas de la carga |
| "Validaciones de Cerrar Terminal: conceptos por regularizar, **tarjetas**, monto por compensar, suma Y = Z, Y abiertos" | La validación de **tarjetas no aplica a Colombia** (solo ARG/SOAR/SOUY/CHI/CMCL, RY-04/RZ-04). Faltan en la lista: **cheque a fecha** (RY-01/RZ-01), **estado Impreso/Sin datos** (RY-02), **ZZZ** (103) y **dólares** (109). "Suma Y = Z" e "Y abiertos" son validaciones **de la Z**, no de la Y |
| "Cerrar terminal o cierre Y: estado cerrado, cerrado por **usuario de proceso**, **fecha y nota**" | **Usuario de proceso:** resuelve en parte P5 para `ter_cerradopor`. **Nota:** `ter_notas` VARCHAR2(2500) existe en ambas tablas. **Fecha:** no hay columna, así que puede ir dentro de la nota (por ejemplo `'CIERRE AUTOMATICO FSCC-12901 06-10-2026 10:15'`). Así P4 se resuelve **sin DDL**, salvo que se pida columna |
| "¿Cierre Y y todas las Y cerradas? Sí → Cerrar el terminal-día (Z)" | ⚠ El diagrama cierra la Z **directamente** al cerrar la última Y. En el sistema, la Z tiene **validaciones propias** (RZ-05 DR de la Z, RZ-06 Z = ΣY, RZ-07, RZ-09) que pueden fallar aunque todas las Y estén en 0. Proponemos que el paso "Cerrar el terminal-día" ejecute las RZ antes de cerrar y, si fallan, deje log "Z pendiente con motivo" (**N5**) |
| Sin rama de error técnico / caja ocupada por otro usuario | Proponemos agregar "Log: error / ocupada" (**N4**) |

**Nuevos puntos derivados de los diagramas (N1–N5)**

| ID | Punto | Propuesta |
|---|---|---|
| N1 | Interruptores **T1 activa** / **T2 activa** | Dos parámetros nuevos en `vta_FACOparam` (por ejemplo tipo 1502, códigos `'DIA_T1'` y `'DIA_T2'`, valor `S`/`N`; el tipo 1502 está libre en test) |
| N2 | Carga correcta o rechazada | Validar el Excel completo antes de insertar (duplicados, locales y terminales existentes, Y informada, montos) y grabar todo o nada. T1/T2 solo corren si la carga fue completa |
| N3 | "Reabrir las cajas que cambian" | Si se confirma, `AbrirTerminal` también tiene que reabrir la **Y** del sobre (`termstaty`), no solo la Z. Resuelve P12. Ojo: reabrir una Y con DI automática previa lleva a "revisión del analista" en T1 |
| N4 | Ramas faltantes | Agregar a los diagramas: DI manual previa, Y sin libro de ventas, error técnico y caja ocupada |
| N5 | Cierre de la Z | Validar las RZ antes de cerrar la Z; si fallan, queda la Z pendiente con motivo |

### 3.13 Documento funcional DF-SCC y archivo PRD 3 (06-10-2026)

Fuentes: `docs/Requeriemintos-FSCC-12901/DF-SCC-vf_Falabella CO (MEJORAS F8 y COMPENSACIONES MENORES).xlsx` y `PRD 3.xlsx`, leídos en modo solo lectura.

**DF-SCC, hoja "F8-LV-CMP-TES"** (las hojas SCC, Estructuras, Backbone y Enriquecimiento son plantillas vacías):

| Fila | Pedido | Relación con FSCC-12901 |
|---|---|---|
| 12 | "No muestran las cajas sin movimiento (Dif. Real en 0)… validando en F8 Chile si se puede dar cierre a la terminal. Considerando el cierre automático de terminales con diferencia real 0". Pantalla: Cierre de cajas. Objetivo: **evitar el archivo "dataload" de cierre de cajas**. Imágenes 6 y 7 ("IMAGEN F8 COLOMBIA" / "F8 CHILE") | **Dentro**: es `Form43` (Consultas de Cuadratura) + T2. Confirma los hallazgos B1–B5 de `CC_ConsultaCuadratura_FACO.md`: en FACO `SubBuscarOpcion` solo agrega filas con DR ≠ 0 (`Form43.frm:1129`) y "Cerrar Terminal" no cierra nada; Chile (`SubBuscarOpcionSOAR_SOUY`) muestra todas las filas y cierra. La imagen de Colombia muestra además el botón visible sin permiso (B4) |
| 57 | DI automática "hasta −1.000 faltante e inferior a 20.000 sobrante" | **Dentro** (= T1). "Faltante" = DR negativa: el signo de la DI coincide con la DR. "Inferior" sugiere límite exclusivo; la respuesta de negocio del 01-10 dice inclusivo. Se mantiene inclusivo y configurable (`CA_DI_MIN` / `CA_DI_MAX`) |
| 34, 40, 46, 52 | ECOMPAY en la Y, cuenta bancaria, control de bancos, fecha contable del envío a SAP | **Fuera** de FSCC-12901. Solo se documentan |

**PRD 3.xlsx:** archivo real de carga de `Form133`, con las 8 columnas de §3.8. 486 sobres, 27 locales, fecha de venta 20260828, cierre Y = 1 en todos, 357 cajas, sin diferencias, sin duplicados y sin sobres sin Y. Conclusiones: el volumen de una carga es manejable para el proceso, y **las cajas que no reciben sobres no aparecen en el archivo**, así que nunca entraban a la cola del trigger.

**Decisiones del usuario (06-10-2026):**
1. `Form43` en FACO **delega en la base**: columnas con funciones del paquete de T2 y "Cerrar Terminal" con un procedimiento del mismo paquete.
2. **Incluir las cajas sin sobres** del mismo local y fecha de venta de la carga, con un parámetro.
3. **Sin pantalla de resumen** (se consulta por SQL).
4. Las otras filas del DF **solo se documentan**.

**Ajustes realizados:**

| Capa | Ajuste |
|---|---|
| Base (T2) | Vista `VTA_FACOV_CAJAS_CIERRE` (COLA + SIN_SOBRE) y parámetro `CA_SIN_SOBRE`; `pr_cuadratura` (misma fórmula, `fn_dif_real` no cambia) con `fn_dif_caja` y `fn_compensado` públicas; `prc_cierre_rango` para `Form43` (`log_proceso` CC, `ter_cerradopor` = analista, sin T1 y sin depender de `CA_ACTIVO`); `prc_cierre_automatico` recorre la vista y resume cerradas / no cerradas |
| Base (T1) | `prc_compensa_di` recorre la vista: las cajas sin sobres con DR en rango también reciben la DI automática |
| Base (permisos) | La opción 1515 "Cerrar Terminal desde Consulta Cuadratura" **no existía en FACO** (sí en Chile, SOAR y SFCL): `03c_permiso_cc.sql` la crea deshabilitada |
| Front | `Form43.frm` (solo FACO): B1–B6 de `README_FSCC-12901.md` §5c |

Riesgo nuevo: mostrar las columnas con funciones PL/SQL hace que `Form43` calcule la cuadratura en la base por cada fila (tres llamadas por fila). Para un local y un día son decenas de filas; con rangos largos o "todos los locales" puede ser lento. Si ocurre, conviene agregar al paquete una función que devuelva las tres columnas en una sola llamada (por ejemplo, un texto `caja|compensado|dr` armado con `pr_cuadratura`) y que `SubBuscarOpcionFACO` lo separe.

### 3.14 Documentación actualizada (07-10-2026) y modelo "solo cierre Y"

Fuente: `docs/Requeriemintos-FSCC-12901/Doc-Actualizado/`.

**Qué cambió en los documentos:**

| Archivo | Cambio |
|---|---|
| `FSCC-12901.doc` (HU, actualizada el 06-10) | 1) "Este paso se debe ejecutar **al momento de realizar la carga** del archivo con la recaudación"; en los comentarios: "Consultar con el negocio en qué parte cargan ese archivo… resuelto: **es en esa pantalla**" (`Form133`, botón Cargar Archivo, `image-20261006-203210.png`). 2) "**Colombia opera con cierre Y**: la evaluación se hace por cierre Y y por Z". 3) **CA9 nuevo**: "Se registra DR = 0 por el proceso de imputación automática → ejecutar la validación de cierre de caja y el cierre de caja automático". 4) Se mantienen el resumen del proceso, los terminales sin sobres, la fecha contable = fecha de venta y el rango inclusivo |
| `FSCC-12957 (1).doc` / `FSCC-12958 (1).doc` | El texto es igual al del 05-10; solo cambian el asignado (ext_nruz) y la fecha |
| `image-20261005-180633.png` (= `…182457.png`) | Proceso 1 rediseñado; misma lógica. "¿Ya compensada en otra carga?" = `DI_AUTO_PREVIA` |
| `image-20261005-183728.png` | Proceso 2 rediseñado: todavía dice "¿Cierre parcial (Y) y todos los del día cerrados? → Cerrar el terminal del día" |
| `image-20261006-203210.png` | `Form133` ("Interfaz de Carga Manual de Sobres") con el botón **Cargar Archivo** marcado y el archivo PRD 3 cargado en la grilla |
| DF-SCC, PRD 3, imágenes 133648 / 133731 | Idénticos (MD5) a los ya analizados |

**Verificación en el código y en test:**
- `Form3Y.CierraTerminal` (`Form3Y.frm:2801`) solo hace `update vta_FACOtermstaty set ter_estado = '1'`. Ninguna rama `FACO` usa `Form3.CierraTerminal` (Z).
- En test, con fecha de venta desde el 24-08-2026:
  - `vta_FACOtermstat` tiene 10.894 filas en −1 y solo 6 cerradas;
  - de las Y, 6 están cerradas por `AUTOMATICO` y 7 siguen en −1.

  En Colombia la Z no se gestiona.

**Revisión de `Form133` (y `Form133.frx`):**
- **`Command4_Click` (Cargar Archivo)** → `CargarArchivo` (`Form133.frm:1671`, rama `Else`, que es la de FACO). Por cada fila del Excel:
  - si el sobre no existe (`existe`: sobre + fecha de venta), hace `insert into vta_FACOprd` con `SEQ_VTA_FACOPRS`, `prv_tiporec 'F8'`, `prv_tiposobre 'EFE'`, monto (col. 3), diferencia (col. 4), recuento (col. 5), fecha de venta (col. 6, `yyyymmdd`), `prv_cierrey` (col. 7) y el recaudador del combo;
  - después llama a `AbrirTerminal`.
- **`AbrirTerminal`** (`:707`): reabre (`ter_estado = 0`) o crea la **Z** en `vta_FACOtermstat` con la nota 'CARGA MANUAL DE SOBRES'. **No toca la Y.**
- **Sin transacción:** un error a mitad deja la carga parcial (riesgo N2). La grilla de columnas sale de `VTA_HOMOLOGA_PRD` (`CargaLista`).
- **`Form133.frx`** (8.182 bytes): solo recursos gráficos.
  - Contiene el ícono del formulario (`:0000`) y 4 metarchivos WMF de la cabecera (`:030A` `Picture1`, `:194E` `Image3`, `:1C3A` `Image2`, `:1F1E` `Image1`).
  - No tiene lógica, listas de combos ni datos.
  - `Form133.log` solo informa OCX faltantes en el IDE (`MSFlexGrid`, `CommonDialog`).

**Decisiones del usuario (07-10-2026):**
1. **Solo cierre Y**: el proceso cierra únicamente `vta_FACOtermstaty` y **no toca la Z**. Se eliminan las reglas RZ, `pr_procesa_z`, `pr_valida_z`, `fn_msg_z_suma_y`, `fn_msg_y_abiertas`, `fn_dif_dolares` y `CA_VAL_USD`. `fn_dif_real`, `fn_dif_caja` y `fn_compensado` exigen la Y. `prc_cierre_rango` y `Form43` trabajan solo con Y.
2. **Disparo: se mantiene el job externo** (cola + trigger); `Form133` no llama al SP.
3. **Sin resumen en pantalla** (log por SQL).
4. **`Form133.AbrirTerminal` no se toca.**

**Diferencias con la HU que quedan abiertas con negocio:**
- La HU pide ejecutar "al momento de la carga" y "emitir un resumen". Se resolvió con un job, que debe agendarse justo después de la carga, y con una consulta SQL del log.
- El diagrama P2 todavía dice "cerrar el terminal del día"; con la decisión 1 no se hace.
- CA1 menciona la "fecha de cierre": queda en `ter_notas`, porque no existe la columna.

**CA9:** ya está cubierto. T1 corre dentro de `prc_cierre_automatico` antes del cierre, y T2 recalcula la DR de la misma Y en la misma ejecución.

---

## 4. Preguntas e inconsistencias para el refinamiento

| ID | Tema | Pregunta / propuesta |
|---|---|---|
| P1 | Signo (criterio 1) | **Resuelta en FSCC-12957:** "la DI es igual a la Diferencia Real, con el mismo signo: DR −22 genera DI −22". Solo falta corregir el texto del criterio 1 de la historia ("DI por 800" → "DI por −800") |
| P2 | Parámetro | En test ya existen `vta_FACOparam` 1500 `'DI'` = **−500** y 1501 `'DI'` = **20.000** (rango de la DI manual). La historia pide −1.000. ¿Se cambia el límite inferior para ambos (manual y automático) o se crean códigos propios para el proceso automático? |
| P3 | Nivel Y / Z | En Colombia la DI solo se registra por Y. Las subtareas hablan de "caja" sin precisar si es la Y o el terminal-día. Proponemos: "caja" = **cierre Y** para T1 (compensar); T2 cierra primero las Y y luego la Z, que solo se valida y se cierra y queda Pendiente con motivo si su DR ≠ 0. ¿Están de acuerdo? |
| P4 | Fecha de cierre | El criterio 1 pide "fecha de cierre", pero `vta_FACOtermstat` y `vta_FACOtermstaty` **no tienen** columna `ter_fechacierre` (verificado en test). El diagrama del proceso 2 dice "fecha y nota": **propuesta sin DDL** → grabar en `ter_notas` un texto con la fecha y hora del cierre, más el log. ¿Alcanza, o se exige columna? |
| P14 | Paquete existente | `PKG_F8_FACO_CIERRE_TER_PM_AP` ya cierra Y y Z de Colombia como `AUTOMATICO` (§3.11). ¿Quién lo ejecuta y cuándo? ¿T2 lo extiende (recomendado) o se hace un proceso nuevo? Necesitamos su cuerpo (DBA) |
| P5 | Usuario y perfil del proceso | La carga la lanza un analista con sesión (§3.8, C4). Propuesta: grabar la DI y el cierre con un **usuario de proceso fijo** (identifica lo automático, P9) y evaluar las validaciones que dependen del perfil con el **perfil del analista que lanzó la carga**. ¿De acuerdo? |
| P6 | Disparador | **Respondida por el código:** la carga del día en Colombia es `Form133` (Carga Manual de Sobres desde Excel, §3.8). Propuesta: ejecutar el proceso al terminar una carga exitosa, sobre los terminales cargados. ¿Se quiere además un botón para relanzarlo manualmente? |
| P7 | Criterio 9 | Redacción confusa. Proponemos: "Dado un terminal-día/Y con DR = 0 (sin necesidad de DI), cuando se ejecuta el proceso, entonces se aplican las validaciones de cierre y se cierra si se cumplen" |
| P8 | DI previa | **Resuelta en parte (FSCC-12957, propuesta DUD-050):** si la caja ya tiene una DI **automática**, no se crea otra y queda para revisión del analista. **Sigue abierto:** qué hacer si tiene una DI **manual**. Hoy hay una sola DI por Y (`mov_rol = 0`) y grabar otra la **sobrescribiría** (`ActualizarRegistroMovDet`). Proponemos tratarla igual: no tocarla y dejarla para revisión |
| P9 | Identificación "automática" | **Resuelta en parte (FSCC-12957, DUD-052):** usuario de proceso + **glosa fija**, "para distinguirla en los informes y en el Envío Contable". En el Informe de Diferencias basta con el usuario de proceso (`mov_hechopor`). **Sigue abierto:** el envío contable (`Form62`) **suma** la DI por fecha y local junto con la manual (§3.9). Para que la glosa se vea ahí hay que cambiar la agrupación de `Form62` (línea aparte para la DI automática). Confirmar con Contabilidad |
| P10 | Excel adjunto | El análisis no incluye `DF-SCC-vf_Falabella CO (MEJORAS F8 y COMPENSACIONES MENORES).xlsx`. Revisar si agrega reglas |
| P11 | DR ≠ 0 por redondeo | La DR se redondea con `gFormat` (D9). ¿Una DR de 0,4 cuenta como 0, o se compensa? |
| P12 | Y ya cerrada que recibe sobres | La carga reabre la **Z**, pero no la **Y** (§3.8, C1). El diagrama general dice "reabrir las cajas que cambian (vigente)", pero en el código eso **no** pasa con las Y (§3.12, N3). Propuesta: que la carga reabra también la Y del sobre. ¿Se incluye en el alcance? |
| P13 | Duplicados en la carga | El control de sobres repetidos de `Form133` no considera el local (§3.8, C2). ¿Se corrige como parte de esta historia? Afecta directamente a la DR que se compensa |

---

## 5. Propuesta técnica

### 5.1 Componentes

1. **Paquete PL/SQL para Colombia.** Recomendado: **extender `PKG_F8_FACO_CIERRE_TER_PM_AP`**, que ya cierra Y y Z de Colombia y ya tiene `VALOR_COMPENSADO` y `VALIDA_CONCEPTO` por Y (§3.11). La alternativa es un paquete nuevo (por ejemplo `PKG_F8_COMPENSACION_DI_FACO`). Componentes:
   - `fn_dif_real(fecha, local, terminal, cierrey)`: §2 de `CierreCaja_FACO_Reglas.md`, partiendo de `FUN_F8_COMPENSACION_DI_DR` con los cambios de §3.11 b.
   - `pr_registrar_di(...)`: `INSERT`/`UPDATE` en `vta_FACOmovdet` + observación en `vta_FACOcompdes` (§3.4).
   - `pr_validar_y` / `pr_validar_z`: reglas RY/RZ en el mismo orden y con el mismo mensaje.
   - `pr_proceso_auto(fecha_carga)`: orquestación y resumen.
2. **Tabla de log/resumen** (nueva), por ejemplo `vta_FACOlog_cierre_auto`, con:
   - id de ejecución, fecha, local, terminal, Y (null = Z);
   - DR antes y después, monto de DI;
   - resultado (`COMPENSADO_CERRADO`, `CERRADO`, `FUERA_RANGO`, `BLOQUEADO`, `DI_PREVIA`, `ERROR`), código de regla y mensaje;
   - usuario, fecha y hora.
3. **Parámetros** en `vta_FACOparam` (según P2).
4. **Integración en VB:** llamada al final de la carga del día (según P6) y una pantalla o Excel con el resumen (puede reutilizar `GeneraCualquierExcel`).

### 5.2 Algoritmo

```
para cada (fecha, local, terminal, Y) de la carga con termstaty.ter_estado in (-1, 0):
    bloquear fila termstaty (FOR UPDATE NOWAIT)
    dr := fn_dif_real(...)
    si dr <> 0:
        si no (rango_min <= dr <= rango_max):  log FUERA_RANGO; continuar
        si existe DI automática previa en la Y:  log DI_PREVIA; continuar        -- P8
        pr_registrar_di(monto = dr, usuario proceso, obs 'Compensación automática DI')
        dr := fn_dif_real(...)                                                   -- recalcular
        si dr <> 0: log QUEDA_CON_DIFERENCIA; rollback; continuar
    pr_validar_y(...)  -> si falla: log BLOQUEADO (regla, mensaje)
                          ¿mantener la DI aunque la Y no cierre? (decidir)
    update termstaty set ter_estado='1', ter_cerradopor=usuario proceso
    commit; log CERRADO / COMPENSADO_CERRADO

para cada (fecha, local, terminal) de la carga con termstat.ter_estado in (-1, 0):
    si todas sus Y están cerradas:
        dr_z := fn_dif_real(..., cierrey = null)
        si dr_z <> 0: log Z_CON_DIFERENCIA; continuar                            -- P3
        pr_validar_z(...) -> si falla: log BLOQUEADO
        update termstat set ter_estado='1', ter_cerradopor=..., ter_fechacierre=sysdate?   -- P4
        commit; log CERRADO
```

**Decisión pendiente:** si la Y se compensa pero no pasa las validaciones de cierre (por ejemplo, un SN pendiente), ¿se mantiene la DI grabada o se revierte? Proponemos **mantenerla**, para que el analista vea la Y ya cuadrada y solo tenga que resolver el bloqueo. Además, es lo que pasaría si el analista lo hiciera a mano.

### 5.3 Transacciones

- Una transacción **por Y** y otra por Z, para que un error no afecte al resto de la carga.
- El log se graba con `PRAGMA AUTONOMOUS_TRANSACTION`, para que quede registrado aunque se haga rollback.

---

## 6. Casos de prueba

Basados en los criterios del ticket y en la matriz de `CierreCaja_FACO_Reglas.md` §10:

| # | Caso | Esperado | CA |
|---|---|---|---|
| T1 | Y con DR −800, sin pendientes | DI −800, DR 0, Y cerrada; si todas las Y cierran, también la Z | 1 |
| T2 | DR = −1.000 y DR = 20.000 | Se compensa y se cierra | 2 |
| T3 | DR = −1.001 y DR = 20.001 | Sin DI, Pendiente, resumen "fuera de rango" | 3 |
| T4 | DR en rango + SN pendiente en la Y | DI grabada (según decisión), Y Pendiente, resumen "Falta regularizar el Sobres No Enviado…" | 4 |
| T5 | DI automática vista en `Form7` y en el envío contable | Identificada como automática | 5 |
| T6 | Cambiar 1500/1501 (o el parámetro nuevo) | La siguiente ejecución usa el valor nuevo | 6 |
| T7 | Venta 28-09 procesada el 30-09 | `mov_fecha` = `mov_fechareg` = 28-09 | 7 |
| T8 | Y sin sobres con DR en rango | Se compensa igual | 8 |
| T9 | Y con DR = 0 | Sin DI; se valida y se cierra | 9 |
| T10 | Y con DI manual previa y DR ≠ 0 | Según P8 | — |
| T11 | Todas las Y cerradas, pero Z ≠ ΣY | Z Pendiente, resumen RZ-06 con la glosa | — |
| T12 | Z con DR ≠ 0 y todas las Y en 0 | Z Pendiente, "Z con diferencia" (sin DI en la Z) | — |
| T13 | Gestión de cheques a fecha ≠ tesorería | Y bloqueada por RY-01 | — |
| T14 | Dos ejecuciones seguidas sobre la misma carga | La segunda no duplica la DI ni cambia lo ya cerrado | — |
| T15 | Error de base a mitad de la carga | Se hace rollback solo de esa Y; el resto se procesa; el log registra ERROR | — |
| T16 | Y ya cerrada recibe un sobre en la carga del día | Según P12; como mínimo, aparece en el resumen como "Y cerrada con diferencia" | — |
| T17 | Carga de Excel con error a mitad del archivo | El proceso automático no se ejecuta, o solo procesa lo cargado (§3.8, C3) | — |
| T18 | Dos sobres con el mismo número y fecha en locales distintos | Según P13 | — |

---

## 7. Comentario sugerido para Jira

> Revisamos la HU contra el código actual del F8 (VB6) y la lógica de cierre de Colombia. La HU es viable y reutiliza piezas existentes:
> - Chile ya tiene un proceso equivalente: `pkg_f8_compensacion_di.cierre_terminal_di`, que se llama desde la Interfaz de Validación después de cargar el PRD.
> - La DI manual de Colombia ya se valida contra `vta_FACOparam` 1500/1501 (código 'DI').
> - La DI ya se registra con fecha contable = fecha de venta (CA7 cubierto).
>
> Para cerrar el refinamiento necesitamos confirmar:
> 1. **CA1:** corregir el texto a "DI por −800". La subtarea T1 ya define el mismo signo (DR −22 → DI −22).
> 2. **Parámetro:** hoy (test) `vta_FACOparam` 1500/1501 'DI' = −500 / 20.000 es el rango de la DI manual. La HU pide −1.000. ¿Cambiamos el límite para ambos o creamos códigos propios para el proceso automático?
> 3. **Y / Z:** en Colombia la DI solo se registra por Y. Proponemos compensar por Y; la Z solo se valida y se cierra (Pendiente con motivo si tiene diferencia).
> 4. **Fecha de cierre (CA1):** las tablas de estado de Colombia (`vta_FACOtermstat` / `termstaty`) no tienen columna de fecha de cierre. ¿Se agrega (DDL) o basta con el log del proceso?
> 5. **Usuario y perfil del proceso:** proponemos un usuario de proceso fijo para `mov_hechopor` / `ter_cerradopor`, y evaluar las validaciones que dependen del perfil con el perfil del analista que ejecuta la carga.
> 6. **Disparador:** la carga diaria de Colombia es la "Interfaz de Carga Manual de Sobres" (Excel). Proponemos ejecutar el proceso al terminar una carga exitosa. ¿Se necesita también un botón para relanzarlo?
> 7. **DI manual previa:** T1 define qué hacer con una DI automática previa (DUD-050), pero no con una manual. Hoy grabar la DI automática sobrescribiría la manual (hay una sola DI por Y). ¿La dejamos para revisión del analista, igual que la automática?
> 8. **Identificación "automática":** en el Informe de Diferencias queda identificada por el usuario de proceso. El envío contable suma la DI por fecha y local junto con la manual. ¿Qué se espera ver ahí (línea separada, glosa, otra cuenta)?
> 9. **CA9:** redacción a aclarar.
> 10. Si la Y se compensa pero no pasa las validaciones de cierre, ¿se mantiene la DI?
>
> 11. **Y ya cerrada que recibe sobres en la carga:** hoy la carga reabre la Z pero no la Y, así que esa Y queda cerrada con diferencia y bloquea la Z. ¿El proceso la reabre y la recompensa, o solo la informa?
> 12. **Duplicados:** la carga descarta sobres repetidos por fecha y número de sobre sin mirar el local. ¿Se corrige en esta HU?
>
> 13. **Cierre automático existente:** en la base ya existe `PKG_F8_FACO_CIERRE_TER_PM_AP`, que cierra Y y Z de Colombia como 'AUTOMATICO' (principalmente Autopago). ¿Quién lo ejecuta y con qué frecuencia? Proponemos que T2 lo extienda en lugar de crear otro proceso.
>
> 14. **Diagrama general, "reabrir las cajas que cambian (vigente)":** hoy la carga reabre solo la Z, no la Y. ¿Se incluye en el alcance reabrir la Y que recibe sobres?
> 15. **Diagrama general, "Carga rechazada":** hoy la carga puede quedar parcial si falla a mitad del archivo. ¿La carga debe pasar a ser todo o nada?
> 16. **Diagrama del proceso 2:** la validación de "tarjetas" no aplica a Colombia. Al cerrar la Z faltan sus validaciones propias (diferencia de la Z, Z = suma de Y, dólares). Proponemos que el cierre de la Z las ejecute y, si fallan, quede pendiente con motivo.
> 17. **Diagramas, ramas faltantes:** DI manual previa, Y sin libro de ventas, error técnico y caja ocupada por otro usuario.
> 18. **Interruptores T1 activa / T2 activa:** proponemos parámetros `vta_FACOparam` tipo 1502, códigos 'DIA_T1' / 'DIA_T2' (S/N).
>
> Pendiente técnico: solicitar al DBA el cuerpo (PACKAGE BODY) de `PKG_F8_FACO_CIERRE_TER_PM_AP` y `PKG_F8_COMPENSACION_DI` (no son visibles con el usuario de test). La función `FUN_F8_COMPENSACION_DI_DR` (cálculo de diferencia real, Chile) sirve de base para T1. Verificado en test: no hay doble conteo en el cálculo de compensaciones.
