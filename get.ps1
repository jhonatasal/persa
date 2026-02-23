# Persa CLI — Instalador remoto (Windows PowerShell)
#
# Uso:
#   irm https://raw.githubusercontent.com/jhonatasal/persa/main/get.ps1 | iex

$ErrorActionPreference = "Stop"

$repo    = "jhonatasal/persa"
$branch  = "main"
$raw     = "https://raw.githubusercontent.com/$repo/$branch"
$srcDir  = if ($env:PERSA_SRC_DIR) { $env:PERSA_SRC_DIR } `
           else { "$env:USERPROFILE\.config\powershell\persa-src" }

Write-Host ""
Write-Host "persa — instalando de $repo@$branch"
Write-Host ""

# Arquivos a baixar
$files = @(
  "cli.conf",
  "persa.ps1",
  "install.ps1"
)

foreach ($file in $files) {
  $dest    = Join-Path $srcDir ($file -replace '/', '\')
  $destDir = Split-Path $dest -Parent
  if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
  }
  Write-Host "  ↓ $file"
  Invoke-WebRequest -Uri "$raw/$file" -OutFile $dest -UseBasicParsing
}

Write-Host ""

# Sinaliza instalação remota para que 'persa update' saiba como atualizar
$env:PERSA_INSTALL_METHOD = "remote"
& "$srcDir\install.ps1"
$env:PERSA_INSTALL_METHOD = $null
