import brioche
import brioche/internals/exception
import brioche/server as bun
import brioche/websocket
import gleam/javascript/promise.{await, resolve}
import gleam/option
import gleam/uri
import gleeunit/should
import utils/websocket as ws

const txt_message = "test string message"

const bytes_message = <<"test bytes message">>

const example_topic = "example-topic"

pub fn websocket_test() {
  let server =
    bun.handler(upgrade_to_ws)
    |> bun.websocket({
      websocket.init()
      |> websocket.on_open(on_server_open)
      |> websocket.on_close(on_server_close)
      |> websocket.on_text(on_server_text)
      |> websocket.on_bytes(on_server_bytes)
      |> websocket.on_drain(on_server_open)
    })
    |> bun.serve
  use <- exception.defer(cleanup: fn() { bun.stop(server, force: False) })
  let assert Ok(uri) = uri.parse("ws://localhost")
  let uri = uri.Uri(..uri, port: option.Some(bun.get_port(server)))
  let socket =
    ws.open(uri)
    |> ws.on_string(on_client_string)
    |> ws.on_bytes(on_client_bitarray)
  use _ <- await(promise.wait(100))
  let _ = ws.send(socket, txt_message)
  let _ = ws.send_bytes(socket, bytes_message)
  use _ <- await(promise.wait(1000))
  ws.close(socket)
  resolve(Nil)
}

pub fn subscribe_websocket_test() {
  let server =
    bun.handler(upgrade_to_ws)
    |> bun.websocket({
      websocket.init()
      |> websocket.publish_to_self(True)
      |> websocket.on_open(on_subscribe_open)
      |> websocket.on_close(on_server_close)
      |> websocket.on_text(on_server_text)
      |> websocket.on_bytes(on_server_bytes)
      |> websocket.on_drain(on_server_open)
    })
    |> bun.serve
  use <- exception.defer(cleanup: fn() { bun.stop(server, force: False) })
  let assert Ok(uri) = uri.parse("ws://localhost")
  let uri = uri.Uri(..uri, port: option.Some(bun.get_port(server)))
  let socket =
    ws.open(uri)
    |> ws.on_string(on_client_string)
    |> ws.on_bytes(on_client_bitarray)
  use _ <- await(promise.wait(100))
  bun.subscriber_count(server, example_topic) |> should.equal(1)
  bun.publish(server, example_topic, txt_message) |> is_message_sent
  bun.publish_bytes(server, example_topic, bytes_message) |> is_message_sent
  let _ = ws.send(socket, txt_message)
  let _ = ws.send_bytes(socket, bytes_message)
  resolve(Nil)
}

fn upgrade_to_ws(req: bun.Request, server: brioche.Server(String)) {
  let headers = []
  // Upgrading should work, and WebSocket should open.
  use <- bun.upgrade(server, req, headers, txt_message)
  // Upgrading failed, should fail test.
  should.fail()
  // Resolving to make the return type happy.
  resolve(bun.ok())
}

fn on_server_open(ws: brioche.WebSocket(a)) {
  ws.is_websocket(ws) |> should.be_true
  resolve(Nil)
}

fn on_subscribe_open(ws: brioche.WebSocket(String)) {
  ws.is_websocket(ws) |> should.be_true
  websocket.subscribe(ws, example_topic)
  websocket.is_subscribed(ws, example_topic) |> should.be_true
  use _ <- await(promise.wait(200))
  websocket.publish(ws, example_topic, txt_message) |> is_message_sent
  websocket.publish_bytes(ws, example_topic, bytes_message) |> is_message_sent
  use _ <- await(promise.wait(200))
  websocket.unsubscribe(ws, example_topic)
  websocket.is_subscribed(ws, example_topic) |> should.be_false
  websocket.remote_address(ws) |> should.equal("::1")
  websocket.ready_state(ws) |> should.equal(1)
  websocket.data(ws) |> should.equal(txt_message)
  resolve(Nil)
}

fn on_server_close(ws: brioche.WebSocket(a), code: Int, reason: String) {
  ws.is_websocket(ws) |> should.be_true
  code |> should.equal(1000)
  reason |> should.equal("")
  resolve(Nil)
}

fn on_server_text(ws: brioche.WebSocket(a), text: String) {
  ws.is_websocket(ws) |> should.be_true
  text |> should.equal(txt_message)
  websocket.send(ws, text) |> is_message_sent
  resolve(Nil)
}

fn on_server_bytes(ws: brioche.WebSocket(a), bytes: BitArray) {
  ws.is_websocket(ws) |> should.be_true
  bytes |> should.equal(bytes_message)
  websocket.send_bytes(ws, bytes) |> is_message_sent
  resolve(Nil)
}

fn on_client_string(message: String) {
  message |> should.equal(txt_message)
}

fn on_client_bitarray(message: BitArray) {
  message |> should.equal(bytes_message)
}

fn is_message_sent(status: websocket.WebSocketSendStatus) -> Nil {
  case status {
    websocket.MessageSent(_) -> Nil
    _ -> should.fail()
  }
}
