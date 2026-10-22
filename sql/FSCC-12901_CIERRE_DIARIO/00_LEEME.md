# FSCC-12901 CIERRE_DIARIO: cierre diario de cajas sin diferencia (multipaís; habilitado: Colombia, FACO)

Creada el 20-10-2026. Completa el modelo del 19-10 (`../FSCC-12901_COMPENSA_DI/`):
- la carga de sobres (`Form133`) solo registra la DI automática y deja la caja **Pendiente**;
- este proceso, que **nhal1** llama una vez al día, cierra las cajas de una fecha de venta que quedaron **sin diferencia**.

No modifica el exe.

## Qué simula: "Cerrar Terminal" de Consultas de Cuadratura (`FTEPROD/Form43.frm`)

| Paso del botón | En el exe | En el paquete |
|---|---|---|
| Universo | `FuncStrPivote :2081`: `VTA_FACOTERMSTATY` + `LIBVTA` (tiporeg `'Y'`, estado `'A'`, `vta_secuencia = ter_cierrey`) + `ZZZ`, rango de fechas y local | Mismo SQL para **una fecha** y **todos los locales**, solo **Pendientes** (`ter_estado <= 0`) y con número de Y |
| Filas candidatas | `Command4_Click :2915`: estado ≠ "Cerrado"/"Pendiente MP", Cierre Y ≠ 0, Dif. Real (grilla) = 0 | Dif. Real de la F8 de la Y **y** Dif. Real de la grilla de CC, **las dos** en 0 |
| RY-01 | `CierraTerminalYYY :4618`: gestión de cheques tipo 1 = `tes_chefecha` (día-terminal, sin Y) | Igual (parámetro `CD_VAL_CHEQ`, S) |
| RY-03 | Conceptos sin regularizar en la Y: SN, AF, ND, FN, NP, BF, CR, CT, CA (`CARTAAVISO`), DP | Igual, mismos mensajes y orden |
| RY-06 | Fórmula ZZZ solo con la opción 103 del perfil (con un bug: pasa el local como Y) | Parámetro `CD_VAL_ZZZ`, **N**; con S valida con la Y correcta |
| Cierre | `update termstaty set ter_estado = '1', ter_cerradopor = LOGINUSER` | Igual, con `ter_cerradopor = 'PROC_CIERRE_DIARIO'`; commit por caja |

FACO opera solo con cierre Y, así que la Z no se toca, salvo en la etapa sin venta.

## Etapa sin venta: cierre de la Z (FCDVT-56, 22-10-2026)

Después de las Y, el proceso cierra los terminales **sin valor**, como los de la captura del usuario: local 5, T2, 15-10, todo en 0, Pendiente en rojo. Simula el **segundo recorrido** de "Cerrar Terminal" (`Command4_Click :2942`: filas con Cierre Y 0 y Dif. Real 0), que llama a `Form43.CierraTerminal :4077`.

Decisiones del usuario del 22-10:
- **P1:** se cierra la Z, igual que CC.
- **P3:** si el terminal ya tiene una Y creada, se considera que espera sobres y no se toca.
- **P4:** solo se modifica este paquete. No se filtra por `ter_tipo`: un Autopago o POS Mobile que ya cerró `PKG_F8_FACO_CIERRE_TER_PM_AP` tiene la Z en 1 y no entra.

| Paso | En el exe (CC) | En el paquete |
|---|---|---|
| Universo | `UNION` de FCDVT-56 en `FuncStrPivote :2212`: Z de terminal vigente sin libro de ventas Y | Lo mismo para **todos** los locales de la fecha, solo Z Pendientes (`ter_estado <= 0`) y **sin ninguna fila en `TERMSTATY`** |
| Dif. Real = 0 | Fila "Cierre Y 0": todas las consultas **sin filtro de Y**, es decir, todo el terminal en el día (sobres, dólares, euros, tarjetas, tesorería, compensado) | `fn_dif_real_cc(..., 0)`. `fn_sql_nums` quita los `and x.cierrey = :b_y`. Si no da 0, el resultado es `CON_DIFERENCIA_CC` (RZ-05) |
| RZ-01 | Conceptos SN, AF, ND, FN, NP, BF, CR, CT, CA y DP sin regularizar en el día (sin Y) | Igual |
| RZ-02 | `FuncValidarZSumaY`: libro de ventas F8 contra la suma de las Y, campo por campo | Igual. Sin libro de ventas F8, cuadra con una sola consulta |
| — | `FuncValidadCierreyyyy`: sin libro de ventas Y no hay filas y la da por buena | No se replica: el universo ya lo garantiza |
| RZ-03 | Fórmula ZZZ de la Z (F8) con la opción `Btovalidacionzzz` | Parámetro `CD_VAL_ZZZ`, el mismo de RY-06, en **N** |
| RZ-04 | Dólares declarados contra Prosegur con la opción `Btovalidacionprddolar` | Parámetro `CD_VAL_DOL`, **N** |
| Cierre | `update termstat set ter_estado = '1', ter_cerradopor = LOGINUSER` (`:4262`) | Igual, con `PROC_CIERRE_DIARIO`, commit por terminal y `CERRADA_SIN_VENTA` en el log (`log_cierrey` 0; el mensaje guarda el estado anterior) |

Se enciende con el parámetro 1502 `CD_SIN_VENTA` en S. Con N, el proceso hace lo mismo que el 20-10. Volumen: alrededor de 2.180 Z por día en FACO; la consulta del universo es una sola por fecha.

**Dos Dif. Real** (decisión del usuario del 20-10: cerrar solo si las dos son 0):
- **F8 de la Y** (`Form3Y`): `PKG_F8_COMPENSA_DI_CARGA.fn_dif_real(pais, ...)`, la misma con la que se decide la DI automática.
- **Grilla de CC** (`Form43.SubBuscarOpcion`): `fn_dif_real_cc`. Respecto de la F8, cambia en cuatro cosas:
  - sobres `F8` **y `DOL`**;
  - suma dólares y **euros**;
  - **todas** las tarjetas;
  - compensado con `AL` en la lista de regularizados y sin `CA` de `MOVDET`.

  En los casos normales dan lo mismo. Si solo la de CC no da 0, el resultado es `CON_DIFERENCIA_CC`.

## Archivos

| Script | Tipo | Qué hace |
|---|---|---|
| `00_prechecks.sql` | Lectura | Dependencia (`PKG_F8_COMPENSA_DI_CARGA` **multipaís**), objetos nuevos, parámetros, tablas, universo de una fecha |
| `01_log_cierre_diario.sql` | Objeto | `VTA_FACOLOG_CIERRE_DIARIO` + secuencia: INICIO, una fila por caja, FIN |
| `02_parametros.sql` | Datos | 1502: `CD_ACTIVO` S, `CD_VAL_CHEQ` S, `CD_VAL_ZZZ` N; desde el 22-10, `CD_SIN_VENTA` S y `CD_VAL_DOL` N (reutiliza `CA_DECIMAL`) |
| `03` / `04` | Paquete | `PKG_F8_CIERRE_DIARIO` (spec / body) |
| `05_grants_sinonimos.sql` | Permisos | Solo si nhal1 no se conecta como el dueño (`-- EDITAR`) |
| `06_pruebas.sql` | Pruebas | Simulación sin grabar, ejecución de un día, log, país no habilitado |
| `99_rollback.sql` | Reversión | 1 apagar (1b solo la etapa sin venta), 2 reabrir las Y (2c, las Z sin venta) cerradas por el proceso en un rango, 3 desinstalar |
| `anterior_2026-10-22/` | Respaldo | Versión del 20-10, antes de la etapa sin venta. No se ejecuta |
| `INSTALAR.sql` | — | 01 → 04 + estado (SQL*Plus) |
| `prueba_test/` | Prueba | Con los datos que ya hay en test (local 6, 31-08 y 28-08-2026). Ver su `LEEME.md` |
| `docs/PRUEBA_Cierre_Diario_FSCC-12901.pdf` | Guía | Guía de prueba en PDF (fuente `docs/pdf/PRUEBA_CIERRE_DIARIO_FSCC-12901.html`), con columna «Obtenido» para completar |

## `PKG_F8_CIERRE_DIARIO`

| Rutina | Uso |
|---|---|
| `prc_cierre_diario(pais, fecha default null, usuario default 'PROC_CIERRE_DIARIO')` | **La llama nhal1**: `begin PKG_F8_CIERRE_DIARIO.prc_cierre_diario('FACO', null); end;`. Fecha nula = **día anterior** |
| `prc_cierre_diario(pais, fecha, usuario, OUT ejecucion, OUT cerradas, OUT no_cerradas)` | La misma, con resumen |
| `fn_evalua_caja(pais, fecha, local, terminal, Y)` | Simulación sin grabar: `CERRABLE` o el motivo. Se puede usar en un `SELECT`. Con Y = 0 evalúa el terminal sin venta: `CERRABLE_SIN_VENTA`, `DADO_DE_BAJA`, `CON_VENTA`, `ESPERA_SOBRES`… |
| `fn_dif_real_cc(pais, fecha, local, terminal, Y)` | Dif. Real como la grilla de CC (con Y = 0, la de la fila "Cierre Y 0") |

**Resultados por caja** (`log_resultado`):

| Resultado | Significado |
|---|---|
| `CERRADA` | Pasó las validaciones y se cerró |
| `CERRADA_SIN_VENTA` | Terminal sin venta (`log_cierrey` 0): se cerró la Z. Los demás motivos de esta tabla también se usan para estos terminales, con las reglas RZ-01 a RZ-05 |
| `CON_DIFERENCIA` | La F8 de la Y no da 0 (RY-05) |
| `CON_DIFERENCIA_CC` | La F8 da 0, pero la grilla de CC no |
| `BLOQUEADA` | Falló una validación (`log_regla` RY-01, RY-03 o RY-06, con el mensaje del exe) |
| `SIN_LIBVTA` | La Y no tiene libro de ventas |
| `SIN_TERMSTAT` | No existe el cierre Y |
| `YA_CERRADA` | La caja ya estaba cerrada |
| `OCUPADA` | Otro usuario tenía la caja bloqueada; queda para la próxima ejecución |
| `ERROR` | Error de base en esa caja; no corta el resto |

**Por ejecución:** `INICIO`, `FIN` (con el conteo), `INACTIVO` (`CD_ACTIVO` ≠ S) y `ERROR`. Un error general (país no habilitado, falla del universo) **se propaga**, para que nhal1 marque el fallo.

**Multipaís:** el mismo patrón que `PKG_F8_COMPENSA_DI_CARGA`:
- `pr_config` con lista blanca;
- marcas `{P}`, `{EST}`, `{ESTZ}`, `{NIVEL}`, `{USD}`, `{EUR}`, `{CCCA}`;
- DBMS_SQL con binds por nombre.

Solo FACO está habilitado. Para otro país (hay un ejemplo comentado en `pr_config`):
1. Habilitarlo también en `PKG_F8_COMPENSA_DI_CARGA`.
2. Crear su log y sus parámetros (`01` y `02` con el prefijo).
3. Revisar contra el exe sus diferencias en `Form43.SubBuscarOpcion` y `CierraTerminalYYY`; SFCL, por ejemplo, tiene rama propia.
4. Agregar la rama en `pr_config`.

## Orden (test, conectado como `INTRANETTS`)

1. **Requisito:** `PKG_F8_COMPENSA_DI_CARGA` en su versión **multipaís**: `../FSCC-12901_COMPENSA_DI/04` → `05`, pendiente 1p. Lo verifica la consulta 2 de `00_prechecks.sql`; sin ella, `04` de esta carpeta no compila.
2. `00_prechecks.sql`.
3. `INSTALAR.sql`, o en DBeaver 01 → 02 → 03 → 04. Revisar `user_errors`.
4. `05_grants_sinonimos.sql`, si hace falta.
5. `prueba_test/` (P0 → P1 → P2; P9 para repetir; P3 para la etapa sin venta).
6. Programar en nhal1: `begin PKG_F8_CIERRE_DIARIO.prc_cierre_diario('FACO', null); end;` una vez al día, después de la carga de sobres. Si se ejecuta para un día que todavía tiene cargas pendientes, esas cajas quedan Pendientes y se pueden cerrar volviendo a llamar con esa fecha o desde CC.

Convenciones: ASCII, sin prefijo de esquema, sin `&`, Oracle 10.2. Lo compila y ejecuta el usuario.

## Estado en test (20-10-2026, en pausa)

- Solo quedó la **spec** del paquete. Al llamarlo: `ORA-04067: package body "INTRANETTS.PKG_F8_CIERRE_DIARIO" does not exist`. Hay que volver a ejecutar `04` entero y revisar `user_errors` (pasos en `docs/README_FSCC-12901.md`, pendiente 1q). No se cerró ninguna caja.
- `02_parametros.sql` usa `INSERT ... VALUES` (la app de scripts no acepta `INSERT SELECT`): **no es idempotente**. Primero se ejecuta la consulta del inicio y se omiten los códigos que ya existen.
- Sin nhal1, la prueba se lanza con el botón **Salir** de `Form174` (temporal): FACO, fecha fija y usuario `PROC_CIERRE_DIARIO`. La fecha fue el 31-08-2026, después el 10-09 y el 17-09; **desde el 22-10 es el 15-10-2026** (FCDVT-56, etapa sin venta: local 5, T2). Equivale al bloque 3 de `prueba_test/P3_sin_venta.sql` y cierra las Y y los sin venta de **todos** los locales de ese día. Para el 31-08 el esperado era: cerradas 2 (T24, T40), no cerradas 1 (T31).
- **22-10 (FCDVT-56):** se agregó la etapa sin venta (sin ejecutar). En test hay que volver a compilar `03` y `04`, e insertar solo los dos parámetros nuevos de `02` (`CD_SIN_VENTA`, `CD_VAL_DOL`). La versión anterior está en `anterior_2026-10-22/`.
