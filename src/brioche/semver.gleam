import gleam/order

@external(javascript, "./semver.ffi.mjs", "satisfies")
pub fn satisfies(version: String, range: String) -> Bool

pub fn compare(version: String, range: String) -> order.Order {
  case do_compare(version, range) {
    0 -> order.Eq
    -1 -> order.Lt
    1 -> order.Gt
    _ -> panic as "Breaking order"
  }
}

@external(javascript, "./semver.ffi.mjs", "compare")
fn do_compare(version: String, range: String) -> Int
