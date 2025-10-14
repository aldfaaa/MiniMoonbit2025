
test "Binary Expr Parsing Test" {
  let code = 
    #|1 + 2 * 3 ;
    #|4 * 5 - 6 / 2 ;
    #|a && b || c && d ;
    #|x << 2 + y >> 3 ;
    #|p > q != r < s
  let tokens = @lexer.tokenize(code)
  let (e, tok_view) = parse_expr(tokens[:])
  assert_true(
    e.kind is BinaryExpr(Add, left, right) &&
    left.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Int(1) &&
    right.kind is BinaryExpr(Mul, left, right) &&
    left.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Int(2) &&
    right.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Int(3)
  )
  let (e, tok_view) = parse_expr(tok_view[1:])
  assert_true(
    e.kind is BinaryExpr(Sub, left1, right1) &&
    left1.kind is BinaryExpr(Mul, left2, right2) &&
    left2.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Int(4) &&
    right2.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Int(5) &&
    right1.kind is BinaryExpr(Div, left3, right3) &&
    left3.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Int(6) &&
    right3.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Int(2)
  )
  let (e, tok_view) = parse_expr(tok_view[1:])
  assert_true(
    e.kind is BinaryExpr(Or, left1, right1) &&
    left1.kind is BinaryExpr(And, left2, right2) &&
    left2.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Ident("a") &&
    right2.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Ident("b") &&
    right1.kind is BinaryExpr(And, left3, right3) &&
    left3.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Ident("c") &&
    right3.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Ident("d")
  )
  let (e, tok_view) = parse_expr(tok_view[1:])
  assert_true(
    e.kind is BinaryExpr(ShiftRight, left1, right1) &&
    left1.kind is BinaryExpr(ShiftLeft, left2, right2) &&
    left2.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Ident("x") &&
    right2.kind is BinaryExpr(Add, left3, right3) &&
    left3.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Int(2) &&
    right3.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Ident("y") &&
    right1.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Int(3)
  )
  let (e, _) = parse_expr(tok_view[1:])
  assert_true(
    e.kind is BinaryExpr(NE, left1, right1) &&
    left1.kind is BinaryExpr(GT, left2, right2) &&
    left2.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Ident("p") &&
    right2.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Ident("q") &&
    right1.kind is BinaryExpr(LT, left3, right3) &&
    left3.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Ident("r") &&
    right3.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Ident("s")
  )
}
