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
  Map
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

@external(javascript, "./sql.ffi.mjs", "byteaify")
pub fn bytea(byte_array: BitArray) -> Value

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
) -> Promise(Result(Returned(a), SqlError)) {
  use rows <- promise.map(do_run(query, connection))
  use Returned(rows:, count:) <- result.then(rows)
  list.try_map(rows, decode.run(_, query.expecting))
  |> result.map(fn(rows) { Returned(rows:, count:) })
  |> result.map_error(UnexpectedResultType)
}

@external(javascript, "./sql.ffi.mjs", "runQuery")
fn do_run(
  query: Query(a),
  connection: Connection,
) -> Promise(Result(Returned(decode.Dynamic), SqlError))

@external(javascript, "./sql.ffi.mjs", "transaction")
pub fn transaction(
  connection: Connection,
  handler: fn(Connection) -> Promise(Result(a, SqlError)),
) -> Promise(Result(a, SqlError))

@external(javascript, "./sql.ffi.mjs", "savepoint")
pub fn savepoint(
  connection: Connection,
  handler: fn(Connection) -> Promise(a),
) -> Promise(a)

@external(javascript, "./sql.ffi.mjs", "close")
pub fn disconnect(connection: Connection) -> Promise(Nil)

pub type SqlError {
  /// The query failed as a database constraint would have been violated by the
  /// change.
  ConstraintViolated(message: String, constraint: String, detail: String)
  /// The query failed within the database.
  /// https://www.postgresql.org/docs/current/errcodes-appendix.html
  PostgresqlError(code: String, name: String, message: String)
  /// The rows returned by the database could not be decoded using the supplied
  /// dynamic decoder.
  UnexpectedResultType(List(decode.DecodeError))
  /// The query timed out.
  QueryTimeout
  /// No connection was available to execute the query. This may be due to
  /// invalid connection details such as an invalid username or password.
  ConnectionUnavailable
  /// Transaction Rolled back
  TransactionRolledBack(String)
}

pub type Returned(a) {
  Returned(rows: List(a), count: Int)
}

/// Get the name for a PostgreSQL error code.
///
/// ```gleam
/// > error_code_name("01007")
/// Ok("privilege_not_granted")
/// ```
///
/// https://www.postgresql.org/docs/current/errcodes-appendix.html
pub fn error_code_name(error_code: String) -> Result(String, Nil) {
  case error_code {
    "00000" -> Ok("successful_completion")
    "01000" -> Ok("warning")
    "0100C" -> Ok("dynamic_result_sets_returned")
    "01008" -> Ok("implicit_zero_bit_padding")
    "01003" -> Ok("null_value_eliminated_in_set_function")
    "01007" -> Ok("privilege_not_granted")
    "01006" -> Ok("privilege_not_revoked")
    "01004" -> Ok("string_data_right_truncation")
    "01P01" -> Ok("deprecated_feature")
    "02000" -> Ok("no_data")
    "02001" -> Ok("no_additional_dynamic_result_sets_returned")
    "03000" -> Ok("sql_statement_not_yet_complete")
    "08000" -> Ok("connection_exception")
    "08003" -> Ok("connection_does_not_exist")
    "08006" -> Ok("connection_failure")
    "08001" -> Ok("sqlclient_unable_to_establish_sqlconnection")
    "08004" -> Ok("sqlserver_rejected_establishment_of_sqlconnection")
    "08007" -> Ok("transaction_resolution_unknown")
    "08P01" -> Ok("protocol_violation")
    "09000" -> Ok("triggered_action_exception")
    "0A000" -> Ok("feature_not_supported")
    "0B000" -> Ok("invalid_transaction_initiation")
    "0F000" -> Ok("locator_exception")
    "0F001" -> Ok("invalid_locator_specification")
    "0L000" -> Ok("invalid_grantor")
    "0LP01" -> Ok("invalid_grant_operation")
    "0P000" -> Ok("invalid_role_specification")
    "0Z000" -> Ok("diagnostics_exception")
    "0Z002" -> Ok("stacked_diagnostics_accessed_without_active_handler")
    "20000" -> Ok("case_not_found")
    "21000" -> Ok("cardinality_violation")
    "22000" -> Ok("data_exception")
    "2202E" -> Ok("array_subscript_error")
    "22021" -> Ok("character_not_in_repertoire")
    "22008" -> Ok("datetime_field_overflow")
    "22012" -> Ok("division_by_zero")
    "22005" -> Ok("error_in_assignment")
    "2200B" -> Ok("escape_character_conflict")
    "22022" -> Ok("indicator_overflow")
    "22015" -> Ok("interval_field_overflow")
    "2201E" -> Ok("invalid_argument_for_logarithm")
    "22014" -> Ok("invalid_argument_for_ntile_function")
    "22016" -> Ok("invalid_argument_for_nth_value_function")
    "2201F" -> Ok("invalid_argument_for_power_function")
    "2201G" -> Ok("invalid_argument_for_width_bucket_function")
    "22018" -> Ok("invalid_character_value_for_cast")
    "22007" -> Ok("invalid_datetime_format")
    "22019" -> Ok("invalid_escape_character")
    "2200D" -> Ok("invalid_escape_octet")
    "22025" -> Ok("invalid_escape_sequence")
    "22P06" -> Ok("nonstandard_use_of_escape_character")
    "22010" -> Ok("invalid_indicator_parameter_value")
    "22023" -> Ok("invalid_parameter_value")
    "22013" -> Ok("invalid_preceding_or_following_size")
    "2201B" -> Ok("invalid_regular_expression")
    "2201W" -> Ok("invalid_row_count_in_limit_clause")
    "2201X" -> Ok("invalid_row_count_in_result_offset_clause")
    "2202H" -> Ok("invalid_tablesample_argument")
    "2202G" -> Ok("invalid_tablesample_repeat")
    "22009" -> Ok("invalid_time_zone_displacement_value")
    "2200C" -> Ok("invalid_use_of_escape_character")
    "2200G" -> Ok("most_specific_type_mismatch")
    "22004" -> Ok("null_value_not_allowed")
    "22002" -> Ok("null_value_no_indicator_parameter")
    "22003" -> Ok("numeric_value_out_of_range")
    "2200H" -> Ok("sequence_generator_limit_exceeded")
    "22026" -> Ok("string_data_length_mismatch")
    "22001" -> Ok("string_data_right_truncation")
    "22011" -> Ok("substring_error")
    "22027" -> Ok("trim_error")
    "22024" -> Ok("unterminated_c_string")
    "2200F" -> Ok("zero_length_character_string")
    "22P01" -> Ok("floating_point_exception")
    "22P02" -> Ok("invalid_text_representation")
    "22P03" -> Ok("invalid_binary_representation")
    "22P04" -> Ok("bad_copy_file_format")
    "22P05" -> Ok("untranslatable_character")
    "2200L" -> Ok("not_an_xml_document")
    "2200M" -> Ok("invalid_xml_document")
    "2200N" -> Ok("invalid_xml_content")
    "2200S" -> Ok("invalid_xml_comment")
    "2200T" -> Ok("invalid_xml_processing_instruction")
    "22030" -> Ok("duplicate_json_object_key_value")
    "22031" -> Ok("invalid_argument_for_sql_json_datetime_function")
    "22032" -> Ok("invalid_json_text")
    "22033" -> Ok("invalid_sql_json_subscript")
    "22034" -> Ok("more_than_one_sql_json_item")
    "22035" -> Ok("no_sql_json_item")
    "22036" -> Ok("non_numeric_sql_json_item")
    "22037" -> Ok("non_unique_keys_in_a_json_object")
    "22038" -> Ok("singleton_sql_json_item_required")
    "22039" -> Ok("sql_json_array_not_found")
    "2203A" -> Ok("sql_json_member_not_found")
    "2203B" -> Ok("sql_json_number_not_found")
    "2203C" -> Ok("sql_json_object_not_found")
    "2203D" -> Ok("too_many_json_array_elements")
    "2203E" -> Ok("too_many_json_object_members")
    "2203F" -> Ok("sql_json_scalar_required")
    "23000" -> Ok("integrity_constraint_violation")
    "23001" -> Ok("restrict_violation")
    "23502" -> Ok("not_null_violation")
    "23503" -> Ok("foreign_key_violation")
    "23505" -> Ok("unique_violation")
    "23514" -> Ok("check_violation")
    "23P01" -> Ok("exclusion_violation")
    "24000" -> Ok("invalid_cursor_state")
    "25000" -> Ok("invalid_transaction_state")
    "25001" -> Ok("active_sql_transaction")
    "25002" -> Ok("branch_transaction_already_active")
    "25008" -> Ok("held_cursor_requires_same_isolation_level")
    "25003" -> Ok("inappropriate_access_mode_for_branch_transaction")
    "25004" -> Ok("inappropriate_isolation_level_for_branch_transaction")
    "25005" -> Ok("no_active_sql_transaction_for_branch_transaction")
    "25006" -> Ok("read_only_sql_transaction")
    "25007" -> Ok("schema_and_data_statement_mixing_not_supported")
    "25P01" -> Ok("no_active_sql_transaction")
    "25P02" -> Ok("in_failed_sql_transaction")
    "25P03" -> Ok("idle_in_transaction_session_timeout")
    "26000" -> Ok("invalid_sql_statement_name")
    "27000" -> Ok("triggered_data_change_violation")
    "28000" -> Ok("invalid_authorization_specification")
    "28P01" -> Ok("invalid_password")
    "2B000" -> Ok("dependent_privilege_descriptors_still_exist")
    "2BP01" -> Ok("dependent_objects_still_exist")
    "2D000" -> Ok("invalid_transaction_termination")
    "2F000" -> Ok("sql_routine_exception")
    "2F005" -> Ok("function_executed_no_return_statement")
    "2F002" -> Ok("modifying_sql_data_not_permitted")
    "2F003" -> Ok("prohibited_sql_statement_attempted")
    "2F004" -> Ok("reading_sql_data_not_permitted")
    "34000" -> Ok("invalid_cursor_name")
    "38000" -> Ok("external_routine_exception")
    "38001" -> Ok("containing_sql_not_permitted")
    "38002" -> Ok("modifying_sql_data_not_permitted")
    "38003" -> Ok("prohibited_sql_statement_attempted")
    "38004" -> Ok("reading_sql_data_not_permitted")
    "39000" -> Ok("external_routine_invocation_exception")
    "39001" -> Ok("invalid_sqlstate_returned")
    "39004" -> Ok("null_value_not_allowed")
    "39P01" -> Ok("trigger_protocol_violated")
    "39P02" -> Ok("srf_protocol_violated")
    "39P03" -> Ok("event_trigger_protocol_violated")
    "3B000" -> Ok("savepoint_exception")
    "3B001" -> Ok("invalid_savepoint_specification")
    "3D000" -> Ok("invalid_catalog_name")
    "3F000" -> Ok("invalid_schema_name")
    "40000" -> Ok("transaction_rollback")
    "40002" -> Ok("transaction_integrity_constraint_violation")
    "40001" -> Ok("serialization_failure")
    "40003" -> Ok("statement_completion_unknown")
    "40P01" -> Ok("deadlock_detected")
    "42000" -> Ok("syntax_error_or_access_rule_violation")
    "42601" -> Ok("syntax_error")
    "42501" -> Ok("insufficient_privilege")
    "42846" -> Ok("cannot_coerce")
    "42803" -> Ok("grouping_error")
    "42P20" -> Ok("windowing_error")
    "42P19" -> Ok("invalid_recursion")
    "42830" -> Ok("invalid_foreign_key")
    "42602" -> Ok("invalid_name")
    "42622" -> Ok("name_too_long")
    "42939" -> Ok("reserved_name")
    "42804" -> Ok("datatype_mismatch")
    "42P18" -> Ok("indeterminate_datatype")
    "42P21" -> Ok("collation_mismatch")
    "42P22" -> Ok("indeterminate_collation")
    "42809" -> Ok("wrong_object_type")
    "428C9" -> Ok("generated_always")
    "42703" -> Ok("undefined_column")
    "42883" -> Ok("undefined_function")
    "42P01" -> Ok("undefined_table")
    "42P02" -> Ok("undefined_parameter")
    "42704" -> Ok("undefined_object")
    "42701" -> Ok("duplicate_column")
    "42P03" -> Ok("duplicate_cursor")
    "42P04" -> Ok("duplicate_database")
    "42723" -> Ok("duplicate_function")
    "42P05" -> Ok("duplicate_prepared_statement")
    "42P06" -> Ok("duplicate_schema")
    "42P07" -> Ok("duplicate_table")
    "42712" -> Ok("duplicate_alias")
    "42710" -> Ok("duplicate_object")
    "42702" -> Ok("ambiguous_column")
    "42725" -> Ok("ambiguous_function")
    "42P08" -> Ok("ambiguous_parameter")
    "42P09" -> Ok("ambiguous_alias")
    "42P10" -> Ok("invalid_column_reference")
    "42611" -> Ok("invalid_column_definition")
    "42P11" -> Ok("invalid_cursor_definition")
    "42P12" -> Ok("invalid_database_definition")
    "42P13" -> Ok("invalid_function_definition")
    "42P14" -> Ok("invalid_prepared_statement_definition")
    "42P15" -> Ok("invalid_schema_definition")
    "42P16" -> Ok("invalid_table_definition")
    "42P17" -> Ok("invalid_object_definition")
    "44000" -> Ok("with_check_option_violation")
    "53000" -> Ok("insufficient_resources")
    "53100" -> Ok("disk_full")
    "53200" -> Ok("out_of_memory")
    "53300" -> Ok("too_many_connections")
    "53400" -> Ok("configuration_limit_exceeded")
    "54000" -> Ok("program_limit_exceeded")
    "54001" -> Ok("statement_too_complex")
    "54011" -> Ok("too_many_columns")
    "54023" -> Ok("too_many_arguments")
    "55000" -> Ok("object_not_in_prerequisite_state")
    "55006" -> Ok("object_in_use")
    "55P02" -> Ok("cant_change_runtime_param")
    "55P03" -> Ok("lock_not_available")
    "55P04" -> Ok("unsafe_new_enum_value_usage")
    "57000" -> Ok("operator_intervention")
    "57014" -> Ok("query_canceled")
    "57P01" -> Ok("admin_shutdown")
    "57P02" -> Ok("crash_shutdown")
    "57P03" -> Ok("cannot_connect_now")
    "57P04" -> Ok("database_dropped")
    "57P05" -> Ok("idle_session_timeout")
    "58000" -> Ok("system_error")
    "58030" -> Ok("io_error")
    "58P01" -> Ok("undefined_file")
    "58P02" -> Ok("duplicate_file")
    "72000" -> Ok("snapshot_too_old")
    "F0000" -> Ok("config_file_error")
    "F0001" -> Ok("lock_file_exists")
    "HV000" -> Ok("fdw_error")
    "HV005" -> Ok("fdw_column_name_not_found")
    "HV002" -> Ok("fdw_dynamic_parameter_value_needed")
    "HV010" -> Ok("fdw_function_sequence_error")
    "HV021" -> Ok("fdw_inconsistent_descriptor_information")
    "HV024" -> Ok("fdw_invalid_attribute_value")
    "HV007" -> Ok("fdw_invalid_column_name")
    "HV008" -> Ok("fdw_invalid_column_number")
    "HV004" -> Ok("fdw_invalid_data_type")
    "HV006" -> Ok("fdw_invalid_data_type_descriptors")
    "HV091" -> Ok("fdw_invalid_descriptor_field_identifier")
    "HV00B" -> Ok("fdw_invalid_handle")
    "HV00C" -> Ok("fdw_invalid_option_index")
    "HV00D" -> Ok("fdw_invalid_option_name")
    "HV090" -> Ok("fdw_invalid_string_length_or_buffer_length")
    "HV00A" -> Ok("fdw_invalid_string_format")
    "HV009" -> Ok("fdw_invalid_use_of_null_pointer")
    "HV014" -> Ok("fdw_too_many_handles")
    "HV001" -> Ok("fdw_out_of_memory")
    "HV00P" -> Ok("fdw_no_schemas")
    "HV00J" -> Ok("fdw_option_name_not_found")
    "HV00K" -> Ok("fdw_reply_handle")
    "HV00Q" -> Ok("fdw_schema_not_found")
    "HV00R" -> Ok("fdw_table_not_found")
    "HV00L" -> Ok("fdw_unable_to_create_execution")
    "HV00M" -> Ok("fdw_unable_to_create_reply")
    "HV00N" -> Ok("fdw_unable_to_establish_connection")
    "P0000" -> Ok("plpgsql_error")
    "P0001" -> Ok("raise_exception")
    "P0002" -> Ok("no_data_found")
    "P0003" -> Ok("too_many_rows")
    "P0004" -> Ok("assert_failure")
    "XX000" -> Ok("internal_error")
    "XX001" -> Ok("data_corrupted")
    "XX002" -> Ok("index_corrupted")
    _ -> Error(Nil)
  }
}
