import brioche/sql
import gleam/dynamic/decode.{type Decoder}
import gleam/javascript/promise.{type Promise, await}
import gleam/list
import gleam/option.{None, Some}
import gleam/time/timestamp
import gleeunit/should

pub fn url_config_everything_test() {
  let expected =
    sql.default_config()
    |> sql.host("db.test")
    |> sql.port(1234)
    |> sql.database("my_db")
    |> sql.user("u")
    |> sql.password(Some("p"))

  sql.url_config("postgres://u:p@db.test:1234/my_db")
  |> should.equal(Ok(expected))
}

pub fn url_config_alternative_postgres_protocol_test() {
  let expected =
    sql.default_config()
    |> sql.host("db.test")
    |> sql.port(1234)
    |> sql.database("my_db")
    |> sql.user("u")
    |> sql.password(Some("p"))
  sql.url_config("postgresql://u:p@db.test:1234/my_db")
  |> should.equal(Ok(expected))
}

pub fn url_config_not_postgres_protocol_test() {
  sql.url_config("foo://u:p@db.test:1234/my_db")
  |> should.equal(Error(Nil))
}

pub fn url_config_no_password_test() {
  let expected =
    sql.default_config()
    |> sql.host("db.test")
    |> sql.port(1234)
    |> sql.database("my_db")
    |> sql.user("u")
    |> sql.password(None)
  sql.url_config("postgres://u@db.test:1234/my_db")
  |> should.equal(Ok(expected))
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
  |> should.equal(Error(Nil))
}

fn start_default() {
  let assert Ok(db) = sql.connect(default_config())
  db
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
  use returned <- await(sql.query(sql) |> sql.execute(db))
  let assert Ok(returned) = returned
  returned |> should.equal([])
  sql.disconnect(db)
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
  |> await(fn(returned) {
    let assert Ok(returned) = returned
    returned |> should.equal(["bill", "felix"])
    sql.disconnect(db)
  })
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

  use returned <- await({
    sql.query(sql)
    |> sql.returning(decode.at([0], decode.int))
    |> sql.execute(db)
  })
  let assert Ok([id]) = returned

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
  })

  let assert Ok(returned) = returned

  let last_petted =
    timestamp.from_unix_seconds_and_nanoseconds(1_665_401_430, 100_000_000)
  let birthday = timestamp.from_unix_seconds(1_583_280_000)
  returned
  |> should.equal([#(id, "neo", True, ["black"], last_petted, birthday)])

  sql.disconnect(db)
}

pub fn invalid_sql_test() {
  let db = start_default()
  let sql = "select       select"

  use returned <- await(sql.query(sql) |> sql.execute(db))
  let assert Error(Nil) = returned

  // code
  // |> should.equal("42601")
  // name
  // |> should.equal("syntax_error")
  // message
  // |> should.equal("syntax error at or near \"select\"")

  sql.disconnect(db)
}

// pub fn insert_constraint_error_test() {
//   let db = start_default()
//   let sql =
//     "
//     INSERT INTO
//       cats
//     VALUES
//       (900, 'bill', true, ARRAY ['black'], now(), '2020-03-04'),
//       (900, 'felix', false, ARRAY ['black'], now(), '2020-03-05')"

//   let assert Error(sql.ConstraintViolated(message, constraint, detail)) =
//     sql.query(sql) |> sql.execute(db)

//   constraint
//   |> should.equal("cats_pkey")

//   detail
//   |> should.equal("Key (id)=(900) already exists.")

//   message
//   |> should.equal(
//     "duplicate key value violates unique constraint \"cats_pkey\"",
//   )

//   sql.disconnect(db)
// }

// pub fn select_from_unknown_table_test() {
//   let db = start_default()
//   let sql = "SELECT * FROM unknown"

//   let assert Error(sql.PostgresqlError(code, name, message)) =
//     sql.query(sql) |> sql.execute(db)

//   code
//   |> should.equal("42P01")
//   name
//   |> should.equal("undefined_table")
//   message
//   |> should.equal("relation \"unknown\" does not exist")

//   sql.disconnect(db)
// }

// pub fn insert_with_incorrect_type_test() {
//   let db = start_default()
//   let sql =
//     "
//       INSERT INTO
//         cats
//       VALUES
//         (true, true, true, true)"
//   let assert Error(sql.PostgresqlError(code, name, message)) =
//     sql.query(sql) |> sql.execute(db)

//   code
//   |> should.equal("42804")
//   name
//   |> should.equal("datatype_mismatch")
//   message
//   |> should.equal(
//     "column \"id\" is of type integer but expression is of type boolean",
//   )

//   sql.disconnect(db)
// }

// pub fn execute_with_wrong_number_of_arguments_test() {
//   let db = start_default()
//   let sql = "SELECT * FROM cats WHERE id = $1"

//   sql.query(sql)
//   |> sql.execute(db)
//   |> should.equal(Error(sql.UnexpectedArgumentCount(expected: 1, got: 0)))

//   sql.disconnect(db)
// }

fn assert_roundtrip(
  db: Promise(sql.Connection),
  value: a,
  type_name: String,
  encoder: fn(a) -> sql.Value,
  decoder: Decoder(a),
) -> Promise(sql.Connection) {
  use db <- await(db)
  sql.query("select $1::" <> type_name)
  |> sql.parameter(encoder(value))
  |> sql.returning(decode.at([0], decoder))
  |> sql.execute(db)
  |> promise.map(fn(response) {
    response |> should.equal(Ok([value]))
    db
  })
}

pub fn null_test() {
  let db = start_default()
  sql.query("select $1")
  |> sql.parameter(sql.null())
  |> sql.returning(decode.at([0], decode.optional(decode.int)))
  |> sql.execute(db)
  |> await(fn(response) {
    response
    |> should.equal(Ok([None]))
    sql.disconnect(db)
  })
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

// pub fn bytea_test() {
//   start_default()
//   |> promise.resolve
//   |> assert_roundtrip(<<"":utf8>>, "bytea", sql.bytea, decode.bit_array)
//   |> assert_roundtrip(<<"✨":utf8>>, "bytea", sql.bytea, decode.bit_array)
//   |> assert_roundtrip(
//     <<"Hello, Joe!":utf8>>,
//     "bytea",
//     sql.bytea,
//     decode.bit_array,
//   )
//   |> assert_roundtrip(<<1>>, "bytea", sql.bytea, decode.bit_array)
//   |> assert_roundtrip(<<1, 2, 3>>, "bytea", sql.bytea, decode.bit_array)
//   |> promise.await(sql.disconnect)
// }

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
  start_default()
  |> promise.resolve
  |> assert_roundtrip(
    timestamp.from_unix_seconds(1000),
    "timestamp",
    sql.timestamp,
    sql.timestamp_decoder(),
  )
  |> promise.await(sql.disconnect)
}

pub fn nullable_test() {
  let txt = sql.nullable(_, sql.text)
  let int = sql.nullable(_, sql.int)
  start_default()
  |> promise.resolve
  |> assert_roundtrip(
    Some("Hello, Joe"),
    "text",
    txt,
    decode.optional(decode.string),
  )
  |> assert_roundtrip(None, "text", txt, decode.optional(decode.string))
  |> assert_roundtrip(Some(123), "int", int, decode.optional(decode.int))
  |> assert_roundtrip(None, "int", int, decode.optional(decode.int))
  |> promise.await(sql.disconnect)
}

// pub fn expected_argument_type_test() {
//   let db = start_default()

//   sql.query("select $1::int")
//   |> sql.returning(decode.at([0], decode.string))
//   |> sql.parameter(sql.float(1.2))
//   |> sql.execute(db)
//   |> should.equal(Error(sql.UnexpectedArgumentType("int4", "1.2")))

//   sql.disconnect(db)
// }

// pub fn expected_return_type_test() {
//   let db = start_default()
//   sql.query("select 1")
//   |> sql.returning(decode.at([0], decode.string))
//   |> sql.execute(db)
//   |> should.equal(
//     Error(
//       sql.UnexpectedResultType([
//         decode.DecodeError(expected: "String", found: "Int", path: ["0"]),
//       ]),
//     ),
//   )

//   sql.disconnect(db)
// }

// pub fn expected_five_millis_timeout_test() {
//   use <- run_with_timeout(20)
//   let db = start_default()

//   sql.query("select sub.ret from (select pg_sleep(0.05), 'OK' as ret) as sub")
//   |> sql.timeout(5)
//   |> sql.returning(decode.at([0], decode.string))
//   |> sql.execute(db)
//   |> should.equal(Error(sql.QueryTimeout))

//   sql.disconnect(db)
// }

// pub fn expected_ten_millis_no_timeout_test() {
//   use <- run_with_timeout(20)
//   let db = start_default()

//   sql.query("select sub.ret from (select pg_sleep(0.01), 'OK' as ret) as sub")
//   |> sql.timeout(30)
//   |> sql.returning(decode.at([0], decode.string))
//   |> sql.execute(db)
//   |> should.equal(Ok(sql.Returned(1, ["Ok"])))

//   sql.disconnect(db)
// }

// pub fn expected_ten_millis_no_default_timeout_test() {
//   use <- run_with_timeout(20)
//   let db =
//     default_config()
//     |> sql.default_timeout(30)
//     |> sql.connect

//   sql.query("select sub.ret from (select pg_sleep(0.01), 'OK' as ret) as sub")
//   |> sql.returning(decode.at([0], decode.string))
//   |> sql.execute(db)
//   |> should.equal(Ok(sql.Returned(1, ["Ok"])))

//   sql.disconnect(db)
// }

pub fn expected_maps_test() {
  let db =
    sql.Config(..default_config(), default_format: sql.Dict)
    |> sql.connect
    |> should.be_ok

  let sql =
    "
    INSERT INTO
      cats
    VALUES
      (DEFAULT, 'neo', true, ARRAY ['black'], '2022-10-10 11:30:30', '2020-03-04')
    RETURNING
      id"

  use id <- await({
    sql.query(sql)
    |> sql.returning(decode.at(["id"], decode.int))
    |> sql.execute(db)
    |> promise.map(should.be_ok)
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

  returned
  |> should.equal([
    #(
      id,
      "neo",
      True,
      ["black"],
      timestamp.from_unix_seconds(1_665_401_430),
      timestamp.from_unix_seconds(1_583_280_000),
    ),
  ])

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
    |> promise.map(list.first)
    |> promise.map(should.be_ok)
  }

  // A succeeding transaction
  // use #(id1, id2) <- await({
  use #(id1, id2) <- await({
    sql.transaction(db, fn(db) {
      use id1 <- await(insert(db, "one"))
      use id2 <- await(insert(db, "two"))
      promise.resolve(#(id1, id2))
    })
  })

  // An error returning transaction, it gets rolled back
  // let assert Error(sql.TransactionRolledBack("Nah bruv!")) =
  //   sql.transaction(db, fn(db) {
  //     let _id1 = insert(db, "two")
  //     let _id2 = insert(db, "three")
  //     Error("Nah bruv!")
  //   })

  // A crashing transaction, it gets rolled back
  // let _ =
  //   exception.rescue(fn() {
  //     sql.transaction(db, fn(db) {
  //       let _id1 = insert(db, "four")
  //       let _id2 = insert(db, "five")
  //       panic as "testing rollbacks"
  //     })
  //   })

  use returned <- await({
    sql.query("select id from cats order by id")
    |> sql.returning(id_decoder)
    |> sql.execute(db)
  })

  let assert Ok([got1, got2]) = returned
  let assert True = id1 == got1
  let assert True = id2 == got2

  sql.disconnect(db)
}
