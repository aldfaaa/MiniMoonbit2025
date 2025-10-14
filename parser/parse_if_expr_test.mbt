test "Parse If Expr Test" {
  let code = 
    #|if a < b { return a; }
    #|if a < b { return a; } else { return b; }
    #|if a > b { a; } else if a == b { 0; } else { b; }

  let tokens = @lexer.tokenize(code)
  let (if_expr1, tok_view) = parse_if_expr(tokens[:])
  assert_true(if_expr1.then_block.stmts.length() is 1)
  assert_true(if_expr1.else_block is None)
  let (if_expr2, tok_view) = parse_if_expr(tok_view)
  assert_true(if_expr2.then_block.stmts.length() is 1)
  assert_true(
    if_expr2.else_block is Some(else_block) &&
    else_block is Right(_)
  )
  let (if_expr3, _) = parse_if_expr(tok_view)
  assert_true(if_expr3.then_block.stmts.length() is 1)
  assert_true(
    if_expr3.else_block is Some(else_block) &&
    else_block is Left(else_if) &&
    else_if.then_block.stmts.length() is 1 &&
    else_if.else_block is Some(else_block2) &&
    else_block2 is Right(_) 
  )
}

