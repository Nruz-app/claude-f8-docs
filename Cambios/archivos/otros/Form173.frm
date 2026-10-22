VERSION 5.00
Object = "{5E9E78A0-531B-11CF-91F6-C2863C385E30}#1.0#0"; "MSFLXGRD.OCX"
Begin VB.Form Form173 
   BackColor       =   &H00E0E0E0&
   Caption         =   "Cuadratura Efectivo API vs Cartola Bancaria Detalle"
   ClientHeight    =   8865
   ClientLeft      =   2055
   ClientTop       =   1410
   ClientWidth     =   13275
   LinkTopic       =   "Form71"
   MaxButton       =   0   'False
   ScaleHeight     =   8865
   ScaleWidth      =   13275
   StartUpPosition =   2  'CenterScreen
   Visible         =   0   'False
   Begin VB.CommandButton Command4 
      BackColor       =   &H00A4E8CB&
      Caption         =   "&Excel"
      Height          =   375
      Index           =   1
      Left            =   360
      MaskColor       =   &H00000080&
      Style           =   1  'Graphical
      TabIndex        =   11
      Top             =   8040
      Width           =   1620
   End
   Begin VB.TextBox txtEdit 
      Height          =   285
      Left            =   6000
      TabIndex        =   10
      Top             =   8160
      Visible         =   0   'False
      Width           =   855
   End
   Begin VB.Frame Frame2 
      BackColor       =   &H00E0E0E0&
      Height          =   735
      Index           =   1
      Left            =   3240
      TabIndex        =   6
      Top             =   720
      Width           =   9855
      Begin VB.Label Label2 
         BackColor       =   &H00E0E0E0&
         Caption         =   "Sobre NO Depositados"
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
         Left            =   3720
         TabIndex        =   7
         Top             =   360
         Width           =   2295
      End
   End
   Begin VB.CommandButton Command3 
      BackColor       =   &H00A4E8CB&
      Caption         =   "&Salir"
      Height          =   375
      Index           =   0
      Left            =   11400
      MaskColor       =   &H00000080&
      Style           =   1  'Graphical
      TabIndex        =   5
      Top             =   8040
      Width           =   1500
   End
   Begin VB.PictureBox Picture1 
      Appearance      =   0  'Flat
      BackColor       =   &H00C0C0C0&
      BorderStyle     =   0  'None
      ForeColor       =   &H80000008&
      Height          =   570
      Left            =   10200
      Picture         =   "Form173.frx":0000
      ScaleHeight     =   570
      ScaleWidth      =   3135
      TabIndex        =   0
      Top             =   0
      Width           =   3135
   End
   Begin VB.Frame Frame1 
      BackColor       =   &H00E0E0E0&
      Height          =   735
      Index           =   0
      Left            =   120
      TabIndex        =   3
      Top             =   720
      Width           =   3015
      Begin VB.Label Label1 
         BackColor       =   &H00E0E0E0&
         Caption         =   "Sobre Depositados"
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
         Left            =   720
         TabIndex        =   4
         Top             =   360
         Width           =   2175
      End
   End
   Begin MSFlexGridLib.MSFlexGrid Grid1 
      Height          =   5775
      Index           =   0
      Left            =   120
      TabIndex        =   8
      Top             =   1560
      Width           =   3015
      _ExtentX        =   5318
      _ExtentY        =   10186
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
   Begin MSFlexGridLib.MSFlexGrid Grid1 
      Height          =   5775
      Index           =   1
      Left            =   3240
      TabIndex        =   9
      Top             =   1560
      Width           =   9855
      _ExtentX        =   17383
      _ExtentY        =   10186
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
   Begin MSFlexGridLib.MSFlexGrid Grid1 
      Height          =   375
      Index           =   2
      Left            =   0
      TabIndex        =   12
      Top             =   7440
      Width           =   3135
      _ExtentX        =   5530
      _ExtentY        =   661
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
   Begin MSFlexGridLib.MSFlexGrid Grid1 
      Height          =   375
      Index           =   3
      Left            =   3240
      TabIndex        =   13
      Top             =   7440
      Width           =   9855
      _ExtentX        =   17383
      _ExtentY        =   661
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
   Begin VB.Label Label2 
      BackColor       =   &H00E0E0E0&
      Caption         =   "V 0.2"
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
      Left            =   120
      TabIndex        =   14
      Top             =   8640
      Width           =   585
   End
   Begin VB.Image Image3 
      Height          =   1500
      Left            =   11160
      Picture         =   "Form173.frx":1644
      Top             =   600
      Width           =   2745
   End
   Begin VB.Label Label10 
      BackColor       =   &H00C0C0C0&
      Height          =   1245
      Left            =   13320
      TabIndex        =   2
      Top             =   -240
      Width           =   1065
   End
   Begin VB.Label Label11 
      BackColor       =   &H00C0C0C0&
      Height          =   10305
      Left            =   13800
      TabIndex        =   1
      Top             =   0
      Width           =   9015
   End
   Begin VB.Image Image1 
      Height          =   810
      Left            =   1620
      Picture         =   "Form173.frx":1930
      Top             =   -210
      Width           =   13590
   End
   Begin VB.Image Image2 
      Height          =   1830
      Left            =   -150
      Picture         =   "Form173.frx":1A08
      Top             =   -1230
      Width           =   4665
   End
End
Attribute VB_Name = "Form173"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Public vtaFechaVenta As String
Public vtaLocal As String
Dim ConsultaDet1 As ADODB.Recordset
Dim ConsultaDet2 As ADODB.Recordset
Dim sq As String
Dim row As Long
Private Const COL_EDITABLE As Integer = 6
Private ColSeleccionada As Integer
Private mEjecutando As Boolean
Private varIdProse As Long


Private Sub Command3_Click(Index As Integer)
    Unload Me
End Sub

Private Sub Command4_Click(Index As Integer)
    Call GeneraExcel
End Sub

Private Sub Form_Load()
    Call definegrid
    varIdProse = 0
End Sub
Private Sub definegrid()

    ' =====================
    ' GRID 1 (Grid1(0))
    ' =====================
    With Grid1(0)
        .Clear
        .Rows = 1
        .Cols = 3
        .RowHeight(0) = 300

        .ColWidth(0) = 1300
        .ColWidth(1) = 600
        .ColWidth(2) = 1000

        .FixedAlignment(0) = flexAlignCenterCenter
        .FixedAlignment(1) = flexAlignCenterCenter
        .FixedAlignment(2) = flexAlignCenterCenter

        .TextMatrix(0, 0) = "Fech Contable"
        .TextMatrix(0, 1) = "Local"
        .TextMatrix(0, 2) = "Monto"

        .ColAlignment(0) = flexAlignLeftCenter
        .ColAlignment(1) = flexAlignLeftCenter
        .ColAlignment(2) = flexAlignRightCenter
    End With

    ' =====================
    ' GRID 2 (Grid1(1))
    ' =====================
    With Grid1(1)
        .Clear
        .Rows = 1
        .Cols = 8
        .RowHeight(0) = 300

        .ColWidth(0) = 1100
        .ColWidth(1) = 1300
        .ColWidth(2) = 600
        .ColWidth(3) = 850
        .ColWidth(4) = 1200
        .ColWidth(5) = 1200
        .ColWidth(6) = 3500
        .ColWidth(7) = 0

        Dim i As Integer
        For i = 0 To .Cols - 1
            .FixedAlignment(i) = flexAlignCenterCenter
        Next i

        .TextMatrix(0, 0) = "Fech Venta"
        .TextMatrix(0, 1) = "Fech Contable"
        .TextMatrix(0, 2) = "Local"
        .TextMatrix(0, 3) = "Terminal"
        .TextMatrix(0, 4) = "Tipo Sobre"
        .TextMatrix(0, 5) = "Monto"
        .TextMatrix(0, 6) = "Código Barra"

        .ColAlignment(5) = flexAlignRightCenter
    End With
    Call definegrid2
    Call CargaGrilla

End Sub
Private Sub definegrid2()

    ' =====================
    ' GRID 1 (Grid1(2))
    ' =====================
    With Grid1(2)
        .Clear
        .Rows = 1
        .Cols = 2
        .RowHeight(0) = 300

        .ColWidth(0) = 1900
        .ColWidth(1) = 1200

        .FixedAlignment(0) = flexAlignCenterCenter
        .FixedAlignment(1) = flexAlignCenterCenter
        .ColAlignment(0) = flexAlignLeftCenter
        .ColAlignment(1) = flexAlignCenterCenter
    End With
    
    With Grid1(3)
        .Clear
        .Rows = 1
        .Cols = 3
        .RowHeight(0) = 300

        .ColWidth(0) = 5050
        .ColWidth(1) = 1200
        .ColWidth(2) = 3500
        
        .FixedAlignment(0) = flexAlignCenterCenter
        .FixedAlignment(1) = flexAlignCenterCenter
        .FixedAlignment(2) = flexAlignCenterCenter
        .ColAlignment(0) = flexAlignLeftCenter
        .ColAlignment(1) = flexAlignCenterCenter
        .ColAlignment(2) = flexAlignCenterCenter
    
    End With
    
End Sub
Private Sub CargaGrilla()

    On Error GoTo ErrHandler

    Dim VMensaje As String
    Dim row As Long
    Dim sq1
    Dim sq2
    Dim montoTotalDepositado As Currency
    Dim montoTotalNODepositado As Currency
    montoTotalDepositado = 0
    montoTotalNODepositado = 0
    ' =====================
    ' QUERY 1
    ' =====================
    
    sq1 = ""
    
    sq1 = sq1 & " SELECT "
    sq1 = sq1 & " TRUNC(PT.ACCOUNTING_DATE) AS fecha_contable, "
    sq1 = sq1 & " PT.SERVICE_POINT_CODE AS local, "
    sq1 = sq1 & " PT.TOTAL AS monto "
    sq1 = sq1 & " FROM PROSEGUR_TRANSACTIONS PT "
    sq1 = sq1 & " WHERE PT.SERVICE_POINT_CODE = " & vtaLocal
    sq1 = sq1 & " AND TRUNC(PT.ACCOUNTING_DATE) = TO_DATE('" & Format(CDate(vtaFechaVenta), "yyyy-mm-dd") & "','YYYY-MM-DD') "
    sq1 = sq1 & " AND PT.VALIDA = 1"

    'Debug.Print sq1
    
    Set ConsultaDet1 = New ADODB.Recordset
    ConsultaDet1.Open sq1, Ado_Conn, adOpenForwardOnly, adLockReadOnly

    Grid1(0).Rows = 1
    row = 1

    Do While Not ConsultaDet1.EOF

        Grid1(0).Rows = Grid1(0).Rows + 1

        ' Fecha
        If Not IsNull(ConsultaDet1.Fields("fecha_contable").Value) Then
            Grid1(0).TextMatrix(row, 0) = Format(ConsultaDet1.Fields("fecha_contable").Value, "dd-mm-yyyy")
        Else
            Grid1(0).TextMatrix(row, 0) = ""
        End If

        ' Local
        Grid1(0).TextMatrix(row, 1) = ConsultaDet1.Fields("local").Value

        ' Monto
        If Not IsNull(ConsultaDet1.Fields("monto").Value) Then
            Grid1(0).TextMatrix(row, 2) = Format(ConsultaDet1.Fields("monto").Value, "#,##0")
            montoTotalDepositado = montoTotalDepositado + ConsultaDet1.Fields("monto").Value
        Else
            Grid1(0).TextMatrix(row, 2) = "0"
        End If

        row = row + 1
        ConsultaDet1.MoveNext

    Loop

    ConsultaDet1.Close

    ' =====================
    ' QUERY 2
    ' =====================

    sq2 = ""

    sq2 = sq2 & " SELECT "
    sq2 = sq2 & " TRUNC(PT.TRANSACTION_DATE) AS fecha_venta, "
    sq2 = sq2 & " TRUNC(PT.ACCOUNTING_DATE) AS fecha_contable, "
    sq2 = sq2 & " PT.SERVICE_POINT_CODE AS local, "
    sq2 = sq2 & " PT.DEVICE_ID AS terminal, "
    sq2 = sq2 & " PT.TYPE_CODE AS tipo_sobre, "
    sq2 = sq2 & " PT.TOTAL AS monto, "
    sq2 = sq2 & " LPAD(TO_CHAR(PT.BARCODE), 30, '0') AS codigo_barra, "
    sq2 = sq2 & " PT.ID AS id "
    sq2 = sq2 & " FROM PROSEGUR_TRANSACTIONS PT "
    sq2 = sq2 & " WHERE "
    '   PT.SERVICE_POINT_CODE = " & vtaLocal
    'sq2 = sq2 & " AND TRUNC(PT.ACCOUNTING_DATE) = TO_DATE('" & Format(CDate(vtaFechaVenta), "yyyy-mm-dd") & "','YYYY-MM-DD') "
    sq2 = sq2 & " PT.VALIDA = 0"

    'Debug.Print sq2

    Set ConsultaDet2 = New ADODB.Recordset
    ConsultaDet2.Open sq2, Ado_Conn, adOpenForwardOnly, adLockReadOnly

    Grid1(1).Rows = 1
    row = 1

    Do While Not ConsultaDet2.EOF

        Grid1(1).Rows = Grid1(1).Rows + 1

        ' Fecha venta
        If Not IsNull(ConsultaDet2.Fields("fecha_venta").Value) Then
            Grid1(1).TextMatrix(row, 0) = Format(ConsultaDet2.Fields("fecha_venta").Value, "dd-mm-yyyy")
        Else
            Grid1(1).TextMatrix(row, 0) = ""
        End If

        ' Fecha contable
        If Not IsNull(ConsultaDet2.Fields("fecha_contable").Value) Then
            Grid1(1).TextMatrix(row, 1) = Format(ConsultaDet2.Fields("fecha_contable").Value, "dd-mm-yyyy")
        Else
            Grid1(1).TextMatrix(row, 1) = ""
        End If

        Grid1(1).TextMatrix(row, 2) = ConsultaDet2.Fields("local").Value
        Grid1(1).TextMatrix(row, 3) = ConsultaDet2.Fields("terminal").Value
        Grid1(1).TextMatrix(row, 4) = ConsultaDet2.Fields("tipo_sobre").Value

        ' Monto
        If Not IsNull(ConsultaDet2.Fields("monto").Value) Then
            Grid1(1).TextMatrix(row, 5) = Format(ConsultaDet2.Fields("monto").Value, "#,##0")
            montoTotalNODepositado = montoTotalNODepositado + ConsultaDet2.Fields("monto").Value
        Else
            Grid1(1).TextMatrix(row, 5) = "0"
        End If

        Grid1(1).TextMatrix(row, 6) = ConsultaDet2.Fields("codigo_barra").Value
        Grid1(1).TextMatrix(row, 7) = ConsultaDet2.Fields("id").Value

        row = row + 1
        ConsultaDet2.MoveNext

    Loop
    
    ConsultaDet2.Close
    
    ' TOTALES
    Grid1(2).Rows = 1
    
    ' Texto correcto
    Grid1(2).TextMatrix(0, 0) = "Totales"
    Grid1(2).TextMatrix(0, 1) = Format(montoTotalDepositado, "#,##0")
    
    ' Posicionarse en la fila
    Grid1(2).row = 0
    
    'Columna 0 amarilla
    Grid1(2).col = 0
    Grid1(2).CellBackColor = RGB(255, 255, 153)
    Grid1(2).CellAlignment = flexAlignLeftCenter
    
    Grid1(2).col = 1
    Grid1(2).CellBackColor = vbWhite
    Grid1(2).CellAlignment = flexAlignRightCenter
    
    Grid1(3).Rows = 1
    
    ' Texto correcto
    Grid1(3).TextMatrix(0, 0) = "Totales"
    Grid1(3).TextMatrix(0, 1) = Format(montoTotalNODepositado, "#,##0")
    
    ' Posicionarse en la fila
    Grid1(3).row = 0
    
    'Columna 0 amarilla
    Grid1(3).col = 0
    Grid1(3).CellBackColor = RGB(255, 255, 153)
    Grid1(3).CellAlignment = flexAlignLeftCenter
    
    Grid1(3).col = 1
    Grid1(3).CellBackColor = vbWhite
    Grid1(3).CellAlignment = flexAlignRightCenter
    
    Grid1(3).col = 2
    Grid1(3).CellBackColor = vbWhite
    Grid1(3).CellAlignment = flexAlignRightCenter
    
    
    Exit Sub

' =====================
' MANEJO DE ERRORES
' =====================
ErrHandler:
    MsgBox "Error en CargaGrilla: " & Err.Description, vbCritical
    If Not ConsultaDet1 Is Nothing Then
        If ConsultaDet1.State = 1 Then ConsultaDet1.Close
    End If
    If Not ConsultaDet2 Is Nothing Then
        If ConsultaDet2.State = 1 Then ConsultaDet2.Close
    End If

End Sub

Private Sub Form_Unload(Cancel As Integer)
Form172.Buscar


End Sub

Private Sub Grid1_DblClick(Index As Integer)

    ' Solo Grid1(1)
    If Index <> 1 Then Exit Sub

    With Grid1(Index)

        ' No encabezado
        If .row = 0 Then Exit Sub

        ' Solo columna 6
        If ColSeleccionada <> COL_EDITABLE Then Exit Sub

        txtEdit.Left = .Left + .CellLeft
        txtEdit.Top = .Top + .CellTop
        txtEdit.Width = .CellWidth
        txtEdit.Height = .CellHeight

        txtEdit.Text = .TextMatrix(.row, COL_EDITABLE)
        txtEdit.Tag = Index
        txtEdit.Visible = True
        txtEdit.SetFocus
        txtEdit.SelStart = 0
        txtEdit.SelLength = Len(txtEdit.Text)
        varIdProse = CLng(.TextMatrix(.row, 7))

    End With

End Sub

Private Sub Grid1_MouseDown(Index As Integer, Button As Integer, Shift As Integer, X As Single, Y As Single)

     With Grid1(Index)
        If .MouseRow > 0 And .MouseRow < .Rows Then
            If .MouseCol >= 0 And .MouseCol < .Cols Then
                .row = .MouseRow
                .col = .MouseCol
                ColSeleccionada = .col
            End If
        End If
    End With

End Sub

Private Sub txtEdit_KeyPress(KeyAscii As Integer)

    If KeyAscii = vbKeyReturn Then
        GuardarEdicion
        KeyAscii = 0
    End If

End Sub

Private Sub GuardarEdicion()

    Dim codigoBarra As String
    Dim codigoBarraForm As String
    Dim idx As Integer

    Dim vtaId As Long
    Dim vtaFecha As Date
    Dim vtaLocal As Long
    Dim vtaTerminal As Long
    Dim VMensaje As String
    Dim fechaTexto As String
    Dim fechaFormateada As String
    Dim dia As Integer
    Dim mes As Integer
    Dim anio As Integer
    
    mEjecutando = False
    codigoBarra = Trim(txtEdit.Text)
   
    If Len(codigoBarra) <> 30 Then
        MsgBox "El código de barra debe tener EXACTAMENTE 30 caracteres. Largo actual: " & Len(codigoBarra), vbExclamation
        Exit Sub
    End If

    'Comentado 20-07-2026
    'If Right(codigoBarra, 1) = "0" Then
    '    MsgBox "El último carácter del código de barra no puede ser 0.", vbExclamation
    '    Exit Sub
    'End If

    idx = CInt(txtEdit.Tag)

    With Grid1(idx)

        If .row <= 0 Or .row >= .Rows Then Exit Sub
        If .col < 0 Or .col >= .Cols Then Exit Sub

        ' Guardar sin modificar
        .TextMatrix(.row, .col) = codigoBarra

        If .Cols > 7 Then

            If Trim(.TextMatrix(.row, 7)) <> "" Then

                If CLng(.TextMatrix(.row, 7)) > 0 Then

                    vtaId = CLng(.TextMatrix(.row, 7))
                    
                    codigoBarraForm = "0" & Left(codigoBarra, Len(codigoBarra) - 1)
                    
                    fechaTexto = Mid$(codigoBarraForm, 11, 6)

                    dia = Val(Left$(fechaTexto, 2))
                    mes = Val(Mid$(fechaTexto, 3, 2))
                    anio = Val(Right$(fechaTexto, 2))
                    
                    If mes < 1 Or mes > 12 Then
                        MsgBox "Mes inválido en código: " & fechaTexto, vbExclamation
                        Exit Sub
                    End If
                    
                    If dia < 1 Or dia > 31 Then
                        MsgBox "Día inválido en código: " & fechaTexto, vbExclamation
                        Exit Sub
                    End If
                    
                    fechaFormateada = "20" & Right$(fechaTexto, 2) & "-" & _
                                      Mid$(fechaTexto, 3, 2) & "-" & _
                                      Left$(fechaTexto, 2)
                    
                    vtaFecha = CDate(fechaFormateada)
                    vtaLocal = CLng(Mid$(codigoBarraForm, 19, 4))
                    vtaTerminal = CLng(Mid$(codigoBarraForm, 23, 4))
                    

                End If
            End If
        End If

    End With

    txtEdit.Visible = False

    If vtaId > 0 And vtaId = varIdProse Then

        VMensaje = ExisteVtaTempEsc(vtaId, vtaLocal, vtaTerminal, vtaFecha, codigoBarra)

        If InStr(1, VMensaje, "PKG OK", vbTextCompare) > 0 Then
            
            MsgBox "La transacción fue procesada correctamente." & vbCrLf & vbCrLf & _
               "Código de barra: " & codigoBarra & vbCrLf & _
               "Local: " & vtaLocal & vbCrLf & _
               "Terminal: " & vtaTerminal & vbCrLf & _
               "Fecha: " & Format(vtaFecha, "dd-mm-yyyy"), _
               vbInformation, "Proceso exitoso"
            
            Call definegrid
        ElseIf InStr(1, VMensaje, "ORA-00001", vbTextCompare) > 0 Then
            MsgBox "El registro ya existe (PK duplicada)." & vbCrLf & VMensaje, vbExclamation
        Else
            MsgBox "No existe asociación para el código " & codigoBarra & vbCrLf & VMensaje, vbExclamation
            Call definegrid
        End If
        
    End If

End Sub
Public Function ExisteVtaTempEsc( _
        ByVal vtaId As Long, _
        ByVal vtaLocal As Long, _
        ByVal vtaTerminal As Long, _
        ByVal vtaFecha As String, _
        ByVal codigoBarra As String) As String

    On Error GoTo ErrHandler

    Dim cmd As ADODB.Command
    Dim VMensaje As String
    Dim vtaFechaForm As String
    Dim FlgPais As String

    Set cmd = New ADODB.Command
    Set cmd.ActiveConnection = Ado_Conn
    
    If mEjecutando Then
        Debug.Print "SKIP: ya se estaba ejecutando"
        Exit Function
    End If
    
    mEjecutando = True
    Debug.Print "INICIO LLAMADA PKG: " & Now

    
    vtaFechaForm = Mid(vtaFecha, 7, 4) & "-" & Mid(vtaFecha, 4, 2) & "-" & Left(vtaFecha, 2)
    
    FlgPais = Flg_Pais$

    With cmd
        .CommandType = adCmdText
        '.NamedParameters = False   ' ?? CLAVE con Oracle
        .CommandText = "BEGIN F8_TRANSACC_DEPO_PKG.EXISTE_VTA_TEMPESC(?,?,?,?,?,?,?); END;"

        ' ?? IMPORTANTE: orden EXACTO del procedimiento
        .Parameters.Append .CreateParameter(, adInteger, adParamInput, , vtaId)
        .Parameters.Append .CreateParameter(, adInteger, adParamInput, , vtaLocal)
        .Parameters.Append .CreateParameter(, adInteger, adParamInput, , vtaTerminal)
        .Parameters.Append .CreateParameter(, adVarChar, adParamInput, 20, vtaFechaForm)
        .Parameters.Append .CreateParameter(, adVarChar, adParamInput, 100, codigoBarra)
        .Parameters.Append .CreateParameter(, adVarChar, adParamInput, 20, FlgPais)
        .Parameters.Append .CreateParameter(, adVarChar, adParamOutput, 4000)

        .Execute
    End With
    'Obtener OUT
    If IsNull(cmd.Parameters(6).Value) Then
        VMensaje = ""
    Else
        VMensaje = CStr(cmd.Parameters(6).Value)
    End If

    mEjecutando = False
    ExisteVtaTempEsc = VMensaje

    Set cmd = Nothing
    Exit Function

ErrHandler:
    ExisteVtaTempEsc = "ERROR: " & Err.Number & " - " & Err.Description
    Set cmd = Nothing

End Function
Private Sub GeneraExcel()

On Error GoTo ErrHandler

Dim xlApp As Object
Dim xlBook As Object
Dim xlSheet As Object

Dim i As Long
Dim j As Long
Dim filaExcel As Long

Dim TotalValidas As Currency
Dim TotalNoValidas As Currency

Dim valor As String
Dim Paso As String

Paso = "Crear Excel"

Set xlApp = CreateObject("Excel.Application")

Paso = "Crear Workbook"

Set xlBook = xlApp.Workbooks.Add

Paso = "Obtener hoja"

Set xlSheet = xlBook.Sheets(1)

Paso = "Nombrar hoja"

xlSheet.Name = "Reporte"

Paso = "Crear título"

With xlSheet.Range("A1:H1")
    .Merge
    .Value = "REPORTE PROSEGUR"
    .Font.Bold = True
    .Font.Size = 14
    .HorizontalAlignment = -4108
End With

filaExcel = 3

Paso = "Título Depositados"

xlSheet.Cells(filaExcel, 1).Value = "DEPOSITADOS"
xlSheet.Cells(filaExcel, 1).Font.Bold = True
xlSheet.Cells(filaExcel, 1).Font.Size = 12

filaExcel = filaExcel + 1

Paso = "Encabezados Depositados"

For j = 0 To Grid1(0).Cols - 1

    xlSheet.Cells(filaExcel, j + 1).Value = _
        Grid1(0).TextMatrix(0, j)

    With xlSheet.Cells(filaExcel, j + 1)
        .Font.Bold = True
        .Interior.Color = RGB(220, 220, 220)
    End With

Next j

filaExcel = filaExcel + 1

Paso = "Datos Depositados"

If Grid1(0).Rows > 1 Then

    For i = 1 To Grid1(0).Rows - 1

        For j = 0 To Grid1(0).Cols - 1

            valor = Trim$(Grid1(0).TextMatrix(i, j))

            If j = 0 Then

                ' FECHA CONTABLE
                If valor <> "" Then

                    xlSheet.Cells(filaExcel, j + 1).Value = _
                        ConvertirFechaExcel(valor)

                    If IsDate(xlSheet.Cells(filaExcel, j + 1).Value) Then
                        xlSheet.Cells(filaExcel, j + 1).NumberFormat = "dd-mm-yyyy"
                    End If

                Else

                    xlSheet.Cells(filaExcel, j + 1).Value = ""

                End If

            ElseIf j = 2 Then

                ' MONTO
                If valor <> "" Then

                    valor = Replace(valor, ".", "")

                    If IsNumeric(valor) Then

                        xlSheet.Cells(filaExcel, j + 1).Value = _
                            CLng(valor)

                        xlSheet.Cells(filaExcel, j + 1).NumberFormat = "#,##0"

                    Else

                        xlSheet.Cells(filaExcel, j + 1).Value = valor

                    End If

                Else

                    xlSheet.Cells(filaExcel, j + 1).Value = ""

                End If

            Else

                xlSheet.Cells(filaExcel, j + 1).Value = valor

            End If

        Next j

        ' CALCULAR TOTAL DEPOSITADOS
        valor = Trim$(Grid1(0).TextMatrix(i, 2))

        If valor <> "" Then

            valor = Replace(valor, ".", "")

            If IsNumeric(valor) Then
                TotalValidas = TotalValidas + CCur(valor)
            End If

        End If

        filaExcel = filaExcel + 1

    Next i

End If

Paso = "Total Depositados"

With xlSheet.Range("A" & filaExcel & ":B" & filaExcel)
    .Merge
    .Value = "TOTAL DEPOSITADOS"
    .Font.Bold = True
    .HorizontalAlignment = -4152
    .Interior.Color = RGB(255, 255, 153)
End With

With xlSheet.Cells(filaExcel, 3)
    .Value = TotalValidas
    .Font.Bold = True
    .NumberFormat = "#,##0"
    .Interior.Color = RGB(255, 255, 153)
End With

filaExcel = filaExcel + 3

Paso = "Título No Depositados"

xlSheet.Cells(filaExcel, 1).Value = "NO DEPOSITADOS"
xlSheet.Cells(filaExcel, 1).Font.Bold = True
xlSheet.Cells(filaExcel, 1).Font.Size = 12

filaExcel = filaExcel + 1

Paso = "Encabezados No Depositados"

For j = 0 To Grid1(1).Cols - 1

    If Grid1(1).ColWidth(j) > 0 Then

        xlSheet.Cells(filaExcel, j + 1).Value = _
            Grid1(1).TextMatrix(0, j)

        With xlSheet.Cells(filaExcel, j + 1)
            .Font.Bold = True
            .Interior.Color = RGB(220, 220, 220)
        End With

    End If

Next j

filaExcel = filaExcel + 1

Paso = "Datos No Depositados"

If Grid1(1).Rows > 1 Then

    For i = 1 To Grid1(1).Rows - 1

        For j = 0 To Grid1(1).Cols - 1

            If Grid1(1).ColWidth(j) > 0 Then

                valor = Trim$(Grid1(1).TextMatrix(i, j))

                If j = 5 Then

                    ' MONTO
                    If valor <> "" Then

                        valor = Replace(valor, ".", "")

                        If IsNumeric(valor) Then

                            xlSheet.Cells(filaExcel, j + 1).Value = _
                                CLng(valor)

                            xlSheet.Cells(filaExcel, j + 1).NumberFormat = "#,##0"

                        Else

                            xlSheet.Cells(filaExcel, j + 1).Value = valor

                        End If

                    Else

                        xlSheet.Cells(filaExcel, j + 1).Value = ""

                    End If

                ElseIf j = 6 Then

                    ' CÓDIGO DE BARRAS COMO TEXTO
                    xlSheet.Cells(filaExcel, j + 1).NumberFormat = "@"

                    xlSheet.Cells(filaExcel, j + 1).Value = _
                        "'" & valor

                ElseIf j = 0 Or j = 1 Then

                    ' FECHA VENTA Y FECHA CONTABLE
                    If valor <> "" Then

                        xlSheet.Cells(filaExcel, j + 1).Value = _
                            ConvertirFechaExcel(valor)

                        If IsDate(xlSheet.Cells(filaExcel, j + 1).Value) Then
                            xlSheet.Cells(filaExcel, j + 1).NumberFormat = "dd-mm-yyyy"
                        End If

                    Else

                        xlSheet.Cells(filaExcel, j + 1).Value = ""

                    End If

                Else

                    xlSheet.Cells(filaExcel, j + 1).Value = valor

                End If

            End If

        Next j

        ' CALCULAR TOTAL NO DEPOSITADOS
        valor = Trim$(Grid1(1).TextMatrix(i, 5))

        If valor <> "" Then

            valor = Replace(valor, ".", "")

            If IsNumeric(valor) Then
                TotalNoValidas = TotalNoValidas + CCur(valor)
            End If

        End If

        filaExcel = filaExcel + 1

    Next i

End If

Paso = "Total No Depositados"

With xlSheet.Range("A" & filaExcel & ":E" & filaExcel)
    .Merge
    .Value = "TOTAL NO DEPOSITADOS"
    .Font.Bold = True
    .HorizontalAlignment = -4152
    .Interior.Color = RGB(255, 255, 153)
End With

With xlSheet.Cells(filaExcel, 6)
    .Value = TotalNoValidas
    .Font.Bold = True
    .NumberFormat = "#,##0"
    .Interior.Color = RGB(255, 255, 153)
End With

Paso = "AutoFit columnas"

xlSheet.Columns.AutoFit

Paso = "Aplicar bordes"

If xlSheet.UsedRange.Rows.Count > 0 Then

    With xlSheet.UsedRange.Borders
        .LineStyle = 1
    End With

End If

Paso = "Mostrar Excel"

xlApp.Visible = True

Set xlSheet = Nothing
Set xlBook = Nothing
Set xlApp = Nothing

Exit Sub

ErrHandler:

MsgBox "Error al generar Excel" & vbCrLf & vbCrLf & _
       "Número: " & Err.Number & vbCrLf & _
       "Descripción: " & Err.Description & vbCrLf & _
       "Paso: " & Paso, _
       vbCritical, _
       "F8.Automatico"

On Error Resume Next

If Not xlBook Is Nothing Then
    xlBook.Close False
End If

If Not xlApp Is Nothing Then
    xlApp.Quit
End If

Set xlSheet = Nothing
Set xlBook = Nothing
Set xlApp = Nothing

End Sub


Private Function ConvertirFechaExcel(ByVal fechaTexto As String) As Variant

Dim partes() As String
Dim dia As Integer
Dim mes As Integer
Dim anio As Integer
Dim fecha As Date

On Error GoTo FechaInvalida

fechaTexto = Trim$(fechaTexto)

If fechaTexto = "" Then
    ConvertirFechaExcel = ""
    Exit Function
End If

partes = Split(fechaTexto, "-")

If UBound(partes) <> 2 Then
    ConvertirFechaExcel = fechaTexto
    Exit Function
End If

If Not IsNumeric(partes(0)) Or _
   Not IsNumeric(partes(1)) Or _
   Not IsNumeric(partes(2)) Then

    ConvertirFechaExcel = fechaTexto
    Exit Function

End If

dia = CInt(partes(0))
mes = CInt(partes(1))
anio = CInt(partes(2))

If Len(Trim$(partes(2))) = 2 Then
    anio = 2000 + anio
End If

If anio < 1900 Or anio > 9999 Then GoTo FechaInvalida
If mes < 1 Or mes > 12 Then GoTo FechaInvalida
If dia < 1 Or dia > 31 Then GoTo FechaInvalida

fecha = DateSerial(anio, mes, dia)

' Evitar que DateSerial normalice fechas inexistentes
If Day(fecha) <> dia Or _
   Month(fecha) <> mes Or _
   Year(fecha) <> anio Then

    GoTo FechaInvalida

End If

ConvertirFechaExcel = fecha
Exit Function


FechaInvalida:

ConvertirFechaExcel = fechaTexto

End Function


