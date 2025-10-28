///|
pub fn Context::apply_expr_to_knf(
  self : Context,
  apply_expr : @typecheck.ApplyExpr,
) -> (Array[KnfStmt], KnfExpr) raise KnfTransformError {
  match apply_expr.kind {
    AtomExpr(atom_expr) => self.atom_expr_to_knf(atom_expr)
    ArrayAccess(array_expr, index_expr) => {
      let (stmts, array_knf_expr) = self.apply_expr_to_knf(array_expr)
      let (index_stmts, index_knf_expr) = self.expr_to_knf(index_expr)
      stmts.append(index_stmts)
      let array_type = self.typekind_to_knf(array_expr.ty)
      let array_name = self.expr_to_knf_name(array_knf_expr, array_type, stmts)
      let index_type = self.typekind_to_knf(index_expr.ty)
      let index_name = self.expr_to_knf_name(index_knf_expr, index_type, stmts)
      (stmts, ArrayAccess(array_name, index_name))
    }
    FieldAccess(struct_expr, field_name) => {
      let (stmts, struct_knf_expr) = self.apply_expr_to_knf(struct_expr)
      let struct_type = self.typekind_to_knf(struct_expr.ty)
      let struct_name = self.expr_to_knf_name(
        struct_knf_expr, struct_type, stmts,
      )
      (stmts, FieldAccess(struct_name, field_name))
    }
    Call(callee_expr, exprs) => {
      let stmts : Array[KnfStmt] = []
      let (callee_stmts, callee_knf_expr) = self.apply_expr_to_knf(callee_expr)
      stmts.append(callee_stmts)
      let callee_type = self.typekind_to_knf(callee_expr.ty)
      let callee_name = self.expr_to_knf_name(
        callee_knf_expr, callee_type, stmts,
      )
      let arg_names : Array[Name] = []
      for expr in exprs {
        let (expr_stmts, expr_knf_expr) = self.expr_to_knf(expr)
        stmts.append(expr_stmts)
        let expr_type = self.typekind_to_knf(expr.ty)
        let expr_name = self.expr_to_knf_name(expr_knf_expr, expr_type, stmts)
        arg_names.push(expr_name)
      }
      (stmts, Call(callee_name, arg_names))
    }
  }
}
