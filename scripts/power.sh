#!/usr/bin/env bash
# mono-power: menú de energía (Bloquear, Cerrar sesión, Suspender, Hibernar, Reiniciar, Apagar).
# Se abre con Super+Shift+P o con el botón de apagado de la barra.
set -u
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

# ejecuta una acción y, si falla, muestra el motivo real (antes fallaba en silencio)
act() {
  local what="$1" out; shift
  out="$("$@" 2>&1)" || { notify-send -u critical "No se pudo $what" "${out:-Revisa si hay programas que lo bloquean.}"; return 1; }
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
