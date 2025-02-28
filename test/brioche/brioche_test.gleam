import brioche
import gleam/float
import gleam/int
import gleam/javascript/promise
import gleam/string
import gleam/time/duration
import gleam/time/timestamp
import gleeunit/should
import utils/promises

/// Current test version. Update the version when updating the Bun
/// runtime after adding new API.
const version = "1.2.4"

/// Current revision. Update the revision when updating the Bun
/// runtime after adding new API.
const revision = "fd9a5ea668e9ffce5fd5f25a7cfd2d45f0eaa85b"

pub fn version_test() {
  brioche.version()
  |> should.equal(version)
}

pub fn revision_test() {
  brioche.revision()
  |> should.equal(revision)
}

pub fn main_script_test() {
  brioche.main_script()
  |> string.contains("brioche/gleam.main.mjs")
  |> should.be_true
}

pub fn which_test() {
  case brioche.which("ls") {
    Ok("/bin/ls") -> Nil
    Ok("/usr/bin/ls") -> Nil
    _ -> should.fail()
  }
  brioche.which("azerty")
  |> should.be_error
  |> should.equal(Nil)
}

pub fn random_uuid_test() {
  let uuid = brioche.random_uuid_v7()
  let parts = string.split(uuid, on: "-")
  case parts {
    [a, b, c, d, e] -> {
      a |> string.length |> should.equal(8)
      b |> string.length |> should.equal(4)
      c |> string.length |> should.equal(4)
      d |> string.length |> should.equal(4)
      e |> string.length |> should.equal(12)
    }
    _ -> should.fail()
  }
}

pub fn sleep_sync_test() {
  let start = timestamp.system_time()
  brioche.sleep(25)
  let end = timestamp.system_time()
  let delta = timestamp.difference(start, end)
  let #(_, nanoseconds) = duration.to_seconds_and_nanoseconds(delta)
  let assert Ok(duration) = int.power(10, 6.0)
  let duration = float.round(duration)
  let duration = 25 * duration
  { nanoseconds >= duration }
  |> should.be_true
}

pub fn peek_test() {
  let resolve = promise.resolve("test")
  let rejection = promises.reject()
  let pending = promises.pending()
  brioche.peek(resolve) |> should.be_ok |> should.equal("test")
  brioche.peek(rejection) |> should.be_error |> should.equal(Nil)
  brioche.peek(pending) |> should.be_error |> should.equal(Nil)
  // Rescue the error to avoid Bun to trigger an error.
  promise.rescue(rejection, fn(_) { Nil })
}

pub fn peek_status_test() {
  let resolve = promise.resolve("test")
  let rejection = promises.reject()
  let pending = promises.pending()
  brioche.peek_status(resolve) |> should.equal(brioche.Fulfilled)
  brioche.peek_status(rejection) |> should.equal(brioche.Rejected)
  brioche.peek_status(pending) |> should.equal(brioche.Pending)
  // Rescue the error to avoid Bun to trigger an error.
  promise.rescue(rejection, fn(_) { Nil })
}

pub fn string_width_test() {
  brioche.string_width("test")
  |> should.equal(4)
}

pub fn gzip_test() {
  let input = <<1, 2, 3, 4, 5>>
  brioche.gzip(input)
  |> should.be_ok
  |> brioche.gunzip
  |> should.be_ok
  |> should.equal(input)
}

pub fn inflate_test() {
  let input = <<1, 2, 3, 4, 5>>
  brioche.deflate(input)
  |> should.be_ok
  |> brioche.inflate
  |> should.be_ok
  |> should.equal(input)
}
