[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$InstanceId,
    [string]$Profile = 'brando',
    [string]$Region = 'us-east-2',
    [switch]$Confirmar
)

$ErrorActionPreference = 'Stop'
$state = aws ec2 describe-instances --profile $Profile --region $Region --instance-ids $InstanceId --query 'Reservations[0].Instances[0].State.Name' --output text
if ($LASTEXITCODE -ne 0) { throw 'No se pudo consultar el estado de la instancia.' }

if (-not $Confirmar) {
    Write-Host "No se detuvo nada. Estado actual: $state" -ForegroundColor Yellow
    Write-Host 'Detener la EC2 reduce cómputo, pero conserva el volumen y puede cambiar la IP pública al volver a iniciarla.' -ForegroundColor Yellow
    Write-Host 'Repite con -Confirmar para detenerla.' -ForegroundColor Yellow
    exit 2
}

if ($state -eq 'running') {
    aws ec2 stop-instances --profile $Profile --region $Region --instance-ids $InstanceId --output table
} else {
    Write-Host "No se detuvo: estado actual $state." -ForegroundColor Cyan
}
