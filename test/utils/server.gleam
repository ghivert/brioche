import brioche.{type Server}
import brioche/server.{type Request, type Response}
import gleam/bool
import gleam/fetch
import gleam/http/request
import gleam/int
import gleam/javascript/promise.{type Promise}
import gleeunit/should

pub fn with_server(
  handler: fn(Request, Server(ctx)) -> Promise(Response),
  next: fn(Server(ctx), Int) -> Promise(Nil),
) -> Promise(Nil) {
  let server = server.handler(handler) |> server.port(0) |> server.serve
  let port = server.get_port(server)
  use <- defer(cleanup: _, body: fn() { next(server, port) })
  server.stop(server, force: False)
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

@external(javascript, "./server.ffi.mjs", "log")
pub fn log(value: a) -> Nil

@external(javascript, "./server.ffi.mjs", "defer")
fn defer(
  cleanup cleanup: fn() -> a,
  body body: fn() -> Promise(b),
) -> Promise(b)
