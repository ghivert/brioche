import gleam/javascript/promise.{type Promise}

pub type Server(context)

pub type File

pub type FileSink

pub type WebSocket(context)

/// Returns the version of the current Bun runtime.
@external(javascript, "./brioche.ffi.mjs", "version")
pub fn version() -> String

/// Returns the revision used to build the current Bun runtime.
@external(javascript, "./brioche.ffi.mjs", "revision")
pub fn revision() -> String

/// Returns the main script file.
@external(javascript, "./brioche.ffi.mjs", "mainScript")
pub fn main_script() -> String

/// Synchronized sleep. Be careful, calling that function will freeze the
/// thread. Use `promise.sleep` instead if possible.
@external(javascript, "./brioche.ffi.mjs", "sleepSync")
pub fn sleep(ms: Int) -> Nil

/// Returns the path to an executable.
@external(javascript, "./brioche.ffi.mjs", "which")
pub fn which(bin: String) -> Result(String, Nil)

/// Generates a random UUID v7, which is monotonic and suitable for sorting
/// and databases.
///
/// ```gleam
/// import bun
///
/// let id = bun.random_uuid_v7()
/// // "0192ce11-26d5-7dc3-9305-1426de888c5a"
/// ```
@external(javascript, "./brioche.ffi.mjs", "randomUUIDV7")
pub fn random_uuid_v7() -> String

/// Reads a Promise result without `await`, but only if the promise  has
/// already fulfilled. In any other case, `peek` will return an error.
///
/// ```gleam
/// import bun
/// import gleam/javascript/promise
///
/// let prom = promise.resolve("example")
/// let assert Ok(peeked) = bun.peek(prom)
/// prom == peeked
/// // => True
@external(javascript, "./brioche.ffi.mjs", "peek")
pub fn peek(promise: Promise(a)) -> Result(a, Nil)

pub type PromiseStatus {
  Fulfilled
  Pending
  Rejected
}

/// Reads a Promise status.
///
/// ```gleam
/// import bun
/// import gleam/javascript/promise
///
/// let prom = promise.resolve("example")
/// let status = bun.peek_status(prom)
/// // => Fulfilled
@external(javascript, "./brioche.ffi.mjs", "peekStatus")
pub fn peek_status(promise: Promise(a)) -> PromiseStatus

/// Open a file in your default editor.
@external(javascript, "./brioche.ffi.mjs", "openInEditor")
pub fn open_in_editor(file: String) -> Nil

/// Compute the width of a string, in a highly efficient way.
/// Contrarily to `string.length`, that utility can be used when there's some
/// performance issue. `string.length` should be used in a first intention
/// unless you're sure to target only Bun.
@external(javascript, "./brioche.ffi.mjs", "stringWidth")
pub fn string_width(string: String) -> Int

/// Gzip a BitArray in a synchronous way.
@external(javascript, "./brioche.ffi.mjs", "gzipSync")
pub fn gzip(content: BitArray) -> Result(BitArray, Nil)

/// Gunzip a BitArray in a synchronous way.
@external(javascript, "./brioche.ffi.mjs", "gunzipSync")
pub fn gunzip(content: BitArray) -> Result(BitArray, Nil)

/// Deflate a BitArray in a synchronous way.
@external(javascript, "./brioche.ffi.mjs", "deflateSync")
pub fn deflate(content: BitArray) -> Result(BitArray, Nil)

/// Inflate a BitArray in a synchronous way.
@external(javascript, "./brioche.ffi.mjs", "inflateSync")
pub fn inflate(content: BitArray) -> Result(BitArray, nil)

/// Inspect a data structure, and return it as string. You should always use
/// `string.inspect` in first intention, unless you're sure to target Bun only.
@external(javascript, "./brioche.ffi.mjs", "inspect")
pub fn inspect(content: a) -> String

/// Returns the current number of nanoseconds elapsed since the start of the
/// main Bun process. `nanoseconds` returns a monotonic time.
@external(javascript, "./brioche.ffi.mjs", "nanoseconds")
pub fn nanoseconds() -> Int
