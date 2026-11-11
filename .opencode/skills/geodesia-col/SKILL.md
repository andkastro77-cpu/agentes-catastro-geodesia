---
name: Geodesia Colombia
description: Marcos de referencia, códigos EPSG, zonas de proyección, fórmulas y verificación con PROJ/pyproj para cálculos geodésicos en Colombia
---

# Skill: Geodesia Colombia

## Cuándo usarla

Siempre que la consulta implique sistemas de referencia, coordenadas, proyecciones, transformaciones,
GNSS, nivelación, áreas o distancias calculadas a partir de coordenadas.

## Flujo de trabajo

1. **Normaliza la entrada.** Convierte a grados decimales si viene en DMS. Identifica el orden:
   en Colombia se escribe latitud, longitud; pyproj y PROJ piden longitud, latitud.
2. **Identifica el CRS de entrada y el de salida** con `references/epsg-colombia.md`.
3. **Verifica las herramientas** antes de calcular:
   ```
   python -c "import pyproj; print(pyproj.__version__)"
   projinfo EPSG:9377
   ```
4. **Calcula** con pyproj o con `cs2cs` / `proj`. No calcules transformaciones "de memoria".
5. **Controla el resultado:** dentro de Colombia, orden de magnitud correcto, unidades coherentes.
6. **Responde** con la plantilla, indicando el EPSG de entrada y de salida.

## Elección rápida de CRS

| Necesidad | EPSG | Notas |
| --- | --- | --- |
| Guardar coordenadas geográficas | 4686 | MAGNA-SIRGAS, lat/lon en grados |
| Trabajo catastral nacional en metros | **9377** | Origen Nacional; una sola zona para todo el país |
| Trabajos locales heredados | 3114–3118 | Zonas clásicas de 3°, origen Bogotá |
| Recibir datos de un GPS de mano | 4326 | WGS84; tratar como equivalente a MAGNA en trabajo local |

Regla práctica: **si no hay una razón para usar otra cosa, usa 9377** para planas y **4686** para
geográficas.

## Verificación con pyproj

```python
from pyproj import Transformer

t = Transformer.from_crs("EPSG:4686", "EPSG:9377", always_xy=True)
este, norte = t.transform(-74.0521, 4.6812)   # ojo: lon, lat
print(round(este, 3), round(norte, 3))
# Bogotá -> 4883355.719  2075354.685   (valor de control)
```

Ese resultado es un **valor de control**: si tu cálculo se aleja más de unos metros de
`E = 4 883 355.719`, `N = 2 075 354.685` para el punto `-74.0521, 4.6812`, hay un error de orden de
coordenadas o de CRS.

Si el resultado no cae en el rango esperado (este entre 1 000 000 y 6 500 000; norte entre
1 000 000 y 2 500 000 para 9377), revisa el orden de las coordenadas antes de dudar del código.

## Plantilla de respuesta

```
**Sistema de referencia:** <nombre> (EPSG:entrada) -> <nombre> (EPSG:salida)
**Resultado:** E = ... m, N = ... m
**Cómo se obtuvo:** <código o comando>
**Verificación:** <control de rango o comparación>
**Precisión y supuestos:** <datum, época, unidades de entrada, decimales>
```

## Errores frecuentes

- **Invertir lat/lon.** Es el error número uno. Con `always_xy=True` pyproj usa (lon, lat).
- **Mezclar grados con metros** en la misma operación.
- **Usar una zona 3114–3118 fuera de su franja** de longitud: el resultado se degrada rápido.
- **Confundir Origen Nacional (9377) con Origen Bogotá (3116):** comparten estética de valores pero
  no son intercambiables.
- **Sumar áreas en grados.** El área en grados² no tiene significado métrico.
- **Ignorar la época.** MAGNA-SIRGAS 2018 y la realización anterior difieren en centímetros; para
  catastro no importa, para geodinámica sí.

## Referencias

- `references/epsg-colombia.md` — tabla verificada de CRS y parámetros de proyección.
- `references/formulas.md` — conversión angular, distancias, azimuts, áreas, factor de escala.
