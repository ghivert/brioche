import brioche/tls
import gleam/dynamic/decode.{type Decoder}
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/string
import gleam/time/timestamp
import gleam/uri

pub type Config {
  Config(
    /// Database server hostname
    host: String,
    /// Database server port number
    port: Int,
    /// Database user for authentication
    user: String,
    /// Database password for authentication
    password: Option(String),
    /// Name of the database to connect to
    database: String,
    /// Maximum time in seconds to wait for connection to become available (alias for idleTimeout)
    idle_timeout: Option(Int),
    /// Maximum time in seconds to wait when establishing a connection
    connection_timeout: Option(Int),
    /// Maximum lifetime in seconds of a connection
    max_lifetime: Option(Int),
    /// Whether to use TLS/SSL for the connection
    ssl: Ssl,
    /// Callback function executed when a connection is established
    onconnect: Option(fn(Connection) -> Nil),
    /// Callback function executed when a connection is closed
    onclose: Option(fn(Connection) -> Nil),
    /// Maximum Int of connections in the pool
    max: Option(Int),
    /// By default values outside i32 range are returned as strings. If this is true, values outside i32 range are returned as BigInts.
    bigint: Option(Bool),
    /// Automatic creation of prepared statements, defaults to true
    prepare: Option(Bool),
    /// Default format.
    default_format: Format,
  )
}

// Connection is #(Bun.SQL, Format).
pub type Connection

pub type Ssl {
  /// Enable SSL connection, and check CA certificate. It is the most secured
  /// option to use SSL and should be always used by default.
  /// Never ignore CA certificate checking _unless you know exactly what you are
  /// doing_.
  SslCustom(tls: tls.Tls)
  /// Enable SSL connection, but don't check CA certificate.
  /// `SslVerified` should always be prioritized upon `SslUnverified`.
  /// As it implies, that option enables SSL, but as it is unverified, the
  /// connection can be unsafe. _Use this option only if you know what you're
  /// doing._ In case `pog` can not find the proper CA certificate, take a look
  /// at the README to get some help to inject the CA certificate in your OS.
  SslEnabled
  /// Disable SSL connection completely. Using this option will let the
  /// connection unsecured, and should be avoided in production environment.
  SslDisabled
}

pub opaque type Query(a) {
  Query(
    sql: String,
    parameters: List(Value),
    format: Option(Format),
    expecting: Decoder(a),
  )
}

pub type Format {
  Dict
  Tuple
}

pub type Value

pub fn default_config() {
  Config(
    host: "127.0.0.1",
    port: 5432,
    user: "postgres",
    password: option.None,
    database: "postgres",
    idle_timeout: option.None,
    connection_timeout: option.None,
    max_lifetime: option.None,
    ssl: SslDisabled,
    onconnect: option.None,
    onclose: option.None,
    max: option.None,
    bigint: option.None,
    prepare: option.None,
    default_format: Tuple,
  )
}

pub fn host(config: Config, host: String) {
  Config(..config, host:)
}

pub fn port(config: Config, port: Int) {
  Config(..config, port:)
}

pub fn user(config: Config, user: String) {
  Config(..config, user:)
}

pub fn password(config: Config, password: Option(String)) {
  Config(..config, password:)
}

pub fn database(config: Config, database: String) {
  Config(..config, database:)
}

pub fn idle_timeout(config: Config, idle_timeout: Int) {
  Config(..config, idle_timeout: option.Some(idle_timeout))
}

pub fn connection_timeout(config: Config, connection_timeout: Int) {
  Config(..config, connection_timeout: option.Some(connection_timeout))
}

pub fn max_lifetime(config: Config, max_lifetime: Int) {
  Config(..config, max_lifetime: option.Some(max_lifetime))
}

pub fn tls(config: Config, tls: tls.Tls) {
  Config(..config, ssl: SslCustom(tls))
}

pub fn onconnect(config: Config, onconnect: fn(Connection) -> Nil) {
  Config(..config, onconnect: option.Some(onconnect))
}

pub fn onclose(config: Config, onclose: fn(Connection) -> Nil) {
  Config(..config, onclose: option.Some(onclose))
}

pub fn max(config: Config, max: Int) {
  Config(..config, max: option.Some(max))
}

pub fn bigint(config: Config, bigint: Bool) {
  Config(..config, bigint: option.Some(bigint))
}

pub fn prepare(config: Config, prepare: Bool) {
  Config(..config, prepare: option.Some(prepare))
}

pub fn default_format(config: Config, default_format: Format) {
  Config(..config, default_format:)
}

pub fn url_config(database_url: String) -> Result(Config, Nil) {
  use uri <- result.then(uri.parse(database_url))
  let uri = case uri.port {
    option.Some(..) -> uri
    option.None -> uri.Uri(..uri, port: option.Some(5432))
  }
  use #(userinfo, host, path, db_port, query) <- result.then(case uri {
    uri.Uri(
      scheme: option.Some(scheme),
      userinfo: option.Some(userinfo),
      host: option.Some(host),
      port: option.Some(db_port),
      path:,
      query:,
      ..,
    ) -> {
      case scheme {
        "postgres" | "postgresql" -> Ok(#(userinfo, host, path, db_port, query))
        _ -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  })
  use #(user, password) <- result.then(extract_user_password(userinfo))
  use ssl <- result.then(extract_ssl_mode(query))
  case string.split(path, "/") {
    ["", database] ->
      Ok(
        Config(
          ..default_config(),
          host:,
          port: db_port,
          database:,
          user:,
          password:,
          ssl:,
        ),
      )
    _ -> Error(Nil)
  }
}

/// Expects `userinfo` as `"username"` or `"username:password"`. Fails otherwise.
fn extract_user_password(
  userinfo: String,
) -> Result(#(String, Option(String)), Nil) {
  case string.split(userinfo, ":") {
    [user] -> Ok(#(user, option.None))
    [user, password] -> Ok(#(user, option.Some(password)))
    _ -> Error(Nil)
  }
}

/// Expects `sslmode` to be `require`, `verify-ca`, `verify-full` or `disable`.
/// If `sslmode` is set, but not one of those value, fails.
/// If `sslmode` is `verify-ca` or `verify-full`, returns `SslVerified`.
/// If `sslmode` is `require`, returns `SslUnverified`.
/// If `sslmode` is unset, returns `SslDisabled`.
fn extract_ssl_mode(query: option.Option(String)) -> Result(Ssl, Nil) {
  case query {
    option.None -> Ok(SslDisabled)
    option.Some(query) -> {
      use query <- result.then(uri.parse_query(query))
      use sslmode <- result.then(list.key_find(query, "sslmode"))
      case sslmode {
        "require" -> Ok(SslEnabled)
        "verify-ca" | "verify-full" -> Ok(SslEnabled)
        "disable" -> Ok(SslDisabled)
        _ -> Error(Nil)
      }
    }
  }
}

@external(javascript, "./sql.ffi.mjs", "connect")
pub fn connect(config: Config) -> Result(Connection, Nil)

pub fn query(sql: String) -> Query(decode.Dynamic) {
  Query(sql:, parameters: [], format: option.None, expecting: decode.dynamic)
}

pub fn parameter(query: Query(a), value: Value) -> Query(a) {
  let parameters = [value, ..query.parameters]
  Query(..query, parameters:)
}

pub fn returning(query: Query(a), decoder: decode.Decoder(b)) -> Query(b) {
  Query(..query, expecting: decoder)
}

pub fn format(query: Query(a), format: Format) -> Query(a) {
  Query(..query, format: option.Some(format))
}

@external(javascript, "./sql.ffi.mjs", "coerce")
pub fn int(int: Int) -> Value

@external(javascript, "./sql.ffi.mjs", "coerce")
pub fn float(float: Float) -> Value

@external(javascript, "./sql.ffi.mjs", "coerce")
pub fn text(text: String) -> Value

@external(javascript, "./sql.ffi.mjs", "coerce")
pub fn bool(bool: Bool) -> Value

@external(javascript, "./sql.ffi.mjs", "nullify")
pub fn null() -> Value

@external(javascript, "./sql.ffi.mjs", "maybeCoerce")
pub fn nullable(value: Option(a), mapper: fn(a) -> Value) -> Value

@external(javascript, "./sql.ffi.mjs", "listCoerce")
pub fn array(value: List(a), mapper: fn(a) -> Value) -> Value

pub fn timestamp(value: timestamp.Timestamp) -> Value {
  let #(s, ns) = timestamp.to_unix_seconds_and_nanoseconds(value)
  let ms = ns / 1_000_000
  let ms = { s * 1000 } + ms
  encode_timestamp(ms)
}

@external(javascript, "./sql.ffi.mjs", "encodeTimestamp")
fn encode_timestamp(milliseconds: Int) -> Value

pub fn timestamp_decoder() {
  use content <- decode.then(decode.dynamic)
  case date_to_ints(content) {
    Error(_) -> decode.failure(timestamp.from_unix_seconds(0), "Timestamp")
    Ok(#(seconds, nanoseconds)) -> {
      decode.success({
        timestamp.from_unix_seconds_and_nanoseconds(seconds, nanoseconds)
      })
    }
  }
}

@external(javascript, "./sql.ffi.mjs", "dateToInts")
fn date_to_ints(dynamic: decode.Dynamic) -> Result(#(Int, Int), Nil)

pub fn execute(
  query: Query(a),
  connection: Connection,
) -> Promise(Result(List(a), Nil)) {
  use r <- promise.map(do_run(query, connection))
  use r <- result.map(r)
  list.filter_map(r, decode.run(_, query.expecting))
}

@external(javascript, "./sql.ffi.mjs", "runQuery")
fn do_run(
  query: Query(a),
  connection: Connection,
) -> Promise(Result(List(decode.Dynamic), Nil))

@external(javascript, "./sql.ffi.mjs", "transaction")
pub fn transaction(
  connection: Connection,
  handler: fn(Connection) -> Promise(a),
) -> Promise(a)

@external(javascript, "./sql.ffi.mjs", "savepoint")
pub fn savepoint(
  connection: Connection,
  handler: fn(Connection) -> Promise(Nil),
) -> Promise(Nil)

@external(javascript, "./sql.ffi.mjs", "close")
pub fn disconnect(connection: Connection) -> Promise(Nil)
