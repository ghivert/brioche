//// `File` created by Bun. A Bun `File` represents a lazily-loaded file;
//// initializing it does not actually read the file from disk.
//// Bun `File` is the recommended way to manipulate files on Bun as operations
//// on files are heavily optimised. However, Bun does not implements every
//// filesystem operations, but instead, provides an almost complete implementation of
//// [`node:fs`](https://nodejs.org/api/fs.html) module. It should be used for
//// every complex operations needed on filesystem. Any Gleam library compatible
//// with `node:fs` will work.
////
//// [`FileSink`](#FileSink) should be used instead of `File` when incremental
//// writing are needed.
////
//// [Bun Documentation](https://bun.sh/docs/api/file-io#reading-files-bun-file)

import brioche.{type File, type FileSink}
import gleam/javascript/promise.{type Promise}

/// Create a new `File` from a path. File will not be read. Use it to initialise
/// your file manipulation pipeline.
///
/// ```gleam
/// import brioche
/// import brioche/file
///
/// pub fn main() {
///   let my_file = file.new("/tmp/my/file.txt")
/// }
/// ```
@external(javascript, "./file.ffi.mjs", "newFile")
pub fn new(path: String) -> File

/// Get the size of a file. That operation never fails, and will defaults to 0
/// if the file does not exists.
///
/// ```gleam
/// import brioche
/// import brioche/file
///
/// pub fn main() {
///   let my_file = file.new("/tmp/my/file/which/does/not/exist.txt")
///   let file_size = file.size(my_file)
///   // -> 0
/// }
/// ```
@external(javascript, "./file.ffi.mjs", "size")
pub fn size(file: File) -> Int

/// Indicates if the file exists or not. That operation never fails.
///
/// ```gleam
/// import brioche
/// import brioche/file
///
/// pub fn main() {
///   file.new("/tmp/my/file.txt")
///   |> file.exists
///   |> should.be_true
///
///   file.new("/tmp/my/file/which/does/not/exist.txt")
///   |> file.exists
///   |> should.be_false
/// }
/// ```
@external(javascript, "./file.ffi.mjs", "exists")
pub fn exists(file: File) -> Promise(Bool)

/// Returns the mime type of the file. That operation never fails.
///
/// ```gleam
/// import brioche
/// import brioche/file
///
/// pub fn main() {
///   file.new("/tmp/my/file.csv")
///   |> file.mime_type
///   |> should.equal("text/csv")
///
///   file.new("/tmp/my/file/which/does/not/exist.txt")
///   |> file.exists
///   |> should.equal("text/plain;charset=utf-8")
/// }
/// ```
@external(javascript, "./file.ffi.mjs", "mime")
pub fn mime_type(file: File) -> String

/// Reads the file as text. If the file does not exists, if you lack rights to
/// read, or if it cannot be converted to string, the operation may fail.
///
/// ```gleam
/// import brioche
/// import brioche/file
/// import gleam/javascript/promise
///
/// pub fn main() {
///   let csv = file.new("/tmp/my/file.csv")
///   let csv = file.text(csv)
///   use csv <- promise.await(csv)
///   case csv {
///     // File has not been read.
///     Error(_) -> promise.resolve(Nil)
///     // File has been read.
///     Ok(csv) -> ...
///   }
/// }
/// ```
@external(javascript, "./file.ffi.mjs", "text")
pub fn text(file: File) -> Promise(Result(String, Nil))

/// Reads the file as binary. If the file does not exists, or if you lack rights
/// to read, the operation may fail.
///
/// ```gleam
/// import brioche
/// import brioche/file
/// import gleam/javascript/promise
///
/// pub fn main() {
///   let csv = file.new("/tmp/my/file.csv")
///   let csv = file.bytes(csv)
///   use csv <- promise.await(csv)
///   case csv {
///     // File has not been read.
///     Error(_) -> promise.resolve(Nil)
///     // File has been read.
///     Ok(csv) -> ...
///   }
/// }
/// ```
@external(javascript, "./file.ffi.mjs", "bytes")
pub fn bytes(file: File) -> Promise(Result(BitArray, Nil))

/// Deletes a file. If the file does not exists, or if you lack rights to delete
/// it, the operation may fail.
///
/// ```gleam
/// import brioche
/// import brioche/file
/// import gleam/javascript/promise
///
/// pub fn main() {
///   let csv = file.new("/tmp/my/file.csv")
///   let csv = file.delete(csv)
///   use csv <- promise.await(csv)
///   case csv {
///     // File is not deleted.
///     Error(_) -> promise.resolve(Nil)
///     // File has been deleted.
///     Ok(_) -> ...
///   }
/// }
/// ```
@external(javascript, "./file.ffi.mjs", "deleteFile")
pub fn delete(file: File) -> Promise(Result(Nil, Nil))

/// Write the text content in file. If the file does not exists it will be
/// created. If you lack rights to write, the operation may fail.
///
/// ```gleam
/// import brioche
/// import brioche/file
/// import gleam/javascript/promise
///
/// pub fn main() {
///   let csv = file.new("/tmp/my/file.csv")
///   let csv = file.write_text("Hello world!")
///   use csv <- promise.await(csv)
///   case csv {
///     // File has not been written.
///     Error(_) -> promise.resolve(Nil)
///     // File has been written.
///     Ok(csv) -> ...
///   }
/// }
/// ```
@external(javascript, "./file.ffi.mjs", "write")
pub fn write_text(file: File, data: String) -> Promise(Result(Int, Nil))

/// Write the binary content in file. If the file does not exists it will be
/// created. If you lack rights to write, the operation may fail.
///
/// ```gleam
/// import brioche
/// import brioche/file
/// import gleam/javascript/promise
///
/// pub fn main() {
///   let csv = file.new("/tmp/my/file.csv")
///   let csv = file.write_binary(<<"Hello world!">>)
///   use csv <- promise.await(csv)
///   case csv {
///     // File has not been written.
///     Error(_) -> promise.resolve(Nil)
///     // File has been written.
///     Ok(csv) -> ...
///   }
/// }
/// ```
@external(javascript, "./file.ffi.mjs", "writeBytes")
pub fn write_bytes(file: File, data: BitArray) -> Promise(Result(Int, Nil))

/// Helper to copy a file to another file. Fails if you lack rights, or if the
/// original file does not exists.
///
/// ```gleam
/// import brioche
/// import brioche/file
/// import gleam/javascript/promise
///
/// pub fn main() {
///   let from = file.new("/tmp/my/file.csv")
///   let dest = file.new("/tmp/my/destination.csv")
///   use size <- promise.await(file.copy(from, to: dest))
///   case size {
///     // File has not been copied.
///     Error(_) -> promise.resolve(Nil)
///     // File has been copied.
///     Ok(size) -> ...
///   }
/// }
/// ```
@external(javascript, "./file.ffi.mjs", "copy")
pub fn copy(file: File, to to: File) -> Promise(Result(Int, Nil))

/// `FileSink` are a way to implement String builder. A String builder is a way
/// to dynamically append data to files, like in streams. Take a look at
/// [`file_sink`](https://hexdocs.pm/brioche/brioche/file.html).
///
/// ```gleam
/// import brioche
/// import brioche/file
///
/// pub fn main() {
///   let my_file = file.new("/tmp/my/file.csv")
///   let writer = file.writer(my_file)
///   ...
/// }
/// ```
@external(javascript, "./file.ffi.mjs", "writer")
pub fn writer(file: File) -> FileSink

/// Get the standard input as a Bun `File`. This allows to use standard input
/// as any file.
///
/// ```gleam
/// import brioche
/// import brioche/file
/// import gleam/javascript/promise
///
/// pub fn main() {
///   let stdin = file.stdin()
///   let read = file.read(stdin)
///   use content <- promise.await(read)
///   case content {
///     // An error happened in reading.}
///     Error(_) -> promise.resolve(Nil)
///     // Standard input has been read.
///     Ok(content) -> ...
///   }
/// }
/// ```
@external(javascript, "./file.ffi.mjs", "stdin")
pub fn stdin() -> File

/// Get the standard output as a Bun `File`. This allows to use standard output
/// as any file.
///
/// ```gleam
/// import brioche
/// import brioche/file
/// import gleam/javascript/promise
///
/// pub fn main() {
///   let stdin = file.stdout()
///   let written = file.write_text(stdin, "Example")
///   use content <- promise.await(written)
///   case content {
///     // Content has not been written to standard output.
///     Error(_) -> promise.resolve(Nil)
///     // Content has been written to standard output.
///     Ok(content) -> ...
///   }
/// }
/// ```
@external(javascript, "./file.ffi.mjs", "stdout")
pub fn stdout() -> File

/// Get the standard error as a Bun `File`. This allows to use standard error
/// as any file.
///
/// ```gleam
/// import brioche
/// import brioche/file
/// import gleam/javascript/promise
///
/// pub fn main() {
///   let stdin = file.stdout()
///   let written = file.write_text(stdin, "Example")
///   use content <- promise.await(written)
///   case content {
///     // Content has not been written to standard error.
///     Error(_) -> promise.resolve(Nil)
///     // Content has been written to standard error.
///     Ok(content) -> ...
///   }
/// }
/// ```
@external(javascript, "./file.ffi.mjs", "stderr")
pub fn stderr() -> File
