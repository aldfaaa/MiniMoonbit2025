///|
pub(all) struct Expr {
  kind : ExprKind
  toks : ArrayView[Token]
} derive(Show, Eq)

///|
pub(all) enum ExprKind {
  ApplyExpr(ApplyExpr)
  BlockExpr(BlockExpr)
  NotExpr(Expr)
  NegExpr(Expr)
  BinaryExpr(BinaryOp, Expr, Expr)
  IfExpr(IfExpr)
  MatchExpr(MatchExpr)
} derive(Show, Eq)

fn Expr::unit() -> Expr {
  let apply_unit = ApplyExpr::unit()
  Expr::{ kind: ApplyExpr(apply_unit), toks: apply_unit.toks }
}

///|
pub fn Expr::new(
  kind : ExprKind,
  init_tokens : ArrayView[Token],
  rest_tokens : ArrayView[Token],
) -> Expr {
  let len = rest_tokens.start_offset() - init_tokens.start_offset()
  let toks = init_tokens[0:len]
  Expr::{ kind, toks }
}

pub fn Expr::new_binary(
  bop : BinaryOp,
  init_tokens : ArrayView[Token],
  left : Expr,
  right : Expr,
) -> Expr {
  let init_offset = init_tokens.start_offset()
  let lhs_offset = left.toks.start_offset()
  let total_len = left.toks.length() + right.toks.length()
  let lhs_init_offset = lhs_offset - init_offset
  let toks = init_tokens[lhs_init_offset:(lhs_init_offset + total_len)]
  Expr::{ kind: ExprKind::BinaryExpr(bop, left, right), toks }
}

///|
pub(all) enum BinaryOp {
  Add // +
  Sub // -
  Mul // *
  Div // /
  Mod // %
  ShiftLeft // <<
  ShiftRight // >>
  Eq // ==
  NE // !=
  LT // <
  GT // >
  LE // <=
  GE // >=
  And // &&
  Or // ||
  BitAnd // &
  BitOr // |
} derive(Show, Eq)

///|
pub fn BinaryOp::from_tok_binary_op(tok_bin_op : @lexer.BinaryOp) -> BinaryOp {
  match tok_bin_op {
    Add => Add
    Sub => Sub
    Mul => Mul
    Div => Div
    Mod => Mod
    ShiftLeft => ShiftLeft
    ShiftRight => ShiftRight
    Eq => Eq
    NE => NE
    LT => LT
    GT => GT
    LE => LE
    GE => GE
    And => And
    Or => Or
    BitAnd => BitAnd
    BitOr => BitOr
  }
}

///|
pub fn parse_expr(
  tokens : ArrayView[Token],
) -> (Expr, ArrayView[Token]) raise ParseError {
  let init_tokens = tokens
  guard tokens is [tok, ..] else {
    println("Compiler ICE: Empty Token ArrayView")
    panic()
  }
  match tok.kind {
    Keyword(If) => {
      let (if_expr, rest) = parse_if_expr(tokens)
      let expr = Expr::new(ExprKind::IfExpr(if_expr), init_tokens, rest)
      return (expr, rest)
    }
    Keyword(Match) => {
      let (match_expr, rest) = parse_match_expr(tokens)
      let expr = Expr::new(ExprKind::MatchExpr(match_expr), init_tokens, rest)
      return (expr, rest)
    }
    Bracket('{') => {
      let (block, rest) = parse_block_expr(tokens)
      let expr = Expr::new(ExprKind::BlockExpr(block), init_tokens, rest)
      return (expr, rest)
    }
    _ => ()
  }
  let op_stack : @deque.Deque[BinaryOp] = @deque.Deque::new()
  let expr_stack : @deque.Deque[Expr] = @deque.Deque::new()

  // Parse unary expression (Not or Neg) or apply expression
  let (head_expr, tokens) = match tokens {
    [{ kind: Not, .. }, .. rest] as tokens => {
      let init_tokens = rest
      let (apply_expr, rest) = parse_apply_expr(rest)
      let expr = Expr::new(ApplyExpr(apply_expr), init_tokens, rest)
      let not_expr = Expr::new(NotExpr(expr), tokens, rest)
      (not_expr, rest)
    }
    [{ kind: BinaryOp(Sub), .. }, .. rest] as tokens => {
      let init_tokens = rest
      let (apply_expr, rest) = parse_apply_expr(rest)
      let expr = Expr::new(ApplyExpr(apply_expr), init_tokens, rest)
      let neg_expr = Expr::new(ExprKind::NegExpr(expr), tokens, rest)
      (neg_expr, rest)
    }
    tokens => {
      let init_tokens = tokens
      let (apply_expr, tokens) = parse_apply_expr(tokens)
      let expr = Expr::new(ExprKind::ApplyExpr(apply_expr), init_tokens, tokens)
      (expr, tokens)
    }
  }
  expr_stack.push_back(head_expr)
  let mut tokens = tokens
  while tokens is [{ kind: BinaryOp(op), .. }, .. rest] {
    // Parse unary expression or apply expression after binary operator
    let (next_expr, rest) = match rest {
      [{ kind: Not, .. }, .. rest] as tokens => {
      let init_tokens = rest
        let (apply_expr, rest) = parse_apply_expr(rest)
        let expr = Expr::new(ExprKind::ApplyExpr(apply_expr), init_tokens, rest)
        let not_expr = Expr::new(ExprKind::NotExpr(expr), tokens, rest)
        (not_expr, rest)
      }
      [{ kind: BinaryOp(Sub), .. }, .. rest] as tokens => {
        let init_tokens = rest
        let (apply_expr, rest) = parse_apply_expr(rest)
        let expr = Expr::new(ExprKind::ApplyExpr(apply_expr), init_tokens, rest)
        let neg_expr = Expr::new(ExprKind::NegExpr(expr), tokens, rest)
        (neg_expr, rest)
      }
      tokens => {
        let init_tokens = tokens
        let (apply_expr, rest) = parse_apply_expr(rest)
        let expr = Expr::new(ExprKind::ApplyExpr(apply_expr), init_tokens, rest)
        (expr, rest)
      }
    }
    let op = BinaryOp::from_tok_binary_op(op)
    while !op_stack.is_empty() &&
          op.precedence() <= op_stack.back().unwrap().precedence() {
      let right = expr_stack.pop_back().unwrap()
      let left = expr_stack.pop_back().unwrap()
      let bop = op_stack.pop_back().unwrap()
      let new_expr = Expr::new_binary(bop, init_tokens, left, right)
      expr_stack.push_back(new_expr)
    }
    op_stack.push_back(op)
    expr_stack.push_back(next_expr)
    tokens = rest
  }
  while !op_stack.is_empty() {
    let right = expr_stack.pop_back().unwrap()
    let left = expr_stack.pop_back().unwrap()
    let bop = op_stack.pop_back().unwrap()
    let new_expr = Expr::new_binary(bop, init_tokens, left, right)
    expr_stack.push_back(new_expr)
  }
  let expr = expr_stack.pop_back().unwrap()
  (expr, tokens)
}

///|
fn BinaryOp::precedence(self : Self) -> Int {
  match self {
    Or => 1
    And => 2
    Eq | NE => 3
    LT | GT | LE | GE => 4
    BitOr => 5
    BitAnd => 7
    ShiftLeft | ShiftRight => 8
    Add | Sub => 9
    Mul | Div | Mod => 10
  }
}

///|
fn parse_expr_list(
  tokens : ArrayView[Token],
) -> (Array[Expr], ArrayView[Token]) raise ParseError {
  let exprs : Array[Expr] = Array::new()
  let tokens = loop tokens {
    [{ kind: Bracket(')'), .. }, ..] as tokens => break tokens
    [{ kind: Symbol(","), .. }, { kind: Bracket(')'), .. }, ..] as tokens =>
      break tokens[1:]
    [{ kind: Symbol(","), .. }, .. tokens] => {
      let (expr, rest) = parse_expr(tokens)
      exprs.push(expr)
      continue rest
    }
    [] => {
      println("Compiler ICE: Empty Token ArrayView")
      panic()
    }
    tokens => {
      let (expr, rest) = parse_expr(tokens)
      exprs.push(expr)
      continue rest
    }
  }
  (exprs, tokens)
}
