#!/usr/bin/env bash
# Descarga wallpapers anime SFW (wallhaven.cc) en tonos que combinan con el tema: negro, rosa, magenta, violeta, rojo.
# Uso: fetch-wallpapers.sh [cantidad=16] [--mono] [--fresh]
#   --mono   los convierte a blanco y negro
#   --fresh  borra antes los wallpapers descargados anteriormente (wallhaven-*), no los tuyos
# Las imágenes son de sus autores: uso personal, no se suben al repo (.gitignore).
set -u
N=16; MONO=0; FRESH=0
for a in "$@"; do case "$a" in --mono) MONO=1 ;; --fresh) FRESH=1 ;; *[0-9]*) N="$a" ;; esac; done

DIR="$HOME/Pictures/wallpapers"; mkdir -p "$DIR"
[ "$FRESH" = 1 ] && rm -f "$DIR"/wallhaven-*

COLORS=(ea4c88 993399 000000 cc0000)      # paleta de wallhaven más cercana al acento #ff3d71
PER=$(( (N + ${#COLORS[@]} - 1) / ${#COLORS[@]} ))

for c in "${COLORS[@]}"; do
  API="https://wallhaven.cc/api/v1/search?q=anime%20girl&categories=010&purity=100&sorting=random&atleast=1920x1080&ratios=16x9&colors=$c"
  curl -fsSL "$API" | jq -r '.data[].path' | head -n "$PER" | while read -r url; do
    f="$DIR/$(basename "$url")"
    [ -f "$f" ] || curl -fsSL "$url" -o "$f" || continue
    [ "$MONO" = 1 ] && convert "$f" -colorspace Gray -brightness-contrast -6x18 "$f"
    echo "ok $(basename "$f")"
  done
  sleep 1   # cortesía con la API
done
