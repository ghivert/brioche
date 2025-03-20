pub type CryptoHasher

pub type Algorithm {
  Blake2B256
  Blake2B512
  Md4
  Md5
  Ripemd160
  Sha1
  Sha224
  Sha256
  Sha384
  Sha512
  Sha512224
  Sha512256
  Sha3224
  Sha3256
  Sha3384
  Sha3512
  Shake128
  Shake256
}

pub type DigestFormat {
  Utf8
  Ucs2
  Utf16Le
  Latin1
  Ascii
  Base64
  Base64Url
  Hex
}

pub type CryptoHasherError {
  HmacNotSupported
  HasherAlreadyConsumed
}

@external(javascript, "./hash.ffi.mjs", "createCryptoHasher")
pub fn new(algorithm: Algorithm) -> CryptoHasher

@external(javascript, "./hash.ffi.mjs", "copyCryptoHasher")
pub fn copy(hasher: CryptoHasher) -> CryptoHasher

@external(javascript, "./hash.ffi.mjs", "createHmacHasher")
pub fn hmac(
  algorithm: Algorithm,
  secret_key: BitArray,
) -> Result(CryptoHasher, CryptoHasherError)

@external(javascript, "./hash.ffi.mjs", "updateCryptoHasher")
pub fn update(crypto_hasher: CryptoHasher, data: String) -> CryptoHasher

@external(javascript, "./hash.ffi.mjs", "updateBytesCryptoHasher")
pub fn update_bytes(crypto_hasher: CryptoHasher, data: BitArray) -> CryptoHasher

@external(javascript, "./hash.ffi.mjs", "digestCryptoHasher")
pub fn digest(
  crypto_hasher: CryptoHasher,
) -> Result(BitArray, CryptoHasherError)

@external(javascript, "./hash.ffi.mjs", "digestCryptoHasher")
pub fn digest_as(
  crypto_hasher: CryptoHasher,
  format: DigestFormat,
) -> Result(String, CryptoHasherError)
