///|
test "Simple AtomExpr Parsing Test" {
  let code =
    #|42 3.14 true false
    #|foo bar "hello minimoonbit"
  let tokens = @lexer.tokenize(code)
  let (a, tok_view) = parse_atom_expr(tokens[:])
  assert_true(a.kind is Int(42))
  let (a, tok_view) = parse_atom_expr(tok_view)
  assert_true(a.kind is Double(3.14))
  let (a, tok_view) = parse_atom_expr(tok_view)
  assert_true(a.kind is Bool(true))
  let (a, tok_view) = parse_atom_expr(tok_view)
  assert_true(a.kind is Bool(false))
  let (a, tok_view) = parse_atom_expr(tok_view)
  assert_true(a.kind is Ident("foo"))
  let (a, tok_view) = parse_atom_expr(tok_view)
  assert_true(a.kind is Ident("bar"))
  let (a, _) = parse_atom_expr(tok_view)
  assert_true(a.kind is String("hello minimoonbit"))
}
