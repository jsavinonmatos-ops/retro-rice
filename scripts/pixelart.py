#!/usr/bin/env python3
"""pixelart: chicas anime en pixel art dibujadas para terminal (32x32), sin dependencias.

  pixelart.py draw NOMBRE  --ansi SALIDA.ansi [--png VISTA.png]   (NOMBRE: sakura yuki mizu kuro)
  pixelart.py sprite ARCHIVO.png --ansi SALIDA.ansi               (tu propio pixel art, PNG de 8 bits)
  pixelart.py config LOGO.ansi ANCHO ALTO SALIDA.jsonc            (configuración de fastfetch)

Cada carácter ▀ dibuja dos píxeles (arriba con el color del texto, abajo con el del fondo).
"""
import json
import struct
import sys
import zlib

W = H = 32
OUTLINE = (34, 22, 40)
SKIN, SKIN_SH, BLUSH, MOUTH = (255, 224, 205), (240, 196, 180), (255, 150, 160), (206, 92, 112)

PALETTES = {
    "sakura": dict(hair=(244, 166, 192), hi=(255, 214, 228), sh=(214, 120, 160), iris=(122, 75, 208), iris2=(176, 140, 240),
                   outfit=(46, 58, 110), trim=(245, 245, 250), ribbon=(226, 64, 90), acc="bow", acc_c=(255, 107, 138)),
    "yuki":   dict(hair=(232, 236, 245), hi=(255, 255, 255), sh=(170, 182, 212), iris=(60, 150, 230), iris2=(150, 212, 255),
                   outfit=(42, 45, 58), trim=(220, 226, 240), ribbon=(120, 208, 255), acc="ears", acc_c=(255, 170, 190)),
    "mizu":   dict(hair=(104, 164, 240), hi=(168, 208, 255), sh=(60, 116, 200), iris=(24, 168, 156), iris2=(120, 228, 210),
                   outfit=(244, 244, 250), trim=(120, 168, 235), ribbon=(255, 120, 150), acc="twin", acc_c=(255, 220, 90)),
    "kuro":   dict(hair=(56, 48, 82), hi=(110, 98, 150), sh=(28, 22, 44), iris=(204, 48, 64), iris2=(255, 120, 132),
                   outfit=(30, 30, 40), trim=(235, 235, 240), ribbon=(224, 40, 70), acc="bow", acc_c=(224, 40, 70)),
}


class Canvas:
    def __init__(self, w=W, h=H):
        self.w, self.h = w, h
        self.px = [[None] * w for _ in range(h)]

    def set(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[y][x] = c

    def get(self, x, y):
        return self.px[y][x] if 0 <= x < self.w and 0 <= y < self.h else None

    def rect(self, x0, y0, x1, y1, c):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.set(x, y, c)

    def ellipse(self, cx, cy, rx, ry, c, where=None):
        for y in range(self.h):
            for x in range(self.w):
                if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0 and (where is None or where(x, y)):
                    self.set(x, y, c)

    def mirror(self, x):
        return self.w - 1 - x


def girl(p, eyes="open"):
    c = Canvas()
    hair, hi, sh = p["hair"], p["hi"], p["sh"]

    # cabello de atrás y mechones largos
    c.ellipse(15.5, 14, 12.5, 12, hair)
    acc = p["acc"]
    long_to = 29 if acc == "twin" else 26
    c.rect(4, 14, 8, long_to, hair)
    c.rect(23, 14, 27, long_to, hair)

    # cuerpo (hombros redondeados), cuello y cara
    c.rect(8, 27, 23, 31, p["outfit"])
    for x, y in ((8, 27), (23, 27)):
        c.set(x, y, None)
    c.rect(14, 22, 17, 27, SKIN_SH)
    c.ellipse(15.5, 17, 8.5, 7.5, SKIN)

    # flequillo con puntas desiguales
    fr = [1, 1, 2, 3, 2, 1, 2, 3, 3, 2, 1, 2, 3, 3, 2, 1, 2, 3, 2, 1, 1, 2, 1, 1, 1]
    for x in range(7, 25):
        bottom = 11 + fr[(x - 7) % len(fr)]
        for y in range(2, bottom + 1):
            if ((x - 15.5) / 11.5) ** 2 + ((y - 12) / 9.5) ** 2 <= 1.0:
                c.set(x, y, hair)
    # mechones laterales delante de las orejas
    c.rect(7, 12, 8, 21, hair)
    c.rect(23, 12, 24, 21, hair)

    # sombra de la cara bajo el flequillo y bajo el mentón
    for x in range(8, 24):
        for y in range(10, 22):
            if c.get(x, y) == SKIN and c.get(x, y - 1) == hair:
                c.set(x, y, SKIN_SH)
    # brillos del cabello: barrido curvo a la izquierda y destellos a la derecha
    for (x, y) in ((9, 9), (9, 8), (10, 7), (11, 6), (12, 5), (13, 4), (14, 4), (15, 4), (12, 6), (13, 5)):
        c.set(x, y, hi)
    for (x, y) in ((19, 5), (20, 6), (21, 8)):
        c.set(x, y, hi)
    for y in range(long_to - 1, long_to + 1):          # sombra solo en las puntas de los mechones
        for x in list(range(4, 9)) + list(range(23, 28)):
            if c.get(x, y) == hair:
                c.set(x, y, sh)
    for y in range(13, 21):                            # sombra suave junto a las mejillas
        for x in (8, 23):
            if c.get(x, y) == hair:
                c.set(x, y, sh)

    if eyes == "open":
        # ojos grandes (4x5): L pestaña, W brillo, a/b/c iris de arriba a abajo
        eye = ("LLLL",
               "LWaa",
               "LabB",
               "LbBc",
               ".ccc")
        cols = {"L": OUTLINE, "W": (255, 255, 255), "a": p["iris"], "b": p["iris"], "B": p["iris2"], "c": p["iris2"]}
        for rowi, row in enumerate(eye):
            for coli, ch in enumerate(row):
                if ch == ".":
                    continue
                c.set(10 + coli, 15 + rowi, cols[ch])               # ojo izquierdo (borde exterior a la izquierda)
                c.set(c.mirror(10 + coli), 15 + rowi, cols[ch])     # ojo derecho en espejo
        # segundo brillo pequeño
        c.set(13, 18, (255, 255, 255)); c.set(c.mirror(13), 18, (255, 255, 255))
    else:                                   # ojos cerrados (parpadeo): un arco "‿" en cada ojo
        for dx, dy in ((0, 2), (1, 3), (2, 3), (3, 2)):
            c.set(10 + dx, 15 + dy, OUTLINE); c.set(c.mirror(10 + dx), 15 + dy, OUTLINE)
    # mejillas y boca
    for x in (9, 10, 21, 22):
        c.set(x, 21, BLUSH)
    c.set(15, 22, MOUTH); c.set(16, 22, MOUTH); c.set(14, 21, MOUTH); c.set(17, 21, MOUTH)

    # uniforme: cuello marinero, lazo
    for y, (a, b) in zip(range(27, 31), ((11, 20), (12, 19), (13, 18), (14, 17))):
        c.rect(a, y, b, y, p["trim"])
    c.rect(15, 27, 16, 29, p["ribbon"])
    c.rect(14, 29, 17, 30, p["ribbon"])

    # accesorios
    ac = p["acc_c"]
    if acc == "bow":
        light = tuple(min(255, v + 45) for v in ac)
        dark = tuple(max(0, v - 60) for v in ac)
        for x0, x1 in ((19, 22), (25, 28)):                       # dos lazadas
            c.rect(x0, 3, x1, 7, ac)
        for (x, y) in ((19, 3), (28, 3), (19, 7), (28, 7)):        # esquinas redondeadas
            c.set(x, y, None)
        c.rect(23, 4, 24, 6, dark)                                 # nudo
        c.set(20, 4, light); c.set(26, 4, light)
    elif acc == "ears":
        for (y, xs) in ((1, (8,)), (2, (8, 9)), (3, (8, 9, 10)), (4, (8, 9, 10, 11)), (5, (8, 9, 10, 11, 12))):
            for x in xs:
                c.set(x, y, hair); c.set(c.mirror(x), y, hair)
        for (x, y) in ((9, 3), (9, 4), (10, 4), (9, 5), (10, 5)):
            c.set(x, y, ac); c.set(c.mirror(x), y, ac)
    elif acc == "twin":
        c.rect(5, 12, 7, 13, ac); c.rect(24, 12, 26, 13, ac)
    return c


def outline(c):
    out = Canvas(c.w, c.h)
    for y in range(c.h):
        for x in range(c.w):
            out.px[y][x] = c.px[y][x]
    for y in range(c.h):
        for x in range(c.w):
            if c.px[y][x] is None and any(c.get(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                out.px[y][x] = OUTLINE
    return out


# ---------------------------------------------------------------- salida
def render_ansi(c):
    """Cada celda = 2 píxeles verticales. Fondo transparente = fondo de la terminal."""
    lines = []
    for y in range(0, c.h, 2):
        row, last = [], None
        for x in range(c.w):
            top, bot = c.get(x, y), c.get(x, y + 1)
            if top and bot:
                code, ch = f"\033[38;2;{top[0]};{top[1]};{top[2]};48;2;{bot[0]};{bot[1]};{bot[2]}m", "▀"
            elif top:
                code, ch = f"\033[0m\033[38;2;{top[0]};{top[1]};{top[2]}m", "▀"
            elif bot:
                code, ch = f"\033[0m\033[38;2;{bot[0]};{bot[1]};{bot[2]}m", "▄"
            else:
                code, ch = "\033[0m", " "
            row.append(code + ch)
        lines.append("".join(row) + "\033[0m")
    return "\n".join(lines) + "\n"


def write_png(path, c, scale=16, alpha=False):
    w, h = c.w * scale, c.h * scale
    raw = bytearray()
    for y in range(h):
        raw.append(0)
        for x in range(w):
            p = c.px[y // scale][x // scale]
            raw.extend((p[0], p[1], p[2], 255) if p else ((0, 0, 0, 0) if alpha else (28, 28, 32, 255)))
    def chunk(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
                + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b""))


def read_png(path):
    """Lee un PNG de 8 bits RGB/RGBA sin entrelazado. Devuelve un Canvas (alfa < 128 = transparente)."""
    data = open(path, "rb").read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("no es un PNG")
    pos, idat, w = 8, b"", 0
    while pos < len(data):
        n, t = struct.unpack(">I4s", data[pos:pos + 8])
        body = data[pos + 8:pos + 8 + n]
        if t == b"IHDR":
            w, h, depth, ctype, _, _, inter = struct.unpack(">IIBBBBB", body)
            if depth != 8 or ctype not in (2, 6) or inter:
                raise ValueError("usa un PNG de 8 bits RGB/RGBA sin entrelazado (mono-pic lo convierte solo)")
        elif t == b"IDAT":
            idat += body
        pos += 12 + n
    bpp = 4 if ctype == 6 else 3
    raw, stride = zlib.decompress(idat), w * bpp
    rows, prev, i = [], bytearray(stride), 0
    for _ in range(h):
        f, line = raw[i], bytearray(raw[i + 1:i + 1 + stride]); i += 1 + stride
        for x in range(stride):
            a = line[x - bpp] if x >= bpp else 0
            b = prev[x]
            cc = prev[x - bpp] if x >= bpp else 0
            if f == 1: line[x] = (line[x] + a) & 255
            elif f == 2: line[x] = (line[x] + b) & 255
            elif f == 3: line[x] = (line[x] + (a + b) // 2) & 255
            elif f == 4:
                pa, pb, pc = abs(b - cc), abs(a - cc), abs(a + b - 2 * cc)
                line[x] = (line[x] + (a if pa <= pb and pa <= pc else b if pb <= pc else cc)) & 255
        rows.append(line); prev = line
    c = Canvas(w, h)
    for y, line in enumerate(rows):
        for x in range(w):
            r, g, b = line[x * bpp:x * bpp + 3]
            if bpp == 3 or line[x * bpp + 3] >= 128:
                c.px[y][x] = (r, g, b)
    return c


def autoscale(c):
    """Si la imagen es pixel art ampliado k veces (bloques kxk idénticos), la devuelve a su tamaño real."""
    for k in range(min(c.w, c.h, 40), 1, -1):
        if c.w % k or c.h % k:
            continue
        if all(c.px[by * k + dy][bx * k + dx] == c.px[by * k][bx * k]
               for by in range(c.h // k) for bx in range(c.w // k) for dy in range(k) for dx in range(k)):
            out = Canvas(c.w // k, c.h // k)
            out.px = [[c.px[y * k][x * k] for x in range(out.w)] for y in range(out.h)]
            return out, k
    return c, 1


def _lum(p):
    return 0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2]


def _axis(edges):
    """Mayor k tal que casi todos los bordes fuertes caen en fronteras múltiplo de k. Devuelve (k, fase) o None."""
    total = sum(edges)
    if total < 20:
        return None
    best = None
    for k in range(2, 41):
        sums = [0] * k
        for x, e in enumerate(edges):
            sums[x % k] += e
        ph = max(range(k), key=lambda i: sums[i])
        if sums[ph] / total >= 0.82:
            best = (k, ph)       # los divisores del k real también cumplen; se queda el mayor
    return best


def detect_grid(c, strong=48):
    """Pixel art ampliado y con ruido: encuentra el tamaño de bloque (kx, ky) y el desfase. Devuelve (kx, ky, px, py) o None."""
    lum = [[_lum(p) if p else 0 for p in row] for row in c.px]
    cols, rows = [0] * c.w, [0] * c.h
    for y in range(c.h):
        row = lum[y]
        for x in range(1, c.w):
            if abs(row[x] - row[x - 1]) > strong:
                cols[x] += 1
    for y in range(1, c.h):
        a, b = lum[y], lum[y - 1]
        for x in range(c.w):
            if abs(a[x] - b[x]) > strong:
                rows[y] += 1
    ax, ay = _axis(cols), _axis(rows)
    if not ax or not ay:
        return None
    return ax[0], ay[0], ax[1], ay[1]


def _median(v):
    v = sorted(v)
    return v[len(v) // 2]


def sample_blocks(c, kx, ky, px, py):
    """Un píxel por bloque: la mediana del centro del bloque (así el ruido de JPEG no importa)."""
    nbx, nby = (c.w - px) // kx, (c.h - py) // ky
    out = Canvas(nbx, nby)
    mx, my = kx // 4, ky // 4
    for by in range(nby):
        for bx in range(nbx):
            x0, y0 = px + bx * kx, py + by * ky
            pix = [c.px[y][x] for y in range(y0 + my, y0 + ky - my) for x in range(x0 + mx, x0 + kx - mx) if c.px[y][x]]
            if len(pix) * 2 >= max(1, (kx - 2 * mx) * (ky - 2 * my)):
                out.px[by][bx] = tuple(_median([p[i] for p in pix]) for i in range(3))
    return out


def palette_of(c, top=8, cover=0.92):
    """Colores dominantes si la imagen usa pocos (estilo pixel art); si no, None."""
    buckets = {}
    for row in c.px:
        for p in row:
            if p:
                b = tuple(v // 16 for v in p)
                acc = buckets.setdefault(b, [0, 0, 0, 0])
                acc[0] += 1; acc[1] += p[0]; acc[2] += p[1]; acc[3] += p[2]
    total = sum(a[0] for a in buckets.values())
    common = sorted(buckets.values(), key=lambda a: -a[0])[:top]
    if not total or sum(a[0] for a in common) / total < cover:
        return None
    return [(a[1] // a[0], a[2] // a[0], a[3] // a[0]) for a in common]


def snap(c, pal):
    if not pal:
        return c
    cache = {}
    for y in range(c.h):
        for x in range(c.w):
            p = c.px[y][x]
            if p:
                if p not in cache:
                    cache[p] = min(pal, key=lambda q: (p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2 + (p[2] - q[2]) ** 2)
                c.px[y][x] = cache[p]
    return c


def box_shrink(c, nw, nh):
    out = Canvas(nw, nh)
    for y in range(nh):
        y0, y1 = int(y * c.h / nh), max(int(y * c.h / nh) + 1, int((y + 1) * c.h / nh))
        for x in range(nw):
            x0, x1 = int(x * c.w / nw), max(int(x * c.w / nw) + 1, int((x + 1) * c.w / nw))
            pix = [c.px[j][i] for j in range(y0, min(y1, c.h)) for i in range(x0, min(x1, c.w)) if c.px[j][i]]
            n = (min(y1, c.h) - y0) * (min(x1, c.w) - x0)
            if pix and len(pix) * 2 >= n:
                out.px[y][x] = tuple(sum(p[i] for p in pix) // len(pix) for i in range(3))
    return out


def fit(c, maxw, maxh, pal=None):
    """Reduce por promedio de áreas (no por salto de píxeles) hasta que quepa; vuelve a la paleta original si era corta."""
    f = min(maxw / c.w, maxh / c.h)
    if f >= 1:
        return c
    return snap(box_shrink(c, max(1, int(c.w * f)), max(1, int(c.h * f))), pal)


def shrink(c, width):
    """Reduce al ancho dado por vecino más cercano (sin mezclar colores)."""
    if c.w <= width:
        return c
    h = max(1, round(c.h * width / c.w))
    out = Canvas(width, h)
    out.px = [[c.px[min(c.h - 1, int(y * c.h / h))][min(c.w - 1, int(x * c.w / width))] for x in range(width)] for y in range(h)]
    return out


def _frame(p, eyes, dy):
    """Un cuadro de la animación: la chica con los ojos abiertos/cerrados, desplazada dy píxeles (respiración)."""
    g = outline(girl(p, eyes))
    c = Canvas(32, 34)
    for y in range(32):
        for x in range(32):
            c.px[y + dy][x] = g.px[y][x]
    return render_ansi(c)


def pet(name="sakura", seconds=None):
    """Chica de pixel art animada en la terminal: parpadea y respira. Salir: q, Esc o Ctrl+C."""
    import random, select, termios, tty, time
    p = PALETTES[name]
    frames = {(e, d): _frame(p, e, d) for e in ("open", "closed") for d in (1, 2)}
    rows = 17
    if not sys.stdin.isatty():                       # sin terminal interactiva: solo un cuadro
        sys.stdout.write(frames[("open", 1)]); return
    fd, old = sys.stdin.fileno(), termios.tcgetattr(sys.stdin.fileno())
    t0 = time.time(); next_blink = t0 + random.uniform(2.5, 5); blink_until = 0; last = None
    try:
        tty.setcbreak(fd); sys.stdout.write("\033[?25l")
        while True:
            now = time.time()
            if now >= next_blink:
                blink_until, next_blink = now + 0.18, now + random.uniform(2.5, 6)
            key = ("closed" if now < blink_until else "open", 1 + int(now / 1.4) % 2)
            if key != last:
                if last is not None:
                    sys.stdout.write(f"\033[{rows}A")
                sys.stdout.write(frames[key]); sys.stdout.flush(); last = key
            if select.select([sys.stdin], [], [], 0.05)[0] and sys.stdin.read(1) in ("q", "\x1b", "\x03"):
                break
            if seconds and now - t0 > seconds:
                break
    except KeyboardInterrupt:
        pass
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)
        sys.stdout.write("\033[?25h\033[0m\n")


def boot_images(name, grub_png, plymouth_png, w=1920, h=1080, scale=18):
    """Fondo negro con la chica a la derecha (menú de GRUB) y la imagen para la pantalla de arranque (Plymouth)."""
    g = outline(girl(PALETTES[name]))
    bg = bytes((10, 10, 12))
    sw = g.w * scale
    x0, y0 = w - sw - 200, (h - g.h * scale) // 2
    srows = []
    for y in range(g.h):
        srows.append(b"".join((bytes(p) if p else bg) * scale for p in g.px[y]))
    blank = b"\x00" + bg * w
    raw = bytearray()
    for y in range(h):
        sy = (y - y0) // scale
        if 0 <= y - y0 < g.h * scale:
            raw += b"\x00" + bg * x0 + srows[sy] + bg * (w - x0 - sw)
        else:
            raw += blank
    def chunk(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)
    with open(grub_png, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
                + chunk(b"IDAT", zlib.compress(bytes(raw), 6)) + chunk(b"IEND", b""))
    write_png(plymouth_png, g, scale=8, alpha=True)


def write_config(logo, width, height, out, position="left", typ="file-raw"):
    def cmd(key, text):
        return {"type": "command", "key": key, "text": text}
    modules = [
        {"type": "title"}, "break",
        cmd("OS", '. /etc/os-release; echo "$NAME $VERSION_ID" | cut -c1-28'),
        cmd("Kernel", "uname -r | cut -c1-28"),
        cmd("Uptime", "uptime -p | sed 's/^up //; s/ hours\\?/h/; s/ minutes\\?/m/; s/,//g' | cut -c1-28"),
        cmd("Shell", "basename \"$SHELL\""),
        cmd("CPU", "lscpu | sed -n 's/^Model name:[[:space:]]*//p' | sed -E 's/ with .*//; s/ [0-9]+-Core.*//' | cut -c1-28"),
        cmd("RAM", "free -h | awk '/^Mem/ {print $3 \" / \" $2}'"),
        cmd("Disk", "df -h / | awk 'NR==2 {print $3 \" / \" $2}'"),
        "break", {"type": "colors", "symbol": "circle"},
    ]
    pad = {"top": 0, "right": 2} if position == "left" else {"top": 0, "bottom": 1}
    cfg = {"logo": {"type": typ, "source": logo, "width": width, "height": height,
                    "position": position, "padding": pad},
           "display": {"separator": "  ", "color": {"keys": "magenta", "title": "magenta"}},
           "modules": modules}
    with open(out, "w", encoding="utf-8") as f:
        json.dump(cfg, f, ensure_ascii=False, indent=2)


def main(argv):
    real_cells = None
    if len(argv) >= 3 and argv[0] == "draw":
        if argv[1] not in PALETTES:
            sys.exit("nombres: " + " ".join(PALETTES))
        canvas = outline(girl(PALETTES[argv[1]]))
    elif len(argv) >= 3 and argv[0] == "sprite":
        opt = lambda name: argv[argv.index(name) + 1] if name in argv else None
        canvas = read_png(argv[1])
        if opt("--scale"):                                   # ampliación indicada a mano
            k = int(opt("--scale"))
            canvas = sample_blocks(canvas, k, k, 0, 0)
        else:
            canvas, k = autoscale(canvas)                    # ampliación exacta (PNG limpio)
            if k > 1:
                print(f"detecté pixel art ampliado x{k}: lo devuelvo a su tamaño real", file=sys.stderr)
            else:
                g = detect_grid(canvas)                      # ampliación con ruido (JPEG)
                if g:
                    canvas = sample_blocks(canvas, *g)
                    print(f"detecté la cuadrícula del pixel art (bloques de {g[0]}x{g[1]}) aunque la imagen tiene ruido: "
                          f"resolución real {canvas.w}x{canvas.h}", file=sys.stderr)
        raw = canvas
        maxw, maxh = int(opt("--width") or 64), 2 * int(opt("--rows") or 22)
        pal = palette_of(canvas)
        if canvas.w > maxw or canvas.h > maxh:
            print(f"mide {canvas.w}x{canvas.h}: para que quepa en texto la reduzco por promedio a un máximo de {maxw}x{maxh} "
                  f"(con --real se muestra completa)", file=sys.stderr)
            canvas = fit(canvas, maxw, maxh, pal)
        if opt("--real"):                                    # imagen real con el protocolo gráfico de kitty
            big = opt("--real")
            write_png(big, raw, scale=max(1, 520 // raw.h), alpha=True)
            write_png(big.replace("pic.png", "pic-ai.png"), raw, scale=max(1, 260 // raw.h), alpha=True)
            cols = 36
            rows = round(cols * raw.h / raw.w / 2.1)
            if rows > 24:
                rows = 24; cols = round(rows * 2.1 * raw.w / raw.h)
            real_cells = f"{cols}x{rows}"
    elif argv and argv[0] == "pet":
        name = argv[1] if len(argv) > 1 and argv[1] in PALETTES else "sakura"
        pet(name, float(argv[argv.index("--seconds") + 1]) if "--seconds" in argv else None); return
    elif len(argv) == 4 and argv[0] == "bootimg":
        boot_images(argv[1] if argv[1] in PALETTES else "sakura", argv[2], argv[3]); return
    elif len(argv) in (5, 6) and argv[0] == "config":
        typ = argv[5] if len(argv) == 6 else "file-raw"
        write_config(argv[1], int(argv[2]), int(argv[3]), argv[4], "left", typ)                                   # logo a la izquierda
        write_config(argv[1], int(argv[2]), int(argv[3]), argv[4].replace(".jsonc", "-top.jsonc"), "top", typ)    # logo arriba (ventanas angostas)
        return
    else:
        sys.exit(__doc__)
    if "--png" in argv:
        write_png(argv[argv.index("--png") + 1], canvas)
    if "--ansi" in argv:
        with open(argv[argv.index("--ansi") + 1], "w", encoding="utf-8") as f:
            f.write(render_ansi(canvas))
        print(f"{canvas.w}x{(canvas.h + 1) // 2}")
        if real_cells:
            print(real_cells)


if __name__ == "__main__":
    main(sys.argv[1:])
