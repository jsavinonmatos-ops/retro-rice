#!/usr/bin/env bash
# mono-pet: la chica de pixel art animada (parpadea y respira) en la terminal. Salir con q.
# Uso: mono-pet [sakura|yuki|mizu|kuro]
HERE="$(dirname "$(readlink -f "$0")")"
name="${1:-$(cat "$HOME/.config/mono-rice/pic.name" 2>/dev/null)}"
exec python3 -I "$HERE/pixelart.py" pet "${name:-sakura}"
