#!/usr/bin/env bash
# Instala el cliente oficial de Zoom (software propietario) desde zoom.us. Para actualizar: vuelve a ejecutarlo.
set -eu
D="$(mktemp -d)"; trap 'rm -rf "$D"' EXIT
echo "==> Descargando Zoom desde zoom.us"
curl -fL --max-time 900 -o "$D/zoom_amd64.deb" https://zoom.us/client/latest/zoom_amd64.deb
[ "$(dpkg-deb -f "$D/zoom_amd64.deb" Package 2>/dev/null)" = "zoom" ] || { echo "El archivo descargado no es el paquete de Zoom. No instalo nada."; exit 1; }
echo "==> Instalando (te pedirá tu contraseña de sudo)"
sudo apt-get install -y "$D/zoom_amd64.deb"
echo "Listo: busca 'Zoom' con Super+Espacio."
