//// Crypto Hasher are general purpose object, that let you incrementally
//// compute a hash of strings or binaries, with different hash algorithms.
//// Crypto Hashers are cryptographically safe.
////
//// Crypto Hasher are stateful objects, that will modify itself after each
//// update. In case you want to treat Crypto Hasher as pure data, you're free
//// to copy them freely.
////
//// ```gleam
//// import brioche/hash/crypto_hasher
//// crypto_hasher.new(crypto_hasher.Sha1)
//// |> crypto_hasher.update("example")
//// |> crypto_hasher.update_bytes(<<"example":utf8>>)
//// |> crypto_hasher.digest_as(crypto_hasher.Hex)
//// ```
////
//// [Bun Documentation](https://bun.sh/docs/api/hashing#bun-cryptohasher)

/// Implementation of a Crypto Hasher, general purpose object allowing to
/// incrementally compute has of strings or binary.
///
/// ```gleam
/// import brioche/hash/crypto_hasher
/// let hasher = crypto_hasher.new(crypto_hasher.Sha256)
/// ```
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

/// Digests from crypto hasher are outputted as binaries by default, but they
/// can also be outputted as strings. `DigestFormat` allows you to indicate
/// which kind of string you desire.
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

/// Create a new, empty Crypto Hasher. Every Crypto Hasher have an algorithm
/// at initialisation, and can not be changed afterwards.
///
/// ```gleam
/// import brioche/hash/crypto_hasher
/// let hasher = crypto_hasher.new(crypto_hasher.Sha256)
/// ```
@external(javascript, "./hash.ffi.mjs", "createCryptoHasher")
pub fn new(algorithm: Algorithm) -> CryptoHasher

/// Create a copy of the Crypto Hasher, in the exact same state. Use it to reuse
/// a hasher multiple times.
///
/// ```gleam
/// import brioche/hash/crypto_hasher
/// let hasher = crypto_hasher.new(crypto_hasher.Sha256)
/// let new_hash = crypto_hasher.copy(hasher)
/// ```
@external(javascript, "./hash.ffi.mjs", "copyCryptoHasher")
pub fn copy(hasher: CryptoHasher) -> CryptoHasher

/// Create a new, empty Crypto Hasher outputing HMAC. As with default Crypto
/// Hasher, an algorithm should be provided at initialisation, and cannot be
/// change afterwards.
///
/// > Be careful, not all algorithms are supported by HMAC Crypto Hashers.
/// > Only `Blake2B512`, `Md5`, `Sha1`, `Sha224`, `Sha256`, `Sha384`,
/// > `Sha512224`, `Sha512256` and `Sha512` are supported.
///
/// ```gleam
/// import brioche/hash/crypto_hasher
/// let hasher = crypto_hasher.hmac(crypto_hasher.Sha1, secret_key)
/// ```
@external(javascript, "./hash.ffi.mjs", "createHmacHasher")
pub fn hmac(
  algorithm: Algorithm,
  secret_key: BitArray,
) -> Result(CryptoHasher, CryptoHasherError)

/// Add a string in the hasher. It can be freely combined with
/// [`update_bytes`](#update_bytes).
///
/// ```gleam
/// import brioche/hash/crypto_hasher
/// crypto_hasher.new(crypto_hasher.Sha1)
/// |> crypto_hasher.update("first part")
/// |> crypto_hasher.update("second part")
/// |> crypto_hasher.update_bytes(<<"third part">>)
/// ```
@external(javascript, "./hash.ffi.mjs", "updateCryptoHasher")
pub fn update(crypto_hasher: CryptoHasher, data: String) -> CryptoHasher

/// Add a binary in the hasher. It can be freely combined with
/// [`update`](#update).
///
/// ```gleam
/// import brioche/hash/crypto_hasher
/// crypto_hasher.new(crypto_hasher.Sha1)
/// |> crypto_hasher.update_bytes(<<"first part">>)
/// |> crypto_hasher.update_bytes(<<"second part">>)
/// |> crypto_hasher.update("third part")
/// ```
@external(javascript, "./hash.ffi.mjs", "updateBytesCryptoHasher")
pub fn update_bytes(crypto_hasher: CryptoHasher, data: BitArray) -> CryptoHasher

/// Consumes the Crypto Hasher & get the digested hash as binary. After the
/// hasher has been consumed, normal Crypto Hashers will be resetted, while HMAC
/// hashers will be consumed and will return an error if already consumed. In
/// case you want to reuse the hasher, you can use [`copy`](#copy) before
/// digesting the result.
///
/// ```gleam
/// import brioche/hash/crypto_hasher
/// crypto_hasher.new(crypto_hasher.Sha1)
/// |> crypto_hasher.update_bytes(<<"first part">>)
/// |> crypto_hasher.update("second part")
/// |> crypto_hasher.digest
/// ```
@external(javascript, "./hash.ffi.mjs", "digestCryptoHasher")
pub fn digest(
  crypto_hasher: CryptoHasher,
) -> Result(BitArray, CryptoHasherError)

/// Consumes the Crypto Hasher & get the digested hash as a string. After the
/// hasher has been consumed, normal Crypto Hashers will be resetted, while HMAC
/// hashers will be consumed and will return an error if already consumed. In
/// case you want to reuse the hasher, you can use [`copy`](#copy) before
/// digesting the result.
///
/// Strings can be of different shapes, as indicated by the `DigestFormat`.
/// Use the one more suited to your use case.
///
/// ```gleam
/// import brioche/hash/crypto_hasher
/// crypto_hasher.new(crypto_hasher.Sha1)
/// |> crypto_hasher.update_bytes(<<"first part">>)
/// |> crypto_hasher.update("second part")
/// |> crypto_hasher.digest_as(crypto_hasher.Base64)
/// ```
@external(javascript, "./hash.ffi.mjs", "digestCryptoHasher")
pub fn digest_as(
  crypto_hasher: CryptoHasher,
  format: DigestFormat,
) -> Result(String, CryptoHasherError)
