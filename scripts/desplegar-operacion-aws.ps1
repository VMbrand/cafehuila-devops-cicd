[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$InstanceId,
    [Parameter(Mandatory)] [string]$AlertEmail,
    [string]$Profile = "curso",
    [string]$Region = "us-east-1",
    [string]$StackName = "cafehuila-operacion",
    [int]$BudgetLimit = 5,
    [switch]$Confirmar
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path $PSScriptRoot -Parent
$preflight = Join-Path $PSScriptRoot "preflight-ec2-aws.ps1"
$template = Join-Path $projectRoot "infra\operacion-cafehuila.yaml"

& $preflight -Profile $Profile -Region $Region
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if (-not $Confirmar) {
    Write-Host "`nNo se crearon alertas ni suscripciones." -ForegroundColor Yellow
    Write-Host "Este comando crea SNS, dos alarmas CloudWatch y un presupuesto mensual de USD $BudgetLimit." -ForegroundColor Yellow
    Write-Host "Repite con -Confirmar despues de revisar InstanceId, correo y costo." -ForegroundColor Yellow
    exit 2
}

aws cloudformation deploy `
    --profile $Profile `
    --region $Region `
    --stack-name $StackName `
    --template-file $template `
    --parameter-overrides "InstanceId=$InstanceId" "AlertEmail=$AlertEmail" "BudgetLimit=$BudgetLimit" `
    --no-fail-on-empty-changeset

if ($LASTEXITCODE -ne 0) { throw "CloudFormation no pudo crear o actualizar $StackName." }

Write-Host "Se enviara una confirmacion SNS a $AlertEmail. La suscripcion no queda activa hasta confirmarla." -ForegroundColor Cyan
