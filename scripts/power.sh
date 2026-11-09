#!/usr/bin/env bash
# mono-power: menú de energía (Bloquear, Cerrar sesión, Suspender, Hibernar, Reiniciar, Apagar).
# Se abre con Super+Shift+P o con el botón de apagado de la barra.
set -u
LOGF=/tmp/mono-power.log
SUDOERS=/etc/sudoers.d/mono-power

case "${1:-}" in
  --diag)
    echo "== Sesión (debe decir Active=yes) =="
    loginctl show-session "${XDG_SESSION_ID:-self}" -p Id -p Type -p Active -p State -p Seat -p Remote 2>&1
    echo; echo "== ¿Qué permite el sistema sin pedir contraseña?  yes = sí | challenge = pediría contraseña | no = prohibido =="
    for a in poweroff reboot suspend hibernate; do printf '  %-10s %s\n' "$a" "$(systemctl can-$a 2>&1)"; done
    echo; echo "== Agente de polkit (el que muestra la ventana de contraseña) =="
    pgrep -a -f '(lx|xfce-|mate-)polkit|polkit-(gnome|kde)' || echo "  NINGUNO corriendo: si el sistema dice 'challenge', la acción fallará. Solución:  sudo apt install lxpolkit  y  mono-power --setup"
    echo; echo "== Programas que bloquean el apagado =="
    systemd-inhibit --list --no-pager 2>&1 | head -12
    echo; echo "== Apagado sin contraseña mediante sudo =="
    [ -f "$SUDOERS" ] && echo "  configurado ($SUDOERS)" || echo "  NO configurado (mono-power --setup lo configura)"
    echo; echo "== Últimos intentos ($LOGF) =="
    tail -8 "$LOGF" 2>/dev/null || echo "  (todavía no se ha intentado nada)"
    exit 0 ;;
  --setup)
    # Permite SOLO estos 4 comandos sin contraseña. Es un respaldo para cuando polkit no autoriza.
    sc="$(readlink -f "$(command -v systemctl)")"; tmp="$(mktemp)"
    printf '# retro-rice: apagar, reiniciar, suspender e hibernar sin contraseña (solo estos 4 comandos exactos)\n%s ALL=(root) NOPASSWD: %s poweroff, %s reboot, %s suspend, %s hibernate\n' \
      "$USER" "$sc" "$sc" "$sc" "$sc" > "$tmp"
    if sudo visudo -cf "$tmp" >/dev/null && sudo install -m 440 -o root -g root "$tmp" "$SUDOERS"; then
      rm -f "$tmp"; echo "Listo: $SUDOERS. Quitarlo cuando quieras:  mono-power --remove"; exit 0
    fi
    rm -f "$tmp"; echo "visudo rechazó el archivo o no se pudo instalar; no cambié nada."; exit 1 ;;
  --remove) sudo rm -f "$SUDOERS" && echo "Quitado."; exit 0 ;;
esac

THEME="$HOME/.config/rofi/power.rasi"
G="JetBrainsMono Nerd Font"

# [icono, etiqueta, ¿pide confirmación?]  (los iconos son glifos de Nerd Font)
GLYPHS=(     )
LABELS=("Bloquear" "Cerrar sesión" "Suspender" "Hibernar" "Reiniciar" "Apagar")
CONFIRM=(0 1 0 0 1 1)

can_hibernate="$(systemctl can-hibernate 2>/dev/null || echo no)"

entries=()
for i in "${!LABELS[@]}"; do
  label="${LABELS[$i]}"
  if [ "$i" = 3 ] && [ "$can_hibernate" != "yes" ]; then label="<span alpha='45%'>${label}</span>"; fi
  entries+=("<span font_family='$G' size='36000'>${GLYPHS[$i]}</span>"$'\n'"$label")
done

# -sep '|' permite entradas de dos líneas (icono arriba, texto abajo); -format i devuelve el número elegido
sel="$(printf '%s|' "${entries[@]}" | rofi -dmenu -sep '|' -markup-rows -eh 2 -no-custom -format i -theme "$THEME" -p "")"
[ -n "$sel" ] || exit 0

if [ "${CONFIRM[$sel]}" = 1 ]; then
  yn="$(printf '%s|' "Sí, ${LABELS[$sel],,}" "Cancelar" | rofi -dmenu -sep '|' -no-custom -format i -theme "$THEME" \
        -theme-str 'window { width: 640px; } listview { columns: 2; } element { padding: 22px 8px; }' -p "")"
  [ "$yn" = 0 ] || exit 0
fi

# Ejecuta una acción. Si falla por permisos reintenta con sudo sin contraseña (si lo configuraste con --setup).
# Todo queda en /tmp/mono-power.log y, si no se logra, se muestra el error ORIGINAL.
act() {
  local what="$1" out rc first; shift
  out="$("$@" 2>&1)"; rc=$?; first="$out"
  echo "$(date +%T) $* -> $rc ${out//$'\n'/ }" >>"$LOGF"
  if [ $rc -ne 0 ] && [ "$1" = systemctl ]; then
    out="$(sudo -n "$@" 2>&1)"; rc=$?
    echo "$(date +%T) sudo -n $* -> $rc ${out//$'\n'/ }" >>"$LOGF"
  fi
  if [ $rc -ne 0 ]; then
    notify-send -u critical "No se pudo $what" "${first:-Un programa lo está bloqueando.}"$'\n'"Diagnóstico:  mono-power --diag"
    return 1
  fi
}

case "$sel" in
  0) exec mono-lock ;;
  1) act "cerrar la sesión" i3-msg exit || loginctl terminate-session "${XDG_SESSION_ID:-}" ;;
  2) act "suspender" systemctl suspend ;;      # xss-lock (en i3) bloquea la pantalla al suspender
  3) if [ "$can_hibernate" = "yes" ]; then
       act "hibernar" systemctl hibernate
     else
       yn="$(printf '%s|' "Sí, configurarla ahora" "Cancelar" | rofi -dmenu -sep '|' -no-custom -format i -theme "$THEME" \
             -mesg "Hibernar necesita un archivo swap y configurar el arranque.  Estado: ${can_hibernate:-desconocido}" \
             -theme-str 'window { width: 760px; } listview { columns: 2; } element { padding: 22px 8px; }' -p "")"
       [ "$yn" = 0 ] && setsid kitty --class mono-setup -e sh -c 'mono-hibernate; printf "\n"; read -r -p "Enter para cerrar… " _' >/dev/null 2>&1 &
     fi ;;
  4) act "reiniciar" systemctl reboot ;;
  5) act "apagar" systemctl poweroff ;;
esac
