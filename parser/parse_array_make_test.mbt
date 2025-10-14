test "Array Make Expr Parsing Test" {
  let code = 
   #|Array::make(10, 0)
   #|Array::make(5, true)

  let tokens = @lexer.tokenize(code)
  let (a, tok_view) = parse_atom_expr(tokens[:])
  assert_true(
    a.kind is AtomExprKind::ArrayMake(size_expr, init_expr) &&
    size_expr.kind is ApplyExpr(app1) &&
    app1.kind is AtomExpr(atom1) &&
    atom1.kind is Int(10) &&
    init_expr.kind is ApplyExpr(app2) &&
    app2.kind is AtomExpr(atom2) &&
    atom2.kind is Int(0)
  )
  let (a, _) = parse_atom_expr(tok_view)
  assert_true(
    a.kind is AtomExprKind::ArrayMake(size_expr, init_expr) &&
    size_expr.kind is ApplyExpr(app1) &&
    app1.kind is AtomExpr(atom1) &&
    atom1.kind is Int(5) &&
    init_expr.kind is ApplyExpr(app2) &&
    app2.kind is AtomExpr(atom2) &&
    atom2.kind is Bool(true)
  )
}

