export async function log(value) {
  console.log(await value)
}

export async function defer(cleanup, body) {
  try {
    return await body()
  } finally {
    cleanup()
  }
}

export function coerce(a) {
  return a
}
