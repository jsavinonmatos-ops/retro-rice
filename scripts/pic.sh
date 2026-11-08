#!/usr/bin/env bash
# mono-pic: foto anime hecha de caracteres de terminal (arte ANSI) para fastfetch y para mono-ai.
# Uso: mono-pic imagen.jpg [--size 40x20] [--real]
#      mono-pic --choices        baja varias fotos anime para que elijas
#   --size  columnas x filas del arte (más grande = más detalle)
#   --real  en fastfetch usa la imagen de verdad (protocolo gráfico de kitty) en vez de caracteres
set -u
DIR="$HOME/.config/mono-rice"; ANSI="$DIR/pic.ansi"; PNG="$DIR/pic.png"
FF="$HOME/.config/fastfetch/pic.jsonc"

# configuración de fastfetch: $1 tipo de logo, $2 archivo, $3 ancho, $4 alto
write_config() {
  mkdir -p "$(dirname "$FF")"
  cat > "$FF" <<JSON
{
  "logo": {
    "type": "$1",
    "source": "$2",
    "width": $3,
    "height": $4,
    "padding": { "top": 1, "right": 3 }
  },
  "display": { "separator": "  " },
  "modules": ["title", "separator", "os", "host", "kernel", "uptime", "packages", "shell", "wm", "terminal", "cpu", "gpu", "memory", "disk", "break", "colors"]
}
JSON
}

choices() {
  local out="$HOME/Pictures/pics" i=0 url t
  mkdir -p "$out"; rm -f "$out"/*.jpg
  local api="https://wallhaven.cc/api/v1/search?q=anime%20girl&categories=010&purity=100&sorting=random&ratios=portrait&atleast=800x1000"
  for url in $(curl -fsSL --max-time 30 "$api" | jq -r '.data[].path' | head -n 12); do
    t="$out/$(printf '%02d' $((i + 1))).jpg"
    curl -fsSL --max-time 60 "$url" -o "$t" && i=$((i + 1)) || rm -f "$t"
  done
  echo "Descargadas $i fotos en $out"
  command -v feh >/dev/null && feh -t -E 200 -y 200 -W 1100 -H 700 "$out" &
  echo "Cuando elijas una (por su número): mono-pic $out/03.jpg"
}

main() {
  local size=40x20 real=0 img="" w h
  while [ $# -gt 0 ]; do
    case "$1" in
      --choices) choices; return ;;
      --size) size="${2:-40x20}"; shift ;;
      --real) real=1 ;;
      *) img="$1" ;;
    esac
    shift
  done
  [ -f "$img" ] || { sed -n '2,8p' "$0" | sed 's/^# \?//'; return 1; }
  command -v chafa >/dev/null || { echo "Falta chafa: sudo apt install chafa"; return 1; }
  [[ "$size" =~ ^[0-9]+x[0-9]+$ ]] || { echo "--size debe ser así: 40x20"; return 1; }
  w="${size%x*}"; h="${size#*x}"
  mkdir -p "$DIR"

  # cuadrado desde arriba (donde suele estar la cara) y a un tamaño razonable
  convert "$img" -gravity north -crop 1:1+0+0 +repage -resize 800x800 "$PNG" || return 1
  # -f symbols: caracteres unicode con color (sin protocolos gráficos); --colors=full: colores de 24 bits
  chafa -f symbols --colors=full -s "${w}x${h}" "$PNG" > "$ANSI"

  if [ "$real" = 1 ]; then write_config kitty-direct "$PNG" "$w" "$h"; else write_config file-raw "$ANSI" "$w" "$h"; fi
  echo "Listo. Así se verá:"; cat "$ANSI"; printf '\033[0m'
  echo "Aparece en fastfetch al abrir kitty y en el saludo de mono-ai."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then main "$@"; fi
