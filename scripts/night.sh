#!/usr/bin/env bash
# mono-night: luz nocturna (quita azul de la pantalla de noche) con gammastep.
# Uso: mono-night on | off | toggle | apply | status      (apply = respetar lo guardado; por defecto, encendida)
# Ubicación (para saber cuándo anochece): ~/.config/mono-rice/location, formato LAT:LON. Por defecto Santo Domingo.
set -u
DIR="$HOME/.config/mono-rice"; STATE="$DIR/night"; LOC_FILE="$DIR/location"
mkdir -p "$DIR"
LOC="$(cat "$LOC_FILE" 2>/dev/null || echo "18.47:-69.89")"
BIN="$(command -v gammastep || command -v redshift || true)"
cur="$(cat "$STATE" 2>/dev/null || echo on)"

start() {
  [ -n "$BIN" ] || { echo "Falta gammastep: sudo apt install gammastep"; return 1; }
  stop
  nohup "$BIN" -l "$LOC" -t 6500:3800 >/dev/null 2>&1 &
}
stop() { pkill -TERM -x gammastep 2>/dev/null; pkill -TERM -x redshift 2>/dev/null; return 0; }

case "${1:-status}" in
  on)     echo on  > "$STATE"; start && echo "Luz nocturna: activada (de noche baja a 3800 K)" ;;
  off)    echo off > "$STATE"; stop;  echo "Luz nocturna: desactivada" ;;
  toggle) if [ "$cur" = on ]; then "$0" off; else "$0" on; fi ;;
  apply)  [ "$cur" = on ] && start ;;
  status) echo "Estado: $cur   Ubicación: $LOC   Programa: ${BIN:-no instalado}" ;;
  *) echo "Uso: mono-night on|off|toggle|status"; exit 1 ;;
esac
