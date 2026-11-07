#!/usr/bin/env bash
# Reinicia polybar. Elige la barra según la sesión (i3 o XFCE) y autodetecta batería y adaptador.
pkill -x polybar 2>/dev/null
while pgrep -u "$UID" -x polybar >/dev/null; do sleep 0.2; done

export MONORICE_DIR="$(cd "$(dirname "$(readlink -f "$0")")/../.." && pwd)"
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

polybar "$BAR" 2>&1 | tee -a /tmp/polybar.log & disown
