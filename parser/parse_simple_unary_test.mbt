test "Unary Expr Parsing Test" {
  let code = 
    #|-42 ;
    #|!true ;
    #|-res ;
    #|!cond ;
  let tokens = @lexer.tokenize(code)
  let (e, tok_view) = parse_expr(tokens[:])
  assert_true(
    e.kind is NegExpr(inner) &&
    inner.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Int(42)
  )
  let (e, tok_view) = parse_expr(tok_view[1:])
  assert_true(
    e.kind is NotExpr(inner) &&
    inner.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Bool(true)
  )
  let (e, tok_view) = parse_expr(tok_view[1:])
  assert_true(
    e.kind is NegExpr(inner) &&
    inner.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Ident("res")
  )
  let (e, _) = parse_expr(tok_view[1:])
  assert_true(
    e.kind is NotExpr(inner) &&
    inner.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Ident("cond")
  )
}


