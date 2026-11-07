#!/usr/bin/env bash
# Evita que el panel original de XFCE arranque con la sesión (polybar lo reemplaza)
set -u
X() { xfconf-query -c xfce4-session "$@" 2>/dev/null; }

# no restaurar sesiones guardadas (ahí viaja el panel)
X -p /general/SaveOnExit --create -t bool -s false
rm -rf "$HOME"/.cache/sessions/* 2>/dev/null || true

# sesión "Failsafe": reemplazar el comando del panel por /bin/true
for p in $(X -l | grep -E '^/sessions/Failsafe/Client[0-9]+_Command$'); do
  if X -p "$p" | grep -q 'xfce4-panel'; then
    X -p "$p" -r
    X -p "$p" --create -a -t string -s true
    echo "Panel de XFCE quitado de la sesión ($p)"
  fi
done
