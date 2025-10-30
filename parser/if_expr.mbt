///|
pub(all) struct IfExpr {
  cond : Expr
  then_block : BlockExpr
  else_block : Either[IfExpr, BlockExpr]?
  toks: ArrayView[Token]
} derive(Show, Eq)

///|
pub fn parse_if_expr(
  tokens : ArrayView[Token],
) -> (IfExpr, ArrayView[Token]) raise ParseError {
  let init_tokens = tokens
  guard tokens is [{ kind: Keyword(If), .. }, .. tokens] else {
    println("Compiler ICE: Misuse parse_if_expr")
    panic()
  }
  let (cond, tokens) = parse_expr(tokens)
  let (then_block, tokens) = parse_block_expr(tokens)
  let (else_block, tokens) = if tokens
    is [{ kind: Keyword(Else), .. }, .. tokens] {
    if tokens is [{ kind: Keyword(If), .. }, ..] {
      let (else_if, tokens) = parse_if_expr(tokens)
      (Some(Either::Left(else_if)), tokens)
    } else {
      guard tokens is [{ kind: Bracket('{'), .. }, ..] else {
        @lexer.throw_(tokens[0], "Parse Error: Expect '{' after else", Error)
        raise ParseError("Expect '{' after else")
      }
      let (else_block, tokens) = parse_block_expr(tokens)
      (Some(Either::Right(else_block)), tokens)
    }
  } else {
    (None, tokens)
  }
  let len = tokens.start_offset() - init_tokens.start_offset()
  let toks = init_tokens[0:len]
  let if_expr = IfExpr::{ cond, then_block, else_block, toks }
  (if_expr, tokens)
}
