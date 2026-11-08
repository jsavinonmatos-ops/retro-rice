#!/usr/bin/env bash
# Foto de usuario: chica anime (SFW, wallhaven) recortada en cuadrado -> pantalla de login
# Uso: setup-avatar.sh            (baja una nueva al azar)
#      setup-avatar.sh foto.jpg   (usa tu propia imagen)
set -u

# mono-avatar --choices : baja varias opciones a ~/Pictures/avatars para que elijas la que quieras
if [ "${1:-}" = "--choices" ]; then
  OUT="$HOME/Pictures/avatars"; mkdir -p "$OUT"; rm -f "$OUT"/*.png
  API="https://wallhaven.cc/api/v1/search?q=anime%20girl&categories=010&purity=100&sorting=random&ratios=portrait&atleast=800x1000"
  i=0
  for url in $(curl -fsSL --max-time 30 "$API" | jq -r '.data[].path' | head -n 12); do
    t="$(mktemp --suffix=.jpg)"
    curl -fsSL --max-time 60 "$url" -o "$t" || { rm -f "$t"; continue; }
    i=$((i + 1))
    convert "$t" -gravity north -crop 1:1+0+0 +repage -resize 512x512 -colorspace Gray -contrast-stretch 1%x1% "$OUT/$(printf '%02d' "$i").png"
    rm -f "$t"
  done
  echo "Descargadas $i opciones en $OUT"
  command -v feh >/dev/null && feh -t -E 200 -y 200 -W 1100 -H 700 "$OUT" &
  echo "Cuando elijas una (el número que ves en el nombre): mono-avatar $OUT/03.png"
  exit 0
fi
SRC="${1:-}"
TMP="$(mktemp -d)"
if [ -z "$SRC" ]; then
  API="https://wallhaven.cc/api/v1/search?q=anime%20girl&categories=010&purity=100&sorting=random&ratios=portrait&atleast=800x1000&colors=ea4c88"
  URL="$(curl -fsSL "$API" | jq -r '.data[0].path // empty')"
  if [ -n "$URL" ]; then
    curl -fsSL "$URL" -o "$TMP/src.jpg" && SRC="$TMP/src.jpg"
  fi
fi
[ -z "$SRC" ] && SRC="$(find "$HOME/Pictures/wallpapers" -type f \( -iname '*.jpg' -o -iname '*.png' \) | shuf -n1)"
[ -f "$SRC" ] || { echo "No pude conseguir una imagen para el avatar"; exit 0; }

# cuadrado centrado arriba (donde suele estar la cara) -> 512x512
convert "$SRC" -gravity north -crop 1:1+0+0 +repage -resize 512x512 -colorspace Gray -contrast-stretch 1%x1% "$TMP/avatar.png"

"$(dirname "$(readlink -f "$0")")/roundify.sh" "$TMP/avatar.png" "$TMP/avatar_round.png" 512 \
  || echo "(no pude recortar el avatar en círculo; queda cuadrado)"
mv -f "$TMP/avatar_round.png" "$TMP/avatar.png"
cp "$TMP/avatar.png" "$HOME/.face"
sudo mkdir -p /var/lib/AccountsService/icons /var/lib/AccountsService/users
sudo cp "$TMP/avatar.png" "/var/lib/AccountsService/icons/$USER"
sudo chmod 644 "/var/lib/AccountsService/icons/$USER"
printf '[User]\nIcon=/var/lib/AccountsService/icons/%s\nSystemAccount=false\n' "$USER" \
  | sudo tee "/var/lib/AccountsService/users/$USER" >/dev/null
rm -rf "$TMP"
command -v mono-lock >/dev/null && mono-lock --prepare >/dev/null 2>&1
echo "Avatar actualizado (se ve en el login). Para otro: mono-avatar"
