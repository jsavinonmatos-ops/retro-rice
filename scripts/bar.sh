#!/usr/bin/env bash
# mono-bar · aspecto de la barra superior
#   mono-bar               muestra el modo actual
#   mono-bar pills         píldoras de cristal oscuro flotando sobre el fondo (por defecto)
#   mono-bar glass         una sola franja transparente (tinte suave)
#   mono-bar solid         la barra negra de siempre
#   mono-bar caps 18 4     ajusta las puntas redondeadas de las píldoras: tamaño y desplazamiento vertical
#   mono-bar caps auto     vuelve al cálculo automático
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/mono-rice"
mkdir -p "$CONF"
HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

apply() {
  pkill -USR1 -x picom 2>/dev/null          # que picom relea su configuración (la barra no lleva desenfoque propio)
  [ -x "$HERE/../config/polybar/launch.sh" ] && "$HERE/../config/polybar/launch.sh" >/dev/null 2>&1 &
  disown -a 2>/dev/null
}

case "${1:-}" in
  "")            echo "modo actual: $(cat "$CONF/bar-mode" 2>/dev/null || echo pills)   (pills | glass | solid)"
                 [ -s "$CONF/bar-caps" ] && echo "puntas: $(cat "$CONF/bar-caps") (tamaño desplazamiento)" || echo "puntas: automáticas" ;;
  pills|glass|solid) echo "$1" > "$CONF/bar-mode"; apply; echo "Barra en modo $1." ;;
  caps)          case "${2:-}" in
                   auto) rm -f "$CONF/bar-caps"; apply; echo "Puntas automáticas." ;;
                   ''|*[!0-9]*) echo "Uso: mono-bar caps <tamaño> [desplazamiento]   o   mono-bar caps auto"; exit 1 ;;
                   *) printf '%s %s\n' "$2" "${3:-3}" > "$CONF/bar-caps"; apply; echo "Puntas: tamaño $2, desplazamiento ${3:-3}." ;;
                 esac ;;
  -h|--help)     sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//' ;;
  *)             echo "Uso: mono-bar [pills|glass|solid|caps <tamaño> [desplazamiento]|caps auto]"; exit 1 ;;
esac
