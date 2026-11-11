# Modelos y hardware

## Los dos modelos locales

Datos tomados del catálogo de Ollama (`ollama.com/library`). Ambos soportan *tools* (llamado de
herramientas) y *thinking* (razonamiento), que es lo que permite usarlos como agentes.

| | `ornith:9b` | `qwen3:8b` |
| --- | --- | --- |
| Familia | Ornith 1.0 (agentes de código, automejora) | Qwen3 (denso, propósito general) |
| Parámetros | 9 B | 8 B |
| Peso descargado | 5.6 GB (Q4) | 5.2 GB (Q4) |
| Contexto nativo | 256 K | 40 K |
| Fuerte en | Razonamiento estructurado, seguir instrucciones largas | Cálculo, explicación paso a paso, español |
| Asignado a | `catastro` | `geodesia` |
| Alternativas | `ornith:9b-q8_0` (9.5 GB, no cabe) | `qwen3:8b-q8_0` (8.9 GB, no cabe) |

Variantes que **no** sirven para 8 GB de VRAM: `ornith:35b` (21 GB), `qwen3:14b` (9.3 GB),
`qwen3:32b` (20 GB).

## Presupuesto de VRAM (8 GB)

| Componente | Aproximado |
| --- | --- |
| Pesos del modelo (Q4) | 5.2 – 5.6 GB |
| Caché KV a 8192 tokens | 0.6 – 1.3 GB |
| Overhead del runtime | 0.3 – 0.5 GB |
| **Total** | **6.1 – 7.4 GB** |

Conclusión: **cabe con contexto de 8192 tokens**, pero no hay margen para 16 K ni para tener los dos
modelos cargados a la vez.

Configuración recomendada (PowerShell, permanente para el usuario):

```powershell
setx OLLAMA_CONTEXT_LENGTH 8192
setx OLLAMA_MAX_LOADED_MODELS 1
setx OLLAMA_KEEP_ALIVE 5m
```

Cierra y reabre la terminal después de `setx`. Sin la última variable, Ollama descarga el modelo tras
5 minutos de inactividad y la siguiente pregunta tarda en responder.

## Descarga

```powershell
ollama pull ornith:9b
ollama pull qwen3:8b
```

Total: ~11 GB de disco. Verificación:

```powershell
ollama list
ollama run ornith:9b "Responde solo: ok"
ollama ps          # muestra qué está cargado y cuánto va a GPU/CPU
```

En `ollama ps`, la columna de procesador debería decir `100% GPU`. Si dice `CPU` o un porcentaje
mixto, el modelo no está entrando completo en la tarjeta y las respuestas serán lentas.

## Este equipo no cumple el requisito

Verificado en esta máquina:

| Recurso | Valor real |
| --- | --- |
| CPU | AMD Ryzen 5 5625U (6 núcleos) |
| RAM | 5.8 GB |
| GPU | AMD Radeon integrada (~2 GB compartidos) |
| Disco libre | 118 GB |

Con 5.8 GB de RAM, los pesos de `ornith:9b` (5.6 GB) **no caben** junto con Windows. Ejecutarlos aquí
provocaría paginación a disco y respuestas de varios minutos, no un agente usable.

Opciones:

1. **PC con 8 GB de VRAM** (el objetivo del ejercicio): usar los modelos tal como están configurados.
2. **Probar el flujo en este portátil** con `qwen3:1.7b` (1.4 GB) o `qwen3:4b` (2.5 GB), cambiando el
   `model:` de los agentes solo para la prueba.
3. **Respaldo en nube** para los especialistas: reemplazar `ollama/...` por un modelo de nube cuando
   no haya hardware. El coordinador ya corre en nube.

## El coordinador

| | |
| --- | --- |
| Modelo | `opencode/deepseek-v4.1-flash-free` |
| Ejecución | Nube |
| Por qué | Debe estar siempre disponible (es la puerta de entrada) y el triaje exige buen razonamiento sobre instrucciones largas |
| Costo | Modelo gratuito del proveedor `opencode` |

Cambiarlo requiere dos líneas, porque en un agente `primary` el modelo de la sesión tiene
prioridad sobre el del archivo del agente:

```json
// opencode.json
"model": "ollama/qwen3:8b"
```
```yaml
# .opencode/agents/coordinador.md
model: ollama/qwen3:8b
```

Con eso todo el sistema quedaría local, pero más lento y con peor enrutamiento.

## Descubrimiento automático

OpenCode detecta Ollama en `http://127.0.0.1:11434` sin configuración adicional, lee la lista de
modelos y sus capacidades (contexto, tools). Por eso los agentes se referencian como
`ollama/<nombre-del-modelo>`. El `opencode.json` de este proyecto solo deja explícita la URL.

Si Ollama está apagado o el modelo no está descargado, la sesión del coordinador funciona pero el
subagente falla; el coordinador está instruido para reportarlo con el comando `ollama pull` que falta.

## Herramientas de cálculo (sí instaladas aquí)

El agente de geodesia necesita verificar sus transformaciones. En este equipo ya quedó disponible:

```powershell
python --version        # Python 3.14.3
python -c "import pyproj; print(pyproj.__version__)"   # pyproj 3.8.0
```

Prueba de control (Bogotá → Origen Nacional):

```powershell
python -c "from pyproj import Transformer; t=Transformer.from_crs('EPSG:4686','EPSG:9377',always_xy=True); print([round(v,3) for v in t.transform(-74.0521,4.6812)])"
# [4883355.719, 2075354.685]
```

Si `pyproj` no estuviera instalado, el agente lo detecta y cae a las fórmulas de la skill, avisando
que el cálculo no fue verificado con PROJ.
