const child_process = require('child_process')
const net = require('net')
const fs = require('fs')
const config = require('../config')
const ConnectionManager = require('./connection_manager')

const dropFileFormats = [
  'DoorSys', 'DorInfo', 'DoorFileSR'
]

function writeDropfile(dirPath, filename, contents) {
  const upper = `${dirPath}/${filename.toUpperCase()}`
  const lower = `${dirPath}/${filename.toLowerCase()}`
  try {
    fs.writeFileSync(upper, contents)
    fs.writeFileSync(lower, contents)
  } catch (e) {}
}

class Door {

  constructor(doorConfig, wrapper) {
    this.wrapper = wrapper
    this.inputMode = 'char'
    this.localEcho = false

    if (!doorConfig.doorCmd) {
      throw new Error('doorCmd not specified')
    }

    if (!doorConfig.dropFileFormat) {
      throw new Error('dropFileFormat not specified')
    }

    if (dropFileFormats.indexOf(doorConfig.dropFileFormat) == -1) {
      throw new Error(doorConfig.dropFileFormat + ' must be one of: ' + dropFileFormats.toString())
    }

    if (!doorConfig.multiNode && !doorConfig.dropFileDir) {
      throw new Error('multiNode or dropFileDir must be specified')
    }

    this.client = null
    this.doorCmd = doorConfig.doorCmd
    this.dropFileFormat = doorConfig.dropFileFormat
    this.doorConfig = doorConfig

    if (doorConfig.multiNode) {
      this.dropFileDir = `${config.dosbox.drivePath}/nodes/node${this.wrapper.node}`
      this.createNodeDir()
    } else {
      this.dropFileDir = `${config.dosbox.drivePath}${doorConfig.dropFileDir}`
    }

    if (doorConfig.removeLockFile) {
      let lockFile = `${config.dosbox.drivePath}${doorConfig.removeLockFile}`
      if (fs.existsSync(lockFile)) {
        fs.unlinkSync(lockFile)
      }
    }

    this.createDosboxConfig()
  }

  createDosboxConfig() {
    const node = this.wrapper.node || 1
    const configFile = `${config.dosbox.configPath}/dosbox.conf`
    const nodeConfigFile = `${config.dosbox.configPath}/dosbox${node}.conf`

    let content = fs.readFileSync(configFile).toString()
    content += '\nSET NODE=' + node + '\n'
    content += `${this.doorCmd}\n`
    content += `exit\n`
    fs.writeFileSync(nodeConfigFile, content)
  }

  createNodeDir() {
    if (!fs.existsSync(this.dropFileDir)) {
      fs.mkdirSync(this.dropFileDir, { recursive: true })
    }
  }

  createDoorSys() {
    const nodeNum = this.wrapper.node || 1;
    let userName = (this.wrapper.user && this.wrapper.user.name) ? this.wrapper.user.name.trim() : 'TheWebExpert';
    let parts = userName.split(/\s+/);
    let sysopFirst = 'Derek';
    let sysopLast = 'Bird';
    if (userName.toLowerCase() === 'sysop') {
      sysopFirst = 'Sysop';
      sysopLast = 'Sysop';
    } else if (parts.length > 1) {
      sysopFirst = parts[0];
      sysopLast = parts.slice(1).join(' ');
    }

    let lines = [
      'COM1:',
      '38400',
      '8',
      String(nodeNum),
      '38400',
      'Y',
      'Y',
      'Y',
      'Y',
      userName,
      'Canada',
      '123 123-1234',
      '123 123-1234',
      'PASSWORD',
      '255',
      '1',
      '01/01/99',
      '86400',
      '1440',
      'GR',
      '25',
      'N',
      '1,2,3,4,5,6,7',
      '7',
      '12/31/99',
      String(nodeNum),
      'Y',
      '0',
      '0',
      '0',
      '999999',
      '01/01/81',
      'C:\\',
      'C:\\',
      sysopFirst,
      sysopLast,
      '00:05',
      'Y',
      'Y',
      'N',
      '25',
      '999999',
      '01/01/99',
      '00:05',
      '00:05',
      '999',
      '0',
      '0',
      '0',
      'User',
      '0',
      '0'
    ];
    const nodeDir = `${config.dosbox.drivePath}/nodes/node${nodeNum}`;
    let contents = lines.join('\r\n') + '\r\n';
    fs.mkdirSync(nodeDir, { recursive: true });
    writeDropfile(nodeDir, 'DOOR.SYS', contents);

    const ooDir = `${config.dosbox.drivePath}/doors/OO2`;
    if (fs.existsSync(ooDir)) {
      writeDropfile(ooDir, 'DOOR.SYS', contents);
    }

    const twDir = `${config.dosbox.drivePath}/doors/TW2002`;
    if (fs.existsSync(twDir)) {
      writeDropfile(twDir, 'DOOR.SYS', contents);
    }

    const lordDir = `${config.dosbox.drivePath}/doors/LORD`;
    if (fs.existsSync(lordDir)) {
      writeDropfile(lordDir, 'DOOR.SYS', contents);
    }

    const mudDir = `${config.dosbox.drivePath}/doors/DOORMUD`;
    if (fs.existsSync(mudDir)) {
      writeDropfile(mudDir, 'DOOR.SYS', contents);
    }

    const usurperDir = `${config.dosbox.drivePath}/doors/usurper`;
    if (fs.existsSync(usurperDir)) {
      writeDropfile(usurperDir, 'DOOR.SYS', contents);
    }

    const dreddDir = `${config.dosbox.drivePath}/doors/dredd`;
    if (fs.existsSync(dreddDir)) {
      writeDropfile(dreddDir, 'DOOR.SYS', contents);
    }
  }

  createDorInfo() {
    const nodeNum = this.wrapper.node || 1;
    let userName = (this.wrapper.user && this.wrapper.user.name) ? this.wrapper.user.name.trim() : 'TheWebExpert';
    let parts = userName.split(/\s+/);
    let userFirst = parts[0] || 'TheWebExpert';
    let userLast = parts.length > 1 ? parts.slice(1).join(' ') : userFirst;
    let sysopFirst = 'Derek';
    let sysopLast = 'Bird';

    let lines = [
      'BirdHouse BBS',
      sysopFirst,
      sysopLast,
      'COM1',
      '38400 BAUD,N,8,1',
      '1',
      userFirst,
      userLast,
      'Canada',
      '1',
      '255',
      '60',
      '1',
      '25',
      '80'
    ];
    let contents = lines.join('\r\n') + '\r\n';

    const nodeDir = `${config.dosbox.drivePath}/nodes/node${nodeNum}`
    fs.mkdirSync(nodeDir, { recursive: true })
    writeDropfile(nodeDir, `dorinfo${nodeNum}.def`, contents)
    writeDropfile(nodeDir, `dorinfo1.def`, contents)

    const lordDir = `${config.dosbox.drivePath}/doors/LORD`
    if (fs.existsSync(lordDir)) {
      writeDropfile(lordDir, `dorinfo1.def`, contents)
      writeDropfile(lordDir, `dorinfo${nodeNum}.def`, contents)
    }

    const twDir = `${config.dosbox.drivePath}/doors/TW2002`
    if (fs.existsSync(twDir)) {
      writeDropfile(twDir, `dorinfo1.def`, contents)
      writeDropfile(twDir, `dorinfo${nodeNum}.def`, contents)
    }

    const ooDir = `${config.dosbox.drivePath}/doors/OO2`
    if (fs.existsSync(ooDir)) {
      writeDropfile(ooDir, `dorinfo1.def`, contents)
      writeDropfile(ooDir, `dorinfo${nodeNum}.def`, contents)
    }

    const opoverDir = `${config.dosbox.drivePath}/opover2`
    if (fs.existsSync(opoverDir)) {
      writeDropfile(opoverDir, `dorinfo1.def`, contents)
      writeDropfile(opoverDir, `dorinfo${nodeNum}.def`, contents)
    }

    const mudDir = `${config.dosbox.drivePath}/doors/DOORMUD`
    if (fs.existsSync(mudDir)) {
      writeDropfile(mudDir, `dorinfo1.def`, contents)
      writeDropfile(mudDir, `dorinfo${nodeNum}.def`, contents)
    }

    const usurperDir = `${config.dosbox.drivePath}/doors/usurper`
    if (fs.existsSync(usurperDir)) {
      writeDropfile(usurperDir, `dorinfo1.def`, contents)
      writeDropfile(usurperDir, `dorinfo${nodeNum}.def`, contents)
    }

    const dreddDir = `${config.dosbox.drivePath}/doors/dredd`
    if (fs.existsSync(dreddDir)) {
      writeDropfile(dreddDir, `dorinfo1.def`, contents)
      writeDropfile(dreddDir, `dorinfo${nodeNum}.def`, contents)
    }
  }

  createDoorFileSR() {
    let contents = this.wrapper.user.name + '\r\n'
    contents += '1\r\n'
    contents += '0\r\n'
    contents += '25\r\n'
    contents += '38400\r\n'
    contents += '1\r\n'
    contents += '86400\r\n'
    contents += this.wrapper.user.name + '\r\n'
    writeDropfile(this.dropFileDir, 'DOORFILE.SR', contents)
  }

  removeDoorFileSR() {}
  removeDorInfo() {}
  removeDoorSys() {}

  render() {
    this.wrapper.clearScreen()

    this.createDoorSys()
    this.createDorInfo()
    this.createDoorFileSR()
    this.createDosboxConfig()

    let env = Object.assign({}, process.env, {
      TERM: 'xterm',
      DISPLAY: process.env.DISPLAY || ':99'
    })

    if (config.dosbox.headless) {
      env.SDL_VIDEODRIVER = 'dummy'
    }

    const socketFd = this.wrapper.socket && this.wrapper.socket._handle ? this.wrapper.socket._handle.fd : null
    if (socketFd === null || socketFd === undefined) {
      console.error(`[DOSBox Node ${this.wrapper.node}]: Socket fd is not available for handoff`)
      ConnectionManager.close(this.wrapper)
      return
    }

    // Detach socket from Node.js event reading so DOSBox receives all raw I/O directly
    this.wrapper.detachForHandoff()

    // Pass socketFd as stdio descriptor 3 to child process
    let opts = [
      '-defaultdir',
      config.dosbox.configPath,
      '-conf',
      `dosbox${this.wrapper.node}.conf`,
      '-socket',
      '3'
    ]

    this.process = child_process.spawn(config.dosbox.dosboxPath, opts, {
      cwd: config.dosbox.configPath,
      env,
      stdio: ['ignore', 'pipe', 'pipe', socketFd]
    })

    this.process.stdout.on('data', d => {
      const str = d.toString()
      console.log(`[DOSBox Node ${this.wrapper.node}]:`, str)
      if (str.includes('Serial1: Disconnected') || str.includes('Disconnected.')) {
        console.log(`[DOSBox Node ${this.wrapper.node}]: Serial disconnect detected, terminating DOSBox process`)
        this.destroy()
        if (this.wrapper) {
          ConnectionManager.close(this.wrapper)
        }
      }
    })
    this.process.stderr.on('data', d => console.error(`[DOSBox Node ${this.wrapper.node} ERR]:`, d.toString()))
    this.process.on('exit', (code) => {
      console.log(`[DOSBox Node ${this.wrapper.node}] exited with code ${code}`)
      this.cleanup()
      if (this.wrapper) {
        ConnectionManager.close(this.wrapper)
      }
    })
  }

  cleanup() {
    this['remove' + this.dropFileFormat]()
    if (this.doorConfig && this.doorConfig.removeLockFile) {
      let lockFile = `${config.dosbox.drivePath}${this.doorConfig.removeLockFile}`
      try {
        if (fs.existsSync(lockFile)) fs.unlinkSync(lockFile)
      } catch (e) {}
    }
    const nodeConfigFile = `${config.dosbox.configPath}/dosbox${this.wrapper.node}.conf`
    try {
      if (fs.existsSync(nodeConfigFile)) fs.unlinkSync(nodeConfigFile)
    } catch (e) {}
  }

  input(input) {
    // No-op: DOSBox handles socket I/O directly via inherited socket descriptor 3
  }

  destroy() {
    this.cleanup()
    if (this.process) {
      try {
        this.process.kill('SIGKILL')
      } catch (e) {}
      this.process = null
    }
  }
}

module.exports = Door