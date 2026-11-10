# CLAUDE.md — contexto del proyecto retro-rice

Este archivo lo lee Claude Code automáticamente al abrirse en esta carpeta. Resume el proyecto, las preferencias de la persona
y las lecciones aprendidas, para continuar el trabajo sin la conversación original.

## Quién y para qué
- Persona hispanohablante (República Dominicana). **Responde siempre en español**, claro y directo, sin jerga innecesaria.
  Tiene poca experiencia en Linux: explica el *porqué*, da comandos listos para copiar y avisa de los riesgos.
- Equipo: **Acer Aspire 3 15** (A315-24), Ryzen 5 7520U, 16 GB, pantalla táctil 1920x1080, **Debian 13 (trixie)**, X11.
  Usuario `sachiret`, equipo `sachi`. Zona horaria `America/Santo_Domingo`.
- El proyecto es su escritorio personal ("rice"): **i3 + polybar + picom + rofi + kitty + dunst**, en **blanco y negro**
  (acento `#fafafa`), con la terminal a color, pixel art, una IA local con personalidad kawaii y herramientas de mantenimiento.
- Repositorio: `https://github.com/jsavinonmatos-ops/retro-rice` (público). Se clona en `~/mono-rice`.
- **No incluyas datos de empleadores ni de trabajo** en commits, documentos ni ejemplos.

## Cómo trabajar (lecciones de la historia del proyecto)
1. **Verifica antes de afirmar.** Hubo muchos errores por dar por hecho algo sin comprobarlo. Si no puedes ver la pantalla o ejecutar
   en el equipo real, dilo ("probé la lógica con simulaciones; no lo he visto funcionando"). Si estás ahora EN la laptop, ejecuta y mira.
2. **Prueba todo lo que escribas.** Patrón usado: programas simulados (stubs de `rofi`, `nmcli`, `systemctl`, `notify-send`…) en un
   directorio temporal con `PATH` modificado, y comprobaciones con `grep`/Python. Los tests no se guardan en el repo.
3. **Valida antes de subir:** `bash -n` a cada script, `python3 -I scripts/polybar-check.py config/polybar/config.ini`, y el
   comprobador de tablas del manual (`docs/COMANDOS.md`). Un solo `%{A}` suelto en `config.ini` dejó a la persona sin barra.
4. **Cambios pequeños y reversibles.** Lo que toca el sistema (`mono-boot`, `mono-hibernate`, `mono-secure`, `mono-slim`) tiene
   modo "solo revisar" por defecto, pide escribir `SI`, hace copia de seguridad y tiene `--revert`.
5. **Sé honesto con los límites.** Ningún script hace el sistema "100 % seguro"; el cifrado de disco solo se activa al instalar.
6. **Commits:** mensaje en español, claro. Sube con `git push origin main` (la persona pega sus credenciales la primera vez).
7. Cuando algo falle en el equipo real, pide la salida del comando de diagnóstico (`mono-power --diag`, `mono-lock-diag`,
   `mono-hibernate`, `journalctl -p err -b`) en vez de adivinar.

## Mapa del repositorio
```
install.sh        instalador desatendido (idempotente). Enlaza config/ en ~/.config, crea los comandos mono-* en /usr/local/bin
bootstrap.sh      atajo: instala git, clona e instala
config/           i3, polybar (config.ini + safe.ini de emergencia + launch.sh), picom, rofi (config/power/menu .rasi), kitty, dunst, gtk-3.0
home/             .zshrc, .xprofile, .Xresources
scripts/          comandos mono-* y ayudantes (ver tabla)
browser/          perfil de Firefox (user.js, userChrome.css, userContent.css, policies.json)
login/            tema GTK de la pantalla de login (lightdm-gtk-greeter)
docs/GUIA.md      guía de mantenimiento      docs/COMANDOS.md   manual completo de comandos
```
Los comandos `mono-*` son scripts de `scripts/` enlazados por `install.sh`. `menus.py` atiende varios nombres por enlace
(`mono-clip`, `mono-wifi`, `mono-bluetooth`, `mono-cal`, `mono-ask`, `mono-music`).

| Comando | Script | Nota |
|---|---|---|
| mono-wall / mono-wall-auto | setwall.sh / wallcycle.sh | en i3 usa `feh`; el cambio automático guarda su PID |
| mono-lock | lock.sh | i3lock-color compilado (`build-i3lock-color.sh`); detecta opciones probándolas con `--version`; respaldo i3lock simple |
| mono-power | power.sh | 5 botones; 4 caminos para apagar (systemctl → sudo -n → pkexec → terminal con sudo); `--diag`, `--setup` |
| mono-ai / mono-ai-setup | ai.py / setup-ai.sh | Ollama local (qwen2.5:7b), herramientas con confirmación y bloqueo de comandos destructivos |
| mono-pic / mono-pet | pic.sh + pixelart.py / pet.sh | pixel art hecho por código; `--real` usa el protocolo gráfico de kitty |
| mono-secure | secure.sh | revisa y refuerza (ufw, actualizaciones automáticas, sysctl) |
| mono-update | update.sh | instantánea Timeshift → apt → flatpak → git pull |
| mono-cal / mono-agenda | menus.py | calendario en cuadrícula (rofi, `calendar.rasi`), feriados de RD, recordatorios; `mono-cal --daemon` (lo inicia i3) avisa |
| mono-hibernate / mono-boot | hibernate.py / boot.py | opcionales, con `--apply`/`--revert` |
| mono-battery / mono-night | battery.sh / night.sh | avisos 20/10/5 % con tiempo restante; luz nocturna con gammastep |
| mono-apps / mono-zoom | install-apps.sh / install-zoom.sh | categorías: office dev media graphics tools notas games (`notas` = Logseq, solo software libre) |

## Decisiones tomadas (respétalas salvo que la persona pida otra cosa)
- Escritorio en **blanco y negro**; se probó un acento rosa y se descartó. **La terminal sí va a color** (kitty, zsh, starship).
- **La barra de polybar siempre visible** (se probó autohide y se quitó). Sin animaciones de ventanas en XFCE; en i3 picom las anima.
- Fondo/arranque/login en **escala de grises**. El login rota entre varios fondos oscuros.
- **Un solo clic elige** en los menús de rofi (`me-select-entry: ""`, `me-accept-entry: "MousePrimary"` en `config.rasi`).
- **Sin botón de Hibernar** en el menú de energía (la herramienta `mono-hibernate` sigue existiendo, opcional).
- **Se descartaron:** cuidado de la batería con límite de carga (TLP), terminal desplegable y tema de VSCodium. Sí hay *avisos* de batería baja.
- **No se usa `nm-applet`**: el WiFi es `mono-wifi` (rofi). Pantalla táctil **desactivada por defecto** (`mono-touch on` la activa).
- VSCodium sin tema propio; Discord y Zoom permitidos aunque no sean libres; las apps libres se prefieren.
- La IA se llama **Xiao Mei 小美**, personalidad kawaii con toque chino, sin caricaturizar; `--serio` la apaga. Los comandos van limpios.
- **Barra: la original (negra, redondeada, con título de ventana).** Se probaron y la persona rechazó por feas: (a) píldoras flotantes con puntas redondeadas de glifos Nerd Font (no cuadran con la altura de la barra), (b) píldoras de esquinas rectas, (c) franja de cristal con desenfoque. Todo se revirtió (commit `c52aab3`). No reintentar sin ver la pantalla.
- **Notificaciones (dunst) en cristal**: negro translúcido; las críticas con tinte y borde rojo (`#ff5370`, el rojo de batería baja). Los avisos de batería llevan barra de progreso (`-h int:value`) y `-a mono-battery`.
- **Calendario** (`menus.py`): cuadrícula 7×8 en rofi. **rofi llena las columnas de arriba abajo**, por eso `to_rofi_order/to_rofi_index/from_rofi_index` reordenan; no usar la propiedad `flow` (no verificada). `-selected-row` arranca en hoy (el resalte inicial en la flecha ◀ se veía mal). Feriados de RD calculados (`holidays_do`: Pascua + Ley 139-97 que mueve a lunes; escrito de memoria, sin verificar con fuente oficial). Recordatorios en `~/.config/mono-rice/reminders.json` (personal, fuera del repo), aviso sin caducar (`notify-send -t 0`); `mono-agenda` los lista junto a los feriados próximos.
- **`install.sh` no vuelve a bajar wallpapers** si ya hay suficientes (36 color / 18 mono / 6 login); `WALLPAPERS=1 bash install.sh` los renueva.
- **Apps de notas:** solo software libre (la persona lo pidió): Logseq (`com.logseq.Logseq`, ID de Flathub sin verificar). Obsidian se descartó por no ser libre. Kanban nativo no existe en Logseq.
- Tamaño de la imagen de fastfetch/IA: `mono-pic <personaje|png> --rows N` (22 por defecto).
- Wallpapers: de wallhaven.cc por API, SFW, **no se suben al repo**. El pixel art de las 4 chicas es original (en `pixelart.py`).

## Trampas conocidas (no las repitas)
- Al escribir archivos con herramientas, **los glifos Nerd Font (zona privada Unicode) se pierden**: insértalos con `chr(0xf0c9)` desde Python.
- `re.S` + `(.*)` en una sustitución se tragó el resto del archivo de polybar. Usa patrones acotados y valida.
- **No uses `pkill -f` con un texto que aparezca en tu propio comando**: puede matar tu shell. `killall` no está instalado (`psmisc`).
- `rofi` por defecto necesita doble clic; un clic sobrante cierra la ventana siguiente: por eso hay una pausa y un reintento único
  cuando una ventana de contraseña o confirmación se cierra vacía en menos de 0,7 s.
- ImageMagick: el recorte redondo con máscara/alfa falló en su versión; `roundify.sh` prueba tres métodos y verifica el resultado.
- `i3lock-color` 2.13.c.5 no lista sus opciones en `--help` ni dice "color" en `--version`: detéctalo probando `--clock --version`.
- LightDM `dm-tool lock` dejó la pantalla negra en este equipo: el bloqueo usa i3lock, no LightDM.
- Debian 13 no trae `touchegg` ni (según el caso) `i3lock-color`; `install.sh` usa `inst` (instala solo lo que existe).
- Python 3.13 ya no tiene `audioop`.
- Al restaurar archivos con módulos de iconos (`config.ini`), **no reescribirlos con Write**: los glifos se pierden. Modificar con Python (regex acotada) o `git checkout <commit> -- archivo`.
- Los commits salen con `git -c user.name=... -c user.email=...` (Gmail personal de la persona); empuja con `git.exe push origin main` si estás en WSL.

## Pendiente / ideas abiertas
- **«Botón de cambiar idioma» que abre muchas ventanas a la izquierda** (en vez de una a la derecha): sin resolver, falta saber cuál botón es. Sospecha: el teclado en pantalla Onboard (icono azul en la bandeja, `Super+K`). Pedir a la persona qué botón es y probar `xdotool search --class onboard` tras pulsarlo.
- Verificar en la laptop real: calendario/agenda/recordatorios (se probó con rofi simulado), notificaciones en cristal, `mono-apps notas`.
- Ideas ofrecidas y no pedidas: feriados/cumpleaños propios, recordatorios anuales, número de semana en el calendario, tema oscuro para Logseq.
- **Ventiladores altos tras arrancar** (varios minutos): sin diagnosticar. Idea: `mono-calor` que guarde procesos por CPU acumulada,
  temperaturas, driver de frecuencia (`amd_pstate` falla porque el BIOS no ofrece CPPC; usa `acpi-cpufreq`), presión de CPU/disco.
  También reducir el sondeo de `mono-clip` (consulta `xclip` 2 veces por segundo; mejor por eventos) y revisar el coste del blur de picom.
- Confirmar en la laptop real: apagado/reinicio con un clic (`mono-power --diag` si falla), ventana de contraseña del WiFi,
  barra superior del login, avisos de batería (`mono-battery test`).
- Instalación **desde un USB limpio** nunca se ha ejecutado de punta a punta (el README lo dice).
- El prefijo `mono-` es solo un nombre; renombrar a `retro-` es posible si la persona lo pide.

## Si estás en la laptop con la persona
Ejecuta y mira los resultados reales: `mono-secure`, `systemctl --failed`, `journalctl -p err -b`, `mono-power --diag`.
Eso es lo que más faltó durante el desarrollo, que se hizo a ciegas desde otro equipo.
