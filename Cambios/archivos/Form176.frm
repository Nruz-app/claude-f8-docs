VERSION 5.00
Object = "{F9043C88-F6F2-101A-A3C9-08002B2F49FB}#1.2#0"; "COMDLG32.OCX"
Object = "{86CF1D34-0C5F-11D2-A9FC-0000F8754DA1}#2.0#0"; "mscomct2.ocx"
Begin VB.Form Form176 
   BackColor       =   &H00E0E0E0&
   Caption         =   " Exportar Cierres Y y Z (plantilla de carga)"
   ClientHeight    =   6180
   ClientLeft      =   2055
   ClientTop       =   1410
   ClientWidth     =   10410
   LinkTopic       =   "Form176"
   MaxButton       =   0   'False
   ScaleHeight     =   6180
   ScaleWidth      =   10410
   StartUpPosition =   2  'CenterScreen
   Visible         =   0   'False
   Begin VB.CommandButton Command1 
      BackColor       =   &H00A4E8CB&
      Caption         =   "&Exportar"
      Height          =   495
      Left            =   6120
      MaskColor       =   &H00000080&
      Style           =   1  'Graphical
      TabIndex        =   6
      ToolTipText     =   "Exporta a CSV los cierres Y y Z de los filtros, con el formato de la plantilla de carga"
      Top             =   5460
      Width           =   1695
   End
   Begin VB.CommandButton Command3 
      BackColor       =   &H00A4E8CB&
      Caption         =   "&Salir"
      Height          =   495
      Left            =   7920
      MaskColor       =   &H00000080&
      Style           =   1  'Graphical
      TabIndex        =   7
      Top             =   5460
      Width           =   1695
   End
   Begin VB.PictureBox Picture1 
      Appearance      =   0  'Flat
      BackColor       =   &H00C0C0C0&
      BorderStyle     =   0  'None
      ForeColor       =   &H80000008&
      Height          =   570
      Left            =   10200
      Picture         =   "Form176.frx":0000
      ScaleHeight     =   570
      ScaleWidth      =   3135
      TabIndex        =   8
      Top             =   0
      Width           =   3135
   End
   Begin VB.Frame Frame1 
      BackColor       =   &H00E0E0E0&
      Caption         =   "Criterio"
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   8.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00000080&
      Height          =   1815
      Left            =   480
      TabIndex        =   0
      Top             =   840
      Width           =   9135
      Begin VB.ComboBox Combo1 
         BackColor       =   &H00F5F5F5&
         ForeColor       =   &H00000080&
         Height          =   315
         Left            =   240
         Style           =   2  'Dropdown List
         TabIndex        =   1
         Top             =   600
         Width           =   3375
      End
      Begin VB.ComboBox Combo2 
         Height          =   315
         Left            =   1200
         Style           =   2  'Dropdown List
         TabIndex        =   9
         Top             =   600
         Visible         =   0   'False
         Width           =   1215
      End
      Begin VB.ComboBox Combo3 
         BackColor       =   &H00F5F5F5&
         ForeColor       =   &H00000080&
         Height          =   315
         Left            =   3840
         Style           =   2  'Dropdown List
         TabIndex        =   2
         Top             =   600
         Width           =   975
      End
      Begin MSComCtl2.DTPicker DTPicker1 
         Height          =   315
         Left            =   5040
         TabIndex        =   3
         Top             =   600
         Width           =   1575
         _ExtentX        =   2778
         _ExtentY        =   556
         _Version        =   393216
         CalendarBackColor=   16119285
         CalendarForeColor=   128
         CalendarTitleBackColor=   12632256
         CalendarTitleForeColor=   128
         CalendarTrailingForeColor=   8421504
         Format          =   112459777
         CurrentDate     =   37707
      End
      Begin MSComCtl2.DTPicker DTPicker2 
         Height          =   315
         Left            =   6840
         TabIndex        =   4
         Top             =   600
         Width           =   1575
         _ExtentX        =   2778
         _ExtentY        =   556
         _Version        =   393216
         CalendarBackColor=   16119285
         CalendarForeColor=   128
         CalendarTitleBackColor=   12632256
         CalendarTitleForeColor=   128
         CalendarTrailingForeColor=   8421504
         Format          =   112459777
         CurrentDate     =   37707
      End
      Begin VB.Label lblLocal 
         BackColor       =   &H00E0E0E0&
         Caption         =   "Local"
         BeginProperty Font 
            Name            =   "MS Sans Serif"
            Size            =   8.25
            Charset         =   0
            Weight          =   700
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         ForeColor       =   &H00000080&
         Height          =   255
         Left            =   240
         TabIndex        =   10
         Top             =   360
         Width           =   1335
      End
      Begin VB.Label lblTerminal 
         BackColor       =   &H00E0E0E0&
         Caption         =   "Terminal"
         BeginProperty Font 
            Name            =   "MS Sans Serif"
            Size            =   8.25
            Charset         =   0
            Weight          =   700
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         ForeColor       =   &H00000080&
         Height          =   255
         Left            =   3840
         TabIndex        =   11
         Top             =   360
         Width           =   975
      End
      Begin VB.Label lblFechaIni 
         BackColor       =   &H00E0E0E0&
         Caption         =   "Fecha Inicio"
         BeginProperty Font 
            Name            =   "MS Sans Serif"
            Size            =   8.25
            Charset         =   0
            Weight          =   700
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         ForeColor       =   &H00000080&
         Height          =   255
         Left            =   5040
         TabIndex        =   12
         Top             =   360
         Width           =   1575
      End
      Begin VB.Label lblFechaFin 
         BackColor       =   &H00E0E0E0&
         Caption         =   "Fecha Fin"
         BeginProperty Font 
            Name            =   "MS Sans Serif"
            Size            =   8.25
            Charset         =   0
            Weight          =   700
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         ForeColor       =   &H00000080&
         Height          =   255
         Left            =   6840
         TabIndex        =   13
         Top             =   360
         Width           =   1575
      End
      Begin VB.Label lblAyuda 
         BackColor       =   &H00E0E0E0&
         Caption         =   "Local 0 = todos los locales del negocio · Terminal 0 = todos los terminales del local"
         ForeColor       =   &H00404040&
         Height          =   255
         Left            =   240
         TabIndex        =   14
         Top             =   1200
         Width           =   8655
      End
   End
   Begin VB.Frame Frame2 
      BackColor       =   &H00F5F5F5&
      Height          =   2490
      Left            =   480
      TabIndex        =   5
      Top             =   2760
      Width           =   9135
      Begin VB.Label lblResultado 
         BackColor       =   &H00F5F5F5&
         Caption         =   "Resultado de la exportación"
         BeginProperty Font 
            Name            =   "MS Sans Serif"
            Size            =   8.25
            Charset         =   0
            Weight          =   700
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         ForeColor       =   &H00404040&
         Height          =   255
         Left            =   240
         TabIndex        =   15
         Top             =   240
         Width           =   8655
      End
      Begin VB.Label lblArchivo 
         BackColor       =   &H00F5F5F5&
         Caption         =   "Archivo: (sin exportar)"
         ForeColor       =   &H00404040&
         Height          =   615
         Left            =   240
         TabIndex        =   16
         Top             =   540
         Width           =   8655
      End
      Begin VB.Label lblFormato 
         BackColor       =   &H00F5F5F5&
         Caption         =   "Formato CSV: mismas columnas y orden de la plantilla de carga"
         ForeColor       =   &H00808080&
         Height          =   255
         Left            =   240
         TabIndex        =   19
         Top             =   1200
         Width           =   8655
      End
      Begin VB.Label lblCierres 
         BackColor       =   &H00F5F5F5&
         Caption         =   "Cierres exportados: -"
         ForeColor       =   &H00404040&
         Height          =   255
         Left            =   240
         TabIndex        =   17
         Top             =   1530
         Width           =   8655
      End
      Begin VB.Label lblNota 
         BackColor       =   &H00F5F5F5&
         Caption         =   "Si no hay cierres para los filtros: «No existen cierres Y/Z para los filtros seleccionados» y no se genera archivo"
         ForeColor       =   &H00808080&
         Height          =   375
         Left            =   240
         TabIndex        =   18
         Top             =   1950
         Width           =   8655
      End
   End
   Begin MSComDlg.CommonDialog CmDlog 
      Left            =   480
      Top             =   4800
      _ExtentX        =   847
      _ExtentY        =   847
      _Version        =   393216
   End
   Begin VB.Image Image1 
      Height          =   810
      Left            =   1620
      Picture         =   "Form176.frx":1644
      Top             =   -210
      Width           =   13590
   End
   Begin VB.Image Image2 
      Height          =   1830
      Left            =   -150
      Picture         =   "Form176.frx":171C
      Top             =   -1230
      Width           =   4665
   End
End
Attribute VB_Name = "Form176"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
'---INI---- xintec-nruz 16-11-2026 FCDVT-259: Exportar Cierres Y y Z (plantilla de carga), solo Colombia (FACO) ----
'Exporta a CSV las Z y las Y grabadas de un rango de fechas, un local (0 = todos) y un terminal (0 = todos),
'con el formato de la plantilla de carga de Form174 (mismas columnas y orden), para volver a cargarlas con Buscar.
'Base: PKG_F8_EXPORTA_MASIVA_YZ (docs/sql/FCDVT-259/02 y 03): fn_encabezado y fn_lineas.
'Regla de fechas (hoy = fecha del servidor): Fecha Fin <= hoy - 1 (ayer), Fecha Fin >= Fecha Inicio y
'rango maximo de 3 dias entre Fecha Inicio y Fecha Fin (dias incluidos), sin limite hacia atras.
'xintec-nruz 17-11-2026 FCDVT-259: antes "Fecha Inicio >= hoy - 2 dias" y calendarios limitados a hoy - 2..ayer.
'xintec-nruz 16-11-2026 FCDVT-259: Fecha Fin hasta ayer (antes hasta hoy): Buscar de Form174 rechaza las fechas de hoy y el CSV no se podria volver a cargar.
'Se abre desde MDIForm1, boton Y > submenu EXPYZ (permiso 461).
Private mHoy As Date            'fecha del servidor al abrir la pantalla
Private mHabilitado As Boolean  'solo FACO

Private Sub Form_Load()
    lblArchivo.Caption = "Archivo: (sin exportar)"
    lblArchivo.ToolTipText = ""
    lblCierres.Caption = "Cierres exportados: -"
    mHabilitado = (Flg_Pais$ = "FACO")
    If Not mHabilitado Then
        Command1.Enabled = False
        MsgBox "Opción disponible solo para Falabella Colombia.", vbExclamation, Me.Caption
        Exit Sub
    End If
    '---INI---- xintec-nruz 17-11-2026 FCDVT-259: calendarios con la fecha de ayer por defecto ----
    mHoy = FechaServidor()
    'Rango permitido en los calendarios: maximo ayer. Primero el maximo y despues el valor,
    'para que el valor nunca quede fuera del rango (el diseno trae 2003).
    'xintec-nruz 17-11-2026 FCDVT-259: sin MinDate (antes hoy - 2): el limite hacia atras lo aplica
    'el boton Exportar (rango maximo de 3 dias entre Fecha Inicio y Fecha Fin, dias incluidos).
    'xintec-nruz 16-11-2026 FCDVT-259: maximo ayer (antes mHoy)
    On Error Resume Next
    DTPicker1.MaxDate = DateAdd("d", -1, mHoy)
    DTPicker2.MaxDate = DateAdd("d", -1, mHoy)
    DTPicker1.Value = DateAdd("d", -1, mHoy)
    DTPicker2.Value = DateAdd("d", -1, mHoy)
    On Error GoTo 0
    '---FIN---- xintec-nruz 17-11-2026 FCDVT-259 ----
    'Locales del perfil (Modulo1.ProLeeLocales): Combo1 = codigo-alias, Combo2 = codigo (oculto).
    'Si el perfil ve mas de un local, "0-TODOS LOS LOCALES" al comienzo, como Form43.
    Call ProLeeLocales(Combo1, Combo2)
    If Combo2.ListCount > 1 Then
        Combo1.AddItem Right("     0", 5) & "-TODOS LOS LOCALES", 0
        Combo2.AddItem "0", 0
        Combo2.ListIndex = 0
    ElseIf Combo2.ListCount = 1 Then
        Combo2.ListIndex = 0
    End If
    If Combo2.ListIndex >= 0 Then
        Combo1.ListIndex = Combo2.ListIndex     'dispara Combo1_Click, que llena los terminales
    Else
        Call LeeTerminales
    End If
End Sub

'Fecha del servidor sin hora (LeeFechaServidor devuelve dd/mm/yyyy); si falla, la del equipo
Private Function FechaServidor() As Date
    Dim s As String
    FechaServidor = Date
    On Error GoTo errFecha
    s = Trim(LeeFechaServidor)
    If Len(s) >= 10 Then
        FechaServidor = DateSerial(Val(Mid(s, 7, 4)), Val(Mid(s, 4, 2)), Val(Left(s, 2)))
    End If
    Exit Function
errFecha:
    FechaServidor = Date
End Function

'Combo2 (codigo del local) sigue a Combo1 y se recargan los terminales del local
Private Sub Combo1_Click()
    Combo2.ListIndex = Combo1.ListIndex
    Call LeeTerminales
End Sub

'La lista de terminales es la de los vigentes a la Fecha Inicio: se recarga al cambiarla
Private Sub DTPicker1_Change()
    Call LeeTerminales
End Sub

'Terminales: 0 (todos) + los vigentes del local a la Fecha Inicio, como Form43.LeeTerminales.
'Con local 0 (todos los locales) solo se ofrece 0.
Private Sub LeeTerminales()
    Dim Consulta As Object, sq As String, vLocal As Long
    Combo3.Clear
    Combo3.AddItem "0"
    Combo3.ListIndex = 0
    If Combo2.ListIndex < 0 Then Exit Sub
    vLocal = Val(Combo2.List(Combo2.ListIndex))
    If vLocal = 0 Then Exit Sub
    Set Consulta = CreateObject("ADODB.Recordset")
    With Consulta
        .ActiveConnection = Ado_Conn
        .CursorLocation = adUseClient
        .CursorType = adOpenForwardOnly
        .LockType = adLockReadOnly
    End With
    sq = "select ter_terminal " & _
         "from   vta_" & Flg_Pais$ & "terminales " & _
         "where  ter_local = " & vLocal & " " & _
         "  and  (ter_fechabaja >= to_date('" & Format(DTPicker1.Value, "yyyymmdd") & "', 'yyyymmdd') or ter_fechabaja is null) " & _
         "order by ter_terminal "
    On Error GoTo oraerror
    Call Consulta.Open(sq)
    Do While Not Consulta.EOF
        If Not IsNull(Consulta!ter_terminal) Then Combo3.AddItem CStr(Consulta!ter_terminal)
        Consulta.MoveNext
    Loop
    Set Consulta.ActiveConnection = Nothing
    Combo3.ListIndex = 0
    Exit Sub
oraerror:
    'como Form43: si no se pueden leer, queda solo el 0 (todos)
    Set Consulta.ActiveConnection = Nothing
    Combo3.ListIndex = 0
End Sub

'Boton Exportar: valida los filtros, lee las lineas del package y guarda el CSV
Private Sub Command1_Click()
    Dim vLocal As Long, vTerm As Long, vIni As Date, vFin As Date, vGrupo As String
    Dim vEncab As String, vLineas() As String, n As Long
    Dim ruta As String, f As Integer, i As Long, vErr As String
    Dim vCampos() As String, vClave As String, vClaves As String
    Dim nY As Long, nZ As Long, nTerm As Long

    If Not mHabilitado Then Exit Sub
    If Combo2.ListIndex < 0 Then
        MsgBox "Seleccione el local.", vbExclamation, Me.Caption
        Exit Sub
    End If
    vLocal = Val(Combo2.List(Combo2.ListIndex))
    vTerm = 0
    If Combo3.ListIndex >= 0 Then vTerm = Val(Combo3.List(Combo3.ListIndex))
    vIni = DateSerial(Year(DTPicker1.Value), Month(DTPicker1.Value), Day(DTPicker1.Value))
    vFin = DateSerial(Year(DTPicker2.Value), Month(DTPicker2.Value), Day(DTPicker2.Value))

    'Validaciones de fechas (FCDVT-259): fin >= inicio, fin <= ayer y rango maximo de 3 dias entre inicio y fin (dias incluidos)
    If vFin < vIni Then
        MsgBox "La Fecha Fin no puede ser anterior a la Fecha Inicio.", vbExclamation, Me.Caption
        Exit Sub
    End If
    'xintec-nruz 16-11-2026 FCDVT-259: fin hasta ayer (antes If vFin > mHoy, "no puede ser mayor que la fecha actual")
    If vFin >= mHoy Then
        MsgBox "La Fecha Fin debe ser anterior a hoy (" & Format(mHoy, "dd-mm-yyyy") & "): la carga masiva no acepta cierres del día.", vbExclamation, Me.Caption
        Exit Sub
    End If
    '---INI---- xintec-nruz 17-11-2026 FCDVT-259: rango maximo de 3 dias entre Fecha Inicio y Fecha Fin (dias incluidos); sin limite hacia atras para Fecha Inicio ----
'    If vIni < DateAdd("d", -2, mHoy) Then
'        MsgBox "La Fecha Inicio no puede ser anterior al " & Format(DateAdd("d", -2, mHoy), "dd-mm-yyyy") & _
'               " (máximo 2 días hacia atrás).", vbExclamation, Me.Caption
'        Exit Sub
'    End If
    'xintec-nruz 17-11-2026 FCDVT-259: rango maximo de 3 dias incluidos (fin - inicio <= 2)
    If DateDiff("d", vIni, vFin) > 2 Then
        MsgBox "El rango entre Fecha Inicio y Fecha Fin no puede superar 3 dias (dias incluidos).", vbExclamation, Me.Caption
        Exit Sub
    End If
    '---FIN---- xintec-nruz 17-11-2026 FCDVT-259 ----

    'Local 0 de un usuario de grupo: solo los locales de su grupo (como ProLeeLocales)
    vGrupo = "null"
    If vLocal = 0 And Val(PERFILUSER) < PERFIL_USER_TDO Then
        If Val(PERFILUSER) = PERFIL_USER_GRP Or Val(PERFILUSER) = PERFIL_JEFEUSER_GRP Then
            vGrupo = CStr(Val(LOCALUSER))
        End If
    End If

    Screen.MousePointer = vbHourglass
    vEncab = EncabezadoExporta()
    If vEncab = "" Then
        Screen.MousePointer = vbDefault
        Exit Sub
    End If
    n = LeeExporta(vLocal, vTerm, vIni, vFin, vGrupo, vLineas)
    Screen.MousePointer = vbDefault
    If n < 0 Then Exit Sub
    If n = 0 Then
        lblArchivo.Caption = "Archivo: (no se generó)"
        lblArchivo.ToolTipText = ""
        lblCierres.Caption = "Cierres exportados: 0"
        MsgBox "No existen cierres Y/Z para los filtros seleccionados", vbInformation, Me.Caption
        Exit Sub
    End If

    'Conteo para el resultado: terminales (local-terminal distintos), Y y Z (campo 10 = TIPO)
    vClaves = "|"
    For i = 1 To n
        vCampos = Split(vLineas(i), ";")
        If UBound(vCampos) >= 9 Then
            vClave = vCampos(1) & "-" & vCampos(2)
            If InStr(vClaves, "|" & vClave & "|") = 0 Then
                vClaves = vClaves & vClave & "|"
                nTerm = nTerm + 1
            End If
            If vCampos(9) = "Z" Then
                nZ = nZ + 1
            Else
                nY = nY + 1
            End If
        End If
    Next i

    On Error GoTo cancelado
    CmDlog.CancelError = True
    CmDlog.DialogTitle = "Exportar cierres Y y Z (plantilla de carga)"
    CmDlog.Filter = "Archivos CSV (*.csv)|*.csv"
    CmDlog.FilterIndex = 1
    CmDlog.DefaultExt = "csv"
    CmDlog.Flags = cdlOFNOverwritePrompt Or cdlOFNHideReadOnly Or cdlOFNPathMustExist
    CmDlog.filename = "carga_Y_compensa_" & Format(vIni, "ddmmyyyy") & "_" & Format(vFin, "ddmmyyyy") & ".csv"
    CmDlog.ShowSave
    ruta = Trim(CmDlog.filename)
    If ruta = "" Then Exit Sub
    If LCase(Right(ruta, 4)) <> ".csv" Then ruta = ruta & ".csv"

    'CSV: encabezado de la plantilla en la linea 1 y una linea por cierre; separador ; y CRLF (Print #)
    On Error GoTo errArchivo
    Screen.MousePointer = vbHourglass
    f = FreeFile
    Open ruta For Output As #f
    Print #f, vEncab
    For i = 1 To n
        Print #f, vLineas(i)
    Next i
    Close #f
    f = 0
    Screen.MousePointer = vbDefault

    lblArchivo.Caption = "Archivo: " & ruta
    lblArchivo.ToolTipText = ruta
    lblCierres.Caption = "Cierres exportados: " & n & " filas (" & nTerm & " terminales · " & nY & " Y y " & nZ & " Z)"
    MsgBox "Archivo generado:" & vbCrLf & ruta, vbInformation, Me.Caption
    Exit Sub

cancelado:
    'Cancelar en el dialogo de guardar (error 32755, cdlCancel): no se hace nada; otro error se avisa
    If Err.Number <> 32755 Then
        MsgBox "No se pudo abrir el diálogo para guardar: " & Err.Description, vbCritical, Me.Caption
    End If
    Exit Sub
errArchivo:
    vErr = Err.Description
    Screen.MousePointer = vbDefault
    On Error Resume Next
    If f <> 0 Then Close #f
    MsgBox "No se pudo generar el archivo CSV: " & vErr, vbCritical, Me.Caption
End Sub

'Encabezado de la plantilla de carga (PKG_F8_EXPORTA_MASIVA_YZ.fn_encabezado). Vacio si no se pudo leer.
Private Function EncabezadoExporta() As String
    Dim Consulta As Object
    EncabezadoExporta = ""
    Set Consulta = CreateObject("ADODB.Recordset")
    With Consulta
        .ActiveConnection = Ado_Conn
        .CursorLocation = adUseClient
        .CursorType = adOpenForwardOnly
        .LockType = adLockReadOnly
    End With
    On Error GoTo oraerror
    Call Consulta.Open("select PKG_F8_EXPORTA_MASIVA_YZ.fn_encabezado encab from dual")
    If Not Consulta.EOF Then EncabezadoExporta = IIf(IsNull(Consulta!encab), "", Consulta!encab)
    Set Consulta.ActiveConnection = Nothing
    Exit Function
oraerror:
    Set Consulta.ActiveConnection = Nothing
    Screen.MousePointer = vbDefault
    SystemMsg = "Problemas al leer el encabezado de la plantilla (PKG_F8_EXPORTA_MASIVA_YZ.fn_encabezado)"
    frmLogOraError.Show 1
End Function

'Lineas de fn_lineas de los filtros en vLineas(1..n). Devuelve n, o -1 si hubo error.
'vGrupo: "null" o el codigo de grupo (texto numerico) para local 0 de un usuario de grupo.
Private Function LeeExporta(ByVal vLocal As Long, ByVal vTerm As Long, ByVal vIni As Date, ByVal vFin As Date, _
                            ByVal vGrupo As String, vLineas() As String) As Long
    Dim Consulta As Object, sq As String, n As Long
    LeeExporta = -1
    n = 0
    ReDim vLineas(0)
    Set Consulta = CreateObject("ADODB.Recordset")
    With Consulta
        .ActiveConnection = Ado_Conn
        .CursorLocation = adUseClient
        .CursorType = adOpenForwardOnly
        .LockType = adLockReadOnly
    End With
    sq = "select column_value linea " & _
         "from   table(PKG_F8_EXPORTA_MASIVA_YZ.fn_lineas(" & vLocal & ", " & vTerm & ", " & _
         "to_date('" & Format(vIni, "yyyymmdd") & "', 'yyyymmdd'), " & _
         "to_date('" & Format(vFin, "yyyymmdd") & "', 'yyyymmdd'), " & vGrupo & "))"
    On Error GoTo oraerror
    Call Consulta.Open(sq)
    If Consulta.RecordCount > 0 Then ReDim vLineas(Consulta.RecordCount)
    Do While Not Consulta.EOF
        n = n + 1
        If n > UBound(vLineas) Then ReDim Preserve vLineas(n)
        vLineas(n) = IIf(IsNull(Consulta!linea), "", Consulta!linea)
        Consulta.MoveNext
    Loop
    Set Consulta.ActiveConnection = Nothing
    LeeExporta = n
    Exit Function
oraerror:
    Set Consulta.ActiveConnection = Nothing
    Screen.MousePointer = vbDefault
    SystemMsg = "Problemas al leer los cierres Y/Z (PKG_F8_EXPORTA_MASIVA_YZ.fn_lineas)"
    frmLogOraError.Show 1
End Function

'Boton Salir
Private Sub Command3_Click()
    Unload Me
End Sub
'---FIN---- xintec-nruz 16-11-2026 FCDVT-259 ----
