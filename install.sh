#!/usr/bin/env bash
# retro-rice (mono-rice) · instalador desatendido para Debian 13 con X11
# Pensado para Acer Aspire 3 15 (Ryzen serie 7000, iGPU AMD, pantalla táctil)
# Uso: bash install.sh      (como usuario normal, NO como root; pide tu contraseña de sudo una vez)
# Es seguro repetirlo: reaplica la configuración y guarda copias de lo que reemplaza. No vuelve a bajar wallpapers que ya tienes (WALLPAPERS=1 los renueva).
set -eu
export DEBIAN_FRONTEND=noninteractive
REPO="$(cd "$(dirname "$0")" && pwd)"
CFG="$HOME/.config"
BACKUP="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

sudo -v
# mantener sudo vivo mientras corre el script
( while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) 2>/dev/null &

echo "==> Reparando repos de terceros (island, etc.) si una versión anterior los tocó"
for b in /etc/apt/sources.list /etc/apt/sources.list.d/*.sources; do
  [ -f "$b.bak-monorice" ] || continue
  if ! grep -qE 'deb\.debian\.org|security\.debian\.org|ftp\.[a-z.]*debian\.org' "$b.bak-monorice"; then
    sudo cp "$b.bak-monorice" "$b" && sudo rm -f "$b.bak-monorice"
    echo "   restaurado: $b"
  fi
done

echo "==> Hora: zona de República Dominicana y sincronización automática"
sudo timedatectl set-timezone America/Santo_Domingo 2>/dev/null || true
sudo timedatectl set-ntp true 2>/dev/null || true

echo "==> Repos non-free-firmware (drivers AMD / WiFi)"
for f in /etc/apt/sources.list /etc/apt/sources.list.d/*.sources; do
  [ -f "$f" ] || continue
  # solo repos oficiales de Debian, nunca repos de terceros
  grep -qE 'deb\.debian\.org|security\.debian\.org|ftp\.[a-z.]*debian\.org' "$f" || continue
  if ! grep -q "non-free-firmware" "$f"; then
    sudo cp "$f" "$f.bak-monorice"
    case "$f" in
      *.sources) sudo sed -i '/^Components:/ s/$/ non-free-firmware/' "$f" ;;
      *)         sudo sed -i '/^deb .* main/ s/$/ non-free-firmware/' "$f" ;;
    esac
  fi
done
sudo apt-get update -y

echo "==> Paquetes"
# instala solo los paquetes que existan en tu versión de Debian; avisa de los que no
inst() {
  local ok=() miss=() p cand
  for p in "$@"; do
    cand="$(apt-cache policy "$p" 2>/dev/null | awk '/Candidate:/ {print $2}')"
    if [ -n "$cand" ] && [ "$cand" != "(none)" ]; then ok+=("$p"); else miss+=("$p"); fi
  done
  if [ ${#ok[@]} -gt 0 ]; then
    sudo apt-get install -y "${ok[@]}" || echo "   (algún paquete opcional falló, continúo)"
  fi
  [ ${#miss[@]} -gt 0 ] && echo "   (no disponibles en tu Debian, se omiten: ${miss[*]})"
  return 0
}
# esenciales: si uno falla, se aborta
sudo apt-get install -y picom polybar rofi kitty dunst feh imagemagick jq curl unzip git python3 \
  fonts-inter arc-theme papirus-icon-theme
# opcionales: hardware, touch, extras
inst pulseaudio-utils libnotify-bin brightnessctl \
  firmware-amd-graphics firmware-realtek firmware-mediatek firmware-atheros \
  mesa-vulkan-drivers libgl1-mesa-dri xserver-xorg-input-libinput \
  touchegg onboard starship x11-xserver-utils \
  numlockx xdotool zsh zsh-autosuggestions zsh-syntax-highlighting fastfetch eza bat fzf firefox-esr

echo "==> Base gráfica y piezas que usa el rice (ajustes, archivos, capturas, energía, login)"
inst polkitd pkexec lxpolkit xserver-xorg xfce4-settings xfconf thunar thunar-volman gvfs xfce4-screenshooter xfce4-power-manager \
     lightdm lightdm-gtk-greeter accountsservice

echo "==> Tiling: sesión i3 (aparte de XFCE)"
inst i3-wm i3lock xss-lock playerctl lxpolkit network-manager-gnome pavucontrol
inst i3lock-color   # versión con reloj y anillo; si no existe en tu Debian se usa i3lock normal
inst chafa fastfetch   # foto anime en arte de terminal
inst xclip gammastep bluez network-manager   # portapapeles, luz nocturna, Bluetooth y WiFi

echo "==> Touchpad (tap-to-click, scroll natural) y touchscreen"
sudo mkdir -p /etc/X11/xorg.conf.d
sudo tee /etc/X11/xorg.conf.d/40-libinput-touchpad.conf >/dev/null <<'EOF'
Section "InputClass"
    Identifier "libinput touchpad mono-rice"
    MatchIsTouchpad "on"
    MatchDriver "libinput"
    Option "Tapping" "on"
    Option "NaturalScrolling" "on"
    Option "DisableWhileTyping" "on"
    Option "ClickMethod" "clickfinger"
EndSection
EOF
if systemctl list-unit-files 2>/dev/null | grep -q '^touchegg'; then
  sudo systemctl enable --now touchegg.service 2>/dev/null || true
fi

echo "==> Pantalla táctil: scroll con el dedo en Firefox/Chromium y puntero que se oculta"
inst unclutter-xfixes xinput
sudo mkdir -p /etc/chromium.d
echo 'export CHROMIUM_FLAGS="$CHROMIUM_FLAGS --touch-events=enabled --disable-features=OverscrollHistoryNavigation"' | sudo tee /etc/chromium.d/mono-touch >/dev/null

echo "==> Fuente JetBrainsMono Nerd Font"
if ! fc-list | grep -qi "JetBrainsMono Nerd"; then
  tmp="$(mktemp -d)"
  curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip -o "$tmp/jb.zip"
  mkdir -p "$HOME/.local/share/fonts/JetBrainsMonoNF"
  unzip -oq "$tmp/jb.zip" -d "$HOME/.local/share/fonts/JetBrainsMonoNF"
  fc-cache -f
  rm -rf "$tmp"
fi

echo "==> Enlazando configs (backup en $BACKUP si ya existían)"
mkdir -p "$CFG" "$BACKUP"
for d in "$REPO"/config/*; do
  d="${d%/}"
  name="$(basename "$d")"
  if [ -e "$CFG/$name" ] && [ ! -L "$CFG/$name" ]; then mv "$CFG/$name" "$BACKUP/"; fi
  ln -sfn "$d" "$CFG/$name"
done
chmod +x "$REPO"/config/polybar/launch.sh "$REPO"/scripts/*.sh

echo "==> Comandos globales (mono-browser, mono-wall, mono-accent, mono-avatar)"
sudo ln -sf "$REPO/scripts/browser.sh"      /usr/local/bin/mono-browser
sudo ln -sf "$REPO/scripts/setwall.sh"      /usr/local/bin/mono-wall
sudo ln -sf "$REPO/scripts/accent.sh"       /usr/local/bin/mono-accent
sudo ln -sf "$REPO/scripts/setup-avatar.sh" /usr/local/bin/mono-avatar
sudo ln -sf "$REPO/scripts/scale.sh"        /usr/local/bin/mono-scale
sudo ln -sf "$REPO/scripts/session-dpi.sh"  /usr/local/bin/mono-session-dpi
sudo ln -sf "$REPO/scripts/install-apps.sh" /usr/local/bin/mono-apps
sudo ln -sf "$REPO/scripts/lock.sh"         /usr/local/bin/mono-lock
sudo ln -sf "$REPO/scripts/touch.sh"        /usr/local/bin/mono-touch
sudo ln -sf "$REPO/scripts/update.sh"       /usr/local/bin/mono-update
sudo ln -sf "$REPO/scripts/guide.sh"        /usr/local/bin/mono-guia
sudo ln -sf "$REPO/scripts/secure.sh"       /usr/local/bin/mono-secure
sudo ln -sf "$REPO/scripts/power.sh"        /usr/local/bin/mono-power
sudo ln -sf "$REPO/scripts/pic.sh"          /usr/local/bin/mono-pic
sudo ln -sf "$REPO/scripts/ai.py"           /usr/local/bin/mono-ai
sudo ln -sf "$REPO/scripts/setup-ai.sh"     /usr/local/bin/mono-ai-setup
sudo ln -sf "$REPO/scripts/lock-diag.sh"    /usr/local/bin/mono-lock-diag
sudo ln -sf "$REPO/scripts/install-zoom.sh" /usr/local/bin/mono-zoom
sudo ln -sf "$REPO/scripts/slim-down.sh"    /usr/local/bin/mono-slim
for n in clip wifi bluetooth cal ask music; do sudo ln -sf "$REPO/scripts/menus.py" "/usr/local/bin/mono-$n"; done
sudo ln -sf "$REPO/scripts/pet.sh"          /usr/local/bin/mono-pet
sudo ln -sf "$REPO/scripts/battery.sh"      /usr/local/bin/mono-battery
sudo ln -sf "$REPO/scripts/night.sh"        /usr/local/bin/mono-night
sudo ln -sf "$REPO/scripts/wallcycle.sh"    /usr/local/bin/mono-wall-auto
sudo ln -sf "$REPO/scripts/hibernate.py"    /usr/local/bin/mono-hibernate
sudo ln -sf "$REPO/scripts/boot.py"         /usr/local/bin/mono-boot
sudo ln -sf "$REPO/scripts/bar.sh"         /usr/local/bin/mono-bar

echo "==> Validando la configuración de la barra"
python3 -I "$REPO/scripts/polybar-check.py" "$CFG/polybar/config.ini" || echo "   (aviso) la barra usará una versión mínima hasta que se corrija; detalle arriba"

if command -v i3 >/dev/null; then
  echo "==> Validando la configuración de i3"
  if i3 -C -c "$CFG/i3/config" >/tmp/i3-check.log 2>&1; then echo "   config de i3 OK"; else echo "   (aviso) la config de i3 tiene errores, mira /tmp/i3-check.log"; fi
fi

echo "==> Autostart (picom, polybar, dunst)"
mkdir -p "$CFG/autostart"
mk() { printf '[Desktop Entry]\nType=Application\nName=%s\nExec=%s\nX-GNOME-Autostart-enabled=true\n' "$1" "$2" > "$CFG/autostart/$1.desktop"; }
mk picom   "$CFG/picom/start.sh"
mk polybar "$CFG/polybar/launch.sh"
mk dunst   "dunst"
mk numlock  "numlockx on"
mk mono-dpi "mono-session-dpi"
# evita que el panel original de XFCE arranque junto a polybar
printf '[Desktop Entry]\nType=Application\nName=xfce4-panel\nExec=xfce4-panel\nHidden=true\n' > "$CFG/autostart/xfce4-panel.desktop"

echo "==> Atajos: los maneja i3 (Super+F1 muestra la guía); quito los de XFCE para que no choquen"
for k in "<Super>space" "<Super>Return" "<Super>k" "<Super>w" "<Super>b"; do
  xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/$k" -r 2>/dev/null || true
done
xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/override -r 2>/dev/null || true
pkill xfsettingsd 2>/dev/null; sleep 0.5; (nohup xfsettingsd >/dev/null 2>&1 &) 2>/dev/null || true

echo "==> Terminal (zsh + starship), navegador y pantalla de login"
"$REPO/scripts/setup-shell.sh" || true
"$REPO/scripts/setup-session.sh" || true
# pixel art por defecto; si la imagen anterior era una foto convertida (sin marca pic.name), se reemplaza
[ -f "$HOME/.config/mono-rice/pic.name" ] || "$REPO/scripts/pic.sh" sakura >/dev/null 2>&1 || true
"$REPO/scripts/setup-browser.sh" || true

xfconf-query -c keyboards -p /Default/Numlock --create -t bool -s true 2>/dev/null || true

echo "==> Ajustes de XFCE"
"$REPO/scripts/xfce-settings.sh"

echo "==> Wallpapers (anime: 48 a color + 24 en blanco y negro + 9 del login)"
"$REPO/scripts/fallback-wall.sh"
# Si ya tienes casi todos, NO se vuelven a descargar (eran ~80 imágenes en cada ejecución). Para renovarlos: WALLPAPERS=1 bash install.sh
# Si wallhaven falla o no hay internet, se sigue con el fondo de reemplazo (se puede repetir después).
WALLDIR="$HOME/Pictures/wallpapers"
enough() { [ "${WALLPAPERS:-0}" != 1 ] && [ "$(ls "$1" 2>/dev/null | grep -c -i -E '\.(jpe?g|png|webp)$')" -ge "$2" ]; }
if enough "$WALLDIR" 36; then echo "   ya tienes wallpapers a color: no se descargan de nuevo"
else "$REPO/scripts/fetch-wallpapers.sh" 48 --fresh || echo "   (no se descargaron wallpapers a color; repite: scripts/fetch-wallpapers.sh 48)"; fi
if enough "$WALLDIR/mono" 18; then echo "   ya tienes wallpapers en blanco y negro: no se descargan de nuevo"
else "$REPO/scripts/fetch-wallpapers.sh" 24 --mono --fresh || echo "   (no se descargaron los de blanco y negro)"; fi
if enough "$WALLDIR/login" 6; then echo "   ya tienes los del login: no se descargan de nuevo"
else "$REPO/scripts/fetch-wallpapers.sh" 9 --login --fresh || echo "   (no se descargaron los del login)"; fi
"$REPO/scripts/setwall.sh" || true

"$REPO/scripts/setup-avatar.sh" || true
"$REPO/scripts/setup-login.sh" || true

echo "==> Aplicando en vivo (sin cerrar sesión)"
pkill dunst 2>/dev/null || true
"$CFG/picom/start.sh" >/dev/null 2>&1 &
nohup dunst >/dev/null 2>&1 &
"$CFG/polybar/launch.sh" >/dev/null 2>&1 || true
pgrep -x xfce4-panel >/dev/null && xfce4-panel -q >/dev/null 2>&1 || true

echo
echo "Listo. Reinicia para activarlo todo (touchpad, login, kernel, sesión i3):  sudo reboot"
echo "Después, los pasos opcionales están en el README: mono-pic, mono-apps, mono-ai-setup, mono-secure..."
