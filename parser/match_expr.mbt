pub struct MatchExpr {
  cond: Expr
  arms: Array[MatchArm]
} derive(Show, Eq)

pub struct MatchArm {
  pattern: Pattern
  match_guard: Expr?
  body: Expr
  toks: ArrayView[Token]
} derive(Show, Eq)

pub fn parse_match_expr(
  tokens: ArrayView[Token]
) -> (MatchExpr, ArrayView[Token]) raise ParseError {
  guard tokens is [{ kind: Keyword(Match), .. }, ..tokens] else {
    println("Compiler ICE: Misuse `parse_match_expr`, start token is not `match` keyword")
    panic()
  }
  let (expr, tokens) = parse_expr(tokens)
  guard tokens is [{ kind: Bracket('{'), .. } as tok, ..tokens] else {
    @lexer.throw_(tokens[0], "Parse Error: Expected `{` after match expression", Error)
    raise ParseError("Expected `{` after match expression")
  }
  let match_arms: Array[MatchArm] = Array::new()
  let tokens = loop tokens {
    [{ kind: Bracket('}'), .. }, ..tokens] => break tokens
    [] => {
      @lexer.throw_(tok, "Parse Error: Expected `}` to close match expression", Error)
      raise ParseError("Expected `}` to close match expression")
    }
    tokens => {
      let (arm, rest) = parse_match_arm(tokens)
      match_arms.push(arm)
      continue rest
    }
  }
  let match_expr = MatchExpr::{
    cond: expr,
    arms: match_arms,
  }
  (match_expr, tokens)
}

pub fn parse_match_arm(
  tokens: ArrayView[Token]
) -> (MatchArm, ArrayView[Token]) raise ParseError {
  let init_tokens = tokens
  let (pattern, tokens) = parse_pattern(tokens)
  let (guard_, tokens) = match tokens {
    [{ kind: Keyword(If), .. }, ..rest] => {
      let (guard_expr, rest) = parse_expr(rest)
      (Some(guard_expr), rest)
    }
    tokens => (None, tokens)
  }
  guard tokens is [{ kind: Symbol("=>"), .. }, ..rest] else {
    @lexer.throw_(tokens[0], "Parse Error: Expected `=>` in match arm", Error)
    raise ParseError("Expected `=>` in match arm")
  }
  let (body_expr, tokens) = parse_expr(rest)
  let toks = init_tokens[0:(tokens.start_offset() - init_tokens.start_offset())]
  let match_arm = MatchArm::{
    pattern: pattern,
    match_guard: guard_,
    body: body_expr,
    toks: toks,
  }
  let tokens = if tokens is [{ kind: Symbol(";"), .. }, ..tokens] {
    tokens
  } else if tokens is [tok, ..] && tok.line != body_expr.toks[body_expr.toks.length() - 1].line {
    tokens
  } else {
    tokens
  }
  (match_arm, tokens)
}
