//// `FileSink` created by Bun. A Bun `FileSink` represents an in-memory buffer
//// storing data that will be periodically flushed on disk. `FileSink` are used
//// for writing large files, or for writing to a file over a long period of
//// time, in an incremental manner. A `FileSink` can easily be obtained from a
//// Bun `File`, with [`writer`](https://hexdocs.pm/brioche/brioche/file.html#writer)
//// function.
////
//// When you need to manage or read files, heads up to
//// [`brioche/file.`](https://hexdocs.pm/brioche/brioche/file.html) instead.
////
//// [Bun Documentation](https://bun.sh/docs/api/file-io#incremental-writing-with-filesink)

import brioche.{type FileSink}
import gleam/javascript/promise.{type Promise}

/// Incrementally write the text content in the file.
///
/// ```gleam
/// import brioche/file
/// import brioche/file_sink
///
/// pub fn main() {
///   let csv = file.new("/tmp/my/file.csv")
///   let writer = file.writer(csv)
///   file_sink.write_text(writer, "example data")
/// }
/// ```
@external(javascript, "./file.ffi.mjs", "writerWriteText")
pub fn write_text(sink: FileSink, data: String) -> Int

/// Incrementally write the binary content in the file.
///
/// ```gleam
/// import brioche/file
/// import brioche/file_sink
///
/// pub fn main() {
///   let csv = file.new("/tmp/my/file.csv")
///   let writer = file.writer(csv)
///   file_sink.write_bytes(writer, <<"example data">>)
/// }
/// ```
@external(javascript, "./file.ffi.mjs", "writerWriteBytes")
pub fn write_bytes(sink: FileSink, data: BitArray) -> Int

/// By default, Bun will not stop the process while a `FileSink` is opened.
/// After a call to [`unref`](#unref), the `FileSink` could be considered as
/// non-essential. `ref` restores the default behaviour.
/// Returns the same file sink to allow chaining calls if needed.
@external(javascript, "./file.ffi.mjs", "ref")
pub fn ref(sink: FileSink) -> FileSink

/// By default, Bun will not stop the process while a `FileSink` is opened.
/// `unref` changes that behaviour, and considers `FileSink` as non-essential.
/// [`ref`](#ref) restores the default behaviour.
/// Returns the same file sink to allow chaining calls if needed.
@external(javascript, "./file.ffi.mjs", "unref")
pub fn unref(sink: FileSink) -> FileSink

/// Flushes the buffer content on disk.
///
/// ```gleam
/// import brioche/file
/// import brioche/file_sink
/// import gleam/javascript/promise
///
/// pub fn main() {
///   let csv = file.new("/tmp/my/file.csv")
///   let writer = file.writer(csv)
///   file_sink.write_bytes(writer, <<"example data">>)
///   use _ <- promise.await(file_sink.flush(writer))
///   promise.resolve(Nil)
/// }
/// ```
@external(javascript, "./file.ffi.mjs", "flush")
pub fn flush(sink: FileSink) -> Promise(Result(Int, Nil))

/// Closes the `FileSink`, and let the process stops if needed.
///
/// ```gleam
/// import brioche/file
/// import brioche/file_sink
/// import gleam/javascript/promise
///
/// pub fn main() {
///   let csv = file.new("/tmp/my/file.csv")
///   let writer = file.writer(csv)
///   file_sink.write_bytes(writer, <<"example data">>)
///   use _ <- promise.await(file_sink.end(writer))
///   promise.resolve(Nil)
/// }
/// ```
@external(javascript, "./file.ffi.mjs", "writerEnd")
pub fn end(sink: FileSink) -> Promise(Result(Int, Nil))
