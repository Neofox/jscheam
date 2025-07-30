import gleam/json
import gleam/string
import gleeunit/should
import jscheam/schema.{Array, Boolean, Float, Integer, Null, String, Union}

// Test basic object structure
pub fn simple_object_test() {
  let schema =
    schema.object([
      schema.prop("name", schema.string()),
      schema.prop("age", schema.integer()),
    ])
    |> schema.disallow_additional_props()

  let json = schema.to_json(schema) |> json.to_string()

  string.contains(json, "\"type\":\"object\"") |> should.be_true()
  string.contains(json, "\"name\":{\"type\":\"string\"}") |> should.be_true()
  string.contains(json, "\"age\":{\"type\":\"number\"}") |> should.be_true()
  string.contains(json, "\"required\":[\"name\",\"age\"]") |> should.be_true()
  string.contains(json, "\"additionalProperties\":false") |> should.be_true()
}

// Test arrays with proper JSON Schema structure
pub fn array_test() {
  let schema =
    schema.object([schema.prop("scores", schema.array(schema.float()))])
    |> schema.disallow_additional_props()

  let json = schema.to_json(schema) |> json.to_string()

  string.contains(json, "\"type\":\"array\"") |> should.be_true()
  string.contains(json, "\"items\":{\"type\":\"number\"}") |> should.be_true()
}

// Test nested objects
pub fn nested_object_test() {
  let schema =
    schema.object([
      schema.prop(
        "profile",
        schema.object([
          schema.prop("bio", schema.string()) |> schema.optional(),
          schema.prop("avatar_url", schema.string()),
        ])
          |> schema.disallow_additional_props(),
      ),
    ])
    |> schema.disallow_additional_props()

  let json = schema.to_json(schema) |> json.to_string()

  // Should contain nested object structure
  string.contains(json, "\"profile\":{\"type\":\"object\"") |> should.be_true()
  string.contains(json, "\"bio\":{\"type\":\"string\"}") |> should.be_true()
  string.contains(json, "\"avatar_url\":{\"type\":\"string\"}")
  |> should.be_true()
}

// Test type constructors
pub fn type_constructors_test() {
  schema.string() |> should.equal(String)
  schema.integer() |> should.equal(Integer)
  schema.boolean() |> should.equal(Boolean)
  schema.float() |> should.equal(Float)
  schema.null() |> should.equal(Null)
  schema.array(schema.string()) |> should.equal(Array(String))
  schema.union([schema.string(), schema.null()])
  |> should.equal(Union([String, Null]))
}

// Test union types
pub fn union_type_test() {
  let schema =
    schema.object([
      schema.prop("units", schema.union([schema.string(), schema.null()]))
      |> schema.description("Units the temperature will be returned in."),
    ])

  let json = schema.to_json(schema) |> json.to_string()

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
    schema.object([
      schema.prop("location", schema.string())
        |> schema.description("City and country e.g. Bogotá, Colombia"),
      schema.prop("units", schema.union([schema.string(), schema.null()]))
        |> schema.enum([json.string("celsius"), json.string("fahrenheit")])
        |> schema.description("Units the temperature will be returned in."),
    ])
    |> schema.disallow_additional_props()

  let json = schema.to_json(schema) |> json.to_string()

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
