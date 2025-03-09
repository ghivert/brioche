import brioche as bun
import gleam/javascript/promise.{type Promise}
import gleam/option.{type Option, None, Some}

pub opaque type Config(context) {
  Config(
    text_message: Option(fn(bun.WebSocket(context), String) -> Promise(Nil)),
    bytes_message: Option(fn(bun.WebSocket(context), BitArray) -> Promise(Nil)),
    open: Option(fn(bun.WebSocket(context)) -> Promise(Nil)),
    close: Option(fn(bun.WebSocket(context), Int, String) -> Promise(Nil)),
    drain: Option(fn(bun.WebSocket(context)) -> Promise(Nil)),
    max_payload_length: Option(Int),
    backpressure_limit: Option(Int),
    close_on_backpressure_limit: Option(Int),
    idle_timeout: Option(Int),
    publish_to_self: Option(Bool),
  )
}

pub type WebSocketSendStatus {
  MessageDropped
  MessageBackpressured
  MessageSent(bytes_sent: Int)
}

pub fn init() {
  Config(
    text_message: None,
    bytes_message: None,
    open: None,
    close: None,
    drain: None,
    max_payload_length: None,
    backpressure_limit: None,
    close_on_backpressure_limit: None,
    idle_timeout: None,
    publish_to_self: None,
  )
}

pub fn on_open(
  config: Config(context),
  handler: fn(bun.WebSocket(context)) -> Promise(Nil),
) -> Config(context) {
  let open = Some(handler)
  Config(..config, open:)
}

pub fn on_drain(
  config: Config(context),
  handler: fn(bun.WebSocket(context)) -> Promise(Nil),
) -> Config(context) {
  let drain = Some(handler)
  Config(..config, drain:)
}

pub fn on_close(
  config: Config(context),
  handler: fn(bun.WebSocket(context), Int, String) -> Promise(Nil),
) -> Config(context) {
  let close = Some(handler)
  Config(..config, close:)
}

pub fn on_text(
  config: Config(context),
  handler: fn(bun.WebSocket(context), String) -> Promise(Nil),
) -> Config(context) {
  let text_message = Some(handler)
  Config(..config, text_message:)
}

pub fn on_bytes(
  config: Config(context),
  handler: fn(bun.WebSocket(context), BitArray) -> Promise(Nil),
) -> Config(context) {
  let bytes_message = Some(handler)
  Config(..config, bytes_message:)
}

pub fn max_payload_length(
  config: Config(context),
  max_payload_length: Int,
) -> Config(context) {
  let max_payload_length = Some(max_payload_length)
  Config(..config, max_payload_length:)
}

pub fn backpressure_limit(
  config: Config(context),
  backpressure_limit: Int,
) -> Config(context) {
  let backpressure_limit = Some(backpressure_limit)
  Config(..config, backpressure_limit:)
}

pub fn close_on_backpressure_limit(
  config: Config(context),
  close_on_backpressure_limit: Int,
) -> Config(context) {
  let close_on_backpressure_limit = Some(close_on_backpressure_limit)
  Config(..config, close_on_backpressure_limit:)
}

pub fn idle_timeout(
  config: Config(context),
  idle_timeout: Int,
) -> Config(context) {
  let idle_timeout = Some(idle_timeout)
  Config(..config, idle_timeout:)
}

pub fn publish_to_self(
  config: Config(context),
  publish_to_self: Bool,
) -> Config(context) {
  let publish_to_self = Some(publish_to_self)
  Config(..config, publish_to_self:)
}

@external(javascript, "./server.ffi.mjs", "data")
pub fn data(websocket: bun.WebSocket(context)) -> context

@external(javascript, "./server.ffi.mjs", "readyState")
pub fn ready_state(websocket: bun.WebSocket(context)) -> Int

@external(javascript, "./server.ffi.mjs", "remoteAddress")
pub fn remote_address(websocket: bun.WebSocket(context)) -> String

@external(javascript, "./server.ffi.mjs", "wsSend")
pub fn send(
  websocket: bun.WebSocket(context),
  message: String,
) -> WebSocketSendStatus

@external(javascript, "./server.ffi.mjs", "wsSend")
pub fn send_bytes(
  websocket: bun.WebSocket(context),
  message: BitArray,
) -> WebSocketSendStatus

@external(javascript, "./server.ffi.mjs", "wsClose")
pub fn close(websocket: bun.WebSocket(context)) -> Int

@external(javascript, "./server.ffi.mjs", "wsTerminate")
pub fn terminate(websocket: bun.WebSocket(context)) -> Int

@external(javascript, "./server.ffi.mjs", "wsSubscribe")
pub fn subscribe(websocket: bun.WebSocket(context), topic: String) -> Nil

@external(javascript, "./server.ffi.mjs", "wsPing")
pub fn ping(websocket: bun.WebSocket(context)) -> Nil

@external(javascript, "./server.ffi.mjs", "wsPong")
pub fn pong(websocket: bun.WebSocket(context)) -> Nil

@external(javascript, "./server.ffi.mjs", "wsUnsubscribe")
pub fn unsubscribe(websocket: bun.WebSocket(context), topic: String) -> Nil

@external(javascript, "./server.ffi.mjs", "publish")
pub fn publish(
  websocket: bun.WebSocket(context),
  topic: String,
  message: String,
) -> WebSocketSendStatus

@external(javascript, "./server.ffi.mjs", "publish")
pub fn publish_bytes(
  websocket: bun.WebSocket(context),
  topic: String,
  message: BitArray,
) -> WebSocketSendStatus

@external(javascript, "./server.ffi.mjs", "wsIsSubscribed")
pub fn is_subscribed(websocket: bun.WebSocket(context), topic: String) -> Bool

@external(javascript, "./server.ffi.mjs", "wsCork")
pub fn cork(
  websocket: bun.WebSocket(context),
  callback: fn(bun.WebSocket(context)) -> Nil,
) -> Nil
