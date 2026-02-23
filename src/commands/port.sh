# Commands Layer — módulo "port"
# Orquestra a infra e a UI; não chama lsof/kill diretamente
# Depende de: src/ui/output.sh, src/infra/port_unix.sh, $CLI_NAME

_cmd_port() {
  if [[ $# -eq 0 || "$1" == "--help" || "$1" == "-h" ]]; then
    _cmd_port_usage
    return 0
  fi

  case "$1" in
    kill) _cmd_port_kill "$2" ;;
    *)    _cmd_port_check "$1" ;;
  esac
}

_cmd_port_usage() {
  echo ""
  echo "  ${_P_BOLD}Uso:${_P_RST} $CLI_NAME port <numero>"
  echo ""
  printf "  ${_P_CYAN}%-34s${_P_RST} %s\n" "$CLI_NAME port <numero>"      "Verifica se a porta está em uso"
  printf "  ${_P_CYAN}%-34s${_P_RST} %s\n" "$CLI_NAME port kill <numero>"  "Mata o processo que usa a porta"
  echo ""
}

_cmd_port_check() {
  local PORT="$1"

  if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
    echo "${_P_RED}Erro: '${PORT}' não é um número de porta válido.${_P_RST}" >&2
    return 1
  fi

  local INFO
  INFO=$(_persa_port_listeners "$PORT")

  if [[ -z "$INFO" ]]; then
    echo "${_P_GREEN}✔ Porta ${_P_BOLD}$PORT${_P_RST}${_P_GREEN} está livre.${_P_RST}"
  else
    echo "${_P_RED}✖ Porta ${_P_BOLD}$PORT${_P_RST}${_P_RED} está em uso:${_P_RST}"
    echo ""
    printf "  ${_P_BOLD}%-12s %-8s %-20s %s${_P_RST}\n" "APP" "PID" "USUÁRIO" "ENDEREÇO"
    echo "  ────────────────────────────────────────────────────"
    echo "$INFO" | while IFS= read -r line; do
      local APP PID USER ADDR
      APP=$(echo "$line"  | awk '{print $1}')
      PID=$(echo "$line"  | awk '{print $2}')
      USER=$(echo "$line" | awk '{print $3}')
      ADDR=$(echo "$line" | awk '{print $9}')
      printf "  ${_P_CYAN}%-12s${_P_RST} %-8s %-20s %s\n" "$APP" "$PID" "$USER" "$ADDR"
    done
    echo ""
    echo "  ${_P_YELLOW}Dica: use ${_P_BOLD}$CLI_NAME port kill $PORT${_P_RST}${_P_YELLOW} para encerrar.${_P_RST}"
  fi
}

_cmd_port_kill() {
  local PORT="$1"

  if [[ -z "$PORT" ]]; then
    echo "${_P_RED}Erro: informe o número da porta. Ex: $CLI_NAME port kill 3000${_P_RST}" >&2
    return 1
  fi

  local PIDS
  PIDS=$(_persa_port_pids "$PORT")

  if [[ -z "$PIDS" ]]; then
    echo "${_P_GREEN}Porta ${_P_BOLD}$PORT${_P_RST}${_P_GREEN} já está livre.${_P_RST}"
    return 0
  fi

  echo "${_P_YELLOW}Matando processo(s) na porta ${_P_BOLD}$PORT${_P_RST}${_P_YELLOW}...${_P_RST}"
  echo "$PIDS" | while read -r pid; do
    local NAME
    NAME=$(_persa_port_proc_name "$pid")
    _persa_port_kill_pid "$pid" \
      && echo "  ${_P_RED}✖${_P_RST} PID ${_P_BOLD}$pid${_P_RST} ($NAME) encerrado" \
      || echo "  Falha ao encerrar PID $pid"
  done
}
