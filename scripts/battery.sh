#!/usr/bin/env bash
# mono-battery: avisos de batería baja (20 %, 10 % y 5 % por defecto), una sola vez por nivel, con el tiempo estimado.
# Uso: mono-battery               estado
#      mono-battery test          muestra los 3 avisos para que veas cómo se ven y suenan
#      mono-battery levels 25 15 7   cambia los niveles de aviso (de mayor a menor, en %)
#      mono-battery autosuspend on|off   suspender solo al llegar a 3 % (por defecto apagado)
#      mono-battery loop          lo usa i3 al iniciar; no hace falta llamarlo a mano
set -u
SYS="${MONO_BATTERY_SYS:-/sys/class/power_supply}"
DIR="$HOME/.config/mono-rice"; mkdir -p "$DIR"
STATE="${XDG_RUNTIME_DIR:-/tmp}/mono-battery.state"      # último nivel avisado (999 = ninguno); se borra al reiniciar

levels() { local l; l="$(cat "$DIR/battery-levels" 2>/dev/null)"; [[ "$l" =~ ^[0-9]+([[:space:]]+[0-9]+)*$ ]] && echo "$l" || echo "20 10 5"; }
bat() { local d; for d in "$SYS"/BAT*; do [ -r "$d/capacity" ] && { echo "$d"; return 0; }; done; return 1; }

# minutos que quedan según el consumo actual (si la batería informa los datos)
est() {
  local d="$1" e p
  if   [ -r "$d/energy_now" ] && [ -r "$d/power_now" ];   then e="$(<"$d/energy_now")"; p="$(<"$d/power_now")"
  elif [ -r "$d/charge_now" ] && [ -r "$d/current_now" ]; then e="$(<"$d/charge_now")"; p="$(<"$d/current_now")"
  else return 0; fi
  [[ "$e" =~ ^[0-9]+$ && "$p" =~ ^[0-9]+$ ]] && [ "$p" -gt 0 ] && echo $(( e * 60 / p ))
  return 0
}
fmt() { local m="$1"; if [ "$m" -ge 60 ]; then echo "$((m / 60)) h $((m % 60)) min"; else echo "${m} min"; fi; }

alert() {   # alert NIVEL PORCENTAJE RUTA_BATERIA
  local lv="$1" cap="$2" d="$3" m extra="" urg title body f
  m="$(est "$d")"; [ -n "$m" ] && extra=" Quedan unos $(fmt "$m")."
  if   [ "$lv" -ge 15 ]; then urg=normal;   title="Batería baja: $cap %";        body="Conecta el cargador pronto.$extra"
  elif [ "$lv" -ge 8 ];  then urg=critical; title="Batería muy baja: $cap %";    body="Conecta el cargador ahora.$extra"
  else                        urg=critical; title="¡Batería crítica: $cap %!";    body="Guarda tu trabajo: el equipo puede apagarse en cualquier momento.$extra"; fi
  notify-send -u "$urg" -h string:x-dunst-stack-tag:mono-battery -i battery-caution "$title" "$body"
  if [ "$urg" = critical ]; then
    for f in /usr/share/sounds/freedesktop/stereo/dialog-warning.oga /usr/share/sounds/freedesktop/stereo/bell.oga; do
      [ -f "$f" ] && { command -v paplay >/dev/null && paplay "$f" >/dev/null 2>&1 & break; }
    done
  fi
}

check() {
  local d cap st state target lv top=0
  d="$(bat)" || return 0                                  # sin batería (equipo de escritorio): nada que hacer
  cap="$(<"$d/capacity")"; st="$(<"$d/status")"
  state="$(cat "$STATE" 2>/dev/null)"; [[ "$state" =~ ^[0-9]+$ ]] || state=999
  if [ "$st" != Discharging ]; then echo 999 > "$STATE"; return 0; fi     # cargando o llena: se reinician los avisos
  for lv in $(levels); do [ "$lv" -gt "$top" ] && top="$lv"; done
  [ "$cap" -gt $((top + 5)) ] && state=999 && echo 999 > "$STATE"        # ya hay suficiente carga: se rearman los avisos
  if [ "$cap" -le 3 ] && [ "$(cat "$DIR/battery-autosuspend" 2>/dev/null)" = on ] && [ "$state" != 0 ]; then
    notify-send -u critical -h string:x-dunst-stack-tag:mono-battery "Batería al $cap %" "Suspendiendo para no perder tu trabajo."
    echo 0 > "$STATE"; systemctl suspend; return 0
  fi
  target=""
  for lv in $(levels); do                                  # el nivel MÁS BAJO que ya se cruzó (si saltas de 50 a 4, sale un solo aviso)
    [ "$cap" -le "$lv" ] && { [ -z "$target" ] || [ "$lv" -lt "$target" ]; } && target="$lv"
  done
  if [ -n "$target" ] && [ "$target" -lt "$state" ]; then alert "$target" "$cap" "$d"; echo "$target" > "$STATE"; fi
}

loop() {
  exec 9>"${XDG_RUNTIME_DIR:-/tmp}/mono-battery.lock"; flock -n 9 || exit 0     # una sola copia
  while :; do check; sleep "${MONO_BATTERY_INTERVAL:-30}"; done
}

status() {
  local d cap st m
  d="$(bat)" || { echo "Este equipo no tiene batería."; return 0; }
  cap="$(<"$d/capacity")"; st="$(<"$d/status")"; m="$(est "$d")"
  echo "Batería: $cap %  ($st)${m:+  ·  ~$(fmt "$m") restantes}"
  echo "Avisos en: $(levels | sed 's/ /%, /g')%     Suspender al 3 %: $(cat "$DIR/battery-autosuspend" 2>/dev/null || echo off)"
}

case "${1:-status}" in
  loop) loop ;;
  check) check ;;
  status) status ;;
  test) d="$(bat)" || d="/nonexistent"; for lv in 20 10 5; do alert "$lv" "$lv" "$d"; sleep 3; done ;;
  levels) shift; [[ $# -gt 0 ]] && echo "$*" | grep -Eq '^[0-9]+( [0-9]+)*$' && { echo "$*" > "$DIR/battery-levels"; echo "Avisos en: $*"; } || { echo "Uso: mono-battery levels 20 10 5"; exit 1; } ;;
  autosuspend) case "${2:-}" in on|off) echo "$2" > "$DIR/battery-autosuspend"; echo "Suspender al 3 %: $2" ;; *) echo "Uso: mono-battery autosuspend on|off"; exit 1 ;; esac ;;
  *) sed -n '2,8p' "$0" | sed 's/^# \?//'; exit 1 ;;
esac
