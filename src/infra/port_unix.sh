# Infrastructure Layer — Unix port operations (macOS + Linux)
# Abstrai as chamadas de sistema: lsof, ps, kill
# Não depende de nenhuma camada superior

# Retorna as linhas do lsof para uma porta em estado LISTEN
_persa_port_listeners() {
  lsof -i :"$1" -sTCP:LISTEN 2>/dev/null | tail -n +2
}

# Retorna os PIDs ouvindo em uma porta
_persa_port_pids() {
  lsof -ti :"$1" 2>/dev/null
}

# Retorna o nome do processo dado um PID
_persa_port_proc_name() {
  ps -p "$1" -o comm= 2>/dev/null | xargs basename 2>/dev/null
}

# Encerra um processo pelo PID; retorna 0 em sucesso
_persa_port_kill_pid() {
  kill -9 "$1" 2>/dev/null
}
