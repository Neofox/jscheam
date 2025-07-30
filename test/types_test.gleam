import gleam/json
import gleam/string
import gleeunit/should
import jscheam
import jscheam/property.{Array, Boolean, Float, Integer, Null, String, Union}

// Test basic object structure
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

// Test union types
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

// Test enum with union base type
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
