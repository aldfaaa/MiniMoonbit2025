
test "Tokenize String" {
  let code =
    #|"Hello"
    #|"This is a test string"
    #|"Hello world!"
    #|"MiniMoonbit2025"
  let tokens = tokenize(code)
  assert_true(tokens.length() is 5)
  assert_true(tokens[0].kind is String("Hello"))
  assert_true(tokens[1].kind is String("This is a test string"))
  assert_true(tokens[2].kind is String("Hello world!"))
  assert_true(tokens[3].kind is String("MiniMoonbit2025"))
  assert_true(tokens[4].kind is EOF)
}
