import gleam/json
import gleam/string
import gleeunit
import gleeunit/should
import jscheam
import jscheam/property.{Array, Boolean, Float, Integer, String}

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn simple_object_test() {
  let schema =
    jscheam.object(
      [
        jscheam.prop("name", jscheam.string()),
        jscheam.prop("age", jscheam.integer()),
      ],
      False,
    )

  let json = jscheam.to_json(schema) |> json.to_string()

  string.contains(json, "\"type\":\"object\"") |> should.be_true()
  string.contains(json, "\"name\":{\"type\":\"string\"}") |> should.be_true()
  string.contains(json, "\"age\":{\"type\":\"number\"}") |> should.be_true()
  string.contains(json, "\"required\":[\"name\",\"age\"]") |> should.be_true()
}

pub fn optional_property_test() {
  let schema =
    jscheam.object(
      [
        jscheam.prop("name", jscheam.string()),
        jscheam.prop("bio", jscheam.string()) |> jscheam.optional(),
      ],
      False,
    )

  let json = jscheam.to_json(schema) |> json.to_string()

  string.contains(json, "\"name\":{\"type\":\"string\"}") |> should.be_true()
  string.contains(json, "\"bio\":{\"type\":\"string\"}") |> should.be_true()
  string.contains(json, "\"required\":[\"name\"]") |> should.be_true()
}

pub fn description_test() {
  let schema =
    jscheam.object(
      [
        jscheam.prop("name", jscheam.string())
          |> jscheam.description("User's full name"),
        jscheam.prop("age", jscheam.integer())
          |> jscheam.description("User's age in years"),
      ],
      False,
    )

  let json = jscheam.to_json(schema) |> json.to_string()

  string.contains(json, "\"description\":\"User's full name\"")
  |> should.be_true()
}

// Test arrays with proper JSON Schema structure
pub fn array_test() {
  let schema =
    jscheam.object(
      [jscheam.prop("scores", jscheam.array(jscheam.float()))],
      False,
    )

  let json = jscheam.to_json(schema) |> json.to_string()

  string.contains(json, "\"type\":\"array\"") |> should.be_true()
  string.contains(json, "\"items\":{\"type\":\"number\"}") |> should.be_true()
}

// Test nested objects
pub fn nested_object_test() {
  let schema =
    jscheam.object(
      [
        jscheam.prop(
          "profile",
          jscheam.object(
            [
              jscheam.prop("bio", jscheam.string()) |> jscheam.optional(),
              jscheam.prop("avatar_url", jscheam.string()),
            ],
            False,
          ),
        ),
      ],
      False,
    )

  let json = jscheam.to_json(schema) |> json.to_string()

  // Should contain nested object structure
  string.contains(json, "\"profile\":{\"type\":\"object\"") |> should.be_true()
  string.contains(json, "\"bio\":{\"type\":\"string\"}") |> should.be_true()
  string.contains(json, "\"avatar_url\":{\"type\":\"string\"}")
  |> should.be_true()
}

pub fn additional_properties_test() {
  let schema =
    jscheam.object(
      [
        jscheam.prop("name", jscheam.string()),
        jscheam.prop("age", jscheam.integer()) |> jscheam.optional(),
      ],
      True,
    )

  let json = jscheam.to_json(schema) |> json.to_string()

  string.contains(json, "\"additionalProperties\":true") |> should.be_true()
}

// Test chaining optional and description
pub fn chained_modifiers_test() {
  let schema =
    jscheam.object(
      [
        jscheam.prop("nickname", jscheam.string())
        |> jscheam.optional()
        |> jscheam.description("Optional user nickname"),
      ],
      False,
    )

  let json = jscheam.to_json(schema) |> json.to_string()

  string.contains(json, "\"required\":[]") |> should.be_true()
  string.contains(json, "\"description\":\"Optional user nickname\"")
  |> should.be_true()
}

// Test type constructors
pub fn type_constructors_test() {
  jscheam.string() |> should.equal(String)
  jscheam.integer() |> should.equal(Integer)
  jscheam.boolean() |> should.equal(Boolean)
  jscheam.float() |> should.equal(Float)
  jscheam.array(jscheam.string()) |> should.equal(Array(String))
}
