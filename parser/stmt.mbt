///|
pub(all) struct Stmt {
  kind : StmtKind
  toks : ArrayView[Token]
} derive(Show, Eq)

///|
pub(all) enum StmtKind {
  LetStmt(LetStmt)
  LetMutStmt(LetMutStmt)
  AssignStmt(AssignStmt)
  WhileStmt(WhileStmt)
  ExprStmt(Expr)
  ReturnStmt(Expr?)
  LocalFunction(LocalFunction)
} derive(Show, Eq)

pub fn Stmt::new(
  kind : StmtKind,
  init_tokens : ArrayView[Token],
  rest_tokens : ArrayView[Token],
) -> Stmt {
  let len = rest_tokens.start_offset() - init_tokens.start_offset()
  let toks = init_tokens[0:len]
  Stmt::{ kind, toks }
}

///|
pub fn parse_stmt(
  tokens : ArrayView[Token],
) -> (Stmt, ArrayView[Token]) raise ParseError {
  let init_tokens = tokens
  match tokens {
    [{ kind: Keyword(Let), .. }, { kind: Keyword(Mut), .. }, ..] as tokens => {
      let (let_mut_stmt, rest) = parse_let_mut_stmt(tokens)
      let stmt = Stmt::new(LetMutStmt(let_mut_stmt), init_tokens, rest)
      (stmt, rest)
    }
    [{ kind: Keyword(Let), .. }, ..] as tokens => {
      let (let_stmt, rest) = parse_let_stmt(tokens)
      let stmt = Stmt::new(LetStmt(let_stmt), init_tokens, rest)
      (stmt, rest)
    }
    [{ kind: Keyword(Return), line, .. }, .. tokens] => {
      let (expr, rest) = if tokens is [{ kind: Symbol(";"), .. }, .. tokens] {
        (None, tokens)
      } else if tokens is [{ kind: Bracket('}'), .. }, ..] {
        // Allow return at end of function without semicolon
        (None, tokens)
      } else if tokens is [tok, ..] && tok.line != line {
        // New line after return keyword means no expression
        (None, tokens)
      } else {
        let (expr, tokens) = parse_expr(tokens)
        let tokens = if tokens is [{ kind: Symbol(";"), .. }, .. tokens] {
          tokens
        } else if tokens is [tok, ..] && tok.line != expr.toks[expr.toks.length() - 1].line {
          tokens
        } else {
          raise ParseError("Expect ';' or newline after return statement")
        }
        (Some(expr), tokens)
      }
      let stmt = Stmt::new(StmtKind::ReturnStmt(expr), init_tokens, rest)
      (stmt, rest)
    }
    // Assignment must start with a lower ident
    // but starting with a lower ident does not
    // mean it's an assignment.
    //
    // Hence need to parse a left value first and
    // check if it's followed by an assignment operator.
    [{ kind: Lower(_), .. }, ..] as tokens => {
      let (_, rest) = parse_left_value(tokens)
      if rest is [{ kind: AssignOp(_), .. }, ..] {
        let (assign_stmt, rest) = parse_assign_stmt(tokens)
        let stmt = Stmt::new(StmtKind::AssignStmt(assign_stmt), init_tokens, rest)
        (stmt, rest)
      } else {
        let (expr, rest) = parse_expr(tokens)
        let stmt = Stmt::new(StmtKind::ExprStmt(expr), init_tokens, rest)
        let rest = if rest is [{ kind: Symbol(";"), .. }, .. rest] {
          rest
        } else if rest is [{ kind: Bracket('}'), .. }, ..] {
          rest
        } else if rest is [tok, ..] && tok.line != expr.toks[expr.toks.length() - 1].line {
          // Allow newline after expression statement
          rest
        } else {
          raise ParseError("Expected ';' or a newline after expression statement")
        }
        (stmt, rest)
      }
    }
    [{ kind: Keyword(While), .. }, ..] as tokens => {
      let (while_stmt, rest) = parse_while_stmt(tokens)
      let stmt = Stmt::new(StmtKind::WhileStmt(while_stmt), init_tokens, rest)
      (stmt, rest)
    }
    [{ kind: Keyword(Fn), .. }, ..] as tokens => {
      let (local_function, rest) = parse_local_function(tokens)
      let stmt = Stmt::new(StmtKind::LocalFunction(local_function), init_tokens, rest)
      (stmt, rest)
    }
    [] => {
      println("Compiler ICE: Empty Token ArrayView")
      panic()
    }
    tokens => {
      let (expr, rest) = parse_expr(tokens)
      let stmt = Stmt::new(StmtKind::ExprStmt(expr), init_tokens, rest)
      let rest = if rest is [{ kind: Symbol(";"), .. }, .. rest] {
        rest
      } else if rest is [{ kind: Bracket('}'), .. }, ..] {
        rest
      } else if rest is [tok, ..] && tok.line != expr.toks[expr.toks.length() - 1].line {
        // Allow newline after expression statement
        rest
      } else {
        raise ParseError("Expected ';' after expression statement")
      }
      (stmt, rest)
    }
  }
}
