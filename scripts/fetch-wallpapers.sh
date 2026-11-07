#!/usr/bin/env bash
# Descarga wallpapers anime SFW (wallhaven.cc).
# Uso: fetch-wallpapers.sh [cantidad=48] [--mono] [--fresh]
#   (sin --mono)  a color, tonos oscuros/rosa/violeta/rojo  -> ~/Pictures/wallpapers/
#   --mono        blanco y negro (convertidos)               -> ~/Pictures/wallpapers/mono/
#   --fresh       borra antes los descargados anteriormente (no toca los tuyos)
# Las imágenes son de sus autores: uso personal, no se suben al repo (.gitignore).
set -u
N=48; MONO=0; FRESH=0
for a in "$@"; do case "$a" in --mono) MONO=1 ;; --fresh) FRESH=1 ;; *[0-9]*) N="$a" ;; esac; done

BASE="$HOME/Pictures/wallpapers"
if [ "$MONO" = 1 ]; then
  DIR="$BASE/mono"; COLORS=(000000 999999 424153)
else
  DIR="$BASE";      COLORS=(ea4c88 993399 000000 cc0000 663399 333399)
fi
mkdir -p "$DIR"
[ "$FRESH" = 1 ] && rm -f "$DIR"/wallhaven-*

PER=$(( (N + ${#COLORS[@]} - 1) / ${#COLORS[@]} ))
[ "$PER" -gt 24 ] && PER=24   # la API da 24 resultados por página

for c in "${COLORS[@]}"; do
  API="https://wallhaven.cc/api/v1/search?q=anime%20girl&categories=010&purity=100&sorting=random&atleast=1920x1080&ratios=16x9&colors=$c"
  curl -fsSL "$API" | jq -r '.data[].path' | head -n "$PER" | while read -r url; do
    f="$DIR/$(basename "$url")"
    if [ ! -f "$f" ]; then
      curl -fsSL "$url" -o "$f" || continue
      if [ "$MONO" = 1 ]; then convert "$f" -colorspace Gray -brightness-contrast -6x18 "$f"; fi
    fi
    echo "ok $(basename "$f")"
  done
  sleep 2   # cortesía con la API (límite 45 peticiones/min)
done
