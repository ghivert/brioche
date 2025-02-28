//// `brioche` exposes common, shared types across the entirety of Bun, and
//// provides an opinionated set of bindings on default Bun namespace.
//// Every functions not implemented have already their equivalent in the Gleam
//// world, and they should be privileged when using them is needed.
////
//// ## Unimplemented bindings
////
//// - [`Bun.env`](https://bun.sh/docs/api/utils#bun-env), use
////   [`envoy`](https://hexdocs.pm/envoy/) instead.
//// - [`Bun.sleep`](https://bun.sh/docs/api/utils#bun-sleep), use
////   `gleam/javascript/promise.sleep` instead.
//// - [`Bun.deepEquals`](https://bun.sh/docs/api/utils#bun-deepequals), use
////   default equality operator in Gleam. Equality in Gleam is already resolved
////   as deep equality.
//// - [`Bun.escapeHTML`](https://bun.sh/docs/api/utils#bun-escapehtml) will not
////   be implemented, as solutions like `lustre` or `nakai` already
////   generate correct, escaped HTML. While `Bun.escapeHTML` is made to be
////   especially fast, it's the responsibility of the framework to detect Bun
////   environment and calling it. When `Bun.escapeHTML` is really needed,
////   writing a function as FFI is the way-to-go.
//// - [`Bun.fileURLToPath`](https://bun.sh/docs/api/utils#bun-fileurltopath)
////   will not be implemented, as solutions like this already exists in Gleam.
////   Otherwise, they should be implemented directly on `gleam/uri`.
//// - [`Bun.pathToFileURL`](https://bun.sh/docs/api/utils#bun-pathtofileurl)
////   will not be implemented, as solutions like this already exists in Gleam.
////   Otherwise, they should be implemented directly on `gleam/uri`.
//// - [`Bun.resolveSync`](https://bun.sh/docs/api/utils#bun-resolvesync) will
////   not be implemented.
//// - [`Bun.readableStreamTo*`](https://bun.sh/docs/api/utils#bun-readablestreamto)
////   is looking for help to find the correct API to implement.
//// - [`serialize` & `deserialize` in `bun:jsc`](https://bun.sh/docs/api/utils#serialize-deserialize-in-bun-jsc)
////   will not be implemented. Using native Gleam ways to [serialize](https://hexdocs.pm/gleam_json) &
////   [deserialize](https://hexdocs.pm/gleam_stdlib/gleam/dynamic/decode.html)
////   data should be used instead.
//// - [`estimateShallowMemoryUsageOf` in `bun:jsc`](https://bun.sh/docs/api/utils#estimateshallowmemoryusageof-in-bun-jsc)
////   will not be implemented.

import gleam/javascript/promise.{type Promise}

/// Server created by Bun. Bun implements efficient, high-performance HTTP
/// servers with a clean & simple API, able to serve static routes, dynamic
/// routes and WebSockets, all-in-one. Bun servers are the recommended way to
/// create HTTP & WebSocket servers, but Bun is also fully compatible with
/// [`node:http`](https://nodejs.org/api/http.html)
/// & [`node:https`](https://nodejs.org/api/https.html) for compatibility
/// purposes.
///
/// Parametric type represents the data passed to a WebSocket connection when
/// created. Servers can be created using `server.serve` in `brioche/server`
/// module.
///
/// [Bun Documentation](https://bun.sh/docs/api/http#bun-serve)
pub type Server(context)

/// WebSocket created by Bun. Bun implements natively WebSockets when using Bun
/// `Server`. Every connection can easily be [upgraded](https://developer.mozilla.org/en-US/docs/Web/HTTP/Protocol_upgrade_mechanism)
/// to a WebSocket connection by using `server.upgrade`. Once a connection has
/// been upgraded, Bun automatically handles the WebSocket lifecycle.
///
/// [Bun Documentation](https://bun.sh/docs/api/websockets)
pub type WebSocket(context)

/// `File` created by Bun. A Bun `File` represents a lazily-loaded file;
/// initializing it does not actually read the file from disk. `File` should be
/// used in conjuction with `brioche/file` module. Bun `File` is the recommended
/// way to manipulate files on Bun as operations on files are heavily optimised.
/// However, Bun does not implements every filesystem operations, but instead,
/// provides an almost complete implementation of
/// [`node:fs`](https://nodejs.org/api/fs.html) module. It should be used for
/// every complex operations needed on filesystem.
///
/// [`FileSink`](#FileSink) should be used instead of `File` when incremental
/// writing are needed.
///
/// [Bun Documentation](https://bun.sh/docs/api/file-io#reading-files-bun-file)
pub type File

/// Native incremental file writing on `File`. Incremental writing on files
/// with regular API can be extremely inefficient due to how file writing is
/// handled with regular `File`. `FileSink` provides a highly-optimized,
/// efficient API to write in a `File` in a buffered way: instead of writing its
/// content immediately to the file when a write operation is required,
/// `FileSink` works by buffering the content, and writing the content after
/// buffer reach a reasonable size. As such, every write operations on `FileSink`
/// are synchronous, and can easily be used in synchronous code.
///
/// `FileSink` can be obtained with `file.writer` from a file.
///
/// [Bun Documentation](https://bun.sh/docs/api/file-io#incremental-writing-with-filesink)
pub type FileSink

/// A string containing the version of the `bun` CLI that is currently running.
///
/// ```gleam
/// import brioche
/// brioche.version()
/// // => "1.2.4"
/// ```
///
/// [Bun Documentation](https://bun.sh/docs/api/utils#bun-version)
@external(javascript, "./brioche.ffi.mjs", "version")
pub fn version() -> String

/// The git commit of [Bun](https://github.com/oven-sh/bun) that was compiled
/// to create the current `bun` CLI.
///
/// ```gleam
/// import brioche
/// brioche.revision()
/// // => "fd9a5ea668e9ffce5fd5f25a7cfd2d45f0eaa85b"
/// ```
///
/// [Bun Documentation](https://bun.sh/docs/api/utils#bun-revision)
@external(javascript, "./brioche.ffi.mjs", "revision")
pub fn revision() -> String

/// An absolute path to the entrypoint of the current program (the file that
/// was executed with `bun run` or `gleam run` when using `runtime = "bun" in
/// `gleam.toml`).
///
/// While probably not particularly useful on Gleam, it can be used to determine
/// if you're running a script, your main file, etc.
///
/// ```gleam
/// import brioche
/// brioche.main_script()
/// // => /path/to/script.mjs
/// ```
///
/// [Bun Documentation](https://bun.sh/docs/api/utils#bun-main)
@external(javascript, "./brioche.ffi.mjs", "mainScript")
pub fn main_script() -> String

/// A blocking, synchronous version of `gleam/javascript/promise.sleep`.
/// `promise.sleep` should almost always be used instead of `sleep`. However,
/// that function can be used in scripts, in WebWorkers, or every other
/// environment where blocking the main thread is not an issue.
///
/// Sleep duration should be indicated in milliseconds.
///
/// ```gleam
/// import brioche
/// // Sleep for 1 second.
/// brioche.sleep(1000)
/// ```
///
/// [Bun Documentation](https://bun.sh/docs/api/utils#bun-sleepsync)
@external(javascript, "./brioche.ffi.mjs", "sleepSync")
pub fn sleep(milliseconds ms: Int) -> Nil

/// Returns the path to an executable, similar to typing `which` in your terminal.
///
/// ```gleam
/// import brioche
/// brioche.which("ls")
/// // => "/usr/bin/ls"
/// ```
///
/// [Bun Documentation](https://bun.sh/docs/api/utils#bun-which)
@external(javascript, "./brioche.ffi.mjs", "which")
pub fn which(bin: String) -> Result(String, Nil)

/// Generates a random [UUID v7](https://www.ietf.org/archive/id/draft-peabody-dispatch-new-uuid-format-01.html#name-uuidv7-layout-and-bit-order),
/// which is monotonic and suitable for sorting and databases.
/// A UUID v7 is a 128-bit value that encodes the current timestamp, a random
/// value, a counter & 8 bytes of cryptographically secure random value.
/// The timestamp is encoded using the lowest 48 bits, and the random value and
/// counter are encoded using the remaining bits.
///
/// ```gleam
/// import brioche
/// brioche.random_uuid_v7()
/// // => "0192ce11-26d5-7dc3-9305-1426de888c5a"
/// ```
///
/// [Bun Documentation](https://bun.sh/docs/api/utils#bun-randomuuidv7)
@external(javascript, "./brioche.ffi.mjs", "randomUUIDV7")
pub fn random_uuid_v7() -> String

/// Reads a Promise result without `gleam/javascript/promise.await`, but only
/// if the promise has already fulfilled. In any other case, `peek` will
/// return an error.
///
/// > `peek` is important when attempting to reduce number of extraneous
/// > microticks in performance-sensitive code. It's an advanced API and you
/// > probably shouldn't use it unless you know what you're doing. Always prefer
/// > using `gleam/javascript/promise.await`.
///
/// ```gleam
/// import brioche
/// import gleam/javascript/promise
///
/// let prom = promise.resolve("example")
/// let assert Ok(peeked) = brioche.peek(prom)
/// prom == peeked
/// // => True
/// ```
///
/// [Bun Documentation](https://bun.sh/docs/api/utils#bun-peek)
@external(javascript, "./brioche.ffi.mjs", "peek")
pub fn peek(promise: Promise(a)) -> Result(a, Nil)

/// Status of a Promise. A Promise can be either fulfilled (i.e. resolved),
/// pending or rejected.
pub type PromiseStatus {
  Fulfilled
  Pending
  Rejected
}

/// Reads a Promise status without resolving it.
///
/// > `peek_status` is an advanced API and you probably shouldn't use it unless
/// > you know whate you're doing. Always prefer using classical control-flow
/// > algorithm.
///
/// ```gleam
/// import bun
/// import gleam/javascript/promise
///
/// let prom = promise.resolve("example")
/// let status = bun.peek_status(prom)
/// // => Fulfilled
/// ```
///
/// [Bun Documentation](https://bun.sh/docs/api/utils#bun-peek)
@external(javascript, "./brioche.ffi.mjs", "peekStatus")
pub fn peek_status(promise: Promise(a)) -> PromiseStatus

/// Opens a file in the default OS editor. Bun auto-detects the editor via the
/// `$VISUAL` or `$EDITOR` environment variables.
///
/// [Bun Documentation](https://bun.sh/docs/api/utils#bun-openineditor)
@external(javascript, "./brioche.ffi.mjs", "openInEditor")
pub fn open_in_editor(file: String) -> Nil

/// Compute the width of a string, in a highly efficient way.
/// Contrarily to `string.length`, that utility can be used when there's some
/// performance issue. `string.length` should be used in a first intention
/// unless you're sure to target only Bun.
///
/// [Bun Documentation](https://bun.sh/docs/api/utils#bun-stringwidth-6-756x-faster-string-width-alternative)
@external(javascript, "./brioche.ffi.mjs", "stringWidth")
pub fn string_width(string: String) -> Int

/// Compresses a `BitArray` using zlib's GZIP algorithm.
///
/// ```gleam
/// import brioche
/// brioche.gzip(<<"content">>)
/// // => Ok(<<31, 139, 8, 0, 0, 0, 0, 0, 0, 19, 75, 206, 207, 43, 73, 205, 43, 1, 0, 169, 48, 197, 254, 7, 0, 0, 0>>)
/// ```
///
/// [Bun Documentation](https://bun.sh/docs/api/utils#bun-gzipsync)
@external(javascript, "./brioche.ffi.mjs", "gzipSync")
pub fn gzip(content: BitArray) -> Result(BitArray, Nil)

/// Decompresses a `BitArray` using zlib's GUNZIP algorithm.
///
/// ```gleam
/// import brioche
/// brioche.gunzip(<<31, 139, 8, 0, 0, 0, 0, 0, 0, 19, 75, 206, 207, 43, 73, 205, 43, 1, 0, 169, 48, 197, 254, 7, 0, 0, 0>>)
/// // => Ok(<<"content">>)
/// ```
///
/// [Bun Documentation](https://bun.sh/docs/api/utils#bun-gunzipsync)
@external(javascript, "./brioche.ffi.mjs", "gunzipSync")
pub fn gunzip(content: BitArray) -> Result(BitArray, Nil)

/// Compresses a `BitArray` using zlib's DEFLATE algorithm.
///
/// ```gleam
/// import brioche
/// brioche.deflate(<<"content">>)
/// // => Ok(<<75, 206, 207, 43, 73, 205, 43, 1, 0>>)
/// ```
///
/// [Bun Documentation](https://bun.sh/docs/api/utils#bun-deflatesync)
@external(javascript, "./brioche.ffi.mjs", "deflateSync")
pub fn deflate(content: BitArray) -> Result(BitArray, Nil)

/// Decompresses a `BitArray` using zlib's DEFLATE algorithm.
///
/// ```gleam
/// import brioche
/// brioche.inflate(<<75, 206, 207, 43, 73, 205, 43, 1, 0>>)
/// // => Ok(<<"content">>)
/// ```
///
/// [Bun Documentation](https://bun.sh/docs/api/utils#bun-inflatesync)
@external(javascript, "./brioche.ffi.mjs", "inflateSync")
pub fn inflate(content: BitArray) -> Result(BitArray, nil)

/// Inspect a data structure, and return it as string. You should always use
/// `string.inspect` in first intention, unless you're sure to target Bun only.
///
/// [Bun Documentation](https://bun.sh/docs/api/utils#bun-inspect)
@external(javascript, "./brioche.ffi.mjs", "inspect")
pub fn inspect(content: a) -> String

/// Returns the current number of nanoseconds elapsed since the start of the
/// main Bun process. `nanoseconds` returns a monotonic time.
///
/// [Bun Documentation](https://bun.sh/docs/api/utils#bun-nanoseconds)
@external(javascript, "./brioche.ffi.mjs", "nanoseconds")
pub fn nanoseconds() -> Int
