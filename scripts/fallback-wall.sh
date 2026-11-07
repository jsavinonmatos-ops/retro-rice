#!/usr/bin/env bash
# Genera un fondo blanco y negro suave por si aún no tienes wallpapers
set -eu
DIR="$HOME/Pictures/wallpapers"; mkdir -p "$DIR"
convert -size 2560x1440 radial-gradient:'#3a3a3a-#000000' \
  \( +clone -attenuate 0.25 +noise Gaussian -colorspace Gray \) -compose overlay -composite \
  "$DIR/00-mono-fallback.png"
echo "Creado $DIR/00-mono-fallback.png"
