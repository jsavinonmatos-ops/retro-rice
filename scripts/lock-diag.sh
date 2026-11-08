#!/usr/bin/env bash
# Informe del bloqueo para pegarlo al pedir ayuda. Uso: mono-lock-diag
I3=/usr/local/bin/i3lock; [ -x "$I3" ] || I3="$(command -v i3lock)"
echo "== binario usado: $I3"; ls -l "$I3" 2>&1
echo "== versión:"; "$I3" --version 2>&1 | head -2
echo "== todos los i3lock del PATH:"; which -a i3lock
echo "== opciones de tu i3lock sobre error, verificación, hora, fecha y posición:"
"$I3" --help 2>&1 | tr ' []' '\n\n\n' | grep -oE -- '--[a-z-]*(wrong|verif|clock|time|date|pos|size)[a-z-]*' | sort -u | tr '\n' ' '; echo
echo "== últimas líneas de /tmp/mono-lock.log:"; tail -25 /tmp/mono-lock.log 2>&1
