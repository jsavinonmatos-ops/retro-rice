#!/usr/bin/env bash
# Instalación en una sola línea en un Debian recién instalado:
#   sudo apt install -y git && git clone https://github.com/jsavinonmatos-ops/retro-rice.git ~/mono-rice && ~/mono-rice/install.sh
set -eu
sudo apt-get update -y && sudo apt-get install -y git
[ -d "$HOME/mono-rice" ] || git clone "${1:-https://github.com/jsavinonmatos-ops/retro-rice.git}" "$HOME/mono-rice"
exec "$HOME/mono-rice/install.sh"
