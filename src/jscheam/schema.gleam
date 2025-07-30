import gleam/json
import gleam/list
import gleam/option

/// Constraints that can be applied to properties
pub type Constraint {
  /// Restrict values to a fixed set of values (can be any JSON value)
  Enum(values: List(json.Json))
  /// Pattern constraint using regex
  Pattern(regex: String)
}

/// A type definition for JSON Schema
pub type Type {
  Integer
  String
  Boolean
  Float
  Null
  Object(
    properties: List(Property),
    additional_properties: AdditionalProperties,
  )
  Array(Type)
  /// Union type for multiple allowed types (e.g., ["string", "null"])
  Union(List(Type))
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

/// Creates a null type for JSON Schema
pub fn null() -> Type {
  Null
}

/// Creates an array type with the specified item type
pub fn array(item_type: Type) -> Type {
  Array(item_type)
}

/// Creates a union type that accepts multiple types (e.g., string or null)
/// Example: union([string(), null()]) creates a schema that accepts both strings and null values
pub fn union(types: List(Type)) -> Type {
  Union(types)
}

/// Creates an object type with the specified properties
/// By default allows any additional properties (JSON Schema default behavior - omits the field)
pub fn object(properties: List(Property)) -> Type {
  Object(properties: properties, additional_properties: AllowAny)
}

/// Explicitly allows any additional properties (outputs "additionalProperties": true)
pub fn allow_additional_props(object_type: Type) -> Type {
  case object_type {
    Object(properties: props, additional_properties: _) ->
      Object(properties: props, additional_properties: AllowExplicit)
    _ -> object_type
  }
}

/// Disallows additional properties (outputs "additionalProperties": false)
pub fn disallow_additional_props(object_type: Type) -> Type {
  case object_type {
    Object(properties: props, additional_properties: _) ->
      Object(properties: props, additional_properties: Disallow)
    _ -> object_type
  }
}

/// Constrains additional properties to conform to the specified schema
pub fn constrain_additional_props(object_type: Type, schema: Type) -> Type {
  case object_type {
    Object(properties: props, additional_properties: _) ->
      Object(properties: props, additional_properties: Schema(schema))
    _ -> object_type
  }
}

/// A property in a JSON Schema object
pub type Property {
  Property(
    name: String,
    property_type: Type,
    is_required: Bool,
    description: option.Option(String),
    constraints: List(Constraint),
  )
}

/// Additional properties configuration for object types
pub type AdditionalProperties {
  /// Allow any additional properties (JSON Schema default behavior)
  /// This is the default and will omit the additionalProperties field from the schema
  AllowAny
  /// Explicitly allow any additional properties (outputs "additionalProperties": true)
  AllowExplicit
  /// Disallow any additional properties
  Disallow
  /// Additional properties must conform to the specified schema
  Schema(Type)
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
    constraints: [],
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

/// Adds an enum constraint to a property that restricts values to a fixed set
/// Example: prop("color", string()) |> enum(enum_strings(["red", "green", "blue"]))
pub fn enum(property: Property, values: List(json.Json)) -> Property {
  let new_constraint = Enum(values: values)
  Property(..property, constraints: [new_constraint, ..property.constraints])
}

/// Adds a pattern constraint to a property that restricts values to match a regex pattern
/// Example: prop("phone", string()) |> pattern("^(\\([0-9]{3}\\))?[0-9]{3}-[0-9]{4}$")
pub fn pattern(property: Property, regex: String) -> Property {
  let new_constraint = Pattern(regex: regex)
  Property(..property, constraints: [new_constraint, ..property.constraints])
}

fn additional_properties_to_json(
  add_props: AdditionalProperties,
) -> List(#(String, json.Json)) {
  case add_props {
    AllowAny -> []
    // Omit the field entirely (JSON Schema Draft 7 default)
    AllowExplicit -> [#("additionalProperties", json.bool(True))]
    Disallow -> [#("additionalProperties", json.bool(False))]
    Schema(schema_type) -> [
      #("additionalProperties", type_to_json_value(schema_type)),
    ]
  }
}

fn type_to_type_string(property_type: Type) -> String {
  case property_type {
    String -> "string"
    Integer -> "number"
    Boolean -> "boolean"
    Null -> "null"
    Float -> "number"
    Object(_, _) -> "object"
    Array(_) -> "array"
    Union(_) ->
      panic as "Union types should not be converted to single type strings"
  }
}

fn type_to_json_value(property_type: Type) -> json.Json {
  case property_type {
    String | Integer | Boolean | Null | Float ->
      json.object([#("type", json.string(type_to_type_string(property_type)))])
    Object(properties: props, additional_properties: add_props) -> {
      let properties_json = list.map(props, property_to_field) |> json.object
      let required_json = fields_to_required(props)
      let additional_props_fields = additional_properties_to_json(add_props)

      let base_fields = [
        #("type", json.string(type_to_type_string(property_type))),
        #("properties", properties_json),
        #("required", required_json),
      ]

      json.object(list.append(base_fields, additional_props_fields))
    }
    Array(item_type) ->
      json.object([
        #("type", json.string(type_to_type_string(property_type))),
        #("items", type_to_json_value(item_type)),
      ])
    Union(types) -> {
      let type_strings = list.map(types, type_to_type_string)
      json.object([#("type", json.array(type_strings, json.string))])
    }
  }
}

fn property_to_field(property: Property) -> #(String, json.Json) {
  let Property(name, property_type, _is_required, description, constraints) =
    property

  let base_fields = get_base_type_fields(property_type)
  let fields_with_constraints = add_constraint_fields(base_fields, constraints)
  let final_fields = case description {
    option.Some(desc) -> [
      #("description", json.string(desc)),
      ..fields_with_constraints
    ]
    option.None -> fields_with_constraints
  }

  #(name, json.object(final_fields))
}

fn get_base_type_fields(property_type: Type) -> List(#(String, json.Json)) {
  case property_type {
    String | Integer | Boolean | Null | Float -> [
      #("type", json.string(type_to_type_string(property_type))),
    ]
    Array(item_type) -> [
      #("type", json.string(type_to_type_string(property_type))),
      #("items", type_to_json_value(item_type)),
    ]
    Object(properties: props, additional_properties: add_props) -> {
      let properties_json = list.map(props, property_to_field) |> json.object
      let required_json = fields_to_required(props)
      let additional_props_fields = additional_properties_to_json(add_props)

      let base_fields = [
        #("type", json.string(type_to_type_string(property_type))),
        #("properties", properties_json),
        #("required", required_json),
      ]

      list.append(base_fields, additional_props_fields)
    }
    Union(types) -> {
      let type_strings = list.map(types, type_to_type_string)
      [#("type", json.array(type_strings, json.string))]
    }
  }
}

fn add_constraint_fields(
  base_fields: List(#(String, json.Json)),
  constraints: List(Constraint),
) -> List(#(String, json.Json)) {
  case constraints {
    [] -> base_fields
    [constraint, ..rest] -> {
      let fields_with_constraint =
        add_single_constraint_field(base_fields, constraint)
      add_constraint_fields(fields_with_constraint, rest)
    }
  }
}

fn add_single_constraint_field(
  fields: List(#(String, json.Json)),
  constraint: Constraint,
) -> List(#(String, json.Json)) {
  case constraint {
    Enum(values: values) -> [
      #("enum", json.array(values, fn(x) { x })),
      ..fields
    ]
    Pattern(regex: regex) -> [#("pattern", json.string(regex)), ..fields]
  }
}

fn fields_to_required(fields: List(Property)) -> json.Json {
  let required_fields =
    list.filter(fields, fn(property) {
      let Property(
        _name,
        _property_type,
        is_required,
        _description,
        _constraints,
      ) = property
      is_required
    })

  let names =
    list.map(required_fields, fn(property) {
      let Property(
        name,
        _property_type,
        _is_required,
        _description,
        _constraints,
      ) = property
      json.string(name)
    })
  json.array(names, fn(x) { x })
}

/// Converts a Type to a JSON Schema document
/// This is the main function to generate JSON Schema from your type definitions
pub fn to_json(object_type: Type) -> json.Json {
  type_to_json_value(object_type)
}
