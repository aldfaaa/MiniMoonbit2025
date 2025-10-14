test "Parse While Stmt Test" {
  let code = 
    #|while a < b { a += 1; b -=2; }
    #|while a < b { println(a); a += b % 3; } 

  let tokens = @lexer.tokenize(code)
  let (while_stmt1, tok_view) = parse_while_stmt(tokens[:])
  assert_true(while_stmt1.body.stmts.length() is 2)
  let (while_stmt2, _) = parse_while_stmt(tok_view)
  assert_true(while_stmt2.body.stmts.length() is 2)
}

