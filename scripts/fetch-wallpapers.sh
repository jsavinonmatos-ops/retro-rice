#!/usr/bin/env bash
# Descarga wallpapers anime SFW desde la API pública de wallhaven.cc
# Uso: fetch-wallpapers.sh [cantidad=12] [--mono]   (--mono los convierte a blanco y negro)
# Las imágenes son de sus autores: uso personal, no se suben al repo (.gitignore).
set -eu
N=12; MONO=0
for a in "$@"; do case "$a" in --mono) MONO=1 ;; *[0-9]*) N="$a" ;; esac; done

DIR="$HOME/Pictures/wallpapers"; mkdir -p "$DIR"
API="https://wallhaven.cc/api/v1/search?q=anime%20girl&categories=010&purity=100&sorting=random&atleast=1920x1080&ratios=16x9"

curl -fsSL "$API" | jq -r '.data[].path' | head -n "$N" | while read -r url; do
  f="$DIR/$(basename "$url")"
  [ -f "$f" ] || curl -fsSL "$url" -o "$f"
  if [ "$MONO" = 1 ]; then
    convert "$f" -colorspace Gray -brightness-contrast -6x18 "$f"
  fi
  echo "ok $(basename "$f")"
done
