import * as bun from 'bun'
import * as $sql from './sql.mjs'
import * as $gleam from '../gleam.mjs'
import { generateTLS } from './tls.ffi.mjs'

export function connect(config) {
  try {
    const sql = new bun.SQL({
      host: config.host[0],
      port: config.port[0],
      user: config.user[0],
      database: config.database[0],
      ssl: generateSSL(config.ssl[0]),
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
    return new $gleam.Error(error)
  }
}

export function generateSSL(ssl) {
  if (!ssl) return
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
      format instanceof $sql.Map
        ? await sql.unsafe(query.sql, parameters)
        : await sql.unsafe(query.sql, parameters).values()
    const rows = await res
    const values = $gleam.List.fromArray(rows)
    return new $gleam.Ok(new $sql.Returned(values, rows.count))
  } catch (error) {
    const gleamError = convertError(error)
    return new $gleam.Error(gleamError)
  }
}

export function byteaify(value) {
  return value.rawBuffer
}

function convertError(error) {
  if (error.constraint) {
    const message = error.message
    const constraint = error.constraint
    const detail = error.detail
    return new $sql.ConstraintViolated(message, constraint, detail)
  }

  const code = error.errno
  const name = $sql.error_code_name(error.errno)[0]
  return new $sql.PostgresqlError(code, name, error.message)
}

export async function transaction(conn, handler) {
  const [connection, format] = conn
  try {
    return await connection.begin(async tx => {
      const result = await handler([tx, format])
      if (result instanceof $gleam.Ok) return result
      const error = new Error()
      error.attached = result[0]
      throw error
    })
  } catch (error) {
    if (error.attached) return new $gleam.Error(error.attached)
    return new $gleam.Error(new $sql.TransactionRolledBack(error.message))
  }
}

export async function savepoint(conn, handler) {
  const [connection, format] = conn
  return await connection.savepoint(async tx => {
    return await handler([tx, format])
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
