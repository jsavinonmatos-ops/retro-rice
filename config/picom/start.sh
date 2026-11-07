#!/usr/bin/env bash
# Arranca picom (blur, sombras, transparencias, fade). Sin animaciones de ventana.
D="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
pkill -x picom 2>/dev/null; sleep 0.3
nohup picom --config "$D/picom.conf" >/tmp/picom.log 2>&1 &
