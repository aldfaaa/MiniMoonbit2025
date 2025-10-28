///|
pub(all) struct LetMutStmt {
  name : String
  ty : TypeKind
  expr : Expr
} derive(Show)

///|
pub fn Context::check_let_mut_stmt(
  self : Context,
  stmt : @parser.LetMutStmt,
) -> LetMutStmt raise TypeCheckError {
  let checked_expr = self.check_expr(stmt.expr)
  let type_kind = checked_expr.ty
  if stmt.ty is Some(type_annote) {
    let annoted_type = self.check_parser_typekind(type_annote.kind)
    if !self.is_type_compatible(annoted_type, checked_expr.ty) {
      raise TypeCheckError(
        "Type annotation does not match the expression type, annoted: \{annoted_type}, expr: \{checked_expr.ty}",
      )
    }
  }
  let type_kind = self.ensure_type(type_kind)
  let ty = Type::{ kind: type_kind, mutable: true }
  let checked_stmt = LetMutStmt::{
    name: stmt.name,
    ty: type_kind,
    expr: checked_expr,
  }
  self.type_env.set(stmt.name, ty)
  checked_stmt
}
