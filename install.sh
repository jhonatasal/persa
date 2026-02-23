#!/usr/bin/env sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Lê CLI_NAME e CLI_VERSION do cli.conf
. "$SCRIPT_DIR/cli.conf"

# Diretório de instalação (fixo, independente do nome da CLI)
INSTALL_DIR="$HOME/.config/shell/port-manager"
SOURCE_REGISTRY="$INSTALL_DIR/.source"
ENTRY_POINT="$INSTALL_DIR/persa.sh"

# Detecta OS e shell
OS="$(uname -s)"
SHELL_NAME="$(basename "$SHELL")"

case "$SHELL_NAME" in
  zsh)  RC_FILE="$HOME/.zshrc" ;;
  bash)
    if [ "$OS" = "Darwin" ]; then
      RC_FILE="$HOME/.bash_profile"
    else
      RC_FILE="$HOME/.bashrc"
    fi
    ;;
  fish) RC_FILE="$HOME/.config/fish/config.fish" ;;
  *)    RC_FILE="$HOME/.profile" ;;
esac

# Linha que vai no RC (define _PERSA_INSTALL e faz o source)
SOURCE_LINE="_PERSA_INSTALL=\"$INSTALL_DIR\"; . \"$ENTRY_POINT\""

echo "Instalando $CLI_NAME v$CLI_VERSION..."
echo "  OS: $OS  |  Shell: $SHELL_NAME  |  RC: $RC_FILE"
echo ""

# Cria estrutura de diretórios
mkdir -p \
  "$INSTALL_DIR/src/ui" \
  "$INSTALL_DIR/src/infra" \
  "$INSTALL_DIR/src/commands"

# Copia todos os arquivos
cp "$SCRIPT_DIR/cli.conf"                        "$INSTALL_DIR/"
cp "$SCRIPT_DIR/persa.sh"                        "$INSTALL_DIR/"
cp "$SCRIPT_DIR/src/ui/output.sh"                "$INSTALL_DIR/src/ui/"
cp "$SCRIPT_DIR/src/infra/port_unix.sh"          "$INSTALL_DIR/src/infra/"
cp "$SCRIPT_DIR/src/infra/docker_unix.sh"        "$INSTALL_DIR/src/infra/"
cp "$SCRIPT_DIR/src/commands/port.sh"            "$INSTALL_DIR/src/commands/"
cp "$SCRIPT_DIR/src/commands/docker.sh"          "$INSTALL_DIR/src/commands/"

# Salva o caminho do projeto e o método de instalação para o comando 'update'
echo "$SCRIPT_DIR" > "$SOURCE_REGISTRY"
echo "${PERSA_INSTALL_METHOD:-local}" > "$INSTALL_DIR/.install-method"

# Atualiza o RC file (remove entrada antiga, adiciona nova)
if [ "$OS" = "Darwin" ]; then
  sed -i '' '/port-manager/d' "$RC_FILE" 2>/dev/null || true
else
  sed -i '/port-manager/d' "$RC_FILE" 2>/dev/null || true
fi
printf '\n%s\n' "$SOURCE_LINE" >> "$RC_FILE"

echo "✔ Instalado em $INSTALL_DIR"
echo "✔ Adicionado ao $RC_FILE"
echo "✔ Para atualizar: $CLI_NAME update"
echo "✔ Recarregue o terminal com: source $RC_FILE"
