# Sistemas de referencia en Colombia (EPSG)

Parámetros verificados contra la base EPSG (consulta directa a `epsg.io/<código>.json`).
Si necesitas confirmar un código, usa `https://epsg.io/<código>` o `projinfo EPSG:<código>`.

## Geográficos

| EPSG | Nombre | Unidades | Uso |
| --- | --- | --- | --- |
| 4686 | MAGNA-SIRGAS | grados (lat, lon) | Coordenadas geográficas del marco oficial |
| 20046 | MAGNA-SIRGAS 2018 | grados (lat, lon) | Realización 2018 del mismo marco |
| 4326 | WGS84 | grados (lat, lon) | GPS, datos abiertos, web |

MAGNA-SIRGAS y WGS84 comparten elipsoide GRS80/WGS84 en la práctica (diferencias sub-milimétricas).
Para levantamientos locales se tratan como equivalentes; para alta precisión, no.

## Proyectado nacional

| EPSG | Nombre | Notas |
| --- | --- | --- |
| **9377** | MAGNA-SIRGAS 2018 / Origen-Nacional | CRS de referencia para catastro multipropósito |

Parámetros de 9377 (Transversa de Mercator, método EPSG 9807):

| Parámetro | Valor |
| --- | --- |
| Latitud de origen | 4° |
| Longitud de origen | -73° |
| Factor de escala en el origen | 0.9992 |
| Falso este | 5 000 000 m |
| Falso norte | 2 000 000 m |
| Elipsoide | GRS 1980 |

Rangos esperados en Colombia para 9377: este ≈ 4 400 000 – 5 700 000; norte ≈ 1 500 000 – 2 300 000.

## Zonas clásicas (origen Bogotá)

Transversa de Mercator, latitud de origen 4.596200417°, k = 1, falso este = falso norte =
1 000 000 m.

| EPSG | Nombre | Longitud de origen | Franja aproximada |
| --- | --- | --- | --- |
| 3114 | Colombia Far West zone | -80.077507917° | al oeste de -78.58° |
| 3115 | Colombia West zone | -77.077507917° | -78.58° a -75.58° |
| 3116 | Colombia Bogota zone | -74.077507917° | -75.58° a -72.58° |
| 3117 | Colombia East Central zone | -71.077507917° | -72.58° a -69.58° |
| 3118 | Colombia East zone | -68.077507917° | al este de -69.58° |

Ejemplo: Bogotá (-74.08°) cae en **3116**. Medellín (-75.57°) está en el borde entre 3115 y 3116:
verifica con el municipio, no con la longitud sola.

## Marcos y épocas

| Marco | Qué es |
| --- | --- |
| MAGNA-SIRGAS (1995 / 2005) | Marco geocéntrico nacional adoptado como datum oficial |
| MAGNA-SIRGAS 2018 | Realización más reciente del marco (base de 9377) |
| MAGNA-ECO | Denominación usada para la actualización del marco; **verificar código EPSG y vigencia** antes de citarla |
| ITRF | Marco global de referencia; MAGNA está ligado a una realización ITRF |

> No afirmes un código EPSG para MAGNA-ECO sin verificarlo. Si no aparece, usa 4686 o 20046 y
> explica la diferencia en la respuesta.

## Consultas útiles

```bash
projinfo EPSG:9377          # definición completa
projinfo -s EPSG:4686 -t EPSG:9377 --spatial-test intersects   # transformaciones disponibles
echo "-74.0521 4.6812" | cs2cs EPSG:4686 EPSG:9377            # conversión rápida
```
