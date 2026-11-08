#!/usr/bin/env bash
# mono-wall-auto: cambia el fondo solo cada cierto tiempo.
# Uso: mono-wall-auto 30   (cada 30 minutos)  |  mono-wall-auto off  |  mono-wall-auto status
#      mono-wall-auto loop (lo usa i3 al iniciar; no hace falta llamarlo a mano)
set -u
DIR="$HOME/.config/mono-rice"; CONF="$DIR/wall-interval"; mkdir -p "$DIR"
UNIT="${MONO_WALL_AUTO_UNIT:-60}"            # segundos por "minuto" (solo se cambia para pruebas)

interval() { local v; v="$(cat "$CONF" 2>/dev/null)"; [[ "$v" =~ ^[0-9]+$ ]] && echo "$v" || echo 30; }

loop() {
  exec 9>"$DIR/wall-auto.lock"; flock -n 9 || exit 0      # una sola copia corriendo
  echo $$ > "$DIR/wall-auto.pid"
  while :; do
    m="$(interval)"
    if [ "$m" -gt 0 ]; then
      sleep $(( m * UNIT ))
      [ "$(interval)" -gt 0 ] && mono-wall >/dev/null 2>&1      # si lo apagaste mientras dormía, no cambia
    else
      sleep 30
    fi
  done
}

# detiene la copia en marcha usando su número de proceso (no depende de cómo se llamó al script)
stop_loop() {
  local pid; pid="$(cat "$DIR/wall-auto.pid" 2>/dev/null)"
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then pkill -P "$pid" 2>/dev/null; kill "$pid" 2>/dev/null; sleep 0.2; fi
}

case "${1:-status}" in
  loop)   loop ;;
  off)    echo 0 > "$CONF"; echo "Cambio automático de fondo: apagado" ;;
  stop)   stop_loop ;;
  status) m="$(interval)"; [ "$m" -gt 0 ] && echo "Cambia el fondo cada $m minutos" || echo "Apagado" ;;
  [0-9]*) echo "$1" > "$CONF"; echo "El fondo cambiará cada $1 minutos"
          stop_loop; setsid nohup "$0" loop >/dev/null 2>&1 & ;;
  *) echo "Uso: mono-wall-auto 30 | off | status"; exit 1 ;;
esac
