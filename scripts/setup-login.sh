#!/usr/bin/env bash
# Pantalla de login (LightDM) en blanco y negro + lista de usuarios para no escribir el nombre cada vez
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
DM="$(cat /etc/X11/default-display-manager 2>/dev/null || true)"
if [ ! -x /usr/sbin/lightdm ] && ! dpkg -s lightdm >/dev/null 2>&1; then
  echo "(LightDM no está instalado; gestor de login actual: ${DM:-desconocido}). Omito la pantalla de login."
  exit 0
fi
case "$DM" in
  *lightdm*|"") ;;
  *) echo "(aviso: tu gestor de login por defecto es $DM, no LightDM; los cambios solo se ven si lo usas)" ;;
esac
sudo apt-get install -y lightdm-gtk-greeter >/dev/null 2>&1 || true

# fondo: un wallpaper de tu carpeta (o el de reemplazo)
SRC="$(find "$HOME/Pictures/wallpapers" -type f \( -iname '*.jpg' -o -iname '*.png' \) 2>/dev/null | shuf -n1)"
if [ -n "$SRC" ]; then
  EXT="${SRC##*.}"
  sudo mkdir -p /usr/share/backgrounds
  sudo cp "$SRC" "/usr/share/backgrounds/monorice-login.$EXT"
  sudo chmod 644 "/usr/share/backgrounds/monorice-login.$EXT"
  BG="/usr/share/backgrounds/monorice-login.$EXT"
else
  BG=""
fi

# tema propio del greeter (hereda Arc-Dark y lo oscurece)
sudo mkdir -p /usr/share/themes/MonoRice-Login/gtk-3.0
printf '[Desktop Entry]\nType=X-GNOME-Metatheme\nName=MonoRice-Login\n\n[X-GNOME-Metatheme]\nGtkTheme=MonoRice-Login\n' \
  | sudo tee /usr/share/themes/MonoRice-Login/index.theme >/dev/null
sudo cp "$REPO/login/gtk.css" /usr/share/themes/MonoRice-Login/gtk-3.0/gtk.css

sudo tee /etc/lightdm/lightdm-gtk-greeter.conf >/dev/null <<EOF
[greeter]
background=$BG
theme-name=MonoRice-Login
icon-theme-name=Papirus-Dark
font-name=Inter 11
xft-antialias=true
xft-hintstyle=hintslight
xft-rgba=rgb
indicators=~host;~spacer;~clock;~spacer;~session;~a11y;~power
clock-format=%a %d %b  %H:%M
position=50%,center
user-background=false
EOF

# mostrar la lista de usuarios (el último usuario queda seleccionado) en vez de pedir que lo escribas
sudo mkdir -p /etc/lightdm/lightdm.conf.d
printf '[Seat:*]\ngreeter-hide-users=false\ngreeter-show-manual-login=false\n' \
  | sudo tee /etc/lightdm/lightdm.conf.d/50-monorice.conf >/dev/null

# LightDM recuerda el último usuario en este caché; debe existir y ser suyo
sudo mkdir -p /var/lib/lightdm/.cache/lightdm-gtk-greeter
sudo chown -R lightdm:lightdm /var/lib/lightdm/.cache 2>/dev/null || true
echo "Pantalla de login lista (se ve en el próximo cierre de sesión o reinicio)."
