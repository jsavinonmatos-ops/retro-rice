#!/usr/bin/env bash
# Activa/desactiva la pantalla táctil (el touchpad NO se toca).
# Uso: mono-touch on | off | toggle | status | apply     (apply = aplica lo guardado; por defecto: off)
set -u
STATE="$HOME/.cache/mono-touch"; mkdir -p "$HOME/.cache"
command -v xinput >/dev/null || { echo "Falta xinput: sudo apt install xinput"; exit 1; }

# la pantalla táctil es un dispositivo "absoluto" (tiene matriz de calibración); el touchpad no
ids() {
  local id p
  for id in $(xinput list --id-only 2>/dev/null); do
    p="$(xinput list-props "$id" 2>/dev/null)"
    echo "$p" | grep -qi 'Calibration Matrix' && ! echo "$p" | grep -qi 'Tapping Enabled' && echo "$id"
  done
}
set_state() {
  local v="$1" id
  for id in $(ids); do xinput "$([ "$v" = on ] && echo enable || echo disable)" "$id"; done
  echo "$v" > "$STATE"
}
cur="$(cat "$STATE" 2>/dev/null || echo off)"
case "${1:-status}" in
  on)     set_state on;  echo "Pantalla táctil: activada" ;;
  off)    set_state off; echo "Pantalla táctil: desactivada" ;;
  toggle) [ "$cur" = on ] && set_state off || set_state on; echo "Pantalla táctil: $(cat "$STATE")" ;;
  apply)  set_state "$cur" ;;
  status) echo "Estado guardado: $cur"; echo "Dispositivos táctiles detectados (id):"; ids | sed 's/^/  /' ;;
  *) echo "Uso: mono-touch on|off|toggle|status"; exit 1 ;;
esac
