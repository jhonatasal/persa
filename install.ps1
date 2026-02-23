# Persa CLI — Windows Installer
#Requires -Version 5.1

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Lê cli.conf
$config = @{ CLI_NAME = "persa"; CLI_VERSION = "1.0.0" }
foreach ($line in (Get-Content (Join-Path $ScriptDir "cli.conf"))) {
  if ($line -match '^CLI_NAME="?([^"]+)"?$')    { $config.CLI_NAME    = $Matches[1] }
  if ($line -match '^CLI_VERSION="?([^"]+)"?$') { $config.CLI_VERSION = $Matches[1] }
}

$cliName    = $config.CLI_NAME
$cliVersion = $config.CLI_VERSION

# Diretório de instalação (fixo, independente do nome da CLI)
$InstallDir     = "$env:USERPROFILE\.config\powershell\port-manager"
$EntryPoint     = "$InstallDir\persa.ps1"
$SourceRegistry = "$InstallDir\.source"
$ProfileFile    = $PROFILE.CurrentUserAllHosts

Write-Host "Instalando $cliName v$cliVersion..."

# Cria diretório de instalação
if (-not (Test-Path $InstallDir)) {
  New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

# Copia os arquivos (persa.ps1 lê cli.conf de $PSScriptRoot)
Copy-Item (Join-Path $ScriptDir "persa.ps1") $EntryPoint -Force
Copy-Item (Join-Path $ScriptDir "cli.conf")  "$InstallDir\cli.conf" -Force

# Salva o caminho do projeto para o comando 'update'
Set-Content -Path $SourceRegistry -Value $ScriptDir -Encoding UTF8

# Garante que o diretório e arquivo do perfil existem
$ProfileDir = Split-Path -Parent $ProfileFile
if (-not (Test-Path $ProfileDir)) {
  New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
}
if (-not (Test-Path $ProfileFile)) {
  New-Item -ItemType File -Path $ProfileFile -Force | Out-Null
}

# Remove entrada antiga e adiciona a nova
$content = Get-Content $ProfileFile -Raw -ErrorAction SilentlyContinue
if ($content -match 'port-manager') {
  $lines = $content -split "`n" | Where-Object { $_ -notmatch 'port-manager' }
  Set-Content -Path $ProfileFile -Value ($lines -join "`n").TrimEnd() -Encoding UTF8
}
Add-Content -Path $ProfileFile -Value "`n. `"$EntryPoint`"" -Encoding UTF8

Write-Host "✔ Instalado em $EntryPoint" -ForegroundColor Green
Write-Host "✔ Adicionado ao perfil: $ProfileFile" -ForegroundColor Green
Write-Host "✔ Para atualizar: $cliName update" -ForegroundColor Green
Write-Host "✔ Recarregue o terminal com: . `$PROFILE" -ForegroundColor Green
Write-Host ""
Write-Host "NOTA: Se encontrar erro de execution policy, execute:" -ForegroundColor Yellow
Write-Host "  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Yellow
