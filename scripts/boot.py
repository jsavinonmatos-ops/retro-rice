#!/usr/bin/env python3
"""mono-boot: menú de arranque (GRUB) y pantalla de inicio (Plymouth) en blanco y negro con pixel art.

  mono-boot            revisa y muestra el plan (no cambia nada)
  mono-boot --apply    lo aplica (pide escribir SI). Copias de seguridad con extensión .mono-boot.bak
  mono-boot --revert   vuelve a lo anterior

Es SEGURO por diseño: si el tema de GRUB falla, GRUB muestra su menú normal. La pantalla de inicio (Plymouth)
solo se instala si tu disco NO está cifrado, porque con cifrado hay que ver el campo de la contraseña
(si quieres forzarla igual: --apply --plymouth).
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.realpath(__file__))
GRUB = "/etc/default/grub"
THEME_DIR = "/boot/grub/themes/retro-rice"
PLY_DIR = "/usr/share/plymouth/themes/retro-rice"
BAK = ".mono-boot.bak"
FONT = "Unifont Regular 16"          # el pf2 que trae GRUB (/usr/share/grub/unicode.pf2): pixelada, combina con el estilo


# ---------------------------------------------------------------- funciones puras (con pruebas)
def theme_txt():
    return f'''desktop-image: "background.png"
desktop-color: "#0a0a0c"
title-text: ""
terminal-font: "{FONT}"

+ boot_menu {{
  left = 6%
  top = 26%
  width = 42%
  height = 50%
  item_font = "{FONT}"
  item_color = "#8c8c8c"
  selected_item_color = "#ffffff"
  item_height = 34
  item_padding = 8
  item_spacing = 6
  scrollbar = false
}}

+ label {{
  id = "__timeout__"
  left = 6%
  top = 80%
  width = 40%
  align = "left"
  text = "Arrancando en %d s"
  color = "#8c8c8c"
  font = "{FONT}"
}}

+ label {{
  left = 6%
  top = 87%
  width = 60%
  align = "left"
  text = "Flechas para elegir  ·  Enter para arrancar  ·  e para editar"
  color = "#555555"
  font = "{FONT}"
}}
'''


def set_var(text, key, value):
    """Fija KEY=value en el archivo de GRUB: sustituye la línea (activa o comentada) o la agrega al final."""
    line = f'{key}={value}'
    pat = re.compile(rf'^\s*#?\s*{re.escape(key)}=.*$', re.M)
    if pat.search(text):
        return pat.sub(line, text, count=1) if not re.search(rf'^{re.escape(key)}=', text, re.M) else \
            re.sub(rf'^{re.escape(key)}=.*$', line, text, count=1, flags=re.M)
    return text.rstrip("\n") + "\n" + line + "\n"


def grub_apply(text):
    text = set_var(text, "GRUB_THEME", f'"{THEME_DIR}/theme.txt"')
    text = set_var(text, "GRUB_GFXMODE", '"1920x1080,auto"')
    text = set_var(text, "GRUB_GFXPAYLOAD_LINUX", "keep")
    # un terminal "console" forzado impide que se vea el tema
    text = re.sub(r'^(GRUB_TERMINAL(_OUTPUT)?=.*console.*)$', r'#\1', text, flags=re.M)
    return text


def add_splash(text):
    def fix(m):
        toks = m.group(3).split()
        if "splash" not in toks:
            toks.append("splash")
        return f'{m.group(1)}{m.group(2)}{" ".join(toks)}{m.group(2)}'
    new, n = re.subn(r'^(GRUB_CMDLINE_LINUX_DEFAULT=)(["\'])(.*)\2\s*$', fix, text, count=1, flags=re.M)
    return new if n else text.rstrip("\n") + '\nGRUB_CMDLINE_LINUX_DEFAULT="quiet splash"\n'


def ply_files():
    plymouth = f'''[Plymouth Theme]
Name=retro-rice
Description=Pixel art en blanco y negro
ModuleName=script

[script]
ImageDir={PLY_DIR}
ScriptFile={PLY_DIR}/retro-rice.script
'''
    script = '''Window.SetBackgroundTopColor(0.04, 0.04, 0.05);
Window.SetBackgroundBottomColor(0.04, 0.04, 0.05);

logo.image = Image("girl.png");
logo.sprite = Sprite(logo.image);
logo.sprite.SetX(Window.GetX() + Window.GetWidth() / 2 - logo.image.GetWidth() / 2);
logo.sprite.SetY(Window.GetY() + Window.GetHeight() / 2 - logo.image.GetHeight() / 2);

frame = 0;
fun refresh_callback() {
  frame++;
  logo.sprite.SetOpacity(0.72 + 0.28 * Math.Sin(frame / 14));
}
Plymouth.SetRefreshFunction(refresh_callback);
'''
    return plymouth, script


# ---------------------------------------------------------------- sistema
def sh(cmd, check=True, inp=None):
    r = subprocess.run(cmd, capture_output=True, text=True, input=inp)
    if check and r.returncode != 0:
        sys.exit(f"Falló: {' '.join(cmd)}\n{r.stderr.strip() or r.stdout.strip()}")
    return r.stdout


def read(p):
    try:
        with open(p, encoding="utf-8") as f:
            return f.read()
    except OSError:
        return ""


def sudo_write(path, text):
    sh(["sudo", "tee", path], inp=text)


def has_luks():
    return "crypt" in sh(["lsblk", "-no", "TYPE"], check=False)


def character():
    name = read(os.path.expanduser("~/.config/mono-rice/pic.name")).strip()
    return name if name in ("sakura", "yuki", "mizu", "kuro") else "sakura"


def report():
    ok = lambda s: print(f"  \033[32m✔\033[0m {s}")
    bad = lambda s: print(f"  \033[31m✘\033[0m {s}")
    problems = []
    print("== Pantalla de arranque ==")
    if os.path.exists(GRUB):
        ok(f"GRUB encontrado ({GRUB})")
    else:
        bad("No encuentro GRUB: este equipo arranca con otro gestor y no lo toco"); problems.append("grub")
    crypt = has_luks()
    (ok if not crypt else bad)("Disco " + ("SIN cifrar: se puede poner la pantalla de inicio" if not crypt
                                         else "cifrado: solo se cambia el menú de GRUB (la pantalla de inicio podría ocultar la contraseña)"))
    print(f"\nPlan: tema de GRUB con {character()} (fondo negro, texto blanco y gris, tipografía pixelada)"
          + ("" if crypt else " y pantalla de inicio de Plymouth con la misma imagen") + ".")
    return problems, crypt


def apply():
    problems, crypt = report()
    if problems:
        sys.exit("\nNo se puede continuar. No cambié nada.")
    plymouth = (not crypt) or "--plymouth" in sys.argv
    if input("\nEscribe SI para aplicar: ").strip() != "SI":
        sys.exit("Cancelado.")
    tmp = tempfile.mkdtemp()
    sh([sys.executable, "-I", os.path.join(HERE, "pixelart.py"), "bootimg", character(), f"{tmp}/background.png", f"{tmp}/girl.png"])
    with open(f"{tmp}/theme.txt", "w", encoding="utf-8") as f:
        f.write(theme_txt())

    print("==> Tema de GRUB")
    sh(["sudo", "mkdir", "-p", THEME_DIR])
    for name in ("background.png", "theme.txt"):
        sh(["sudo", "cp", f"{tmp}/{name}", f"{THEME_DIR}/{name}"])
    if os.path.exists("/usr/share/grub/unicode.pf2"):
        sh(["sudo", "cp", "/usr/share/grub/unicode.pf2", f"{THEME_DIR}/unicode.pf2"])
    sh(["sudo", "cp", GRUB, GRUB + BAK])
    new = grub_apply(read(GRUB))

    if plymouth:
        print("==> Pantalla de inicio (Plymouth)")
        sh(["sudo", "apt-get", "install", "-y", "plymouth", "plymouth-themes"])
        prev = sh(["plymouth-set-default-theme"], check=False).strip()
        sh(["sudo", "mkdir", "-p", "/etc/plymouth"])
        sudo_write("/etc/plymouth/mono-boot-prev", prev + "\n")
        pl, script = ply_files()
        sh(["sudo", "mkdir", "-p", PLY_DIR])
        sudo_write(f"{PLY_DIR}/retro-rice.plymouth", pl)
        sudo_write(f"{PLY_DIR}/retro-rice.script", script)
        sh(["sudo", "cp", f"{tmp}/girl.png", f"{PLY_DIR}/girl.png"])
        new = add_splash(new)

    sudo_write(GRUB, new)
    sh(["sudo", "update-grub"])
    if plymouth:
        sh(["sudo", "plymouth-set-default-theme", "-R", "retro-rice"])
    shutil.rmtree(tmp, ignore_errors=True)
    print("\nListo. Reinicia para verlo. Si algo no te gusta:  mono-boot --revert")


def revert():
    if input("Escribe SI para volver al arranque anterior: ").strip() != "SI":
        sys.exit("Cancelado.")
    if os.path.exists(GRUB + BAK):
        sh(["sudo", "cp", GRUB + BAK, GRUB])
    sh(["sudo", "rm", "-rf", THEME_DIR])
    sh(["sudo", "update-grub"])
    prev = read("/etc/plymouth/mono-boot-prev").strip()
    if os.path.exists(PLY_DIR):
        if prev:
            sh(["sudo", "plymouth-set-default-theme", "-R", prev], check=False)
        sh(["sudo", "rm", "-rf", PLY_DIR])
    print("Deshecho. Reinicia cuando quieras.")


def main():
    if "--apply" in sys.argv:
        apply()
    elif "--revert" in sys.argv:
        revert()
    else:
        problems, _ = report()
        print("\nPara aplicarlo:  mono-boot --apply" if not problems else "\nNo se puede aplicar en este equipo.")


if __name__ == "__main__":
    main()
