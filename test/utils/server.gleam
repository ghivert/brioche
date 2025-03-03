import brioche.{type Server}
import brioche/server.{type Request, type Response} as bun
import gleam/bool
import gleam/dynamic/decode
import gleam/fetch
import gleam/http/request
import gleam/int
import gleam/javascript/promise.{type Promise}
import gleam/json
import gleam/option
import gleeunit/should

pub fn with_server(
  handler: fn(Request, Server(ctx)) -> Promise(Response),
  next: fn(Server(ctx), Int) -> Promise(Nil),
) -> Promise(Nil) {
  let server = bun.handler(handler) |> bun.port(0) |> bun.serve
  let port = bun.get_port(server)
  use <- defer(cleanup: _, body: fn() { next(server, port) })
  bun.stop(server, force: False)
}

pub fn with_custom_server(
  config: bun.Config(ctx),
  next: fn(Server(ctx), Int) -> Promise(Nil),
) -> Promise(Nil) {
  let server = bun.serve(config)
  let port = bun.get_port(server)
  use <- defer(cleanup: _, body: fn() { next(server, port) })
  bun.stop(server, force: False)
}

pub fn to_local(port: Int, path: String) -> request.Request(String) {
  let port = int.to_string(port)
  let to = "http://localhost:" <> port <> path
  let assert Ok(request) = request.to(to)
  request
}

pub fn loopback(
  request: request.Request(String),
  status status: Int,
  body body: String,
) -> Promise(Nil) {
  fetch.send(request)
  |> promise.try_await(fetch.read_text_body)
  |> promise.map(fn(res) {
    case res {
      Error(_) -> should.fail()
      Ok(res) -> {
        use <- bool.lazy_guard(when: res.status != status, return: should.fail)
        use <- bool.lazy_guard(when: res.body != body, return: should.fail)
        Nil
      }
    }
  })
}

pub fn request_ip(request: Request, server: Server(ctx)) {
  let address = bun.request_ip(server, request)
  case address {
    option.None -> promise.resolve(bun.not_found())
    option.Some(address) ->
      address
      |> encode_socket_address
      |> bun.json_response
      |> promise.resolve
  }
}

pub fn timeout(request: Request, server: Server(ctx)) {
  bun.timeout(server, request, 1)
  use _ <- promise.await(promise.wait(5000))
  promise.resolve(bun.not_found())
}

pub fn encode_socket_address(address: bun.SocketAddress) {
  json.object([
    #("address", json.string(address.address)),
    #("port", json.int(address.port)),
    #("family", case address.family {
      bun.IPv4 -> json.string("ipv4")
      bun.IPv6 -> json.string("ipv6")
    }),
  ])
}

pub fn socket_address_decoder() {
  use address <- decode.field("address", decode.string)
  use port <- decode.field("port", decode.int)
  use family <- decode.field("family", {
    use family <- decode.then(decode.string)
    case family {
      "ipv4" -> decode.success(bun.IPv4)
      "ipv6" -> decode.success(bun.IPv6)
      _ -> decode.failure(bun.IPv4, "Family")
    }
  })
  decode.success(bun.SocketAddress(address:, port:, family:))
}

@external(javascript, "./server.ffi.mjs", "log")
pub fn log(value: a) -> Nil

@external(javascript, "./server.ffi.mjs", "coerce")
pub fn coerce(a: a) -> b

@external(javascript, "./server.ffi.mjs", "defer")
fn defer(
  cleanup cleanup: fn() -> a,
  body body: fn() -> Promise(b),
) -> Promise(b)
