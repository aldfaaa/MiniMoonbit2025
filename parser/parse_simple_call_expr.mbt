test "Simple Call Expr Parsing Test" {
  let code = 
    #|foo()
    #|bar(42, true)
    #|qux(1 + 3)

  let tokens = @lexer.tokenize(code)
  let (a, tok_view) = parse_apply_expr(tokens[:])
  assert_true(
    a.kind is ApplyExprKind::Call(callee, args) &&
    args is [] &&
    callee.kind is AtomExpr(callee_atom) &&
    callee_atom.kind is AtomExprKind::Ident("foo")
  )
  let (a, tok_view) = parse_apply_expr(tok_view)
  assert_true(
    a.kind is ApplyExprKind::Call(callee, args) &&
    args is [arg1, arg2] &&
    arg1.kind is ApplyExpr(arg1_app) &&
    arg1_app.kind is AtomExpr(arg1_atom) &&
    arg1_atom.kind is AtomExprKind::Int(42) &&
    arg2.kind is ApplyExpr(arg2_app) &&
    arg2_app.kind is AtomExpr(arg2_atom) &&
    arg2_atom.kind is AtomExprKind::Bool(true) &&
    callee.kind is AtomExpr(callee_atom) &&
    callee_atom.kind is AtomExprKind::Ident("bar")
  )
  let (a, _) = parse_apply_expr(tok_view)
  assert_true(
    a.kind is ApplyExprKind::Call(callee, args) &&
    args is [arg1] &&
    arg1.kind is BinaryExpr(Add, left, right) &&
    left.kind is ApplyExpr(left_app) &&
    left_app.kind is AtomExpr(left_atom) &&
    left_atom.kind is AtomExprKind::Int(1) &&
    right.kind is ApplyExpr(right_app) &&
    right_app.kind is AtomExpr(right_atom) &&
    right_atom.kind is AtomExprKind::Int(3) &&
    callee.kind is AtomExpr(callee_atom) &&
    callee_atom.kind is AtomExprKind::Ident("qux")
  )
}

