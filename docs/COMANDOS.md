# Manual de comandos: manejar tu distro completa

Referencia para administrar Debian 13 desde la terminal, de lo básico a la seguridad. Se abre con `mono-guia comandos`.

**Cómo leerlo**
- Los comandos van en bloques de código. **No escribas el `$`** si aparece al inicio.
- Lo que va en MAYÚSCULAS o entre `<…>` lo cambias por tu valor (`ARCHIVO`, `<nombre>`).
- ⚠ marca lo que puede **borrar datos, dejar el sistema sin arrancar o abrirlo a otras personas**. Los demás comandos solo leen o se pueden deshacer.
- `sudo` ejecuta como administrador. Úsalo solo cuando haga falta, y entendiendo qué hace el comando.
- Casi todos aceptan `--help` (ayuda corta) y tienen manual con `man COMANDO` (sal con `q`).
- Pulsa `Tab` para autocompletar nombres y rutas: ahorra errores.

**Herramientas que conviene tener instaladas** (varias aparecen más abajo):
```bash
sudo apt install tree ncdu ripgrep fd-find plocate psmisc bind9-dnsutils traceroute mtr-tiny \
  inxi smartmontools lm-sensors debsums rsync restic tmux htop exfatprogs ntfs-3g timeshift
```

## Índice
1. [Moverte y ver archivos](#1-moverte-y-ver-archivos)
2. [Crear, copiar, mover y borrar](#2-crear-copiar-mover-y-borrar)
3. [Buscar archivos y texto](#3-buscar-archivos-y-texto)
4. [Editar y modificar archivos](#4-editar-y-modificar-archivos)
5. [Permisos, dueños y usuarios](#5-permisos-dueños-y-usuarios)
6. [Comprimir y respaldar](#6-comprimir-y-respaldar)
7. [Paquetes: apt, dpkg y Flatpak](#7-paquetes-apt-dpkg-y-flatpak)
8. [Procesos y recursos](#8-procesos-y-recursos)
9. [Servicios y registros (systemd)](#9-servicios-y-registros-systemd)
10. [Red y WiFi](#10-red-y-wifi)
11. [Discos, memoria y USB](#11-discos-memoria-y-usb)
12. [Hardware, batería, pantalla y sonido](#12-hardware-batería-pantalla-y-sonido)
13. [Seguridad](#13-seguridad)
14. [Git](#14-git)
15. [Mantenimiento y recuperación](#15-mantenimiento-y-recuperación)
16. [Tus comandos `mono-*`](#16-tus-comandos-mono-)
17. [i3: atajos y comandos](#17-i3-atajos-y-comandos)
18. [Editores y atajos de la terminal](#18-editores-y-atajos-de-la-terminal)
19. [Scripts y tareas programadas](#19-scripts-y-tareas-programadas)
20. [Dónde está cada cosa](#20-dónde-está-cada-cosa)
21. ["Quiero hacer X": respuestas rápidas](#21-quiero-hacer-x-respuestas-rápidas)
22. [Reglas de oro y comandos peligrosos](#22-reglas-de-oro-y-comandos-peligrosos)

---

## 1. Moverte y ver archivos

| Comando | Qué hace |
|---|---|
| `pwd` | Muestra en qué carpeta estás |
| `ls` | Lista el contenido (en tu terminal usa `eza` con iconos) |
| `ls -la` | Lista todo, con archivos ocultos (los que empiezan con `.`), permisos y tamaños |
| `ll` / `la` | Atajos tuyos para lista larga / lista larga con ocultos |
| `cd CARPETA` | Entra a una carpeta |
| `cd ..` | Sube un nivel (también `..`) |
| `cd -` | Vuelve a la carpeta anterior |
| `cd` o `cd ~` | Va a tu carpeta personal |
| `tree -L 2` | Muestra el árbol de carpetas, hasta 2 niveles |
| `cat ARCHIVO` | Muestra el contenido de un archivo corto (en tu terminal usa `bat`) |
| `less ARCHIVO` | Lee un archivo largo página a página (`q` sale, `/texto` busca, `Espacio` avanza) |
| `head -n 20 ARCHIVO` | Primeras 20 líneas |
| `tail -n 20 ARCHIVO` | Últimas 20 líneas |
| `tail -f ARCHIVO` | Sigue un archivo en vivo (ideal para registros). `Ctrl+C` para salir |
| `file ARCHIVO` | Dice qué tipo de archivo es |
| `stat ARCHIVO` | Tamaño, permisos, dueño y fechas exactas |
| `wc -l ARCHIVO` | Cuenta líneas (`-w` palabras, `-c` bytes) |
| `xdg-open ARCHIVO` | Abre un archivo con su programa predeterminado |
| `clear` o `Ctrl+L` | Limpia la pantalla |
| `history` | Historial de comandos (con `Ctrl+R` lo buscas) |

## 2. Crear, copiar, mover y borrar

| Comando | Qué hace |
|---|---|
| `mkdir CARPETA` | Crea una carpeta |
| `mkdir -p a/b/c` | Crea toda la ruta de golpe |
| `touch ARCHIVO` | Crea un archivo vacío (o actualiza su fecha) |
| `cp ORIGEN DESTINO` | Copia un archivo |
| `cp -r CARPETA DESTINO` | Copia una carpeta con todo lo que tiene |
| `cp -i …` | Pregunta antes de sobrescribir |
| `cp -a ORIGEN DESTINO` | Copia conservando permisos, fechas y enlaces (para respaldos) |
| `mv ORIGEN DESTINO` | Mueve **o renombra** (`mv viejo.txt nuevo.txt`) |
| `mv -i …` | Pregunta antes de sobrescribir |
| `rm ARCHIVO` | ⚠ Borra un archivo **sin papelera**: no se recupera |
| `rm -i ARCHIVO` | Pregunta antes de borrar |
| `rm -r CARPETA` | ⚠ Borra una carpeta y todo lo que contiene |
| `rm -rf CARPETA` | ⚠⚠ Igual, sin preguntar ni avisar de errores. Revisa la ruta **dos veces** |
| `rmdir CARPETA` | Borra una carpeta **solo si está vacía** (más seguro) |
| `gio trash ARCHIVO` | Manda a la papelera (recuperable desde Thunar) |
| `ln -s ORIGEN ENLACE` | Crea un enlace simbólico (un acceso directo) |
| `readlink -f ENLACE` | Muestra a dónde apunta realmente un enlace |
| `shred -u ARCHIVO` | ⚠ Sobrescribe y borra. **No es fiable en SSD ni en discos con registro**; para eso, cifra el disco |

**Hábito seguro antes de borrar:** primero `ls` con la misma ruta, para ver exactamente qué vas a borrar.

## 3. Buscar archivos y texto

| Comando | Qué hace |
|---|---|
| `find ~ -name "*.pdf"` | Busca por nombre desde tu carpeta personal |
| `find . -iname "*foto*"` | Igual, ignorando mayúsculas |
| `find . -type d -name node_modules` | Solo carpetas |
| `find . -type f -size +100M` | Archivos de más de 100 MB |
| `find . -mtime -1` | Modificados en las últimas 24 horas |
| `find . -name "*.tmp" -delete` | ⚠ Busca y **borra**. Antes ejecútalo sin `-delete` para ver la lista |
| `fdfind NOMBRE` | Búsqueda rápida por nombre (paquete `fd-find`) |
| `locate NOMBRE` | Búsqueda instantánea en un índice (paquete `plocate`; actualízalo con `sudo updatedb`) |
| `grep -rn "texto" CARPETA` | Busca texto dentro de los archivos, con número de línea |
| `grep -rni "texto" .` | Igual, ignorando mayúsculas |
| `grep -v "texto"` | Muestra las líneas que **no** lo contienen |
| `rg "texto"` | Como `grep -r` pero mucho más rápido (paquete `ripgrep`) |
| `which COMANDO` | Dónde está el programa de un comando |
| `type COMANDO` | Si es un programa, un alias o una función |
| `du -sh CARPETA` | Cuánto pesa una carpeta |
| `du -h --max-depth=1 ~ \| sort -h` | Qué carpetas ocupan más en tu carpeta personal |
| `ncdu ~` | Explorador interactivo del uso de disco (`q` sale) |

## 4. Editar y modificar archivos

### Con la terminal, sin editor
| Comando | Qué hace |
|---|---|
| `echo "texto" > ARCHIVO` | ⚠ Escribe el texto y **reemplaza todo** el archivo |
| `echo "texto" >> ARCHIVO` | Añade el texto al final, sin borrar lo anterior |
| `cmd > salida.txt` | Guarda en un archivo lo que imprime un comando |
| `cmd >> salida.txt` | Lo añade al final |
| `cmd 2> errores.txt` | Guarda solo los mensajes de error |
| `cmd1 \| cmd2` | Pasa la salida del primero como entrada del segundo (tubería) |
| `cmd \| tee ARCHIVO` | Muestra la salida **y** la guarda |
| `echo "x" \| sudo tee -a /etc/ARCHIVO` | Añade una línea a un archivo del sistema (con permisos) |
| `sed -i.bak 's/viejo/nuevo/g' ARCHIVO` | Reemplaza texto en el archivo y deja la copia `ARCHIVO.bak` |
| `sed -n '10,20p' ARCHIVO` | Muestra solo las líneas 10 a 20 |
| `sed -i '5d' ARCHIVO` | ⚠ Borra la línea 5 |
| `awk '{print $1}' ARCHIVO` | Imprime la primera columna |
| `cut -d: -f1 /etc/passwd` | Toma el campo 1 usando `:` como separador |
| `sort ARCHIVO` / `sort -u` | Ordena / ordena sin repetidos |
| `sort \| uniq -c \| sort -nr` | Cuenta repeticiones y ordena de más a menos |
| `diff -u A B` | Muestra las diferencias entre dos archivos |
| `column -t` | Alinea en columnas |

Un archivo de varias líneas, de golpe:
```bash
cat > ARCHIVO <<'EOF'
primera línea
segunda línea
EOF
```

### Con un editor
| Editor | Cómo abrirlo | Notas |
|---|---|---|
| nano (el más sencillo) | `nano ARCHIVO` | Los atajos salen abajo en pantalla |
| Neovim | `nvim ARCHIVO` | Potente; ver la sección 18 |
| VSCodium | `flatpak run com.vscodium.codium ARCHIVO` | Editor gráfico |

### Editar archivos del sistema (`/etc/...`)
**Siempre haz copia antes**, y usa el editor seguro:
```bash
sudo cp /etc/ARCHIVO /etc/ARCHIVO.bak       # copia de seguridad
sudoedit /etc/ARCHIVO                        # edita con tu editor, sin ejecutar el editor como root
sudo visudo                                  # ÚNICA forma segura de editar permisos de sudo (valida la sintaxis)
```
Para usar nano como editor por defecto: `export EDITOR=nano` (para que sea permanente, agrégalo a `~/.zshrc`).

Si te equivocas, restauras: `sudo cp /etc/ARCHIVO.bak /etc/ARCHIVO`.

**Cambios en tu configuración del escritorio:** edita los archivos de `~/mono-rice/config/` (los de `~/.config` son enlaces a esa carpeta). Luego guarda tus cambios con Git (sección 14) y recarga con `Super+Shift+R`.

## 5. Permisos, dueños y usuarios

### Leer los permisos
`ls -l` muestra algo como `-rwxr-xr-- 1 sachiret sachiret 1234 nov 8 archivo`:
- El primer carácter: `-` archivo, `d` carpeta, `l` enlace.
- Luego tres grupos de tres: **dueño**, **grupo**, **otros**; en cada uno `r` leer, `w` escribir, `x` ejecutar.
- Números: `r=4`, `w=2`, `x=1`. Se suman: `rwx=7`, `r-x=5`, `r--=4`.

| Comando | Qué hace |
|---|---|
| `chmod 644 ARCHIVO` | Dueño lee y escribe; los demás solo leen (típico para archivos) |
| `chmod 755 ARCHIVO` | Dueño todo; los demás leen y ejecutan (típico para programas y carpetas) |
| `chmod 600 ARCHIVO` | Solo el dueño lee y escribe (claves, contraseñas) |
| `chmod 700 CARPETA` | Solo el dueño puede entrar (`~/.ssh`) |
| `chmod +x ARCHIVO` | Hace un archivo ejecutable |
| `chmod u+rwx,go-rwx ARCHIVO` | Forma simbólica: el dueño todo, grupo y otros nada |
| `chmod -R 755 CARPETA` | Aplica a todo el contenido (⚠ con cuidado) |
| `chmod -R 777 …` | ⚠⚠ **Nunca**: da permiso total a cualquiera |
| `sudo chown USUARIO:GRUPO ARCHIVO` | Cambia el dueño |
| `sudo chown -R $USER:$USER CARPETA` | Devuelve una carpeta a tu usuario (útil si quedó de `root`) |
| `umask` | Muestra los permisos por defecto de los archivos nuevos (`0022` es lo normal) |

### Usuarios y grupos
| Comando | Qué hace |
|---|---|
| `whoami` | Tu usuario |
| `id` | Tu usuario, grupos y números |
| `groups` | Tus grupos |
| `who` / `w` | Quién está conectado ahora |
| `last -n 10` | Últimos inicios de sesión |
| `sudo -l` | Qué puedes ejecutar con `sudo` |
| `passwd` | Cambia **tu** contraseña |
| `sudo passwd USUARIO` | Cambia la contraseña de otro usuario |
| `sudo adduser NOMBRE` | Crea un usuario |
| `sudo usermod -aG GRUPO USUARIO` | Añade un usuario a un grupo (la `-a` es importante: sin ella lo **saca** de los demás) |
| `sudo deluser NOMBRE` | Borra un usuario (mantiene su carpeta) |
| `sudo deluser --remove-home NOMBRE` | ⚠ Lo borra con su carpeta personal |
| `sudo passwd -l USUARIO` / `-u` | Bloquea / desbloquea una cuenta |
| `sudo chage -l USUARIO` | Ver caducidad de la contraseña |
| `su - USUARIO` | Cambia a otro usuario |

## 6. Comprimir y respaldar

| Comando | Qué hace |
|---|---|
| `tar -czf copia.tar.gz CARPETA/` | Crea un archivo comprimido |
| `tar -tf copia.tar.gz` | Lista el contenido sin extraer |
| `tar -xzf copia.tar.gz` | Extrae en la carpeta actual |
| `tar -xzf copia.tar.gz -C DESTINO` | Extrae en otra carpeta |
| `tar -xf archivo.tar.xz` | Extrae `.xz`, `.bz2` y otros (detecta el formato) |
| `zip -r copia.zip CARPETA` | Crea un `.zip` |
| `unzip -l archivo.zip` | Lista el contenido (**revísalo antes de extraer** si no confías en el origen) |
| `unzip archivo.zip -d DESTINO` | Extrae en una carpeta nueva |
| `7z a -p -mhe=on copia.7z CARPETA` | `.7z` **cifrado** con contraseña (también oculta los nombres) |
| `7z x copia.7z` | Extrae un `.7z` |
| `gzip ARCHIVO` / `gunzip ARCHIVO.gz` | Comprime / descomprime un solo archivo |

### Copias con `rsync` (sincronizar carpetas)
```bash
rsync -aAXv --dry-run ~/Documentos/ /media/$USER/DISCO/Documentos/   # SIMULA: muestra qué haría
rsync -aAXv ~/Documentos/ /media/$USER/DISCO/Documentos/              # lo hace
rsync -aAXv --delete ORIGEN/ DESTINO/                                  # ⚠ también BORRA en el destino lo que ya no está en el origen
```
Importante: la `/` final en `ORIGEN/` significa "el contenido"; sin ella copia la carpeta entera.

### Copias cifradas y con historial: `restic`
```bash
restic init --repo /media/$USER/DISCO/respaldo          # crear el repositorio (te pide una contraseña: GUÁRDALA)
restic -r /media/$USER/DISCO/respaldo backup ~/Documentos ~/Proyectos
restic -r /media/$USER/DISCO/respaldo snapshots          # lista de copias
restic -r /media/$USER/DISCO/respaldo restore latest --target /tmp/recuperado
restic -r /media/$USER/DISCO/respaldo forget --keep-daily 7 --keep-weekly 4 --prune   # limpiar copias viejas
```

## 7. Paquetes: apt, dpkg y Flatpak

### apt (el instalador de Debian)
| Comando | Qué hace |
|---|---|
| `sudo apt update` | Actualiza la **lista** de paquetes disponibles (no instala nada) |
| `apt list --upgradable` | Ver qué se puede actualizar |
| `sudo apt full-upgrade` | Actualiza todo (puede instalar o quitar paquetes si hace falta; lee la lista) |
| `sudo apt install PAQUETE` | Instala |
| `sudo apt install --reinstall PAQUETE` | Reinstala (arregla archivos dañados del paquete) |
| `sudo apt remove PAQUETE` | Desinstala (conserva la configuración) |
| `sudo apt purge PAQUETE` | Desinstala **y** borra su configuración |
| `sudo apt autoremove` | Quita paquetes que ya nadie necesita (lee la lista) |
| `sudo apt clean` | Borra los archivos descargados de instalaciones |
| `apt search PALABRA` | Busca paquetes |
| `apt show PAQUETE` | Información del paquete |
| `apt policy PAQUETE` | Versión instalada, disponible y de qué repositorio |
| `apt list --installed` | Lo instalado |
| `apt depends PAQUETE` / `apt rdepends PAQUETE` | De qué depende / quién depende de él |
| `sudo apt install PAQUETE=VERSION` | Instala una versión concreta (volver atrás) |
| `sudo apt-mark hold PAQUETE` | Impide que se actualice (`unhold` lo libera) |
| `sudo apt-mark showmanual` | Lo que instalaste tú (no por dependencia) |
| `sudo apt -s install PAQUETE` | **Simula**: muestra qué haría sin hacer nada |
| `sudo apt --fix-broken install` | Arregla dependencias rotas |
| `sudo apt install ./archivo.deb` | Instala un `.deb` descargado |

### dpkg (por debajo de apt)
| Comando | Qué hace |
|---|---|
| `dpkg -l \| grep NOMBRE` | ¿Está instalado? |
| `dpkg -L PAQUETE` | Qué archivos instaló |
| `dpkg -S /ruta/archivo` | A qué paquete pertenece un archivo |
| `sudo dpkg --configure -a` | Termina instalaciones que quedaron a medias |
| `sudo dpkg-reconfigure PAQUETE` | Repite las preguntas de configuración (ej.: `locales`, `keyboard-configuration`) |

### Repositorios
- Archivos: `/etc/apt/sources.list` y `/etc/apt/sources.list.d/*.sources`.
- **No agregues repositorios que no conozcas**, ni de otras versiones de Debian (`testing`, `unstable`): es la causa más común de sistemas rotos.
- Al cambiar un repositorio: `sudo apt update`.

### Flatpak (apps aisladas, tomadas de Flathub)
| Comando | Qué hace |
|---|---|
| `flatpak list --user` | Lo instalado |
| `flatpak install --user flathub ID` | Instala (ej.: `com.discordapp.Discord`) |
| `flatpak run ID` | Ejecuta |
| `flatpak update --user -y` | Actualiza todo |
| `flatpak uninstall --user ID` | Desinstala |
| `flatpak uninstall --user --unused` | Quita runtimes que ya no se usan |
| `flatpak info ID` | Datos de una app |
| `flatpak repair --user` | Repara instalaciones dañadas |
| `flatpak override --user --nofilesystem=home ID` | Quita a una app el acceso a tu carpeta personal |

### Python y otros
- **No uses `sudo pip install`.** Crea un entorno aislado: `python3 -m venv ~/venvs/mi && source ~/venvs/mi/bin/activate`, y sales con `deactivate`.
- Programas de Python como herramientas: `pipx install PAQUETE`.
- AppImage: `chmod +x archivo.AppImage && ./archivo.AppImage`.

## 8. Procesos y recursos

| Comando | Qué hace |
|---|---|
| `btop` | Monitor completo y bonito (`q` sale; `f` filtra; `k` mata un proceso) |
| `htop` | Monitor más sencillo |
| `ps aux` | Todos los procesos |
| `ps aux --sort=-%mem \| head` | Los 10 que más memoria usan |
| `ps aux --sort=-%cpu \| head` | Los 10 que más procesador usan |
| `pgrep -a NOMBRE` | Busca procesos por nombre y muestra su número (PID) |
| `kill PID` | Pide a un proceso que termine (forma educada) |
| `kill -9 PID` | ⚠ Lo mata a la fuerza (último recurso; pierde lo no guardado) |
| `pkill NOMBRE` | Termina procesos por nombre |
| `killall NOMBRE` | Igual (requiere `sudo apt install psmisc`) |
| `xkill` | Haz clic en una ventana congelada para cerrarla |
| `free -h` | Memoria RAM y swap |
| `uptime` | Cuánto lleva encendido y la carga reciente |
| `lscpu` | Datos del procesador |
| `nproc` | Cuántos núcleos |
| `vmstat 2` | Actividad del sistema cada 2 segundos |
| `nice -n 10 COMANDO` | Ejecuta con menos prioridad |
| `renice 10 -p PID` | Cambia la prioridad de uno en marcha |

**Segundo plano en la terminal**
| Comando | Qué hace |
|---|---|
| `COMANDO &` | Lo ejecuta en segundo plano |
| `Ctrl+Z` | Pausa el programa actual |
| `bg` / `fg` | Lo manda al fondo / lo trae al frente |
| `jobs` | Lista lo que tienes en segundo plano |
| `nohup COMANDO &` | Sigue funcionando aunque cierres la terminal |
| `setsid COMANDO` | Lo separa por completo de la terminal |
| `tmux` | Sesiones que sobreviven aunque cierres la ventana (`Ctrl+B` luego `d` para salir sin cerrar; `tmux attach` para volver) |

## 9. Servicios y registros (systemd)

### Servicios
| Comando | Qué hace |
|---|---|
| `systemctl status NOMBRE` | Estado y últimas líneas del servicio |
| `systemctl is-active NOMBRE` | `active` / `inactive` |
| `sudo systemctl start NOMBRE` | Lo inicia ahora |
| `sudo systemctl stop NOMBRE` | Lo detiene ahora |
| `sudo systemctl restart NOMBRE` | Lo reinicia |
| `sudo systemctl reload NOMBRE` | Recarga su configuración sin cortarlo |
| `sudo systemctl enable NOMBRE` | Que arranque con el sistema |
| `sudo systemctl enable --now NOMBRE` | Habilitarlo y arrancarlo ya |
| `sudo systemctl disable --now NOMBRE` | Que no arranque, y detenerlo |
| `sudo systemctl mask NOMBRE` | Bloquea el servicio por completo (nadie puede iniciarlo) |
| `systemctl list-units --type=service --state=running` | Servicios activos |
| `systemctl --failed` | **Servicios que fallaron** (mírala después de cada arranque raro) |
| `systemctl list-timers` | Tareas programadas del sistema |
| `systemctl cat NOMBRE` | Ver su archivo de configuración |
| `sudo systemctl edit NOMBRE` | Cambiar su configuración sin tocar el archivo original |
| `sudo systemctl daemon-reload` | Recargar tras editar archivos de servicio |
| `systemctl --user status NOMBRE` | Lo mismo para servicios de **tu** usuario |
| `systemd-analyze` | Cuánto tardó en arrancar |
| `systemd-analyze blame` | Qué servicios tardaron más |

### Registros (journal)
| Comando | Qué hace |
|---|---|
| `journalctl -b` | Todo lo del arranque actual |
| `journalctl -b -1` | Lo del arranque anterior (útil si se colgó) |
| `journalctl -p err -b` | Solo errores del arranque actual |
| `journalctl -xe` | Lo último, con explicaciones |
| `journalctl -u NOMBRE -f` | Sigue en vivo los registros de un servicio |
| `journalctl --since "1 hour ago"` | De la última hora (`"today"`, `"2026-11-08 10:00"`) |
| `journalctl _COMM=sudo` | Quién ejecutó `sudo` y qué |
| `journalctl -k` | Mensajes del kernel (como `dmesg`) |
| `dmesg --level=err,warn` | Errores y avisos del kernel y el hardware |
| `journalctl --disk-usage` | Cuánto espacio ocupan los registros |
| `sudo journalctl --vacuum-time=14d` | Borra los registros de más de 14 días |
| `sudo journalctl --vacuum-size=500M` | Los reduce a 500 MB |

Otros: `/var/log/apt/history.log` (qué instaló o quitó apt y cuándo), `/var/log/Xorg.0.log`.

## 10. Red y WiFi

### Ver el estado
| Comando | Qué hace |
|---|---|
| `ip -br a` | Interfaces y direcciones IP (resumen) |
| `ip route` | Ruta por defecto (tu router) |
| `ping -c 4 debian.org` | Prueba conexión **y** DNS |
| `ping -c 4 1.1.1.1` | Prueba conexión sin depender del DNS |
| `curl -I https://debian.org` | Prueba que la web responde |
| `curl ifconfig.me` | Tu IP pública (ese sitio la ve) |
| `cat /etc/resolv.conf` | Qué DNS usas |
| `dig +short debian.org` | Consulta DNS (paquete `bind9-dnsutils`) |
| `traceroute debian.org` / `mtr debian.org` | Por dónde pasa tu conexión |
| `hostname` / `hostnamectl` | Nombre del equipo |
| `sudo ss -tulpn` | **Qué programas escuchan conexiones** (puertos abiertos) |
| `sudo lsof -i -P -n` | Conexiones de red por programa |

### NetworkManager (`nmcli`)
| Comando | Qué hace |
|---|---|
| `nmcli device status` | Estado de cada interfaz |
| `nmcli dev wifi list` | Redes WiFi visibles |
| `nmcli dev wifi connect "RED" password "CLAVE"` | Conectar (la clave queda en tu historial: bórrala con `history -d`) |
| `nmcli connection show` | Conexiones guardadas |
| `nmcli connection up id "RED"` / `down id "RED"` | Conectar / desconectar una guardada |
| `nmcli connection delete id "RED"` | ⚠ Olvidar una red |
| `nmcli radio wifi off` / `on` | Apagar / encender el WiFi |
| `nmtui` | Menú de texto para todo lo anterior |
| `rfkill list` | ¿Hay WiFi o Bluetooth bloqueado por hardware o software? |
| `sudo rfkill unblock all` | Desbloquearlos |

Con el escritorio: clic en el WiFi de la barra (`mono-wifi`) y en el icono de Bluetooth (`mono-bluetooth`).

### Bluetooth por terminal
```bash
bluetoothctl            # entra a su consola; dentro:
power on                # encender
scan on                 # buscar (copia la dirección MAC del aparato)
pair AA:BB:CC:DD:EE:FF
trust AA:BB:CC:DD:EE:FF
connect AA:BB:CC:DD:EE:FF
devices                 # lista de aparatos
exit
```

### Descargar
| Comando | Qué hace |
|---|---|
| `wget URL` | Descarga un archivo |
| `wget -c URL` | Reanuda una descarga cortada |
| `curl -LO URL` | Descarga siguiendo redirecciones, con el nombre original |
| `scp ARCHIVO usuario@host:/ruta` | Copia por SSH a otro equipo |

## 11. Discos, memoria y USB

| Comando | Qué hace |
|---|---|
| `lsblk -f` | Discos, particiones, sistema de archivos y dónde están montadas |
| `df -h` | Espacio libre por partición |
| `df -h /` | Solo el disco principal |
| `sudo blkid` | UUID de cada partición |
| `sudo fdisk -l` | Tabla de particiones (solo lectura) |
| `mount \| grep sd` | Qué está montado |
| `swapon --show` | Swap activo (importante para hibernar) |
| `free -h` | RAM y swap |
| `sudo smartctl -H /dev/nvme0` | Salud del disco (`/dev/sda` si es SATA; paquete `smartmontools`) |
| `sudo smartctl -a /dev/nvme0` | Informe completo de salud |

### USB y discos externos
```bash
lsblk -f                                  # identifica el USB (mira su tamaño y nombre, ej. sdb1)
udisksctl mount -b /dev/sdb1              # montar sin sudo (queda en /media/$USER/...)
udisksctl unmount -b /dev/sdb1            # desmontar
udisksctl power-off -b /dev/sdb           # apagarlo para sacarlo con seguridad
sync                                      # fuerza a escribir lo pendiente
```
**Siempre desmonta antes de sacar el USB**, o pierdes datos.

### ⚠ Comandos que destruyen datos (confirma el dispositivo con `lsblk` antes)
| Comando | Qué hace |
|---|---|
| `sudo mkfs.ext4 -L NOMBRE /dev/sdX1` | ⚠ Formatea la partición en ext4 (borra todo) |
| `sudo mkfs.exfat -L NOMBRE /dev/sdX1` | ⚠ Formatea en exFAT (compatible con Windows y Linux) |
| `sudo mkfs.vfat -F 32 /dev/sdX1` | ⚠ Formatea en FAT32 |
| `sudo dd if=ARCHIVO.iso of=/dev/sdX bs=4M status=progress conv=fsync` | ⚠⚠ Graba una ISO en un USB. **Si te equivocas de `sdX` borras otro disco** |
| `sudo fsck -f /dev/sdXn` | Repara un sistema de archivos. **Solo si está desmontado** |
| `gparted` | Programa gráfico de particiones (ejecútalo con cuidado) |

### Montar de forma permanente
Edita `/etc/fstab` (con `sudoedit` y copia antes). Una línea típica:
```
UUID=1234-ABCD  /mnt/datos  ext4  defaults,nofail  0  2
```
`nofail` evita que un disco ausente impida arrancar. Pruébalo con `sudo mount -a` **antes de reiniciar**.

## 12. Hardware, batería, pantalla y sonido

### Información
| Comando | Qué hace |
|---|---|
| `inxi -Fxz` | Resumen completo del equipo (paquete `inxi`) |
| `fastfetch` | Resumen vistoso |
| `uname -a` / `uname -r` | Kernel |
| `lspci -k` | Dispositivos PCI y el controlador que usa cada uno |
| `lsusb` | Dispositivos USB |
| `sudo dmidecode -t system` | Modelo del equipo (también `-t bios`, `-t memory`) |
| `lsmod` | Módulos del kernel cargados |
| `sensors` | Temperaturas (`sudo sensors-detect` la primera vez; paquete `lm-sensors`) |
| `cat /etc/os-release` | Versión de Debian |

### Batería
```bash
upower -i $(upower -e | grep BAT)         # estado y salud (mira "capacity": 80 % o más es buena)
cat /sys/class/power_supply/BAT*/capacity  # porcentaje actual
```

### Pantalla
| Comando | Qué hace |
|---|---|
| `xrandr` | Pantallas conectadas y resoluciones |
| `xrandr --output eDP-1 --mode 1920x1080` | Fija la resolución (el nombre `eDP-1` lo ves en `xrandr`) |
| `xrandr --output HDMI-1 --auto --right-of eDP-1` | Enciende un monitor externo a la derecha |
| `xrandr --output HDMI-1 --off` | Lo apaga |
| `brightnessctl set 50%` / `+10%` / `10%-` | Brillo |
| `mono-scale 120` | Tamaño de todo (96 a 168) |
| `xprop` | Haz clic en una ventana: muestra su clase (útil para reglas de i3) |

### Sonido (PipeWire)
| Comando | Qué hace |
|---|---|
| `wpctl status` | Dispositivos de audio |
| `wpctl set-volume @DEFAULT_AUDIO_SINK@ 50%` | Volumen |
| `wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle` | Silenciar / activar |
| `pactl set-sink-volume @DEFAULT_SINK@ +5%` | Lo mismo con `pactl` (el que usan tus teclas) |
| `pactl list short sinks` | Salidas disponibles |
| `pactl set-default-sink NOMBRE` | Cambiar la salida |
| `pavucontrol` | Mezclador gráfico (volumen por aplicación) |

### Hora, teclado e idioma
| Comando | Qué hace |
|---|---|
| `timedatectl` | Hora, zona y si está sincronizada |
| `timedatectl list-timezones \| grep Santo` | Buscar una zona |
| `sudo timedatectl set-timezone America/Santo_Domingo` | Fijar zona |
| `sudo timedatectl set-ntp true` | Sincronizar la hora por internet |
| `setxkbmap -layout latam` | Teclado latinoamericano (temporal) |
| `sudo localectl set-x11-keymap latam` | Teclado permanente |
| `locale` | Idioma actual |
| `sudo dpkg-reconfigure locales` | Cambiar idioma |
| `sudo hostnamectl set-hostname NOMBRE` | Cambiar el nombre del equipo |

### Firmware
```bash
fwupdmgr refresh && fwupdmgr get-updates    # busca actualizaciones de firmware (BIOS, SSD...)
fwupdmgr update                              # las instala (con el equipo conectado a corriente)
```

### Energía
| Comando | Qué hace |
|---|---|
| `systemctl suspend` | Suspender |
| `systemctl hibernate` | Hibernar (requiere `mono-hibernate --apply`) |
| `systemctl reboot` / `poweroff` | Reiniciar / apagar |
| `mono-power` (`Super+Shift+P`) | Menú gráfico con todo lo anterior |

## 13. Seguridad

La seguridad es una suma de capas: **ninguna sola basta**. Aquí van los comandos para revisar y aplicar cada una.

### 13.1 Revisión rápida con tus herramientas
```bash
mono-secure             # estado: cortafuegos, actualizaciones, cifrado, AppArmor, SSH, puertos...
mono-secure --apply     # aplica el refuerzo (muestra el plan y pide escribir SI)
mono-secure --audit     # puntaje de seguridad con Lynis
```

### 13.2 Cortafuegos (ufw)
| Comando | Qué hace |
|---|---|
| `sudo ufw status verbose` | Estado y reglas |
| `sudo ufw status numbered` | Reglas numeradas |
| `sudo ufw enable` / `disable` | Encender / apagar |
| `sudo ufw default deny incoming` | Bloquear todo lo entrante por defecto |
| `sudo ufw default allow outgoing` | Dejar salir todo |
| `sudo ufw allow 3000/tcp` | Permitir un puerto (ej.: probar tu app desde el teléfono) |
| `sudo ufw allow from 192.168.1.0/24 to any port 3000 proto tcp` | Permitir un puerto **solo** desde tu red local |
| `sudo ufw limit ssh` | Permitir SSH con límite de intentos |
| `sudo ufw delete allow 3000/tcp` | Quitar esa regla |
| `sudo ufw delete 2` | Quitar la regla número 2 de la lista numerada |
| `sudo ufw logging on` | Registrar bloqueos (`journalctl -k \| grep UFW`) |
| `sudo ufw reset` | ⚠ Borra todas las reglas |

**Tus servidores de desarrollo** (por ejemplo en el puerto 3000) funcionan desde el mismo equipo (`localhost`) aunque el cortafuegos esté activo. Solo bloquea que **otros dispositivos** entren.

### 13.3 ¿Qué está abierto y quién se conecta?
```bash
sudo ss -tulpn                    # programas que escuchan (si algo escucha en 0.0.0.0, está abierto a la red)
sudo lsof -i -P -n | grep ESTAB   # conexiones establecidas ahora mismo
last -n 20                        # inicios de sesión recientes
sudo lastb | head                 # intentos de inicio de sesión fallidos
journalctl _COMM=sudo --since today   # lo que se ejecutó con sudo hoy
```

### 13.4 Actualizaciones de seguridad
```bash
sudo apt update && apt list --upgradable            # ver pendientes
sudo apt full-upgrade                                # aplicar (o usa mono-update)
systemctl status unattended-upgrades                 # actualizaciones automáticas de seguridad
sudo unattended-upgrade --dry-run -d | tail          # probar sin instalar
cat /var/log/unattended-upgrades/unattended-upgrades.log   # qué instaló solo
```
Tras actualizar el kernel, **reinicia** para usarlo.

### 13.5 Cuentas y contraseñas
| Comando | Qué hace |
|---|---|
| `passwd` | Cambiar tu contraseña (usa una larga y única) |
| `sudo passwd -l root` | Bloquear la contraseña de root (⚠ el modo de recuperación necesitará el método de la sección 15) |
| `sudo chage -l USUARIO` | Ver caducidad |
| `sudo -l` | Ver lo que tu usuario puede hacer con sudo |
| `getent group sudo` | Quién tiene permisos de sudo |
| `keepassxc` | Tu gestor de contraseñas (guarda ahí todas las demás) |

### 13.6 Cifrado de archivos y claves
| Comando | Qué hace |
|---|---|
| `gpg -c ARCHIVO` | Cifra un archivo con contraseña (crea `ARCHIVO.gpg`) |
| `gpg ARCHIVO.gpg` | Lo descifra |
| `gpg --full-generate-key` | Crea un par de claves |
| `gpg --list-keys` | Lista tus claves |
| `gpg --encrypt -r CORREO ARCHIVO` | Cifra para otra persona |
| `7z a -p -mhe=on seguro.7z CARPETA` | Carpeta completa en un `.7z` cifrado |
| `ssh-keygen -t ed25519 -C "tu@correo"` | Crea una clave SSH moderna |
| `ssh-copy-id usuario@servidor` | Instala tu clave pública en un servidor |
| `chmod 700 ~/.ssh && chmod 600 ~/.ssh/id_ed25519` | Permisos correctos de las claves (si no, SSH las rechaza) |

**Cifrado de todo el disco (LUKS):** solo se activa al **instalar** el sistema; no se puede añadir después sin reinstalar. Para ver si lo tienes: `lsblk -f` (busca `crypto_LUKS` y `crypt`). Es la protección más importante si pierdes la laptop.

### 13.6.1 Comprobar Secure Boot y estado del arranque
```bash
mokutil --sb-state                    # ¿Secure Boot activo?
cat /sys/kernel/security/lockdown     # "none" es lo normal; "integrity" bloquea la hibernación
```

### 13.7 AppArmor (aísla programas)
| Comando | Qué hace |
|---|---|
| `sudo aa-status` | Perfiles cargados y en qué modo están |
| `sudo aa-complain /ruta/programa` | Modo aviso (registra pero no bloquea) |
| `sudo aa-enforce /ruta/programa` | Modo estricto |
| `journalctl -k \| grep apparmor` | Ver bloqueos |

### 13.8 Revisar si algo cambió o es sospechoso
| Comando | Qué hace |
|---|---|
| `sudo debsums -s` | Muestra archivos de paquetes que **fueron modificados** (silencioso si todo está bien) |
| `find / -xdev -perm -4000 -type f 2>/dev/null` | Programas con SUID (se ejecutan con permisos del dueño): deben ser pocos y conocidos |
| `find / -xdev -type f -perm -0002 2>/dev/null` | Archivos que **cualquiera** puede escribir (debería ser casi nada) |
| `ps aux --sort=-%cpu \| head` | Procesos que más consumen (un minero oculto se nota aquí) |
| `crontab -l` y `ls /etc/cron.*` | Tareas programadas que no reconozcas |
| `systemctl list-unit-files --state=enabled` | Servicios que arrancan solos |
| `ls -la ~/.config/autostart` | Programas que arrancan con tu sesión |
| `sudo apt install clamav && sudo freshclam` | Instala el antivirus y actualiza sus firmas |
| `clamscan -r -i ~/Descargas` | Escanea una carpeta (solo muestra los infectados) |
| `sudo lynis audit system` | Auditoría con puntaje y sugerencias |

### 13.9 SSH (si algún día lo instalas)
`mono-secure` lo marca como pendiente a quitar si no lo usas. Si lo necesitas:
1. Clave en vez de contraseña: `ssh-copy-id` y luego, en `/etc/ssh/sshd_config.d/mono.conf`:
   ```
   PasswordAuthentication no
   PermitRootLogin no
   ```
2. `sudo systemctl restart ssh` y prueba **en otra terminal** antes de cerrar la actual.
3. `sudo ufw limit ssh`.

### 13.10 Navegador y hábitos
- Firefox ya viene con uBlock Origin, protección de rastreo y solo HTTPS.
- Verificación en dos pasos en tus cuentas importantes.
- Nada de `curl … | sh` ni de `.sh` de internet sin leerlos antes.
- Instala solo de apt o Flatpak/Flathub.
- Copias de seguridad (sección 6): cifradas y fuera del equipo.

### 13.11 Rutina de seguridad
**Cada semana:** `mono-update`, `systemctl --failed`, `mono-secure`.
**Cada mes:** `sudo ss -tulpn`, `last -n 20`, `sudo debsums -s`, `sudo lynis audit system`, y probar que puedes **restaurar** una copia.

## 14. Git

Tu configuración vive en `~/mono-rice` (un repositorio Git).

| Comando | Qué hace |
|---|---|
| `git status` | Qué cambió |
| `git diff` | Ver los cambios línea a línea |
| `git add -A` | Prepara todos los cambios |
| `git commit -m "mensaje"` | Guarda los cambios con una descripción |
| `git log --oneline -10` | Últimos 10 cambios guardados |
| `git pull` | Baja cambios nuevos |
| `git push` | Sube tus cambios |
| `git clone URL` | Descarga un repositorio |
| `git stash` / `git stash pop` | Guarda tus cambios aparte / los vuelve a poner (útil antes de un `pull`) |
| `git restore ARCHIVO` | ⚠ Descarta tus cambios sin guardar de ese archivo |
| `git restore --staged ARCHIVO` | Saca un archivo de lo preparado |
| `git checkout COMMIT -- ARCHIVO` | Recupera un archivo como estaba en un cambio anterior |
| `git revert COMMIT` | Deshace un cambio creando otro (seguro) |
| `git reset --hard origin/main` | ⚠⚠ Descarta **todo** lo local y deja igual al remoto |
| `git branch` / `git switch -c NUEVA` | Ver ramas / crear y cambiar a una |
| `git remote -v` | A qué repositorio apunta |
| `git config --global user.name "Nombre"` | Tu nombre para los cambios |
| `git config --global user.email "correo"` | Tu correo |

**Flujo habitual para tu rice:** editas un archivo de `~/mono-rice/config/…`, pruebas, `git add -A && git commit -m "…" && git push`. Para otra laptop: `git clone` y `bash install.sh`.

## 15. Mantenimiento y recuperación

### Rutina
```bash
mono-update             # semanal: instantánea → actualizar → Flatpak → configuración → limpieza
```

### Instantáneas del sistema (Timeshift)
| Comando | Qué hace |
|---|---|
| `sudo timeshift --create --comments "antes de X" --tags O` | Crea una instantánea ahora |
| `sudo timeshift --list` | Lista las instantáneas |
| `sudo timeshift --restore` | Restaura una (te lo pregunta paso a paso) |
| `sudo timeshift --delete --snapshot 'NOMBRE'` | Borra una |
| `sudo timeshift-gtk` | Versión gráfica |

Timeshift protege el **sistema**, no tus documentos: para eso son las copias de la sección 6.

### Arreglar paquetes rotos
```bash
sudo dpkg --configure -a            # termina instalaciones a medias
sudo apt --fix-broken install       # arregla dependencias
sudo apt install --reinstall PAQUETE
sudo apt update --fix-missing
```

### Liberar espacio
```bash
df -h /                                   # ¿cuánto queda?
sudo apt autoremove && sudo apt clean     # paquetes sobrantes y descargas
sudo journalctl --vacuum-time=14d         # registros viejos
flatpak uninstall --user --unused         # runtimes sin uso
du -h --max-depth=1 ~ | sort -h           # qué ocupa más en tu carpeta
ncdu ~                                    # lo mismo, interactivo
```

### Kernel
```bash
uname -r                                  # el que usas
dpkg -l 'linux-image*' | grep ^ii         # los instalados
sudo update-grub                          # regenerar el menú de arranque
```
Conserva **al menos el kernel anterior**: si el nuevo falla, lo eliges en GRUB.

### Si algo no arranca
1. **Menú de arranque (GRUB):** mantén `Shift` (BIOS) o pulsa `Esc` al encender → *Opciones avanzadas para Debian* → elige un kernel anterior.
2. **Terminal de texto:** `Ctrl+Alt+F3`, entra con tu usuario y contraseña. Para volver a la pantalla gráfica, `Ctrl+Alt+F7` (o `F1`/`F2`).
3. **Ver qué falló:** `systemctl --failed`, `journalctl -p err -b`, `tail ~/.xsession-errors`.
4. **Reaplicar tu configuración:** `cd ~/mono-rice && bash install.sh`.
5. **Volver atrás con Timeshift:** `sudo timeshift --restore`.
6. **Recuperar la barra:** `~/mono-rice/config/polybar/launch.sh` (si su configuración falla, usa una barra mínima sola).

### Si olvidaste tu contraseña (y el disco NO está cifrado)
1. En GRUB, resalta tu entrada y pulsa `e`.
2. En la línea que empieza con `linux`, al final agrega un espacio y `init=/bin/bash`.
3. Pulsa `Ctrl+X`. Cuando aparezca el símbolo de sistema:
   ```bash
   mount -o remount,rw /
   passwd TU_USUARIO
   sync
   reboot -f
   ```
Si el disco está **cifrado**, necesitas la frase de cifrado primero, y sin ella los datos no se pueden recuperar (esa es la idea del cifrado).

### Restaurar una carpeta de configuración
Copias antiguas: `~/.config-backup-FECHA`. Para ver: `ls ~/.config-backup-*`.

## 16. Tus comandos `mono-*`

El prefijo `mono-` es solo un nombre: son scripts de `~/mono-rice/scripts`, enlazados en `/usr/local/bin` por `install.sh`.

### Sistema y mantenimiento
| Comando | Opciones y uso |
|---|---|
| `mono-update` | Actualiza con instantánea previa. Úsalo cada semana |
| `mono-guia` | Abre la guía. `mono-guia comandos` abre este manual |
| `mono-secure` | `--apply` refuerza, `--audit` puntaje de seguridad |
| `mono-apps` | Instala apps. Categorías: `office dev media graphics tools games`. Ej.: `mono-apps games` |
| `mono-zoom` | Instala o actualiza Zoom |
| `mono-slim` | Muestra qué quitaría de XFCE. `--yes` lo quita |
| `mono-hibernate` | Revisa la hibernación. `--apply` la configura (swap + arranque). `--revert` la deshace |
| `mono-boot` | Menú de arranque y pantalla de inicio. `--apply`, `--revert`, `--plymouth` |
| `mono-lock-diag` | Informe del bloqueo, para pedir ayuda |

### Apariencia
| Comando | Opciones y uso |
|---|---|
| `mono-wall` | Fondo al azar. `mono-wall mono` (blanco y negro), `mono-wall color`, `mono-wall /ruta/imagen.jpg` |
| `mono-wall-auto` | `30` cambia cada 30 min, `off`, `status` |
| `mono-scale` | Tamaño de todo: `mono-scale 120` (96 a 168) |
| `mono-accent` | Color de acento: `mono`, `rose`, `violet`, `cyan`, `red`, `green` o `'#rrggbb'` |
| `mono-avatar` | Foto de usuario. `--choices` baja opciones; `mono-avatar foto.jpg` usa la tuya |
| `mono-pic` | Pixel art de `fastfetch` y la IA: `sakura`, `yuki`, `mizu`, `kuro` o un PNG. Opciones: `--real`, `--scale N`, `--width N`, `--rows N` |
| `mono-pet` | La chica animada (parpadea y respira). `q` sale |
| `mono-night` | Luz nocturna: `on`, `off`, `toggle`, `status` |

### Escritorio
| Comando | Opciones y uso |
|---|---|
| `mono-lock` | Bloquea la pantalla |
| `mono-power` | Menú de apagado |
| `mono-touch` | Pantalla táctil: `on`, `off`, `toggle`, `status` |
| `mono-browser` | Firefox con el perfil del rice |
| `mono-clip` | Historial del portapapeles (`Super+V`) |
| `mono-wifi` / `mono-bluetooth` | Menús de red y Bluetooth |
| `mono-cal` | Calendario y clima |
| `mono-music` | Texto de la música actual (lo usa la barra) |
| `mono-session-dpi` | Interno: fija el tamaño de la sesión |

### Inteligencia artificial
| Comando | Opciones y uso |
|---|---|
| `mono-ai` | Chat con Xiao Mei. `mono-ai "pregunta"`; `--serio` sin personalidad; `--sin-herramientas` solo texto |
| `mono-ai-setup` | Instala Ollama y el modelo (`mono-ai-setup qwen2.5:3b` para otro) |
| `mono-ask` | Pregunta sobre el texto seleccionado (`Super+Shift+I`) |

Archivos útiles de la IA: `~/.config/mono-ai/name` (nombre), `~/.config/mono-ai/persona.txt` (personalidad), `~/.local/share/mono-ai/log.txt` (todo lo que ejecutó).
Configuración personal del rice: `~/.config/mono-rice/` (`city`, `location`, `wall-interval`, `pic.name`…).

## 17. i3: atajos y comandos

`Super` es la tecla Windows. `Super+F1` muestra la guía dentro de i3.

### Aplicaciones
| Atajo | Acción |
|---|---|
| `Super+Enter` | Terminal |
| `Super+Espacio` / `Super+D` | Buscador de aplicaciones |
| `Super+Tab` | Cambiar entre ventanas abiertas |
| `Super+B` | Navegador |
| `Super+Shift+F` | Archivos (Thunar) |
| `Super+K` | Teclado en pantalla |
| `Super+I` | Asistente de IA |
| `Super+Shift+I` | IA sobre el texto seleccionado |
| `Super+V` | Historial del portapapeles |
| `Super+W` / `Super+Shift+W` | Cambiar fondo / solo blanco y negro |
| `Super+N` | Luz nocturna |
| `Super+Esc` | Bloquear |
| `Super+Shift+P` | Menú de apagado |
| `Print` | Captura de pantalla |

### Ventanas
| Atajo | Acción |
|---|---|
| `Super+Q` | Cerrar ventana |
| `Super+F` | Pantalla completa |
| `Super+Shift+Espacio` | Flotante / en mosaico |
| `Super+flechas` (o `H J L U`) | Mover el foco |
| `Super+Shift+flechas` (o `Shift+H J K L`) | Mover la ventana |
| `Super+-` / `Super+\` | La próxima ventana se abre debajo / al lado |
| `Super+E` | Alternar división vertical/horizontal |
| `Super+S` / `Super+T` | Layout apilado / en pestañas |
| `Super+R` | Modo redimensionar (flechas; `Enter` o `Esc` sale) |
| `Super` + clic izquierdo arrastrando | Mover una ventana flotante |
| `Super` + clic derecho arrastrando | Redimensionar una flotante |

### Escritorios y sesión
| Atajo | Acción |
|---|---|
| `Super+1…9` | Ir al escritorio |
| `Super+Shift+1…9` | Mandar la ventana a ese escritorio |
| `Super+Ctrl+→` / `←` | Escritorio siguiente / anterior |
| `Super+Shift+C` | Recargar la configuración |
| `Super+Shift+R` | Reiniciar i3 (conserva tus ventanas) |
| `Super+Shift+E` | Salir de i3 (cerrar sesión) |

### Comandos de i3
```bash
i3-msg reload                          # recargar configuración
i3-msg restart                         # reiniciar i3
i3-msg 'workspace 3'                   # ir al escritorio 3
i3-msg -t get_workspaces               # ver escritorios (formato JSON)
i3 -C -c ~/.config/i3/config           # comprobar que tu configuración no tiene errores
xprop | grep -i class                  # clase de una ventana (clic en ella) para crear reglas
```
Tu configuración: `~/mono-rice/config/i3/config`. Regla de ejemplo para que una app siempre flote: `for_window [class="NombreClase"] floating enable`.

## 18. Editores y atajos de la terminal

### nano
| Atajo | Acción |
|---|---|
| `Ctrl+O` luego `Enter` | Guardar |
| `Ctrl+X` | Salir (pregunta si guardar) |
| `Ctrl+W` | Buscar |
| `Ctrl+K` / `Ctrl+U` | Cortar línea / pegar |
| `Alt+U` | Deshacer |
| `Ctrl+G` | Ayuda |

### Neovim (`nvim`)
Tiene **modos**: empieza en modo normal (comandos). `i` para escribir, `Esc` para volver.
| Tecla | Acción |
|---|---|
| `i` / `a` | Escribir antes / después del cursor |
| `Esc` | Volver al modo normal |
| `:w` | Guardar |
| `:q` | Salir |
| `:wq` o `ZZ` | Guardar y salir |
| `:q!` | ⚠ Salir **sin guardar** |
| `dd` | Borrar (cortar) la línea |
| `yy` / `p` | Copiar la línea / pegar |
| `u` / `Ctrl+R` | Deshacer / rehacer |
| `/texto` luego `n` | Buscar / siguiente resultado |
| `gg` / `G` | Ir al inicio / al final |
| `:%s/viejo/nuevo/g` | Reemplazar en todo el archivo |
| `:set number` | Mostrar números de línea |
| `v` | Seleccionar (modo visual) |

### less
`Espacio` avanza, `b` retrocede, `/texto` busca, `n` siguiente, `G` final, `g` inicio, `F` sigue en vivo, `q` sale.

### Terminal kitty
| Atajo | Acción |
|---|---|
| `Ctrl+Shift+C` / `V` | Copiar / pegar |
| `Ctrl+Shift+T` | Pestaña nueva |
| `Ctrl+Shift+Enter` | Ventana nueva dentro de kitty |
| `Ctrl+Shift+←` / `→` | Pestaña anterior / siguiente |
| `Ctrl+Shift+↑` / `↓` | Desplazarte por el historial |
| `Ctrl+Shift+=` / `-` | Letra más grande / más pequeña |
| `Ctrl+Shift+L` | Cambiar la distribución de ventanas |

### zsh (tu shell)
| Atajo | Acción |
|---|---|
| `Tab` | Autocompleta |
| `Ctrl+R` | Busca en el historial con fzf |
| `Ctrl+T` | Elige un archivo con fzf |
| `Alt+C` | Salta a una carpeta con fzf |
| `↑` / `↓` | Historial |
| `Ctrl+A` / `Ctrl+E` | Inicio / final de la línea |
| `Ctrl+W` | Borra la palabra anterior |
| `Ctrl+U` / `Ctrl+K` | Borra hasta el inicio / hasta el final |
| `Ctrl+L` | Limpia la pantalla |
| `Ctrl+C` | Cancela el comando actual |
| `Ctrl+D` | Cierra la terminal |
| `!!` | Repite el último comando (útil: `sudo !!`) |
| `source ~/.zshrc` | Recarga tu configuración de la terminal |

## 19. Scripts y tareas programadas

### Un script básico
```bash
nano ~/hola.sh
```
Contenido:
```bash
#!/usr/bin/env bash
set -eu                      # se detiene ante un error o una variable sin definir
nombre="${1:-mundo}"         # primer argumento, o "mundo"
echo "Hola, $nombre"
for f in ~/Descargas/*.pdf; do
  [ -e "$f" ] && echo "PDF: $f"
done
```
```bash
chmod +x ~/hola.sh && ~/hola.sh Sachi
```
Conceptos útiles: `$?` (resultado del último comando: 0 = bien), `$1 $2` (argumentos), `if [ -f ARCHIVO ]; then … fi`, `cmd1 && cmd2` (solo si el primero salió bien), `cmd1 || cmd2` (solo si falló). Revisa scripts con `shellcheck ARCHIVO`.

### cron (tareas programadas)
```bash
crontab -e           # editar las tuyas
crontab -l           # verlas
```
Formato: `minuto hora día-del-mes mes día-de-la-semana comando`. Ejemplos:
```
0 3 * * *    rsync -a ~/Documentos/ /media/disco/Documentos/    # todos los días a las 3:00
*/30 * * * * mono-wall                                           # cada 30 minutos
```
También: `systemctl list-timers` para los temporizadores del sistema.

## 20. Dónde está cada cosa

| Qué | Dónde |
|---|---|
| Tu configuración del rice | `~/mono-rice/` (repositorio Git) |
| i3 | `~/.config/i3/config` → `~/mono-rice/config/i3/config` |
| Barra | `~/.config/polybar/config.ini` (y `safe.ini`, la de emergencia) |
| Efectos de ventanas | `~/.config/picom/picom.conf` |
| Buscador y menús | `~/.config/rofi/` (`config.rasi`, `power.rasi`, `menu.rasi`) |
| Terminal | `~/.config/kitty/kitty.conf`, `~/.zshrc`, `~/.config/starship.toml` |
| Notificaciones | `~/.config/dunst/dunstrc` |
| Tema de ventanas | `~/.config/gtk-3.0/gtk.css` |
| Firefox (perfil del rice) | `~/.mozilla/firefox-mono/` |
| Wallpapers | `~/Pictures/wallpapers/` (y `mono/`, `login/`) |
| Ajustes del rice | `~/.config/mono-rice/` |
| Foto de usuario | `~/.face` |
| Configuración del sistema | `/etc/` |
| Programas de usuario | `/usr/local/bin/` (tus `mono-*`) |
| Registros del sistema | `journalctl`; `/var/log/` |
| Registros del rice | `/tmp/polybar.log`, `/tmp/picom.log`, `/tmp/mono-lock.log`, `/tmp/mono-apps.log`, `/tmp/setwall.log` |
| Copias de configuración viejas | `~/.config-backup-FECHA` |

## 21. "Quiero hacer X": respuestas rápidas

| Quiero… | Hago… |
|---|---|
| Saber cuánto espacio me queda | `df -h /` |
| Saber qué ocupa tanto espacio | `ncdu ~` |
| Encontrar un archivo por nombre | `find ~ -iname "*parte*"` |
| Encontrar un texto dentro de archivos | `grep -rni "texto" ~/carpeta` |
| Ver qué consume mi RAM o procesador | `btop` |
| Cerrar un programa congelado | `xkill` y clic; o `pkill NOMBRE` |
| Actualizar todo | `mono-update` |
| Instalar un programa | `sudo apt install NOMBRE` (o `flatpak install --user flathub ID`) |
| Desinstalar un programa | `sudo apt remove NOMBRE` |
| Saber en qué paquete viene un comando | `dpkg -S $(which COMANDO)` |
| Ver mi IP | `ip -br a` |
| Conectarme a una red WiFi | clic en el WiFi de la barra, o `nmtui` |
| Ver qué puertos tengo abiertos | `sudo ss -tulpn` |
| Abrir un puerto para probar mi app desde el teléfono | `sudo ufw allow from 192.168.1.0/24 to any port 3000 proto tcp` |
| Revisar la seguridad | `mono-secure` |
| Saber la salud de la batería | `upower -i $(upower -e \| grep BAT)` |
| Saber la salud del disco | `sudo smartctl -H /dev/nvme0` |
| Ver errores del sistema | `journalctl -p err -b` |
| Ver qué servicio falló | `systemctl --failed` |
| Cambiar mi contraseña | `passwd` |
| Cambiar la hora o zona | `sudo timedatectl set-timezone America/Santo_Domingo` |
| Cambiar el idioma del teclado | `sudo localectl set-x11-keymap latam` |
| Copiar mis documentos a un disco | `rsync -aAXv ~/Documentos/ /media/$USER/DISCO/Documentos/` |
| Hacer una instantánea del sistema | `sudo timeshift --create --comments "antes de X"` |
| Volver el sistema a como estaba | `sudo timeshift --restore` |
| Editar un archivo del sistema con seguridad | `sudo cp A A.bak && sudoedit A` |
| Guardar un cambio de mi configuración | `cd ~/mono-rice && git add -A && git commit -m "cambio" && git push` |
| Ver qué instalé yo | `apt-mark showmanual` |
| Ver qué cambió apt hace poco | `less /var/log/apt/history.log` |
| Que mi laptop hiberne | `mono-hibernate --apply` |
| Cambiar el aspecto del arranque | `mono-boot --apply` |
| Apagar la pantalla táctil | `mono-touch off` |
| Ver los atajos de i3 | `Super+F1` |
| Cerrar sesión / apagar | `Super+Shift+P` |

## 22. Reglas de oro y comandos peligrosos

**Hábitos que evitan casi todos los desastres**
1. **Lee antes de aceptar.** Si apt dice "serán ELIMINADOS" paquetes que no esperas, di que no.
2. **Mira antes de borrar.** Usa `ls` con la misma ruta, y `rm -i` mientras te acostumbras.
3. **Simula primero.** Muchos comandos tienen modo de prueba: `apt -s`, `rsync --dry-run`, `find` sin `-delete`.
4. **Copia antes de modificar.** `cp archivo archivo.bak`.
5. **Una instantánea antes de cambios grandes** (`mono-update` ya la crea).
6. **Tus archivos, respaldados** fuera del equipo, y comprueba que se pueden restaurar.
7. **Un cambio a la vez**, y pruébalo antes del siguiente.
8. **No pegues comandos que no entiendas**, sobre todo con `sudo`.

**Comandos que casi nunca debes ejecutar** (y por qué)
| Comando | Por qué es peligroso |
|---|---|
| `rm -rf /` , `rm -rf ~` , `rm -rf *` | Borra el sistema, tu carpeta personal o todo el directorio actual |
| `sudo rm -rf /ruta` con una variable vacía (`rm -rf $VAR/`) | Si `$VAR` está vacía, se convierte en `rm -rf /` |
| `chmod -R 777 /` o `chmod -R 777 ~` | Da permiso total a cualquiera; rompe SSH y otros servicios |
| `chown -R usuario /` | Rompe la propiedad de todo el sistema |
| `dd if=… of=/dev/sdX` con el dispositivo equivocado | Sobrescribe un disco entero |
| `mkfs.*` sobre una partición en uso | Borra todo lo que tenga |
| `> archivo` o `echo … > /etc/archivo` | Reemplaza el archivo entero (para añadir usa `>>`) |
| `curl URL \| sh` o `wget -O- URL \| sudo bash` | Ejecuta código desconocido con tus permisos |
| `:(){ :\|:& };:` | Bomba de procesos que congela el equipo |
| `sudo apt remove` con `-y` sin mirar | Puede quitar el escritorio |
| `sudo pip install …` | Rompe herramientas del sistema que usan Python |
| Agregar repositorios de `testing` o `unstable` | Mezcla versiones y rompe dependencias |
| `kill -9` a procesos del sistema (`systemd`, `Xorg`) | Cierra tu sesión o cuelga el equipo |
| Apagar durante `apt full-upgrade` | Deja paquetes a medias (repara con `sudo dpkg --configure -a`) |

**Si cometes un error:** no sigas ejecutando comandos para "arreglarlo" a ciegas. Detente, lee el mensaje de error completo, y revisa la sección 15. Con una instantánea y copias, casi todo tiene vuelta atrás.
