#!/usr/bin/env bash
# Quita el escritorio XFCE (panel, escritorio, gestor de ventanas, sesión) y deja solo i3.
# CONSERVA lo que i3 usa: ajustes, Thunar, capturas, energía y LightDM.
# Uso: slim-down.sh          -> solo muestra qué quitaría (no cambia nada)
#      slim-down.sh --yes    -> lo quita (pide escribir SI)
set -u
KEEP=(i3-wm xfce4-settings xfconf thunar thunar-volman gvfs xfce4-screenshooter xfce4-power-manager lightdm lightdm-gtk-greeter polybar rofi picom dunst kitty)
REMOVE=(xfce4-panel xfdesktop4 xfwm4 xfce4-session xfce4-whiskermenu-plugin xfce4-notifyd xfce4 task-xfce-desktop xfce4-goodies)

command -v i3 >/dev/null || { echo "i3 no está instalado: no quito nada."; exit 1; }
sudo apt-mark manual "${KEEP[@]}" >/dev/null 2>&1   # que autoremove nunca los toque

PKGS=()
for p in "${REMOVE[@]}"; do dpkg -s "$p" >/dev/null 2>&1 && PKGS+=("$p"); done
[ ${#PKGS[@]} -eq 0 ] && { echo "No queda nada de XFCE por quitar."; exit 0; }

SIM="$(apt-get -s remove "${PKGS[@]}" 2>/dev/null | awk '/^Remv/ {print $2}')"
echo "Se quitarían estos paquetes:"; echo "$SIM" | sed 's/^/  - /'

for k in "${KEEP[@]}"; do
  if grep -qx "$k" <<<"$SIM"; then
    echo; echo "ABORTO: quitar eso también quitaría '$k', que i3 necesita. No cambio nada."
    exit 1
  fi
done

if [ "${1:-}" != "--yes" ]; then
  echo; echo "Modo simulación: no se cambió nada. Para aplicarlo: slim-down.sh --yes"
  exit 0
fi
read -rp "Escribe SI para quitar XFCE (se puede reinstalar con: sudo apt install xfce4): " R
[ "$R" = "SI" ] || { echo "Cancelado."; exit 0; }

sudo apt-get remove -y "${PKGS[@]}"
AUTO="$(apt-get -s autoremove 2>/dev/null | awk '/^Remv/ {print $2}')"
for k in "${KEEP[@]}"; do grep -qx "$k" <<<"$AUTO" && { echo "autoremove tocaría '$k': lo omito."; exit 0; }; done
sudo apt-get autoremove -y
echo "Listo. En el login ya solo aparece i3."
