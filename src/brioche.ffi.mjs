import * as gleam from './gleam.mjs'
import * as $brioche from './brioche.mjs'

export const version = () => Bun.version
export const revision = () => Bun.revision
export const mainScript = () => Bun.main
export const sleep = ms => Bun.sleep(ms)
export const sleepSync = ms => Bun.sleepSync(ms)
export const randomUUIDV7 = () => Bun.randomUUIDv7()
export const openInEditor = file => Bun.openInEditor(file)
export const stringWidth = str => Bun.stringWidth(str)
export const inspect = content => Bun.inspect(content)
export const nanoseconds = () => Bun.nanoseconds()

export function which(bin) {
  const where = Bun.which(bin)
  if (!where) return new gleam.Error()
  return new gleam.Ok(where)
}

export function gzipSync(content) {
  try {
    const result = Bun.gzipSync(content.rawBuffer)
    const buffer = gleam.toBitArray(result)
    return new gleam.Ok(buffer)
  } catch (error) {
    return new gleam.Error()
  }
}

export function gunzipSync(content) {
  try {
    const result = Bun.gunzipSync(content.rawBuffer)
    const buffer = gleam.toBitArray(result)
    return new gleam.Ok(buffer)
  } catch (error) {
    return new gleam.Error()
  }
}

export function deflateSync(content) {
  try {
    const result = Bun.deflateSync(content.rawBuffer)
    const buffer = gleam.toBitArray(result)
    return new gleam.Ok(buffer)
  } catch (error) {
    return new gleam.Error()
  }
}

export function inflateSync(content) {
  try {
    const result = Bun.inflateSync(content.rawBuffer)
    const buffer = gleam.toBitArray(result)
    return new gleam.Ok(buffer)
  } catch (error) {
    throw new gleam.Error()
  }
}

export function peek(prom) {
  switch (Bun.peek.status(prom)) {
    case 'fulfilled':
      return new gleam.Ok(Bun.peek(prom))
    case 'pending':
      return new gleam.Error()
    case 'rejected':
      return new gleam.Error()
  }
}

export function peekStatus(prom) {
  switch (Bun.peek.status(prom)) {
    case 'fulfilled':
      return new $brioche.Fulfilled()
    case 'pending':
      return new $brioche.Pending()
    case 'rejected':
      return new $brioche.Rejected()
  }
}
