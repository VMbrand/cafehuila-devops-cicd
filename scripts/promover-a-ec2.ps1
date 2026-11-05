[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$PublicHost,
    [Parameter(Mandatory)] [string]$KeyPath,
    [string]$Image = 'ghcr.io/vmbrand/cafehuila-devops-cicd',
    [string]$Tag = (git rev-parse HEAD).Trim(),
    [switch]$Confirmar
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$composeFile = Join-Path $projectRoot 'compose.prod.yml'

if (-not (Test-Path -LiteralPath $KeyPath)) {
    throw "No existe la llave SSH: $KeyPath"
}

if (-not $Confirmar) {
    Write-Host 'No se modifico produccion.' -ForegroundColor Yellow
    Write-Host "Se promocionara $Image con tag $Tag a $PublicHost." -ForegroundColor Yellow
    Write-Host 'Repite con -Confirmar despues de revisar host, llave e imagen.' -ForegroundColor Yellow
    exit 2
}

scp -o StrictHostKeyChecking=yes -i $KeyPath $composeFile "ec2-user@$PublicHost`:app/compose.prod.yml"
if ($LASTEXITCODE -ne 0) { throw 'No se pudo copiar compose.prod.yml a la EC2.' }

$remote = @"
set -euo pipefail
cd app
export IMAGEN='$Image' TAG='$Tag'
docker compose -f compose.prod.yml pull
docker compose -f compose.prod.yml up -d --wait
echo "TAG=$Tag" > desplegado.env
docker image prune -af --filter "until=72h"
"@

$remote | ssh -o StrictHostKeyChecking=yes -i $KeyPath "ec2-user@$PublicHost" 'bash -s'
if ($LASTEXITCODE -ne 0) { throw 'La EC2 no pudo actualizar los contenedores.' }

$health = Invoke-RestMethod -Uri "http://$PublicHost/api/health" -TimeoutSec 30
$expectedVersion = $Tag.Substring(0, [Math]::Min(7, $Tag.Length))
if ($health.version -ne $expectedVersion) {
    throw "Health check inesperado: version=$($health.version), esperada=$expectedVersion."
}

Write-Host "Produccion validada: $($health | ConvertTo-Json -Compress)" -ForegroundColor Green
