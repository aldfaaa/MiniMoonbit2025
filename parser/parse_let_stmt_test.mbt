
test "Let Stmt Parsing Test" {
  let code = 
    #|let x : Int = 42;
    #|let (a, b) = (1, 2);
    #|let _ = println();
    #|let (_, (p, q)) = (r, s);


  let tokens = @lexer.tokenize(code)
  let (s, tok_view) = parse_let_stmt(tokens)
  assert_true(
    s.pattern.kind is Ident("x") &&
    s.ty is Some(ty) &&
    ty.kind is Int &&
    s.expr.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Int(42)
  )
  let (s, tok_view) = parse_let_stmt(tok_view)
  assert_true(
    s.pattern.kind is Tuple(ps) &&
    ps is [p1, p2] &&
    p1.kind is Ident("a") &&
    p2.kind is Ident("b") &&
    s.ty is None &&
    s.expr.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Tuple(es) &&
    es is [e1, e2] &&
    e1.kind is ApplyExpr(a1) &&
    a1.kind is AtomExpr(atom1) &&
    atom1.kind is Int(1) &&
    e2.kind is ApplyExpr(a2) &&
    a2.kind is AtomExpr(atom2) &&
    atom2.kind is Int(2)
  )
  let (s, tok_view) = parse_let_stmt(tok_view)
  assert_true(
    s.pattern.kind is Wildcard &&
    s.ty is None &&
    s.expr.kind is ApplyExpr(a) &&
    a.kind is Call(callee, []) &&
    callee.kind is AtomExpr(atom) &&
    atom.kind is Ident("println")
  )
  let (s, _) = parse_let_stmt(tok_view)
  assert_true(
    s.pattern.kind is Tuple(ps) &&
    ps is [p1, p2] &&
    p1.kind is Wildcard &&
    p2.kind is Tuple(ps2) &&
    ps2 is [p21, p22] &&
    p21.kind is Ident("p") &&
    p22.kind is Ident("q") &&
    s.ty is None &&
    s.expr.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Tuple(es) &&
    es is [e1, e2] &&
    e1.kind is ApplyExpr(a1) &&
    a1.kind is AtomExpr(atom1) &&
    atom1.kind is Ident("r") &&
    e2.kind is ApplyExpr(a2) &&
    a2.kind is AtomExpr(atom2) &&
    atom2.kind is Ident("s")
  )
}
