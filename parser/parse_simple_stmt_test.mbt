
test "Stmt Parsing Test" {
  let code = 
    #|let x = 5;
    #|let mut y = 10;
    #|y = y + x;
    #|y();
    #|println(123);
    #|print_int(foo(1, 2));
    #|foo.bar[3][4] = 42;
    #|return 0;
    #|return ;

  let tokens = @lexer.tokenize(code)
  let (s, tok_view) = parse_stmt(tokens[:])
  assert_true(s.kind is LetStmt(_))
  let (s, tok_view) = parse_stmt(tok_view)
  assert_true(s.kind is LetMutStmt(_))
  let (s, tok_view) = parse_stmt(tok_view)
  assert_true(s.kind is AssignStmt(_))
  let (s, tok_view) = parse_stmt(tok_view)
  assert_true(s.kind is ExprStmt(_))
  let (s, tok_view) = parse_stmt(tok_view)
  assert_true(s.kind is ExprStmt(_))
  let (s, tok_view) = parse_stmt(tok_view)
  assert_true(s.kind is ExprStmt(_))
  let (s, tok_view) = parse_stmt(tok_view)
  assert_true(s.kind is AssignStmt(_))
  let (s, tok_view) = parse_stmt(tok_view)
  assert_true(s.kind is ReturnStmt(_))
  let (s, _) = parse_stmt(tok_view)
  assert_true(s.kind is ReturnStmt(_))
}

