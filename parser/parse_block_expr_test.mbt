
test "Block Expr Parsing" {
  let code = 
    #|{
    #|  let x = 10;
    #|  let mut y = 20;
    #|  y = y + x;
    #|  let t = Array::make(5, 0);
    #|  t[0] = y;
    #|}

  let tokens = @lexer.tokenize(code)
  let (block, _) = parse_block_expr(tokens)
  assert_true(block.stmts.length() is 5)
  assert_true(block.stmts[0].kind is LetStmt(_))
  assert_true(block.stmts[1].kind is LetMutStmt(_))
  assert_true(block.stmts[2].kind is AssignStmt(_))
  assert_true(block.stmts[3].kind is LetStmt(_))
  assert_true(block.stmts[4].kind is AssignStmt(_))
}

