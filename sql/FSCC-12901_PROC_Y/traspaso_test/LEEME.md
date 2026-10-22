# Traspaso a test: FSCC-12901 v2 (cierre automático y DI automática, FACO)

El archivo único `TRASPASO_TEST_FSCC-12901_v2.sql` contiene los objetos de base de `docs/sql/FSCC-12901_POC_v2` (scripts 00 a 09), en el orden de `INSTALAR.sql`. Cada sección indica de qué script viene y lo copia sin cambios. Solo se agregaron tres cosas:
- la habilitación de la opción 1515 para los perfiles 7 y 9;
- los permisos y sinónimos ya completados para `UINTRANETTS` → `INTRANETTS`;
- el job, comentado.

Generado el 14-10-2026.

## Requisitos
- Base de test `sgfnprds`, con la VPN activa.
- Conectarse como **`INTRANETTS`** (dueño de las tablas `VTA_*`). `UINTRANETTS` no puede crear objetos.
- La parte 5B (sinónimos en `UINTRANETTS`) necesita un DBA (`CREATE ANY SYNONYM`).
- Que en la base no haya ninguna versión anterior de FSCC-12901. Al 14-10-2026 test no tiene ninguna.

## Ejecución
- SQL*Plus: `sqlplus INTRANETTS@<alias_test> @TRASPASO_TEST_FSCC-12901_v2.sql`. Para que se detenga en el primer error, descomentar `whenever sqlerror exit failure rollback`.
- DBeaver: abrir el archivo y ejecutarlo como script (Alt+X).

| Parte | Qué hace | Resultado esperado |
|---|---|---|
| 0 | Verificaciones previas (solo lectura) | Consultas 0 y 1 sin filas. Si devuelven filas, **detenerse**. El resto, según lo que indica cada comentario |
| 1 | Cola, log, secuencias, parámetros 1502 y opción 1515 (habilitada para los perfiles 7 y 9) | Sin errores, 8 parámetros |
| 2 | `PKG_F8_CIERRE_AUTO` y `PKG_F8_COMPENSA_DI_AUTO` | Compilados |
| 3 | Trigger `TRG_VTA_FACOPRD_CIERRE_AI` | Creado. Desde este momento los sobres F8/DOL entran a la cola |
| 4 | Validación | 9 objetos VALID, 0 filas en `user_errors` |
| 5 | Permisos (A, como dueño) y sinónimos (B, como DBA) para `UINTRANETTS` | 4 sinónimos |
| 6 | Job con `DBMS_JOB` (comentado) | Se activa cuando negocio defina la frecuencia; anotar el número de job |

## Objetos
| Tipo | Nombre |
|---|---|
| Tabla | `VTA_FACOPRD_CIERRE` (cola), `VTA_FACOLOG_CIERRE_AUTO` (log) |
| Secuencia | `SEQ_VTA_FACOPRD_CIERRE`, `SEQ_VTA_FACOLOG_CIERRE_AUTO` |
| Paquete | `PKG_F8_CIERRE_AUTO`, `PKG_F8_COMPENSA_DI_AUTO` |
| Trigger | `TRG_VTA_FACOPRD_CIERRE_AI` sobre `VTA_FACOPRD` |
| Datos | `VTA_FACOPARAM` tipo 1502 (8 filas), `VTA_FACOMENU`/`VTA_FACORELPERMEN` opción 1515 |

## Si algo falla
`ROLLBACK_TEST_FSCC-12901_v2.sql` tiene tres partes. Hay que ejecutar **solo la que corresponda**:
- **Parte 1**: apaga T1 y T2 sin desinstalar nada.
- **Parte 2**: revierte una ejecución del proceso.
- **Parte 3**: desinstala todo.

Si el traspaso se cortó a mitad de camino, ejecutar la parte 3 (los `DROP` de objetos que no alcanzaron a crearse fallan, y esos errores se pueden ignorar) y volver a ejecutar el traspaso completo.

## Después del traspaso
- Pruebas: `../10_pruebas.sql`.
- Cambios del exe: `../FORM43_cambios_v2.md`.

Ninguno de los dos está incluido en el traspaso.
