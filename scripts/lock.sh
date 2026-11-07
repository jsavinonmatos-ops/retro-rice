#!/usr/bin/env bash
# Bloqueo estilo macOS: fondo borroso, tarjeta de cristal con avatar y nombre, y (con i3lock-color) anillo con reloj.
# Uso: mono-lock             bloquea
#      mono-lock --nofork    para xss-lock (se queda en primer plano)
#      mono-lock --prepare   solo prepara la tarjeta (avatar+nombre) para que el bloqueo sea instantáneo
# Para el anillo con reloj hay que compilar i3lock-color una vez: scripts/build-i3lock-color.sh
set -u
NOFORK=""; PREPARE=0
case "${1:-}" in --nofork) NOFORK="-n" ;; --prepare) PREPARE=1 ;; esac
HERE="$(dirname "$(readlink -f "$0")")"
# usar explícitamente el i3lock-color compilado (/usr/local/bin) si existe; así no depende del orden del PATH
I3LOCK=i3lock; [ -x /usr/local/bin/i3lock ] && I3LOCK=/usr/local/bin/i3lock

# Opcional (desactivado: en algunas máquinas al desbloquear queda la pantalla negra): MONO_LOCK_LIGHTDM=1 mono-lock
if [ "${MONO_LOCK_LIGHTDM:-0}" = 1 ] && [ -n "${XDG_SEAT_PATH:-}" ] && command -v dm-tool >/dev/null && pgrep -x lightdm >/dev/null; then
  dm-tool lock; [ -n "$NOFORK" ] && sleep 3; exit 0
fi

CACHE="$HOME/.cache/mono-lock"; mkdir -p "$CACHE"
OVERLAY="$CACHE/overlay.png"
FONT="$(fc-match -f '%{file}' Inter 2>/dev/null)"
NAME="$(getent passwd "$USER" | cut -d: -f5 | cut -d, -f1 | grep . || echo "$USER")"

# --- tarjeta (avatar + nombre): se hace UNA vez y se guarda; se rehace si cambias la foto ---
build_overlay() {
  local T; T="$(mktemp -d)"
  convert -size 440x640 xc:none -fill '#00000066' -stroke '#ffffff30' -strokewidth 1 \
          -draw "roundrectangle 1,1 438,638 30,30" "$T/o.png"
  if [ -f "$HOME/.face" ]; then
    "$HERE/roundify.sh" "$HOME/.face" "$T/av.png" 140
    convert "$T/o.png" "$T/av.png" -gravity center -geometry +0-202 -composite "$T/o.png"
    convert -size 154x154 xc:none -fill none -stroke white -strokewidth 3 -draw "circle 77,77 77,3" "$T/ring.png"
    convert "$T/o.png" "$T/ring.png" -gravity center -geometry +0-202 -composite "$T/o.png"
  fi
  if [ -n "$FONT" ]; then
    convert "$T/o.png" -gravity center -font "$FONT" \
            -pointsize 26 -fill white -annotate +0-100 "$NAME" \
            -pointsize 17 -fill '#ffffff99' -annotate +0+270 "Escribe tu contraseña" "$T/o.png"
  fi
  cp "$T/o.png" "$OVERLAY"; rm -rf "$T"
}
KEY="v2-$(stat -c %Y "$HOME/.face" 2>/dev/null)-$NAME"
if [ ! -f "$OVERLAY" ] || [ "$(cat "$CACHE/key" 2>/dev/null)" != "$KEY" ]; then
  build_overlay; echo "$KEY" > "$CACHE/key"
fi
[ "$PREPARE" = 1 ] && { echo "Tarjeta de bloqueo lista."; exit 0; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# --- fondo: captura -> borrosa a poca resolución (rápido) -> oscurecida -> tarjeta encima, en UN solo paso ---
import -window root ppm:- 2>/dev/null \
  | convert - -resize 12.5% -blur 0x1.2 -resize 800% -modulate 90,40 -fill black -colorize 42% \
            "$OVERLAY" -gravity center -geometry +0-80 -composite \
            -define png:compression-level=1 "$TMP/bg.png" 2>/dev/null \
  || convert -size 1920x1080 xc:black "$TMP/bg.png"

HAS_CLOCK=0
if "$I3LOCK" --version 2>&1 | grep -qi 'color' || "$I3LOCK" --help 2>&1 | grep -qi -- 'clock'; then HAS_CLOCK=1; fi
if [ "$HAS_CLOCK" = 0 ] && [ -n "$FONT" ]; then
  convert "$TMP/bg.png" -gravity center -font "$FONT" \
          -pointsize 20 -fill '#ffffff90' -annotate +0-70 "Bloqueado a las" \
          -pointsize 96 -fill white -annotate +0+0 "$(date +%H:%M)" \
          -pointsize 22 -fill '#ffffffb0' -annotate +0+70 "$(date '+%A, %d %B')" "$TMP/bg.png"
fi

fancy() {
  "$I3LOCK" $NOFORK -i "$TMP/bg.png" -e \
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
plain() { "$I3LOCK" $NOFORK -e -u -i "$TMP/bg.png"; }   # i3lock normal: sin su indicador (anillo verde y "Num Lock")

# i3lock-color rechaza opciones desconocidas: si falla, caer al i3lock simple y no dejar la pantalla sin bloquear
if [ "$HAS_CLOCK" = 1 ]; then fancy || plain; else plain; fi
[ -z "$NOFORK" ] && sleep 0.5
exit 0
