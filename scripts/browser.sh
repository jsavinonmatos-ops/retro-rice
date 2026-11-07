#!/usr/bin/env bash
# Abre Firefox con el perfil blanco y negro (no toca el navegador por defecto del sistema)
exec firefox-esr -no-remote -profile "$HOME/.mozilla/firefox-mono" "$@"
