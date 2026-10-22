# FSCC-12901 COMPENSA_DI: cambio de `Form133`

## Cambio del 20-10-2026: llamada multipaís (aplicado, sin compilar)

El paquete pasó a ser multipaís (ver `00_LEEME.md`, "Multipaís") y `EjecutaCompensaDIFACO` ahora envía el país:
- `CommandText`: `BEGIN PKG_F8_COMPENSA_DI_CARGA.prc_compensa_caja(?, to_date(?, 'yyyymmdd'), ?, ?, ?, ?, ?, ?, ?); END;`.
- Primer parámetro nuevo: `p_flg_pais` (`adVarChar` 10, `Flg_Pais$`).
- Las salidas se leen por los índices 6, 7 y 8 (antes 5, 6 y 7).
- La llamada sigue solo para `Flg_Pais$ = "FACO"`. Para otro país, primero se habilita en el paquete.
- Las líneas anteriores quedan comentadas. Marcas `xintec-nruz 20-10-2026`.
- Respaldo previo: `FTEPROD/Form133.frm.bak_FSCC-12901_DIPAIS`, MD5 `7f868d39c0a4b0363db7780dd1b6b418` (la versión ya pasada por el IDE y probada en test). Archivo nuevo: MD5 `00abac131ef669946bfd9be12b8fe38f`, CP1252 + CRLF, sin LF sueltos.
- **Compatibilidad:** el paquete mantiene la firma sin país (equivale a FACO), así que el exe compilado antes de este cambio sigue funcionando con el paquete nuevo. No hace falta instalar paquete y exe al mismo tiempo.

## Cambio del 19-10-2026

Estado 19-10-2026: **aplicado en `FTEPROD/Form133.frm`, sin compilar** (en este equipo no hay VB6).
- Respaldo previo: `FTEPROD/Form133.frm.bak_FSCC-12901_DI`, MD5 `d68736f8c00c0835c0e2de10d7bd3559`, que ya incluye el cambio del 16-10.
- Archivo nuevo: MD5 `5471c124499406506e2e6e399d9463f7`. Se editó en binario y conserva CP1252 + CRLF (2.297 líneas, sin LF sueltos). El diff contra el respaldo solo agrega líneas o comenta las existentes (+117).
- Marcas: `xintec-nruz 19-10-2026`.

Lo aplicado:
1. **`CargarArchivo`:** `Dim vCajasDI`, `vClaveDI`. Después de `X = X + 1` en la rama de inserción, si `Flg_Pais$ = "FACO"` y la Y es mayor que 0, guarda la clave `|local;terminal;yyyymmdd;Y|` sin repetir.
2. **Llamada:** la del 16-10 queda comentada. En su lugar, `If Flg_Pais$ = "FACO" And vCajasDI <> "" Then Call EjecutaCompensaDIFACO(vCajasDI)`.
3. **`EjecutaCierreAutomaticoFACO`:** queda comentada completa.
4. **Nueva `EjecutaCompensaDIFACO`:**
   - por cada caja, un `ADODB.Command` con `BEGIN PKG_F8_COMPENSA_DI_CARGA.prc_compensa_caja(to_date(?, 'yyyymmdd'), ?, ?, ?, ?, ?, ?, ?); END;`;
   - entradas: fecha `adVarChar`, local, terminal e Y `adInteger`, `LOGINUSER`. Las tres salidas son `adVarChar` (`o_monto_di` también, como texto);
   - un error ADO en una caja se anota y se sigue con la siguiente;
   - al final, un `MsgBox` con cajas evaluadas, con DI, sin DI y el detalle (máximo 20 líneas).

Prueba: `prueba_test/LEEME.md`.

Lo que sigue es la propuesta original.

## Por qué

El exe de test llama hoy, al terminar una carga FACO, a `PKG_F8_CIERRE_AUTO.prc_cierre_automatico('FACO')`. Ese código es `EjecutaCierreAutomaticoFACO`, entre las marcas `xintec-nruz 16-10-2026`, en `Form133.frm:1880-1884` y `:1891-1951`.

`01_DESINSTALAR_v2.sql` borra ese paquete. Desde ese momento, cada carga FACO:
- graba los sobres;
- falla en la llamada y muestra "Los sobres quedaron cargados, pero falló el cierre automático de la Y".

Modelo nuevo: la carga **no cierra** la Y. Por cada caja cargada se llama a `PKG_F8_COMPENSA_DI_CARGA.prc_compensa_caja`.

## Cambio

1. En `CargarArchivo`, rama FACO (la que inserta con `to_date(Grid2.TextMatrix(i, 6), 'yyyymmdd')` y `prv_cierrey = Grid2.TextMatrix(i, 7)`, cerca de `:1850`):
   - cuando un sobre **se inserta** (`X = X + 1`), guardar la caja (columna 0 local, 1 terminal, 6 fecha `yyyymmdd`, 7 Y) en una colección **sin repetir**;
   - omitir las cajas con Y = 0.
2. Reemplazar la llamada `EjecutaCierreAutomaticoFACO` (`:1880-1884`) por `EjecutaCompensaDIFACO`. La sub recorre las cajas guardadas y, por cada una:

```vb
'---INI---- xintec-nruz <fecha> FSCC-12901: compensacion automatica de DI al cargar (solo FACO) ----
Set cmd = CreateObject("ADODB.Command")
With cmd
    Set .ActiveConnection = Ado_Conn
    .CommandType = adCmdText
    .CommandText = "BEGIN PKG_F8_COMPENSA_DI_CARGA.prc_compensa_caja(to_date(?, 'yyyymmdd'), ?, ?, ?, ?, ?, ?, ?); END;"
    .Parameters.Append .CreateParameter("p_fecha", adVarChar, adParamInput, 8, vFecha)        'yyyymmdd
    .Parameters.Append .CreateParameter("p_local", adNumeric, adParamInput, , CLng(vLocal))
    .Parameters.Append .CreateParameter("p_terminal", adNumeric, adParamInput, , CLng(vTerminal))
    .Parameters.Append .CreateParameter("p_cierrey", adNumeric, adParamInput, , CLng(vCierreY))
    .Parameters.Append .CreateParameter("p_usuario", adVarChar, adParamInput, 50, <usuario de la sesion>)
    .Parameters.Append .CreateParameter("o_resultado", adVarChar, adParamOutput, 30)
    .Parameters.Append .CreateParameter("o_monto_di", adNumeric, adParamOutput)
    .Parameters.Append .CreateParameter("o_mensaje", adVarChar, adParamOutput, 1000)
    .Execute
    vRes = .Parameters("o_resultado").Value
End With
'---FIN---- xintec-nruz <fecha> ----
```

Hay que seguir el patrón de `Form173.ExisteVtaTempEsc` (`Form173.frm:779`, parámetros OUT con `ADODB.Command`) y probar el tipo de `o_monto_di` con el proveedor `MSDAORA`. Si da problemas, se cambia a `adVarChar` y en el paquete se devuelve como texto.

3. Mostrar un resumen al final, un solo `MsgBox`:
   - total de cajas;
   - "DI registradas: n" con local/terminal/Y y monto;
   - "Sin DI: n" con el resultado de cada una (DR_CERO, FUERA_RANGO, SIN_TERMSTAT, …).
   
   El detalle queda en `VTA_FACOLOG_COMPENSA_DI`.
4. Si una llamada falla en ADO, se avisa con `SystemMsg` + `frmLogOraError` y se sigue con la siguiente caja. Los sobres ya están grabados y el paquete no propaga errores.
5. `EjecutaCierreAutomaticoFACO` se deja **comentada**, como manda el estilo de la casa.

## Permisos

El usuario de `[CONNECT]` (test: `UINTRANETTS`) necesita `execute` sobre el paquete y `select` sobre el log, más los sinónimos: `06_grants_sinonimos.sql`.

## Orden recomendado en la Y

Primero se ingresa la Y (`Form19Y`) y después se cargan los sobres. Si se cargan antes, el paquete responde `SIN_TERMSTAT` o `SIN_LIBVTA` y la caja queda sin DI hasta la próxima carga (o hasta el cron, cuando exista).
