# Form43: cambios para usar los paquetes v2 (multipaís)

**Estado (16-10-2026, tarde): DESCARTADO.**
- El usuario definió que `Form43` **solo** debe mostrar en la grilla las cajas con Diferencia Real 0, como en Chile, sin llamar al paquete ni cerrar desde la pantalla.
- `FTEPROD/Form43.frm` volvió al original con un cambio mínimo: `Or Flg_Pais$ = "FACO"` en el filtro de `SubBuscarOpcion` (ver `docs/FSCC-12901_T3_Form43_propuesta_Jira.md`).
- La v2 aplicada queda en `docs/respaldos/FSCC-12901_2026-10-16_form43-v2.zip`.

Historia anterior: **(16-10-2026) aplicado** en `FTEPROD/Form43.frm` (MD5 `de76a2c3…`).
- Se partió de la v1 del ZIP `solo-Y` y se le aplicaron las secciones 1 y 2.
- Las marcas `'CK: FSCC-12901` se reemplazaron por `'---INI---- xintec-nruz 16-10-2026 FSCC-12901: … ----` / `'---FIN---- xintec-nruz 16-10-2026 ----`, igual que en `Form133`.
- Diff contra `Form43.frm.bak_FSCC-12901`: 267 líneas nuevas y 2 originales comentadas. CP1252 + CRLF.
- **Falta compilar y probar en test.**

Lo que sigue describe el estado del 13-10, antes de aplicarlo.

**Estado (13-10-2026):** este documento **no se aplicó**.

- **Versión actual de `FTEPROD/Form43.frm`:** es la **original**. Es idéntica a `Form43.frm.bak_FSCC-12901` (MD5 `0e1bfd0c…`), es decir, **sin** los cambios de FSCC-12901.
- **Versión modificada (v1):** con `SubBuscarOpcionFACO` y `CierreTerminalFACO` llamando a `PKG_F8_FACO_CIERRE_AUTO`. Está en el respaldo `docs/respaldos/FSCC-12901_2026-10-07_solo-Y.zip` (`FTEPROD/Form43.frm`, MD5 `196067062b…`).

Para pasar a v2, primero hay que restaurar esa versión modificada. Después se aplican los cambios de abajo, editando en Windows-1252 + CRLF (Perl `:raw`) y marcándolos con `'CK: FSCC-12901 v2`.

**Regla general:**
- `PKG_F8_FACO_CIERRE_AUTO` pasa a ser `PKG_F8_CIERRE_AUTO`;
- **todas** las llamadas reciben primero el país, `Flg_Pais$` (`"FACO"` en Colombia).

El resto de la lógica de la pantalla no cambia.

## 1. `SubBuscarOpcionFACO`: columnas del informe "Terminal"

Antes (v1):
```vb
sq = " select x.ter_fecha, x.ter_local, x.ter_terminal, x.ter_cierrey, x.ter_estado, " & _
     "        PKG_F8_FACO_CIERRE_AUTO.fn_dif_caja(x.ter_fecha, x.ter_local, x.ter_terminal, x.p_cierrey) dif_caja, " & _
     "        PKG_F8_FACO_CIERRE_AUTO.fn_compensado(x.ter_fecha, x.ter_local, x.ter_terminal, x.p_cierrey) compensado, " & _
     "        PKG_F8_FACO_CIERRE_AUTO.fn_dif_real(x.ter_fecha, x.ter_local, x.ter_terminal, x.p_cierrey) dif_real " & _
```

Después (v2):
```vb
'CK: FSCC-12901 v2 - paquete multipais: el pais (Flg_Pais$) va como primer argumento
sq = " select x.ter_fecha, x.ter_local, x.ter_terminal, x.ter_cierrey, x.ter_estado, " & _
     "        PKG_F8_CIERRE_AUTO.fn_dif_caja('" & Flg_Pais$ & "', x.ter_fecha, x.ter_local, x.ter_terminal, x.p_cierrey) dif_caja, " & _
     "        PKG_F8_CIERRE_AUTO.fn_compensado('" & Flg_Pais$ & "', x.ter_fecha, x.ter_local, x.ter_terminal, x.p_cierrey) compensado, " & _
     "        PKG_F8_CIERRE_AUTO.fn_dif_real('" & Flg_Pais$ & "', x.ter_fecha, x.ter_local, x.ter_terminal, x.p_cierrey) dif_real " & _
```

`Flg_Pais$` viene de `vta_parametros.vta_prefijo`, no del usuario. Además, el paquete solo acepta países de su lista blanca: con cualquier otro valor da ORA-20001.

En el mensaje de error de la misma rutina, reemplazar `(PKG_F8_FACO_CIERRE_AUTO)` por `(PKG_F8_CIERRE_AUTO)`.


## 2. `CierreTerminalFACO`: botón "Cerrar Terminal", **un día por vez**

En v2 el cierre desde la pantalla es **día por día**. `prc_cierre_rango` se reemplaza por `prc_cierre_dia`.

**Por qué:**
- el DF-SCC (fila 12) no pide un rango de fechas;
- el `Command4_Click` original ya tenía comentada la validación "Seleccione Día de Cierre de Terminal";
- SFCL ya fuerza `DTPicker2 = DTPicker1`.

`prc_cierre_dia` recibe 8 parámetros: país, fecha, local, terminal, usuario y 3 salidas. Las salidas quedan en los índices **5, 6 y 7**, igual que en v1.

**Validación al inicio de la rutina (nueva):**
```vb
'CK: FSCC-12901 v2 - el cierre desde Consultas de Cuadratura es de un solo dia
If DTPicker1.Value <> DTPicker2.Value Then
    MsgBox "Seleccione Día de Cierre de Terminal", vbExclamation, Me.Caption
    Exit Sub
End If
```

Antes (v1):
```vb
    .CommandText = "BEGIN PKG_F8_FACO_CIERRE_AUTO.prc_cierre_rango(?,?,?,?,?,?,?,?); END;"
    ' orden exacto del procedimiento
    .Parameters.Append .CreateParameter(, adVarChar, adParamInput, 8, Format(DTPicker1.Value, VgFormatoFecha))
    .Parameters.Append .CreateParameter(, adVarChar, adParamInput, 8, Format(DTPicker2.Value, VgFormatoFecha))
    ...
vEjecucion = "" & cmd.Parameters(5).Value
vCerradas = "" & cmd.Parameters(6).Value
vNoCerradas = "" & cmd.Parameters(7).Value
```

Después (v2):
```vb
    'CK: FSCC-12901 v2 - paquete multipais (pais = Flg_Pais$) y cierre de un solo dia
    .CommandText = "BEGIN PKG_F8_CIERRE_AUTO.prc_cierre_dia(?,?,?,?,?,?,?,?); END;"
    ' orden exacto del procedimiento
    .Parameters.Append .CreateParameter(, adVarChar, adParamInput, 10, Flg_Pais$)
    .Parameters.Append .CreateParameter(, adVarChar, adParamInput, 8, Format(DTPicker1.Value, VgFormatoFecha))
    .Parameters.Append .CreateParameter(, adInteger, adParamInput, , CLng(Trim(Combo2.Text)))
    .Parameters.Append .CreateParameter(, adInteger, adParamInput, , vTerminal)
    .Parameters.Append .CreateParameter(, adVarChar, adParamInput, 50, Left(Trim(LOGINUSER), 50))
    .Parameters.Append .CreateParameter(, adVarChar, adParamOutput, 40)
    .Parameters.Append .CreateParameter(, adVarChar, adParamOutput, 40)
    .Parameters.Append .CreateParameter(, adVarChar, adParamOutput, 40)
    .Execute
End With

vEjecucion = "" & cmd.Parameters(5).Value
vCerradas = "" & cmd.Parameters(6).Value
vNoCerradas = "" & cmd.Parameters(7).Value
```

En los mensajes:
- reemplazar `"Detalle en VTA_FACOLOG_CIERRE_AUTO, ejecucion "` por `"Detalle en VTA_" & Flg_Pais$ & "LOG_CIERRE_AUTO, ejecucion "`;
- en `SystemMsg`, reemplazar `PKG_F8_FACO_CIERRE_AUTO.prc_cierre_rango` por `PKG_F8_CIERRE_AUTO.prc_cierre_dia`.

La consulta de la grilla (sección 1) puede seguir aceptando un rango para **consultar** varios días. Solo el **cierre** exige un único día.

## 3. Lo que no cambia
- Las condiciones `If Flg_Pais$ = "FACO"` que llevan a `SubBuscarOpcionFACO` y `CierreTerminalFACO` se mantienen, porque hoy solo Colombia usa el paquete. Para habilitar otro país habría que:
  1. agregarlo en `PKG_F8_CIERRE_AUTO.pr_config`;
  2. crear sus objetos (cola, log, trigger y parámetros);
  3. extender esas condiciones.
- La opción 1515, los permisos y el resto de la pantalla quedan igual.
- `09_grants_sinonimos.sql` debe dar `EXECUTE` sobre `PKG_F8_CIERRE_AUTO` al usuario de la conexión `[CONNECT]`.
