import * as $gleam from '../gleam.mjs'
import * as $file from './file.mjs'

export const stdin = () => Bun.stdin
export const stdout = () => Bun.stdout
export const stderr = () => Bun.stderr

export const newFile = path => Bun.file(path)
export const mime = file => file.type
export const writer = file => file.writer()

export async function stat(file) {
  try {
    const result = await file.stat()
    const stat = new $file.Stat(
      result.dev,
      result.ino,
      result.mode,
      result.nlink,
      result.uid,
      result.gid,
      result.rdev,
      result.size,
      result.blksize,
      result.blocks,
      result.atimeMs,
      result.mtimeMs,
      result.ctimeMs,
      result.birthtimeMs
    )
    return new $gleam.Ok(stat)
  } catch (error) {
    const err = convertError(error)
    return new $gleam.Error(err)
  }
}

export async function exists(file) {
  try {
    const exists = await file.exists()
    return new $gleam.Ok(exists)
  } catch (error) {
    const err = convertError(error)
    return new $gleam.Error(err)
  }
}

export async function flush(writer) {
  try {
    const content = await writer.flush()
    return new $gleam.Ok(content)
  } catch (error) {
    const err = convertError(error)
    return new $gleam.Error(err)
  }
}

export function ref(writer) {
  writer.ref()
  return writer
}

export function unref(writer) {
  writer.unref()
  return writer
}

// Unused at the moment, while the API is unclear.
export function writerStart(writer) {
  writer.start()
  return writer
}

export async function writerEnd(writer) {
  try {
    const res = await writer.end()
    return new $gleam.Ok(res)
  } catch (error) {
    const err = convertError(error)
    return new $gleam.Error(err)
  }
}

export function writerWriteText(writer, data) {
  return writer.write(data)
}

export function writerWriteBytes(writer, data) {
  return writer.write(data.rawBuffer)
}

export async function bytes(file) {
  try {
    const exists = await file.exists()
    if (!exists) return new $gleam.Error(new $file.Enoent())
    const content = await file.bytes()
    const bits = $gleam.toBitArray(content)
    return new $gleam.Ok(bits)
  } catch (error) {
    const err = convertError(error)
    return new $gleam.Error(err)
  }
}

export async function formData(file) {
  try {
    const exists = await file.exists()
    if (!exists) return new $gleam.Error(new $file.Enoent())
    const content = await file.formData()
    return new $gleam.Ok(content)
  } catch (error) {
    const err = convertError(error)
    return new $gleam.Error(err)
  }
}

export async function text(file) {
  try {
    const exists = await file.exists()
    if (!exists) return new $gleam.Error(new $file.Enoent())
    const content = await file.text()
    return new $gleam.Ok(content)
  } catch (error) {
    const err = convertError(error)
    return new $gleam.Error(err)
  }
}

export async function json(file) {
  try {
    const exists = await file.exists()
    if (!exists) return new $gleam.Error(new $file.Enoent())
    const content = await file.json()
    return new $gleam.Ok(content)
  } catch (error) {
    const err = convertError(error)
    return new $gleam.Error(err)
  }
}

export async function deleteFile(file) {
  try {
    const exists = await file.exists()
    if (!exists) return new $gleam.Error(new $file.Enoent())
    await file.delete()
    return new $gleam.Ok()
  } catch (error) {
    const err = convertError(error)
    return new $gleam.Error(err)
  }
}

export async function write(destination, data) {
  try {
    const bits = await Bun.write(destination, data)
    return new $gleam.Ok(bits)
  } catch (error) {
    const err = convertError(error)
    return new $gleam.Error(err)
  }
}

export async function writeBytes(destination, data) {
  try {
    const dat = data.rawBuffer
    const bits = await Bun.write(destination, dat)
    return new $gleam.Ok(bits)
  } catch (error) {
    const err = convertError(error)
    return new $gleam.Error(err)
  }
}

export async function copy(source, destination) {
  try {
    const bits = await Bun.write(destination, source)
    return new $gleam.Ok(bits)
  } catch (error) {
    const err = convertError(error)
    return new $gleam.Error(err)
  }
}

function convertError(error) {
  if (error.code === 'ERR_S3_MISSING_CREDENTIALS')
    return new $file.S3MissingCredentials()
  if (error.code === 'ERR_S3_INVALID_METHOD') return new $file.S3InvalidMethod()
  if (error.code === 'ERR_S3_INVALID_PATH') return new $file.S3InvalidPath()
  if (error.code === 'ERR_S3_INVALID_ENDPOINT')
    return new $file.S3InvalidEndpoint()
  if (error.code === 'ERR_S3_INVALID_SIGNATURE')
    return new $file.S3InvalidSignature()
  if (error.code === 'ERR_S3_INVALID_SESSION_TOKEN')
    return new $file.S3InvalidSessionToken()
  if (error.name === 'S3Error') return new $file.S3Error(error)
  return new $file.FileError(error)
}
