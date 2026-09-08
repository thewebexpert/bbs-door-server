# BBS Door Server (Dockerized DOSBox Multi-Node RLogin Server)

A modern, turnkey Docker container for running 16-bit DOS BBS door games (TradeWars 2002, Legend of the Red Dragon, Operation: Overkill II, DoorMUD, and more) on contemporary Linux and macOS systems with **zero-latency socket inheritance** and a **web-based Sysop desktop via noVNC**.

---

## Features

* **Turnkey Docker Setup**: Runs out of the box with `docker compose up -d`.
* **Zero-Latency Socket Inheritance**: Direct file-descriptor handoff (`-socket <fd>`) with 100% byte-transparent binary I/O, completely eliminating TCP loopback overhead and ANSI escape-code corruption.
* **Web Management Desktop (noVNC)**: Access a full graphical X11 desktop directly in your web browser on port `6080` without installing VNC viewer software.
* **Right-Click Sysop Menu (Openbox)**: Right-click the desktop to instantly launch a standalone DOSBox prompt (`C:\>`), game setup utilities, or Linux shell terminals.
* **Pre-configured Classic Doors**: Includes working setups and multi-node batch launchers for:
  * **TradeWars 2002 v3.13**
  * **Legend of the Red Dragon (LORD) v4.07**
  * **Operation: Overkill II (OO2) v1.21**
  * **DoorMUD v0.99**
* **FOSSIL Driver Integration**: Bundled with tuned **BNU 1.89h** FOSSIL driver featuring a 32KB resident transmit buffer, locked 38400 baud, and CTS/watchdog bypass.
* **Multi-Node Operation**: Supports simultaneous callers across independent node directories (`C:\nodes\node1` through `node6`).
* **Popular Dropfile Formats**: Generates `DOOR.SYS`, `DORINFO1.DEF` (through `DORINFO6.DEF`), and `DOORFILE.SR`.
* **Universal BBS Support**: Connects seamlessly with **Synchronet (`sbbs`)**, **Binkterm PHP**, **MajorBBS / WorldGroup**, **Mystic BBS**, and **Enigma½** via standard RFC 1282 RLogin.

---

## Quick Start

### 1. Clone & Start

```bash
git clone https://github.com/thewebexpert/bbs-door-server.git
cd bbs-door-server
docker compose up -d
```

### 2. Access the Ports

| Service | Port | Description |
| :--- | :--- | :--- |
| **Web Sysop Desktop (noVNC)** | `6080` | Open `http://localhost:6080/` in your browser |
| **RLogin Server** | `513` | Port for BBS connections (Synchronet, Binkterm, etc.) |
| **Debug Test Console** | `1234` | Connect via telnet (`telnet localhost 1234`) to test doors |

---

## Web Management Desktop (noVNC)

Open **`http://localhost:6080/`** in any web browser. You will be greeted by an X11 desktop environment featuring an active green `xterm` Linux terminal.

### Right-Click Sysop Menu
Right-click anywhere on the desktop background to open the Openbox **Sysop Menu**:

* **DOSBox Prompt (`C:\>`)**: Opens an interactive DOSBox session with `C:\` pre-mounted to `/app/dosbox/drive`. Use this to run installers, create characters, or test executables.
* **Dynamic Door Management**:
  * Uninstalled open-source doors show an **Install <Game>** option.
  * Once installed, the menu **dynamically updates** to replace the installer with **Configure <Game>** (launching its setup editor in DOSBox) and **Run Locally**!
* **Linux Terminal (xterm)**: Spawns an additional Linux terminal window for downloading archives, managing files, and checking logs.

---

## Installing Open-Source BBS Doors

The door server comes pre-configured with launcher batch scripts and dropfile integrations for official open-source BBS doors. To avoid forcing unneeded software onto your system, these doors are not pre-installed, but can be added in seconds.

### Supported Open-Source Doors
1. **Usurper v0.20e** (GNU General Public License v2)
   - Legendary fantasy RPG door by Jakob Dangarden, ported and maintained by [Rick Parrish](https://github.com/rickparrish/Usurper).
   - Features dungeon crawling, monster slaying, player combat, gods, and marriages.
2. **Judge Dredd Door** (MIT License)
   - Modern L.O.R.D.-style Mega-City One RPG door created by [GrumpyGrendil](https://github.com/GrumpyGrendil/JudgeDredd) with Scott Baker's DDPlus 7.1 DoorKit.
   - Fight perps, level up your Judge, patrol the sectors, and upgrade equipment.

### Option A: 1-Click Installation from Web Desktop (noVNC)
1. Open the noVNC desktop at `http://localhost:6080/`.
2. Right-click anywhere on the desktop background.
3. Click **Install Usurper (GPL)** or **Install Judge Dredd (MIT)**.
4. A terminal window will open, download the official release directly from GitHub, and set up all required directories.
5. Once complete, right-clicking the desktop will now show:
   * **Usurper** ➔ **Configure Usurper (Editor)** or **Run Usurper Locally**
   * **Judge Dredd** ➔ **Edit Config (JUDGE.CFG)** or **Run Judge Dredd Locally**

### Option B: Command-Line Installation
You can also run the installer script directly on the host or inside the container:

```bash
# Install Usurper only:
./install-doors.sh usurper

# Install Judge Dredd only:
./install-doors.sh dredd

# Install all available open-source doors:
./install-doors.sh all
```

---

## How to Add Custom DOS Door Games

Here is a complete, step-by-step guide to installing a new door game using the web interface:

### Step 1: Download the Game Archive
Open the web desktop at `http://localhost:6080/`. In the open terminal window, navigate to the doors folder and curl the game:

```bash
cd /app/dosbox/drive/doors
curl -L -O http://www.example.com/downloads/mygame.zip
```

### Step 2: Extract the Game Files
Extract the archive into its own folder:

```bash
mkdir MYGAME
unzip mygame.zip -d MYGAME
# Ensure lowercase permissions if needed:
chmod -R 775 MYGAME
```

*(Note: You can also use DOS `PKUNZIP` from inside the DOSBox prompt: `pkunzip mygame.zip C:\doors\MYGAME`)*

### Step 3: Run the Game Setup in DOSBox
1. Right-click anywhere on the desktop and click **DOSBox Prompt (`C:\>`)**.
2. In the DOSBox prompt, navigate to your game's directory and run its setup utility:

```dos
C:
CD \doors\MYGAME
SETUP.EXE
```

3. **Configure the door settings**:
   * **Comm Type**: Select **FOSSIL** (or **COM1 / Standard IRQ 4**).
   * **Baud Rate**: Set to **38,400** or Locked.
   * **Drop File Type**: Choose **DOOR.SYS** or **DORINFO1.DEF**.
   * **Multi-node Paths**: If the game supports multi-node, configure the dropfile path for each node:
     * Node 1: `C:\nodes\node1`
     * Node 2: `C:\nodes\node2`
     * *(and so on)*

### Step 4: Create the Batch Launcher
Create a batch launcher in `/app/dosbox/drive/doors/bin/<game>.bat`. You can create this from the Linux terminal using `nano`:

```bash
nano /app/dosbox/drive/doors/bin/mygame.bat
```

Add your batch script (parameter `%1` represents the node number):

```bat
@echo off
C:
CD \doors\MYGAME
REM Launch the game with node dropfile path:
MYGAME.EXE C:\nodes\node%1\DOOR.SYS
```

Make it executable:
```bash
chmod +x /app/dosbox/drive/doors/bin/mygame.bat
```

### Step 5: Register the Door in `config.js`
Open `/app/config.js` in your editor (or on your host system):

```javascript
  doors: [
    // ... existing doors ...
    {
      name: 'MYGAME',
      doorCmd: 'CALL mygame.bat',
      dropFileFormat: 'DoorSys',   // 'DoorSys', 'DorInfo', or 'DoorFile'
      multiNode: true
    }
  ]
```

### Step 6: Test Locally via the Debug Port
Before wiring it up to your BBS, test it directly via the debug console:

```bash
telnet localhost 1234
```
You will be greeted with:
```
Welcome to the doornode debug server!
Available modules:
1) LORD
2) TW2002
3) OO2
4) DOORMUD
5) MYGAME
Select a module:
```
Type `5` or `MYGAME` and press **Enter**. DOSBox will launch immediately and stream the game directly into your terminal!

---

## Connecting Your BBS to Door Server

Door Server speaks standard **RFC 1282 RLogin** on port `513`.

### 1. Synchronet BBS (`sbbs`)
In Synchronet's configuration utility (`scfg`):
1. Navigate to **External Programs** $\to$ **Online Programs (Doors)**.
2. Select or create a section (e.g. `External Games`).
3. Add a new program:
   * **Name**: TradeWars 2002
   * **Internal Code**: TW2002
   * **Execution Method**: `?rlogin -p 513 door-server TW2002`
   * **Native Executable**: `No`
   * **Use Shell to Execute**: `No`

### 2. Binkterm PHP
In Binkterm's door configuration (`public_html/webdoors/rlogindoors/index.php` or `webdoor.json`):
* **Host**: `door-server` (or IP address)
* **Port**: `513`
* **RLogin User / Door Tag**: `TW2002`, `LORD`, `OO2`, or `DOORMUD`

---

## Architecture & Technical Deep-Dive

### Why Socket Inheritance?
Traditional DOSBox BBS door setups run a local TCP nullmodem server (`serial1=nullmodem server:10001`) and use a TCP proxy process to route caller traffic. This introduces:
1. Significant latency and packet fragmentation.
2. Character dropping and ANSI screen corruption when users type fast.
3. Needing to open and manage individual TCP ports per node.

This container uses **DOSBox Socket Inheritance**:
```
Client (WebSocket/Telnet) 
    │
    ▼
Node.js RLogin Server (port 513)
    │  - Performs RLogin handshake
    │  - Writes dropfile (DOOR.SYS / DORINFO)
    │  - Detaches client socket from Node.js event loop
    ▼
DOSBox Process (-socket <FD>)
    │  - Inherits raw file descriptor directly onto serial1 (COM1)
    ▼
BNU FOSSIL Driver (INT 14h)
    │
    ▼
16-bit DOS Door Game
```
Caller input flows **directly into the emulated 16550 UART with zero intermediary buffering**, providing an authentic 100% responsive dial-up experience.

---

## Environment Variables & Custom Ports

You can customize port bindings by copying `.env.example` to `.env`:

```bash
cp .env.example .env
```

| Variable | Default | Description |
| :--- | :--- | :--- |
| `DOOR_PORT` | `513` | Host port for RLogin BBS traffic |
| `VNC_WEB_PORT` | `6080` | Host port for the noVNC Sysop web interface |
| `DEBUG_PORT` | `1234` | Host port for the interactive debug test console |
| `TZ` | `America/New_York`| Container timezone |

---

## Credits & License

* **Original Prototype**: Based on `doornode` (2019) by Tom Dinchak (`dinchak/doornode`).
* **Containerization & Enhancements**: Architected by [TheWebExpert](https://github.com/thewebexpert) with Docker containerization, DOSBox binary nullmodem patches, noVNC management desktop, and socket-inheritance pipeline.
* **License**: Released under the **GNU General Public License v3.0 (GPL-3.0)**. See [LICENSE](LICENSE) for details.
