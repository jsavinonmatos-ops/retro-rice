# mono-rice

Rice blanco y negro para **Debian + XFCE**: blur tipo cristal, esquinas redondeadas, barra flotante, launcher y terminal a juego.

| Pieza | Herramienta |
|---|---|
| Compositor (blur, sombras, fade) | picom |
| Barra | polybar (flotante, translúcida) |
| Launcher | rofi (`Super+Espacio`) |
| Terminal | kitty |
| Notificaciones | dunst |
| GTK / ventanas | Arc-Dark + overrides en negro puro |
| Iconos | Papirus-Dark |
| Fuentes | Inter + JetBrainsMono Nerd Font |

## Instalar

```bash
git clone https://github.com/SachiretMatos/retrorice.git ~/mono-rice
cd ~/mono-rice
./install.sh
```

Cierra sesión y vuelve a entrar. Las configs se enlazan con symlinks en `~/.config`, así que editar el repo cambia el sistema. Lo que ya existía se respalda en `~/.config-backup-*`.

## Wallpapers anime

No van en el repo (son de sus autores). Se descargan aparte, SFW, desde wallhaven:

```bash
scripts/fetch-wallpapers.sh 15 --mono   # --mono = blanco y negro
scripts/setwall.sh                      # uno al azar
```

## Notas

- La batería se llama `BAT0` en `config/polybar/config.ini`; si la tuya es otra, ajústalo (`ls /sys/class/power_supply`).
- El panel de XFCE queda oculto (autohide); la barra real es polybar.
- Si picom da problemas en una VM o GPU vieja, cambia `backend = "glx"` a `"xrender"` en `config/picom/picom.conf`.

## Tiling (i3)

`install.sh` instala i3 como **sesión aparte**: en el login eliges "i3" o tu sesión de XFCE. No reemplaza al escritorio normal.
Dentro de i3, `Super+F1` abre la guía de atajos. Las animaciones de ventanas (picom) solo se activan en i3.
