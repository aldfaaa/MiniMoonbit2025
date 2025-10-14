///|
test "MiniMoonBit Challenge 3: Tokenize Keyword" {
  let code =
    #|fn let mut if else struct return _
  let tokens = tokenize(code)
  assert_true(tokens.length() is 9)
  assert_true(tokens[0].kind is Keyword(Fn))
  assert_true(tokens[1].kind is Keyword(Let))
  assert_true(tokens[2].kind is Keyword(Mut))
  assert_true(tokens[3].kind is Keyword(If))
  assert_true(tokens[4].kind is Keyword(Else))
  assert_true(tokens[5].kind is Keyword(Struct))
  assert_true(tokens[6].kind is Keyword(Return))
  assert_true(tokens[7].kind is Wildcard)
  assert_true(tokens[8].kind is EOF)
}
