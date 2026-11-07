#!/usr/bin/env bash
# Firefox ESR con perfil propio blanco y negro. No cambia tu navegador por defecto (ni toca Island).
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
command -v firefox-esr >/dev/null || { echo "(firefox-esr no instalado, omito el navegador)"; exit 0; }

P="$HOME/.mozilla/firefox-mono"
mkdir -p "$P/chrome"
cp "$REPO/browser/user.js" "$P/user.js"
cp "$REPO/browser/userChrome.css" "$REPO/browser/userContent.css" "$P/chrome/"

# extensiones (uBlock Origin y Dark Reader) por política del sistema
if [ -d /usr/lib/firefox-esr ]; then
  sudo mkdir -p /usr/lib/firefox-esr/distribution
  sudo cp "$REPO/browser/policies.json" /usr/lib/firefox-esr/distribution/policies.json
fi

# entrada en el menú de apps / rofi
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/firefox-mono.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Firefox (mono)
Exec=$REPO/scripts/browser.sh %u
Icon=firefox-esr
Categories=Network;WebBrowser;
EOF
echo "Navegador listo: Firefox (mono)"
