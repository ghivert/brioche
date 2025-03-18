import * as bun from 'bun'
import * as $sql from './sql.mjs'
import * as $gleam from '../gleam.mjs'
import { generateTLS } from './tls.ffi.mjs'

export function connect(config) {
  try {
    const sql = new bun.SQL({
      host: config.host,
      port: config.port,
      user: config.user,
      database: config.database,
      ssl: generateSSL(config.ssl),
      password: config.password[0],
      idle_timeout: config.idle_timeout[0],
      connection_timeout: config.connection_timeout[0],
      max_lifetime: config.max_lifetime[0],
      onconnect: onconnect(config.onconnect[0], config.default_format),
      default_format: config.default_format[0],
      onclose: onconnect(config.onclose[0], config.default_format),
      default_format: config.default_format[0],
      max: config.max[0],
      bigint: config.bigint[0],
      prepare: config.prepare[0],
    })
    return new $gleam.Ok([sql, config.default_format])
  } catch (error) {
    return new $gleam.Error()
  }
}

export function generateSSL(ssl) {
  if (ssl instanceof $sql.SslCustom) return generateTLS(ssl.tls)
  if (ssl instanceof $sql.SslEnabled) return true
  return false
}

function onconnect(handler, default_format) {
  if (!handler) return undefined
  return function (sql) {
    return handler([sql, default_format])
  }
}

export function coerce(a) {
  return a
}

export function maybeCoerce(a, b) {
  if (a[0]) return b(a[0])
  return null
}

export function listCoerce(a, b) {
  return a.toArray().map(b)
}

export function nullify() {
  return null
}

export async function runQuery(query, conn) {
  try {
    const [sql, format] = conn
    const parameters = query.parameters.toArray().reverse()
    const res =
      format instanceof $sql.Dict
        ? await sql.unsafe(query.sql, parameters)
        : await sql.unsafe(query.sql, parameters).values()
    const rows = await res
    if (!Array.isArray(rows)) return new $gleam.Error()
    const values = $gleam.List.fromArray(rows)
    return new $gleam.Ok(values)
  } catch (error) {
    console.log(error.constructor)
    console.log(error)
    return new $gleam.Error()
  }
}

export async function transaction(conn, handler) {
  const [connection, format] = conn
  return await connection.begin(async tx => {
    return handler([tx, format])
  })
}

export async function savepoint(conn, handler) {
  const [connection, format] = conn
  return await connection.savepoint(async tx => {
    return handler([tx, format])
  })
}

export function close(conn) {
  return conn[0].close()
}

export function dateToInts(date) {
  if (!(date instanceof Date)) return new $gleam.Error()
  const value = date.valueOf()
  const milliseconds = value % 1000
  const nanoseconds = milliseconds * 1000000
  const seconds = (value - milliseconds) / 1000
  return new $gleam.Ok([seconds, nanoseconds])
}

export function encodeTimestamp(ms) {
  return new Date(ms)
}
