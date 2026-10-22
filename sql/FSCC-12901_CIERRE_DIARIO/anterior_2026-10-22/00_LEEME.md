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

La Z no se toca: FACO opera solo con cierre Y.

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
| `02_parametros.sql` | Datos | 1502: `CD_ACTIVO` S, `CD_VAL_CHEQ` S, `CD_VAL_ZZZ` N (reutiliza `CA_DECIMAL`) |
| `03` / `04` | Paquete | `PKG_F8_CIERRE_DIARIO` (spec / body) |
| `05_grants_sinonimos.sql` | Permisos | Solo si nhal1 no se conecta como el dueño (`-- EDITAR`) |
| `06_pruebas.sql` | Pruebas | Simulación sin grabar, ejecución de un día, log, país no habilitado |
| `99_rollback.sql` | Reversión | 1 apagar, 2 reabrir las Y cerradas por el proceso en un rango, 3 desinstalar |
| `INSTALAR.sql` | — | 01 → 04 + estado (SQL*Plus) |
| `prueba_test/` | Prueba | Con los datos que ya hay en test (local 6, 31-08 y 28-08-2026). Ver su `LEEME.md` |
| `docs/PRUEBA_Cierre_Diario_FSCC-12901.pdf` | Guía | Guía de prueba en PDF (fuente `docs/pdf/PRUEBA_CIERRE_DIARIO_FSCC-12901.html`), con columna «Obtenido» para completar |

## `PKG_F8_CIERRE_DIARIO`

| Rutina | Uso |
|---|---|
| `prc_cierre_diario(pais, fecha default null, usuario default 'PROC_CIERRE_DIARIO')` | **La llama nhal1**: `begin PKG_F8_CIERRE_DIARIO.prc_cierre_diario('FACO', null); end;`. Fecha nula = **día anterior** |
| `prc_cierre_diario(pais, fecha, usuario, OUT ejecucion, OUT cerradas, OUT no_cerradas)` | La misma, con resumen |
| `fn_evalua_caja(pais, fecha, local, terminal, Y)` | Simulación sin grabar: `CERRABLE` o el motivo. Se puede usar en un `SELECT` |
| `fn_dif_real_cc(pais, fecha, local, terminal, Y)` | Dif. Real como la grilla de CC |

**Resultados por caja** (`log_resultado`):

| Resultado | Significado |
|---|---|
| `CERRADA` | Pasó las validaciones y se cerró |
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
- marcas `{P}`, `{EST}`, `{NIVEL}`, `{USD}`, `{EUR}`, `{CCCA}`;
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
5. `prueba_test/` (P0 → P1 → P2; P9 para repetir).
6. Programar en nhal1: `begin PKG_F8_CIERRE_DIARIO.prc_cierre_diario('FACO', null); end;` una vez al día, después de la carga de sobres. Si se ejecuta para un día que todavía tiene cargas pendientes, esas cajas quedan Pendientes y se pueden cerrar volviendo a llamar con esa fecha o desde CC.

Convenciones: ASCII, sin prefijo de esquema, sin `&`, Oracle 10.2. Lo compila y ejecuta el usuario.

## Estado en test (20-10-2026, en pausa)

- Solo quedó la **spec** del paquete. Al llamarlo: `ORA-04067: package body "INTRANETTS.PKG_F8_CIERRE_DIARIO" does not exist`. Hay que volver a ejecutar `04` entero y revisar `user_errors` (pasos en `docs/README_FSCC-12901.md`, pendiente 1q). No se cerró ninguna caja.
- `02_parametros.sql` usa `INSERT ... VALUES` (la app de scripts no acepta `INSERT SELECT`): **no es idempotente**. Primero se ejecuta la consulta del inicio y se omiten los códigos que ya existen.
- Sin nhal1, la prueba se lanza con el botón **Salir** de `Form174` (temporal): FACO, fecha fija 31-08-2026, usuario `PROC_CIERRE_DIARIO`. Esperado: cerradas 2 (T24, T40), no cerradas 1 (T31).
