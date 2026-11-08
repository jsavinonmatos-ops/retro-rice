#!/usr/bin/env python3
"""Valida config/polybar/config.ini sin necesitar polybar: líneas sueltas, referencias ${...}, módulos inexistentes,
etiquetas %{A..} sin cerrar y módulos sin 'type'. Uso: polybar-check.py [archivo]   (salida 0 = correcto)"""
import re
import sys

path = sys.argv[1] if len(sys.argv) > 1 else __import__("os").path.expanduser("~/.config/polybar/config.ini")
errors, sections, cur = [], {}, None
for n, raw in enumerate(open(path, encoding="utf-8").read().splitlines(), 1):
    line = raw.strip()
    if not line or line[0] in ";#":
        continue
    m = re.match(r"^\[([^\]]+)\]$", line)
    if m:
        cur = sections.setdefault(m.group(1), {})
        continue
    m = re.match(r"^([A-Za-z0-9_.-]+)\s*=\s*(.*)$", line)
    if not m:
        errors.append(f"línea {n}: no es una opción válida -> {raw[:60]!r}")
        continue
    if cur is None:
        errors.append(f"línea {n}: opción fuera de una sección")
        continue
    cur[m.group(1)] = m.group(2)

for sec, opts in sections.items():
    if sec.startswith("module/") and "type" not in opts:
        errors.append(f"[{sec}] no tiene 'type'")
    for key, val in opts.items():
        opens, closes = len(re.findall(r"%\{A\d?:", val)), len(re.findall(r"%\{A\}", val))
        if opens != closes:
            errors.append(f"[{sec}] {key}: {opens} etiquetas %{{A..}} abiertas y {closes} cerradas")
        for ref in re.findall(r"\$\{([a-z]+)\.([A-Za-z0-9_-]+)\}", val):
            if ref[1] not in sections.get(ref[0], {}):
                errors.append(f"[{sec}] {key}: referencia a ${{{ref[0]}.{ref[1]}}} que no existe")
    for key in ("modules-left", "modules-center", "modules-right"):
        for mod in opts.get(key, "").split():
            if f"module/{mod}" not in sections:
                errors.append(f"[{sec}] {key}: el módulo '{mod}' no existe")
    inh = opts.get("inherit")
    if inh and inh not in sections:
        errors.append(f"[{sec}] inherit apunta a '{inh}' que no existe")
for needed in ("bar/main", "bar/i3"):
    if needed not in sections:
        errors.append(f"falta la barra [{needed}]")

if errors:
    print("Configuración de polybar con errores:")
    print("\n".join("  - " + e for e in errors))
    sys.exit(1)
print(f"Configuración de polybar correcta ({len(sections)} secciones).")
