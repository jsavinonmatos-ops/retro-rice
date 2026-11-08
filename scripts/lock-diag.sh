#!/usr/bin/env bash
# Informe del bloqueo para pegarlo al pedir ayuda. Uso: mono-lock-diag
I3=/usr/local/bin/i3lock; [ -x "$I3" ] || I3="$(command -v i3lock)"
echo "== binario usado: $I3"; ls -l "$I3" 2>&1
echo "== versión:"; "$I3" --version 2>&1 | head -2
echo "== todos los i3lock del PATH:"; which -a i3lock
echo "== ¿acepta estas opciones? (si = sí):"
for o in --clock --indicator --no-modkey-text --force-clock --wrong-size=20 --wrongsize=20 --wrong-pos=ix:iy --wrongpos=ix:iy --verif-pos=ix:iy --time-pos=ix:iy; do
  "$I3" "$o" --version >/dev/null 2>&1 && echo "  si  $o" || echo "  no  $o"
done
echo "== últimas líneas de /tmp/mono-lock.log:"; tail -25 /tmp/mono-lock.log 2>&1
