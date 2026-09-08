#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DOORS_DIR="$APP_DIR/dosbox/drive/doors"

TARGET="${1:-all}"
TARGET=$(echo "$TARGET" | tr '[:upper:]' '[:lower:]')

echo "=========================================="
echo " BBS Door Server - Open Source Installer"
echo "=========================================="

install_usurper() {
  echo ""
  echo "--> Installing Usurper v0.20e (GPL v2)..."
  echo "    Source: https://github.com/rickparrish/Usurper"
  DEST="$DOORS_DIR/usurper"
  mkdir -p "$DEST"
  TMP_ZIP="/tmp/usurp020e.zip"
  
  echo "    Downloading original release archive..."
  curl -sSL "https://github.com/rickparrish/Usurper/raw/master/ORIGINAL%20ARCHIVES/usurp020e.zip" -o "$TMP_ZIP"
  
  echo "    Extracting game files..."
  if command -v unzip >/dev/null 2>&1; then
    unzip -qo "$TMP_ZIP" -d "$DEST"
    if [ -f "$DEST/SAMPLES.ZIP" ]; then
      unzip -qo "$DEST/SAMPLES.ZIP" -d "$DEST"
    fi
  else
    python3 -m zipfile -e "$TMP_ZIP" "$DEST"
    if [ -f "$DEST/SAMPLES.ZIP" ]; then
      python3 -m zipfile -e "$DEST/SAMPLES.ZIP" "$DEST"
    fi
  fi
  rm -f "$TMP_ZIP"
  
  echo "    Setting up default control files..."
  [ -f "$DEST/SAMPLE.CTL" ] && cp -n "$DEST/SAMPLE.CTL" "$DEST/USURP.CTL" 2>/dev/null || true
  [ -f "$DEST/SAMPLE.CFG" ] && cp -n "$DEST/SAMPLE.CFG" "$DEST/USURP.CFG" 2>/dev/null || true
  
  chmod -R 777 "$DEST" 2>/dev/null || true
  echo "    [SUCCESS] Usurper installed to $DEST"
}

install_dredd() {
  echo ""
  echo "--> Installing Judge Dredd Door (MIT License)..."
  echo "    Source: https://github.com/GrumpyGrendil/JudgeDredd"
  DEST="$DOORS_DIR/dredd"
  mkdir -p "$DEST"
  TMP_DIR="/tmp/dredd_install_$$"
  mkdir -p "$TMP_DIR"
  
  echo "    Downloading repository tarball..."
  curl -sSL "https://github.com/GrumpyGrendil/JudgeDredd/archive/refs/heads/main.tar.gz" | tar -xz -C "$TMP_DIR"
  
  echo "    Copying game files..."
  cp -r "$TMP_DIR"/JudgeDredd-main/GAME/* "$DEST/"
  rm -rf "$TMP_DIR"
  
  chmod -R 777 "$DEST" 2>/dev/null || true
  echo "    [SUCCESS] Judge Dredd installed to $DEST"
}

case "$TARGET" in
  usurper)
    install_usurper
    ;;
  dredd|judgedredd)
    install_dredd
    ;;
  all)
    install_usurper
    install_dredd
    ;;
  *)
    echo "Unknown door: $1"
    echo "Usage: $0 [usurper | dredd | all]"
    exit 1
    ;;
esac

echo ""
echo "Updating Sysop Desktop Menu..."
if [ -f "$SCRIPT_DIR/generate-menu.sh" ]; then
  "$SCRIPT_DIR/generate-menu.sh"
fi

echo ""
echo "=========================================="
echo " Installation Complete!"
echo " The Sysop menu has been updated with the"
echo " configuration options for installed doors."
echo "=========================================="

if [ -t 1 ] && [ -n "$DISPLAY" ]; then
  echo ""
  echo "Press Enter to close this window..."
  read -r _ || sleep 2
fi
