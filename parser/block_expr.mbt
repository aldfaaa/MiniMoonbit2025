///|
pub(all) struct BlockExpr {
  stmts : Array[Stmt]
  toks: ArrayView[Token]
} derive(Show, Eq)

///|
pub fn parse_block_expr(
  tokens : ArrayView[Token],
) -> (BlockExpr, ArrayView[Token]) {
  let init_tokens = tokens
  guard tokens is [{ kind: Bracket('{'), .. }, .. tokens] else {
    println("Compiler ICE: Misuse parse_block_expr")
    panic()
  }
  let stmts : Array[Stmt] = Array::new()
  let tokens = loop tokens {
    [{ kind: Bracket('}'), .. }, .. rest] => break rest
    [] => {
      println("Compiler ICE: Failed Parsing BlockExpr, Empty Token ArrayView")
      panic()
    }
    tokens => {
      let (stmt, tokens) = parse_stmt(tokens)
      stmts.push(stmt)
      continue tokens
    }
  }
  let len = tokens.start_offset() - init_tokens.start_offset()
  let toks = init_tokens[0:len]
  let block_expr = BlockExpr::{ stmts, toks }
  (block_expr, tokens)
}
