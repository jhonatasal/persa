# Persa CLI — Windows Uninstaller
#Requires -Version 5.1

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Lê cli.conf
$config = @{ CLI_NAME = "persa" }
foreach ($line in (Get-Content (Join-Path $ScriptDir "cli.conf"))) {
  if ($line -match '^CLI_NAME="?([^"]+)"?$') { $config.CLI_NAME = $Matches[1] }
}

$cliName     = $config.CLI_NAME
$InstallDir  = "$env:USERPROFILE\.config\powershell\port-manager"
$ProfileFile = $PROFILE.CurrentUserAllHosts

Write-Host "Desinstalando $cliName..."

# Remove entrada do perfil do PowerShell
if (Test-Path $ProfileFile) {
  $content = Get-Content $ProfileFile -Raw -ErrorAction SilentlyContinue
  if ($content -match 'port-manager') {
    $lines = $content -split "`n" | Where-Object { $_ -notmatch 'port-manager' }
    Set-Content -Path $ProfileFile -Value ($lines -join "`n").TrimEnd() -Encoding UTF8
    Write-Host "✔ Removido do perfil: $ProfileFile" -ForegroundColor Green
  }
}

# Remove o diretório de instalação
if (Test-Path $InstallDir) {
  Remove-Item $InstallDir -Recurse -Force
  Write-Host "✔ Removido: $InstallDir" -ForegroundColor Green
}

Write-Host "✔ Recarregue o terminal com: . `$PROFILE" -ForegroundColor Green
