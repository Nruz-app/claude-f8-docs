# -*- coding: utf-8 -*-
"""
FCDVT-14: generador de los CSV de la prueba de estres de la carga masiva
(Form174, Buscar + Cargar). Genera 6 archivos en la misma carpeta:

  Serie A (profundidad: todo en 1 grupo de fecha 07-11-2026, terminal 1):
    a01_1000.csv  =  999 Y + 1 Z  (1000 lineas)
    a02_2000.csv  = 1999 Y + 1 Z  (2000 lineas)
    a03_5000.csv  = 4999 Y + 1 Z  (5000 lineas)

  Serie B (anchura: 112 grupos = 28 fechas de agosto 2026 x terminales
  1..4 del local 5; las fechas ocupadas de agosto son 13, 14 y 29):
    b01_1000.csv  =  999 Y repartidos + 112 Z (1111 lineas)
    b02_2000.csv  = 1999 Y repartidos + 112 Z (2111 lineas)
    b03_5000.csv  = 4999 Y repartidos + 112 Z (5111 lineas)

Montos: muestreados (al azar, semilla fija) de montos_reales_test.csv,
la muestra de 300 valores reales de VTA_FACOLIBVTA.VTA_MONTOBOL de test.
En cada fila Y: VTA_MONTOBOL = REC_MEFECTIVO = monto (BOLETAS = EFECTIVO,
el resto de las columnas de montos en 0, como la s5).

La fila Z de cada grupo cierra la cuadratura: VTA_MONTOBOL = suma de los
montos Y del grupo, HORA 21:00, NRO_Y vacio (identica a la sesion s5,
cuyo CSV ya cargo bien Form174).
"""
import csv
import os
import random

RESPALDO = "montos_reales_test.csv"

ENCABEZADO = ("FECHA;LOCAL;TERMINAL;NRO_Y;HORA;SECUENCIA;NUM_BOLETA;VENDEDOR;"
              "CONT_REPOSICION;TIPO;TIPO_CARGA;VTA_MONTOBOL;VTA_MONTONCR;"
              "VTA_MONTOFAC;REC_MEFECTIVO;REC_MRECAUDAEFEC;REC_MCHKDIA;"
              "REC_MCHKFECHA;REC_MTARJ;REC_MSODIMAC;REC_MCMR;REC_MTREGALO;"
              "REC_MTOTCONVENIO;REC_MTRASPASOTDE;REC_MRENUEVA;REC_MTOTFACXCOB;"
              "REC_MDOTACIONES;REC_MRETIROS;REC_MABONOCMR;REC_MAVANCECMR;"
              "REC_MTOTPREPRENUEVA;REC_MTRANSFERENCIA;REC_MREVERSATRANS;"
              "REC_MRETIROTRANS;REC_MATRFEFEC;REC_MATRFCHK;REC_MATRFCMR;"
              "REC_MATRFDEB;REC_MATRFCRE;REC_MREVATOTTRF;REC_MREVATRFEFEC;"
              "REC_MREVATRFCMR;REC_MABONOTDE;REC_MTDE;REC_MSELLOSVRD;"
              "REC_MTOTRECAUDA;REC_MTOTREVRECAUDA;REC_MCANJEPUNTOS;"
              "REC_MREVCANJEPUNTOS;REC_MTOTSIF;REC_MRECTERCERO;REC_MDEVTERCERO;"
              "REC_MQUICKPAYCMR;REC_MQUICKPAYBCO;REC_ECOMPAY;REC_MPAGOPUNTOS")

SEMILLA = 20261109
LOCAL = 5
FECHA_A = "07-11-2026"   # serie A: un solo grupo sobre esa fecha/terminal
TERM_A = 1
# Serie B: agosto 2026 sin los dias 13, 14 y 29 (ocupados en test)
FECHAS_B = ["%02d-08-2026" % d for d in list(range(1, 13)) + list(range(15, 29)) + [30, 31]]
TERMS_B = [1, 2, 3, 4]
ZONA_HORA = range(10 * 60, 21 * 60)   # horas Y entre 10:00 y 20:59; Z siempre 21:00


def carga_montos():
    ruta = os.path.join(os.path.dirname(os.path.abspath(__file__)), RESPALDO)
    with open(ruta, "r", encoding="cp1252") as f:
        montos = [int(linea.strip()) for linea in f if linea.strip().isdigit()]
    if not montos:
        raise SystemExit("Sin montos en " + ruta)
    return montos


def fila(fecha, term, nro_y, hora, secuencia, boleta, vendedor, crepo, tipo, monto, tipo_carga):
    cero = "0"
    return ";".join([
        fecha, str(LOCAL), str(term),
        "" if nro_y is None else str(nro_y),
        hora, str(secuencia), str(boleta), str(vendedor), str(crepo),
        tipo, tipo_carga, str(monto), cero, cero,
        cero if tipo == "Z" else str(monto),  # REC_MEFECTIVO
    ] + [cero] * 41)   # del REC_MRECAUDAEFEC al final son 41 columnas en 0


def genera(nombre, n, grupos, rng, montos):
    """grupos = lista de (fecha, terminal) en orden de produccion."""
    ng = len(grupos)
    ny = n - 1 if ng == 1 else n - ng          # Y del archivo
    por_grupo = [[] for _ in range(ng)]
    secuencia = 2100                           # la primera fila usa 2101
    boleta = 61000000
    used = 0
    for i in range(ny):
        gi = i % ng if ng > 1 else 0
        used += 1
        nro_y = len(por_grupo[gi]) + 1
        secuencia += 1
        boleta += 1
        monto = montos[rng.randrange(len(montos))]
        fecha, term = grupos[gi]
        minutos = list(ZONA_HORA)[rng.randrange(len(ZONA_HORA))]
        hora = "%02d:%02d" % (minutos // 60, minutos % 60)
        crepo = 4000 + term * 100 + 1          # 4101, 4201, 4301, 4401
        por_grupo[gi].append(fila(fecha, term, nro_y, hora, secuencia,
                                  boleta, 71001 + (used % 50), crepo,
                                  "Y", monto, "INGRESAR"))
    lineas = []
    totales = []
    for gi, (fecha, term) in enumerate(grupos):
        lineas.extend(por_grupo[gi])
        suma = sum(int(x.split(";")[11]) for x in por_grupo[gi])
        total_y = suma
        ult = por_grupo[gi][-1]
        secuencia += 1
        crepo = 4000 + term * 100 + 1
        zfila = ";".join([
            fecha, str(LOCAL), str(term), "", "21:00", str(secuencia),
            ult.split(";")[6], ult.split(";")[7], str(crepo),
            "Z", "INGRESAR", str(total_y), "0", "0", "0",
        ] + ["0"] * 41)
        lineas.append(zfila)
        totales.append((fecha, term, len(por_grupo[gi]), total_y))
    ruta = os.path.join(os.path.dirname(os.path.abspath(__file__)), nombre)
    with open(ruta, "w", encoding="cp1252", newline="") as f:
        f.write(ENCABEZADO + "\r\n")
        for l in lineas:
            f.write(l + "\r\n")
    mayor = max(total for _, _, _, total in totales)
    print("%s: %d lineas (%d Y + %d Z) | suma del grupo mas grande: %s" % (
        nombre, len(lineas) + 1, ny, ng, formato(mayor)))
    return totales


def formato(n):
    return "{:,}".format(n).replace(",", ".")


def main():
    montos = carga_montos()
    gs_a = [(FECHA_A, TERM_A)]
    gs_b = [(f, t) for f in FECHAS_B for t in TERMS_B]
    print("Serie B: %d fechas x %d terminales = %d grupos" % (
        len(FECHAS_B), len(TERMS_B), len(gs_b)))
    for nombre, n in [("a01_1000.csv", 1000), ("a02_2000.csv", 2000), ("a03_5000.csv", 5000)]:
        genera(nombre, n, gs_a, random.Random(SEMILLA), montos)
    for nombre, n in [("b01_1000.csv", 1000), ("b02_2000.csv", 2000), ("b03_5000.csv", 5000)]:
        genera(nombre, n, gs_b, random.Random(SEMILLA + 1), montos)


if __name__ == "__main__":
    main()
