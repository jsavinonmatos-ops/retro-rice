#!/usr/bin/env bash
# Genera un fondo negro con brillo rosa por si aún no tienes wallpapers
set -eu
DIR="$HOME/Pictures/wallpapers"; mkdir -p "$DIR"
convert -size 2560x1440 radial-gradient:'#4a1226-#000000' \
  \( +clone -attenuate 0.2 +noise Gaussian -colorspace Gray \) -compose overlay -composite \
  "$DIR/00-mono-fallback.png"
echo "Creado $DIR/00-mono-fallback.png"
