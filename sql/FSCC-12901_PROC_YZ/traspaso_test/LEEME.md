# Traspaso a test: FSCC-12901 PROC_YZ (Y + Z, FACO)

`TRASPASO_TEST_FSCC-12901_YZ.sql` se generó el 15-10-2026 a partir del traspaso de PROC_Y (`docs/sql/FSCC-12901_PROC_Y/traspaso_test/TRASPASO_TEST_FSCC-12901_v2.sql`). Solo cambian 4 partes, que toman el contenido de `docs/sql/FSCC-12901_PROC_YZ`:

| Parte | Script | Cambio |
|---|---|---|
| 0 | `00_prechecks.sql` | Verificaciones 15 a 20 de la Z |
| 1c | `03_parametros_FACO.sql` | 12 parámetros (4 de la Z, con `CA_CIERRA_Z = N`) |
| 2a | `04_pkg_cierre_auto_spec.sql` | `fn_z_suma_y`, `fn_dolares_z` y `pr_valida_z` |
| 2d | `07_pkg_cierre_auto_body.sql` | Cierre de la Z |

El resto es idéntico al de PROC_Y: la opción 1515 para los perfiles 7 y 9, los permisos para `UINTRANETTS` y el job comentado. La parte 4 espera ahora **12** parámetros.

## Cuál usar

| Situación en test | Archivo |
|---|---|
| Test **sin** FSCC-12901 y se decide instalar directo con la Z | `TRASPASO_TEST_FSCC-12901_YZ.sql` (como `INTRANETTS`) |
| Test **ya tiene PROC_Y** (el traspaso v2) | **No usar este archivo.** Usar `../ACTUALIZAR_DESDE_PROC_Y.sql`, que agrega 4 parámetros y recompila `PKG_F8_CIERRE_AUTO` |

En los dos casos la Z queda apagada. Se activa con:

```sql
update VTA_FACOPARAM set vta_xglosa = 'S' where vta_ccodtipo = 1502 and vta_ccodigo = 'CA_CIERRA_Z';
commit;
```

## Ejecución

Igual que el de PROC_Y: requisitos, partes 0 a 6 y sinónimos como DBA. Ver `docs/sql/FSCC-12901_PROC_Y/traspaso_test/LEEME.md`.

## Si algo falla

`ROLLBACK_TEST_FSCC-12901_YZ.sql` es el rollback de PROC_Y con estos agregados:
- **parte 1b:** apaga solo la Z;
- **parte 2:** también reabre las Z que cerró esa ejecución (`CERRADA_Z`);
- **parte 3:** también borra los 4 parámetros de la Z.

Para volver de PROC_YZ a PROC_Y sin desinstalar: `../VOLVER_A_PROC_Y.sql`.
