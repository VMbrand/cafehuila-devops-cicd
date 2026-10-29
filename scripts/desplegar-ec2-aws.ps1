[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$VpcId,
    [Parameter(Mandatory)] [string]$PublicSubnetId,
    [Parameter(Mandatory)] [string]$KeyName,
    [Parameter(Mandatory)] [string]$AdminCidr,
    [string]$Profile = "curso",
    [string]$Region = "us-east-1",
    [string]$StackName = "cafehuila-ec2",
    [switch]$Confirmar
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path $PSScriptRoot -Parent
$preflight = Join-Path $PSScriptRoot "preflight-ec2-aws.ps1"
$template = Join-Path $projectRoot "infra\ec2-cafehuila.yaml"

& $preflight -Profile $Profile -Region $Region
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if (-not $Confirmar) {
    Write-Host "`nNo se creo ningun recurso." -ForegroundColor Yellow
    Write-Host "Este comando creara una EC2 t3.micro, un volumen gp3 de 12 GB y un Security Group." -ForegroundColor Yellow
    Write-Host "Cuando hayas revisado costo, VPC, subred e IP administrativa, repite agregando -Confirmar." -ForegroundColor Yellow
    exit 2
}

aws cloudformation deploy `
    --profile $Profile `
    --region $Region `
    --stack-name $StackName `
    --template-file $template `
    --parameter-overrides "VpcId=$VpcId" "PublicSubnetId=$PublicSubnetId" "KeyName=$KeyName" "AdminCidr=$AdminCidr" `
    --no-fail-on-empty-changeset

if ($LASTEXITCODE -ne 0) { throw "CloudFormation no pudo crear o actualizar $StackName." }

aws cloudformation describe-stacks `
    --profile $Profile `
    --region $Region `
    --stack-name $StackName `
    --query "Stacks[0].Outputs" `
    --output table
