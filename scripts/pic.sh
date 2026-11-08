#!/usr/bin/env bash
# mono-pic: pixel art de chica anime hecho para la terminal (fastfetch y saludo de mono-ai).
# Uso: mono-pic sakura | yuki | mizu | kuro     (personajes incluidos)
#      mono-pic mi-pixel-art.png                (tu propio pixel art; conserva su resolución, hasta 64 px de ancho)
#      mono-pic imagen.png --scale 8            (si es una versión ampliada 8 veces y no se detectó sola)
#      mono-pic imagen.png --real               (la imagen COMPLETA, sin reducir, con el protocolo gráfico de kitty)
#      mono-pic imagen.png --rows 18            (altura máxima en filas de texto; por defecto 22)
#      mono-pic --list
set -u
HERE="$(dirname "$(readlink -f "$0")")"
DIR="$HOME/.config/mono-rice"; ANSI="$DIR/pic.ansi"; FF="$HOME/.config/fastfetch/pic.jsonc"
PA="$HERE/pixelart.py"
BUILTIN="sakura yuki mizu kuro"

main() {
  local arg="" scale="" width="" rows="" real=0 out size cells w h tmp
  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help) sed -n '2,12p' "$0" | sed 's/^# \?//'; return 1 ;;
      --list) echo "Personajes: $BUILTIN"; return 0 ;;
      --scale) scale="${2:-}"; shift ;;
      --width|--pixels) width="${2:-}"; shift ;;
      --rows) rows="${2:-}"; shift ;;
      --real) real=1 ;;
      *) arg="$1" ;;
    esac
    shift
  done
  [ -n "$arg" ] || { sed -n '2,12p' "$0" | sed 's/^# \?//'; return 1; }
  mkdir -p "$DIR" "$(dirname "$FF")"
  rm -f "$DIR/pic.real"

  if [[ " $BUILTIN " == *" $arg "* ]]; then
    out="$(python3 -I "$PA" draw "$arg" --ansi "$ANSI")" || return 1
  elif [ -f "$arg" ]; then
    command -v convert >/dev/null || { echo "Falta ImageMagick: sudo apt install imagemagick"; return 1; }
    tmp="$(mktemp --suffix=.png)"
    # solo se normaliza el formato (PNG de 8 bits con transparencia); NO se cambia el tamaño aquí
    convert "${arg}[0]" -depth 8 -interlace none -define png:color-type=6 "png32:$tmp" || return 1
    out="$(python3 -I "$PA" sprite "$tmp" --ansi "$ANSI" ${scale:+--scale "$scale"} ${width:+--width "$width"} \
           ${rows:+--rows "$rows"} ${real:+--real "$DIR/pic.png"})" || { rm -f "$tmp"; return 1; }
    rm -f "$tmp"
  else
    echo "No conozco '$arg'. Opciones: $BUILTIN, o la ruta a una imagen."; return 1
  fi

  echo "$arg" > "$DIR/pic.name"
  size="$(printf '%s\n' "$out" | sed -n 1p)"; cells="$(printf '%s\n' "$out" | sed -n 2p)"
  if [ "$real" = 1 ] && [ -n "$cells" ]; then
    w="${cells%x*}"; h="${cells#*x}"
    touch "$DIR/pic.real"; echo "$w $h" > "$DIR/pic.size"
    python3 -I "$PA" config "$DIR/pic.png" "$w" "$h" "$FF" kitty-direct || return 1
    echo "Listo: imagen real (${w}x${h} celdas) con el protocolo gráfico de kitty. Ábrela en una terminal nueva."
    echo "(En vista previa de texto aproximada:)"; cat "$ANSI"; printf '\033[0m'
  else
    w="${size%x*}"; h="${size#*x}"
    echo "$w $h" > "$DIR/pic.size"
    python3 -I "$PA" config "$ANSI" "$w" "$h" "$FF" || return 1
    echo "Listo (${w}x${h} píxeles). Así se ve:"; cat "$ANSI"; printf '\033[0m'
  fi
  echo "Aparece en fastfetch al abrir kitty y en el saludo de mono-ai (Super+I)."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then main "$@"; fi
