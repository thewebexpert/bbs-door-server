# Complete Door Server Architecture & Setup Guide

This document describes the architecture, internal data pipeline, patches, configuration parameters, and integration methods for the `door-server` container in this workspace.

---

## 1. Overview & High-Level Architecture

The `door-server` container is a high-performance, multi-node BBS door game server designed to run 16-bit DOS door games (LORD, TradeWars 2002, Operation: Overkill II, etc.) on modern Linux/macOS environments with **100% byte-transparent I/O** and **zero-latency socket inheritance**.

### Data Flow Diagram

```
+---------------------------+       +----------------------------+
|  Binkterm Web (xterm.js)  |       | External Telnet / fTerminal|
+-------------+-------------+       +--------------+-------------+
              |                                    |
              | (WebSocket)                        | (Telnet RFC 854)
              v                                    v
+---------------------------+       +----------------------------+
| binkterm (dosdoor_bridge) |       |  Synchronet BBS (sbbs)     |
+-------------+-------------+       +--------------+-------------+
              |                                    |
              +-----------------+------------------+
                                |
                                | (RFC 1282 RLogin TCP / port 513)
                                v
                +-------------------------------+
                |     door-server (Node.js)     |
                |   - Reads RLogin handshake    |
                |   - Allocates dynamic node    |
                |   - Writes dropfiles          |
                |   - Generates dosbox<N>.conf  |
                |   - Detaches socket from loop |
                +---------------+---------------+
                                |
                                | Socket Descriptor Handoff (-socket 3)
                                v
                +-------------------------------+
                |   DOSBox (0.74-3 Patched)     |
                |  - serial1=nullmodem          |
                |    transparent:1 inhsocket:1  |
                |  - rx_state=0 binary patch    |
                |  - exit(0) on drop patch      |
                +---------------+---------------+
                                |
                                | Emulated 16550 UART (COM1 / IRQ 4)
                                v
                +-------------------------------+
                |    BNU 1.89h FOSSIL Driver    |
                |  - Resident: 32KB TX buffer   |
                |  - Locked: 38400 baud, 8N1    |
                |  - CTS/Watchdog bypassed      |
                +---------------+---------------+
                                |
                                | INT 14h FOSSIL API
                                v
                +-------------------------------+
                |   DOS Door Game (16-bit)      |
                | (TW2002, LORD, OO2, Pit, BRE) |
                +-------------------------------+
```

---

## 2. Core Components

### A. RLogin Daemon (`door-server/app.js` & `lib/door.js`)
1. **Connection Ingress**: Listens on TCP port `513` (exposed on host as `5130`).
2. **Handshake Parsing**: Reads standard RFC 1282 RLogin authentication (`\0client_user\0server_user\0term_type/speed\0`).
   - Parses the requested door name (e.g. `TW2002`, `LORD`, `OO2`) and user handle.
   - Acknowledges the connection with a single null byte (`\0`).
3. **Dynamic Node Allocation** ([`lib/connection_manager.js`](file:///Users/derekbird/code-env/door-server/lib/connection_manager.js)):
   - Dynamically scans active nodes and allocates the lowest available integer (`1..32`).
   - Prevents node ID collisions when multiple users connect and disconnect out of order.
4. **Drop File Generation**:
   - Creates isolated node directory `/app/dosbox/drive/nodes/node<N>/`.
   - Generates `DOOR.SYS`, `DORINFO<N>.DEF`, and `DOORFILE.SR` with correct user handle, security level, time limits, and baud parameters.
   - Sets COM port to `'1'` (`COM1`) and graphics mode to `'1'` (`ANSI`).
5. **Direct Socket Handoff**:
   - Extracts the raw file descriptor from Node's libuv socket: `socketFd = this.wrapper.socket._handle.fd`.
   - Calls `readStop()` on the libuv handle to halt Node.js kernel read polling.
   - Spawns DOSBox passing the socket directly as file descriptor 3:
     ```javascript
     const opts = ['-conf', nodeConfigFile, '-socket', '3'];
     this.process = spawn(config.dosbox.dosboxPath, opts, {
         stdio: ['ignore', 'pipe', 'pipe', socketFd]
     });
     ```
   - Node.js completely stops relaying bytes. All serial I/O flows directly between the kernel TCP socket and DOSBox COM1.

---

### B. DOSBox Socket Inheritance & Binary Patches

The container runs Debian's `dosbox` 0.74-3 package, enhanced with two machine-code binary patches directly applied in [`door-server/Dockerfile`](file:///Users/derekbird/code-env/door-server/Dockerfile#L18) and [`door-server/entrypoint.sh`](file:///Users/derekbird/code-env/door-server/entrypoint.sh#L51-L80):

#### Patch 1: Fixing `inhsocket` Keystroke Starvation
- **Bug in Debian DOSBox**: When spawned with `-socket <fd>`, DOSBox's `CNullModem` constructor sets up the socket but leaves `rx_state = N_RX_DISC (4)` instead of transitioning to `N_RX_IDLE (0)`. The serial polling event bypassed all socket read calls, preventing any keystrokes from reaching the DOS guest.
- **Binary Patch**: Replaces a redundant 10-byte instruction at file offset `0x1ee579` (`setRI(false)`) with:
  ```asm
  movl $0x0, 0x350(%rbx)   ; rx_state = N_RX_IDLE (0)
  ; Hex bytes: c7 83 50 03 00 00 00 00 00 00
  ```

#### Patch 2: Instant Process Exit on Client Disconnect (Zero Idle CPU)
- **Problem**: When a player drops their connection (closes browser tab or disconnects telnet), DOSBox detects socket carrier loss (`Serial1: Disconnected.`), but previously remained trapped in an infinite CPU loop (`cycles=fixed 25000`), consuming 100% of a host CPU core indefinitely.
- **Binary Patch**: Replaces the function exit epilogue in `CNullModem::Disconnect` at offset `0x1ee6d3` (`add $8, %rsp; pop %rbx; pop %rbp; ret`) with:
  ```asm
  xor %edi, %edi           ; exit code 0
  call exit@plt            ; exit(0)
  ; Hex bytes: 31 ff e8 c6 54 e3 ff
  ```
- As soon as the client socket disconnects, DOSBox immediately terminates itself.

---

### C. Pure Raw Byte Transparency (`nullmodem`)

In [`door-server/dosbox/dosbox.conf`](file:///Users/derekbird/code-env/door-server/dosbox/dosbox.conf#L62):
```ini
[serial]
serial1=nullmodem transparent:1 inhsocket:1
serial2=disabled
serial3=disabled
serial4=disabled
```

- **`transparent:1` is critical**:
  - Without `transparent:1`, DOSBox escapes every `0xFF` byte as `0xFF 0xFF` and injects modem control status sequences (`0xFF 0x03`) on connection start.
  - With `transparent:1`, DOSBox operates in pure byte-transparent mode: no byte alterations, no injected handshake bytes, and no control character filtering.

---

### D. FOSSIL Communications Driver (`BNU.COM`)

Most 1990s DOS doors (including TradeWars 2002 and LORD) communicate with the serial port through the FOSSIL standard (BIOS INT 14h) rather than direct UART polling.

#### The Transmit Buffer Overflow Issue
- TradeWars 2002 bursts large ANSI animations (e.g. `TWHELLO2.ANS`, 5,240 bytes) in a single CPU millisecond burst.
- BNU's default transmit ring buffer is only **1,024 bytes**.
- When BNU was invoked with `/L0:38400,8N1` without first being resident, it failed to initialize custom buffers. When TradeWars pumped 5,240 bytes into a 1,024-byte buffer at 38,400 baud, over 900 bytes of ANSI escape sequences were dropped in flight, resulting in fragmented text (`W I I I J`, `p`, `C .`) and broken ANSI tags (`←[0m`).

#### The Solution: 32KB Pre-Allocated Ring Buffer
In `dosbox.conf` autoexec:
```bat
MOUNT C /app/dosbox/drive
PATH Z:\;C:\doors\bin;C:\bin
C:
FAKESHAR
BNU /R16384 /T32768
BNU /L0:38400,8N1 /W0- /H0-
```
1. `BNU /R16384 /T32768`: Installs BNU resident with a **16KB receive buffer** and a **32KB transmit buffer**.
2. `BNU /L0:38400,8N1 /W0- /H0-`: Locks COM1 to 38,400 baud, 8 data bits, no parity, 1 stop bit, and disables hardware flow-control stalls.
3. Door batch files ([`doors/bin/tw2002.bat`](file:///Users/derekbird/code-env/door-server/dosbox/drive/doors/bin/tw2002.bat), [`doors/bin/lord.bat`](file:///Users/derekbird/code-env/door-server/dosbox/drive/doors/bin/lord.bat), [`doors/bin/oo2.bat`](file:///Users/derekbird/code-env/door-server/dosbox/drive/doors/bin/oo2.bat), [`doors/bin/runmud.bat`](file:///Users/derekbird/code-env/door-server/dosbox/drive/doors/bin/runmud.bat)) inherit this 32KB buffer without reloading or shrinking memory.

---

## 3. Node Configuration Reference

### Active Doors
All active door batch scripts reside in **`C:\doors\bin\`** (`/app/dosbox/drive/doors/bin/`). System utilities (`BNU.COM`, `SHARE.EXE`, `PKUNZIP.EXE`) reside in **`C:\bin\`**.

- **LORD** (`doors/bin/lord.bat`): Legend of the Red Dragon
- **TW2002** (`doors/bin/tw2002.bat`): TradeWars 2002
- **OO2** (`doors/bin/oo2.bat`): Operation: Overkill II
- **DOORMUD / RUNMUD** (`doors/bin/runmud.bat`, `doors/bin/doormud.bat`): DoorMUD: Land of the Forgotten
- **MUDCFG** (`doors/bin/mudcfg.bat`): DoorMUD Offline Configuration Editor

### TradeWars 2002 (`TWNODE.DAT`)
`TWNODE.DAT` controls TradeWars multi-node communications. Each node record is 172 bytes:
- **Record 1 (Node 0)**: Reserved for local sysop console (`LOCL`).
- **Records 2–17 (Nodes 1–16)**: Configured for FOSSIL port 1 (`COM1`), 38,400 baud, ANSI mode enabled (`01`), drop file path `C:\NODES\NODE<N>\`.
- Invocation:
  ```bat
  tw2002.exe TWNODE=%NODE% SHARE
  ```

### Legend of the Red Dragon (LORD)
- Dropfile: `DORINFO<N>.DEF` (copied to `dorinfo1.def` and `dorinfo%NODE%.def`).
- Line 6 of `DORINFO1.DEF` must specify COM port `'1'` (`COM1`), not `'0'` (local).
- Invocation:
  ```bat
  lord.bat %NODE%
  ```

### Operation: Overkill II (OO2)
- Dropfile: `DOOR.SYS`.
- Batch file uses `OOINFO.EXE 2 c:\nodes\node%NODE%\ %NODE%` (parameter `2` selects `DOOR.SYS`).
- Stale lock file `OONODE.DAT` is automatically cleared on launch.

---

## 4. Connecting External Systems (BBS Integration)

### A. Synchronet BBS (`sbbs`)
Configure an external RLogin door in SCFG:
- **Command Line**: `?rlogin -s door-server:513 -u %u -z TW2002`
- **Drop File Type**: None needed (door-server generates it internally).
- **Native / 16-bit**: Native.

### B. Binkterm Web Doors (`dosdoor_bridge`)
- **Protocol**: RLogin adapter (`RloginAdapter` in `scripts/dosbox-bridge/emulator-adapters.js`).
- **Host**: `door-server`
- **Port**: `513`
- **Client Encoding**: `cp437`
- **Browser Terminal**: `xterm.js` with `windowsMode: true` and Backspace remapped from `0x7F` (DEL) to `0x08` (BS).

---

## 5. Maintenance & Diagnostics

### Live Debugging Console
You can connect directly to the DoorNode debug server using any Telnet or Netcat client:
```bash
nc localhost 1234
# Or inside the Docker network:
nc door-server 1234
```
From the debug menu, you can manually launch any door module and test output streams without an RLogin client.

### Checking Process Status & System CPU
```bash
# Check container CPU usage (should be ~0.1% when idle):
docker stats --no-stream door-server

# Check running DOSBox instances:
docker exec door-server ps aux | grep dosbox
```

### Inspecting Raw Socket Output
To verify byte transparency and ensure no bytes are being dropped:
```bash
node -e '
const net = require("net");
const client = net.connect({ host: "127.0.0.1", port: 5130 }, () => {
  client.write("\0TheWebExpert\0TW2002\0ansi/38400\0");
});
client.on("data", (d) => process.stdout.write(d));
'
```
