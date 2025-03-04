import brioche.{type Server}
import brioche/tls
import brioche/websocket.{type WebSocketSendStatus}
import gleam/bytes_tree.{type BytesTree}
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/javascript/promise.{type Promise}
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import gleam/string_tree.{type StringTree}
import gleam/uri

/// Incoming request received by a server. `brioche` converts every incoming
/// request to Gleam `Request`, and takes care of everything.
/// `Request` still exposes the real JavaScript
/// [`Request`](https://developer.mozilla.org/docs/Web/API/Request)
/// in its body in case interoperability is needed with JavaScript or TypeScript.
pub type Request =
  request.Request(IncomingMessage)

/// Outgoing response sent by the server in response to an incoming request, or
/// as a static response. Gleam `Response` are not identical to JavaScript
/// `Response`, and `brioche` takes care of the conversion between the two.
pub type Response =
  response.Response(Body)

/// Incoming message received by a server. Under-the-hood, `IntomingMessage`
/// is the real JavaScript `Request` object. Due to its nature, it cannot be
/// used as-is in Gleam. `IncomingMessage` should always be managed directly
/// with the appropriate functions to stay type-safe all along.
pub type IncomingMessage

/// Body of outgoing response, which can be text, JSON, bit array or empty.
/// Be careful, setting a response body manually will not set appropriate
/// headers. [`json_response`](#json_response) or
/// [`bit_array_response`](#bit_array_response) should always be privileged
/// instead in order to automatically set the appropriate headers when
/// needed (`content-type`, etc.).
pub type Body {
  /// Any String text. Used when returning anything else than JSON or bit array
  /// is needed, like HTML or encoded data. Correct `content-type` should always
  /// be set in the response header accordingly.
  Text(text: String)
  /// JSON content exclusively. Any JSON can be sent in `Text`, but JSON field
  /// provides type safety to guarantee JSON is sent, and not anything else.
  /// `content-type: application/json` header is automatically used when using
  /// JSON functions, and should not be overriden. However, it is always
  /// possible to change it (when defining a custom protocol, for example).
  Json(json: Json)
  /// Bit Array content. Used to transfer raw data, like pictures or any
  /// binary encoded data. Setting the `content-type` header to
  /// `application/octet-stream` is most of the time appropriate, but it's also
  /// possible to set it to something that suits the content, like the
  /// [mime type](https://developer.mozilla.org/docs/Web/HTTP/MIME_types/Common_types)
  /// of the blob being sent.
  Bytes(bytes: BitArray)
  /// Empty body. Used when generating a simple response, like [`ok`](#ok).
  Empty
}

/// Config used to setup a Bun's server. Config is opaque, and is created by
/// using [`server.handler`](#handler). Every server must have a handler (even
/// if a simple default "OK"), and can have a bun of options:
/// - [`development`](#development), to set the development mode. Defaults to `True`.
/// - [`hostname`](#hostname), to set the hostname to listen to. Defaults to `"0.0.0.0"`.
/// - [`idle_timeout`](#idle_timeout), to set the default timeout for a request.
///   Defaults to `10`.
/// - [`port`](#port), to set the port to listen to. Defaults to `3000`.
/// - [`static_routes`](#static_routes), to define default static routes.
/// - [`tls`](#tls), to define HTTPS options.
/// - [`unix`](#unix), to listen to a Unix socket instead of HTTP.
/// - [`websocket`](#websocket), to handle WebSockets connections.
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
  /// Address with shape `www.xxx.yyy.zzz`.
  IPv4(ip: String)
  /// Address with shape `xxx:xxxx:xxxx:xxxx:xxxx:xxxx:xxxx:xxxx`.
  IPv6(ip: String)
}

/// Define an address for a Socket.
pub type SocketAddress {
  SocketAddress(
    /// Port, in integer format.
    port: Int,
    /// IP address, in corresponding format.
    address: IP,
  )
}

/// Read path segments as a `List(String)`. Used in simple routing.
///
/// ```gleam
/// /// Simple router matching routes `/`, `/example` & `/example/:id`. All
/// /// other routes returns a 404 Not Found.
/// fn main() {
///   server.handler(fn (request, _server) {
///     case server.path_segments(request) {
///       [] -> server.text_response("Root")
///       ["example"] -> server.text_response("Example")
///       ["example", example_id] -> server.text_response("Example ID")
///       _ -> server.not_found()
///     }
///   })
/// }
/// ```
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
/// code throws an error (i.e. panic in Gleam). Defaults to `True`. Should be
/// set to `False` in production to avoid leaking important information.
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

/// Provide the path to a socket to listen on a Unix socket directly. Bun
/// supports Unix domain sockets as well as abstract namespaces sockets. In that
/// case, prefix the socket path with a null byte.
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
/// Returns the same server to allow chaining calls if needed.
/// `unref` can be used to disable that behaviour.
@external(javascript, "./server.ffi.mjs", "ref")
pub fn ref(server: Server(context)) -> Server(context)

/// Stop counting server as running to determine if process should be kept
/// alive or not. Returns the same server to allow chaining calls if needed.
/// `ref` restore the old behaviour.
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

/// TODO
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
    // Connection has been upgraded, return undefined.
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

/// TODO
@external(javascript, "./server.ffi.mjs", "publish")
pub fn publish(
  server: Server(context),
  topic: String,
  data: String,
) -> WebSocketSendStatus

/// TODO
@external(javascript, "./server.ffi.mjs", "publish")
pub fn publish_bytes(
  server: Server(context),
  topic: String,
  data: BitArray,
) -> WebSocketSendStatus

/// TODO
@external(javascript, "./server.ffi.mjs", "subscriberCount")
pub fn subscriber_count(server: Server(context), topic: String) -> Int

/// Get the current port the server is listening on.
///
/// ```gleam
/// let server = server.handler(handler) |> server.port(0) |> server.serve
/// let port = server.get_port(server)
/// /// port is the defined port by the server.
/// ```
@external(javascript, "./server.ffi.mjs", "getPort")
pub fn get_port(server: Server(context)) -> Int

/// Get the current development mode. `True` if the server runs in development
/// mode, `False` otherwise.
///
/// ```gleam
/// let server = server.handler(handler) |> server.serve
/// let is_dev = server.get_development(server)
/// /// is_dev == True
/// ```
@external(javascript, "./server.ffi.mjs", "getDevelopment")
pub fn get_development(server: Server(context)) -> Bool

/// Get the hostname the server is listening to.
///
/// ```gleam
/// let server = server.handler(handler) |> server.serve
/// let hostname = server.get_hostname(server)
/// /// hostname == "0.0.0.0"
/// ```
@external(javascript, "./server.ffi.mjs", "getHostname")
pub fn get_hostname(server: Server(context)) -> String

/// Get the server instance identifier.
///
/// ```gleam
/// let server = server.handler(handler) |> server.serve
/// let id: String = server.get_id(server)
/// ```
@external(javascript, "./server.ffi.mjs", "getId")
pub fn get_id(server: Server(context)) -> String

/// Get the current pending requests the server is handling when called.
///
/// ```gleam
/// let server = server.handler(handler) |> server.serve
/// let requests = server.get_pending_requests(server)
/// // requests == 0
/// ```
@external(javascript, "./server.ffi.mjs", "getPendingRequests")
pub fn get_pending_requests(server: Server(context)) -> Int

/// Get the current pending opened WebSockets the server is maintaining when called.
///
/// ```gleam
/// let server = server.handler(handler) |> server.serve
/// let websockets = server.get_pending_websockets(server)
/// // websockets == 0
/// ```
@external(javascript, "./server.ffi.mjs", "getPendingWebsockets")
pub fn get_pending_websockets(server: Server(context)) -> Int

@external(javascript, "./server.ffi.mjs", "getUrl")
fn do_get_url(server: Server(context)) -> String

/// Get the current URI of the server. Gleam counterpart of `server.url`.
///
/// ```gleam
/// let server = server.handler(handler) |> server.serve
/// let uri = server.get_uri(server)
/// // uri == uri.Uri
/// ```
pub fn get_uri(server: Server(context)) -> uri.Uri {
  let uri = do_get_url(server)
  let assert Ok(uri) = uri.parse(uri)
  uri
}

pub fn response(status: Int) -> Response {
  response.new(status)
  |> response.set_body(Empty)
}

pub fn ok() -> Response {
  response.Response(200, [], Empty)
}

pub fn text_response(content: String) -> Response {
  response.Response(200, [], Text(content))
}

pub fn json_response(content: Json, status: Int) -> Response {
  let content = Json(content)
  let headers = [#("content-type", "text/html; charset=utf-8")]
  response.Response(status, headers, content)
}

pub fn bytes_response(content: BitArray) -> Response {
  let content = Bytes(content)
  let headers = [#("content-type", "application/octet-stream")]
  response.Response(200, headers, content)
}

pub fn bytes_body(response: Response, content: BitArray) -> Response {
  response
  |> response.set_body(Bytes(content))
  |> response.set_header("content-type", "application/octet-stream")
}

pub fn bytes_tree_response(content: BytesTree) -> Response {
  let content = Bytes(bytes_tree.to_bit_array(content))
  let headers = [#("content-type", "application/octet-stream")]
  response.Response(200, headers, content)
}

pub fn bytes_tree_body(response: Response, content: BytesTree) -> Response {
  response
  |> response.set_body(Bytes(bytes_tree.to_bit_array(content)))
  |> response.set_header("content-type", "application/octet-stream")
}

/// Set the body of a response to a given HTML document, and set the
/// `content-type` header to `text/html`.
///
/// The body is expected to be valid HTML, though this is not validated.
///
/// # Examples
///
/// ```gleam
/// let body = string_tree.from_string("<h1>Hello, Joe!</h1>")
/// response(201)
/// |> html_body(body)
/// // -> Response(201, [#("content-type", "text/html; charset=utf-8")], Text(body))
/// ```
///
pub fn html_body(response: Response, html: String) -> Response {
  response
  |> response.set_body(Text(html))
  |> response.set_header("content-type", "text/html; charset=utf-8")
}

/// Set the body of a response to a given JSON document, and set the
/// `content-type` header to `application/json`.
///
/// The body is expected to be valid JSON, though this is not validated.
///
/// # Examples
///
/// ```gleam
/// let body = string_tree.from_string("{\"name\": \"Joe\"}")
/// response(201)
/// |> json_body(body)
/// // -> Response(201, [#("content-type", "application/json; charset=utf-8")], Text(body))
/// ```
///
pub fn json_body(response: Response, json: Json) -> Response {
  response
  |> response.set_body(Json(json))
  |> response.set_header("content-type", "application/json; charset=utf-8")
}

/// Set the body of a response to a given string tree.
///
/// You likely want to also set the request `content-type` header to an
/// appropriate value for the format of the content.
///
/// # Examples
///
/// ```gleam
/// let body = string_tree.from_string("Hello, Joe!")
/// response(201)
/// |> string_tree_body(body)
/// // -> Response(201, [], Text(body))
/// ```
///
pub fn string_tree_body(response: Response, content: StringTree) -> Response {
  response
  |> response.set_body(Text(string_tree.to_string(content)))
}

/// Set the body of a response to a given string.
///
/// You likely want to also set the request `content-type` header to an
/// appropriate value for the format of the content.
///
/// # Examples
///
/// ```gleam
/// let body =
/// response(201)
/// |> string_body("Hello, Joe!")
/// // -> Response(
/// //   201,
/// //   [],
/// //   Text(string_tree.from_string("Hello, Joe"))
/// // )
/// ```
///
pub fn text_body(response: Response, content: String) -> Response {
  response
  |> response.set_body(Text(content))
}

@external(javascript, "./server.ffi.mjs", "escapeHTML")
pub fn escape_html(content: String) -> String

/// Create an empty response with status code 405: Method Not Allowed. Use this
/// when a request does not have an appropriate method to be handled.
///
/// The `allow` header will be set to a comma separated list of the permitted
/// methods.
///
/// # Examples
///
/// ```gleam
/// method_not_allowed(allowed: [Get, Post])
/// // -> Response(405, [#("allow", "GET, POST")], Empty)
/// ```
///
pub fn method_not_allowed(allowed methods: List(http.Method)) -> Response {
  let allowed =
    methods
    |> list.map(http.method_to_string)
    |> list.sort(string.compare)
    |> string.join(", ")
    |> string.uppercase
  response.Response(405, [#("allow", allowed)], Empty)
}

/// Create an empty response with status code 201: Created.
///
/// # Examples
///
/// ```gleam
/// created()
/// // -> Response(201, [], Empty)
/// ```
///
pub fn created() -> Response {
  response.Response(201, [], Empty)
}

/// Create an empty response with status code 202: Accepted.
///
/// # Examples
///
/// ```gleam
/// accepted()
/// // -> Response(202, [], Empty)
/// ```
///
pub fn accepted() -> Response {
  response.Response(202, [], Empty)
}

/// Create an empty response with status code 303: See Other, and the `location`
/// header set to the given URL. Used to redirect the client to another page.
///
/// # Examples
///
/// ```gleam
/// redirect(to: "https://example.com")
/// // -> Response(303, [#("location", "https://example.com")], Empty)
/// ```
///
pub fn redirect(to url: String) -> Response {
  response.Response(303, [#("location", url)], Empty)
}

/// Create an empty response with status code 308: Moved Permanently, and the
/// `location` header set to the given URL. Used to redirect the client to
/// another page.
///
/// This redirect is permanent and the client is expected to cache the new
/// location, using it for future requests.
///
/// # Examples
///
/// ```gleam
/// moved_permanently(to: "https://example.com")
/// // -> Response(308, [#("location", "https://example.com")], Empty)
/// ```
///
pub fn moved_permanently(to url: String) -> Response {
  response.Response(308, [#("location", url)], Empty)
}

/// Create an empty response with status code 204: No content.
///
/// # Examples
///
/// ```gleam
/// no_content()
/// // -> Response(204, [], Empty)
/// ```
///
pub fn no_content() -> Response {
  response.Response(204, [], Empty)
}

/// Create an empty response with status code 404: No content.
///
/// # Examples
///
/// ```gleam
/// not_found()
/// // -> Response(404, [], Empty)
/// ```
///
pub fn not_found() -> Response {
  response.Response(404, [], Empty)
}

/// Create an empty response with status code 400: Bad request.
///
/// # Examples
///
/// ```gleam
/// bad_request()
/// // -> Response(400, [], Empty)
/// ```
///
pub fn bad_request() -> Response {
  response.Response(400, [], Empty)
}

/// Create an empty response with status code 413: Entity too large.
///
/// # Examples
///
/// ```gleam
/// entity_too_large()
/// // -> Response(413, [], Empty)
/// ```
///
pub fn entity_too_large() -> Response {
  response.Response(413, [], Empty)
}

/// Create an empty response with status code 415: Unsupported media type.
///
/// The `allow` header will be set to a comma separated list of the permitted
/// content-types.
///
/// # Examples
///
/// ```gleam
/// unsupported_media_type(accept: ["application/json", "text/plain"])
/// // -> Response(415, [#("allow", "application/json, text/plain")], Empty)
/// ```
///
pub fn unsupported_media_type(accept acceptable: List(String)) -> Response {
  let acceptable = string.join(acceptable, ", ")
  response.Response(415, [#("accept", acceptable)], Empty)
}

/// Create an empty response with status code 422: Unprocessable entity.
///
/// # Examples
///
/// ```gleam
/// unprocessable_entity()
/// // -> Response(422, [], Empty)
/// ```
///
pub fn unprocessable_entity() -> Response {
  response.Response(422, [], Empty)
}

/// Create an empty response with status code 500: Internal server error.
///
/// # Examples
///
/// ```gleam
/// internal_server_error()
/// // -> Response(500, [], Empty)
/// ```
///
pub fn internal_server_error() -> Response {
  response.Response(500, [], Empty)
}

pub fn set_body(response: Response, body: Body) {
  response.set_body(response, body)
}

/// Create a HTML response.
///
/// The body is expected to be valid HTML, though this is not validated.
/// The `content-type` header will be set to `text/html`.
///
/// # Examples
///
/// ```gleam
/// let body = string_tree.from_string("<h1>Hello, Joe!</h1>")
/// html_response(body, 200)
/// // -> Response(200, [#("content-type", "text/html")], Text(body))
/// ```
///
pub fn html_response(html: String, status: Int) -> Response {
  let headers = [#("content-type", "text/html; charset=utf-8")]
  response.Response(status, headers, Text(html))
}

@external(javascript, "./server.ffi.mjs", "coerce")
fn coerce(a: a) -> b
