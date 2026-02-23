#!/usr/bin/env sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/cli.conf"

INSTALL_DIR="$HOME/.config/shell/port-manager"

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

echo "Desinstalando $CLI_NAME..."

if [ "$OS" = "Darwin" ]; then
  sed -i '' '/port-manager/d' "$RC_FILE" 2>/dev/null || true
else
  sed -i '/port-manager/d' "$RC_FILE" 2>/dev/null || true
fi

rm -rf "$INSTALL_DIR"

echo "✔ Removido de $RC_FILE"
echo "✔ Recarregue o terminal com: source $RC_FILE"
