# Infrastructure Layer — Unix SSH tunnel operations (macOS + Linux)
# Abstrai as chamadas ssh; não depende de nenhuma camada superior

# Verifica se o ssh está disponível
_persa_ssh_available() {
  command -v ssh >/dev/null 2>&1
}

# Inicia um túnel SSH de local port forwarding (bloqueante — Ctrl+C para parar)
# Uso: _persa_ssh_tunnel <localPort> <remoteHost> <remotePort> <sshTarget> [sshPort]
_persa_ssh_tunnel() {
  local local_port="$1"
  local remote_host="$2"
  local remote_port="$3"
  local ssh_target="$4"
  local ssh_port="${5:-22}"

  ssh -N \
      -L "${local_port}:${remote_host}:${remote_port}" \
      -p "$ssh_port" \
      "$ssh_target"
}
