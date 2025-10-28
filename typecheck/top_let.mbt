///|
pub struct TopLet {
  name : String
  ty : Type
  expr : Expr
} derive(Show)

///|
pub fn Context::check_top_let(
  self : Context,
  top_let : @parser.TopLet,
) -> TopLet raise TypeCheckError {
  let checked_expr = self.check_expr(top_let.expr)
  let type_kind = checked_expr.ty
  if top_let.ty is Some(type_annote) {
    let annoted_type = self.check_parser_typekind(type_annote.kind)
    if !self.is_type_compatible(annoted_type, checked_expr.ty) {
      raise TypeCheckError(
        "Type annotation does not match the expression type, annoted: \{annoted_type}, expr: \{checked_expr.ty}",
      )
    }
  }
  let type_kind = self.ensure_type(type_kind)
  let ty = Type::{ kind: type_kind, mutable: false }
  let checked_top_let = TopLet::{ name: top_let.name, ty, expr: checked_expr }
  self.type_env.set(top_let.name, ty)
  checked_top_let
}
