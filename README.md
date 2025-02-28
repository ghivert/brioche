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
gleam_fetch = ">= 1.1.1 and < 2.0.0"
gleam_json = ">= 2.3.0 and < 3.0.0"

[dev-dependencies]
gleeunit = ">= 1.0.0 and < 2.0.0"
```
