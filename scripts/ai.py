#!/usr/bin/env python3
"""mono-ai: asistente local (Ollama) para archivos, búsqueda web y control del sistema.

Seguridad:
  - Los comandos de shell SIEMPRE piden confirmación y muestran el comando exacto.
  - Hay un bloqueo duro para comandos destructivos (rm -rf /, mkfs, dd a discos, curl | sh...).
  - Leer/listar/buscar archivos solo funciona dentro de tu carpeta personal y evita carpetas sensibles.
  - Todo lo ejecutado queda en ~/.local/share/mono-ai/log.txt

Uso:  mono-ai            (chat)      mono-ai "pregunta"   (una sola pregunta)
Modelo: ~/.config/mono-ai/model  o variable MONO_AI_MODEL  (por defecto qwen2.5:7b)
"""
import datetime
import fnmatch
import html
import json
import os
import re
import shlex
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from html.parser import HTMLParser

HOME = os.path.realpath(os.path.expanduser("~"))
CONF_DIR = os.path.join(HOME, ".config", "mono-ai")
LOG_DIR = os.path.join(HOME, ".local", "share", "mono-ai")
LOG_FILE = os.path.join(LOG_DIR, "log.txt")
HOST = os.environ.get("MONO_AI_HOST", "http://127.0.0.1:11434")
UA = "Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0"

B, DIM, RED, GRN, YEL, CYA, RST = "\033[1m", "\033[2m", "\033[31m", "\033[32m", "\033[33m", "\033[36m", "\033[0m"

SENSITIVE = {".ssh", ".gnupg", ".aws", ".kube", ".password-store", ".mozilla", ".docker",
             ".zsh_history", ".bash_history", ".netrc", ".npmrc", ".pypirc", ".claude", ".claude.json"}

BLOCKED = [
    r"\bmkfs", r"\bdd\s+.*of=/dev/", r":\(\)\s*\{", r">\s*/dev/(sd|nvme|mmcblk)",
    r"\bchmod\s+-R\s+\d+\s+/(\s|$)", r"\bchown\s+-R\s+\S+\s+/(\s|$)",
    r"(curl|wget)[^|;]*\|\s*(sudo\s+)?(ba|z)?sh", r"\bshred\b.*(/dev/|~)",
]
RISKY = [r"\bsudo\b", r"\brm\b", r"\bapt(-get)?\s+(remove|purge|autoremove)", r"\bsystemctl\b",
         r"\bkill(all)?\b|\bpkill\b", r"\bmv\b", r"\bchmod\b|\bchown\b", r">", r"\breboot\b|\bshutdown\b|\bpoweroff\b"]

SYSTEM = (
    "Eres mono-ai, un asistente que corre localmente en un portátil con Debian y el gestor de ventanas i3. "
    "Respondes SIEMPRE en español, de forma breve y directa. "
    "Tienes herramientas: úsalas para obtener datos reales en vez de inventarlos. "
    "Prefiere las herramientas específicas (system_status, set_volume, change_wallpaper, list_dir, read_file, "
    "search_files, web_search, fetch_url) y usa run_shell solo cuando no exista una específica. "
    "Antes de run_shell, explica en una frase qué hará; el usuario confirmará. "
    "Nunca ejecutes comandos destructivos ni inventes resultados. Si no sabes algo, búscalo o dilo. "
    "Cuando busques en internet, resume lo encontrado y cita la dirección (URL) de la fuente."
)


def _tool(name, desc, props=None, required=None):
    return {"type": "function", "function": {"name": name, "description": desc,
            "parameters": {"type": "object", "properties": props or {}, "required": required or []}}}


TOOLS = [
    _tool("system_status", "Muestra RAM, disco, carga del sistema y los procesos que más memoria usan."),
    _tool("list_dir", "Lista el contenido de una carpeta dentro de la carpeta personal.",
          {"path": {"type": "string", "description": "Ruta, por ejemplo ~/Descargas"}}, ["path"]),
    _tool("read_file", "Lee un archivo de texto (o PDF) de la carpeta personal.",
          {"path": {"type": "string"}, "max_chars": {"type": "integer"}}, ["path"]),
    _tool("search_files", "Busca archivos por parte del nombre dentro de la carpeta personal.",
          {"query": {"type": "string", "description": "Texto que debe contener el nombre"},
           "directory": {"type": "string", "description": "Carpeta donde buscar, por defecto ~"}}, ["query"]),
    _tool("web_search", "Busca en internet (DuckDuckGo) y devuelve títulos, enlaces y resúmenes.",
          {"query": {"type": "string"}}, ["query"]),
    _tool("fetch_url", "Descarga una página web y devuelve su texto.",
          {"url": {"type": "string"}}, ["url"]),
    _tool("set_volume", "Cambia el volumen del sistema (0 a 100).",
          {"percent": {"type": "integer"}}, ["percent"]),
    _tool("change_wallpaper", "Cambia el fondo de pantalla. kind: any, mono (blanco y negro) o color.",
          {"kind": {"type": "string"}}),
    _tool("run_shell", "Ejecuta un comando de shell. El usuario debe confirmar cada comando.",
          {"command": {"type": "string"}}, ["command"]),
]


# ---------------------------------------------------------------- utilidades
def log(event):
    try:
        os.makedirs(LOG_DIR, exist_ok=True)
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(f"{datetime.datetime.now().isoformat(timespec='seconds')} {event}\n")
    except OSError:
        pass


def model_name():
    if os.environ.get("MONO_AI_MODEL"):
        return os.environ["MONO_AI_MODEL"]
    try:
        with open(os.path.join(CONF_DIR, "model"), encoding="utf-8") as f:
            m = f.read().strip()
            if m:
                return m
    except OSError:
        pass
    return "qwen2.5:7b"


def safe_path(p):
    """Devuelve una ruta real dentro de HOME y fuera de carpetas sensibles, o lanza ValueError."""
    p = os.path.expanduser(str(p or "~"))
    if not os.path.isabs(p):
        p = os.path.join(HOME, p)
    real = os.path.realpath(p)
    if real != HOME and not real.startswith(HOME + os.sep):
        raise ValueError("solo puedo acceder a tu carpeta personal")
    parts = real[len(HOME):].strip(os.sep).split(os.sep)
    if any(part in SENSITIVE for part in parts):
        raise ValueError("esa ubicación es sensible y está bloqueada")
    return real


DANGEROUS_TARGETS = {"/", "/*", "~", "~/", "~/*", "$HOME", "$HOME/", "$HOME/*", "${HOME}", "/home", "/home/", "/home/*",
                     "/etc", "/usr", "/var", "/bin", "/sbin", "/boot", "/lib", "/lib64", "/opt", "/root", "/srv",
                     ".", "..", "*", ".*", HOME, HOME + "/", HOME + "/*"}


def rm_dangerous(cmd):
    """True si algún tramo del comando es un 'rm' recursivo sobre la raíz, el home o carpetas del sistema."""
    for seg in re.split(r"&&|\|\||;|\||\n", cmd):
        try:
            toks = shlex.split(seg)
        except ValueError:
            return True      # comando que no se puede analizar: por prudencia, se bloquea
        # buscar 'rm' en cualquier posición (así vale sudo -E rm, env X=1 rm, nice rm...). Es conservador a propósito.
        idx = next((i for i, t in enumerate(toks) if os.path.basename(t) == "rm"), None)
        if idx is None:
            continue
        toks = toks[idx:]
        flags = [t for t in toks[1:] if t.startswith("-")]
        recursive = any(t in ("--recursive",) or (not t.startswith("--") and ("r" in t.lower())) for t in flags)
        targets = [t.rstrip("/") + "/" if t not in ("/",) and t.endswith("/") else t for t in toks[1:] if not t.startswith("-")]
        if recursive and any((t in DANGEROUS_TARGETS) or (t.rstrip("/") in DANGEROUS_TARGETS) for t in targets):
            return True
    return False


def is_blocked(cmd):
    return rm_dangerous(cmd) or any(re.search(p, cmd) for p in BLOCKED)


def is_risky(cmd):
    return any(re.search(p, cmd) for p in RISKY)


class _Text(HTMLParser):
    def __init__(self):
        super().__init__()
        self.out, self.skip = [], 0

    def handle_starttag(self, tag, attrs):
        if tag in ("script", "style", "noscript", "svg", "head"):
            self.skip += 1

    def handle_endtag(self, tag):
        if tag in ("script", "style", "noscript", "svg", "head") and self.skip:
            self.skip -= 1

    def handle_data(self, data):
        if not self.skip and data.strip():
            self.out.append(data.strip())


def html_to_text(raw):
    p = _Text()
    p.feed(raw)
    return re.sub(r"\s+", " ", " ".join(p.out))


def http_get(url, timeout=20, limit=1_500_000):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept-Language": "es,en;q=0.8"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        data = r.read(limit)
        ctype = r.headers.get("Content-Type", "")
    m = re.search(r"charset=([\w-]+)", ctype)
    return data.decode(m.group(1) if m else "utf-8", errors="replace"), ctype


def parse_ddg(page, n=5):
    links = re.findall(r'<a[^>]*class="result__a"[^>]*href="([^"]+)"[^>]*>(.*?)</a>', page, re.S)
    snips = re.findall(r'class="result__snippet"[^>]*>(.*?)</a>', page, re.S)
    out = []
    for i, (href, title) in enumerate(links[:n]):
        href = html.unescape(href)
        q = urllib.parse.urlparse(href if href.startswith("http") else "https:" + href).query
        real = urllib.parse.parse_qs(q).get("uddg", [href])[0]
        clean = lambda s: html.unescape(re.sub(r"<[^>]+>", "", s)).strip()
        out.append(f"{i + 1}. {clean(title)}\n   {real}\n   {clean(snips[i]) if i < len(snips) else ''}")
    return "\n".join(out)


# ---------------------------------------------------------------- herramientas
def t_system_status(_):
    parts = []
    for cmd in (["free", "-h"], ["df", "-h", "/"], ["uptime"], ["bash", "-c", "ps aux --sort=-%mem | head -6 | cut -c1-150"]):
        r = subprocess.run(cmd, capture_output=True, text=True)
        parts.append(r.stdout.strip())
    return "\n\n".join(parts)


def t_list_dir(a):
    p = safe_path(a.get("path", "~"))
    names = sorted(os.listdir(p), key=str.lower)
    lines = [n + ("/" if os.path.isdir(os.path.join(p, n)) else "") for n in names if not n.startswith(".")]
    return f"{p}  ({len(lines)} elementos visibles)\n" + "\n".join(lines[:200])


def t_read_file(a):
    p = safe_path(a.get("path"))
    n = max(200, min(int(a.get("max_chars") or 6000), 12000))
    if p.lower().endswith(".pdf"):
        r = subprocess.run(["pdftotext", "-layout", p, "-"], capture_output=True, text=True)
        return (r.stdout or r.stderr or "no pude leer el PDF (instala poppler-utils)")[:n]
    with open(p, "rb") as f:
        raw = f.read(n * 4)
    if b"\0" in raw[:2000]:
        return "archivo binario, no se puede mostrar"
    return raw.decode("utf-8", errors="replace")[:n]


def t_search_files(a):
    q = str(a.get("query", "")).lower()
    root = safe_path(a.get("directory", "~"))
    found, start = [], time.time()
    for d, dirs, files in os.walk(root):
        dirs[:] = [x for x in dirs if not x.startswith(".") and x not in ("node_modules", "__pycache__") and x not in SENSITIVE]
        for f in files + dirs:
            if fnmatch.fnmatch(f.lower(), f"*{q}*"):
                found.append(os.path.join(d, f))
        if len(found) >= 50 or time.time() - start > 10:
            break
    return "\n".join(found) or "sin resultados"


def t_web_search(a):
    q = urllib.parse.quote_plus(str(a.get("query", "")))
    page, _ = http_get(f"https://html.duckduckgo.com/html/?q={q}")
    return parse_ddg(page) or "sin resultados (o DuckDuckGo cambió su formato)"


def t_fetch_url(a):
    url = str(a.get("url", ""))
    if not re.match(r"^https?://", url):
        raise ValueError("solo se permiten direcciones http y https")
    page, ctype = http_get(url)
    text = html_to_text(page) if "html" in ctype.lower() else page
    return text[:6000]


def t_set_volume(a):
    v = max(0, min(100, int(a.get("percent", 50))))
    r = subprocess.run(["pactl", "set-sink-volume", "@DEFAULT_SINK@", f"{v}%"], capture_output=True, text=True)
    return f"volumen {v}%" if r.returncode == 0 else r.stderr


def t_change_wallpaper(a):
    kind = str(a.get("kind", "any"))
    cmd = ["mono-wall"] + ([kind] if kind in ("mono", "color") else [])
    r = subprocess.run(cmd, capture_output=True, text=True)
    return "fondo cambiado" if r.returncode == 0 else (r.stderr or "no pude cambiar el fondo")


def t_run_shell(a):
    cmd = str(a.get("command", "")).strip()
    if not cmd:
        return "comando vacío"
    if is_blocked(cmd):
        log(f"BLOQUEADO {cmd}")
        print(f"{RED}✗ Comando bloqueado por seguridad:{RST} {cmd}")
        return "BLOQUEADO: ese comando es destructivo y no se ejecuta nunca."
    warn = f"  {RED}{B}(modifica el sistema o los archivos){RST}" if is_risky(cmd) else ""
    print(f"\n{YEL}{B}Comando propuesto:{RST}{warn}\n  {CYA}{cmd}{RST}")
    try:
        ok = input(f"{B}¿Ejecutarlo? [s/N] {RST}").strip().lower() in ("s", "si", "sí", "y", "yes")
    except EOFError:
        ok = False
    if not ok:
        log(f"RECHAZADO {cmd}")
        return "el usuario rechazó ejecutar el comando"
    log(f"EJECUTADO {cmd}")
    try:
        r = subprocess.run(cmd, shell=True, executable="/bin/bash", cwd=HOME,
                           stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=180)
    except subprocess.TimeoutExpired:
        return "el comando tardó más de 3 minutos y se detuvo"
    out = (r.stdout or "").strip()
    return f"código de salida {r.returncode}\n{out[-4000:]}"


IMPL = {"system_status": t_system_status, "list_dir": t_list_dir, "read_file": t_read_file,
        "search_files": t_search_files, "web_search": t_web_search, "fetch_url": t_fetch_url,
        "set_volume": t_set_volume, "change_wallpaper": t_change_wallpaper, "run_shell": t_run_shell}


def run_tool(name, args):
    fn = IMPL.get(name)
    if not fn:
        return f"herramienta desconocida: {name}"
    try:
        return str(fn(args or {}))[:6000]
    except Exception as e:  # el modelo debe ver el error para corregirse
        return f"error: {e}"


# ---------------------------------------------------------------- modelo
def ollama_chat(messages):
    body = json.dumps({"model": model_name(), "messages": messages, "tools": TOOLS, "stream": True,
                       "options": {"num_ctx": 8192, "temperature": 0.3}}).encode()
    req = urllib.request.Request(HOST + "/api/chat", data=body, headers={"Content-Type": "application/json"})
    content, calls, first = "", [], True
    print(f"{DIM}pensando…{RST}", end="", flush=True)
    with urllib.request.urlopen(req, timeout=900) as r:
        for line in r:
            if not line.strip():
                continue
            d = json.loads(line)
            if "error" in d:
                raise RuntimeError(d["error"])
            m = d.get("message", {})
            c = m.get("content", "")
            if c:
                if first:
                    print("\r\033[K", end="")
                    first = False
                print(c, end="", flush=True)
                content += c
            calls += m.get("tool_calls") or []
    if first:
        print("\r\033[K", end="")
    return content, calls


def fallback_calls(content):
    """Algunos modelos escriben la llamada como JSON en el texto en vez de usar tool_calls."""
    m = re.search(r"\{.*\}", content, re.S)
    if not m:
        return []
    try:
        d = json.loads(m.group(0))
    except ValueError:
        return []
    if isinstance(d, dict) and d.get("name") in IMPL:
        return [{"function": {"name": d["name"], "arguments": d.get("arguments") or d.get("parameters") or {}}}]
    return []


def turn(messages):
    for _ in range(8):
        content, calls = ollama_chat(messages)
        if not calls:
            calls = fallback_calls(content)
        msg = {"role": "assistant", "content": content}
        if calls:
            msg["tool_calls"] = calls
        messages.append(msg)
        if not calls:
            print()
            return
        for call in calls:
            fn = call.get("function", {})
            name, args = fn.get("name", ""), fn.get("arguments") or {}
            if isinstance(args, str):
                try:
                    args = json.loads(args)
                except ValueError:
                    args = {}
            if name != "run_shell":
                print(f"\n{DIM}→ {name}({', '.join(f'{k}={v!r}' for k, v in args.items())}){RST}")
            result = run_tool(name, args)
            messages.append({"role": "tool", "tool_name": name, "content": result})
    print(f"\n{YEL}(llegué al límite de pasos; reformula o divide la tarea){RST}")


def check_ollama():
    try:
        with urllib.request.urlopen(HOST + "/api/tags", timeout=5) as r:
            names = [m["name"] for m in json.load(r).get("models", [])]
    except Exception:
        sys.exit(f"{RED}Ollama no responde.{RST} Instálalo con: mono-ai-setup   (o arráncalo: sudo systemctl start ollama)")
    want = model_name()
    if not any(n == want or n.split(":")[0] == want for n in names):
        sys.exit(f"{RED}El modelo '{want}' no está descargado.{RST} Ejecuta: mono-ai-setup")


def main():
    check_ollama()
    messages = [{"role": "system", "content": SYSTEM}]
    if len(sys.argv) > 1:
        messages.append({"role": "user", "content": " ".join(sys.argv[1:])})
        turn(messages)
        return
    print(f"{B}mono-ai{RST} · modelo {model_name()} · /salir para cerrar · /limpiar para empezar de nuevo")
    print(f"{DIM}Los comandos que modifican algo piden tu confirmación. Registro: {LOG_FILE}{RST}\n")
    while True:
        try:
            q = input(f"{GRN}{B}tú ›{RST} ").strip()
        except (EOFError, KeyboardInterrupt):
            print()
            return
        if not q:
            continue
        if q in ("/salir", "/exit", "salir"):
            return
        if q == "/limpiar":
            messages = messages[:1]
            print("(conversación reiniciada)")
            continue
        messages.append({"role": "user", "content": q})
        print(f"{CYA}{B}ia ›{RST} ", end="", flush=True)
        try:
            turn(messages)
        except KeyboardInterrupt:
            print(f"\n{YEL}(interrumpido){RST}")
        except Exception as e:
            print(f"\n{RED}error: {e}{RST}")
        if len(messages) > 40:   # mantener el contexto manejable
            messages = messages[:1] + messages[-30:]


if __name__ == "__main__":
    main()
