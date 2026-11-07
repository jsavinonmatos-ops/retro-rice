#!/usr/bin/env bash
# Oculta polybar cuando el mouse se aleja del borde superior y la muestra al tocar el borde.
# Super+B (mono-bar) activa/desactiva este comportamiento.
command -v xdotool >/dev/null || exit 0
OFF="$HOME/.cache/mono-bar-autohide-off"
hidden=0; away=0
sleep 5
while pgrep -x polybar >/dev/null; do
  if [ -f "$OFF" ]; then
    [ "$hidden" = 1 ] && polybar-msg cmd show >/dev/null 2>&1 && hidden=0
    away=0; sleep 0.5; continue
  fi
  y="$(xdotool getmouselocation --shell 2>/dev/null | awk -F= '/^Y=/ {print $2}')"
  y="${y:-500}"
  if [ "$y" -le 1 ]; then
    away=0
    if [ "$hidden" = 1 ]; then polybar-msg cmd show >/dev/null 2>&1; hidden=0; fi
  elif [ "$y" -gt 70 ]; then
    away=$((away + 1))
    if [ "$hidden" = 0 ] && [ "$away" -ge 7 ]; then polybar-msg cmd hide >/dev/null 2>&1; hidden=1; fi
  else
    away=0
  fi
  sleep 0.15
done
