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

/// Every webserver is defined by a handler, that accepts incoming requests
/// and returns outcoming responses. Because JavaScript is asynchronous,
/// handlers should return `Promise`. In Bun, every handlers can also access the
/// `Server` instance, for example to read configuration at runtime.
///
/// `handler` creates the initial configuration object for Bun servers to use in
/// conjuction with `serve`.
///
/// ```gleam
/// import bun
/// import bun/server.{type Request, type Response}
/// import gleam/javascript/promise.{type Promise}
///
/// pub fn main() -> bun.Server {
///   server.handler(handler)
///   |> server.serve
/// }
///
/// fn handler(req: Request, server: bun.Server) -> Promise(Response) {
///   server.text_response("OK")
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
pub fn port(options: Config(context), port: Int) -> Config(context) {
  let port = Some(port)
  Config(..options, port:)
}

/// Hostname on which listen incoming requests. If not set, hostname defaults
/// to `0.0.0.0`.
///
/// ```gleam
/// import bun
/// import bun/server
///
/// pub fn main() -> bun.Server {
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
/// import bun
/// import bun/server
///
/// pub fn main() -> bun.Server {
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
/// import bun
/// import bun/server
///
/// pub fn main() -> bun.Server {
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
/// import bun
/// import bun/server
///
/// pub fn main() -> bun.Server {
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
/// ```gleam
/// import bun
/// import bun/server
///
/// pub fn main() -> bun.Server {
///   server.handler(handler)
///   |> server.idle_timeout(10) // 10 seconds
///   |> server.serve
/// }
/// ```
pub fn idle_timeout(options: Config(context), timeout: Int) -> Config(context) {
  let idle_timeout = Some(timeout)
  Config(..options, idle_timeout:)
}

pub fn tls(options: Config(context), tls: tls.TLS) -> Config(context) {
  let tls = Some(tls)
  Config(..options, tls:)
}

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
/// import bun.{type Server}
/// import bun/server.{type Request}
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
/// requests with the new configuration.
@external(javascript, "./server.ffi.mjs", "reload")
pub fn reload(
  server: Server(context),
  options: Config(context),
) -> Server(context)

/// Stop the server from accepting new connections. When forced to stop, Bun
/// will immediately stop all pending connections, otherwise it let in-flight
/// requests & WebSocket connections to complete.
@external(javascript, "./server.ffi.mjs", "stop")
pub fn stop(server: Server(context), force: Bool) -> Promise(Nil)

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

@external(javascript, "./server.ffi.mjs", "timeout")
pub fn timeout(
  server: Server(context),
  request: Request,
  timeout: Int,
) -> Request

@external(javascript, "./server.ffi.mjs", "requestIp")
pub fn request_ip(
  server: Server(context),
  request: Request,
  timeout: Int,
) -> Option(SocketAddress)

@external(javascript, "./server.ffi.mjs", "upgrade")
pub fn upgrade(
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
pub fn subscriber_count(server: Server(context), topi: String) -> Int

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
