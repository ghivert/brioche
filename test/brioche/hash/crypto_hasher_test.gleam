import brioche/hash/crypto_hasher
import gleeunit/should

pub fn digest_test() {
  crypto_hasher.new(crypto_hasher.Sha1)
  |> crypto_hasher.update("example")
  |> crypto_hasher.update_bytes(<<"example":utf8>>)
  |> crypto_hasher.digest
  |> should.be_ok
  |> should.equal(<<
    170, 200, 136, 24, 96, 155, 106, 144, 223, 125, 25, 85, 235, 129, 227, 104,
    198, 153, 65, 69,
  >>)
}

pub fn digest_to_test() {
  crypto_hasher.new(crypto_hasher.Sha1)
  |> crypto_hasher.update("example")
  |> crypto_hasher.update_bytes(<<"example":utf8>>)
  |> crypto_hasher.digest_as(crypto_hasher.Hex)
  |> should.be_ok
  |> should.equal("aac88818609b6a90df7d1955eb81e368c6994145")
}

pub fn hmac_test() {
  crypto_hasher.hmac(crypto_hasher.Sha1, <<"example":utf8>>)
  |> should.be_ok
  |> crypto_hasher.update("example")
  |> crypto_hasher.update_bytes(<<"example":utf8>>)
  |> crypto_hasher.digest
  |> should.be_ok
  |> should.equal(<<
    210, 35, 101, 17, 154, 36, 103, 109, 235, 230, 11, 174, 35, 137, 55, 63, 208,
    141, 27, 254,
  >>)
}

pub fn hmac_reuse_test() {
  let assert Ok(hasher) =
    crypto_hasher.hmac(crypto_hasher.Sha1, <<"example":utf8>>)
  hasher
  |> crypto_hasher.update("example")
  |> crypto_hasher.update_bytes(<<"example":utf8>>)
  |> crypto_hasher.digest
  |> should.be_ok
  |> should.equal(<<
    210, 35, 101, 17, 154, 36, 103, 109, 235, 230, 11, 174, 35, 137, 55, 63, 208,
    141, 27, 254,
  >>)
  hasher
  |> crypto_hasher.digest
  |> should.be_error
  |> should.equal(crypto_hasher.HasherAlreadyConsumed)
}

pub fn standard_reuse_test() {
  let hasher = crypto_hasher.new(crypto_hasher.Sha1)
  hasher
  |> crypto_hasher.update("example")
  |> crypto_hasher.update_bytes(<<"example":utf8>>)
  |> crypto_hasher.digest
  |> should.be_ok
  |> should.equal(<<
    170, 200, 136, 24, 96, 155, 106, 144, 223, 125, 25, 85, 235, 129, 227, 104,
    198, 153, 65, 69,
  >>)
  hasher
  |> crypto_hasher.digest
  |> should.be_ok
}

pub fn copy_test() {
  let hasher1 = crypto_hasher.new(crypto_hasher.Sha1)
  hasher1
  |> crypto_hasher.update("example")
  |> crypto_hasher.update_bytes(<<"example":utf8>>)
  let hasher2 = crypto_hasher.copy(hasher1)
  let res1 = crypto_hasher.digest(hasher1)
  let res2 = crypto_hasher.digest(hasher2)
  res1 |> should.equal(res2)
}
