
test "Parse Simple Apply Expr Test" {
  let code =
    #|42 3.14 true false
    #|foo bar
  let tokens = @lexer.tokenize(code)
  let (a, tok_view) = parse_apply_expr(tokens[:])
  assert_true(a.kind is AtomExpr(atom) && atom.kind is Int(42))
  let (a, tok_view) = parse_apply_expr(tok_view)
  assert_true(a.kind is AtomExpr(atom) && atom.kind is Double(3.14))
  let (a, tok_view) = parse_apply_expr(tok_view)
  assert_true(a.kind is AtomExpr(atom) && atom.kind is Bool(true))
  let (a, tok_view) = parse_apply_expr(tok_view)
  assert_true(a.kind is AtomExpr(atom) && atom.kind is Bool(false))
  let (a, tok_view) = parse_apply_expr(tok_view)
  assert_true(a.kind is AtomExpr(atom) && atom.kind is Ident("foo"))
  let (a, _) = parse_apply_expr(tok_view)
  assert_true(a.kind is AtomExpr(atom) && atom.kind is Ident("bar"))
}
