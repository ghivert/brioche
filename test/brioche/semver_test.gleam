import brioche/semver
import gleam/list
import gleeunit/should

pub fn satisfies_test() {
  semver.satisfies("1.1.1", "~> 1.0.0") |> should.be_false
  semver.satisfies("1.1.1", "~> 1.1.0") |> should.be_true
  semver.satisfies("1.1.1", "~> 1.0.0") |> should.be_false
  semver.satisfies("1.1.1", ">= 1.1.0 and < 2.0.0") |> should.be_true
  semver.satisfies("1.1.1", "^1.0.0") |> should.be_true
}

pub fn order_test() {
  let versions = ["1.1.1", "1.1.0", "2.0.0", "2.1.0", "3.2.0", "1.0.0"]
  list.sort(versions, semver.compare)
  |> should.equal(["1.0.0", "1.1.0", "1.1.1", "2.0.0", "2.1.0", "3.2.0"])
}
