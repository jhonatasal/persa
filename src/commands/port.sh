# Commands Layer — módulo "port"
# Orquestra a infra e a UI; não chama lsof/kill diretamente
# Depende de: src/ui/output.sh, src/infra/port_unix.sh, $CLI_NAME

_cmd_port() {
  if [[ $# -eq 0 || "$1" == "--help" || "$1" == "-h" ]]; then
    _cmd_port_usage
    return 0
  fi

  case "$1" in
    kill)    _cmd_port_kill "$2" ;;
    forward) shift; _cmd_port_forward "$@" ;;
    *)       _cmd_port_check "$1" ;;
  esac
}

_cmd_port_usage() {
  echo ""
  echo "  ${_P_BOLD}Uso:${_P_RST} $CLI_NAME port <subcomando>"
  echo ""
  printf "  ${_P_CYAN}%-44s${_P_RST} %s\n" "$CLI_NAME port <numero>"                    "Verifica se a porta está em uso"
  printf "  ${_P_CYAN}%-44s${_P_RST} %s\n" "$CLI_NAME port kill <numero>"               "Mata o processo que usa a porta"
  printf "  ${_P_CYAN}%-44s${_P_RST} %s\n" "$CLI_NAME port forward <usuario@servidor>"  "Abre um túnel SSH para acesso local"
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

_cmd_port_forward_usage() {
  echo ""
  echo "  ${_P_BOLD}Uso:${_P_RST} $CLI_NAME port forward <usuario@servidor> [opções]"
  echo ""
  echo "  Abre um túnel SSH (local port forwarding) para acessar uma porta"
  echo "  remota via localhost — útil para testar APIs com Postman."
  echo ""
  printf "  ${_P_CYAN}%-38s${_P_RST} %s\n" "--local-port,  -l <porta>"  "Porta local  (padrão: igual à remota)"
  printf "  ${_P_CYAN}%-38s${_P_RST} %s\n" "--remote-host, -H <host>"   "Host remoto  (padrão: 127.0.0.1)"
  printf "  ${_P_CYAN}%-38s${_P_RST} %s\n" "--remote-port, -r <porta>"  "Porta remota (padrão: 3000)"
  printf "  ${_P_CYAN}%-38s${_P_RST} %s\n" "--ssh-port,    -p <porta>"  "Porta SSH    (padrão: 22)"
  echo ""
  echo "  ${_P_BOLD}Exemplos:${_P_RST}"
  printf "  ${_P_CYAN}%s${_P_RST}\n" "  $CLI_NAME port forward user@servidor"
  printf "  ${_P_CYAN}%s${_P_RST}\n" "  $CLI_NAME port forward user@servidor --remote-port 8080"
  printf "  ${_P_CYAN}%s${_P_RST}\n" "  $CLI_NAME port forward user@servidor -l 9000 -r 3000 -H 127.0.0.1"
  echo ""
}

_cmd_port_forward() {
  local ssh_target=""
  local local_port=""
  local remote_host="127.0.0.1"
  local remote_port="3000"
  local ssh_port="22"

  if [[ $# -eq 0 || "$1" == "--help" || "$1" == "-h" ]]; then
    _cmd_port_forward_usage
    return 0
  fi

  # Primeiro argumento posicional = user@host
  ssh_target="$1"
  shift

  # Parse das opções restantes
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --local-port|-l)
        shift
        local_port="$1"
        ;;
      --remote-host|-H)
        shift
        remote_host="$1"
        ;;
      --remote-port|-r)
        shift
        remote_port="$1"
        ;;
      --ssh-port|-p)
        shift
        ssh_port="$1"
        ;;
      *)
        echo "${_P_RED}Erro: opção desconhecida '$1'. Use '$CLI_NAME port forward --help'.${_P_RST}" >&2
        return 1
        ;;
    esac
    shift
  done

  # local_port padrão = remote_port
  [[ -z "$local_port" ]] && local_port="$remote_port"

  # Validações
  if ! [[ "$local_port" =~ ^[0-9]+$ ]]; then
    echo "${_P_RED}Erro: porta local inválida: '$local_port'${_P_RST}" >&2
    return 1
  fi

  if ! [[ "$remote_port" =~ ^[0-9]+$ ]]; then
    echo "${_P_RED}Erro: porta remota inválida: '$remote_port'${_P_RST}" >&2
    return 1
  fi

  if ! [[ "$ssh_port" =~ ^[0-9]+$ ]]; then
    echo "${_P_RED}Erro: porta SSH inválida: '$ssh_port'${_P_RST}" >&2
    return 1
  fi

  if ! _persa_ssh_available; then
    echo "${_P_RED}Erro: ssh não encontrado. Instale o OpenSSH e tente novamente.${_P_RST}" >&2
    return 1
  fi

  echo ""
  echo "  ${_P_BOLD}Túnel SSH ativo${_P_RST}"
  echo ""
  printf "  ${_P_CYAN}%-22s${_P_RST} →  %s\n" "localhost:$local_port" "${remote_host}:${remote_port}  (via $ssh_target)"
  echo ""
  echo "  ${_P_YELLOW}Testável em:${_P_RST}  ${_P_BOLD}http://localhost:$local_port${_P_RST}"
  echo "  ${_P_YELLOW}Encerrar:${_P_RST}     ${_P_BOLD}Ctrl+C${_P_RST}"
  echo ""

  _persa_ssh_tunnel "$local_port" "$remote_host" "$remote_port" "$ssh_target" "$ssh_port"
  local exit_code=$?

  echo ""
  # Ctrl+C gera exit code 130; ambos indicam encerramento normal
  if [[ $exit_code -eq 0 || $exit_code -eq 130 ]]; then
    echo "${_P_GREEN}✔ Túnel encerrado.${_P_RST}"
  else
    echo "${_P_RED}✖ Túnel encerrado com erro (código $exit_code).${_P_RST}" >&2
    return $exit_code
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
