import brioche.{type Server}
import brioche/tls
import brioche/websocket.{type WebSocketSendStatus}
import gleam/http/request
import gleam/http/response
import gleam/javascript/promise.{type Promise}
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}

pub type Request =
  request.Request(Body)

pub type Response =
  response.Response(Body)

pub opaque type Body {
  Text(text: String)
  Json(json: Json)
  Bytes(bytes: BitArray)
  Empty
}

pub opaque type Config(context) {
  Config(
    development: Bool,
    fetch: fn(Request, Server(context)) -> Promise(Response),
    hostname: Option(String),
    idle_timeout: Option(Int),
    port: Option(Int),
    static_routes: Option(List(#(String, Response))),
    tls: Option(tls.TLS),
    unix: Option(String),
    websocket: Option(websocket.Config(context)),
  )
}

pub type IP {
  IPv4
  IPv6
}

pub type SocketAddress {
  SocketAddress(address: String, port: Int, family: IP)
}

pub const path_segments = request.path_segments

/// Every webserver is defined by a handler, that accepts incoming requests
/// and returns outcoming responses. Because JavaScript is asynchronous,
/// handlers should always return `Promise`. In Bun, every handlers can also
/// access the `Server` instance, for example to read configuration at runtime.
///
/// `handler` creates the initial configuration object for Bun servers to use
/// in conjuction with `serve`.
///
/// ```gleam
/// import brioche
/// import brioche/server.{type Request, type Response}
/// import gleam/javascript/promise.{type Promise}
///
/// pub fn main() -> brioche.Server {
///   server.handler(handler)
///   |> server.serve
/// }
///
/// fn handler(req: Request, server: brioche.Server) -> Promise(Response) {
///   server.text_response("OK")
///   |> promise.resolve
/// }
/// ```
pub fn handler(
  fetch: fn(Request, Server(context)) -> Promise(Response),
) -> Config(context) {
  Config(
    development: False,
    fetch:,
    hostname: None,
    idle_timeout: None,
    port: None,
    static_routes: None,
    tls: None,
    unix: None,
    websocket: None,
  )
}

/// If not set, defaults to environment variables `BUN_PORT`, `PORT`, `NODE_PORT`,
/// and ultimately if those are not set, on the standard port 3000.
/// Be careful, setting port to `0` will select a port randomly.
///
/// ```gleam
/// import brioche
/// import brioche/server.{type Request, type Response}
/// import gleam/javascript/promise.{type Promise}
///
/// pub fn main() -> brioche.Server {
///   server.handler(handler)
///   |> server.port(3000)
///   |> server.serve
/// }
/// ```
pub fn port(options: Config(context), port: Int) -> Config(context) {
  let port = Some(port)
  Config(..options, port:)
}

/// Hostname on which listen incoming requests. If not set, hostname defaults
/// to `0.0.0.0`.
///
/// ```gleam
/// import brioche
/// import brioche/server
///
/// pub fn main() -> brioche.Server {
///   server.handler(handler)
///   |> server.hostname("127.0.0.1")
///   |> server.serve
/// }
/// ```
pub fn hostname(options: Config(context), hostname: String) -> Config(context) {
  let hostname = Some(hostname)
  Config(..options, hostname:)
}

/// Activate or deactivate development mode in Bun. Activating development mode
/// enables a special mode in browser, displaying enriched error messages when
/// code throws an error (i.e. panic in Gleam).
///
/// ```gleam
/// import brioche
/// import brioche/server
///
/// pub fn main() -> brioche.Server {
///   server.handler(handler)
///   |> server.development(True)
///   |> server.serve
/// }
/// ```
pub fn development(
  options: Config(context),
  development: Bool,
) -> Config(context) {
  Config(..options, development:)
}

/// Serve static responses directly for certain routes. Like handlers, static
/// routes support status code, headers & body.
/// Because static routes are already pre-rendered, they're more performant than
/// handlers because instanciating `Request` or `AbortSignal` is not needed.
///
/// ```gleam
/// import brioche
/// import brioche/server
///
/// pub fn main() -> brioche.Server {
///   server.handler(handler)
///   |> server.static(static_routes())
///   |> server.serve
/// }
///
/// fn static_routes() -> List(#(String, server.Response)) {
///   [#("/healthcheck", server.text_response("OK"))]
/// }
/// ```
pub fn static(
  options: Config(context),
  static_routes: List(#(String, Response)),
) -> Config(context) {
  let static_routes = Some(static_routes)
  Config(..options, static_routes:)
}

/// Provide the path to your socket to listen on a Unix socket directly. Bun
/// supports Unix domain sockets as well as abstract namespaces sockets. In that
/// case, prefix your socket path with a null byte.
///
/// Unlike unix domain sockets, abstract namespace sockets are not bound to the
/// filesystem and are automatically removed when the last reference to the
/// socket is closed.
///
/// ```gleam
/// import brioche
/// import brioche/server
///
/// pub fn main() -> brioche.Server {
///   server.handler(handler)
///   |> server.unix("/tmp/my-socket.sock") // Unix socket
///   |> server.unix("\0my-abstract-socket") // Abstract Unix socket
///   |> server.serve
/// }
/// ```
pub fn unix(options: Config(context), unix: String) -> Config(context) {
  let unix = Some(unix)
  Config(..options, unix:)
}

/// Maximum amount of time in seconds a connection is allowed to be idle before
/// the server closes it. A connection is idling if there is no data sent or
/// received.
///
/// Timeout is in seconds here.
///
/// ```gleam
/// import brioche
/// import brioche/server
///
/// pub fn main() -> brioche.Server {
///   server.handler(handler)
///   |> server.idle_timeout(10) // 10 seconds
///   |> server.serve
/// }
/// ```
pub fn idle_timeout(
  options: Config(context),
  after timeout: Int,
) -> Config(context) {
  let idle_timeout = Some(timeout)
  Config(..options, idle_timeout:)
}

/// Set the TLS configuration to create an HTTPS server. More information can
/// be found in `brioche/tls` module.
///
/// ```gleam
/// import brioche
/// import brioche/file
/// import brioche/server
/// import brioche/tls
///
/// pub fn main() -> brioche.Server {
///   server.handler(handler)
///   |> server.tls({
///     let key = tls.File(file.new("/path/to/key/file.key"))
///     let cert = tls.File(file.new("/path/to/cert/file.cert"))
///     tls.new(key:, cert:)
///   })
/// }
/// ```
pub fn tls(options: Config(context), tls: tls.TLS) -> Config(context) {
  let tls = Some(tls)
  Config(..options, tls:)
}

/// Set the websocket configuration on the server. When not set, server will
/// reject upgrading a connection to WebSocket. More information can be found
/// in `brioche/websocket` module.
/// ```gleam
/// import brioche
/// import brioche/file
/// import brioche/server
/// import brioche/websocket
///
/// pub fn main() -> brioche.Server {
///   server.handler(handler)
///   |> server.websocket({
///     websocket.init()
///     |> websocket.on_open(fn (socket) { promise.resolve(Nil) })
///     |> websocket.on_drain(fn (socket) { promise.resolve(Nil) })
///     |> websocket.on_close(fn (socket, code, reason) { promise.resolve(Nil) })
///     |> websocket.on_text(fn (socket, text) { promise.resolve(Nil) })
///     |> websocket.on_bytes(fn (socket, bytes) { promise.resolve(Nil) })
///   })
/// }
/// ```
pub fn websocket(
  options: Config(context),
  websocket: websocket.Config(context),
) -> Config(context) {
  let websocket = Some(websocket)
  Config(..options, websocket:)
}

/// Launch the webserver with defined options. By default, Bun will never
/// shutdown itself while a webserver is running. Take a look at `ref` and
/// `unref` to modify that behaviour.
///
/// ```gleam
/// import brioche.{type Server}
/// import brioche/server.{type Request}
///
/// pub fn main() {
///   server.handler(handler)
///   |> server.port(3000)
///   |> server.hostname("0.0.0.0")
///   |> server.serve
/// }
///
/// fn handler(request: Request, server: Server) {
///   server.text_response("OK")
///   |> promise.resolve
/// }
/// ```
@external(javascript, "./server.ffi.mjs", "serve")
pub fn serve(options: Config(context)) -> Server(context)

/// Reload the webserver with new configuration. Bun will continue to serve
/// pending requests with the existing configuration, and will switch new
/// requests with the new configuration. Passing new config for host or port
/// will have no effect.
///
/// ```gleam
/// import brioche/server
///
/// pub fn main() {
///   let server =
///     server.handler(handler)
///     |> server.port(3000)
///     |> server.hostname("0.0.0.0")
///     |> server.serve
///   // Reload the server with another handler.
///   let server = server.reload(server, server.handler(handler))
/// }
///
/// fn handler(request: Request, server: Server) {
///   server.text_response("OK")
///   |> promise.resolve
/// }
/// ```
@external(javascript, "./server.ffi.mjs", "reload")
pub fn reload(
  server: Server(context),
  options: Config(context),
) -> Server(context)

/// Stop the server from accepting new connections. When forced to stop, Bun
/// will immediately stop all pending connections, otherwise it let in-flight
/// requests & WebSocket connections to complete.
///
/// ```gleam
/// import brioche/server
///
/// pub fn main() {
///   let server =
///     server.handler(handler)
///     |> server.port(3000)
///     |> server.hostname("0.0.0.0")
///     |> server.serve
///   server.stop(server)
/// }
///
/// fn handler(request: Request, server: Server) {
///   server.text_response("OK")
///   |> promise.resolve
/// }
/// ```
@external(javascript, "./server.ffi.mjs", "stop")
pub fn stop(server: Server(context), force force: Bool) -> Promise(Nil)

/// Count server as running to determine if process should be kept
/// alive or not. Restore the default behaviour of servers.
/// Returns the same server to allow you chaining calls if needed.
/// To disable that behaviour, use `unref`.
@external(javascript, "./server.ffi.mjs", "ref")
pub fn ref(server: Server(context)) -> Server(context)

/// Stop counting server as running to determine if process should be kept
/// alive or not. Returns the same server to allow you chaining calls if needed.
/// To restore the old behaviour, use `ref`.
@external(javascript, "./server.ffi.mjs", "unref")
pub fn unref(server: Server(context)) -> Server(context)

/// Set a custom idle timeout for individual requests, or pass 0 to disable
/// the timeout for a request. Timeout is indicated in seconds.
///
/// ```gleam
/// import brioche.{type Server}
/// import brioche/server.{type Request}
///
/// pub fn main() {
///   server.handler(fn (request: Request, server: Server(ctx)) {
///     server.timeout(server, request, 60)
///     // Request will timeout after 60 seconds.
///   })
///   |> server.serve
/// }
/// ```
@external(javascript, "./server.ffi.mjs", "timeout")
pub fn timeout(
  server: Server(context),
  request: Request,
  timeout: Int,
) -> Request

/// Get client IP and port information, returns `None` for closed requests or
/// Unix domain sockets.
///
/// ```gleam
/// import brioche.{type Server}
/// import brioche/server.{type Request}
///
/// pub fn main() {
///   server.handler(fn (request: Request, server: Server(ctx)) {
///     let address = server.request_ip(server, request)
///     // Use adress here.
///   })
///   |> server.serve
/// }
/// ```
@external(javascript, "./server.ffi.mjs", "requestIp")
pub fn request_ip(
  server: Server(context),
  request: Request,
) -> Option(SocketAddress)

/// Upgrade a Request to a WebSocket connection handled by Bun. In case the
/// upgrading could not be achieved, continue the execution. If the upgrade is
/// successful, `upgrade` will automatically return, and shortcut execution.
///
/// ```gleam
/// import brioche
/// import brioche/server.{type Request, type Server}
/// import gleam/javascript/promise.{type Promise}
///
/// /// Context is the data sent during the WebSocket creation. After `upgrade`
/// /// calls, it's possible to set a context scoped to the newly created
/// /// WebSocket. Any data can be set, and it's up to you to choose what
/// /// data you want to put in the context.
/// pub type Context {
///   Context(
///     /// In this example, push a session_id in the context in order
///     /// to identify the user easily across sessions if needed.
///     session_id: String,
///   )
/// }
///
/// /// Handler function used in Bun servers. Upgrading a WebSocket should be
/// /// done in a Bun handler. When upgrading, Buns respond for you, and returns
/// /// 101 Switching Protocols instead of another response (like 200 for example).
/// /// That handler upgrade a connection to WebSocket no matter what the path
/// /// is. In your real handler, you probably want to upgrade the connection iif
/// /// the request comes on a specific path (like /ws for example).
/// fn handler(req: Request, server: Server(context)) {
///   // Create the initial session for the WebSocket.
///   let session_id = brioche.random_uuid_v7()
///   let initial_context = Context(session_id:)
///   // Prepare headers to return after Bun responds 101 Switching Protocols.
///   let headers = [#("set-cookie", "session_id=" <> session_id)]
///   // Upgrade the connection.
///   use <- server.upgrade(server, request, headers, initial_context)
///   // If upgrading failed, code below will execute.
///   brioche.internal_error()
///   |> brioche.text_body("Impossible to upgrade connection, internal error.")
///   |> promise.resolve
/// }
///
/// // Run your server, and let your connection come.
/// fn main() {
///   server.handler(handler)
///   |> server.serve
/// }
/// ```
pub fn upgrade(
  server: Server(context),
  request: Request,
  headers: List(#(String, String)),
  context: context,
  next: fn() -> Promise(Response),
) -> Promise(Response) {
  case do_upgrade(server, request, headers, context) {
    // Connection has been upgraded, don't return anything.
    True -> coerce(Nil)
    // Connection has not been upgraded, continue with the following execution.
    False -> next()
  }
}

@external(javascript, "./server.ffi.mjs", "upgrade")
fn do_upgrade(
  server: Server(context),
  request: Request,
  headers: List(#(String, String)),
  context: context,
) -> Bool

@external(javascript, "./server.ffi.mjs", "publish")
pub fn publish(
  server: Server(context),
  topic: String,
  data: String,
) -> WebSocketSendStatus

@external(javascript, "./server.ffi.mjs", "publish")
pub fn publish_bytes(
  server: Server(context),
  topic: String,
  data: BitArray,
) -> WebSocketSendStatus

@external(javascript, "./server.ffi.mjs", "subscriberCount")
pub fn subscriber_count(server: Server(context), topic: String) -> Int

@external(javascript, "./server.ffi.mjs", "getPort")
pub fn get_port(server: Server(context)) -> Int

@external(javascript, "./server.ffi.mjs", "getDevelopment")
pub fn get_development(server: Server(context)) -> Bool

@external(javascript, "./server.ffi.mjs", "getHostname")
pub fn get_hostname(server: Server(context)) -> String

@external(javascript, "./server.ffi.mjs", "getId")
pub fn get_id(server: Server(context)) -> String

@external(javascript, "./server.ffi.mjs", "getPendingRequests")
pub fn get_pending_request(server: Server(context)) -> Int

@external(javascript, "./server.ffi.mjs", "getPendingWebsockets")
pub fn get_pending_websockets(server: Server(context)) -> Int

@external(javascript, "./server.ffi.mjs", "getUrl")
pub fn get_url(server: Server(context)) -> String

pub fn ok() -> Response {
  response.new(200)
  |> response.set_body(Empty)
}

pub fn text_response(content: String) -> Response {
  response.new(200)
  |> response.set_body(Text(content))
}

pub fn json_response(content: Json) -> Response {
  response.new(200)
  |> response.set_body(Json(content))
  |> response.set_header("content-type", "application/json")
}

pub fn bytes_response(content: BitArray) {
  response.new(200)
  |> response.set_body(Bytes(content))
  |> response.set_header("content-type", "application/octet-stream")
}

pub fn not_found() -> Response {
  response.new(404)
  |> response.set_body(Empty)
}

pub fn internal_error() -> Response {
  response.new(500)
  |> response.set_body(Empty)
}

pub fn text_body(response: Response, content: String) {
  response.set_body(response, Text(content))
}

pub fn json_body(response: Response, content: Json) {
  response.set_body(response, Json(content))
}

pub fn bytes_body(response: Response, content: BitArray) {
  response.set_body(response, Bytes(content))
}

pub fn empty_body(response: Response) {
  response.set_body(response, Empty)
}

@external(javascript, "./server.ffi.mjs", "coerce")
fn coerce(a: a) -> b
