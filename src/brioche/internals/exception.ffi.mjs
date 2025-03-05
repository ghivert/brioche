import * as gleam from '../../gleam.mjs'

export async function defer(cleanup, body) {
  try {
    return await body()
  } finally {
    cleanup()
  }
}

export async function rescue(body) {
  try {
    return new gleam.Ok(await body())
  } catch (error) {
    return new gleam.Error(error)
  }
}

export function log(value) {
  console.log(value)
}
