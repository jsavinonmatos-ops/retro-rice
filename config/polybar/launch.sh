#!/usr/bin/env bash
# Reinicia polybar. Elige la barra según la sesión (i3 o XFCE) y autodetecta batería y adaptador.
# Protección: valida config.ini antes; si tiene errores, o polybar se cae al arrancar, usa safe.ini (barra mínima) y avisa.
pkill -x polybar 2>/dev/null
while pgrep -u "$UID" -x polybar >/dev/null; do sleep 0.2; done

HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
export MONORICE_DIR="$(cd "$HERE/../.." && pwd)"
PS=/sys/class/power_supply
export POLYBAR_BAT="$(ls $PS 2>/dev/null | grep -m1 '^BAT' || echo BAT0)"
export POLYBAR_AC="$(ls $PS 2>/dev/null | grep -m1 -E '^(AC|ACAD|ADP)' || echo AC)"

if pgrep -x i3 >/dev/null; then
  BAR=i3
else
  BAR=main
  # en XFCE polybar reemplaza al panel original: cerrarlo en cuanto aparezca (hasta 20 s)
  ( for _ in $(seq 1 100); do
      if pgrep -x xfce4-panel >/dev/null; then xfce4-panel -q; break; fi
      sleep 0.2
    done ) >/dev/null 2>&1 &
fi

# aspecto de la barra: `mono-bar pills|glass|solid` (por defecto glass). Ver scripts/bar.sh
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/mono-rice"
MODE="$(cat "$CONF/bar-mode" 2>/dev/null)"
case "$MODE" in
  pills) export POLYBAR_BG="#00000000" POLYBAR_PILL="#b8000000" POLYBAR_BORDER="#00000000" ;;
  solid) export POLYBAR_BG="#cc000000" POLYBAR_PILL="#00000000" POLYBAR_BORDER="#55fafafa" ;;
  *)     export POLYBAR_BG="#66000000" POLYBAR_PILL="#00000000" POLYBAR_BORDER="#33ffffff" ;;   # glass (por defecto): franja de cristal con desenfoque de picom
esac
CFG="$HERE/config.ini"
if command -v python3 >/dev/null && ! python3 -I "$MONORICE_DIR/scripts/polybar-check.py" "$CFG" >/tmp/polybar-check.log 2>&1; then
  notify-send -u critical "Barra" "config.ini tiene errores; uso una barra mínima. Detalle en /tmp/polybar-check.log" 2>/dev/null
  CFG="$HERE/safe.ini"
fi

polybar -c "$CFG" "$BAR" >>/tmp/polybar.log 2>&1 &
PB=$!
# si polybar muere enseguida (error que el validador no vio), levantar la barra mínima
( sleep 2
  if ! kill -0 "$PB" 2>/dev/null && [ "$CFG" != "$HERE/safe.ini" ]; then
    notify-send -u critical "Barra" "polybar no arrancó con config.ini; uso una barra mínima. Mira /tmp/polybar.log" 2>/dev/null
    polybar -c "$HERE/safe.ini" "$BAR" >>/tmp/polybar.log 2>&1
  fi ) >/dev/null 2>&1 &
disown -a 2>/dev/null

# la barra queda siempre visible
( sleep 1; polybar-msg cmd show >/dev/null 2>&1 ) &
