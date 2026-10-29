[CmdletBinding()]
param(
    [string]$Region = "us-east-1",
    [string]$Profile = "curso"
)

$ErrorActionPreference = "Stop"

function Stop-WithExplanation([string]$Message) {
    Write-Host "`nBLOQUEADO: $Message" -ForegroundColor Yellow
    Write-Host "No habilites DEPLOY_ENABLED ni guardes secretos de EC2 todavia." -ForegroundColor Yellow
    exit 1
}

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Stop-WithExplanation "No se encontro AWS CLI. Instala AWS CLI v2 o usa CloudShell del laboratorio institucional."
}

try {
    $respuestaIdentidad = aws sts get-caller-identity --profile $Profile --output json 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $respuestaIdentidad) { throw "AWS CLI returned an invalid session" }
    $identidad = $respuestaIdentidad | ConvertFrom-Json
} catch {
    Stop-WithExplanation "No hay credenciales AWS validas. Inicia el laboratorio AWS Educate/AWS Academy y configura sus credenciales temporales."
}

Write-Host "Sesion AWS valida" -ForegroundColor Green
Write-Host "Perfil: $Profile"
Write-Host "Cuenta: $($identidad.Account)"
Write-Host "Principal: $($identidad.Arn)"
Write-Host "Region objetivo: $Region"

try {
    $null = aws ec2 describe-availability-zones --profile $Profile --region $Region --all-availability-zones --output json 2>$null
    if ($LASTEXITCODE -ne 0) { throw "EC2 check failed" }
} catch {
    Stop-WithExplanation "La sesion existe, pero EC2 no esta habilitado para esta cuenta o region. Pide al profesor activar EC2 en la cuenta academica o asignarte un laboratorio con EC2 habilitado."
}

Write-Host "EC2 accesible en $Region" -ForegroundColor Green
Write-Host "`nSiguiente paso: crear la EC2 y cargar EC2_HOST + EC2_SSH_KEY en GitHub. Solo despues activa DEPLOY_ENABLED=true." -ForegroundColor Cyan
