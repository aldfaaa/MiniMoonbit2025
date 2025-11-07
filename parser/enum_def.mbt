
///|
pub struct EnumDef {
  name: String
  enum_fields: Array[EnumField]
} derive(Show, Eq)

pub struct EnumField {
  name: String
  types: Array[Type]
} derive(Show, Eq)

///|
pub fn parse_enum_field(
  tokens: ArrayView[Token]
) -> (EnumField, ArrayView[Token]) raise ParseError {
  guard tokens is [{kind: Upper(name), ..} as name_tok, ..tokens] else {
    raise ParseError("Expected enum field name")
  }
  let types: Array[Type] = Array::new()
  let mut last_tok = Some(name_tok)
  guard tokens is [ { kind: Bracket('('), ..}, .. rest] else {
    return (EnumField::{name, types}, tokens)
  }
  let rest = loop rest {
    [{ kind: Bracket(')'), ..} as rparen_tok, ..rest] => {
      last_tok = Some(rparen_tok)
      break rest
    }
    [{ kind: Upper(_), ..}, ..] as tokens => {
      let (ty, rest) = parse_type(tokens)
      types.push(ty)
      if rest is [{ kind: Symbol(","), ..}, ..rest] {
        continue rest
      }
      continue rest
    }
    [] => {
      raise ParseError("Unclosed bracket in enum field types")
    }
    [tok, ..] => {
      @lexer.throw_(tok, "Expected type in enum field types", Error)
      raise ParseError("Unexpected token in enum field types")
    }
  }
  let enum_field = EnumField::{name, types}
  let rest = if rest is [{ kind: Symbol(";"), ..}, ..rest] {
    rest
  } else if rest is [tok, ..] && tok.line != last_tok.unwrap().line {
    rest
  } else {
    rest
  }
  (enum_field, rest)
}

pub fn parse_enum_def(
  tokens: ArrayView[Token]
) -> (EnumDef, ArrayView[Token]) raise ParseError {
  guard tokens is [{kind: Keyword(Enum), ..}, ..tokens] else {
    println("Compiler ICE: Misuse parse_enum_def")
    panic()
  }
  guard tokens is [{kind: Upper(name), ..}, .. tokens] else {
    raise ParseError("Expected enum name")
  }
  guard tokens is [{ kind: Bracket('{'), ..}, .. rest] else {
    raise ParseError("Expected '{' after enum name")
  }
  let enum_fields: Array[EnumField] = Array::new()
  let rest = loop rest {
    [{ kind: Bracket('}'), ..}, ..rest] => break rest
    [] => {
      raise ParseError("Unclosed enum definition")
    }
    tokens => {
      let (enum_field, rest) = parse_enum_field(tokens)
      enum_fields.push(enum_field)
      continue rest
    }
  }
  let enum_def = EnumDef::{name, enum_fields}
  (enum_def, rest)
}
