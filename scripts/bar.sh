#!/usr/bin/env bash
# mono-bar · aspecto de la barra superior
#   mono-bar               muestra el modo actual
#   mono-bar pills         píldoras de cristal oscuro (esquinas rectas) flotando sobre el fondo (por defecto)
#   mono-bar glass         una sola franja transparente (tinte suave)
#   mono-bar solid         la barra negra de siempre
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/mono-rice"
mkdir -p "$CONF"
HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

apply() {
  pkill -USR1 -x picom 2>/dev/null          # que picom relea su configuración (la barra no lleva desenfoque propio)
  [ -x "$HERE/../config/polybar/launch.sh" ] && "$HERE/../config/polybar/launch.sh" >/dev/null 2>&1 &
  disown -a 2>/dev/null
}

case "${1:-}" in
  "")            echo "modo actual: $(cat "$CONF/bar-mode" 2>/dev/null || echo pills)   (pills | glass | solid)" ;;
  pills|glass|solid) echo "$1" > "$CONF/bar-mode"; apply; echo "Barra en modo $1." ;;
  -h|--help)     sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//' ;;
  *)             echo "Uso: mono-bar [pills|glass|solid]"; exit 1 ;;
esac
