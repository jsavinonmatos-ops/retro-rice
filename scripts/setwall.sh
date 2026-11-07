#!/usr/bin/env bash
# Uso: setwall.sh [imagen]   (sin argumento elige una al azar de ~/Pictures/wallpapers)
set -eu
DIR="$HOME/Pictures/wallpapers"
IMG="${1:-}"
if [ -z "$IMG" ]; then
  IMG="$(find "$DIR" -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.webp' \) | shuf -n1)"
fi
[ -f "$IMG" ] || { echo "No hay wallpapers en $DIR (corre fetch-wallpapers.sh)"; exit 1; }

# xfdesktop dibuja el fondo, hay que setearlo en cada monitor/workspace
xfconf-query -c xfce4-desktop -l | grep 'last-image$' | while read -r p; do
  xfconf-query -c xfce4-desktop -p "$p" -s "$IMG"
  xfconf-query -c xfce4-desktop -p "${p%last-image}image-style" --create -t int -s 5 2>/dev/null || true
done
echo "Fondo: $IMG"
