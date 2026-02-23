#!/usr/bin/env sh
# Persa CLI — Instalador remoto (Unix: macOS + Linux)
#
# Uso:
#   curl -fsSL https://raw.githubusercontent.com/jhonatasal/persa/main/get.sh | sh
#   wget -qO-  https://raw.githubusercontent.com/jhonatasal/persa/main/get.sh | sh

set -e

REPO="jhonatasal/persa"
BRANCH="main"
RAW="https://raw.githubusercontent.com/$REPO/$BRANCH"
SRC_DIR="${PERSA_SRC_DIR:-$HOME/.config/shell/persa-src}"

# Verifica ferramenta de download disponível
if command -v curl >/dev/null 2>&1; then
  _fetch() { curl -fsSL "$RAW/$1" -o "$SRC_DIR/$1"; }
elif command -v wget >/dev/null 2>&1; then
  _fetch() { wget -qO "$SRC_DIR/$1" "$RAW/$1"; }
else
  echo "Erro: curl ou wget sao necessarios para a instalacao remota." >&2
  exit 1
fi

echo ""
echo "persa — instalando de $REPO@$BRANCH"
echo ""

# Cria estrutura permanente de diretórios (fonte para updates futuros)
mkdir -p \
  "$SRC_DIR/src/ui" \
  "$SRC_DIR/src/infra" \
  "$SRC_DIR/src/commands"

# Baixa todos os arquivos necessários
for file in \
  "cli.conf" \
  "persa.sh" \
  "install.sh" \
  "src/ui/output.sh" \
  "src/infra/port_unix.sh" \
  "src/infra/docker_unix.sh" \
  "src/commands/port.sh" \
  "src/commands/docker.sh"
do
  printf "  ↓ %s\n" "$file"
  _fetch "$file"
done

chmod +x "$SRC_DIR/install.sh"

echo ""

# Sinaliza instalação remota para que 'persa update' saiba como atualizar
PERSA_INSTALL_METHOD="remote" sh "$SRC_DIR/install.sh"
