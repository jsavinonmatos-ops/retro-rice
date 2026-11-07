#!/usr/bin/env bash
# Activa/desactiva el autohide de la barra (Super+B)
OFF="$HOME/.cache/mono-bar-autohide-off"
mkdir -p "$HOME/.cache"
if [ -f "$OFF" ]; then rm -f "$OFF"; notify-send "Barra" "Autohide activado" 2>/dev/null
else touch "$OFF"; polybar-msg cmd show >/dev/null 2>&1; notify-send "Barra" "Siempre visible" 2>/dev/null; fi
