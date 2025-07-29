import gleam/json
import gleam/string
import gleeunit
import gleeunit/should
import jscheam
import jscheam/property.{
  Array, Boolean, Enum, Float, Integer, Null, Property, String, Union,
}

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn simple_object_test() {
  let schema =
    jscheam.object([
      jscheam.prop("name", jscheam.string()),
      jscheam.prop("age", jscheam.integer()),
    ])
    |> jscheam.disallow_additional_props()

  let json = jscheam.to_json(schema) |> json.to_string()

  string.contains(json, "\"type\":\"object\"") |> should.be_true()
  string.contains(json, "\"name\":{\"type\":\"string\"}") |> should.be_true()
  string.contains(json, "\"age\":{\"type\":\"number\"}") |> should.be_true()
  string.contains(json, "\"required\":[\"name\",\"age\"]") |> should.be_true()
  string.contains(json, "\"additionalProperties\":false") |> should.be_true()
}

pub fn optional_property_test() {
  let schema =
    jscheam.object([
      jscheam.prop("name", jscheam.string()),
      jscheam.prop("bio", jscheam.string()) |> jscheam.optional(),
    ])
    |> jscheam.disallow_additional_props()

  let json = jscheam.to_json(schema) |> json.to_string()

  string.contains(json, "\"name\":{\"type\":\"string\"}") |> should.be_true()
  string.contains(json, "\"bio\":{\"type\":\"string\"}") |> should.be_true()
  string.contains(json, "\"required\":[\"name\"]") |> should.be_true()
}

pub fn description_test() {
  let schema =
    jscheam.object([
      jscheam.prop("name", jscheam.string())
        |> jscheam.description("User's full name"),
      jscheam.prop("age", jscheam.integer())
        |> jscheam.description("User's age in years"),
    ])
    |> jscheam.disallow_additional_props()

  let json = jscheam.to_json(schema) |> json.to_string()

  string.contains(json, "\"description\":\"User's full name\"")
  |> should.be_true()
}

// Test arrays with proper JSON Schema structure
pub fn array_test() {
  let schema =
    jscheam.object([jscheam.prop("scores", jscheam.array(jscheam.float()))])
    |> jscheam.disallow_additional_props()

  let json = jscheam.to_json(schema) |> json.to_string()

  string.contains(json, "\"type\":\"array\"") |> should.be_true()
  string.contains(json, "\"items\":{\"type\":\"number\"}") |> should.be_true()
}

// Test nested objects
pub fn nested_object_test() {
  let schema =
    jscheam.object([
      jscheam.prop(
        "profile",
        jscheam.object([
          jscheam.prop("bio", jscheam.string()) |> jscheam.optional(),
          jscheam.prop("avatar_url", jscheam.string()),
        ])
          |> jscheam.disallow_additional_props(),
      ),
    ])
    |> jscheam.disallow_additional_props()

  let json = jscheam.to_json(schema) |> json.to_string()

  // Should contain nested object structure
  string.contains(json, "\"profile\":{\"type\":\"object\"") |> should.be_true()
  string.contains(json, "\"bio\":{\"type\":\"string\"}") |> should.be_true()
  string.contains(json, "\"avatar_url\":{\"type\":\"string\"}")
  |> should.be_true()
}

pub fn additional_properties_test() {
  // Test default behavior (allow any additional properties - omit field)
  let schema_default =
    jscheam.object([
      jscheam.prop("name", jscheam.string()),
      jscheam.prop("age", jscheam.integer()) |> jscheam.optional(),
    ])

  let json_default = jscheam.to_json(schema_default) |> json.to_string()

  // Should NOT contain additionalProperties field (defaults to true)
  string.contains(json_default, "additionalProperties") |> should.be_false()
}

// Test chaining optional and description
pub fn chained_modifiers_test() {
  let schema =
    jscheam.object([
      jscheam.prop("nickname", jscheam.string())
      |> jscheam.optional()
      |> jscheam.description("Optional user nickname"),
    ])
    |> jscheam.disallow_additional_props()

  let json = jscheam.to_json(schema) |> json.to_string()

  string.contains(json, "\"required\":[]") |> should.be_true()
  string.contains(json, "\"description\":\"Optional user nickname\"")
  |> should.be_true()
}

// Test additional properties with schema
pub fn additional_properties_with_schema_test() {
  let schema =
    jscheam.object([jscheam.prop("name", jscheam.string())])
    |> jscheam.constrain_additional_props(jscheam.string())

  let json = jscheam.to_json(schema) |> json.to_string()

  string.contains(json, "\"additionalProperties\":{\"type\":\"string\"}")
  |> should.be_true()
}

// Test strict additional properties (false)
pub fn additional_properties_strict_test() {
  let schema =
    jscheam.object([jscheam.prop("name", jscheam.string())])
    |> jscheam.disallow_additional_props()

  let json = jscheam.to_json(schema) |> json.to_string()

  string.contains(json, "\"additionalProperties\":false") |> should.be_true()
}

// Test explicit additional properties (true)
pub fn additional_properties_explicit_test() {
  let schema =
    jscheam.object([jscheam.prop("name", jscheam.string())])
    |> jscheam.allow_additional_props()

  let json = jscheam.to_json(schema) |> json.to_string()

  string.contains(json, "\"additionalProperties\":true") |> should.be_true()
}

// Test type constructors
pub fn type_constructors_test() {
  jscheam.string() |> should.equal(String)
  jscheam.integer() |> should.equal(Integer)
  jscheam.boolean() |> should.equal(Boolean)
  jscheam.float() |> should.equal(Float)
  jscheam.null() |> should.equal(Null)
  jscheam.array(jscheam.string()) |> should.equal(Array(String))
  jscheam.union([jscheam.string(), jscheam.null()])
  |> should.equal(Union([String, Null]))
}

pub fn union_type_test() {
  let schema =
    jscheam.object([
      jscheam.prop("units", jscheam.union([jscheam.string(), jscheam.null()]))
      |> jscheam.description("Units the temperature will be returned in."),
    ])

  let json = jscheam.to_json(schema) |> json.to_string()

  string.contains(json, "\"type\":\"object\"") |> should.be_true()
  string.contains(json, "\"units\":{") |> should.be_true()
  string.contains(json, "\"type\":[\"string\",\"null\"]") |> should.be_true()
  string.contains(
    json,
    "\"description\":\"Units the temperature will be returned in.\"",
  )
  |> should.be_true()
  string.contains(json, "\"required\":[\"units\"]") |> should.be_true()
}

// Test enum with string base type
pub fn enum_string_test() {
  let schema =
    jscheam.object([
      jscheam.prop("units", jscheam.string())
      |> jscheam.enum([json.string("celsius"), json.string("fahrenheit")])
      |> jscheam.description("Units the temperature will be returned in."),
    ])

  let json = jscheam.to_json(schema) |> json.to_string()

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

// Test enum with union base type (as in your example)
pub fn enum_union_test() {
  let schema =
    jscheam.object([
      jscheam.prop("location", jscheam.string())
        |> jscheam.description("City and country e.g. Bogotá, Colombia"),
      jscheam.prop("units", jscheam.union([jscheam.string(), jscheam.null()]))
        |> jscheam.enum([json.string("celsius"), json.string("fahrenheit")])
        |> jscheam.description("Units the temperature will be returned in."),
    ])
    |> jscheam.disallow_additional_props()

  let json = jscheam.to_json(schema) |> json.to_string()

  string.contains(json, "\"type\":\"object\"") |> should.be_true()
  string.contains(json, "\"location\":{") |> should.be_true()
  string.contains(json, "\"units\":{") |> should.be_true()
  string.contains(json, "\"type\":[\"string\",\"null\"]") |> should.be_true()
  string.contains(json, "\"enum\":[\"celsius\",\"fahrenheit\"]")
  |> should.be_true()
  string.contains(json, "\"required\":[\"location\",\"units\"]")
  |> should.be_true()
  string.contains(json, "\"additionalProperties\":false") |> should.be_true()
}

// Test enum constraint application
pub fn enum_constraint_test() {
  let expected_values = [
    json.string("red"),
    json.string("green"),
    json.string("blue"),
  ]
  let property =
    jscheam.prop("color", jscheam.string())
    |> jscheam.enum(expected_values)

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
    jscheam.object([
      jscheam.prop(
        "status",
        jscheam.union([jscheam.string(), jscheam.null(), jscheam.integer()]),
      )
      |> jscheam.enum(mixed_values)
      |> jscheam.description("Traffic light status with special values"),
    ])

  let json = jscheam.to_json(schema) |> json.to_string()

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
