test "Let Mut Stmt Parsing Test" {
  let code = 
    #|let mut x : Int = 42;
    #|let mut y = 100;
    #|let mut z : (Int, Double) = (1, 2.0);

  let tokens = @lexer.tokenize(code)
  let (s, tok_view) = parse_let_mut_stmt(tokens)
  assert_true(
    s.name is "x" &&
    s.ty is Some(ty) &&
    ty.kind is Int &&
    s.expr.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Int(42)
  )
  let (s, tok_view) = parse_let_mut_stmt(tok_view)
  assert_true(
    s.name is "y" &&
    s.ty is None &&
    s.expr.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Int(100)
  )
  let (s, _) = parse_let_mut_stmt(tok_view)
  assert_true(
    s.name is "z" &&
    s.ty is Some(ty) &&
    ty.kind is Tuple(tys) &&
    tys is [ty1, ty2] &&
    ty1 is Int &&
    ty2 is Double &&
    s.expr.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Tuple(es) &&
    es is [e1, e2] &&
    e1.kind is ApplyExpr(a1) &&
    a1.kind is AtomExpr(atom1) &&
    atom1.kind is Int(1) &&
    e2.kind is ApplyExpr(a2) &&
    a2.kind is AtomExpr(atom2) &&
    atom2.kind is Double(2.0)
  )
}

