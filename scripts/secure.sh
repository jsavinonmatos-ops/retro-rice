#!/usr/bin/env bash
# mono-secure: revisa y refuerza la seguridad del equipo.
# Uso: mono-secure           -> solo MUESTRA el estado (no cambia nada)
#      mono-secure --apply   -> aplica el refuerzo (muestra el plan y pide escribir SI)
#      mono-secure --audit   -> auditoría completa con Lynis (puntaje de seguridad)
set -u
ok()  { printf '  \033[32m✔\033[0m %s\n' "$*"; }
bad() { printf '  \033[31m✘\033[0m %s\n' "$*"; }
inf() { printf '  \033[2m·\033[0m %s\n' "$*"; }

report() {
  echo "== Estado de seguridad =="
  if systemctl is-active --quiet ufw 2>/dev/null; then ok "Cortafuegos (ufw) activo"; else bad "Sin cortafuegos activo"; fi
  if dpkg -s unattended-upgrades >/dev/null 2>&1 && grep -qs 'Unattended-Upgrade "1"' /etc/apt/apt.conf.d/20auto-upgrades; then
    ok "Actualizaciones de seguridad automáticas activadas"; else bad "Las actualizaciones de seguridad NO son automáticas"; fi
  n="$(apt list --upgradable 2>/dev/null | grep -c upgradable)"
  if [ "$n" -eq 0 ]; then ok "Sistema al día"; else bad "$n paquetes por actualizar (sudo apt update && sudo apt full-upgrade)"; fi
  if lsblk -o TYPE 2>/dev/null | grep -q crypt; then ok "Disco cifrado (LUKS)"; else bad "Disco SIN cifrar: si te roban el equipo, pueden leer tus archivos"; fi
  if [ "$(cat /sys/module/apparmor/parameters/enabled 2>/dev/null)" = "Y" ]; then ok "AppArmor activo (aísla programas)"; else bad "AppArmor inactivo"; fi
  if dpkg -s openssh-server >/dev/null 2>&1; then bad "Servidor SSH instalado (acceso remoto): quítalo si no lo usas"; else ok "Sin servidor SSH (nadie puede entrar por red)"; fi
  for s in avahi-daemon cups-browsed; do
    if systemctl is-active --quiet "$s" 2>/dev/null; then bad "$s activo (servicio de red que casi nunca necesitas)"; fi
  done
  inf "Puertos que aceptan conexiones (red):"
  ss -tuln 2>/dev/null | awk 'NR>1 && $5 !~ /^(127\.|\[::1\]|::1)/ {print "      " $1 " " $5}' | sort -u | head -12
  if xset q 2>/dev/null | grep -q 'timeout:  *[1-9]'; then ok "La pantalla se bloquea sola por inactividad"; else bad "La pantalla NO se bloquea sola al dejar el equipo"; fi
  echo
  echo "Para corregir lo automático:  mono-secure --apply     |    auditoría completa:  mono-secure --audit"
}

apply() {
  cat <<'TXT'
Se aplicará lo siguiente (todo reversible):
  1. Cortafuegos ufw: bloquea conexiones ENTRANTES y deja salir todo. (Tus servidores locales siguen
     funcionando en este equipo; solo otros dispositivos de tu red dejarán de poder entrar.)
  2. Actualizaciones de seguridad automáticas (sin reinicio automático).
  3. Endurecimiento del kernel (/etc/sysctl.d/99-mono-secure.conf): oculta datos internos, bloquea
     redirecciones de red falsas y protege enlaces de archivos.
  4. Desactiva avahi-daemon y cups-browsed (descubrimiento de red; las impresoras USB siguen igual).
  5. AppArmor activado, y Firefox solo con HTTPS.
  6. Bloqueo automático de pantalla a los 10 minutos (i3).
TXT
  read -rp "Escribe SI para continuar: " r; [ "$r" = "SI" ] || { echo "Cancelado."; return; }
  export DEBIAN_FRONTEND=noninteractive
  sudo apt-get install -y ufw unattended-upgrades apparmor apparmor-utils lynis

  sudo ufw default deny incoming >/dev/null; sudo ufw default allow outgoing >/dev/null
  systemctl is-active --quiet ssh 2>/dev/null && sudo ufw limit ssh >/dev/null   # si usas SSH, no te deja fuera
  sudo ufw --force enable >/dev/null && ok "ufw activado"

  printf 'APT::Periodic::Update-Package-Lists "1";\nAPT::Periodic::Unattended-Upgrade "1";\n' | sudo tee /etc/apt/apt.conf.d/20auto-upgrades >/dev/null
  ok "actualizaciones automáticas de seguridad"

  sudo tee /etc/sysctl.d/99-mono-secure.conf >/dev/null <<'EOS'
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.unprivileged_bpf_disabled = 1
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.protected_fifos = 2
fs.protected_regular = 2
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
EOS
  sudo sysctl --system >/dev/null 2>&1; ok "kernel endurecido"

  for s in avahi-daemon.socket avahi-daemon.service cups-browsed.service; do
    systemctl list-unit-files "$s" 2>/dev/null | grep -q "$s" && sudo systemctl disable --now "$s" >/dev/null 2>&1
  done
  ok "servicios de descubrimiento de red desactivados"
  sudo systemctl enable --now apparmor >/dev/null 2>&1; ok "AppArmor activo"
  echo
  echo "Listo. El bloqueo por inactividad y HTTPS-only de Firefox se aplican al hacer 'git pull' y 'bash install.sh'."
  echo "Midiendo el resultado con Lynis (tarda un minuto)..."; audit
}

audit() {
  command -v lynis >/dev/null || sudo apt-get install -y lynis
  sudo lynis audit system --quick --no-colors 2>/dev/null | grep -E 'Hardening index|Warnings|Suggestions' | head -5
  echo "Informe completo: /var/log/lynis-report.dat  (sudo lynis show details TEST-ID para cada sugerencia)"
}

case "${1:-}" in
  --apply) apply ;;
  --audit) audit ;;
  *) report ;;
esac
