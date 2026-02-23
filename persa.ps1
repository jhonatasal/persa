# Persa CLI — Entry Point (Windows PowerShell)
#
# Como trocar o nome da CLI:
#   1. Edite cli.conf → CLI_NAME="outro_nome"
#   2. Rode install.ps1 novamente
#
# As camadas estão organizadas neste arquivo na ordem:
#   Config → Infrastructure → Commands → Entry Point

# ── Config ────────────────────────────────────────────────────────────────────
# Lê cli.conf do mesmo diretório deste script
$_persaConfigFile = Join-Path $PSScriptRoot "cli.conf"
$_persaConfig = @{ Name = "persa"; Version = "1.0.0" }  # defaults

if (Test-Path $_persaConfigFile) {
  foreach ($line in (Get-Content $_persaConfigFile)) {
    if ($line -match '^CLI_NAME="?([^"]+)"?$')    { $_persaConfig.Name    = $Matches[1] }
    if ($line -match '^CLI_VERSION="?([^"]+)"?$') { $_persaConfig.Version = $Matches[1] }
  }
}

# ── Infrastructure Layer — operações de porta (Windows) ───────────────────────

function _Persa_Port_GetListeners([int]$Port) {
  try { Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction Stop }
  catch { $null }
}

function _Persa_Port_GetOwner([int]$Pid) {
  try {
    $wmi   = Get-CimInstance Win32_Process -Filter "ProcessId = $Pid" -ErrorAction SilentlyContinue
    $owner = $wmi | Invoke-CimMethod -MethodName GetOwner -ErrorAction SilentlyContinue
    if ($owner -and $owner.User) { return $owner.User }
  } catch {}
  return "desconhecido"
}

function _Persa_Port_KillPid([int]$Pid) {
  $proc = Get-Process -Id $Pid -ErrorAction SilentlyContinue
  $name = if ($proc) { $proc.ProcessName } else { "desconhecido" }
  try {
    Stop-Process -Id $Pid -Force -ErrorAction Stop
    return @{ Success = $true; Name = $name }
  } catch {
    return @{ Success = $false; Name = $name }
  }
}

# ── Infrastructure Layer — operações docker (Windows) ────────────────────────

function _Persa_Docker_Available {
  try {
    $null = Get-Command docker -ErrorAction Stop
    $null = docker info 2>$null
    return $?
  } catch { return $false }
}

function _Persa_Docker_ListImages {
  docker images --format "{{.ID}}`t{{.Repository}}:{{.Tag}}`t{{.Size}}" 2>$null
}

function _Persa_Docker_ImageIds {
  (docker images -aq 2>$null) | Sort-Object -Unique
}

function _Persa_Docker_ImageTag([string]$Id) {
  $tag = docker inspect --format '{{index .RepoTags 0}}' $Id 2>$null
  if (-not $tag) { return "<sem tag>" }
  return $tag
}

function _Persa_Docker_Rmi([string]$Id) {
  $output = docker rmi -f $Id 2>&1
  return $LASTEXITCODE -eq 0
}

# ── Commands Layer — módulo "port" ────────────────────────────────────────────

function _Persa_Cmd_Port {
  $cliName = $_persaConfig.Name
  $cmd     = if ($args.Count -gt 0) { $args[0] } else { "" }
  $rest    = if ($args.Count -gt 1) { $args[1..($args.Count - 1)] } else { @() }

  switch ($cmd) {
    { $_ -in @("", "--help", "-h") } { _Persa_Cmd_Port_Usage; return }
    "kill"                           { _Persa_Cmd_Port_Kill $rest[0]; return }
    default                          { _Persa_Cmd_Port_Check $cmd }
  }
}

function _Persa_Cmd_Port_Usage {
  $n = $_persaConfig.Name
  Write-Host ""
  Write-Host "  Uso: $n port <numero>" -ForegroundColor White
  Write-Host ""
  Write-Host -NoNewline ("  {0,-34}" -f "$n port <numero>")      -ForegroundColor Cyan
  Write-Host "Verifica se a porta esta em uso"
  Write-Host -NoNewline ("  {0,-34}" -f "$n port kill <numero>")  -ForegroundColor Cyan
  Write-Host "Mata o processo que usa a porta"
  Write-Host ""
}

function _Persa_Cmd_Port_Check([string]$PortArg) {
  $cliName = $_persaConfig.Name

  if ($PortArg -notmatch '^\d+$') {
    Write-Host "Erro: '$PortArg' nao e um numero de porta valido." -ForegroundColor Red
    return
  }

  $portNum     = [int]$PortArg
  $connections = _Persa_Port_GetListeners $portNum

  if (-not $connections) {
    Write-Host -NoNewline "✔ Porta " -ForegroundColor Green
    Write-Host -NoNewline $portNum
    Write-Host " esta livre." -ForegroundColor Green
  } else {
    Write-Host -NoNewline "✖ Porta " -ForegroundColor Red
    Write-Host -NoNewline $portNum
    Write-Host " esta em uso:" -ForegroundColor Red
    Write-Host ""
    Write-Host ("  {0,-12} {1,-8} {2,-20} {3}" -f "APP", "PID", "USUARIO", "ENDERECO")
    Write-Host "  ────────────────────────────────────────────────────"

    foreach ($conn in $connections) {
      $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
      $name = if ($proc) { $proc.ProcessName } else { "desconhecido" }
      $user = _Persa_Port_GetOwner $conn.OwningProcess
      $addr = "$($conn.LocalAddress):$($conn.LocalPort)"

      Write-Host -NoNewline "  "
      Write-Host -NoNewline ("{0,-12}" -f $name) -ForegroundColor Cyan
      Write-Host (" {0,-8} {1,-20} {2}" -f $conn.OwningProcess, $user, $addr)
    }

    Write-Host ""
    Write-Host -NoNewline "  Dica: use " -ForegroundColor Yellow
    Write-Host -NoNewline "$cliName port kill $portNum"
    Write-Host " para encerrar." -ForegroundColor Yellow
  }
}

function _Persa_Cmd_Port_Kill([string]$PortArg) {
  $cliName = $_persaConfig.Name

  if (-not $PortArg) {
    Write-Host "Erro: informe o numero da porta. Ex: $cliName port kill 3000" -ForegroundColor Red
    return
  }

  $portNum     = [int]$PortArg
  $connections = _Persa_Port_GetListeners $portNum

  if (-not $connections) {
    Write-Host -NoNewline "Porta " -ForegroundColor Green
    Write-Host -NoNewline $portNum
    Write-Host " ja esta livre." -ForegroundColor Green
    return
  }

  Write-Host -NoNewline "Matando processo(s) na porta " -ForegroundColor Yellow
  Write-Host -NoNewline $portNum
  Write-Host "..." -ForegroundColor Yellow

  foreach ($conn in $connections) {
    $result = _Persa_Port_KillPid $conn.OwningProcess
    if ($result.Success) {
      Write-Host -NoNewline "  x " -ForegroundColor Red
      Write-Host "PID $($conn.OwningProcess) ($($result.Name)) encerrado"
    } else {
      Write-Host "  Falha ao encerrar PID $($conn.OwningProcess)" -ForegroundColor Red
    }
  }
}

# ── Commands Layer — módulo "docker" ─────────────────────────────────────────

function _Persa_Cmd_Docker {
  $cmd  = if ($args.Count -gt 0) { $args[0] } else { "" }
  $rest = if ($args.Count -gt 1) { $args[1..($args.Count - 1)] } else { @() }

  switch ($cmd) {
    { $_ -in @("", "--help", "-h") } { _Persa_Cmd_Docker_Usage; return }
    "clean"                          { _Persa_Cmd_Docker_Clean @rest; return }
    default {
      Write-Host "Erro: subcomando desconhecido '$cmd'. Use '$($_persaConfig.Name) docker --help'." -ForegroundColor Red
    }
  }
}

function _Persa_Cmd_Docker_Usage {
  $n = $_persaConfig.Name
  Write-Host ""
  Write-Host "  Uso: $n docker <subcomando>" -ForegroundColor White
  Write-Host ""
  Write-Host -NoNewline ("  {0,-44}" -f "$n docker clean images")         -ForegroundColor Cyan
  Write-Host "Remove todas as imagens docker"
  Write-Host -NoNewline ("  {0,-44}" -f "$n docker clean images --force") -ForegroundColor Cyan
  Write-Host "Remove sem pedir confirmacao"
  Write-Host ""
}

function _Persa_Cmd_Docker_Clean {
  $target = if ($args.Count -gt 0) { $args[0] } else { "" }
  $rest   = if ($args.Count -gt 1) { $args[1..($args.Count - 1)] } else { @() }

  switch ($target) {
    { $_ -in @("", "--help", "-h") } { _Persa_Cmd_Docker_Usage; return }
    "images"                         { _Persa_Cmd_Docker_Clean_Images @rest; return }
    default {
      Write-Host "Erro: recurso desconhecido '$target'. Use '$($_persaConfig.Name) docker --help'." -ForegroundColor Red
    }
  }
}

function _Persa_Cmd_Docker_Clean_Images {
  $force = ($args[0] -in @("--force", "-f"))
  $n     = $_persaConfig.Name

  if (-not (_Persa_Docker_Available)) {
    Write-Host "Erro: docker nao encontrado ou daemon nao esta em execucao." -ForegroundColor Red
    return
  }

  $images = _Persa_Docker_ListImages
  if (-not $images) {
    Write-Host "✔ Nenhuma imagem docker encontrada." -ForegroundColor Green
    return
  }

  $rows  = @($images)
  $count = $rows.Count

  # Exibe tabela
  Write-Host -NoNewline "✖ " -ForegroundColor Red
  Write-Host -NoNewline "$count imagem(ns) encontrada(s):" -ForegroundColor Red
  Write-Host ""
  Write-Host ""
  Write-Host ("  {0,-14} {1,-44} {2}" -f "ID", "IMAGEM", "TAMANHO")
  Write-Host "  ────────────────────────────────────────────────────────────────────"

  foreach ($row in $rows) {
    $parts = $row -split "`t"
    $id    = if ($parts[0].Length -gt 12) { $parts[0].Substring(0,12) } else { $parts[0] }
    $name  = $parts[1]
    $size  = $parts[2]
    Write-Host -NoNewline "  "
    Write-Host -NoNewline ("{0,-14}" -f $id) -ForegroundColor Cyan
    Write-Host (" {0,-44} {1}" -f $name, $size)
  }
  Write-Host ""

  # Confirmação
  if (-not $force) {
    Write-Host -NoNewline "  Remover todas as imagens? [s/N]: " -ForegroundColor Yellow
    $confirm = Read-Host
    Write-Host ""
    if ($confirm -notin @("s", "S")) {
      Write-Host "Operacao cancelada." -ForegroundColor Yellow
      return
    }
  }

  Write-Host "Removendo imagens..." -ForegroundColor Yellow
  Write-Host ""

  foreach ($id in (_Persa_Docker_ImageIds)) {
    if (-not $id) { continue }
    $tag = _Persa_Docker_ImageTag $id
    if (_Persa_Docker_Rmi $id) {
      Write-Host -NoNewline "  "
      Write-Host -NoNewline "✔ " -ForegroundColor Green
      Write-Host "$($id.Substring(0,[Math]::Min(12,$id.Length)))  $tag"
    } else {
      Write-Host -NoNewline "  "
      Write-Host -NoNewline "✖ " -ForegroundColor Red
      Write-Host "$($id.Substring(0,[Math]::Min(12,$id.Length)))  $tag  (container em uso)" -ForegroundColor Red
    }
  }

  Write-Host ""
  Write-Host "✔ Operacao concluida. Verifique com: docker images" -ForegroundColor Green
}

# ── Entry Point ───────────────────────────────────────────────────────────────

function _Persa_Update {
  $registry = "$env:USERPROFILE\.config\powershell\port-manager\.source"
  if (-not (Test-Path $registry)) {
    Write-Host "Erro: origem nao encontrada. Rode install.ps1 novamente." -ForegroundColor Red
    return
  }
  $projectDir = (Get-Content $registry -Raw).Trim()
  if (-not (Test-Path $projectDir)) {
    Write-Host "Erro: diretorio do projeto nao existe: $projectDir" -ForegroundColor Red
    return
  }
  & "$projectDir\install.ps1"
}

function _Persa_Usage {
  $n = $_persaConfig.Name
  $v = $_persaConfig.Version
  Write-Host ""
  Write-Host "$n v$v" -ForegroundColor White
  Write-Host ""
  Write-Host "  port" -ForegroundColor White
  Write-Host -NoNewline ("    {0,-38}" -f "$n port <numero>")      -ForegroundColor Cyan
  Write-Host "Verifica se a porta esta em uso"
  Write-Host -NoNewline ("    {0,-38}" -f "$n port kill <numero>")  -ForegroundColor Cyan
  Write-Host "Mata o processo que usa a porta"
  Write-Host ""
  Write-Host "  docker" -ForegroundColor White
  Write-Host -NoNewline ("    {0,-38}" -f "$n docker clean images")  -ForegroundColor Cyan
  Write-Host "Remove todas as imagens docker"
  Write-Host ""
  Write-Host -NoNewline ("  {0,-40}" -f "$n update") -ForegroundColor Cyan
  Write-Host "Atualiza o $n"
  Write-Host ""
  Write-Host "  Ajuda de modulo: $n <modulo> --help"
  Write-Host ""
}

function _Persa_Main {
  $cmd  = if ($args.Count -gt 0) { $args[0] } else { "" }
  $rest = if ($args.Count -gt 1) { $args[1..($args.Count - 1)] } else { @() }

  switch ($cmd) {
    { $_ -in @("", "--help", "-h") } { _Persa_Usage }
    "update"                         { _Persa_Update }
    "port"                           { _Persa_Cmd_Port @rest }
    "docker"                         { _Persa_Cmd_Docker @rest }
    default {
      Write-Host "Erro: modulo desconhecido '$cmd'. Use '$($_persaConfig.Name) --help'." -ForegroundColor Red
    }
  }
}

# ── Registra a função com o nome configurado em cli.conf ──────────────────────
# Para renomear: basta trocar CLI_NAME no cli.conf e rodar install.ps1
Set-Item -Path "Function:global:$($_persaConfig.Name)" -Value { _Persa_Main @args }
