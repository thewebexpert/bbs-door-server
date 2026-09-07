FROM node:20-bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    dosbox \
    xvfb \
    xdotool \
    x11vnc \
    novnc \
    websockify \
    openbox \
    xterm \
    curl \
    vim-tiny \
    nano \
    && ln -s /usr/bin/vim.tiny /usr/bin/vi 2>/dev/null || true \
    && ln -s /usr/share/novnc/vnc.html /usr/share/novnc/index.html 2>/dev/null || true \
    && rm -rf /var/lib/apt/lists/* \
    && python3 -c 'f="/usr/bin/dosbox"; d=bytearray(open(f,"rb").read()); d[0x1ee579:0x1ee579+10]=bytes.fromhex("c7835003000000000000"); d[0x1ee6d3:0x1ee6d3+7]=bytes.fromhex("31ffe8c654e3ff"); open(f,"wb").write(d)'

WORKDIR /app

COPY package*.json ./
RUN npm install --omit=dev

COPY . .

EXPOSE 513 1234 6080

ENTRYPOINT ["/app/entrypoint.sh"]
