
pub(all) struct ForStmt {
  inits: Array[(String, Expr)]
  cond: Expr // if parser cond is None, this is Bool::true
  steps: Array[(String, AssignOp, Expr)]
  body: BlockExpr
} derive(Show)

pub fn Context::check_for_stmt(
  self : Context,
  for_stmt : @parser.ForStmt,
) -> ForStmt raise TypeCheckError {
  ignore(self);
  ignore(for_stmt);
  raise TypeCheckError("for statement type checking not yet implemented");
}

