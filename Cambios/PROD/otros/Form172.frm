VERSION 5.00
Object = "{5E9E78A0-531B-11CF-91F6-C2863C385E30}#1.0#0"; "MSFLXGRD.OCX"
Object = "{86CF1D34-0C5F-11D2-A9FC-0000F8754DA1}#2.0#0"; "mscomct2.ocx"
Begin VB.Form Form172 
   BackColor       =   &H00E0E0E0&
   Caption         =   "Cuadratura Efectivo API vs Cartola Bancaria"
   ClientHeight    =   9015
   ClientLeft      =   2055
   ClientTop       =   1410
   ClientWidth     =   11565
   LinkTopic       =   "Form71"
   MaxButton       =   0   'False
   ScaleHeight     =   9015
   ScaleWidth      =   11565
   StartUpPosition =   2  'CenterScreen
   Visible         =   0   'False
   Begin VB.CommandButton Command2 
      BackColor       =   &H00A4E8CB&
      Caption         =   "&Exportar Excel"
      Height          =   375
      Left            =   480
      MaskColor       =   &H00000080&
      Style           =   1  'Graphical
      TabIndex        =   19
      Top             =   8280
      Width           =   1695
   End
   Begin VB.TextBox txtEdit 
      Height          =   285
      Left            =   7320
      TabIndex        =   15
      Top             =   8280
      Visible         =   0   'False
      Width           =   855
   End
   Begin VB.CommandButton Command3 
      BackColor       =   &H00A4E8CB&
      Caption         =   "&Salir"
      Height          =   375
      Left            =   9480
      MaskColor       =   &H00000080&
      Style           =   1  'Graphical
      TabIndex        =   12
      Top             =   8280
      Width           =   1500
   End
   Begin VB.PictureBox Picture1 
      Appearance      =   0  'Flat
      BackColor       =   &H00C0C0C0&
      BorderStyle     =   0  'None
      ForeColor       =   &H80000008&
      Height          =   570
      Left            =   10200
      Picture         =   "Form172.frx":0000
      ScaleHeight     =   570
      ScaleWidth      =   3135
      TabIndex        =   5
      Top             =   0
      Width           =   3135
   End
   Begin VB.CommandButton Command1 
      BackColor       =   &H00A4E8CB&
      Caption         =   "&Buscar"
      Height          =   375
      Left            =   7800
      MaskColor       =   &H00000080&
      Style           =   1  'Graphical
      TabIndex        =   4
      Top             =   1560
      Width           =   1695
   End
   Begin VB.ComboBox Combo2 
      Height          =   315
      Left            =   2400
      TabIndex        =   2
      Top             =   1800
      Width           =   3855
   End
   Begin VB.ComboBox Combo1 
      Height          =   315
      Left            =   2400
      TabIndex        =   1
      Top             =   1320
      Width           =   3855
   End
   Begin MSFlexGridLib.MSFlexGrid Grid1 
      Height          =   4455
      Index           =   0
      Left            =   480
      TabIndex        =   0
      Top             =   3240
      Width           =   10575
      _ExtentX        =   18653
      _ExtentY        =   7858
      _Version        =   393216
      Rows            =   1
      Cols            =   11
      FixedCols       =   0
      BackColor       =   16119285
      ForeColor       =   128
      BackColorFixed  =   10807499
      ForeColorFixed  =   3560496
      BackColorSel    =   13692411
      ForeColorSel    =   128
      BackColorBkg    =   15132904
      SelectionMode   =   1
      BeginProperty Font {0BE35203-8F91-11CE-9DE3-00AA004BB851} 
         Name            =   "MS Sans Serif"
         Size            =   8.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
   End
   Begin MSComCtl2.DTPicker DTPicker2 
      Height          =   375
      Left            =   2400
      TabIndex        =   3
      Top             =   2400
      Width           =   1455
      _ExtentX        =   2566
      _ExtentY        =   661
      _Version        =   393216
      Format          =   155910145
      CurrentDate     =   45877
   End
   Begin VB.Frame Frame1 
      BackColor       =   &H00E0E0E0&
      Height          =   2055
      Left            =   480
      TabIndex        =   8
      Top             =   960
      Width           =   10575
      Begin MSComCtl2.DTPicker DTPicker1 
         Height          =   375
         Left            =   4320
         TabIndex        =   9
         Top             =   1440
         Width           =   1455
         _ExtentX        =   2566
         _ExtentY        =   661
         _Version        =   393216
         Format          =   155910145
         CurrentDate     =   45894
      End
      Begin VB.Label Label3 
         BackColor       =   &H00E0E0E0&
         Caption         =   "Negocio"
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
         Index           =   2
         Left            =   480
         TabIndex        =   17
         Top             =   480
         Width           =   1215
      End
      Begin VB.Label Label3 
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
         Index           =   1
         Left            =   480
         TabIndex        =   16
         Top             =   1080
         Width           =   1215
      End
      Begin VB.Label lblLoad 
         Alignment       =   2  'Center
         BackColor       =   &H80000018&
         BorderStyle     =   1  'Fixed Single
         Caption         =   "Cargando Espere por Favor ..."
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
         Left            =   6240
         TabIndex        =   14
         Top             =   1440
         Visible         =   0   'False
         Width           =   3855
      End
      Begin VB.Label Label4 
         BackColor       =   &H00E0E0E0&
         Caption         =   "Hasta"
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
         Left            =   3600
         TabIndex        =   11
         Top             =   1560
         Width           =   615
      End
      Begin VB.Label Label3 
         BackColor       =   &H00E0E0E0&
         Caption         =   "Fecha"
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
         Index           =   0
         Left            =   480
         TabIndex        =   10
         Top             =   1560
         Width           =   1215
      End
   End
   Begin MSFlexGridLib.MSFlexGrid Grid1 
      Height          =   375
      Index           =   1
      Left            =   480
      TabIndex        =   18
      Top             =   7680
      Width           =   10575
      _ExtentX        =   18653
      _ExtentY        =   661
      _Version        =   393216
      Rows            =   1
      Cols            =   11
      FixedCols       =   0
      BackColor       =   16119285
      ForeColor       =   128
      BackColorFixed  =   10807499
      ForeColorFixed  =   3560496
      BackColorSel    =   12640511
      ForeColorSel    =   128
      BackColorBkg    =   15132904
      ScrollBars      =   0
      SelectionMode   =   1
      BeginProperty Font {0BE35203-8F91-11CE-9DE3-00AA004BB851} 
         Name            =   "MS Sans Serif"
         Size            =   8.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
   End
   Begin VB.Label Label5 
      Height          =   495
      Left            =   4440
      TabIndex        =   13
      Top             =   3960
      Width           =   3135
   End
   Begin VB.Label Label10 
      BackColor       =   &H00C0C0C0&
      Height          =   1245
      Left            =   13320
      TabIndex        =   7
      Top             =   -240
      Width           =   1065
   End
   Begin VB.Label Label11 
      BackColor       =   &H00C0C0C0&
      Height          =   9585
      Left            =   13920
      TabIndex        =   6
      Top             =   0
      Width           =   615
   End
   Begin VB.Image Image1 
      Height          =   810
      Left            =   1620
      Picture         =   "Form172.frx":1644
      Top             =   -210
      Width           =   13590
   End
   Begin VB.Image Image2 
      Height          =   1830
      Left            =   -150
      Picture         =   "Form172.frx":171C
      Top             =   -1230
      Width           =   4665
   End
End
Attribute VB_Name = "Form172"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Private Const COL_EDITABLE As Integer = 3
Private ColSeleccionada As Integer
Private efeDepositariaTotal As Currency
Private efeBancoTotal As Currency
Private diferenciaTotal As Currency



Private Sub Combo1_Change()
    'Call llenalocales
End Sub

Private Sub Combo1_Click()
    Call llenalocales
    'If Mid(Trim(Combo1.Text), 1, 1) > 0 Then
    '    Call llenalocales
    '    Combo2.Enabled = True
    'Else
    '    Combo2.Clear
    '    Combo2.Enabled = False
    'End If
End Sub

Private Sub Command1_Click()
    Call Buscar
End Sub
Public Sub Buscar()
   Screen.MousePointer = vbHourglass
    lblLoad.Visible = True
    lblLoad.Refresh
    DoEvents
    Grid1(0).Clear
    lblLoad.Visible = False
    Call definegrid
    Screen.MousePointer = vbDefault

End Sub

Private Sub Command2_Click()
    Call GeneraExcel
End Sub

Private Sub Command3_Click()
    Unload Me
End Sub

Private Sub Form_Load()
    DTPicker1.Value = Now
    DTPicker2.Value = Now
    Call llenaNegocio
    'Call llenalocales
End Sub


Private Function llenaNegocio()

Set Consulta = CreateObject("ADODB.Recordset")
With Consulta
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With


sq = "select VTA_CCODIGO ||' - '||VTA_XGLOSA VTA_XGLOSA from vta_param where VTA_CCODTIPO=85"
   
    
Call Consulta.Open(sq)
X = Consulta.RecordCount
Combo1.AddItem "0   - TODOS"
For i = 1 To X
    If Consulta.EOF Then Exit Function '---------------------------
    Combo1.AddItem Consulta.Fields(0).Value
    Consulta.MoveNext
Next i
Combo1.ListIndex = 0
Set Consulta.ActiveConnection = Nothing
Exit Function
oraerror:
   Set Consulta.ActiveConnection = Nothing
End Function

Private Function llenalocales()

    Dim idxSeleccion As Integer
    idxSeleccion = -1
    Dim codCombo As String
    Dim codGlobal As Variant

    Set Consulta = CreateObject("ADODB.Recordset")
    With Consulta
        .ActiveConnection = Ado_Conn
        .CursorLocation = adUseClient
        .CursorType = adOpenForwardOnly
        .LockType = adLockReadOnly
    End With

    Combo2.Clear

    If Mid(Trim(Combo1.Text), 1, 1) <> "0" Then
        sq = "select RPAD(VTA_COD_LOCAL, 4, ' ')||' - '||VTA_ALIAS from vta_locales where VTA_COD_NEGOCIO = " & Mid(Trim(Combo1.Text), 1, 1)
    Else
        sq = "select RPAD(VTA_COD_LOCAL, 4, ' ')||' - '||VTA_ALIAS from vta_locales where VTA_COD_NEGOCIO <> 0 "
    End If

    If PERFILUSER < PERFIL_USER_TDO Then
        If PERFILUSER = PERFIL_USER_GRP Or PERFILUSER = PERFIL_JEFEUSER_GRP Then
            sq = sq & " and vta_grupo = " & LOCALUSER & " "
        Else
            sq = sq & " and vta_cod_local = " & LOCALUSER & " "
        End If
    End If

    sq = sq & " order by VTA_COD_NEGOCIO asc, VTA_COD_LOCAL asc "

    'Agregar TODOS
    Combo2.AddItem "0   - TODOS"

    Call Consulta.Open(sq)

    i = 1

    Do While Not Consulta.EOF

        Combo2.AddItem Consulta.Fields(0).Value

        'Buscar coincidencia con Glocal
        codCombo = GetCodigo(Consulta.Fields(0).Value)
        codGlobal = GetCodigo(Glocal)
        
        If codCombo = codGlobal Then
            idxSeleccion = i
        End If

        i = i + 1
        Consulta.MoveNext
    Loop

    'Seleccionar
    If idxSeleccion <> -1 Then
        Combo2.ListIndex = idxSeleccion
    Else
        Combo2.ListIndex = 0
    End If

    Set Consulta.ActiveConnection = Nothing
    Exit Function

oraerror:
    Set Consulta.ActiveConnection = Nothing

End Function
Private Function GetCodigo(valor As Variant) As String
    
    Dim tmp As String
    
    ' Quitar espacios
    tmp = Trim(valor)
    
    ' Tomar todo antes del "-"
    If InStr(tmp, "-") > 0 Then
        tmp = Split(tmp, "-")(0)
    End If
    
    ' Limpiar espacios otra vez
    tmp = Trim(tmp)
    
    GetCodigo = tmp

End Function

Private Function definegrid()
   
   fch_ini = Mid(DTPicker1.Value, 1, 10)
   fch_fin = Mid(DTPicker2.Value, 1, 10)
   
   fecha_ini = Format(CDate(fch_ini), "dd-MM-yyyy")
   fecha_fin = Format(CDate(fch_fin), "dd-MM-yyyy")
   
   n_dias = DateDiff("d", fecha_ini, fecha_fin)
   
   
    'If n_dias < 45 Or n_dias > 60 Then
    '    MsgBox "El rango de fechas debe estar entre 45 y 60 días.", vbExclamation, "Rango de fechas"
    '    Exit Function
    'End If
   
    Grid1(0).Cols = 6
    Grid1(0).Rows = 1
    Grid1(0).RowHeight(0) = 300
    
    Grid1(0).ColWidth(0) = 2000
    Grid1(0).ColWidth(1) = 2400
    Grid1(0).ColWidth(2) = 2000
    Grid1(0).ColWidth(3) = 2100
    Grid1(0).ColWidth(4) = 2000
    Grid1(0).ColWidth(5) = 0
    
    'Grid1.FixedAlignment(0) = 4
    Grid1(0).FixedAlignment(0) = flexAlignCenterCenter
    Grid1(0).FixedAlignment(1) = flexAlignCenterCenter
    Grid1(0).FixedAlignment(2) = 4
    Grid1(0).FixedAlignment(3) = 4
    Grid1(0).FixedAlignment(4) = 4
        
    Grid1(0).TextMatrix(0, 0) = "Fecha Contable"
    Grid1(0).TextMatrix(0, 1) = "Local"
    Grid1(0).TextMatrix(0, 2) = "Efectivo Depositario"
    Grid1(0).TextMatrix(0, 3) = "Efetivo Banco"
    Grid1(0).TextMatrix(0, 4) = "Diferencia"
    
    Grid1(0).ColAlignment(0) = flexAlignLeftCenter
    
    Call definegrid2
    Call CargaGrilla
    
End Function
Private Function definegrid2()

    Grid1(1).Cols = 4
    Grid1(1).Rows = 1
    Grid1(1).RowHeight(0) = 300
    
    Grid1(1).ColWidth(0) = 4400
    Grid1(1).ColWidth(1) = 2000
    Grid1(1).ColWidth(2) = 2100
    Grid1(1).ColWidth(3) = 2000
    
    'Grid1.FixedAlignment(0) = 4
    Grid1(1).FixedAlignment(0) = 1
    Grid1(1).FixedAlignment(1) = flexAlignCenterCenter
    Grid1(1).FixedAlignment(2) = 4
    Grid1(1).FixedAlignment(3) = 4
        
    Grid1(1).ColAlignment(0) = flexAlignLeftCenter
    

End Function


Private Sub CargaGrilla()
Set ConsultaCua = CreateObject("ADODB.Recordset")
With ConsultaCua
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With

Dim idProTraSum As Currency
Dim vtaDif As Currency
Dim efeBanco As Double
lblLoad.Visible = False

sq = sq & " SELECT "
sq = sq & " TRUNC(PT.ACCOUNTING_DATE) AS fecha, "
'sq = sq & " SUM(NVL(PT.TOTAL, 0)) AS monto_total, "
sq = sq & " SUM( "
sq = sq & "     CASE "
sq = sq & "         WHEN PT.VALIDA = 1 THEN NVL(PT.TOTAL, 0) "
sq = sq & "         ELSE 0 "
sq = sq & "     END "
sq = sq & " ) AS monto_total, "
sq = sq & " TO_NUMBER(TRIM(NVL(PT.SERVICE_POINT_CODE,'0'))) AS local, "
sq = sq & " NVL(l.VTA_ALIAS, '') AS alias "
sq = sq & " FROM PROSEGUR_TRANSACTIONS PT "
sq = sq & " JOIN VTA_LOCALES l ON l.VTA_COD_LOCAL = TO_NUMBER(TRIM(NVL(PT.SERVICE_POINT_CODE,'0'))) "
sq = sq & " WHERE 1=1 "

If Trim(Combo2.Text) <> "" And Mid(Trim(Combo2.Text), 1, 1) <> "0" Then
    sq = sq & " AND TO_NUMBER(TRIM(NVL(PT.SERVICE_POINT_CODE,'0'))) = " & Val(Combo2.Text) & " "
End If

If Trim(DTPicker1.Value) <> "" And Trim(DTPicker2.Value) <> "" Then

    sq = sq & " AND PT.ACCOUNTING_DATE >= TO_DATE('" & Format(DTPicker2.Value, "yyyy-mm-dd") & "','YYYY-MM-DD') "
    sq = sq & " AND PT.ACCOUNTING_DATE < TO_DATE('" & Format(DTPicker1.Value, "yyyy-mm-dd") & "','YYYY-MM-DD') + 1 "

End If

If Mid(Trim(Combo1.Text), 1, 1) > 0 Then
    sq = sq & " AND l.VTA_COD_NEGOCIO = " & Val(Combo1.Text) & " "
End If

sq = sq & " GROUP BY TRUNC(PT.ACCOUNTING_DATE), TO_NUMBER(TRIM(NVL(PT.SERVICE_POINT_CODE,'0'))), l.VTA_ALIAS "
sq = sq & " ORDER BY fecha DESC "

Call ConsultaCua.Open(sq)

efeDepositariaTotal = 0
efeBancoTotal = 0
diferenciaTotal = 0
Grid1(0).Cols = 6
Grid1(0).Rows = 1
row = 1
Grid1(0).ColAlignment(0) = flexAlignCenterCenter

Do While Not ConsultaCua.EOF

    Grid1(0).Rows = Grid1(0).Rows + 1

    Grid1(0).TextMatrix(row, 0) = ConsultaCua.Fields(0).Value
    Grid1(0).TextMatrix(row, 1) = ConsultaCua.Fields(3).Value
    Grid1(0).TextMatrix(row, 2) = Format(ConsultaCua.Fields(1).Value, "#,##0")
    Grid1(0).TextMatrix(row, 5) = ConsultaCua.Fields(2).Value
    
    fechaFormateada = Format(CDate(ConsultaCua.Fields(0).Value), "yyyymmdd")
    idProTraSum = CCur(fechaFormateada & CStr(ConsultaCua.Fields(2).Value))
    
    efeBanco = BuscarProsegurTransSum(idProTraSum, 1)
    vtaDif = BuscarProsegurTransSum(idProTraSum, 2)
    efeBancoTotal = efeBancoTotal + efeBanco
    diferenciaTotal = diferenciaTotal + vtaDif
    Grid1(0).TextMatrix(row, 3) = Format(efeBanco, "#,##0")
    Grid1(0).TextMatrix(row, 4) = Format(vtaDif, "#,##0")
    
    efeDepositariaTotal = efeDepositariaTotal + ConsultaCua.Fields(1).Value
    
    
    Grid1(0).row = row
    Grid1(0).col = 2
    Grid1(0).CellForeColor = vbBlue
    Grid1(0).CellFontUnderline = True

    row = row + 1
    ConsultaCua.MoveNext
Loop
    ' TOTALES
    Grid1(1).Rows = 1
    
    ' Texto correcto
    Grid1(1).TextMatrix(0, 0) = "Totales"
    Grid1(1).TextMatrix(0, 1) = Format(efeDepositariaTotal, "#,##0")
    Grid1(1).TextMatrix(0, 2) = Format(efeBancoTotal, "#,##0")
    Grid1(1).TextMatrix(0, 3) = Format(diferenciaTotal, "#,##0")
    
    ' Posicionarse en la fila
    Grid1(1).row = 0
    
    'Columna 0 amarilla
    Grid1(1).col = 0
    Grid1(1).CellBackColor = RGB(255, 255, 153)
    Grid1(1).CellAlignment = flexAlignLeftCenter
    
    'Columnas de montos blancas
    Dim c As Integer
    For c = 1 To 3
        Grid1(1).col = c
        Grid1(1).CellBackColor = vbWhite
        Grid1(1).CellAlignment = flexAlignRightCenter
    Next c
    
    
Set ConsultaCua.ActiveConnection = Nothing
Exit Sub
oraerror:
   lblLoad.Visible = False
   Set ConsultaCua.ActiveConnection = Nothing
End Sub


Private Sub Grid1_DblClick(Index As Integer)
    
    With Grid1(Index)

        ' No encabezado
        If .row = 0 Then Exit Sub

        ' Solo columna editable
        If ColSeleccionada <> COL_EDITABLE Then Exit Sub

        txtEdit.Left = .Left + .CellLeft + 6390
        txtEdit.Top = .Top + .CellTop
        txtEdit.Width = .CellWidth + 150
        txtEdit.Height = .CellHeight

        txtEdit.Text = .TextMatrix(.row, COL_EDITABLE)
        txtEdit.Tag = Index
        txtEdit.Visible = True
        txtEdit.SetFocus
        txtEdit.SelStart = 0
        txtEdit.SelLength = Len(txtEdit.Text)

    End With
End Sub

Private Sub Grid1_MouseDown(Index As Integer, Button As Integer, Shift As Integer, X As Single, Y As Single)

    Static lastClickTime As Single
    Dim col As Integer
    Dim ancho As Single
    Dim i As Integer

    ' Evitar título
    If Grid1(Index).row = 0 Then Exit Sub

    ' Calcular columna real
    ancho = 0
    For i = 0 To Grid1(Index).Cols - 1
        ancho = ancho + Grid1(Index).ColWidth(i)
        If X < ancho Then
            col = i
            Exit For
        End If
    Next i

    ColSeleccionada = col

    ' Columna 2
    If col = 2 And Grid1(Index).row > 0 Then
        
        Form173.vtaFechaVenta = Grid1(Index).TextMatrix(Grid1(Index).row, 0)
        Form173.vtaLocal = Grid1(Index).TextMatrix(Grid1(Index).row, 5)
        Form173.Show 1
        
    End If

    lastClickTime = Timer
End Sub

Private Sub txtEdit_KeyPress(KeyAscii As Integer)

    If KeyAscii = vbKeyReturn Then
        GuardarEdicion
        KeyAscii = 0
    End If

End Sub
Private Sub txtEdit_LostFocus()
    GuardarEdicion
End Sub
Private Sub GuardarEdicion()

    Dim i As Integer
    Dim valor As String
    Dim valorBan As String
    Dim valordif As String
    Dim efeBanco As Double
    Dim idx As Integer
    Dim vtaEfecDespitaria As Double
    Dim vtaFecha As String
    Dim idProTraSum As Currency
    Dim vtaLocal As Integer
    Dim vtaDif As Currency
    
    If Not IsNumeric(txtEdit.Text) Then Exit Sub
       efeBanco = CLng(txtEdit.Text)

    With Grid1(0)

        ' Tomar valor
        valor = Trim(.TextMatrix(.row, 2))
    
        ' Limpiar separadores
        valor = Replace(valor, ".", "")
        valor = Replace(valor, ",", "")
    
        If IsNumeric(valor) Then
            vtaEfecDespitaria = CDbl(valor)
        Else
            vtaEfecDespitaria = 0
        End If
    
        ' Calcular
        .TextMatrix(.row, 3) = Format(efeBanco, "#,##0")
        .TextMatrix(.row, 4) = Format(vtaEfecDespitaria - efeBanco, "#,##0")
        
        vtaFecha = Trim(Grid1(0).TextMatrix(.row, 0))
        vtaLocal = Trim(Grid1(0).TextMatrix(.row, 5))
        fechaFormateada = Format(CDate(vtaFecha), "yyyymmdd")
        idProTraSum = CCur(fechaFormateada & CStr(vtaLocal))
        vtaDif = CDbl(Trim(Grid1(0).TextMatrix(.row, 4)))
    
        'Registra Suma Transacion
        Call GrabarProsegurTransSum(idProTraSum, vtaFecha, vtaLocal, vtaEfecDespitaria, efeBanco, vtaDif)
    
    End With
    efeBancoTotal = 0
    diferenciaTotal = 0
    For i = 1 To Grid1(0).Rows - 1

        valorBan = Trim(Grid1(0).TextMatrix(i, 3))
        valordif = Trim(Grid1(0).TextMatrix(i, 4))
    
        ' limpiar formato
        valorBan = Replace(valorBan, ".", "")
        valorBan = Replace(valorBan, ",", "")
        valordif = Replace(valordif, ".", "")
        valordif = Replace(valordif, ",", "")
    
        If IsNumeric(valorBan) Then
            efeBancoTotal = efeBancoTotal + CCur(valorBan)
        End If
        If IsNumeric(valordif) Then
            diferenciaTotal = diferenciaTotal + CCur(valordif)
        End If

    Next i
    
    Grid1(1).TextMatrix(0, 2) = Format(efeBancoTotal, "#,##0")
    Grid1(1).TextMatrix(0, 3) = Format(diferenciaTotal, "#,##0")
    
    txtEdit.Visible = False

End Sub
Private Sub Grid1_MouseMove(Index As Integer, Button As Integer, Shift As Integer, X As Single, Y As Single)

    Dim col As Integer
    Dim ancho As Single
    Dim i As Integer

    ancho = 0

    For i = 0 To Grid1(Index).Cols - 1
        ancho = ancho + Grid1(Index).ColWidth(i)
        If X < ancho Then
            col = i
            Exit For
        End If
    Next i

    If col = 1 And Grid1(Index).MouseRow > 0 Then
        Screen.MousePointer = vbHand
    Else
        Screen.MousePointer = vbDefault
    End If

End Sub

Private Sub GeneraExcel()

    Dim xlApp As Object
    Dim xlBook As Object
    Dim xlSheet As Object
    Dim i As Integer
    Dim filaFin As Integer
    Dim filaTotal As Integer
    
    ' Crear Excel
    Set xlApp = CreateObject("Excel.Application")
    Set xlBook = xlApp.Workbooks.Add
    Set xlSheet = xlBook.Sheets(1)
    
    ' Nombre hoja
    xlSheet.Name = Left(Me.Caption, 30)
    
    ' TITULO
    With xlSheet.Range("A1:E1")
        .Merge
        .Value = "Reporte de Diferencias"
        .Font.Size = 14
        .Font.Bold = True
        .HorizontalAlignment = -4108 ' Centro
    End With
    
    ' ENCABEZADOS
    xlSheet.Cells(3, 1).Value = "Fecha Contable"
    xlSheet.Cells(3, 2).Value = "Local"
    xlSheet.Cells(3, 3).Value = "Efectivo Depositario"
    xlSheet.Cells(3, 4).Value = "Efectivo Banco"
    xlSheet.Cells(3, 5).Value = "Diferencia"
    
    With xlSheet.Range("A3:E3")
        .Font.Bold = True
        .Interior.Color = RGB(200, 200, 200)
        .HorizontalAlignment = -4108
        .VerticalAlignment = -4108
        .Borders.LineStyle = 1
    End With
    
    ' DATOS DESDE GRID(0)
    For i = 1 To Grid1(0).Rows - 1
        
        xlSheet.Cells(i + 3, 1).Value = Grid1(0).TextMatrix(i, 0)
        xlSheet.Cells(i + 3, 2).Value = Grid1(0).TextMatrix(i, 1)
        xlSheet.Cells(i + 3, 3).Value = Grid1(0).TextMatrix(i, 2)
        xlSheet.Cells(i + 3, 4).Value = Grid1(0).TextMatrix(i, 3)
        xlSheet.Cells(i + 3, 5).Value = Grid1(0).TextMatrix(i, 4)
        
    Next i
    
    filaFin = Grid1(0).Rows + 3
    filaTotal = filaFin + 1
    
    'Merge A y B para "Totales"
    With xlSheet.Range("A" & filaTotal & ":B" & filaTotal)
        .Merge
        .Value = Grid1(1).TextMatrix(0, 0) ' "Totales"
        .HorizontalAlignment = -4131 ' Izquierda
    End With
    
    'Montos alineados con columnas reales
    xlSheet.Cells(filaTotal, 3).Value = Grid1(1).TextMatrix(0, 1)
    xlSheet.Cells(filaTotal, 4).Value = Grid1(1).TextMatrix(0, 2)
    xlSheet.Cells(filaTotal, 5).Value = Grid1(1).TextMatrix(0, 3)
    
    ' FORMATO TOTALES
    With xlSheet.Range("A" & filaTotal & ":E" & filaTotal)
        .Interior.Color = RGB(255, 255, 153)
        .Font.Bold = True
        .Borders.LineStyle = 1
    End With
    
    ' FORMATOS GENERALES
    
    ' Anchos de columna
    xlSheet.Columns("A").Columnwidth = 18
    xlSheet.Columns("B").Columnwidth = 30
    xlSheet.Columns("C").Columnwidth = 22
    xlSheet.Columns("D").Columnwidth = 22
    xlSheet.Columns("E").Columnwidth = 18
    
    ' Formato numérico
    xlSheet.Range("C4:E" & filaTotal).NumberFormat = "#,##0"
    
    ' Bordes tabla principal
    With xlSheet.Range("A3:E" & filaFin)
        .Borders.LineStyle = 1
    End With
    
    ' Línea superior más marcada en totales
    With xlSheet.Range("A" & filaTotal & ":E" & filaTotal).Borders(8)
        .LineStyle = 1
        .Weight = 2
    End With
    
    ' Auto ajuste
    xlSheet.Columns("A:E").AutoFit
    
    ' Mostrar Excel
    xlApp.Visible = True
    xlApp.ActiveWindow.Zoom = 90

    ' Liberar objetos
    Set xlSheet = Nothing
    Set xlBook = Nothing
    Set xlApp = Nothing

End Sub

Private Sub GrabarProsegurTransSum(ByVal vtaIdProTransSum As Currency, _
                                   ByVal vtaFechaContable As String, _
                                   ByVal vtaServicePointCode As Long, _
                                   ByVal vtaEfectivoDepositaria As Double, _
                                   ByVal vtaEfectivoBancario As Double, _
                                   ByVal vtaDiferencia As Double)

    Dim sq As String
    Dim Deposito As String
    Dim Banco As String
    Dim Diferencia As String

    On Error GoTo ErrHandler

    Deposito = Replace$(Format$(vtaEfectivoDepositaria, "0.00"), ",", ".")
    Banco = Replace$(Format$(vtaEfectivoBancario, "0.00"), ",", ".")
    Diferencia = Replace$(Format$(vtaDiferencia, "0.00"), ",", ".")

    sq = ""

    sq = sq & "MERGE INTO PROSEGUR_TRANS_SUM T "
    sq = sq & "USING ( "
    sq = sq & "SELECT "
    sq = sq & vtaServicePointCode & " SERVICE_POINT_CODE, "
    sq = sq & "TO_TIMESTAMP('" & vtaFechaContable & "','DD-MM-YYYY') ACCOUNTING_DATE "
    sq = sq & "FROM DUAL "
    sq = sq & ") S "

    sq = sq & "ON ( "
    sq = sq & "T.SERVICE_POINT_CODE = S.SERVICE_POINT_CODE "
    sq = sq & "AND T.ACCOUNTING_DATE = S.ACCOUNTING_DATE "
    sq = sq & ") "

    sq = sq & "WHEN MATCHED THEN UPDATE SET "
    sq = sq & "T.DEPOSITORY_CASH_AMOUNT = " & Deposito & ", "
    sq = sq & "T.BANK_CASH_AMOUNT = " & Banco & ", "
    sq = sq & "T.DIFFERENCE_AMOUNT = " & Diferencia & " "

    sq = sq & "WHEN NOT MATCHED THEN INSERT ("
    sq = sq & "ID_PRO_TRANS_SUM, "
    sq = sq & "SERVICE_POINT_CODE, "
    sq = sq & "ACCOUNTING_DATE, "
    sq = sq & "DEPOSITORY_CASH_AMOUNT, "
    sq = sq & "BANK_CASH_AMOUNT, "
    sq = sq & "DIFFERENCE_AMOUNT"
    sq = sq & ") VALUES ("
    sq = sq & vtaIdProTransSum & ", "
    sq = sq & vtaServicePointCode & ", "
    sq = sq & "TO_TIMESTAMP('" & vtaFechaContable & "','DD-MM-YYYY'), "
    sq = sq & Deposito & ", "
    sq = sq & Banco & ", "
    sq = sq & Diferencia
    sq = sq & ")"

    Ado_Conn.Execute sq

    Exit Sub

ErrHandler:
    MsgBox "Error al grabar Prosegur: " & Err.Number & vbCrLf & Err.Description, vbCritical, "PROSEGUR"

End Sub

Private Function BuscarProsegurTransSum(ByVal vtaIdProsegur As String, _
                                        ByVal Tipo As Integer) As Long

    Dim rs As ADODB.Recordset
    Dim sq As String

    On Error GoTo ErrHandler

    Select Case Tipo
        Case 1
            sq = "SELECT NVL(BANK_CASH_AMOUNT,0) AS VALOR " & _
                 "FROM PROSEGUR_TRANS_SUM " & _
                 "WHERE ID_PRO_TRANS_SUM = " & vtaIdProsegur

        Case 2
            sq = "SELECT NVL(DIFFERENCE_AMOUNT,0) AS VALOR " & _
                 "FROM PROSEGUR_TRANS_SUM " & _
                 "WHERE ID_PRO_TRANS_SUM = " & vtaIdProsegur

        Case Else
            BuscarProsegurTransSum = 0
            Exit Function
    End Select

    Set rs = New ADODB.Recordset
    rs.Open sq, Ado_Conn, adOpenForwardOnly, adLockReadOnly

    If Not rs.EOF Then
        BuscarProsegurTransSum = CLng(rs!valor)
    Else
        BuscarProsegurTransSum = 0
    End If

    rs.Close
    Set rs = Nothing

    Exit Function

ErrHandler:
    BuscarProsegurTransSum = 0
    MsgBox "Error al buscar Prosegur: " & Err.Number & vbCrLf & Err.Description, vbCritical, "PROSEGUR"
End Function

