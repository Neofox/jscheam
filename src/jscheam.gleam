import gleam/json
import gleam/list
import gleam/option
import jscheam/property.{
  type Property, type Type, Array, Boolean, Float, Integer, Object, Property,
  String,
}

// Property builders
/// Creates a property with the specified name and type
/// Properties are required by default
pub fn prop(name: String, property_type: Type) -> Property {
  Property(
    name: name,
    property_type: property_type,
    is_required: True,
    description: option.None,
  )
}

/// Makes a property optional (not required in the schema)
pub fn optional(property: Property) -> Property {
  Property(..property, is_required: False)
}

/// Adds a description to a property for documentation purposes
pub fn description(property: Property, desc: String) -> Property {
  Property(..property, description: option.Some(desc))
}

// Type builders
/// Creates a string type for JSON Schema
pub fn string() -> Type {
  String
}

/// Creates an integer/number type for JSON Schema
pub fn integer() -> Type {
  Integer
}

/// Creates a boolean type for JSON Schema
pub fn boolean() -> Type {
  Boolean
}

/// Creates a float/number type for JSON Schema
pub fn float() -> Type {
  Float
}

/// Creates an array type with the specified item type
pub fn array(item_type: Type) -> Type {
  Array(item_type)
}

/// Creates an object type with the specified properties
/// Set additional_properties to True to allow additional properties beyond those defined
pub fn object(properties: List(Property), additional_properties: Bool) -> Type {
  Object(properties: properties, additional_properties: additional_properties)
}

fn type_to_json_value(property_type: Type) -> json.Json {
  case property_type {
    String -> json.object([#("type", json.string("string"))])
    Integer -> json.object([#("type", json.string("number"))])
    Boolean -> json.object([#("type", json.string("boolean"))])
    Float -> json.object([#("type", json.string("number"))])
    Object(properties: props, additional_properties: add_props) -> {
      let properties_json = list.map(props, property_to_field) |> json.object
      let required_json = fields_to_required(props)
      json.object([
        #("type", json.string("object")),
        #("properties", properties_json),
        #("required", required_json),
        #("additionalProperties", json.bool(add_props)),
      ])
    }
    Array(item_type) ->
      json.object([
        #("type", json.string("array")),
        #("items", type_to_json_value(item_type)),
      ])
  }
}

fn property_to_field(property: Property) -> #(String, json.Json) {
  let Property(name, property_type, _is_required, description) = property
  let base_schema = type_to_json_value(property_type)

  // Add description if provided
  let schema_with_description = case description {
    option.Some(desc) -> {
      case base_schema {
        _ -> {
          case property_type {
            String ->
              json.object([
                #("type", json.string("string")),
                #("description", json.string(desc)),
              ])
            Integer ->
              json.object([
                #("type", json.string("number")),
                #("description", json.string(desc)),
              ])
            Boolean ->
              json.object([
                #("type", json.string("boolean")),
                #("description", json.string(desc)),
              ])
            Float ->
              json.object([
                #("type", json.string("number")),
                #("description", json.string(desc)),
              ])
            Array(item_type) ->
              json.object([
                #("type", json.string("array")),
                #("items", type_to_json_value(item_type)),
                #("description", json.string(desc)),
              ])
            Object(properties: props, additional_properties: add_props) -> {
              let properties_json =
                list.map(props, property_to_field) |> json.object
              let required_json = fields_to_required(props)
              json.object([
                #("type", json.string("object")),
                #("properties", properties_json),
                #("required", required_json),
                #("additionalProperties", json.bool(add_props)),
                #("description", json.string(desc)),
              ])
            }
          }
        }
      }
    }
    option.None -> base_schema
  }

  #(name, schema_with_description)
}

fn fields_to_required(fields: List(Property)) -> json.Json {
  let required_fields =
    list.filter(fields, fn(property) {
      let Property(_name, _property_type, is_required, _description) = property
      is_required
    })

  let names =
    list.map(required_fields, fn(property) {
      let Property(name, _property_type, _is_required, _description) = property
      json.string(name)
    })
  json.array(names, fn(x) { x })
}

/// Converts a Type to a JSON Schema document
/// This is the main function to generate JSON Schema from your type definitions
pub fn to_json(object_type: Type) -> json.Json {
  type_to_json_value(object_type)
}
