#!/usr/bin/env bash
# Ajusta el tamaño de todo el escritorio. Uso: mono-scale 120   (96 = pequeño, 120 = recomendado, 144 = grande)
set -eu
REPO="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
DPI="${1:-}"
case "$DPI" in ''|*[!0-9]*) echo "Uso: mono-scale <96-168>   (actual: $(grep -o '[0-9]*' <<<"$(grep '^Xft.dpi' "$REPO/home/.Xresources")" | head -1))"; exit 1 ;; esac
[ "$DPI" -ge 96 ] && [ "$DPI" -le 168 ] || { echo "Usa un valor entre 96 y 168"; exit 1; }
CUR=$(( 24 * DPI / 96 ))
sed -i -e "s/^Xft.dpi:.*/Xft.dpi: $DPI/" -e "s/^Xcursor.size:.*/Xcursor.size: $CUR/" "$REPO/home/.Xresources"
xrdb -merge "$HOME/.Xresources" 2>/dev/null || true
xfconf-query -c xsettings -p /Xft/DPI --create -t int -s "$DPI"
xfconf-query -c xsettings -p /Gtk/CursorThemeSize --create -t int -s "$CUR"
sed -i "s/^xft-dpi=.*/xft-dpi=$DPI/" "$REPO/scripts/setup-login.sh" 2>/dev/null || true
"$REPO/config/polybar/launch.sh" >/dev/null 2>&1 || true
echo "DPI $DPI aplicado. Cierra y abre kitty/Firefox y las demás apps para verlo; cierra sesión para el cursor."
