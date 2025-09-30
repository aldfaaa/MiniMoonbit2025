/////|
//pub suberror ParserError String derive(Show)
//
/////| Parser Type
///// PType :=
/////   Unit
/////   | Bool
/////   | Int
/////   | Int64
/////   | UInt
/////   | UInt64
/////   | Float
/////   | Double
/////   | String
/////   | '(' PType (',' PType)* ')'
/////   | '(' PType (',' PType)* ')' '->' PType
/////   | upper_string '[' PType (',' PType)* ']'
/////   | upper_string
//pub enum PType {
//  Unit
//  Bool
//  Int
//  Int64
//  UInt
//  UInt64
//  Float
//  Double
//  String
//  Tuple(Array[PType])
//  Generic(String, Array[PType])
//  Function(Array[PType], PType)
//  UserDefine(String)
//} derive(Show, Eq, ToJson)
//
/////|
//pub fn parse_type(
//  tokens : ArrayView[Token],
//) -> (PType, ArrayView[Token]) raise ParserError {
//  match tokens {
//    [Upper("Unit"), .. toks] => (PType::Unit, toks)
//    [Upper("Bool"), .. toks] => (Bool, toks)
//    [Upper("Int"), .. toks] => (Int, toks)
//    [Upper("Int64"), .. toks] => (Int64, toks)
//    [Upper("UInt"), .. toks] => (UInt, toks)
//    [Upper("UInt64"), .. toks] => (UInt64, toks)
//    [Upper("Float"), .. toks] => (Float, toks)
//    [Upper("Double"), .. toks] => (Double, toks)
//    [Upper("String"), .. toks] => (String, toks)
//    [Bracket('('), ..] as toks => {
//      let (types, rest) = parse_tuple(toks)
//      match rest {
//        [LeftArrow, .. rest] => {
//          let (return_type, rest2) = parse_type(rest)
//          (PType::Function(types, return_type), rest2)
//        }
//        _ => (PType::Tuple(types), rest)
//      }
//    }
//    [Upper(_), Bracket('['), ..] as toks => {
//      let (generic_type, rest) = parse_generic(toks)
//      (generic_type, rest)
//    }
//    [Upper(name), .. toks] => (UserDefine(name), toks)
//    _ => raise ParserError("Invalid type representation")
//  }
//}
//
//// tuple_type := '(' PType (',' PType)* ')'
//
/////|
//pub fn parse_tuple(
//  tokens : ArrayView[Token],
//) -> (Array[PType], ArrayView[Token]) raise ParserError {
//  guard tokens is [Bracket(RoundOpen), .. tokens] else {
//    raise ParserError("Expected '(' to start a tuple type")
//  }
//  let types : Array[PType] = Array::new()
//  let rest = loop tokens {
//    [Comma, .. rest] => continue rest
//    [Bracket(RoundClose), .. rest] => break rest
//    tokens => {
//      let (type_repr, rest) = parse_type(tokens)
//      types.push(type_repr)
//      continue rest
//    }
//  }
//  (types, rest)
//}
//
//// generic_type := upper_string '[' PType (',' PType)* ']'
//
/////|
//pub fn parse_generic(
//  tokens : ArrayView[Token],
//) -> (PType, ArrayView[Token]) raise ParserError {
//  guard tokens is [Upper(name), Bracket(SquareOpen), .. tokens] else {
//    raise ParserError("Expected a generic type with square brackets")
//  }
//  let types : Array[PType] = Array::new()
//  let rest = loop tokens {
//    [Comma, .. rest] => continue rest
//    [Bracket(SquareClose), .. rest] => break rest
//    tokens => {
//      let (type_repr, rest) = parse_type(tokens)
//      types.push(type_repr)
//      continue rest
//    }
//  }
//  (PType::Generic(name, types), rest)
//}
//
/////|
//test "PType Parsing" {
//  let code_expects : Map[String, PType] = {
//    "(Int, Int64, Bool, String)": Tuple([Int, Int64, Bool, String]),
//    "Array[(Int, String)]": Generic("Array", [Tuple([Int, String])]),
//    "Array[(Int, Double) -> Int64]": Generic("Array", [
//      Function([Int, Double], Int64),
//    ]),
//    "(Int) -> String": Function([Int], String),
//    "(Int, String) -> Bool": Function([Int, String], Bool),
//    "(Int, Int64) -> (String, Bool)": Function(
//      [Int, Int64],
//      Tuple([String, Bool]),
//    ),
//    "(Int, Int64) -> Set[Bool]": Function([Int, Int64], Generic("Set", [Bool])),
//    "Map[Int, String]": Generic("Map", [Int, String]),
//    "Set[Bool]": Generic("Set", [Bool]),
//    "Map[Int, Int64]": Generic("Map", [Int, Int64]),
//    "(Int, Int64) -> Bool": Function([Int, Int64], Bool),
//    "Option[Int]": Generic("Option", [Int]),
//    "Result[String, Int]": Generic("Result", [String, Int]),
//    "Map[Bool, Int64]": Generic("Map", [Bool, Int64]),
//    "(Int) -> (String, Bool)": Function([Int], Tuple([String, Bool])),
//    "(Int, String) -> Set[Bool]": Function(
//      [Int, String],
//      Generic("Set", [Bool]),
//    ),
//  }
//  for code, expect in code_expects {
//    let (actual, _) = code |> lex |> parse_type
//    assert_eq(
//      actual,
//      expect,
//      msg="Parsing failed for code: \{code}, expected: \{expect}, got: \{actual}",
//    )
//  }
//}
//
//// ================================================
//// AtomExpr
//// ================================================
//
//type BlockExpr Array[Stmt] derive(Show, Eq, ToJson)
//
/////|
//pub(all) enum AtomExpr {
//  Bool(Bool)
//  Int(Int)
//  Int64(Int64)
//  UInt(UInt)
//  UInt64(UInt64)
//  Double(Double)
//  Var(String) // e.g. x
//  Tuple(Array[Expr]) // e.g. (1, 2, 3)
//  Array(Array[Expr]) // e.g. [1, 2, 3]
//  Paren(Expr) // e.g. (1 + 2)
//  Call(String, Array[Expr]) // e.g. func(arg1, arg2)
//  If(Expr, BlockExpr, BlockExpr?) // e.g. if (x > 0) { ... } else { ... }
//  BlockExpr(BlockExpr) // e.g. { let x = 1; x + 2; }
//} derive(Show, Eq, ToJson)
//
//fn parse_atom_expr(tokens: ArrayView[Token]) -> (AtomExpr, ArrayView[Token]) raise ParserError {
//  match tokens {
//    [Bool(b), .. rest_toks] => (AtomExpr::Bool(b), rest_toks)
//    [Int(i), .. rest_toks] => (Int(i), rest_toks)
//    [Int64(i64), .. rest_toks] => (Int64(i64), rest_toks)
//    [UInt(u), .. rest_toks] => (UInt(u), rest_toks)
//    [UInt64(u64), .. rest_toks] => (UInt64(u64), rest_toks)
//    [Double(d), .. rest_toks] => (Double(d), rest_toks)
//    [Lower(func_name), Bracket(RoundOpen), .. rest_toks] => {
//      let args : Array[Expr] = Array::new()
//      let rest_toks = loop rest_toks {
//        [Bracket(RoundClose), .. rest_toks] => break rest_toks
//        _ as rest_toks => {
//          let (arg_expr, rest_toks) = parse_expr(rest_toks)
//          args.push(arg_expr)
//          match rest_toks {
//            [Comma, .. rest_toks] => continue rest_toks // continue if there is a comma
//            [Bracket(RoundClose), .. rest_toks] => break rest_toks // break if we reach the end of the arguments
//            _ =>
//              raise ParserError(
//                "Parse AtomExpr Error: Unexpected token in function call: \{rest_toks}",
//              )
//          }
//        }
//      }
//      (Call(func_name, args), rest_toks)
//    }
//    [Lower(var_name), .. rest_toks] => (Var(var_name), rest_toks)
//    [Bracket(SquareOpen), .. rest_toks] => {
//      let elements : Array[Expr] = Array::new()
//      let rest_toks = loop rest_toks {
//        [Bracket(SquareClose), .. rest_toks] => break rest_toks
//        _ as rest_toks => {
//          let (expr, rest_toks) = parse_expr(rest_toks)
//          elements.push(expr)
//          match rest_toks {
//            [Comma, .. rest_toks] => continue rest_toks // continue if there is a comma
//            [Bracket(SquareClose), .. rest_toks] => break rest_toks // break if we reach the end of the array
//            _ =>
//              raise ParserError(
//                "Parse AtomExpr Error: Unexpected token in array literal: \{rest_toks}",
//              )
//          }
//        }
//      }
//      (Array(elements), rest_toks)
//    }
//    [Bracket(RoundOpen), .. rest_toks] => {
//      let exprs : Array[Expr] = Array::new()
//      let rest_toks = loop rest_toks {
//        [Bracket(RoundClose), .. rest_toks] => break rest_toks
//        _ as rest_toks => {
//          let (expr, rest_toks) = parse_expr(rest_toks)
//          exprs.push(expr)
//          match rest_toks {
//            [Comma, .. rest_toks] => continue rest_toks // continue if there is a comma
//            [Bracket(RoundClose), .. rest_toks] => break rest_toks // break if we reach the end of the tuple
//            _ =>
//              raise ParserError(
//                "Parse AtomExpr Error: Unexpected token in tuple literal: \{rest_toks}",
//              )
//          }
//        }
//      }
//      if exprs.length() == 1 {
//        (Paren(exprs[0]), rest_toks)
//      } else {
//        (AtomExpr::Tuple(exprs), rest_toks)
//      }
//    }
//    [Bracket(CurlyOpen), ..] => {
//      let (block_expr, rest_toks) = parse_block_expr(tokens)
//      (AtomExpr::BlockExpr(block_expr), rest_toks)
//    }
//    // if expr '{' '}'
//    [Keyword(If), .. rest_toks] => {
//      let (cond_expr, rest_toks) = parse_expr(rest_toks)
//      guard rest_toks is [Bracket(CurlyOpen), .. rest_toks] else {
//        raise ParserError("Expected '{' after 'if' condition")
//      }
//      let (then_block, rest_toks) = parse_block_expr(rest_toks)
//      let else_block = if rest_toks is [Keyword(Else), Bracket(CurlyOpen), .. rest_toks] {
//        let (else_block, _) = parse_block_expr(rest_toks)
//        Some(else_block)
//      } else {
//        None
//      }
//      (AtomExpr::If(cond_expr, then_block, else_block), rest_toks)
//    }
//    _ => raise ParserError(
//      "Parse AtomExpr Error: Unexpected token in atom expression: \{tokens}",
//    )
//  }
//}
//
//fn parse_block_expr(
//  tokens : ArrayView[Token]
//) -> (BlockExpr, ArrayView[Token]) raise ParserError {
//  guard tokens is [Bracket(CurlyOpen), .. rest_toks] else {
//    raise ParserError("Expected '{' to start a block expression")
//  }
//  let stmts : Array[Stmt] = Array::new()
//  let rest = loop rest_toks {
//    [Bracket(CurlyClose), .. rest_toks] => break rest_toks
//    _ as rest_toks => {
//      let (stmt, rest_toks) = parse_stmt(rest_toks)
//      stmts.push(stmt)
//      match rest_toks {
//        [SemiColon, .. rest_toks] => continue rest_toks // continue if there is a semicolon
//        [Bracket(CurlyClose), .. rest_toks] => break rest_toks // break if we reach the end of the block
//        _ =>
//          raise ParserError(
//            "Parse BlockExpr Error: Unexpected token in block expression: \{rest_toks}",
//          )
//      }
//    }
//  }
//  (BlockExpr::BlockExpr(stmts), rest)
//}
//
//test "AtomExpr Parsing" {
//  let code_expects : Map[String, AtomExpr] = {
//    "1": Int(1),
//    "true": Bool(true),
//    "false": Bool(false),
//    "x": Var("x"),
//    "(1, 2, 3)" : AtomExpr::Tuple([
//      Expr::Apply(ApplyExpr::Atom(AtomExpr::Int(1))),
//      Expr::Apply(ApplyExpr::Atom(AtomExpr::Int(2))),
//      Expr::Apply(ApplyExpr::Atom(AtomExpr::Int(3))),
//    ]),
//  }
//  for code, expect in code_expects {
//    let (actual, _) = code |> lex |> parse_atom_expr
//    assert_eq(
//      actual,
//      expect,
//      msg="Parsing failed for code: \{code}, expected: \{expect}, got: \{actual}",
//    )
//  }
//
//}
//
/////|
//pub(all) enum ApplyExpr {
//  Atom(AtomExpr) // e.g. 1, x, ref x, sizeof(Int), [1, 2, 3], (1 + 2), ref x
//  ArrayGet(ApplyExpr, Expr) // e.g. arr[i]
//  TupleGet(ApplyExpr, Int) // e.g. tuple.0
//  StructGet(ApplyExpr, String) // e.g. struct.field
//} derive(Show, Eq, ToJson)
//
/////|
//pub fn parse_apply_expr(
//  tokens : ArrayView[Token]
//) -> (ApplyExpr, ArrayView[Token]) raise ParserError{
//  let (atom_expr, rest_toks) = parse_atom_expr(tokens)
//  let mut apply_expr = ApplyExpr::Atom(atom_expr)
//  loop rest_toks {
//    [Bracket(SquareOpen), .. rest_toks] => {
//      let (index_expr, rest_toks) = parse_expr(rest_toks)
//      guard rest_toks is [Bracket(SquareClose), .. rest_toks] else {
//        raise ParserError(
//          "Parse ApplyExpr Error: Expected ']' after array index",
//        )
//      }
//      apply_expr = ApplyExpr::ArrayGet(apply_expr, index_expr)
//      continue rest_toks
//    }
//    [Dot, Lower(field_name), .. rest_toks] => {
//      apply_expr = ApplyExpr::StructGet(apply_expr, field_name)
//      continue rest_toks
//    }
//    [Dot, Int(index), .. rest_toks] => {
//      apply_expr = ApplyExpr::TupleGet(apply_expr, index)
//      continue rest_toks
//    }
//    _ as tokens => return (apply_expr, tokens) // no more applies or accesses
//  }
//}
//
//test "ApplyExpr Parsing" {
//  let code_expects : Map[String, ApplyExpr] = {
//    "1": Atom(AtomExpr::Int(1)),
//    "x": Atom(AtomExpr::Var("x")),
//    "arr[i]": ApplyExpr::ArrayGet(
//      Atom(AtomExpr::Var("arr")),
//      Expr::Apply(ApplyExpr::Atom(AtomExpr::Var("i"))),
//    ),
//    "tuple.0": ApplyExpr::TupleGet(
//      Atom(AtomExpr::Var("tuple")),
//      0,
//    ),
//    "my_struct.field": ApplyExpr::StructGet(
//      Atom(AtomExpr::Var("my_struct")),
//      "field",
//    ),
//  }
//  for code, expect in code_expects {
//    let (actual, _) = code |> lex |> parse_apply_expr
//    assert_eq(
//      actual,
//      expect,
//      msg="Parsing failed for code: \{code}, expected: \{expect}, got: \{actual}",
//    )
//  }
//}
//
/////|
//pub(all) enum Expr {
//  Apply(ApplyExpr) // e.g. func(arg1, arg2)
//  Neg(Expr) // e.g. -1, -x
//  Add(Expr, Expr) // e.g. 1 + 2
//  Sub(Expr, Expr) // e.g. 1 - 2
//  Mul(Expr, Expr) // e.g. 1 * 2
//  Div(Expr, Expr) // e.g. 1 / 2
//  Rem(Expr, Expr) // e.g. 1 % 2
//  BitAnd(Expr, Expr) // e.g. 1 & 2
//  BitOr(Expr, Expr) // e.g. 1 | 2
//  Not(Expr) // e.g. !true, !x
//  Eq(Expr, Expr) // e.g. 1 == 2, ty must be Bool
//  Ne(Expr, Expr)
//  Le(Expr, Expr)
//  Ge(Expr, Expr)
//  Lt(Expr, Expr)
//  Gt(Expr, Expr)
//  And(Expr, Expr)
//  Or(Expr, Expr)
//  Shl(Expr, Expr) // e.g. 1 << 2
//  Shr(Expr, Expr) // e.g. 1 >> 2
//} derive(Show, Eq, ToJson)
//
//fn parse_expr(tokens: ArrayView[Token]) -> (Expr, ArrayView[Token]) raise ParserError {
//  if tokens is [Operator(Minus), .. rest_tokens] {
//    let (expr, rest_tokens) = parse_expr(rest_tokens)
//    return (Expr::Neg(expr), rest_tokens)
//  }
//  if tokens is [Operator(Not), .. rest_tokens] {
//    let (expr, rest_tokens) = parse_expr(rest_tokens)
//    return (Expr::Not(expr), rest_tokens)
//  }
//  fn construct_bin_expr(
//    left : Expr,
//    right : Expr,
//    oper : Operator
//  ) -> Expr raise ParserError {
//    match oper {
//      Plus => Expr::Add(left, right)
//      Minus => Expr::Sub(left, right)
//      Mult => Expr::Mul(left, right)
//      Div => Expr::Div(left, right)
//      Mod => Expr::Rem(left, right)
//      BitAnd => Expr::BitAnd(left, right)
//      BitOr => Expr::BitOr(left, right)
//      Eq => Expr::Eq(left, right)
//      NE => Expr::Ne(left, right)
//      LE => Expr::Le(left, right)
//      GE => Expr::Ge(left, right)
//      LT => Expr::Lt(left, right)
//      GT => Expr::Gt(left, right)
//      And => Expr::And(left, right)
//      Or => Expr::Or(left, right)
//      ShiftLeft => Expr::Shl(left, right) // left shift
//      ShiftRight => Expr::Shr(left, right) // logical right shift
//      _ => {
//        raise ParserError(
//          "Parse Expression Error: Unsupported operator in binary expression: \{oper}",
//        )
//      }
//    }
//  }
//
//  fn preced(op : Operator) -> Int {
//    match op {
//      Not => 10
//      Mult | Div | Mod => 9
//      BitAnd | BitOr => 8
//      Plus | Minus => 8
//      ShiftLeft | ShiftRight => 7 // left and logical right shift
//      Eq | NE | LE | GE | LT | GT => 6
//      And => 3
//      Or => 2
//    }
//  }
//
//  let exprs : Array[Expr] = Array::new()
//  let opers : Array[Operator] = Array::new()
//  let (head_apply, rest_toks) = parse_apply_expr(tokens)
//  exprs.push(Expr::Apply(head_apply))
//  loop rest_toks {
//    [Operator(op), .. rest_toks] if opers.is_empty() => {
//      let (next_apply, rest_toks) = parse_apply_expr(rest_toks)
//      exprs.push(Expr::Apply(next_apply))
//      opers.push(op)
//      continue rest_toks
//    }
//    [Operator(op), .. rest_toks] if preced(op) >= preced(opers.last().unwrap()) => {
//      let (next_apply, rest_toks) = parse_apply_expr(rest_toks)
//      exprs.push(Expr::Apply(next_apply))
//      opers.push(op)
//      continue rest_toks
//    }
//    [Operator(op), .. rest_toks] => {
//      let new_exprs = Array::new()
//      let new_opers = Array::new()
//      while opers.last() is Some(last_op) && preced(op) < preced(last_op) {
//        new_exprs.push(exprs.pop().unwrap()) // right_expr
//        new_opers.push(opers.pop().unwrap())
//      } else {
//        new_exprs.push(exprs.pop().unwrap()) // left_expr
//      }
//      while not(new_opers.is_empty()) {
//        let left_expr = new_exprs.pop().unwrap()
//        let right_expr = new_exprs.pop().unwrap()
//        let oper = new_opers.pop().unwrap()
//        let new_expr = construct_bin_expr(left_expr, right_expr, oper)
//        new_exprs.push(new_expr)
//      }
//      guard new_exprs.length() == 1 else {
//        raise ParserError(
//          "Parse Expression Error: Mismatched expression and operators",
//        )
//      }
//      exprs.push(new_exprs.pop().unwrap())
//      let (next_apply, rest_toks) = parse_apply_expr(rest_toks)
//      exprs.push(Expr::Apply(next_apply))
//      opers.push(op)
//      continue rest_toks
//    }
//    _ as rest_toks => {
//      // clear opers and exprs
//      while not(opers.is_empty()) {
//        let right_expr = exprs.pop().unwrap()
//        let left_expr = exprs.pop().unwrap()
//        let oper = opers.pop().unwrap()
//        let new_expr = construct_bin_expr(left_expr, right_expr, oper)
//        exprs.push(new_expr)
//      }
//      guard exprs.length() == 1 else {
//        raise ParserError(
//          "Parse Expression Error: Mismatched expression and operators",
//        )
//      }
//      (exprs[0], rest_toks)
//    }
//  }
//}
//
/////|
//pub(all) enum LeftValue {
//  Var(String) // e.g. x
//  ArrayGet(LeftValue, Expr) // e.g. arr[i]
//  StructGet(LeftValue, String) // e.g. struct.field
//  TupleGet(LeftValue, Int) // e.g. tuple.0
//} derive(Show, Eq, ToJson)
//
//fn parse_left_value(
//  tokens : ArrayView[Token]
//) -> (LeftValue, ArrayView[Token]) raise ParserError {
//  guard tokens is [Lower(var_name), .. rest_toks] else {
//    raise ParserError("Parse LeftValue Error: Not a valid left value")
//  }
//  let mut left_value = LeftValue::Var(var_name)
//  loop rest_toks {
//    [Bracket(SquareOpen), .. rest_toks] => {
//      let (index_expr, rest_toks) = parse_expr(rest_toks)
//      guard rest_toks is [Bracket(SquareClose), .. rest_toks] else {
//        raise ParserError(
//          "Parse LeftValue Error: Expected ']' after array index",
//        )
//      }
//      left_value = LeftValue::ArrayGet(left_value, index_expr)
//      continue rest_toks
//    }
//    [Dot, Lower(field_name), .. rest_toks] => {
//      left_value = LeftValue::StructGet(left_value, field_name)
//      continue rest_toks
//    }
//    [Dot, Int(index), .. rest_toks] => {
//      left_value = LeftValue::TupleGet(left_value, index)
//      continue rest_toks
//    }
//    _ as tokens => break (left_value, tokens)
//  }
//}
//
//test "LeftValue Parsing" {
//  let code_expects : Map[String, LeftValue] = {
//    "x": LeftValue::Var("x"),
//    "arr[i]": LeftValue::ArrayGet(
//      LeftValue::Var("arr"),
//      Expr::Apply(ApplyExpr::Atom(AtomExpr::Var("i"))),
//    ),
//    "tuple.0": LeftValue::TupleGet(
//      LeftValue::Var("tuple"),
//      0,
//    ),
//    "my_struct.field": LeftValue::StructGet(
//      LeftValue::Var("my_struct"),
//      "field",
//    ),
//  }
//  for code, expect in code_expects {
//    let (actual, _) = code |> lex |> parse_left_value
//    assert_eq(
//      actual,
//      expect,
//      msg="Parsing failed for code: \{code}, expected: \{expect}, got: \{actual}",
//    )
//  }
//}
//
/////|
//pub(all) enum Stmt {
//  Let(String, PType?, Expr) // e.g. let x: Int = 1 or let x = 1
//  LetMut(String, PType?, Expr) // e.g. let mut x: Int = 1 or let mut x = 1
//  LetTuple(Array[String], PType?, Expr) // e.g. let (x, y) = (1, 2)
//  While(Expr, Array[Stmt]) // e.g. while (x < 10) { ... }
//  For(ForInit, ForCond, ForStep, Array[Stmt]) // e.g. for i = 0; i < 10; i = i + 1 { ... }
//  Return(Expr?) // e.g. return 1 or return
//  Assign(LeftValue, AssignOp, Expr) // e.g. x = 1 or arr[i] = 2 or arr[i].field = 3
//  LocalFn(String, Array[(String, PType?)], PType?, Array[Stmt]) // e.g. fn name(arg1, arg2: Double) { ... }
//  Expr(Expr) // single expression statement, e.g. print_int(1);
//} derive(Show, Eq, ToJson)
//
//fn parse_stmt(tokens : ArrayView[Token]) -> (Stmt, ArrayView[Token]) raise ParserError{
//  match tokens {
//    [Keyword(Let), Bracket(RoundOpen), ..] => parse_let_tuple(tokens)
//    [Keyword(Let), ..] => parse_let(tokens)
//    [Keyword(Return), ..] => parse_return(tokens)
//    [Keyword(While), ..] => parse_while(tokens)
//    [Keyword(For), ..] => parse_for(tokens)
//    [Lower(_), ..] => {
//      let (_, rest_toks) = parse_apply_expr(tokens)
//      match rest_toks[0] {
//        AssignOp(_) => parse_assign(tokens)
//        _ => parse_expr_stmt(tokens)
//      }
//    }
//    _ =>
//      raise ParserError(
//        "Parse Statement Error: Unexpected token in statement: \{tokens}",
//      )
//  }
//}
//
//// 'let' '(' lower (',' lower)* ')' ':' PType? '=' Expr
//fn parse_let_tuple(tokens : ArrayView[Token]) -> (Stmt, ArrayView[Token]) raise ParserError {
//  guard tokens is [Keyword(Let), Bracket(RoundOpen), .. rest_toks] else {
//    raise ParserError("Expected 'let' followed by '(' for tuple assignment")
//  }
//  let bindings : Array[String] = Array::new()
//  let rest_toks = loop rest_toks {
//    [Lower(var_name), .. rest_toks] => {
//      bindings.push(var_name)
//      continue rest_toks
//    }
//    [Comma, .. rest_toks] => continue rest_toks
//    [Bracket(RoundClose), .. rest_toks] => break rest_toks
//    rest_toks => {
//      raise ParserError(
//        "Expected variable names in let tuple, found: \{rest_toks}",
//      )
//    }
//  }
//  if rest_toks is [Colon, .. rest_toks] {
//    let (p_type, rest_toks) = parse_type(rest_toks)
//    guard rest_toks is [AssignOp(Assign), .. rest_toks] else {
//      raise ParserError("Expected '=' after type annotation in let tuple")
//    }
//    let (expr, rest_toks) = parse_expr(rest_toks)
//    (Stmt::LetTuple(bindings, Some(p_type), expr), rest_toks)
//  } else {
//    guard rest_toks is [AssignOp(Assign), .. rest_toks] else {
//      raise ParserError("Expected '=' after variable names in let tuple")
//    }
//    let (expr, rest_toks) = parse_expr(rest_toks)
//    (Stmt::LetTuple(bindings, None, expr), rest_toks)
//  }
//}
//
//// 'let' 'mut' lower ':' PType? '=' Expr
//fn parse_let(tokens : ArrayView[Token]) -> (Stmt, ArrayView[Token]) raise ParserError {
//  let (is_mut, rest_toks) = match tokens {
//    [Keyword(Let), Keyword(Mut), .. rest_toks] => (true, rest_toks)
//    [Keyword(Let), .. rest_toks] => (false, rest_toks)
//    _ => raise ParserError("Expected 'let' followed by 'mut' or a variable name")
//  }
//  guard rest_toks is [Lower(var_name), .. rest_toks] else {
//    raise ParserError("Expected a variable name after 'let'")
//  }
//  let (ptype, rest_toks) = if rest_toks is [Colon, .. rest_toks] {
//    let (p_type, rest_toks) = parse_type(rest_toks)
//    (Some(p_type), rest_toks)
//  } else {
//    (None, rest_toks)
//  }
//  guard rest_toks is [AssignOp(Assign), .. rest_toks] else {
//    raise ParserError("Expected '=' after variable name in let statement")
//  }
//  let (expr, rest_toks) = parse_expr(rest_toks)
//  match is_mut {
//    true => (Stmt::LetMut(var_name, ptype, expr), rest_toks)
//    false => (Stmt::Let(var_name, ptype, expr), rest_toks)
//  }
//
//}
//
//// 'while' expr '{' stmt* '}'
//fn parse_while(tokens: ArrayView[Token]) -> (Stmt, ArrayView[Token]) raise ParserError {
//  guard tokens is [Keyword(While), .. rest_toks] else {
//    raise ParserError("Expected 'while' keyword")
//  }
//  let (cond_expr, rest_toks) = parse_expr(rest_toks)
//  guard rest_toks is [Bracket(CurlyOpen), .. rest_toks] else {
//    raise ParserError("Expected '{' after 'while' condition")
//  }
//  let stmts : Array[Stmt] = Array::new()
//  let rest = loop rest_toks {
//    [Bracket(CurlyClose), .. rest_toks] => break rest_toks
//    _ as rest_toks => {
//      let (stmt, rest_toks) = parse_stmt(rest_toks)
//      stmts.push(stmt)
//      match rest_toks {
//        [SemiColon, .. rest_toks] => continue rest_toks // continue if there is a semicolon
//        [Bracket(CurlyClose), .. rest_toks] => break rest_toks // break if we reach the end of the block
//        _ =>
//          raise ParserError(
//            "Parse While Error: Unexpected token in while block: \{rest_toks}",
//          )
//      }
//    }
//  }
//  (Stmt::While(cond_expr, stmts), rest)
//}
//
//// 'for' (lower '=' Expr)? ';' Expr ';' (lower AssignOp Expr)? '{' stmt* '}'
//fn parse_for(tokens: ArrayView[Token]) -> (Stmt, ArrayView[Token]) raise ParserError {
// ... 
//}
//
//// left_value assign_op expr
//fn parse_assign(tokens: ArrayView[Token]) -> (Stmt, ArrayView[Token]) raise ParserError {
//  let (left_value, rest_toks) = parse_left_value(tokens)
//  guard rest_toks is [AssignOp(assign_op), .. rest_toks] else {
//    raise ParserError("Expected assignment operator after left value")
//  }
//  let (expr, rest_toks) = parse_expr(rest_toks)
//  (Stmt::Assign(left_value, assign_op, expr), rest_toks)
//}
//
//// 'return' Expr?
//fn parse_return(tokens: ArrayView[Token]) -> (Stmt, ArrayView[Token]) raise ParserError {
//  match tokens {
//    [Keyword(Return), SemiColon, .. rest_toks] => {
//      (Stmt::Return(None), rest_toks)
//    }
//    [Keyword(Return), .. rest_toks] => {
//      let (expr, rest_toks) = parse_expr(rest_toks)
//      (Stmt::Return(Some(expr)), rest_toks)
//    }
//    _ => raise ParserError("Expected 'return' followed by an expression or a semicolon")
//  }
//}
//
//// expr ';'
//fn parse_expr_stmt(tokens: ArrayView[Token]) -> (Stmt, ArrayView[Token]) raise ParserError {
//  ...
//}
//
//type ForInit (String, Expr) derive(Show, Eq, ToJson)
//type ForCond Expr derive(Show, Eq, ToJson)
//type ForStep (LeftValue, AssignOp, Expr) derive(Show, Eq, ToJson)
//
/////|
//pub(all) struct Function {
//  name : String
//  params : Array[(String, PType)]
//  ret_ty : PType
//  body : Array[Stmt]
//} derive(Show, Eq, ToJson)
//
/////|
//pub(all) struct StructDef {
//  name : String
//  fields : Array[(String, PType)]
//} derive(Show, Eq, ToJson)
//
/////|
//pub struct Program {
//  functions : Map[String, Function]
//  externs : Map[String, Function]
//  structs : Map[String, StructDef]
//} derive(Show, ToJson)
