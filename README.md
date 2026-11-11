# Agentes de Catastro y Geodesia (Colombia)

Sistema de tres agentes de IA para consultas territoriales colombianas. Un **coordinador** en la
nube atiende al usuario, clasifica la consulta y delega en dos especialistas que corren **en local**
con Ollama.

```
                 ┌──────────────────────────┐
   Usuario ────► │ coordinador  (NUBE)      │  triaje + síntesis
                 │ deepseek-v4.1-flash-free │  no responde dominio
                 └───────┬──────────┬───────┘
                         │ subagent │ subagent
                 ┌───────▼──────┐ ┌─▼────────────┐
                 │ catastro     │ │ geodesia     │  LOCAL · 8 GB VRAM
                 │ ornith:9b    │ │ qwen3:8b     │  contexto 8192
                 └──────────────┘ └──────────────┘
```

## Qué resuelve cada agente

| Agente | Modo | Modelo | Ejecución | Alcance |
| --- | --- | --- | --- | --- |
| `coordinador` | `primary` | `opencode/deepseek-v4.1-flash-free` | Nube | Atiende, clasifica, delega, sintetiza |
| `catastro` | `subagent` | `ollama/ornith:9b` | Local | Catastro multipropósito, LADM, folio de matrícula, avalúos, linderos, PH |
| `geodesia` | `subagent` | `ollama/qwen3:8b` | Local | Datum, MAGNA-SIRGAS, EPSG, proyecciones, coordenadas, GNSS, precisión |

Solo el coordinador aparece en el selector de agentes. Todo pasa por su triaje.

## Requisitos

| Componente | Mínimo | Notas |
| --- | --- | --- |
| OpenCode | V2 (probado con 2.0.28) | Usa `agents/`, `permissions` y `skills` de V2 |
| Ollama | 0.40 o superior | Debe estar corriendo en `127.0.0.1:11434` |
| GPU | 8 GB de VRAM | Los dos modelos caben justos a 8192 tokens de contexto |
| Disco | ~12 GB libres | 5.6 GB + 5.2 GB de pesos |
| Python | 3.10+ con `pyproj` | Opcional: solo para verificar transformaciones |

> Con menos de 8 GB de VRAM los modelos entran en RAM y las respuestas pasan de segundos a minutos.
> Ver `docs/03-modelos.md` para las alternativas.

## Puesta en marcha

### 1. Instalar los modelos

```powershell
.\scripts\setup.ps1
```

Ese script descarga `ornith:9b` y `qwen3:8b`, fija el contexto en 8192 tokens y deja un solo modelo
cargado a la vez. Después **reinicia la aplicación de Ollama** para que tome las variables.

Equivalente manual:

```powershell
ollama pull ornith:9b
ollama pull qwen3:8b
setx OLLAMA_CONTEXT_LENGTH 8192
setx OLLAMA_MAX_LOADED_MODELS 1
```

### 2. (Opcional) Verificar cálculos geodésicos

```powershell
python -m pip install pyproj
```

### 3. Abrir el proyecto

```powershell
opencode "C:\ruta\a\agentes-catastro-geodesia"
```

Elige el agente **coordinador** y escribe tu consulta.

## Cómo usarlo

```powershell
opencode run --agent coordinador "¿Qué es el folio de matrícula inmobiliaria?"
opencode run --agent coordinador "Convierte 4.6812, -74.0521 de MAGNA-SIRGAS a Origen Nacional"
```

O desde la interfaz: abre OpenCode en esta carpeta y habla con `coordinador`.

## Pruebas

```powershell
.\scripts\test.ps1
```

Ejecuta los cuatro casos de control:

| Consulta | Comportamiento esperado |
| --- | --- |
| "¿Qué es el folio de matrícula inmobiliaria?" | Delega en `catastro` |
| "Convierte 4.6812, -74.0521 a Origen Nacional" | Delega en `geodesia` |
| "Transforma estas coordenadas y calcula el área del predio" | `geodesia` → `catastro` |
| "¿Cuál es la mejor receta de torta?" | Rechaza en 3 líneas y redirige |

Valor de control geodésico: `-74.0521, 4.6812` (EPSG:4686) → **E 4 883 355.719 / N 2 075 354.685**
(EPSG:9377). Si tu cálculo se aleja más de unos metros, hay un error de orden o de CRS.

## Estructura

```
.
├─ AGENTS.md                    definición del sistema (lenguaje natural)
├─ opencode.json                modelo por defecto + proveedor Ollama
├─ .opencode/
│  ├─ agents/
│  │  ├─ coordinador.md         primary · nube · permisos de subagent
│  │  ├─ catastro.md            subagent · ornith:9b · skill catastro-col
│  │  └─ geodesia.md            subagent · qwen3:8b · skill geodesia-col
│  └─ skills/
│     ├─ catastro-col/          glosario + normativa
│     └─ geodesia-col/          EPSG verificados + fórmulas
├─ docs/
│  ├─ 02-configuracion-agentes.md
│  └─ 03-modelos.md
└─ scripts/
   ├─ setup.ps1
   └─ test.ps1
```

## Personalización

**Cambiar el modelo de un especialista:** edita `model:` en el archivo del agente.

**Probar un especialista directamente:** cambia su `mode: subagent` por `mode: all`; aparecerá en el
selector. Recuerda revertirlo.

**Cambiar el coordinador a local:** hay que tocar dos archivos, porque en un agente `primary` el
modelo de la sesión tiene prioridad:

```json
// opencode.json
"model": "ollama/qwen3:8b"
```
```yaml
# .opencode/agents/coordinador.md
model: ollama/qwen3:8b
```

## Diagnóstico

| Síntoma | Causa probable | Solución |
| --- | --- | --- |
| `Model unavailable: ollama/ornith:9b` | Falta el modelo | `ollama pull ornith:9b` |
| `Model unavailable` con el modelo descargado | Ollama apagado | Abrir la app o `ollama serve` |
| Respuestas de varios minutos | Modelo en CPU, sin VRAM suficiente | `ollama ps` para ver `100% GPU` |
| Contexto truncado o error de memoria | Contexto muy alto | `setx OLLAMA_CONTEXT_LENGTH 8192` |
| El coordinador no delega | Permisos de `subagent` | Revisar `permissions` en `coordinador.md` |
| Usa un modelo distinto al configurado | Modelo de sesión elegido en `/models` | Elegir el modelo correcto o reiniciar la sesión |

## Advertencia sobre normativa

Los agentes están instruidos para **no inventar** números de resolución, códigos EPSG ni
coordenadas, y para advertir cuando un dato no se puede verificar. Aun así, la normativa colombiana
cambia: toda cita debe confirmarse en `igac.gov.co`, `snr.gov.co` o `funcionpublica.gov.co` antes de
usarse en un trámite real.

Este repositorio es material académico. No constituye asesoría jurídica ni técnica certificada.
