///|
pub(all) struct BlockExpr {
  stmts : Array[Stmt]
  ty : TypeKind
} derive(Show)

///|
pub fn Context::check_block_expr(
  self : Context,
  block_expr : @parser.BlockExpr,
) -> BlockExpr raise TypeCheckError {
  self.enter_scope()
  let checked_stmts = Array::new()
  for stmt in block_expr.stmts {
    let checked_stmt = self.check_stmt(stmt)
    checked_stmts.push(checked_stmt)
  }
  self.exit_scope()
  let tykind = if checked_stmts.length() > 0 {
    match checked_stmts[checked_stmts.length() - 1].kind {
      StmtKind::ExprStmt(expr) => expr.ty
      StmtKind::ReturnStmt(_) => Any
      _ => Unit
    }
  } else {
    Unit
  }
  BlockExpr::{ stmts: checked_stmts, ty: tykind }
}
