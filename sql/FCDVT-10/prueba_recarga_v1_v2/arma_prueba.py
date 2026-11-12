# -*- coding: utf-8 -*-
"""FCDVT-10 (HU-03) - Prueba "recarga v1 / v2" de la carga masiva de Tottus Chile (SFCL).

Arma los dos CSV de la prueba (carga_v1.csv y carga_v2.csv), los scripts
py2_resultados.sql y py9_limpiar.sql y el Excel de resumen, con el
encabezado REAL de VTA_PAINT_Z (que no esta en el clon offline).

Entrada: paint_z_sfcl.csv, exportado de la consulta 3 de py0_prechecks.sql
(FILA;VTA_CMP_ASOC;VTA_POP_UP;VTA_VALIDADORZZZ;VTA_SIGNO;VTAGLOSA_Z).
Opcional: encabezado.txt con la salida de la consulta 4 de py0
(fn_encabezado('SFCL')); si esta, se compara con el encabezado armado aqui.

Uso (desde esta carpeta o con rutas absolutas):
    python -I arma_prueba.py --local 216 --terminales 6,7,8,9
    python -I arma_prueba.py --local 216 --terminales 6,7,8,9 --fecha 11-11-2026 \
        --paint paint_z_sfcl.csv --encabezado encabezado.txt --col-pago REC_MEFECTIVO

Replica PKG_F8_CARGA_MASIVA_YZ_SFCL.prc_config (04_pkg_carga_masiva_yz_sfcl_body.sql):
  - filas 2 a 6 = conceptos de venta (vta_pop_up 0 y columna VTA_), fila 7 =
    total (vta_pop_up 3);
  - fila > 7 con vta_pop_up 0 y columna que no empieza con VTA_ (o empieza con
    MVTA_) = concepto de VTA_SFCLZZZ (va en el CSV);
  - encabezado = 11 columnas de identificacion + esos conceptos, en orden;
  - formula de la Z (vta_validadorzzz 1..7, vta_signo): g7 - g6 - ... - g1 = 0,
    con libvta = venta y total (solo las 6 columnas que graba Cargar) y zzz =
    conceptos del CSV.
La venta va en BOLETAS (fila 2) y una columna de pago de la formula (la de
glosa EFECTIVO, o --col-pago) se calcula para que la Z cuadre.

Solo biblioteca estandar, mas openpyxl para el Excel (si no esta, se omite).
No se conecta a ninguna base.
"""
import argparse
import csv
import datetime
import io
import os
import re
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))

ENCAB_ID = ['FECHA', 'LOCAL', 'TERMINAL', 'NRO_Y', 'HORA', 'SECUENCIA', 'NUM_BOLETA',
            'VENDEDOR', 'CONT_REPOSICION', 'TIPO', 'TIPO_CARGA']

# Columnas de VTA_SFCLLIBVTA (clon docs/ddl, test 26-10-2026): para saber si
# una columna de la formula es de libvta ('L') o de zzz ('Z'), como
# fn_existe_col('VTA_SFCLLIBVTA', ...) del package.
COLS_LIBVTA = set('''VTA_FECHA VTA_LOCAL VTA_TERMINAL VTA_TIPOREG VTA_SECUENCIA VTA_FECHA_VENTA
VTA_MONTOBOL VTA_MONTOFAC VTA_MONTONCR VTA_TOTALVTA VTA_NUMBOL VTA_NUMFAC VTA_NUMNCR
VTA_MONBOL_IVA VTA_MONBOL_AD VTA_MONBOL_EX VTA_MONIVA VTA_MONADIC VTA_BOLINICIAL VTA_BOLFINAL
VTA_CANTBOL VTA_NROLLO VTA_CREPO_INICIAL VTA_CREPO_FINAL VTA_ESTADO VTA_TIPOF8 VTA_TRASPASO
VTA_FECHA_TRASPASO VTA_TRASPASADO_AL VTA_TRASPASADO_POR VTA_SECUENCIA_SRX VTA_HORA
VTA_VENDEDOR VTA_TECHKEY VTA_CONSOLIDADO VTA_MMONTOBOLPER VTA_MMONTOTKRUC VTA_MMONTONDB
VTA_MNETOTKT VTA_MMONTOTROSIMP VTA_RECAUDACION VTA_REVRECAUDA VTA_MONTOGUIA VTA_RECMFPAY'''.split())

# Columnas de libvta que graba Cargar (fn_dif_valida_archivo): el resto vale 0
LIBVTA_VENTA = ['VTA_MONTOBOL', 'VTA_MONTONCR', 'VTA_MONTOFAC', 'VTA_MMONTONDB', 'VTA_MONTOGUIA']

# ---------------------------------------------------------------------------
# Escenarios. Cada fila: (tipo, nro_y, hora, secuencia, boleta, cont_repo, monto)
# TA..TD se reemplazan por las terminales reales; vendedor = 8100<n>.
# ---------------------------------------------------------------------------
ESCENARIOS = [
    {'clave': 'TA', 'n': 1,
     'titulo': 'Prueba 1 - INGRESAR v1 > INGRESAR v2 (Z + Y1, otro monto)',
     'desc': 'v1 carga la Z y la Y1 por 1.000.000; v2, con la misma fecha, local y terminal, '
             'las carga por 1.200.000 (Z = Y, cuadra). Cargar v2 REEMPLAZA: queda 1.200.000.',
     'v1': [('Z', '', '21:00', 3102, 7101000, 5101, 1000000),
            ('Y', 1, '15:30', 3101, 7101000, 5101, 1000000)],
     'v2': [('Z', '', '22:00', 3202, 7101500, 5201, 1200000),
            ('Y', 1, '19:30', 3201, 7101500, 5201, 1200000)],
     'msg_v1': 'Grabado: Z + 1 Y (numeros 1 a 1)',
     'msg_v2': 'Grabado: Z + 1 Y (numeros 1 a 1). Reemplazo lo anterior: 1 Z y 1 Y',
     'final': 1200000, 'final_y': 'Y1 1.200.000 (la de v2)',
     'concl': 'Queda el monto del ultimo archivo (v2) en la Z y en la Y.'},
    {'clave': 'TB', 'n': 2,
     'titulo': 'Prueba 2 - INGRESAR v1 (Z + 2 Y) > INGRESAR v2 (Z + 1 Y)',
     'desc': 'v1 carga la Z por 1.000.000 con Y1 600.000 e Y2 400.000; v2 trae la Z y una sola Y '
             'por 1.150.000. Cargar v2 borra TODAS las Y del dia: queda solo la Y1 de v2.',
     'v1': [('Z', '', '21:00', 3113, 7102400, 5102, 1000000),
            ('Y', 1, '11:00', 3111, 7102000, 5102, 600000),
            ('Y', 2, '17:00', 3112, 7102400, 5102, 400000)],
     'v2': [('Z', '', '22:00', 3212, 7102800, 5202, 1150000),
            ('Y', 1, '20:00', 3211, 7102800, 5202, 1150000)],
     'msg_v1': 'Grabado: Z + 2 Y (numeros 1 a 2)',
     'msg_v2': 'Grabado: Z + 1 Y (numeros 1 a 1). Reemplazo lo anterior: 1 Z y 2 Y',
     'final': 1150000, 'final_y': 'Y1 1.150.000; la Y2 de v1 se borra',
     'concl': 'Queda v2 completo: tambien desaparecen las Y de v1 que v2 no trae (Y2).'},
    {'clave': 'TC', 'n': 3,
     'titulo': 'Prueba 3 - Z sin Y v1 > Z sin Y v2 (Y1 automatica)',
     'desc': 'v1 carga solo la Z por 800.000 y Cargar crea la Y1 copiando la Z; v2 trae solo la Z '
             'por 950.000: Cargar reemplaza y vuelve a crear la Y1, ahora con 950.000.',
     'v1': [('Z', '', '21:00', 3121, 7103000, 5103, 800000)],
     'v2': [('Z', '', '22:00', 3221, 7103500, 5203, 950000)],
     'msg_v1': 'Grabado: Z + Y1 automatica (copia de la Z)',
     'msg_v2': 'Grabado: Z + Y1 automatica (copia de la Z). Reemplazo lo anterior: 1 Z y 1 Y',
     'final': 950000, 'final_y': 'Y1 automatica 950.000 (copia de la Z de v2)',
     'concl': 'La Y1 automatica se rehace con el monto de v2.'},
    {'clave': 'TD', 'n': 4,
     'titulo': 'Prueba 4 - INGRESAR v1 (Z + 2 Y) > Z sin Y v2 (Y1 automatica)',
     'desc': 'v1 carga la Z por 800.000 con Y1 500.000 e Y2 300.000; v2 trae solo la Z por '
             '900.000: Cargar borra las 2 Y de v1 y crea la Y1 automatica con 900.000.',
     'v1': [('Z', '', '21:00', 3133, 7104300, 5104, 800000),
            ('Y', 1, '12:00', 3131, 7104000, 5104, 500000),
            ('Y', 2, '18:00', 3132, 7104300, 5104, 300000)],
     'v2': [('Z', '', '22:00', 3231, 7104900, 5204, 900000)],
     'msg_v1': 'Grabado: Z + 2 Y (numeros 1 a 2)',
     'msg_v2': 'Grabado: Z + Y1 automatica (copia de la Z). Reemplazo lo anterior: 1 Z y 2 Y',
     'final': 900000, 'final_y': 'Y1 automatica 900.000; las Y de v1 se borran',
     'concl': 'Z sin Y despues de una carga con Y: quedan la Z de v2 y una Y1 copia de ella.'},
]


def fmt(n):
    return '{:,}'.format(n).replace(',', '.')


def falla(msg):
    sys.stderr.write('ERROR: ' + msg + '\n')
    sys.exit(1)


# ---------------------------------------------------------------------------
# Lectura de VTA_PAINT_Z
# ---------------------------------------------------------------------------
def lee_texto(ruta):
    raw = open(ruta, 'rb').read()
    for enc in ('utf-8-sig', 'cp1252'):
        try:
            return raw.decode(enc)
        except UnicodeDecodeError:
            pass
    falla('no se pudo leer ' + ruta)


def lee_paint(ruta):
    txt = lee_texto(ruta)
    try:
        dialecto = csv.Sniffer().sniff(txt.splitlines()[0], delimiters=';,\t')
    except csv.Error:
        class PuntoComa(csv.excel):
            delimiter = ';'
        dialecto = PuntoComa
    filas = list(csv.reader(io.StringIO(txt), dialecto))
    filas = [f for f in filas if any(c.strip() for c in f)]
    enc = [c.strip().strip('"').upper() for c in filas[0]]
    req = ['VTA_CMP_ASOC', 'VTA_POP_UP', 'VTA_VALIDADORZZZ', 'VTA_SIGNO']
    for r in req:
        if r not in enc:
            falla('%s no tiene la columna %s (encabezado leido: %s)' % (ruta, r, ';'.join(enc)))
    pos = {c: i for i, c in enumerate(enc)}

    def val(f, c):
        i = pos.get(c)
        return f[i].strip() if i is not None and i < len(f) else ''

    def num(s):
        s = s.strip()
        if s == '':
            return 0
        return int(float(s.replace(',', '.')))

    out = []
    for k, f in enumerate(filas[1:], start=1):
        out.append({'fila': num(val(f, 'FILA')) if 'FILA' in pos else k,
                    'col': val(f, 'VTA_CMP_ASOC').upper() or None,
                    'pop': num(val(f, 'VTA_POP_UP')),
                    'vld': num(val(f, 'VTA_VALIDADORZZZ')),
                    'signo': -1 if val(f, 'VTA_SIGNO') == '-' else 1,
                    'glosa': val(f, 'VTAGLOSA_Z')})
    out.sort(key=lambda r: r['fila'])
    return out


def config(paint):
    """Replica de prc_config: conceptos del CSV, venta y formula."""
    conc = []          # (col, glosa, destino)
    venta = {}
    vld = []           # (col, tabla, grupo, signo, glosa)
    avisos = []
    vld_ok = True
    if len(paint) < 7:
        falla('VTA_PAINT_Z no tiene los conceptos de SFCL (filas: %d)' % len(paint))
    for r, p in enumerate(paint, start=1):
        col = p['col']
        if 2 <= r <= 6:
            if p['pop'] != 0 or not col or not col.startswith('VTA_'):
                falla('la fila %d (%s) no es un concepto de venta: el package dara ORA-20002'
                      % (r, p['glosa']))
            venta[r - 1] = col
            conc.append((col, p['glosa'], 'L'))
        elif r == 7:
            if p['pop'] != 3:
                falla('la fila 7 (%s) no es el total de venta (vta_pop_up 3): ORA-20002' % p['glosa'])
        elif r > 7 and col:
            zzz = (not col.startswith('VTA_')) or col.startswith('MVTA_')
            if p['pop'] == 0:
                if zzz:
                    if any(c[0] == col for c in conc):
                        falla('la columna %s aparece en mas de un concepto: ORA-20002' % col)
                    conc.append((col, p['glosa'], 'Z'))
                else:
                    avisos.append('%s (%s) no va en el CSV: Form19Y no lo graba.' % (col, p['glosa']))
        if 1 <= p['vld'] <= 7 and col:
            tabla = 'L' if col in COLS_LIBVTA else 'Z'
            vld.append((col, tabla, p['vld'], p['signo'], p['glosa']))
    return conc, venta, vld, vld_ok, avisos


def dif_formula(montos, venta, conc, vld, total):
    """fn_dif_valida_archivo: g7 - g6 - ... - g1 con lo que grabara Cargar."""
    lib = {c: 0 for c in LIBVTA_VENTA}
    for k, c in enumerate(LIBVTA_VENTA, start=1):
        lib[c] = montos.get(venta[k], 0)
    lib['VTA_TOTALVTA'] = total
    zcols = {c[0] for c in conc if c[2] == 'Z'}
    g = [0] * 8
    for col, tabla, grupo, signo, _ in vld:
        if tabla == 'L':
            v = lib.get(col, 0)
        else:
            v = montos.get(col, 0) if col in zcols else 0
        g[grupo] += signo * v
    return g[7] - g[6] - g[5] - g[4] - g[3] - g[2] - g[1]


def elige_pago(conc, vld, venta, forzada):
    zcols = [c for c in conc if c[2] == 'Z']
    cand = [e for e in vld if e[1] == 'Z' and any(z[0] == e[0] for z in zcols)]
    if forzada:
        forzada = forzada.upper()
        if not any(e[0] == forzada for e in cand):
            falla('--col-pago %s no es una columna del CSV que participe en la formula '
                  '(candidatas: %s)' % (forzada, ', '.join(sorted({e[0] for e in cand})) or 'ninguna'))
        return forzada
    if not cand:
        return None

    def coef(col):
        m = {venta[1]: 0, col: 1}
        return dif_formula(m, venta, conc, vld, 0)

    efe = [e for e in cand if 'EFECTIVO' in (e[4] or '').upper() and coef(e[0]) != 0]
    otras = [e for e in cand if coef(e[0]) != 0]
    if efe:
        return efe[0][0]
    if otras:
        return otras[0][0]
    return None


def montos_fila(monto, conc, venta, vld, col_pago):
    m = {venta[1]: monto}
    if col_pago:
        d0 = dif_formula(m, venta, conc, vld, monto)
        m2 = dict(m)
        m2[col_pago] = 1
        k = dif_formula(m2, venta, conc, vld, monto) - d0
        if k == 0:
            falla('la columna de pago %s no cambia la formula' % col_pago)
        v = -d0 / float(k)
        if v != int(v):
            falla('el monto de pago no es entero (%s): revisar la formula' % v)
        m[col_pago] = int(v)
        if dif_formula(m, venta, conc, vld, monto) != 0:
            falla('la Z no quedo cuadrada con %s' % col_pago)
    return m


# ---------------------------------------------------------------------------
# Salidas
# ---------------------------------------------------------------------------
def arma_csv(version, terms, local, fecha, conc, venta, vld, col_pago):
    lineas = [';'.join(ENCAB_ID + [c[0] for c in conc])]
    for esc in ESCENARIOS:
        term = terms[esc['clave']]
        for tipo, nroy, hora, sec, bol, crepo, monto in esc[version]:
            m = montos_fila(monto, conc, venta, vld, col_pago)
            ident = [fecha, str(local), str(term), str(nroy), hora, str(sec), str(bol),
                     str(81000 + esc['n']), str(crepo), tipo, 'INGRESAR']
            lineas.append(';'.join(ident + [str(m.get(c[0], 0)) for c in conc]))
    return '\r\n'.join(lineas) + '\r\n'


def verifica_csv(texto, conc, venta, vld):
    filas = [l.split(';') for l in texto.split('\r\n') if l]
    n = 11 + len(conc)
    grupos = {}
    for f in filas[1:]:
        assert len(f) == n, 'fila con %d columnas (deben ser %d)' % (len(f), n)
        m = {c[0]: int(v) for c, v in zip(conc, f[11:])}
        total = sum(m.get(venta[k], 0) for k in range(1, 6))
        g = grupos.setdefault(f[2], {'Z': 0, 'Y': 0, 'ny': 0})
        g[f[9]] += total
        if f[9] == 'Y':
            g['ny'] += 1
        else:
            assert dif_formula(m, venta, conc, vld, total) == 0, 'Z descuadrada (T%s)' % f[2]
    for t, g in grupos.items():
        assert g['ny'] == 0 or g['Z'] == g['Y'], 'Z <> suma de Y en T%s' % t
    return len(filas) - 1


def render(tpl, valores):
    s = open(os.path.join(AQUI, 'plantillas', tpl), 'rb').read().decode('ascii').replace('\r\n', '\n')
    for k, v in valores.items():
        s = s.replace('{' + k + '}', str(v))
    resto = re.findall(r'\{[A-Z_0-9]+\}', s)
    if resto:
        falla('quedaron marcas sin reemplazar en %s: %s' % (tpl, ', '.join(sorted(set(resto)))))
    return s.replace('\n', '\r\n').encode('ascii')


def arma_excel(ruta, terms, local, fecha, col_pago, ncols):
    try:
        import openpyxl
        from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
    except ImportError:
        print('AVISO: openpyxl no esta instalado; no se genero el Excel de resumen.')
        return False
    fino = Side(style='thin', color='FF999999')
    borde = Border(left=fino, right=fino, top=fino, bottom=fino)
    gris = PatternFill('solid', fgColor='FFE7E6E6')
    azul = PatternFill('solid', fgColor='FF1F4E79')
    amar = PatternFill('solid', fgColor='FFFFF2CC')
    cab = PatternFill('solid', fgColor='FFD9E1F2')
    wrap = Alignment(wrap_text=True, vertical='top')

    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = 'Resumen'
    for col, w in zip('ABCDEFG', (30, 24, 40, 3, 30, 24, 40)):
        ws.column_dimensions[col].width = w
    ws['A1'] = ('FCDVT-10 (carga masiva de Y/Z, Tottus Chile SFCL) - Recarga v1 / v2 del mismo '
                'terminal-dia - local %s - %s' % (local, fecha))
    ws['A1'].font = Font(bold=True, size=14, color='FF1F3864')
    ws.merge_cells('A1:G1')
    ws['A2'] = ('Misma prueba de FCDVT-14 sesion 7 (FACO), sin DI ni sobres (en SFCL no estan '
                'habilitados). Se cargan dos archivos INGRESAR con la misma fecha, local y terminal y '
                'otro monto que cuadra: carga_v1.csv y despues carga_v2.csv. Cargar '
                '(PKG_F8_GRABA_MASIVA_YZ_SFCL) REEMPLAZA la Z y TODAS las Y del terminal-dia; si el '
                'grupo no trae Y, crea la Y1 copiando la Z. Respuesta esperada: queda el monto del '
                'ultimo archivo (v2). CSV de %d columnas armados con arma_prueba.py; columna de pago '
                'de la formula: %s.' % (ncols, col_pago or 'ninguna (formula desactivada)'))
    ws['A2'].alignment = wrap
    ws.merge_cells('A2:G2')
    ws.row_dimensions[2].height = 80

    def filas_v(rows):
        return len(rows) + (0 if any(x[0] == 'Y' for x in rows) else 1)

    def bloque(fila0, base, esc, pad):
        t = terms[esc['clave']]
        filas = [('title', esc['titulo'], None, None),
                 ('desc', esc['desc'], None, None),
                 ('sec', 'Datos', None, None),
                 ('row', 'Local / Terminal', '%s / %s (%s)' % (local, t, esc['clave']), None),
                 ('row', 'Fecha de venta', fecha, None),
                 ('row', 'Tipo de carga', 'INGRESAR (v1 y v2)', None),
                 ('sec', 'Carga v1 (carga_v1.csv)', None, None)]
        for tipo, nroy, hora, sec, bol, crepo, monto in esc['v1']:
            et = 'Z' if tipo == 'Z' else 'Y%s' % nroy
            filas.append(('row', et, monto, 'hora %s, secuencia %s, boleta %s' % (hora, sec, bol)))
        if not any(x[0] == 'Y' for x in esc['v1']):
            filas.append(('row', 'Y1 (automatica)', esc['v1'][0][6], 'Cargar copia la Z'))
        filas += [('row', None, None, None)] * (pad['v1'] - filas_v(esc['v1']))
        filas.append(('row', 'Mensaje de Cargar v1', esc['msg_v1'], None))
        filas.append(('sec', 'Carga v2 (carga_v2.csv)', None, None))
        for tipo, nroy, hora, sec, bol, crepo, monto in esc['v2']:
            et = 'Z' if tipo == 'Z' else 'Y%s' % nroy
            filas.append(('row', et, monto, 'hora %s, secuencia %s, boleta %s' % (hora, sec, bol)))
        if not any(x[0] == 'Y' for x in esc['v2']):
            filas.append(('row', 'Y1 (automatica)', esc['v2'][0][6], 'Cargar copia la Z'))
        filas += [('row', None, None, None)] * (pad['v2'] - filas_v(esc['v2']))
        filas.append(('row', 'Mensaje de Cargar v2', esc['msg_v2'], None))
        filas += [('sec', 'Resultado final (despues de v2)', None, None),
                  ('amt', 'MONTO FINAL Z (libvta F8/99)', esc['final'], 'Queda v2'),
                  ('amt', 'Y que quedan', esc['final_y'], None),
                  ('row', 'termstaty', 'Solo cierrey 1, estado -1', 'Glosa CARGA <n de v2>'),
                  ('row', 'termstat (Z)', 'Estado -1', 'Glosa CARGA <n de v1>: no se cambia'),
                  ('row', 'VTA_SFCLTARJ 2001/2002', 'Solo cierrey 1',
                   'El insert de la zzz de la Z borra las del dia; cada Y las recrea'),
                  ('desc', 'Conclusion: ' + esc['concl'], None, None)]
        for i, (tipo, a, b, c) in enumerate(filas):
            r = fila0 + i
            ca, cb, cc = ws.cell(r, base), ws.cell(r, base + 1), ws.cell(r, base + 2)
            for x in (ca, cb, cc):
                x.border = borde
                x.alignment = wrap
            ca.value = a
            if tipo == 'title':
                ca.font = Font(bold=True, size=12, color='FFFFFFFF')
                ca.fill = azul
                ws.merge_cells(start_row=r, start_column=base, end_row=r, end_column=base + 2)
                ws.row_dimensions[r].height = 30
            elif tipo == 'desc':
                ws.merge_cells(start_row=r, start_column=base, end_row=r, end_column=base + 2)
                ws.row_dimensions[r].height = 48
            elif tipo == 'sec':
                ca.font = Font(bold=True)
                ca.fill = gris
                ws.merge_cells(start_row=r, start_column=base, end_row=r, end_column=base + 2)
            else:
                cb.value = b
                cc.value = c
                if isinstance(b, int):
                    cb.number_format = '#,##0'
                if tipo == 'amt':
                    cb.font = Font(bold=True)
                    cb.fill = amar
        return len(filas)

    fila = 4
    for par in (ESCENARIOS[0:2], ESCENARIOS[2:4]):
        pad = {v: max(filas_v(e[v]) for e in par) for v in ('v1', 'v2')}
        alto = max(bloque(fila, 1, par[0], pad), bloque(fila, 5, par[1], pad))
        fila += alto + 2

    # Hoja Recarga v1-v2
    rv = wb.create_sheet('Recarga v1-v2')
    rv['A1'] = 'Recarga del mismo terminal-dia (FCDVT-10, SFCL): que monto queda al final - local %s - %s' % (local, fecha)
    rv['A1'].font = Font(bold=True, size=14, color='FF1F3864')
    rv.merge_cells('A1:J1')
    rv['A2'] = ('Regla (PKG_F8_GRABA_MASIVA_YZ_SFCL.pr_graba_ingresar): INGRESAR borra la zzz de los techkeys, '
                'la libvta F8/Y y TODAS las termstaty del dia y graba lo del archivo nuevo (termstaty -1). Sin '
                'Y en el grupo crea la Y1 = copia de la Z. Solo rechaza si la Z o alguna Y del dia estan '
                'CERRADAS (Buscar y Cargar). La termstat de la Z solo se inserta si no existe (conserva la glosa '
                'de v1). TRG_VTA_SFCLZZZ_I: al insertar la zzz de la Z borra VTA_SFCLTARJ 2001-2999 y los AL del '
                'dia; cada Y los vuelve a crear. Las filas de v1 en VTA_SFCLCARGA_YZ_RES quedan GRABADO.')
    rv['A2'].alignment = wrap
    rv.merge_cells('A2:J2')
    rv.row_dimensions[2].height = 90
    hdr = ['Prueba', 'Terminal', 'v1 (Z / Y)', 'v2 (Z / Y)', 'Mensaje de Cargar v2',
           'MONTO FINAL Z', 'Y que quedan', 'Filas libvta al final', 'Estado', 'Conclusion']
    for j, h in enumerate(hdr, start=1):
        c = rv.cell(4, j, h)
        c.font = Font(bold=True)
        c.fill = cab
        c.border = borde
        c.alignment = wrap

    def desc_v(rows):
        z = [r for r in rows if r[0] == 'Z'][0][6]
        ys = [r for r in rows if r[0] == 'Y']
        if not ys:
            return 'Z %s, sin Y (Y1 automatica)' % fmt(z)
        return 'Z %s; %s' % (fmt(z), ', '.join('Y%s %s' % (r[1], fmt(r[6])) for r in ys))

    for i, esc in enumerate(ESCENARIOS, start=5):
        vals = [esc['n'], '%s (%s)' % (terms[esc['clave']], esc['clave']), desc_v(esc['v1']),
                desc_v(esc['v2']), esc['msg_v2'], esc['final'], esc['final_y'], '2 (F8/99 + Y/1)',
                'Abierta (-1)', esc['concl']]
        for j, v in enumerate(vals, start=1):
            c = rv.cell(i, j, v)
            c.border = borde
            c.alignment = wrap
            if j == 6:
                c.font = Font(bold=True)
                c.fill = amar
                c.number_format = '#,##0'
        rv.row_dimensions[i].height = 60
    c = rv.cell(10, 1, 'Respuesta: al final queda el monto del ULTIMO archivo cargado (v2), en la Z y en las Y; '
                       'las Y de v1 que v2 no trae se borran, y si v2 no trae Y se crea la Y1 copiando su Z.')
    c.font = Font(bold=True)
    c.alignment = wrap
    rv.merge_cells('A10:J10')
    rv.row_dimensions[10].height = 34
    for j, w in enumerate((8, 12, 30, 30, 40, 14, 30, 16, 12, 40), start=1):
        rv.column_dimensions[openpyxl.utils.get_column_letter(j)].width = w

    # Hoja Pasos
    ps = wb.create_sheet('Pasos')
    ps.column_dimensions['A'].width = 5
    ps.column_dimensions['B'].width = 36
    ps.column_dimensions['C'].width = 120
    pasos = [
        ('#', 'Paso', 'Detalle'),
        ('0', 'Prerrequisitos', 'FCDVT-10 instalado en test (INSTALAR.sql, packages VALID), exe compilado con '
         'Form174/MDIForm1 de FCDVT-10 y permiso 460 de SFCL (01_menu_ingreso_masivo_y_sfcl.sql). py0 consultas 1 y 2.'),
        ('1', 'py0_prechecks.sql', 'Consulta 3 -> exportar a paint_z_sfcl.csv; consulta 4 -> encabezado.txt; '
         'consulta 6 y 7 -> elegir el local y 4 terminales libres.'),
        ('2', 'arma_prueba.py', 'python -I arma_prueba.py --local L --terminales a,b,c,d. Genera carga_v1.csv, '
         'carga_v2.csv, py2_resultados.sql, py9_limpiar.sql y este Excel.'),
        ('3', 'F8 (toolbar)', 'Usuario de Tottus (SFCL), local %s, fecha %s.' % (local, fecha)),
        ('4', 'Carga v1 (Form174)', 'Boton Y - "Ingreso del YYY Masivo" - Buscar carga_v1.csv - 4 grupos CARGADO '
         '(1.000.000, 1.000.000, 800.000, 800.000) - Cargar - anotar el numero de carga v1. Mensajes: '
         'TA "Grabado: Z + 1 Y (numeros 1 a 1)", TB y TD "Grabado: Z + 2 Y (numeros 1 a 2)", '
         'TC "Grabado: Z + Y1 automatica (copia de la Z)".'),
        ('5', 'py2_resultados.sql', 'Ver lo que dejo v1 (valores entre parentesis en los ESPERADO).'),
        ('6', 'Carga v2 (Form174)', 'Buscar carga_v2.csv - 4 grupos CARGADO (1.200.000, 1.150.000, 950.000, '
         '900.000) - Cargar - anotar el numero de carga v2. Cada mensaje termina en "Reemplazo lo anterior: '
         '1 Z y n Y" (n = 1 en TA y TC, 2 en TB y TD).'),
        ('7', 'py2_resultados.sql', 'Monto final (E1), sin restos de v1 (B2), una sola Y por terminal (C1), '
         'VTA_SFCLTARJ solo cierrey 1 (D1).'),
        ('8', 'Form3Y / Form19Y', 'F8 de cada terminal: la Z y la Y1 con el monto de v2.'),
        ('9', 'Repetir (opcional)', 'py9_limpiar.sql (N cuenta, S borra; sin commit hasta el final del bloque) y '
         'Buscar + Cargar v1 y v2 de nuevo.'),
    ]
    for i, fila_p in enumerate(pasos, start=1):
        for j, v in enumerate(fila_p, start=1):
            c = ps.cell(i, j, v)
            c.border = borde
            c.alignment = wrap
            if i == 1:
                c.font = Font(bold=True)
                c.fill = cab
    wb.save(ruta)
    return True


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--local', type=int, required=True)
    ap.add_argument('--terminales', required=True, help='4 terminales TA,TB,TC,TD (py0 consulta 7)')
    ap.add_argument('--fecha', default='11-11-2026', help='dd-mm-yyyy, anterior a hoy (default 11-11-2026)')
    ap.add_argument('--paint', default=os.path.join(AQUI, 'paint_z_sfcl.csv'))
    ap.add_argument('--encabezado', default=os.path.join(AQUI, 'encabezado.txt'))
    ap.add_argument('--col-pago', default=None, help='columna de pago para cuadrar la formula de la Z')
    ap.add_argument('--salida', default=AQUI)
    a = ap.parse_args()

    terms_l = [t.strip() for t in a.terminales.split(',') if t.strip()]
    if len(terms_l) != 4 or not all(t.isdigit() for t in terms_l) or len(set(terms_l)) != 4:
        falla('--terminales debe traer 4 numeros distintos separados por coma')
    terms = dict(zip(('TA', 'TB', 'TC', 'TD'), [int(t) for t in terms_l]))
    try:
        f = datetime.datetime.strptime(a.fecha, '%d-%m-%Y').date()
    except ValueError:
        falla('--fecha debe ser dd-mm-yyyy')
    if f >= datetime.date.today():
        print('AVISO: la fecha %s no es anterior a hoy: Buscar la rechazara.' % a.fecha)
    if a.fecha != '11-11-2026':
        print('AVISO: py0_prechecks.sql usa 11-11-2026 en las consultas 6 y 7; cambiar la fecha ahi.')
    if not os.path.exists(a.paint):
        falla('no existe %s: exportar la consulta 3 de py0_prechecks.sql' % a.paint)

    paint = lee_paint(a.paint)
    conc, venta, vld, vld_ok, avisos = config(paint)
    encab = ';'.join(ENCAB_ID + [c[0] for c in conc])
    for x in avisos:
        print('AVISO: ' + x)
    print('Encabezado armado: %d columnas (11 + %d conceptos).' % (11 + len(conc), len(conc)))
    if os.path.exists(a.encabezado):
        real = lee_texto(a.encabezado).strip().strip('"').rstrip(';').upper()
        if real != encab.upper():
            falla('el encabezado de %s no es igual al armado desde %s.\n  real : %s\n  armado: %s'
                  % (a.encabezado, a.paint, real[:300], encab[:300]))
        print('Encabezado verificado contra %s.' % os.path.basename(a.encabezado))
    else:
        print('AVISO: no hay %s; el encabezado no se verifico contra fn_encabezado.'
              % os.path.basename(a.encabezado))

    if not vld:
        print('AVISO: VTA_PAINT_Z no tiene formula de validacion de la Z: no se usa columna de pago.')
        col_pago = None
    else:
        col_pago = elige_pago(conc, vld, venta, a.col_pago)
        if col_pago is None:
            falla('la formula de la Z no tiene una columna del CSV para cuadrarla: usar --col-pago')
        print('Columna de pago para la formula de la Z: %s (BOLETAS = %s).' % (col_pago, venta[1]))
        print('  Si alguna columna de la formula es de VTA_SFCLZZZ y no existe, el package la desactiva '
              '(00_prechecks.sql de FCDVT-10, consulta 5).')

    for v in ('v1', 'v2'):
        txt = arma_csv(v, terms, a.local, a.fecha, conc, venta, vld, col_pago)
        n = verifica_csv(txt, conc, venta, vld)
        open(os.path.join(a.salida, 'carga_%s.csv' % v), 'wb').write(txt.encode('cp1252'))
        print('carga_%s.csv: %d filas.' % (v, n))

    valores = {'FECHA': f.strftime('%Y%m%d'), 'FECHA_DMY': a.fecha, 'LOCAL': a.local,
               'TA': terms['TA'], 'TB': terms['TB'], 'TC': terms['TC'], 'TD': terms['TD'],
               'TERMS': ', '.join(str(terms[k]) for k in ('TA', 'TB', 'TC', 'TD')),
               'COL_PAGO': col_pago or 'ninguna',
               'COL_PAGO_EXPR': ('z.' + col_pago) if col_pago else 'null'}
    for tpl, out in (('py2_resultados.sql.tpl', 'py2_resultados.sql'),
                     ('py9_limpiar.sql.tpl', 'py9_limpiar.sql')):
        open(os.path.join(a.salida, out), 'wb').write(render(tpl, valores))
        print(out + ' generado.')
    if arma_excel(os.path.join(a.salida, 'Prueba-Recarga-SFCL_Resumen.xlsx'), terms, a.local, a.fecha,
                  col_pago, 11 + len(conc)):
        print('Prueba-Recarga-SFCL_Resumen.xlsx generado.')


if __name__ == '__main__':
    main()
