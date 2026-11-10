# retro-rice

Escritorio **en blanco y negro** para Debian 13: tiling con i3, barra flotante, efectos de cristal, terminal con colores,
pixel art, bloqueo de pantalla propio, asistente de IA local y herramientas de mantenimiento. Pensado para un
**Acer Aspire 3 15** (Ryzen serie 7000, gráficos integrados AMD, pantalla táctil), pero funciona en cualquier PC con Debian 13.

> Se fue construyendo y probando sobre esa laptop. El camino **completo desde un USB limpio no lo he ejecutado de punta a punta**:
> si vas a reinstalar de verdad, pruébalo antes en una máquina virtual (VirtualBox o virt-manager) con Debian 13.

---

## Instalación desde cero

### 0. Antes de empezar
- Copia tus archivos importantes a un disco externo o a la nube.
- Necesitas internet durante toda la instalación (cable, o el celular compartiendo internet por USB, porque el WiFi de algunas laptops
  no funciona hasta instalar sus drivers).
- Un USB de 4 GB o más.

### 1. Instalar Debian 13
1. Descarga la ISO **netinst** de Debian 13 desde `debian.org` y grábala en el USB (con BalenaEtcher, Rufus o `dd`).
2. Arranca desde el USB (en Acer, tecla `F12`) y elige **Install** (la opción gráfica o la de texto).
3. En el instalador:
   - **Contraseña de root: déjala vacía.** Así tu usuario queda con permisos de `sudo` automáticamente.
   - **Cifrar el disco** (en "Particionado": *Guiado, usar todo el disco y configurar LVM cifrado*). Es lo que protege tus archivos si pierdes la laptop,
     y **solo se puede hacer ahora**.
   - En **Selección de software** marca **entorno de escritorio Debian → Xfce** y **utilidades estándar del sistema**.
     Desmarca *servidor SSH*, salvo que lo necesites.
4. Termina, retira el USB y reinicia.

### 2. Primer arranque
Entra con tu usuario, abre una terminal (`Aplicaciones → Emulador de terminal`) y comprueba que tienes sudo:
```bash
sudo -v
```
Si dice `sudo: command not found` o que no estás en el archivo sudoers:
```bash
su -                              # pide la contraseña de root (si dejaste root sin contraseña, usa tu usuario con 'sudo' y salta este paso)
apt install -y sudo
usermod -aG sudo TU_USUARIO       # cambia TU_USUARIO por tu nombre de usuario
exit
```
Luego **cierra sesión y vuelve a entrar** para que el permiso se active.

### 3. Instalar el rice
```bash
sudo apt update && sudo apt install -y git
git clone https://github.com/jsavinonmatos-ops/retro-rice.git ~/mono-rice
bash ~/mono-rice/install.sh
```
Tarda de **15 a 30 minutos** (descarga paquetes, una fuente y ~80 wallpapers) y pide tu contraseña de `sudo` una sola vez. Hace esto:

| Parte | Qué instala o configura |
|---|---|
| Sistema | Zona horaria de República Dominicana, repositorios de firmware, drivers AMD y WiFi |
| Escritorio | i3, polybar, picom, rofi, dunst, temas Arc-Dark y Papirus, fuentes |
| Terminal | kitty, zsh con colores, starship, fastfetch con pixel art |
| Pantalla de login | Tema propio con fondo en blanco y negro y avatar |
| Navegador | Firefox con tema oscuro, uBlock Origin y Dark Reader |
| Táctil y touchpad | Tap-to-click y scroll natural; la pantalla táctil queda **desactivada** (`mono-touch on` la activa) |
| Comandos | Los `mono-*` (ver tabla) |

Es **seguro repetirlo** cuantas veces quieras: reaplica la configuración y guarda copias de lo que reemplaza en `~/.config-backup-FECHA`.

### 4. Reiniciar
```bash
sudo reboot
```
En la pantalla de login entra con tu usuario: la sesión **i3** viene seleccionada. Si quieres volver a XFCE, abre el menú de sesión del login.
Dentro de i3, `Super+F1` muestra todos los atajos (`Super` es la tecla Windows).

### 5. Pasos opcionales, en este orden
| Comando | Para qué | Tamaño |
|---|---|---|
| `bash ~/mono-rice/scripts/build-i3lock-color.sh` | Pantalla de bloqueo con anillo y reloj (se compila una vez) | pequeño |
| `mono-pic sakura` | Cambia la chica de pixel art de `fastfetch` y la IA (`yuki`, `mizu`, `kuro` o tu PNG) | nada |
| `mono-apps` | LibreOffice, VSCodium, GIMP, OBS, Discord, Zoom, clientes de GOG y más | 6 a 10 GB |
| `mono-ai-setup` | IA local (Ollama + Qwen 2.5 7B). Se abre con `Super+I` | ~5 GB |
| `sudo apt install timeshift` | Copias del sistema para poder volver atrás | pequeño |
| `mono-secure` y luego `mono-secure --apply` | Revisa y refuerza la seguridad | pequeño |
| `mono-avatar --choices` | Elegir tu foto de usuario | pequeño |
| `mono-hibernate --apply` | Hacer que Hibernar funcione (crea el swap y configura el arranque). Requiere Secure Boot desactivado | ~RAM |
| `mono-boot --apply` | Menú de arranque y pantalla de inicio con tu pixel art (`--revert` lo deshace) | pequeño |
| `mono-apps games` | Clientes de GOG (Minigalaxy y Heroic) y herramientas de juegos | ~1 GB |

---

## Comandos

| Comando | Qué hace |
|---|---|
| `mono-update` | Actualiza el sistema con instantánea previa. Úsalo cada semana |
| `mono-guia` | Guía de uso, mantenimiento y solución de problemas. `mono-guia comandos` abre el **manual completo de comandos** |
| `mono-secure` | Estado de seguridad. `--apply` lo refuerza, `--audit` da un puntaje |
| `mono-ai` | Asistente de IA local con personalidad (`--serio` la apaga) |
| `mono-pic` | Pixel art para `fastfetch` y la IA. Con `--real` muestra tu imagen completa |
| `mono-wall` | Cambia el fondo (`mono` para blanco y negro, `color` para color) |
| `mono-lock` | Bloquea la pantalla |
| `mono-power` | Menú de apagado (bloquear, cerrar sesión, suspender, reiniciar, apagar). Si un botón falla: `mono-power --diag` |
| `mono-apps` | Instala aplicaciones por categorías (`office dev media graphics tools games`) |
| `mono-zoom` | Instala o actualiza Zoom |
| `mono-avatar` | Foto de usuario |
| `mono-scale 120` | Tamaño de todo (96 a 168) |
| `mono-touch` | Activa o desactiva la pantalla táctil |
| `mono-browser` | Firefox con el perfil del rice |
| `mono-slim` | Quita el escritorio XFCE una vez que i3 te funcione bien |
| `mono-clip` | Historial del portapapeles (`Super+V`). Lo copiado desde KeePassXC no se guarda |
| `mono-wifi` / `mono-bluetooth` | Menús de red y Bluetooth (clic en el WiFi y en el icono de Bluetooth de la barra). **Un solo clic elige** en todos los menús |
| `mono-cal` | Calendario en cuadrícula con clima; ◀ ▶ cambian de mes y «Hoy» vuelve al actual (clic en la hora). Ciudad en `~/.config/mono-rice/city` |
| `mono-ask` | Pregúntale a la IA sobre el texto seleccionado: explicar, traducir, resumir, corregir (`Super+Shift+I`) |
| `mono-pet` | La chica de pixel art animada: parpadea y respira. Salir con `q` |
| `mono-night` | Luz nocturna (`Super+N`). Ubicación en `~/.config/mono-rice/location` |
| `mono-battery` | Avisa cuando la batería baja de 20 %, 10 % y 5 % (`test` para verlos) |
| `mono-wall-auto 30` | Cambia el fondo solo cada 30 minutos (`off` lo apaga) |
| `mono-hibernate` | Prepara la hibernación (archivo swap + arranque). `--apply` la configura |
| `mono-boot` | Menú de arranque y pantalla de inicio en blanco y negro con pixel art. `--apply` y `--revert` |

El prefijo `mono-` es solo un nombre: son scripts de este repositorio (`scripts/`), enlazados en `/usr/local/bin` por `install.sh`.

### Atajos principales
`Super+Enter` terminal · `Super+Espacio` aplicaciones · `Super+Q` cerrar · `Super+1..9` escritorios · `Super+R` redimensionar ·
`Super+Esc` bloquear · `Super+Shift+P` apagado · `Super+I` IA · `Super+Shift+I` IA sobre lo seleccionado · `Super+V` portapapeles · `Super+N` luz nocturna · `Super+W` cambiar fondo · `Super+F1` lista completa.

---

## Cómo está organizado

```
install.sh        instalador principal
bootstrap.sh      atajo: instala git, clona e instala
config/           configuración (se enlaza en ~/.config): i3, polybar, picom, rofi, kitty, dunst, gtk-3.0
home/             .zshrc, .xprofile, .Xresources
scripts/          los comandos mono-* y sus ayudantes
browser/          perfil de Firefox (tema, extensiones, ajustes táctiles)
login/            tema de la pantalla de login
docs/GUIA.md      guía de mantenimiento
docs/COMANDOS.md  manual completo de comandos (archivos, seguridad, red, discos, Git, recuperación...)
```
Los archivos de `~/.config` son **enlaces** a este repositorio: editar uno edita el repositorio.

## Mantenerlo al día
```bash
mono-update                       # sistema + apps + esta configuración
cd ~/mono-rice && git pull        # solo la configuración
bash install.sh                   # reaplicar tras un git pull con cambios
WALLPAPERS=1 bash install.sh        # lo mismo, pero renovando también los wallpapers (normalmente no se vuelven a descargar)
```

## Problemas comunes
| Síntoma | Solución |
|---|---|
| `sudo: command not found` | Paso 2 de la instalación |
| Se detiene a mitad del instalador | Repite `bash install.sh`: continúa donde falló |
| No hay wallpapers | `scripts/fetch-wallpapers.sh 48`, luego `mono-wall` |
| La barra se ve mal tras actualizar | `Super+Shift+R` |
| Pantalla negra al iniciar sesión | `Ctrl+Alt+F3`, entra a la terminal y mira `mono-guia` (sección "Si algo se rompe") |
| Picom da problemas (VM o GPU vieja) | En `config/picom/picom.conf`, cambia `backend = "glx"` por `"xrender"` |
| El WiFi de la bandeja se cerraba solo | Ya no se usa `nm-applet`: haz clic en el WiFi de la barra (`mono-wifi`), que se queda abierto |
| La batería no aparece en la barra | Se detecta sola; revisa `ls /sys/class/power_supply` |

## Imágenes y créditos
Los wallpapers **no están en el repositorio** (son de sus autores): se descargan de wallhaven.cc para uso personal.
El pixel art de `sakura`, `yuki`, `mizu` y `kuro` está dibujado por código en `scripts/pixelart.py`.
