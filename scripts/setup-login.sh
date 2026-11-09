#!/usr/bin/env bash
# Pantalla de login (LightDM) en blanco y negro, con lista de usuarios y fondo distinto en cada arranque.
# Uso: setup-login.sh [imagen]    (con imagen: usa solo esa)
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

# --- fondos: login/ primero, luego mono/, al final cualquiera; todos pasan a blanco y negro ---
W="$HOME/Pictures/wallpapers"
pick() { find "$1" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | shuf -n"$2"; }
if [ -n "${1:-}" ] && [ -f "$1" ]; then
  LIST="$1"
else
  LIST="$(pick "$W/login" 8)"
  [ -z "$LIST" ] && LIST="$(pick "$W/mono" 8)"
  [ -z "$LIST" ] && LIST="$(pick "$W" 8)"
fi

BGDIR=/usr/share/backgrounds/monorice-login
sudo mkdir -p "$BGDIR"
sudo rm -f "$BGDIR"/* /usr/share/backgrounds/monorice-login.* 2>/dev/null
i=0
while read -r img; do
  [ -f "$img" ] || continue
  i=$((i + 1))
  t="$(mktemp --suffix=.jpg)"
  convert "$img" -colorspace Gray -brightness-contrast -12x8 -quality 92 "$t"
  sudo cp "$t" "$BGDIR/$(printf '%02d' "$i").jpg"; rm -f "$t"
done <<< "$LIST"
sudo chmod -R a+rX "$BGDIR"
echo "Fondos de login instalados: $i"

# en cada arranque del login se elige uno distinto (script de root de LightDM) + numlock
sudo tee /usr/local/sbin/monorice-greeter-setup >/dev/null <<'EOS'
#!/bin/sh
/usr/bin/numlockx on 2>/dev/null
f="$(ls /usr/share/backgrounds/monorice-login/*.jpg 2>/dev/null | shuf -n1)"
[ -n "$f" ] && ln -sf "$f" /usr/share/backgrounds/monorice-login.jpg
exit 0
EOS
sudo chmod 755 /usr/local/sbin/monorice-greeter-setup
sudo /usr/local/sbin/monorice-greeter-setup

# --- tema propio del greeter (hereda Arc-Dark y quita su azul) ---
sudo mkdir -p /usr/share/themes/MonoRice-Login/gtk-3.0
printf '[Desktop Entry]\nType=X-GNOME-Metatheme\nName=MonoRice-Login\n\n[X-GNOME-Metatheme]\nGtkTheme=MonoRice-Login\n' \
  | sudo tee /usr/share/themes/MonoRice-Login/index.theme >/dev/null
sudo cp "$REPO/login/gtk.css" /usr/share/themes/MonoRice-Login/gtk-3.0/gtk.css

sudo tee /etc/lightdm/lightdm-gtk-greeter.conf >/dev/null <<EOT
[greeter]
background=/usr/share/backgrounds/monorice-login.jpg
theme-name=MonoRice-Login
icon-theme-name=Papirus-Dark
font-name=Inter 11
xft-antialias=true
xft-dpi=120
xft-hintstyle=hintslight
xft-rgba=rgb
indicators=~spacer;~clock;~spacer;~session;~power
clock-format=%H:%M   %A %d %B
position=50%,center
user-background=false
EOT

# lista de usuarios (queda seleccionado el último) en vez de escribir el nombre
sudo mkdir -p /etc/lightdm/lightdm.conf.d
printf '[Seat:*]\ngreeter-hide-users=false\ngreeter-show-manual-login=false\nuser-session=i3\ngreeter-setup-script=/usr/local/sbin/monorice-greeter-setup\n' \
  | sudo tee /etc/lightdm/lightdm.conf.d/50-monorice.conf >/dev/null

sudo mkdir -p /var/lib/lightdm/.cache/lightdm-gtk-greeter
sudo chown -R lightdm:lightdm /var/lib/lightdm/.cache 2>/dev/null || true

# --- comprobación: el fondo activo debe tener saturación ~0 ---
SAT="$(convert /usr/share/backgrounds/monorice-login.jpg -colorspace HSL -channel G -separate +channel -format '%[fx:mean]' info: 2>/dev/null || echo '?')"
echo "Fondo activo: $(readlink -f /usr/share/backgrounds/monorice-login.jpg) (saturación: $SAT, debe ser ~0)"
echo "Pantalla de login lista (se ve al cerrar sesión o reiniciar)."
