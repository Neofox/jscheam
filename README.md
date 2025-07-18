# jscheam - A Simple JSON Schema Library

[![Package Version](https://img.shields.io/hexpm/v/jscheam)](https://hex.pm/packages/jscheam)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/jscheam/)

A Gleam library for generating JSON Schema documents (Draft 7 compliant).
I looked for a simple way to create JSON schemas in Gleam but every things I tried where either outdated or incomplete. This library was born out of that need.
This library provides a fluent API for building JSON schemas programmatically, making it easy to create validation schemas for APIs, configuration files, and data structures.

## Installation

```sh
gleam add jscheam
```

## Usage

### Basic Types

```gleam
import jscheam
import gleam/json

// Create simple types
let name_schema = jscheam.string()
let age_schema = jscheam.integer()
let active_schema = jscheam.boolean()
let score_schema = jscheam.float()

// Generate JSON Schema
let json_schema = jscheam.to_json(name_schema) |> json.to_string()
// Result: {"type":"string"}
```

### Object Schemas

```gleam
import jscheam
import gleam/json

// Create an object with properties
let user_schema = jscheam.object([
  jscheam.prop("name", jscheam.string()),
  jscheam.prop("age", jscheam.integer()),
  jscheam.prop("email", jscheam.string())
], additional_properties: False)

let json_schema = jscheam.to_json(user_schema) |> json.to_string()
// Result: {
//   "type": "object",
//   "properties": {
//     "name": {"type": "string"},
//     "age": {"type": "number"},
//     "email": {"type": "string"}
//   },
//   "required": ["name", "age", "email"],
//   "additionalProperties": false
// }
```

### Optional Properties and Descriptions

```gleam
import jscheam
import gleam/json

let user_schema = jscheam.object([
  jscheam.prop("name", jscheam.string()) |> jscheam.description("User's full name"),
  jscheam.prop("age", jscheam.integer()) |> jscheam.optional(),
  jscheam.prop("email", jscheam.string())
    |> jscheam.description("User's email address")
    |> jscheam.optional()
])

let json_schema = jscheam.to_json(user_schema) |> json.to_string()
// Result: {
//   "type": "object",
//   "properties": {
//     "name": {"type": "string", "description": "User's full name"},
//     "age": {"type": "number"},
//     "email": {"type": "string", "description": "User's email address"}
//   },
//   "required": ["name"],
//   "additionalProperties": false
// }
```

### Arrays

```gleam
import jscheam
import gleam/json

// Array of strings
let tags_schema = jscheam.array(jscheam.string())

// Array of objects
let users_schema = jscheam.array(
  jscheam.object([
    jscheam.prop("name", jscheam.string()),
    jscheam.prop("age", jscheam.integer()) |> jscheam.optional()
  ])
)

let json_schema = jscheam.to_json(tags_schema) |> json.to_string()
// Result: {
//   "type": "array",
//   "items": {"type": "string"}
// }
```

### Nested Objects

```gleam
import jscheam
import gleam/json

let profile_schema = jscheam.object([
  jscheam.prop("user", jscheam.object([
    jscheam.prop("name", jscheam.string()),
    jscheam.prop("age", jscheam.integer()) |> jscheam.optional()
  ])),
  jscheam.prop("preferences", jscheam.object([
    jscheam.prop("theme", jscheam.string()) |> jscheam.description("UI theme preference"),
    jscheam.prop("notifications", jscheam.boolean()) |> jscheam.optional()
  ])),
  jscheam.prop("tags", jscheam.array(jscheam.string())) |> jscheam.description("User tags")
])

let json_schema = jscheam.to_json(profile_schema) |> json.to_string()
```

## TODO: Future Features

### Tuples

- Support for tuple types with fixed-length arrays and specific item types at each position
- Example: `tuple([string(), null()])`

### Restrictions

- **String restrictions**:
  - `pattern(regex)` - Regular expression pattern validation
  - `format(format)` - Format validation (email, uri, date-time, etc.)
- **Number restrictions**:
  - `minimum(n)` / `maximum(n)` - Value range constraints
- **Array restrictions**:
  - `min_items(n)` / `max_items(n)` - Array length constraints

### Null Type

- Support for nullable types and null values
- `nullable(type)` - Makes a type nullable
- `null()` - Explicit null type

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```

## Contributing

Contributions are welcome! Please feel free to submit issues and enhancement requests.

## License

This project is licensed under the MIT License.
