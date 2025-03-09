import * as $gleam from '../gleam.mjs'

export function open(url) {
  return new WebSocket(url)
}

export function send(ws, content) {
  try {
    const data = content.rawBuffer !== undefined ? content.rawBuffer : content
    ws.send(data)
    return new $gleam.Ok(ws)
  } catch (error) {
    return new $gleam.Error()
  }
}

export function addStringMessageListener(ws, handler) {
  ws.addEventListener('message', function (event) {
    if (typeof event.data === 'string') {
      handler(event.data)
    }
  })
  return ws
}

export function addBitArrayMessageListener(ws, handler) {
  ws.addEventListener('message', function (event) {
    if (event.data instanceof Uint8Array) {
      handler($gleam.toBitArray(event.data))
    }
  })
  return ws
}

export function addEventListener(ws, event, handler) {
  ws.addEventListener(event, handler)
  return ws
}

export function close(ws) {
  ws.close()
}

export function isWebSocket(ws) {
  return 'send' in ws
}
