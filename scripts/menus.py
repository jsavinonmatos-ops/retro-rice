#!/usr/bin/env python3
"""Menús de escritorio en rofi (estilo cristal): portapapeles, WiFi, Bluetooth, calendario con clima,
preguntarle a la IA sobre el texto seleccionado y música para la barra.

Se usa mediante enlaces con su nombre (mono-clip, mono-wifi, mono-bluetooth, mono-cal, mono-ask, mono-music)
o directamente:  menus.py clip | wifi | bluetooth | cal | ask | music | clip-daemon
"""
import calendar
import datetime
import fcntl
import html
import json
import os
import re
import shutil
import subprocess
import sys
import time
import urllib.parse

HOME = os.path.expanduser("~")
CONF = os.path.join(HOME, ".config", "mono-rice")
THEME = os.path.join(HOME, ".config", "rofi", "menu.rasi")
RUNTIME = os.environ.get("XDG_RUNTIME_DIR") or f"/tmp/mono-{os.getuid()}"
G = {k: chr(v) for k, v in dict(lock=0xF023, music=0xF001, pause=0xF04C, dot=0x25CF).items()}


# ---------------------------------------------------------------- utilidades
def run(cmd, inp=None, timeout=15):
    try:
        r = subprocess.run(cmd, input=inp, capture_output=True, text=True, timeout=timeout)
        return r.returncode, r.stdout, r.stderr
    except (OSError, subprocess.TimeoutExpired) as e:
        return 127, "", str(e)


def notify(title, msg="", tag=None):
    """Aviso de escritorio. Con 'tag', un aviso nuevo REEMPLAZA al anterior con la misma etiqueta (dunst)."""
    run(["notify-send", "-a", "mono"] + (["-h", f"string:x-dunst-stack-tag:{tag}"] if tag else []) + [title, msg])


def rofi(entries, prompt="", mesg=None, markup=False, settle=0):
    """Muestra una lista y devuelve el número elegido (o None si se cancela). settle = pausa antes de mostrarla."""
    if settle:
        time.sleep(settle)
    args = ["rofi", "-dmenu", "-i", "-format", "i", "-no-custom", "-theme", THEME, "-p", prompt]
    if mesg:
        args += ["-mesg", mesg]
    if markup:
        args.append("-markup-rows")
    rc, out, _ = run(args, inp="\n".join(entries), timeout=900)
    if rc != 0 or not out.strip():
        return None
    try:
        return int(out.strip())
    except ValueError:
        return None


def rofi_text(prompt, password=False, tries=2):
    """Pide un texto (o una contraseña).

    Si esta ventana se abre justo después de un clic en otro menú, ese clic puede caer sobre ella y cerrarla vacía al instante.
    Por eso: 1) se espera un momento antes de mostrarla, y 2) si aun así se cierra vacía en menos de 0,7 s
    (nadie escribe tan rápido), se asume que fue accidental y se reabre.
    """
    for _ in range(tries):
        time.sleep(0.4)
        args = ["rofi", "-dmenu", "-theme", THEME, "-theme-str", "listview { enabled: false; }", "-p", prompt]
        if password:
            args.append("-password")
        t0 = time.monotonic()
        rc, out, _err = run(args, inp="\n", timeout=900)          # una línea vacía: con la entrada totalmente vacía rofi puede salir de inmediato
        text = out.rstrip("\n") if rc == 0 else None
        if text:
            return text
        if time.monotonic() - t0 > 0.7:
            return text                                           # la cerraste tú (Esc o Enter sin escribir)
    return None


# ---------------------------------------------------------------- portapapeles
CLIP_FILE = os.path.join(RUNTIME, "mono-clip.json")     # en RAM (tmpfs): se borra al cerrar sesión
CLIP_MAX, CLIP_MAXLEN = 50, 20000
SENSITIVE_APPS = ("keepassxc", "keepass", "bitwarden", "1password", "enpass")


def clip_load():
    try:
        with open(CLIP_FILE, encoding="utf-8") as f:
            data = json.load(f)
        return [t for t in data if isinstance(t, str)]
    except (OSError, ValueError):
        return []


def clip_save(items):
    os.makedirs(os.path.dirname(CLIP_FILE), exist_ok=True)
    fd = os.open(CLIP_FILE, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        json.dump(items, f)


def clip_add(items, text):
    if not text.strip() or len(text) > CLIP_MAXLEN:
        return items
    items = [t for t in items if t != text]
    items.insert(0, text)
    return items[:CLIP_MAX]


def active_class():
    rc, out, _ = run(["xdotool", "getactivewindow", "getwindowclassname"], timeout=2)
    return out.strip().lower() if rc == 0 else ""


def clip_daemon(poll=0.7, once=False):
    lock = open(os.path.join(RUNTIME, "mono-clip.lock"), "w") if os.path.isdir(RUNTIME) else open("/tmp/mono-clip.lock", "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        return                                   # ya hay uno corriendo
    items, last = clip_load(), None
    while True:
        rc, out, _ = run(["xclip", "-selection", "clipboard", "-o"], timeout=2)
        if rc == 0 and out != last:
            last = out
            # lo copiado desde un gestor de contraseñas NO se guarda en el historial
            if not any(a in active_class() for a in SENSITIVE_APPS):
                items = clip_add(items, out)
                clip_save(items)
        if once:
            return
        time.sleep(poll)


def summary(text, width=90):
    lines = [l.strip() for l in text.replace("\t", " ").splitlines() if l.strip()]
    first = lines[0] if lines else ""
    first = first if len(first) <= width else first[:width - 1] + "…"
    return first + (f"   ⏎ +{len(lines) - 1} líneas" if len(lines) > 1 else "")


def clip_menu():
    items = clip_load()
    if not items:
        notify("Portapapeles", "Todavía no hay nada guardado. Lo que copies aparecerá aquí.")
        return
    i = rofi([summary(t) for t in items] + ["— Borrar historial —"], prompt="Portapapeles")
    if i is None:
        return
    if i == len(items):
        clip_save([])
        notify("Portapapeles", "Historial borrado")
        return
    p = subprocess.Popen(["xclip", "-selection", "clipboard"], stdin=subprocess.PIPE)
    p.communicate(items[i].encode("utf-8"))
    clip_save(clip_add(items, items[i]))
    notify("Copiado", "Pégalo con Ctrl+V")


# ---------------------------------------------------------------- WiFi
def split_nm(line):
    return [p.replace("\\:", ":").replace("\\\\", "\\") for p in re.split(r"(?<!\\):", line)]


def wifi_parse(text):
    nets = {}
    for line in text.splitlines():
        f = split_nm(line)
        if len(f) < 4 or not f[1]:
            continue
        inuse, ssid, sig, sec = f[0].strip() == "*", f[1], int(f[2] or 0), f[3]
        cur = nets.get(ssid)
        if cur is None or sig > cur["signal"]:
            nets[ssid] = {"ssid": ssid, "signal": sig, "security": "" if sec in ("", "--") else sec,
                          "inuse": inuse or bool(cur and cur["inuse"])}
        elif inuse:
            cur["inuse"] = True
    return sorted(nets.values(), key=lambda n: (not n["inuse"], -n["signal"]))


def bars(sig):
    return "▂▄▆█"[:max(1, min(4, 1 + sig // 26))]


def saved_wifi():
    """SSID -> nombre del perfil guardado en NetworkManager (el nombre del perfil no siempre coincide con el SSID)."""
    out = run(["nmcli", "-t", "-f", "NAME,TYPE", "con", "show"])[1]
    saved = {}
    for line in out.splitlines():
        parts = split_nm(line)
        if len(parts) >= 2 and parts[1] == "802-11-wireless":
            ssid = run(["nmcli", "-g", "802-11-wireless.ssid", "con", "show", "id", parts[0]])[1].strip() or parts[0]
            saved.setdefault(ssid, parts[0])
    return saved


def wifi_connect(n, known):
    ssid = n["ssid"]
    if n["inuse"]:
        run(["nmcli", "con", "down", "id", ssid])
        notify("WiFi", f"Desconectado de {ssid}", tag="mono-wifi")
        return
    if ssid in known:
        cmd = ["nmcli", "con", "up", "id", known[ssid]]
    elif not n["security"]:
        cmd = ["nmcli", "dev", "wifi", "connect", ssid]
    else:
        pw = rofi_text(f"Contraseña de {ssid}", password=True)
        if not pw:
            return
        cmd = ["nmcli", "dev", "wifi", "connect", ssid, "password", pw]
    notify("WiFi", f"Conectando a {ssid}…", tag="mono-wifi")
    rc, out, err = run(cmd, timeout=60)
    notify(f"Conectado a {ssid}" if rc == 0 else "No se pudo conectar", "" if rc == 0 else (err or out).strip()[:160], tag="mono-wifi")


def wifi():
    refresh = "auto"
    while True:                      # la lista se queda abierta; solo se vuelve a buscar si lo pides ("Buscar redes de nuevo")
        rc, out, _ = run(["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list", "--rescan", refresh], timeout=30)
        radio = run(["nmcli", "radio", "wifi"])[1].strip()
        if rc != 0 and radio != "disabled":
            notify("WiFi", "No pude hablar con NetworkManager. ¿Está instalado y activo?")
            return
        nets = wifi_parse(out) if radio == "enabled" else []
        entries = [(G["dot"] + " " if n["inuse"] else "   ") + n["ssid"] + f"   {bars(n['signal'])}" + (f"  {G['lock']}" if n["security"] else "")
                   for n in nets]
        extras = ["Buscar redes de nuevo", "Apagar WiFi" if radio == "enabled" else "Encender WiFi", "Editor de conexiones…"]
        i = rofi(entries + extras, prompt="WiFi", settle=0.4 if refresh == "yes" else 0)
        if i is None:
            return
        if i < len(nets):
            wifi_connect(nets[i], saved_wifi())
            return
        k = i - len(nets)
        if k == 0:
            refresh = "yes"
            continue
        if k == 1:
            run(["nmcli", "radio", "wifi", "off" if radio == "enabled" else "on"])
        else:
            subprocess.Popen(["nm-connection-editor"])
        return


# ---------------------------------------------------------------- Bluetooth
def bt_devices():
    out = run(["bluetoothctl", "devices"])[1]
    return [m.groups() for m in re.finditer(r"^Device ([0-9A-F:]{17}) (.+)$", out, re.M | re.I)]


def bt_info(mac):
    out = run(["bluetoothctl", "info", mac])[1]
    return "Connected: yes" in out, "Paired: yes" in out


def bluetooth():
    scanned = False
    if not shutil.which("bluetoothctl"):
        notify("Bluetooth", "Falta el paquete bluez: sudo apt install bluez")
        return
    while True:
        powered = "Powered: yes" in run(["bluetoothctl", "show"])[1]
        devs = bt_devices() if powered else []
        info = {m: bt_info(m) for m, _ in devs}
        entries = [(G["dot"] + " " if info[m][0] else "   ") + name for m, name in devs]
        extras = ["Apagar Bluetooth" if powered else "Encender Bluetooth"] + (["Buscar dispositivos nuevos (8 s)"] if powered else [])
        i = rofi(entries + extras, prompt="Bluetooth", settle=0.4 if scanned else 0)
        if i is None:
            return
        if i < len(devs):
            mac, name = devs[i]
            connected, paired = info[mac]
            if connected:
                run(["bluetoothctl", "disconnect", mac]); notify("Bluetooth", f"Desconectado de {name}")
            elif paired:
                rc, out, _ = run(["bluetoothctl", "connect", mac], timeout=30)
                notify(f"Conectado a {name}" if "successful" in out else "No se pudo conectar", name)
            else:
                for step in ("pair", "trust", "connect"):
                    rc, out, _ = run(["bluetoothctl", step, mac], timeout=40)
                notify(f"Conectado a {name}" if "successful" in out else "No se pudo emparejar", name)
            return
        if i == len(devs):
            run(["bluetoothctl", "power", "off" if powered else "on"])
        else:
            notify("Bluetooth", "Buscando durante 8 segundos…")
            run(["bluetoothctl", "--timeout", "8", "scan", "on"], timeout=20)
            scanned = True
            continue
        return


# ---------------------------------------------------------------- calendario y clima
MESES = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"]


CAL_THEME = os.path.join(HOME, ".config", "rofi", "calendar.rasi")
NB = "\u00a0"
DIAS = ["Lu", "Ma", "Mi", "Ju", "Vi", "Sá", "Do"]
WEATHER_FILE = os.path.join(RUNTIME, "mono-weather.json")      # clima en RAM, para que el calendario abra al instante
WEATHER_TTL = 1800


def weather(city):
    url = "https://wttr.in/" + urllib.parse.quote(city) + "?format=%C+%t+(sensación+%f)+·+humedad+%h&lang=es"
    rc, out, _ = run(["curl", "-fsS", "--max-time", "4", url], timeout=8)
    return out.strip() if rc == 0 and out.strip() and "Unknown" not in out else ""


def weather_cached(city, now=None):
    """Clima de la ciudad, guardado 30 min. Devuelve '' si no hay internet y no hay nada guardado."""
    now = now if now is not None else time.time()
    try:
        with open(WEATHER_FILE, encoding="utf-8") as f:
            d = json.load(f)
        if d.get("city") == city and now - d.get("t", 0) < WEATHER_TTL and d.get("text"):
            return d["text"]
    except (OSError, ValueError):
        d = {}
    text = weather(city)
    if text:
        try:
            os.makedirs(os.path.dirname(WEATHER_FILE), exist_ok=True)
            with open(WEATHER_FILE, "w", encoding="utf-8") as f:
                json.dump({"city": city, "t": now, "text": text}, f)
        except OSError:
            pass
    return text or (d.get("text", "") if d.get("city") == city else "")


def shift_month(year, month, delta):
    n = year * 12 + (month - 1) + delta
    return n // 12, n % 12 + 1


def cal_message(year, month, city, w):
    head = f"<span size='x-large'><b>{MESES[month - 1].capitalize()} {year}</b></span>"
    sub = f"{html.escape(city)}  ·  {html.escape(w)}" if w else f"{html.escape(city)}  ·  sin clima (¿sin internet?)"
    return f"{head}\n<span foreground='#8c8c8c' size='small'>{sub}</span>"


def cal_entries(year, month, today):
    """Cuadrícula para rofi (7 columnas): fila 0 = navegación, fila 1 = días de la semana, luego 6 semanas.
    Devuelve (entradas, índices_de_hoy)."""
    nav = ["◀", NB, NB, "Hoy", NB, NB, "▶"]
    entries = nav + [f"<span foreground='#8c8c8c' size='small'>{d}</span>" for d in DIAS]
    active = []
    weeks = calendar.Calendar(0).monthdayscalendar(year, month)
    weeks += [[0] * 7] * (6 - len(weeks))                  # siempre 6 filas: la ventana no cambia de alto entre meses
    for week in weeks:
        for col, d in enumerate(week):
            if not d:
                entries.append(NB)
                continue
            if (year, month, d) == (today.year, today.month, today.day):
                active.append(len(entries))
                entries.append(f"<b>{d}</b>")
            else:
                entries.append(f"<span foreground='#b3b3b3'>{d}</span>" if col >= 5 else str(d))
    return entries, active


def cal_pick(i, year, month, today):
    """Qué hace un clic en la casilla i: devuelve el nuevo (año, mes) o None para cerrar."""
    if i == 0:
        return shift_month(year, month, -1)
    if i == 3:
        return today.year, today.month
    if i == 6:
        return shift_month(year, month, +1)
    return None


def cal():
    try:
        with open(os.path.join(CONF, "city"), encoding="utf-8") as f:
            city = f.read().strip() or "Santo Domingo"
    except OSError:
        city = "Santo Domingo"
    today = datetime.date.today()
    year, month = today.year, today.month
    w = weather_cached(city)
    while True:
        entries, active = cal_entries(year, month, today)
        args = ["rofi", "-dmenu", "-format", "i", "-no-custom", "-markup-rows", "-theme", CAL_THEME,
                "-mesg", cal_message(year, month, city, w), "-p", ""]
        if active:
            args += ["-a", ",".join(map(str, active))]
        rc, out, _ = run(args, inp="\n".join(entries), timeout=300)
        try:
            i = int(out.strip()) if rc == 0 else None
        except ValueError:
            i = None
        nxt = cal_pick(i, year, month, today) if i is not None else None
        if nxt is None:
            return
        year, month = nxt


# ---------------------------------------------------------------- preguntarle a la IA sobre lo seleccionado
ACTIONS = [
    ("Explicar", "Explica de forma sencilla y breve el siguiente texto:"),
    ("Traducir al español", "Traduce al español el siguiente texto. Responde solo con la traducción:"),
    ("Traducir al inglés", "Traduce al inglés el siguiente texto. Responde solo con la traducción:"),
    ("Resumir", "Resume en pocas líneas el siguiente texto:"),
    ("Corregir ortografía y gramática", "Corrige la ortografía y la gramática del siguiente texto. Responde solo con el texto corregido:"),
    ("Preguntar algo sobre esto…", None),
]


def selection():
    for sel in ("primary", "clipboard"):
        rc, out, _ = run(["xclip", "-selection", sel, "-o"], timeout=2)
        if rc == 0 and out.strip():
            return out.strip()
    return ""


def ask_prompt(action_index, text, question=None):
    text = text[:4000]
    prefix = ACTIONS[action_index][1] or (question or "")
    return f"{prefix}\n\n{text}"


def ask():
    text = selection()
    if not text:
        notify("Preguntar a la IA", "Selecciona primero un texto con el mouse.")
        return
    i = rofi([a[0] for a in ACTIONS], prompt="IA", mesg=html.escape(summary(text, 70)))
    if i is None:
        return
    question = None
    if ACTIONS[i][1] is None:
        question = rofi_text("Tu pregunta sobre el texto")
        if not question:
            return
    subprocess.Popen(["kitty", "--class", "mono-ai", "-e", "sh", "-c",
                      'mono-ai --sin-herramientas "$1"; printf "\\n"; read -r -p "Enter para cerrar… " _',
                      "sh", ask_prompt(i, text, question)])


# ---------------------------------------------------------------- música para la barra
def music():
    rc, st, _ = run(["playerctl", "status"], timeout=2)
    st = st.strip()
    if rc != 0 or st not in ("Playing", "Paused"):
        return                                   # sin reproductor: la barra no muestra nada
    rc, meta, _ = run(["playerctl", "metadata", "--format", "{{artist}} - {{title}}"], timeout=2)
    meta = meta.strip().strip("-").strip()
    meta = meta if len(meta) <= 34 else meta[:33] + "…"
    print(f"{G['music'] if st == 'Playing' else G['pause']} {meta}")


# ---------------------------------------------------------------- arranque
COMMANDS = {"clip": clip_menu, "clip-daemon": clip_daemon, "wifi": wifi, "bluetooth": bluetooth, "cal": cal, "ask": ask, "music": music}


def main():
    name = os.path.basename(sys.argv[0])
    key = name[5:] if name.startswith("mono-") else (sys.argv[1] if len(sys.argv) > 1 else "")
    if key == "clip" and "--daemon" in sys.argv:
        key = "clip-daemon"
    if key not in COMMANDS:
        sys.exit("Uso: menus.py " + " | ".join(COMMANDS))
    COMMANDS[key]()


if __name__ == "__main__":
    main()
