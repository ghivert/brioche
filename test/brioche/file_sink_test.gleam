import brioche/file
import brioche/file_sink
import gleam/javascript/promise
import gleeunit/should

pub const example = "./test/samples/example_sink.txt"

pub fn write_text_test() {
  let file = file.new(example)
  let writer = file.writer(file)
  file_sink.write_text(writer, "example") |> should.equal(7)
  file_sink.write_bytes(writer, <<"example">>) |> should.equal(7)
  use content <- promise.await(file_sink.flush(writer))
  content
  |> should.be_ok
  |> should.equal(14)
  use res <- promise.await(file_sink.end(writer))
  res
  |> should.be_ok
  |> should.equal(0)
  use end <- promise.map(file.delete(file))
  end
  |> should.be_ok
  |> should.equal(Nil)
}

pub fn write_start_test() {
  let file = file.new(example)
  let writer = file.writer(file)
  file_sink.start(writer)
  |> should.equal(writer)
}

pub fn ref_test() {
  let writer = file.writer(file.new(example))
  writer
  |> file_sink.ref
  |> file_sink.ref
  |> file_sink.unref
  |> file_sink.unref
  |> file_sink.ref
  |> file_sink.unref
}
