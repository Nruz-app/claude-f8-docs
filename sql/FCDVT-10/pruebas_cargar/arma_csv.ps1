# =====================================================================
# FCDVT-10 (HU-03) - Carga masiva de cierres Y/Z de Tottus Chile (SFCL)
# arma_csv.ps1: genera los CSV de prueba de la carpeta (s01 a s09)
# con el encabezado REAL de VTA_PAINT_Z (encabezado.txt) y valida que
# cada terminal-dia cuadre (Z = suma de las Y) y que la formula de la Z
# de 0 (fn_sql_valida_z, reconstruida desde paint_z_sfcl.csv).
#
# Entradas (las trae el ticket, no se editan a mano):
#   encabezado.txt    - salida de
#                       PKG_F8_CARGA_MASIVA_YZ_SFCL.fn_encabezado('SFCL')
#                       (11 columnas de identificacion + 63 conceptos, 74 en total)
#   paint_z_sfcl.csv  - VTA_PAINT_Z de SFCL en orden vta_order_z
#                       (FILA;VTA_CMP_ASOC;VTA_POP_UP;VTA_VALIDADORZZZ;VTA_SIGNO;VTAGLOSA_Z)
#
# Uso (desde esta carpeta):
#   powershell -ExecutionPolicy Bypass -File .\arma_csv.ps1
#   powershell -ExecutionPolicy Bypass -File .\arma_csv.ps1 -Local 116 `
#       -FechaA 17-11-2026 -TermA 1,5,6 -FechaB 16-11-2026 -TermB 1,4,5,6 `
#       -TermReemp 7 -TermNum 8 -TermZSinY 7 -TermErr 8
#
# Solo biblioteca estandar de PowerShell 5.1. No se conecta a la base.
# Los CSV se escriben en ASCII con CRLF (como los de FCDVT-14).
# =====================================================================
[CmdletBinding()]
param(
    [int]$Local = 116,
    [string]$FechaA = '17-11-2026',
    [int[]]$TermA = @(1, 5, 6),      # s01: T1; s02: T5, T6
    [string]$FechaB = '16-11-2026',
    [int[]]$TermB = @(1, 4, 5, 6),   # s03: OK, descuadre, vendedor, NRO_Y 99
    [int]$TermReemp = 7,             # s04/s05 (FechaA)
    [int]$TermNum   = 8,             # s06 (FechaA)
    [int]$TermZSinY = 7,             # s08 (FechaB)
    [int]$TermErr   = 8,             # s09 formula de la Z (FechaB)
    [string]$Salida = $PSScriptRoot
)

$ErrorActionPreference = 'Stop'
$enc1252 = [System.Text.Encoding]::GetEncoding(1252)

if ($TermA.Count -ne 3) { throw 'TermA debe traer 3 terminales (s01 y las dos de s02)' }
if ($TermB.Count -ne 4) { throw 'TermB debe traer 4 terminales (s03)' }
$usadosA = @($TermA[0], $TermA[1], $TermA[2], $TermReemp, $TermNum) | Sort-Object -Unique
if ($usadosA.Count -ne 5) { throw 'En FechaA los terminales deben ser distintos: TermA, TermReemp y TermNum' }
$usadosB = @($TermB[0], $TermB[1], $TermB[2], $TermB[3], $TermZSinY, $TermErr) | Sort-Object -Unique
if ($usadosB.Count -ne 6) { throw 'En FechaB los terminales deben ser distintos: TermB, TermZSinY y TermErr' }
if ($Salida -eq '') { $Salida = (Get-Location).Path }

# ---------------------------------------------------------------------
# Encabezado (autoritativo, viene de fn_encabezado)
# ---------------------------------------------------------------------
$rutaEnc = Join-Path $Salida 'encabezado.txt'
$encabezado = ([System.IO.File]::ReadAllText($rutaEnc, $enc1252)).Trim()
$cols = $encabezado.Split(';')
$nCampos = $cols.Count
$idCols = $cols[0..10]
$csvCols = $cols[11..($nCampos - 1)]
$ventaCols = $csvCols[0..4]
$colPago = 'REC_MEFECTIVO'
if ($ventaCols[0] -ne 'VTA_MONTOBOL') { throw ('La columna 12 deberia ser VTA_MONTOBOL, es ' + $ventaCols[0]) }
if (($csvCols -notcontains $colPago)) { throw ('El encabezado no trae ' + $colPago) }
if (($csvCols -notcontains 'REC_MTRANSBANK')) { throw 'El encabezado no trae REC_MTRANSBANK (s09)' }

Write-Output ('Encabezado: {0} columnas ({1} de identificacion + {2} conceptos).' -f $nCampos, $idCols.Count, $csvCols.Count)
if ($nCampos -ne 74) { Write-Output ('AVISO: el encabezado no tiene 74 columnas; revisar antes de cargar.') }

# ---------------------------------------------------------------------
# VTA_PAINT_Z: conceptos del CSV y formula de la Z (grupos 1 a 7)
# ---------------------------------------------------------------------
$rutaPaint = Join-Path $Salida 'paint_z_sfcl.csv'
if (-not (Test-Path $rutaPaint)) { throw ('No existe ' + $rutaPaint) }
$paint = @()
$num = 0
foreach ($l in [System.IO.File]::ReadAllLines($rutaPaint, $enc1252)) {
    if ($l.Trim() -eq '' -or $l -like 'FILA;VTA_CMP_ASOC*') { continue }
    $f = $l.Split(';')
    if ($f.Count -lt 6) { throw ('Linea de paint_z_sfcl.csv con ' + $f.Count + ' campos: ' + $l) }
    $num++
    $paint += [pscustomobject]@{
        fila  = [int]$f[0]
        col   = $f[1].Trim().ToUpper()
        pop   = [int]$f[2]
        vld   = [int]$f[3]
        signo = $(if ($f[4].Trim() -eq '-') { -1 } else { 1 })
        glosa = $f[5].Trim()
    }
}
if ($num -lt 7) { throw ('paint_z_sfcl.csv tiene ' + $num + ' filas: faltan los conceptos de SFCL') }

$formula = @()
foreach ($p in $paint) {
    if ($p.vld -ge 1 -and $p.vld -le 7 -and $p.col -ne '') {
        $formula += $p
    }
}
if ($formula.Count -eq 0) { throw ('paint_z_sfcl.csv no trae formula de la Z (vta_validadorzzz)') }

# Encabezado que arma prc_config: filas 2 a 6 + conceptos de VTA_SFCLZZZ
# (fila > 7 con vta_pop_up 0 y columna que no empieza con VTA_, o MVTA_).
$concPaint = @()
foreach ($p in $paint) {
    if ($p.fila -ge 2 -and $p.fila -le 6) {
        if ($p.pop -ne 0 -or $p.col -eq '' -or -not $p.col.StartsWith('VTA_')) {
            throw ('VTA_PAINT_Z fila {0} ({1}) no es concepto de venta' -f $p.fila, $p.glosa)
        }
        $concPaint += $p.col
    } elseif ($p.fila -eq 7) {
        if ($p.pop -ne 3) { throw ('VTA_PAINT_Z fila 7 ({0}) no es el total de venta' -f $p.glosa) }
    } elseif ($p.fila -gt 7 -and $p.pop -eq 0 -and $p.col -ne '') {
        $esZzz = (-not $p.col.StartsWith('VTA_')) -or $p.col.StartsWith('MVTA_')
        if ($esZzz) { $concPaint += $p.col }
    }
}
$encPaint = (($idCols + $concPaint) -join ';')
if ($encPaint -cne $encabezado) {
    throw ("encabezado.txt no coincide con VTA_PAINT_Z (paint_z_sfcl.csv).`n  paint : $encPaint`n  real  : $encabezado")
}
Write-Output 'Encabezado verificado contra paint_z_sfcl.csv.'

function Get-DifFormula([hashtable]$montos) {
    $g = @(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
    foreach ($t in $formula) {
        # Los conceptos que no van en el CSV (vta_pop_up 3) se graban en 0;
        # los montos solo traen las columnas del CSV, asi que el resto es 0.
        $v = 0.0
        if ($montos.ContainsKey($t.col)) { $v = [double]$montos[$t.col] }
        $g[$t.vld] += $t.signo * $v
    }
    return $g[7] - $g[6] - $g[5] - $g[4] - $g[3] - $g[2] - $g[1]
}

# ---------------------------------------------------------------------
# Armado de filas
# ---------------------------------------------------------------------
function New-Fila {
    param(
        [string]$Caso,
        [string]$Fecha,
        [int]$Terminal,
        $NroY,           # $null o '' = vacio
        [string]$Hora,
        [int]$Secuencia,
        [int]$Boleta,
        [long]$Vendedor,
        [int]$ContRepo,
        [string]$Tipo,
        [int]$Monto,
        [hashtable]$Otros = @{}
    )
    $m = @{}
    foreach ($c in $csvCols) { $m[$c] = 0 }
    $m['VTA_MONTOBOL'] = $Monto
    $m[$colPago] = $Monto
    foreach ($k in $Otros.Keys) {
        if ($csvCols -notcontains $k) { throw ('La columna ' + $k + ' no esta en el encabezado') }
        $m[$k] = $Otros[$k]
    }
    $ident = @(
        $Fecha,
        [string]$Local,
        [string]$Terminal,
        $(if ($null -eq $NroY) { '' } else { [string]$NroY }),
        $Hora,
        [string]$Secuencia,
        [string]$Boleta,
        [string]$Vendedor,
        [string]$ContRepo,
        $Tipo,
        'INGRESAR'
    )
    $valores = @()
    foreach ($c in $csvCols) { $valores += [string]$m[$c] }
    return [pscustomobject]@{
        Caso    = $Caso
        Fecha   = $Fecha
        Local   = $Local
        Terminal = $Terminal
        Tipo    = $Tipo
        NroY    = $NroY
        Total   = ($m[$ventaCols[0]] + $m[$ventaCols[1]] + $m[$ventaCols[2]] + $m[$ventaCols[3]] + $m[$ventaCols[4]])
        Dif     = (Get-DifFormula $m)
        Linea   = (($ident + $valores) -join ';')
    }
}

function New-FilaMod {
    # MODIFICAR: la identificacion restante va vacia y solo se informan los
    # conceptos que cambian (vacio = no cambia). La Z ignora NRO_Y.
    param(
        [string]$Caso,
        [string]$Fecha,
        [int]$Terminal,
        $NroY,
        [string]$Tipo,
        [hashtable]$Montos
    )
    if ($Montos.Count -eq 0) { throw 'MODIFICAR sin conceptos informados' }
    $m = @{}
    foreach ($c in $csvCols) { $m[$c] = '' }
    $num = @{}
    foreach ($k in $Montos.Keys) {
        if ($csvCols -notcontains $k) { throw ('La columna ' + $k + ' no esta en el encabezado') }
        $m[$k] = [string]$Montos[$k]
        $num[$k] = [double]$Montos[$k]
    }
    $ident = @(
        $Fecha,
        [string]$Local,
        [string]$Terminal,
        $(if ($null -eq $NroY) { '' } else { [string]$NroY }),
        '', '', '', '', '',
        $Tipo,
        'MODIFICAR'
    )
    $valores = @()
    foreach ($c in $csvCols) { $valores += [string]$m[$c] }
    $total = 0
    foreach ($c in $ventaCols) { if ($num.ContainsKey($c)) { $total += $num[$c] } }
    return [pscustomobject]@{
        Caso    = $Caso
        Fecha   = $Fecha
        Local   = $Local
        Terminal = $Terminal
        Tipo    = $Tipo
        NroY    = $NroY
        Total   = $total
        Dif     = (Get-DifFormula $num)
        Linea   = (($ident + $valores) -join ';')
    }
}

$t1 = $TermA[0]; $t2 = $TermA[1]; $t3 = $TermA[2]
$e1 = $TermB[0]; $e2 = $TermB[1]; $e3 = $TermB[2]; $e4 = $TermB[3]

# --- s01_ok.csv: local $Local / T1 el $FechaA; Z 890.000 = Y1 500.000 + Y2 390.000
$s01 = @(
    (New-Fila -Caso 'ok' -Fecha $FechaA -Terminal $t1 -NroY $null -Hora '21:00' -Secuencia 102 -Boleta 5002 -Vendedor 93343 -ContRepo 2918 -Tipo 'Z' -Monto 890000),
    (New-Fila -Caso 'ok' -Fecha $FechaA -Terminal $t1 -NroY 1     -Hora '12:00' -Secuencia 101 -Boleta 5001 -Vendedor 93343 -ContRepo 2918 -Tipo 'Y' -Monto 500000),
    (New-Fila -Caso 'ok' -Fecha $FechaA -Terminal $t1 -NroY 2     -Hora '18:00' -Secuencia 102 -Boleta 5002 -Vendedor 93343 -ContRepo 2918 -Tipo 'Y' -Monto 390000)
)

# --- s02_dos_terminales.csv: T5 con 3 Y sin NRO_Y (Cargar numera 1 a 3) y T6 con Y1/Y2
$s02 = @(
    (New-Fila -Caso 'ok' -Fecha $FechaA -Terminal $t2 -NroY $null -Hora '21:30' -Secuencia 5202 -Boleta 7002 -Vendedor 93351 -ContRepo 2925 -Tipo 'Z' -Monto 2000000),
    (New-Fila -Caso 'ok' -Fecha $FechaA -Terminal $t2 -NroY $null -Hora '11:00' -Secuencia 5200 -Boleta 7000 -Vendedor 93351 -ContRepo 2925 -Tipo 'Y' -Monto 700000),
    (New-Fila -Caso 'ok' -Fecha $FechaA -Terminal $t2 -NroY $null -Hora '15:00' -Secuencia 5201 -Boleta 7001 -Vendedor 93351 -ContRepo 2925 -Tipo 'Y' -Monto 650000),
    (New-Fila -Caso 'ok' -Fecha $FechaA -Terminal $t2 -NroY $null -Hora '19:00' -Secuencia 5201 -Boleta 7001 -Vendedor 93351 -ContRepo 2925 -Tipo 'Y' -Monto 650000),
    (New-Fila -Caso 'ok' -Fecha $FechaA -Terminal $t3 -NroY $null -Hora '21:15' -Secuencia 5302 -Boleta 7102 -Vendedor 93352 -ContRepo 2926 -Tipo 'Z' -Monto 1120000),
    (New-Fila -Caso 'ok' -Fecha $FechaA -Terminal $t3 -NroY 1     -Hora '13:00' -Secuencia 5301 -Boleta 7100 -Vendedor 93352 -ContRepo 2926 -Tipo 'Y' -Monto 600000),
    (New-Fila -Caso 'ok' -Fecha $FechaA -Terminal $t3 -NroY 2     -Hora '20:00' -Secuencia 5301 -Boleta 7101 -Vendedor 93352 -ContRepo 2926 -Tipo 'Y' -Monto 520000)
)

# --- s03_mixto.csv: 4 grupos el $FechaB (1 correcto y 3 con error esperado)
$s03 = @(
    # e1: correcto, Z 1.250.000 = Y1 800.000 + Y2 450.000
    (New-Fila -Caso 'ok'        -Fecha $FechaB -Terminal $e1 -NroY $null -Hora '21:00' -Secuencia 102 -Boleta 6002 -Vendedor 93343 -ContRepo 2918 -Tipo 'Z' -Monto 1250000),
    (New-Fila -Caso 'ok'        -Fecha $FechaB -Terminal $e1 -NroY 1     -Hora '12:00' -Secuencia 101 -Boleta 6000 -Vendedor 93343 -ContRepo 2918 -Tipo 'Y' -Monto 800000),
    (New-Fila -Caso 'ok'        -Fecha $FechaB -Terminal $e1 -NroY 2     -Hora '18:00' -Secuencia 101 -Boleta 6001 -Vendedor 93343 -ContRepo 2918 -Tipo 'Y' -Monto 450000),
    # e2: Z 741.000 contra Y 400.000 + 340.000 = 740.000 (descuadre de 1.000)
    (New-Fila -Caso 'descuadre' -Fecha $FechaB -Terminal $e2 -NroY $null -Hora '21:00' -Secuencia 202 -Boleta 7402 -Vendedor 93344 -ContRepo 2919 -Tipo 'Z' -Monto 741000),
    (New-Fila -Caso 'descuadre' -Fecha $FechaB -Terminal $e2 -NroY 1     -Hora '12:00' -Secuencia 201 -Boleta 7400 -Vendedor 93344 -ContRepo 2919 -Tipo 'Y' -Monto 400000),
    (New-Fila -Caso 'descuadre' -Fecha $FechaB -Terminal $e2 -NroY 2     -Hora '18:00' -Secuencia 201 -Boleta 7401 -Vendedor 93344 -ContRepo 2919 -Tipo 'Y' -Monto 340000),
    # e3: la Y2 trae VENDEDOR de 11 digitos (vta_vendedor es NUMBER(10))
    (New-Fila -Caso 'vendedor'  -Fecha $FechaB -Terminal $e3 -NroY $null -Hora '21:00' -Secuencia 302 -Boleta 7502 -Vendedor 93345 -ContRepo 2920 -Tipo 'Z' -Monto 500000),
    (New-Fila -Caso 'vendedor'  -Fecha $FechaB -Terminal $e3 -NroY 1     -Hora '12:00' -Secuencia 301 -Boleta 7500 -Vendedor 93345 -ContRepo 2920 -Tipo 'Y' -Monto 250000),
    (New-Fila -Caso 'vendedor'  -Fecha $FechaB -Terminal $e3 -NroY 2     -Hora '18:00' -Secuencia 301 -Boleta 7501 -Vendedor 12345678901 -ContRepo 2920 -Tipo 'Y' -Monto 250000),
    # e4: NRO_Y 99 (el 99 es la Z); Buscar lo rechaza en LECTURA
    (New-Fila -Caso 'nroy99'    -Fecha $FechaB -Terminal $e4 -NroY $null -Hora '21:00' -Secuencia 402 -Boleta 7602 -Vendedor 93346 -ContRepo 2921 -Tipo 'Z' -Monto 350000),
    (New-Fila -Caso 'nroy99'    -Fecha $FechaB -Terminal $e4 -NroY 99    -Hora '20:30' -Secuencia 401 -Boleta 7601 -Vendedor 93346 -ContRepo 2921 -Tipo 'Y' -Monto 350000)
)

# --- s04_reemplazo_v1.csv: primera carga de T7 el $FechaA (3 Y sin NRO_Y)
$s04 = @(
    (New-Fila -Caso 'ok' -Fecha $FechaA -Terminal $TermReemp -NroY $null -Hora '21:00' -Secuencia 7202 -Boleta 7202 -Vendedor 93347 -ContRepo 2922 -Tipo 'Z' -Monto 1750000),
    (New-Fila -Caso 'ok' -Fecha $FechaA -Terminal $TermReemp -NroY $null -Hora '10:00' -Secuencia 7200 -Boleta 7200 -Vendedor 93347 -ContRepo 2922 -Tipo 'Y' -Monto 600000),
    (New-Fila -Caso 'ok' -Fecha $FechaA -Terminal $TermReemp -NroY $null -Hora '14:00' -Secuencia 7201 -Boleta 7201 -Vendedor 93347 -ContRepo 2922 -Tipo 'Y' -Monto 550000),
    (New-Fila -Caso 'ok' -Fecha $FechaA -Terminal $TermReemp -NroY $null -Hora '19:00' -Secuencia 7201 -Boleta 7201 -Vendedor 93347 -ContRepo 2922 -Tipo 'Y' -Monto 600000)
)

# --- s05_reemplazo_v2.csv: segunda carga de T7 (reemplaza la Z y las 3 Y de s04)
$s05 = @(
    (New-Fila -Caso 'ok' -Fecha $FechaA -Terminal $TermReemp -NroY $null -Hora '21:30' -Secuencia 7212 -Boleta 7212 -Vendedor 93347 -ContRepo 2922 -Tipo 'Z' -Monto 1860000),
    (New-Fila -Caso 'ok' -Fecha $FechaA -Terminal $TermReemp -NroY 1     -Hora '11:00' -Secuencia 7210 -Boleta 7210 -Vendedor 93347 -ContRepo 2922 -Tipo 'Y' -Monto 900000),
    (New-Fila -Caso 'ok' -Fecha $FechaA -Terminal $TermReemp -NroY 2     -Hora '18:30' -Secuencia 7211 -Boleta 7211 -Vendedor 93347 -ContRepo 2922 -Tipo 'Y' -Monto 960000)
)

# --- s06_numeracion.csv: NRO_Y [vacio, vacio, 1] -> Cargar asigna 2, 3 y 1
$s06 = @(
    (New-Fila -Caso 'ok' -Fecha $FechaA -Terminal $TermNum -NroY $null -Hora '21:00' -Secuencia 8202 -Boleta 8202 -Vendedor 93348 -ContRepo 2923 -Tipo 'Z' -Monto 680000),
    (New-Fila -Caso 'ok' -Fecha $FechaA -Terminal $TermNum -NroY $null -Hora '10:00' -Secuencia 8200 -Boleta 8200 -Vendedor 93348 -ContRepo 2923 -Tipo 'Y' -Monto 210000),
    (New-Fila -Caso 'ok' -Fecha $FechaA -Terminal $TermNum -NroY $null -Hora '14:00' -Secuencia 8201 -Boleta 8201 -Vendedor 93348 -ContRepo 2923 -Tipo 'Y' -Monto 320000),
    (New-Fila -Caso 'ok' -Fecha $FechaA -Terminal $TermNum -NroY 1     -Hora '19:00' -Secuencia 8201 -Boleta 8201 -Vendedor 93348 -ContRepo 2923 -Tipo 'Y' -Monto 150000)
)

# --- s07_modificar.csv: MODIFICAR la Y1 y la Z del T1 del s03 ($FechaB).
#     La Y1 pasa de 800.000 a 700.000 y la Z de 1.250.000 a 1.150.000, para
#     que la Z siga igual a la suma de las Y (700.000 + 450.000 de la Y2).
$s07 = @(
    (New-FilaMod -Caso 'modificar' -Fecha $FechaB -Terminal $e1 -NroY $null -Tipo 'Z' -Montos @{'VTA_MONTOBOL'=1150000; 'REC_MEFECTIVO'=1150000}),
    (New-FilaMod -Caso 'modificar' -Fecha $FechaB -Terminal $e1 -NroY 1     -Tipo 'Y' -Montos @{'VTA_MONTOBOL'=700000; 'REC_MEFECTIVO'=700000})
)

# --- s08_z_sin_y.csv: Z sin Y; Cargar crea la Y1 copiando la Z
$s08 = @(
    (New-Fila -Caso 'ok' -Fecha $FechaB -Terminal $TermZSinY -NroY $null -Hora '21:00' -Secuencia 7202 -Boleta 7202 -Vendedor 93349 -ContRepo 2924 -Tipo 'Z' -Monto 400000)
)

# --- s09_errores.csv: 3 grupos con error esperado
$s09 = @(
    # T5 del s02 ($FechaA): MODIFICAR una Y que no existe (solo hay 1 a 3)
    (New-FilaMod -Caso 'modificar_inexistente' -Fecha $FechaA -Terminal $t2 -NroY 7 -Tipo 'Y' -Montos @{'VTA_MONTOBOL'=300000}),
    # T6 del s02 ($FechaA): mezcla INGRESAR + MODIFICAR en el mismo terminal-dia
    (New-Fila    -Caso 'mezcla' -Fecha $FechaA -Terminal $t3 -NroY 2 -Hora '18:00' -Secuencia 5301 -Boleta 7101 -Vendedor 93352 -ContRepo 2926 -Tipo 'Y' -Monto 300000),
    (New-FilaMod -Caso 'mezcla' -Fecha $FechaA -Terminal $t3 -NroY 1 -Tipo 'Y' -Montos @{'VTA_MONTOBOL'=400000; 'REC_MEFECTIVO'=400000}),
    # T8 ($FechaB): Z = suma de las Y, pero la formula de la Z descuadra en 50.000
    (New-Fila -Caso 'formula' -Fecha $FechaB -Terminal $TermErr -NroY $null -Hora '21:00' -Secuencia 9202 -Boleta 9202 -Vendedor 93350 -ContRepo 2927 -Tipo 'Z' -Monto 500000 -Otros @{'REC_MTRANSBANK'=50000}),
    (New-Fila -Caso 'formula' -Fecha $FechaB -Terminal $TermErr -NroY 1     -Hora '12:00' -Secuencia 9201 -Boleta 9201 -Vendedor 93350 -ContRepo 2927 -Tipo 'Y' -Monto 500000)
)

# ---------------------------------------------------------------------
# Validaciones antes de escribir
# ---------------------------------------------------------------------
function Test-Archivo($nombre, $filas, [string[]]$casosOk, [string[]]$casosFormula) {
    foreach ($r in $filas) {
        $n = $r.Linea.Split(';').Count
        if ($n -ne $nCampos) { throw ('{0}: linea de {1} campos (deben ser {2})' -f $nombre, $n, $nCampos) }
        if ($casosFormula -contains $r.Caso -and $r.Dif -ne 0) {
            throw ('{0}: la formula da {1} en {2} T{3}' -f $nombre, $r.Dif, $r.Tipo, $r.Terminal)
        }
    }
    $grupos = @{}
    foreach ($r in $filas) {
        $k = $r.Fecha + '|' + $r.Terminal
        if (-not $grupos.ContainsKey($k)) {
            $grupos[$k] = [pscustomobject]@{ Z = 0; Y = 0; CantY = 0; Caso = $r.Caso; Filas = @() }
        }
        if ($r.Tipo -eq 'Z') {
            $grupos[$k].Z += $r.Total
        } else {
            $grupos[$k].Y += $r.Total
            $grupos[$k].CantY++
        }
        $grupos[$k].Filas += $r
    }
    $res = @()
    foreach ($k in ($grupos.Keys | Sort-Object)) {
        $g = $grupos[$k]
        if ($casosOk -contains $g.Caso -and $g.CantY -gt 0 -and $g.Z -ne $g.Y) {
            throw ('{0}: T{1} Z {2} <> suma de las Y {3}' -f $nombre, $k.Split('|')[1], $g.Z, $g.Y)
        }
        $res += [pscustomobject]@{
            Archivo = $nombre
            Grupo   = $k
            Z       = $g.Z
            SumaY   = $g.Y
            CantY   = $g.CantY
            Caso    = $g.Caso
        }
    }
    return $res
}

function Write-Csv($nombre, $filas) {
    $txt = $encabezado + "`r`n"
    foreach ($r in $filas) { $txt += $r.Linea + "`r`n" }
    $ruta = Join-Path $Salida $nombre
    [System.IO.File]::WriteAllText($ruta, $txt, [System.Text.Encoding]::ASCII)
    Write-Output ('{0}: {1} filas' -f $nombre, $filas.Count)
}

# s07: la Z modificada tiene que seguir igual a la suma de las Y del dia
# (la Y1 pasa a 700.000; la Y2 del s03 queda en 450.000).
if ($s07[0].Total -ne 1150000) { throw ('s07: la Z informada deberia ser 1.150.000, es ' + $s07[0].Total) }
if ($s07[1].Total -ne 700000)   { throw ('s07: la Y1 informada deberia ser 700.000, es ' + $s07[1].Total) }
if ($s07[0].Total -ne ($s07[1].Total + 450000)) {
    throw ('s07: la Z (' + $s07[0].Total + ') no cuadra con la Y1 (' + $s07[1].Total + ') + la Y2 del s03 (450.000)')
}

# s09: la Z del grupo 'formula' tiene que descuadrar exactamente en 50.000
$zFormula = $s09 | Where-Object { $_.Caso -eq 'formula' -and $_.Tipo -eq 'Z' }
if ($zFormula.Dif -ne 50000) { throw ('s09: la formula de la Z deberia dar 50.000, da ' + $zFormula.Dif) }

$chk = @()
$chk += Test-Archivo 's01_ok.csv'            $s01 @('ok') @('ok')
$chk += Test-Archivo 's02_dos_terminales.csv' $s02 @('ok') @('ok')
$chk += Test-Archivo 's03_mixto.csv'          $s03 @('ok') @('ok')
$chk += Test-Archivo 's04_reemplazo_v1.csv'   $s04 @('ok') @('ok')
$chk += Test-Archivo 's05_reemplazo_v2.csv'   $s05 @('ok') @('ok')
$chk += Test-Archivo 's06_numeracion.csv'     $s06 @('ok') @('ok')
$chk += Test-Archivo 's07_modificar.csv'      $s07 @()     @('modificar')
$chk += Test-Archivo 's08_z_sin_y.csv'        $s08 @('ok') @('ok')
$chk += Test-Archivo 's09_errores.csv'        $s09 @('formula') @()

Write-Csv 's01_ok.csv' $s01
Write-Csv 's02_dos_terminales.csv' $s02
Write-Csv 's03_mixto.csv' $s03
Write-Csv 's04_reemplazo_v1.csv' $s04
Write-Csv 's05_reemplazo_v2.csv' $s05
Write-Csv 's06_numeracion.csv' $s06
Write-Csv 's07_modificar.csv' $s07
Write-Csv 's08_z_sin_y.csv' $s08
Write-Csv 's09_errores.csv' $s09

Write-Output ''
$chk | Format-Table -AutoSize | Out-String -Width 160
