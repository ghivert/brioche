import brioche/hash/password
import gleam/javascript/promise
import gleam/string
import gleeunit/should

pub fn hash_test() {
  let hash = password.hash("example", password.argon2d())
  use content <- promise.tap(hash)
  content
  |> string.starts_with("$argon2d")
  |> should.be_true
}

pub fn hash_sync_test() {
  let content = password.hash_sync("example", password.argon2id())
  content
  |> string.starts_with("$argon2id")
  |> should.be_true
}

pub fn verify_test() {
  let hash = password.hash("example", password.argon2i())
  use hash <- promise.await(hash)
  hash
  |> string.starts_with("$argon2i")
  |> should.be_true
  let verify = password.verify(password: "example", hash:)
  use verify <- promise.await(verify)
  verify
  |> should.be_ok
  |> should.be_true
  promise.resolve(Nil)
}

pub fn verify_invalid_test() {
  let verify = password.verify(password: "example", hash: "invalid")
  use verify <- promise.await(verify)
  verify
  |> should.be_error
  |> should.equal(password.HashInvalid)
  promise.resolve(Nil)
}

pub fn verify_sync_test() {
  let hash = password.hash_sync("example", password.bcrypt())
  hash
  |> string.starts_with("$2b")
  |> should.be_true
  let verify = password.verify_sync(password: "example", hash:)
  verify
  |> should.be_ok
  |> should.be_true
}

pub fn verify_sync_invalid_test() {
  let verify = password.verify_sync(password: "example", hash: "invalid")
  verify
  |> should.be_error
  |> should.equal(password.HashInvalid)
}

pub fn options_test() {
  password.hash_sync("example", {
    password.argon2d()
    |> password.memory_cost(10)
    |> password.time_cost(10)
    |> password.cost(10)
  })
  |> string.starts_with("$argon2")
  |> should.be_true
}
