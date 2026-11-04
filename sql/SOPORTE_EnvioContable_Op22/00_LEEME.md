# Soporte: Envío Contable (Form159), Chile, operación 22, sin registros

Creado el 04-11-2026. Es **solo lectura**: `01_diagnostico_op22.sql` tiene únicamente `SELECT` / `WITH`, así que no necesita rollback.

## Síntoma

Pantalla "Envio Contable" (`Form159`, toolbar *Mantenedor SAP* ▸ *Envio Contable*), Chile (`Flg_Pais$ = ""`), con estos filtros:
- Operación 22-Recaudaciones;
- Local TODOS;
- Tipo de fecha "Fecha Contable";
- Estado POR ENVIAR;
- fechas del 22-10-2026 al 22-10-2026.

Al presionar Buscar sale **"No Existe Registros para estas Fechas"**.

Llamada que se ejecuta:

```sql
declare rs_resultado varchar2(250);
BEGIN
  rs_resultado := pkg_fr_f8_int_sap.prc_ins_sel_doc_contab7(294523,0,22,'POR ENVIAR','D_FECHA_CONTABLE',
                  '04-noviembre-2026','04-noviembre-2026','16900');
END;
```

## Flujo (verificado en el código)

1. `Form159.listarAsociacion` (:1342) genera un `c_idbusqueda` aleatorio. En Chile `ID_ALEATORIO` está fijo en `16900`.
2. `cargarTabla` (:1852) llama a `PKG_FR_F8_INT_SAP.PRC_INS_SEL_DOC_CONTAB7`. Este paquete inserta en `VTA_ENVIOCONTAB_FR` lo que encuentra.
3. Después la pantalla lee `VTA_ENVIOCONTAB_FR` filtrando por ese `c_idbusqueda` (:1700).
   - Si el pkg falla, el mensaje es "No Existe Registros **Asociados** para estas Fechas" (:1466). El error se oculta.
   - Si el pkg funciona pero no inserta nada, el mensaje es "No Existe Registros para estas Fechas" (:1787). **Este es el caso del síntoma.**

Rama `ID_OPERACION = 22` / `POR ENVIAR`: está en el body de desa, `docs/ddl/desa_2026-10-26/objetos/PACKAGE_BODY/PKG_FR_F8_INT_SAP.sql:186-289`. El body de producción no está en el clon; Q1 lo muestra. La rama une dos orígenes:

| Origen | Filtros |
|---|---|
| `VTA_PRD` | `prv_tiporec = 'F8'`, `prv_tiposobre in ('CHE','EFE')`, `prv_fechacontable between desde and hasta` (o `prv_fechavta` si el tipo de fecha es "Fecha Venta"), local si es distinto de 0 |
| `TES_CCHEQUE` | `d_fecvencto between desde and hasta`, `c_estado = 3`, `a_pais = 'CL'`, `c_idempresa = 971878`, `a_codmoneda = 'CLP'` |

En los dos orígenes se **excluye** lo que ya está en `SAP_ENVIADOS_FR`. La comparación se hace por la clave del paquete:
- `VTA_PRD`: `REC-<fvta>-<fcont>-<tiposobre>-16900-<BP>`;
- `TES_CCHEQUE`: `REC-<fvenc>-<fvenc>-CHEF-16900-<BP>`.

El BP sale de `PKG_FR_F8_INT_SAP.OBTIENE_RUTBP(local, 22)`. Si el local no tiene BP asociado, queda `'0'`.

## Cómo ejecutarlo

En el `.sql`, buscar y reemplazar en todo el archivo:
- `22-10-2026` por la fecha desde;
- `23-10-2026` por la fecha hasta;
- `0 as loc` por el local;
- `294523` por el `c_idbusqueda`.

Ejecutarlo en producción, conectado como el dueño de las tablas `VTA_*`. En DBeaver se puede ejecutar cada consulta por separado.

> Ojo con la fecha hasta: el pkg usa `between` sin truncar. Para revisar un solo día se pone la misma fecha en desde y hasta, igual que en la pantalla. Las consultas Q3, Q4, Q7 y Q9 usan `< hasta + 1`, así que muestran también las filas con hora del último día.

## Cómo interpretar los resultados

| Consulta | Qué muestra | Si da… | Conclusión |
|---|---|---|---|
| Q1 | Estado del package y texto de la rama 22 en producción | `INVALID`, o filtros distintos a los de la tabla de arriba | El body de producción no es el de desa. Revisar con el texto real. |
| Q2 | NLS de la sesión | `NLS_DATE_LANGUAGE` distinto de SPANISH | La fecha `dd/MMMM/yyyy` (por ejemplo "octubre") podría convertirse mal. Hay que compararlo con la sesión del exe. |
| Q3 | Todo `VTA_PRD` con esa fecha contable | Vacío | **No hay carga PRD con esa fecha contable** (falta cargar Prosegur, o la fecha contable es otra). |
| Q3 | Igual que arriba | Filas, pero con otro `prv_tiporec` u otro `prv_tiposobre` | El pkg solo toma `F8` y `CHE`/`EFE`. |
| Q3 | Columnas `filas_con_hora` y `filas_en_between_pkg` | `filas_con_hora` > 0 y `filas_en_between_pkg` = 0 | La fecha contable tiene hora y el `between` la deja fuera. |
| Q4 | `VTA_PRD` F8 CHE/EFE por fecha de venta | La venta existe, pero la fecha contable es `(NULA)` u otro día | Buscar en la pantalla con "Fecha Venta" o con la fecha contable real. |
| Q5 | Candidatos de `VTA_PRD`, uno por paquete | Todos con `YA_ENVIADO = 'S'` | **Ya se enviaron.** Buscar en la pantalla con el estado que muestra `A_ESTADO_ENVIADO`. |
| Q6 / Q6b | Cheques de `TES_CCHEQUE`, filtro por filtro | La columna donde la cuenta cae a 0 | Ese filtro es el que descarta los cheques. |
| Q7 | Resumen de `SAP_ENVIADOS_FR` `REC-%` por estado | Filas en otros estados | Confirma que los paquetes ya pasaron a "ENVIADO A SAP", "CON ERROR EN SAP", etc. |
| Q8 | Locales con PRD y sin BP para la operación 22 | Locales listados | No es la causa de la falta de registros (queda BP `'0'`), pero esos paquetes no deberían enviarse a SAP. Hay que asociarlos en *Mantenedor SAP* ▸ *BP Tienda*. |
| Q9 | Lo que dejó el pkg en `VTA_ENVIOCONTAB_FR` | Vacío | Confirma que la inserción fue de 0 filas. Ojo: si la búsqueda ya se cerró, `FNC_BORRA_BUSQUEDA` puede haberla borrado. |

Orden sugerido: Q3 → Q5 → Q7. Con esas tres consultas casi siempre aparece la causa: o no hay PRD, o ya se envió. Q1, Q2 y Q6 sirven para los casos raros.

## Observaciones del código (no se corrigen aquí)

- `cargarTabla` oculta los errores del pkg, porque `salir:` no muestra `Err`. Un error de Oracle aparece en pantalla como "sin registros asociados".
- Las fechas viajan como texto (`dd/MMMM/yyyy`) a parámetros `DATE`. Dentro del pkg se vuelven a concatenar como texto en el SQL dinámico, así que todo depende del NLS de la sesión.
- Dentro de `IF ID_OPERACION = 22` hay un bloque `IF ID_OPERACION = 9830` que nunca se ejecuta (código muerto).
