#!/usr/bin/env bash
# Aplica los ajustes de XFCE por xfconf (tema, iconos, fuentes, ventanas)
set -u

xs() { xfconf-query -c "$1" -p "$2" --create -t "$3" -s "$4" 2>/dev/null; }

# Apariencia
xs xsettings /Net/ThemeName        string "Arc-Dark"
xs xsettings /Net/IconThemeName    string "Papirus-Dark"
xs xsettings /Gtk/FontName         string "Inter 10"
xs xsettings /Gtk/MonospaceFontName string "JetBrainsMono Nerd Font 11"
xs xsettings /Xft/Antialias        int 1
xs xsettings /Xft/Hinting          int 1
xs xsettings /Xft/HintStyle        string "hintslight"
xs xsettings /Xft/RGBA             string "rgb"

# Ventanas: tema Arc-Dark, el compositor lo pasa a picom
xs xfwm4 /general/theme            string "Arc-Dark"
xs xfwm4 /general/title_font       string "Inter Bold 10"
xs xfwm4 /general/use_compositing  bool false
xs xfwm4 /general/show_dock_shadow bool false

# El panel de XFCE se oculta, la barra es polybar
xs xfce4-panel /panels/panel-1/autohide-behavior uint 2
xs xfce4-panel /panels/panel-1/size              uint 1

# Escritorio limpio
xs xfce4-desktop /desktop-icons/style int 0
echo "Ajustes de XFCE aplicados."
