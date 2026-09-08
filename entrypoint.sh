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
mkdir -p /var/lib/openbox
ln -sf /root/.config/openbox/menu.xml /var/lib/openbox/debian-menu.xml 2>/dev/null || true

openbox &

# Start VNC server (port 5900)
x11vnc -display :99 -forever -shared -rfbport 5900 -nopw -bg -o /tmp/x11vnc.log

# Setup noVNC web console redirect and DOM readiness fix
rm -f /usr/share/novnc/index.html 2>/dev/null || true
echo '{"name": "noVNC", "version": "1.3.0"}' > /usr/share/novnc/package.json 2>/dev/null || true
cat << "EOF" > /usr/share/novnc/index.html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta http-equiv="refresh" content="0; url=vnc.html?autoconnect=true&resize=scale">
    <title>BBS Door Server Console</title>
</head>
<body style="background-color: #111; color: #aaa; font-family: monospace; padding: 20px;">
    Redirecting to <a href="vnc.html?autoconnect=true&resize=scale" style="color: #00ff00;">noVNC Web Console</a>...
    <script>
        window.location.replace("vnc.html?autoconnect=true&resize=scale");
    </script>
</body>
</html>
EOF

python3 -c '
ui_path = "/usr/share/novnc/app/ui.js"
try:
    with open(ui_path, "r") as f:
        content = f.read()

    changed = False
    proxy_snippet = """// Safe element proxy fallback to prevent null addEventListener crashes
if (typeof document !== "undefined" && !document._safeGetElementById) {
    document._safeGetElementById = document.getElementById.bind(document);
    const _nullProxy = new Proxy({}, {
        get: (target, prop) => {
            if (prop === "addEventListener" || prop === "removeEventListener") return () => {};
            if (prop === "classList") return { add: () => {}, remove: () => {}, contains: () => false, toggle: () => {} };
            if (prop === "style") return {};
            if (prop === "setAttribute" || prop === "removeAttribute") return () => {};
            if (prop === "getAttribute") return () => null;
            return undefined;
        }
    });
    document.getElementById = (id) => document._safeGetElementById(id) || _nullProxy;
}
"""
    if "document._safeGetElementById" not in content:
        content = proxy_snippet + content
        changed = True

    old_prime = """            if (document.readyState === "interactive" || document.readyState === "complete") {
                return UI.start();
            }

            return new Promise((resolve, reject) => {
                document.addEventListener(\x27DOMContentLoaded\x27, () => UI.start().then(resolve).catch(reject));
            });"""

    new_prime = """            if (document.readyState === "complete") {
                return UI.start();
            }

            return new Promise((resolve, reject) => {
                window.addEventListener(\x27load\x27, () => UI.start().then(resolve).catch(reject));
            });"""

    if old_prime in content:
        content = content.replace(old_prime, new_prime)
        changed = True

    if changed:
        with open(ui_path, "w") as f:
            f.write(content)
        print("[entrypoint] Patched noVNC ui.js successfully")
except Exception as e:
    print("[entrypoint] Warning checking noVNC patch:", e)
'

# Force HTTP no-cache headers in websockify so browsers never serve stale cached scripts
python3 -c '
path = "/usr/lib/python3/dist-packages/websockify/websockifyserver.py"
try:
    with open(path, "r") as f:
        code = f.read()
    target = "class WebSockifyRequestHandler(WebSocketRequestHandlerMixIn, SimpleHTTPRequestHandler):"
    replacement = target + """
    def end_headers(self):
        self.send_header(\x27Cache-Control\x27, \x27no-store, no-cache, must-revalidate, max-age=0\x27)
        self.send_header(\x27Pragma\x27, \x27no-cache\x27)
        self.send_header(\x27Expires\x27, \x270\x27)
        super().end_headers()
"""
    if target in code and "def end_headers(self):" not in code:
        code = code.replace(target, replacement, 1)
        with open(path, "w") as f:
            f.write(code)
        print("[entrypoint] Patched websockifyserver.py with no-cache headers")
except Exception as e:
    print("[entrypoint] Warning patching websockifyserver.py:", e)
'

# Patch vnc.html with cache-busting and legacy compatibility stubs for cached scripts
python3 -c '
path = "/usr/share/novnc/vnc.html"
try:
    with open(path, "r") as f:
        html = f.read()

    # Cache-bust script references
    html = html.replace("src=\"app/error-handler.js\"", "src=\"app/error-handler.js?v=2.0.0\"")
    html = html.replace("src=\"app/ui.js\"", "src=\"app/ui.js?v=2.0.0\"")

    cleanup_script = """<script>
    if (\x27serviceWorker\x27 in navigator) {
        navigator.serviceWorker.getRegistrations().then(r => r.forEach(x => x.unregister()));
    }
    if (\x27caches\x27 in window) {
        caches.keys().then(keys => keys.forEach(k => caches.delete(k)));
    }
    </script>"""
    if "serviceWorker" not in html:
        html = html.replace("<head>", "<head>\n    " + cleanup_script, 1)

    # Add compatibility stubs for older cached scripts
    stubs = """<body>
    <!-- Legacy compatibility elements for cached noVNC scripts -->
    <div style="display:none;" aria-hidden="true">
        <div id="noVNC_mouse_button0"></div>
        <div id="noVNC_mouse_button1"></div>
        <div id="noVNC_mouse_button2"></div>
        <div id="noVNC_mouse_button4"></div>
    </div>"""

    if "noVNC_mouse_button0" not in html:
        html = html.replace("<body>", stubs, 1)

    with open(path, "w") as f:
        f.write(html)
    print("[entrypoint] Patched vnc.html with compatibility stubs and cache-busting")
except Exception as e:
    print("[entrypoint] Warning patching vnc.html:", e)
'

# Recursively cache-bust all JS imports in /usr/share/novnc so dependencies are never served from browser disk cache
python3 -c '
import os, re
novnc_dir = "/usr/share/novnc"
try:
    for root, dirs, files in os.walk(novnc_dir):
        for f in files:
            if f.endswith(".js"):
                path = os.path.join(root, f)
                with open(path, "r", encoding="utf-8", errors="ignore") as fh:
                    content = fh.read()
                new_content = re.sub(r"""from\s+([\"\x27])(\.{1,2}/[^\s\"\x27]+\.js)([\"\x27])""", r"""from \1\2?v=2.0.0\3""", content)
                new_content = re.sub(r"""import\s+([\"\x27])(\.{1,2}/[^\s\"\x27]+\.js)([\"\x27])""", r"""import \1\2?v=2.0.0\3""", new_content)
                if new_content != content:
                    with open(path, "w", encoding="utf-8") as fh:
                        fh.write(new_content)
    print("[entrypoint] Patched all JS imports with cache-busting version query")
except Exception as e:
    print("[entrypoint] Warning updating JS imports:", e)
'

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
