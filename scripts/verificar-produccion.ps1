[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$PublicHost,
    [string]$ExpectedTag,
    [string]$KeyPath,
    [string]$Image = 'ghcr.io/vmbrand/cafehuila-devops-cicd'
)

$ErrorActionPreference = 'Stop'
$health = Invoke-RestMethod -Uri "http://$PublicHost/api/health" -TimeoutSec 30

if ($health.estado -ne 'ok' -or $health.entorno -ne 'produccion') {
    throw "Health check inválido: $($health | ConvertTo-Json -Compress)"
}

if ($ExpectedTag) {
    $expectedVersion = $ExpectedTag.Substring(0, [Math]::Min(7, $ExpectedTag.Length))
    if ($health.version -ne $expectedVersion) {
        throw "Versión inválida: $($health.version); se esperaba $expectedVersion."
    }
}

Write-Host "Endpoint público OK: $($health | ConvertTo-Json -Compress)" -ForegroundColor Green

if ($KeyPath) {
    if (-not (Test-Path -LiteralPath $KeyPath)) { throw "No existe la llave SSH: $KeyPath" }
    ssh -o StrictHostKeyChecking=yes -i $KeyPath "ec2-user@$PublicHost" "cd app && export IMAGEN='$Image' && export `$(cat desplegado.env) && cat desplegado.env && docker compose -f compose.prod.yml ps"
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo verificar el estado de contenedores en la EC2.' }
}
