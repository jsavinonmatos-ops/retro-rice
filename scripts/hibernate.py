#!/usr/bin/env python3
"""mono-hibernate: prepara la hibernación (archivo swap del tamaño de tu RAM + parámetros de reanudación).

  mono-hibernate            revisa tu equipo y muestra el plan (no cambia nada)
  mono-hibernate --apply    lo aplica (muestra el plan y pide escribir SI)
  mono-hibernate --revert   deshace lo que se agregó

Hibernar guarda toda la memoria en el disco y apaga el equipo; al encender, vuelve todo como estaba.
"""
import math
import os
import re
import subprocess
import sys

SWAPFILE = "/swapfile"
GRUB = "/etc/default/grub"
RESUME_CONF = "/etc/initramfs-tools/conf.d/resume"
FSTAB = "/etc/fstab"
MARK = ".mono-hibernate.bak"


# ---------------------------------------------------------------- funciones puras (con pruebas)
def swap_size_gib(mem_kib):
    """Tamaño del swap: la RAM redondeada hacia arriba + 2 GiB de margen."""
    return math.ceil(mem_kib / 1024 / 1024) + 2


def parse_offset(filefrag_out):
    """Posición física del archivo en el disco (primer bloque), necesaria para reanudar desde un archivo swap."""
    m = re.search(r"^\s*0:\s+0\.\.\s*\d+:\s+(\d+)\.\.", filefrag_out, re.M)
    return int(m.group(1)) if m else None


def lockdown_blocks(text):
    """Con Secure Boot el kernel entra en 'lockdown' y bloquea la hibernación."""
    m = re.search(r"\[(\w+)\]", text or "")
    return bool(m and m.group(1) in ("integrity", "confidentiality"))


def _tokens(line):
    m = re.match(r'^(GRUB_CMDLINE_LINUX_DEFAULT=)(["\'])(.*)\2\s*$', line)
    return (m.group(1), m.group(2), m.group(3).split()) if m else None


def set_cmdline(grub_text, uuid, offset=None):
    """Añade resume=UUID=… (y resume_offset=…) a GRUB_CMDLINE_LINUX_DEFAULT, sustituyendo valores anteriores."""
    new_params = [f"resume=UUID={uuid}"] + ([f"resume_offset={offset}"] if offset is not None else [])
    out, done = [], False
    for line in grub_text.splitlines():
        t = _tokens(line)
        if t and not done:
            pre, q, toks = t
            toks = [x for x in toks if not x.startswith(("resume=", "resume_offset="))] + new_params
            line, done = f'{pre}{q}{" ".join(toks)}{q}', True
        out.append(line)
    if not done:
        out.append(f'GRUB_CMDLINE_LINUX_DEFAULT="{" ".join(new_params)}"')
    return "\n".join(out) + "\n"


def remove_cmdline(grub_text):
    out = []
    for line in grub_text.splitlines():
        t = _tokens(line)
        if t:
            pre, q, toks = t
            line = f'{pre}{q}{" ".join(x for x in toks if not x.startswith(("resume=", "resume_offset=")))}{q}'
        out.append(line)
    return "\n".join(out) + "\n"


def add_fstab(text):
    if re.search(r"^\s*/swapfile\s", text, re.M):
        return text
    return text.rstrip("\n") + f"\n{SWAPFILE} none swap sw 0 0\n"


def remove_fstab(text):
    return "".join(l for l in text.splitlines(True) if not re.match(r"^\s*/swapfile\s", l))


# ---------------------------------------------------------------- sistema
def sh(cmd, check=True, inp=None):
    r = subprocess.run(cmd, capture_output=True, text=True, input=inp)
    if check and r.returncode != 0:
        sys.exit(f"Falló: {' '.join(cmd)}\n{r.stderr.strip() or r.stdout.strip()}")
    return r.stdout


def read(path, default=""):
    try:
        with open(path, encoding="utf-8") as f:
            return f.read()
    except OSError:
        return default


def sudo_write(path, text):
    sh(["sudo", "tee", path], inp=text)


def mem_kib():
    m = re.search(r"MemTotal:\s+(\d+)", read("/proc/meminfo"))
    return int(m.group(1)) if m else 0


def swap_devices():
    """Swaps reales (sin zram) con su tamaño en bytes."""
    out = sh(["swapon", "--noheadings", "--bytes", "--show=NAME,TYPE,SIZE"], check=False)
    res = []
    for line in out.splitlines():
        f = line.split()
        if len(f) == 3 and "zram" not in f[0]:
            res.append((f[0], f[1], int(f[2])))
    return res


def report():
    ok = lambda s: print(f"  \033[32m✔\033[0m {s}")
    bad = lambda s: print(f"  \033[31m✘\033[0m {s}")
    problems = []
    ram = mem_kib()
    print(f"== Hibernación ==  (RAM: {ram / 1024 / 1024:.1f} GiB)")
    can = sh(["systemctl", "can-hibernate"], check=False).strip()
    (ok if can == "yes" else bad)(f"Estado actual de la hibernación: {can or 'desconocido'}")
    if lockdown_blocks(read("/sys/kernel/security/lockdown")):
        bad("Secure Boot activo (kernel en 'lockdown'): Linux BLOQUEA la hibernación en ese modo. "
            "Para usarla hay que desactivar Secure Boot en la BIOS.")
        problems.append("lockdown")
    else:
        ok("Sin lockdown del kernel")
    fs = sh(["findmnt", "-no", "FSTYPE", "/"], check=False).strip()
    (ok if fs == "ext4" else bad)(f"Sistema de archivos de /: {fs} " + ("" if fs == "ext4" else "(este asistente solo prepara ext4)"))
    if fs != "ext4":
        problems.append("fs")
    need = swap_size_gib(ram)
    existing = [d for d in swap_devices() if d[2] >= ram * 1024]
    if existing:
        ok(f"Ya hay un swap suficiente: {existing[0][0]}")
    else:
        free = int(sh(["df", "--output=avail", "-B1", "/"], check=False).split()[-1] or 0) / 1024 ** 3
        (ok if free > need + 10 else bad)(f"Espacio libre: {free:.0f} GiB (hacen falta {need} GiB para el swap y ~10 de margen)")
        if free <= need + 10:
            problems.append("espacio")
    print("\nPlan: " + (f"crear {SWAPFILE} de {need} GiB, activarlo en /etc/fstab, añadir resume= al arranque (GRUB) y a initramfs."
                        if not existing else "usar el swap existente, añadir resume= al arranque (GRUB) y a initramfs."))
    return problems


def apply():
    problems = report()
    if problems:
        sys.exit(f"\nNo se puede continuar ({', '.join(problems)}). No cambié nada.")
    if input("\nEscribe SI para aplicar: ").strip() != "SI":
        sys.exit("Cancelado.")
    ram = mem_kib()
    existing = [d for d in swap_devices() if d[2] >= ram * 1024]
    offset = None
    if existing:
        dev, typ, _ = existing[0]
        if typ == "file":
            target, uuid = dev, sh(["findmnt", "-no", "UUID", "-T", dev]).strip()
            offset = parse_offset(sh(["sudo", "filefrag", "-v", dev]))
        else:
            uuid = sh(["sudo", "blkid", "-s", "UUID", "-o", "value", dev]).strip()
    else:
        gib = swap_size_gib(ram)
        print(f"==> Creando {SWAPFILE} de {gib} GiB (puede tardar un minuto)")
        sh(["sudo", "fallocate", "-l", f"{gib}G", SWAPFILE])
        sh(["sudo", "chmod", "600", SWAPFILE])
        sh(["sudo", "mkswap", SWAPFILE])
        sh(["sudo", "swapon", SWAPFILE])
        fstab = read(FSTAB)
        sh(["sudo", "cp", FSTAB, FSTAB + MARK])
        sudo_write(FSTAB, add_fstab(fstab))
        uuid = sh(["findmnt", "-no", "UUID", "-T", SWAPFILE]).strip()
        offset = parse_offset(sh(["sudo", "filefrag", "-v", SWAPFILE]))
        if offset is None:
            sys.exit("No pude calcular la posición del archivo swap (filefrag). Dejé el swap creado pero NO toqué el arranque.")
    if not uuid:
        sys.exit("No pude obtener el UUID del disco. No toqué el arranque.")
    print("==> Configurando el arranque (copias de seguridad con extensión " + MARK + ")")
    sh(["sudo", "cp", GRUB, GRUB + MARK])
    sudo_write(GRUB, set_cmdline(read(GRUB), uuid, offset))
    sudo_write(RESUME_CONF, f"RESUME=UUID={uuid}\n")
    sh(["sudo", "update-grub"])
    sh(["sudo", "update-initramfs", "-u", "-k", "all"])
    print("\nListo. REINICIA y luego prueba la hibernación con tus archivos guardados:  systemctl hibernate")
    print("Si al encender no recupera tu sesión, no pierdes nada del disco; solo arranca de cero. Para deshacer: mono-hibernate --revert")


def revert():
    if input("Escribe SI para deshacer la hibernación (quita resume= del arranque y el archivo swap): ").strip() != "SI":
        sys.exit("Cancelado.")
    sudo_write(GRUB, remove_cmdline(read(GRUB)))
    sh(["sudo", "rm", "-f", RESUME_CONF])
    if os.path.exists(SWAPFILE):
        sh(["sudo", "swapoff", SWAPFILE], check=False)
        sudo_write(FSTAB, remove_fstab(read(FSTAB)))
        sh(["sudo", "rm", "-f", SWAPFILE])
    sh(["sudo", "update-grub"])
    sh(["sudo", "update-initramfs", "-u", "-k", "all"])
    print("Deshecho. Reinicia cuando quieras.")


def main():
    if "--apply" in sys.argv:
        apply()
    elif "--revert" in sys.argv:
        revert()
    else:
        problems = report()
        print("\nPara prepararla:  mono-hibernate --apply" if not problems else "\nHay cosas que impiden prepararla (arriba).")


if __name__ == "__main__":
    main()
