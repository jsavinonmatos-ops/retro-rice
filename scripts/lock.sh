#!/usr/bin/env bash
# Pantalla de bloqueo estilo macOS: fondo borroso y en tonos grises, tarjeta de cristal,
# avatar redondo con aro, nombre y anillo con reloj.
# Uso: mono-lock            (bloquea)
#      mono-lock --nofork   (para xss-lock: se queda en primer plano)
# Con i3lock-color se ve completo; con i3lock normal queda la imagen sin reloj ni anillo.
set -u
NOFORK=""; [ "${1:-}" = "--nofork" ] && NOFORK="-n"

# Preferido: bloquear con la pantalla de LightDM (la misma del login, con tu tema, avatar y usuario)
if [ -n "${XDG_SEAT_PATH:-}" ] && command -v dm-tool >/dev/null && pgrep -x lightdm >/dev/null; then
  dm-tool lock
  [ -n "$NOFORK" ] && sleep 3     # xss-lock espera a que el bloqueo ya esté puesto antes de suspender
  exit 0
fi

# Respaldo (sin LightDM): i3lock con una imagen borrosa
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
ROUND="$(dirname "$(readlink -f "$0")")/roundify.sh"
FONT="$(fc-match -f '%{file}' Inter 2>/dev/null)"
NAME="$(getent passwd "$USER" | cut -d: -f5 | cut -d, -f1 | grep . || echo "$USER")"

# 1) captura -> borrosa, poco saturada (para que combine con el blanco y negro), viñeta y oscurecida
import -window root "$TMP/shot.png" 2>/dev/null || convert -size 1920x1080 xc:black "$TMP/shot.png"
convert "$TMP/shot.png" -scale 20% -blur 0x3 -scale 500% -modulate 90,40 \
        -background black -vignette 0x160 -fill black -colorize 40% "$TMP/bg.png"

# 2) tarjeta de cristal centrada (y desplazada un poco hacia arriba)
convert -size 440x570 xc:none -fill '#00000066' -stroke '#ffffff30' -strokewidth 1 \
        -draw "roundrectangle 1,1 438,568 30,30" "$TMP/card.png"
convert "$TMP/bg.png" "$TMP/card.png" -gravity center -geometry +0-35 -composite "$TMP/bg.png"

# 3) avatar redondo: se recorta con una máscara (más fiable que el canal alfa) y lleva un aro blanco
if [ -f "$HOME/.face" ]; then
  "$ROUND" "$HOME/.face" "$TMP/aface.png" 140
  convert "$TMP/bg.png" "$TMP/aface.png" -gravity center -geometry +0-250 -composite "$TMP/bg.png"
  convert -size 154x154 xc:none -fill none -stroke white -strokewidth 3 -draw "circle 77,77 77,3" "$TMP/aring.png"
  convert "$TMP/bg.png" "$TMP/aring.png" -gravity center -geometry +0-250 -composite "$TMP/bg.png"
fi

# 4) textos
if [ -n "$FONT" ]; then
  convert "$TMP/bg.png" -gravity center -font "$FONT" \
          -pointsize 26 -fill white -annotate +0-163 "$NAME" \
          -pointsize 17 -fill '#ffffff99' -annotate +0+185 "Escribe tu contraseña" "$TMP/bg.png"
fi

# 5) bloquear
fancy() {
  i3lock $NOFORK -i "$TMP/bg.png" -e \
    --clock --indicator --force-clock --no-modkey-text \
    --time-str="%H:%M" --date-str="%A, %d %B" \
    --time-font="Inter" --date-font="Inter" \
    --time-size=54 --date-size=17 \
    --time-color=ffffffff --date-color=ffffffbb \
    --radius=150 --ring-width=3 \
    --inside-color=00000055 --ring-color=ffffff40 --line-color=00000000 --separator-color=00000000 \
    --keyhl-color=ffffffff --bshl-color=ffffff80 \
    --insidever-color=00000055 --ringver-color=ffffffcc \
    --insidewrong-color=00000055 --ringwrong-color=ff5370ff \
    --verif-color=ffffffff --wrong-color=ff5370ff --modif-color=ffffffff \
    --verif-text="" --wrong-text="Incorrecto" --noinput-text="" \
    --ignore-empty-password --pass-media-keys --pass-volume-keys
}
plain() { i3lock $NOFORK -e -i "$TMP/bg.png"; }

# si i3lock-color rechaza alguna opción (versión distinta), no dejar la pantalla sin bloquear
if i3lock --help 2>&1 | grep -q -- '--clock'; then fancy || plain; else plain; fi
[ -z "$NOFORK" ] && sleep 1
exit 0
