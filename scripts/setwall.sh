#!/usr/bin/env bash
# Uso: setwall.sh [imagen]   (sin argumento elige una al azar de ~/Pictures/wallpapers)
# Log en /tmp/setwall.log para depurar (útil cuando se lanza con Super+W)
exec >>/tmp/setwall.log 2>&1
set -u
DIR="$HOME/Pictures/wallpapers"
IMG="${1:-}"
if [ -z "$IMG" ]; then
  IMG="$(find "$DIR" -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | shuf -n1)"
fi
if [ ! -f "$IMG" ]; then
  echo "No hay wallpapers en $DIR (corre fetch-wallpapers.sh)"
  notify-send "Wallpaper" "No hay imágenes en $DIR" 2>/dev/null
  exit 1
fi

setp() { xfconf-query -c xfce4-desktop -p "$1" --create -t "$2" -s "$3"; }

# 1) propiedades que ya existen
while read -r p; do
  setp "$p" string "$IMG"
  setp "${p%last-image}image-style" int 5
done < <(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep 'last-image$')

# 2) crear las que falten: monitor<nombre> x workspace0..3 (xfdesktop no las crea hasta que se usa su GUI)
for m in $(xrandr --query 2>/dev/null | awk '/ connected/ {print $1}'); do
  for w in 0 1 2 3; do
    b="/backdrop/screen0/monitor${m}/workspace${w}"
    setp "$b/last-image" string "$IMG"
    setp "$b/image-style" int 5
    setp "$b/color-style" int 0
  done
done

xfdesktop --reload >/dev/null 2>&1 || true
echo "$(date +%T) Fondo: $IMG"
