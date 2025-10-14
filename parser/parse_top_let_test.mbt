test "Top Let Parsing Test" {
  let code = 
    #|let x: Int = 42;
    #|let y: Bool = true;
    #|let z: Array[Int] = [1, 2, 3];
  
  let tokens = @lexer.tokenize(code)
  let (s, tok_view) = parse_top_let(tokens)
  assert_true(
    s.name is "x" &&
    s.ty is Some(ty) &&
    ty.kind is Int &&
    s.expr.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Int(42)
  )
  let (s, tok_view) = parse_top_let(tok_view)
  assert_true(
    s.name is "y" &&
    s.ty is Some(ty) &&
    ty.kind is Bool &&
    s.expr.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Bool(true)
  )
  let (s, _) = parse_top_let(tok_view)
  assert_true(
    s.name is "z" &&
    s.ty is Some(ty) &&
    ty.kind is Array(Int) &&
    s.expr.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Array([e1, e2, e3]) &&
    e1.kind is ApplyExpr(a1) &&
    a1.kind is AtomExpr(atom1) &&
    atom1.kind is Int(1) &&
    e2.kind is ApplyExpr(a2) &&
    a2.kind is AtomExpr(atom2) &&
    atom2.kind is Int(2) &&
    e3.kind is ApplyExpr(a3) &&
    a3.kind is AtomExpr(atom3) &&
    atom3.kind is Int(3)
  )
}


