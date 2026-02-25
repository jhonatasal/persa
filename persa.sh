# Persa CLI — Entry Point (Unix: macOS + Linux)
#
# Como trocar o nome da CLI:
#   1. Edite cli.conf → CLI_NAME="outro_nome"
#   2. Rode install.sh novamente
#
# Esta variável deve ser definida antes do source (feito pelo install.sh):
#   _PERSA_INSTALL="$HOME/.config/shell/port-manager"
# Em desenvolvimento (bash), detecta automaticamente se não estiver definida.

# ── Localiza o diretório de instalação ────────────────────────────────────────
if [ -z "${_PERSA_INSTALL:-}" ]; then
  # Fallback para desenvolvimento: funciona em bash
  if [ -n "${BASH_SOURCE[0]:-}" ]; then
    _PERSA_INSTALL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  else
    echo "persa: _PERSA_INSTALL não definido. Execute install.sh primeiro." >&2
    return 1
  fi
fi

# ── Carrega camadas (ordem: config → ui → infra → commands) ───────────────────
. "$_PERSA_INSTALL/cli.conf"
. "$_PERSA_INSTALL/src/ui/output.sh"
. "$_PERSA_INSTALL/src/infra/port_unix.sh"
. "$_PERSA_INSTALL/src/infra/docker_unix.sh"
. "$_PERSA_INSTALL/src/infra/ssh_unix.sh"
. "$_PERSA_INSTALL/src/commands/port.sh"
. "$_PERSA_INSTALL/src/commands/docker.sh"

# ── Entry point interno ────────────────────────────────────────────────────────
_persa_usage() {
  echo ""
  echo "${_P_BOLD}$CLI_NAME${_P_RST} v${CLI_VERSION}"
  echo ""
  echo "  ${_P_BOLD}port${_P_RST}"
  printf "  ${_P_CYAN}%-48s${_P_RST} %s\n" "  $CLI_NAME port <numero>"                    "Verifica se a porta está em uso"
  printf "  ${_P_CYAN}%-48s${_P_RST} %s\n" "  $CLI_NAME port kill <numero>"               "Mata o processo que usa a porta"
  printf "  ${_P_CYAN}%-48s${_P_RST} %s\n" "  $CLI_NAME port forward <usuario@servidor>"  "Abre um túnel SSH para acesso local"
  echo ""
  echo "  ${_P_BOLD}docker${_P_RST}"
  printf "  ${_P_CYAN}%-38s${_P_RST} %s\n" "  $CLI_NAME docker clean images"  "Remove todas as imagens docker"
  echo ""
  printf "  ${_P_CYAN}%-38s${_P_RST} %s\n" "$CLI_NAME update"  "Atualiza o $CLI_NAME"
  echo ""
  echo "  Ajuda de módulo: ${_P_BOLD}$CLI_NAME <modulo> --help${_P_RST}"
  echo ""
}

_persa_update() {
  local method="local"
  local method_file="$_PERSA_INSTALL/.install-method"
  [[ -f "$method_file" ]] && method=$(cat "$method_file")

  if [[ "$method" == "remote" ]]; then
    # Instalado via get.sh → re-busca a versão mais recente do GitHub
    echo "${_P_CYAN}Atualizando do GitHub...${_P_RST}"
    if command -v curl >/dev/null 2>&1; then
      curl -fsSL "https://raw.githubusercontent.com/jhonatasal/persa/main/get.sh" | sh
    elif command -v wget >/dev/null 2>&1; then
      wget -qO- "https://raw.githubusercontent.com/jhonatasal/persa/main/get.sh" | sh
    else
      echo "${_P_RED}Erro: curl ou wget são necessários para atualizar.${_P_RST}" >&2
      return 1
    fi
  else
    # Instalado via clone local → re-executa install.sh do projeto
    local registry="$_PERSA_INSTALL/.source"
    if [[ ! -f "$registry" ]]; then
      echo "${_P_RED}Erro: origem não encontrada. Rode install.sh novamente.${_P_RST}" >&2
      return 1
    fi
    local project_dir
    project_dir=$(cat "$registry")
    if [[ ! -d "$project_dir" ]]; then
      echo "${_P_RED}Erro: diretório do projeto não existe: $project_dir${_P_RST}" >&2
      return 1
    fi
    sh "$project_dir/install.sh"
  fi
}

_persa_main() {
  local cmd="${1:-}"
  shift 2>/dev/null || true

  case "$cmd" in
    ""|-h|--help) _persa_usage ;;
    update)       _persa_update ;;
    port)         _cmd_port "$@" ;;
    docker)       _cmd_docker "$@" ;;
    *)
      echo "${_P_RED}Erro: módulo desconhecido '$cmd'. Use '$CLI_NAME --help'.${_P_RST}" >&2
      return 1
      ;;
  esac
}

# ── Registra a função com o nome configurado em cli.conf ──────────────────────
# Para renomear: basta trocar CLI_NAME no cli.conf e rodar install.sh
eval "${CLI_NAME}() { _persa_main \"\$@\"; }"
