///|
test "Tuple, Paren and Unit Expr Parisng Test " {
  let code =
    #|(42, 3.14, true)
    #|(foo)
    #|((3.15, false))
    #|()
    #|((), ())
  let tokens = @lexer.tokenize(code)
  let (a, tok_view) = parse_atom_expr(tokens[:])
  assert_true(
    a.kind is Tuple(tup) &&
    tup is [e1, e2, e3] &&
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
    a.kind is Paren(expr) &&
    expr.kind is ApplyExpr(app) &&
    app.kind is AtomExpr(atom) &&
    atom.kind is Ident("foo"),
  )
  let (a, tok_view) = parse_atom_expr(tok_view)
  assert_true(
    a.kind is Paren(expr) &&
    expr.kind is ApplyExpr(app) &&
    app.kind is AtomExpr(atom) &&
    atom.kind is Tuple(tup) &&
    tup is [e1, e2] &&
    e1.kind is ApplyExpr(app1) &&
    app1.kind is AtomExpr(atom1) &&
    atom1.kind is Double(3.15) &&
    e2.kind is ApplyExpr(app2) &&
    app2.kind is AtomExpr(atom2) &&
    atom2.kind is Bool(false),
  )
  let (a, tok_view) = parse_atom_expr(tok_view)
  assert_true(a.kind is Unit)
  let (a, _) = parse_atom_expr(tok_view)
  assert_true(
    a.kind is Tuple(tup) &&
    tup is [e1, e2] &&
    e1.kind is ApplyExpr(app1) &&
    app1.kind is AtomExpr(atom1) &&
    atom1.kind is Unit &&
    e2.kind is ApplyExpr(app2) &&
    app2.kind is AtomExpr(atom2) &&
    atom2.kind is Unit,
  )
}
