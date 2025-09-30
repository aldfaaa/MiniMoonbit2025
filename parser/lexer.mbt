/////|
//pub suberror LexerError String derive(Show)
//
/////|
//pub enum Keyword {
//  Fn
//  Struct
//  Enum
//  Let
//  Mut
//  If
//  Else
//  Match
//  While
//  For
//  Return
//} derive(Show, Eq)
//
/////|
//pub enum Operator {
//  Plus        // +
//  Minus       // -
//  Mult        // *
//  Div         // /
//  Mod         // %
//  ShiftLeft   // <<
//  ShiftRight  // >>
//  Eq          // ==
//  NE          // !=
//  LT          // <
//  GT          // >
//  LE          // <=
//  GE          // >=
//  And         // &&
//  Or          // ||
//  BitAnd      // &
//  BitOr       // |
//  Not         // !
//} derive(Show, Eq)
//
//pub enum AssignOp {
//  Assign // =
//  PlusAssign // +=
//  MinusAssign // -=
//  MultAssign // *=
//  DivAssign // /=
//  ModAssign // %=
//} derive(Show, Eq, ToJson)
//
/////|
//pub enum Token {
//  Bool(Bool) // true, false
//  Int(Int) // 1, 42, -100
//  Int64(Int64) // 1L, 42L, -100L
//  UInt(UInt) // 1U, 42U, 100U
//  UInt64(UInt64) // 1UL, 42UL, 100UL
//  //Float(Float) // 1.0F, 3.14F
//  Double(Double)
//  Keyword(Keyword)
//  Upper(String)
//  Lower(String)
//  Operator(Operator) // +, -, *, /, %, =, ==, !=, <, >, <=, >=, &&, ||
//  AssignOp(AssignOp) // =, +=, -=, *=, /=, %=
//  Bracket(Char) // (, ), [, ], {, }
//  Dot // .
//  Comma
//  Colon
//  DoubleColon // ::
//  SemiColon // ;
//  LeftArrow // ->
//  BoldLeftArrow // =>
//  EOF
//} derive(Show, Eq)
//
/////|
//pub fn lex(code : String) -> Array[Token] raise {
//  let tokens = Array::new()
//  loop code[:] {
//    [] => {
//      tokens.push(EOF)
//      break tokens
//    }
//    [' ' | '\n' | '\r' | '\t', .. rest] => continue rest
//    [.. "//", .. rest] =>
//      continue loop rest {
//          ['\n' | '\r', .. rest_str] => break rest_str
//          [_, .. rest_str] => continue rest_str
//          [] as rest_str => break rest_str
//        }
//    [.. "::", .. rest] => {
//      tokens.push(DoubleColon)
//      continue rest
//    }
//    [.. "!=", .. rest] => {
//      tokens.push(Operator(NE))
//      continue rest
//    }
//    [.. "+=", .. rest] => {
//      tokens.push(AssignOp(PlusAssign))
//      continue rest
//    }
//    [.. "-=", .. rest] => {
//      tokens.push(AssignOp(MinusAssign))
//      continue rest
//    }
//    [.. "*=", .. rest] => {
//      tokens.push(AssignOp(MultAssign))
//      continue rest
//    }
//    [.. "/=", .. rest] => {
//      tokens.push(AssignOp(DivAssign))
//      continue rest
//    }
//    [.. "%=", .. rest] => {
//      tokens.push(AssignOp(ModAssign))
//      continue rest
//    }
//    [.. "->", .. rest] => {
//      tokens.push(LeftArrow)
//      continue rest
//    }
//    [.. "=>", .. rest] => {
//      tokens.push(BoldLeftArrow)
//      continue rest
//    }
//    [.. ">>", .. rest] => {
//      tokens.push(Operator(ShiftRight))
//      continue rest
//    }
//    [.. "<<", .. rest] => {
//      tokens.push(Operator(ShiftLeft))
//      continue rest
//    }
//    [.. "==", .. rest] => {
//      tokens.push(Operator(Eq))
//      continue rest
//    }
//    [.. "<=", .. rest] => {
//      tokens.push(Operator(LE))
//      continue rest
//    }
//    [.. ">=", .. rest] => {
//      tokens.push(Operator(GE))
//      continue rest
//    }
//    [.. "&&", .. rest] => {
//      tokens.push(Operator(And))
//      continue rest
//    }
//    [.. "||", .. rest] => {
//      tokens.push(Operator(Or))
//      continue rest
//    }
//    [';', .. rest] => {
//      tokens.push(SemiColon)
//      continue rest
//    }
//    [':', .. rest] => {
//      tokens.push(Colon)
//      continue rest
//    }
//    ['.', .. rest] => {
//      tokens.push(Dot)
//      continue rest
//    }
//    [',', .. rest] => {
//      tokens.push(Comma)
//      continue rest
//    }
//    ['!', .. rest] => {
//      tokens.push(Operator(Not))
//      continue rest
//    }
//    ['+', .. rest] => {
//      tokens.push(Operator(Plus))
//      continue rest
//    }
//    ['-', .. rest] => {
//      tokens.push(Operator(Minus))
//      continue rest
//    }
//    ['*', .. rest] => {
//      tokens.push(Operator(Mult))
//      continue rest
//    }
//    ['/', .. rest] => {
//      tokens.push(Operator(Div))
//      continue rest
//    }
//    ['%', .. rest] => {
//      tokens.push(Operator(Mod))
//      continue rest
//    }
//    ['&', .. rest] => {
//      tokens.push(Operator(BitAnd))
//      continue rest
//    }
//    ['|', .. rest] => {
//      tokens.push(Operator(BitOr))
//      continue rest
//    }
//    ['<', .. rest] => {
//      tokens.push(Operator(LT))
//      continue rest
//    }
//    ['>', .. rest] => {
//      tokens.push(Operator(GT))
//      continue rest
//    }
//    ['=', .. rest] => {
//      tokens.push(AssignOp(Assign))
//      continue rest
//    }
//    ['(', .. rest] => {
//      tokens.push(Bracket('('))
//      continue rest
//    }
//    [')', .. rest] => {
//      tokens.push(Bracket(')'))
//      continue rest
//    }
//    ['[', .. rest] => {
//      tokens.push(Bracket('['))
//      continue rest
//    }
//    [']', .. rest] => {
//      tokens.push(Bracket(']'))
//      continue rest
//    }
//    ['{', .. rest] => {
//      tokens.push(Bracket('{'))
//      continue rest
//    }
//    ['}', .. rest] => {
//      tokens.push(Bracket('}'))
//      continue rest
//    }
//    ['A'..='Z' as c, .. rest] => {
//      let ident = [c]
//      let rest_str = loop rest {
//        ['a'..='z' | 'A'..='Z' | '0'..='9' | '_' as c, .. rest_str] => {
//          ident.push(c)
//          continue rest_str
//        }
//        _ as rest_str => break rest_str
//      }
//      tokens.push(Token::Upper(String::from_array(ident)))
//      continue rest_str
//    }
//    ['a'..='z', ..] as code => {
//      let (tok, rest) = lex_lower_ident(code)
//      tokens.push(tok)
//      continue rest
//    }
//    ['0'..='9', ..] as code => {
//      let (tok, rest) = lex_number(code)
//      tokens.push(tok)
//      continue rest
//    }
//    other_strs =>
//      raise LexerError("Parse Error: Unexpected char: \{other_strs}")
//  }
//}
//
/////|
//pub fn lex_lower_ident(rest : @string.View) -> (Token, @string.View) {
//  let ident = Array::new()
//  let rest_str = loop rest {
//    ['a'..='z' | 'A'..='Z' | '0'..='9' | '_' as c, .. rest_str] => {
//      ident.push(c)
//      continue rest_str
//    }
//    _ as rest_str => break rest_str
//  }
//  let ident = String::from_array(ident)
//  let tok = match ident {
//    "fn" => Token::Keyword(Keyword::Fn)
//    "struct" => Token::Keyword(Keyword::Struct)
//    "enum" => Token::Keyword(Keyword::Enum)
//    "mut" => Token::Keyword(Keyword::Mut)
//    "let" => Token::Keyword(Keyword::Let)
//    "if" => Token::Keyword(Keyword::If)
//    "else" => Token::Keyword(Keyword::Else)
//    "match" => Token::Keyword(Keyword::Match)
//    "while" => Token::Keyword(Keyword::While)
//    "for" => Token::Keyword(Keyword::For)
//    "return" => Token::Keyword(Keyword::Return)
//    "true" => Token::Bool(true)
//    "false" => Token::Bool(false)
//    _ => Token::Lower(ident)
//  }
//  (tok, rest_str)
//}
//
/////|
//pub fn lex_number(rest : @string.View) -> (Token, @string.View) raise {
//  let mut has_dot = false
//  let num_chars = Array::new()
//  loop rest {
//    ['0'..='9' as c, .. rest_str] => {
//      num_chars.push(c)
//      continue rest_str
//    }
//    ['.', .. rest_str] if not(has_dot) => {
//      has_dot = true
//      num_chars.push('.')
//      continue rest_str
//    }
//    ['L', .. rest_str] => {
//      let num_str = String::from_array(num_chars)
//      let num = match (try? @strconv.parse_int64(num_str)) {
//        Ok(n) => n
//        Err(_) => raise LexerError("Parse Int64 failed: \{num_str}")
//      }
//      break (Token::Int64(num), rest_str)
//    }
//    [.. "UL", .. rest_str] => {
//      let num_str = String::from_array(num_chars)
//      let num = match (try? @strconv.parse_uint64(num_str)) {
//        Ok(n) => n
//        Err(_) => raise LexerError("Parse UInt64 failed: \{num_str}")
//      }
//      break (Token::UInt64(num), rest_str)
//    }
//    ['U', .. rest_str] => {
//      let num_str = String::from_array(num_chars)
//      let num = match (try? @strconv.parse_uint(num_str)) {
//        Ok(n) => n
//        Err(_) => raise LexerError("Parse UInt failed: \{num_str}")
//      }
//      break (Token::UInt(num), rest_str)
//    }
//    _ as rest if has_dot => {
//      let num_str = String::from_array(num_chars)
//      let num = match (try? @strconv.parse_double(num_str)) {
//        Ok(n) => n
//        Err(_) => raise LexerError("Parse Double failed: \{num_str}")
//      }
//      break (Token::Double(num), rest)
//    }
//    _ as rest => {
//      let num_str = String::from_array(num_chars)
//      let num = match (try? @strconv.parse_int(num_str)) {
//        Ok(n) => n
//        Err(_) => raise LexerError("Parse Int failed: \{num_str}")
//      }
//      break (Token::Int(num), rest)
//    }
//  }
//}
//
/////|
//test "lex" {
//  let code =
//    #|fn add(x: Int, y: Int) -> Int {
//    #|  return x + y - 342UL
//    #|}
//  let toks = lex(code)
//  let expect = [
//    Keyword(Fn),
//    Lower("add"),
//    Bracket('('),
//    Lower("x"),
//    Colon,
//    Upper("Int"),
//    Comma,
//    Lower("y"),
//    Colon,
//    Upper("Int"),
//    Bracket(')'),
//    LeftArrow,
//    Upper("Int"),
//    Bracket('{'),
//    Keyword(Return),
//    Lower("x"),
//    Operator(Plus),
//    Lower("y"),
//    Operator(Minus),
//    UInt64(342),
//    Bracket('}'),
//    EOF,
//  ]
//  assert_eq(toks, expect)
//}
