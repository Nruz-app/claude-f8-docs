# -*- coding: utf-8 -*-
"""FCDVT-14: valida los 6 CSV del estres contra lo que espera Form174."""
import os

CARPETA = os.path.dirname(os.path.abspath(__file__))
PLANTILLA = r"C:\FALABELLA\F8\F8NK\claude-f8-docs\sql\FCDVT-14\prueba_carga_y_compensa_di_s5\carga_Y_compensa.csv"

ARCHIVOS = [
    ("a01_1000.csv", 1000, 1),
    ("a02_2000.csv", 2000, 1),
    ("a03_5000.csv", 5000, 1),
    ("b01_1000.csv", 1000, 112),
    ("b02_2000.csv", 2000, 112),
    ("b03_5000.csv", 5000, 112),
]

enc_ok = open(PLANTILLA, "rb").read().decode("cp1252").split("\r\n")[0]
errores = 0

for nombre, n, ng in ARCHIVOS:
    ruta = os.path.join(CARPETA, nombre)
    crudo = open(ruta, "rb").read()
    problemas = []

    txt = None
    try:
        txt = crudo.decode("cp1252")
    except UnicodeDecodeError as e:
        problemas.append("no decodifica CP1252: %s" % e)
    if "\n" in txt.replace("\r\n", ""):
        problemas.append("hay LF suelto (no CRLF puro)")
    if txt.endswith("\r\n"):
        txt = txt[:-2]
    else:
        problemas.append("no termina en CRLF")
    lineas = txt.split("\r\n")

    if lineas[0] != enc_ok:
        problemas.append("encabezado distinto al de la s5")
    if len(lineas[0].split(";")) != 56:
        problemas.append("encabezado no tiene 56 columnas")

    # grupos: fecha+terminal -> filas
    grupos = {}
    for idx, l in enumerate(lineas[1:], start=2):
        c = l.split(";")
        if len(c) != 56:
            problemas.append("linea %d: %d columnas" % (idx, len(c)))
            continue
        if c[9] not in ("Y", "Z"):
            problemas.append("linea %d: TIPO %r" % (idx, c[9]))
        if c[11] != str(int(c[11])) or int(c[11]) < 0:
            problemas.append("linea %d: monto no entero" % idx)
        grupos.setdefault((c[0], c[2]), []).append(c)

    if len(grupos) != ng:
        problemas.append("se esperaban %d grupos, hay %d" % (ng, len(grupos)))

    n_datos = len(lineas) - 1
    if ng == 1 and n_datos != n:
        problemas.append("datos %d != %d" % (n_datos, n))

    secs, boletas_y = {}, set()
    n_y_total = n_z_total = 0
    for gkey, filas in grupos.items():
        ys = [f for f in filas if f[9] == "Y"]
        zs = [f for f in filas if f[9] == "Z"]
        n_y_total += len(ys)
        n_z_total += len(zs)
        if len(zs) != 1:
            problemas.append("grupo %s: %d filas Z" % (gkey, len(zs)))
        # NRO_Y: 1..n sin repetir; en la Z vacio
        nros = [f[3] for f in ys]
        if nros != [str(i) for i in range(1, len(ys) + 1)]:
            problemas.append("grupo %s: NRO_Y no es 1..%d" % (gkey, len(ys)))
        if zs and zs[0][3] != "":
            problemas.append("grupo %s: la Z tiene NRO_Y=%r" % (gkey, zs[0][3]))
        if zs and zs[0][4] != "21:00":
            problemas.append("grupo %s: hora Z %r" % (gkey, zs[0][4]))
        for f in ys:
            h = f[4]
            hh, mm = h.split(":")
            if not (10 <= int(hh) <= 20 and int(mm) < 60):
                problemas.append("grupo %s: hora Y %r fuera de 10:00-20:59" % (gkey, h))
            # BOLETAS = EFECTIVO
            if f[11] != f[14]:
                problemas.append("grupo %s Y%s: VTA_MONTOBOL %s != REC_MEFECTIVO %s"
                                 % (gkey, f[3], f[11], f[14]))
        # cuadratura Z = suma de Y
        suma = sum(int(f[11]) for f in ys)
        z_monto = int(zs[0][11])
        if suma != z_monto:
            problemas.append("grupo %s: Z %d != suma Y %d" % (gkey, z_monto, suma))
        for f in filas:
            s = f[5]
            if s in secs.setdefault(gkey, []):
                problemas.append("grupo %s: secuencia %s repetida" % (gkey, s))
            secs[gkey].append(s)
            # la NUM_BOLETA de la Z comparte el de la ultima Y (patron s5);
            # el unico debe verificarce solo entre filas Y
            if f[9] == "Y":
                b = f[6]
                if b in boletas_y:
                    problemas.append("boleta %s repetida" % b)
                boletas_y.add(b)
            for col, val in [(7, "VENDEDOR"), (8, "CONT_REPOSICION")]:
                if f[col] == "":
                    problemas.append("grupo %s: %s vacio" % (gkey, val))

    print("%-13s datos=%5d (Y %5d + Z %4d) grupos=%3d | %s" % (
        nombre, n_datos, n_y_total, n_z_total, len(grupos),
        "OK" if not problemas else "ERRORES:"))
    for p in problemas:
        print("   ! " + p)
        errores += 1

print("\nTOTAL problemas: %d" % errores)
