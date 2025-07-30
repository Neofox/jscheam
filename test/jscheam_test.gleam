import gleam/json
import gleam/string
import gleeunit
import gleeunit/should
import jscheam/schema

pub fn main() -> Nil {
  gleeunit.main()
}

// Test default additional properties behavior (allow any - omit field)
pub fn additional_properties_test() {
  let schema_default =
    schema.object([
      schema.prop("name", schema.string()),
      schema.prop("age", schema.integer()) |> schema.optional(),
    ])

  let json_default = schema.to_json(schema_default) |> json.to_string()

  // Should NOT contain additionalProperties field (defaults to true)
  string.contains(json_default, "additionalProperties") |> should.be_false()
}

// Test additional properties with schema constraint
pub fn additional_properties_with_schema_test() {
  let schema =
    schema.object([schema.prop("name", schema.string())])
    |> schema.constrain_additional_props(schema.string())

  let json = schema.to_json(schema) |> json.to_string()

  string.contains(json, "\"additionalProperties\":{\"type\":\"string\"}")
  |> should.be_true()
}

// Test strict additional properties (false)
pub fn additional_properties_strict_test() {
  let schema =
    schema.object([schema.prop("name", schema.string())])
    |> schema.disallow_additional_props()

  let json = schema.to_json(schema) |> json.to_string()

  string.contains(json, "\"additionalProperties\":false") |> should.be_true()
}

// Test explicit additional properties (true)
pub fn additional_properties_explicit_test() {
  let schema =
    schema.object([schema.prop("name", schema.string())])
    |> schema.allow_additional_props()

  let json = schema.to_json(schema) |> json.to_string()

  string.contains(json, "\"additionalProperties\":true") |> should.be_true()
}

// Test optional properties
pub fn optional_property_test() {
  let schema =
    schema.object([
      schema.prop("name", schema.string()),
      schema.prop("bio", schema.string()) |> schema.optional(),
    ])
    |> schema.disallow_additional_props()

  let json = schema.to_json(schema) |> json.to_string()

  string.contains(json, "\"name\":{\"type\":\"string\"}") |> should.be_true()
  string.contains(json, "\"bio\":{\"type\":\"string\"}") |> should.be_true()
  string.contains(json, "\"required\":[\"name\"]") |> should.be_true()
}

// Test property descriptions
pub fn description_test() {
  let schema =
    schema.object([
      schema.prop("name", schema.string())
        |> schema.description("User's full name"),
      schema.prop("age", schema.integer())
        |> schema.description("User's age in years"),
    ])
    |> schema.disallow_additional_props()

  let json = schema.to_json(schema) |> json.to_string()

  string.contains(json, "\"description\":\"User's full name\"")
  |> should.be_true()
}

// Test chaining optional and description
pub fn chained_modifiers_test() {
  let schema =
    schema.object([
      schema.prop("nickname", schema.string())
      |> schema.optional()
      |> schema.description("Optional user nickname"),
    ])
    |> schema.disallow_additional_props()

  let json = schema.to_json(schema) |> json.to_string()

  string.contains(json, "\"required\":[]") |> should.be_true()
  string.contains(json, "\"description\":\"Optional user nickname\"")
  |> should.be_true()
}
