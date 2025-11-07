
pub struct EnumDef {
  name: String
  enum_fields: Array[EnumField]
} derive(Show)

pub struct EnumField {
  name: String
  types: Array[Type]
} derive(Show)

pub fn Context::check_enum_def(
  self: Self,
  enum_def: @parser.EnumDef,
) -> EnumDef raise TypeCheckError {
  let fields: Array[EnumField] = Array::new()
  for field in enum_def.enum_fields {
    let { name, types } = field
    let checked_types: Array[Type] = types.map(t => self.check_parser_type(t))
    let checked_field = EnumField::{
      name: name,
      types: checked_types,
    }
    fields.push(checked_field)
  }
  let enum_def = EnumDef::{
    name: enum_def.name,
    enum_fields: fields,
  }
  self.enum_defs.set(enum_def.name, enum_def)
  enum_def
}
