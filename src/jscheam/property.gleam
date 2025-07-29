import gleam/json
import gleam/option

/// Constraints that can be applied to properties
pub type Constraint {
  /// Restrict values to a fixed set of values (can be any JSON value)
  Enum(values: List(json.Json))
  /// Pattern constraint using regex 
  Pattern(regex: String)
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

/// A JSON Schema type
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
