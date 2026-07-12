#!/usr/bin/env bash
# Installs the local toolchain. Debian/Ubuntu. Run once on the agents machine.
set -euo pipefail

echo "==> apt packages"
sudo apt-get update
sudo apt-get install -y \
  ocrmypdf tesseract-ocr tesseract-ocr-eng \
  ghostscript qpdf unpaper pngquant poppler-utils \
  python3 xz-utils libegl1 libopengl0 libxcb-cursor0

# Extra OCR languages (Hebrew shown as an example — drop if you don't need it)
sudo apt-get install -y tesseract-ocr-heb || true

echo "==> calibre (ebook-convert)"
if ! command -v ebook-convert >/dev/null 2>&1; then
  # Distro calibre is often years old; the upstream installer is the safe bet.
  sudo -v
  sudo -H bash -c "$(curl -fsSL https://download.calibre-ebook.com/linux-installer.sh)"
fi

echo "==> versions"
ocrmypdf --version
tesseract --version | head -1
ebook-convert --version

echo "==> done"
