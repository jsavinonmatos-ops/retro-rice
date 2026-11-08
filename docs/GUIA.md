# Guía de tu sistema: qué es, cómo instalarlo y cómo mantenerlo

Se abre desde la terminal con `mono-guia`. Está escrita para quien no tiene mucha experiencia en Linux.

---

## 1. Qué tienes instalado

Tu sistema es **Debian 13 ("trixie")**, un Linux estable y muy usado. Encima armamos un escritorio propio con piezas pequeñas, cada una con un trabajo:

| Pieza | Para qué sirve |
|---|---|
| **i3** | El gestor de ventanas: acomoda las ventanas en mosaico y maneja los atajos de teclado |
| **polybar** | La barra de arriba (reloj, volumen, red, batería, botón de apagado) |
| **picom** | Efectos visuales: transparencias, desenfoque, sombras y esquinas redondeadas |
| **rofi** | El buscador de aplicaciones (`Super+Espacio`) y el menú de energía |
| **kitty** | La terminal |
| **dunst** | Las notificaciones |
| **LightDM** | La pantalla de login |
| **Ollama + mono-ai** | La inteligencia artificial local (Xiao Mei) |

Tu configuración vive en una carpeta, `~/mono-rice`, que es un repositorio de Git subido a GitHub (`retro-rice`). Los archivos de `~/.config` son **enlaces** a esa carpeta: si editas uno, editas el del repositorio.

---

## 2. Instalar todo, en orden

> Desde un Debian recién instalado, empieza por el **README** (sección "Instalación desde cero"); esta tabla es para completar o repetir pasos.

> Necesitas internet. Algunos pasos descargan varios GB y tardan.

| # | Comando | Qué hace | Cuánto pesa |
|---|---|---|---|
| 1 | `cd ~/mono-rice && git pull && bash install.sh` | Instala o actualiza el escritorio completo: temas, barra, atajos, terminal, login, pixel art | ~1 GB |
| 2 | `mono-pic sakura` | Pone la imagen de pixel art en `fastfetch` y en la IA | nada |
| 3 | `mono-apps` | Instala las aplicaciones libres (LibreOffice, VSCodium, GIMP, OBS...) y Zoom | 6 a 10 GB |
| 4 | `mono-ai-setup` | Instala Ollama y descarga el modelo de IA (Qwen 2.5 7B) | ~5 GB |
| 5 | `sudo apt install timeshift` | Programa de copias del sistema, para volver atrás si algo se rompe | pequeño |
| 6 | `mono-secure` y luego `mono-secure --apply` | Revisa tu seguridad y la refuerza | pequeño |
| 7 | `sudo reboot` | Reinicia para que todo quede activo | |

Si prefieres ir por partes con las apps: `mono-apps office`, `mono-apps dev`, `mono-apps media`, `mono-apps graphics`, `mono-apps tools`.

---

## 3. Todos los comandos

| Comando | Para qué sirve |
|---|---|
| `mono-update` | Actualiza el sistema con red de seguridad (úsalo cada semana) |
| `mono-guia` | Abre esta guía |
| `mono-secure` | Muestra tu estado de seguridad. `--apply` lo refuerza, `--audit` da un puntaje |
| `mono-ai` | La IA. `mono-ai "pregunta"` o `mono-ai --serio` sin personalidad |
| `mono-ai-setup` | Instala el motor de IA y el modelo |
| `mono-pic NOMBRE` | Cambia la imagen de pixel art: `sakura`, `yuki`, `mizu`, `kuro`, o tu propio PNG |
| `mono-apps` | Instala las aplicaciones |
| `mono-zoom` | Instala o actualiza Zoom |
| `mono-wall` | Cambia el fondo. `mono-wall mono` solo blanco y negro |
| `mono-lock` | Bloquea la pantalla |
| `mono-power` | Abre el menú de apagado |
| `mono-avatar` | Cambia la foto de usuario (`--choices` para elegir) |
| `mono-scale 120` | Cambia el tamaño de todo (entre 96 y 168) |
| `mono-touch` | Activa o desactiva la pantalla táctil |
| `mono-browser` | Abre Firefox con el perfil blanco y negro |
| `mono-slim` | Quita el escritorio XFCE (solo cuando i3 ya te funcione bien) |
| `mono-clip` | Historial del portapapeles (`Super+V`). Lo copiado desde KeePassXC no se guarda |
| `mono-wifi` / `mono-bluetooth` | Menús de red y Bluetooth (clic en el WiFi y en el icono de Bluetooth de la barra) |
| `mono-cal` | Calendario y clima (clic en la hora). Ciudad en `~/.config/mono-rice/city` |
| `mono-ask` | Pregúntale a la IA sobre el texto seleccionado: explicar, traducir, resumir, corregir (`Super+Shift+I`) |
| `mono-pet` | La chica de pixel art animada: parpadea y respira. Salir con `q` |
| `mono-night` | Luz nocturna (`Super+N`). Ubicación en `~/.config/mono-rice/location` |
| `mono-wall-auto 30` | Cambia el fondo solo cada 30 minutos (`off` lo apaga) |
| `mono-hibernate` | Prepara la hibernación (archivo swap + arranque). `--apply` la configura |
| `mono-boot` | Menú de arranque y pantalla de inicio en blanco y negro con pixel art. `--apply` y `--revert` |

### Atajos de teclado (`Super` = tecla Windows)
Dentro de i3, `Super+F1` muestra la lista completa. Los más usados: `Super+Enter` terminal, `Super+Espacio` aplicaciones, `Super+Q` cerrar ventana, `Super+1..9` escritorios, `Super+Shift+P` apagado, `Super+Esc` bloquear, `Super+I` la IA.

---

## 4. Mantener el sistema

Debian no se actualiza solo (salvo las correcciones de seguridad, si activaste `mono-secure --apply`). **Tú decides cuándo.** La regla es: poco y seguido es más seguro que mucho y de golpe.

### Cada semana (5 minutos)
```bash
mono-update
```
Hace, en orden:
1. Crea una **instantánea** del sistema con Timeshift (tu seguro).
2. Busca y muestra las actualizaciones.
3. Las instala. **Lee la lista**: si dice "serán ELIMINADOS" paquetes que no esperas, di que no (`n`) y pregúntale a alguien o a mí.
4. Actualiza las apps de Flatpak (VSCodium, DBeaver...).
5. Baja los cambios nuevos de tu configuración.
6. Te ofrece borrar paquetes que ya no sirven.

Si te avisa de que hay un **kernel nuevo**, reinicia cuando puedas.

### Cada mes
- `df -h /` — ¿cuánto espacio queda? Con menos del 15 % libre, limpia.
- `sudo apt clean` y `sudo apt autoremove` — borran archivos de descarga y paquetes huérfanos.
- `journalctl -p err -b | tail -30` — errores recientes del sistema. Unos pocos son normales.
- `mono-secure` — repasa tu seguridad.

### Cada seis meses o cuando cambie Debian
Debian publica una versión nueva cada ~2 años. **No la instales sin leer la guía oficial** y sin una copia de tus archivos. Para quedarte tranquilo, sigue en la 13 mientras reciba seguridad.

---

## 5. Cómo evitar que se rompa

**Hazlo**
- Haz una instantánea con Timeshift antes de cualquier cambio grande (`mono-update` ya la hace).
- Copia tus archivos importantes (documentos, proyectos) a un disco externo o a la nube **cada semana**. Una instantánea del sistema no reemplaza una copia de tus archivos.
- Instala programas con `apt` o con `mono-apps` (Flatpak). Son los caminos probados.
- Lee lo que apt va a hacer antes de escribir `s` o pulsar Enter.
- Deja que una actualización termine. Si la interrumpes (apagado, cerrar la terminal), puede quedar a medias. Si pasa: `sudo dpkg --configure -a` y luego `sudo apt install -f`.

**No lo hagas**
- No mezcles repositorios de otras versiones de Debian (testing, unstable) ni agregues repositorios que no conoces: es la causa número uno de sistemas rotos.
- No uses `sudo pip install` ni `sudo npm install -g`. Usa entornos virtuales (`python3 -m venv`) o instálalo en tu carpeta.
- No pegues en la terminal comandos de internet que no entiendas, sobre todo los que llevan `sudo` o `| sh`.
- No uses `rm -rf` con rutas que no hayas revisado dos veces.
- No uses `apt remove` con `-y` sin mirar la lista de lo que se va a quitar.
- No edites archivos dentro de `/etc` sin hacer antes una copia (`sudo cp archivo archivo.bak`).

**Tus cambios en la configuración**
Los archivos de `~/mono-rice` se guardan con Git. Si cambias algo y quieres conservarlo:
```bash
cd ~/mono-rice
git add -A && git commit -m "mi cambio"
```
Si haces `git pull` y te da un conflicto, no entres en pánico: `git stash` guarda tus cambios aparte, luego `git pull`, y `git stash pop` los vuelve a poner.

---

## 6. Si algo se rompe

Empieza por lo más sencillo y ve bajando.

1. **Una aplicación o la barra se ve mal.** Reinicia i3 con `Super+Shift+R`. Si sigue, cierra sesión (`Super+Shift+P`) y vuelve a entrar.
2. **Se rompió la configuración.** Vuelve a aplicar la tuya:
   ```bash
   cd ~/mono-rice && git status        # ¿qué cambió?
   bash install.sh                     # reaplica todo
   ```
   Lo que había antes quedó en carpetas `~/.config-backup-FECHA`.
3. **No arranca el escritorio (pantalla negra).** Pulsa `Ctrl+Alt+F3`, entra con tu usuario (`sachiret`) y contraseña (no se ven al escribir), y mira el error: `cat ~/.xsession-errors | tail`. Para volver a la pantalla gráfica, `Ctrl+Alt+F7`.
4. **Tras una actualización, algo dejó de funcionar.** Restaura la instantánea: abre Timeshift (`sudo timeshift-gtk`), elige la anterior y restaura.
5. **No arranca el sistema.** En el menú de arranque, elige **Opciones avanzadas de Debian → una versión anterior del kernel**. Muchas veces el problema es el kernel nuevo.
6. **Nada funciona.** Con una memoria USB de Debian puedes reinstalar sin perder tu carpeta personal si no formateas esa partición. Tu configuración está en GitHub: se recupera con `git clone` y `bash install.sh`.

### Dónde mirar los errores
| Archivo | Qué contiene |
|---|---|
| `/tmp/polybar.log` | Errores de la barra |
| `/tmp/picom.log` | Errores de las transparencias |
| `/tmp/mono-lock.log` | Errores del bloqueo de pantalla |
| `/tmp/mono-apps.log` | Errores al instalar aplicaciones |
| `~/.local/share/mono-ai/log.txt` | Lo que la IA ejecutó o rechazaste |
| `journalctl -b` | El registro del sistema desde el último arranque |

---

## 7. Seguridad

`mono-secure` revisa tu equipo y `mono-secure --apply` aplica lo seguro: cortafuegos, actualizaciones de seguridad automáticas, endurecimiento del kernel y bloqueo de pantalla por inactividad.

Lo que **no** puede hacer ningún script:
- **Cifrar el disco** solo se puede al instalar Debian. Si te importa, es una razón para reinstalar con "Cifrar el disco".
- **Contraseña larga y distinta** en cada cuenta, guardadas en KeePassXC.
- **Verificación en dos pasos** en tus correos y cuentas importantes.
- **Copias de seguridad.** Si te roban o se daña el disco, solo lo que tengas respaldado se salva.

### Sobre la IA local
`mono-ai` pide tu confirmación antes de cada comando que cambie algo, y bloquea los comandos destructivos. **Lee siempre el comando que propone antes de aceptarlo**: un modelo pequeño se equivoca.

---

## 8. Mini glosario

- **apt**: el instalador de programas de Debian.
- **paquete**: un programa empaquetado para instalar.
- **repositorio**: el servidor de donde apt baja los paquetes.
- **Flatpak**: otra forma de instalar apps, aisladas del resto del sistema.
- **kernel**: el núcleo de Linux; si hay uno nuevo, se usa al reiniciar.
- **sudo**: ejecuta un comando como administrador. Úsalo con cuidado.
- **Git**: lleva el historial de tu configuración.
- **dotfiles**: los archivos de configuración (los de `~/mono-rice`).
- **TTY**: la terminal de texto a pantalla completa (`Ctrl+Alt+F3`).
