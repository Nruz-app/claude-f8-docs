VERSION 5.00
Object = "{5E9E78A0-531B-11CF-91F6-C2863C385E30}#1.0#0"; "MSFLXGRD.OCX"
Object = "{86CF1D34-0C5F-11D2-A9FC-0000F8754DA1}#2.0#0"; "mscomct2.ocx"
Begin VB.Form Form43 
   BackColor       =   &H00E6E8E8&
   Caption         =   "Consultas  de Cuadratura "
   ClientHeight    =   8805
   ClientLeft      =   60
   ClientTop       =   450
   ClientWidth     =   14385
   Icon            =   "Form43.frx":0000
   LinkTopic       =   "Form43"
   ScaleHeight     =   8805
   ScaleWidth      =   14385
   StartUpPosition =   2  'CenterScreen
   Begin VB.CommandButton Command2 
      BackColor       =   &H00A4E8CB&
      Caption         =   "&Consulta"
      Height          =   345
      Left            =   10680
      Style           =   1  'Graphical
      TabIndex        =   6
      ToolTipText     =   "Consulta según criterio seleccionado"
      Top             =   1560
      Width           =   1395
   End
   Begin VB.PictureBox Picture2 
      Appearance      =   0  'Flat
      BackColor       =   &H00C0C0C0&
      BorderStyle     =   0  'None
      ForeColor       =   &H80000008&
      Height          =   810
      Left            =   11400
      Picture         =   "Form43.frx":030A
      ScaleHeight     =   810
      ScaleWidth      =   2295
      TabIndex        =   16
      Top             =   -320
      Width           =   2295
   End
   Begin VB.Frame Frame2 
      BackColor       =   &H00E6E8E8&
      Caption         =   "Informes Por"
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
      Height          =   1455
      Left            =   120
      TabIndex        =   15
      Top             =   600
      Width           =   2175
      Begin VB.OptionButton OptionInforme 
         BackColor       =   &H00E6E8E8&
         Caption         =   "Gral. Tesoreria"
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
         Left            =   120
         TabIndex        =   2
         Top             =   1080
         Width           =   1935
      End
      Begin VB.OptionButton OptionInforme 
         BackColor       =   &H00E6E8E8&
         Caption         =   "F8 General"
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
         Left            =   120
         TabIndex        =   1
         Top             =   720
         Width           =   1935
      End
      Begin VB.OptionButton OptionInforme 
         BackColor       =   &H00E6E8E8&
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
         Index           =   0
         Left            =   120
         TabIndex        =   0
         Top             =   360
         Width           =   1935
      End
   End
   Begin VB.Frame Frame1 
      BackColor       =   &H00E6E8E8&
      Caption         =   "Criterio"
      Enabled         =   0   'False
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
      Height          =   1455
      Left            =   2400
      TabIndex        =   11
      Top             =   600
      Width           =   11415
      Begin VB.CommandButton Command4 
         BackColor       =   &H00A4E8CB&
         Caption         =   "&Cerrar Terminal"
         Height          =   345
         Left            =   9840
         Style           =   1  'Graphical
         TabIndex        =   22
         ToolTipText     =   "Consulta según criterio seleccionado"
         Top             =   960
         Visible         =   0   'False
         Width           =   1395
      End
      Begin VB.ComboBox Combo3 
         BackColor       =   &H00F5F5F5&
         ForeColor       =   &H00000080&
         Height          =   315
         ItemData        =   "Form43.frx":194E
         Left            =   4200
         List            =   "Form43.frx":1950
         Style           =   2  'Dropdown List
         TabIndex        =   21
         Top             =   600
         Visible         =   0   'False
         Width           =   975
      End
      Begin VB.ComboBox Combo1 
         BackColor       =   &H00FFFFFF&
         ForeColor       =   &H00000080&
         Height          =   315
         Left            =   240
         Style           =   2  'Dropdown List
         TabIndex        =   3
         Top             =   600
         Width           =   3735
      End
      Begin MSComCtl2.DTPicker DTPicker1 
         Height          =   315
         Left            =   5280
         TabIndex        =   4
         Top             =   600
         Width           =   1335
         _ExtentX        =   2355
         _ExtentY        =   556
         _Version        =   393216
         CalendarBackColor=   16119285
         CalendarForeColor=   128
         CalendarTitleBackColor=   12632256
         CalendarTitleForeColor=   128
         CalendarTrailingForeColor=   8421504
         Format          =   137822209
         CurrentDate     =   37707
      End
      Begin MSComCtl2.DTPicker DTPicker2 
         Height          =   315
         Left            =   6720
         TabIndex        =   5
         Top             =   600
         Width           =   1335
         _ExtentX        =   2355
         _ExtentY        =   556
         _Version        =   393216
         CalendarBackColor=   16119285
         CalendarForeColor=   128
         CalendarTitleBackColor=   12632256
         CalendarTitleForeColor=   128
         CalendarTrailingForeColor=   8421504
         Format          =   137625601
         CurrentDate     =   37707
      End
      Begin VB.Label Labelterminal 
         BackStyle       =   0  'Transparent
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
         Left            =   4200
         TabIndex        =   20
         Top             =   240
         Visible         =   0   'False
         Width           =   1215
      End
      Begin VB.Label Labellocal 
         BackStyle       =   0  'Transparent
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
         TabIndex        =   14
         Top             =   240
         Width           =   855
      End
      Begin VB.Label Labelfecha 
         BackStyle       =   0  'Transparent
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
         Left            =   6720
         TabIndex        =   13
         Top             =   240
         Width           =   1455
      End
      Begin VB.Label Label1 
         BackStyle       =   0  'Transparent
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
         Left            =   5280
         TabIndex        =   12
         Top             =   240
         Width           =   1575
      End
   End
   Begin VB.CommandButton Command1 
      BackColor       =   &H00A4E8CB&
      Caption         =   "Generar &Excel"
      Height          =   345
      Left            =   10800
      Style           =   1  'Graphical
      TabIndex        =   7
      ToolTipText     =   "Genera una planilla Excel "
      Top             =   8280
      Width           =   1395
   End
   Begin VB.ComboBox Combo2 
      Height          =   315
      Left            =   6960
      Style           =   2  'Dropdown List
      TabIndex        =   10
      Top             =   8280
      Visible         =   0   'False
      Width           =   975
   End
   Begin VB.CommandButton Command3 
      BackColor       =   &H00A4E8CB&
      Caption         =   "&Salir"
      Height          =   345
      Left            =   12360
      Style           =   1  'Graphical
      TabIndex        =   8
      Top             =   8280
      Width           =   1395
   End
   Begin MSFlexGridLib.MSFlexGrid Grid1 
      Height          =   6015
      Left            =   120
      TabIndex        =   9
      Top             =   2160
      Width           =   13725
      _ExtentX        =   24209
      _ExtentY        =   10610
      _Version        =   393216
      Cols            =   3
      FixedCols       =   0
      BackColor       =   16119285
      ForeColor       =   128
      BackColorFixed  =   10807499
      ForeColorFixed  =   3560496
      BackColorBkg    =   15132904
      WordWrap        =   -1  'True
      AllowBigSelection=   0   'False
      HighLight       =   0
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
   Begin VB.Image Image3 
      Height          =   1500
      Left            =   11270
      Picture         =   "Form43.frx":1952
      Top             =   490
      Width           =   2745
   End
   Begin VB.Label Label11 
      BackColor       =   &H00C0C0C0&
      Height          =   6075
      Left            =   14000
      TabIndex        =   19
      Top             =   480
      Width           =   495
   End
   Begin VB.Label Label3 
      BackColor       =   &H00C0C0C0&
      Height          =   1245
      Left            =   13560
      TabIndex        =   18
      Top             =   -240
      Width           =   1005
   End
   Begin VB.Label Label2 
      BackColor       =   &H00C0C0C0&
      Height          =   6075
      Left            =   14000
      TabIndex        =   17
      Top             =   5280
      Width           =   495
   End
   Begin VB.Image Image2 
      Height          =   1830
      Left            =   -120
      Picture         =   "Form43.frx":1C3E
      Top             =   -1320
      Width           =   4665
   End
   Begin VB.Image Image1 
      Height          =   810
      Left            =   840
      Picture         =   "Form43.frx":1F22
      Top             =   -280
      Width           =   13590
   End
End
Attribute VB_Name = "Form43"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Dim vf_suspender As Boolean
Dim VF_NumInforme As Integer
Dim Zefectivo As Double, Zchequedia As Double, Zdolares As Double
Dim Zeuros As Double, Zchequefecha As Double, Ztarjeta As Double
Dim Zticketpago As Double, Ztarjetacmr As Double
Dim ZReales As Double, ZPesoArg As Double

Dim ZZZefectivo As Double, ZZZchequedia As Double, ZZZdolares As Double
Dim ZZZeuros As Double, ZZZchequefecha As Double, ZZZtarjeta As Double
Dim ZZZticketpago As Double, ZZZtarjetacmr As Double
Private Function ValorCompensacion(ByVal vfecha As String, ByVal VLocal As String, ByVal vterminal As String, ByVal vcierrey As String) As Double
Dim SumaConceptos  As Double
Dim totcon  As Integer
Dim nombreObjeto, vl_cierrey As String

Set Consulta = CreateObject("ADODB.Recordset")
With Consulta
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With
   ValorCompensacion = 0
   SumaConceptos = 0
 
   
 
   sq = StrSumCompensado(vfecha, VLocal, vterminal, vcierrey)
   On Error GoTo oraerror
   Call Consulta.Open(sq)
   totcon = Consulta.RecordCount
  
   For i = 0 To totcon - 1
      SumaConceptos = SumaConceptos + CDbl(Change_Char(Consulta.Fields(0).Value, ".", ","))
      Consulta.MoveNext
   Next i
   
   Set Consulta.ActiveConnection = Nothing
   
   ValorCompensacion = SumaConceptos
   Exit Function
oraerror:
Set Consulta.ActiveConnection = Nothing
End Function

Public Function StrSumCompensado(ByVal strFecha As String, ByVal StrLocal As String, ByVal strTERMINAL As String, ByVal StrCierrey As String) As String
Dim sq As String
StrSumCompensado = ""

' subquery para mov TC calcula la diferencia entre los compensado y por compensar
sq = " select " & _
" " & _
" " & _
" (  nvl(( select  sum(m.mov_monto)" & _
"            from   vta_" & Flg_Pais$ & "movdet m" & _
"            where m.MOV_FECHA      = to_date('" & Format(strFecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')"

sq = sq & "     and m.mov_local  = " & StrLocal & " "

If strTERMINAL <> "" Then
    sq = sq & "    and m.mov_terminal  = " & strTERMINAL & " "
End If

If StrCierrey <> "" And StrCierrey <> "0" Then
    sq = sq & "    and m.mov_cierrey  = " & StrCierrey & " "
End If


'sq = sq & "    and m.MOV_REGUL = 'S'" & _

sq = sq & "   and m.mov_tipomov = 'TC' ),0)   - " & _
"      nvl((  select  sum(mov.mov_monto)" & _
"             from   vta_" & Flg_Pais$ & "movdet mov" & _
"             where mov.MOV_FECHAREG = to_date('" & Format(strFecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')"

    sq = sq & "     and mov.mov_local  = " & StrLocal & " "

If strTERMINAL <> "" Then
    sq = sq & "     and mov.mov_terminal  = " & strTERMINAL & " "
End If
If StrCierrey <> "" And StrCierrey <> "0" Then
    sq = sq & "    and mov.mov_cierrey  = " & StrCierrey & " "
End If

sq = sq & "     and mov.MOV_REGUL = 'S' and   mov.mov_tipomov = 'TC'),0) )" & _
"  as mov_monto" & _
" ,d.mov_tipomov " & _
" " & _
" from  vta_" & Flg_Pais$ & "concepdif d" & _
" where d.mov_tipomov = 'TC'" & _
" union "



' subquery para mov SN calcula la diferencia entre los compensado y por compensar
sq = sq & " select " & _
" " & _
" " & _
" ( nvl(( select  sum(m.mov_monto)" & _
"          from   vta_" & Flg_Pais$ & "movdet m" & _
"          where   m.MOV_FECHA      = to_date('" & Format(strFecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')"

    sq = sq & "  and   m.mov_local  = " & StrLocal & " "
If strTERMINAL <> "" Then
   sq = sq & "  and   m.mov_terminal  = " & strTERMINAL & " "
End If
If StrCierrey <> "" And StrCierrey <> "0" Then
    sq = sq & "    and m.mov_cierrey  = " & StrCierrey & " "
End If

sq = sq & "  and   m.MOV_REGUL = 'S'" & _
"            and   m.mov_tipomov = 'SN' ),0)    -" & _
"    nvl(( select  sum(mov.mov_monto)" & _
"          from   vta_" & Flg_Pais$ & "movdet mov" & _
"          where mov.MOV_FECHAREG   = to_date('" & Format(strFecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')"

sq = sq & "  and mov.mov_local  = " & StrLocal & " "

If strTERMINAL <> "" Then
    sq = sq & "  and mov.mov_terminal  = " & strTERMINAL & " "
End If
If StrCierrey <> "" And StrCierrey <> "0" Then
    sq = sq & "    and mov.mov_cierrey  = " & StrCierrey & " "
End If

sq = sq & "  and mov.MOV_REGUL = 'S'" & _
"            and mov.mov_tipomov = 'SN'),0) )" & _
" as mov_monto" & _
" ,d.mov_tipomov " & _
" " & _
" from  vta_" & Flg_Pais$ & "concepdif d" & _
" where  d.mov_tipomov = 'SN'" & _
" union "

' subquery para mov AF calcula la diferencia entre los compensado y por compensar
'sq = sq & " select " & _
'" " & _
'" " & _
'" ( nvl(( select  sum(m.mov_monto)" & _
'"          from   vta_" & Flg_Pais$ & "movdet m" & _
'"          where   m.MOV_FECHA      = to_date('" & Format(StrFecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')"
'sq = sq & "  and   m.mov_local  = " & StrLocal & " "
'
'If StrTerminal <> "" Then
'    sq = sq & "  and   m.mov_terminal  = " & StrTerminal & " "
'End If
'If StrCierrey <> "" And StrCierrey <> "0" Then
'    sq = sq & "    and m.mov_cierrey  = " & StrCierrey & " "
'End If
'
'sq = sq & "  and   m.MOV_REGUL = 'S'  and m.mov_vbpor='S'  " & _
'"            and   m.mov_tipomov = 'AF' ),0)    -" & _
'"    nvl(( select  sum(mov.mov_monto)" & _
'"          from   vta_" & Flg_Pais$ & "movdet mov" & _
'"          where mov.MOV_FECHAREG   = to_date('" & Format(StrFecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')"
'
'    sq = sq & "  and mov.mov_local  = " & StrLocal & " "
'
'If StrTerminal <> "" Then
'    sq = sq & "  and mov.mov_terminal  = " & StrTerminal & " "
'End If
'If StrCierrey <> "" And StrCierrey <> "0" Then
'    sq = sq & "    and mov.mov_cierrey  = " & StrCierrey & " "
'End If
'
'sq = sq & "  and mov.MOV_REGUL = 'S' and mov.mov_vbpor='S'  " & _
'"            and mov.mov_tipomov = 'AF'),0) )" & _
'" as mov_monto" & _
'" ,d.mov_tipomov " & _
'" " & _
'" from  vta_" & Flg_Pais$ & "concepdif d" & _
'" where  d.mov_tipomov = 'AF'" & _
'" union "

sq = sq & " select  " & _
" " & _
" " & _
" (  nvl((select  sum(m.mov_monto)" & _
"          from   vta_" & Flg_Pais$ & "movdet m" & _
"          where  m.MOV_FECHA      = to_date('" & Format(strFecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')"
    sq = sq & "  and  m.mov_local  = " & StrLocal & " "

If strTERMINAL <> "" Then
    sq = sq & "  and  m.mov_terminal  = " & strTERMINAL & " "
End If
If StrCierrey <> "" And StrCierrey <> "0" Then
    sq = sq & "    and m.mov_cierrey  = " & StrCierrey & " "
End If
sq = sq & "  and  m.MOV_REGUL = 'S'" & _
"            and  m.mov_tipomov = 'BF' ),0)     " & _
" ) as mov_monto" & _
" ,d.mov_tipomov " & _
" " & _
" from  vta_" & Flg_Pais$ & "concepdif d" & _
" where d.mov_tipomov = 'BF'" & _
" union "


' subquery para mov ND calcula la diferencia entre los compensado y por compensar
sq = sq & " select " & _
" " & _
" " & _
" ( nvl(( select  sum(m.mov_monto)" & _
"          from   vta_" & Flg_Pais$ & "movdet m" & _
"          where   m.MOV_FECHA      = to_date('" & Format(strFecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')"
sq = sq & "  and   m.mov_local  = " & StrLocal & " "

If strTERMINAL <> "" Then
    sq = sq & "  and   m.mov_terminal  = " & strTERMINAL & " "
End If
If StrCierrey <> "" And StrCierrey <> "0" Then
    sq = sq & "    and m.mov_cierrey  = " & StrCierrey & " "
End If

sq = sq & "  and   m.MOV_REGUL = 'S'" & _
"            and   m.mov_tipomov = 'ND' ),0)    -" & _
"    nvl(( select  sum(mov.mov_monto)" & _
"          from   vta_" & Flg_Pais$ & "movdet mov" & _
"          where mov.MOV_FECHAREG   = to_date('" & Format(strFecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')"

    sq = sq & "  and mov.mov_local  = " & StrLocal & " "

If strTERMINAL <> "" Then
    sq = sq & "  and mov.mov_terminal  = " & strTERMINAL & " "
End If
If StrCierrey <> "" And StrCierrey <> "0" Then
    sq = sq & "    and mov.mov_cierrey  = " & StrCierrey & " "
End If

sq = sq & "  and mov.MOV_REGUL = 'S'" & _
"            and mov.mov_tipomov = 'ND'),0) )" & _
" as mov_monto" & _
" ,d.mov_tipomov " & _
" " & _
" from  vta_" & Flg_Pais$ & "concepdif d" & _
" where  d.mov_tipomov = 'ND'" & _
" union "


' subquery para mov FN calcula la diferencia entre los compensado y por compensar
sq = sq & " select " & _
" " & _
" " & _
" ( nvl(( select  sum(m.mov_monto)" & _
"          from   vta_" & Flg_Pais$ & "movdet m" & _
"          where   m.MOV_FECHA      = to_date('" & Format(strFecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')"
sq = sq & "  and   m.mov_local  = " & StrLocal & " "

If strTERMINAL <> "" Then
    sq = sq & "  and   m.mov_terminal  = " & strTERMINAL & " "
End If
If StrCierrey <> "" And StrCierrey <> "0" Then
    sq = sq & "    and m.mov_cierrey  = " & StrCierrey & " "
End If

sq = sq & "  and   m.MOV_REGUL = 'S'" & _
"            and   m.mov_tipomov = 'FN' ),0)    -" & _
"    nvl(( select  sum(mov.mov_monto)" & _
"          from   vta_" & Flg_Pais$ & "movdet mov" & _
"          where mov.MOV_FECHAREG   = to_date('" & Format(strFecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')"

    sq = sq & "  and mov.mov_local  = " & StrLocal & " "

If strTERMINAL <> "" Then
    sq = sq & "  and mov.mov_terminal  = " & strTERMINAL & " "
End If
If StrCierrey <> "" And StrCierrey <> "0" Then
    sq = sq & "    and mov.mov_cierrey  = " & StrCierrey & " "
End If

sq = sq & "  and mov.MOV_REGUL = 'S'" & _
"            and mov.mov_tipomov = 'FN'),0) )" & _
" as mov_monto" & _
" ,d.mov_tipomov " & _
" " & _
" from  vta_" & Flg_Pais$ & "concepdif d" & _
" where  d.mov_tipomov = 'FN'" & _
" union "

' SACADOS

''"     nvl((select sum(mov.mov_monto)" & _
''"          from   vta_" & Flg_Pais$ & "movdet mov" & _
''"          where  mov.MOV_FECHAREG   = to_date('" & Format(StrFecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')"
''If Gopcion = "T" Or Gopcion = "G" Then
''    sq = sq & "  and  mov.mov_local  = " & StrLocal & " "
''End If
''If Gopcion = "T" Then
''    sq = sq & "  and  mov.mov_terminal  = " & StrTerminal & " "
''End If
''sq = sq & "  and  mov.MOV_REGUL = 'S'" & _
''"            and  mov.mov_tipomov = 'BF'),0) )" & _

' subquery para mov NP calcula la diferencia entre los compensado y por compensar
sq = sq & " select " & _
" " & _
" " & _
" ( nvl(( select  sum(m.mov_monto)" & _
"          from   vta_" & Flg_Pais$ & "movdet m" & _
"          where  m.MOV_FECHA      = to_date('" & Format(strFecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')"

sq = sq & "  and  m.mov_local  = " & StrLocal & " "

If strTERMINAL <> "" Then
    sq = sq & "  and  m.mov_terminal  = " & strTERMINAL & " "
End If
If StrCierrey <> "" And StrCierrey <> "0" Then
    sq = sq & "    and m.mov_cierrey  = " & StrCierrey & " "
End If

sq = sq & "  and  m.MOV_REGUL = 'S'" & _
"            and  m.mov_tipomov  in ( 'NP','FT'  ) ),0)      ) "
sq = sq & " as mov_monto" & _
" ,d.mov_tipomov " & _
" " & _
" from  vta_" & Flg_Pais$ & "concepdif d" & _
" where  d.mov_tipomov  in ( 'NP','FT'  )" & _
" union "


' subquery para  el resto de los movimientos 'CT','CA','RE','CR','PC','DN','P1','P2','DI','RP','DP','DE'
sq = sq & " select " & _
"  " & _
" " & _
" nvl(sum(m.mov_monto),0) as mov_monto" & _
" ,d.mov_tipomov  " & _
" " & _
" from  vta_" & Flg_Pais$ & "movdet m" & _
"      ,vta_" & Flg_Pais$ & "concepdif d" & _
" where      m.mov_fecha  = to_date('" & Format(strFecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')"

    sq = sq & "  and m.mov_local  = " & StrLocal & " "
If strTERMINAL <> "" Then
    sq = sq & "  and m.mov_terminal  = " & strTERMINAL & " "
End If
If StrCierrey <> "" And StrCierrey <> "0" Then
    sq = sq & "    and m.mov_cierrey  = " & StrCierrey & " "
End If

sq = sq & "  and m.MOV_REGUL = 'S'" & _
"   and m.MOV_FECHAREG  is not null" & _
"   and m.mov_tipomov = d.mov_tipomov" & _
"   and d.mov_tipomov in  (  'AL','TU','DV','P1','P2','CM','CB','CC','SB' ,'SC','SV','CP','CF','CT'" & IIf(Flg_Pais$ = "CHI" Or Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "KFCL" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "", " ", ",'CA' ") & ",'RE','CR','PC','DN','AF','DD','AA','DI','AV','RP','DP','DE','PM' ) " & _
" group by d.mov_tipomov  "
sq = sq & " union "

' ('DV','CM','CB','CC','SB' ,'SC','SV','CP','CF','CT','CA','RE','CR','PC','DN','P1','P2','DI','RP','DP','DE')" & _
' sacamos esta condición "   and m.MOV_REGULPOR is not null" & _
' subquery para los movimientos 'CT','CA','RE','CR','PC','DN','P1','P2','DI','RP','DP','DE' que no tienen valor segun filtro

'sq = sq & " select " & _
'" " & _
'" " & _
'" ,0 as mov_monto" & _
'" " & _
'" " & _
'" from   vta_" & Flg_Pais$ & "concepdif d" & _
'" where  vta_coddif  <> 1" & _
'"   and  d.mov_tipomov not in ('NP', 'TC',  'BF','SN','DT')" & _
'"   and  d.mov_tipomov not in (select m.mov_tipomov" & _
'"                              from   vta_" & Flg_Pais$ & "movdet m" & _
'"                              where  m.mov_fecha = to_date('" & Format(StrFecha, VgFormatoFechaWhere) & "','yyyy/mm/dd')"
'If Gopcion = "T" Or Gopcion = "G" Then
'    sq = sq & "                and  m.mov_local = " & StrLocal & " "
'End If
'If Gopcion = "T" Then
'    sq = sq & "                and  m.mov_terminal = " & StrTerminal & " "
'End If
'
'sq = sq & "                    and  m.MOV_REGUL =  'S'" & _
'"                              and  m.MOV_FECHAREG is not null" & _
'"                              and  m.mov_tipomov in ('CT','CA','RE','CR','PC','DN','P1','P2','DI','RP','DP','DE' ) " & _
'" group by m.mov_tipomov )" & _
'" union "

' sacamos esta con "                              and  m.MOV_REGULPOR is not null" & _

' mov de venta VC
sq = sq & " select " & _
" " & _
" " & _
" ( select nvl(sum(m.VEN_MONTO),0)" & _
"    from   vta_" & Flg_Pais$ & "difvend m" & _
"    where  m.ven_fecha = to_date('" & Format(strFecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')"
sq = sq & " and    m.ven_local = " & StrLocal & " "
If strTERMINAL <> "" Then
    sq = sq & " and    m.ven_terminal = " & strTERMINAL
End If
If StrCierrey <> "" And StrCierrey <> "0" Then
    sq = sq & "    and m.ven_cierrey  = " & StrCierrey & " "
End If

sq = sq & " )" & _
" as MOV_MONTO" & _
" ,d.mov_tipomov " & _
" " & _
" from vta_" & Flg_Pais$ & "concepdif d" & _
" where vta_coddif=1" & _
" union "

'' mov   'DT' cuando no existe movimiento
'sq = sq & " select " & _
'" " & _
'" " & _
'" ,0 as mov_monto" & _
'" " & _
'" " & _
'" from   vta_" & Flg_Pais$ & "concepdif d" & _
'" where  d.mov_tipomov ='DT' and" & _
'"        d.mov_tipomov not in (select m.mov_tipomov" & _
'"                              from   vta_" & Flg_Pais$ & "movdet m , vta_" & Flg_Pais$ & "concepdif d" & _
'"                              where  m.mov_fecha  = to_date('" & Format(StrFecha, VgFormatoFechaWhere) & "','yyyy/mm/dd')" & _
'"                              and m.MOV_ROL   <> 0  " & _
'"                              and m.mov_tipomov = d.mov_tipomov "
'If Gopcion = "T" Or Gopcion = "G" Then
'sq = sq & "                    and m.mov_local  = " & StrLocal & " "
'End If
'If Gopcion = "T" Then
'sq = sq & "                    and m.mov_terminal  = " & StrTerminal
'End If
'sq = sq & "             and d.mov_tipomov ='DT'  " & _
'"                              and m.mov_monto > 0 " & _
'"                              group by m.mov_tipomov)" & _
'" union "
'
'and m.MOV_ROL   <> 0
' mov   'DT'
sq = sq & " select " & _
" " & _
" " & _
" nvl(sum(m.mov_monto),0) as mov_monto" & _
" , d.mov_tipomov  " & _
" " & _
" from   vta_" & Flg_Pais$ & "movdet m , vta_" & Flg_Pais$ & "concepdif d" & _
" where  m.mov_fecha  = to_date('" & Format(strFecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')" & _
"   and m.mov_numero <> m.mov_terminal  "

sq = sq & "   and m.mov_local  = " & StrLocal & " "

If strTERMINAL <> "" Then
    sq = sq & "   and m.mov_terminal  = " & strTERMINAL & " "
End If
If StrCierrey <> "" And StrCierrey <> "0" Then
    sq = sq & "    and m.mov_cierrey  = " & StrCierrey & " "
End If


sq = sq & "       and  m.mov_tipomov = d.mov_tipomov   " & _
"                 and d.mov_tipomov in('DT','NC')  " & _
" group by  d.mov_tipomov  " & _
" union "
' mov   'DT'
sq = sq & " select " & _
" " & _
" " & _
" nvl(sum(m.mov_monto),0) as mov_monto" & _
" , d.mov_tipomov  " & _
" " & _
" from   vta_" & Flg_Pais$ & "movdet m , vta_" & Flg_Pais$ & "concepdif d" & _
" where  m.mov_fecha  = to_date('" & Format(strFecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')" & _
" and    m.mov_numero = m.mov_terminal  "

    sq = sq & "   and m.mov_local  = " & StrLocal & " "

If strTERMINAL <> "" Then
    sq = sq & "   and    m.mov_terminal  = " & strTERMINAL & " "
End If
If StrCierrey <> "" And StrCierrey <> "0" Then
    sq = sq & "    and m.mov_cierrey  = " & StrCierrey & " "
End If
sq = sq & "       and  m.mov_tipomov = d.mov_tipomov   " & _
    "                 and d.mov_tipomov in('DT','NC')  " & _
    " group by  d.mov_tipomov  "
    
If (Flg_Pais$ = "" Or Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "CHI" Or Flg_Pais$ = "CMCL" Or Flg_Pais$ = "KFCL" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "SFCL") Then
    sq = sq & " union "
      sq = sq & " select " & _
    "  " & _
    " " & _
    " nvl(sum(m.mov_monto),0) as mov_monto" & _
    " ,d.mov_tipomov  " & _
    "  " & _
    " from  vta_" & Flg_Pais$ & "cartaaviso m" & _
    "      ,vta_" & Flg_Pais$ & "concepdif d" & _
    " where      m.mov_fecha  = to_date('" & Format(strFecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')"
    
        sq = sq & "  and m.mov_local  = " & StrLocal & " "
    If strTERMINAL <> "" Then
        sq = sq & "  and m.mov_terminal  = " & strTERMINAL & " "
    End If
    If StrCierrey <> "" And StrCierrey <> "0" Then
        sq = sq & "    and m.mov_cierrey  = " & StrCierrey & " "
    End If
    
    sq = sq & "  and m.MOV_REGUL = 'S'" & _
    "   and m.MOV_FECHAREG  is not null" & _
    "   and m.mov_tipomov = d.mov_tipomov" & _
    "   and d.mov_tipomov  = 'CA' " & _
    " group by d.mov_tipomov  "
End If
' Xintec informe Concepto "Devolucion Inet" 21-12-2017
' subquery para mov TB calcula la valor compensado
    
sq = sq & " union  select " & _
" " & _
" " & _
" nvl(sum(m.mov_monto),0) as mov_monto" & _
" , d.mov_tipomov  " & _
" " & _
" from   vta_" & Flg_Pais$ & "movdet m , vta_" & Flg_Pais$ & "concepdif d" & _
" where  m.mov_fecha  = to_date('" & Format(strFecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')" & _
" and    m.mov_numero = m.mov_terminal  "
 
    sq = sq & "   and m.mov_local  = " & StrLocal & " "
 
  If strTERMINAL <> "" Then
        sq = sq & "  and m.mov_terminal  = " & strTERMINAL & " "
    End If
    If StrCierrey <> "" And StrCierrey <> "0" Then
        sq = sq & "    and m.mov_cierrey  = " & StrCierrey & " "
    End If

sq = sq & "       and  m.mov_tipomov = d.mov_tipomov   " & _
"                 and d.mov_tipomov in('TB')  " & _
" group by  d.mov_tipomov  "
StrSumCompensado = sq
End Function


Private Sub Combo1_Click()
Combo2.ListIndex = Combo1.ListIndex
'xintec NR 11-03-2019
If (Flg_Pais$ = "MAPE" Or Flg_Pais$ = "MPAM" Or Flg_Pais$ = "SPOR") Then
    Call LeeVendedor
Else
    Call LeeTerminales
End If
End Sub

Private Sub Command1_Click()
If Grid1.Rows = 1 Then
   MsgBox "No hay datos para generar archivo", vbCritical + vbDefaultButton1, Me.Caption
   Exit Sub
End If
    
GeneraExcel VF_NumInforme


End Sub

Private Sub Command2_Click()
Dim maxvldia, minvldia, i As Integer
Dim vllocal As Integer
Dim vlterminal As Integer
Dim cd, cl, ct   As Integer
Dim respuesta As Integer
Dim fila As Integer
Screen.MousePointer = 11

'If DTPicker1.Value > DTPicker2.Value Then
'   MsgBox "La fecha inicio  debe ser menor a fecha final ", vbCritical + vbDefaultButton1, Me.Caption
'   Screen.MousePointer = 0
'   Exit Sub
'End If
' FSCC-7789'

VF_NumInforme = -1
For i = 0 To 2
    If OptionInforme(i).Value = True Then
       VF_NumInforme = i
       Exit For
    End If
Next i

If VF_NumInforme = -1 Then
   MsgBox "Seleccione un tipo de informe ", vbCritical + vbDefaultButton1, Me.Caption
   Screen.MousePointer = 0
   Exit Sub
End If

If Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "CHI" Or Flg_Pais$ = "" Or Flg_Pais$ = "PER" Or Flg_Pais$ = "MAPE" Or Flg_Pais$ = "FAOR" Or Flg_Pais$ = "SPOR" Then
    Select Case VF_NumInforme
    Case 2
        Call SubBuscarOpcion2SOAR_SOUY(VF_NumInforme)
    Case 1
         Call SubBuscarOpcion1SOAR_SOUY(VF_NumInforme)
    Case 0
        Call SubBuscarOpcionSOAR_SOUY(VF_NumInforme)
    End Select
Else
    Select Case VF_NumInforme
    Case 2
        Call SubBuscarOpcion2(VF_NumInforme)
    Case 1
         Call SubBuscarOpcion1(VF_NumInforme)
    Case 0
        Call SubBuscarOpcion(VF_NumInforme)
    End Select
End If
 
Screen.MousePointer = 0

End Sub
Private Sub SubBuscarOpcion(ByVal Index As Integer)
Dim DiferenciaCaja, DiferenciaReal, xFecha, xlocal, Xterminal, XEstado, Xcierrey, Vcompensado
Dim BEfectivo, BChequeDia, BDolares, BEuros, Btarjeta, BTicker, Bcmr
Dim nFILA
Dim VLocal As String
Grid1.Visible = False

If Flg_Pais$ = "SFCL" Then
    DTPicker2.Value = DTPicker1.Value
End If

Call definegrid(Index)
Combo1.ListIndex = Combo2.ListIndex
VLocal = Combo2.Text
If VLocal = 0 Then
    VLocal = ""
End If
 sq = FuncStrPivote(VLocal)

On Error GoTo salir
Set BuscarOpcion = CreateObject("ADODB.Recordset")
With BuscarOpcion
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With

Call BuscarOpcion.Open(sq)

' EUROS = "304"   ' "233"  '
'DOLAR = "305"

nFILA = 1
While Not BuscarOpcion.EOF
      xFecha = BuscarOpcion.Fields(0).Value
      xlocal = BuscarOpcion.Fields(1).Value
      Xterminal = BuscarOpcion.Fields(2).Value
      
      Xcierrey = BuscarOpcion.Fields(3).Value
      
      If Xterminal = 1201 Then
        Y = 2
      End If
      
      XEstado = Format(BuscarOpcion.Fields(4).Value, gFormat)
      X = FuncValorZoY(xFecha, xlocal, Xterminal, Xcierrey)
      BEfectivo = FuncBuscarRecEfectivo("EFE", xFecha, xlocal, Xterminal, Xcierrey)
      BChequeDia = FuncBuscarRecEfectivo("CHE", xFecha, xlocal, Xterminal, Xcierrey)
      BDolares = FuncBuscarRecModRec(DOLAR, xFecha, xlocal, Xterminal, Xcierrey)
      BEuros = FuncBuscarRecModRec(EUROS, xFecha, xlocal, Xterminal, Xcierrey)
      BChequeFecha = FuncBuscarRecCheFecha(xFecha, xlocal, Xterminal, Xcierrey, "")
      
'      If Flg_Pais$ = "SFCL" Then
'        Btarjeta = CDbl(Change_Char(FuncLeeTarjeta(CStr(Xfecha), CStr(xlocal), CStr(Xterminal), CTARJ), ".", ","))
'      Else
        Btarjeta = FuncBuscarRecTarj("tarj", xFecha, xlocal, Xterminal, Xcierrey)
'      End If
      
      If Flg_Pais$ = "PER" Or Flg_Pais$ = "SOPE" Or Flg_Pais$ = "SPOR" Or Flg_Pais$ = "MAPE" Or Flg_Pais$ = "MPAM" Or Flg_Pais$ = "FAOR" Or Flg_Pais$ = "HTPE" Then
         BTicker = FuncBuscarRecCheFecha(xFecha, xlocal, Xterminal, Xcierrey, "Cupones")
      Else
         BTicker = FuncBuscarRecTarj("ticket", xFecha, xlocal, Xterminal, Xcierrey)
      End If
      Bcmr = FuncBuscarRecTarj("CMR", xFecha, xlocal, Xterminal, Xcierrey)
      Vcompensado = ValorCompensacion(xFecha, xlocal, Xterminal, Xcierrey)
      
      If Flg_Pais$ = "SFCL" Then
        DiferenciaCaja = ((BEfectivo - Zefectivo) + (BChequeDia - Zchequedia) + _
                          (Zdolares) + (BEuros - Zeuros) + _
                          (Btarjeta - Ztarjeta) + (BTicker - Zticketpago) + _
                          (Bcmr - Ztarjetacmr) + (BChequeFecha - Zchequefecha))
      'CK: 160531 Modificaciones F8 ARG
      ElseIf Flg_Pais$ = "ARG" Then
          DiferenciaCaja = ((BEfectivo - Zefectivo) + (BChequeDia - Zchequedia) + _
                          (BDolares - Zdolares) + (BEuros - Zeuros) + _
                          (Btarjeta - Ztarjeta) + (BTicker - Zticketpago) + _
                          (Bcmr - Ztarjetacmr) + (BChequeFecha - Zchequefecha))
      Else
      DiferenciaCaja = ((BEfectivo - Zefectivo) + (BChequeDia - Zchequedia) + _
                        (BDolares - Zdolares) + (BEuros - Zeuros) + _
                        (Btarjeta - Ztarjeta) + (BTicker - Zticketpago) + _
                        (Bcmr - Ztarjetacmr) + (BChequeFecha - Zchequefecha))
      End If
              
      DiferenciaReal = (Format(DiferenciaCaja, gFormat) - Format(Vcompensado, gFormat))
      
      If Flg_Pais$ = "SFCL" Or Flg_Pais$ = "HTPE" Then
            Grid1.AddItem ""
            Grid1.TextMatrix(nFILA, 0) = Format(xFecha, VgFormatoFechaLectura)
            Grid1.TextMatrix(nFILA, 1) = xlocal
            Grid1.TextMatrix(nFILA, 2) = Xterminal
            Grid1.TextMatrix(nFILA, 3) = Xcierrey
            Grid1.row = nFILA
            Grid1.ColAlignment(4) = 7
            Grid1.ColAlignment(5) = 7
            Grid1.ColAlignment(6) = 7
           
            Grid1.TextMatrix(nFILA, 4) = Format((DiferenciaCaja), gFormat)
            Grid1.TextMatrix(nFILA, 5) = Format((Vcompensado), gFormat)
            Grid1.TextMatrix(nFILA, 6) = Format((DiferenciaReal), gFormat)
        
            Grid1.col = 7
            Select Case XEstado
                  Case -1
                     Grid1.CellBackColor = &HFF&       'rojo
                     Grid1.CellForeColor = &H80000005   'blanco
                     Grid1.TextMatrix(nFILA, 7) = "Pendiente"
                    
                  Case 0
                     Grid1.CellBackColor = &H80FFFF         'amarillo
                     Grid1.CellForeColor = &H0&            'negro
                     Grid1.TextMatrix(nFILA, 7) = "Pendiente"
                  Case 1
                     Grid1.CellBackColor = &H80FF80        ' verde
                     Grid1.CellForeColor = &H0&            ' negro
                      Grid1.TextMatrix(nFILA, 7) = "Cerrado"
                  Case 2
                     Grid1.CellBackColor = &HFF0000         ' azul
                     Grid1.CellForeColor = &H80000005      ' blanco
                    Grid1.TextMatrix(nFILA, 7) = "Impreso"
                  Case 3
                     Grid1.CellBackColor = &H0&          'negro
                     Grid1.CellForeColor = &H80000005    'blanco
                     Grid1.TextMatrix(nFILA, 7) = "Sin Datos"
             End Select
             nFILA = nFILA + 1

      Else
        'CK: 160531 Modificaciones F8 ARG
        '---INI---- xintec-nruz 16-10-2026 FSCC-12901: FACO muestra tambien las cajas con Diferencia Real 0 (como Chile) ----
        'If DiferenciaReal <> 0 Or Flg_Pais$ = "ARG" Then
        If DiferenciaReal <> 0 Or Flg_Pais$ = "ARG" Or Flg_Pais$ = "FACO" Then
        '---FIN---- xintec-nruz 16-10-2026 ----
            Grid1.AddItem ""
            Grid1.TextMatrix(nFILA, 0) = Format(xFecha, VgFormatoFechaLectura)
            Grid1.TextMatrix(nFILA, 1) = xlocal
            Grid1.TextMatrix(nFILA, 2) = Xterminal
            Grid1.TextMatrix(nFILA, 3) = Xcierrey
            Grid1.row = nFILA
            Grid1.ColAlignment(4) = 7
            Grid1.ColAlignment(5) = 7
            Grid1.ColAlignment(6) = 7
           
            Grid1.TextMatrix(nFILA, 4) = Format((DiferenciaCaja), gFormat)
            Grid1.TextMatrix(nFILA, 5) = Format((Vcompensado), gFormat)
            Grid1.TextMatrix(nFILA, 6) = Format((DiferenciaReal), gFormat)
        
            Grid1.col = 7
            Select Case XEstado
                  Case -1
                     Grid1.CellBackColor = &HFF&       'rojo
                     Grid1.CellForeColor = &H80000005   'blanco
                     Grid1.TextMatrix(nFILA, 7) = "Pendiente"
                    
                  Case 0
                     Grid1.CellBackColor = &H80FFFF         'amarillo
                     Grid1.CellForeColor = &H0&            'negro
                     Grid1.TextMatrix(nFILA, 7) = "Pendiente"
                  Case 1
                     Grid1.CellBackColor = &H80FF80        ' verde
                     Grid1.CellForeColor = &H0&            ' negro
                      Grid1.TextMatrix(nFILA, 7) = "Cerrado"
                  Case 2
                     Grid1.CellBackColor = &HFF0000         ' azul
                     Grid1.CellForeColor = &H80000005      ' blanco
                    Grid1.TextMatrix(nFILA, 7) = "Impreso"
                  Case 3
                     Grid1.CellBackColor = &H0&          'negro
                     Grid1.CellForeColor = &H80000005    'blanco
                     Grid1.TextMatrix(nFILA, 7) = "Sin Datos"
                  Case -2 'CK: 160531 Modificaciones F8 ARG
                     Grid1.CellBackColor = &H80FF&      'naranjo
                     Grid1.CellForeColor = &H80000005   'blanco
                     Grid1.TextMatrix(nFILA, 7) = "Pendiente"
             End Select
             nFILA = nFILA + 1
        End If
      End If
   BuscarOpcion.MoveNext
Wend
Grid1.Visible = True

 
Set BuscarOpcion.ActiveConnection = Nothing
BuscarOpcion.Close
Exit Sub

salir:
  
    Set BuscarOpcionCompensa.ActiveConnection = Nothing
    SystemMsg = "Problemas de comunicación con servidor, buscando información de perfiles"
    frmLogOraError.Show 1
    Exit Sub
End Sub


Private Sub SubBuscarOpcionSOAR_SOUY(ByVal Index As Integer)
Dim xFecha, xlocal, Xterminal, XEstado, Xcierrey, XFechaCierre '----Xintec sep 2025---
Dim BEfectivo, BChequeDia, BDolares, BEuros, Btarjeta, BTicker, Bcmr, BReales, BPesoArg
Dim nFILA
Dim VLocal As String
Dim dblDiferenciaCaja As Double, dblCompensado As Double, dblDiferenciaReal As Double

Grid1.Visible = False

If Flg_Pais$ = "SFCL" Then
    DTPicker2.Value = DTPicker1.Value
End If

Call definegrid(Index)
Combo1.ListIndex = Combo2.ListIndex
VLocal = Combo2.Text
If VLocal = 0 Then
    VLocal = ""
End If
 sq = FuncStrPivoteSOAR_SOUY(VLocal)

On Error GoTo salir
Set BuscarOpcion = CreateObject("ADODB.Recordset")
With BuscarOpcion
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With

Call BuscarOpcion.Open(sq)

' EUROS = "304"   ' "233"  '
'DOLAR = "305"
' FSCC-7789'

nFILA = 1
While Not BuscarOpcion.EOF
    xFecha = BuscarOpcion.Fields(0).Value
    xlocal = BuscarOpcion.Fields(1).Value
    Xterminal = BuscarOpcion.Fields(2).Value
    Xcierrey = BuscarOpcion.Fields(3).Value
    XEstado = Format(BuscarOpcion.Fields(4).Value, gFormat)
    
     If Flg_Pais$ = "" Or Flg_Pais$ = "CHI" Then
        XFechaCierre = BuscarOpcion.Fields(5).Value '----Xintec sep 2025---
         
        If Len(Trim(XFechaCierre)) = 10 Then
          XFechaCierre = Trim(XFechaCierre) & " 00:00"
        End If
    End If
         
         
    Rem RMOYAG 20170208 Problemas con el cuadre entre monedas y formas de pago F8 SOUY
    Rem Se crea funcion para homologar el tratramiento de cuadre por F8 Local
    Call TerminalCuadrado(xFecha, xlocal, Xterminal, Xcierrey, dblDiferenciaCaja, dblCompensado, dblDiferenciaReal)
          
    If (Flg_Pais$ = "SFCL" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "CHI" Or Flg_Pais$ = "" Or Flg_Pais$ = "PER" Or Flg_Pais$ = "HTPE" Or Flg_Pais$ = "FAOR" Or Flg_Pais$ = "MAPE" Or Flg_Pais$ = "SPOR") Then
        Grid1.AddItem ""
        Grid1.TextMatrix(nFILA, 0) = Format(xFecha, VgFormatoFechaLectura)
        Grid1.TextMatrix(nFILA, 1) = xlocal
        Grid1.TextMatrix(nFILA, 2) = Xterminal
        Grid1.TextMatrix(nFILA, 3) = Xcierrey
        Grid1.row = nFILA
        Grid1.ColAlignment(4) = 7
        Grid1.ColAlignment(5) = 7
        Grid1.ColAlignment(6) = 7
       
        Grid1.TextMatrix(nFILA, 4) = Format((dblDiferenciaCaja), gFormat)
        Grid1.TextMatrix(nFILA, 5) = Format((dblCompensado), gFormat)
        Grid1.TextMatrix(nFILA, 6) = Format((dblDiferenciaReal), gFormat)

        Grid1.col = 7
        Select Case XEstado
              Case -1
                 Grid1.CellBackColor = &HFF&       'rojo
                 Grid1.CellForeColor = &H80000005   'blanco
                 Grid1.TextMatrix(nFILA, 7) = "Pendiente"
              Case 0
                 Grid1.CellBackColor = &H80FFFF         'amarillo
                 Grid1.CellForeColor = &H0&            'negro
                 Grid1.TextMatrix(nFILA, 7) = "Pendiente"
              Case 1
                 Grid1.CellBackColor = &H80FF80        ' verde
                 Grid1.CellForeColor = &H0&            ' negro
                 Grid1.TextMatrix(nFILA, 7) = "Cerrado"
              Case 2
                 Grid1.CellBackColor = &HFF0000         ' azul
                 Grid1.CellForeColor = &H80000005      ' blanco
                 Grid1.TextMatrix(nFILA, 7) = "Impreso"
              Case 3
                 Grid1.CellBackColor = &H0&          'negro
                 Grid1.CellForeColor = &H80000005    'blanco
                 Grid1.TextMatrix(nFILA, 7) = "Sin Datos"
        End Select
         
        If dblDiferenciaReal = 0 And (Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY") Then
            If Not FuncValidarZoY(xFecha, xlocal, Xterminal, 0) Then
                Rem esta Descuadrado por medio Pado
                Grid1.CellBackColor = &HC0C0C0           ' Gris
                Grid1.CellForeColor = &H0&            ' negro
                Grid1.TextMatrix(nFILA, 7) = "Pendiente MP"
            End If
        End If
        
        If Flg_Pais$ = "" Or Flg_Pais$ = "CHI" Then
        Grid1.TextMatrix(nFILA, 8) = XFechaCierre '----Xintec sep 2025---
        End If
        nFILA = nFILA + 1
    Else
        If DiferenciaReal <> 0 Then
            Grid1.AddItem ""
            Grid1.TextMatrix(nFILA, 0) = Format(xFecha, VgFormatoFechaLectura)
            Grid1.TextMatrix(nFILA, 1) = xlocal
            Grid1.TextMatrix(nFILA, 2) = Xterminal
            Grid1.TextMatrix(nFILA, 3) = Xcierrey
            Grid1.row = nFILA
            Grid1.ColAlignment(4) = 7
            Grid1.ColAlignment(5) = 7
            Grid1.ColAlignment(6) = 7
           
            Grid1.TextMatrix(nFILA, 4) = Format((dblDiferenciaCaja), gFormat)
            Grid1.TextMatrix(nFILA, 5) = Format((dblCompensado), gFormat)
            Grid1.TextMatrix(nFILA, 6) = Format((dblDiferenciaReal), gFormat)
        
            Grid1.col = 7
            Select Case XEstado
                  Case -1
                     Grid1.CellBackColor = &HFF&       'rojo
                     Grid1.CellForeColor = &H80000005   'blanco
                     Grid1.TextMatrix(nFILA, 7) = "Pendiente"
                    
                  Case 0
                     Grid1.CellBackColor = &H80FFFF        'amarillo
                     Grid1.CellForeColor = &H0&            'negro
                     Grid1.TextMatrix(nFILA, 7) = "Pendiente"
                  Case 1
                     Grid1.CellBackColor = &H80FF80        ' verde
                     Grid1.CellForeColor = &H0&            ' negro
                      Grid1.TextMatrix(nFILA, 7) = "Cerrado"
                  Case 2
                     Grid1.CellBackColor = &HFF0000        ' azul
                     Grid1.CellForeColor = &H80000005      ' blanco
                    Grid1.TextMatrix(nFILA, 7) = "Impreso"
                  Case 3
                     Grid1.CellBackColor = &H0&          'negro
                     Grid1.CellForeColor = &H80000005    'blanco
                     Grid1.TextMatrix(nFILA, 7) = "Sin Datos"
             End Select
             nFILA = nFILA + 1
        End If
    End If
    BuscarOpcion.MoveNext
Wend
Grid1.Visible = True

 
Set BuscarOpcion.ActiveConnection = Nothing
BuscarOpcion.Close
Exit Sub

salir:
  
    Set BuscarOpcionCompensa.ActiveConnection = Nothing
    SystemMsg = "Problemas de comunicación con servidor, buscando información de perfiles"
    frmLogOraError.Show 1
    Exit Sub
End Sub

Private Sub SubBuscarOpcion2(ByVal Index As Integer)
Dim Diferencia, DiferenciaCaja, DiferenciaReal, xFecha, xlocal, Xterminal, XEstado, Xcierrey, Vcompensado
Dim BEfectivo, BChequeDia, BDolares, BEuros, Btarjeta, BTicker, Bcmr
Dim nFILA
Dim VLocal As String
Grid1.Visible = False

Call definegrid(Index)
Combo1.ListIndex = Combo2.ListIndex
VLocal = Combo2.Text
If VLocal = 0 Then
    VLocal = ""
End If
 sq = FuncStrPivote(VLocal)

On Error GoTo salir
Set BuscarOpcion = CreateObject("ADODB.Recordset")
With BuscarOpcion
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With
Call BuscarOpcion.Open(sq)
VlocalAnterior = 0
nFILA = 1

' EUROS = "304"   ' "233"  '
'DOLAR = "305"
While Not BuscarOpcion.EOF
      xFecha = BuscarOpcion.Fields(0).Value
      xlocal = BuscarOpcion.Fields(1).Value
      Xterminal = BuscarOpcion.Fields(2).Value
      If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
         XEstado = BuscarOpcion.Fields(4).Value
      Else
         XEstado = BuscarOpcion.Fields(3).Value
      End If
      
      Xcierrey = IIf(BuscarOpcion.Fields(3).Value = 0, "", BuscarOpcion.Fields(3).Value)
      X = FuncValorZoY(xFecha, xlocal, Xterminal, Xcierrey)
      BEfectivo = FuncBuscarRecEfectivo("EFE", xFecha, xlocal, Xterminal, Xcierrey)
      BChequeDia = FuncBuscarRecEfectivo("CHE", xFecha, xlocal, Xterminal, Xcierrey)
      BDolares = FuncBuscarRecModRec(DOLAR, xFecha, xlocal, Xterminal, Xcierrey)
     ' BDolares = FuncBuscarRecEfectivo("OTR", Xfecha, Xlocal, Xterminal, Xcierrey)
      
      BEuros = FuncBuscarRecModRec(EUROS, xFecha, xlocal, Xterminal, Xcierrey)
     ' BEuros = FuncBuscarRecEfectivo("EUR", Xfecha, Xlocal, Xterminal, Xcierrey)
     
      BChequeFecha = FuncBuscarRecCheFecha(xFecha, xlocal, Xterminal, Xcierrey, "")
      Btarjeta = FuncBuscarRecTarj("tarj", xFecha, xlocal, Xterminal, Xcierrey)
       If Flg_Pais$ = "PER" Or Flg_Pais$ = "SOPE" Or Flg_Pais$ = "SPOR" Or Flg_Pais$ = "MAPE" Or Flg_Pais$ = "MPAM" Or Flg_Pais$ = "FAOR" Or Flg_Pais$ = "HTPE" Then
         BTicker = FuncBuscarRecCheFecha(xFecha, xlocal, Xterminal, Xcierrey, "Cupones")
      Else
         
         BTicker = FuncBuscarRecTarj("ticket", xFecha, xlocal, Xterminal, Xcierrey)
      End If
      
      
      
      
      Bcmr = FuncBuscarRecTarj("CMR", xFecha, xlocal, Xterminal, Xcierrey)
      VPorcompensado = SumaConceptosPorCompensado(xFecha, xlocal, Xterminal, Xcierrey)
     
      DiferenciaCaja = ((BEfectivo - Zefectivo) + (BChequeDia - Zchequedia) + _
                        (BDolares - Zdolares) + (BEuros - Zeuros) + _
                        (Btarjeta - Ztarjeta) + (BTicker - Zticketpago) + _
                        (Bcmr - Ztarjetacmr) + (BChequeFecha - Zchequefecha))

      
      

      
      
      
      Diferencia = (Format(DiferenciaCaja, gFormat) - Format(VPorcompensado, gFormat))
              
     
      
       If Diferencia <> 0 Then
          Grid1.AddItem ""
          Grid1.TextMatrix(nFILA, 0) = Format(xFecha, VgFormatoFechaLectura)
          Grid1.TextMatrix(nFILA, 1) = xlocal
          Grid1.TextMatrix(nFILA, 2) = Xterminal
          Grid1.TextMatrix(nFILA, 3) = Xcierrey
          Grid1.row = nFILA
          Grid1.ColAlignment(4) = 7
          Grid1.ColAlignment(5) = 7
          Grid1.ColAlignment(6) = 7
         
          Grid1.TextMatrix(nFILA, 4) = Format((DiferenciaCaja), gFormat)
          Grid1.TextMatrix(nFILA, 5) = Format((VPorcompensado), gFormat)
          Grid1.TextMatrix(nFILA, 6) = Format((Diferencia), gFormat)
      
          Grid1.col = 7
          Select Case XEstado          'FuncEstadoLocal(Xfecha, Xlocal)
                Case -1
                   Grid1.CellBackColor = &HFF&       'rojo
                   Grid1.CellForeColor = &H80000005   'blanco
                   Grid1.TextMatrix(nFILA, 7) = "Pendiente"
                  
                Case 0
                   Grid1.CellBackColor = &H80FFFF         'amarillo
                   Grid1.CellForeColor = &H0&            'negro
                   Grid1.TextMatrix(nFILA, 7) = "Pendiente"
                Case 1
                   Grid1.CellBackColor = &H80FF80        ' verde
                   Grid1.CellForeColor = &H0&            ' negro
                    Grid1.TextMatrix(nFILA, 7) = "Cerrado"
                Case 2
                   Grid1.CellBackColor = &HFF0000         ' azul
                   Grid1.CellForeColor = &H80000005      ' blanco
                  Grid1.TextMatrix(nFILA, 7) = "Impreso"
                Case 3
                   Grid1.CellBackColor = &H0&          'negro
                   Grid1.CellForeColor = &H80000005    'blanco
                   Grid1.TextMatrix(nFILA, 7) = "Sin Datos"
                Case -2 'CK: 160531 Modificaciones F8 ARG
                   Grid1.CellBackColor = &H80FF&      'naranjo
                   Grid1.CellForeColor = &H80000005   'blanco
                   Grid1.TextMatrix(nFILA, 7) = "Pendiente"
           End Select
           nFILA = nFILA + 1
      End If
   BuscarOpcion.MoveNext
Wend
Grid1.Visible = True

 
Set BuscarOpcion.ActiveConnection = Nothing
BuscarOpcion.Close
Exit Sub

salir:
  
    Set BuscarOpcionCompensa.ActiveConnection = Nothing
    SystemMsg = "Problemas de comunicación con servidor, buscando información de perfiles"
    frmLogOraError.Show 1
    Exit Sub
End Sub

Private Sub SubBuscarOpcion2SOAR_SOUY(ByVal Index As Integer)
Dim Diferencia, DiferenciaCaja, DiferenciaReal, xFecha, xlocal, Xterminal, XEstado, Xcierrey, Vcompensado
Dim BEfectivo, BChequeDia, BDolares, BEuros, Btarjeta, BTicker, Bcmr
Dim nFILA
Dim VLocal As String
Grid1.Visible = False

Call definegrid(Index)
Combo1.ListIndex = Combo2.ListIndex
VLocal = Combo2.Text
If VLocal = 0 Then
    VLocal = ""
End If
 sq = FuncStrPivoteSOAR_SOUY(VLocal)

On Error GoTo salir
Set BuscarOpcion = CreateObject("ADODB.Recordset")
With BuscarOpcion
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With
Call BuscarOpcion.Open(sq)
VlocalAnterior = 0
nFILA = 1

' EUROS = "304"   ' "233"  '
'DOLAR = "305"
While Not BuscarOpcion.EOF
      xFecha = BuscarOpcion.Fields(0).Value
      xlocal = BuscarOpcion.Fields(1).Value
      Xterminal = BuscarOpcion.Fields(2).Value
      If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
         XEstado = BuscarOpcion.Fields(4).Value
      Else
         XEstado = BuscarOpcion.Fields(3).Value
      End If
      
      Xcierrey = IIf(BuscarOpcion.Fields(3).Value = 0, "", BuscarOpcion.Fields(3).Value)
      X = FuncValorZoY(xFecha, xlocal, Xterminal, Xcierrey)
      BEfectivo = FuncBuscarRecEfectivo("EFE", xFecha, xlocal, Xterminal, Xcierrey)
      BChequeDia = FuncBuscarRecEfectivo("CHE", xFecha, xlocal, Xterminal, Xcierrey)
      BDolares = FuncBuscarRecModRec(DOLAR, xFecha, xlocal, Xterminal, Xcierrey)
     ' BDolares = FuncBuscarRecEfectivo("OTR", Xfecha, Xlocal, Xterminal, Xcierrey)
      
      BEuros = FuncBuscarRecModRec(EUROS, xFecha, xlocal, Xterminal, Xcierrey)
     ' BEuros = FuncBuscarRecEfectivo("EUR", Xfecha, Xlocal, Xterminal, Xcierrey)
     
      BChequeFecha = FuncBuscarRecCheFecha(xFecha, xlocal, Xterminal, Xcierrey, "")
      Btarjeta = FuncBuscarRecTarj("tarj", xFecha, xlocal, Xterminal, Xcierrey)
       If Flg_Pais$ = "PER" Or Flg_Pais$ = "SOPE" Or Flg_Pais$ = "SPOR" Or Flg_Pais$ = "MAPE" Or Flg_Pais$ = "MPAM" Or Flg_Pais$ = "FAOR" Or Flg_Pais$ = "HTPE" Then
         BTicker = FuncBuscarRecCheFecha(xFecha, xlocal, Xterminal, Xcierrey, "Cupones")
      Else
         
         BTicker = FuncBuscarRecTarj("ticket", xFecha, xlocal, Xterminal, Xcierrey)
      End If
      
      
      
      
      Bcmr = FuncBuscarRecTarj("CMR", xFecha, xlocal, Xterminal, Xcierrey)
      VPorcompensado = SumaConceptosPorCompensado(xFecha, xlocal, Xterminal, Xcierrey)
     
      DiferenciaCaja = ((BEfectivo - Zefectivo) + (BChequeDia - Zchequedia) + _
                        (BDolares - Zdolares) + (BEuros - Zeuros) + _
                        (Btarjeta - Ztarjeta) + (BTicker - Zticketpago) + _
                        (Bcmr - Ztarjetacmr) + (BChequeFecha - Zchequefecha))

      
      

      
      
      
      Diferencia = (Format(DiferenciaCaja, gFormat) - Format(VPorcompensado, gFormat))
              
     
      
       If Diferencia <> 0 Then
          Grid1.AddItem ""
          Grid1.TextMatrix(nFILA, 0) = Format(xFecha, VgFormatoFechaLectura)
          Grid1.TextMatrix(nFILA, 1) = xlocal
          Grid1.TextMatrix(nFILA, 2) = Xterminal
          Grid1.TextMatrix(nFILA, 3) = Xcierrey
          Grid1.row = nFILA
          Grid1.ColAlignment(4) = 7
          Grid1.ColAlignment(5) = 7
          Grid1.ColAlignment(6) = 7
         
          Grid1.TextMatrix(nFILA, 4) = Format((DiferenciaCaja), gFormat)
          Grid1.TextMatrix(nFILA, 5) = Format((VPorcompensado), gFormat)
          Grid1.TextMatrix(nFILA, 6) = Format((Diferencia), gFormat)
      
          Grid1.col = 7
          Select Case XEstado          'FuncEstadoLocal(Xfecha, Xlocal)
                Case -1
                   Grid1.CellBackColor = &HFF&       'rojo
                   Grid1.CellForeColor = &H80000005   'blanco
                   Grid1.TextMatrix(nFILA, 7) = "Pendiente"
                  
                Case 0
                   Grid1.CellBackColor = &H80FFFF         'amarillo
                   Grid1.CellForeColor = &H0&            'negro
                   Grid1.TextMatrix(nFILA, 7) = "Pendiente"
                Case 1
                   Grid1.CellBackColor = &H80FF80        ' verde
                   Grid1.CellForeColor = &H0&            ' negro
                    Grid1.TextMatrix(nFILA, 7) = "Cerrado"
                Case 2
                   Grid1.CellBackColor = &HFF0000         ' azul
                   Grid1.CellForeColor = &H80000005      ' blanco
                  Grid1.TextMatrix(nFILA, 7) = "Impreso"
                Case 3
                   Grid1.CellBackColor = &H0&          'negro
                   Grid1.CellForeColor = &H80000005    'blanco
                   Grid1.TextMatrix(nFILA, 7) = "Sin Datos"
           End Select
           nFILA = nFILA + 1
      End If
   BuscarOpcion.MoveNext
Wend
Grid1.Visible = True

 
Set BuscarOpcion.ActiveConnection = Nothing
BuscarOpcion.Close
Exit Sub

salir:
  
    Set BuscarOpcionCompensa.ActiveConnection = Nothing
    SystemMsg = "Problemas de comunicación con servidor, buscando información de perfiles"
    frmLogOraError.Show 1
    Exit Sub
End Sub

Public Function FuncBuscarRecEfectivo(ByVal vtipo As String, ByVal vfecha As String, ByVal VLocal As String, ByVal vterminal As String, ByVal vcierrey As String) As Double
Dim sq As String

FuncBuscarRecEfectivo = 0
On Error GoTo salir
Set RecEfectivo = CreateObject("ADODB.Recordset")
With RecEfectivo
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With
'jlom-20112007 if  Flg_Pais$ = "CHI" Or Flg_Pais$ = "CMCL" Or Flg_Pais$ = "" Then
'jlom-20112007  sq = " select   (nvl((p.prv_montosobre),0) +nvl((p.prv_montodif),0))   as efectivo   "
'jlom-20112007  Else
 sq = " select   (nvl(sum(p.prv_montosobre),0) +nvl(sum(p.prv_montodif),0))   as efectivo  "
'jlom-20112007  End If
 sq = sq & "   " & _
 " From   vta_" & Flg_Pais$ & "prd p " & _
 " where p.prv_fechavta = to_date('" & Format(vfecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')" & _
 "   and   p.prv_local =    " & VLocal & _
 "   and  (p.prv_tiporec = 'F8' or p.prv_tiporec = 'DOL') " & _
 "   and  ( p.prv_tiposobre ='" & vtipo & "')"

If vterminal <> "" And vterminal <> "0" Then
     sq = sq & "   and   p.prv_terminal =   " & vterminal
End If
If vcierrey <> "0" And vcierrey <> "" Then
      sq = sq & " and    p.prv_cierrey  =  " & vcierrey
End If

'jlom-20112007  if  Flg_Pais$ = "CHI" Or Flg_Pais$ = "CMCL" Or Flg_Pais$ = "" Then
'jlom-20112007   sq = sq & "  group by   p.prv_tiposobre, p.prv_tiporec, p.prv_sobre, p.prv_montosobre, p.prv_montodif, p.prv_totdocs, p.prv_numdifdoc  "
'jlom-20112007  End If
     
 
Call RecEfectivo.Open(sq)

 
FuncBuscarRecEfectivo = 0
While Not RecEfectivo.EOF
   FuncBuscarRecEfectivo = FuncBuscarRecEfectivo + RecEfectivo.Fields(0)
   RecEfectivo.MoveNext
Wend
 

 
Set RecEfectivo.ActiveConnection = Nothing
RecEfectivo.Close
Exit Function

salir:
    
    Set RecEfectivo.ActiveConnection = Nothing
    FuncBuscarRecEfectivo = 0
    SystemMsg = "Problemas de comunicación con servidor,Información de prosegur "
    frmLogOraError.Show 1
    Exit Function
End Function

Public Function FuncBuscarRecModRec(ByVal vtipo As String, ByVal vfecha As String, ByVal VLocal As String, ByVal vterminal As String, ByVal vcierrey As String) As Double

FuncBuscarRecModRec = 0
On Error GoTo salir
Set RecModRec = CreateObject("ADODB.Recordset")
With RecModRec
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With

Rem RMOYAG 20170208 Problemas con el tratamiento de dolara F8 SOUY
Rem Problema: Esta considerando solo sobres de racaudacion tipo dolar y hay recaudacion dolar vendedor, Comprador, etc
Rem Respaldo
 '"   and  ( p.id_mdareg = " & vTipo & " )"
 
    sq = "select "
    sq = sq & " nvl( sum(p.mex_monto),0)   as valorrec "
    sq = sq & " From   vta_" & Flg_Pais$ & "recmex p "
    sq = sq & " where   p.mex_fecha = to_date('" & Format(vfecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')"
    sq = sq & " and   p.mex_local =    " & VLocal
    If vtipo = "305" And (Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY") Then
        sq = sq & " and   p.id_mdareg in(select vta_xglosa from vta_" & Flg_Pais$ & "param where vta_ccodtipo = 10060 and vta_ccodigo <> 0) "
    Else
        sq = sq & " and  p.id_mdareg = " & vtipo
    End If


    If vterminal <> "" And vterminal <> "" Then
        sq = sq & "  and   p.mex_terminal =   " & vterminal
    End If
    If vcierrey <> "" And vcierrey <> "0" Then
        sq = sq & " and    p.mex_cierrey  =  " & vcierrey
    End If

   
     
 
Call RecModRec.Open(sq)

 
FuncBuscarRecModRec = 0
While Not RecModRec.EOF
   FuncBuscarRecModRec = FuncBuscarRecModRec + RecModRec.Fields(0)
   RecModRec.MoveNext
Wend
 

 
Set RecModRec.ActiveConnection = Nothing
RecModRec.Close
Exit Function

salir:
    
    Set RecModRec.ActiveConnection = Nothing
    FuncBuscarRecModRec = 0
    SystemMsg = "Problemas de comunicación con servidor,Información de prosegur "
    frmLogOraError.Show 1
    Exit Function
End Function
Public Function FuncBuscarNumRecModRec(ByVal vtipo As String, ByVal vfecha As String, ByVal VLocal As String, ByVal vterminal As String, ByVal vcierrey As String, ByVal vtipo_valor As Integer) As Double

FuncBuscarNumRecModRec = 0
On Error GoTo salir
Set RecModRec = CreateObject("ADODB.Recordset")
With RecModRec
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With

 sq = "" & _
 "  select  nvl(Trunc( sum(p.mex_valor)/ count(*),2 ),0)   as valorrec ,nvl(sum(nvl(p.mex_cantidad,0)),0) ,nvl(sum(nvl(p.mex_monto,0)),0) " & _
 " From   vta_" & Flg_Pais$ & "recmex p " & _
 " where   p.mex_fecha = to_date('" & Format(vfecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')" & _
 "   and   p.mex_local =    " & VLocal & _
 "   and  ( p.id_mdareg = " & vtipo & " )"


If vterminal <> "" And vterminal <> "" Then
   sq = sq & "   and   p.mex_terminal =   " & vterminal
End If
If vcierrey <> "" And vcierrey <> "0" Then
      sq = sq & " and    p.mex_cierrey  =  " & vcierrey
End If

   
     
 
Call RecModRec.Open(sq)

 
FuncBuscarNumRecModRec = 0
While Not RecModRec.EOF
 
    FuncBuscarNumRecModRec = FuncBuscarNumRecModRec + RecModRec.Fields(vtipo_valor)
 
   RecModRec.MoveNext
Wend
 

 
Set RecModRec.ActiveConnection = Nothing
RecModRec.Close
Exit Function

salir:
    
    Set RecModRec.ActiveConnection = Nothing
    FuncBuscarNumRecModRec = 0
    SystemMsg = "Problemas de comunicación con servidor,Información de prosegur "
    frmLogOraError.Show 1
    Exit Function
End Function

Public Function FuncBuscarRecCheFecha(ByVal vfecha As String, ByVal VLocal As String, ByVal vterminal As String, ByVal vcierrey As String, ByVal strTipo As String) As Double
Dim nombreCampo  As String

If strTipo = "Cupones" Then
   nombreCampo = "tes_mcupones"
Else
   nombreCampo = "tes_chefecha"
End If

FuncBuscarRecCheFecha = 0
On Error GoTo salir
Set RecCheFecha = CreateObject("ADODB.Recordset")
With RecCheFecha
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With

 sq = "" & _
 "  select  nvl( sum(p." & nombreCampo & " ),0)   as valorrec " & _
 " From   vta_" & Flg_Pais$ & "tesor p " & _
 " where   p.tes_fecha = to_date('" & Format(vfecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')" & _
 "   and   p.tes_local =    " & VLocal
 

If vterminal <> "" And vterminal <> "0" Then
 sq = sq & "   and   p.tes_terminal =   " & vterminal
End If

If vcierrey <> "" And vcierrey <> "0" Then
      sq = sq & " and    p.tes_cierrey  =  " & vcierrey
End If

   
     
 
Call RecCheFecha.Open(sq)

 
FuncBuscarRecCheFecha = 0
While Not RecCheFecha.EOF
   FuncBuscarRecCheFecha = FuncBuscarRecCheFecha + RecCheFecha.Fields(0)
   RecCheFecha.MoveNext
Wend
 

 
Set RecCheFecha.ActiveConnection = Nothing
RecCheFecha.Close
Exit Function

salir:
    
    Set RecCheFecha.ActiveConnection = Nothing
    FuncBuscarRecCheFecha = 0
    SystemMsg = "Problemas de comunicación con servidor,Información de prosegur "
    frmLogOraError.Show 1
    Exit Function
End Function

Public Function FuncBuscarRecTarj(ByVal vtipo As String, ByVal vfecha As String, ByVal VLocal As String, ByVal vterminal As String, ByVal vcierrey As String) As Double

FuncBuscarRecTarj = 0
On Error GoTo salir
Set RecTarj = CreateObject("ADODB.Recordset")
With RecTarj
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With

 sq = "" & _
 "  select  nvl( sum(p.vta_monto_inf),0)   as valorrec " & _
 " From   vta_" & Flg_Pais$ & "tarj p " & _
 " where   p.vta_fecha = to_date('" & Format(vfecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')" & _
 "   and   p.vta_local =    " & VLocal

If vterminal <> "" And vterminal <> "0" Then
    sq = sq & "   and   p.vta_terminal =   " & vterminal
End If
If vcierrey <> "" And vcierrey <> "0" Then
      sq = sq & " and    p.vta_cierrey  =  " & vcierrey
End If

If Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Then
    Select Case UCase(vtipo)
       Case CTICKET
           cod_tar_aux = " ( 3005,3006,3007 )"
       Case CCMR
            If Flg_Pais$ = "ARG" Then
                cod_tar_aux = " 4200"
            Else
                cod_tar_aux = " (4100 ,4200 )"
           End If
    End Select
    
    Select Case vtipo
        Case "tarj"
             sq = sq & "  and (p.vta_cod_tarj  >= 2000 and p.vta_cod_tarj  <= 2999 )  "
        Case "CMR"
             sq = sq & "  and (p.vta_cod_tarj  >= 4000 and p.vta_cod_tarj  <= 4099 )  "
             sq = sq & " and   p.vta_cod_tarj not in  " & cod_tar_aux
        Case "ticket"
             sq = sq & "  and (p.vta_cod_tarj    >= 3000 and p.vta_cod_tarj   <= 3999 )  "
             sq = sq & " and   p.vta_cod_tarj not in  " & cod_tar_aux
    End Select
ElseIf Flg_Pais$ = "PER" Or Flg_Pais$ = "SOPE" Or Flg_Pais$ = "SPOR" Or Flg_Pais$ = "MAPE" Or Flg_Pais$ = "MPAM" Or Flg_Pais$ = "FAOR" Or Flg_Pais$ = "HTPE" Then
     Select Case vtipo
          Case "tarj"
          sq = sq & "  and p.vta_cod_tarj  <= 1000    "
 
        Case Else
           sq = sq & "  and p.vta_cod_tarj = 9999999 "
     End Select
Else
   Select Case vtipo
     Case "CMR", "ticket"
          sq = sq & "  and p.vta_cod_tarj= 9999999 "
   End Select
End If

 
 If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY") And (vtipo = "CMR" Or vtipo = "ticket") Then
 
     sq = sq & " Union all "
     sq = sq & " select   "
     sq = sq & " decode( sum(p.det_monto),null,0,sum(p.det_monto)) "
     sq = sq & " from vta_" & Flg_Pais$ & "detpago p "
     sq = sq & " Where  p.det_fecha = to_date('" & Format(vfecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')"
     sq = sq & "   and  p.det_local  =  " & VLocal
    
     If vterminal <> "" And vterminal <> "0" Then
       sq = sq & "   and   p.det_terminal = " & vterminal
     End If
     If vcierrey <> "" And vcierrey <> "0" Then
         sq = sq & " and    p.det_cierrey  =  " & vcierrey
     End If
     sq = sq & "   and  p.det_cod_tarj  in  " & cod_tar_aux
End If
 
 
 

 
 
   
     
 
Call RecTarj.Open(sq)

 
FuncBuscarRecTarj = 0
While Not RecTarj.EOF
   FuncBuscarRecTarj = FuncBuscarRecTarj + RecTarj.Fields(0)
   RecTarj.MoveNext
Wend
 

 
Set RecTarj.ActiveConnection = Nothing
RecTarj.Close
Exit Function

salir:
    
    Set RecTarj.ActiveConnection = Nothing
    FuncBuscarRecTarj = 0
    SystemMsg = "Problemas de comunicación con servidor,Información de prosegur "
    frmLogOraError.Show 1
    Exit Function
End Function


Private Function FuncLeeTarjeta(vl_FECHA As String, vl_LOCAL As String, vl_TERMINAL As String, vl_tajeta As String) As Double
Dim totalret As Double
Set Consultarjeta = CreateObject("ADODB.Recordset")
With Consultarjeta
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With
On Error GoTo oraerror
FuncLeeTarjeta = 0
If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE" Or Flg_Pais$ = "PER" Or Flg_Pais$ = "SOPE" Or Flg_Pais$ = "SPOR" Or Flg_Pais$ = "MAPE" Or Flg_Pais$ = "MPAM" Or Flg_Pais$ = "FAOR") Then
    Select Case vl_tajeta
    Case CTARJ
     If Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "SFCL" Then
        Vl_min = 2000
        Vl_max = 2999
     Else
         Vl_min = 0
         Vl_max = 999
     End If
   Case "ABONO"
        Vl_min = 6000
        Vl_max = 6002

   Case "VALES"
        Vl_min = 4999
        Vl_max = 5000
    Case CTICKET
        Vl_min = 3000
        Vl_max = 3999
        cod_tar_aux = " ( 3005,3006,3007 )"
    Case CCMR
        Vl_min = 4000
        Vl_max = 4999
        cod_tar_aux = " (4100 ,4200 )"
    End Select
     
End If

 sq = " Select decode(sum(t.vta_monto_inf),null,0,sum(t.vta_monto_inf))   " & _
 "      From vta_" & Flg_Pais$ & "tarj t " & _
 "      where  vta_fecha = to_date('" & Format(vl_FECHA, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "') " & _
 "      and t.vta_local = " & vl_LOCAL & " " & _
 "      and t.vta_terminal = " & vl_TERMINAL
 If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO") And (vl_tajeta = CCMR Or vl_tajeta = CTICKET) Then
            sq = sq & "   and   t.vta_cod_tarj not in  " & cod_tar_aux
 End If
 If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE" Or Flg_Pais$ = "FAOR" Or Flg_Pais$ = "PER" Or Flg_Pais$ = "SOPE" Or Flg_Pais$ = "SPOR" Or Flg_Pais$ = "MAPE" Or Flg_Pais$ = "MPAM") Then
    sq = sq + "   and ((t.vta_cod_tarj >=" & Vl_min & ") and (t.vta_cod_tarj <= " & Vl_max & ") )"
 End If
 
 
If ((Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO")) And (vl_tajeta = CCMR Or vl_tajeta = CTICKET) Then
 
  sq = sq & " Union all "
  sq = sq & " select   "
  sq = sq & " decode( sum(p.det_monto),null,0,sum(p.det_monto)) "
  sq = sq & " from vta_" & Flg_Pais$ & "detpago p "
  sq = sq & " Where  p.det_fecha  = to_date('" & Format(vl_FECHA, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "') "
  sq = sq & "   and  p.det_local  = " & vl_LOCAL & " "
  sq = sq & "   and  p.det_terminal  =  " & vl_TERMINAL
  sq = sq & "   and   p.det_cod_tarj  in  " & cod_tar_aux
  
End If
 
  Call Consultarjeta.Open(sq)
  Monto = 0
  While Not Consultarjeta.EOF
     Monto = Monto + CDbl(Consultarjeta.Fields(0).Value)
     Consultarjeta.MoveNext
  Wend
  FuncLeeTarjeta = CDbl(Change_Char(Monto, ".", ","))
 
 
 Set Consultarjeta.ActiveConnection = Nothing
 Exit Function
 
oraerror:
Set Consultarjeta.ActiveConnection = Nothing
   SystemMsg = "Error al leer Sobres Prosegur para este terminal"
   frmLogOraError.Show 1
   Exit Function
End Function

Private Function FuncStrPivote(ByVal VLocal As String) As String
Dim sq As String
FuncStrPivote = ""

If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
    TipoReg = "y"
    TipoCondi = "Y"
Else
 
     TipoReg = ""
     TipoCondi = "F8"
End If
    
    
sq = " Select distinct  t.ter_fecha " & _
   "  ,t.ter_local " & _
   "  ,t.ter_terminal "
   
If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
      sq = sq & " ,t.ter_cierrey  "
Else
       sq = sq & " ,0  as ter_cierrey "
End If

sq = sq & " , t.ter_estado  "

sq = sq & " From   vta_" & Flg_Pais$ & "libvta l, vta_" & Flg_Pais$ & "zzz r  ,vta_" & Flg_Pais$ & "termstat" & TipoReg & " t  " & _
   " where  l.vta_tiporeg     = '" & TipoCondi & "' " & _
   " and  ( t.ter_fecha >=  to_date('" & Format(DTPicker1.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')" & _
   " and    t.ter_fecha <=  to_date('" & Format(DTPicker2.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')  ) " & _
   " and    l.vta_estado      = 'A'     " & _
   " and    l.vta_techkey     = r.rec_techkey  " & _
   " and    l.vta_fecha_venta = t.ter_fecha " & _
   " and    l.vta_local       = t.ter_local " & _
   " and    l.vta_terminal    = t.ter_terminal "
If (Flg_Pais$ = "" Or Flg_Pais$ = "CHI" Or Flg_Pais$ = "CMCL" Or Flg_Pais$ = "KFCL") Then
    sq = sq & " and    l.vta_local    not in (36,37) "
End If

'If Flg_Pais$ = "SFCL" And Trim(Combo3.Text) <> "0" Then
'CK: 160531 Modificaciones F8 ARG
If ((Flg_Pais$ = "SFCL" Or Flg_Pais$ = "ARG") And Trim(Combo3.Text) <> "0") Then
    sq = sq & " and    l.vta_terminal  = " & Trim(Combo3.Text)
End If
'---INI---- xintec-nruz 22-10-2026 FCDVT-56: FACO filtra por Terminal cuando es distinto de 0 (opcion Terminal) ----
If Flg_Pais$ = "FACO" And VF_NumInforme = 0 And Val(Trim(Combo3.Text)) <> 0 Then
    sq = sq & " and    l.vta_terminal  = " & Val(Trim(Combo3.Text))
End If
'---FIN---- xintec-nruz 22-10-2026 ----

If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
   sq = sq & " and    l.vta_secuencia   = t.ter_cierrey "
End If
   
   
   If VLocal <> "" Then
       'sq = sq & " and  t.ter_local  = " & VLocal
       sq = sq & " and  l.vta_local  = " & VLocal
   End If


If Flg_Pais$ = "SFCL" Or Flg_Pais$ = "HTPE" Then
   sq = sq & " Union"
   sq = sq & " Select distinct t.ter_fecha,"
   sq = sq & " t.ter_local,"
   sq = sq & " t.ter_terminal,"
   sq = sq & " 0 as ter_cierrey,"
   sq = sq & " t.ter_estado"
   sq = sq & " From vta_" & Flg_Pais$ & "libvta l,vta_" & Flg_Pais$ & "termstat t"
   sq = sq & " where l.vta_tiporeg = 'F8'"
   sq = sq & " and (t.ter_fecha >= to_date('" & Format(DTPicker1.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')"
   sq = sq & " and t.ter_fecha <= to_date('" & Format(DTPicker2.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "'))"
   sq = sq & " and l.vta_estado = 'A'"
   sq = sq & " and l.vta_fecha_venta = t.ter_fecha"
   sq = sq & " and l.vta_local = t.ter_local"
   sq = sq & " and l.vta_terminal = t.ter_terminal"
   If CDbl(Combo3.Text) <> 0 Then
        sq = sq & " and l.vta_terminal = " & Combo3.Text
   End If
   sq = sq & " and t.ter_local = " & VLocal
   sq = sq & " Union"
   sq = sq & " select"
   sq = sq & " t.ter_fecha"
   sq = sq & " , t.ter_local"
   sq = sq & " ,t.ter_terminal"
   sq = sq & " ,0 as ter_cierrey"
   sq = sq & " ,t.ter_estado"
   sq = sq & " from vta_" & Flg_Pais$ & "termstat t"
   sq = sq & " where not exists(select v.vta_terminal from vta_" & Flg_Pais$ & "libvta v where v.vta_fecha_venta = t.ter_fecha"
   sq = sq & "                         and v.vta_local = t.ter_local"
   sq = sq & "                         and v.vta_terminal = t.ter_terminal)"
   sq = sq & " and t.ter_local = " & VLocal
   sq = sq & " and (t.ter_fecha >= to_date('" & Format(DTPicker1.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')"
   sq = sq & " and t.ter_fecha <= to_date('" & Format(DTPicker2.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "'))"
   If CDbl(Combo3.Text) <> 0 Then
        sq = sq & " and t.ter_terminal = " & Combo3.Text
   End If
End If

If Flg_Pais$ = "ARG" Then
   sq = sq & " Union"
   sq = sq & " select distinct"
   sq = sq & " t.ter_fecha"
   sq = sq & " , t.ter_local"
   sq = sq & " ,t.ter_terminal"
   sq = sq & " ,0 as ter_cierrey"
   sq = sq & " ,t.ter_estado"
   sq = sq & " from vta_argtermstat t, vta_argterminales s"
'   sq = sq & " inner join vta_arglibvta l"
'   sq = sq & " on l.vta_fecha_venta = t.ter_fecha"
'   sq = sq & " and l.vta_local = t.ter_local"
'   sq = sq & " and l.vta_terminal = t.ter_terminal"
'   sq = sq & " inner join vta_argzzz r on"
'   sq = sq & " l.vta_techkey = r.rec_techkey"
   sq = sq & " where /*exists(select v.vta_terminal from vta_arglibvta v where v.vta_fecha_venta = t.ter_fecha"
   sq = sq & "                         and v.vta_local = t.ter_local"
   sq = sq & "                         and v.vta_terminal = t.ter_terminal"
   sq = sq & "                         and v.vta_tiporeg = 'F8'"
   sq = sq & "                         and v.vta_estado = 'A')"
'   sq = sq & " and l.vta_tiporeg = 'F8'"
   sq = sq & " and*/ t.ter_local = " & VLocal
   sq = sq & " and t.ter_local = s.ter_local"
   sq = sq & " and t.ter_terminal = s.ter_terminal"
   sq = sq & " and (s.ter_fechabaja >= to_date('" & Format(DTPicker1.Value, VgFormatoFechaWhere) & "', '" & VgFormatoFechaWhere & "') or s.ter_fechabaja is null)"
   sq = sq & " and (t.ter_fecha >= to_date('" & Format(DTPicker1.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')"
   sq = sq & " and t.ter_fecha <= to_date('" & Format(DTPicker2.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "'))"
   If CDbl(Combo3.Text) <> 0 Then
        sq = sq & " and t.ter_terminal = " & Combo3.Text
   End If
End If

'---INI---- xintec-nruz 22-10-2026 FCDVT-56: FACO muestra los terminales vigentes sin movimiento (Z sin libro de ventas Y), como Chile ----
'Solo informe Terminal (VF_NumInforme = 0) y con un local elegido (no 0-TODOS). Cerrar Terminal los cierra con CierraTerminal (Z).
If Flg_Pais$ = "FACO" And VLocal <> "" And VF_NumInforme = 0 Then
   sq = sq & " Union"
   sq = sq & " select t.ter_fecha, t.ter_local, t.ter_terminal, 0 as ter_cierrey, t.ter_estado"
   sq = sq & " from vta_" & Flg_Pais$ & "termstat t, vta_" & Flg_Pais$ & "terminales s"
   sq = sq & " where t.ter_local = " & VLocal
   sq = sq & " and s.ter_local = t.ter_local and s.ter_terminal = t.ter_terminal"
   sq = sq & " and (s.ter_fechabaja is null or s.ter_fechabaja >= t.ter_fecha)"
   sq = sq & " and (t.ter_fecha >= to_date('" & Format(DTPicker1.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')"
   sq = sq & " and t.ter_fecha <= to_date('" & Format(DTPicker2.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "'))"
   sq = sq & " and not exists (select 1 from vta_" & Flg_Pais$ & "libvta v"
   sq = sq & "                  where v.vta_tiporeg = 'Y' and v.vta_estado = 'A'"
   sq = sq & "                    and v.vta_fecha_venta = t.ter_fecha"
   sq = sq & "                    and v.vta_local = t.ter_local"
   sq = sq & "                    and v.vta_terminal = t.ter_terminal)"
   If Val(Trim(Combo3.Text)) <> 0 Then
      sq = sq & " and t.ter_terminal = " & Val(Trim(Combo3.Text))
   End If
End If
'---FIN---- xintec-nruz 22-10-2026 ----

sq = sq & "  Order by 1,2,3 "
sq = sq & "  "

 

FuncStrPivote = sq
















End Function
Private Function FuncStrPivote1(ByVal VLocal As String) As String
Dim sq As String
FuncStrPivote1 = ""

If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
    TipoReg = "y"
    TipoCondi = "Y"
Else
    TipoReg = ""
     TipoCondi = "F8"
End If
    
    
sq = " Select /*+ ordered use_nl(l  r  t)*/ distinct t.ter_fecha " & _
     "       ,t.ter_local " & _
     "       ,sum(t.ter_estado)  " & _
     "       ,count(*) "
   



sq = sq & " From   vta_" & Flg_Pais$ & "libvta l, vta_" & Flg_Pais$ & "zzz r  ,vta_" & Flg_Pais$ & "termstat" & TipoReg & " t  " & _
   " where  l.vta_tiporeg     = '" & TipoCondi & "' " & _
   " and  ( t.ter_fecha >=  to_date('" & Format(DTPicker1.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')" & _
   " and    t.ter_fecha <=  to_date('" & Format(DTPicker2.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')  ) " & _
   " and    l.vta_estado      = 'A'     " & _
   " and    l.vta_techkey     = r.rec_techkey  " & _
   " and    l.vta_fecha_venta = t.ter_fecha " & _
   " and    l.vta_local       = t.ter_local " & _
   " and    l.vta_terminal    = t.ter_terminal "
   
   If (Flg_Pais$ = "" Or Flg_Pais$ = "CHI" Or Flg_Pais$ = "CMCL" Or Flg_Pais$ = "KFCL") Then
    sq = sq & " and    l.vta_local    not in (36,37) "
     End If
   
If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
   sq = sq & " and    l.vta_secuencia   = t.ter_cierrey "
End If
   

sq = sq & "  Group by t.ter_fecha " & _
     "       ,t.ter_local "
sq = sq & "  Order    by t.ter_fecha " & _
     "       ,t.ter_local "

 
FuncStrPivote1 = sq
 
End Function

Private Function FuncStrPivoteSOAR_SOUY(ByVal VLocal As String) As String
Dim sq As String
FuncStrPivoteSOAR_SOUY = ""

If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
    TipoReg = "y"
    TipoCondi = "Y"
Else
 
     TipoReg = ""
     TipoCondi = "F8"
End If
    
    
sq = " Select distinct  t.ter_fecha " & _
   "  ,t.ter_local " & _
   "  ,t.ter_terminal "
   
'If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
      sq = sq & " ,t.ter_cierrey  "
Else
      sq = sq & " ,0  as ter_cierrey "
End If

sq = sq & " , t.ter_estado  "

If Flg_Pais$ = "" Or Flg_Pais$ = "CHI" Then
   sq = sq & " , decode (t.ter_estado,1,to_char(t.ter_fechacierre,'dd/mm/yyyy hh24:mi'),' ') ter_fechacierre " '----Xintec sep 2025----
End If
'xintec NR 11-03-2019
If (Flg_Pais$ = "MAPE" Or Flg_Pais$ = "MPAM" Or Flg_Pais$ = "SPOR") Then
sq = sq & " From   vta_" & Flg_Pais$ & "libvta l, vta_" & Flg_Pais$ & "zzz r  ,vta_" & Flg_Pais$ & "termstat" & TipoReg & " t, vta_" & Flg_Pais$ & "relvendedor ta " & _
   " where  l.vta_tiporeg     = '" & TipoCondi & "' " & _
   " and    ta.vta_local  = '" & VLocal & "' " & _
   " and   (ta.ter_fechabaja >= to_date('" & Format(FormVariable.DTPicker1.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "') or ta.ter_fechabaja is null  )" & _
   " and   (t.ter_fecha >=  to_date('" & Format(DTPicker1.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')" & _
   " and    t.ter_fecha <=  to_date('" & Format(DTPicker2.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')  ) " & _
   " and    l.vta_estado      = 'A'     " & _
   " and    t.ter_terminal    = ta.vta_cod  " & _
   " and    l.vta_techkey     = r.rec_techkey  " & _
   " and    l.vta_fecha_venta = t.ter_fecha " & _
   " and    l.vta_local       = t.ter_local " & _
   " and    l.vta_terminal    = t.ter_terminal "

Else

sq = sq & " From   vta_" & Flg_Pais$ & "libvta l, vta_" & Flg_Pais$ & "zzz r  ,vta_" & Flg_Pais$ & "termstat" & TipoReg & " t, vta_" & Flg_Pais$ & "terminales ta " & _
   " where  l.vta_tiporeg     = '" & TipoCondi & "' " & _
   " and    ta.ter_local  = '" & VLocal & "' " & _
   " and   (ta.ter_fechabaja >= to_date('" & Format(FormVariable.DTPicker1.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "') or ta.ter_fechabaja is null  )" & _
   " and   (t.ter_fecha >=  to_date('" & Format(DTPicker1.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')" & _
   " and    t.ter_fecha <=  to_date('" & Format(DTPicker2.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')  ) " & _
   " and    l.vta_estado      = 'A'     " & _
   " and    t.ter_terminal    = ta.ter_terminal  " & _
   " and    l.vta_techkey     = r.rec_techkey  " & _
   " and    l.vta_fecha_venta = t.ter_fecha " & _
   " and    l.vta_local       = t.ter_local " & _
   " and    l.vta_terminal    = t.ter_terminal "
End If
   
If (Flg_Pais$ = "" Or Flg_Pais$ = "CHI" Or Flg_Pais$ = "CMCL" Or Flg_Pais$ = "KFCL") Then
    sq = sq & " and    l.vta_local    not in (36,37) "
End If

'If Flg_Pais$ = "SFCL" And Trim(Combo3.Text) <> "0" Then
If (Flg_Pais$ = "SFCL" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "" Or Flg_Pais$ = "CHI") And Trim(Combo3.Text) <> "0" Then 'Se agrega terminal(vendedor) para SOAR
    sq = sq & " and    l.vta_terminal  = " & Combo3.Text
End If

'If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
   sq = sq & " and    l.vta_secuencia   = t.ter_cierrey "
End If
   
   
   If VLocal <> "" Then
       sq = sq & " and  t.ter_local  = " & VLocal
   End If
   
sq = sq & " Union"
sq = sq & "  Select distinct  t.ter_fecha " & _
   "   ,t.ter_local " & _
   "   ,t.ter_terminal " & _
   "   ,0  as ter_cierrey " & _
   "   , t.ter_estado "
   
 If Flg_Pais$ = "" Or Flg_Pais$ = "CHI" Then
    sq = sq & " , decode (t.ter_estado,1,to_char(t.ter_fechacierre,'dd/mm/yyyy hh24:mi'),' ') ter_fechacierre " '----Xintec sep 2025----
 End If
'xintec NR 11-03-2019
If (Flg_Pais$ = "MAPE" Or Flg_Pais$ = "MPAM" Or Flg_Pais$ = "SPOR") Then
sq = sq & "  From  vta_" & Flg_Pais$ & "termstat" & TipoReg & " t, vta_" & Flg_Pais$ & "relvendedor ta " & _
   "    where ta.vta_local      = '" & VLocal & "' " & _
   " and  (ta.ter_fechabaja >= to_date('" & Format(FormVariable.DTPicker1.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "') or ta.ter_fechabaja is null  ) " & _
   " and  (t.ter_fecha >=  to_date('" & Format(DTPicker1.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "') " & _
   " and  t.ter_fecha <=  to_date('" & Format(DTPicker2.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')  ) " & _
   " and  t.ter_terminal    = ta.vta_cod " & _
   " and  t.ter_local    = ta.vta_local " & _
   " and  t.ter_local      = '" & VLocal & "' " & _
   " and  t.ter_terminal  not IN(SELECT l.vta_terminal FROM vta_" & Flg_Pais$ & "libvta l WHERE l.vta_tiporeg = '" & TipoCondi & "' and l.vta_estado = 'A' and (l.vta_fecha_venta >=  to_date('" & Format(DTPicker1.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "') and l.vta_fecha_venta <=  to_date('" & Format(DTPicker2.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "'))  AND l.vta_local = '" & VLocal & "')"

Else
'sq = sq & "  From  vta_" & Flg_Pais$ & "termstat" & TipoReg & " t, vta_" & Flg_Pais$ & "terminales ta " & _
'   "    where ta.ter_local      = '" & VLocal & "' " & _
'   " and  (ta.ter_fechabaja >= to_date('" & Format(FormVariable.DTPicker1.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "') or ta.ter_fechabaja is null  ) " & _
'   " and  (t.ter_fecha >=  to_date('" & Format(DTPicker1.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "') " & _
'   " and  t.ter_fecha <=  to_date('" & Format(DTPicker2.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')  ) " & _
'   " and  t.ter_terminal    = ta.ter_terminal " & _
'   " and  t.ter_local    = ta.ter_local " & _
'   " and  t.ter_local      = '" & VLocal & "' " & _
'   " and  t.ter_terminal  not IN(SELECT l.vta_terminal FROM vta_" & Flg_Pais$ & "libvta l WHERE l.vta_tiporeg = '" & TipoCondi & "' and l.vta_estado = 'A' and (l.vta_fecha_venta >=  to_date('" & Format(DTPicker1.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "') and l.vta_fecha_venta <=  to_date('" & Format(DTPicker2.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "'))  AND l.vta_local = '" & VLocal & "')"
sq = sq & "FROM vta_" & Flg_Pais$ & "termstat t " & _
          "JOIN vta_" & Flg_Pais$ & "terminales ta " & _
          "  ON ta.ter_terminal = t.ter_terminal " & _
          " AND ta.ter_local = t.ter_local " & _
          "LEFT JOIN vta_libvta l " & _
          "  ON l.vta_terminal = t.ter_terminal " & _
          " AND l.vta_local = t.ter_local " & _
          " AND TRUNC(l.vta_fecha_venta) = TRUNC(t.ter_fecha) " & _
          " AND l.vta_tiporeg = 'F8' " & _
          " AND l.vta_estado = 'A' " & _
          " AND l.vta_local NOT IN (36, 37) " & _
          "LEFT JOIN vta_zzz r ON l.vta_techkey = r.rec_techkey " & _
          "WHERE t.ter_local = " & VLocal & " " & _
          "AND ( t.ter_fecha >= TO_DATE('" & Format(DTPicker1.Value, "yyyymmdd") & "', 'yyyymmdd') " & _
          "AND   t.ter_fecha <= TO_DATE('" & Format(DTPicker2.Value, "yyyymmdd") & "', 'yyyymmdd') ) "

    
End If
If (Flg_Pais$ = "SFCL" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "" Or Flg_Pais$ = "CHI") And Trim(Combo3.Text) <> "0" Then 'Se agrega terminal(vendedor) para SOAR
    sq = sq & " and    t.ter_terminal  = " & Combo3.Text
End If



If Flg_Pais$ = "SFCL" Then
   sq = sq & " Union"
   sq = sq & " Select distinct t.ter_fecha,"
   sq = sq & " t.ter_local,"
   sq = sq & " t.ter_terminal,"
   sq = sq & " 0 as ter_cierrey,"
   sq = sq & " t.ter_estado"
   sq = sq & " From vta_SFCLlibvta l,vta_sfcltermstat t"
   sq = sq & " where l.vta_tiporeg = 'F8'"
   sq = sq & " and (t.ter_fecha >= to_date('" & Format(DTPicker1.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')"
   sq = sq & " and t.ter_fecha <= to_date('" & Format(DTPicker2.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "'))"
   sq = sq & " and l.vta_estado = 'A'"
   sq = sq & " and l.vta_fecha_venta = t.ter_fecha"
   sq = sq & " and l.vta_local = t.ter_local"
   sq = sq & " and l.vta_terminal = t.ter_terminal"
   If CDbl(Combo3.Text) <> 0 Then
        sq = sq & " and l.vta_terminal = " & Combo3.Text
   End If
   sq = sq & " and t.ter_local = " & VLocal
   sq = sq & " Union"
   sq = sq & " select"
   sq = sq & " t.ter_fecha"
   sq = sq & " , t.ter_local"
   sq = sq & " ,t.ter_terminal"
   sq = sq & " ,0 as ter_cierrey"
   sq = sq & " ,t.ter_estado"
   sq = sq & " from vta_sfcltermstat t"
   sq = sq & " where not exists(select v.vta_terminal from vta_sfcllibvta v where v.vta_fecha_venta = t.ter_fecha"
   sq = sq & "                         and v.vta_local = t.ter_local"
   sq = sq & "                         and v.vta_terminal = t.ter_terminal)"
   sq = sq & " and t.ter_local = " & VLocal
   sq = sq & " and (t.ter_fecha >= to_date('" & Format(DTPicker1.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')"
   sq = sq & " and t.ter_fecha <= to_date('" & Format(DTPicker2.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "'))"
   If CDbl(Combo3.Text) <> 0 Then
        sq = sq & " and t.ter_terminal = " & Combo3.Text
   End If
End If

sq = sq & "  Order by 1,2,3 "
sq = sq & "  "

 

FuncStrPivoteSOAR_SOUY = sq




End Function
Private Function FuncStrPivote1SOAR_SOUY(ByVal VLocal As String) As String

    Dim sq As String
    Dim TipoReg As String
    Dim TipoCondi As String

    FuncStrPivote1SOAR_SOUY = ""

    If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or _
        Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
        TipoReg = "y"
        TipoCondi = "Y"
    Else
        TipoReg = ""
        TipoCondi = "F8"
    End If

    ' =========================
    ' QUERY CON ROW_NUMBER()
    ' =========================
    sq = ""
    sq = sq & " SELECT ter_fecha, ter_local, ter_fechacierre FROM ( " & _
              "   SELECT /*+ ordered use_nl(l r t)*/ " & _
              "          t.ter_fecha, " & _
              "          t.ter_local, " & _
              "          TO_CHAR(t.ter_fechacierre,'DD/MM/YYYY') ter_fechacierre, " & _
              "          ROW_NUMBER() OVER ( " & _
              "              PARTITION BY t.ter_fecha, t.ter_local " & _
              "              ORDER BY t.ter_fechacierre DESC ) rn " & _
              "   FROM vta_" & Flg_Pais$ & "libvta l, " & _
              "        vta_" & Flg_Pais$ & "zzz r, " & _
              "        vta_" & Flg_Pais$ & "termstat" & TipoReg & " t " & _
              "   WHERE l.vta_tiporeg = '" & TipoCondi & "' " & _
              "     AND t.ter_fecha >= TO_DATE('" & Format(DTPicker1.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "') " & _
              "     AND t.ter_fecha <= TO_DATE('" & Format(DTPicker2.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "') " & _
              "     AND l.vta_estado = 'A' " & _
              "     AND l.vta_techkey = r.rec_techkey " & _
              "     AND l.vta_fecha_venta = t.ter_fecha " & _
              "     AND l.vta_local = t.ter_local " & _
              "     AND l.vta_terminal = t.ter_terminal "

    If (Flg_Pais$ = "" Or Flg_Pais$ = "CHI" Or Flg_Pais$ = "CMCL" Or Flg_Pais$ = "KFCL") Then
        sq = sq & " AND l.vta_local NOT IN (36,37) "
    End If

    If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or _
        Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
        sq = sq & " AND l.vta_secuencia = t.ter_cierrey "
    End If

    sq = sq & " ) WHERE rn = 1 " & _
              " ORDER BY ter_fecha, ter_local "

    FuncStrPivote1SOAR_SOUY = sq

End Function


Private Sub SubBuscarOpcion1(ByVal Index As Integer)
Dim DiferenciaCaja, DiferenciaReal, xFecha, xlocal, Xterminal, XEstado, Xcierrey, Vcompensado
Dim BEfectivo, BChequeDia, BDolares, BEuros, Btarjeta, BTicker, Bcmr
Dim nFILA, XSumEstado, XContador
Dim VLocal, Bprod
Dim DifZconY As Boolean
Grid1.Visible = False

Call definegrid(Index)
Combo1.ListIndex = Combo2.ListIndex
VLocal = Combo2.Text
If VLocal = 0 Then
    VLocal = ""
End If
 sq = FuncStrPivote1(VLocal)

On Error GoTo salir
Set BuscarOpcion = CreateObject("ADODB.Recordset")
With BuscarOpcion
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With
Call BuscarOpcion.Open(sq)
VLocal = 0
nFILA = 1
While Not BuscarOpcion.EOF
      xFecha = BuscarOpcion.Fields(0).Value
      xlocal = BuscarOpcion.Fields(1).Value
      XSumEstado = BuscarOpcion.Fields(2).Value
      XContador = BuscarOpcion.Fields(3).Value
      
      Xterminal = ""
      Xcierrey = ""
 
      
      X = FuncValorZoY(xFecha, xlocal, Xterminal, Xcierrey)
      If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
         DifZconY = FuncValorZ(xFecha, xlocal, Xterminal, Xcierrey)
      End If
      BEfectivo = FuncBuscarRecEfectivo("EFE", xFecha, xlocal, Xterminal, Xcierrey)
          BChequeDia = FuncBuscarRecEfectivo("CHE", xFecha, xlocal, Xterminal, Xcierrey)
      BDolares = FuncBuscarRecEfectivo("OTR", xFecha, xlocal, Xterminal, Xcierrey)
'      BDolares = FuncBuscarRecModRec(DOLAR, Xfecha, Xlocal, Xterminal, Xcierrey)
      If BDolares <> 0 Then
         Bprod = FuncBuscarNumRecModRec(DOLAR, xFecha, xlocal, Xterminal, Xcierrey, 1)
         If BDolares = Bprod Then
            BDolares = FuncBuscarNumRecModRec(DOLAR, xFecha, xlocal, Xterminal, Xcierrey, 2)
         Else
            Bprod = FuncBuscarNumRecModRec(DOLAR, xFecha, xlocal, Xterminal, Xcierrey, 0)
            BDolares = (BDolares * Bprod)
         End If
      End If
     ' BEuros = FuncBuscarRecModRec(EUROS, Xfecha, Xlocal, Xterminal, Xcierrey)

      BEuros = FuncBuscarRecEfectivo("EUR", xFecha, xlocal, Xterminal, Xcierrey)
      If BEuros <> 0 Then
         Bprod = FuncBuscarNumRecModRec(EUROS, xFecha, xlocal, Xterminal, Xcierrey, 1)
         If BEuros = Bprod Then
            BDolares = FuncBuscarNumRecModRec(EUROS, xFecha, xlocal, Xterminal, Xcierrey, 2)
         Else
            Bprod = FuncBuscarNumRecModRec(EUROS, xFecha, xlocal, Xterminal, Xcierrey, 0)
            BEuros = (BEuros * Bprod)
         End If
              
      End If
           
      BChequeFecha = FuncBuscarRecCheFecha(xFecha, xlocal, Xterminal, Xcierrey, "")
      Btarjeta = FuncBuscarRecTarj("tarj", xFecha, xlocal, Xterminal, Xcierrey)
      
      
      If Flg_Pais$ = "PER" Or Flg_Pais$ = "SOPE" Or Flg_Pais$ = "SPOR" Or Flg_Pais$ = "MAPE" Or Flg_Pais$ = "MPAM" Or Flg_Pais$ = "FAOR" Or Flg_Pais$ = "HTPE" Then
         BTicker = FuncBuscarRecCheFecha(xFecha, xlocal, Xterminal, Xcierrey, "Cupones")
      Else
         
         BTicker = FuncBuscarRecTarj("ticket", xFecha, xlocal, Xterminal, Xcierrey)
      End If
      
      If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
          Bcmr = FuncBuscarRecTarj("CMR", xFecha, xlocal, Xterminal, Xcierrey)
      Else
         Bcmr = 0
      End If
      
      Vcompensado = ValorCompensacion(xFecha, xlocal, Xterminal, Xcierrey)
   
      DiferenciaCaja = ((BEfectivo - Zefectivo) + (BChequeDia - Zchequedia) + _
                        (BDolares - Zdolares) + (BEuros - Zeuros) + _
                        (Btarjeta - Ztarjeta) + (BTicker - Zticketpago) + _
                        (Bcmr - Ztarjetacmr) + (BChequeFecha - Zchequefecha))
              
      DiferenciaReal = (Format(DiferenciaCaja, gFormat) - Format(Vcompensado, gFormat))
'   Grid1.TextMatrix(0, 0) = "Fecha"
'   Grid1.TextMatrix(0, 1) = "Local"
'   Grid1.TextMatrix(0, 4) = "Dif. de Caja"
'   Grid1.TextMatrix(0, 5) = "Compensación"
'   Grid1.TextMatrix(0, 6) = "Dif. Real"
'   Grid1.TextMatrix(0, 7) = "Estado"
      
      
      'If Xlocal <> vlocal Then
          Grid1.AddItem ""
          Grid1.TextMatrix(nFILA, 0) = Format(xFecha, VgFormatoFechaLectura)
          Grid1.TextMatrix(nFILA, 1) = xlocal
          Grid1.TextMatrix(nFILA, 2) = ""
          If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
             Grid1.TextMatrix(nFILA, 3) = IIf(DifZconY, "NO", "SI")
          End If
          Grid1.row = nFILA
          Grid1.ColAlignment(4) = 7
          Grid1.ColAlignment(5) = 7
          Grid1.ColAlignment(6) = 7
         
          Grid1.TextMatrix(nFILA, 4) = Format((DiferenciaCaja), gFormat)
          Grid1.TextMatrix(nFILA, 5) = Format((Vcompensado), gFormat)
          Grid1.TextMatrix(nFILA, 8) = Format((DiferenciaReal), gFormat)
      
          Grid1.col = 8
          
'          If Abs(XSumEstado) = XContador Then
'              BEstado = True
'          Else
'              BEstado = False
'          End If
'          If BEstado = True Then
'                If XSumEstado = (XContador * -1) Then
'                   XEstado = -1
'                End If
'                If XSumEstado = 0 Then
'                   XEstado = -1
'                End If
'                If XSumEstado = XContador Then
'                   XEstado = 1
'                End If
'
'                If (XSumEstado / 2) = XContador Then
'                   XEstado = 2
'                End If
'                If (XSumEstado / 3) = XContador Then
'                   XEstado = 3
'                End If
'          Else
'                  XEstado = -1
'          End If
          
          Select Case FuncEstadoLocal(xFecha, xlocal)
                Case -1
                   Grid1.CellBackColor = &HFF&       'rojo
                   Grid1.CellForeColor = &H80000005   'blanco
                   Grid1.TextMatrix(nFILA, 7) = "Pendiente"
                  
                Case 0
                   Grid1.CellBackColor = &H80FFFF         'amarillo
                   Grid1.CellForeColor = &H0&            'negro
                   Grid1.TextMatrix(nFILA, 7) = "Pendiente"
                Case 1
                   Grid1.CellBackColor = &H80FF80        ' verde
                   Grid1.CellForeColor = &H0&            ' negro
                    Grid1.TextMatrix(nFILA, 7) = "Cerrado"
                Case 2
                   Grid1.CellBackColor = &HFF0000         ' azul
                   Grid1.CellForeColor = &H80000005      ' blanco
                  Grid1.TextMatrix(nFILA, 7) = "Impreso"
                Case 3
                   Grid1.CellBackColor = &H0&          'negro
                   Grid1.CellForeColor = &H80000005    'blanco
                   Grid1.TextMatrix(nFILA, 7) = "Sin Datos"
                Case -2 'CK: 160531 Modificaciones F8 ARG
                   Grid1.CellBackColor = &H80FF&      'naranjo
                   Grid1.CellForeColor = &H80000005   'blanco
                   Grid1.TextMatrix(nFILA, 7) = "Pendiente"
           End Select
           nFILA = nFILA + 1
     ' End If
   BuscarOpcion.MoveNext
Wend
Grid1.Visible = True

 
Set BuscarOpcion.ActiveConnection = Nothing
BuscarOpcion.Close
Exit Sub

salir:
  
   ' Set BuscarOpcionCompensa.ActiveConnection = Nothing
    SystemMsg = "Problemas de comunicación con servidor, buscando información de perfiles"
    frmLogOraError.Show 1
    Exit Sub
End Sub


Private Sub SubBuscarOpcion1SOAR_SOUY(ByVal Index As Integer)
Dim DiferenciaCaja, DiferenciaReal, xFecha, xlocal, Xterminal, XEstado, Xcierrey, Vcompensado
Dim BEfectivo, BChequeDia, BDolares, BEuros, Btarjeta, BTicker, Bcmr
Dim nFILA, XSumEstado, XContador
Dim VLocal, Bprod
Dim DifZconY As Boolean
Grid1.Visible = False
Dim XFechaCierre As Date

Call definegrid(Index)
Combo1.ListIndex = Combo2.ListIndex
VLocal = Combo2.Text
If VLocal = 0 Then
    VLocal = ""
End If
 sq = FuncStrPivote1SOAR_SOUY(VLocal)

On Error GoTo salir
Set BuscarOpcion = CreateObject("ADODB.Recordset")
With BuscarOpcion
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With
Call BuscarOpcion.Open(sq)
VLocal = 0
nFILA = 1
While Not BuscarOpcion.EOF
      xFecha = BuscarOpcion.Fields(0).Value
      xlocal = BuscarOpcion.Fields(1).Value
      'XSumEstado = BuscarOpcion.Fields(2).Value
      'XContador = BuscarOpcion.Fields(3).Value
      XFechaCierre = BuscarOpcion.Fields(2).Value
      Xterminal = ""
      Xcierrey = ""
 
      
      X = FuncValorZoY(xFecha, xlocal, Xterminal, Xcierrey)
      If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
         DifZconY = FuncValorZ(xFecha, xlocal, Xterminal, Xcierrey)
      End If
      BEfectivo = FuncBuscarRecEfectivo("EFE", xFecha, xlocal, Xterminal, Xcierrey)
          BChequeDia = FuncBuscarRecEfectivo("CHE", xFecha, xlocal, Xterminal, Xcierrey)
      BDolares = FuncBuscarRecEfectivo("OTR", xFecha, xlocal, Xterminal, Xcierrey)
'      BDolares = FuncBuscarRecModRec(DOLAR, Xfecha, Xlocal, Xterminal, Xcierrey)
      If BDolares <> 0 Then
         Bprod = FuncBuscarNumRecModRec(DOLAR, xFecha, xlocal, Xterminal, Xcierrey, 1)
         If BDolares = Bprod Then
            BDolares = FuncBuscarNumRecModRec(DOLAR, xFecha, xlocal, Xterminal, Xcierrey, 2)
         Else
            Bprod = FuncBuscarNumRecModRec(DOLAR, xFecha, xlocal, Xterminal, Xcierrey, 0)
            BDolares = (BDolares * Bprod)
         End If
      End If
     ' BEuros = FuncBuscarRecModRec(EUROS, Xfecha, Xlocal, Xterminal, Xcierrey)

      BEuros = FuncBuscarRecEfectivo("EUR", xFecha, xlocal, Xterminal, Xcierrey)
      If BEuros <> 0 Then
         Bprod = FuncBuscarNumRecModRec(EUROS, xFecha, xlocal, Xterminal, Xcierrey, 1)
         If BEuros = Bprod Then
            BDolares = FuncBuscarNumRecModRec(EUROS, xFecha, xlocal, Xterminal, Xcierrey, 2)
         Else
            Bprod = FuncBuscarNumRecModRec(EUROS, xFecha, xlocal, Xterminal, Xcierrey, 0)
            BEuros = (BEuros * Bprod)
         End If
              
      End If
           
      BChequeFecha = FuncBuscarRecCheFecha(xFecha, xlocal, Xterminal, Xcierrey, "")
      Btarjeta = FuncBuscarRecTarj("tarj", xFecha, xlocal, Xterminal, Xcierrey)
      
      
      If Flg_Pais$ = "PER" Or Flg_Pais$ = "SOPE" Or Flg_Pais$ = "SPOR" Or Flg_Pais$ = "MAPE" Or Flg_Pais$ = "MPAM" Or Flg_Pais$ = "FAOR" Or Flg_Pais$ = "HTPE" Then
         BTicker = FuncBuscarRecCheFecha(xFecha, xlocal, Xterminal, Xcierrey, "Cupones")
      Else
         
         BTicker = FuncBuscarRecTarj("ticket", xFecha, xlocal, Xterminal, Xcierrey)
      End If
      
      If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
          Bcmr = FuncBuscarRecTarj("CMR", xFecha, xlocal, Xterminal, Xcierrey)
      Else
         Bcmr = 0
      End If
      
      Vcompensado = ValorCompensacion(xFecha, xlocal, Xterminal, Xcierrey)
   
      DiferenciaCaja = ((BEfectivo - Zefectivo) + (BChequeDia - Zchequedia) + _
                        (BDolares - Zdolares) + (BEuros - Zeuros) + _
                        (Btarjeta - Ztarjeta) + (BTicker - Zticketpago) + _
                        (Bcmr - Ztarjetacmr) + (BChequeFecha - Zchequefecha))
              
      DiferenciaReal = (Format(DiferenciaCaja, gFormat) - Format(Vcompensado, gFormat))
'   Grid1.TextMatrix(0, 0) = "Fecha"
'   Grid1.TextMatrix(0, 1) = "Local"
'   Grid1.TextMatrix(0, 4) = "Dif. de Caja"
'   Grid1.TextMatrix(0, 5) = "Compensación"
'   Grid1.TextMatrix(0, 6) = "Dif. Real"
'   Grid1.TextMatrix(0, 7) = "Estado"
      
      
      'If Xlocal <> vlocal Then
          Grid1.AddItem ""
          Grid1.TextMatrix(nFILA, 0) = Format(xFecha, VgFormatoFechaLectura)
          Grid1.TextMatrix(nFILA, 1) = xlocal
          Grid1.TextMatrix(nFILA, 2) = ""
          If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
             Grid1.TextMatrix(nFILA, 3) = IIf(DifZconY, "NO", "SI")
          End If
          Grid1.row = nFILA
          Grid1.ColAlignment(4) = 7
          Grid1.ColAlignment(5) = 7
          Grid1.ColAlignment(6) = 7
         
          Grid1.TextMatrix(nFILA, 4) = Format((DiferenciaCaja), gFormat)
          Grid1.TextMatrix(nFILA, 5) = Format((Vcompensado), gFormat)
          Grid1.TextMatrix(nFILA, 6) = Format((DiferenciaReal), gFormat)
          
          
    
      
          Grid1.col = 8
          
'          If Abs(XSumEstado) = XContador Then
'              BEstado = True
'          Else
'              BEstado = False
'          End If
'          If BEstado = True Then
'                If XSumEstado = (XContador * -1) Then
'                   XEstado = -1
'                End If
'                If XSumEstado = 0 Then
'                   XEstado = -1
'                End If
'                If XSumEstado = XContador Then
'                   XEstado = 1
'                End If
'
'                If (XSumEstado / 2) = XContador Then
'                   XEstado = 2
'                End If
'                If (XSumEstado / 3) = XContador Then
'                   XEstado = 3
'                End If
'          Else
'                  XEstado = -1
'          End If
          
          Select Case FuncEstadoLocal(xFecha, xlocal)
                Case -1
                   Grid1.CellBackColor = &HFF&       'rojo
                   Grid1.CellForeColor = &H80000005   'blanco
                   Grid1.TextMatrix(nFILA, 7) = "Pendiente"
                  
                Case 0
                   Grid1.CellBackColor = &H80FFFF         'amarillo
                   Grid1.CellForeColor = &H0&            'negro
                   Grid1.TextMatrix(nFILA, 7) = "Pendiente"
                   Grid1.TextMatrix(nFILA, 8) = ""
                Case 1
                   Grid1.CellBackColor = &H80FF80        ' verde
                   Grid1.CellForeColor = &H0&            ' negro
                   Grid1.TextMatrix(nFILA, 7) = "Cerrado"
                   Grid1.TextMatrix(nFILA, 8) = Format(XFechaCierre, "dd/mm/yyyy")
                Case 2
                   Grid1.CellBackColor = &HFF0000         ' azul
                   Grid1.CellForeColor = &H80000005      ' blanco
                   Grid1.TextMatrix(nFILA, 7) = "Impreso"
                   Grid1.TextMatrix(nFILA, 8) = ""
                Case 3
                   Grid1.CellBackColor = &H0&          'negro
                   Grid1.CellForeColor = &H80000005    'blanco
                   Grid1.TextMatrix(nFILA, 7) = "Sin Datos"
                   Grid1.TextMatrix(nFILA, 8) = ""
           End Select
           nFILA = nFILA + 1
     ' End If
   BuscarOpcion.MoveNext
Wend
Grid1.Visible = True

 
Set BuscarOpcion.ActiveConnection = Nothing
BuscarOpcion.Close
Exit Sub

salir:
  
   ' Set BuscarOpcionCompensa.ActiveConnection = Nothing
    SystemMsg = "Problemas de comunicación con servidor, buscando información de perfiles"
    frmLogOraError.Show 1
    Exit Sub
End Sub
Private Sub Command3_Click()
Unload Me
End Sub

Private Sub Command4_Click()
Screen.MousePointer = 11
Dim X As Integer, ExitoProcArg As Boolean
X = 0
ExitoProcArg = True
'If DTPicker1.Value <> DTPicker2.Value Then
'    MsgBox "Seleccione Día de Cierre de Terminal"
'    Exit Sub
'End If
'
'If Combo3.Text = 0 Then
'    MsgBox "Seleccione Terminal de Cierre"
'    Exit Sub
'End If
'
'For i = 1 To Grid1.Rows - 1
'    If CDbl(Grid1.TextMatrix(i, 6)) <> 0 Then
'        X = X + 1
'    End If
'Next i
'
'If X <> 0 Then
'    MsgBox "Existen Diferencias en el Terminal, No se permite el Cierre", vbCritical
'    Exit Sub
'End If

If Grid1.Rows <> 0 And Grid1.Rows <> 1 Then
    
    
    'If Not ConsultaCierreTerm(DTPicker1.Value, Combo2.Text, Combo3.Text) Then
    'End
     If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
           
        '---INI---- xintec-nruz 20-10-2026 FSCC-12901: confirmacion al cerrar con TODOS LOS LOCALES (FACO) ----
        If Flg_Pais$ = "FACO" And Trim(Combo2.Text) = "0" Then
            Dim nCajasTodos As Long, nLocalesTodos As Long, vLocalesTodos As String, respTodos As Integer
            nCajasTodos = 0
            nLocalesTodos = 0
            vLocalesTodos = ""
            For i = 1 To Grid1.Rows - 1
                If (Trim(Grid1.TextMatrix(i, 7)) <> "Cerrado" And Trim(Grid1.TextMatrix(i, 7)) <> "Pendiente MP") And CDbl(Grid1.TextMatrix(i, 6)) = 0 Then
                    nCajasTodos = nCajasTodos + 1
                    If InStr(vLocalesTodos, "|" & Trim(Grid1.TextMatrix(i, 1)) & "|") = 0 Then
                        vLocalesTodos = vLocalesTodos & "|" & Trim(Grid1.TextMatrix(i, 1)) & "|"
                        nLocalesTodos = nLocalesTodos + 1
                    End If
                End If
            Next i
            If nCajasTodos > 0 Then
                Screen.MousePointer = 0
                respTodos = MsgBox("Se cerraran " & nCajasTodos & " caja(s) con Dif. Real 0 de " & nLocalesTodos & " local(es), entre el " & _
                                   Format(DTPicker1.Value, "dd-mm-yyyy") & " y el " & Format(DTPicker2.Value, "dd-mm-yyyy") & "." & vbCrLf & vbCrLf & _
                                   "Desea continuar?", vbYesNo + vbQuestion + vbDefaultButton2, "Cerrar Terminal - Todos los locales")
                If respTodos <> vbYes Then
                    Exit Sub
                End If
                Screen.MousePointer = 11
            End If
        End If
        '---FIN---- xintec-nruz 20-10-2026 ----
        '---INI---- xintec-nruz 20-10-2026 FSCC-12901: mensaje final de cierre en FACO (cuenta cajas cerradas) ----
        Dim nCerradosAntes As Long, nCerradosDespues As Long
        nCerradosAntes = 0
        If Flg_Pais$ = "FACO" Then
            For i = 1 To Grid1.Rows - 1
                If Trim(Grid1.TextMatrix(i, 7)) = "Cerrado" Then nCerradosAntes = nCerradosAntes + 1
            Next i
        End If
        '---FIN---- xintec-nruz 20-10-2026 ----
        For i = 1 To Grid1.Rows - 1
            If (Trim(Grid1.TextMatrix(i, 7)) <> "Cerrado" And Trim(Grid1.TextMatrix(i, 7)) <> "Pendiente MP") And CDbl(Grid1.TextMatrix(i, 3)) <> 0 And CDbl(Grid1.TextMatrix(i, 6)) = 0 Then
                Call CierraTerminalYYY(Grid1.TextMatrix(i, 0), Grid1.TextMatrix(i, 1), Grid1.TextMatrix(i, 2), Grid1.TextMatrix(i, 3))
              
            End If
        Next i
        Call Command2_Click
        Screen.MousePointer = 11
        
        For i = 1 To Grid1.Rows - 1
            If (Trim(Grid1.TextMatrix(i, 7)) <> "Cerrado" And Trim(Grid1.TextMatrix(i, 7)) <> "Pendiente MP") And CDbl(Grid1.TextMatrix(i, 3)) = 0 And CDbl(Grid1.TextMatrix(i, 6)) = 0 Then
                Call CierraTerminal(Grid1.TextMatrix(i, 0), Grid1.TextMatrix(i, 1), Grid1.TextMatrix(i, 2))
                
            End If
        Next i
        Call Command2_Click
        Screen.MousePointer = 11
        '---INI---- xintec-nruz 20-10-2026 FSCC-12901: mensaje final de cierre en FACO (cuenta cajas cerradas) ----
        If Flg_Pais$ = "FACO" Then
            nCerradosDespues = 0
            For i = 1 To Grid1.Rows - 1
                If Trim(Grid1.TextMatrix(i, 7)) = "Cerrado" Then nCerradosDespues = nCerradosDespues + 1
            Next i
            If nCerradosDespues > nCerradosAntes Then X = nCerradosDespues - nCerradosAntes
        End If
        '---FIN---- xintec-nruz 20-10-2026 ----
     ElseIf Flg_Pais$ = "ARG" Then
        Valida_Cierre_Arg = False
        For i = 1 To Grid1.Rows - 1
            If (Trim(Grid1.TextMatrix(i, 7)) <> "Cerrado" And Trim(Grid1.TextMatrix(i, 7)) <> "Pendiente MP") And CDbl(Grid1.TextMatrix(i, 3)) <> 0 And CDbl(Grid1.TextMatrix(i, 6)) = 0 Then
                Call CierraTerminalYYY(Grid1.TextMatrix(i, 0), Grid1.TextMatrix(i, 1), Grid1.TextMatrix(i, 2), Grid1.TextMatrix(i, 3))
            End If
        Next i
        'Call Command2_Click
        Screen.MousePointer = 11
        For i = 1 To Grid1.Rows - 1
            If Trim(Grid1.TextMatrix(i, 7)) <> "Cerrado" And Trim(Grid1.TextMatrix(i, 7)) <> "Pendiente MP" And CDbl(Grid1.TextMatrix(i, 3)) <> 0 And CDbl(Grid1.TextMatrix(i, 6)) = 0 And CDbl(Grid1.TextMatrix(i, 3)) <> 0 Then
                Call CierraTerminal(Grid1.TextMatrix(i, 0), Grid1.TextMatrix(i, 1), Grid1.TextMatrix(i, 2))
                If Valida_Cierre_Arg Then
                    X = X + 1
                Else
                    Call UpdateCierreTerminalZYArg(Grid1.TextMatrix(i, 0), Grid1.TextMatrix(i, 1), Grid1.TextMatrix(i, 2))
                    ExitoProcArg = False
                End If
            ElseIf (Trim(Grid1.TextMatrix(i, 7)) <> "Cerrado" And Trim(Grid1.TextMatrix(i, 7)) <> "Pendiente MP") And CDbl(Grid1.TextMatrix(i, 3)) = 0 And CDbl(Grid1.TextMatrix(i, 6)) = 0 And CDbl(Grid1.TextMatrix(i, 3)) = 0 Then
                Call CierraTerminalArgSinY(Grid1.TextMatrix(i, 0), Grid1.TextMatrix(i, 1), Grid1.TextMatrix(i, 2))
                If Valida_Cierre_Arg Then
                    X = X + 1
                Else
                    Call UpdateCierreTerminalZYArg(Grid1.TextMatrix(i, 0), Grid1.TextMatrix(i, 1), Grid1.TextMatrix(i, 2))
                    ExitoProcArg = False
                End If
            End If
        Next i
        Call Command2_Click
        Screen.MousePointer = 11
     Else
        For i = 1 To Grid1.Rows - 1
            'If (Trim(Grid1.TextMatrix(i, 7)) <> "Cerrado" And Trim(Grid1.TextMatrix(i, 7)) <> "Pendiente MP") And CDbl(Grid1.TextMatrix(i, 4)) = 0 And CDbl(Grid1.TextMatrix(i, 5)) = 0 And CDbl(Grid1.TextMatrix(i, 6)) = 0 Then
            If (Trim(Grid1.TextMatrix(i, 7)) <> "Cerrado" And Trim(Grid1.TextMatrix(i, 7)) <> "Pendiente MP") And CDbl(Grid1.TextMatrix(i, 6)) = 0 Then
                Call CierraTerminal(Grid1.TextMatrix(i, 0), Grid1.TextMatrix(i, 1), Grid1.TextMatrix(i, 2))
                X = X + 1
            End If
        Next i
        Call Command2_Click
     End If
 
End If
Screen.MousePointer = 0
    If Flg_Pais$ = "ARG" Then
        If (X > 0 And Valida_Cierre_Arg And ExitoProcArg) Then
            MsgBox "Proceso de Cierre Terminal Ejecutado Exitosamente", vbInformation
        ElseIf (X > 0 And ExitoProcArg = False) Then
            MsgBox "Proceso de Cierre Terminal Ejecutado Exitosamente, pero existen terminales sin cerrar", vbInformation
        Else
            MsgBox "No hay Terminales que Cumplan con el Proceso de Cierre", vbInformation
        End If
    Else
        If (X > 0) Then
            MsgBox "Proceso de Cierre Terminal Ejecutado Exitosamente", vbInformation
        Else
            MsgBox "No hay Terminales que Cumplan con el Proceso de Cierre", vbInformation
        End If
    End If
End Sub
Private Sub Command5_Click()
Form143.Show 1
End Sub

Private Sub DTPicker1_Click()
Call LeeTerminales
End Sub

Private Sub Form_Load()
vf_suspender = False
Me.Left = Screen.Width / 2 - Me.Width / 2
Me.Top = Screen.Height / 2 - Me.Height / 2

If Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "MAPE" Or Flg_Pais$ = "MPAM" Or Flg_Pais$ = "SPOR" Then
    'OptionInforme(1).Caption = "Vendedor"
    OptionInforme(0).Caption = "Vendedor"
    
    OptionInforme(1).Visible = False
    OptionInforme(2).Visible = False
    Combo3.Visible = True
    'Combo3.Left = 7920
    Labelterminal.Visible = True
    Labelterminal.Caption = "Vendedor"
    'Labelterminal.Left = 7920
    
    If FuncBuscarOpcionCompensa(PERFILUSER, OpcionPermiteCerrarTerminalCC) Then
        Command4.Visible = True
    End If
End If

If Flg_Pais$ = "" Or Flg_Pais$ = "CHI" Then
    Combo3.Visible = True
    'Combo3.Left = 7920
    Labelterminal.Visible = True
    Labelterminal.Caption = "Terminal"
    'Labelterminal.Left = 7920
    
    If FuncBuscarOpcionCompensa(PERFILUSER, OpcionPermiteCerrarTerminalCC) Then
        Command4.Visible = True
    End If
End If

If Flg_Pais$ = "SFCL" Or Flg_Pais$ = "HTPE" Then
    OptionInforme(1).Visible = False
    OptionInforme(2).Visible = False
    Combo3.Visible = True
    Labelterminal.Visible = True
    Labelfecha.Visible = False
    DTPicker2.Visible = False
    Label1.Caption = "Fecha Venta"
    
    If FuncBuscarOpcionCompensa(PERFILUSER, OpcionPermiteCerrarTerminalCC) Then
        Command4.Visible = True
    End If
End If

Call LeeLocales
Combo1.Text = FormVariable.Combo1.Text
'Call LeeTerminales
If Flg_Pais$ = "SFCL" Then
    DTPicker1.Value = Gfecha
Else
    DTPicker1.Value = Form3.DTPicker1.Value 'Date "01-" + Mid(Trim(FormVariable.DTPicker1.Value), 4) 'FormVariable.DTPicker1.Value
    
End If
DTPicker2.Value = Form3.DTPicker1.Value 'Date FormVariable.DTPicker1.Value
Combo3.Text = FormVariable.Combo3.Text
VF_NumInforme = -1
Call definegrid(0)
Call LeeTerminales
End Sub
Private Function StrPorCompensado(ByVal strFecha As String, ByVal StrLocal As String, ByVal strTERMINAL As String, ByVal StrCierrey As String) As String
Dim sq As String
StrPorCompensado = ""

'af
'sq = " select  " & _
'"   ( nvl((select  sum(m.mov_monto)   " & _
'"         from   vta_" & Flg_Pais$ & "movdet m" & _
'"         where  m.mov_fecha  =  to_date('" & Format(StrFecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')"
'
'If Trim(StrCierrey) <> "" Then
'    sq = sq & "    and m.mov_cierrey  = " & StrCierrey & " "
'End If
'
'If Trim(StrLocal) <> "" Then
'   sq = sq & "      and m.mov_local  = " & StrLocal & " "
'End If
'If StrTerminal <> "" Then
'   sq = sq & "      and m.mov_terminal  = " & StrTerminal & " "
'End If
'sq = sq & "      and m.mov_tipomov   in ( 'AF')  ),0)    -  " & _
'"  nvl((select          sum(mo.mov_monto)   " & _
'"         from   vta_" & Flg_Pais$ & "movdet mo" & _
'"         where  mo.mov_fechavb  =  to_date('" & Format(StrFecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')"
'
'If Trim(StrCierrey) <> "" Then
'    sq = sq & "    and mo.mov_cierrey  = " & StrCierrey & " "
'End If
'
'If Trim(StrLocal) <> "" Then
'   sq = sq & "      and mo.mov_local  = " & StrLocal & " "
'End If
'If StrTerminal <> "" Then
'   sq = sq & "      and mo.mov_terminal  = " & StrTerminal & " "
'End If
'sq = sq & "   and mo.mov_vbpor = 'S'     and  mo.mov_tipomov   in ( 'AF')   ),0 )   ) as mov_monto     "
'
'sq = sq & "  " & _
'" FROM vta_" & Flg_Pais$ & "concepdif d" & _
'" where  d.mov_tipomov in ('AF')   " & _
'" Union "




sq = sq & " select " & _
"        sum(m.mov_monto) as mov_monto" & _
"         from   vta_" & Flg_Pais$ & "movdet m" & _
"           , vta_" & Flg_Pais$ & "concepdif d" & _
"         where  m.mov_fecha  = to_date('" & Format(strFecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')"
If Trim(StrCierrey) <> "" Then
    sq = sq & "    and m.mov_cierrey  = " & StrCierrey & " "
End If

If Trim(StrLocal) <> "" Then
   sq = sq & "      and m.mov_local  = " & StrLocal & " "
End If
If strTERMINAL <> "" Then
   sq = sq & "      and m.mov_terminal  = " & strTERMINAL & " "
End If
sq = sq & "      and m.mov_tipomov = d.mov_tipomov" & _
         "     and d.mov_tipomov not in ( 'VC' " & IIf(Flg_Pais$ = "CHI" Or Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "KFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "", ",'CA'", " ") & " )" & _
         " union"
','AF' le sacamos


If (Flg_Pais$ = "CHI" Or Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "" Or Flg_Pais$ = "KFCL" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "SFCL") Then
    sq = sq & " select " & _
    "            nvl(sum(m.mov_monto),0)" & _
    "         from   vta_" & Flg_Pais$ & "cartaaviso m" & _
    "              , vta_" & Flg_Pais$ & "concepdif d" & _
    "         where  m.mov_fecha  = to_date('" & Format(strFecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')"
   If Trim(StrCierrey) <> "" Then
        sq = sq & "    and m.mov_cierrey  = " & StrCierrey & " "
    End If
    If Trim(StrLocal) <> "" Then
        sq = sq & "      and m.mov_local  = " & StrLocal & " "
    End If
    If strTERMINAL <> "" Then
        sq = sq & "      and m.mov_terminal  = " & strTERMINAL & " "
    End If
    sq = sq & "      and m.mov_tipomov = d.mov_tipomov" & _
    "      and d.mov_tipomov = 'CA' " & _
    "      union"
    
 End If


sq = sq & "   select nvl(sum(m.VEN_MONTO),0)        " & _
"          from   vta_" & Flg_Pais$ & "difvend m    " & _
"          where  m.ven_fecha = to_date('" & Format(strFecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')"
sq = sq & " and  m.VEN_MONTO < 0 "
If Trim(StrCierrey) <> "" Then ' FormVariable.Name = VG_PantaForm3Y And
    sq = sq & "    and m.ven_cierrey  = " & StrCierrey & " "
End If

If Trim(StrLocal) <> "" Then
    sq = sq & "  and  m.ven_local = " & StrLocal & " "
End If
If strTERMINAL <> "" Then
sq = sq & "  and  m.ven_terminal = " & strTERMINAL & " "
End If

StrPorCompensado = sq
End Function

Private Function SumaConceptosPorCompensado(ByVal vfecha As String, ByVal VLocal As String, ByVal vterminal As String, ByVal vcierrey As String) As Double
Set Consulta = CreateObject("ADODB.Recordset")
Dim sq As String
Dim totcon  As Integer
Dim i           As Integer


With Consulta
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With

SumaConceptosPorCompensado = 0
sq = StrPorCompensado(vfecha, VLocal, vterminal, vcierrey)
On Error GoTo oraerror
   
Call Consulta.Open(sq)
totcon = Consulta.RecordCount
   
For i = 0 To totcon - 1
   SumaConceptosPorCompensado = SumaConceptosPorCompensado + CDbl(Change_Char(Consulta.Fields(0).Value, ".", ",")) ' jlom cambio por CDbl(Consulta.Fields(2).Value) 'Grid1.TextMatrix(i, 2)
   Consulta.MoveNext
Next i
  
    
Set Consulta.ActiveConnection = Nothing
Exit Function
oraerror:
 Set Consulta.ActiveConnection = Nothing
End Function

Public Function FuncValorZoY(ByVal vfecha As String, ByVal VLocal As String, ByVal vterminal As String, ByVal vcierrey As String) As Boolean
Dim VL_TipoReg As String

'If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
      VL_TipoReg = "Y"
Else
   VL_TipoReg = "F8"
End If

FuncValorZoY = 0
On Error GoTo salir
Set ValorZoY = CreateObject("ADODB.Recordset")
With ValorZoY
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With

Zefectivo = 0: Zchequedia = 0: Zdolares = 0: Zeuros = 0: Zchequefecha = 0: Ztarjeta = 0: Zticketpago = 0: Ztarjetacmr = 0
ZReales = 0: ZPesoArg = 0
Select Case Flg_Pais$
Rem rmoyag zpesoarg
Case "ARG", "SOAR", "SOUY"
  sq = "   select  /*+ ordered us_nl(l r) */ " & _
       "     nvl(sum(MSUM_EFEC_PESOS),0)          As Zefectivo  " & _
       "    ,nvl(sum(MTOTAL_CHEQUE_DIA),0)          as Zchequedia " & _
       "    ,nvl(sum(MSUM_EFEC_DOLARES),0)          as Zdolares  " & _
       "    ,nvl(sum(MSUM_EFEC_EUROS),0)            as Zeuros " & _
       "    ,nvl(sum(MREALES),0)                         as zreales " & _
       "    ,nvl(sum(MNC_AZUL),0)                         as zpesoarg " & _
       "    ,nvl(sum(MTOTAL_CHEQUE_FECHA),0)        as Zchequefecha " & _
       "    ,nvl(sum(MSUM_TARJ_BANCARIA),0)             as Ztarjeta " & _
       "    ,nvl(sum(MSUM_TRAVELLERS_CHEQUE),0) + nvl(sum(MSUM_MEMBERSHIPS_R),0) + nvl(sum(MSUM_BLUE_REWARDS),0) + nvl(sum(MSUM_TICKET_CANASTA),0) + nvl(sum(MSUM_TICKET_UNIFORME),0)   as Zticketpago "
       If (Trim(re(i).iNombre) = "MSUM_TARJ_CMR" Or Trim(re(i).iNombre) = "MSUM_CTA_CTE") And CDbl(Format(vfecha, VgFormatoFechaWhere)) > VG_Fecha_ARG_Valid Then
          sq = sq & "    , nvl(sum(MSUM_VALE_CREDITO),0)              as Ztarjetacmr "
       Else
          If Flg_Pais$ = "ARG" Then
            sq = sq & "    , nvl(sum(MSUM_VALE_CREDITO),0)              as Ztarjetacmr "
          Else
            sq = sq & "    ,nvl(sum(MSUM_TARJ_CMR),0)  + nvl(sum(MSUM_CTA_CTE),0) + nvl(sum(MSUM_VALE_CREDITO),0)              as Ztarjetacmr "
          End If
       End If
       
       
       '"    , nvl(sum(MSUM_VALE_CREDITO),0)              as Ztarjetacmr "
       
       '
 Case "PER", "HTPE", "FAOR", "MAPE", "SOPE", "MPAM", "SPOR"
   sq = "   select /*+ ordered us_nl(l r) */ " & _
       "     nvl(sum(REC_MEFECTIVO ),0)         as Zefectivo  " & _
       "    ,nvl(sum(REC_MCHEQUES),0)           as Zchequedia " & _
       "    ,nvl(sum(REC_MEFECTIVODOLAR ),0)    as Zdolares  " & _
       "    ,0                                  as Zeuros " & _
       "    ,0                                  as zreales " & _
       "    ,0                                  as zpesoarg " & _
       "    ,nvl(sum(REC_MVALECREDITO),0)       as Zchequefecha " & _
       "    ,nvl(sum(rec_mtarj),0)              as Ztarjeta" & _
       "    ,nvl(sum(REC_MCUPONES),0)           as Zticketpago " & _
       "    ,0                                  as Ztarjetacmr "
       
    
       
  
 Case "FACO"
      sq = "   select /*+ ordered us_nl(l r) */ " & _
       "     nvl(sum(REC_MEFECTIVO   ),0)         as Zefectivo  " & _
       "    ,nvl(sum(REC_MCHKDIA  ),0)            as Zchequedia " & _
       "    ,0                                    as Zdolares  " & _
       "    ,0                                    as Zeuros " & _
       "    ,0                                    as zreales " & _
       "    ,0                                    as zpesoarg " & _
       "    ,nvl(sum(REC_MCHKFECHA),0)            as Zchequefecha " & _
       "    ,nvl(sum(rec_mtarj),0) +nvl(sum(rec_msodimac),0)            as Ztarjeta" & _
       "    ,0                                    as Zticketpago " & _
       "    ,0                                    as Ztarjetacmr "
        
  Case "SFCL"
      sq = "   select /*+ ordered us_nl(l r) */ " & _
       "     nvl(sum(REC_MEFECTIVO   ),0)         as Zefectivo  " & _
       "    ,nvl(sum(REC_MCHKDIA  ),0)            as Zchequedia " & _
       "    ,0                                    as Zdolares  " & _
       "    ,0                                    as Zeuros " & _
       "    ,0                                    as zreales " & _
       "    ,0                                    as zpesoarg " & _
       "    ,nvl(sum(REC_MCHKFECHA),0)            as Zchequefecha " & _
       "    ,nvl(sum(rec_mtransbank),0) + nvl(sum(REC_MSODIMAC),0) as Ztarjeta" & _
       "    ,0                                    as Zticketpago " & _
       "    ,0                                    as Ztarjetacmr "
    
 
 Case Else
      sq = "   select /*+ ordered us_nl(l r) */ " & _
       "     nvl(sum(REC_MEFECTIVO   ),0)         as Zefectivo  " & _
       "    ,nvl(sum(REC_MCHKDIA  ),0)            as Zchequedia " & _
       "    ,0                                    as Zdolares  " & _
       "    ,0                                    as Zeuros " & _
       "    ,0                                    as zreales " & _
       "    ,0                                    as zpesoarg " & _
       "    ,nvl(sum(REC_MCHKFECHA),0)            as Zchequefecha " & _
       "    ,nvl(sum(rec_mtarj),0)                as Ztarjeta" & _
       "    ,0                                    as Zticketpago " & _
       "    ,0                                    as Ztarjetacmr "
        
        
 End Select

 
  
    
    sq = sq & " From   vta_" & Flg_Pais$ & "libvta l, vta_" & Flg_Pais$ & "zzz r " & _
       " where  l.vta_tiporeg = '" & VL_TipoReg & "' " & _
       " and    l.vta_fecha_venta = to_date('" & Format(vfecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')"

If vcierrey <> "" And vcierrey <> "0" Then
       sq = sq & " and    l.vta_secuencia   =  " & vcierrey
End If
If vterminal <> "" And vterminal <> "0" Then
       sq = sq & " and    l.vta_terminal =   " & vterminal
End If
       sq = sq & " and    l.vta_local =   " & VLocal & _
       " and    l.vta_estado = 'A' " & _
       " and    l.vta_techkey = r.rec_techkey "
      

 
 
Call ValorZoY.Open(sq)

 

While Not ValorZoY.EOF
   
   
   Zefectivo = Zefectivo + ValorZoY.Fields("Zefectivo").Value
   Zchequedia = Zchequedia + ValorZoY.Fields("Zchequedia").Value
   Zdolares = Zdolares + ValorZoY.Fields("Zdolares").Value
   Zeuros = Zeuros + ValorZoY.Fields("Zeuros").Value
   ZReales = ZReales + ValorZoY.Fields("zreales").Value
   ZPesoArg = ZPesoArg + ValorZoY.Fields("zpesoarg").Value
   If Flg_Pais$ = "PER" Or Flg_Pais$ = "SOPE" Or Flg_Pais$ = "SPOR" Or Flg_Pais$ = "MAPE" Or Flg_Pais$ = "MPAM" Or Flg_Pais$ = "FAOR" Or Flg_Pais$ = "HTPE" Then
       Zchequefecha = Zchequefecha + IIf(CDbl(Format(vfecha, VG_Fecha_Peru)) < CDbl(VG_Fecha_Peru_Valid), 0, CDbl(ValorZoY.Fields("Zchequefecha").Value))
   Else
       Zchequefecha = Zchequefecha + ValorZoY.Fields("Zchequefecha").Value
   End If
   Ztarjeta = Ztarjeta + ValorZoY.Fields("Ztarjeta").Value
   Zticketpago = Zticketpago + ValorZoY.Fields("Zticketpago").Value
   Ztarjetacmr = Ztarjetacmr + ValorZoY.Fields("Ztarjetacmr").Value

   
   ValorZoY.MoveNext
Wend
 

 
Set ValorZoY.ActiveConnection = Nothing
ValorZoY.Close
Exit Function

salir:
    
    Set ValorZoY.ActiveConnection = Nothing
    FuncValorZoY = 0
    SystemMsg = "Problemas de comunicación con servidor,Información del Z o Y "
    frmLogOraError.Show 1
    Exit Function
End Function

Public Function FuncValorZ(ByVal vfecha As String, ByVal VLocal As String, ByVal vterminal As String, ByVal vcierrey As String) As Boolean
Dim VL_TipoReg As String

If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
   VL_TipoReg = "F8"
Else
   VL_TipoReg = "F8"
End If
 FuncValorZ = True
On Error GoTo salir
Set ValorZoY = CreateObject("ADODB.Recordset")
With ValorZoY
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With

ZZZefectivo = 0: ZZZchequedia = 0: ZZZdolares = 0: ZZZeuros = 0: ZZZchequefecha = 0: ZZZtarjeta = 0: ZZZticketpago = 0: ZZZtarjetacmr = 0
ZReales = 0: ZPesoArg = 0

Select Case Flg_Pais$

Case "ARG", "SOAR", "SOUY"
  sq = "   select " & _
       "     nvl(sum(MSUM_EFEC_PESOS),0)          As Zefectivo  " & _
       "    ,nvl(sum(MTOTAL_CHEQUE_DIA),0)          as Zchequedia " & _
       "    ,nvl(sum(MSUM_EFEC_DOLARES),0)          as Zdolares  " & _
       "    ,nvl(sum(MSUM_EFEC_EUROS),0)            as Zeuros " & _
       "    ,nvl(sum(MREALES),0)                         as zreales " & _
       "    ,nvl(sum(MNC_AZUL),0)                         as zpesoarg " & _
       "    ,nvl(sum(MTOTAL_CHEQUE_FECHA),0)        as Zchequefecha " & _
       "    ,nvl(sum(MSUM_TARJ_BANCARIA),0)             as Ztarjeta " & _
       "    ,nvl(sum(MSUM_TRAVELLERS_CHEQUE),0) + nvl(sum(MSUM_MEMBERSHIPS_R),0) + nvl(sum(MSUM_BLUE_REWARDS),0) + nvl(sum(MSUM_TICKET_CANASTA),0) + nvl(sum(MSUM_TICKET_UNIFORME),0)   as Zticketpago "
       
       If (Trim(re(i).iNombre) = "MSUM_TARJ_CMR" Or Trim(re(i).iNombre) = "MSUM_CTA_CTE") And CDbl(Format(vfecha, VgFormatoFechaWhere)) > VG_Fecha_ARG_Valid Then
          sq = sq & "    , nvl(sum(MSUM_VALE_CREDITO),0)              as Ztarjetacmr "
       Else
          sq = sq & "    ,nvl(sum(MSUM_TARJ_CMR),0)  + nvl(sum(MSUM_CTA_CTE),0) + nvl(sum(MSUM_VALE_CREDITO),0)              as Ztarjetacmr "
       End If
    sq = sq & "      ,nvl(sum(MREALES),0)            as Zreal  "
   
   '    "    ,nvl(sum(MSUM_TARJ_CMR),0)  + nvl(sum(MSUM_CTA_CTE),0) + nvl(sum(MSUM_VALE_CREDITO),0)             as Ztarjetacmr "
       '"    ,nvl(sum(MSUM_VALE_CREDITO),0)             as Ztarjetacmr "
       '
  Case "PER", "HTPE", "FAOR", "MAPE", "SOPE", "MPAM", "SPOR"
   sq = "   select " & _
       "     nvl(sum(REC_MEFECTIVO ),0)         as Zefectivo  " & _
       "    ,nvl(sum(REC_MCHEQUES),0)           as Zchequedia " & _
       "    ,nvl(sum(REC_MEFECTIVODOLAR ),0)    as Zdolares  " & _
       "    ,0                                  as Zeuros " & _
       "    ,nvl(sum(MREALES),0)                         as zreales " & _
       "    ,nvl(sum(MNC_AZUL),0)                         as zpesoarg " & _
       "    ,nvl(sum(REC_MVALECREDITO),0)       as Zchequefecha " & _
       "    ,nvl(sum(rec_mtarj),0)              as Ztarjeta" & _
       "    ,nvl(sum(REC_MCUPONES),0)           as Zticketpago " & _
       "    ,0                                  as Ztarjetacmr "
       
    
 Case "FACO"
      sq = "   select " & _
       "     nvl(sum(REC_MEFECTIVO   ),0)         as Zefectivo  " & _
       "    ,nvl(sum(REC_MCHKDIA  ),0)            as Zchequedia " & _
       "    ,0                                    as Zdolares  " & _
       "    ,0                                    as Zeuros " & _
       "    ,nvl(sum(MREALES),0)                         as zreales " & _
       "    ,nvl(sum(MNC_AZUL),0)                         as zpesoarg " & _
       "    ,nvl(sum(REC_MCHKFECHA),0)            as Zchequefecha " & _
       "    ,nvl(sum(rec_mtarj),0) +nvl(sum(rec_msodimac),0)            as Ztarjeta" & _
       "    ,0   as Zticketpago " & _
       "    ,0   as Ztarjetacmr  "
   
 
 Case Else
      sq = "   select " & _
       "     nvl(sum(REC_MEFECTIVO   ),0)         as Zefectivo  " & _
       "    ,nvl(sum(REC_MCHKDIA  ),0)            as Zchequedia " & _
       "    ,0                                    as Zdolares  " & _
       "    ,0                                    as Zeuros " & _
       "    ,nvl(sum(MREALES),0)                         as zreales " & _
       "    ,nvl(sum(MNC_AZUL),0)                         as zpesoarg " & _
       "    ,nvl(sum(REC_MCHKFECHA),0)            as Zchequefecha " & _
       "    ,nvl(sum(rec_mtarj),0)                as Ztarjeta" & _
       "    ,0                                    as Zticketpago " & _
       "    ,0                                    as Ztarjetacmr "
        
        
 End Select
 
 
  
    
    sq = sq & " From   vta_" & Flg_Pais$ & "libvta l, vta_" & Flg_Pais$ & "zzz r " & _
       " where  l.vta_tiporeg = '" & VL_TipoReg & "' " & _
       " and    l.vta_fecha_venta = to_date('" & Format(vfecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')"

If vcierrey <> "" And vcierrey <> "0" Then
       sq = sq & " and    l.vta_secuencia   =  " & vcierrey
End If
If vterminal <> "" And vterminal <> "0" Then
       sq = sq & " and    l.vta_terminal =   " & vterminal
End If
       sq = sq & " and    l.vta_local =   " & VLocal & _
       " and    l.vta_estado = 'A' " & _
       " and    l.vta_techkey = r.rec_techkey "
  
 
Call ValorZoY.Open(sq)
 
While Not ValorZoY.EOF
   
   
   ZZZefectivo = ZZZefectivo + ValorZoY.Fields(0)
   ZZZchequedia = ZZZchequedia + ValorZoY.Fields(1)
   ZZZdolares = ZZZdolares + ValorZoY.Fields(2)
   ZZZeuros = ZZZeuros + ValorZoY.Fields(3)
   ZReales = ZReales + ValorZoY.Fields("zreales").Value
   ZPesoArg = ZPesoArg + ValorZoY.Fields("zpesoarg").Value
   If Flg_Pais$ = "PER" Or Flg_Pais$ = "SOPE" Or Flg_Pais$ = "SPOR" Or Flg_Pais$ = "MAPE" Or Flg_Pais$ = "MPAM" Or Flg_Pais$ = "FAOR" Or Flg_Pais$ = "HTPE" Then
       ZZZchequefecha = ZZZchequefecha + IIf(CDbl(Format(vfecha, VG_Fecha_Peru)) < CDbl(VG_Fecha_Peru_Valid), 0, CDbl(ValorZoY.Fields(4)))
   Else
       ZZZchequefecha = ZZZchequefecha + ValorZoY.Fields(4)
   End If
   ZZZtarjeta = ZZZtarjeta + ValorZoY.Fields(5)
   ZZZticketpago = ZZZticketpago + ValorZoY.Fields(6)
   ZZZtarjetacmr = ZZZtarjetacmr + ValorZoY.Fields(7)
   
   ValorZoY.MoveNext
Wend
 

If ZZZefectivo <> Zefectivo Or ZZZchequedia <> Zchequedia Or ZZZdolares <> Zdolares Or ZZZeuros <> Zeuros Or ZZZchequefecha <> Zchequefecha Or ZZZtarjeta <> Ztarjeta Or ZZZticketpago <> Zticketpago Or ZZZtarjetacmr <> Ztarjetacmr Then
   FuncValorZ = False
End If

Set ValorZoY.ActiveConnection = Nothing
ValorZoY.Close
Exit Function

salir:
    
    Set ValorZoY.ActiveConnection = Nothing
    FuncValorZ = False
    SystemMsg = "Problemas de comunicación con servidor,Información del Z o Y "
    frmLogOraError.Show 1
    Exit Function
End Function


Public Function FuncEstadoLocal(ByVal vfecha As String, ByVal VLocal As String) As Integer
Dim VL_TipoReg As String

FuncEstadoLocal = 0
On Error GoTo salir
Set EstadoLocal = CreateObject("ADODB.Recordset")
With EstadoLocal
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With

If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
   VL_TipoReg = "Y"
   TipoCondi = "Y"
Else
   VL_TipoReg = ""
   TipoCondi = "F8"
End If

 
    sq = " Select /*+ ordered use_nl(l r t)*/ t.ter_estado  "
    sq = sq & " From   vta_" & Flg_Pais$ & "libvta l, vta_" & Flg_Pais$ & "zzz r  ,vta_" & Flg_Pais$ & "termstat" & VL_TipoReg & " t  " & _
       " where  l.vta_tiporeg     = '" & TipoCondi & "' " & _
       " and  ( t.ter_fecha >=  to_date('" & Format(DTPicker1.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')" & _
       " and    t.ter_fecha <=  to_date('" & Format(DTPicker2.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "')  ) " & _
       " and    l.vta_estado      = 'A'     " & _
       " and    l.vta_techkey     = r.rec_techkey  " & _
       " and    l.vta_fecha_venta = t.ter_fecha " & _
       " and    l.vta_local       = t.ter_local " & _
       " and    l.vta_terminal    = t.ter_terminal " & _
       " and    l.vta_local      = " & VLocal
   If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
    sq = sq & " and    l.vta_secuencia   = t.ter_cierrey "
   End If
    sq = sq & "  order by  t.ter_estado asc  "
 
Call EstadoLocal.Open(sq)
While Not EstadoLocal.EOF
   
  XEstado = EstadoLocal.Fields(0)
   
  Select Case XEstado
    Case 2
          FuncEstadoLocal = XEstado
    Case 1
          FuncEstadoLocal = XEstado
    Case Else
         FuncEstadoLocal = XEstado
         Set EstadoLocal.ActiveConnection = Nothing
         EstadoLocal.Close
         Exit Function
         ' -1 "Pendiente"
         '  0  "Pendiente"
         '  1 "Cerrado"
         '  2 "Impreso"
         '  3 "Sin Datos"
          
  End Select
   
   EstadoLocal.MoveNext
Wend
 

 
Set EstadoLocal.ActiveConnection = Nothing
EstadoLocal.Close
Exit Function

salir:
    
    Set EstadoLocal.ActiveConnection = Nothing
    FuncEstadoLocal = -1
    SystemMsg = "Problemas de comunicación con servidor,Información del estado de terminales"
    frmLogOraError.Show 1
    Exit Function
End Function
Private Sub GeneraExcel(ByVal Index As Integer)
Dim fec As String
Dim fecha As String
Dim NombreLocal As String
Dim N_Columna As Integer
Dim letraH, letraE, letraG, letraD As String

    Set apexcel = CreateObject("Excel.application")
    apexcel.Workbooks.Add
    Set newSheet = apexcel.Worksheets.Add
    newSheet.Name = "INFORME POR " & UCase(Trim(OptionInforme(Index).Caption))
    '
    '
    apexcel.Cells(1, 1).Value = "INFORME POR " & UCase(Trim(OptionInforme(Index).Caption))
 
   If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
      N_Columna = 0
   Else
      N_Columna = 1
   End If
      
 Select Case Index
 Case 0
      apexcel.Cells(3, 1).Value = "Fecha"
      apexcel.Cells(3, 2).Value = "Local"
      If (Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY") Then
      apexcel.Cells(3, 3).Value = "Vendedor"
      Else
      apexcel.Cells(3, 3).Value = "Terminal"
      End If
      'If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
      If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
        apexcel.Cells(3, 4).Value = "Cierre Y"
        apexcel.Cells(3, 5 - N_Columna).Value = "Dif. de Caja"
        apexcel.Cells(3, 6 - N_Columna).Value = "Compensación"
        apexcel.Cells(3, 7 - N_Columna).Value = "Dif. Real"
        apexcel.Cells(3, 8 - N_Columna).Value = "Estado"
      
      Else
      apexcel.Cells(3, 4).Value = "Dif. de Caja"
      apexcel.Cells(3, 5).Value = "Compensación"
      apexcel.Cells(3, 6).Value = "Dif. Real"
      apexcel.Cells(3, 7).Value = "Estado"
      apexcel.Cells(3, 9 - N_Columna).Value = "Fecha Cierre" '----Xintec sep 2025----
      End If
      'apexcel.cells(3, 5 - N_Columna).Value = "Dif. de Caja"
      'apexcel.cells(3, 6 - N_Columna).Value = "Compensación"
      'apexcel.cells(3, 7 - N_Columna).Value = "Dif. Real"
      'apexcel.cells(3, 8 - N_Columna).Value = "Estado"
 Case 1
      apexcel.Cells(3, 1).Value = "Fecha"
      apexcel.Cells(3, 2).Value = "Local"
      apexcel.Cells(3, 3).Value = "Dif. de Caja"
      apexcel.Cells(3, 4).Value = "Compensación"
      apexcel.Cells(3, 5).Value = "Dif. Real"
      apexcel.Cells(3, 6).Value = "Estado"
      apexcel.Cells(3, 7).Value = "Fecha Cierre" '----Xintec sep 2025----
      If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
         apexcel.Cells(3, 7).Value = "Diferncia entre la Sumatoria(Y) y Z"
      End If
Case 2
      apexcel.Cells(3, 1).Value = "Fecha"
      apexcel.Cells(3, 2).Value = "Local"
      apexcel.Cells(3, 3).Value = "Terminal"
      'If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
      If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
          apexcel.Cells(3, 4).Value = "Cierre Y"
      End If
      apexcel.Cells(3, 5 - N_Columna).Value = "Monto A Compensar(a)"
      apexcel.Cells(3, 6 - N_Columna).Value = "Monto Por Comp.  (b)"
      apexcel.Cells(3, 7 - N_Columna).Value = "Diferencia (a-b)"
      
End Select
    
   d = 3
   For i = 1 To Grid1.Rows - 1
       d = d + i
 Select Case Index
 Case 0
       
    apexcel.Cells(i + 3, 1).Value = " " & (Format(Trim(Grid1.TextMatrix(i, 0)), VgFormatoFechaLectura))
    apexcel.Cells(i + 3, 2).Value = Grid1.TextMatrix(i, 1)
    apexcel.Cells(i + 3, 3).Value = Grid1.TextMatrix(i, 2)
    'If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
    If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
        apexcel.Cells(i + 3, 4).Value = Grid1.TextMatrix(i, 3)
        apexcel.Cells(i + 3, 5 - N_Columna).Value = CDbl(Grid1.TextMatrix(i, 4))
        apexcel.Cells(i + 3, 6 - N_Columna).Value = CDbl(Grid1.TextMatrix(i, 5))
        apexcel.Cells(i + 3, 7 - N_Columna).Value = CDbl(Grid1.TextMatrix(i, 6))
        apexcel.Cells(i + 3, 8 - N_Columna).Value = (Grid1.TextMatrix(i, 7))
    
    Else
    apexcel.Cells(i + 3, 4).Value = CDbl(Grid1.TextMatrix(i, 4))
    apexcel.Cells(i + 3, 5).Value = CDbl(Grid1.TextMatrix(i, 5))
    apexcel.Cells(i + 3, 6).Value = CDbl(Grid1.TextMatrix(i, 6))
    apexcel.Cells(i + 3, 7).Value = (Grid1.TextMatrix(i, 7))
    apexcel.Cells(i + 3, 8).Value = (Grid1.TextMatrix(i, 8))  ' ----Xintec Sep 2025----
    End If
    'apexcel.cells(i + 3, 5 - N_Columna).Value = CDbl(Grid1.TextMatrix(i, 4))
    'apexcel.cells(i + 3, 6 - N_Columna).Value = CDbl(Grid1.TextMatrix(i, 5))
    'apexcel.cells(i + 3, 7 - N_Columna).Value = CDbl(Grid1.TextMatrix(i, 6))
    'apexcel.cells(i + 3, 8 - N_Columna).Value = (Grid1.TextMatrix(i, 7))
 Case 1
    apexcel.Cells(i + 3, 1).Value = " " & (Format(Trim(Grid1.TextMatrix(i, 0)), VgFormatoFechaLectura))
    apexcel.Cells(i + 3, 2).Value = Grid1.TextMatrix(i, 1)
    apexcel.Cells(i + 3, 3).Value = CDbl(Grid1.TextMatrix(i, 4))
    apexcel.Cells(i + 3, 4).Value = CDbl(Grid1.TextMatrix(i, 5))
    apexcel.Cells(i + 3, 5).Value = CDbl(Grid1.TextMatrix(i, 6))
    apexcel.Cells(i + 3, 6).Value = (Grid1.TextMatrix(i, 7))
    If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
         apexcel.Cells(i + 3, 7).Value = Grid1.TextMatrix(i, 3)
    End If
    apexcel.Cells(i + 3, 8 - N_Columna).Value = (Grid1.TextMatrix(i, 8))
 Case 2
   apexcel.Cells(i + 3, 1).Value = " " & (Format(Trim(Grid1.TextMatrix(i, 0)), VgFormatoFechaLectura))
    apexcel.Cells(i + 3, 2).Value = Grid1.TextMatrix(i, 1)
    apexcel.Cells(i + 3, 3).Value = Grid1.TextMatrix(i, 2)
    If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
       apexcel.Cells(i + 3, 4).Value = Grid1.TextMatrix(i, 3)
    End If
    
    apexcel.Cells(i + 3, 5 - N_Columna).Value = CDbl(Grid1.TextMatrix(i, 4))
    apexcel.Cells(i + 3, 6 - N_Columna).Value = CDbl(Grid1.TextMatrix(i, 5))
    apexcel.Cells(i + 3, 7 - N_Columna).Value = CDbl(Grid1.TextMatrix(i, 6))
    
   
 End Select
   Next i
   

   Select Case Index
    Case 0
         If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then letraH = "H" Else letraH = "H" 'G
         If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then letraE = "E" Else letraE = "D"
         If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then letraG = "G" Else letraG = "F"
         If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then letraD = "D" Else letraD = "C"
         
         apexcel.Range("A1:H1").Font.Color = RGB(0, 0, 0)
         apexcel.Range("A1:H1").Font.FontStyle = "Negrita"
         apexcel.Range("A3:" & letraH & "3").Interior.Color = RGB(255, 255, 255)
         apexcel.Range("A3:" & letraH & "3").Font.Color = RGB(0, 0, 0)
         apexcel.Range("A3:" & letraH & "3").Font.FontStyle = "Negrita"
         apexcel.Range("A3:" & letraH & "3").Borders.Color = RGB(0, 0, 0)
         apexcel.Range("A:A").Columns.Columnwidth = 10
         apexcel.Range("B:" & letraG & "").Columns.Columnwidth = 20
           
        
         apexcel.Rows("3:3").Select
         apexcel.Selection.HorizontalAlignment = -4108
         apexcel.Selection.VerticalAlignment = -4108
         apexcel.Selection.WrapText = True
         apexcel.Selection.RowHeight = 30
    
         apexcel.Range("" & letraE & ":" & letraG & "").NumberFormat = gFormat
         apexcel.Range("B:" & letraD & "").HorizontalAlignment = 3
         apexcel.Range("" & letraE & ":" & letraG & "").HorizontalAlignment = 4
         apexcel.Range("" & letraH & ":" & letraH & "").HorizontalAlignment = 3
         apexcel.Range("A3:" & letraH & "3").HorizontalAlignment = 3
          
    Case 1
    
         If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then letraH = "G" Else letraH = "H"
         If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then letraE = "E" Else letraE = "D"
         If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then letraG = "G" Else letraG = "G"
         If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then letraD = "D" Else letraD = "C"
         
         apexcel.Range("A1:" + letraH + "1").Font.Color = RGB(0, 0, 0)
         apexcel.Range("A1:" + letraH + "1").Font.FontStyle = "Negrita"
        
         apexcel.Range("A3:" + letraG + "3").Interior.Color = RGB(255, 255, 255)
         apexcel.Range("A3:" + letraG + "3").Font.Color = RGB(0, 0, 0)
         apexcel.Range("A3:" + letraG + "3").Font.FontStyle = "Negrita"
         apexcel.Range("A3:" + letraG + "3").Borders.Color = RGB(0, 0, 0)
         apexcel.Range("A:A").Columns.Columnwidth = 10
         apexcel.Range("B:D").Columns.Columnwidth = 20
           
        
         apexcel.Rows("3:3").Select
         apexcel.Selection.HorizontalAlignment = -4108
         apexcel.Selection.VerticalAlignment = -4108
         apexcel.Selection.WrapText = True
         apexcel.Selection.RowHeight = 30
    
         apexcel.Range("C:E").NumberFormat = gFormat
         apexcel.Range("B:D").HorizontalAlignment = 3
         apexcel.Range("F:" + letraG).HorizontalAlignment = 3
         apexcel.Range("C:E").HorizontalAlignment = 4

    Case 2
         If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then letraH = "H" Else letraH = "G"
         If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then letraE = "E" Else letraE = "D"
         If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then letraG = "G" Else letraG = "F"
         If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then letraD = "D" Else letraD = "C"
         apexcel.Range("A1:" & letraG & "1").Font.Color = RGB(0, 0, 0)
         apexcel.Range("A1:" & letraG & "1").Font.FontStyle = "Negrita"
        
         apexcel.Range("A3:" & letraG & "3").Interior.Color = RGB(255, 255, 255)
         apexcel.Range("A3:" & letraG & "3").Font.Color = RGB(0, 0, 0)
         apexcel.Range("A3:" & letraG & "3").Font.FontStyle = "Negrita"
         apexcel.Range("A3:" & letraG & "3").Borders.Color = RGB(0, 0, 0)
         apexcel.Range("A:A").Columns.Columnwidth = 10
         apexcel.Range("B:" & letraG & "").Columns.Columnwidth = 20
           
        
         apexcel.Rows("3:3").Select
         apexcel.Selection.HorizontalAlignment = -4108
         apexcel.Selection.VerticalAlignment = -4108
         apexcel.Selection.WrapText = True
         apexcel.Selection.RowHeight = 30
    
         apexcel.Range("" & letraE & ":" & letraG & "").NumberFormat = gFormat
         apexcel.Range("B:" & letraD & "").HorizontalAlignment = 3
         apexcel.Range("" & letraE & ":" & letraG & "").HorizontalAlignment = 4
         apexcel.Range("" & letraE & "3:" & letraG & "3").HorizontalAlignment = 3
   End Select
   apexcel.Visible = True
   apexcel.ActiveWindow.Zoom = 90
   Set apexcel = Nothing
   Screen.MousePointer = vbDefault

End Sub
Private Function LeeLocales() As String
Dim cod, nombre As String
 Set Consulta = CreateObject("ADODB.Recordset")
With Consulta
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With

   LeeLocales = "SI"
   sq = "select vta_cod_local " & _
        ",      vta_Alias " & _
        ",      vta_estado_local " & _
        ",      vta_grupo " & _
        "From   vta_" & Flg_Pais$ & "locales " & _
        "where  (vta_estado_local = 'V' or vta_estado_local = 'X') "
   If PERFILUSER < PERFIL_USER_TDO Then
      If PERFILUSER = PERFIL_USER_GRP Or PERFILUSER = PERFIL_JEFEUSER_GRP Then
            sq = sq & " and vta_grupo = " & LOCALUSER & " "
      Else
         sq = sq & " and vta_cod_local = " & LOCALUSER & " "
      End If
'   ElseIf PERFILUSER = PERFIL_JEFEUSER_LOCAL Or PERFILUSER = PERFIL_JEFEUSER_GRP Then
'      If PERFILUSER = PERFIL_JEFEUSER_GRP Then
'          sq = sq & " and vta_grupo = " & LOCALUSER & " "
'      Else ' PERFIL_JEFEUSER_GRP
'          sq = sq & " and vta_cod_local = " & LOCALUSER & " "
'      End If
'
   End If
   sq = sq + "order by vta_cod_local "
   
   On Error GoTo oraerror
   
   Call Consulta.Open(sq)
   
   
   '---INI---- xintec-nruz 20-10-2026 FSCC-12901: TODOS (al comienzo del combo) en FACO para perfiles 9 y 10 ----
   If Flg_Pais$ = "FACO" And (Val(PERFILUSER) = PERFIL_USER_ADM Or Val(PERFILUSER) = PERFIL_USER_DIEZ) Then
      cod = 0
      nombre = "TODOS"
      Combo1.AddItem Right("     " & cod, 5) & "-" & nombre
      Combo2.AddItem cod
   End If
   '---FIN---- xintec-nruz 20-10-2026 ----
   
   
   For i = 1 To Consulta.RecordCount
      cod = Consulta.Fields(0).Value
      nombre = Consulta.Fields(1).Value
      Combo1.AddItem Right("     " & cod, 5) & "-" & nombre
      Combo2.AddItem cod
      Consulta.MoveNext
   Next i
   Set Consulta.ActiveConnection = Nothing
   
   If Flg_Pais$ <> "SFCL" Then
   
   If PERFILUSER < PERFIL_USER_TDO Then
      If PERFILUSER = PERFIL_USER_GRP Or PERFILUSER = PERFIL_JEFEUSER_GRP Then
        cod = 0
        nombre = "TODOS LOS LOCALES"
        Combo1.AddItem Right("     " & cod, 5) & "-" & nombre
        Combo2.AddItem cod
        Combo2.Text = 0
      End If
   End If
   
   End If
   
  
   Combo1.ListIndex = Combo2.ListIndex
   
   Exit Function
oraerror:
   Set Consulta.ActiveConnection = Nothing
   SystemMsg = "No pudo Leer Datos del Local - Proceso Abortado"
   frmLogOraError.Show 1
   End
End Function
Private Function LeeTerminales() As String
Set Consulta = CreateObject("ADODB.Recordset")
With Consulta
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With
   Combo3.Clear
   
   sq = "select 0 as ter_terminal from dual union select ter_terminal " & _
        "From   vta_" & Flg_Pais$ & "terminales " & _
        "where  ter_local = '" & Combo2.Text & "' " & _
        "  and   (ter_fechabaja >= to_date('" & Format(FormVariable.DTPicker1.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "') or ter_fechabaja is null  )" & _
        "order by ter_terminal "
'        "and    ter_fechabaja >= to_date('" & Format(DTPicker1.Value, "yyyy/mm/dd") & "','yyyy/mm/dd') "
   
   On Error GoTo oraerror
   Call Consulta.Open(sq)
   
   
   
   For i = 1 To Consulta.RecordCount
      cod = Consulta.Fields(0).Value
      Combo3.AddItem cod
      Consulta.MoveNext
   Next i
   Combo3.ListIndex = 0
   Set Consulta.ActiveConnection = Nothing
   Exit Function
oraerror:
   Set Consulta.ActiveConnection = Nothing
   Combo3.AddItem 0
   Combo3.ListIndex = 0
End Function
'xintec NR 11-03-2019
Private Function LeeVendedor() As String
Set Consulta = CreateObject("ADODB.Recordset")
With Consulta
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With
   Combo3.Clear
   
   sq = "select 0 as vta_cod from dual union select vta_cod " & _
        "From   vta_" & Flg_Pais$ & "relvendedor " & _
        "where  vta_local = '" & Combo2.Text & "' " & _
        "  and   (ter_fechabaja >= to_date('" & Format(FormVariable.DTPicker1.Value, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "') or ter_fechabaja is null  )" & _
        "order by vta_cod "
'        "and    ter_fechabaja >= to_date('" & Format(DTPicker1.Value, "yyyy/mm/dd") & "','yyyy/mm/dd') "
   
   On Error GoTo oraerror
   Call Consulta.Open(sq)
   
   
   
   For i = 1 To Consulta.RecordCount
      cod = Consulta.Fields(0).Value
      Combo3.AddItem cod
      Consulta.MoveNext
   Next i
   Combo3.ListIndex = 0
   Set Consulta.ActiveConnection = Nothing
   Exit Function
oraerror:
   Set Consulta.ActiveConnection = Nothing
   Combo3.AddItem 0
   Combo3.ListIndex = 0
End Function


Public Function CierraTerminal(vl_FECHA As String, vl_LOCAL As String, vl_TERMINAL As String)
Dim tipovalidar As String
Dim menssaje As String
Dim Vl_MontoChequeDia, Vl_MontoChequeFec
Dim Vl_MontoChequeDiaTer, Vl_MontoChequeFecTer
Dim xd As Double

menssaje = ""


    menssaje = "Falta regularizar el Sobres No Enviado declarada, o elimine el registro "
    tipovalidar = "SN"
    
    If FuncvalidarConcepto(Trim(vl_FECHA), Trim(vl_LOCAL), Trim(vl_TERMINAL), tipovalidar, "") Then
       MsgBox menssaje, vbCritical, "Cierre de Terminal"
       Valida_Cierre_Arg = False
       Exit Function
    End If
       
    menssaje = "Falta regularizar Atesoramiento Fondo Fijo, o elimine el registro "
    tipovalidar = "AF"
    If FuncvalidarConcepto(Trim(vl_FECHA), Trim(vl_LOCAL), Trim(vl_TERMINAL), tipovalidar, "") Then
       MsgBox menssaje, vbCritical, "Cierre de Terminal"
       Valida_Cierre_Arg = False
       Exit Function
    End If
       
   menssaje = "Falta regularizar N/D no digitada declarada, o elimine el registro "
   tipovalidar = "ND"
   If FuncvalidarConcepto(Trim(vl_FECHA), Trim(vl_LOCAL), Trim(vl_TERMINAL), tipovalidar, "") Then
         MsgBox menssaje, vbCritical, "Cierre de Terminal"
         Valida_Cierre_Arg = False
      Exit Function
   End If
   
   
   menssaje = "Falta regularizar Factura no digitada declarada, o elimine el registro "
   tipovalidar = "FN"
   If FuncvalidarConcepto(Trim(vl_FECHA), Trim(vl_LOCAL), Trim(vl_TERMINAL), tipovalidar, "") Then
         MsgBox menssaje, vbCritical, "Cierre de Terminal"
         Valida_Cierre_Arg = False
      Exit Function
   End If
   
   menssaje = "Falta regularizar el N/C Publicidad declarada, o elimine el registro "
   tipovalidar = "NP"
   If FuncvalidarConcepto(Trim(vl_FECHA), Trim(vl_LOCAL), Trim(vl_TERMINAL), tipovalidar, "") Then
         MsgBox menssaje, vbCritical, "Cierre de Terminal"
         Valida_Cierre_Arg = False
      Exit Function
   End If
   
   
   menssaje = "Falta regularizar el Billete Falso declarada, o elimine el registro "
   tipovalidar = "BF"
  If FuncvalidarConcepto(Trim(vl_FECHA), Trim(vl_LOCAL), Trim(vl_TERMINAL), tipovalidar, "") Then
         MsgBox menssaje, vbCritical, "Cierre de Terminal"
         Valida_Cierre_Arg = False
      Exit Function
   End If
   
   
   menssaje = "Falta regularizar el Certificado Regalo declarada, o elimine el registro "
   tipovalidar = "CR"
   nombre = "Certificado Regalo"
   If FuncvalidarConcepto(Trim(vl_FECHA), Trim(vl_LOCAL), Trim(vl_TERMINAL), tipovalidar, "") Then
         MsgBox menssaje, vbCritical, "Cierre de Terminal"
         Valida_Cierre_Arg = False
      Exit Function
   End If
   
   
'   menssaje = "Falta regularizar la Tarjeta Convenio  declarada, o elimine el registro "
'   tipovalidar = "TC"
'   nombre = "Tarjeta Convenio"
'   If FuncvalidarConcepto(Trim(vl_fecha), Trim(vl_local), Trim(vl_terminal), tipovalidar) Then
'         MsgBox menssaje, vbCritical, "Cierre de Terminal"
'      Exit Function
'   End If

   menssaje = "Falta regularizar el carta aviso tienda declarada, o elimine el registro "
   tipovalidar = "CT"
   If FuncvalidarConcepto(Trim(vl_FECHA), Trim(vl_LOCAL), Trim(vl_TERMINAL), tipovalidar, "") Then
         MsgBox menssaje, vbCritical, "Cierre de Terminal"
         Valida_Cierre_Arg = False
      Exit Function
   End If
   
     
   menssaje = "Falta regularizar el carta aviso central  declarada, o elimine el registro "
   tipovalidar = "CA"
   If FuncvalidarConcepto(Trim(vl_FECHA), Trim(vl_LOCAL), Trim(vl_TERMINAL), tipovalidar, "") Then
         MsgBox menssaje, vbCritical, "Cierre de Terminal"
         Valida_Cierre_Arg = False
      Exit Function
   End If

   menssaje = "Falta regularizar la Diferencia Prestadora declarada, o elimine el registro "
   tipovalidar = "DP"
   If FuncvalidarConcepto(Trim(vl_FECHA), Trim(vl_LOCAL), Trim(vl_TERMINAL), tipovalidar, "") Then
         MsgBox menssaje, vbCritical, "Cierre de Terminal"
         Valida_Cierre_Arg = False
      Exit Function
   End If
   
   'If Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "CHI" Or Flg_Pais$ = "CMCL" Or Flg_Pais$ = "" Then
   'CK: 160531 Modificaciones F8 ARG
   'Flg_Pais$ = "ARG" Or
   If Flg_Pais$ = "CMCL" Then
     menssaje = "Error, existen diferencia en total tarjetas " + Label15.Caption + " <> " + Label51.Caption
   
     If CDbl(Label15.Caption) <> CDbl(Label51.Caption) Then
        MsgBox menssaje, vbCritical, "Cierre de Terminal"
       Exit Function
     End If
   End If
   
'   If CDbl(Grid1.TextMatrix(Grid1.RowSel, 6)) <> 0 Then
'      MsgBox "Falta Monto por Compensar", vbCritical, "Cierre de Terminal"
'      Exit Function
'   End If
   
      
   'If Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE" Or Flg_Pais$ = "SFCL" Then
   If Flg_Pais$ = "ARG" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE" Or Flg_Pais$ = "SFCL" Then
       If Not FuncValidarZSumaY(Trim(vl_FECHA), Trim(vl_LOCAL), Trim(vl_TERMINAL)) Then
           Valida_Cierre_Arg = False
           Exit Function
       End If
  
      If Not FuncValidadCierreyyyy(Trim(vl_FECHA), Trim(vl_LOCAL), Trim(vl_TERMINAL)) Then
'        If Not (Flg_Pais$ = "SFCL") Then
            Valida_Cierre_Arg = False
            Exit Function
'        End If
      End If
   End If
   If Flg_Pais$ = "PER" Or Flg_Pais$ = "SOPE" Or Flg_Pais$ = "SPOR" Or Flg_Pais$ = "MAPE" Or Flg_Pais$ = "MPAM" Or Flg_Pais$ = "FAOR" Or Flg_Pais$ = "HTPE" Or Flg_Pais$ = "FAOR" Then
        If Not ValidarCuadraturaZY(vl_FECHA, vl_LOCAL, vl_TERMINAL, " ") Then
           Exit Function
        End If
   End If
 If FuncBuscarOpcionCompensa(PERFILUSER, Btovalidacionzzz) Then
     menssaje = "Error, Z descuadrada, favor revisar... diferencia : "

   If Flg_Pais$ = "" Or Flg_Pais$ = "CHI" Or Flg_Pais$ = "CMCL" Then
       If Not TraeMontoValidacionZZZ(vl_FECHA, vl_LOCAL, vl_TERMINAL) Then
            menssaje = menssaje & FuncMontoValidaZZZ(vl_FECHA, vl_LOCAL, vl_TERMINAL)
            MsgBox menssaje, vbCritical, "Cierre de Terminal"
            Exit Function
       End If
   Else
            xd = FuncMontoValidaZZZ(vl_FECHA, vl_LOCAL, vl_TERMINAL)
            If xd <> 0 Then
                menssaje = menssaje & xd
                MsgBox menssaje, vbCritical, "Cierre de Terminal"
                Valida_Cierre_Arg = False
                Exit Function
            End If
            
   End If
   
End If
 If FuncBuscarOpcionCompensa(PERFILUSER, Btovalidacionprddolar) Then
    If FuncvalidarDifDolares(vl_FECHA, vl_LOCAL, vl_TERMINAL, 0) Then
        menssaje = " Error, existen diferencias entre los dólares declarados  y los dolares informado por Prosegur , favor revisar... diferencia "
        MsgBox menssaje, vbCritical, "Cierre de Terminal"
        Valida_Cierre_Arg = False
        Exit Function
    End If
 End If
   
   
 '  Call GrabaTesoreria
   
   On Error GoTo oraerror
   Set ConsultaCierre = CreateObject("ADODB.Recordset")
   With ConsultaCierre
      .ActiveConnection = Ado_Conn
      .CursorLocation = adUseClient
      .CursorType = adOpenForwardOnly
      .LockType = adLockReadOnly
   End With

   
   sq = "update vta_" & Flg_Pais$ & "termstat set ter_estado = '1' "
   sq = sq & ",      ter_cerradopor = '" & LOGINUSER & "' "
   
   If Flg_Pais$ = "" Or Flg_Pais$ = "CHI" Then
        sq = sq & ",      ter_fechacierre = sysdate"
   End If
   
   sq = sq & " where  ter_fecha = to_date('" & Format(vl_FECHA, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "') "
   sq = sq & " and    ter_local = " & vl_LOCAL & " "
   sq = sq & " and    ter_terminal = " & vl_TERMINAL & " "
   
   Call ConsultaCierre.Open(sq)
   swform3 = "NO"
   Valida_Cierre_Arg = True
   Set ConsultaCierre.ActiveConnection = Nothing
   Exit Function
oraerror:
   SystemMsg = "Actualizacion de estado no realizada"
   frmLogOraError.Show 1
End Function

Public Function UpdateCierreTerminalZYArg(vl_FECHA As String, vl_LOCAL As String, vl_TERMINAL As String)
   On Error GoTo oraerror
   Set ConsultaCierre = CreateObject("ADODB.Recordset")
   With ConsultaCierre
      .ActiveConnection = Ado_Conn
      .CursorLocation = adUseClient
      .CursorType = adOpenForwardOnly
      .LockType = adLockReadOnly
   End With

   
   sq = "update vta_" & Flg_Pais$ & "termstat set ter_estado = '-1' "
   sq = sq & ",      ter_cerradopor = ' ' "
   sq = sq & " where  ter_fecha = to_date('" & Format(vl_FECHA, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "') "
   sq = sq & " and    ter_local = " & vl_LOCAL & " "
   sq = sq & " and    ter_terminal = " & vl_TERMINAL & " "
   
   Call ConsultaCierre.Open(sq)
   Set ConsultaCierre.ActiveConnection = Nothing
   
   Set ConsultaCierreY = CreateObject("ADODB.Recordset")
   With ConsultaCierreY
      .ActiveConnection = Ado_Conn
      .CursorLocation = adUseClient
      .CursorType = adOpenForwardOnly
      .LockType = adLockReadOnly
   End With

   
   sqY = "update vta_" & Flg_Pais$ & "termstaty set ter_estado = '-1' "
   sqY = sqY & ",      ter_cerradopor = ' ' "
   sqY = sqY & " where  ter_fecha = to_date('" & Format(vl_FECHA, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "') "
   sqY = sqY & " and    ter_local = " & vl_LOCAL & " "
   sqY = sqY & " and    ter_terminal = " & vl_TERMINAL & " "
   
   Call ConsultaCierreY.Open(sqY)
   Set ConsultaCierreY.ActiveConnection = Nothing
   Exit Function
   
oraerror:
   SystemMsg = "Actualizacion de estado no realizada"
   frmLogOraError.Show 1
End Function

Public Function CierraTerminalArgSinY(vl_FECHA As String, vl_LOCAL As String, vl_TERMINAL As String)
Dim tipovalidar As String
Dim menssaje As String
Dim Vl_MontoChequeDia, Vl_MontoChequeFec
Dim Vl_MontoChequeDiaTer, Vl_MontoChequeFecTer
Dim xd As Double

menssaje = ""


    menssaje = "Falta regularizar el Sobres No Enviado declarada, o elimine el registro "
    tipovalidar = "SN"
    
    If FuncvalidarConcepto(Trim(vl_FECHA), Trim(vl_LOCAL), Trim(vl_TERMINAL), tipovalidar, "") Then
       MsgBox menssaje, vbCritical, "Cierre de Terminal"
       Valida_Cierre_Arg = False
       Exit Function
    End If
       
    menssaje = "Falta regularizar Atesoramiento Fondo Fijo, o elimine el registro "
    tipovalidar = "AF"
    If FuncvalidarConcepto(Trim(vl_FECHA), Trim(vl_LOCAL), Trim(vl_TERMINAL), tipovalidar, "") Then
       MsgBox menssaje, vbCritical, "Cierre de Terminal"
       Valida_Cierre_Arg = False
       Exit Function
    End If
       
   menssaje = "Falta regularizar N/D no digitada declarada, o elimine el registro "
   tipovalidar = "ND"
   If FuncvalidarConcepto(Trim(vl_FECHA), Trim(vl_LOCAL), Trim(vl_TERMINAL), tipovalidar, "") Then
         MsgBox menssaje, vbCritical, "Cierre de Terminal"
         Valida_Cierre_Arg = False
      Exit Function
   End If
   
   
   menssaje = "Falta regularizar Factura no digitada declarada, o elimine el registro "
   tipovalidar = "FN"
   If FuncvalidarConcepto(Trim(vl_FECHA), Trim(vl_LOCAL), Trim(vl_TERMINAL), tipovalidar, "") Then
         MsgBox menssaje, vbCritical, "Cierre de Terminal"
         Valida_Cierre_Arg = False
      Exit Function
   End If
   
   menssaje = "Falta regularizar el N/C Publicidad declarada, o elimine el registro "
   tipovalidar = "NP"
   If FuncvalidarConcepto(Trim(vl_FECHA), Trim(vl_LOCAL), Trim(vl_TERMINAL), tipovalidar, "") Then
         MsgBox menssaje, vbCritical, "Cierre de Terminal"
         Valida_Cierre_Arg = False
      Exit Function
   End If
   
   
   menssaje = "Falta regularizar el Billete Falso declarada, o elimine el registro "
   tipovalidar = "BF"
  If FuncvalidarConcepto(Trim(vl_FECHA), Trim(vl_LOCAL), Trim(vl_TERMINAL), tipovalidar, "") Then
         MsgBox menssaje, vbCritical, "Cierre de Terminal"
         Valida_Cierre_Arg = False
      Exit Function
   End If
   
   
   menssaje = "Falta regularizar el Certificado Regalo declarada, o elimine el registro "
   tipovalidar = "CR"
   nombre = "Certificado Regalo"
   If FuncvalidarConcepto(Trim(vl_FECHA), Trim(vl_LOCAL), Trim(vl_TERMINAL), tipovalidar, "") Then
         MsgBox menssaje, vbCritical, "Cierre de Terminal"
         Valida_Cierre_Arg = False
      Exit Function
   End If

   menssaje = "Falta regularizar el carta aviso tienda declarada, o elimine el registro "
   tipovalidar = "CT"
   If FuncvalidarConcepto(Trim(vl_FECHA), Trim(vl_LOCAL), Trim(vl_TERMINAL), tipovalidar, "") Then
         MsgBox menssaje, vbCritical, "Cierre de Terminal"
         Valida_Cierre_Arg = False
      Exit Function
   End If
   
     
   menssaje = "Falta regularizar el carta aviso central  declarada, o elimine el registro "
   tipovalidar = "CA"
   If FuncvalidarConcepto(Trim(vl_FECHA), Trim(vl_LOCAL), Trim(vl_TERMINAL), tipovalidar, "") Then
         MsgBox menssaje, vbCritical, "Cierre de Terminal"
         Valida_Cierre_Arg = False
      Exit Function
      
   End If

   menssaje = "Falta regularizar la Diferencia Prestadora declarada, o elimine el registro "
   tipovalidar = "DP"
   If FuncvalidarConcepto(Trim(vl_FECHA), Trim(vl_LOCAL), Trim(vl_TERMINAL), tipovalidar, "") Then
         MsgBox menssaje, vbCritical, "Cierre de Terminal"
         Valida_Cierre_Arg = False
      Exit Function
   End If
   
 If FuncBuscarOpcionCompensa(PERFILUSER, Btovalidacionzzz) Then
    menssaje = "Error, Z descuadrada, favor revisar... diferencia : "
    xd = FuncMontoValidaZZZ(vl_FECHA, vl_LOCAL, vl_TERMINAL)
    If xd <> 0 Then
        menssaje = menssaje & xd
        MsgBox menssaje, vbCritical, "Cierre de Terminal"
        Valida_Cierre_Arg = False
        Exit Function
    End If
   
End If
 If FuncBuscarOpcionCompensa(PERFILUSER, Btovalidacionprddolar) Then
    If FuncvalidarDifDolares(vl_FECHA, vl_LOCAL, vl_TERMINAL, 0) Then
        menssaje = " Error, existen diferencias entre los dólares declarados  y los dolares informado por Prosegur , favor revisar... diferencia "
        MsgBox menssaje, vbCritical, "Cierre de Terminal"
        Valida_Cierre_Arg = False
        Exit Function
    End If
 End If
   
   
 '  Call GrabaTesoreria
   
   On Error GoTo oraerror
   Set ConsultaCierre = CreateObject("ADODB.Recordset")
   With ConsultaCierre
      .ActiveConnection = Ado_Conn
      .CursorLocation = adUseClient
      .CursorType = adOpenForwardOnly
      .LockType = adLockReadOnly
   End With

   
   sq = "update vta_" & Flg_Pais$ & "termstat set ter_estado = '1' "
   sq = sq & ",      ter_cerradopor = '" & LOGINUSER & "' "
   If Flg_Pais$ = "" Then
        sq = sq & ",      ter_fechacierre = to_date(to_char(sysdate,'dd-mm-yyyy'),'dd-mm-yyyy')"
   End If
   
   sq = sq & " where  ter_fecha = to_date('" & Format(vl_FECHA, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "') "
   sq = sq & " and    ter_local = " & vl_LOCAL & " "
   sq = sq & " and    ter_terminal = " & vl_TERMINAL & " "
   
   Call ConsultaCierre.Open(sq)
   swform3 = "NO"
   Valida_Cierre_Arg = True
    Set ConsultaCierre.ActiveConnection = Nothing
   Exit Function
oraerror:
   SystemMsg = "Actualizacion de estado no realizada"
   frmLogOraError.Show 1
End Function

Private Function FuncvalidarDifDolares(ByVal pfecha As String, ByVal plocal As String, ByVal pterminal As String, ptipo As String) As Boolean
Dim monto2 As String

FuncvalidarDifDolares = False
Set ConsultaC = CreateObject("ADODB.Recordset")

With ConsultaC
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With

 
   FuncvalidarDifDolares = False
 sq = "     "
 sq = sq & "  select nvl(sum(a.monto),0)"
 sq = sq & "        ,nvl(sum(a.numero),0)"
 sq = sq & "  from ("
 sq = sq & "    select  sum(nvl(r.mex_cantidad,0)*-1) as monto"
 sq = sq & "       , (count(*)*-1) as numero"
 sq = sq & "       , 'RECMEX'"
 sq = sq & "    from vta_" & Flg_Pais$ & "RECMEX r"
 sq = sq & "   Where r.Mex_Fecha   = to_date('" & Format(pfecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "') "
 sq = sq & "    and r.Mex_Local    = " & plocal
 sq = sq & "    and r.Id_Mdareg    = 305 "
 sq = sq & "    and r.mex_terminal = " & pterminal
 sq = sq & "  Union "
 sq = sq & "    select  (SUM(P.PRV_MONTOSOBRE) + SUM(P.PRV_MONTODIF)) as monto"
 sq = sq & "            ,count(*) as numero"
 sq = sq & "            ,'PRD'"
 sq = sq & "    From vta_" & Flg_Pais$ & "prd p"
 sq = sq & "   where p.prv_fechavta = to_date('" & Format(pfecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "') "
 sq = sq & "    and  (p.prv_tiporec = 'DOL')"
 sq = sq & "    and p.prv_local     = " & plocal
 sq = sq & "    and p.prv_terminal  = " & pterminal
 sq = sq & "  ) a "
  
   On Error GoTo oraerror
   Call ConsultaC.Open(sq)
   If Not ConsultaC.EOF Then
       If ConsultaC.Fields(0).Value <> 0 Then
          FuncvalidarDifDolares = True
       End If
   End If
   
   
   Set ConsultaC.ActiveConnection = Nothing
   ConsultaC.Close
   Exit Function
oraerror:
   FuncvalidarDifDolares = True
   Set ConsultaC.ActiveConnection = Nothing
    
   SystemMsg = "No pudo Leer Datos de Consulta - Proceso Abortado"
   frmLogOraError.Show 1
     Exit Function
End Function

Private Function FuncValidadCierreyyyy(ByVal vfecha As String, ByVal VLocal As String, ByVal vterminal As String)
Dim Cierrey, estadoy As String
Dim VlColumna As Integer
 
FuncValidadCierreyyyy = False
Set Consulta = CreateObject("ADODB.Recordset")
With Consulta
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With

   
   sq = "select  l.vta_secuencia ,t.ter_estado  " & _
   "    " & _
   " From   vta_" & Flg_Pais$ & "libvta l, vta_" & Flg_Pais$ & "zzz r  ,vta_" & Flg_Pais$ & "termstaty t  " & _
   " where  l.vta_tiporeg     = 'Y' " & _
   " and    l.vta_fecha_venta = to_date('" & Format(vfecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "') " & _
   " and    l.vta_local       =   " & VLocal & _
   " and    l.vta_terminal    =  " & vterminal & _
   " and    l.vta_estado      = 'A'     " & _
   " and    l.vta_techkey     = r.rec_techkey  " & _
   " and    l.vta_fecha_venta =  t.ter_fecha " & _
   " and    l.vta_local       = t.ter_local " & _
   " and    l.vta_terminal    = t.ter_terminal " & _
   " and    l.vta_secuencia   = t.ter_cierrey "

   On Error GoTo oraerror
   
   Call Consulta.Open(sq)
   If Consulta.RecordCount = 0 Then
      FuncValidadCierreyyyy = True
      'MsgBox "Existen problema para traer informacón de los estados de los cierre  Y del terminal", vbCritical, Me.Caption
      Exit Function
   End If
   
   While Not Consulta.EOF
      Cierrey = Consulta.Fields(0).Value
      estadoy = Consulta.Fields(1).Value
       Select Case estadoy
         Case -1
            'Grid2.CellBackColor = &HFF&   'rojo
            'Grid2.CellForeColor = &H80000005   '&HFF&   'blanco
            FuncValidadCierreyyyy = False
            'MsgBox "No se puede cerrar el terminal, Porque se encuentra con estado Pendiente, el N° de cierre de Y : " & cierrey & " del terminal : " & vterminal, vbCritical, "Proceso de Cierre de terminal"
            Set Consulta.ActiveConnection = Nothing
            Exit Function
         Case 0
            FuncValidadCierreyyyy = False
            'MsgBox "No se puede cerrar el terminal, Porque se encuentra con estado Pendiente, el N° de cierre de Y : " & cierrey & " del terminal : " & vterminal, vbCritical, "Proceso de Cierre de terminal"
            Set Consulta.ActiveConnection = Nothing
            Exit Function
         Case 1
            FuncValidadCierreyyyy = True
         Case 2
            FuncValidadCierreyyyy = False
            'MsgBox "No se puede cerrar el terminal, Porque se encuentra con estado Impreso, el N° de cierre de Y : " & cierrey & " del terminal : " & vterminal, vbCritical, "Proceso de Cierre de terminal"
            Set Consulta.ActiveConnection = Nothing
            Exit Function
         Case 3
            FuncValidadCierreyyyy = False
            'MsgBox "No se puede cerrar el terminal, Porque se encuentra con estado Sin dato, el N° de cierre de Y  : " & cierrey & " del terminal : " & vterminal, vbCritical, "Proceso de Cierre de terminal"
            Set Consulta.ActiveConnection = Nothing
            Exit Function
      End Select
      Consulta.MoveNext
   Wend
   
   Set Consulta.ActiveConnection = Nothing
   Exit Function
oraerror:
   Set Consulta.ActiveConnection = Nothing
   SystemMsg = "No pudo Leer Datos del Local - Proceso Abortado"
   frmLogOraError.Show 1
   End
End Function

Private Function ConsultaCierreTerm(vl_FECHA As String, vl_LOCAL As String, vl_TERMINAL As String) As Boolean
   On Error GoTo oraerror
   Set cQuery = CreateObject("ADODB.Recordset")
   With cQuery
      .ActiveConnection = Ado_Conn
      .CursorLocation = adUseClient
      .CursorType = adOpenForwardOnly
      .LockType = adLockReadOnly
   End With
    ConsultaCierreTerm = True
   
   sq = "select * from vta_" & Flg_Pais$ & "termstat "
   sq = sq & " where  ter_fecha = to_date('" & Format(vl_FECHA, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "') "
   sq = sq & " and    ter_local = " & vl_LOCAL & " "
   sq = sq & " and    ter_terminal = " & vl_TERMINAL & " "
   sq = sq & " and    ter_estado = '1'  "
   
   Call cQuery.Open(sq)
    
   If cQuery.RecordCount = 0 Then
        ConsultaCierreTerm = False
   End If
    
   Set cQuery.ActiveConnection = Nothing
   Exit Function
oraerror:
   SystemMsg = "Actualizacion de estado no realizada"
   ConsultaCierreTerm = False
   frmLogOraError.Show 1
End Function

Public Function CierraTerminalYYY(xFecha As String, xlocal As String, Xterminal As String, Xcierrey As String)
Dim tipovalidar As String
Dim menssaje As String
Dim Vl_MontoChequeDia, Vl_MontoChequeFec
Dim Vl_MontoChequeDiaTer, Vl_MontoChequeFecTer

menssaje = ""
If Flg_Pais$ <> "FACO" Then
   Vl_MontoChequeDia = Format(Func_ValorGestionCheque(Trim(xFecha), Trim(xlocal), Trim(Xterminal), 2), gFormat)
End If
If Flg_Pais$ <> "HTPE" Then
   Vl_MontoChequeFec = Format(Func_ValorGestionCheque(Trim(xFecha), Trim(xlocal), Trim(Xterminal), 1), gFormat)
End If
If Flg_Pais$ <> "FACO" Then
   Vl_MontoChequeDiaTer = Format(Func_ValorChequeDia(Trim(xFecha), Trim(xlocal), Trim(Xterminal)), gFormat)
End If
If Flg_Pais$ <> "HTPE" Then
  Vl_MontoChequeFecTer = Format(Func_ValorChequeFecha(Trim(xFecha), Trim(xlocal), Trim(Xterminal)), gFormat)
End If

If Flg_Pais$ <> "FACO" And Flg_Pais$ <> "HTPE" And Flg_Pais$ <> "SFCL" Then
    menssaje = "Existe diferencia para el concepto cheques día entre la Gestión de Cheque : ( " & Vl_MontoChequeDia & " ) versus Cheques a fecha columna recaudación banco  : ( " & Vl_MontoChequeDiaTer & " ), para poder cerrar Y."
    If Vl_MontoChequeDia <> Vl_MontoChequeDiaTer Then
       MsgBox menssaje, vbCritical, "Cierre de Terminal"
       Exit Function
    End If
End If
If Flg_Pais$ <> "HTPE" And Flg_Pais$ <> "SFCL" Then
 ' menssaje = "Se debe ingresar el registro de documento en Gestión de Cheque, para poder cerrar Y."
  menssaje = "Existe diferencia para el concepto cheques a Fecha  entre la Gestión de Cheque : ( " & Vl_MontoChequeFec & " ) versus columna tesoreria : ( " & Vl_MontoChequeFecTer & " )  , para poder cerrar Y."
 If Vl_MontoChequeFec <> Vl_MontoChequeFecTer Then
       MsgBox menssaje, vbCritical, "Cierre de Terminal"
       Exit Function
 End If
End If

If Flg_Pais$ <> "FACO" And Flg_Pais$ <> "HTPE" And Flg_Pais$ <> "SFCL" Then
   menssaje = "Error en la Y Número = " & Trim(Xcierrey) & ", se encuentra descuadrado el total de venta versus  suma de métodos de pagos ."
   If Not FuncValidarZoY(Trim(xFecha), Trim(xlocal), Trim(Xterminal), Trim(Xcierrey)) Then
      MsgBox menssaje, vbCritical, "Cierre de Terminal"
      Exit Function
   End If
End If
   menssaje = ""


'   If lblEstado.Tag > 0 Then
'      MsgBox "Terminal ya se Encuentra Cerrado"
'      Exit Function
'   End If
 
   
   menssaje = "Falta regularizar el Sobres No Enviado declarada, o elimine el registro "
   tipovalidar = "SN"
   If FuncvalidarConcepto(Trim(xFecha), Trim(xlocal), Trim(Xterminal), tipovalidar, Trim(Xcierrey)) Then
         MsgBox menssaje, vbCritical, "Cierre de Terminal"
      Exit Function
   End If
   
   menssaje = "Falta regularizar Atesoramiento Fondo Fijo, o elimine el registro "
   tipovalidar = "AF"
   If FuncvalidarConcepto(Trim(xFecha), Trim(xlocal), Trim(Xterminal), tipovalidar, Trim(Xcierrey)) Then
         MsgBox menssaje, vbCritical, "Cierre de Terminal"
      Exit Function
   End If
   
   menssaje = "Falta regularizar N/D no digitada declarada, o elimine el registro "
   
   tipovalidar = "ND"
   If FuncvalidarConcepto(Trim(xFecha), Trim(xlocal), Trim(Xterminal), tipovalidar, Trim(Xcierrey)) Then
         MsgBox menssaje, vbCritical, "Cierre de Terminal"
      Exit Function
   End If
   
   menssaje = "Falta regularizar Factura no digitada declarada, o elimine el registro "
   tipovalidar = "FN"
   If FuncvalidarConcepto(Trim(xFecha), Trim(xlocal), Trim(Xterminal), tipovalidar, Trim(Xcierrey)) Then
         MsgBox menssaje, vbCritical, "Cierre de Terminal"
      Exit Function
   End If
   
   menssaje = "Falta regularizar el N/C Publicidad declarada, o elimine el registro "
   tipovalidar = "NP"
   If FuncvalidarConcepto(Trim(xFecha), Trim(xlocal), Trim(Xterminal), tipovalidar, Trim(Xcierrey)) Then
         MsgBox menssaje, vbCritical, "Cierre de Terminal"
      Exit Function
   End If
   
   
   menssaje = "Falta regularizar el Billete Falso declarada, o elimine el registro "
   tipovalidar = "BF"
  If FuncvalidarConcepto(Trim(xFecha), Trim(xlocal), Trim(Xterminal), tipovalidar, Trim(Xcierrey)) Then
         MsgBox menssaje, vbCritical, "Cierre de Terminal"
      Exit Function
   End If
   
   
   menssaje = "Falta regularizar el Certificado Regalo declarada, o elimine el registro "
   tipovalidar = "CR"
   nombre = "Certificado Regalo"
   If FuncvalidarConcepto(Trim(xFecha), Trim(xlocal), Trim(Xterminal), tipovalidar, Trim(Xcierrey)) Then
      MsgBox menssaje, vbCritical, "Cierre de Terminal"
      Exit Function
   End If
       
   menssaje = "Falta regularizar el carta aviso Tienda declarada, o elimine el registro "
   tipovalidar = "CT"
   If FuncvalidarConcepto(Trim(xFecha), Trim(xlocal), Trim(Xterminal), tipovalidar, Trim(Xcierrey)) Then
      MsgBox menssaje, vbCritical, "Cierre de Terminal"
      Exit Function
   End If
   
   menssaje = "Falta regularizar el carta aviso central  declarada, o elimine el registro "
   tipovalidar = "CA"
   If FuncvalidarConcepto(Trim(xFecha), Trim(xlocal), Trim(Xterminal), tipovalidar, Trim(Xcierrey)) Then
      MsgBox menssaje, vbCritical, "Cierre de Terminal"
      Exit Function
   End If
   
    menssaje = "Falta regularizar la Diferencia Prestadora declarada, o elimine el registro "
   tipovalidar = "DP"
   If FuncvalidarConcepto(Trim(xFecha), Trim(xlocal), Trim(Xterminal), tipovalidar, Trim(Xcierrey)) Then
         MsgBox menssaje, vbCritical, "Cierre de Terminal"
      Exit Function
   End If
   'CK: 160531 Modificaciones F8 ARG
   'Flg_Pais$ = "ARG" Or
   If (Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "CHI" Or Flg_Pais$ = "CMCL" Or Flg_Pais$ = "") Then
     menssaje = "Error, existen diferencia en total tarjetas " + Label15.Caption + " <> " + Label51.Caption
     
     If CDbl(Label15.Caption) <> CDbl(Label51.Caption) Then
       MsgBox menssaje, vbCritical, "Cierre de Terminal"
       Exit Function
     End If
   End If
   
'   If CDbl(Grid1.TextMatrix(Grid1.RowSel, 6)) <> 0 Then
'      MsgBox "Falta Monto por Compensar", vbCritical, "Cierre de Terminal"
'      Exit Function
'   End If
   
   
   If Flg_Pais$ = "PER" Or Flg_Pais$ = "SOPE" Or Flg_Pais$ = "SPOR" Or Flg_Pais$ = "MAPE" Or Flg_Pais$ = "MPAM" Or Flg_Pais$ = "FAOR" Or Flg_Pais$ = "HTPE" Then
        If Not ValidarCuadraturaZY(xFecha, xlocal, Xterminal, Xcierrey) Then
           Exit Function
        End If
   End If
   If Flg_Pais$ = "SFCL" Then
      menssaje = "Error, Y descuadrada, favor revisar... diferencia : "
      xd = FuncMontoValidaZZZYY(xFecha, xlocal, Xterminal, Xcierrey)
            If xd <> 0 Then
                menssaje = menssaje & xd
                MsgBox menssaje, vbCritical, "Cierre de Terminal"
                Exit Function
            End If
   ElseIf FuncBuscarOpcionCompensa(PERFILUSER, Btovalidacionzzz) Then
      menssaje = "Error, Y descuadrada, favor revisar... diferencia : "
      xd = FuncMontoValidaZZZYY(xFecha, xlocal, Xterminal, xlocal)
            If xd <> 0 Then
                menssaje = menssaje & xd
                MsgBox menssaje, vbCritical, "Cierre de Terminal"
                Exit Function
            End If
   End If
   
'   msg = "¿Esta seguro de realizar el cierre del Y N° : " & xCierreY & ", para este Terminal ? "
'   Estilo = vbYesNo + vbQuestion + vbDefaultButton1
'   respuesta = MsgBox(msg, Estilo, "Confirma Cierre")
'   If respuesta = vbNo Then Exit Function
   
   
 '  Call GrabaTesoreria
   
   On Error GoTo oraerror
   Set ConsultaCierre = CreateObject("ADODB.Recordset")
   With ConsultaCierre
      .ActiveConnection = Ado_Conn
      .CursorLocation = adUseClient
      .CursorType = adOpenForwardOnly
      .LockType = adLockReadOnly
   End With


   
   sq = "update vta_" & Flg_Pais$ & "termstaty set ter_estado = '1' " & _
        ",      ter_cerradopor = '" & LOGINUSER & "' " & _
        "where  ter_fecha = to_date('" & Format(xFecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "') " & _
        "and    ter_local = " & xlocal & " " & _
        "and    ter_terminal = " & Xterminal & " " & _
        "and    ter_cierrey = " & Xcierrey & " "
        
   Call ConsultaCierre.Open(sq)
   swform3 = "NO"
    Set ConsultaCierre.ActiveConnection = Nothing

   Exit Function
oraerror:
   SystemMsg = "Actualizacion de estado no realizada"
   frmLogOraError.Show 1
End Function


Private Function FuncvalidarConcepto(ByVal pfecha As String, ByVal plocal As String, ByVal pterminal As String, ptipo As String, ByVal pcierrey As String) As Boolean
Dim monto2 As String

FuncvalidarConcepto = False
Set ConsultaC = CreateObject("ADODB.Recordset")

With ConsultaC
    .ActiveConnection = Ado_Conn
    .CursorLocation = adUseClient
    .CursorType = adOpenForwardOnly
    .LockType = adLockReadOnly
End With

  'sq = " Select  mov_techkey from  vta_" & Flg_Pais$ & "movdet    " &
  sq = " Select  " & IIf(ptipo = "CA" And (Flg_Pais$ = "SFCL" Or Flg_Pais$ = "" Or Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "CHI" Or Flg_Pais$ = "CMCL" Or Flg_Pais$ = "KFCL" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "FACO"), "mov_fecha", "mov_techkey") & "  " & _
       " from  vta_" & Flg_Pais$ & IIf(ptipo = "CA" And (Flg_Pais$ = "" Or Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "CHI" Or Flg_Pais$ = "CMCL" Or Flg_Pais$ = "KFCL" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "SFCL"), "cartaaviso", "movdet") & _
       " Where   mov_fecha  = to_date('" & Format(pfecha, VgFormatoFechaWhere) & "','" & VgFormatoFechaWhere & "') " & _
       " and    mov_local = " & plocal & " " & _
       " and    mov_terminal = " & pterminal & " " & _
       " and (mov_regul  is null or mov_regul =' ' or mov_regul ='N' or mov_regul ='' )   " & _
       " and mov_tipomov = '" & ptipo & "' "
   
   If Trim(pcierrey) <> "" Then
       sq = sq & " and mov_cierrey = " & pcierrey
   End If
       
  If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY") And (ptipo = "CR" Or ptipo = "PC") Then
    sq = sq & "   and ( mov_vb = 's' or      mov_vb = 'S' )"
  End If
  ' If ptipo = "TC" Then
     'sq = sq & " and ( mov_vb is null or  mov_vb ='' or mov_vb ='N' or mov_vb = ' '  )  "
  ' End If
   
   
   On Error GoTo oraerror
   Call ConsultaC.Open(sq)
   If Not ConsultaC.EOF Then
       If ConsultaC.RecordCount > 0 Then
          FuncvalidarConcepto = True
       End If
   End If
   
   
   Set ConsultaC.ActiveConnection = Nothing
   ConsultaC.Close
   Exit Function
oraerror:
   FuncvalidarConcepto = True
   Set ConsultaC.ActiveConnection = Nothing
    
   SystemMsg = "No pudo Leer Datos de Consulta - Proceso Abortado"
   frmLogOraError.Show 1
     Exit Function
End Function


Private Sub definegrid(Index As Integer)
Grid1.Clear
Dim suma As Integer

If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
   suma = 0
Else
   suma = 400
End If
Select Case Index
Case 0
   
   Grid1.Cols = 9 '8 '----Xintec Sep 2025----
   Grid1.Rows = 1
   Grid1.RowHeight(0) = 500
      
   Grid1.ColWidth(0) = 1200 + suma
   Grid1.ColWidth(1) = 1200 + suma
   Grid1.ColWidth(2) = 1200 + suma
   'If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
   If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
      Grid1.ColWidth(3) = 1200
   Else
      Grid1.ColWidth(3) = 0
   End If
   Grid1.ColWidth(4) = 2400
   Grid1.ColWidth(5) = 2400
   Grid1.ColWidth(6) = 2400
   Grid1.ColWidth(7) = 1300
   Grid1.ColWidth(8) = 2000 '----Xintec Sep 2025----
   
   Grid1.ColAlignment(0) = 4
   Grid1.ColAlignment(1) = 4
   Grid1.ColAlignment(2) = 4
   Grid1.ColAlignment(3) = 4
   Grid1.ColAlignment(4) = 4
   Grid1.ColAlignment(8) = 4 '----Xintec Sep 2025----
   
   Grid1.FixedAlignment(0) = 4
   Grid1.FixedAlignment(1) = 4
   Grid1.FixedAlignment(2) = 4
   Grid1.FixedAlignment(3) = 4
   Grid1.FixedAlignment(4) = 4
   Grid1.FixedAlignment(5) = 4
   Grid1.FixedAlignment(6) = 4
   Grid1.FixedAlignment(7) = 4
   Grid1.FixedAlignment(8) = 4 '----Xintec Sep 2025----
   
   Grid1.TextMatrix(0, 0) = "Fecha"
   Grid1.TextMatrix(0, 1) = "Local"
   'Grid1.TextMatrix(0, 2) = "Terminal"
   'If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
   If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then ' Se quita Cierre Y para uruguay
      Grid1.TextMatrix(0, 2) = "Terminal"
      Grid1.TextMatrix(0, 3) = "Cierre Y"
   Else
      If (Flg_Pais$ = "" Or Flg_Pais$ = "CHI") Then
      Grid1.TextMatrix(0, 2) = "Terminal"
      Grid1.TextMatrix(0, 3) = ""
      Else
      Grid1.TextMatrix(0, 2) = "Vendedor"
      Grid1.TextMatrix(0, 3) = ""
      End If
   End If
   Grid1.TextMatrix(0, 4) = "Dif. de Caja"
   Grid1.TextMatrix(0, 5) = "Compensación"
   Grid1.TextMatrix(0, 6) = "Dif. Real"
   Grid1.TextMatrix(0, 7) = "Estado"
   Grid1.TextMatrix(0, 8) = "Fecha Cierre" '----Xintec Sep 20205----
Case 1
   Grid1.Cols = 9 '8 '----Xintec Sep 20205----
   Grid1.Rows = 1
   Grid1.RowHeight(0) = 500
   
   Grid1.ColWidth(0) = 1500
   Grid1.ColWidth(1) = 1500
   Grid1.ColWidth(2) = 0
   If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
   Grid1.ColWidth(3) = 2700
   Grid1.ColWidth(4) = 2100
   Grid1.ColWidth(5) = 2100
   Grid1.ColWidth(6) = 2100
   
   Else
   Grid1.ColWidth(3) = 0
   Grid1.ColWidth(4) = 2900
   Grid1.ColWidth(5) = 2900
   Grid1.ColWidth(6) = 2900
   
   End If
   Grid1.ColWidth(7) = 1500
   Grid1.ColWidth(8) = 1300 '----Xintec Sep 20205----
   Grid1.ColAlignment(0) = 4
   Grid1.ColAlignment(1) = 4
   Grid1.ColAlignment(2) = 4
   Grid1.ColAlignment(3) = 4
   Grid1.ColAlignment(4) = 4
   Grid1.ColAlignment(8) = 4 '----Xintec Sep 2025----
   
   Grid1.FixedAlignment(0) = 4
   Grid1.FixedAlignment(1) = 4
   Grid1.FixedAlignment(2) = 4
   Grid1.FixedAlignment(3) = 4
   Grid1.FixedAlignment(4) = 4
   Grid1.FixedAlignment(5) = 4
   Grid1.FixedAlignment(6) = 4
   Grid1.FixedAlignment(7) = 4
   Grid1.FixedAlignment(8) = 4 '----Xintec Sep 20205----
   Grid1.TextMatrix(0, 0) = "Fecha"
   Grid1.TextMatrix(0, 1) = "Local"
   Grid1.TextMatrix(0, 3) = "Dif. Sumatoria(Y) y Z"
   Grid1.TextMatrix(0, 4) = "Dif. de Caja"
   Grid1.TextMatrix(0, 5) = "Compensación"
   Grid1.TextMatrix(0, 6) = "Dif. Real"
   Grid1.TextMatrix(0, 7) = "Estado"
   Grid1.TextMatrix(0, 8) = "Fecha Cierre" '----Xintec Sep 20205----
Case 2

  Grid1.Cols = 9 ' 8'----Xintec Sep 20205----
   Grid1.Rows = 1
   Grid1.RowHeight(0) = 500
   
   Grid1.ColWidth(0) = 1300 + suma
   Grid1.ColWidth(1) = 1300 + suma
   Grid1.ColWidth(2) = 1300 + suma
   
   If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
      Grid1.ColWidth(3) = 1300
   Else
      Grid1.ColWidth(3) = 0
   End If
   Grid1.ColWidth(4) = 2700
   Grid1.ColWidth(5) = 2500
   Grid1.ColWidth(6) = 2200
   Grid1.ColWidth(7) = 1000
   Grid1.ColWidth(8) = 1300 '----Xintec Sep 20205----
   Grid1.ColAlignment(0) = 4
   Grid1.ColAlignment(1) = 4
   Grid1.ColAlignment(2) = 4
   Grid1.ColAlignment(3) = 4
   Grid1.ColAlignment(4) = 4
   Grid1.ColAlignment(8) = 4 '----Xintec Sep 2025----
   
   Grid1.FixedAlignment(0) = 4
   Grid1.FixedAlignment(1) = 4
   Grid1.FixedAlignment(2) = 4
   Grid1.FixedAlignment(3) = 4
   Grid1.FixedAlignment(4) = 4
   Grid1.FixedAlignment(5) = 4
   Grid1.FixedAlignment(6) = 4
   Grid1.FixedAlignment(7) = 4
   Grid1.FixedAlignment(8) = 4 '----Xintec Sep 20205----
   
   Grid1.TextMatrix(0, 0) = "Fecha"
   Grid1.TextMatrix(0, 1) = "Local"
   Grid1.TextMatrix(0, 2) = "Terminal"
      'If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SOAR" Or Flg_Pais$ = "SOUY" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
   If (Flg_Pais$ = "ARG" Or Flg_Pais$ = "SFCL" Or Flg_Pais$ = "FACO" Or Flg_Pais$ = "HTPE") Then
      Grid1.TextMatrix(0, 2) = "Terminal"
      Grid1.TextMatrix(0, 3) = "Cierre Y"
   Else
      If (Flg_Pais$ = "" Or Flg_Pais$ = "CHI") Then
      Grid1.TextMatrix(0, 2) = "Terminal"
      Grid1.TextMatrix(0, 3) = ""
      Else
      Grid1.TextMatrix(0, 2) = "Vendedor"
      Grid1.TextMatrix(0, 3) = ""
      End If
   End If
   
   Grid1.TextMatrix(0, 4) = "Monto A Compensar(a)"
   Grid1.TextMatrix(0, 5) = "Monto Por Comp.  (b)"
   Grid1.TextMatrix(0, 6) = "Diferencia (a-b)"
   Grid1.TextMatrix(0, 7) = "Estado"
   Grid1.TextMatrix(0, 8) = "Fecha Cierre" '----Xintec Sep 20205----
End Select
End Sub

Private Sub OptionInforme_Click(Index As Integer)
VF_NumInforme = Index
If Frame1.Enabled = False Then
    Frame1.Enabled = True
End If
Select Case Index
Case (1)
   Combo2.ListIndex = 0
   Combo1.ListIndex = Combo2.ListIndex
   Combo1.Visible = False
   Labellocal.Visible = False
    Combo3.Visible = False
    Labelterminal.Visible = False
    Command4.Visible = False
    
Case (2)
    Combo1.Visible = True
    Labellocal.Visible = True
    Combo3.Visible = False
    Labelterminal.Visible = False
    Command4.Visible = False
    
Case Else
   If Command4.Visible = False Then
      Combo1.Visible = True
      Labellocal.Visible = True
      Combo3.Visible = True
      Labelterminal.Visible = True
      Command4.Visible = True
    
   End If

End Select
Call definegrid(Index)
End Sub


