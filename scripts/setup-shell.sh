#!/usr/bin/env bash
# zsh + starship + fastfetch como shell por defecto
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
if [ -e "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then mv "$HOME/.zshrc" "$HOME/.zshrc.bak-monorice"; fi
ln -sfn "$REPO/home/.zshrc" "$HOME/.zshrc"
if command -v zsh >/dev/null && [ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v zsh)" ]; then
  sudo chsh -s "$(command -v zsh)" "$USER" && echo "Shell por defecto: zsh (se aplica al próximo login)"
fi
