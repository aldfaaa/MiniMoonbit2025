///|
pub fn Context::while_stmt_to_knf(
  self : Context,
  while_stmt : @typecheck.WhileStmt,
) -> Array[KnfStmt] raise KnfTransformError {
  // Transform condition expression
  let (cond_stmts, cond_knf_expr) = self.expr_to_knf(while_stmt.cond)
  cond_stmts.push(KnfStmt::ExprStmt(cond_knf_expr))
  let cond_ty = self.typekind_to_knf(while_stmt.cond.ty)
  let cond_block = KnfBlock::{ stmts: cond_stmts, ty: cond_ty }

  // Transform body block
  let body_block = self.block_expr_to_knf(while_stmt.body)
  [KnfStmt::While(cond_block, body_block)]
}

pub fn Context::for_stmt_to_knf(
  self : Context,
  for_stmt : @typecheck.ForStmt,
) -> Array[KnfStmt] raise KnfTransformError {
  ignore(self);
  ignore(for_stmt);
  raise KnfTransformError("for loops are not supported in KNF transformation yet")
}
