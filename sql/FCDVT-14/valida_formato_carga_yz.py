# -*- coding: utf-8 -*-
"""FCDVT-14: valida un CSV de carga masiva Y/Z (Form174, FACO) ANTES de subirlo.

Reproduce del lado del archivo lo que hace PKG_F8_CARGA_MASIVA_YZ
(sql/FCDVT-14/04_pkg_carga_masiva_yz_body.sql) en prc_inserta_linea y
prc_procesa, para no gastar numeros de carga en la base:

  - CP1252 sin BOM, CRLF puro y CRLF final;
  - encabezado identico a c_encabezado (56 columnas);
  - 56 campos por linea;
  - FECHA dd-mm-yyyy valida y anterior a hoy;
  - HORA HH:MM de 24 horas;
  - LOCAL/TERMINAL/SECUENCIA/NUM_BOLETA/VENDEDOR/CONT_REPOSICION enteros
    obligatorios; NRO_Y opcional; VENDEDOR de hasta 10 digitos;
  - TIPO Y o Z; TIPO_CARGA = INGRESAR;
  - 45 montos enteros de hasta 12 digitos (vacio = 0);
  - por grupo fecha/local/terminal: 1 Z, al menos 1 Y, sin NRO_Y repetido y
    total Z (BOLETAS + N.CREDITO + FACTURA) = suma de los totales de las Y.

NO valida contra la base: local/terminal vigentes (VTA_FACOTERMINALES) y
Z/Y ya cerradas los revisa el package.

Uso:
    py -3 valida_formato_carga_yz.py archivo.csv [archivo2.csv ...]

Codigo de salida 0 = todo OK, 1 = hay errores.
"""
import datetime
import re
import sys

CAMPOS = 56
ENCABEZADO = ";".join([
    "FECHA", "LOCAL", "TERMINAL", "NRO_Y", "HORA", "SECUENCIA", "NUM_BOLETA",
    "VENDEDOR", "CONT_REPOSICION", "TIPO", "TIPO_CARGA",
    "VTA_MONTOBOL", "VTA_MONTONCR", "VTA_MONTOFAC", "REC_MEFECTIVO",
    "REC_MRECAUDAEFEC", "REC_MCHKDIA", "REC_MCHKFECHA", "REC_MTARJ",
    "REC_MSODIMAC", "REC_MCMR", "REC_MTREGALO", "REC_MTOTCONVENIO",
    "REC_MTRASPASOTDE", "REC_MRENUEVA", "REC_MTOTFACXCOB", "REC_MDOTACIONES",
    "REC_MRETIROS", "REC_MABONOCMR", "REC_MAVANCECMR", "REC_MTOTPREPRENUEVA",
    "REC_MTRANSFERENCIA", "REC_MREVERSATRANS", "REC_MRETIROTRANS",
    "REC_MATRFEFEC", "REC_MATRFCHK", "REC_MATRFCMR", "REC_MATRFDEB",
    "REC_MATRFCRE", "REC_MREVATOTTRF", "REC_MREVATRFEFEC", "REC_MREVATRFCMR",
    "REC_MABONOTDE", "REC_MTDE", "REC_MSELLOSVRD", "REC_MTOTRECAUDA",
    "REC_MTOTREVRECAUDA", "REC_MCANJEPUNTOS", "REC_MREVCANJEPUNTOS",
    "REC_MTOTSIF", "REC_MRECTERCERO", "REC_MDEVTERCERO", "REC_MQUICKPAYCMR",
    "REC_MQUICKPAYBCO", "REC_ECOMPAY", "REC_MPAGOPUNTOS",
])

RE_ENTERO = re.compile(r"^-?[0-9]{1,15}$")
RE_FECHA = re.compile(r"^[0-9]{2}-[0-9]{2}-[0-9]{4}$")
RE_HORA = re.compile(r"^[0-9]{1,2}:[0-9]{2}$")

# columnas 1..9 (indices 0..8): identificacion; 10 TIPO; 11 TIPO_CARGA
OBLIGATORIOS = [(1, "LOCAL"), (2, "TERMINAL"), (5, "SECUENCIA"),
                (6, "NUM_BOLETA"), (7, "VENDEDOR"), (8, "CONT_REPOSICION")]


def valida(ruta):
    problemas = []
    grupos = {}

    crudo = open(ruta, "rb").read()
    if crudo[:3] == b"\xef\xbb\xbf":
        problemas.append("tiene BOM UTF-8 (debe ser CP1252 sin BOM)")
    try:
        txt = crudo.decode("cp1252")
    except UnicodeDecodeError as e:
        return ["no decodifica CP1252: %s" % e], grupos

    if "\n" in txt.replace("\r\n", ""):
        problemas.append("hay LF suelto (debe ser CRLF puro)")
    if txt.endswith("\r\n"):
        txt = txt[:-2]
    else:
        problemas.append("no termina en CRLF")
    lineas = txt.split("\r\n")

    if lineas[0].strip().upper() != ENCABEZADO:
        problemas.append("el encabezado no es el de la plantilla de 56 columnas")
        # sin encabezado correcto el package rechaza la carga completa
        return problemas, grupos

    hoy = datetime.date.today()
    montos_txt = ""

    for idx, linea in enumerate(lineas[1:], start=2):
        if linea.strip().replace(";", "") == "":
            continue                     # lineas vacias: el package las omite
        c = linea.split(";")
        if len(c) != CAMPOS:
            problemas.append("linea %d: %d campos (deben ser %d)"
                             % (idx, len(c), CAMPOS))
            continue
        c = [x.strip() for x in c]

        # FECHA
        fecha = None
        if not c[0]:
            problemas.append("linea %d: FECHA vacia" % idx)
        elif not RE_FECHA.match(c[0]):
            problemas.append("linea %d: FECHA %r no es dd-mm-yyyy" % (idx, c[0]))
        else:
            try:
                fecha = datetime.datetime.strptime(c[0], "%d-%m-%Y").date()
            except ValueError:
                problemas.append("linea %d: FECHA %r inexistente" % (idx, c[0]))
            if fecha and fecha >= hoy:
                problemas.append("linea %d: FECHA %s no es anterior a hoy"
                                 % (idx, c[0]))

        # HORA
        if not c[4]:
            problemas.append("linea %d: HORA vacia" % idx)
        elif not RE_HORA.match(c[4]):
            problemas.append("linea %d: HORA %r no es HH:MM de 24 horas "
                             "(12 h con a. m./p. m. no se acepta)" % (idx, c[4]))
        else:
            hh, mm = c[4].split(":")
            if int(hh) > 23 or int(mm) > 59:
                problemas.append("linea %d: HORA %r fuera de 00:00-23:59"
                                 % (idx, c[4]))

        # identificacion
        for pos, nombre in OBLIGATORIOS:
            if not c[pos]:
                problemas.append("linea %d: %s vacio" % (idx, nombre))
            elif not RE_ENTERO.match(c[pos]):
                problemas.append("linea %d: %s %r no es entero"
                                 % (idx, nombre, c[pos]))
        if c[3] and not RE_ENTERO.match(c[3]):
            problemas.append("linea %d: NRO_Y %r no es entero" % (idx, c[3]))
        if RE_ENTERO.match(c[7]) and abs(int(c[7])) > 9999999999:
            problemas.append("linea %d: VENDEDOR %s tiene mas de 10 digitos"
                             % (idx, c[7]))

        # TIPO / TIPO_CARGA
        if c[9] not in ("Y", "Z"):
            problemas.append("linea %d: TIPO %r (debe ser Y o Z)" % (idx, c[9]))
        if c[10].upper() != "INGRESAR":
            problemas.append("linea %d: TIPO_CARGA %r (debe ser INGRESAR)"
                             % (idx, c[10]))

        # montos
        montos = []
        for i in range(11, CAMPOS):
            v = c[i]
            if v == "":
                montos.append(0)
                continue
            if not RE_ENTERO.match(v):
                problemas.append("linea %d: %s %r no es entero"
                                 % (idx, ENCABEZADO.split(";")[i], v))
                montos.append(None)
            elif abs(int(v)) > 999999999999:
                problemas.append("linea %d: %s %s supera 12 digitos"
                                 % (idx, ENCABEZADO.split(";")[i], v))
                montos.append(int(v))
            else:
                montos.append(int(v))
        total = (montos[0] + montos[1] + montos[2]
                 if None not in montos[:3] else None)

        if fecha is None or not c[1] or not c[2]:
            continue                      # sin grupo, como en la base
        clave = (fecha, c[1], c[2])
        grupos.setdefault(clave, []).append(
            {"linea": idx, "tipo": c[9], "nro_y": c[3], "total": total})

    for clave in sorted(grupos):
        filas = grupos[clave]
        etiqueta = "%s L%s T%s" % (clave[0].strftime("%d-%m-%Y"), clave[1], clave[2])
        ys = [f for f in filas if f["tipo"] == "Y"]
        zs = [f for f in filas if f["tipo"] == "Z"]
        if len(zs) != 1:
            problemas.append("grupo %s: %d filas Z (debe ser 1)"
                             % (etiqueta, len(zs)))
        if not ys:
            problemas.append("grupo %s: sin filas Y" % etiqueta)
        nros = [f["nro_y"] for f in ys]
        if len(set(nros)) != len(nros):
            problemas.append("grupo %s: NRO_Y repetido (%s)"
                             % (etiqueta, ", ".join(nros)))
        if zs and zs[0]["nro_y"] != "":
            problemas.append("grupo %s: la Z trae NRO_Y=%r (va vacio)"
                             % (etiqueta, zs[0]["nro_y"]))
        if len(zs) == 1 and ys:
            tz = zs[0]["total"]
            ty = sum(f["total"] for f in ys if f["total"] is not None)
            if None not in [f["total"] for f in ys] and tz is not None and tz != ty:
                problemas.append("grupo %s: total Z %s distinto de la suma de las Y %s"
                                 % (etiqueta, tz, ty))

    montos_txt = ""
    return problemas, grupos


def main(rutas):
    errores = 0
    for ruta in rutas:
        try:
            problemas, grupos = valida(ruta)
        except OSError as e:
            print("%s\n   ! no se pudo leer: %s" % (ruta, e))
            errores += 1
            continue
        n_lineas = sum(len(f) for f in grupos.values())
        print("%s\n   lineas=%d grupos=%d | %s"
              % (ruta, n_lineas, len(grupos),
                 "OK" if not problemas else "ERRORES:"))
        for p in problemas:
            print("   ! " + p)
        errores += len(problemas)
        if not problemas and not grupos:
            print("   ! el archivo no generaria ningun grupo (revisar FECHA/LOCAL/TERMINAL)")
            errores += 1
    print("\nTOTAL problemas: %d" % errores)
    return 0 if errores == 0 else 1


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(2)
    sys.exit(main(sys.argv[1:]))
