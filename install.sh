#!/usr/bin/env bash
# mono-rice · instalador desatendido para Debian + XFCE
# Pensado para Acer Aspire 3 15 (Ryzen serie 7000, iGPU AMD, pantalla touch)
# Uso: ./install.sh      (solo pide tu contraseña de sudo una vez)
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
sudo apt-get install -y picom polybar rofi kitty dunst feh imagemagick jq curl unzip git \
  fonts-inter arc-theme papirus-icon-theme
# opcionales: hardware, touch, extras
inst pulseaudio-utils libnotify-bin brightnessctl \
  firmware-amd-graphics firmware-realtek firmware-mediatek firmware-atheros \
  mesa-vulkan-drivers libgl1-mesa-dri xserver-xorg-input-libinput \
  touchegg onboard starship x11-xserver-utils \
  numlockx xdotool zsh zsh-autosuggestions zsh-syntax-highlighting fastfetch eza bat fzf firefox-esr

echo "==> Tiling: sesión i3 (aparte de XFCE)"
inst i3-wm i3lock xss-lock playerctl lxpolkit network-manager-gnome pavucontrol

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
sudo ln -sf "$REPO/scripts/slim-down.sh"    /usr/local/bin/mono-slim
sudo rm -f /usr/local/bin/mono-bar   # autohide eliminado

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
"$REPO/scripts/setup-browser.sh" || true

xfconf-query -c keyboards -p /Default/Numlock --create -t bool -s true 2>/dev/null || true

echo "==> Ajustes de XFCE"
"$REPO/scripts/xfce-settings.sh"

echo "==> Wallpapers (anime: 48 a color + 24 en blanco y negro, tarda unos minutos)"
"$REPO/scripts/fallback-wall.sh"
"$REPO/scripts/fetch-wallpapers.sh" 48 --fresh
"$REPO/scripts/fetch-wallpapers.sh" 24 --mono --fresh
"$REPO/scripts/fetch-wallpapers.sh" 9 --login --fresh || echo "(sin internet o wallhaven caído, uso el fondo de reemplazo)"
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
echo "Listo. El touchpad/touchegg se activan por completo en el próximo reinicio."
echo "Reinicia cuando puedas:  sudo reboot"
