import gleam/option

/// A property in a JSON Schema object
pub type Property {
  Property(
    name: String,
    property_type: Type,
    is_required: Bool,
    description: option.Option(String),
  )
}

/// A JSON Schema type
pub type Type {
  Integer
  String
  Boolean
  Float
  Object(properties: List(Property), additional_properties: Bool)
  Array(Type)
}
