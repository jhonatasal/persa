# Commands Layer — módulo "docker"
# Orquestra a infra e a UI; não chama docker diretamente
# Depende de: src/ui/output.sh, src/infra/docker_unix.sh, $CLI_NAME

_cmd_docker() {
  local cmd="${1:-}"
  shift 2>/dev/null || true

  case "$cmd" in
    ""|-h|--help) _cmd_docker_usage ;;
    clean)        _cmd_docker_clean "$@" ;;
    *)
      echo "${_P_RED}Erro: subcomando desconhecido '$cmd'. Use '$CLI_NAME docker --help'.${_P_RST}" >&2
      return 1
      ;;
  esac
}

_cmd_docker_usage() {
  echo ""
  echo "  ${_P_BOLD}Uso:${_P_RST} $CLI_NAME docker <subcomando>"
  echo ""
  printf "  ${_P_CYAN}%-44s${_P_RST} %s\n" "$CLI_NAME docker clean images"          "Remove todas as imagens docker"
  printf "  ${_P_CYAN}%-44s${_P_RST} %s\n" "$CLI_NAME docker clean images --force"  "Remove sem pedir confirmação"
  echo ""
}

_cmd_docker_clean() {
  local target="${1:-}"
  shift 2>/dev/null || true

  case "$target" in
    images)       _cmd_docker_clean_images "$@" ;;
    ""|-h|--help) _cmd_docker_usage ;;
    *)
      echo "${_P_RED}Erro: recurso desconhecido '$target'. Use '$CLI_NAME docker --help'.${_P_RST}" >&2
      return 1
      ;;
  esac
}

_cmd_docker_clean_images() {
  local force=0
  [[ "${1:-}" == "--force" || "${1:-}" == "-f" ]] && force=1

  # Verifica disponibilidade do docker
  if ! _persa_docker_available; then
    echo "${_P_RED}Erro: docker não encontrado ou daemon não está em execução.${_P_RST}" >&2
    return 1
  fi

  local images
  images=$(_persa_docker_list_images)

  if [[ -z "$images" ]]; then
    echo "${_P_GREEN}✔ Nenhuma imagem docker encontrada.${_P_RST}"
    return 0
  fi

  local count
  count=$(echo "$images" | wc -l | tr -d ' ')

  # Exibe tabela de imagens
  echo "${_P_RED}✖ ${_P_BOLD}$count${_P_RST}${_P_RED} imagem(ns) encontrada(s):${_P_RST}"
  echo ""
  printf "  ${_P_BOLD}%-14s %-44s %s${_P_RST}\n" "ID" "IMAGEM" "TAMANHO"
  echo "  ────────────────────────────────────────────────────────────────────"
  echo "$images" | while read -r line; do
    local id name size
    id=$(echo "$line"   | awk -F'\t' '{print $1}')
    name=$(echo "$line" | awk -F'\t' '{print $2}')
    size=$(echo "$line" | awk -F'\t' '{print $3}')
    printf "  ${_P_CYAN}%-14s${_P_RST} %-44s %s\n" "${id:0:12}" "$name" "$size"
  done
  echo ""

  # Confirmação (pula se --force)
  if [[ "$force" -eq 0 ]]; then
    printf "  ${_P_YELLOW}Remover todas as imagens? [s/N]:${_P_RST} "
    read -r confirm
    echo ""
    if [[ "$confirm" != "s" && "$confirm" != "S" ]]; then
      echo "${_P_YELLOW}Operação cancelada.${_P_RST}"
      return 0
    fi
  fi

  echo "${_P_YELLOW}Removendo imagens...${_P_RST}"
  echo ""

  # Remove uma a uma, mostrando status
  _persa_docker_image_ids | while read -r id; do
    [[ -z "$id" ]] && continue
    local tag
    tag=$(_persa_docker_image_tag "$id")
    [[ -z "$tag" ]] && tag="<sem tag>"

    if _persa_docker_rmi "$id"; then
      printf "  ${_P_GREEN}✔${_P_RST} ${_P_BOLD}%.12s${_P_RST}  %s\n" "$id" "$tag"
    else
      printf "  ${_P_RED}✖${_P_RST} ${_P_BOLD}%.12s${_P_RST}  %s  ${_P_YELLOW}(container em uso)${_P_RST}\n" "$id" "$tag"
    fi
  done

  echo ""
  echo "${_P_GREEN}✔ Operação concluída. Verifique com: ${_P_BOLD}docker images${_P_RST}"
}
