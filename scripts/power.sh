#!/usr/bin/env bash
# mono-power: menú de energía (Bloquear, Cerrar sesión, Suspender, Reiniciar, Apagar).
# Quitar la pregunta de confirmación:  echo off > ~/.config/mono-rice/power-confirm   (borra el archivo para volver a activarla)
# Se abre con Super+Shift+P o con el botón de apagado de la barra.
set -u
LOGF=/tmp/mono-power.log
SUDOERS=/etc/sudoers.d/mono-power

case "${1:-}" in
  --diag)
    echo "== Sesión (debe decir Active=yes) =="
    loginctl show-session "${XDG_SESSION_ID:-self}" -p Id -p Type -p Active -p State -p Seat -p Remote 2>&1
    echo; echo "== ¿Qué permite el sistema sin pedir contraseña?  yes = sí | challenge = pediría contraseña | no = prohibido =="
    for a in poweroff reboot suspend; do printf '  %-10s %s\n' "$a" "$(systemctl can-$a 2>&1)"; done
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
    printf '# retro-rice: apagar, reiniciar y suspender sin contraseña (solo estos 3 comandos exactos)\n%s ALL=(root) NOPASSWD: %s poweroff, %s reboot, %s suspend\n' \
      "$USER" "$sc" "$sc" "$sc" > "$tmp"
    if sudo visudo -cf "$tmp" >/dev/null && sudo install -m 440 -o root -g root "$tmp" "$SUDOERS"; then
      rm -f "$tmp"; echo "Listo: $SUDOERS. Quitarlo cuando quieras:  mono-power --remove"; exit 0
    fi
    rm -f "$tmp"; echo "visudo rechazó el archivo o no se pudo instalar; no cambié nada."; exit 1 ;;
  --remove) sudo rm -f "$SUDOERS" && echo "Quitado."; exit 0 ;;
esac

THEME="$HOME/.config/rofi/power.rasi"
G="JetBrainsMono Nerd Font"

# [icono, etiqueta, ¿pide confirmación?]  (los iconos son glifos de Nerd Font)
GLYPHS=(    )
LABELS=("Bloquear" "Cerrar sesión" "Suspender" "Reiniciar" "Apagar")
CONFIRM=(0 1 0 1 1)

entries=()
for i in "${!LABELS[@]}"; do
  label="${LABELS[$i]}"
  entries+=("<span font_family='$G' size='36000'>${GLYPHS[$i]}</span>"$'\n'"$label")
done

# -sep '|' permite entradas de dos líneas (icono arriba, texto abajo); -format i devuelve el número elegido
sel="$(printf '%s|' "${entries[@]}" | rofi -dmenu -sep '|' -markup-rows -eh 2 -no-custom -format i -theme "$THEME" -p "")"
[ -n "$sel" ] || exit 0

if [ "${CONFIRM[$sel]}" = 1 ] && [ "$(cat "$HOME/.config/mono-rice/power-confirm" 2>/dev/null)" != off ]; then
  sleep 0.4        # evita que un clic de más (o un doble clic) caiga sobre la ventana de confirmación recién abierta
  yn="$(printf '%s|' "Sí, ${LABELS[$sel],,}" "Cancelar" | rofi -dmenu -sep '|' -no-custom -format i -theme "$THEME" \
        -theme-str 'window { width: 640px; } listview { columns: 2; } element { padding: 22px 8px; }' -p "")"
  [ "$yn" = 0 ] || exit 0
fi

log() { echo "$(date +%T) $*" >>"$LOGF"; }

# Ejecuta una acción. Para apagar/reiniciar/suspender/hibernar prueba, en orden:
#   1) systemctl normal   2) sudo sin contraseña (si hiciste  mono-power --setup)
#   3) pkexec (ventana de contraseña de polkit)   4) una terminal que te pide la contraseña de sudo
# Así el botón SIEMPRE llega a algo que funciona. Todo queda en /tmp/mono-power.log
act() {
  local what="$1" out rc first verb; shift
  out="$("$@" 2>&1)"; rc=$?; first="$out"
  log "$* -> $rc ${out//$'\n'/ }"
  [ $rc -eq 0 ] && return 0
  if [ "$1" = systemctl ]; then
    verb="$2"
    out="$(sudo -n "$@" 2>&1)"; rc=$?; log "sudo -n $* -> $rc ${out//$'\n'/ }"
    [ $rc -eq 0 ] && return 0
    if command -v pkexec >/dev/null; then
      out="$(pkexec "$@" 2>&1)"; rc=$?; log "pkexec $* -> $rc ${out//$'\n'/ }"
      [ $rc -eq 0 ] && return 0
      [ $rc -eq 126 ] && return 1          # cerraste la ventana de contraseña: es tu decisión
    fi
    notify-send "No se pudo $what directamente" "${first:-El sistema no lo autorizó.}"$'\n'"Te pido tu contraseña en una terminal."
    log "terminal con sudo para: $verb"
    setsid kitty --class mono-setup -e sh -c "printf 'Para $what hace falta tu contraseña de administrador.\n\n'; sudo systemctl $verb || { printf '\nFalló. ¿Forzar ignorando los programas que lo bloquean? [s/N] '; read -r r; [ \"\$r\" = s ] && sudo systemctl -i $verb; }" >/dev/null 2>&1 &
    return 0
  fi
  notify-send -u critical "No se pudo $what" "${first:-Un programa lo está bloqueando.}"$'\n'"Diagnóstico:  mono-power --diag"
  return 1
}

case "$sel" in
  0) exec mono-lock ;;
  1) act "cerrar la sesión" i3-msg exit || loginctl terminate-session "${XDG_SESSION_ID:-}" ;;
  2) act "suspender" systemctl suspend ;;      # xss-lock (en i3) bloquea la pantalla al suspender
  3) act "reiniciar" systemctl reboot ;;
  4) act "apagar" systemctl poweroff ;;
esac
