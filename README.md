# jscheam - A Simple JSON Schema Library

[![Package Version](https://img.shields.io/hexpm/v/jscheam)](https://hex.pm/packages/jscheam)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/jscheam/)

A Gleam library for generating JSON Schema documents (Draft 7 compliant).
I looked for a simple way to create JSON schemas in Gleam but every things I tried where either outdated or incomplete. This library was born out of that need.
This library provides a fluent API for building JSON schemas programmatically, making it easy to create validation schemas for APIs, configuration files, and data structures.

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
  - [Basic Types](#basic-types)
  - [Object Schemas](#object-schemas)
  - [Optional Properties and Descriptions](#optional-properties-and-descriptions)
  - [Arrays](#arrays)
  - [Union Types](#union-types)
  - [Constraints](#constraints)
  - [Nested Objects](#nested-objects)
- [TODO: Future Features](#todo-future-features)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

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

// Create an object with default additional properties behavior (allows any)
let user_schema = jscheam.object([
  jscheam.prop("name", jscheam.string()),
  jscheam.prop("age", jscheam.integer()),
  jscheam.prop("email", jscheam.string())
])

let json_schema = jscheam.to_json(user_schema) |> json.to_string()
// Result: {
//   "type": "object",
//   "properties": {
//     "name": {"type": "string"},
//     "age": {"type": "number"},
//     "email": {"type": "string"}
//   },
//   "required": ["name", "age", "email"]
//   // Note: additionalProperties is omitted (defaults to true as per JSON Schema Draft 7)
// }

// Create an object with strict additional properties 
let strict_user_schema = jscheam.object([jscheam.prop("name", jscheam.string())])
  |> jscheam.disallow_additional_props()
  |> jscheam.to_json(strict_user_schema) |> json.to_string()
// Result: {..., "additionalProperties": false}

// Create an object with constrained additional properties 
let constrained_user_schema = jscheam.object([jscheam.prop("id", jscheam.string())])
  |> jscheam.constrain_additional_props(jscheam.string())
  |> jscheam.to_json(constrained_user_schema) |> json.to_string()
// Result: {..., "additionalProperties": {"type": "string"}}

// Explicitly allow additional properties
let explicit_allow_schema = jscheam.object([
  jscheam.prop("name", jscheam.string())
]) 
|> jscheam.allow_additional_props()
|> jscheam.to_json(explicit_allow_schema) |> json.to_string()
// Result: {..., "additionalProperties": true}
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
//   "required": ["name"]
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

### Union Types

Union types allow a property to accept multiple types.
Some API require all fields to be required (no optional fields), so the only way to add nullability is to use union types.

```gleam
import jscheam
import gleam/json

// Simple union: string or null
let nullable_string_schema = jscheam.union([jscheam.string(), jscheam.null()])

// Used in an object
let user_schema = jscheam.object([
  jscheam.prop("name", jscheam.string()),
  jscheam.prop("nickname", jscheam.union([jscheam.string(), jscheam.null()]))
    |> jscheam.description("Optional nickname, can be string or null")
])

let json_schema = jscheam.to_json(user_schema) |> json.to_string()
// Result: {
//   "type": "object",
//   "properties": {
//     "name": {"type": "string"},
//     "nickname": {
//       "type": ["string", "null"],
//       "description": "Optional nickname, can be string or null"
//     }
//   },
//   "required": ["name", "nickname"]
// }
```

### Constraints

Constraints allow you to add validation rules to your schema properties. jscheam supports enum and pattern constraints with more to come in the future.

#### Enum Constraints

Enum constraints restrict values to a fixed set of allowed values. It uses the `json` module to define the allowed values. as enum values can be any valid JSON type (string, number, boolean, null, ...)

```gleam
import jscheam
import gleam/json

// String enum
let color_schema = jscheam.object([
  jscheam.prop("color", jscheam.string())
  |> jscheam.enum([
    json.string("red"),
    json.string("green"), 
    json.string("blue")
  ])
  |> jscheam.description("Primary colors only")
])

// Mixed type enum with union
let status_schema = jscheam.object([
  jscheam.prop("status", jscheam.union([jscheam.string(), jscheam.null(), jscheam.integer()]))
  |> jscheam.enum([
    json.string("active"),
    json.string("inactive"),
    json.null(),
    json.int(42)
  ])
  |> jscheam.description("Status with mixed types")
])

let json_schema = jscheam.to_json(color_schema) |> json.to_string()
// Result: {
//   "type": "object",
//   "properties": {
//     "color": {
//       "type": "string",
//       "enum": ["red", "green", "blue"],
//       "description": "Primary colors only"
//     }
//   },
//   "required": ["color"]
// }
```

#### Pattern Constraints

Pattern constraints use regular expressions to validate string values:

```gleam
import jscheam
import gleam/json

// Email validation
let user_schema = jscheam.object([
  jscheam.prop("email", jscheam.string())
  |> jscheam.pattern("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")
  |> jscheam.description("Valid email address"),
  
  jscheam.prop("phone", jscheam.string())
  |> jscheam.pattern("^(\\([0-9]{3}\\))?[0-9]{3}-[0-9]{4}$")
  |> jscheam.description("Phone number in US format")
])

let json_schema = jscheam.to_json(user_schema) |> json.to_string()
// Result: {
//   "type": "object", 
//   "properties": {
//     "email": {
//       "type": "string",
//       "pattern": "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$",
//       "description": "Valid email address"
//     },
//     "phone": {
//       "type": "string", 
//       "pattern": "^(\\([0-9]{3}\\))?[0-9]{3}-[0-9]{4}$",
//       "description": "Phone number in US format"
//     }
//   },
//   "required": ["email", "phone"]
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
// Result: {
//   "type": "object",
//   "properties": {
//     "user": {
//       "type": "object",
//       "properties": {
//         "name": {"type": "string"},
//         "age": {"type": "number"}
//       },
//       "required": ["name"]
//     },
//     "preferences": {
//       "type": "object",
//       "properties": {
//         "theme": {"type": "string", "description": "UI theme preference"},
//         "notifications": {"type": "boolean"}
//       },
//       "required": ["theme"]
//     },
//     "tags": {
//       "type": "array",
//       "items": {"type": "string"},
//       "description": "User tags"
//     }
//   },
//   "required": ["user", "preferences"]
// }
```

## TODO: Future Features

### Restrictions

- **Conditional Schema Validation**
  - `dependentRequired` - conditionally requires that certain properties must be present based on the presence of other properties
  - `dependentSchemas` - conditionally applies different schemas based on the presence of other properties
  - `if - then - else` - conditional schema validation based on the value of a property
- **String restrictions**:
  - `format(format)` - Format validation (email, uri, date-time, etc.)
- **Number restrictions**:
  - `minimum(n)` / `maximum(n)` - Value range constraints
- **Array restrictions**:
  - `min_items(n)` / `max_items(n)` - Array length constraints

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```

## Contributing

Contributions are welcome! Please feel free to submit issues and enhancement requests.

## License

This project is licensed under the MIT License.
