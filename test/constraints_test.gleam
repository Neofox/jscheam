import gleam/json
import gleam/string
import gleeunit/should
import jscheam/schema.{Enum, Pattern, Property}

// Test enum with string base type
pub fn enum_string_test() {
  let schema =
    schema.object([
      schema.prop("units", schema.string())
      |> schema.enum([json.string("celsius"), json.string("fahrenheit")])
      |> schema.description("Units the temperature will be returned in."),
    ])

  let json = schema.to_json(schema) |> json.to_string()

  string.contains(json, "\"type\":\"object\"") |> should.be_true()
  string.contains(json, "\"units\":{") |> should.be_true()
  string.contains(json, "\"type\":\"string\"") |> should.be_true()
  string.contains(json, "\"enum\":[\"celsius\",\"fahrenheit\"]")
  |> should.be_true()
  string.contains(
    json,
    "\"description\":\"Units the temperature will be returned in.\"",
  )
  |> should.be_true()
  string.contains(json, "\"required\":[\"units\"]") |> should.be_true()
}

// Test enum constraint application
pub fn enum_constraint_test() {
  let expected_values = [
    json.string("red"),
    json.string("green"),
    json.string("blue"),
  ]
  let property =
    schema.prop("color", schema.string())
    |> schema.enum(expected_values)

  // Test that the constraint was applied
  let Property(_name, _type, _required, _description, constraints) = property
  case constraints {
    [Enum(values: values)] -> values |> should.equal(expected_values)
    _ -> should.fail()
  }
}

// Test mixed-type enum (strings, numbers, null)
pub fn enum_mixed_types_test() {
  let mixed_values = [
    json.string("red"),
    json.string("amber"),
    json.string("green"),
    json.null(),
    json.int(42),
  ]

  let schema =
    schema.object([
      schema.prop(
        "status",
        schema.union([schema.string(), schema.null(), schema.integer()]),
      )
      |> schema.enum(mixed_values)
      |> schema.description("Traffic light status with special values"),
    ])

  let json = schema.to_json(schema) |> json.to_string()

  string.contains(json, "\"type\":\"object\"") |> should.be_true()
  string.contains(json, "\"status\":{") |> should.be_true()
  string.contains(json, "\"type\":[\"string\",\"null\",\"number\"]")
  |> should.be_true()
  string.contains(json, "\"enum\":[\"red\",\"amber\",\"green\",null,42]")
  |> should.be_true()
  string.contains(
    json,
    "\"description\":\"Traffic light status with special values\"",
  )
  |> should.be_true()
}

// Test pattern constraint with phone number regex
pub fn pattern_constraint_test() {
  let phone_regex = "^(\\([0-9]{3}\\))?[0-9]{3}-[0-9]{4}$"

  let schema =
    schema.object([
      schema.prop("phone", schema.string())
      |> schema.pattern(phone_regex)
      |> schema.description("Phone number in US format"),
    ])
    |> schema.disallow_additional_props()

  let json = schema.to_json(schema) |> json.to_string()

  string.contains(json, "\"type\":\"object\"") |> should.be_true()
  string.contains(json, "\"phone\":{") |> should.be_true()
  string.contains(json, "\"type\":\"string\"") |> should.be_true()
  string.contains(
    json,
    "\"pattern\":\"^(\\\\([0-9]{3}\\\\))?[0-9]{3}-[0-9]{4}$\"",
  )
  |> should.be_true()
  string.contains(json, "\"description\":\"Phone number in US format\"")
  |> should.be_true()
  string.contains(json, "\"required\":[\"phone\"]") |> should.be_true()
  string.contains(json, "\"additionalProperties\":false") |> should.be_true()
}

// Test pattern constraint application to property structure
pub fn pattern_constraint_application_test() {
  let email_regex = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"

  let property =
    schema.prop("email", schema.string())
    |> schema.pattern(email_regex)

  // Test that the constraint was applied
  let Property(_name, _type, _required, _description, constraints) = property
  case constraints {
    [Pattern(regex: regex)] -> regex |> should.equal(email_regex)
    _ -> should.fail()
  }
}

// Test multiple constraints (enum and pattern) on same property
pub fn multiple_constraints_test() {
  let color_regex = "^#[0-9a-fA-F]{6}$"
  let color_values = [
    json.string("#FF0000"),
    json.string("#00FF00"),
    json.string("#0000FF"),
  ]

  let schema =
    schema.object([
      schema.prop("color", schema.string())
      |> schema.pattern(color_regex)
      |> schema.enum(color_values)
      |> schema.description("Hex color code from predefined set"),
    ])

  let json = schema.to_json(schema) |> json.to_string()

  string.contains(json, "\"type\":\"string\"") |> should.be_true()
  string.contains(json, "\"pattern\":\"^#[0-9a-fA-F]{6}$\"") |> should.be_true()
  string.contains(json, "\"enum\":[\"#FF0000\",\"#00FF00\",\"#0000FF\"]")
  |> should.be_true()
  string.contains(
    json,
    "\"description\":\"Hex color code from predefined set\"",
  )
  |> should.be_true()
}

// Test simple pattern constraint output format
pub fn simple_pattern_output_test() {
  let schema =
    schema.object([
      schema.prop("test", schema.string())
      |> schema.pattern("^(\\([0-9]{3}\\))?[0-9]{3}-[0-9]{4}$"),
    ])

  let json_string = schema.to_json(schema) |> json.to_string()

  // Should produce output similar to your example
  string.contains(json_string, "\"type\":\"string\"") |> should.be_true()
  string.contains(
    json_string,
    "\"pattern\":\"^(\\\\([0-9]{3}\\\\))?[0-9]{3}-[0-9]{4}$\"",
  )
  |> should.be_true()
}
