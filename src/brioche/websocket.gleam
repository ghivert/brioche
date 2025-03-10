import brioche as bun
import gleam/javascript/promise.{type Promise}
import gleam/option.{type Option, None, Some}

/// Config used to setup Bun's WebSockets. Config is opaque, and is created by
/// using [`websocket.init`](#init). It is recommended for each WebSocket Config
/// to have a text handler and a bytes handler. It can have multiple other options:
/// - [`on_open`](#on_open), to set the `open` event handler.
/// - [`on_drain`](#on_drain), to set the `drain` event handler.
/// - [`on_close`](#on_close), to set the `close` event handler.
/// - [`on_text`](#on_text), to set the `message` event handler, when a text
///   message has been sent.
/// - [`on_bytes`](#on_bytes), to set the `message` event handler, when a bytes
///   message has been set.
/// - [`max_payload_length`](#max_payload_length), to define the maximum size of
///   messages in bytes. Defaults to 16 MB, or `1024 * 1024 * 16` in bytes.
/// - [`backpressure_limit`](#backpressure_limit), to define the maximum number
///   of bytes that can be buffered on a single connection. Defaults to 16 MB,
///   or `1024 * 1024 * 16` in bytes.
/// - [`close_on_backpressure_limit`](#close_on_backpressure_limit), to define
///   if the connection should be closed if `backpressure_limit` is reached.
///   Defaults to `False`.
/// - [`idle_timeout`](#idle_timeout), to define the number of seconds to
///   wait before timing out a connection due to no messages or pings. Defaults
///   to 2 minutes, or `120` in seconds.
/// - [`publish_to_self`](#publish_to_self), to define if `websocket.publish`
///   also sends a message to the websocket, if it is subscribed.
///   Defaults to `False`.
/// - [`send_pings`](#send_pings), to define if the server should automatically
///   send and respond to pings to clients. Defaults to `True`.
///
/// > Take note of the context type. That type is used to pass contextual data
/// > to every WebSocket upon initialisation with `server.upgrade`.
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
    send_pings: Option(Bool),
  )
}

/// Status representing the outcome of a sent message.
pub type WebSocketSendStatus {
  /// Received when message is dropped.
  MessageDropped
  /// Received when there is backpressure of messages.
  MessageBackpressured
  /// Received when message has been sent successfully.
  /// `bytes_sent` represents the number of bytes sent.
  MessageSent(bytes_sent: Int)
}

/// Accepting WebSockets in a Bun application is done by providing a `websocket`
/// configuration to [`serve`](https://hexdocs.pm/brioche/brioche/server.html#server).
///
/// Use `init` to create an empty `Config` option.
///
/// ```gleam
/// import brioche
/// import brioche/server
/// import brioche/websocket
///
/// type Context = Nil
///
/// pub fn main() -> brioche.Server(Context) {
///   server.handler(handler)
///   |> server.websocket(websocket())
///   |> server.serve
/// }
///
/// fn websocket() -> websocket.Config(Context) {
///   websocket.init()
///   |> websocket.on_open(on_open)
///   |> websocket.on_close(on_close)
///   |> websocket.on_bytes(on_bytes)
///   |> websocket.on_text(on_text)
/// }
/// ```
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
    send_pings: None,
  )
}

/// WebSocket emits an `open` message after a connection has been upgraded, and
/// once the connection has been established.
///
/// First argument of the handler is always the current WebSocket. It's
/// possible to use it to communicate with clients, send message, close the
/// connection, etc.
///
/// ```gleam
/// import brioche
/// import brioche/server
/// import brioche/websocket
///
/// type Context = Nil
///
/// pub fn main() -> brioche.Server(Context) {
///   server.handler(handler)
///   |> server.websocket(websocket())
///   |> server.serve
/// }
///
/// fn websocket() -> websocket.Config(Context) {
///   websocket.init()
///   |> websocket.on_open(on_open)
/// }
///
/// fn on_open(ws: brioche.WebSocket(Context)) {
///   // Connection has been established!
///   websocket.send(ws, "Connected!")
///   websocket.send_bytes(ws, <<"Connected!">>)
///   promise.resolve(Nil)
/// }
/// ```
pub fn on_open(
  config: Config(context),
  handler: fn(bun.WebSocket(context)) -> Promise(Nil),
) -> Config(context) {
  let open = Some(handler)
  Config(..config, open:)
}

/// WebSocket emits a `drain` message after a backpressure has been applied, and
/// that WebSocket is now able to handle new data.
///
/// First argument of the handler is always the current WebSocket. It's
/// possible to use it to communicate with clients, send message, close the
/// connection, etc.
///
/// ```gleam
/// import brioche
/// import brioche/server
/// import brioche/websocket
///
/// type Context = Nil
///
/// pub fn main() -> brioche.Server(Context) {
///   server.handler(handler)
///   |> server.websocket(websocket())
///   |> server.serve
/// }
///
/// fn websocket() -> websocket.Config(Context) {
///   websocket.init()
///   |> websocket.on_drain(on_drain)
/// }
///
/// fn on_drain(ws: brioche.WebSocket(Context)) {
///   // WebSocket is now usable again!
///   websocket.send(ws, "Drained!")
///   websocket.send_bytes(ws, <<"Drained!">>)
///   promise.resolve(Nil)
/// }
/// ```
pub fn on_drain(
  config: Config(context),
  handler: fn(bun.WebSocket(context)) -> Promise(Nil),
) -> Config(context) {
  let drain = Some(handler)
  Config(..config, drain:)
}

/// WebSocket emits a `close` message after the WebSocket has been closed,
/// whether from the server or the client.
///
/// First argument of the handler is always the current WebSocket. It's
/// possible to use it to communicate with clients, send message, close the
/// connection, etc.
///
/// Second argument is the error code, as a number. Non exhaustive list of
/// close codes.
/// - `1000` means "normal closure" **(default)**.
/// - `1009` means a message was too big and was rejected.
/// - `1011` means the server encountered an error.
/// - `1012` means the server is restarting.
/// - `1013` means the server is too busy or the client is rate-limited.
/// - `4000` through `4999` are reserved for applications.
///
/// Third argument is the reason, as string.
///
/// ```gleam
/// import brioche
/// import brioche/server
/// import brioche/websocket
///
/// type Context = Nil
///
/// pub fn main() -> brioche.Server(Context) {
///   server.handler(handler)
///   |> server.websocket(websocket())
///   |> server.serve
/// }
///
/// fn websocket() -> websocket.Config(Context) {
///   websocket.init()
///   |> websocket.on_close(on_close)
/// }
///
/// fn on_close(ws: brioche.WebSocket(Context)) {
///   // WebSocket is closing!
///   websocket.send(ws, "Closing!")
///   websocket.send_bytes(ws, <<"Closing!">>)
///   promise.resolve(Nil)
/// }
/// ```
pub fn on_close(
  config: Config(context),
  handler: fn(bun.WebSocket(context), Int, String) -> Promise(Nil),
) -> Config(context) {
  let close = Some(handler)
  Config(..config, close:)
}

/// WebSocket emits a `message` message after after receiving a message. A
/// message can be binary or textual. In `brioche`, the hard routing & decoding
/// task is already done for you. You can subscribe to messages emitted as text
/// or binary simply by using `on_text` or `on_bytes`.
///
/// First argument of the handler is always the current WebSocket. It's
/// possible to use it to communicate with clients, send message, close the
/// connection, etc.
///
/// Second argument is the text message received.
///
/// ```gleam
/// import brioche
/// import brioche/server
/// import brioche/websocket
/// import gleam/bit_array
/// import gleam/io
///
/// type Context = Nil
///
/// pub fn main() -> brioche.Server(Context) {
///   server.handler(handler)
///   |> server.websocket(websocket())
///   |> server.serve
/// }
///
/// fn websocket() -> websocket.Config(Context) {
///   websocket.init()
///   |> websocket.on_text(on_text)
/// }
///
/// fn on_text(ws: brioche.WebSocket(Context), message: String) {
///   // WebSocket received a textual message!
///   io.println("WebSocket received a message: " <> message)
///   websocket.send(ws, "Echoed message: " <> message)
///   let message = bit_array.from_string(message)
///   let message = bit_array.append(<<"Echoed message: ">>, message)
///   websocket.send_bytes(ws, message)
///   promise.resolve(Nil)
/// }
/// ```
pub fn on_text(
  config: Config(context),
  handler: fn(bun.WebSocket(context), String) -> Promise(Nil),
) -> Config(context) {
  let text_message = Some(handler)
  Config(..config, text_message:)
}

/// WebSocket emits a `message` message after after receiving a message. A
/// message can be binary or textual. In `brioche`, the hard routing & decoding
/// task is already done for you. You can subscribe to messages emitted as text
/// or binary simply by using `on_text` or `on_bytes`.
///
/// First argument of the handler is always the current WebSocket. It's
/// possible to use it to communicate with clients, send message, close the
/// connection, etc.
///
/// Second argument is the binary message received.
///
/// ```gleam
/// import brioche
/// import brioche/server
/// import brioche/websocket
/// import gleam/bit_array
/// import gleam/io
///
/// type Context = Nil
///
/// pub fn main() -> brioche.Server(Context) {
///   server.handler(handler)
///   |> server.websocket(websocket())
///   |> server.serve
/// }
///
/// fn websocket() -> websocket.Config(Context) {
///   websocket.init()
///   |> websocket.on_bytes(on_bytes)
/// }
///
/// fn on_bytes(ws: brioche.WebSocket(Context), message: BitArray) {
///   // WebSocket received a binary message!
///   io.println("WebSocket received a message!")
///   let message = bit_array.from_string(message)
///   let message = bit_array.append(<<"Echoed message: ">>, message)
///   websocket.send_bytes(ws, message)
///   promise.resolve(Nil)
/// }
/// ```
pub fn on_bytes(
  config: Config(context),
  handler: fn(bun.WebSocket(context), BitArray) -> Promise(Nil),
) -> Config(context) {
  let bytes_message = Some(handler)
  Config(..config, bytes_message:)
}

/// Define the maximum size of messages in bytes. \
/// Defaults to 16 MB, or `1024 * 1024 * 16` in bytes.
///
/// ```gleam
/// import brioche/websocket
///
/// pub fn ws_config() {
///   websocket.init()
///   // Sets payload size to 1024 MB, or 1 GB.
///   |> websocket.max_payload_length(1024 * 1024 * 1024)
/// }
/// ```
pub fn max_payload_length(
  config: Config(context),
  max_payload_length: Int,
) -> Config(context) {
  let max_payload_length = Some(max_payload_length)
  Config(..config, max_payload_length:)
}

/// Defines the maximum number of bytes that can be buffered on a single
/// connection. \
/// Defaults to 16 MB, or `1024 * 1024 * 16` in bytes.
///
/// ```gleam
/// import brioche/websocket
///
/// pub fn ws_config() {
///   websocket.init()
///   // Sets maximum buffer size to 1024 MB, or 1 GB.
///   |> websocket.backpressure_limit(1024 * 1024 * 1024)
/// }
/// ```
pub fn backpressure_limit(
  config: Config(context),
  backpressure_limit: Int,
) -> Config(context) {
  let backpressure_limit = Some(backpressure_limit)
  Config(..config, backpressure_limit:)
}

/// Defines if the connection should be closed if `backpressure_limit`
/// is reached. \
/// Defaults to `False`.
///
/// ```gleam
/// import brioche/websocket
///
/// pub fn ws_config() {
///   websocket.init()
///   // Sets connection to close if backpressure limit is reached.
///   |> websocket.close_on_backpressure_limit(True)
/// }
/// ```
pub fn close_on_backpressure_limit(
  config: Config(context),
  close_on_backpressure_limit: Int,
) -> Config(context) {
  let close_on_backpressure_limit = Some(close_on_backpressure_limit)
  Config(..config, close_on_backpressure_limit:)
}

/// Defines the number of seconds to wait before timing out a connection due to
/// no messages or pings. \
/// Defaults to 2 minutes, or `120` in seconds.
///
/// ```gleam
/// import brioche/websocket
///
/// pub fn ws_config() {
///   websocket.init()
///   // Sets the idle timeout to 1 minute.
///   |> websocket.idle_timeout(60)
/// }
/// ```
pub fn idle_timeout(
  config: Config(context),
  idle_timeout: Int,
) -> Config(context) {
  let idle_timeout = Some(idle_timeout)
  Config(..config, idle_timeout:)
}

/// Defines if `websocket.publish` also sends a message to the websocket, if it
/// is subscribed. \
/// Defaults to `False`.
///
/// ```gleam
/// import brioche/websocket
///
/// pub fn ws_config() {
///   websocket.init()
///   // Sets WebSocket to publish to itself when publishing.
///   |> websocket.publish_to_self(True)
/// }
/// ```
pub fn publish_to_self(
  config: Config(context),
  publish_to_self: Bool,
) -> Config(context) {
  let publish_to_self = Some(publish_to_self)
  Config(..config, publish_to_self:)
}

/// Defines if the server should automatically send and respond to pings to
/// clients. \
/// Defaults to `True`.
///
/// ```gleam
/// import brioche/websocket
///
/// pub fn ws_config() {
///   websocket.init()
///   // Sets the connection to not automatically send and respond to pings.
///   |> websocket.send_pings(False)
/// }
/// ```
pub fn send_pings(config: Config(context), send_pings: Bool) -> Config(context) {
  let send_pings = Some(send_pings)
  Config(..config, send_pings:)
}

/// Read the `data` stored on the WebSocket upon initialisation.
///
/// ```gleam
/// import brioche
/// import brioche/server
/// import brioche/websocket
/// import gleam/bit_array
/// import gleam/io
///
/// type Context = String
///
/// pub fn main() -> brioche.Server(Context) {
///   server.handler(handler)
///   |> server.websocket(websocket())
///   |> server.serve
/// }
///
/// fn handler(request: server.Request, server: brioche.Server(Context)) {
///   let headers = []
///   let session_id = brioche.random_uuid_v7()
///   use <- server.upgrade(server, request, headers, session_id)
///   server.internal_error()
/// }
///
/// fn websocket() -> websocket.Config(Context) {
///   websocket.init()
///   |> websocket.on_text(on_text)
/// }
///
/// fn on_text(ws: brioche.WebSocket(Context), text: String) {
///   let session_id = websocket.data(ws)
///   websocket.send("Your session_id is: " <> session_id)
///   promise.resolve(Nil)
/// }
/// ```
@external(javascript, "./server.ffi.mjs", "data")
pub fn data(websocket: bun.WebSocket(context)) -> context

/// Read the state of the Websocket.
///
/// - If `0`, the client is connecting.
/// - If `1`, the client is connected.
/// - If `2`, the client is closing.
/// - If `3`, the client is closed.
@external(javascript, "./server.ffi.mjs", "readyState")
pub fn ready_state(websocket: bun.WebSocket(context)) -> Int

/// Read IP address of the client.
///
/// ```gleam
/// fn on_text(ws: brioche.WebSocket(context), message: String) {
///   websocket.remote_address(ws)
///   // -> "127.0.0.1"
///   promise.resolve(Nil)
/// }
/// ```
@external(javascript, "./server.ffi.mjs", "remoteAddress")
pub fn remote_address(websocket: bun.WebSocket(context)) -> String

/// Send a textual message to the connected client.
///
/// ```gleam
/// import brioche
/// import brioche/websocket
///
/// fn on_text(ws: brioche.WebSocket(context), message: String) {
///   // Echoes back the message.
///   websocket.send(ws, "Message received! " <> message)
///   promise.resolve(Nil)
/// }
/// ```
@external(javascript, "./server.ffi.mjs", "wsSend")
pub fn send(
  websocket: bun.WebSocket(context),
  message: String,
) -> WebSocketSendStatus

/// Send a binary message to the connected client.
///
/// ```gleam
/// import brioche
/// import brioche/websocket
///
/// fn on_bytes(ws: brioche.WebSocket(context), message: BitArray) {
///   // Echoes back the message.
///   websocket.send_bytes(ws, message)
///   promise.resolve(Nil)
/// }
/// ```
@external(javascript, "./server.ffi.mjs", "wsSend")
pub fn send_bytes(
  websocket: bun.WebSocket(context),
  message: BitArray,
) -> WebSocketSendStatus

/// Closes the connection. Non exhaustive list of close codes.
/// - `1000` means "normal closure" **(default)**.
/// - `1009` means a message was too big and was rejected.
/// - `1011` means the server encountered an error.
/// - `1012` means the server is restarting.
/// - `1013` means the server is too busy or the client is rate-limited.
/// - `4000` through `4999` are reserved for applications (usable by developers).
/// To close the connection abruptly, use [`terminate`](#terminate).
@external(javascript, "./server.ffi.mjs", "wsClose")
pub fn close(
  websocket: bun.WebSocket(context),
  code: Int,
  reason: String,
) -> Int

/// Abruptly close the connection. \
/// To gracefully close the connection, use [`close`](#close).
@external(javascript, "./server.ffi.mjs", "wsTerminate")
pub fn terminate(websocket: bun.WebSocket(context)) -> Int

/// Bun makes it easy to implement a Pub-Sub mechanism by using topics. Every
/// WebSocket can subscribe to specific topics, and listen on new incoming
/// messages. Every time the server or another WebSocket publishes on that
/// topic, every listening WebSockets will receive the message.
///
/// To unsubscribe to a topic, take a look at [`unsubscribe`](#unsubscribe).
///
/// ```gleam
/// import brioche
/// import brioche/server
/// import brioche/websocket
///
/// // Context is the session id.
/// type Context = String
///
/// pub fn main() -> brioche.Server(Context) {
///   server.handler(handler)
///   |> server.websocket(websocket())
///   |> server.serve
/// }
///
/// fn websocket() -> websocket.Config(Context) {
///   websocket.init()
///   |> websocket.on_open(on_open)
///   |> websocket.on_text(on_text)
/// }
///
/// fn on_open(ws: brioche.WebSocket(Context)) {
///   // Subscribing to new connected users.
///   websocket.subscribe(ws, "new-users")
///   // Sending the information to other users that we're connecting.
///   json.object([
///     #("session_id", json.string(websocket.data(ws))),
///     #("name", json.string("John Doe")),
///   ])
///   |> json.to_string
///   |> websocket.publish(ws, "new-users", _)
///   promise.resolve(Nil)
/// }
///
/// fn on_text(ws: brioche.WebSocket(Context), message: String) {
///   // Decode the data.
///   let decoder = {
///     use session_id <- decode.field("session_id", decode.string)
///     use name <- decode.field("name", decode.string)
///     #(session_id, name)
///   }
///   case json.parse(message, decode.at(["session_id"], decode.string)) {
///     // Ignore the error, message is not for us.
///     Error(_) -> promise.resolve(Nil)
///     // Signal a new user connected.
///     Ok(#(session_id, name)) -> {
///       // Create the new data to send.
///       json.object([
///         #("name", json.string(name)),
///         #("type", json.string("new-connected-user")),
///       ])
///       |> json.string
///       |> websocket.send(ws, _)
///       promise.resolve(Nil)
///     }
///   }
/// }
/// ```
@external(javascript, "./server.ffi.mjs", "wsSubscribe")
pub fn subscribe(websocket: bun.WebSocket(context), topic: String) -> Nil

/// Send a ping message. Ping and pong messages are part of the WebSockets
/// Heartbeat. [More information can be found on MDN for that subject.](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API/Writing_WebSocket_servers#pings_and_pongs_the_heartbeat_of_websockets)
@external(javascript, "./server.ffi.mjs", "wsPing")
pub fn ping(websocket: bun.WebSocket(context)) -> Nil

/// Send a pong message. Ping and pong messages are part of the WebSockets
/// Heartbeat. [More information can be found on MDN for that subject.](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API/Writing_WebSocket_servers#pings_and_pongs_the_heartbeat_of_websockets)
@external(javascript, "./server.ffi.mjs", "wsPong")
pub fn pong(websocket: bun.WebSocket(context)) -> Nil

/// Unsubscribe from a topic. To get more information on Pub-Sub, topics and
/// subscriptions, take a look at [`subscribe`](#subscribe).
@external(javascript, "./server.ffi.mjs", "wsUnsubscribe")
pub fn unsubscribe(websocket: bun.WebSocket(context), topic: String) -> Nil

/// Publish textual message to a topic. To get more information on Pub-Sub,
/// topics and subscriptions, take a look at [`subscribe`](#subscribe).
@external(javascript, "./server.ffi.mjs", "publish")
pub fn publish(
  websocket: bun.WebSocket(context),
  topic: String,
  message: String,
) -> WebSocketSendStatus

/// Publish binary message to a topic. To get more information on Pub-Sub,
/// topics and subscriptions, take a look at [`subscribe`](#subscribe).
@external(javascript, "./server.ffi.mjs", "publish")
pub fn publish_bytes(
  websocket: bun.WebSocket(context),
  topic: String,
  message: BitArray,
) -> WebSocketSendStatus

/// Indicates if a WebSocket is connected to a topic or not.
/// To get more information on Pub-Sub, topics and subscriptions, take a
/// look at [`subscribe`](#subscribe).
@external(javascript, "./server.ffi.mjs", "wsIsSubscribed")
pub fn is_subscribed(websocket: bun.WebSocket(context), topic: String) -> Bool

/// Batches [`send`](#send) and [`publish`](#publish) operations, which makes
/// it faster to send data.
///
/// The `message`, `open`, and `drain` callbacks are automatically corked, so
/// you only need to call this if you are sending messages outside of those
/// callbacks or in async functions.
///
/// ```gleam
/// fn on_text(ws: brioche.WebSocket(context), message: String) {
///   use _ <- promise.map(promise.wait(1000))
///   use ws <- websocket.cork()
///   websocket.send(ws, "My message")
///   websocket.send(ws, "My other message")
/// }
/// ```
@external(javascript, "./server.ffi.mjs", "wsCork")
pub fn cork(
  websocket: bun.WebSocket(context),
  callback: fn(bun.WebSocket(context)) -> Nil,
) -> Nil
