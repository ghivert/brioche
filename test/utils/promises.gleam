import gleam/javascript/promise.{type Promise}

@external(javascript, "./promises.ffi.mjs", "reject")
pub fn reject() -> Promise(Nil)

@external(javascript, "./promises.ffi.mjs", "pending")
pub fn pending() -> Promise(Nil)
