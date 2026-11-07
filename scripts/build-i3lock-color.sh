#!/usr/bin/env bash
# Compila e instala i3lock-color (anillo + reloj) en /usr/local. No toca el i3lock de Debian.
# Código: https://github.com/Raymo111/i3lock-color  (se compila con tu permiso, una sola vez)
set -eu
export DEBIAN_FRONTEND=noninteractive
sudo -v
echo "==> Dependencias de compilación"
sudo apt-get install -y git autoconf automake gcc make pkg-config libpam0g-dev libcairo2-dev libfontconfig1-dev \
  libxcb-composite0-dev libev-dev libx11-xcb-dev libxcb-xkb-dev libxcb-xinerama0-dev libxcb-randr0-dev \
  libxcb-image0-dev libxcb-util-dev libxcb-xrm-dev libxkbcommon-dev libxkbcommon-x11-dev libjpeg-dev libxcb-xrm0

SRC="$(mktemp -d)"; trap 'rm -rf "$SRC"' EXIT
echo "==> Descargando código"
git clone --depth 1 --branch 2.13.c.5 https://github.com/Raymo111/i3lock-color.git "$SRC/i3lock-color" 2>/dev/null \
  || git clone --depth 1 https://github.com/Raymo111/i3lock-color.git "$SRC/i3lock-color"

echo "==> Compilando (1-3 minutos)"
cd "$SRC/i3lock-color"
autoreconf -fiv
mkdir -p build && cd build
../configure --prefix=/usr/local --sysconfdir=/etc --disable-sanitizers
make -j"$(nproc)"
sudo make install

hash -r
echo "==> Listo: $(command -v i3lock)"
i3lock --version 2>&1 | head -1
i3lock --help 2>&1 | grep -q -- '--clock' && echo "Soporta reloj y anillo: mono-lock ya lo usará." || echo "(aviso) i3lock no muestra --clock; el PATH puede estar usando /usr/bin/i3lock"
