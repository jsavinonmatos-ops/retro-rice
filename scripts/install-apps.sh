#!/usr/bin/env bash
# Instala apps libres para reemplazar las de siempre.
# Uso: install-apps.sh                      (todo)
#      install-apps.sh office dev media     (solo esas categorías: office dev media graphics tools notas games)
# Ocupa varios GB y tarda: es normal. Si una app no está disponible, avisa y sigue.
set -u
export DEBIAN_FRONTEND=noninteractive
REPO="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
sudo -v

ln -sfn "$REPO/home/.xprofile" "$HOME/.xprofile"

inst() {
  local ok=() miss=() p cand
  for p in "$@"; do
    cand="$(apt-cache policy "$p" 2>/dev/null | awk '/Candidate:/ {print $2}')"
    if [ -n "$cand" ] && [ "$cand" != "(none)" ]; then ok+=("$p"); else miss+=("$p"); fi
  done
  [ ${#ok[@]} -gt 0 ] && { sudo apt-get install -y "${ok[@]}" || echo "   (algún paquete falló, continúo)"; }
  [ ${#miss[@]} -gt 0 ] && echo "   (no disponibles en tu Debian: ${miss[*]})"
  return 0
}
fp() {
  if flatpak install --user -y --noninteractive flathub "$@" >>/tmp/mono-apps.log 2>&1; then
    echo "   ok $*"
  else
    echo "   FALLÓ $*  -> motivo:"; tail -3 /tmp/mono-apps.log | sed 's/^/        /'
  fi
}

sudo apt-get update -y
echo "==> Base: Flatpak (para las apps que Debian no trae) y soporte de tema en Qt"
inst flatpak qt5-gtk-platformtheme qt6-gtk-platformtheme adwaita-qt
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null
fp org.gtk.Gtk3theme.Arc-Dark
flatpak override --user --env=GTK_THEME=Arc-Dark 2>/dev/null

office() {
  echo "==> Oficina: LibreOffice (Word/Excel/PowerPoint), PDF, correo, claves"
  inst libreoffice-writer libreoffice-calc libreoffice-impress libreoffice-draw libreoffice-gtk3 \
       libreoffice-l10n-es hunspell-es evince thunderbird keepassxc
  fp net.cozic.joplin_desktop
  bash "$REPO/scripts/install-zoom.sh" || echo "   (no pude instalar Zoom; prueba después: mono-zoom)"
}
dev() {
  echo "==> Desarrollo: editor, git, lenguajes, bases de datos, APIs"
  inst neovim git gh lazygit build-essential python3-pip python3-venv nodejs npm default-jdk maven jq shellcheck
  fp com.vscodium.codium io.dbeaver.DBeaverCommunity com.usebruno.Bruno
}
media() {
  echo "==> Música y video"
  inst strawberry mpv vlc ffmpeg yt-dlp playerctl audacity obs-studio kdenlive
  fp com.github.KRTirtho.Spotube
}
graphics() {
  echo "==> Gráficos: GIMP, Inkscape, Krita, capturas"
  inst gimp inkscape krita flameshot
}
tools() {
  echo "==> Utilidades"
  inst btop qbittorrent file-roller p7zip-full galculator gparted telegram-desktop chromium fastfetch
  fp com.discordapp.Discord
}
notas() {
  echo "==> Notas y proyectos (software libre): Logseq (notas enlazadas, tareas y pizarrones)"
  fp com.logseq.Logseq
}
games() {
  echo "==> Juegos: clientes de GOG (Heroic y Minigalaxy)"
  inst gamemode mangohud
  fp com.heroicgameslauncher.hgl io.github.sharkwouter.Minigalaxy
}

CATS=("$@"); [ ${#CATS[@]} -eq 0 ] && CATS=(office dev media graphics tools notas games)
for c in "${CATS[@]}"; do
  if declare -F "$c" >/dev/null && [ "$c" != inst ] && [ "$c" != fp ]; then "$c"; else echo "categoría desconocida: $c"; fi
done

cat <<'TXT'

Listo. Reemplazos:
  Word / Excel / PowerPoint  -> LibreOffice Writer / Calc / Impress
  Visual Studio Code         -> VSCodium (mismo editor, sin telemetría) y Neovim
  Visual Studio / IntelliJ   -> sin equivalente exacto; usa VSCodium + extensiones, o JDK + Maven desde la terminal
  Postman                    -> Bruno
  Spotify                    -> Spotube (usa tu cuenta) y Strawberry (música local)
  Photoshop / Illustrator    -> GIMP / Inkscape (Krita para dibujo)
  Premiere / OBS             -> Kdenlive / OBS Studio
  Outlook                    -> Thunderbird
  Acrobat                    -> Evince
  Notion / Evernote          -> Joplin (notas) o Logseq (notas enlazadas, tareas y pizarrones)
  1Password / LastPass       -> KeePassXC
  DBeaver / Workbench        -> DBeaver Community
No tienen versión para Linux: Power BI Desktop, Teams y Zoom de escritorio (úsalos desde el navegador).
Cierra sesión y entra de nuevo para que el tema y las apps Flatpak aparezcan en rofi (Super+Espacio).
TXT
