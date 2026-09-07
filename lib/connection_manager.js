const Wrapper = require('./wrapper')

exports.wrappers = []

exports.close = function (wrapper) {
  if (!wrapper || !exports.wrappers.includes(wrapper)) return
  exports.wrappers = exports.wrappers.filter(w => w != wrapper)
  if (wrapper.module) {
    try {
      wrapper.module.destroy()
    } catch (e) {
      console.error('Error destroying module:', e)
    }
  }
  if (wrapper.socket) {
    try {
      wrapper.socket.destroy()
    } catch (e) {
      console.error('Error destroying socket:', e)
    }
  }
  console.log('Connection from ' + wrapper.remoteAddress + ' closed, ' + exports.wrappers.length + ' active connections')
}

function getAvailableNode() {
  const used = new Set(exports.wrappers.map(w => w.node))
  for (let n = 1; n <= 32; n++) {
    if (!used.has(n)) return n
  }
  return exports.wrappers.length + 1
}

exports.init = function (conn) {
  const node = getAvailableNode()
  const wrapper = new Wrapper(conn, node)
  exports.wrappers.push(wrapper)
  console.log('New connection from ' + wrapper.remoteAddress + ' assigned to node ' + node + ', ' + exports.wrappers.length + ' active connections')
  return wrapper
}
