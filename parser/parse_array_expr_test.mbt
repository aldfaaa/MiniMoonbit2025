///|
test "Array Expr Parsing Test" {
  let code =
    #|[42, 3.14, true]
    #|[foo, bar, baz]
    #|[ 1 + 3]
  let tokens = @lexer.tokenize(code)
  let (a, tok_view) = parse_atom_expr(tokens[:])
  assert_true(
    a.kind is AtomExprKind::Array(exprs) &&
    exprs is [e1, e2, e3] &&
    e1.kind is ApplyExpr(app1) &&
    app1.kind is AtomExpr(atom1) &&
    atom1.kind is Int(42) &&
    e2.kind is ApplyExpr(app2) &&
    app2.kind is AtomExpr(atom2) &&
    atom2.kind is Double(3.14) &&
    e3.kind is ApplyExpr(app3) &&
    app3.kind is AtomExpr(atom3) &&
    atom3.kind is Bool(true),
  )
  let (a, tok_view) = parse_atom_expr(tok_view)
  assert_true(
    a.kind is AtomExprKind::Array(exprs) &&
    exprs is [e1, e2, e3] &&
    e1.kind is ApplyExpr(app1) &&
    app1.kind is AtomExpr(atom1) &&
    atom1.kind is Ident("foo") &&
    e2.kind is ApplyExpr(app2) &&
    app2.kind is AtomExpr(atom2) &&
    atom2.kind is Ident("bar") &&
    e3.kind is ApplyExpr(app3) &&
    app3.kind is AtomExpr(atom3) &&
    atom3.kind is Ident("baz"),
  )
  let (a, _) = parse_atom_expr(tok_view)
  assert_true(
    a.kind is AtomExprKind::Array(exprs) &&
    exprs is [e1] &&
    e1.kind is BinaryExpr(Add, left, right) &&
    left.kind is ApplyExpr(app1) &&
    app1.kind is AtomExpr(atom1) &&
    atom1.kind is Int(1) &&
    right.kind is ApplyExpr(app2) &&
    app2.kind is AtomExpr(atom2) &&
    atom2.kind is Int(3),
  )
}
