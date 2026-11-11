# Fórmulas de trabajo

Fórmulas para resolver a mano y para verificar resultados de PROJ. Elipse GRS 1980:
a = 6 378 137 m, 1/f = 298.257222101.

## 1. Ángulos

De grados-minutos-segundos a decimales:

```
decimal = grados + minutos/60 + segundos/3600
```

Con signo negativo para el oeste y el sur. Ejemplo:
`4° 40' 52.3" N` → `4 + 40/60 + 52.3/3600 = 4.681194°`.

Referencia de precisión en grados decimales:

| Decimales | Equivalencia aproximada |
| --- | --- |
| 4 | ~11 m |
| 5 | ~1.1 m |
| 6 | ~0.11 m |
| 7 | ~1.1 cm |

## 2. Distancia

Plana, sobre la proyección (metros):

```
D = sqrt((E2-E1)^2 + (N2-N1)^2)
```

Elipsoidal aproximada (haversine, radio medio R = 6 371 000 m):

```
phi1, phi2, dphi, dlambda en radianes
a = sin(dphi/2)^2 + cos(phi1)*cos(phi2)*sin(dlambda/2)^2
D = 2*R*asin(sqrt(a))
```

Para distancias cortas (< 10 km) la diferencia entre ambas es despreciable frente a la precisión
del levantamiento.

## 3. Azimut

```
az = atan2(E2-E1, N2-N1)   # radianes
az_grados = (grados(az) + 360) % 360
```

Se mide desde el norte, en sentido horario. Si el resultado es 0° el punto 2 está al norte.

## 4. Área de un polígono por coordenadas

Fórmula del polígono (Gauss / shoelace), coordenadas planas en metros:

```
A = 0.5 * |sum(E_i * N_{i+1} - E_{i+1} * N_i)|
```

```python
def area(e, n):
    s = 0.0
    for i in range(len(e)):
        j = (i + 1) % len(e)
        s += e[i] * n[j] - e[j] * n[i]
    return abs(s) / 2.0
```

El resultado es positivo sin importar el sentido de giro. Para pasar a hectáreas divide entre
10 000.

**No calcules áreas en grados.** Primero proyecta a 9377 y después aplica la fórmula.

## 5. Escalas y reducciones

Factor de escala de la proyección `k`: relación entre la distancia en el plano y la distancia sobre
el elipsoide. En Transversa de Mercator depende de la distancia al meridiano central; en el meridiano
central vale k0 (0.9992 en 9377).

Factor de elevación: una distancia medida a la altura `h` se reduce al elipsoide multiplicando por

```
(1 - h / R)   con R = 6 371 000 m
```

Factor combinado:

```
F = k * (1 - h/R)
```

Ejemplo: a 2 600 m de altura, `1 - 2600/6371000 = 0.999592`, es decir ~0.4 mm por metro
(~40 cm en 1 km). No es despreciable en levantamientos largos.

## 6. Alturas

```
h = H + N
```

`h` = altura elipsoidal (la que entrega el GNSS), `H` = altura ortométrica (sobre el nivel medio del
mar), `N` = ondulación geoidal del modelo (por ejemplo EGM2008). En Colombia `N` está en el orden de
decenas de metros, así que **nunca** uses `h` como cota de un plano.

## 7. Transformación entre datums (Helmert, 7 parámetros)

```
[X']   [ 1    -rz   ry ] [X]   [tx]
[Y'] = [ rz    1   -rx ] [Y] + [ty] * (1 + s*1e-6)
[Z']   [ -ry  rx    1  ] [Z]   [tz]
```

`t` en metros, `r` en radianes (o segundos de arco × 4.84813681e-6), `s` en partes por millón.
Para MAGNA-SIRGAS ↔ WGS84 los parámetros oficiales son prácticamente nulos; no los inventes.

## 8. Propagación de error (regla simple)

Para una distancia entre dos puntos con incertidumbre posicional `σA` y `σB`:

```
sigma_D = sqrt(sigmaA^2 + sigmaB^2)
```

Dos puntos con σ = 2 cm dan una distancia con σ ≈ 2.8 cm. Es una cota conservadora: no incluye
errores sistemáticos de la proyección.

## 9. Órdenes de magnitud de precisión

| Método | Precisión horizontal típica |
| --- | --- |
| GPS de mano | 3 – 10 m |
| GNSS estático post-proceso | 5 mm – 2 cm |
| RTK / NTRIP | 1 – 3 cm |
| Nivelación geométrica | 1 – 5 mm por km (depende de la clase) |

Estos valores son referencias de orden, no garantías: dependen de la época, la línea base, la
ionosfera y la geometría satelital.
