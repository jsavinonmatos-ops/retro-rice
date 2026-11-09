#!/usr/bin/env bash
# mono-guia: abre la documentación.
#   mono-guia             guía de uso y mantenimiento (docs/GUIA.md)
#   mono-guia comandos    manual completo de comandos (docs/COMANDOS.md)
HERE="$(dirname "$(readlink -f "$0")")/../docs"
case "${1:-}" in
  comandos|comando|manual) G="$HERE/COMANDOS.md" ;;
  ""|guia|mantenimiento)   G="$HERE/GUIA.md" ;;
  *) echo "Uso: mono-guia [comandos]"; exit 1 ;;
esac
[ -f "$G" ] || { echo "No encuentro $G (¿hiciste git pull?)"; exit 1; }
if command -v glow >/dev/null; then exec glow -p "$G"
elif command -v batcat >/dev/null; then exec batcat --paging=always --language=markdown "$G"
else exec less -R "$G"; fi
