//// Bun provides a [semantic versioning](https://semver.org/) API, to compare
//// versions and determine if a version is compatible with a range of versions.
//// Bun's semver is compatible with [`node-semver`](https://github.com/npm/node-semver).
////
//// [Bun Documentation](https://bun.sh/docs/api/semver)

import gleam/order

/// Checks if a `version` is comprised within desired `range`.
///
/// ```gleam
/// import brioche/semver
/// semver.satisfies("1.0.0", "^1.0.0") // true
/// semver.satisfies("1.0.0", "^1.0.1") // false
/// semver.satisfies("1.0.0", "~1.0.0") // true
/// semver.satisfies("1.0.0", "~1.0.1") // false
/// semver.satisfies("1.0.0", "1.0.0") // true
/// semver.satisfies("1.0.0", "1.0.1") // false
/// semver.satisfies("1.0.1", "1.0.0") // false
/// semver.satisfies("1.0.0", "1.0.x") // true
/// semver.satisfies("1.0.0", "1.x.x") // true
/// semver.satisfies("1.0.0", "x.x.x") // true
/// semver.satisfies("1.0.0", ">= 1.0.0 and < 2.0.0") // true
/// semver.satisfies("1.0.0", ">= 1.0.0 and < 1.0.1") // true
/// ```
@external(javascript, "./semver.ffi.mjs", "satisfies")
pub fn satisfies(version version: String, range range: String) -> Bool

/// Compares two versions.
///
/// ```gleam
/// import brioche/semver
///
/// semver.compare("1.0.0", "1.0.0") // order.Eq
/// semver.compare("1.0.0", "1.0.1") // order.Lt
/// semver.compare("1.0.1", "1.0.0") // order.Gt
///
/// let unsorted = ["1.0.0", "1.0.1", "1.0.0-alpha", "1.0.0-beta", "1.0.0-rc"]
/// list.sort(unsorted, semver.compare)
/// // -> ["1.0.0-alpha", "1.0.0-beta", "1.0.0-rc", "1.0.0", "1.0.1"]
/// ```
pub fn compare(version_a: String, version_b: String) -> order.Order {
  case do_compare(version_a, version_b) {
    0 -> order.Eq
    -1 -> order.Lt
    1 -> order.Gt
    _ -> panic as "Breaking order"
  }
}

@external(javascript, "./semver.ffi.mjs", "compare")
fn do_compare(version_a: String, version_b: String) -> Int
