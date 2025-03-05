import gleam/dynamic/decode
import gleam/javascript/promise.{type Promise}

@external(javascript, "./exception.ffi.mjs", "defer")
pub fn defer(
  cleanup cleanup: fn() -> a,
  body body: fn() -> Promise(b),
) -> Promise(b)

@external(javascript, "./exception.ffi.mjs", "rescue")
pub fn rescue(body: fn() -> Promise(a)) -> Promise(Result(a, decode.Dynamic))

@external(javascript, "./exception.ffi.mjs", "log")
pub fn log(a: a) -> Nil
