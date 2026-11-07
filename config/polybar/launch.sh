#!/usr/bin/env bash
# Reinicia polybar y autodetecta batería y adaptador (Acer usa BAT1/ACAD, otros BAT0/AC)
killall -q polybar
while pgrep -u "$UID" -x polybar >/dev/null; do sleep 0.2; done

PS=/sys/class/power_supply
export POLYBAR_BAT="$(ls $PS 2>/dev/null | grep -m1 '^BAT' || echo BAT0)"
export POLYBAR_AC="$(ls $PS 2>/dev/null | grep -m1 -E '^(AC|ACAD|ADP)' || echo AC)"

polybar main 2>&1 | tee -a /tmp/polybar.log & disown
