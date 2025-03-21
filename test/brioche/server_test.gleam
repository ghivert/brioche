import brioche.{type Server}
import brioche/file
import brioche/internals/exception
import brioche/server.{type Request} as bun
import brioche/tls
import brioche/websocket
import gleam/bool
import gleam/dynamic/decode
import gleam/fetch
import gleam/fetch/form_data
import gleam/http
import gleam/http/request
import gleam/javascript/promise.{await}
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/uri
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

/// Test basic getters for server.
pub fn server_getters_test() {
  let ok = fn(_, _) { promise.resolve(bun.text_response("OK")) }
  let server = bun.handler(ok) |> bun.port(1234) |> bun.serve
  use <- exception.defer(cleanup: fn() { bun.stop(server, force: False) })
  bun.get_port(server) |> should.equal(1234)
  bun.get_development(server) |> should.equal(True)
  bun.get_hostname(server) |> should.equal("localhost")
  bun.get_id(server) |> should.equal("")
  bun.get_pending_requests(server) |> should.equal(0)
  bun.get_pending_websockets(server) |> should.equal(0)
  let assert Ok(uri) = uri.parse("http://localhost:1234/")
  bun.get_uri(server) |> should.equal(uri)
  promise.resolve(Nil)
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
    |> loopback(status: 200, body: "Nothing")
  })
  promise.resolve(Nil)
}

/// Request IP should respond with a correct `SocketAddress`.
/// Also test JSON response, as JSON is sent to encode `SocketAddress`.
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

/// Reload should correctly change the handler on the existing server.
pub fn reload_test() {
  use server, port <- server_utils.with_server(foo_bar)
  use _ <- await(to_local(port, "/foo") |> loopback(status: 200, body: "foo"))
  let _server = bun.reload(server, bun.handler(reject_all))
  use _ <- await(promise.wait(200))
  use _ <- await(to_local(port, "/foo") |> loopback(status: 404, body: ""))
  use _ <- await(to_local(port, "/") |> loopback(status: 200, body: "reloaded"))
  promise.resolve(Nil)
}

/// Static should return static routes.
pub fn static_test() {
  use _server, port <- server_utils.with_custom_server({
    fn(_request, _server) { promise.resolve(bun.not_found()) }
    |> bun.handler
    |> bun.static([#("/foo", bun.text_response("foo"))])
  })
  use _ <- await(to_local(port, "/foo") |> loopback(status: 200, body: "foo"))
  use _ <- await(to_local(port, "/") |> loopback(status: 404, body: ""))
  promise.resolve(Nil)
}

/// Bun File should be handled correctly.
pub fn file_test() {
  let path = "/tmp/brioche_test.json"
  use _server, port <- server_utils.with_server(fn(_request, _server) {
    let content = json.to_string(json.object([#("example", json.null())]))
    use _ <- await(file.write_text(file.new(path), content))
    promise.resolve(bun.file_response(file.new(path), 200))
  })
  to_local(port, "/")
  |> fetch.send
  |> promise.try_await(fetch.read_json_body)
  |> promise.map(should.be_ok)
  |> promise.tap(fn(content) {
    decode.at(["example"], decode.optional(decode.int))
    |> decode.run(content.body, _)
    |> should.be_ok
    |> should.equal(option.None)
  })
  |> promise.await(fn(_) { file.delete(file.new(path)) })
  |> promise.map(fn(_) { Nil })
}

/// Non-regression test, make sure no handler is modified by mistake.
pub fn handler_test() {
  let handlers = [
    #(bun.ok, 200),
    #(bun.created, 201),
    #(bun.accepted, 202),
    #(fn() { bun.redirect("") }, 303),
    #(fn() { bun.moved_permanently("") }, 308),
    #(bun.no_content, 204),
    #(bun.not_found, 404),
    #(bun.bad_request, 400),
    #(bun.entity_too_large, 413),
    #(fn() { bun.unsupported_media_type([]) }, 415),
    #(bun.unprocessable_entity, 422),
    #(bun.internal_server_error, 500),
  ]
  let loc = [#("location", "brioche")]
  bun.redirect("brioche").headers |> should.equal(loc)
  bun.moved_permanently("brioche").headers |> should.equal(loc)
  bun.unsupported_media_type(["md", "txt"]).headers
  |> should.equal([#("accept", "md, txt")])
  use #(handler, status) <- list.each(handlers)
  let response = handler()
  response.status |> should.equal(status)
  response.body |> should.equal(bun.Empty)
}

/// Non-regression test, make sure `escape_html` is not modified by mistake.
pub fn escape_html_test() {
  let input = "<html><head><title>Chou & Corp.</title></head></html>"
  let output =
    "&lt;html&gt;&lt;head&gt;&lt;title&gt;Chou &amp; Corp.&lt;/title&gt;&lt;/head&gt;&lt;/html&gt;"
  input
  |> bun.escape_html
  |> should.equal(output)
}

pub fn body_string_middleware_test() {
  let server =
    bun.handler(fn(request, _server) {
      use content <- bun.require_string_body(request)
      content |> should.equal("Hello world!")
      promise.resolve(bun.ok())
    })
    |> bun.port(0)
    |> bun.serve
  use _ <- await({
    bun.get_port(server)
    |> to_local("/")
    |> request.set_method(http.Post)
    |> request.set_body("Hello world!")
    |> fetch.send
    |> promise.tap(fn(response) {
      let response = response |> should.be_ok
      response.status |> should.equal(200)
    })
  })
  bun.stop(server, force: False)
}

pub fn body_bit_array_middleware_test() {
  let server =
    bun.handler(fn(request, _server) {
      use content <- bun.require_bit_array_body(request)
      content |> should.equal(<<"Hello world!">>)
      promise.resolve(bun.ok())
    })
    |> bun.port(0)
    |> bun.serve
  use _ <- await({
    bun.get_port(server)
    |> to_local("/")
    |> request.set_method(http.Post)
    |> request.set_body(<<"Hello world!">>)
    |> fetch.send_bits
    |> promise.tap(fn(response) {
      let response = response |> should.be_ok
      response.status |> should.equal(200)
    })
  })
  bun.stop(server, force: False)
}

pub fn body_form_data_middleware_test() {
  let server =
    bun.handler(fn(request, _server) {
      use content <- bun.require_form(request)
      content |> form_data.get("key") |> should.equal(["value"])
      promise.resolve(bun.ok())
    })
    |> bun.port(0)
    |> bun.serve
  use _ <- await({
    bun.get_port(server)
    |> to_local("/")
    |> request.set_method(http.Post)
    |> request.set_body(form_data.new() |> form_data.append("key", "value"))
    |> fetch.send_form_data
    |> promise.tap(fn(response) {
      let response = response |> should.be_ok
      response.status |> should.equal(200)
    })
  })
  bun.stop(server, force: False)
}

pub fn body_json_middleware_test() {
  let body = json.to_string(json.object([#("key", json.string("value"))]))
  let server =
    bun.handler(fn(request, _server) {
      use content <- bun.require_json(request)
      content |> Ok |> should.equal(json.parse(body, decode.dynamic))
      promise.resolve(bun.ok())
    })
    |> bun.port(0)
    |> bun.serve
  use _ <- await({
    bun.get_port(server)
    |> to_local("/")
    |> request.set_method(http.Post)
    |> request.set_body(body)
    |> fetch.send
    |> promise.tap(fn(response) {
      let response = response |> should.be_ok
      response.status |> should.equal(200)
    })
  })
  bun.stop(server, force: False)
}

pub fn body_json_failure_middleware_test() {
  let server =
    bun.handler(fn(request, _server) {
      use _content <- bun.require_json(request)
      promise.resolve(bun.ok())
    })
    |> bun.port(0)
    |> bun.serve
  use _ <- await({
    bun.get_port(server)
    |> to_local("/")
    |> request.set_method(http.Post)
    |> request.set_body("wrong json")
    |> fetch.send
    |> promise.tap(fn(response) {
      let response = response |> should.be_ok
      response.status |> should.equal(400)
    })
  })
  bun.stop(server, force: False)
}

fn foo_bar(req: Request, _server: Server(ctx)) {
  let default = fn() { promise.resolve(bun.text_response("Nothing")) }
  use <- bool.lazy_guard(when: req.method != http.Get, return: default)
  promise.resolve({
    case bun.path_segments(req) {
      ["foo"] -> bun.text_response("foo")
      ["bar"] -> bun.text_response("bar")
      _ -> bun.not_found()
    }
  })
}

fn reject_all(req: Request, _server: Server(ctx)) {
  let default = fn() { promise.resolve(bun.text_response("Nothing")) }
  use <- bool.lazy_guard(when: req.method != http.Get, return: default)
  promise.resolve({
    case bun.path_segments(req) {
      [] -> bun.text_response("reloaded")
      _ -> bun.not_found()
    }
  })
}
