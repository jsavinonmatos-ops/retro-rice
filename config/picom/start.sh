#!/usr/bin/env bash
# Arranca picom. Con el argumento "anim" (sesión i3) añade animaciones de ventanas;
# si esa config falla (picom viejo), cae a la base sin animaciones.
D="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
pkill -x picom 2>/dev/null; sleep 0.3
if [ "${1:-}" = "anim" ]; then
  cat "$D/picom.conf" "$D/animations.conf" > /tmp/picom-full.conf
  nohup picom --config /tmp/picom-full.conf >/tmp/picom.log 2>&1 &
  PID=$!
  sleep 2
  if ! kill -0 "$PID" 2>/dev/null; then
    echo "picom con animaciones falló, uso la config base" >>/tmp/picom.log
    nohup picom --config "$D/picom.conf" >>/tmp/picom.log 2>&1 &
  fi
else
  nohup picom --config "$D/picom.conf" >/tmp/picom.log 2>&1 &
fi
