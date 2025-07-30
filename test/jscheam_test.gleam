import gleam/json
import gleam/string
import gleeunit
import gleeunit/should
import jscheam

pub fn main() -> Nil {
  gleeunit.main()
}

// Test default additional properties behavior (allow any - omit field)
pub fn additional_properties_test() {
  let schema_default =
    jscheam.object([
      jscheam.prop("name", jscheam.string()),
      jscheam.prop("age", jscheam.integer()) |> jscheam.optional(),
    ])

  let json_default = jscheam.to_json(schema_default) |> json.to_string()

  // Should NOT contain additionalProperties field (defaults to true)
  string.contains(json_default, "additionalProperties") |> should.be_false()
}

// Test additional properties with schema constraint
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

// Test optional properties
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

// Test property descriptions
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
