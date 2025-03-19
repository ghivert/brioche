import brioche/sql
import gleam/dynamic/decode.{type Decoder}
import gleam/javascript/promise.{type Promise, await}
import gleam/list
import gleam/option.{None, Some}
import gleam/time/timestamp
import gleeunit/should

fn rows(ret: sql.Returned(a)) {
  ret.rows
}

pub fn url_config_everything_test() {
  sql.url_config("postgres://u:p@db.test:1234/my_db")
  |> should.be_ok
  |> should.equal({
    sql.default_config()
    |> sql.host("db.test")
    |> sql.port(1234)
    |> sql.database("my_db")
    |> sql.user("u")
    |> sql.password(Some("p"))
  })
}

pub fn url_config_alternative_postgres_protocol_test() {
  sql.url_config("postgresql://u:p@db.test:1234/my_db")
  |> should.be_ok
  |> should.equal({
    sql.default_config()
    |> sql.host("db.test")
    |> sql.port(1234)
    |> sql.database("my_db")
    |> sql.user("u")
    |> sql.password(Some("p"))
  })
}

pub fn url_config_not_postgres_protocol_test() {
  sql.url_config("foo://u:p@db.test:1234/my_db")
  |> should.be_error
  |> should.equal(Nil)
}

pub fn url_config_no_password_test() {
  sql.url_config("postgres://u@db.test:1234/my_db")
  |> should.be_ok
  |> should.equal({
    sql.default_config()
    |> sql.host("db.test")
    |> sql.port(1234)
    |> sql.database("my_db")
    |> sql.user("u")
    |> sql.password(None)
  })
}

pub fn url_config_no_port_test() {
  let expected =
    sql.default_config()
    |> sql.host("db.test")
    |> sql.port(5432)
    |> sql.database("my_db")
    |> sql.user("u")
    |> sql.password(None)
  sql.url_config("postgres://u@db.test/my_db")
  |> should.equal(Ok(expected))
}

pub fn url_config_path_slash_test() {
  sql.url_config("postgres://u:p@db.test:1234/my_db/foo")
  |> should.be_error
  |> should.equal(Nil)
}

fn start_default() {
  sql.connect(default_config())
  |> should.be_ok
}

fn default_config() {
  sql.Config(
    ..sql.default_config(),
    database: "gleam_pog_test",
    password: Some("postgres"),
  )
}

pub fn inserting_new_rows_test() {
  let db = start_default()
  let sql =
    "
  INSERT INTO
    cats
  VALUES
    (DEFAULT, 'bill', true, ARRAY ['black'], now(), '2020-03-04'),
    (DEFAULT, 'felix', false, ARRAY ['grey'], now(), '2020-03-05')"
  sql.query(sql)
  |> sql.execute(db)
  |> promise.map(should.be_ok)
  |> promise.map(rows)
  |> promise.map(should.equal(_, []))
  |> promise.await(fn(_) { sql.disconnect(db) })
}

pub fn inserting_new_rows_and_returning_test() {
  let db = start_default()
  let sql =
    "
  INSERT INTO
    cats
  VALUES
    (DEFAULT, 'bill', true, ARRAY ['black'], now(), '2020-03-04'),
    (DEFAULT, 'felix', false, ARRAY ['grey'], now(), '2020-03-05')
  RETURNING
    name"
  sql.query(sql)
  |> sql.returning(decode.at([0], decode.string))
  |> sql.execute(db)
  |> promise.map(should.be_ok)
  |> promise.map(rows)
  |> promise.map(should.equal(_, ["bill", "felix"]))
  |> promise.await(fn(_) { sql.disconnect(db) })
}

pub fn selecting_rows_test() {
  let db = start_default()
  let sql =
    "
    INSERT INTO
      cats
    VALUES
      (DEFAULT, 'neo', true, ARRAY ['black'], '2022-10-10 11:30:30.1', '2020-03-04')
    RETURNING
      id"

  use id <- await({
    sql.query(sql)
    |> sql.returning(decode.at([0], decode.int))
    |> sql.execute(db)
    |> promise.map(should.be_ok)
    |> promise.map(rows)
    |> promise.map(list.first)
    |> promise.map(should.be_ok)
  })

  use returned <- await({
    sql.query("SELECT * FROM cats WHERE id = $1")
    |> sql.parameter(sql.int(id))
    |> sql.returning({
      use x0 <- decode.field(0, decode.int)
      use x1 <- decode.field(1, decode.string)
      use x2 <- decode.field(2, decode.bool)
      use x3 <- decode.field(3, decode.list(decode.string))
      use x4 <- decode.field(4, sql.timestamp_decoder())
      use x5 <- decode.field(5, sql.timestamp_decoder())
      decode.success(#(x0, x1, x2, x3, x4, x5))
    })
    |> sql.execute(db)
    |> promise.map(should.be_ok)
  })

  let last_petted =
    timestamp.from_unix_seconds_and_nanoseconds(1_665_401_430, 100_000_000)
  let birthday = timestamp.from_unix_seconds(1_583_280_000)
  returned.rows
  |> should.equal([#(id, "neo", True, ["black"], last_petted, birthday)])

  sql.disconnect(db)
}

pub fn invalid_sql_test() {
  let db = start_default()
  let sql = "select       select"
  sql.query(sql)
  |> sql.execute(db)
  |> promise.map(should.be_error)
  |> promise.map(fn(error) {
    let assert sql.PostgresqlError(code:, name:, message:) = error
    code |> should.equal("42601")
    name |> should.equal("syntax_error")
    message |> should.equal("syntax error at or near \"select\"")
  })
  |> promise.await(fn(_) { sql.disconnect(db) })
}

pub fn insert_constraint_error_test() {
  let db = start_default()
  "INSERT INTO
    cats
  VALUES
    (900, 'bill', true, ARRAY ['black'], now(), '2020-03-04'),
    (900, 'felix', false, ARRAY ['black'], now(), '2020-03-05')"
  |> sql.query
  |> sql.execute(db)
  |> promise.map(should.be_error)
  |> promise.map(fn(error) {
    let assert sql.ConstraintViolated(message, constraint, detail) = error
    constraint |> should.equal("cats_pkey")
    detail |> should.equal("Key (id)=(900) already exists.")
    message
    |> should.equal(
      "duplicate key value violates unique constraint \"cats_pkey\"",
    )
  })
  |> promise.await(fn(_) { sql.disconnect(db) })
}

pub fn select_from_unknown_table_test() {
  let db = start_default()
  let sql = "SELECT * FROM unknown"

  sql.query(sql)
  |> sql.execute(db)
  |> promise.map(should.be_error)
  |> promise.map(fn(error) {
    let assert sql.PostgresqlError(code, name, message) = error
    code |> should.equal("42P01")
    name |> should.equal("undefined_table")
    message |> should.equal("relation \"unknown\" does not exist")
  })
  |> promise.await(fn(_) { sql.disconnect(db) })
}

pub fn insert_with_incorrect_type_test() {
  let db = start_default()
  "INSERT INTO
    cats
  VALUES
    (true, true, true, true)"
  |> sql.query
  |> sql.execute(db)
  |> promise.map(should.be_error)
  |> promise.map(fn(error) {
    let assert sql.PostgresqlError(code, name, message) = error
    code |> should.equal("42804")
    name |> should.equal("datatype_mismatch")
    message
    |> should.equal(
      "column \"id\" is of type integer but expression is of type boolean",
    )
  })
  |> promise.await(fn(_) { sql.disconnect(db) })
}

pub fn execute_with_wrong_number_of_arguments_test() {
  let db = start_default()
  "SELECT * FROM cats WHERE id = $1"
  |> sql.query
  |> sql.execute(db)
  |> promise.map(should.be_error)
  |> promise.map(fn(error) {
    let assert sql.PostgresqlError(code, name, message) = error
    code |> should.equal("42P02")
    name |> should.equal("undefined_parameter")
    message |> should.equal("there is no parameter $1")
  })
  |> promise.await(fn(_) { sql.disconnect(db) })
}

fn assert_roundtrip(
  db: Promise(sql.Connection),
  value: a,
  type_name: String,
  encoder: fn(a) -> sql.Value,
  decoder: Decoder(a),
) -> Promise(sql.Connection) {
  use db <- await(db)
  use result <- await({
    sql.query("select $1::" <> type_name)
    |> sql.parameter(encoder(value))
    |> sql.returning(decode.at([0], decoder))
    |> sql.execute(db)
  })
  result
  |> should.be_ok
  |> rows
  |> should.equal([value])
  promise.resolve(db)
}

pub fn null_test() {
  let db = start_default()
  use response <- await({
    sql.query("select $1")
    |> sql.parameter(sql.null())
    |> sql.returning(decode.at([0], decode.optional(decode.int)))
    |> sql.execute(db)
  })
  response
  |> should.be_ok
  |> rows
  |> should.equal([None])
  sql.disconnect(db)
}

pub fn bool_test() {
  start_default()
  |> promise.resolve
  |> assert_roundtrip(True, "bool", sql.bool, decode.bool)
  |> assert_roundtrip(False, "bool", sql.bool, decode.bool)
  |> promise.await(sql.disconnect)
}

pub fn int_test() {
  start_default()
  |> promise.resolve
  |> assert_roundtrip(0, "int", sql.int, decode.int)
  |> assert_roundtrip(1, "int", sql.int, decode.int)
  |> assert_roundtrip(2, "int", sql.int, decode.int)
  |> assert_roundtrip(3, "int", sql.int, decode.int)
  |> assert_roundtrip(4, "int", sql.int, decode.int)
  |> assert_roundtrip(5, "int", sql.int, decode.int)
  |> assert_roundtrip(-0, "int", sql.int, decode.int)
  |> assert_roundtrip(-1, "int", sql.int, decode.int)
  |> assert_roundtrip(-2, "int", sql.int, decode.int)
  |> assert_roundtrip(-3, "int", sql.int, decode.int)
  |> assert_roundtrip(-4, "int", sql.int, decode.int)
  |> assert_roundtrip(-5, "int", sql.int, decode.int)
  |> assert_roundtrip(10_000_000, "int", sql.int, decode.int)
  |> promise.await(sql.disconnect)
}

pub fn float_test() {
  start_default()
  |> promise.resolve
  |> assert_roundtrip(0.123, "float", sql.float, decode.float)
  |> assert_roundtrip(1.123, "float", sql.float, decode.float)
  |> assert_roundtrip(2.123, "float", sql.float, decode.float)
  |> assert_roundtrip(3.123, "float", sql.float, decode.float)
  |> assert_roundtrip(4.123, "float", sql.float, decode.float)
  |> assert_roundtrip(5.123, "float", sql.float, decode.float)
  |> assert_roundtrip(-0.654, "float", sql.float, decode.float)
  |> assert_roundtrip(-1.654, "float", sql.float, decode.float)
  |> assert_roundtrip(-2.654, "float", sql.float, decode.float)
  |> assert_roundtrip(-3.654, "float", sql.float, decode.float)
  |> assert_roundtrip(-4.654, "float", sql.float, decode.float)
  |> assert_roundtrip(-5.654, "float", sql.float, decode.float)
  |> assert_roundtrip(10_000_000.0, "float", sql.float, decode.float)
  |> promise.await(sql.disconnect)
}

pub fn text_test() {
  start_default()
  |> promise.resolve
  |> assert_roundtrip("", "text", sql.text, decode.string)
  |> assert_roundtrip("✨", "text", sql.text, decode.string)
  |> assert_roundtrip("Hello, Joe!", "text", sql.text, decode.string)
  |> promise.await(sql.disconnect)
}

pub fn bytea_test() {
  let hi = <<"Hello, Joe!":utf8>>
  start_default()
  |> promise.resolve
  |> assert_roundtrip(<<"":utf8>>, "bytea", sql.bytea, decode.bit_array)
  |> assert_roundtrip(<<"✨":utf8>>, "bytea", sql.bytea, decode.bit_array)
  |> assert_roundtrip(hi, "bytea", sql.bytea, decode.bit_array)
  |> assert_roundtrip(<<1>>, "bytea", sql.bytea, decode.bit_array)
  |> assert_roundtrip(<<1, 2, 3>>, "bytea", sql.bytea, decode.bit_array)
  |> promise.await(sql.disconnect)
}

// pub fn array_test() {
//   let decoder = decode.list(decode.string)
//   start_default()
//   |> promise.resolve
//   |> assert_roundtrip(["black"], "text[]", sql.array(_, sql.text), decoder)
//   |> assert_roundtrip(["gray"], "text[]", sql.array(_, sql.text), decoder)
//   |> assert_roundtrip(["g", "b"], "text[]", sql.array(_, sql.text), decoder)
//   |> assert_roundtrip(
//     [1, 2, 3],
//     "integer[]",
//     sql.array(_, sql.int),
//     decode.list(decode.int),
//   )
//   |> promise.await(sql.disconnect)
// }

pub fn datetime_test() {
  let s = timestamp.from_unix_seconds(1000)
  start_default()
  |> promise.resolve
  |> assert_roundtrip(s, "timestamp", sql.timestamp, sql.timestamp_decoder())
  |> promise.await(sql.disconnect)
}

pub fn nullable_test() {
  let txt = sql.nullable(_, sql.text)
  let int = sql.nullable(_, sql.int)
  let hello = Some("Hello, Joe")
  start_default()
  |> promise.resolve
  |> assert_roundtrip(hello, "text", txt, decode.optional(decode.string))
  |> assert_roundtrip(None, "text", txt, decode.optional(decode.string))
  |> assert_roundtrip(Some(123), "int", int, decode.optional(decode.int))
  |> assert_roundtrip(None, "int", int, decode.optional(decode.int))
  |> promise.await(sql.disconnect)
}

pub fn expected_argument_type_test() {
  let db = start_default()
  sql.query("select $1::int")
  |> sql.returning(decode.at([0], decode.string))
  |> sql.parameter(sql.text("1.2"))
  |> sql.execute(db)
  |> promise.map(should.be_error)
  |> promise.map(fn(error) {
    let assert sql.PostgresqlError(code, name, message) = error
    code |> should.equal("22P02")
    name |> should.equal("invalid_text_representation")
    message |> should.equal("invalid input syntax for type integer: \"1.2\"")
  })
  |> promise.await(fn(_) { sql.disconnect(db) })
}

pub fn expected_return_type_test() {
  let db = start_default()
  sql.query("select 1")
  |> sql.returning(decode.at([0], decode.string))
  |> sql.execute(db)
  |> promise.map(should.be_error)
  |> promise.map(fn(error) {
    [decode.DecodeError(expected: "String", found: "Int", path: ["0"])]
    |> sql.UnexpectedResultType
    |> should.equal(error, _)
  })
  |> promise.await(fn(_) { sql.disconnect(db) })
}

pub fn expected_maps_test() {
  let db =
    default_config()
    |> sql.default_format(sql.Map)
    |> sql.connect
    |> should.be_ok

  use id <- await({
    "INSERT INTO
      cats
    VALUES
      (DEFAULT, 'neo', true, ARRAY ['black'], '2022-10-10 11:30:30', '2020-03-04')
    RETURNING
      id"
    |> sql.query
    |> sql.returning(decode.at(["id"], decode.int))
    |> sql.execute(db)
    |> promise.map(should.be_ok)
    |> promise.map(rows)
    |> promise.map(list.first)
    |> promise.map(should.be_ok)
  })

  use returned <- await({
    sql.query("SELECT * FROM cats WHERE id = $1")
    |> sql.parameter(sql.int(id))
    |> sql.returning({
      use id <- decode.field("id", decode.int)
      use name <- decode.field("name", decode.string)
      use is_cute <- decode.field("is_cute", decode.bool)
      use colors <- decode.field("colors", decode.list(decode.string))
      use last_petted_at <- decode.field(
        "last_petted_at",
        sql.timestamp_decoder(),
      )
      use birthday <- decode.field("birthday", sql.timestamp_decoder())
      decode.success(#(id, name, is_cute, colors, last_petted_at, birthday))
    })
    |> sql.execute(db)
    |> promise.map(should.be_ok)
  })

  let petted = timestamp.from_unix_seconds(1_665_401_430)
  let birthday = timestamp.from_unix_seconds(1_583_280_000)
  returned.rows
  |> should.equal([#(id, "neo", True, ["black"], petted, birthday)])

  sql.disconnect(db)
}

pub fn transaction_commit_test() {
  let db = start_default()
  let id_decoder = decode.at([0], decode.int)
  use _ <- await({
    sql.query("truncate table cats")
    |> sql.execute(db)
    |> promise.map(should.be_ok)
  })

  let insert = fn(db, name) {
    let sql = "
  INSERT INTO
    cats
  VALUES
    (DEFAULT, '" <> name <> "', true, ARRAY ['black'], now(), '2020-03-04')
  RETURNING id"
    sql.query(sql)
    |> sql.returning(id_decoder)
    |> sql.execute(db)
    |> promise.map(should.be_ok)
    |> promise.map(rows)
    |> promise.map(list.first)
    |> promise.map(should.be_ok)
  }

  // A succeeding transaction
  // use #(id1, id2) <- await({
  use #(id1, id2) <- await({
    sql.transaction(db, fn(db) {
      use id1 <- await(insert(db, "one"))
      use id2 <- await(insert(db, "two"))
      promise.resolve(Ok(#(id1, id2)))
    })
    |> promise.map(should.be_ok)
  })

  // An error returning transaction, it gets rolled back
  use result <- await({
    sql.transaction(db, fn(db) {
      use _id1 <- await(insert(db, "two"))
      use _id2 <- await(insert(db, "three"))
      promise.resolve(Error(sql.TransactionRolledBack("Nah bruv!")))
    })
  })
  result
  |> should.be_error
  |> should.equal(sql.TransactionRolledBack("Nah bruv!"))

  // A crashing transaction, it gets rolled back
  use _ <- await({
    sql.transaction(db, fn(db) {
      let _id1 = insert(db, "four")
      let _id2 = insert(db, "five")
      panic as "testing rollbacks"
    })
  })

  use returned <- await({
    sql.query("select id from cats order by id")
    |> sql.returning(id_decoder)
    |> sql.execute(db)
  })

  let assert Ok(sql.Returned(rows: [got1, got2], ..)) = returned
  let assert True = id1 == got1
  let assert True = id2 == got2

  sql.disconnect(db)
}
