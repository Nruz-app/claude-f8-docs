# FCDVT-14: prueba de estres de la carga masiva de Y/Z (Form174)

Creada el 10-11-2026. Objetivo: medir cuantos registros soporta **Buscar +
Cargar** del ingreso masivo (`F8 > boton Y > "Ingreso del YYY Masivo"`),
con montos reales muestreados de la base de test.

La sesion de funcionalidad completa (crear Y compensables con DI) es
`../prueba_carga_y_compensa_di_s5/`; esta carpeta solo mide **volumen**:
no se cargan sobres ni se usa Form133.

## Archivos de la prueba

| Archivo                  | Contenido                                                                          |
|--------------------------|------------------------------------------------------------------------------------|
| `montos_reales_test.csv` | muestra de 300 montos reales de `VTA_FACOLIBVTA` extraidos de test el 10-11-2026    |
| `genera_csv.py`          | regenera los 6 CSV (semilla fija, reproducible)                                     |
| `valida_csv.py`          | valida los 6 CSV (cuadratura, unicidades, formato)                                  |
| `a01_1000.csv` a `a03_5000.csv` | **Serie A** (profundidad): todo en 1 grupo                                   |
| `b01_1000.csv` a `b03_5000.csv` | **Serie B** (anchura): 112 grupos de agosto                                  |
| `e0_prechecks.sql`       | verificaciones de solo lectura antes de la corrida                                  |
| `e2_resultados.sql`      | resultados de solo lectura despues de cada etapa                                    |
| `e9_limpia.sql`          | borra lo que la prueba grabo (v_ejecutar N/S)                                        |

### Grupos usados

- **Serie A**: 1 grupo = fecha `07-11-2026`, local 5, terminal 1. El
  archivo tiene `N-1` Y (numeradas 1 a `N-1`) + 1 Z que cierra la
  cuadratura (su monto es la suma de todas las Y del grupo).
- **Serie B**: 112 grupos = 28 fechas de agosto 2026 x terminales **1 a
  4** del local 5. Los dias 13, 14 y 29 de agosto estan ocupados en
  test y se excluyen (ver e0). Las Y se reparten round-robin entre los
  grupos (`Y i -> grupo i mod 112`, `NRO_Y` reinicia por grupo) y hay
  una Z por grupo (112 en total) que cuadra la suma propia. Segun la
  etapa, cada caja lleva entre 8 y 44 Y.

Los montos se muestrean al azar (semilla fija `20261109`) de los 300
valores reales. En cada fila Y `VTA_MONTOBOL = REC_MEFECTIVO = monto`
con el resto de las columnas de montos en 0; la fila Z lleva `NRO_Y`
vacio y hora fija `21:00` (formato exacto del CSV de la s5, ese cargo
bien por Buscar y lo grabo bien el package).

`py -3.12 valida_csv.py` ya paso con 0 problemas sobre los 6 CSV:
encabezado identico al de la s5 (56 columnas), cuadratura Z = suma de
su grupo, `NRO_Y` 1..n sin repetir en cada grupo, secuencias y boletas
unicas, CP1252 + CRLF. Correrlo de nuevo si se regeneran los CSV.

## Preparar el entorno

1. VPN Fortinet conectada y F8 apuntado a test (como para la s5).
2. Correr `e0_prechecks.sql` (solo lectura). ESPERADO: paquetes y
   tablas del ticket VALID (en test ya estan instalados de INTRANETTS),
   terminales 1 a 4 vigentes y **sin filas en ninguna fecha objetivo**
   (consultas 6 a 9). Si alguna fecha tiene filas de la prueba, correr
   `e9_limpia.sql` primero con `v_ejecutar='N'` (cuenta) y `'S'` (borra).
   Nota sqlplus de este PC: si reclama `SP2-1502: HTTP proxy setting...`
   es la variable `NO_PROXY` del entorno: `set NO_PROXY=  && sqlplus ...`.

## Protocolo de corrida

Con F8 en test: `F8 > boton Y > Ingreso del YYY Masivo`. A y B se
pueden intercalar; dentro de cada serie conviene subir de a un paso
(1.000, 2.000, 5.000):

1. **Buscar** con el CSV de la etapa. Cronometrar desde que se acepta
   el archivo hasta que aparece la grilla. Anotar el tiempo y el
   numero de carga que muestra el mensaje.
2. Verificar en la grilla el grupo de ejemplo (terminal 1 de la serie
   A, o cualquier fecha/terminal de la B): la cantidad de Y y el monto
   de la Z contra la suma total del README.
3. **Cargar**. Cronometrar desde el click hasta el mensaje final.
4. `e2_resultados.sql` en sqlplus: estados GRABADO, cantidades y suma
   de `res_total_y` contra la tabla de sumas de este README.
5. Etapa siguiente. **No hace falta limpiar entre etapas**: Cargar
   REEMPLAZA cada grupo. Si se quiere conservar el estado de una etapa
   previa, hacer backup de las tablas antes de la siguiente (e9 no
   guarda historico: borra todo el estres).

### Cuello de botella a medir

- **Buscar** es O(n) en idas y vueltas ADO: `prc_inicia` + **una llamada
  a `prc_inserta_linea` por cada linea del CSV** + `prc_procesa`.
- **Cargar** graba por grupo: 1 libvta + 1 zzz + 1 termstaty por cada Y,
  mas la Z, con commits por grupo.

### Tabla de tiempos (completar al correr)

| Etapa    | Archivo        | Lineas | Buscar (s) | Cargar (s) | Notas |
|----------|----------------|--------|------------|------------|-------|
| A x1.000 | `a01_1000.csv` | 1.000  |            |            |       |
| A x2.000 | `a02_2000.csv` | 2.000  |            |            |       |
| A x5.000 | `a03_5000.csv` | 5.000  |            |            |       |
| B x1.000 | `b01_1000.csv` | 1.000  |            |            |       |
| B x2.000 | `b02_2000.csv` | 2.000  |            |            |       |
| B x5.000 | `b03_5000.csv` | 5.000  |            |            |       |

Se sube de etapa mientras la anterior pase; donde falle, quedan
registradas ahi el **maximo soportado**.

### Criterio de parada

- Error de Oracle en pantalla, o grupos en ERROR en
  `VTA_FACOCARGA_YZ_LOG` (el motivo esta en `log_motivo`).
- Ventana colgada sin movimiento ~5 min: cerrar f8.exe, dejar la etapa
  anotada y no escalar mas.
- Mensaje del package distinto de `Grabado: Z + N Y ...`.

### Sumas totales por archivo (para comparar con e2)

| Archivo        | Cant Y | Cant Z | Suma total Y (= suma de las Z) |
|----------------|--------|--------|--------------------------------|
| `a01_1000.csv` | 999    | 1      | 6.154.992.598                  |
| `a02_2000.csv` | 1.999  | 1      | 12.594.134.013                 |
| `a03_5000.csv` | 4.999  | 1      | 31.282.447.381                 |
| `b01_1000.csv` | 888    | 112    | 5.313.587.971                  |
| `b02_2000.csv` | 1.888  | 112    | 11.551.857.959                 |
| `b03_5000.csv` | 4.888  | 112    | 30.394.072.340                 |

En serie B las Y por grupo van de 8 a 44 (el reparto round-robin lo
deja desparejo a proposito; el detalle queda en e2 A3).

## Limpieza

`e9_limpia.sql`, dos pasadas: `v_ejecutar='N'` primero (cuenta lo que
queda del estres) y `'S'` despues (borra y commit). Todo lo que borra
son datos sinteticos de la prueba; en test no hace falta respaldo. Si
se prefieren conservar las filas de las tablas CARGA_YZ_* (auditoria
de volumes), se pueden comentar esos deletes del paso 1.

## Cuidados

- Solo se tocan las terminales de la prueba: 1 (A) y 1 a 4 (B), fechas
  agosto 2026 (sin 13/14/29) y 07-11-2026. Verificado en e0.
- Los grupos de cada terminal-dia **se REEMPLAZAN** al recargar: si
  otra sesion cargo algo en esas fechas y terminales, e0 debe correrse
  antes de cada corrida.
- El 12-11-2026 y fechas posteriores no se usan: la regla del package
  es **fecha anterior a hoy**.
- La numeracion `NRO_Y` en serie B reinicia por grupo a proposito (asi
  graba el package por terminal-dia); en serie A es 1..4999 continuo,
  que es la escalera de profundidad.
