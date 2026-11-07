#!/usr/bin/env bash
# Fija el DPI de la sesión actual (X resources + xsettings).
# Uso: mono-session-dpi 108     |  sin argumento: lee Xft.dpi de ~/.Xresources (el DPI de XFCE)
DPI="${1:-$(awk -F': *' '/^Xft.dpi/ {print $2}' "$HOME/.Xresources" 2>/dev/null)}"
DPI="${DPI:-120}"
CUR=$(( 24 * DPI / 96 ))
printf 'Xft.dpi: %s\nXcursor.size: %s\n' "$DPI" "$CUR" | xrdb -merge
xfconf-query -c xsettings -p /Xft/DPI --create -t int -s "$DPI" 2>/dev/null
xfconf-query -c xsettings -p /Gtk/CursorThemeSize --create -t int -s "$CUR" 2>/dev/null
exit 0
