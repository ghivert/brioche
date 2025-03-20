//// Hash in the `hash` module are not cryptographically secure.
//// You can use them for non-important data, such a identity hash for files
//// or data, but you should never use them to store sensible informations.
//// To store sensible informations, Brioche exposes two additional modules:
//// [`brioche/hash/password`](https://hexdocs.pm/brioche/brioche/hash/password.html)
//// and [`brioche/hash/crypto_hasher`](https://hexdocs.pm/brioche/brioche/hash/crypto_hasher.html).
//// Both modules are cryptographically secure, and are made to work with
//// passwords, or with any data.
////
//// As a matter of convenience, `hash` exposes an entrypoint for hashing, and
//// is using Wyhash, to provide fast and robust hashing. However, multiple
//// algorithms can be used, according to your needs. Every function exposes two
//// way to hash data: hashing strings or hashing binaries. Hashing strings is
//// a commodity, while hashing binaries should be your privileged way to
//// perform hashing.
////
//// Every functions working on 32 bits will return an Int, while every functions
//// working with 64 bits will return a `BigInt`. This is due to a limitation of
//// JavaScript, that can not handle 64 bits as max integer. [`bigi`](https://hexdocs.pm/bigi)
//// is used to manipulate easily BigInt in JavaScript and Brioche.
////
//// ```gleam
//// import brioche/hash
////
//// hash.hash("my-data")
//// hash.hash_bytes(<<"my-bit-array":utf8>>)
//// hash.wyhash("my-data")
//// hash.crc32("my-data")
//// hash.city_hash64("my-data")
//// ```
////
//// [Bun Documentation](https://bun.sh/docs/api/hashing#bun-hash)

import bigi.{type BigInt}

/// Hash a string using Wyhash.
///
/// This is not a cryptographic hash function.
@external(javascript, "./hash/hash.ffi.mjs", "hash")
pub fn hash(data: String) -> BigInt

/// Hash a binary using Wyhash.
///
/// This is not a cryptographic hash function.
@external(javascript, "./hash/hash.ffi.mjs", "hashBytes")
pub fn hash_bytes(data: BitArray) -> BigInt

@external(javascript, "./hash/hash.ffi.mjs", "hash")
pub fn wyhash(data: String) -> BigInt

@external(javascript, "./hash/hash.ffi.mjs", "hashBytes")
pub fn wyhash_bytes(data: BitArray) -> BigInt

@external(javascript, "./hash/hash.ffi.mjs", "crc32")
pub fn crc32(data: String) -> Int

@external(javascript, "./hash/hash.ffi.mjs", "crc32Bytes")
pub fn crc32_bytes(data: BitArray) -> Int

@external(javascript, "./hash/hash.ffi.mjs", "adler32")
pub fn adler32(data: String) -> Int

@external(javascript, "./hash/hash.ffi.mjs", "adler32Bytes")
pub fn adler32_bytes(data: BitArray) -> Int

@external(javascript, "./hash/hash.ffi.mjs", "cityHash32")
pub fn city_hash32(data: String) -> Int

@external(javascript, "./hash/hash.ffi.mjs", "cityHash32Bytes")
pub fn city_hash32_bytes(data: BitArray) -> Int

@external(javascript, "./hash/hash.ffi.mjs", "cityHash64")
pub fn city_hash64(data: String) -> BigInt

@external(javascript, "./hash/hash.ffi.mjs", "cityHash64Bytes")
pub fn city_hash64_bytes(data: BitArray) -> BigInt

@external(javascript, "./hash/hash.ffi.mjs", "xxHash32")
pub fn xx_hash32(data: String) -> Int

@external(javascript, "./hash/hash.ffi.mjs", "xxHash32Bytes")
pub fn xx_hash32_bytes(data: BitArray) -> Int

@external(javascript, "./hash/hash.ffi.mjs", "xxHash64")
pub fn xx_hash64(data: String) -> BigInt

@external(javascript, "./hash/hash.ffi.mjs", "xxHash64Bytes")
pub fn xx_hash64_bytes(data: BitArray) -> BigInt

@external(javascript, "./hash/hash.ffi.mjs", "xxHash3")
pub fn xx_hash3(data: String) -> BigInt

@external(javascript, "./hash/hash.ffi.mjs", "xxHash3Bytes")
pub fn xx_hash3_bytes(data: BitArray) -> BigInt

@external(javascript, "./hash/hash.ffi.mjs", "murmur32v3")
pub fn murmur32v3(data: String) -> Int

@external(javascript, "./hash/hash.ffi.mjs", "murmur32v3Bytes")
pub fn murmur32v3_bytes(data: BitArray) -> Int

@external(javascript, "./hash/hash.ffi.mjs", "murmur32v2")
pub fn murmur32v2(data: String) -> Int

@external(javascript, "./hash/hash.ffi.mjs", "murmur32v2Bytes")
pub fn murmur32v2_bytes(data: BitArray) -> Int

@external(javascript, "./hash/hash.ffi.mjs", "murmur64v2")
pub fn murmur64v2(data: String) -> BigInt

@external(javascript, "./hash/hash.ffi.mjs", "murmur64v2Bytes")
pub fn murmur64v2_bytes(data: BitArray) -> BigInt
