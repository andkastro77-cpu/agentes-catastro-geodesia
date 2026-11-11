# Ejecuta los cuatro casos de control del sistema de agentes
# Uso:  .\scripts\test.ps1
# Requiere: OpenCode V2 y los modelos locales descargados (ver setup.ps1)

$ErrorActionPreference = 'Continue'

$cli = (Get-Command opencode -ErrorAction SilentlyContinue)
if (-not $cli) {
    $desktop = "$env:LOCALAPPDATA\Programs\@opencodedesktop\resources\opencode-cli.exe"
    if (Test-Path $desktop) { $cli = @{ Source = $desktop } }
}

if (-not $cli) {
    Write-Host "No encontre el ejecutable de OpenCode." -ForegroundColor Red
    Write-Host "Agrega 'opencode' al PATH o ejecuta los comandos del README a mano." -ForegroundColor Red
    exit 1
}

$exe = $cli.Source
$project = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

$casos = @(
    @{ Nombre = "Catastro";     Pregunta = "Que es el folio de matricula inmobiliaria?" },
    @{ Nombre = "Geodesia";     Pregunta = "Convierte la coordenada 4.6812, -74.0521 de MAGNA-SIRGAS geografico a Origen Nacional" },
    @{ Nombre = "Mixta";        Pregunta = "Transforma estas coordenadas y calcula el area del predio: 4.6812, -74.0521; 4.6815, -74.0518; 4.6818, -74.0522" },
    @{ Nombre = "Fuera de tema"; Pregunta = "Cual es la mejor receta de torta de chocolate?" }
)

Write-Host "Proyecto: $project" -ForegroundColor Cyan
Write-Host ""

foreach ($caso in $casos) {
    Write-Host ("=" * 70) -ForegroundColor DarkGray
    Write-Host "CASO: $($caso.Nombre)" -ForegroundColor Cyan
    Write-Host "PREGUNTA: $($caso.Pregunta)" -ForegroundColor DarkGray
    Write-Host ("=" * 70) -ForegroundColor DarkGray

    Push-Location $project
    & $exe run --agent coordinador --title "Prueba $($caso.Nombre)" $caso.Pregunta 2>&1 |
        Where-Object { $_ -notmatch 'NativeCommandError|CategoryInfo|FullyQualifiedErrorId|^\s*\+' }
    Pop-Location

    Write-Host ""
}

Write-Host "Revisa que: catastro delegue en 'catastro', geodesia en 'geodesia', la mixta use los dos" -ForegroundColor Yellow
Write-Host "y la ultima rechace en 3 lineas sin responder la receta." -ForegroundColor Yellow
