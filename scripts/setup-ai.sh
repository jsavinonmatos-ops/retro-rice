#!/usr/bin/env bash
# Instala Ollama (motor de IA local) y descarga el modelo. Usa unos 5 GB de disco.
# Uso: mono-ai-setup [modelo]      (por defecto qwen2.5:7b)
set -eu
MODEL="${1:-qwen2.5:7b}"
export DEBIAN_FRONTEND=noninteractive
sudo -v

echo "==> Requisitos"
sudo apt-get install -y curl zstd poppler-utils fonts-noto-cjk fonts-noto-color-emoji   # caracteres chinos y emojis en la terminal

if ! command -v ollama >/dev/null; then
  echo "==> Descargando el instalador oficial de Ollama (ollama.com)"
  D="$(mktemp -d)"; trap 'rm -rf "$D"' EXIT
  curl -fsSL https://ollama.com/install.sh -o "$D/install.sh"
  echo "    (puedes revisarlo antes en https://ollama.com/install.sh)"
  sh "$D/install.sh"
fi

echo "==> Arrancando el servicio"
sudo systemctl enable --now ollama 2>/dev/null || true
for _ in $(seq 1 40); do
  curl -fs http://127.0.0.1:11434/ >/dev/null 2>&1 && break
  sleep 1
done
curl -fs http://127.0.0.1:11434/ >/dev/null 2>&1 || { echo "Ollama no arrancó. Prueba: sudo systemctl start ollama"; exit 1; }

echo "==> Descargando el modelo $MODEL (varios GB, paciencia)"
ollama pull "$MODEL"

mkdir -p "$HOME/.config/mono-ai"
echo "$MODEL" > "$HOME/.config/mono-ai/model"
echo
echo "Listo. Abre el asistente con:  mono-ai    (o Super+I en i3)"
echo "Para cambiar de modelo: mono-ai-setup qwen2.5:3b   (más rápido y menos capaz)"
