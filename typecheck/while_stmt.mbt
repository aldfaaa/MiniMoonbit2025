///|
pub(all) struct WhileStmt {
  cond : Expr
  body : BlockExpr
} derive(Show)

///|
pub fn Context::check_while_stmt(
  self : Context,
  while_stmt : @parser.WhileStmt,
) -> WhileStmt raise TypeCheckError {
  let checked_cond = self.check_expr(while_stmt.cond)
  // Ensure the condition is of boolean type
  if !(checked_cond.ty is Bool) {
    raise TypeCheckError("While condition must be of boolean type")
  }
  let checked_body = self.check_block_expr(while_stmt.body)
  WhileStmt::{ cond: checked_cond, body: checked_body }
}
