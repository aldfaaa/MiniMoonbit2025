///|
pub(all) struct StructConstructExpr {
  name : String
  fields : Array[(String, Expr)]
} derive(Show)

///|
pub fn Context::check_struct_construct_expr(
  self : Self,
  sc_expr : @parser.StructConstructExpr,
) -> (AtomExprKind, TypeKind) raise TypeCheckError {
  let struct_def = match self.struct_defs.get(sc_expr.name) {
    Some(def) => def
    None => raise TypeCheckError("Undefined struct: \{sc_expr.name}")
  }
  if sc_expr.fields.length() != struct_def.fields.length() {
    raise TypeCheckError(
      "Struct \{sc_expr.name} requires \{struct_def.fields.length()} fields, but \{sc_expr.fields.length()} were provided",
    )
  }
  let checked_fields : Array[(String, Expr)] = Array::new()
  for i in 0..<sc_expr.fields.length() {
    let (field_name, field_expr) = sc_expr.fields[i]
    let field_type = match struct_def.get_field_type(field_name) {
      Some(ty) => ty
      None =>
        raise TypeCheckError(
          "Field \{field_name} does not exist in struct \{sc_expr.name}",
        )
    }
    let checked_expr = self.check_expr(field_expr)
    if self.is_type_compatible(checked_expr.ty, field_type.kind) is false {
      raise TypeCheckError(
        "Field \{field_name} expects type \{field_type.kind.to_string()}, but got \{checked_expr.ty.to_string()}",
      )
    }
    checked_fields.push((field_name, checked_expr))
  }
  let struct_construct_expr = StructConstructExpr::{
    name: sc_expr.name,
    fields: checked_fields,
  }
  let atom_expr_kind = AtomExprKind::StructConstruct(struct_construct_expr)
  let type_kind = TypeKind::Struct(sc_expr.name)
  (atom_expr_kind, type_kind)
}
