#!/usr/bin/env bash
# Cambia el color de acento en todo el rice.
# Uso: accent.sh rose|violet|cyan|red|green   o   accent.sh '#rrggbb'
set -eu
REPO="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
CUR="$(cat "$REPO/.accent" 2>/dev/null || echo ff3d71)"
case "${1:-}" in
  rose) NEW=ff3d71 ;; violet) NEW=a46bff ;; cyan) NEW=2fd7e8 ;; red) NEW=ff2a2a ;; green) NEW=3ddc84 ;;
  \#??????) NEW="${1#\#}" ;;
  *) echo "Uso: accent.sh rose|violet|cyan|red|green|'#rrggbb'   (actual: #$CUR)"; exit 1 ;;
esac
hex2rgb() { printf '%d, %d, %d' "0x${1:0:2}" "0x${1:2:2}" "0x${1:4:2}"; }
FILES=$(grep -rIl -i -e "$CUR" -e "$(hex2rgb "$CUR")" "$REPO/config" "$REPO/browser" "$REPO/login" "$REPO/home" 2>/dev/null || true)
for f in $FILES; do
  sed -i -e "s/$CUR/$NEW/gI" -e "s/$(hex2rgb "$CUR")/$(hex2rgb "$NEW")/g" "$f"
done
echo "$NEW" > "$REPO/.accent"
"$REPO/config/polybar/launch.sh" >/dev/null 2>&1 || true
echo "Acento: #$NEW. Para aplicar Firefox y login corre: bash $REPO/scripts/setup-browser.sh && bash $REPO/scripts/setup-login.sh"
