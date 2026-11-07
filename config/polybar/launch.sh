#!/usr/bin/env bash
# Reinicia polybar y autodetecta batería y adaptador (Acer usa BAT1/ACAD, otros BAT0/AC)
killall -q polybar
while pgrep -u "$UID" -x polybar >/dev/null; do sleep 0.2; done

export MONORICE_DIR="$(cd "$(dirname "$(readlink -f "$0")")/../.." && pwd)"
PS=/sys/class/power_supply
export POLYBAR_BAT="$(ls $PS 2>/dev/null | grep -m1 '^BAT' || echo BAT0)"
export POLYBAR_AC="$(ls $PS 2>/dev/null | grep -m1 -E '^(AC|ACAD|ADP)' || echo AC)"

# polybar reemplaza al panel de XFCE: se cierra al iniciar sesión (para recuperarlo: xfce4-panel &)
# cerrar el panel viejo en cuanto aparezca (hasta 20 s), sin esperar fijo
( for _ in $(seq 1 100); do
    if pgrep -x xfce4-panel >/dev/null; then xfce4-panel -q; break; fi
    sleep 0.2
  done ) >/dev/null 2>&1 &

polybar main 2>&1 | tee -a /tmp/polybar.log & disown

# autohide animado: aparece al llevar el mouse arriba
pkill -f polybar/autohide.sh 2>/dev/null
"$(dirname "$(readlink -f "$0")")/autohide.sh" >/dev/null 2>&1 & disown
