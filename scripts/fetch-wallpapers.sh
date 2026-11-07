#!/usr/bin/env bash
# Descarga wallpapers anime SFW (wallhaven.cc).
# Uso: fetch-wallpapers.sh [cantidad=48] [--mono] [--fresh]
#   (sin --mono)  a color, tonos oscuros/rosa/violeta/rojo  -> ~/Pictures/wallpapers/
#   --mono        blanco y negro (convertidos)               -> ~/Pictures/wallpapers/mono/
#   --fresh       reemplaza los descargados antes (solo si la descarga nueva funcionó; no toca los tuyos)
# Las imágenes son de sus autores: uso personal, no se suben al repo (.gitignore).
set -u
N=48; MONO=0; FRESH=0
for a in "$@"; do case "$a" in --mono) MONO=1 ;; --fresh) FRESH=1 ;; *[0-9]*) N="$a" ;; esac; done

BASE="$HOME/Pictures/wallpapers"
if [ "$MONO" = 1 ]; then
  DIR="$BASE/mono"; COLORS=(000000 999999 424153)
else
  DIR="$BASE";      COLORS=(ea4c88 993399 000000 cc0000 663399 333399)
fi
mkdir -p "$DIR"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

PER=$(( (N + ${#COLORS[@]} - 1) / ${#COLORS[@]} ))
[ "$PER" -gt 24 ] && PER=24   # la API da 24 resultados por página
GOT=0; FAIL=0

for c in "${COLORS[@]}"; do
  API="https://wallhaven.cc/api/v1/search?q=anime%20girl&categories=010&purity=100&sorting=random&atleast=1920x1080&ratios=16x9&colors=$c"
  list=""
  for try in 1 2 3; do
    list="$(curl -fsSL --max-time 30 "$API" 2>/dev/null | jq -r '.data[].path' 2>/dev/null)" && [ -n "$list" ] && break
    echo "   (color $c: la API no respondió, reintento $try/3)"; sleep 5
  done
  [ -z "$list" ] && { echo "   color $c: sin resultados, lo salto"; FAIL=$((FAIL+1)); continue; }

  while read -r url; do
    f="$TMP/$(basename "$url")"
    if [ -f "$DIR/$(basename "$url")" ]; then cp "$DIR/$(basename "$url")" "$f"; GOT=$((GOT+1)); continue; fi
    if curl -fsSL --max-time 90 "$url" -o "$f"; then
      [ "$MONO" = 1 ] && convert "$f" -colorspace Gray -brightness-contrast -6x18 "$f"
      GOT=$((GOT+1)); echo "ok $(basename "$f")"
    else
      rm -f "$f"; echo "   falló $(basename "$url")"
    fi
  done < <(echo "$list" | head -n "$PER")
  sleep 3   # cortesía con la API (límite 45 peticiones/min)
done

if [ "$GOT" -eq 0 ]; then
  echo "No se pudo descargar nada (sin internet o wallhaven bloqueó la petición). No borré nada tuyo. Reintenta en un rato."
  exit 1
fi
[ "$FRESH" = 1 ] && rm -f "$DIR"/wallhaven-*
mv -f "$TMP"/* "$DIR"/
echo "Listo: $GOT imágenes en $DIR (fallaron $FAIL búsquedas)"
