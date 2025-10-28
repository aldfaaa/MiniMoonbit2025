///|
pub(all) struct IfExpr {
  cond : Expr
  then_block : BlockExpr
  else_block : Either[IfExpr, BlockExpr]?
  ty : TypeKind
} derive(Show)

///|
pub fn Context::check_if_expr(
  self : Context,
  if_expr : @parser.IfExpr,
) -> IfExpr raise TypeCheckError {
  let checked_cond = self.check_expr(if_expr.cond)
  // Ensure the condition is of boolean type
  if !(checked_cond.ty is Bool) {
    raise TypeCheckError("If condition must be of boolean type")
  }
  let checked_then_block = self.check_block_expr(if_expr.then_block)
  let then_type = checked_then_block.ty
  let checked_else_block = match if_expr.else_block {
    Some(Left(else_if_expr)) => {
      let checked_else_if = self.check_if_expr(else_if_expr)
      if !self.is_type_compatible(then_type, checked_else_if.ty) {
        raise TypeCheckError(
          "Type mismatch between then block and else-if block",
        )
      }
      Some(Either::Left(checked_else_if))
    }
    Some(Right(else_block)) => {
      let checked_else = self.check_block_expr(else_block)
      if !self.is_type_compatible(then_type, checked_else.ty) {
        raise TypeCheckError("Type mismatch between then block and else block")
      }
      Some(Right(checked_else))
    }
    None => None
  }
  let ty = self.ensure_type(then_type)
  IfExpr::{
    cond: checked_cond,
    then_block: checked_then_block,
    else_block: checked_else_block,
    ty,
  }
}
