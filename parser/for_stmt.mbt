
///|
///
/// Ast - For Statement
///
/// ```mbt
/// let code =
///   #|for i = 0; i < 10; i += 1 {
///   #|  println(i);
///   #|}
///
/// let toks = @lexer.tokenize(code)
///
/// let (for_stmt, _) = parse_for_stmt(toks)
/// assert_true(for_stmt.inits.length() is 1)
/// assert_true(
///   for_stmt.inits[0] is ("i", {kind: ApplyExpr(a), ..}) &&
///   a is {kind: AtomExpr(a), ..} &&
///   a is {kind: Int(0), ..}
/// )
/// assert_true(
///   for_stmt.cond is Some({kind: BinaryExpr(LT, left, right), ..}) &&
///   left is {kind: ApplyExpr(a1), ..} &&
///   right is {kind: ApplyExpr(a2), ..} &&
///   a1 is {kind: AtomExpr(a1), ..} &&
///   a1 is {kind: Ident("i"), ..} &&
///   a2 is {kind: AtomExpr(a2), ..} &&
///   a2 is {kind: Int(10), ..}
/// )
/// assert_true(for_stmt.steps.length() is 1)
/// assert_true(
///   for_stmt.steps[0] is ("i", PlusAssign, {kind: ApplyExpr(a), ..}) &&
///   a is {kind: AtomExpr(a), ..} &&
///   a is {kind: Int(1), ..}
/// )
/// ```
pub struct ForStmt {
  inits: Array[(String, Expr)]
  cond: Expr?
  steps: Array[(String, AssignOp, Expr)]
  body: BlockExpr
} derive(Show, Eq)

///|
pub fn parse_for_stmt(
  tokens: ArrayView[Token]
) -> (ForStmt, ArrayView[Token]) raise ParseError {
  guard tokens is [{ kind: Keyword(For), .. }, .. tokens] else {
    println("Compiler ICE: Misuse parse_for_stmt")
    panic()
  }
  let inits : Array[(String, Expr)] = Array::new()
  let tokens = loop tokens {
    [{ kind: Lower(name), .. }, { kind: AssignOp(Assign), .. }, .. tokens] => {
      let (expr, rest) = parse_expr(tokens)
      inits.push((name, expr))
      continue rest
    }
    [
      { kind: Symbol(","), .. },
      { kind: Lower(name), .. },
      { kind: AssignOp(Assign), .. },
      .. tokens,
    ] => {
      let (expr, rest) = parse_expr(tokens)
      inits.push((name, expr))
      continue rest
    }
    [{ kind: Symbol(";"), .. }, .. tokens] => break tokens
    [] => {
      println("Compiler ICE: Incomplete for statement")
      panic()
    }
    [tok, ..] => {
      @lexer.throw_(tok, "Parse Error: Invalid init statement in for loop", Error)
      raise ParseError("Invalid init statement in for loop")
    }
  }
  let (cond, tokens) = if tokens is [{ kind: Symbol(";"), .. }, .. tokens] {
    (None, tokens[1:])
  } else {
    let (expr, tokens) = parse_expr(tokens)
    guard tokens is [{ kind: Symbol(";"), .. }, ..tokens] else {
      @lexer.throw_(tokens[0], "Parse Error: Failed Parsing For Stmt, Expect ';'", Error)
      raise ParseError("Failed Parsing For Stmt, Expect ';'")
    }
    (Some(expr), tokens)
  }
  let steps : Array[(String, AssignOp, Expr)] = Array::new()
  let tokens = loop tokens {
    [{ kind: Lower(name), .. }, { kind: AssignOp(op), .. }, .. tokens] => {
      let (expr, rest) = parse_expr(tokens)
      let op = AssignOp::from_tok_assign_op(op)
      steps.push((name, op, expr))
      continue rest
    }
    [
      { kind: Symbol(","), .. },
      { kind: Lower(name), .. },
      { kind: AssignOp(op), .. },
      .. tokens,
    ] => {
      let (expr, rest) = parse_expr(tokens)
      let op = AssignOp::from_tok_assign_op(op)
      steps.push((name, op, expr))
      continue rest
    }
    [{ kind: Bracket('{'), .. }, ..] as tokens => break tokens
    [] => {
      println("Compiler ICE: Incomplete for statement")
      panic()
    }
    [tok, ..] => {
      @lexer.throw_(tok, "Parse Error: Invalid step statement in for loop", Error)
      raise ParseError("Invalid step statement in for loop")
    }
  }
  let (body, tokens) = parse_block_expr(tokens)
  let for_stmt = ForStmt::{ inits, cond, steps, body }
  (for_stmt, tokens)
}
