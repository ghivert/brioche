import brioche.{type File, type FileSink}
import gleam/javascript/promise.{type Promise}

@external(javascript, "./file.ffi.mjs", "newFile")
pub fn new(path: String) -> File

@external(javascript, "./file.ffi.mjs", "size")
pub fn size(file: File) -> Int

@external(javascript, "./file.ffi.mjs", "exists")
pub fn exists(file: File) -> Promise(Bool)

@external(javascript, "./file.ffi.mjs", "mime")
pub fn mime(file: File) -> String

@external(javascript, "./file.ffi.mjs", "text")
pub fn text(file: File) -> Promise(Result(String, Nil))

@external(javascript, "./file.ffi.mjs", "bytes")
pub fn bytes(file: File) -> Promise(Result(BitArray, Nil))

@external(javascript, "./file.ffi.mjs", "deleteFile")
pub fn delete(file: File) -> Promise(Result(Nil, Nil))

@external(javascript, "./file.ffi.mjs", "write")
pub fn write_text(file: File, data: String) -> Promise(Result(Int, Nil))

@external(javascript, "./file.ffi.mjs", "writeBytes")
pub fn write_bytes(file: File, data: BitArray) -> Promise(Result(Int, Nil))

@external(javascript, "./file.ffi.mjs", "copy")
pub fn copy(file: File, to to: File) -> Promise(Result(Int, Nil))

@external(javascript, "./file.ffi.mjs", "writer")
pub fn writer(file: File) -> FileSink
