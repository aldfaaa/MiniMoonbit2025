test "Simple Expr Parsing Test" {
  let code = 
    #|42 3.14 true false
    #|a
  let tokens = @lexer.tokenize(code)
  let (e, tok_view) = parse_expr(tokens[:])
  assert_true(
    e.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Int(42)
  )
  let (e, tok_view) = parse_expr(tok_view)
  assert_true(
    e.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Double(3.14)
  )
  let (e, tok_view) = parse_expr(tok_view)
  assert_true(
    e.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Bool(true)
  )
  let (e, tok_view) = parse_expr(tok_view)
  assert_true(
    e.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Bool(false)
  )
  let (e, _) = parse_expr(tok_view)
  assert_true(
    e.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Ident("a")
  )
}


