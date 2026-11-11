# Configuración de los agentes

Tabla de referencia de la entrega. El detalle operativo vive en cada archivo de
`.opencode/agents/`; aquí está la vista de conjunto.

## Vista general

| | `coordinador` | `catastro` | `geodesia` |
| --- | --- | --- | --- |
| **Archivo** | `.opencode/agents/coordinador.md` | `.opencode/agents/catastro.md` | `.opencode/agents/geodesia.md` |
| **Modo** | `primary` | `subagent` | `subagent` |
| **Modelo** | `opencode/deepseek-v4.1-flash-free` | `ollama/ornith:9b` | `ollama/qwen3:8b` |
| **Ejecución** | Nube | Local (8 GB VRAM) | Local (8 GB VRAM) |
| **Pasos máximos** | 16 | 10 | 10 |
| **Skill** | ninguna | `catastro-col` | `geodesia-col` |
| **Habla con el usuario** | Sí | No (lo invoca el coordinador) | No (lo invoca el coordinador) |

## Herramientas por agente

En OpenCode V2 las herramientas se controlan con `permissions` (lista ordenada; **gana la última
regla que coincide**). No existe el campo `tools:` de V1.

| Acción | `coordinador` | `catastro` | `geodesia` |
| --- | --- | --- | --- |
| `read`, `glob`, `grep` | allow | allow | allow |
| `webfetch` | allow | allow | allow |
| `websearch` | (heredado) | (heredado) | (heredado) |
| `edit` (escribir archivos) | **deny** | **deny** | **deny** |
| `shell` | **deny** | **deny** | deny general; allow `python *`, `proj *`, `cs2cs *`, `projinfo *` |
| `skill` | deny `*` | deny `*` → allow `catastro-*` | deny `*` → allow `geodesia-*` |
| `subagent` | deny `*` → allow `catastro`, `geodesia` | deny `*` | deny `*` |

Lectura de la tabla:

- El coordinador **no puede escribir ni ejecutar comandos**: solo lee, consulta la web y delega.
- Los especialistas **no pueden crear archivos**: responden, no modifican el proyecto.
- Solo el coordinador puede lanzar subagentes, y solo los dos permitidos.
- Geodesia es el único con shell, y únicamente para cálculos (pyproj / PROJ), no para instalar cosas.

## Por qué `subagent` y no `all`

Con `mode: subagent`, los agentes A y B solo existen dentro de una sesión hija: el usuario no los
puede seleccionar en el menú de agentes. Eso garantiza que **todo** pase por el triaje del
coordinador.

Si quieres probarlos por separado, cambia temporalmente su `mode` a `all`; aparecerán en el selector
y podrás hablarles directo. Recuerda devolverlo a `subagent` antes de entregar.

## Modelo de sesión vs. modelo del agente

Detalle de V2 verificado en pruebas: en un agente `primary`, **el modelo de la sesión tiene
prioridad** sobre el `model:` del archivo del agente. En un `subagent`, en cambio, sí se usa el
modelo configurado.

Por eso el proyecto fija el modelo en `opencode.json`:

```json
"model": "opencode/deepseek-v4.1-flash-free"
```

Así cualquier sesión nueva en esta carpeta arranca con el coordinador en la nube. Si el usuario
cambia el modelo desde `/models`, esa elección gana hasta que abra otra sesión.

Los subagentes no se ven afectados: `catastro` siempre intenta `ollama/ornith:9b` y `geodesia`
siempre intenta `ollama/qwen3:8b`.

## Flujo de una consulta

```
1. El usuario escribe al coordinador.
2. El coordinador clasifica: catastro, geodesia, mixta o fuera de alcance.
3. Si es de dominio, llama a subagent con un encargo autocontenido.
4. El especialista carga su skill, responde con su plantilla y declara supuestos.
5. El coordinador integra, conserva las advertencias y entrega.
```

## Cómo verificar que quedó bien configurado

1. El selector de agentes muestra `coordinador` y **no** muestra `catastro` ni `geodesia`.
2. Al preguntar por un folio de matrícula, la respuesta dice que se consultó al agente de catastro.
3. Al preguntar por un EPSG, la respuesta cita el código y las unidades.
4. Al preguntar algo fuera de tema, el coordinador lo declara en lugar de improvisar.
