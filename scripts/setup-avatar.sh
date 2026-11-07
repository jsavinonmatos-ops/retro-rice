#!/usr/bin/env bash
# Foto de usuario: chica anime (SFW, wallhaven) recortada en cuadrado -> pantalla de login
# Uso: setup-avatar.sh            (baja una nueva al azar)
#      setup-avatar.sh foto.jpg   (usa tu propia imagen)
set -u
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
echo "Avatar actualizado (se ve en el login). Para otro: mono-avatar"
