///|
pub fn Context::block_codegen(
  self : Self,
  block : @knf.KnfBlock,
) -> &@llvm.Value? raise {
  // add branch inst
  let current_bb = self.builder.getInsertBlock()
  let current_func = current_bb.getParent()
  let block_bb = current_func.addBasicBlock()
  let after_bb = current_func.addBasicBlock()
  let _ = self.builder.createBr(block_bb)
  self.builder.setInsertPoint(block_bb)
  let stmts_cnt = block.stmts.length()
  if stmts_cnt == 0 {
    let _ = self.builder.createBr(after_bb)
    self.builder.setInsertPoint(after_bb)
    return None
  }
  if block.ty is Unit {
    for stmt in block.stmts {
      self.stmt_codegen(stmt)
    }
    let _ = self.builder.createBr(after_bb)
    self.builder.setInsertPoint(after_bb)
    return None
  } else {
    for stmt in block.stmts[:stmts_cnt - 1] {
      self.stmt_codegen(stmt)
    }
    let ret_v = match block.stmts.last().unwrap() {
      ExprStmt(expr) => {
        let v = self.expr_codegen(expr)
        v
      }
      stmt => {
        self.stmt_codegen(stmt)
        None
      }
    }
    let _ = self.builder.createBr(after_bb)
    self.builder.setInsertPoint(after_bb)
    ret_v
  }
}
