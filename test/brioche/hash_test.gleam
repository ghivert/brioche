import bigi
import brioche/hash
import gleam/bit_array
import gleeunit/should

pub fn hash_test() {
  let assert Ok(result) = bigi.from_string("2221272278162326096")
  hash.hash("example")
  |> should.equal(result)
}

pub fn hash_bytes_test() {
  let assert Ok(result) = bigi.from_string("2221272278162326096")
  hash.hash_bytes(bit_array.from_string("example"))
  |> should.equal(result)
}

pub fn crc32_test() {
  let result = 1_861_000_095
  hash.crc32("example")
  |> should.equal(result)
}

pub fn crc32_bytes_test() {
  let result = 1_861_000_095
  hash.crc32_bytes(bit_array.from_string("example"))
  |> should.equal(result)
}

pub fn adler32_test() {
  let result = 197_133_037
  hash.adler32("example")
  |> should.equal(result)
}

pub fn adler32_bytes_test() {
  let result = 197_133_037
  hash.adler32_bytes(bit_array.from_string("example"))
  |> should.equal(result)
}

pub fn city_hash32_test() {
  let result = 1_042_329_319
  hash.city_hash32("example")
  |> should.equal(result)
}

pub fn city_hash32_bytes_test() {
  let result = 1_042_329_319
  hash.city_hash32_bytes(bit_array.from_string("example"))
  |> should.equal(result)
}

pub fn city_hash64_test() {
  let assert Ok(result) = bigi.from_string("16020355434752283834")
  hash.city_hash64("example")
  |> should.equal(result)
}

pub fn city_hash64_bytes_test() {
  let assert Ok(result) = bigi.from_string("16020355434752283834")
  hash.city_hash64_bytes(bit_array.from_string("example"))
  |> should.equal(result)
}

pub fn xx_hash32_test() {
  let result = 1_808_882_584
  hash.xx_hash32("example")
  |> should.equal(result)
}

pub fn xx_hash32_bytes_test() {
  let result = 1_808_882_584
  hash.xx_hash32_bytes(bit_array.from_string("example"))
  |> should.equal(result)
}

pub fn xx_hash64_test() {
  let assert Ok(result) = bigi.from_string("16640137846744947806")
  hash.xx_hash64("example")
  |> should.equal(result)
}

pub fn xx_hash64_bytes_test() {
  let assert Ok(result) = bigi.from_string("16640137846744947806")
  hash.xx_hash64_bytes(bit_array.from_string("example"))
  |> should.equal(result)
}

pub fn xx_hash3_test() {
  let assert Ok(result) = bigi.from_string("18120799560859703692")
  hash.xx_hash3("example")
  |> should.equal(result)
}

pub fn xx_hash3_bytes_test() {
  let assert Ok(result) = bigi.from_string("18120799560859703692")
  hash.xx_hash3_bytes(bit_array.from_string("example"))
  |> should.equal(result)
}

pub fn murmur32v3_test() {
  let result = 4_028_466_757
  hash.murmur32v3("example")
  |> should.equal(result)
}

pub fn murmur32v3_bytes_test() {
  let result = 4_028_466_757
  hash.murmur32v3_bytes(bit_array.from_string("example"))
  |> should.equal(result)
}

pub fn murmur32v2_test() {
  let result = 2_330_924_198
  hash.murmur32v2("example")
  |> should.equal(result)
}

pub fn murmur32v2_bytes_test() {
  let result = 2_330_924_198
  hash.murmur32v2_bytes(bit_array.from_string("example"))
  |> should.equal(result)
}

pub fn murmur64v2_test() {
  let assert Ok(result) = bigi.from_string("8159245465611987064")
  hash.murmur64v2("example")
  |> should.equal(result)
}

pub fn murmur64v2_bytes_test() {
  let assert Ok(result) = bigi.from_string("8159245465611987064")
  hash.murmur64v2_bytes(bit_array.from_string("example"))
  |> should.equal(result)
}
