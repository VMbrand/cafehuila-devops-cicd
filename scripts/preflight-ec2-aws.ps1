[CmdletBinding()]
param(
    [string]$Profile = "curso",
    [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Stop"

function Stop-WithExplanation([string]$Message) {
    Write-Host "`nBLOQUEADO: $Message" -ForegroundColor Yellow
    exit 1
}

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Stop-WithExplanation "No se encontro AWS CLI v2."
}

$identityJson = aws sts get-caller-identity --profile $Profile --output json 2>$null
if ($LASTEXITCODE -ne 0 -or -not $identityJson) {
    Stop-WithExplanation "El perfil '$Profile' no tiene una sesion AWS valida. Ejecuta: aws login --profile $Profile"
}
$identity = $identityJson | ConvertFrom-Json

$null = aws ec2 describe-vpcs --profile $Profile --region $Region --max-results 5 --output json 2>$null
if ($LASTEXITCODE -ne 0) {
    Stop-WithExplanation "La cuenta autentica, pero EC2 no esta disponible en $Region. Activa EC2 en la cuenta/laboratorio antes de crear recursos."
}

$template = Join-Path $PSScriptRoot "..\infra\ec2-cafehuila.yaml"
$null = aws cloudformation validate-template --profile $Profile --region $Region --template-body "file://$template" --output json 2>$null
if ($LASTEXITCODE -ne 0) {
    Stop-WithExplanation "EC2 responde, pero CloudFormation no pudo validar la plantilla. Revisa el acceso a CloudFormation."
}

Write-Host "PRECHECK OK" -ForegroundColor Green
Write-Host "Cuenta: $($identity.Account)"
Write-Host "Principal: $($identity.Arn)"
Write-Host "Region: $Region"
Write-Host "EC2 y CloudFormation estan disponibles para CafeHuila." -ForegroundColor Green
