#!/bin/bash
set -e

rm -f /tmp/.X99-lock /tmp/.X11-unix/X99 2>/dev/null || true

# Start virtual X11 display for DOSBox SDL compatibility (1024x768)
Xvfb :99 -screen 0 1024x768x16 -ac +extension GLX +render -noreset &
export DISPLAY=:99
export TERM=xterm

sleep 1

# Setup Openbox Sysop Menu
mkdir -p /root/.config/openbox
cat << "EOF" > /root/.config/openbox/menu.xml
<?xml version="1.0" encoding="UTF-8"?>
<openbox_menu xmlns="http://openbox.org/3.4/menu">
<menu id="root-menu" label="Sysop Menu">
  <item label="DOSBox Prompt (C:\>)">
    <action name="Execute"><command>dosbox -conf /app/dosbox/dosbox.conf</command></action>
  </item>
  <separator />
  <item label="Operation Overkill Setup (OOSETUP)">
    <action name="Execute"><command>dosbox -conf /app/dosbox/dosbox.conf -c "CD \doors\oo2" -c "oosetup.exe"</command></action>
  </item>
  <item label="TradeWars TEDIT">
    <action name="Execute"><command>dosbox -conf /app/dosbox/dosbox.conf -c "CD \doors\tw2002" -c "tedit.exe"</command></action>
  </item>
  <item label="LORD Configuration (LORDCFG)">
    <action name="Execute"><command>dosbox -conf /app/dosbox/dosbox.conf -c "CD \doors\lord" -c "lordcfg.exe"</command></action>
  </item>
  <item label="DoorMUD Configuration (MUDCFG)">
    <action name="Execute"><command>dosbox -conf /app/dosbox/dosbox.conf -c "CD \doors\doormud" -c "dmud.exe -l"</command></action>
  </item>
  <separator />
  <item label="Linux Terminal (xterm)">
    <action name="Execute"><command>xterm -geometry 100x30 -bg black -fg white</command></action>
  </item>
</menu>
</openbox_menu>
EOF

openbox &

# Start VNC server (port 5900)
x11vnc -display :99 -forever -shared -rfbport 5900 -nopw -bg -o /tmp/x11vnc.log

# Start noVNC WebSocket proxy (port 6080)
websockify --web /usr/share/novnc 6080 localhost:5900 &

# Launch desktop terminal
xterm -geometry 110x32+40+40 -bg black -fg '#00ff00' -title "DOSBox Sysop Terminal" &

# Patch DOSBox inhsocket bugs if needed:
# 1) Ensure rx_state is initialized to N_RX_IDLE 0
# 2) Ensure DOSBox exits cleanly when the inherited socket disconnects
python3 -c '
import os
try:
    with open("/usr/bin/dosbox", "rb") as f:
        data = bytearray(f.read())
    changed = False
    p1_expected = bytes.fromhex("31 f6 48 89 df e8 0d aa ff ff")
    p1_patch = bytes.fromhex("c7 83 50 03 00 00 00 00 00 00")
    if data[0x1ee579:0x1ee579+10] == p1_expected:
        data[0x1ee579:0x1ee579+10] = p1_patch
        changed = True

    p2_expected = bytes.fromhex("48 83 c4 08 5b 5d c3")
    p2_patch = bytes.fromhex("31 ff e8 c6 54 e3 ff")
    if data[0x1ee6d3:0x1ee6d3+7] == p2_expected:
        data[0x1ee6d3:0x1ee6d3+7] = p2_patch
        changed = True

    if changed:
        with open("/usr/bin/dosbox.patched", "wb") as f:
            f.write(data)
        os.chmod("/usr/bin/dosbox.patched", 0o755)
        os.replace("/usr/bin/dosbox.patched", "/usr/bin/dosbox")
        print("[entrypoint] Patched /usr/bin/dosbox inhsocket bugs successfully")
except Exception as e:
    print("[entrypoint] Warning checking dosbox patch:", e)
'

exec node app.js
