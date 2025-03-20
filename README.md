# Brioche

> Opinionated Gleam bindings over Bun API.

Brioche fills the gap between Gleam and a part of the JavaScript ecosystem, by
providing easy-to-use, opinionated, gleamy bindings on Bun. Writing Gleam
JavaScript & Bun code has never been easier, and no bindings are required for
main features for Bun.

## Opinions

While Bun is a JavaScript runtime, Brioche does no try to provide 1:1 API.
Instead, Brioche tries to provide idiomatic Gleam bindings on top of Bun, while
leveraging the performance and the efficiency of the Bun runtime. Brioche takes
inspiration in existing major Gleam packages in the ecosystem
([`Wisp`](https://hexdocs.pm/wisp), [`Glen`](https://hexdocs.pm/glen),
[`Pog`](https://hexdocs.pm/pog), and so on), and provides similar API for a
unified experience across the different Gleam targets. Brioche does not try to
substitute to any of those, but tries to provide an alternative to those
solutions if you're looking for something different.

Brioche tries to use as much standard, official packages as possible from the
Gleam ecosystem, while being dependent on almost no package. Brioche is a
binding on top of Bun on which you can build or bring your own framework.

[`Wisp`](https://hexdocs.pm/wisp) continues to be the _de facto_ default web
server in Gleam, and unless you know what you're doing, and you're ready to
handle all the JavaScript promises and asynchronicity, you should use `Wisp`
instead.

[`Glen`](https://hexdocs.pm/glen) is also a more mature, production-ready
framework that proved to be efficient in case you're targetting another runtime
that Bun. You can also use `Glen` with Brioche freely, so if any code you're
looking for is already using `Glen`, use it!

## Getting Started

Gleam & Bun are required to run. Bun is the runtime for Brioche. Brioche _will
not_ run on anything else than Bun.

### Installing Brioche

```sh
# Install brioche.
gleam add brioche

# Install the other core packages. While those are transitive dependencies, they
# should be added in your `gleam.toml` to avoid any inconsistencies.
gleam add gleam_javascript gleam_http gleam_fetch gleam_json
```

### Setting your `gleam.toml`

Setting your `gleam.toml` with `target = "javascript"`, and the `[javascript]`
section is a simple way to use Bun without hassle. At the end, your `gleam.toml`
should look like this.

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

## Documentation

Every Brioche modules are documented in their own modules. Complete
documentation can be found on [HexDocs](https://hexdocs.pm/brioche).

## Features

Brioche tries to implements all major features from Bun, with proper tests. Some
still remain to be implemented. To stay stable, Brioche will not implement
experimental features as they are subject to changes. In those cases, discretion
is left to developer to implement missing features with the Gleam FFI. Below is
the list of implemented features, with their state. Any help is welcome for
non-implemented features.

### Features already-made, documented, tested, and usable

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

### Features made, but untested

- [x] S3, with `brioche/s3`.

### Features remaining to implement

- [ ] $ shell
- [ ] Streams
- [ ] SQLite
- [ ] Child processes
- [ ] TCP sockets
- [ ] UDP sockets

### Experimental API, waiting for stabilisation before implementation

- [ ] DNS
- [ ] Workers

## Contributing

Any Pull Request is welcome! Feel free to open a Pull Request with your desired
changes to start the discussion, or open an issue first.
