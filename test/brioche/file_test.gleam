import brioche/file
import gleam/javascript/promise
import gleeunit/should

pub const example = "./test/samples/example.txt"

pub const intermediate = "./test/samples/sample.txt"

pub fn size_test() {
  use stat <- promise.tap(file.new(example) |> file.stat)
  let stat = stat |> should.be_ok
  stat.size |> should.equal(5)
}

pub fn mime_test() {
  file.new(example)
  |> file.mime_type
  |> should.equal("text/plain;charset=utf-8")
}

pub fn text_test() {
  let file = file.new(example)
  use content <- promise.tap(file.text(file))
  content
  |> should.be_ok
  |> should.equal("test\n")
}

pub fn json_test() {
  let file = file.new("./test/samples/example.json")
  use content <- promise.tap(file.json(file))
  content
  |> should.be_ok
}

pub fn bytes_test() {
  let file = file.new(example)
  use content <- promise.tap(file.bytes(file))
  content
  |> should.be_ok
  |> should.equal(<<"test\n">>)
}

pub fn string_delete_write_test() {
  let file_content = "file_content"
  let file = file.new(intermediate)
  use size <- promise.await(file.write_text(file, file_content))
  use exists <- promise.await(file.exists(file))
  exists |> should.be_ok |> should.be_true()
  use content <- promise.await(file.text(file))
  use _ <- promise.await(file.delete(file))
  size
  |> should.be_ok
  |> should.equal(12)
  content
  |> should.be_ok
  |> should.equal(file_content)
  let file = file.new(intermediate)
  use exists <- promise.map(file.exists(file))
  exists |> should.be_ok |> should.be_false()
}

pub fn failing_delete_write_test() {
  let intermediate = intermediate <> "inexistent"
  let file = file.new(intermediate)
  use exists <- promise.await(file.exists(file))
  exists |> should.be_ok |> should.be_false()
  use _ <- promise.await(file.delete(file))
  use content <- promise.map(file.text(file))
  content
  |> should.be_error
  |> should.equal(file.Enoent)
}

pub fn bitarray_delete_write_test() {
  let file_content = <<"file_content">>
  let intermediate = intermediate
  let file = file.new(intermediate)
  use size <- promise.await(file.write_bytes(file, file_content))
  use exists <- promise.await(file.exists(file))
  exists |> should.be_ok |> should.be_true()
  use content <- promise.await(file.bytes(file))
  use _ <- promise.await(file.delete(file))
  size
  |> should.be_ok
  |> should.equal(12)
  content
  |> should.be_ok
  |> should.equal(file_content)
  let file = file.new(intermediate)
  use exists <- promise.map(file.exists(file))
  exists |> should.be_ok |> should.be_false()
}

pub fn copy_test() {
  let file_content = "file_content"
  let intermediate = intermediate
  let dest = intermediate <> "txt"
  let file_dest = file.new(dest)
  let file = file.new(intermediate)
  use size <- promise.await(file.write_text(file, file_content))
  use exists <- promise.await(file.exists(file))
  exists |> should.be_ok |> should.be_true()
  use _ <- promise.await(file.copy(file, file_dest))
  use content <- promise.await(file.text(file_dest))
  use dest_exists <- promise.await(file.exists(file_dest))
  use _ <- promise.await(file.delete(file))
  use _ <- promise.await(file.delete(file_dest))
  dest_exists |> should.be_ok |> should.be_true()
  size
  |> should.be_ok
  |> should.equal(12)
  content
  |> should.be_ok
  |> should.equal(file_content)
  let file = file.new(intermediate)
  use exists <- promise.map(file.exists(file))
  exists |> should.be_ok |> should.be_false()
}
