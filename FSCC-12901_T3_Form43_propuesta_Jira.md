# Propuesta de subtarea Jira: HU-01-T3 (Form43, DF-SCC fila 12)

Texto listo para crear la subtarea bajo **FSCC-12901**.

Origen: Excel DF-SCC (`docs/Requeriemintos-FSCC-12901/DF-SCC-vf_Falabella CO (MEJORAS F8 y COMPENSACIONES MENORES).xlsx`, fila 12). El pedido no figura en el texto de FSCC-12901, FSCC-12957 ni FSCC-12958.

**Alcance definido por el usuario (16-10-2026):** solo visualización. La grilla de Consultas de Cuadratura de Colombia debe mostrar también las cajas con Diferencia Real 0, como en Chile. **No** llama al paquete ni agrega un cierre nuevo. Reemplaza una versión anterior de esta propuesta que sí cerraba con `PKG_F8_CIERRE_AUTO` (descartada).

Estado al 16-10-2026: **desarrollado** en `FTEPROD/Form43.frm`.
- `SubBuscarOpcion`: se agrega `Or Flg_Pais$ = "FACO"` a la condición `If DiferenciaReal <> 0 Or Flg_Pais$ = "ARG" Then`, con marcas `xintec-nruz 16-10-2026`.
- **Pendiente:** compilar y probar.

---

```
Titulo: HU-01-T3 · Consultas de Cuadratura Colombia: mostrar las cajas con Diferencia Real 0

Descripcion
T3 ajusta la grilla del informe "Terminal" de la pantalla Consultas de Cuadratura (Form43) para
Falabella Colombia (FACO), segun el DF-SCC fila 12: la grilla debe mostrar tambien las cajas sin
diferencia (Diferencia Real 0), como en Chile, para que el analista vea en un solo lugar las cajas
cuadradas y las que tienen diferencia.

Situacion actual: en Colombia la grilla solo muestra las cajas con Diferencia Real distinta de 0.

Reglas
- Solo cambia que filas se muestran. Las columnas (Dif. de Caja, Compensacion, Diferencia Real,
  Estado) se siguen calculando como hoy en la pantalla.
- No se agrega ningun cierre ni llamada a procesos de base de datos.
- Otros paises sin cambios.
- Nota: el boton "Cerrar Terminal" de la pantalla no se modifica. Hasta ahora en Colombia no
  cerraba nada porque la grilla no traia cajas en 0. Con este cambio, quien lo presione cerrara
  los cierres Y con Diferencia Real 0 que no esten cerrados, con la logica actual del exe.

Criterios de aceptacion
# | Dado | Cuando | Entonces
1 | un local-dia con cierres Y de Diferencia Real 0 y cierres Y con diferencia | se consulta el informe "Terminal" | aparecen todos, incluidos los de Diferencia Real 0, con su estado (Pendiente / Cerrado / Impreso)
2 | un cierre Y cerrado por el proceso automatico (FSCC-12958) | se consulta el informe "Terminal" | aparece con Diferencia Real 0 y estado Cerrado
3 | un usuario de otro pais | usa Consultas de Cuadratura | la grilla muestra lo mismo que antes

Estado: desarrollado en Form43.frm (16-10-2026); pendiente compilar el exe y probar en test.
```
