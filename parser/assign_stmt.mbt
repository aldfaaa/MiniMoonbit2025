///|
pub(all) struct AssignStmt {
  left_value : LeftValue
  op : AssignOp
  expr : Expr
} derive(Show, Eq)

///|
pub(all) enum AssignOp {
  Assign // =
  PlusAssign // +=
  MinusAssign // -=
  MultAssign // *=
  DivAssign // /=
  ModAssign // %=
} derive(Show, Eq)

///|
fn AssignOp::from_tok_assign_op(op : @lexer.AssignOp) -> AssignOp {
  match op {
    Assign => Assign
    PlusAssign => PlusAssign
    MinusAssign => MinusAssign
    MultAssign => MultAssign
    DivAssign => DivAssign
    ModAssign => ModAssign
  }
}

///|
pub fn parse_assign_stmt(
  tokens : ArrayView[Token],
) -> (AssignStmt, ArrayView[Token]) raise ParseError {
  let (left_value, tokens) = parse_left_value(tokens)
  guard tokens is [{ kind: AssignOp(op), .. }, .. tokens] else {
    @lexer.throw_(tokens[0], "Parse Error: Expect an assign operator", Error)
    raise ParseError("Expect an assign operator")
  }
  let op = AssignOp::from_tok_assign_op(op)
  let (expr, tokens) = parse_expr(tokens)
  let assign_stmt = AssignStmt::{ left_value, op, expr }
  let tokens = if tokens is [{ kind: Symbol(";"), .. }, .. tokens] {
    tokens
  } else if tokens is [tok, ..] && tok.line != expr.toks[expr.toks.length() - 1].line {
    tokens
  } else if tokens is [{ kind: Bracket('}'), .. }, ..] {
    tokens
  } else {
    @lexer.throw_(tokens[0], "Parse Error: Expect ';' or '} or newline after assign statement", Error)
    raise ParseError("Expect ';' or '}' or newline after assign statement")
  }
  (assign_stmt, tokens)
}
