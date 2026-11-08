#!/usr/bin/env bash
# mono-pic: foto anime como pixel art hecho de caracteres de terminal, para fastfetch y mono-ai.
# Uso: mono-pic imagen.jpg [--pixels 48] [--colors 28] [--smooth] [--real]
#      mono-pic --choices          baja varias fotos anime para que elijas
#      mono-pic --choices pixel    busca imágenes que ya son pixel art
#   --pixels N   ancho del pixel art (más grande = más detalle; el alto es la mitad en caracteres)
#   --colors N   colores de la paleta (menos = más estilo retro)
#   --smooth     sin efecto pixel art (conversión directa, suele verse más borrosa)
#   --real       en fastfetch usa la imagen real (protocolo gráfico de kitty) en vez de caracteres
set -u
DIR="$HOME/.config/mono-rice"; ANSI="$DIR/pic.ansi"; PNG="$DIR/pic.png"
FF="$HOME/.config/fastfetch/pic.jsonc"

# configuración de fastfetch: $1 tipo de logo, $2 archivo, $3 ancho, $4 alto (en caracteres)
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
  local kind="${1:-}" out="$HOME/Pictures/pics" i=0 url t q api
  mkdir -p "$out"; rm -f "$out"/*.jpg "$out"/*.png
  if [ "$kind" = "pixel" ]; then
    q="pixel%20art%20anime%20girl"; api="https://wallhaven.cc/api/v1/search?q=$q&categories=111&purity=100&sorting=relevance&atleast=500x500"
  else
    api="https://wallhaven.cc/api/v1/search?q=anime%20girl&categories=010&purity=100&sorting=random&ratios=portrait&atleast=800x1000"
  fi
  for url in $(curl -fsSL --max-time 30 "$api" | jq -r '.data[].path' | head -n 12); do
    t="$out/$(printf '%02d' $((i + 1))).${url##*.}"
    curl -fsSL --max-time 60 "$url" -o "$t" && i=$((i + 1)) || rm -f "$t"
  done
  echo "Descargadas $i imágenes en $out"
  command -v feh >/dev/null && feh -t -E 200 -y 200 -W 1100 -H 700 "$out" &
  echo "Cuando elijas una (por su número): mono-pic $out/03.jpg"
}

main() {
  local n=48 colors=28 smooth=0 real=0 img="" w h iw ih grav tmp
  while [ $# -gt 0 ]; do
    case "$1" in
      --choices) choices "${2:-}"; return ;;
      --pixels|--size) n="${2:-48}"; n="${n%%x*}"; shift ;;
      --colors) colors="${2:-28}"; shift ;;
      --smooth) smooth=1 ;;
      --real) real=1 ;;
      *) img="$1" ;;
    esac
    shift
  done
  [ -f "$img" ] || { sed -n '2,11p' "$0" | sed 's/^# \?//'; return 1; }
  command -v chafa >/dev/null || { echo "Falta chafa: sudo apt install chafa"; return 1; }
  [[ "$n" =~ ^[0-9]+$ && "$colors" =~ ^[0-9]+$ ]] || { echo "--pixels y --colors deben ser números"; return 1; }
  n=$(( n / 2 * 2 )); [ "$n" -lt 16 ] && n=16
  w="$n"; h=$(( n / 2 ))
  mkdir -p "$DIR"; tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' RETURN

  # cuadrado: desde arriba en fotos verticales (la cara), centrado en las horizontales
  read -r iw ih < <(identify -format '%w %h' "${img}[0]")
  grav=north; [ "${iw:-0}" -gt "${ih:-0}" ] && grav=center
  convert "${img}[0]" -gravity "$grav" -crop 1:1+0+0 +repage "$tmp/sq.png" || return 1

  if [ "$smooth" = 1 ]; then
    convert "$tmp/sq.png" -resize 800x800 "$PNG"
    chafa -f symbols --colors=full -s "${w}x${h}" "$PNG" > "$ANSI"
  else
    # pixel art: reducir con promedio de cajas, realzar color y contraste, paleta limitada y SIN tramado
    convert "$tmp/sq.png" -filter Box -resize "${n}x${n}!" -modulate 100,130,100 \
            -contrast-stretch 0.5%x0.5% -colors "$colors" +dither "$tmp/px.png" || return 1
    # versión grande con píxeles nítidos (para el modo --real)
    convert "$tmp/px.png" -filter point -resize 800x800 "$PNG"
    # media celda = un píxel: los caracteres ▀ ▄ reproducen el pixel art sin mezclar colores
    chafa -f symbols --symbols half --colors=full --dither none -s "${w}x${h}" "$tmp/px.png" > "$ANSI"
  fi

  if [ "$real" = 1 ]; then write_config kitty-direct "$PNG" "$w" "$h"; else write_config file-raw "$ANSI" "$w" "$h"; fi
  echo "Listo. Así se verá:"; cat "$ANSI"; printf '\033[0m'
  echo "Aparece en fastfetch al abrir kitty y en el saludo de mono-ai."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then main "$@"; fi
