#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Use node to dynamically parse config.js and display RLogin entrypoints
node << 'NODE_SCRIPT'
const config = require('./config');
const fs = require('fs');
const path = require('path');

const cyan = '\x1b[36m';
const green = '\x1b[32m';
const yellow = '\x1b[33m';
const magenta = '\x1b[35m';
const bold = '\x1b[1m';
const dim = '\x1b[2m';
const reset = '\x1b[0m';

console.log(`${cyan}╔══════════════════════════════════════════════════════════════════════════════════╗${reset}`);
console.log(`${cyan}║${bold}                    BBS DOOR SERVER - RLOGIN ENTRYPOINTS                    ${reset}${cyan}║${reset}`);
console.log(`${cyan}╚══════════════════════════════════════════════════════════════════════════════════╝${reset}`);
console.log('');
console.log(`${bold}Network Endpoints:${reset}`);
console.log(`  • RLogin Internal (BBS / Docker): ${green}door-server:${config.port || 513}${reset}`);
console.log(`  • RLogin External (Host LAN):     ${green}localhost:5130${reset} (or server host port)`);
console.log(`  • Debug Interface:                ${green}localhost:${config.debugPort || 1234}${reset}`);
console.log(`  • Web Desktop (noVNC):            ${green}http://localhost:6080/${reset}`);
console.log('');
console.log(`${bold}Configured Doors (RLogin Remote User Handshake):${reset}`);
console.log('');
console.log(` ${bold}${'RLOGIN NAME'.padEnd(14)} ${'LAUNCHER'.padEnd(18)} ${'DROPFILE'.padEnd(12)} ${'MULTI-NODE'.padEnd(12)} ${'STATUS'}${reset}`);
console.log(` ${dim}${'─'.repeat(14)} ${'─'.repeat(18)} ${'─'.repeat(12)} ${'─'.repeat(12)} ${'─'.repeat(16)}${reset}`);

const doorsDir = path.join(config.dosbox.drivePath || path.join(__dirname, 'dosbox/drive'), 'doors');

config.doors.forEach(door => {
  const name = door.name;
  const cmd = door.doorCmd || '';
  const drop = door.dropFileFormat || 'DoorSys';
  const multi = door.multiNode ? 'Yes' : 'No';

  // Check if directory exists in dosbox/drive/doors/
  const possiblePaths = [
    path.join(doorsDir, name.toLowerCase()),
    path.join(doorsDir, name.toUpperCase()),
    path.join(doorsDir, name)
  ];
  let isInstalled = possiblePaths.some(p => fs.existsSync(p));

  // Special checks for aliases
  if (name === 'RUNMUD' || name === 'MUDCFG') {
    isInstalled = fs.existsSync(path.join(doorsDir, 'DOORMUD')) || fs.existsSync(path.join(doorsDir, 'doormud'));
  }

  const statusStr = isInstalled ? `${green}● INSTALLED${reset}` : `${yellow}○ NOT INSTALLED${reset}`;

  console.log(` ${cyan}${bold}${name.padEnd(14)}${reset} ${cmd.padEnd(18)} ${drop.padEnd(12)} ${multi.padEnd(12)} ${statusStr}`);
});

console.log('');
console.log(`${bold}How to Connect from your BBS:${reset}`);
console.log(`  ${magenta}Synchronet (scfg ➔ External Programs ➔ Online Programs):${reset}`);
console.log(`    • Program Type:         ${bold}RLogin${reset}`);
console.log(`    • Command Line:         ${bold}?rlogin -p 513 door-server %u <RLOGIN_NAME>${reset}`);
console.log(`    • Example for Usurper:  ${cyan}?rlogin -p 513 door-server %u USURPER${reset}`);
console.log(`    • Example for Dredd:    ${cyan}?rlogin -p 513 door-server %u DREDD${reset}`);
console.log(`    • Example for TW2002:   ${cyan}?rlogin -p 513 door-server %u TW2002${reset}`);
console.log(`    • Example for LORD:     ${cyan}?rlogin -p 513 door-server %u LORD${reset}`);
console.log('');
console.log(`  ${magenta}SyncTERM Direct Testing:${reset}`);
console.log(`    • Connection Type:      ${bold}RLogin${reset}`);
console.log(`    • Host / Port:          ${bold}localhost : 5130${reset} (or your host IP)`);
console.log(`    • User Name:            ${cyan}<RLOGIN_NAME>${reset} (e.g. USURPER or LORD)`);
console.log('');
console.log(`  ${magenta}CLI Direct Test:${reset}`);
console.log(`    ${bold}node util/test-rlogin.js <RLOGIN_NAME>${reset}`);
console.log('');
NODE_SCRIPT

# Interactive test prompt if running in interactive terminal
if [ -t 0 ] && [ -t 1 ]; then
  echo -n "Enter an RLogin door name to test now (or press Enter to exit): "
  read -r DOOR_CHOICE
  if [ -n "$DOOR_CHOICE" ]; then
    echo "Connecting to RLogin door '$DOOR_CHOICE'..."
    node "$APP_DIR/util/test-rlogin.js" "$DOOR_CHOICE"
  fi
else
  # If launched from Openbox without interactive stdin, pause so user can view
  echo "Press Enter to close this window..."
  read -r _ 2>/dev/null || sleep 10
fi
