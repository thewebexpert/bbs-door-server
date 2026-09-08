#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DOORS_DIR="$APP_DIR/dosbox/drive/doors"
MENU_FILE="/root/.config/openbox/menu.xml"

mkdir -p "$(dirname "$MENU_FILE")"

cat << "XML" > "$MENU_FILE"
<?xml version="1.0" encoding="UTF-8"?>
<openbox_menu xmlns="http://openbox.org/3.4/menu">
<menu id="root-menu" label="Sysop Menu">
  <item label="DOSBox Prompt (C:\>)">
    <action name="Execute"><command>dosbox -conf /app/dosbox/dosbox.conf</command></action>
  </item>
  <separator />
XML

# --- USURPER ---
if [ -d "$DOORS_DIR/usurper" ] || [ -d "$DOORS_DIR/USURPER" ]; then
  cat << "XML" >> "$MENU_FILE"
  <menu id="menu-usurper" label="Usurper">
    <item label="Configure Usurper (Editor)">
      <action name="Execute"><command>dosbox -conf /app/dosbox/dosbox.conf -c "CD \doors\usurper" -c "editor.exe"</command></action>
    </item>
    <item label="Run Usurper Locally">
      <action name="Execute"><command>dosbox -conf /app/dosbox/dosbox.conf -c "CD \doors\usurper" -c "usurper.exe /l"</command></action>
    </item>
  </menu>
XML
else
  cat << "XML" >> "$MENU_FILE"
  <item label="Install Usurper (GPL)">
    <action name="Execute"><command>xterm -T "Installing Usurper" -geometry 90x25 -bg black -fg green -e /app/scripts/install-door.sh usurper</command></action>
  </item>
XML
fi

# --- JUDGE DREDD ---
if [ -d "$DOORS_DIR/dredd" ] || [ -d "$DOORS_DIR/DREDD" ]; then
  cat << "XML" >> "$MENU_FILE"
  <menu id="menu-dredd" label="Judge Dredd">
    <item label="Run Judge Dredd Locally">
      <action name="Execute"><command>dosbox -conf /app/dosbox/dosbox.conf -c "CD \doors\dredd" -c "dredd.exe /l"</command></action>
    </item>
    <item label="Edit Config (JUDGE.CFG)">
      <action name="Execute"><command>xterm -T "Judge Dredd Config" -geometry 90x25 -bg black -fg white -e nano /app/dosbox/drive/doors/dredd/JUDGE.CFG</command></action>
    </item>
  </menu>
XML
else
  cat << "XML" >> "$MENU_FILE"
  <item label="Install Judge Dredd (MIT)">
    <action name="Execute"><command>xterm -T "Installing Judge Dredd" -geometry 90x25 -bg black -fg green -e /app/scripts/install-door.sh dredd</command></action>
  </item>
XML
fi

# --- CLASSIC BBS DOORS (shown if installed) ---
if [ -d "$DOORS_DIR/tw2002" ] || [ -d "$DOORS_DIR/TW2002" ]; then
  cat << "XML" >> "$MENU_FILE"
  <item label="TradeWars TEDIT">
    <action name="Execute"><command>dosbox -conf /app/dosbox/dosbox.conf -c "CD \doors\tw2002" -c "tedit.exe"</command></action>
  </item>
XML
fi

if [ -d "$DOORS_DIR/lord" ] || [ -d "$DOORS_DIR/LORD" ]; then
  cat << "XML" >> "$MENU_FILE"
  <item label="LORD Configuration (LORDCFG)">
    <action name="Execute"><command>dosbox -conf /app/dosbox/dosbox.conf -c "CD \doors\lord" -c "lordcfg.exe"</command></action>
  </item>
XML
fi

if [ -d "$DOORS_DIR/oo2" ] || [ -d "$DOORS_DIR/OO2" ]; then
  cat << "XML" >> "$MENU_FILE"
  <item label="Operation Overkill Setup (OOSETUP)">
    <action name="Execute"><command>dosbox -conf /app/dosbox/dosbox.conf -c "CD \doors\oo2" -c "oosetup.exe"</command></action>
  </item>
XML
fi

if [ -d "$DOORS_DIR/doormud" ] || [ -d "$DOORS_DIR/DOORMUD" ]; then
  cat << "XML" >> "$MENU_FILE"
  <item label="DoorMUD Configuration (MUDCFG)">
    <action name="Execute"><command>dosbox -conf /app/dosbox/dosbox.conf -c "CD \doors\doormud" -c "dmud.exe -l"</command></action>
  </item>
XML
fi

cat << "XML" >> "$MENU_FILE"
  <separator />
  <item label="List RLogin Entrypoints (BBS Info)">
    <action name="Execute"><command>xterm -T "RLogin Entrypoints &amp; BBS Setup" -geometry 105x35 -bg black -fg white -e /app/scripts/list-rlogin.sh</command></action>
  </item>
  <item label="Linux Terminal (xterm)">
    <action name="Execute"><command>xterm -geometry 100x30 -bg black -fg white</command></action>
  </item>
</menu>
</openbox_menu>
XML

mkdir -p /var/lib/openbox
ln -sf "$MENU_FILE" /var/lib/openbox/debian-menu.xml 2>/dev/null || true

if [ -n "$DISPLAY" ] && command -v openbox >/dev/null 2>&1; then
  openbox --reconfigure 2>/dev/null || true
fi
