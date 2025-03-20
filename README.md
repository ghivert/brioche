# Brioche

Brioche provides bindings over Bun API.

## Getting Started

You need Bun & Gleam to get started.

### Installing Brioche

```sh
gleam add brioche
```

When working with JavaScript, it's advised to install the common toolbox of
JavaScript utilities for Gleam.

```sh
gleam add gleam_javascript gleam_http gleam_fetch gleam_json
```

### Setting your `gleam.toml`

```toml
name = "your_project"
version = "1.0.0"
target = "javascript"

[javascript]
typescript_declarations = true
runtime = "bun"

[dependencies]
brioche = ">= 1.0.0 and < 2.0.0"
gleam_stdlib = ">= 0.44.0 and < 2.0.0"
gleam_javascript = ">= 1.0.0 and < 2.0.0"
gleam_http = ">= 4.0.0 and < 5.0.0"
gleam_fetch = ">= 1.2.0 and < 2.0.0"
gleam_json = ">= 2.0.0 and < 3.0.0"

[dev-dependencies]
gleeunit = ">= 1.0.0 and < 2.0.0"
```

## Features

Faetures already-made, tested, and usable.

- [x] Web server, with `brioche/server`.
- [x] Websockets, with `brioche/websocket`.
- [x] SQL, with `brioche/sql`.
- [x] Bun.File, with `brioche/file`.
- [x] Bun.FileSink, with `brioche/file_sink`.
- [x] Semver, with `brioche/semver`.
- [x] TLS, with `brioche/tls`.
- [x] Utils, with `brioche`.
- [x] Hashing, with `brioche/hash`, `brioche/hash/password` &
      `brioche/hash/crypto_hasher`.

Features made, but untested.

- [x] S3, with `brioche/s3`.

Features remaining to implement.

- [ ] $ shell
- [ ] Streams
- [ ] SQLite
- [ ] Child processes
- [ ] TCP sockets
- [ ] UDP sockets

Experimental API, waiting stabilisation before implementation.

- [ ] DNS
