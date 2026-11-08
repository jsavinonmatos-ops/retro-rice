#!/usr/bin/env bash
# mono-pic: pixel art de chica anime hecho para la terminal (fastfetch y saludo de mono-ai).
# Uso: mono-pic sakura | yuki | mizu | kuro     (personajes incluidos)
#      mono-pic mi-pixel-art.png                (tu propio pixel art; conserva su resolución, hasta 64 px de ancho)
#      mono-pic imagen.png --scale 8            (si es una versión ampliada 8 veces y no se detectó sola)
#      mono-pic imagen.png --width 80           (permitir hasta 80 px de ancho)
#      mono-pic --list
set -u
HERE="$(dirname "$(readlink -f "$0")")"
DIR="$HOME/.config/mono-rice"; ANSI="$DIR/pic.ansi"; FF="$HOME/.config/fastfetch/pic.jsonc"
PA="$HERE/pixelart.py"
BUILTIN="sakura yuki mizu kuro"

main() {
  local arg="" scale="" width="" size w h tmp
  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help) sed -n '2,10p' "$0" | sed 's/^# \?//'; return 1 ;;
      --list) echo "Personajes: $BUILTIN"; return 0 ;;
      --scale) scale="${2:-}"; shift ;;
      --width|--pixels) width="${2:-}"; shift ;;
      *) arg="$1" ;;
    esac
    shift
  done
  [ -n "$arg" ] || { sed -n '2,10p' "$0" | sed 's/^# \?//'; return 1; }
  mkdir -p "$DIR" "$(dirname "$FF")"

  if [[ " $BUILTIN " == *" $arg "* ]]; then
    size="$(python3 -I "$PA" draw "$arg" --ansi "$ANSI")" || return 1
  elif [ -f "$arg" ]; then
    command -v convert >/dev/null || { echo "Falta ImageMagick: sudo apt install imagemagick"; return 1; }
    tmp="$(mktemp --suffix=.png)"
    # solo se normaliza el formato (PNG de 8 bits con transparencia); NO se cambia el tamaño aquí
    convert "${arg}[0]" -depth 8 -interlace none -define png:color-type=6 "png32:$tmp" || return 1
    size="$(python3 -I "$PA" sprite "$tmp" --ansi "$ANSI" ${scale:+--scale "$scale"} ${width:+--width "$width"})" || { rm -f "$tmp"; return 1; }
    rm -f "$tmp"
  else
    echo "No conozco '$arg'. Opciones: $BUILTIN, o la ruta a un PNG."; return 1
  fi

  echo "$arg" > "$DIR/pic.name"
  w="${size%x*}"; h="${size#*x}"
  echo "$w $h" > "$DIR/pic.size"
  python3 -I "$PA" config "$ANSI" "$w" "$h" "$FF" || return 1
  echo "Listo (${w}x${h} píxeles). Así se ve:"; cat "$ANSI"; printf '\033[0m'
  echo "Aparece en fastfetch al abrir kitty y en el saludo de mono-ai (Super+I)."
  [ "$w" -gt 40 ] && echo "Es ancha: si tu ventana es angosta, fastfetch pondrá la imagen arriba y la información debajo."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then main "$@"; fi
