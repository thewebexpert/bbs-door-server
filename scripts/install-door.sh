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
  
  echo "    Patching ANSI screens with cursor home sequence for VT100/xterm compatibility..."
  python3 -c "
import os
ans_dir = '$DEST/ANS'
if os.path.isdir(ans_dir):
    home_seq = b'\x1b[1;1H'
    for f in os.listdir(ans_dir):
        if f.upper().endswith('.ANS'):
            p = os.path.join(ans_dir, f)
            with open(p, 'rb') as fh:
                data = fh.read()
            if not data.startswith(b'\x1b[H') and not data.startswith(b'\x1b[1;1H'):
                with open(p, 'wb') as fh:
                    fh.write(home_seq + data)
"

  echo "    Configuring JUDGE.CTL for FOSSIL 38400 operation..."
  if [ -f "$DEST/JUDGE.CTL" ]; then
    sed -i.bak \
      -e 's/^[; ]*COMPORT.*/COMPORT 1/' \
      -e 's/^[; ]*FOSSIL/FOSSIL/' \
      -e 's/^[; ]*LOCKBAUD.*/LOCKBAUD 38400/' \
      -e 's/^SYSOPFIRST .*/SYSOPFIRST Derek/' \
      -e 's/^SYSOPLAST .*/SYSOPLAST Bird/' \
      -e 's/^BBSNAME .*/BBSNAME The Adventure BBS/' \
      "$DEST/JUDGE.CTL" && rm -f "$DEST/JUDGE.CTL.bak"
  fi

  BIN_DEST="$DOORS_DIR/bin/dredd.bat"
  if [ ! -f "$BIN_DEST" ]; then
    echo "    Creating dredd.bat launcher..."
    mkdir -p "$DOORS_DIR/bin"
    cat << 'EOF' > "$BIN_DEST"
@echo off
c:
if "%NODE%"=="" set NODE=1
if not "%1"=="" set NODE=%1
bnu /c /l0:38400,8n1 /w0- /h0-
cd \doors\dredd
if exist c:\nodes\node%NODE%\door.sys copy c:\nodes\node%NODE%\door.sys c:\doors\dredd\door.sys > nul
if exist c:\nodes\node%NODE%\DOOR.SYS copy c:\nodes\node%NODE%\DOOR.SYS c:\doors\dredd\DOOR.SYS > nul
dredd /Pc:\nodes\node%NODE%\
exit
EOF
    chmod 755 "$BIN_DEST" 2>/dev/null || true
  fi

  chmod -R 777 "$DEST" 2>/dev/null || true
  echo "    [SUCCESS] Judge Dredd installed to $DEST"
}

install_pimpwars() {
  echo ""
  echo "--> Installing PimpWars v1.52 DOS..."
  echo "    Source: https://archive.org/download/msdos_PimpWars_1990/PimpWars_1990.zip"
  DEST="$DOORS_DIR/pimpwars"
  mkdir -p "$DEST"
  TMP_ZIP="/tmp/pimpwars_$$.zip"

  echo "    Downloading release archive..."
  curl -sSL "https://archive.org/download/msdos_PimpWars_1990/PimpWars_1990.zip" -o "$TMP_ZIP"

  echo "    Extracting game files..."
  if command -v unzip >/dev/null 2>&1; then
    unzip -qo "$TMP_ZIP" -d "$DEST"
  else
    python3 -m zipfile -e "$TMP_ZIP" "$DEST"
  fi
  rm -f "$TMP_ZIP"

  BIN_DEST="$DOORS_DIR/bin/pimpwars.bat"
  if [ ! -f "$BIN_DEST" ]; then
    echo "    Creating pimpwars.bat launcher..."
    mkdir -p "$DOORS_DIR/bin"
    cat << 'EOF' > "$BIN_DEST"
@echo off
c:
if "%NODE%"=="" set NODE=1
if not "%1"=="" set NODE=%1
bnu /c /l0:38400,8n1 /w0- /h0-
cd \doors\pimpwars
if exist c:\nodes\node%NODE%\door.sys copy c:\nodes\node%NODE%\door.sys c:\doors\pimpwars\door.sys > nul
if exist c:\nodes\node%NODE%\DOOR.SYS copy c:\nodes\node%NODE%\DOOR.SYS c:\doors\pimpwars\DOOR.SYS > nul
if exist c:\nodes\node%NODE%\dorinfo%NODE%.def copy c:\nodes\node%NODE%\dorinfo%NODE%.def c:\doors\pimpwars\dorinfo%NODE%.def > nul
if exist c:\nodes\node%NODE%\dorinfo1.def copy c:\nodes\node%NODE%\dorinfo1.def c:\doors\pimpwars\dorinfo1.def > nul
pimpwars.exe c:\nodes\node%NODE%\door.sys %NODE%
exit
EOF
    chmod 755 "$BIN_DEST" 2>/dev/null || true
  fi

  chmod -R 777 "$DEST" 2>/dev/null || true
  echo "    [SUCCESS] PimpWars installed to $DEST"
}

case "$TARGET" in
  usurper)
    install_usurper
    ;;
  dredd|judgedredd)
    install_dredd
    ;;
  pimpwars|pimp)
    install_pimpwars
    ;;
  all)
    install_usurper
    install_dredd
    install_pimpwars
    ;;
  *)
    echo "Unknown door: $1"
    echo "Usage: $0 [usurper | dredd | pimpwars | all]"
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
