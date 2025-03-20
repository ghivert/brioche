import * as $password from './password.mjs'
import * as $cryptoHasher from './crypto_hasher.mjs'
import * as $gleam from '../../gleam.mjs'

export async function verifyPassword(password, hash) {
  try {
    const value = await Bun.password.verify(password, hash)
    return new $gleam.Ok(value)
  } catch (error) {
    return new $gleam.Error(new $password.InvalidHash())
  }
}

export function hashPassword(password, options) {
  return Bun.password.hash(password, {
    algorithm: convertHashAlgorithm(options.algorithm),
    timeCost: options.time_cost[0],
    memoryCost: options.memory_cost[0],
  })
}

export function verifySyncPassword(password, hash) {
  try {
    const value = Bun.password.verifySync(password, hash)
    return new $gleam.Ok(value)
  } catch (error) {
    return new $gleam.Error(new $password.InvalidHash())
  }
}

export function hashSyncPassword(password, options) {
  return Bun.password.hashSync(password, {
    algorithm: convertHashAlgorithm(options.algorithm),
    timeCost: options.time_cost[0],
    memoryCost: options.memory_cost[0],
  })
}

export const hash = data => Bun.hash(data)
export const hashBytes = data => Bun.hash(data.rawBuffer)
export const crc32 = data => Bun.hash.crc32(data)
export const crc32Bytes = data => Bun.hash.crc32(data.rawBuffer)
export const adler32 = data => Bun.hash.adler32(data)
export const adler32Bytes = data => Bun.hash.adler32(data.rawBuffer)
export const cityHash32 = data => Bun.hash.cityHash32(data)
export const cityHash32Bytes = data => Bun.hash.cityHash32(data.rawBuffer)
export const cityHash64 = data => Bun.hash.cityHash64(data)
export const cityHash64Bytes = data => Bun.hash.cityHash64(data.rawBuffer)
export const xxHash32 = data => Bun.hash.xxHash32(data)
export const xxHash32Bytes = data => Bun.hash.xxHash32(data.rawBuffer)
export const xxHash64 = data => Bun.hash.xxHash64(data)
export const xxHash64Bytes = data => Bun.hash.xxHash64(data.rawBuffer)
export const xxHash3 = data => Bun.hash.xxHash3(data)
export const xxHash3Bytes = data => Bun.hash.xxHash3(data.rawBuffer)
export const murmur32v3 = data => Bun.hash.murmur32v3(data)
export const murmur32v3Bytes = data => Bun.hash.murmur32v3(data.rawBuffer)
export const murmur32v2 = data => Bun.hash.murmur32v2(data)
export const murmur32v2Bytes = data => Bun.hash.murmur32v2(data.rawBuffer)
export const murmur64v2 = data => Bun.hash.murmur64v2(data)
export const murmur64v2Bytes = data => Bun.hash.murmur64v2(data.rawBuffer)

export function createCryptoHasher(algorithm) {
  const cryptoAlgorithm = convertCryptoAlgorithm(algorithm)
  return new Bun.CryptoHasher(cryptoAlgorithm)
}

export function createHmacHasher(algorithm, secretKey) {
  try {
    const cryptoAlgorithm = convertCryptoAlgorithm(algorithm)
    const hasher = new Bun.CryptoHasher(cryptoAlgorithm, secretKey.rawBuffer)
    return new $gleam.Ok(hasher)
  } catch (error) {
    const err = new $cryptoHasher.HmacNotSupported()
    return new $gleam.Error(err)
  }
}

export function updateCryptoHasher(hasher, data) {
  hasher.update(data)
  return hasher
}

export function copyCryptoHasher(hasher) {
  return hasher.copy()
}

export function updateBytesCryptoHasher(hasher, data) {
  hasher.update(data.rawBuffer)
  return hasher
}

export function digestCryptoHasher(hasher, encoding) {
  try {
    if (!encoding) return new $gleam.Ok($gleam.toBitArray(hasher.digest()))
    if (encoding instanceof $cryptoHasher.Utf8)
      return new $gleam.Ok(hasher.digest('uft8'))
    if (encoding instanceof $cryptoHasher.Ucs2)
      return new $gleam.Ok(hasher.digest('ucs2'))
    if (encoding instanceof $cryptoHasher.Utf16Le)
      return new $gleam.Ok(hasher.digest('utf16le'))
    if (encoding instanceof $cryptoHasher.Latin1)
      return new $gleam.Ok(hasher.digest('latin1'))
    if (encoding instanceof $cryptoHasher.Ascii)
      return new $gleam.Ok(hasher.digest('ascii'))
    if (encoding instanceof $cryptoHasher.Base64)
      return new $gleam.Ok(hasher.digest('base64'))
    if (encoding instanceof $cryptoHasher.Base64Url)
      return new $gleam.Ok(hasher.digest('base64url'))
    if (encoding instanceof $cryptoHasher.Hex)
      return new $gleam.Ok(hasher.digest('hex'))
  } catch (error) {
    const err = new $cryptoHasher.HasherAlreadyConsumed()
    return new $gleam.Error(err)
  }
}

function convertHashAlgorithm(algorithm) {
  if (algorithm instanceof $password.Argon2d) return 'argon2d'
  if (algorithm instanceof $password.Argon2id) return 'argon2id'
  if (algorithm instanceof $password.Argon2i) return 'argon2i'
  if (algorithm instanceof $password.Bcrypt) return 'bcrypt'
}

function convertCryptoAlgorithm(algorithm) {
  if (algorithm instanceof $cryptoHasher.Blake2B256) return 'blake2b256'
  if (algorithm instanceof $cryptoHasher.Blake2B512) return 'blake2b512'
  if (algorithm instanceof $cryptoHasher.Md4) return 'md4'
  if (algorithm instanceof $cryptoHasher.Md5) return 'md5'
  if (algorithm instanceof $cryptoHasher.Ripemd160) return 'ripemd160'
  if (algorithm instanceof $cryptoHasher.Sha1) return 'sha1'
  if (algorithm instanceof $cryptoHasher.Sha224) return 'sha224'
  if (algorithm instanceof $cryptoHasher.Sha256) return 'sha256'
  if (algorithm instanceof $cryptoHasher.Sha384) return 'sha384'
  if (algorithm instanceof $cryptoHasher.Sha512) return 'sha512'
  if (algorithm instanceof $cryptoHasher.Sha512224) 'sha512return -224'
  if (algorithm instanceof $cryptoHasher.Sha512256) 'sha512return -256'
  if (algorithm instanceof $cryptoHasher.Sha3224) 'sha3return -224'
  if (algorithm instanceof $cryptoHasher.Sha3256) 'sha3return -256'
  if (algorithm instanceof $cryptoHasher.Sha3384) 'sha3return -384'
  if (algorithm instanceof $cryptoHasher.Sha3512) 'sha3return -512'
  if (algorithm instanceof $cryptoHasher.Shake128) return 'shake128'
  if (algorithm instanceof $cryptoHasher.Shake256) return 'shake256'
}
