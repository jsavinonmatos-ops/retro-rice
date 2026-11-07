#!/usr/bin/env bash
# Recorta una imagen en círculo con esquinas transparentes.
# Uso: roundify.sh entrada salida.png [tamaño=512]
# Prueba tres métodos (ImageMagick 6 y 7 se comportan distinto) y comprueba que el resultado
# realmente tenga las esquinas transparentes; si ninguno sirve, deja la imagen cuadrada y devuelve 1.
IN="$1"; OUT="$2"; S="${3:-512}"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
H=$((S / 2))

convert "$IN" -resize "${S}x${S}^" -gravity center -extent "${S}x${S}" +repage "$T/sq.png" || exit 1

# la esquina (0,0) debe tener distinto alfa que el centro
ok() {
  local c m
  c="$(convert "$1" -format '%[fx:p{0,0}.a]' info: 2>/dev/null)"
  m="$(convert "$1" -format "%[fx:p{$H,$H}.a]" info: 2>/dev/null)"
  [ -n "$c" ] && [ -n "$m" ] && [ "$c" != "$m" ]
}

# 1) relleno con la imagen como patrón (el más portable)
convert -size "${S}x${S}" xc:none -tile "$T/sq.png" -draw "circle $H,$H $H,1" "$OUT" 2>/dev/null && ok "$OUT" && exit 0

# 2) máscara con DstIn
convert -size "${S}x${S}" xc:none -fill white -draw "circle $H,$H $H,1" "$T/m.png"
convert "$T/sq.png" -alpha set "$T/m.png" -compose DstIn -composite "$OUT" 2>/dev/null && ok "$OUT" && exit 0

# 3) CopyOpacity (ImageMagick 6: negro = opaco) y CopyAlpha (ImageMagick 7: blanco = opaco)
convert -size "${S}x${S}" xc:white -fill black -draw "circle $H,$H $H,1" "$T/m6.png"
convert "$T/sq.png" "$T/m6.png" -alpha off -compose CopyOpacity -composite "$OUT" 2>/dev/null && ok "$OUT" && exit 0
convert -size "${S}x${S}" xc:black -fill white -draw "circle $H,$H $H,1" "$T/m7.png"
convert "$T/sq.png" "$T/m7.png" -alpha off -compose CopyAlpha -composite "$OUT" 2>/dev/null && ok "$OUT" && exit 0

cp "$T/sq.png" "$OUT"; exit 1
