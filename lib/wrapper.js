const ansi = require('ansi-escape-sequences');
const config = require('../config')
const Door = require('./door')
const Debug = require('./debug')

class Wrapper {
  constructor(conn, node) {
    this.socket = conn;
    if (this.socket && typeof this.socket.setNoDelay === 'function') {
      this.socket.setNoDelay(true);
    }
    this.node = node;
    this.remoteAddress = conn.remoteAddress;
    this.user = null;
    this.module = null;
    this.readyForInput = true;
    this.inputBuffer = ''
    this.inputQueue = [];
    this.outBuffer = [];
    this.flushTimer = null;
  }

  setModule(name) {
    let doorConfig = config.doors.find(d => d.name.toLowerCase() == (name || '').toLowerCase())
    if (!doorConfig) {
      throw new Error(`No door config found with name=${name}`)
    }
    this.module = new Door(doorConfig, this);
    this.module.render();
  }

  setDebugModule() {
    // set character mode, don't wait for enter
    this.write(
      String.fromCharCode(255) +
      String.fromCharCode(253) +
      String.fromCharCode(34),
      'ascii'
    );

    // turn off local echo
    this.write(
      String.fromCharCode(255) +
      String.fromCharCode(251) +
      String.fromCharCode(1),
      'ascii'
    );

    this.module = new Debug(this)
    this.module.render()
  }

  clearScreen() {
      // clear screen
    this.write(ansi.erase.display(2));  
      // move cursor to 0,0
    this.write(ansi.cursor.position(1, 1));
  }

  resetLine() {
    const lineLength = this.module.promptLength + this.inputBuffer.length
    const lines = Math.floor(lineLength / this.width)
    if (lines) {
      this.write(ansi.cursor.up(lines))
    }
    this.write(ansi.cursor.horizontalAbsolute(1))
    this.write(ansi.erase.display(0))
  }

  detectCursorPosition() {
    this.write('\x1b[6n')
  }

  fixCursorPosition() {
    if (this.cursor[1]) {
      this.cursor[1]--
      if (this.cursor[1] < 0) {
        this.cursor[1] = this.width - 1
        this.cursor[0]--
      }
    }
  }

  write(str, encoding) {
    try {
      if (this.socket && !this.socket.destroyed) {
        let buf = Buffer.isBuffer(str) ? str : Buffer.from(str, encoding || 'binary');
        this.socket.write(buf);
      }
    } catch (err) {
      console.log(err);
    }
  }

  detachForHandoff() {
    if (this.socket) {
      try {
        if (this.socket._handle && typeof this.socket._handle.readStop === 'function') {
          this.socket._handle.readStop();
        }
        this.socket.pause();
        this.socket.removeAllListeners('data');
      } catch (err) {
        console.error('Error detaching socket for handoff:', err);
      }
    }
  }
}

module.exports = Wrapper;
