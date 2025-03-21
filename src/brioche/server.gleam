//// Bun provides a native, highly performant HTTP server, that can respond to
//// classic HTTP, but also provides first-class experience for WebSockets,
//// static routes, etc.
////
//// In case you want to use an external JavaScript server, it is recommended to
//// default to `Bun.serve` API to guarantee the performance of the runtime,
//// and the ability to use any new features from Bun. However, Bun also
//// implements `node:http` and `node:https` modules, with a fast, Bun-native
//// internal implementation similar to `Bun.serve`. Feel free to use
//// them if you like.
////
//// `brioche/serve` API is heavily inspired of [`wisp`](https://hexdocs.pm/wisp)
//// to let you leverage on your current Gleam knowledge, and to integrate
//// nicely in the Gleam ecosystem! Thanks to all maintainer of `wisp`
//// for their work!
////
//// Bun is also natively compatible with [`glen`](https://hexdocs.pm/glen), as
//// `glen` only requests compatibility with native JavaScript `Request`
//// and `Response` objects — which is what Bun implements. In case you want to
//// reuse some `glen` code with Bun, you can easily plug in `glen`, and avoid
//// `brioche/serve`. Pick what is most suited to your needs!
////
//// [Bun Documentation](https://bun.sh/docs/api/http)

import brioche.{type Server}
import brioche/internals/exception
import brioche/tls
import brioche/websocket.{type WebSocketSendStatus}
import gleam/bytes_tree.{type BytesTree}
import gleam/dynamic/decode
import gleam/fetch/form_data.{type FormData}
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

/// Incoming message received by a server. Under-the-hood, `IncomingMessage`
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
  /// Bun File. Lazy loaded file will be automatically read by the runtime, and
  /// sent to the user as the response, with the correct mime type and content.
  /// If you provide an S3 File, a redirection will automatically be created
  /// with a presigned URL. Because S3 Files are lazy loaded, this avoid to
  /// download the file to your server and send it back to your users.
  File(file: brioche.File)
  /// Empty body. Used when generating a simple response, like [`ok`](#ok).
  Empty
}

/// Config used to setup a Bun's server. Default Config is created by using
/// [`server.handler`](#handler). Every server must have a handler (even
/// if a simple default "OK"), and can have a bunch of options.
///
/// > Take note of the context type. That type is used with WebSockets, to pass
/// > contextual data to every WebSocket upon initialisation.
pub type Config(context) {
  Config(
    /// Set the development mode. Defaults to `True`.
    development: Bool,
    /// Set the server handler.
    fetch: fn(Request, Server(context)) -> Promise(Response),
    /// Set the hostname to listen to. Defaults to `"0.0.0.0"`.
    hostname: Option(String),
    /// Set the default timeout for a request. Defaults to `10`.
    idle_timeout: Option(Int),
    /// Set the port to listen to. Defaults to `3000`.
    port: Option(Int),
    /// Define default static routes.
    static_routes: Option(List(#(String, Response))),
    /// Define HTTPS options.
    tls: Option(tls.Tls),
    /// Listen to a Unix socket instead of HTTP.
    unix: Option(String),
    /// Handle WebSockets connections.
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

/// Set a given header to a given value, replacing any existing value.
///
/// ```gleam
/// server.ok()
/// |> server.set_header("content-type", "application/json")
/// // -> Request(200, [#("content-type", "application/json")], Empty)
/// ```
pub const set_header = request.set_header

/// Parse the query parameters of a request into a list of key-value pairs. The
/// `key_find` function in the `gleam/list` stdlib module may be useful for
/// finding values in the list.
///
/// Query parameter names do not have to be unique and so may appear multiple
/// times in the list.
pub const get_query = request.get_query

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
/// pub fn main() -> brioche.Server(context) {
///   server.handler(handler)
///   |> server.serve
/// }
///
/// fn handler(req: Request, server: brioche.Server(context)) -> Promise(Response) {
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
/// pub fn main() -> brioche.Server(context) {
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
/// pub fn main() -> brioche.Server(context) {
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
/// pub fn main() -> brioche.Server(context) {
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
/// pub fn main() -> brioche.Server(context) {
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
/// pub fn main() -> brioche.Server(context) {
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
/// pub fn main() -> brioche.Server(context) {
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
/// pub fn main() -> brioche.Server(context) {
///   server.handler(handler)
///   |> server.tls({
///     let key = tls.File(file.new("/path/to/key/file.key"))
///     let cert = tls.File(file.new("/path/to/cert/file.cert"))
///     tls.new(key:, cert:)
///   })
/// }
/// ```
pub fn tls(options: Config(context), tls: tls.Tls) -> Config(context) {
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
/// pub fn main() -> brioche.Server(context) {
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
/// pub fn main() -> brioche.Server(context) {
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
/// pub fn main() -> brioche.Server(context) {
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
/// pub fn main() -> brioche.Server(context) {
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

/// By default, Bun will not stop the process while a `Server` is running.
/// After a call to [`unref`](#unref), the `Server` could be considered as
/// non-essential. `ref` restores the default behaviour.
/// Returns the same server to allow chaining calls if needed.
@external(javascript, "./server.ffi.mjs", "ref")
pub fn ref(server: Server(context)) -> Server(context)

/// By default, Bun will not stop the process while a `Server` is opened.
/// `unref` changes that behaviour, and considers `Server` as non-essential.
/// [`ref`](#ref) restores the default behaviour.
/// Returns the same server to allow chaining calls if needed.
@external(javascript, "./server.ffi.mjs", "unref")
pub fn unref(server: Server(context)) -> Server(context)

/// A middleware function which reads the entire body of the request as a string.
///
/// This function does not cache the body in any way, so if you call this
/// function (or any other body reading function) more than once, Bun will throw
/// an error. It is the responsibility of the caller to cache the body if it is
/// needed multiple times.
///
/// ```gleam
/// fn handle_request(request: Request) -> Promise(Response) {
///   use body <- server.require_string_body(request)
///   // ...
/// }
/// ```
pub fn require_string_body(
  request: Request,
  next: fn(String) -> Promise(Response),
) -> Promise(Response) {
  use content <- promise.await(read_request_body(request.body, "text"))
  case content {
    Ok(content) -> next(content)
    Error(_) -> promise.resolve(bad_request())
  }
}

/// A middleware function which reads the entire body of the request as a bit
/// string.
///
/// This function does not cache the body in any way, so if you call this
/// function (or any other body reading function) more than once, Bun will throw
/// an error. It is the responsibility of the caller to cache the body if it is
/// needed multiple times.
///
/// ```gleam
/// fn handle_request(request: Request) -> Promise(Response) {
///   use body <- server.require_bit_array_body(request)
///   // ...
/// }
/// ```
pub fn require_bit_array_body(
  request: Request,
  next: fn(BitArray) -> Promise(Response),
) -> Promise(Response) {
  use content <- promise.await(read_request_body(request.body, "bytes"))
  case content {
    Ok(content) -> next(content)
    Error(_) -> promise.resolve(bad_request())
  }
}

/// A middleware function which reads the entire body of the request as a
/// `FormData`. You should use functions from `gleam/fetch/form_data` to
/// manipulate that object.
///
/// In case the body cannot be read as a `FormData`, a 400: Bad Request
/// response will be sent instead.
///
/// This function does not cache the body in any way, so if you call this
/// function (or any other body reading function) more than once, Bun will throw
/// an error. It is the responsibility of the caller to cache the body if it is
/// needed multiple times.
///
/// ```gleam
/// fn handle_request(request: Request) -> Promise(Response) {
///   use body <- server.require_form(request)
///   // ...
/// }
/// ```
pub fn require_form(
  request: Request,
  next: fn(FormData) -> Promise(Response),
) -> Promise(Response) {
  use content <- promise.await(read_request_body(request.body, "form-data"))
  case content {
    Ok(content) -> next(content)
    Error(_) -> promise.resolve(bad_request())
  }
}

/// A middleware function which reads the entire body of the request as a JSON.
///
/// In case the body cannot be read as a JSON, a 400: Bad Request response will
/// be sent instead.
///
/// This function does not cache the body in any way, so if you call this
/// function (or any other body reading function) more than once, Bun will throw
/// an error. It is the responsibility of the caller to cache the body if it is
/// needed multiple times.
///
/// ```gleam
/// fn handle_request(request: Request) -> Promise(Response) {
///   use body <- server.require_json(request)
///   // ...
/// }
/// ```
pub fn require_json(
  request: Request,
  next: fn(decode.Dynamic) -> Promise(Response),
) -> Promise(Response) {
  use content <- promise.await(read_request_body(request.body, "json"))
  case content {
    Ok(content) -> next(content)
    Error(_) -> promise.resolve(bad_request())
  }
}

/// Read the entire body of the request as a bit string.
///
/// You may instead wish to use the `require_bit_array_body` or the
/// `require_string_body` middleware functions instead.
///
/// This function does not cache the body in any way, so if you call this
/// function (or any other body reading function) more than once, Bun will throw
/// an error. It is the responsibility of the caller to cache the body if it is
/// needed multiple times.
pub fn read_body_to_bitstring(
  request: Request,
) -> Promise(Result(BitArray, Nil)) {
  read_request_body(request.body, "bytes")
}

@external(javascript, "./server.ffi.mjs", "readRequestBody")
fn read_request_body(
  request: IncomingMessage,
  type_: String,
) -> Promise(Result(a, Nil))

/// Set a custom idle timeout for individual requests, or pass 0 to disable
/// the timeout for a request. Timeout is indicated in seconds.
///
/// ```gleam
/// import brioche.{type Server}
/// import brioche/server.{type Request}
///
/// pub fn main() -> brioche.Server(context) {
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
/// pub fn main() -> brioche.Server(context) {
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
///   server.internal_error()
///   |> server.text_body("Impossible to upgrade connection, internal error.")
///   |> promise.resolve
/// }
///
/// // Run your server, and let your connection come.
/// fn main() -> brioche.Server(context) {
///   server.handler(handler)
///   |> server.serve
/// }
/// ```
@external(javascript, "./server.ffi.mjs", "upgrade")
pub fn upgrade(
  server: Server(context),
  request: Request,
  headers: List(#(String, String)),
  context: context,
  next: fn() -> Promise(Response),
) -> Promise(Response)

/// Publish a string message to every WebSockets connected to a specific topic.
///
/// ```gleam
/// let server =
///   server.handler(handler)
///   |> server.websocket(websocket)
///   |> server.serve
/// server.publish(server, "my-topic", "example message")
/// // Every WebSockets that called `websocket.subscribe("my-topic")` will
/// // receive the message.
/// ```
@external(javascript, "./server.ffi.mjs", "publish")
pub fn publish(
  server: Server(context),
  topic: String,
  data: String,
) -> WebSocketSendStatus

/// Publish a bytes message to every WebSockets connected to a specific topic.
///
/// ```gleam
/// let server =
///   server.handler(handler)
///   |> server.websocket(websocket)
///   |> server.serve
/// server.publish_bytes(server, "my-topic", <<"example message">>)
/// // Every WebSockets that called `websocket.subscribe("my-topic")` will
/// // receive the message.
/// ```
@external(javascript, "./server.ffi.mjs", "publish")
pub fn publish_bytes(
  server: Server(context),
  topic: String,
  data: BitArray,
) -> WebSocketSendStatus

/// Get the current count of WebSockets subscribed to the topic.
///
/// ```gleam
/// let server =
///   server.handler(handler)
///   |> server.websocket(websocket)
///   |> server.serve
/// let count = server.subscriber_count(server)
/// // count == 0 while nobody subscribed.
/// ```
@external(javascript, "./server.ffi.mjs", "subscriberCount")
pub fn subscriber_count(server: Server(context), topic: String) -> Int

/// Get the current port the server is listening on.
///
/// ```gleam
/// let server = server.handler(handler) |> server.port(0) |> server.serve
/// let port = server.get_port(server)
/// // port is the defined port by the server.
/// ```
@external(javascript, "./server.ffi.mjs", "getPort")
pub fn get_port(server: Server(context)) -> Int

/// Get the current development mode. `True` if the server runs in development
/// mode, `False` otherwise.
///
/// ```gleam
/// let server = server.handler(handler) |> server.serve
/// let is_dev = server.get_development(server)
/// // is_dev == True
/// ```
@external(javascript, "./server.ffi.mjs", "getDevelopment")
pub fn get_development(server: Server(context)) -> Bool

/// Get the hostname the server is listening to.
///
/// ```gleam
/// let server = server.handler(handler) |> server.serve
/// let hostname = server.get_hostname(server)
/// // hostname == "0.0.0.0"
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

/// Create a text response.
///
/// The `content-type` header will be set to `text/plain`.
///
/// ```gleam
/// let body = "Hello world!"
/// text_response(body, 200)
/// // -> Response(200, [#("content-type", "text/plain")], Text(body))
/// ```
pub fn text_response(content: String) -> Response {
  let headers = [#("content-type", "text/plain")]
  response.Response(200, headers, Text(content))
}

/// Create a JSON response.
///
/// The body is expected to be valid JSON, though this is not validated.
/// The `content-type` header will be set to `application/json`.
///
/// ```gleam
/// let body = json.object([#("name", json.string("Joe")])
/// json_response(body, 200)
/// // -> Response(200, [#("content-type", "application/json")], Json(body))
/// ```
pub fn json_response(content: Json, status: Int) -> Response {
  let content = Json(content)
  let headers = [#("content-type", "text/html; charset=utf-8")]
  response.Response(status, headers, content)
}

/// Create a file response.
///
/// The `content-type` header will be set automatically accordingly to the
/// file mime type.
///
/// ```gleam
/// let body = file.new("/my/file/path")
/// file_response(body, 200)
/// // -> Response(200, [#("content-type", "application/json")], File(body))
/// ```
pub fn file_response(file: brioche.File, status: Int) -> Response {
  let content = File(file)
  response.Response(status, [], content)
}

/// Set the body of a response to a given `BitArray`.
///
/// You likely want to also set the request `content-type` header to an
/// appropriate value for the format of the content.
///
/// ```gleam
/// let body = <<"Hello, Joe!">>
/// response(201)
/// |> bytes_body(body)
/// // -> Response(201, [], Bytes(body))
/// ```
pub fn bytes_body(response: Response, content: BitArray) -> Response {
  response
  |> response.set_body(Bytes(content))
  |> response.set_header("content-type", "application/octet-stream")
}

/// Set the body of a response to a given `File`.
///
/// You likely want to also set the request `content-type` header to an
/// appropriate value for the format of the content.
///
/// ```gleam
/// let body = file.new("/path/to/file")
/// response(201)
/// |> file_body(body)
/// // -> Response(201, [], File(file.new("/path/to/file")))
/// ```
pub fn file_body(response: Response, file: brioche.File) -> Response {
  response
  |> response.set_body(File(file))
}

/// Set the body of a response to a given `BytesTree`.
///
/// You likely want to also set the request `content-type` header to an
/// appropriate value for the format of the content.
///
/// ```gleam
/// let body = bytes_tree.from_string("Hello, Joe!")
/// response(201)
/// |> bytes_tree_body(body)
/// // -> Response(201, [], Bytes(bytes_tree.to_bit_array(body)))
/// ```
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
/// ```gleam
/// let body = "<h1>Hello, Joe!</h1>"
/// response(201)
/// |> html_body(body)
/// // -> Response(201, [#("content-type", "text/html; charset=utf-8")], Text(body))
/// ```
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
/// ```gleam
/// let body = json.object([#("name", json.string("Joe"))])
/// response(201)
/// |> json_body(body)
/// // -> Response(201, [#("content-type", "application/json; charset=utf-8")], Json(body))
/// ```
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
/// ```gleam
/// let body = string_tree.from_string("Hello, Joe!")
/// response(201)
/// |> string_tree_body(body)
/// // -> Response(201, [], Text(string_tree.to_string(body)))
/// ```
pub fn string_tree_body(response: Response, content: StringTree) -> Response {
  response
  |> response.set_body(Text(string_tree.to_string(content)))
}

/// Set the body of a response to a given string.
///
/// You likely want to also set the request `content-type` header to an
/// appropriate value for the format of the content.
///
/// ```gleam
/// let body = "Hello, Joe!"
/// response(201)
/// |> string_body(body)
/// // -> Response(201, [], Text("Hello, Joe"))
/// ```
pub fn text_body(response: Response, content: String) -> Response {
  response
  |> response.set_body(Text(content))
}

/// Escape a string so that it can be safely included in a HTML document.
///
/// Any content provided by the user should be escaped before being included in
/// a HTML document to prevent cross-site scripting attacks.
///
/// `escape_html` uses `Bun.escapeHTML`, and is highly optimized for large inputs.
///
/// ```gleam
/// escape_html("<h1>Hello, Joe!</h1>")
/// // -> "&lt;h1&gt;Hello, Joe!&lt;/h1&gt;"
/// ```
@external(javascript, "./server.ffi.mjs", "escapeHTML")
pub fn escape_html(content: String) -> String

/// This middleware function ensures that the request has a value for the
/// `content-type` header, returning an empty response with status code 415:
/// Unsupported media type if the header is not the expected value
///
/// ```gleam
/// fn handle_request(request: Request) -> Response {
///   use <- wisp.require_content_type(request, "application/json")
///   // ...
/// }
/// ```
pub fn require_content_type(
  request: Request,
  expected: String,
  next: fn() -> Response,
) -> Response {
  case list.key_find(request.headers, "content-type") {
    Ok(content_type) ->
      // This header may have further such as `; charset=utf-8`, so discard
      // that if it exists.
      case string.split_once(content_type, ";") {
        Ok(#(content_type, _)) if content_type == expected -> next()
        _ if content_type == expected -> next()
        _ -> unsupported_media_type([expected])
      }

    _ -> unsupported_media_type([expected])
  }
}

/// A middleware function that rescues crashes and returns an empty response
/// with status code 500: Internal server error.
///
/// ```gleam
/// import gleam/javascript/promise.{type Promise}
///
/// fn handle_request(req: Request) -> Promise(Response) {
///   use <- server.rescue_crashes
///   // ...
/// }
/// ```
pub fn rescue_crashes(handler: fn() -> Promise(Response)) -> Promise(Response) {
  use content <- promise.map(exception.rescue(handler))
  case content {
    Ok(response) -> response
    Error(error) -> {
      exception.log(error)
      internal_server_error()
    }
  }
}

/// Create an empty response with the given status code.
///
/// ```gleam
/// response(200)
/// // -> Response(200, [], Empty)
/// ```
pub fn response(status: Int) -> Response {
  response.new(status)
  |> response.set_body(Empty)
}

/// Create an empty response with status code 200: OK.
///
/// ```gleam
/// ok()
/// // -> Response(200, [], Empty)
/// ```
pub fn ok() -> Response {
  response.Response(200, [], Empty)
}

/// Create an empty response with status code 405: Method Not Allowed. Use this
/// when a request does not have an appropriate method to be handled.
///
/// The `allow` header will be set to a comma separated list of the permitted
/// methods.
///
/// ```gleam
/// method_not_allowed(allowed: [Get, Post])
/// // -> Response(405, [#("allow", "GET, POST")], Empty)
/// ```
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
/// ```gleam
/// created()
/// // -> Response(201, [], Empty)
/// ```
pub fn created() -> Response {
  response.Response(201, [], Empty)
}

/// Create an empty response with status code 202: Accepted.
///
/// ```gleam
/// accepted()
/// // -> Response(202, [], Empty)
/// ```
pub fn accepted() -> Response {
  response.Response(202, [], Empty)
}

/// Create an empty response with status code 303: See Other, and the `location`
/// header set to the given URL. Used to redirect the client to another page.
///
/// ```gleam
/// redirect(to: "https://example.com")
/// // -> Response(303, [#("location", "https://example.com")], Empty)
/// ```
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
/// ```gleam
/// moved_permanently(to: "https://example.com")
/// // -> Response(308, [#("location", "https://example.com")], Empty)
/// ```
pub fn moved_permanently(to url: String) -> Response {
  response.Response(308, [#("location", url)], Empty)
}

/// Create an empty response with status code 204: No content.
///
/// ```gleam
/// no_content()
/// // -> Response(204, [], Empty)
/// ```
pub fn no_content() -> Response {
  response.Response(204, [], Empty)
}

/// Create an empty response with status code 404: No content.
///
/// ```gleam
/// not_found()
/// // -> Response(404, [], Empty)
/// ```
pub fn not_found() -> Response {
  response.Response(404, [], Empty)
}

/// Create an empty response with status code 400: Bad request.
///
/// ```gleam
/// bad_request()
/// // -> Response(400, [], Empty)
/// ```
pub fn bad_request() -> Response {
  response.Response(400, [], Empty)
}

/// Create an empty response with status code 413: Entity too large.
///
/// ```gleam
/// entity_too_large()
/// // -> Response(413, [], Empty)
/// ```
pub fn entity_too_large() -> Response {
  response.Response(413, [], Empty)
}

/// Create an empty response with status code 415: Unsupported media type.
///
/// The `allow` header will be set to a comma separated list of the permitted
/// content-types.
///
/// ```gleam
/// unsupported_media_type(accept: ["application/json", "text/plain"])
/// // -> Response(415, [#("allow", "application/json, text/plain")], Empty)
/// ```
pub fn unsupported_media_type(accept acceptable: List(String)) -> Response {
  let acceptable = string.join(acceptable, ", ")
  response.Response(415, [#("accept", acceptable)], Empty)
}

/// Create an empty response with status code 422: Unprocessable entity.
///
/// ```gleam
/// unprocessable_entity()
/// // -> Response(422, [], Empty)
/// ```
pub fn unprocessable_entity() -> Response {
  response.Response(422, [], Empty)
}

/// Create an empty response with status code 500: Internal server error.
///
/// ```gleam
/// internal_server_error()
/// // -> Response(500, [], Empty)
/// ```
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
/// ```gleam
/// let body = string_tree.from_string("<h1>Hello, Joe!</h1>")
/// html_response(body, 200)
/// // -> Response(200, [#("content-type", "text/html")], Text(body))
/// ```
pub fn html_response(html: String, status: Int) -> Response {
  let headers = [#("content-type", "text/html; charset=utf-8")]
  response.Response(status, headers, Text(html))
}
