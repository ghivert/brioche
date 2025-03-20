//// Hash and verify passwords using argon2 or bcrypt. Password hashing
//// functions are necessarily slow, and the functions in the
//// `brioche/hash/password` will automatically run in a worker thread.
////
//// Every hash function should be configured with the desired hashing algorithm
//// and some features when needed. To simplify the usage of the hashing functions,
//// you can use the `argon2d`, `argon2i`, `argon2id` & `bcrypt` helpers that
//// create automatically default hash options for any hash.
////
//// ```gleam
//// import brioche/hash/password
//// let hash = password.hash("hello world", password.argon2d())
//// use hash <- promise.await(hash)
//// let verify = password.verify("hello world", hash)
//// use verify <- promise.await(verify)
//// echo verify // True
//// ```
////
//// [Bun Documentation](https://bun.sh/docs/api/hashing#bun-password)

import gleam/javascript/promise.{type Promise}
import gleam/option.{type Option}

pub type PasswordError {
  InvalidHash
}

/// Verify a password against a previously hashed password.
///
/// ```gleam
/// import brioche/hash/password
/// import gleam/javascript/promise
/// let hash = "$argon2id$v=19$m=65536,t=2,p=1$ddbcyBcbAcagei7wSkZFiouX6TqnUQHmTyS5mxGCzeM$+3OIaFatZ3n6LtMhUlfWbgJyNp7h8/oIsLK+LzZO+WI"
/// password.verify("hey", hash)
/// |> promise.await(fn (result) {
///   // result == True
/// })
/// ```
@external(javascript, "./hash.ffi.mjs", "verifyPassword")
pub fn verify(
  password password: String,
  hash hash: String,
) -> Promise(Result(Bool, PasswordError))

/// Verify a password against a previously hashed password.
///
/// > Be careful, sync versions should almost never be used as verify hash takes
/// > time, and can considerably impact your production.
///
/// ```gleam
/// import brioche/hash/password
/// let hash = "$argon2id$v=19$m=65536,t=2,p=1$ddbcyBcbAcagei7wSkZFiouX6TqnUQHmTyS5mxGCzeM$+3OIaFatZ3n6LtMhUlfWbgJyNp7h8/oIsLK+LzZO+WI"
/// password.verify_sync("hey", hash)
/// // result == True
/// ```
@external(javascript, "./hash.ffi.mjs", "verifySyncPassword")
pub fn verify_sync(
  password password: String,
  hash hash: String,
) -> Result(Bool, PasswordError)

/// Hash a password using argon2 or bcrypt.
///
/// ```gleam
/// import brioche/hash/password
/// import gleam/javascript/promise
/// use hash <- promise.await(password.hash("hello world", password.argon2d()))
/// use verify <- promise.await(password.verify("hello world", hash))
/// ```
@external(javascript, "./hash.ffi.mjs", "hashPassword")
pub fn hash(
  password password: String,
  options options: HashOptions,
) -> Promise(String)

/// Hash a password using argon2 or bcrypt.
///
/// > Be careful, sync versions should almost never be used as verify hash takes
/// > time, and can considerably impact your production.
///
/// ```gleam
/// import brioche/hash/password
/// let hash = password.hash("hello world", password.argon2d())
/// let verify = password.verify("hello world", hash)
/// ```
@external(javascript, "./hash.ffi.mjs", "hashSyncPassword")
pub fn hash_sync(
  password password: String,
  options options: HashOptions,
) -> String

pub type HashAlgorithm {
  Argon2d
  Argon2i
  Argon2id
  Bcrypt
}

pub type HashOptions {
  HashOptions(
    /// Algorithm to use in hashing.
    algorithm: HashAlgorithm,
    /// Memory usage, in kibibytes.
    memory_cost: Option(Int),
    /// Number of hash iterations.
    time_cost: Option(Int),
  )
}

pub fn argon2d() -> HashOptions {
  HashOptions(
    algorithm: Argon2d,
    memory_cost: option.None,
    time_cost: option.None,
  )
}

pub fn argon2id() -> HashOptions {
  HashOptions(
    algorithm: Argon2id,
    memory_cost: option.None,
    time_cost: option.None,
  )
}

pub fn argon2i() -> HashOptions {
  HashOptions(
    algorithm: Argon2i,
    memory_cost: option.None,
    time_cost: option.None,
  )
}

pub fn bcrypt() -> HashOptions {
  HashOptions(
    algorithm: Bcrypt,
    memory_cost: option.None,
    time_cost: option.None,
  )
}

/// Set the memory usage, in kibibytes.
pub fn memory_cost(options: HashOptions, memory_cost: Int) -> HashOptions {
  let memory_cost = option.Some(memory_cost)
  HashOptions(..options, memory_cost:)
}

/// Set the number of iterations for hash.
pub fn time_cost(options: HashOptions, time_cost: Int) -> HashOptions {
  let time_cost = option.Some(time_cost)
  HashOptions(..options, time_cost:)
}
