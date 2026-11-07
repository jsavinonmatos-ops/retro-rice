#!/usr/bin/env bash
# Pantalla de bloqueo estilo macOS: fondo borroso + avatar + anillo con reloj.
# Uso: mono-lock            (bloquea)
#      mono-lock --nofork   (para xss-lock: se queda en primer plano)
# Con i3lock-color se ve completo; con i3lock normal queda el fondo borroso con avatar y nombre.
set -u
NOFORK=""; [ "${1:-}" = "--nofork" ] && NOFORK="-n"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
FONT="$(fc-match -f '%{file}' Inter 2>/dev/null)"

# 1) captura de la pantalla, borrosa y oscurecida
import -window root "$TMP/shot.png" 2>/dev/null || convert -size 1920x1080 xc:black "$TMP/shot.png"
convert "$TMP/shot.png" -scale 20% -blur 0x3 -scale 500% -fill black -colorize 45% "$TMP/bg.png"
W="$(identify -format %w "$TMP/bg.png")"; H="$(identify -format %h "$TMP/bg.png")"

# 2) avatar redondo + nombre, centrados arriba del anillo
if [ -f "$HOME/.face" ]; then
  convert -size 140x140 xc:none -fill white -draw "circle 70,70 70,0" "$TMP/mask.png"
  convert "$HOME/.face" -resize 140x140^ -gravity center -extent 140x140 "$TMP/mask.png" \
          -compose DstIn -composite "$TMP/round.png"
  convert "$TMP/bg.png" "$TMP/round.png" -gravity center -geometry +0-260 -composite "$TMP/bg.png"
fi
if [ -n "$FONT" ]; then
  convert "$TMP/bg.png" -gravity center -font "$FONT" -pointsize 24 -fill white \
          -annotate +0-166 "$(getent passwd "$USER" | cut -d: -f5 | cut -d, -f1 | grep . || echo "$USER")" "$TMP/bg.png"
fi

# 3) bloquear
if i3lock --help 2>&1 | grep -q -- '--clock'; then
  i3lock $NOFORK -i "$TMP/bg.png" -e \
    --clock --indicator --force-clock \
    --time-str="%H:%M" --date-str="%A, %d %B" \
    --time-font="Inter" --date-font="Inter" \
    --time-size=56 --date-size=18 \
    --time-color=ffffffff --date-color=ffffffbb \
    --radius=150 --ring-width=3 \
    --inside-color=00000000 --ring-color=ffffff55 --line-color=00000000 --separator-color=00000000 \
    --keyhl-color=ffffffff --bshl-color=ffffff99 \
    --insidever-color=00000000 --ringver-color=ffffffff \
    --insidewrong-color=00000000 --ringwrong-color=ff5370ff \
    --verif-text="" --wrong-text="Incorrecto" --noinput-text="" \
    --ignore-empty-password --pass-media-keys --pass-volume-keys
else
  i3lock $NOFORK -e -i "$TMP/bg.png"
fi
[ -z "$NOFORK" ] && sleep 1
exit 0
