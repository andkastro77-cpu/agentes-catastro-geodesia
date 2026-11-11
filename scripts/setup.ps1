# Descarga e instala los modelos locales del sistema de agentes
# Uso:  .\scripts\setup.ps1
# Requiere: Ollama instalado y en el PATH.

$ErrorActionPreference = 'Stop'

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "    OK  $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "    !!!  $msg" -ForegroundColor Yellow }

Write-Step "Verificando Ollama"
$ollama = Get-Command ollama -ErrorAction SilentlyContinue
if (-not $ollama) {
    Write-Host "Ollama no esta instalado o no esta en el PATH." -ForegroundColor Red
    Write-Host "Descargalo en https://ollama.com/download y vuelve a ejecutar este script." -ForegroundColor Red
    exit 1
}
$version = (ollama --version) 2>&1 | Out-String
Write-Ok $version.Trim()

Write-Step "Comprobando que el servidor responda"
$serverUp = $false
try {
    $tags = Invoke-RestMethod -Uri "http://127.0.0.1:11434/api/tags" -TimeoutSec 5
    $serverUp = $true
    Write-Ok ("Modelos instalados: " + $tags.models.Count)
} catch {
    Write-Warn "El servidor no responde. Abre la aplicacion de Ollama o ejecuta 'ollama serve' en otra terminal."
}

Write-Step "Descargando modelos (aprox. 11 GB)"
foreach ($model in @('ornith:9b', 'qwen3:8b')) {
    Write-Host "    -> $model"
    ollama pull $model
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Fallo la descarga de $model." -ForegroundColor Red
        exit 1
    }
}

Write-Step "Configurando limites para 8 GB de VRAM"
setx OLLAMA_CONTEXT_LENGTH 8192    | Out-Null
setx OLLAMA_MAX_LOADED_MODELS 1    | Out-Null
setx OLLAMA_KEEP_ALIVE 5m          | Out-Null
Write-Ok "Variables guardadas para el usuario actual"

Write-Step "Resumen"
ollama list

Write-Host ""
Write-Warn "Reinicia la aplicacion de Ollama para que tome las variables nuevas."
Write-Host "    Luego ejecuta:  .\scripts\test.ps1" -ForegroundColor Cyan
Write-Host ""

if (Get-Command python -ErrorAction SilentlyContinue) {
    $hasPyproj = (python -c "import pyproj" 2>&1) -notmatch 'ModuleNotFoundError'
    if ($hasPyproj) {
        Write-Ok "pyproj disponible"
    } else {
        Write-Warn "pyproj no esta instalado (opcional, solo para verificar transformaciones):"
        Write-Host "    python -m pip install pyproj"
    }
}
