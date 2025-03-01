import brioche.{type Server}
import brioche/file
import brioche/server.{type Request}
import brioche/tls
import brioche/websocket
import gleam/bool
import gleam/fetch
import gleam/http/request
import gleam/http/response
import gleam/int
import gleam/io
import gleam/javascript/promise.{await}
import gleeunit/should
import utils/server.{request_text} as server_utils

/// Modification of this test implies at least a minor upgrade when adding new
/// functions, and probably a breaking change and a major release when modifying
/// existing functions. Adding new features is possible, but avoid modifying
/// this test as possible. Guaranteeing stability of the API across versions
/// is essential, and while useless per se, that test acts as a way to take
/// consciouness of a deep API modification.
pub fn config_stability_test() {
  server.handler(fn(_, _) { promise.resolve(server.text_response("")) })
  |> server.port(3000)
  |> server.hostname("localhost")
  |> server.development(True)
  |> server.static([#("/static", server.text_response("Static"))])
  |> server.unix("/tpm/socket.sock")
  |> server.idle_timeout(after: 30)
  |> server.tls({
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
  |> server.websocket({
    websocket.init()
    |> websocket.on_open(fn(_socket) { promise.resolve(Nil) })
    |> websocket.on_drain(fn(_socket) { promise.resolve(Nil) })
    |> websocket.on_close(fn(_socket, _code, _reason) { promise.resolve(Nil) })
    |> websocket.on_text(fn(_socket, _text) { promise.resolve(Nil) })
    |> websocket.on_bytes(fn(_socket, _bytes) { promise.resolve(Nil) })
  })
}

pub fn simple_response_test() {
  let ok = fn(_, _) { promise.resolve(server.text_response("OK")) }
  use _server, port <- server_utils.with_server(ok)
  use _ <- await(request_text(port:, path: "/", status: 200, body: "OK"))
  promise.resolve(Nil)
}

pub fn routed_response_test() {
  use _server, port <- server_utils.with_server(foo_bar)
  use _ <- await(request_text(port:, path: "/foo", status: 200, body: "foo"))
  use _ <- await(request_text(port:, path: "/bar", status: 200, body: "bar"))
  use _ <- await(request_text(port:, path: "/", status: 404, body: ""))
  use _ <- await(request_text(port:, path: "/any", status: 404, body: ""))
  promise.resolve(Nil)
}

fn foo_bar(req: Request, server: Server(ctx)) {
  promise.resolve({
    case server.path_segments(req) {
      ["foo"] -> server.text_response("foo")
      ["bar"] -> server.text_response("bar")
      _ -> server.not_found()
    }
  })
}
