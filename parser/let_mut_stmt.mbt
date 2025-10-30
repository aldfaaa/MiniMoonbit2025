///|
pub(all) struct LetMutStmt {
  name : String
  ty : Type?
  expr : Expr
} derive(Show, Eq)

///|
pub fn parse_let_mut_stmt(
  tokens : ArrayView[Token],
) -> (LetMutStmt, ArrayView[Token]) raise ParseError {
  guard tokens
    is [{ kind: Keyword(Let), .. }, { kind: Keyword(Mut), .. }, .. tokens] else {
    println("Compiler ICE: Misuse parse_let_mut_stmt")
    panic()
  }
  guard tokens is [{ kind: Lower(name), .. }, .. tokens] else {
    @lexer.throw_(tokens[0], "Parse Error: Expect a lower ident", Error)
    raise ParseError("Expect a lower ident")
  }
  let (ty, tokens) = if tokens is [{ kind: Symbol(":"), .. }, .. tokens] {
    let (ty, tokens) = parse_type(tokens)
    (Some(ty), tokens)
  } else {
    (None, tokens)
  }
  guard tokens is [{ kind: AssignOp(Assign), .. }, .. tokens] else {
    @lexer.throw_(tokens[0], "Parse Error: Expect '='", Error)
    let line = tokens[0].line
    let rest = loop tokens {
      [{ kind: Symbol(";"), .. }, .. tokens] => break tokens
      [tok, ..] as tokens if tok.line != line => break tokens
      [{ kind: Bracket('}'), .. }, ..] as tokens => break tokens
      [] as tokens => break tokens
      [_, .. tokens] => continue tokens
    }
    let expr = Expr::unit()
    let let_mut_stmt = LetMutStmt::{ name, ty, expr }
    return (let_mut_stmt, rest)
  }
  let (expr, tokens) = parse_expr(tokens)
  let let_mut_stmt = LetMutStmt::{ name, ty, expr }
  let tokens = if tokens is [{ kind: Symbol(";"), .. }, .. tokens] {
    tokens
  } else if tokens is [tok, ..] && tok.line != expr.toks[expr.toks.length() - 1].line {
    tokens
  } else if tokens is [{ kind: Bracket('}'), .. }, ..] {
    tokens
  } else {
    @lexer.throw_(tokens[0], "Parse Error: Expect ';' or '}' or newline after let mut statement", Error)
    tokens
  }
  (let_mut_stmt, tokens)
}
