///|
pub(all) struct ApplyExpr {
  kind : ApplyExprKind
  toks : ArrayView[Token]
} derive(Show, Eq)

///|
pub(all) enum ApplyExprKind {
  AtomExpr(AtomExpr)
  ArrayAccess(ApplyExpr, Expr)
  FieldAccess(ApplyExpr, String)
  Call(ApplyExpr, Array[Expr])
} derive(Show, Eq)

///|
pub fn ApplyExpr::new(
  kind : ApplyExprKind,
  init_tokens : ArrayView[Token],
  rest_tokens : ArrayView[Token],
) -> ApplyExpr {
  let len = rest_tokens.start_offset() - init_tokens.start_offset()
  let toks = init_tokens[0:len]
  ApplyExpr::{ kind, toks }
}

///|
pub fn parse_apply_expr(
  tokens : ArrayView[Token],
) -> (ApplyExpr, ArrayView[Token]) raise ParseError {
  let init_tokens = tokens
  let (atom_expr, tokens) = parse_atom_expr(tokens)
  let apply_expr = ApplyExpr::new(AtomExpr(atom_expr), init_tokens, tokens)
  if !(tokens is [{ kind: Bracket('[') | Symbol(".") | Bracket('('), .. }, ..]) {
    return (apply_expr, tokens)
  }
  let mut apply_expr = apply_expr
  loop tokens {
    [{ kind: Bracket('['), .. }, .. tokens] => {
      let (index_expr, tokens) = parse_expr(tokens)
      guard tokens is [{ kind: Bracket(']'), .. }, .. tokens] else {
        raise ParseError("Expect ']'")
      }
      apply_expr = ApplyExpr::new(
        ArrayAccess(apply_expr, index_expr),
        init_tokens,
        tokens,
      )
      continue tokens
    }
    [{ kind: Symbol("."), .. }, { kind: Lower(field), .. }, .. tokens] => {
      apply_expr = ApplyExpr::new(
        FieldAccess(apply_expr, field),
        init_tokens,
        tokens,
      )
      continue tokens
    }
    [{ kind: Bracket('('), .. }, .. tokens] => {
      let (args, tokens) = parse_expr_list(tokens)
      guard tokens is [{ kind: Bracket(')'), .. }, .. tokens] else {
        raise ParseError("Expect ')'")
      }
      apply_expr = ApplyExpr::new(
        Call(apply_expr, args),
        init_tokens,
        tokens,
      )
      continue tokens
    }
    tokens => break (apply_expr, tokens)
  }
}
