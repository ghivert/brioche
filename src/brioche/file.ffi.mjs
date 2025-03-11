import * as $gleam from '../gleam.mjs'

export const stdin = () => Bun.stdin
export const stdout = () => Bun.stdout
export const stderr = () => Bun.stderr

export const newFile = path => Bun.file(path)
export const exists = file => file.exists()
export const size = file => file.size
export const mime = file => file.type
export const writer = file => file.writer()

export async function flush(writer) {
  try {
    const content = await writer.flush()
    return new $gleam.Ok(content)
  } catch (error) {
    return new $gleam.Error()
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
    return new $gleam.Error()
  }
}

export function writerWriteText(writer, data) {
  return writer.write(data)
}

export function writerWriteBytes(writer, data) {
  return writer.write(data.rawBuffer)
}

export async function bytes(file) {
  const exists = await file.exists()
  if (!exists) return new $gleam.Error()
  const content = await file.bytes()
  const bits = $gleam.toBitArray(content)
  return new $gleam.Ok(bits)
}

export async function text(file) {
  const exists = await file.exists()
  if (!exists) return new $gleam.Error()
  const content = await file.text()
  return new $gleam.Ok(content)
}

export async function deleteFile(file) {
  const exists = await file.exists()
  if (!exists) return new $gleam.Error()
  await file.delete()
  return new $gleam.Ok()
}

export async function write(destination, data) {
  try {
    const bits = await Bun.write(destination, data)
    return new $gleam.Ok(bits)
  } catch (error) {
    return new $gleam.Error()
  }
}

export async function writeBytes(destination, data) {
  try {
    const dat = data.rawBuffer
    const bits = await Bun.write(destination, dat)
    return new $gleam.Ok(bits)
  } catch (error) {
    return new $gleam.Error()
  }
}

export async function copy(source, destination) {
  try {
    const bits = await Bun.write(destination, source)
    return new $gleam.Ok(bits)
  } catch (error) {
    return new $gleam.Error()
  }
}
