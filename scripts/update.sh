#!/usr/bin/env bash
# mono-update: actualiza el sistema con red de seguridad (instantánea antes, avisos claros, limpieza después).
# Úsalo una vez por semana. Lee siempre si apt dice que va a ELIMINAR algo antes de aceptar.
set -u
REPO="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
say() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
ask() { read -rp "$1 [s/N] " r; [[ "$r" =~ ^[sSyY] ]]; }

say "1/5 Instantánea (para poder volver atrás si algo sale mal)"
if command -v timeshift >/dev/null; then
  sudo timeshift --create --comments "antes de mono-update" --tags O || { echo "(no pude crear la instantánea)"; ask "¿Continuar de todas formas?" || exit 0; }
else
  echo "Timeshift no está instalado (recomendado):  sudo apt install timeshift"
  ask "¿Continuar sin instantánea?" || exit 0
fi

say "2/5 Buscando actualizaciones"
sudo apt-get update
apt list --upgradable 2>/dev/null | tail -n +2 | head -40

say "3/5 Actualizando (mira si dice 'serán ELIMINADOS' y lee la lista antes de aceptar)"
sudo apt-get full-upgrade

say "4/5 Apps Flatpak"
command -v flatpak >/dev/null && flatpak update --user -y || echo "(sin Flatpak)"

say "5/5 Tu configuración (retro-rice)"
if [ -d "$REPO/.git" ]; then
  before="$(git -C "$REPO" rev-parse HEAD)"
  git -C "$REPO" pull --ff-only 2>&1 | tail -2
  [ "$before" != "$(git -C "$REPO" rev-parse HEAD)" ] && echo "Hay cambios nuevos: corre  bash $REPO/install.sh  para aplicarlos."
fi

say "Limpieza"
ask "¿Quitar paquetes que ya no se usan (autoremove)?" && sudo apt-get autoremove
sudo apt-get clean

latest="$(ls /boot/vmlinuz-* 2>/dev/null | sed 's#/boot/vmlinuz-##' | sort -V | tail -1)"
if [ -n "$latest" ] && [ "$latest" != "$(uname -r)" ]; then
  printf '\n\033[33mHay un kernel nuevo (%s). Reinicia cuando puedas para usarlo.\033[0m\n' "$latest"
fi
echo; echo "Listo."
