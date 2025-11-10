///|
pub(all) struct Pattern {
  kind : PatternKind
} derive(Show, Eq)

///|
pub(all) enum PatternKind {
  Wildcard
  Integer(Int)
  Ident(String)
  Tuple(Array[Pattern])
  EnumVariant(String?, String, Array[Pattern])
} derive(Show, Eq)

///|
pub fn parse_pattern(
  tokens : ArrayView[Token],
) -> (Pattern, ArrayView[Token]) raise ParseError {
  match tokens {
    [{ kind: Wildcard, .. }, .. tokens] => {
      let pattern = Pattern::{ kind: Wildcard }
      (pattern, tokens)
    }
    [{ kind: Lower(ident), .. }, .. tokens] => {
      let pattern = Pattern::{ kind: Ident(ident) }
      (pattern, tokens)
    }
    [{ kind: Int(v), ..}, ..tokens] => {
      let pattern = Pattern::{ kind: Integer(v) }
      (pattern, tokens)
    }
    [{ kind: Upper(name1), ..}, .. tokens] => {
      let (tag, enum_name, tokens) = if tokens is [{ kind: Symbol("::"), .. }, ..tokens] {
        guard tokens is [{ kind: Upper(name2), .. }, ..tokens] else {
          @lexer.throw_(tokens[0], "Parse Error: InValid Pattern", Error)
          raise ParseError("InValid Pattern")
        }
        (Some(name1), name2, tokens)
      } else {
        (None, name1, tokens)
      }
      let patterns: Array[Pattern] = Array::new()
      guard tokens is [{ kind: Bracket('('), .. } as tok, ..tokens] else {
        let patternkind = EnumVariant(tag, enum_name, patterns)
        let pattern = Pattern::{ kind: patternkind }
        return (pattern, tokens)
      }
      let tokens = loop tokens {
        [{ kind: Bracket(')'), .. }, .. tokens] => break tokens
        [{ kind: Int(_) | Lower(_) | Wildcard | Bracket('(') | Upper(_), .. }, ..] as tokens => {
          let (pat, rest) = parse_pattern(tokens)
          patterns.push(pat)
          continue rest
        }
        [
          { kind: Symbol(","), .. },
          { kind: Int(_) | Lower(_) | Wildcard | Bracket('(') | Bracket(')') | Upper(_), .. },
          ..,
        ] as tokens => continue tokens[1:]
        [] => {
          println("Compiler ICE: Failed Parsing Pattern Empty Token ArrayView")
          panic()
        }
        tokens => {
          raise ParseError("InValid Pattern: \{tokens[0]}")
        }
      }
      let kind = if patterns.length() == 0 {
        @lexer.throw_(tok, "Parse Error: InValid Pattern", Error)
        raise ParseError("InValid Pattern")
      } else {
        PatternKind::EnumVariant(tag, enum_name, patterns)
      }
      let pattern = Pattern::{ kind, }
      (pattern, tokens)
    }
    [{ kind: Bracket('('), .. } as tok, .. tokens] => {
      let patterns : Array[Pattern] = Array::new()
      let tokens = loop tokens {
        [{ kind: Bracket(')'), .. }, .. tokens] => break tokens
        [{ kind: Lower(_) | Wildcard | Bracket('(') | Upper(_), .. }, ..] as tokens => {
          let (pat, rest) = parse_pattern(tokens)
          patterns.push(pat)
          continue rest
        }
        [
          { kind: Symbol(","), .. },
          { kind: Lower(_) | Wildcard | Bracket('(') | Bracket(')') | Upper(_), .. },
          ..,
        ] as tokens => continue tokens[1:]
        [] => {
          println("Compiler ICE: Failed Parsing Pattern Empty Token ArrayView")
          panic()
        }
        tokens => raise ParseError("InValid Pattern: \{tokens[0]}")
      }
      let kind = if patterns.length() == 0 {
        @lexer.throw_(tok, "Parse Error: InValid Pattern", Error)
        raise ParseError("InValid Pattern")
      } else if patterns.length() == 1 {
        @lexer.throw_(tok, "Warning: Should Not use tuple pattern for single pattern", Warning)
        patterns[0].kind
      } else {
        PatternKind::Tuple(patterns)
      }
      let pattern = Pattern::{ kind, }
      (pattern, tokens)
    }
    [] => {
      println("Compiler ICE: Empty Token ArrayView")
      panic()
    }
    [tok, ..] => {
      @lexer.throw_(tok, "Parse Error: InValid Pattern", Error)
      raise ParseError("InValid Pattern")
    }
  }
}
