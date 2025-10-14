///|
pub(all) struct Expr {
  kind : ExprKind
} derive(Show, Eq)

///|
pub(all) enum ExprKind {
  ApplyExpr(ApplyExpr)
  BlockExpr(BlockExpr)
  NotExpr(Expr)
  NegExpr(Expr)
  BinaryExpr(BinaryOp, Expr, Expr)
  IfExpr(IfExpr)
} derive(Show, Eq)

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

pub fn BinaryOp::from_tok_binary_op(tok_bin_op: @lexer.BinaryOp) -> BinaryOp {
  match tok_bin_op{
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


pub fn parse_expr(
  tokens : ArrayView[Token],
) -> (Expr, ArrayView[Token]) raise ParseError {
  guard tokens is [tok, ..] else {
    println("Compiler ICE: Empty Token ArrayView")
    panic()
  }
  match tok.kind {
    Keyword(If) => {
      let (if_expr, rest) = parse_if_expr(tokens)
      let expr = Expr::{
        kind: ExprKind::IfExpr(if_expr),
      }
      return (expr, rest)
    }
    Bracket('{') => {
      let (block, rest) = parse_block_expr(tokens)
      let expr = Expr::{
        kind: ExprKind::BlockExpr(block),
      }
      return (expr, rest)
    }
    Not => {
      let (expr, rest) = parse_expr(tokens[1:])
      let not_expr = Expr::{
        kind: ExprKind::NotExpr(expr),
      }
      return (not_expr, rest)
    }
    BinaryOp(Sub) => {
      let (expr, rest) = parse_expr(tokens[1:])
      let neg_expr = Expr::{
        kind: ExprKind::NegExpr(expr),
      }
      return (neg_expr, rest)
    }
    _ => ()
  }
  let op_stack : @deque.Deque[BinaryOp] = @deque.Deque::new()
  let expr_stack : @deque.Deque[Expr] = @deque.Deque::new()
  let (apply_expr, tokens) = parse_apply_expr(tokens)
  let head_expr = Expr::{
    kind: ExprKind::ApplyExpr(apply_expr),
  }
  expr_stack.push_back(head_expr)
  let mut tokens = tokens
  while tokens is [{ kind: BinaryOp(op) }, .. rest] {
    let (apply_expr, rest) = parse_apply_expr(rest)
    let next_expr = Expr::{
      kind: ExprKind::ApplyExpr(apply_expr),
    }
    let op = BinaryOp::from_tok_binary_op(op)
    while !op_stack.is_empty() &&
          op.precedence() <= op_stack.back().unwrap().precedence() {
      let right = expr_stack.pop_back().unwrap()
      let left = expr_stack.pop_back().unwrap()
      let bop = op_stack.pop_back().unwrap()
      let new_expr = Expr::{
        kind: ExprKind::BinaryExpr(bop, left, right),
      }
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
    let new_expr = Expr::{
      kind: ExprKind::BinaryExpr(bop, left, right),
    }
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

