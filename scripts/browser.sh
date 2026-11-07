#!/usr/bin/env bash
# Abre Firefox con el perfil blanco y negro (no toca el navegador por defecto del sistema)
# Errores en /tmp/browser.log
BIN="$(command -v firefox-esr || command -v firefox || true)"
if [ -z "$BIN" ]; then
  echo "$(date +%T) Firefox no está instalado" >>/tmp/browser.log
  notify-send "Navegador" "Firefox no está instalado. Corre: sudo apt install firefox-esr" 2>/dev/null
  exit 1
fi
mkdir -p "$HOME/.mozilla/firefox-mono"
exec "$BIN" -no-remote -profile "$HOME/.mozilla/firefox-mono" "$@" >>/tmp/browser.log 2>&1
