import brioche.{type Server}
import brioche/file
import brioche/server.{type Request} as bun
import brioche/tls
import brioche/websocket
import gleam/bool
import gleam/dynamic/decode
import gleam/fetch
import gleam/http
import gleam/http/request
import gleam/javascript/promise.{await}
import gleam/result
import gleeunit/should
import utils/server.{loopback, to_local} as server_utils

/// Modification of this test implies at least a minor upgrade when adding new
/// functions, and probably a breaking change and a major release when modifying
/// existing functions. Adding new features is possible, but avoid modifying
/// this test as possible. Guaranteeing stability of the API across versions
/// is essential, and while useless per se, that test acts as a way to take
/// consciouness of a deep API modification.
pub fn config_stability_test() {
  bun.handler(fn(_, _) { promise.resolve(bun.text_response("")) })
  |> bun.port(3000)
  |> bun.hostname("localhost")
  |> bun.development(True)
  |> bun.static([#("/static", bun.text_response("Static"))])
  |> bun.unix("/tpm/socket.sock")
  |> bun.idle_timeout(after: 30)
  |> bun.tls({
    let key = tls.File(file.new("/example.key"))
    let cert = tls.File(file.new("/example.cert"))
    let ca = tls.File(file.new("/example.ca"))
    tls.new(key:, cert:)
    |> tls.passphrase("passphrase")
    |> tls.server_name("example.com")
    |> tls.reject_unauthorized(True)
    |> tls.request_cert(True)
    |> tls.ca(ca)
    |> tls.dh_params_file("params")
  })
  |> bun.websocket({
    websocket.init()
    |> websocket.on_open(fn(_socket) { promise.resolve(Nil) })
    |> websocket.on_drain(fn(_socket) { promise.resolve(Nil) })
    |> websocket.on_close(fn(_socket, _code, _reason) { promise.resolve(Nil) })
    |> websocket.on_text(fn(_socket, _text) { promise.resolve(Nil) })
    |> websocket.on_bytes(fn(_socket, _bytes) { promise.resolve(Nil) })
  })
}

/// Simple response should respond when provided a simple loopback.
pub fn simple_response_test() {
  let ok = fn(_, _) { promise.resolve(bun.text_response("OK")) }
  use _server, port <- server_utils.with_server(ok)
  use _ <- await(to_local(port, "/") |> loopback(status: 200, body: "OK"))
  promise.resolve(Nil)
}

/// Routed response uses a more complicated handler to check routing, correct
/// method handling and path handling.
pub fn routed_response_test() {
  use _server, port <- server_utils.with_server(foo_bar)
  use _ <- await(to_local(port, "/foo") |> loopback(status: 200, body: "foo"))
  use _ <- await(to_local(port, "/bar") |> loopback(status: 200, body: "bar"))
  use _ <- await(to_local(port, "/") |> loopback(status: 404, body: ""))
  use _ <- await(to_local(port, "/any") |> loopback(status: 404, body: ""))
  use _ <- await({
    to_local(port, "/")
    |> request.set_method(http.Post)
    |> loopback(status: 200, body: "Not get")
  })
  promise.resolve(Nil)
}

/// Request IP should respond with a correct `SocketAddress`.
pub fn request_ip_test() {
  use _server, port <- server_utils.with_server(server_utils.request_ip)
  to_local(port, "/")
  |> fetch.send
  |> promise.try_await(fetch.read_json_body)
  |> promise.tap(fn(content) {
    case content {
      Error(_) -> should.fail()
      Ok(res) -> {
        res.body
        |> decode.run(server_utils.socket_address_decoder())
        |> result.map_error(fn(_) { should.fail() })
        |> result.replace(Nil)
        |> result.unwrap_both
        Nil
      }
    }
  })
  |> promise.map(fn(_) { Nil })
}

/// Request IP should respond with a correct `SocketAddress`.
pub fn timeout_test() {
  use _server, port <- server_utils.with_server(server_utils.timeout)
  to_local(port, "/")
  |> fetch.send
  |> promise.tap(should.be_error)
  |> promise.map(fn(_) { Nil })
}

fn foo_bar(req: Request, _server: Server(ctx)) {
  let default = fn() { promise.resolve(bun.text_response("Not get")) }
  use <- bool.lazy_guard(when: req.method != http.Get, return: default)
  promise.resolve(handle_get(req))
}

fn handle_get(req: Request) {
  case bun.path_segments(req) {
    ["foo"] -> bun.text_response("foo")
    ["bar"] -> bun.text_response("bar")
    _ -> bun.not_found()
  }
}
