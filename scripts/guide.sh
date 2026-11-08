#!/usr/bin/env bash
# mono-guia: abre la guía de uso y mantenimiento (docs/GUIA.md)
G="$(dirname "$(readlink -f "$0")")/../docs/GUIA.md"
if command -v glow >/dev/null; then exec glow -p "$G"
elif command -v batcat >/dev/null; then exec batcat --paging=always --language=markdown "$G"
else exec less -R "$G"; fi
