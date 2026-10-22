VERSION 5.00
Object = "{5E9E78A0-531B-11CF-91F6-C2863C385E30}#1.0#0"; "MSFLXGRD.OCX"
Object = "{F9043C88-F6F2-101A-A3C9-08002B2F49FB}#1.2#0"; "COMDLG32.OCX"
Begin VB.Form Form133 
   Appearance      =   0  'Flat
   BackColor       =   &H00E6E8E8&
   BorderStyle     =   3  'Fixed Dialog
   Caption         =   "Interfaz de Carga Manual de Sobres"
   ClientHeight    =   10095
   ClientLeft      =   45
   ClientTop       =   330
   ClientWidth     =   16575
   Icon            =   "Form133.frx":0000
   LinkTopic       =   "Form133"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   10095
   ScaleWidth      =   16575
   ShowInTaskbar   =   0   'False
   StartUpPosition =   1  'CenterOwner
   Begin VB.TextBox Text3 
      Height          =   285
      Left            =   2640
      TabIndex        =   23
      Top             =   9690
      Visible         =   0   'False
      Width           =   855
   End
   Begin VB.CommandButton Command2 
      BackColor       =   &H00A4E8CB&
      Caption         =   "&Salir"
      Height          =   375
      Left            =   14520
      Style           =   1  'Graphical
      TabIndex        =   20
      Top             =   9600
      Width           =   1335
   End
   Begin VB.Frame Frame3 
      BackColor       =   &H00E6E8E8&
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
      Height          =   1095
      Left            =   120
      TabIndex        =   8
      Top             =   720
      Width           =   15855
      Begin VB.ComboBox Combo4 
         ForeColor       =   &H00000080&
         Height          =   315
         Left            =   1680
         Style           =   2  'Dropdown List
         TabIndex        =   17
         Top             =   480
         Width           =   3255
      End
      Begin VB.ComboBox Combo1 
         ForeColor       =   &H00000080&
         Height          =   315
         Left            =   3840
         Style           =   2  'Dropdown List
         TabIndex        =   16
         Top             =   240
         Visible         =   0   'False
         Width           =   1095
      End
      Begin VB.CommandButton Command4 
         BackColor       =   &H00A4E8CB&
         Caption         =   "&Cargar Archivo"
         Height          =   375
         Left            =   14280
         Style           =   1  'Graphical
         TabIndex        =   13
         Top             =   480
         Width           =   1335
      End
      Begin VB.CommandButton Command3 
         BackColor       =   &H00A4E8CB&
         Caption         =   "&Buscar"
         Height          =   315
         Left            =   11160
         Style           =   1  'Graphical
         TabIndex        =   12
         Top             =   480
         Width           =   855
      End
      Begin VB.TextBox Text1 
         Height          =   315
         Left            =   6960
         TabIndex        =   11
         Top             =   480
         Width           =   4215
      End
      Begin VB.Label Label3 
         BackStyle       =   0  'Transparent
         Caption         =   "Recaudador"
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
         Left            =   360
         TabIndex        =   18
         Top             =   550
         Width           =   1095
      End
      Begin VB.Label Label6 
         BackColor       =   &H00E6E8E8&
         Caption         =   "Label6"
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
         TabIndex        =   15
         Top             =   8880
         Visible         =   0   'False
         Width           =   5775
      End
      Begin VB.Label Label4 
         BackStyle       =   0  'Transparent
         Caption         =   "Recaudador"
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
         Left            =   1200
         TabIndex        =   14
         Top             =   3120
         Width           =   1095
      End
      Begin VB.Label Label2 
         BackStyle       =   0  'Transparent
         Caption         =   "Nombre Archivo"
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
         Left            =   5400
         TabIndex        =   10
         Top             =   550
         Width           =   1575
      End
   End
   Begin VB.PictureBox Picture1 
      Appearance      =   0  'Flat
      BackColor       =   &H00C0C0C0&
      BorderStyle     =   0  'None
      ForeColor       =   &H80000008&
      Height          =   810
      Left            =   13440
      Picture         =   "Form133.frx":030A
      ScaleHeight     =   810
      ScaleWidth      =   2295
      TabIndex        =   3
      Top             =   -240
      Width           =   2295
   End
   Begin MSFlexGridLib.MSFlexGrid Grid2 
      Height          =   7575
      Left            =   120
      TabIndex        =   19
      Top             =   1920
      Width           =   15855
      _ExtentX        =   27966
      _ExtentY        =   13361
      _Version        =   393216
      Cols            =   1
      FixedCols       =   0
      BackColor       =   16119285
      ForeColor       =   128
      BackColorFixed  =   10807499
      ForeColorFixed  =   3560496
      BackColorSel    =   13692411
      ForeColorSel    =   128
      BackColorBkg    =   15132904
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
   Begin VB.Frame Frame2 
      BackColor       =   &H00E6E8E8&
      Caption         =   "Parámetros de Selección"
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
      Height          =   6855
      Left            =   840
      TabIndex        =   6
      Top             =   2160
      Width           =   3735
      Begin VB.CommandButton Command1 
         BackColor       =   &H00A4E8CB&
         Cancel          =   -1  'True
         Caption         =   "&Aceptar"
         Height          =   375
         Left            =   3120
         Style           =   1  'Graphical
         TabIndex        =   9
         Top             =   8760
         Width           =   1335
      End
      Begin MSFlexGridLib.MSFlexGrid Grid1 
         Height          =   5775
         Left            =   360
         TabIndex        =   7
         Top             =   1920
         Width           =   4335
         _ExtentX        =   7646
         _ExtentY        =   10186
         _Version        =   393216
         Cols            =   13
         FixedCols       =   0
         BackColor       =   16119285
         ForeColor       =   128
         BackColorFixed  =   10807499
         ForeColorFixed  =   3560496
         BackColorSel    =   13692411
         ForeColorSel    =   128
         BackColorBkg    =   15132904
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
      Begin MSComDlg.CommonDialog CmDlog 
         Left            =   240
         Top             =   8760
         _ExtentX        =   847
         _ExtentY        =   847
         _Version        =   393216
      End
   End
   Begin VB.Label label_cant 
      BackStyle       =   0  'Transparent
      Caption         =   "Cant de Registros cargados"
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
      Left            =   120
      TabIndex        =   22
      Top             =   9720
      Visible         =   0   'False
      Width           =   3015
   End
   Begin VB.Label Label7 
      BackStyle       =   0  'Transparent
      Caption         =   "Recaudador"
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
      Left            =   2640
      TabIndex        =   21
      Top             =   5400
      Width           =   1095
   End
   Begin VB.Image Image3 
      Height          =   1500
      Left            =   13350
      Picture         =   "Form133.frx":194E
      Top             =   580
      Width           =   2745
   End
   Begin VB.Label Label10 
      BackColor       =   &H00C0C0C0&
      Height          =   1005
      Left            =   15600
      TabIndex        =   4
      Top             =   0
      Width           =   1065
   End
   Begin VB.Label Label11 
      BackColor       =   &H00C0C0C0&
      Height          =   10305
      Left            =   16080
      TabIndex        =   5
      Top             =   960
      Width           =   495
   End
   Begin VB.Image Image2 
      Height          =   1830
      Left            =   -150
      Picture         =   "Form133.frx":1C3A
      Top             =   -1230
      Width           =   4665
   End
   Begin VB.Image Image1 
      Height          =   810
      Left            =   2400
      Picture         =   "Form133.frx":1F1E
      Top             =   -210
      Width           =   13590
   End
   Begin VB.Label Label5 
      Alignment       =   1  'Right Justify
      BackColor       =   &H00C0FFFF&
      BorderStyle     =   1  'Fixed Single
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   8.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00800000&
      Height          =   375
      Left            =   7800
      TabIndex        =   2
      Top             =   6120
      Visible         =   0   'False
      Width           =   1545
   End
   Begin VB.Label tot_2 
      BackStyle       =   0  'Transparent
      Caption         =   "Total"
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
      Left            =   3870
      TabIndex        =   1
      Top             =   5070
      Width           =   735
   End
   Begin VB.Label Label1 
      Alignment       =   1  'Right Justify
      BackColor       =   &H00E1FDFD&
      BorderStyle     =   1  'Fixed Single
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
      Height          =   375
      Left            =   10460
      TabIndex        =   0
      Top             =   4980
      Width           =   1815
   End
End
Attribute VB_Name = "Form133"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Private obj_Excel       As Object
Private obj_Workbook    As Object
Private obj_Worksheet   As Object
Dim Cierrey As Double
Private Sub Command1_Click()
'If Combo4.Text = "" Then
'    MsgBox "Seleccione Recaudador"
'    Exit Sub
'End If
'Call CargaLista(True)
'Command3.Visible = True
End Sub

Private Sub Command2_Click()
Unload Me
End Sub

Private Sub Command3_Click()
Dim RecaudacionSinCajero As Boolean
    Label6.Caption = ""
    CmDlog.filename = ""
    CmDlog.ShowOpen
    nomFile = CmDlog.filename
    
    'SRF 167735 - F8 Sodimac ARG
    If nomFile = "" Then
        MsgBox "Debe seleccionar un archivo", vbCritical + vbDefaultButton1, Me.Caption
        Exit Sub
    End If
    
    Text1.Text = nomFile
    Text3.Text = ""
    
    RecaudacionSinCajero = False
    
    If CmDlog.filename = "" Then Exit Sub
    
    Screen.MousePointer = 11
    Call Excel_FlexGrid(CStr(nomFile), Grid2, Grid2.Cols, 5)

    Command4.Visible = True
    
    If Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Then
        Dim xpros As String
        Dim xlocal As String
        Dim X As Integer
        Dim xError As Integer
        xError = 0
                
        Grid2.Cols = Grid2.Cols + 2
        xVar = Grid2.Cols
        
        Grid2.TextMatrix(0, xVar - 2) = "Cajero"
        Grid2.TextMatrix(0, xVar - 1) = "Local"
        
        For i = 1 To Grid2.Rows - 1
            xpros = Mid(Grid2.TextMatrix(i, 3), 1, 12)
            xlocal = GetLocal(xpros)
            Grid2.TextMatrix(i, xVar - 1) = xlocal
            
            Rem RMOYAG 20170314 F8 SOUY - Estabilizaciom F8
            Rem Problema:El campo vta_idprosegur lo está trabajando como numérico, y en el Excel se informa (Cashier Id) como alfanumérico con ceros a la derecha
            Rem Respaldo
            'Grid2.TextMatrix(i, xVar - 2) = GetVendedor(Mid(Grid2.TextMatrix(i, 3), 15, Len(Grid2.TextMatrix(i, 3))), xlocal)
            If Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Then
                Grid2.TextMatrix(i, xVar - 2) = GetVendedor(Val(Mid(Grid2.TextMatrix(i, 3), 15, Len(Grid2.TextMatrix(i, 3)))), xlocal)
            Else
                Grid2.TextMatrix(i, xVar - 2) = GetVendedor(Mid(Grid2.TextMatrix(i, 3), 15, Len(Grid2.TextMatrix(i, 3))), xlocal)
            End If
            
            If Trim(Grid2.TextMatrix(i, xVar - 2)) = "-1" Then
                Call PintaData(CInt(i), CInt(xVar - 1))
                xError = xError + 1
                RecaudacionSinCajero = True
            End If
            X = i
        Next i
        Text3.Text = X
    End If
    
    Screen.MousePointer = 0
    If RecaudacionSinCajero Then
        MsgBox "Proceso de despliegue completado con éxito," & Chr(13) & "pero se encontraron recaudaciones sin cajero asociado(Filas marcadas en Rojo).", vbInformation
    Else
        MsgBox "Proceso de despliegue completado con éxito.", vbInformation
    End If
    Label6.Caption = Grid2.Rows - 1 & " Registro(s)"
End Sub


Private Sub CargaLista(OK As Boolean)
Set Consulta = CreateObject("ADODB.Recordset")
With Consulta
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With

'strArray = Split(Combo4.Text, "-")
'numeroLocal = Trim(strArray(0))

    Call DefineGrilla
 
    sq = " SELECT "
    sq = sq & " P.VTA_DEFAULT"
    sq = sq & " ,P.VTA_HOMOLOGA"
    sq = sq & " ,P.VTA_NOM_COL"
    sq = sq & " ,P.VTA_VALORDEFAULT"
    sq = sq & " ,P.VTA_TIPOVAR"
    sq = sq & " ,(ROW_NUMBER() OVER (ORDER BY p.vta_orden asc)-1) rn"
    sq = sq & " FROM VTA_HOMOLOGA_PRD P"
    sq = sq & " WHERE P.VTA_LOCALIZ = '" & Flg_Pais$ & "'"
'    If ok = True Then
'        sq = sq & " and p.vta_default = 'N'"
'    End If
    sq = sq & " ORDER BY P.VTA_ORDEN ASC"
    
    Call Consulta.Open(sq)
    X = Consulta.RecordCount
    
    If X = 0 Then
        MsgBox "No hay datos en parámetros, informe a su proveedor de servicios IT"
        Exit Sub
    End If
    
    ReDim check(X) As String
    Const strChecked = "þ"
    Const strUnChecked = "q"


    For i = 1 To X
        Grid1.AddItem " "
        Grid1.TextMatrix(i, 0) = ""
        If Consulta.Fields(0).Value = "N" Then
            check(i) = strChecked
        Else
            check(i) = strUnChecked
        End If
        Grid1.TextMatrix(i, 1) = Consulta.Fields(1).Value
        Grid1.TextMatrix(i, 2) = Consulta.Fields(2).Value
        Grid1.TextMatrix(i, 3) = Consulta.Fields(3).Value
        Grid1.TextMatrix(i, 4) = Consulta.Fields(4).Value
        Grid1.TextMatrix(i, 5) = Consulta.Fields(5).Value
        Consulta.MoveNext
    Next i

         With Grid1
            .Rows = X + 1
            .Cols = 6
 
            .AllowUserResizing = flexResizeBoth
 
            For Y = 0 To .Rows - 1  'define fields as checkbox
                'For X = 1 To .Cols - 1
                    .row = Y
                    .col = 0
                    .CellFontName = "Wingdings"
                    .CellFontSize = 14
                    .CellAlignment = flexAlignCenterCenter
                    .Text = check(Y)
               ' Next X
            Next Y
        End With
    
    If OK = True And Flg_Pais$ <> "SOAR" Then
        Call CargarCabecera
    End If

   Set Consulta.ActiveConnection = Nothing
   Exit Sub
oraerror:
   Set Consulta.ActiveConnection = Nothing
   SystemMsg = "No pudo Leer Datos del Local - Proceso Abortado"
   frmLogOraError.Show 1
End Sub

Private Sub GetFlex3()

'For i = 1 To Grid2.Rows - 1
'    For z = 1 To Grid1.Rows - 1
'
'    'grid3.TextMatrix(i,
'Next i
'
End Sub

Private Sub Command4_Click()
If Flg_Pais$ = "PER" Or Flg_Pais$ = "FAOR" Or Flg_Pais$ = "HTPE" Or Flg_Pais = "HTOR" Or Flg_Pais = "MAPE" Or Flg_Pais = "MPAM" Or Flg_Pais = "SPOR" Then '08-06-2020 cambios para tomar un registro o mas
    Screen.MousePointer = 11
    If Grid2.Rows <= 1 Then
        MsgBox "No existen Registros a Cargar"
        Screen.MousePointer = 0
        Exit Sub
    End If
Else
    Screen.MousePointer = 11
    If Grid2.Rows <= 2 Then
        MsgBox "No existen Registros a Cargar"
        Screen.MousePointer = 0
        Exit Sub
    End If
End If

If Trim(Combo4.Text) = "" Then
    MsgBox "Seleccione Recaudador"
    Exit Sub
End If

If Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Then
    If Grid2.Cols > 20 Then
        MsgBox "El archivo no contiene la cantidad de columnas correctas, favor revisar.", vbCritical
        Screen.MousePointer = 0
        Exit Sub
    End If
Else
    If Grid2.Cols > 18 Then
        MsgBox "El archivo no contiene la cantidad de columnas correctas, favor revisar.", vbCritical
        Screen.MousePointer = 0
        Exit Sub
    End If
End If

   msg = "Se cargará el archivo de recaudación, desea continuar?"
   Estilo = vbYesNo + vbQuestion + vbDefaultButton2
   respuesta = MsgBox(msg, Estilo, "Confirma Carga Archivo")
   
   If respuesta = vbNo Then
        Screen.MousePointer = 0
        Exit Sub
   End If

   If Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Then
    Call CargarArchivoSoar
   Else
    Call CargarArchivo
   End If
   
   Command4.Visible = False
Screen.MousePointer = 0
End Sub

Private Sub EliminaRegistroPRDSOAR_RecMex(v_fecha As String)
Set cAdo = CreateObject("ADODB.Recordset")
With cAdo
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With

Set cAdolta = CreateObject("ADODB.Recordset")
With cAdolta
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With

    sq = " delete from vta_soarprd p where p.prv_fechavta = to_date('" & Format(v_fecha, "yyyymmdd") & "','yyyymmdd')"

Call cAdo.Open(sq)


sq1 = " delete from vta_soarrecmex r where r.mex_fecha = to_date('" & Format(v_fecha, "yyyymmdd") & "','yyyymmdd')"

Call cAdolta.Open(sq1)

Set cAdo.ActiveConnection = Nothing
Set cAdolta.ActiveConnection = Nothing
Exit Sub
oraerror:
   Set cAdo.ActiveConnection = Nothing
   Set cAdolta.ActiveConnection = Nothing
   SystemMsg = "No pudo Leer Datos del Local - Proceso Abortado"
   frmLogOraError.Show 1
End Sub

Private Sub AbrirTerminal(xlocal As String, Xterminal As String, xFecha As String)
Set cConsu = CreateObject("ADODB.Recordset")
With cConsu
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With

Dim var As Boolean
var = False

Set cConsulta = CreateObject("ADODB.Recordset")
With cConsulta
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With

Sql = " select * from vta_" & Flg_Pais$ & "termstat t"
If Flg_Pais$ = "PER" Or Flg_Pais$ = "FAOR" Or Flg_Pais$ = "HTPE" Or Flg_Pais$ = "MAPE" Or Flg_Pais$ = "MPAM" Or Flg_Pais$ = "SPOR" Then   'rh 13-05-2020
Sql = Sql & " where t.ter_fecha = to_date('" & xFecha & "','dd-mm-yyyy')"
Else
Sql = Sql & " where t.ter_fecha = to_date('" & xFecha & "','yyyymmdd')"
End If
Sql = Sql & " and t.ter_local =" & xlocal
Sql = Sql & " and t.ter_terminal =" & Xterminal

Call cConsulta.Open(Sql)
z = cConsulta.RecordCount

If z <> 0 Then
    var = True
End If

If var Then
    sq = " update vta_" & Flg_Pais$ & "termstat t"
    sq = sq & " Set t.ter_estado = 0"
    sq = sq & " ,t.ter_notas = 'CARGA MANUAL DE SOBRES'"
    If Flg_Pais$ = "PER" Or Flg_Pais$ = "FAOR" Or Flg_Pais$ = "HTPE" Or Flg_Pais$ = "MAPE" Or Flg_Pais$ = "MPAM" Or Flg_Pais$ = "SPOR" Then 'rh 04-03-02
    sq = sq & " where t.ter_fecha = to_date('" & xFecha & "','dd-mm-yyyy')"
    Else
    sq = sq & " where t.ter_fecha = to_date('" & xFecha & "','yyyymmdd')"
    End If
    sq = sq & " and t.ter_local =" & xlocal
    sq = sq & " and t.ter_terminal =" & Xterminal
Else
    sq = " insert into vta_" & Flg_Pais$ & "termstat t"
    sq = sq & " (t.ter_local,t.ter_terminal,t.ter_fecha,t.ter_estado,t.ter_notas)"
    sq = sq & " Values"
    If Flg_Pais$ = "PER" Or Flg_Pais$ = "FAOR" Or Flg_Pais$ = "HTPE" Or Flg_Pais$ = "MAPE" Or Flg_Pais$ = "MPAM" Or Flg_Pais$ = "SPOR" Then 'rh 14-05-20
        sq = sq & " (" & xlocal & "," & Xterminal & ",to_date('" & xFecha & "','dd-mm-yyyy'),0,'CARGA MANUAL DE SOBRES')"
    Else
        sq = sq & " (" & xlocal & "," & Xterminal & ",to_date('" & xFecha & "','yyyymmdd'),0,'CARGA MANUAL DE SOBRES')"
    End If
End If

Call cConsu.Open(sq)

Set cConsu.ActiveConnection = Nothing
Set cConsulta.ActiveConnection = Nothing
Exit Sub
oraerror:
   Set cConsu.ActiveConnection = Nothing
   Set cConsulta.ActiveConnection = Nothing
   SystemMsg = "No pudo Leer Datos del Local - Proceso Abortado"
   frmLogOraError.Show 1
End Sub

Private Function existe(xSobre As String, xFechaV As String) As Boolean
Set Consulta = CreateObject("ADODB.Recordset")
With Consulta
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With

existe = False

strArray = Split(Combo4.Text, "-")
vRecaudador = Trim(strArray(0))

sq = " select * from vta_" & Flg_Pais$ & "prd p"



sq = " select * from vta_" & Flg_Pais$ & "prd p"
If Flg_Pais = "PER" Or Flg_Pais$ = "FAOR" Or Flg_Pais = "HTPE" Or Flg_Pais = "MAPE" Or Flg_Pais = "MPAM" Or Flg_Pais = "SPOR" Then  'RH 14-05-2020
sq = sq & " where p.prv_fechavta = to_date('" & xFechaV & "','dd-mm-yyyy')"
sq = sq & " and p.prv_local="
Else
sq = sq & " where p.prv_fechavta = to_date('" & xFechaV & "','yyyymmdd')"
End If
If (Flg_Pais$ <> "SOAR" And Flg_Pais$ <> "SOUY") Then
    sq = sq & " and p.prv_sobre = " & xSobre
End If

Call Consulta.Open(sq)

If Consulta.RecordCount <> 0 Then
    existe = True
End If

Set Consulta.ActiveConnection = Nothing
   Exit Function
oraerror:
   existe = True
   Set Consulta.ActiveConnection = Nothing
   SystemMsg = "No pudo Leer Datos del Local - Proceso Abortado"
   frmLogOraError.Show 1
End Function

Private Function ExisteCta(ByVal Tsobre As String, ByVal Banco As String) As String 'Rh 10-03-2020

Set cConsulta = CreateObject("ADODB.Recordset")
With cConsulta
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With

sq = "select r.vta_codigo,r.vta_cuenta"
sq = sq & " from vta_homologactactesap r "
sq = sq & "where r.vta_banco ='" & Banco & "'"
    If Trim(Tsobre) = "EFE" Then
        sq = sq & " and r.vta_moneda ='SOLES'"
    ElseIf Trim(Tsobre) = "OTR" Then
        sq = sq & " and r.vta_moneda ='DOLARES'"
    Else
        sq = sq & " and r.vta_moneda ='0'" 'Rh validacion preventiva en caso de Moneda distina a OTR y EFE
    End If
        sq = sq & " and r.VTA_EMPRESA ='" & PAIS$ & "'"

    
Call cConsulta.Open(sq)

If cConsulta.RecordCount > 0 Then

    For i = 1 To cConsulta.RecordCount
  
      CodCta = cConsulta.Fields(0).Value
      NumCta = cConsulta.Fields(1).Value
      
      'cmbLocal.AddItem Right("     " & cod, 5) & "-" & nombre
      cConsulta.MoveNext
   
    Next i
    ExisteCta = CodCta & "-" & NumCta
    
Else
 
  ExisteCta = "0-0"

End If
   Set cConsulta.ActiveConnection = Nothing

Exit Function
End Function

Private Function Gridcta()
Dim fila, col

 
End Function

Private Sub PintaData(fila As Integer, colum As Integer)
Dim i As Integer
With Grid2
    For i = 0 To colum
        .col = i
        .row = fila
        .CellBackColor = &HFF&
    Next i
End With
End Sub

Private Function GetVendedor(IdPros As String, VLocal As String) As String
Set Consulta = CreateObject("ADODB.Recordset")
With Consulta
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With

'strArray = Split(Combo4.Text, "-")
'vRecaudador = Trim(strArray(0))

sq = " select v.vta_cod from vta_soarrelvendedor v"
sq = sq & " where v.vta_local =" & VLocal
sq = sq & " and v.vta_idprosegur = '" & IdPros & "'"

Call Consulta.Open(sq)

If Consulta.RecordCount <> 0 Then
    GetVendedor = Consulta.Fields(0).Value
ElseIf IdPros = "99999" Then
    GetVendedor = "999"
Else
    GetVendedor = "-1"
End If

Set Consulta.ActiveConnection = Nothing
   Exit Function
oraerror:
   Set Consulta.ActiveConnection = Nothing
   SystemMsg = "No pudo Leer Datos del Local - Proceso Abortado"
   frmLogOraError.Show 1
End Function

Private Function GetLocal(IdPros As String) As String
Set Consulta = CreateObject("ADODB.Recordset")
With Consulta
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With

'strArray = Split(Combo4.Text, "-")
'vRecaudador = Trim(strArray(0))

sq = " select m.vta_xglosa from vta_soarparam m "
sq = sq & " where m.vta_ccodtipo = 444 and m.vta_ccodigo = '" & IdPros & "'"

Call Consulta.Open(sq)

If Consulta.RecordCount <> 0 Then
    GetLocal = Consulta.Fields(0).Value
Else
    GetLocal = "0"
End If

Set Consulta.ActiveConnection = Nothing
   Exit Function
oraerror:
   Set Consulta.ActiveConnection = Nothing
   SystemMsg = "No pudo Leer Datos del Local - Proceso Abortado"
   frmLogOraError.Show 1
End Function


Private Function CargarDetalleRecMex(v_fecha As String) As String
Set cAdoQuery = CreateObject("ADODB.Recordset")
With cAdoQuery
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With

   sq = " pkg_vta_f8lv.proc_soarinsertarecmex('" & Format(v_fecha, "yyyymmdd") & "') "
   
   Call cAdoQuery.Open(sq)
   
Set cAdoQuery.ActiveConnection = Nothing
   Exit Function
oraerror:
   Set cAdoQuery.ActiveConnection = Nothing
   SystemMsg = "No pudo Leer Datos del Local - Proceso Abortado"
   frmLogOraError.Show 1
End Function

Private Function CargarDetalleRecMexSOUY(v_fechaI As String, v_fechaF As String) As String
Dim varlocal As Variant
Dim varTerminal As Variant
Dim varTipoSobre As Variant
Dim varSobre As Variant
Dim dblCantidad As Double
Dim dblCantidad_USD_vend As Double
Dim dblCantidad_USD_Comp As Double
Dim dblCantidad_USD_vend_Ori As Double
Dim dblCantidad_USD_Comp_Ori As Double
Dim dblRestoComp As Double
Dim dblRestoVend As Double
Dim dblDifenrencia As Double
Dim dbl_totZetaUsd As Double
Dim dbl_cantCompUsd As Double
Dim dbl_cantVendUsd As Double
Dim strSql As String
Dim cAdoQuery As Object
Dim cAdoQuery2 As Object
On Error GoTo LabelError

    Set cAdoQuery = CreateObject("ADODB.Recordset")
    With cAdoQuery
        .ActiveConnection = Ado_Conn
        .CursorLocation = adUseClient
        .CursorType = adOpenForwardOnly
        .LockType = adLockReadOnly
    End With
    Set cAdoQuery2 = CreateObject("ADODB.Recordset")
    With cAdoQuery2
        .ActiveConnection = Ado_Conn
        .CursorLocation = adUseClient
        .CursorType = adOpenForwardOnly
        .LockType = adLockReadOnly
    End With
    
    strSql = ""
    strSql = strSql & "select"
    strSql = strSql & " p.prv_local,"
    strSql = strSql & " p.prv_terminal,"
    strSql = strSql & " p.prv_tiposobre,"
    strSql = strSql & " p.prv_sobre,"
    strSql = strSql & " sum(p.prv_montosobre + p.prv_montodif)as Monto,"
    strSql = strSql & " p.prv_fechavta"
    If Flg_Pais$ = "PER" Or Flg_Pais$ = "HTPE" Or Flg_Pais$ = "FAOR" Or Flg_Pais$ = "MAPE" Or Flg_Pais$ = "MPAM" Or Flg_Pais$ = "SPOR" Then 'Xintec 28-09-2020
        strSql = strSql & " ,p.prv_techkey"
    End If
    If Flg_Pais$ = "HTPE" Then
        strSql = strSql & " ,p.prv_cierrey"
    End If
    'xintec 15-09-2020
    If Flg_Pais$ = "PER" Or Flg_Pais$ = "HTPE" Or Flg_Pais$ = "FAOR" Or Flg_Pais$ = "MAPE" Or Flg_Pais$ = "MPAM" Or Flg_Pais$ = "SPOR" Then
        strSql = strSql & " from vta_" & Flg_Pais$ & "prd p "
    Else
        strSql = strSql & " from vta_soarprd p "
    End If
    
    strSql = strSql & " where p.prv_tiporec = 'DOL'"
    strSql = strSql & " and p.prv_fechadep between to_date ('" & v_fechaI & "', 'yyyymmdd') "
    strSql = strSql & " and to_date ('" & v_fechaF & "', 'yyyymmdd') "
    If Flg_Pais$ = "PER" Or Flg_Pais$ = "HTPE" Or Flg_Pais$ = "FAOR" Or Flg_Pais$ = "MAPE" Or Flg_Pais$ = "MPAM" Or Flg_Pais$ = "SPOR" Then
        strSql = strSql & " and prv_techkey not in ("
        strSql = strSql & " select t.prv_techkey from vta_" & Flg_Pais$ & "recmex t"
        strSql = strSql & " where t.mex_fecha = p.prv_fechavta) "
    End If
    If Flg_Pais$ = "HTPE" Then
        strSql = strSql & "group by p.prv_local,p.prv_terminal,p.prv_tiposobre, p.prv_sobre, p.prv_fechavta,p.prv_cierrey,p.prv_techkey "
    ElseIf Flg_Pais$ = "PER" Or Flg_Pais$ = "FAOR" Or Flg_Pais$ = "MAPE" Or Flg_Pais$ = "MPAM" Or Flg_Pais$ = "SPOR" Then
        strSql = strSql & "group by p.prv_local,p.prv_terminal,p.prv_tiposobre, p.prv_sobre, p.prv_fechavta, p.prv_techkey "
    Else
        strSql = strSql & "group by p.prv_local,p.prv_terminal,p.prv_tiposobre, p.prv_sobre, p.prv_fechavta "
    End If
    strSql = strSql & "order by p.prv_fechavta, p.prv_local, p.prv_terminal, p.prv_tiposobre, sum(p.prv_montosobre + p.prv_montodif) ASC"
    Call cAdoQuery.Open(strSql)
    
    dblRestoComp = 0
    dblRestoVend = 0
    dblDifenrencia = 0
    strkeyzz = "Inicio"
    
    While Not cAdoQuery.EOF
        varlocal = Trim(cAdoQuery.Fields("prv_local").Value)
        varTerminal = Trim(cAdoQuery.Fields("prv_terminal").Value)
        varSobre = Trim(cAdoQuery.Fields("prv_sobre").Value)
        varTipoSobre = Trim(cAdoQuery.Fields("prv_tiposobre").Value)
        v_fecha = Trim(cAdoQuery.Fields("prv_fechavta").Value)
        v_fecha = Format(v_fecha, "yyyymmdd")
        dblCantidad = CDbl(0 & cAdoQuery.Fields("Monto").Value)
        dblCantidad_USD_Comp = 0
        dblCantidad_USD_vend = 0
        If Flg_Pais$ = "PER" Or Flg_Pais$ = "HTPE" Or Flg_Pais$ = "FAOR" Or Flg_Pais$ = "MAPE" Or Flg_Pais$ = "MPAM" Or Flg_Pais$ = "SPOR" Then
            varSobre = Trim(cAdoQuery.Fields("prv_techkey").Value)
        End If
        If Flg_Pais$ = "HTPE" Then 'rh 22-09
            Cierrey = Trim(cAdoQuery.Fields("prv_cierrey").Value)
        End If
        
        If varlocal = 7012 And varTerminal = 90 Then
            DoEvents
        End If
        
        If ExisteTerminal(varlocal, varTerminal) Or varTerminal = 999 Then
            If varTipoSobre <> "OTR" Then
                Rem Monedas extranjeras excepto el dólar
                 Select Case varTipoSobre
                    Case "ARS"
                        Call InsertaMovMonedaSoar(v_fecha, varlocal, varTerminal, 12, dblCantidad, varSobre, True)
                    Case "REA"
                        Call InsertaMovMonedaSoar(v_fecha, varlocal, varTerminal, 36, dblCantidad, varSobre, True)
                    Case "EUR"
                        Call InsertaMovMonedaSoar(v_fecha, varlocal, varTerminal, 304, dblCantidad, varSobre, True)
                End Select
            'xintec 15-09-2020 prueba
            ElseIf Flg_Pais$ = "PER" Or Flg_Pais$ = "HTPE" Or Flg_Pais$ = "FAOR" Or Flg_Pais$ = "MAPE" Or Flg_Pais$ = "MPAM" Or Flg_Pais$ = "SPOR" Then
                Call InsertaMovMonedaSoar(v_fecha, varlocal, varTerminal, 305, dblCantidad, varSobre, True)
            Else
                Rem Validar si cambio el local/terminal
                If Trim(v_fecha & varlocal & varTerminal) <> strkeyzz Then
                    Set cAdoQuery2 = Nothing
                    Set cAdoQuery2 = CreateObject("ADODB.Recordset")
                    With cAdoQuery2
                        .ActiveConnection = Ado_Conn
                        .CursorLocation = adUseClient
                        .CursorType = adOpenForwardOnly
                        .LockType = adLockReadOnly
                    End With
                    
                    strSql = ""
                    strSql = strSql & "select"
                    strSql = strSql & " z.mnc_visa,"
                    strSql = strSql & " z.mnc_electron,"
                    strSql = strSql & " z.mnc_provencred,"
                    strSql = strSql & " z.mnc_naranja,"
                    strSql = strSql & " z.mnc_nativa,"
                    strSql = strSql & " z.mnc_nevada "
                    strSql = strSql & " from vta_soarlibvta t, vta_soarzzz z "
                    strSql = strSql & " Where t.vta_techkey = z.rec_techkey"
                    strSql = strSql & " and t.vta_fecha = to_date ('" & v_fecha & "', 'yyyymmdd')"
                    strSql = strSql & " and t.vta_local = " & varlocal
                    strSql = strSql & " and t.vta_terminal = " & varTerminal
                    Call cAdoQuery2.Open(strSql)
                    
                    If Not cAdoQuery2.EOF Then
                        dblCantidad_USD_Comp_Ori = CDbl(0 & cAdoQuery2.Fields("mnc_electron").Value)
                        dblCantidad_USD_vend_Ori = CDbl(0 & cAdoQuery2.Fields("mnc_nativa").Value)
                        dblRestoComp = dblCantidad_USD_Comp_Ori
                        dblRestoVend = dblCantidad_USD_vend_Ori
                    End If
                    strkeyzz = Trim(v_fecha & varlocal & varTerminal)
                    Set cAdoQuery2.ActiveConnection = Nothing
                End If
                
                Rem Solo un sobre de Moneda Extranjera en la Z
                If dblCantidad = dblCantidad_USD_Comp_Ori + dblCantidad_USD_vend_Ori Then
                    If ExisteSobre(varlocal, varTerminal, 302, v_fecha) Then
                        dblRestoComp = 0
                    End If
                    If ExisteSobre(varlocal, varTerminal, 303, v_fecha) Then
                        dblRestoVend = 0
                    End If
                    If dblRestoComp = 0 And dblRestoVend = 0 Then
                        dblRestoComp = dblCantidad
                    End If
                    Call InsertaMovMonedaSoar(v_fecha, varlocal, varTerminal, 302, dblRestoComp, varSobre, False)
                    Call InsertaMovMonedaSoar(v_fecha, varlocal, varTerminal, 303, dblRestoVend, varSobre, False)
                    dblRestoComp = 0
                    dblRestoVend = 0
                Else
                Rem Mas de un sobre de Moneda Extranjera
                    If (dblCantidad - dblRestoComp) <= 0 Then
                        Rem Se consumio el sobre
                        dblCantidad_USD_Comp = dblCantidad
                        dblCantidad_USD_vend = 0
                        dblRestoComp = dblRestoComp - dblCantidad
                    Else
                        Rem Quedo sobre que completar
                        dblCantidad = dblCantidad - dblRestoComp
                        dblCantidad_USD_Comp = dblRestoComp
                        dblRestoComp = 0
                        
                        If (dblCantidad - dblRestoVend) < 0 Or Str(dblCantidad) = Str(dblRestoVend) Then
                            Rem Se consumio el sobre
                            dblCantidad_USD_vend = dblCantidad
                            If Str(dblCantidad) = Str(dblRestoVend) Then
                                dblRestoVend = 0
                            Else
                                dblRestoVend = dblRestoVend - dblCantidad
                            End If
                        Else
                            Rem en el caso que la cartola no cuadra con lo informado en zeta
                            If ((dblCantidad - dblRestoVend) > 0 And dblCantidad_USD_Comp > 0 And dblCantidad > dblRestoVend) Then
                                dblCantidad = dblCantidad - dblRestoVend
                                dblCantidad_USD_Comp = dblCantidad_USD_Comp + dblCantidad
                                dblCantidad_USD_vend = dblRestoVend
                                dblRestoVend = 0
                            Else
                                Rem sobro sobre mal asociado que se imputara al Dolar Comprador
                                dblCantidad = dblCantidad - dblRestoComp
                                dblCantidad_USD_Comp = dblCantidad
                                dblRestoComp = 0
                            End If
                        End If
                    End If
                    
                    
'                    If dblCantidad <= dblRestoComp Then
'                        dblRestoComp = dblRestoComp - dblCantidad
'                        dblCantidad_USD_Comp_Aux = dblCantidad
'                        dblCantidad_USD_vend_Aux = 0
'                    Else
'                        dblDifenrencia = dblCantidad - dblRestoComp
'                        If Str(dblDifenrencia) = Str(dblCantidad_USD_vend) Then
'                            dblCantidad_USD_vend_Aux = dblRestoVend
'                            dblRestoComp = 0
'                        Else
'                            dblCantidad_USD_vend_Aux = dblDifenrencia + dblCantidad_USD_vend_Aux
'                        End If
'                        dblCantidad_USD_Comp_Aux = dblRestoComp
'                    End If
                    
                    Call InsertaMovMonedaSoar(v_fecha, varlocal, varTerminal, 302, dblCantidad_USD_Comp, varSobre, False)
                    Call InsertaMovMonedaSoar(v_fecha, varlocal, varTerminal, 303, dblCantidad_USD_vend, varSobre, False)
                End If
            End If
        End If
        
        cAdoQuery.MoveNext
    Wend
    
LabelSalir:
Screen.MousePointer = 0
Set cAdoQuery.ActiveConnection = Nothing
Set cAdoQuery2.ActiveConnection = Nothing
Exit Function

LabelError:
    MsgBox "Problemas de comunicación con servidor,Información de Recaudación", vbCritical, "Carga Recaudación"
    GoTo LabelSalir
    Resume 0
End Function

Private Function ExisteTerminal(varlocal As Variant, varTerminal As Variant) As Boolean
Dim strSql As String
Dim cAdoQuery3 As Object
On Error GoTo LabelError
    
    ExisteTerminal = False
    Set cAdoQuery3 = CreateObject("ADODB.Recordset")
    With cAdoQuery3
        .ActiveConnection = Ado_Conn
        .CursorLocation = adUseClient
        .CursorType = adOpenForwardOnly
        .LockType = adLockReadOnly
    End With
    
    strSql = ""
    strSql = strSql & "select "
    strSql = strSql & " count(1) "
    'xintec 15-09-2020
    If Flg_Pais$ = "PER" Or Flg_Pais$ = "HTPE" Or Flg_Pais$ = "FAOR" Or Flg_Pais$ = "MAPE" Or Flg_Pais$ = "MPAM" Or Flg_Pais$ = "SPOR" Then
        strSql = strSql & "from vta_" & Flg_Pais$ & "terminales t "
    Else
        strSql = strSql & "from vta_soarterminales t "
    End If
    strSql = strSql & "Where t.ter_local = " & Trim(varlocal)
    strSql = strSql & " and t.ter_terminal =" & Trim(varTerminal)
    Call cAdoQuery3.Open(strSql)
    If Not cAdoQuery3.EOF Then
        If cAdoQuery3.Fields(0).Value > 0 Then ExisteTerminal = True
    End If
    
Set cAdoQuery3.ActiveConnection = Nothing
Exit Function

LabelError:
    Set cAdoQuery3.ActiveConnection = Nothing
    SystemMsg = "Problemas de comunicación con servidor,Información de Recaudación"
    frmLogOraError.Show 1
    Exit Function
End Function

Private Sub InsertaMovMonedaSoar(varfecha As Variant, varlocal As Variant, varTerminal As Variant, varMoneda As Variant, dblCantidad As Double, varSobre As Variant, blnAnteriorMasProxima As Boolean)
Dim strSql As String
Dim dblTasaCambio As Double
Dim cAdoQuery As Object
On Error GoTo LabelError
    
    If dblCantidad <= 0 Then Exit Sub
    
    Set cAdoQuery = CreateObject("ADODB.Recordset")
    With cAdoQuery
        .ActiveConnection = Ado_Conn
        .CursorLocation = adUseClient
        .CursorType = adOpenForwardOnly
        .LockType = adLockReadOnly
    End With
    
    dblTasaCambio = TraeTasaCambio(varfecha, varMoneda, blnAnteriorMasProxima)
    If dblTasaCambio = 0 Then
        MsgBox "No existe Tasa de cambio " & StrConv(TraeDescripcionMoneda(Val(varMoneda)), vbProperCase) & " para " & Mid(varfecha, 7, 2) & "-" & Mid(varfecha, 5, 2) & "-" & Mid(varfecha, 1, 4) & Chr(13) & "Favor Ingrese tasa y vuelva a Cargar", vbExclamation
        Exit Sub
    End If
    
    strSql = ""
    'xintec 15-09-2020
    If Flg_Pais$ = "PER" Or Flg_Pais$ = "HTPE" Or Flg_Pais$ = "FAOR" Or Flg_Pais$ = "MAPE" Or Flg_Pais$ = "MPAM" Or Flg_Pais$ = "SPOR" Then
        strSql = strSql & "insert into vta_" & Flg_Pais$ & "RECMEX ("
    Else
        strSql = strSql & "insert into vta_SOARRECMEX ("
    End If
    strSql = strSql & "Mex_Fecha,"
    strSql = strSql & "Mex_Local,"
    strSql = strSql & "Mex_Terminal,"
    strSql = strSql & "Id_Mdareg,"
    strSql = strSql & "Mex_Cantidad,"
    strSql = strSql & "Mex_Valor,"
    strSql = strSql & "Mex_Monto,"
    strSql = strSql & "MEX_SECUENCIA,"
    'xintec 28-09-2020
    If Flg_Pais$ = "PER" Or Flg_Pais$ = "FAOR" Or Flg_Pais$ = "MAPE" Or Flg_Pais$ = "MPAM" Or Flg_Pais$ = "SPOR" Then
        strSql = strSql & "MEX_REGULPOR,"
        strSql = strSql & "prv_techkey)"
    ElseIf Flg_Pais$ = "HTPE" Then
        strSql = strSql & "MEX_REGULPOR,"
        strSql = strSql & "MEX_CIERREY,"
        strSql = strSql & "prv_techkey)"
    Else
        strSql = strSql & "MEX_REGULPOR,"
        strSql = strSql & "PRV_SOBRE)"
    End If
    strSql = strSql & "Values("
    strSql = strSql & "to_date ('" & varfecha & "', 'yyyymmdd'),"
    strSql = strSql & varlocal & ","
    strSql = strSql & varTerminal & ","
    strSql = strSql & varMoneda & ","
    strSql = strSql & Replace(dblCantidad, ",", ".") & ","
    strSql = strSql & Replace(dblTasaCambio, ",", ".") & ","
    strSql = strSql & Replace(dblCantidad * dblTasaCambio, ",", ".") & ","
    'xintec 22-09-2020
    If Flg_Pais$ = "PER" Or Flg_Pais$ = "FAOR" Or Flg_Pais$ = "MAPE" Or Flg_Pais$ = "MPAM" Or Flg_Pais$ = "SPOR" Then
        strSql = strSql & "seq_vta_" & Flg_Pais$ & "recmex.NEXTVAL,"
        strSql = strSql & "'" & StrConv(UserName$, vbUpperCase) & "', "
        strSql = strSql & varSobre & ")"
    ElseIf Flg_Pais$ = "HTPE" Then
        strSql = strSql & "seq_vta_" & Flg_Pais$ & "recmex.NEXTVAL,"
        strSql = strSql & "'" & StrConv(UserName$, vbUpperCase) & "',"
        strSql = strSql & "'" & Cierrey & "', "
        strSql = strSql & varSobre & ")"
    Else
        strSql = strSql & "seq_vta_soarrecmex.NEXTVAL,"
        strSql = strSql & "'" & StrConv(UserName$, vbUpperCase) & "',"
        strSql = strSql & varSobre & ")"
    End If
    Call cAdoQuery.Open(strSql)
            
LabelSalir:
Set cAdoQuery.ActiveConnection = Nothing
Exit Sub

LabelError:
    MsgBox "Problemas de comunicación con servidor,Información de Recaudación", vbCritical, "Carga Recaudación"
    GoTo LabelSalir
    Exit Sub
    Resume 0
End Sub


Private Function ExisteSobre(varlocal As Variant, varTerminal As Variant, varCodMoneda As Variant, varfecha As Variant) As Boolean
Dim strSql As String
Dim cAdoQuery As Object
On Error GoTo LabelError
    
    ExisteSobre = False
    Set cAdoQuery = CreateObject("ADODB.Recordset")
    With cAdoQuery
        .ActiveConnection = Ado_Conn
        .CursorLocation = adUseClient
        .CursorType = adOpenForwardOnly
        .LockType = adLockReadOnly
    End With
    
    strSql = ""
    strSql = strSql & "select "
    strSql = strSql & " Count(*) "
    strSql = strSql & "from vta_SOARRECMEX "
    strSql = strSql & "Where mex_local=" & Trim(varlocal)
    strSql = strSql & " and mex_terminal=" & Trim(varTerminal)
    strSql = strSql & " and mex_fecha = to_date ('" & varfecha & "', 'yyyymmdd')"
    strSql = strSql & " and id_mdareg = " & varCodMoneda
    Call cAdoQuery.Open(strSql)
    If Not cAdoQuery.EOF Then
        If cAdoQuery.Fields(0).Value > 0 Then ExisteSobre = True
    End If
    
Set cAdoQuery.ActiveConnection = Nothing
Exit Function

LabelError:
    Set cAdoQuery.ActiveConnection = Nothing
    SystemMsg = "Problemas de comunicación con servidor,Información de Recaudación"
    frmLogOraError.Show 1
    Exit Function
End Function


Private Function HoraCorteExtracto() As String
Set cConsu = CreateObject("ADODB.Recordset")
With cConsu
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With

sq = " select m.vta_xglosa"
sq = sq & " from vta_soarparam m"
sq = sq & " Where m.vta_ccodtipo = 50"
sq = sq & " and m.vta_ccodigo = 1"

Call cConsu.Open(sq)

If cConsu.RecordCount <> 0 Then
    HoraCorteExtracto = cConsu.Fields(0).Value
Else
    HoraCorteExtracto = "1700"
End If

Set cConsu.ActiveConnection = Nothing
   Exit Function
oraerror:
   Set cConsu.ActiveConnection = Nothing
   SystemMsg = "No pudo Leer Parametros"
   frmLogOraError.Show 1
End Function


Private Sub CargarArchivoSoar()
Set cQuery = CreateObject("ADODB.Recordset")
With cQuery
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With

Dim vRecaudador As String
Dim xlocal As String
Dim xcajero As String
Dim xTipoRec As String
Dim xTipoSobre As String
Dim xNumSobre As String
Dim xCodRec As Integer
Dim xFecha As String
Dim xCorte As String
Dim strFecha As String
Dim X As Integer
Dim dtFechaProceso As Date

Dim intI As Integer
Dim strLocalActual As String
Dim strFechaActual As String

Dim xFechaInicio As String
Dim xFechaFin As String

X = 0
intI = 0
strLocalActual = "INICIO"
Erase typeSobres

strArray = Split(Combo4.Text, "-")
vRecaudador = Trim(strArray(0))

If Trim(Grid2.TextMatrix(1, 0)) = "" Then
    MsgBox "Error al cargar el archivo", vbCritical
    Exit Sub
End If

dtFechaProceso = Now
xCorte = HoraCorteExtracto


    'If existe(0, Format(Grid2.TextMatrix(1, 0), "yyyymmdd")) Then
    If Flg_Pais$ <> "SOAR" And Flg_Pais$ <> "SOUY" Then
        Call EliminaRegistroPRDSOAR_RecMex(Grid2.TextMatrix(1, 0))
    End If
    'End Ifcata123fmt.


For i = 1 To Grid2.Rows - 1

        strArray = Split(Grid2.TextMatrix(i, 7), ":")
        xNumSobre = Trim(strArray(0))
        xcajero = IIf(Trim(Grid2.TextMatrix(i, 18)) = -1, 999, Trim(Grid2.TextMatrix(i, 18)))
        
        If VG_COD_PAIS = "UY" Then
            xFechaInicio = Format(Grid2.TextMatrix(1, 0), "yyyymmdd")
            xFechaFin = Format(Grid2.TextMatrix(i, 0), "yyyymmdd")
    
            If xFechaInicio <> xFechaFin And xFechaFin < xFechaInicio Then
                xFechaInicio = xFechaFin
            End If
        End If
        
        Select Case Trim(Grid2.TextMatrix(i, 8))
            Case "UYU"
                xTipoRec = "F8"
                xTipoSobre = "EFE"
                xCodRec = 0
            Case "ARS"
                xTipoRec = "DOL"
                xTipoSobre = "ARS"
                xCodRec = 12
            Case "USD"
                xTipoRec = "DOL"
                xTipoSobre = "OTR"
                xCodRec = 305
            Case "REA", "BRL"
                xTipoRec = "DOL"
                xTipoSobre = "REA"
                xCodRec = 36
            Case "EUR"
                xTipoRec = "DOL"
                xTipoSobre = "EUR"
                xCodRec = 304
        End Select
        
    
        sq = " insert into vta_" & Flg_Pais$ & "prd"
        sq = sq & " (PRV_TECHKEY"
        sq = sq & " ,PRV_FECHADEP"
        sq = sq & " ,PRV_LOCAL"
        sq = sq & " ,PRV_TERMINAL"
        sq = sq & " ,PRV_TIPOREC"
        sq = sq & " ,PRV_PRSCLI"
        sq = sq & " ,PRV_SERVICIO"
        sq = sq & " ,PRV_SOBRE"
        sq = sq & " ,PRV_PRSLOC"
        sq = sq & " ,PRV_PRSCAJERO"
        sq = sq & " ,PRV_TIPOSOBRE"
        sq = sq & " ,PRV_CTACTE"
        sq = sq & " ,PRV_NOMCTA"
        sq = sq & " ,PRV_TOTDOCS"
        sq = sq & " ,PRV_TIPODIFDOC"
        sq = sq & " ,PRV_NUMDIFDOC"
        sq = sq & " ,PRV_CODDIFDOC"
        sq = sq & " ,PRV_NOMDIFDOC"
        sq = sq & " ,PRV_MONTOSOBRE"
        sq = sq & " ,PRV_TIPODIFMON"
        sq = sq & " ,PRV_MONTODIF"
        sq = sq & " ,PRV_CODDIFMON"
        sq = sq & " ,PRV_NOMDIFMON"
        sq = sq & " ,PRV_SERV2"
        sq = sq & " ,PRV_NUMREC"
        sq = sq & " ,PRV_FECHAVTA"
        sq = sq & " ,PRV_MODIFPOR"
        sq = sq & " ,PRV_CIERREY"
        sq = sq & " ,PRV_SERIEDEPOSITO"
        sq = sq & " ,PRV_NUMDEPOSITO"
        sq = sq & " ,PRV_FECHACONTABLE"
        sq = sq & " ,PRV_FECHAREG"
        sq = sq & " ,PRV_NOMBREARCH"
        sq = sq & " ,PRV_USUARIOREG"
        sq = sq & " ,PRV_FECHACONTABLE2)"
        sq = sq & " Values"
        sq = sq & " (SEQ_VTA_SOARPRS.nextval"
        sq = sq & " ,to_date ('" & Format(Grid2.TextMatrix(i, 0), "yyyymmdd") & "', 'yyyymmdd')"
        sq = sq & " ," & Trim(Grid2.TextMatrix(i, 19))
        sq = sq & " ," & xcajero
        sq = sq & " ,'" & xTipoRec & "'"
        sq = sq & " ," & Mid(Grid2.TextMatrix(i, 3), 1, 14)
        sq = sq & " ,'E'"
        sq = sq & " ,SEQ_VTA_SOARPRS.nextval"
        sq = sq & " ," & Mid(Grid2.TextMatrix(i, 3), 1, 14)
        sq = sq & " ," & Mid(Grid2.TextMatrix(i, 3), 15, Len(Grid2.TextMatrix(i, 3)))
        sq = sq & " ,'" & xTipoSobre & "'"
        sq = sq & " ,0"
        sq = sq & " ,'INTERNO'"
        sq = sq & " ,0"
        sq = sq & " ,'c'"
        sq = sq & " ,0"
        sq = sq & " ,0"
        sq = sq & " ,' '"
        sq = sq & " ," & Replace(Grid2.TextMatrix(i, 10), ".", "")
        sq = sq & " ,'c'"
        sq = sq & " ,0"
        sq = sq & " ,0"
        sq = sq & " ,' '"
        sq = sq & " ,'IN'"
        sq = sq & " ,1"
        sq = sq & " ,to_date ('" & Format(Grid2.TextMatrix(i, 0), "yyyymmdd") & "', 'yyyymmdd')"
        sq = sq & " ,'" & LOCALUSER & "'"
        sq = sq & " ,1"
        sq = sq & " ,'DEP'"
        sq = sq & " ,0"
        
        If Format(Grid2.TextMatrix(i, 0), "hhmm") > xCorte Then
            sq = sq & " ,to_date ('" & Format(Grid2.TextMatrix(i, 0), "yyyymmdd") & "', 'yyyymmdd') + 1"
        Else
            sq = sq & " ,to_date ('" & Format(Grid2.TextMatrix(i, 0), "yyyymmdd") & "', 'yyyymmdd')"
        End If
        
        If Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Then
            sq = sq & " ,to_date ('" & Format(dtFechaProceso, "yyyymmdd hh:mm:ss") & "', 'yyyymmdd hh24:mi:ss')"

        Else
            sq = sq & " ,to_date ('" & Format(Now, "yyyymmdd") & "', 'yyyymmdd')"
        End If
        
        sq = sq & " ,'Manual'"
        sq = sq & " ,'uintrateso'"
        sq = sq & " ,to_date ('" & Format(Grid2.TextMatrix(i, 0), "yyyymmdd hh:mm:ss") & "', 'yyyymmdd hh24:mi:ss')"
        sq = sq & ")"
    
        Call cQuery.Open(sq)
        X = X + 1
        
        If xCodRec <> 0 Then
            'Call CargaRecMex(Format(Grid2.TextMatrix(i, 0), "yyyymmdd"), Grid2.TextMatrix(i, 17), xcajero, xCodRec, 0)
        End If
        
'        If Grid2.TextMatrix(i, 19) = 7011 And xcajero = 800 Then
'            DoEvents
'        End If
        If Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Then
            If strLocalActual <> Trim(Grid2.TextMatrix(i, 19)) Then
                If Not ExisteLocalEnArreglo(Trim(Grid2.TextMatrix(i, 19)), Format(Grid2.TextMatrix(i, 0), "yyyymmdd")) Then
                    typeSobres(intI).StrLocal = Trim(Grid2.TextMatrix(i, 19))
                    typeSobres(intI).strFecha = Format(Grid2.TextMatrix(i, 0), "yyyymmdd")
                    intI = intI + 1
                    strLocalActual = Trim(Grid2.TextMatrix(i, 19))
                End If
            End If
        Else
            Call AbrirTerminal(Grid2.TextMatrix(i, 19), xcajero, Format(Grid2.TextMatrix(i, 0), "yyyymmdd"))
        End If
Next i
    
    Rem RMOYAG 20171201 F8 SOUY - Problemas en el flujo de recaudacion
    If Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Then
        Call AperturaTerminales
    End If
       

    If VG_COD_PAIS = "UY" Then
        Call CargarDetalleRecMexSOUY(xFechaInicio, xFechaFin)
    Else
        For Y = 1 To Grid2.Rows - 1
            If Y > 1 Then
                If Format(Grid2.TextMatrix(Y - 1, 0), "yyyymmdd") <> Format(Grid2.TextMatrix(Y, 0), "yyyymmdd") Then
                    Call CargarDetalleRecMex(Grid2.TextMatrix(Y, 0))
                End If
            Else
                Call CargarDetalleRecMex(Grid2.TextMatrix(Y, 0))
            End If
        Next Y
    End If
    
    If X = 0 Then
        MsgBox "Carga no realizada. Ya existen los registros", vbExclamation, "Carga Recaudación"
    Else
        MsgBox "Se Cargaron " & X & " Registros", vbInformation, "Carga Recaudación"
    End If

Set cQuery.ActiveConnection = Nothing
   Exit Sub
oraerror:
   Set cQuery.ActiveConnection = Nothing
   SystemMsg = "No pudo Leer Datos del Local - Proceso Abortado"
   frmLogOraError.Show 1
End Sub

Private Sub CargaRecMex(vfecha As String, VLocal As String, vTerm As String, vtipo As String, vSec As String, vCant As Integer, vValor As Double, vMonto As Double)
Set cConsulta = CreateObject("ADODB.Recordset")
With cConsulta
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With

Dim xRecaud As Integer

sq = " Insert vta_soarrecmex"
sq = sq & " (MEX_FECHA,MEX_LOCAL,MEX_TERMINAL,ID_MDAREG,MEX_SECUENCIA,MEX_CANTIDAD,MEX_VALOR,MEX_MONTO,MEX_FECHAREG)"
sq = sq & " Values"
sq = sq & " (to_date(" & Format(vfecha, "yyyymmdd") & ",'yyyymmdd')," & VLocal & "," & vTerm & "," & xRecaud & "," & vSec & "," & vCant & "," & vValor & "," & vMonto & ",to_char(sysdate,'yyyymmdd'))"

Call cConsulta.Open(sq)

Set cConsulta.ActiveConnection = Nothing
   Exit Sub
oraerror:
   Set cConsulta.ActiveConnection = Nothing
   SystemMsg = "Error al grabar RECMEX - Proceso Abortado"
   frmLogOraError.Show 1
End Sub

Private Sub CargarArchivo()
Set cQuery = CreateObject("ADODB.Recordset")
With cQuery
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With

Dim xFechaInicio As String
Dim xFechaFin As String

Dim vRecaudador As String
Dim X As Integer
Dim clocal As String

X = 0

strArray = Split(Combo4.Text, "-")
vRecaudador = Trim(strArray(0))

On Error GoTo oraerror

For i = 1 To Grid2.Rows - 1

    
    If (Flg_Pais$ = "PER" Or Flg_Pais$ = "FAOR" Or Flg_Pais$ = "HTPE" Or Flg_Pais$ = "MAPE" Or Flg_Pais$ = "MPAM" Or Flg_Pais$ = "SPOR") Then 'Rh 13-05-2020
    
       'If Not existe(Grid2.TextMatrix(i, 2), Grid2.TextMatrix(i, 7)) Then
        
        sq = " insert into vta_" & Flg_Pais$ & "prd"
        sq = sq & " (prv_techkey,"
        sq = sq & " prv_fechadep,"
        sq = sq & " prv_local,"
        sq = sq & " prv_terminal,"
        sq = sq & " prv_tiporec,"
        sq = sq & " prv_prscli,"
        sq = sq & " prv_servicio,"
        sq = sq & " prv_sobre,"
        sq = sq & " prv_prsloc,"
        sq = sq & " prv_prscajero,"
        sq = sq & " prv_tiposobre,"
        sq = sq & " prv_ctacte2,"
        sq = sq & " prv_nomcta,"
        sq = sq & " prv_totdocs,"
        sq = sq & " prv_tipodifdoc,"
        sq = sq & " prv_numdifdoc,"
        sq = sq & " prv_coddifdoc,"
        sq = sq & " prv_nomdifdoc,"
        sq = sq & " prv_montosobre,"
        sq = sq & " prv_tipodifmon,"
        sq = sq & " prv_montodif,"
        sq = sq & " prv_coddifmon,"
        sq = sq & " prv_nomdifmon,"
        sq = sq & " prv_serv2,"
        sq = sq & " prv_numrec,"
        sq = sq & " prv_fechavta,"
        sq = sq & " prv_modifpor,"
        sq = sq & " prv_cierrey,"
        sq = sq & " PRV_COD_RECAUD,"
        sq = sq & " PRV_NUMDEPOSITO,"
        sq = sq & " PRV_CTACTE)"
        sq = sq & " Values"
        If Flg_Pais$ = "FAOR" Or Flg_Pais$ = "FAIQ" Then
        sq = sq & " (SEQ_VTA_FAORPRS.nextval"
        ElseIf Flg_Pais$ = "PER" Then
        sq = sq & " (SEQ_VTA_PRS.nextval"
        ElseIf Flg_Pais$ = "HTPE" Or Flg_Pais$ = "HTOR" Then
        sq = sq & " (SEQ_VTA_HTPEPRS.nextval"
        ElseIf Flg_Pais$ = "SPOR" Then
        sq = sq & " (SEQ_VTA_SPORPRS.nextval"
        ElseIf Flg_Pais$ = "MPAM" Then
        sq = sq & " (SEQ_VTA_MPAMPRS.nextval"
        ElseIf Flg_Pais$ = "MAPE" Then
        sq = sq & " (SEQ_VTA_MAPEPRS.nextval"
        End If
        sq = sq & " ,to_date('" & Grid2.TextMatrix(i, 11) & "', 'dd-mm-yyyy')"
        sq = sq & " , " & Grid2.TextMatrix(i, 0)
        sq = sq & " , " & Grid2.TextMatrix(i, 1)
        'xin 15-09-2020
        If (Grid2.TextMatrix(i, 3) = "OTR") Then
            sq = sq & " , 'DOL'"
        Else
            sq = sq & ", 'F8'"
        End If
        sq = sq & " , 1"
        sq = sq & " , 'E'"
        sq = sq & " , " & Grid2.TextMatrix(i, 2)
        sq = sq & " , 1"
        sq = sq & " , 7"
        sq = sq & " , trim('" & Grid2.TextMatrix(i, 3) & "')"
        sq = sq & " , nvl('" & Grid2.TextMatrix(i, 13) & "','0')" 'cuenta corriente
        sq = sq & " , 'INTERNO'"
        sq = sq & " , 0"
        sq = sq & " , 'C'"
        sq = sq & " , 0"
        sq = sq & " , '000'"
        sq = sq & " , 'in'"
        sq = sq & " , replace ('" & Grid2.TextMatrix(i, 4) & "',',','.')"
        sq = sq & " , 'C'"
        sq = sq & " , " & Grid2.TextMatrix(i, 5)
        sq = sq & " , 0"
        sq = sq & " , '000'"
        sq = sq & " , 'in'"
        sq = sq & " , " & Grid2.TextMatrix(i, 5)
        sq = sq & " , to_date('" & Grid2.TextMatrix(i, 7) & "', 'dd-mm-yyyy')" 'rh
        sq = sq & " , 'int'"
        sq = sq & " , trim('" & Grid2.TextMatrix(i, 8) & "')"
        sq = sq & " , '" & vRecaudador & "'"
        sq = sq & " , trim('" & Grid2.TextMatrix(i, 9) & "')"
        sq = sq & " , nvl('" & Grid2.TextMatrix(i, 12) & "','0'))"
    
        Call cQuery.Open(sq)
        X = X + 1
        
        Call AbrirTerminal(Grid2.TextMatrix(i, 0), Grid2.TextMatrix(i, 1), Grid2.TextMatrix(i, 7))
        'End If
    
    Else
        If Not existe(Grid2.TextMatrix(i, 2), Grid2.TextMatrix(i, 6)) Then
        
        sq = " insert into vta_" & Flg_Pais$ & "prd"
        sq = sq & " (prv_techkey,"
        sq = sq & " prv_fechadep,"
        sq = sq & " prv_local,"
        sq = sq & " prv_terminal,"
        sq = sq & " prv_tiporec,"
        sq = sq & " prv_prscli,"
        sq = sq & " prv_servicio,"
        sq = sq & " prv_sobre,"
        sq = sq & " prv_prsloc,"
        sq = sq & " prv_prscajero,"
        sq = sq & " prv_tiposobre,"
        sq = sq & " prv_ctacte,"
        sq = sq & " prv_nomcta,"
        sq = sq & " prv_totdocs,"
        sq = sq & " prv_tipodifdoc,"
        sq = sq & " prv_numdifdoc,"
        sq = sq & " prv_coddifdoc,"
        sq = sq & " prv_nomdifdoc,"
        sq = sq & " prv_montosobre,"
        sq = sq & " prv_tipodifmon,"
        sq = sq & " prv_montodif,"
        sq = sq & " prv_coddifmon,"
        sq = sq & " prv_nomdifmon,"
        sq = sq & " prv_serv2,"
        sq = sq & " prv_numrec,"
        sq = sq & " prv_fechavta,"
        sq = sq & " prv_modifpor,"
        sq = sq & " prv_cierrey,"
        sq = sq & " PRV_COD_RECAUD)"
        sq = sq & " Values"
        sq = sq & " (SEQ_VTA_FACOPRS.nextval"
        sq = sq & " ,to_date ('" & Format(Now, "yyyymmdd") & "', 'yyyymmdd')"
        sq = sq & " , " & Grid2.TextMatrix(i, 0)
        sq = sq & " , " & Grid2.TextMatrix(i, 1)
        sq = sq & " , 'F8'"
        sq = sq & " , 1"
        sq = sq & " , 'E'"
        sq = sq & " , " & Grid2.TextMatrix(i, 2)
        sq = sq & " , 1"
        sq = sq & " , 7"
        sq = sq & " , 'EFE'"
        sq = sq & " , '00'"
        sq = sq & " , 'INTERNO'"
        sq = sq & " , 0"
        sq = sq & " , 'C'"
        sq = sq & " , 0"
        sq = sq & " , '000'"
        sq = sq & " , 'in'"
        sq = sq & " , " & Grid2.TextMatrix(i, 3)
        sq = sq & " , 'C'"
        sq = sq & " , " & Grid2.TextMatrix(i, 4)
        sq = sq & " , 0"
        sq = sq & " , '000'"
        sq = sq & " , 'in'"
        sq = sq & " , " & Grid2.TextMatrix(i, 5)
        sq = sq & " , to_date('" & Grid2.TextMatrix(i, 6) & "', 'yyyymmdd')"
        sq = sq & " , 'int'"
        sq = sq & " , " & Grid2.TextMatrix(i, 7)
        sq = sq & " , '" & vRecaudador & "')"
    
        Call cQuery.Open(sq)
        X = X + 1
        
        Call AbrirTerminal(Grid2.TextMatrix(i, 0), Grid2.TextMatrix(i, 1), Grid2.TextMatrix(i, 6))
    
        'Call cQuery.Open(sq)
        'X = X + 1
        'Call AbrirTerminal(Grid2.TextMatrix(i, 0), Grid2.TextMatrix(i, 1), Grid2.TextMatrix(i, 6))
        
        End If
    End If
    If (Flg_Pais$ = "PER" Or Flg_Pais$ = "FAOR" Or Flg_Pais$ = "HTPE" Or Flg_Pais$ = "MAPE" Or Flg_Pais$ = "MPAM" Or Flg_Pais$ = "SPOR") Then 'Rh 13-05-2020
        xFechaInicio = Format(Grid2.TextMatrix(1, 11), "yyyymmdd")
        xFechaFin = Format(Grid2.TextMatrix(i, 11), "yyyymmdd")
    End If
Next i

    'xin 15-09-2020
    If (Flg_Pais$ = "PER" Or Flg_Pais$ = "FAOR" Or Flg_Pais$ = "HTPE" Or Flg_Pais$ = "MAPE" Or Flg_Pais$ = "MPAM" Or Flg_Pais$ = "SPOR") Then 'Rh 13-05-2020
        Call CargarDetalleRecMexSOUY(xFechaInicio, xFechaFin)
    End If

    If X = 0 Then
        MsgBox "Carga No Realizada. Ya existen los registros"
    Else
        MsgBox "Se Cargaron " & X & " Registros"
    End If

Set cQuery.ActiveConnection = Nothing
   Exit Sub
oraerror:
   Set cQuery.ActiveConnection = Nothing
   SystemMsg = "No pudo Leer Datos del Local - Proceso Abortado"
   frmLogOraError.Show 1
End Sub

Private Sub Form_Load()
'Command3.Visible = False
'Command4.Visible = False

If Flg_Pais$ = "SOAR" Then
    label_cant.Visible = True
    Text3.Visible = True
End If

Call GetRecaudador
Call CargaLista(True)
End Sub

Private Sub CargarCabecera()
Const strChecked = "þ"
Const strUnChecked = "q"
Dim cont As Integer
cont = 0
Grid2.Cols = 1
z = 0
For i = 1 To Grid1.Rows - 1
    If Grid1.TextMatrix(i, 0) = strChecked Then
        Grid2.TextMatrix(0, z) = Grid1.TextMatrix(i, 1)
        Grid2.Cols = Grid2.Cols + 1
        Grid2.ColWidth(z) = 2000
        Grid2.ColAlignment(z) = 1
        z = z + 1
    End If
Next i
Grid2.Cols = z
End Sub

Private Sub DefineGrilla()
    Grid1.Clear
    Grid1.Cols = 6
    Grid1.Rows = 1
    
    Grid1.ColWidth(0) = 800
    Grid1.ColWidth(1) = 3400
    Grid1.ColWidth(2) = 0
    Grid1.ColWidth(3) = 0
    Grid1.ColWidth(4) = 0
    Grid1.ColWidth(5) = 0
     
    Grid1.FixedAlignment(0) = 4
    Grid1.FixedAlignment(1) = 4
    Grid1.FixedAlignment(2) = 4
    Grid1.FixedAlignment(3) = 4
    Grid1.FixedAlignment(4) = 4
    Grid1.FixedAlignment(5) = 4
    
    Grid1.ColAlignment(0) = 1
    Grid1.ColAlignment(1) = 1
    Grid1.ColAlignment(4) = 7
    
    Grid1.TextMatrix(0, 0) = "Ok"
    Grid1.TextMatrix(0, 1) = "Columna"
    Grid1.TextMatrix(0, 2) = "NombreCol"
    Grid1.TextMatrix(0, 3) = "ValorDefault"
    Grid1.TextMatrix(0, 4) = "TipoVar"
    Grid1.TextMatrix(0, 5) = "Col"

End Sub


Private Sub Excel_FlexGrid(sPath As String, FlexGrid As Object, filas As Integer, Columnas As Integer, Optional sSheetName As String = vbNullString)

    Dim i As Long
    Dim n As Long
    Dim X As Long
    X = 1
    
    On Error GoTo error_sub
    ' -- Comproba si existe l archivo
    If Len(Dir(sPath)) = 0 Then
       MsgBox "No se ha encontrado el archivo: " & sPath, vbCritical
       Exit Sub
    End If
    
    Me.MousePointer = vbHourglass
    ' -- crea rnueva instancia de Excel
    Set obj_Excel = CreateObject("Excel.Application")
    'obj_Excel.Visible = True
    
    ' -- Abrir el libro
    Set obj_Workbook = obj_Excel.Workbooks.Open(sPath)
    ' -- referencia la Hoja, por defecto la hoja activa
    If sSheetName = vbNullString Then
        Set obj_Worksheet = obj_Workbook.ActiveSheet
    Else
        Set obj_Worksheet = obj_Workbook.Sheets(sSheetName)
    End If
    
    ' -- Setear Grid
    With Grid2
        ' -- Especificar  la cantidad de filas y columnas
        '.Cols = Columnas
        .Rows = obj_Worksheet.UsedRange.Rows.Count
        
        If Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Then
     
            .Rows = obj_Worksheet.UsedRange.Rows.Count - 2
            If VG_COD_PAIS = "UY" Then
                .Cols = 18
            Else
                .Cols = obj_Worksheet.UsedRange.Columns.Count
            End If
           
            
            X = 0
            
            For j = 0 To .Cols - 1
                Grid2.ColWidth(j) = 2200
                Grid2.ColAlignment(j) = 1
            Next j
        End If
        
        ' -- Recorrer las filas del FlexGrid para agregar los datos
        For i = X To .Rows - 1
            ' -- Establecer la fila activa
            .row = i
            ' -- Recorrer las columnas del FlexGrid
            For n = 0 To .Cols - 1
                ' -- Establecer columna activa
                .col = n
                ' -- Asignar a la celda del Flex el contenido de la celda del excel
                If Flg_Pais$ = "SOAR" Then
                    .Text = obj_Worksheet.cells(i + 3, n + 1).Value
                Else
                    .Text = obj_Worksheet.cells(i + 1, n + 1).Value
                End If
            Next n
            
                    If Flg_Pais$ = "PER" Or Flg_Pais = "FAOR" Or Flg_Pais$ = "HTPE" Or Flg_Pais$ = "MAPE" Or Flg_Pais$ = "MPAM" Or Flg_Pais$ = "SPOR" Then 'rh 14-05-2020
                        Tsobre = obj_Worksheet.cells(i + 1, 4).Value
                        Banco = obj_Worksheet.cells(i + 1, 11).Value
                            If Grid2.TextMatrix(i, 3) <> "CHE" Then
                                exCta = ExisteCta(Tsobre, Banco)
                                If exCta = "0-0" And Grid2.TextMatrix(i, 1) <> "" Or Grid2.TextMatrix(i, 1) = "" Then
                                    For Co = 0 To 11
                                        Grid2.row = i
                                        Grid2.col = Co
                                        Grid2.CellBackColor = &HFF
                                        Grid2.CellForeColor = &H80000005
                                        
                                    Next Co
                                    Command4.Enabled = False
                                
                                Else
                                    arrexcta = Split(exCta, "-")
                                    codBanco = arrexcta(0)
                                    NumCta = arrexcta(1)
                                    Grid2.TextMatrix(i, 12) = codBanco
                                    Grid2.TextMatrix(i, 13) = NumCta
                                End If
                            End If
                    End If
                    
        Next i
    End With
    ' -- Cerrar libro
    obj_Workbook.Close
    ' -- Cerrar Excel
    obj_Excel.Quit
    ' -- Descargar objetos para liberar recursos
    Call Descargar
' -- Errores
Exit Sub
error_sub:
    MsgBox Err.Description
    Call Descargar
        Me.MousePointer = vbDefault
End Sub

Private Sub Descargar()
    On Local Error Resume Next
    Set obj_Workbook = Nothing
    Set obj_Excel = Nothing
    Set obj_Worksheet = Nothing
    Me.MousePointer = vbDefault
End Sub

Private Sub GetRecaudador()
Set cQuery = CreateObject("ADODB.Recordset")
With cQuery
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With

sq = " select"
sq = sq & " r.vta_cod_recaud,"
sq = sq & " r.vta_nombre"
sq = sq & " from vta_" & Flg_Pais$ & "recaudadora r"

Call cQuery.Open(sq)

 While Not cQuery.EOF
 
      cod = cQuery.Fields(0).Value
      nombre = cQuery.Fields(1).Value
      Combo4.AddItem Right("     " & cod, 5) & "-" & nombre
      
      Combo1.AddItem cod
      cQuery.MoveNext
 Wend

If (Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY") Then
    'SRF 167735 - F8 Sodimac ARG
    If Combo1.ListCount > 0 Then
        Combo1.ListIndex = 0
        Combo4.ListIndex = Combo1.ListIndex
    End If
End If

Set cQuery.ActiveConnection = Nothing
   Exit Sub
oraerror:
   Set cQuery.ActiveConnection = Nothing
   SystemMsg = "No pudo Leer Datos del Local - Proceso Abortado"
   frmLogOraError.Show 1
End Sub


