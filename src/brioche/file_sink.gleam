import brioche.{type FileSink}
import gleam/javascript/promise.{type Promise}

@external(javascript, "./file.ffi.mjs", "writerWriteText")
pub fn write_text(sink: FileSink, data: String) -> Int

@external(javascript, "./file.ffi.mjs", "writerWriteBytes")
pub fn write_bytes(sink: FileSink, data: BitArray) -> Int

@external(javascript, "./file.ffi.mjs", "ref")
pub fn ref(sink: FileSink) -> FileSink

@external(javascript, "./file.ffi.mjs", "unref")
pub fn unref(sink: FileSink) -> FileSink

@external(javascript, "./file.ffi.mjs", "flush")
pub fn flush(sink: FileSink) -> Promise(Result(Int, Nil))

@external(javascript, "./file.ffi.mjs", "writerEnd")
pub fn end(sink: FileSink) -> Promise(Result(Int, Nil))

@external(javascript, "./file.ffi.mjs", "writerStart")
pub fn start(sink: FileSink) -> FileSink
