import brioche
import gleam/dynamic/decode
import gleam/uri

pub type WebSocket

pub fn open(uri: uri.Uri) -> WebSocket {
  uri.to_string(uri)
  |> do_open
}

@external(javascript, "./websocket.ffi.mjs", "close")
pub fn close(ws: WebSocket) -> Nil

@external(javascript, "./websocket.ffi.mjs", "send")
pub fn send(ws: WebSocket, content: String) -> Result(WebSocket, Nil)

@external(javascript, "./websocket.ffi.mjs", "send")
pub fn send_bytes(ws: WebSocket, content: BitArray) -> Result(WebSocket, Nil)

pub fn on_open(ws: WebSocket, handler: fn(decode.Dynamic) -> Nil) -> WebSocket {
  add_event_listener(ws, "open", handler)
}

pub fn on_close(ws: WebSocket, handler: fn(decode.Dynamic) -> Nil) -> WebSocket {
  add_event_listener(ws, "close", handler)
}

pub fn on_error(ws: WebSocket, handler: fn(decode.Dynamic) -> Nil) -> WebSocket {
  add_event_listener(ws, "error", handler)
}

@external(javascript, "./websocket.ffi.mjs", "addStringMessageListener")
pub fn on_string(ws: WebSocket, handler: fn(String) -> Nil) -> WebSocket

@external(javascript, "./websocket.ffi.mjs", "addBitArrayMessageListener")
pub fn on_bytes(ws: WebSocket, handler: fn(BitArray) -> Nil) -> WebSocket

@external(javascript, "./websocket.ffi.mjs", "addEventListener")
fn add_event_listener(
  ws: WebSocket,
  event: String,
  handler: fn(decode.Dynamic) -> Nil,
) -> WebSocket

@external(javascript, "./websocket.ffi.mjs", "open")
fn do_open(url: String) -> WebSocket

@external(javascript, "./websocket.ffi.mjs", "isWebSocket")
pub fn is_websocket(ws: brioche.WebSocket(a)) -> Bool
