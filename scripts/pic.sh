#!/usr/bin/env bash
# mono-pic: pixel art de chica anime hecho para la terminal (fastfetch y saludo de mono-ai).
# Uso: mono-pic sakura | yuki | mizu | kuro     (personajes incluidos)
#      mono-pic mi-pixel-art.png                (tu propio pixel art, hasta 40 px de ancho)
#      mono-pic --list
set -u
HERE="$(dirname "$(readlink -f "$0")")"
DIR="$HOME/.config/mono-rice"; ANSI="$DIR/pic.ansi"; FF="$HOME/.config/fastfetch/pic.jsonc"
PA="$HERE/pixelart.py"
BUILTIN="sakura yuki mizu kuro"

main() {
  local arg="${1:-}" size w h tmp
  case "$arg" in
    ""|-h|--help) sed -n '2,6p' "$0" | sed 's/^# \?//'; return 1 ;;
    --list) echo "Personajes: $BUILTIN"; return 0 ;;
  esac
  mkdir -p "$DIR" "$(dirname "$FF")"

  if [[ " $BUILTIN " == *" $arg "* ]]; then
    size="$(python3 -I "$PA" draw "$arg" --ansi "$ANSI")" || return 1
  elif [ -f "$arg" ]; then
    command -v convert >/dev/null || { echo "Falta ImageMagick: sudo apt install imagemagick"; return 1; }
    tmp="$(mktemp --suffix=.png)"
    # sin suavizar (píxeles nítidos), 8 bits RGBA, sin entrelazado; solo se reduce si es más ancho de 40 px
    convert "${arg}[0]" -filter point -resize '40x40>' -depth 8 -interlace none -define png:color-type=6 "png32:$tmp" || return 1
    size="$(python3 -I "$PA" sprite "$tmp" --ansi "$ANSI")" || { rm -f "$tmp"; return 1; }
    rm -f "$tmp"
  else
    echo "No conozco '$arg'. Opciones: $BUILTIN, o la ruta a un PNG."; return 1
  fi

  w="${size%x*}"; h="${size#*x}"
  python3 -I "$PA" config "$ANSI" "$w" "$h" "$FF" || return 1
  echo "Listo. Así se ve:"; cat "$ANSI"; printf '\033[0m'
  echo "Aparece en fastfetch al abrir kitty y en el saludo de mono-ai (Super+I)."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then main "$@"; fi
