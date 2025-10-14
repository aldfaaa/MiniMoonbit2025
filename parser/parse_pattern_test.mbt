
test "Pattern Parsing Test" {
  let code = 
    #|_
    #|a
    #|(a, b, _)
    #|(a, (b, c), _)
    #|((a, b), (c, d))

  let tokens = @lexer.tokenize(code)
  let (p, tok_view) = parse_pattern(tokens[:])
  assert_true(p.kind is Wildcard)
  let (p, tok_view) = parse_pattern(tok_view)
  assert_true(p.kind is Ident("a"))
  let (p, tok_view) = parse_pattern(tok_view)
  assert_true(
    p.kind is Tuple(ps) &&
    ps is [p1, p2, p3] &&
    p1.kind is Ident("a") &&
    p2.kind is Ident("b") &&
    p3.kind is Wildcard
  )
  let (p, tok_view) = parse_pattern(tok_view)
  assert_true(
    p.kind is Tuple(ps) &&
    ps is [p1, p2, p3] &&
    p1.kind is Ident("a") &&
    p2.kind is Tuple(ps2) &&
    ps2 is [p21, p22] &&
    p21.kind is Ident("b") &&
    p22.kind is Ident("c") &&
    p3.kind is Wildcard
  )
  let (p, _) = parse_pattern(tok_view)
  assert_true(
    p.kind is Tuple(ps) &&
    ps is [p1, p2] &&
    p1.kind is Tuple(ps1) &&
    ps1 is [p11, p12] &&
    p11.kind is Ident("a") &&
    p12.kind is Ident("b") &&
    p2.kind is Tuple(ps2) &&
    ps2 is [p21, p22] &&
    p21.kind is Ident("c") &&
    p22.kind is Ident("d")
  )
}

