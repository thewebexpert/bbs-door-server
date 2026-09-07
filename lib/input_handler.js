const ansi = require('ansi-escape-sequences')
const config = require('../config')

async function sendInput(wrapper, input) {
  if (wrapper.module && typeof wrapper.module.input === 'function') {
    await wrapper.module.input(input)
  }
}

async function handleCharInput(wrapper, str) {
  for (let i = 0; i < str.length; i++) {
    let char = str[i];
    let charCode = str.charCodeAt(i);
    if (charCode === 10 || charCode === 13) {
      continue;
    }
    if (charCode === 127) {
      char = String.fromCharCode(8);
    }
    if (wrapper.module && wrapper.module.localEcho) {
      wrapper.write(char);
    }
    await sendInput(wrapper, char);
  }
}

async function handleLineInput(wrapper, str) {
  for (let i = 0; i < str.length; i++) {
    let char = str[i];
    let charCode = str.charCodeAt(i);

    if (charCode === 13 || charCode === 10) {
      if (charCode === 13 && str.charCodeAt(i + 1) === 10) {
        i++;
      }
      let buffer = wrapper.inputBuffer;
      wrapper.inputBuffer = '';
      await sendInput(wrapper, buffer);
      continue;
    }

    if (charCode === 8 || charCode === 127) {
      if (wrapper.inputBuffer.length > 0) {
        wrapper.inputBuffer = wrapper.inputBuffer.substring(0, wrapper.inputBuffer.length - 1);
        renderBackspace(wrapper);
      }
      continue;
    }

    if (charCode >= 32 && charCode <= 126) {
      if (wrapper.module && wrapper.module.localEcho) {
        wrapper.write(char);
      }
      wrapper.inputBuffer += char;
    }
  }
}

function detectScreenSize(wrapper, char) {
  var index = char.indexOf(String.fromCharCode(255) + String.fromCharCode(250) + String.fromCharCode(31))
  if (index > -1) {
    wrapper.width = (char.charCodeAt(index + 3) * 256) + char.charCodeAt(index + 4)
    wrapper.height = (char.charCodeAt(index + 5) * 256) + char.charCodeAt(index + 6)
    return true
  }
}

function detectCursorPosition(wrapper, char) {
  const index = char.indexOf('\x1b[')
  if (index > -1) {
    let coords = char.replace('\x1b[', '').replace('R', '').split(';')
    wrapper.cursor = [parseInt(coords[0], 10), parseInt(coords[1], 10)]
    return true
  } else {
    let charCode = char.charCodeAt(0)
    if (charCode < 32 || charCode > 126) {
      return
    }
    wrapper.write('\x1b[6n')
  }
}

function renderBackspace(wrapper) {
  if (wrapper.cursor[1] === 0) {
    wrapper.cursor[0]--
    wrapper.cursor[1] = wrapper.width
  }
  wrapper.write(ansi.cursor.position(wrapper.cursor[0], wrapper.cursor[1]))
  wrapper.write(' ')
  wrapper.write(ansi.cursor.position(wrapper.cursor[0], wrapper.cursor[1]))
  wrapper.cursor[1]--
}

function rloginAuth(wrapper, str) {
  if (wrapper.user) {
    return true
  }

  let pieces = str.split(/[\0\s]+/).filter(s => s.length)

  if (pieces.length < 1) {
    console.log(`Unable to negotiate rlogin connection, received: ${JSON.stringify(str)}`)
    wrapper.socket.end()
    return
  }

  let userName = pieces[0] || 'TheWebExpert';
  let doorName = pieces[1] || '';
  let term = pieces[2] || '';

  // 1. Try matching pieces[1] (door name)
  let doorConfig = config.doors.find(d => d.name.toLowerCase() === (doorName || '').toLowerCase());

  // 2. Try matching pieces[0] (user name field, e.g. SyncTERM User field = OO2)
  if (!doorConfig && userName) {
    let match = config.doors.find(d => d.name.toLowerCase() === userName.toLowerCase());
    if (match) {
      doorConfig = match;
      doorName = match.name;
      userName = 'TheWebExpert';
    }
  }

  // 3. Try matching pieces[2] (terminal type before slash, e.g. oo2/38400)
  if (!doorConfig && term) {
    let termDoor = term.split('/')[0];
    let match = config.doors.find(d => d.name.toLowerCase() === termDoor.toLowerCase());
    if (match) {
      doorConfig = match;
      doorName = match.name;
    }
  }

  // 4. Default to first door in config if nothing matched
  if (!doorConfig) {
    doorConfig = config.doors[0];
    doorName = doorConfig ? doorConfig.name : 'OO2';
  }

  wrapper.user = {
    name: userName || 'TheWebExpert',
    module: doorConfig.name,
    terminal: term
  };

  wrapper.write('\0');
  wrapper.setModule(doorConfig.name);
  console.log(`User ${wrapper.user.name} launched ${doorConfig.name}`);
  return;
}


const Door = require('./door')
const Debug = require('./debug')

exports.onData = async function(wrapper, chunk) {
  if (!wrapper.user) {
    let str = Buffer.isBuffer(chunk) ? chunk.toString('binary') : String(chunk);
    rloginAuth(wrapper, str);
    return;
  }

  if (wrapper.module && typeof wrapper.module.input === 'function') {
    await wrapper.module.input(chunk);
    return;
  }
}
