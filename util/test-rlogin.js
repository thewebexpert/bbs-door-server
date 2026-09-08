const net = require('net')

const door = (process.argv[2] || 'LORD').toUpperCase()
const user = process.argv[3] || 'Sysop'
const port = parseInt(process.env.RLOGIN_PORT || '513', 10)
const host = process.env.RLOGIN_HOST || '127.0.0.1'

let client = net.connect({port, host}, () => {
  client.setEncoding('binary')
  client.on('data', data => {
    process.stdout.write(data, 'binary')
  })
})

client.on('connect', () => {
  console.log(` -- connected to ${host}:${port} launching ${door} for ${user}`)
  client.write(`${user}\0${door}\0xterm/38400\0`, 'binary')
})

client.on('close', () => {
  console.log(' -- connection closed')
  process.exit()
})

process.stdin.setRawMode(true)

process.stdin.on('data', function (data) {
  data = String(data)
  if (data.charCodeAt(0) === 3) {
    process.exit()
  }
  client.write(data, 'binary')
})