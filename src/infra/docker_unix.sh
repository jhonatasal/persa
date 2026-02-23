# Infrastructure Layer — Docker operations (Unix: macOS + Linux)
# Abstrai as chamadas ao docker CLI
# Não depende de nenhuma camada superior

# Verifica se o docker está instalado e o daemon está rodando
_persa_docker_available() {
  command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1
}

# Retorna uma linha por imagem: "ID <TAB> NOME:TAG <TAB> TAMANHO"
_persa_docker_list_images() {
  docker images --format "{{.ID}}\t{{.Repository}}:{{.Tag}}\t{{.Size}}" 2>/dev/null
}

# Retorna IDs únicos de todas as imagens (incluindo sem tag)
_persa_docker_image_ids() {
  docker images -aq 2>/dev/null | sort -u
}

# Retorna a primeira tag de uma imagem pelo ID
_persa_docker_image_tag() {
  docker inspect --format '{{index .RepoTags 0}}' "$1" 2>/dev/null
}

# Remove uma imagem pelo ID (força remoção)
_persa_docker_rmi() {
  docker rmi -f "$1" >/dev/null 2>&1
}
