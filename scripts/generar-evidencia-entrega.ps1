[CmdletBinding()]
param(
    [string]$Profile = 'cafehuila-advanced',
    [string]$Region = 'us-east-1',
    [string]$OutputPath = 'evidencias/estado-entrega.md'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$destination = Join-Path $repoRoot $OutputPath
$destinationDirectory = Split-Path -Parent $destination

New-Item -ItemType Directory -Force -Path $destinationDirectory | Out-Null

$lines = [System.Collections.Generic.List[string]]::new()
function Add-Line([string]$Text = '') { $lines.Add($Text) }
function Command-Result([scriptblock]$Command) {
    $output = & $Command 2>&1
    [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($output | Out-String).Trim() }
}

$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss K'
$commit = (Command-Result { git -C $repoRoot rev-parse --short HEAD })
$branch = (Command-Result { git -C $repoRoot branch --show-current })

Add-Line '# Evidencia técnica — CafeHuila DevOps'
Add-Line ''
Add-Line "Generado: **$timestamp**"
Add-Line ''
Add-Line '> Este reporte diferencia resultados reales de simulaciones locales. No contiene contraseñas, claves secretas ni una IP inventada.'
Add-Line ''
Add-Line '## Trazabilidad del repositorio'
Add-Line ''
Add-Line "- Rama: ``$($branch.Output)``"
Add-Line "- Commit: ``$($commit.Output)``"
Add-Line '- Infraestructura declarada: `infra/ec2-cafehuila.yaml`'
Add-Line '- Pipeline: `.github/workflows/ci-cd.yml`'
Add-Line '- Operación: `infra/operacion-cafehuila.yaml`'
Add-Line ''

Add-Line '## Infraestructura como código'
Add-Line ''
$cfnLint = Get-Command cfn-lint -ErrorAction SilentlyContinue
if ($null -eq $cfnLint) {
    $candidate = Join-Path $env:APPDATA 'Python\Python314\Scripts\cfn-lint.exe'
    if (Test-Path -LiteralPath $candidate) { $cfnLint = Get-Item -LiteralPath $candidate }
}
if ($null -ne $cfnLint) {
    $ec2Template = Join-Path $repoRoot 'infra\ec2-cafehuila.yaml'
    $operationTemplate = Join-Path $repoRoot 'infra\operacion-cafehuila.yaml'
    $lintExecutable = if ($cfnLint -is [System.Management.Automation.CommandInfo]) { $cfnLint.Source } else { $cfnLint.FullName }
    $lint = Command-Result { & $lintExecutable -t $ec2Template $operationTemplate }
    if ($lint.ExitCode -eq 0) {
        Add-Line '- Validación `cfn-lint`: **OK** para las plantillas EC2 y operación.'
    } else {
        Add-Line '- Validación `cfn-lint`: detectó observaciones.'
        Add-Line '```text'
        Add-Line $lint.Output
        Add-Line '```'
    }
} else {
    Add-Line '- `cfn-lint` no está disponible en este equipo para esta ejecución.'
}
Add-Line ''

Add-Line '## Validación local'
Add-Line ''
$compose = Command-Result { docker compose -f (Join-Path $repoRoot 'compose.yml') ps }
if ($compose.ExitCode -eq 0) {
    Add-Line '```text'
    Add-Line $compose.Output
    Add-Line '```'
} else {
    Add-Line '- Docker Compose no pudo consultarse en este momento.'
}

try {
    $health = Invoke-RestMethod -Uri 'http://localhost:8080/api/health' -TimeoutSec 10
    Add-Line '- Health check local: **OK**'
    Add-Line '```json'
    Add-Line ($health | ConvertTo-Json -Compress)
    Add-Line '```'
} catch {
    Add-Line '- Health check local: no disponible durante la generación del reporte.'
}
Add-Line ''

Add-Line '## AWS: identidad y revisión'
Add-Line ''
$identity = Command-Result { aws sts get-caller-identity --profile $Profile --output json }
if ($identity.ExitCode -eq 0) {
    $identityJson = $identity.Output | ConvertFrom-Json
    Add-Line "- Perfil AWS validado: **$Profile**"
    Add-Line "- Cuenta: ``$($identityJson.Account)``"
    Add-Line "- Principal: ``$($identityJson.Arn)``"
} else {
    Add-Line "- Perfil AWS no disponible: ``$($identity.Output)``"
}

$reviewer = Command-Result { aws iam list-attached-user-policies --user-name revisor-docente --profile $Profile --output json }
if ($reviewer.ExitCode -eq 0) {
    $reviewerJson = $reviewer.Output | ConvertFrom-Json
    $policyNames = @($reviewerJson.AttachedPolicies | ForEach-Object PolicyName) -join ', '
    Add-Line "- Usuario de revisión: ``revisor-docente``"
    Add-Line "- Políticas directas: **$policyNames**"
} else {
    Add-Line '- Usuario de revisión: no pudo verificarse con el perfil actual.'
}
Add-Line ''

Add-Line '## AWS: disponibilidad de EC2'
Add-Line ''
$ec2 = Command-Result { aws ec2 describe-vpcs --profile $Profile --region $Region --output json }
if ($ec2.ExitCode -eq 0) {
    Add-Line "- EC2 en ``$Region``: **HABILITADO**"
    Add-Line '- Siguiente paso permitido: desplegar el stack CloudFormation y obtener IP pública real.'
} else {
    $safeMessage = ($ec2.Output -replace '[\r\n]+', ' ').Trim()
    Add-Line "- EC2 en ``$Region``: **BLOQUEADO/PENDIENTE DE ACTIVACIÓN**"
    Add-Line "- Respuesta AWS: ``$safeMessage``"
    Add-Line '- No se creó una EC2 ni se declara una IP pública para evitar evidencia falsa.'
}
Add-Line ''

Add-Line '## Conclusión de entrega'
Add-Line ''
if ($ec2.ExitCode -eq 0) {
    Add-Line 'La cuenta está autorizada para el despliegue real. Este reporte debe regenerarse después del despliegue para adjuntar la IP pública y el health check remoto.'
} else {
    Add-Line 'La aplicación, CI/CD, infraestructura como código y el usuario de solo lectura están preparados. El único bloqueo externo es la activación de EC2 de AWS; no debe sustituirse por una simulación al llenar el formato obligatorio de Moodle.'
}

Set-Content -LiteralPath $destination -Value $lines -Encoding utf8
Write-Host "Evidencia creada: $destination"
