
///|
test "Apply Expr Knf Transformation Test" {
  // Prelude Parts
  // set a, b, x, arr, point, max type in typecheck and knf context
  let typecheck_ctx = @typecheck.Context::new()
  typecheck_ctx.type_env.set("a", { kind: Int, mutable: false })
  typecheck_ctx.type_env.set("b", { kind: Int, mutable: false })
  typecheck_ctx.type_env.set("x", { kind: Int, mutable: false })
  let point_struct_def : @typecheck.StructDef = {
    name: "Point",
    fields: [
      { name: "x", ty: { kind: Int, mutable: false } },
      { name: "y", ty: { kind: Int, mutable: false } },
    ],
    methods: Map::new(),
  }
  typecheck_ctx.struct_defs.set("Point", point_struct_def)
  typecheck_ctx.type_env.set("arr", { kind: Array(Int), mutable: false })
  typecheck_ctx.type_env.set("point", { kind: Struct("Point"), mutable: false })
  typecheck_ctx.type_env.set("max", {
    kind: Function([Int, Int], Int),
    mutable: false,
  })
  let knf_ctx = Context::new()
  knf_ctx.globals.set("max", Function([Int, Int], Int))
  let _ = knf_ctx.add_new_name("a", Int)
  let _ = knf_ctx.add_new_name("b", Int)
  let _ = knf_ctx.add_new_name("x", Int)
  let _ = knf_ctx.add_new_name("arr", Array(Int))
  let _ = knf_ctx.add_new_name("point", Struct("Point"))

  // Test Parts
  let code =
    #|arr[3]
    #|arr[x]
    #|point.x
    #|max(a + b, a - b)
  // Code parse, typecheck, knf transform
  let tokens = @lexer.tokenize(code)
  // Parse and transform `arr[3]`.
  let (e, tok_view) = @parser.parse_apply_expr(tokens)
  let e = typecheck_ctx.check_apply_expr(e)
  let (stmts, knf_expr) = knf_ctx.apply_expr_to_knf(e)
  assert_true(
    stmts is [s1] &&
    s1 is Let(n1, Int, Int(3)) &&
    knf_expr is ArrayAccess(arr_name, index_name) &&
    arr_name is { id: "arr", .. } &&
    index_name == n1,
  )
  // Parse and transform `arr[x]`.
  let (e, tok_view) = @parser.parse_apply_expr(tok_view)
  let e = typecheck_ctx.check_apply_expr(e)
  let (stmts, knf_expr) = knf_ctx.apply_expr_to_knf(e)
  assert_true(
    stmts is [] &&
    knf_expr is ArrayAccess(arr_name, index_name) &&
    arr_name is { id: "arr", .. } &&
    index_name is { id: "x", .. },
  )
  // Parse and transform `point.x`.
  let (e, tok_view) = @parser.parse_apply_expr(tok_view)
  let e = typecheck_ctx.check_apply_expr(e)
  let (stmts, knf_expr) = knf_ctx.apply_expr_to_knf(e)
  assert_true(
    stmts is [] &&
    knf_expr is FieldAccess(struct_name, field_name) &&
    struct_name is { id: "point", .. } &&
    field_name is "x",
  )
  // Parse and transform `max(a + b, a - b)`.
  let (e, _) = @parser.parse_apply_expr(tok_view)
  let e = typecheck_ctx.check_apply_expr(e)
  let (stmts, knf_expr) = knf_ctx.apply_expr_to_knf(e)
  assert_true(
    stmts is [s1, s2] &&
    s1 is Let(n1, Int, Binary(Add, l1, r1)) &&
    l1.id is "a" &&
    r1.id is "b" &&
    s2 is Let(n2, Int, Binary(Sub, l2, r2)) &&
    l2.id is "a" &&
    r2.id is "b" &&
    knf_expr is Call(callee_name, arg_names) &&
    callee_name.id is "max" &&
    arg_names == [n1, n2],
  )
}

///|
test "Assign Stmt Knf Transformation Test" {
  // Prelude Parts
  // set x, y type in typecheck and knf context
  let typecheck_ctx = @typecheck.Context::new()
  let point_struct_def : @typecheck.StructDef = {
    name: "Point",
    fields: [{ name: "x", ty: { kind: Int, mutable: true } }],
    methods: Map::new(),
  }
  typecheck_ctx.struct_defs.set("Point", point_struct_def)
  typecheck_ctx.type_env.set("x", { kind: Int, mutable: true })
  typecheck_ctx.type_env.set("y", { kind: Double, mutable: true })
  typecheck_ctx.type_env.set("mat", { kind: Array(Array(Int)), mutable: true })
  typecheck_ctx.type_env.set("point", { kind: Struct("Point"), mutable: false })
  let knf_ctx = Context::new()
  let _ = knf_ctx.add_new_name("x", Int)
  let _ = knf_ctx.add_new_name("y", Double)
  let _ = knf_ctx.add_new_name("arr", Array(Int))
  let _ = knf_ctx.add_new_name("point", Struct("Point"))
  let _ = knf_ctx.add_new_name("mat", Array(Array(Int)))

  // Test Parts
  let code =
    #|x = 10;
    #|y = 3.14;
    #|x += 5;
    #|y -= 1.0;
    #|mat[0][0] = 42;
    #|point.x = 100;
  // Code parse, typecheck, knf transform
  let tokens = @lexer.tokenize(code)

  // Parse and transform `x = 10;`
  let (stmt, tok_view) = @parser.parse_assign_stmt(tokens)
  let stmt = typecheck_ctx.check_assign_stmt(stmt)
  let knf_stmts = knf_ctx.assign_stmt_to_knf(stmt)
  assert_true(
    knf_stmts is [s] &&
    s is Assign(name, expr) &&
    name is { id: "x", .. } &&
    expr is Int(10),
  )

  // Parse and transform `y = 3.14;`
  let (stmt, tok_view) = @parser.parse_assign_stmt(tok_view)
  let stmt = typecheck_ctx.check_assign_stmt(stmt)
  let knf_stmts = knf_ctx.assign_stmt_to_knf(stmt)
  assert_true(
    knf_stmts is [s] &&
    s is Assign(name, expr) &&
    name is { id: "y", .. } &&
    expr is Double(3.14),
  )

  // Parse and transform `x += 5;`
  let (stmt, tok_view) = @parser.parse_assign_stmt(tok_view)
  let stmt = typecheck_ctx.check_assign_stmt(stmt)
  let knf_stmts = knf_ctx.assign_stmt_to_knf(stmt)
  assert_true(
    knf_stmts is [s1, s2, s3] &&
    s1 is Let(_, Int, Int(5)) &&
    s2 is Let(_, Int, Binary(Add, _, _)) &&
    s3 is Assign(name, Ident(_)) &&
    name is { id: "x", .. },
  )

  // Parse and transform `y -= 1.0;`
  let (stmt, tok_view) = @parser.parse_assign_stmt(tok_view)
  let stmt = typecheck_ctx.check_assign_stmt(stmt)
  let knf_stmts = knf_ctx.assign_stmt_to_knf(stmt)
  assert_true(
    knf_stmts is [s1, s2, s3] &&
    s1 is Let(_, Double, Double(1.0)) &&
    s2 is Let(_, Double, Binary(Sub, _, _)) &&
    s3 is Assign(name, Ident(_)) &&
    name is { id: "y", .. },
  )
  // Parse and transform `max[0][0] = 42;`
  let (stmt, tok_view) = @parser.parse_assign_stmt(tok_view)
  let stmt = typecheck_ctx.check_assign_stmt(stmt)
  let knf_stmts = knf_ctx.assign_stmt_to_knf(stmt)
  assert_true(
    knf_stmts is [s1, s2, s3, s4] &&
    s1 is Let(n1, Int, Int(0)) &&
    s2 is Let(n2, Array(Int), ArrayAccess(_, mat_idx_name)) &&
    s3 is Let(n3, Int, Int(0)) &&
    s4 is ArrayPut(array_name, idx_name, Int(42)) &&
    n1 == mat_idx_name &&
    array_name == n2 &&
    idx_name == n3,
  )
  // Parse and transform `point.x = 100;`
  let (stmt, _) = @parser.parse_assign_stmt(tok_view)
  let stmt = typecheck_ctx.check_assign_stmt(stmt)
  let knf_stmts = knf_ctx.assign_stmt_to_knf(stmt)
  assert_true(
    knf_stmts is [s1, s2] &&
    s1 is Let(n1, Int, Int(100)) &&
    s2 is StructFieldSet(_, "x", value_name) &&
    n1 == value_name,
  )
}

///|
test "Atom Expr Knf Transformation Test" {
  // set a, b, x, y, z type in typecheck and knf context
  let typecheck_ctx = @typecheck.Context::new()
  typecheck_ctx.type_env.set("a", { kind: Int, mutable: false })
  typecheck_ctx.type_env.set("b", { kind: Int, mutable: false })
  typecheck_ctx.type_env.set("x", { kind: Double, mutable: false })
  typecheck_ctx.type_env.set("y", { kind: String, mutable: false })
  typecheck_ctx.type_env.set("z", { kind: Bool, mutable: false })
  let point_struct_def : @typecheck.StructDef = {
    name: "Point",
    fields: [
      { name: "x", ty: { kind: Int, mutable: false } },
      { name: "y", ty: { kind: Int, mutable: false } },
    ],
    methods: Map::new(),
  }
  typecheck_ctx.struct_defs.set("Point", point_struct_def)
  let knf_ctx = Context::new()
  knf_ctx.globals.set("x", Double)
  let _ = knf_ctx.add_new_name("y", String)
  knf_ctx.enter_scope()
  let _ = knf_ctx.add_new_name("z", Bool)
  let _ = knf_ctx.add_new_name("a", Int)
  let _ = knf_ctx.add_new_name("b", Int)

  // Code parse, typecheck, knf transform
  let code =
    #|(a + b)
    #|[1, 2, 3]
    #|(x, y, z)
    #|Array::make(5, 0)
    #|Point::{ x: 10, y: 20 }
  let tokens = @lexer.tokenize(code)
  // Parse and transform `(a + b)`.
  let (e, tok_view) = @parser.parse_atom_expr(tokens)
  let e = typecheck_ctx.check_atom_expr(e)
  let (stmts, knf_expr) = knf_ctx.atom_expr_to_knf(e)
  assert_true(
    stmts is [] &&
    knf_expr is Binary(Add, l, r) &&
    l is { id: "a", .. } &&
    r is { id: "b", .. },
  )
  // Parse and transform `[1, 2, 3]`.
  let (e, tok_view) = @parser.parse_atom_expr(tok_view)
  let e = typecheck_ctx.check_atom_expr(e)
  let (stmts, knf_expr) = knf_ctx.atom_expr_to_knf(e)
  assert_true(
    stmts is [s1, s2, s3] &&
    s1 is Let(n1, Int, Int(1)) &&
    s2 is Let(n2, Int, Int(2)) &&
    s3 is Let(n3, Int, Int(3)) &&
    knf_expr is ArrayLiteral(_, [a1, a2, a3]) &&
    n1 == a1 &&
    n2 == a2 &&
    n3 == a3,
  )
  // Parse and transform `(x, y, z)`.
  let (e, tok_view) = @parser.parse_atom_expr(tok_view)
  let e = typecheck_ctx.check_atom_expr(e)
  let (stmts, knf_expr) = knf_ctx.atom_expr_to_knf(e)
  assert_true(
    stmts is [] &&
    knf_expr is TupleLiteral([t1, t2, t3]) &&
    t1 is { id: "x", .. } &&
    t2 is { id: "y", .. } &&
    t3 is { id: "z", .. },
  )
  // Parse and transform `Array::make(5, 0)`.
  let (e, tok_view) = @parser.parse_atom_expr(tok_view)
  let e = typecheck_ctx.check_atom_expr(e)
  let (stmts, knf_expr) = knf_ctx.atom_expr_to_knf(e)
  assert_true(
    stmts is [s1, s2] &&
    s1 is Let(n1, Int, Int(5)) &&
    s2 is Let(n2, Int, Int(0)) &&
    knf_expr is ArrayMake(size_name, init_name) &&
    size_name == n1 &&
    init_name == n2,
  )
  // Parse and transform `Point::{ x: 10, y: 20 }`.
  let (e, _) = @parser.parse_atom_expr(tok_view)
  let e = typecheck_ctx.check_atom_expr(e)
  let (stmts, knf_expr) = knf_ctx.atom_expr_to_knf(e)
  assert_true(
    stmts is [s1, s2] &&
    s1 is Let(n1, Int, Int(10)) &&
    s2 is Let(n2, Int, Int(20)) &&
    knf_expr is CreateStruct("Point", [("x", f1), ("y", f2)]) &&
    n1 == f1 &&
    n2 == f2,
  )
}

///|
test "Block Expr Knf Transformation Test" {
  // Prelude Parts
  let typecheck_ctx = @typecheck.Context::new()
  let knf_ctx = @knf.Context::new()

  // Setup type environment for testing
  typecheck_ctx.type_env.set("print_int", {
    kind: Function([Int], Unit),
    mutable: false,
  })

  // For return statement
  typecheck_ctx.current_func_ret_ty = Some(Int)

  // Setup knf context
  knf_ctx.globals.set("print_int", Function([Int], Unit))

  // Test Parts
  let code =
    #|{
    #|  let x: Int = 10;
    #|  let mut y: Double = 3.14;
    #|  let mut z : Int = 0;
    #|  z = 42;
    #|  print_int(z);
    #|  return z;
    #|}

  // Code parse, typecheck, knf transform
  let tokens = @lexer.tokenize(code)
  let (stmt, _) = @parser.parse_block_expr(tokens)
  let checked_block = typecheck_ctx.check_block_expr(stmt)
  let knf_block = knf_ctx.block_expr_to_knf(checked_block)
  assert_true(knf_block.stmts.length() is 6)

  // Test 1: Parse and transform `let x: Int = 10;`
  assert_true(
    knf_block.stmts[0] is Let(name1, Int, init_expr) &&
    name1 is { id: "x", .. } &&
    init_expr is Int(10),
  )

  // Test 2: Parse and transform `let mut y: Double = 3.14;`
  assert_true(
    knf_block.stmts[1] is LetMut(name2, Double, init_expr2) &&
    name2 is { id: "y", .. } &&
    init_expr2 is Double(3.14),
  )

  // Test 3: Parse and transform `let mut z : Int = 0;`
  assert_true(
    knf_block.stmts[2] is LetMut(name3, Int, init_expr3) &&
    name3 is { id: "z", .. } &&
    init_expr3 is Int(0),
  )

  // Test 4: Parse and transform `z = 42;`
  assert_true(
    knf_block.stmts[3] is Assign(name3, expr3) &&
    name3 is { id: "z", .. } &&
    expr3 is Int(42),
  )

  // Test 4: Parse and transform `print_int(z);` (ExprStmt)
  assert_true(
    knf_block.stmts[4] is ExprStmt(call_expr) &&
    call_expr is Call(func, args) &&
    func is { id: "print_int", .. } &&
    args is [arg] &&
    arg is { id: "z", .. },
  )

  // Test 5: Parse and transform `return z;` (ReturnStmt)
  assert_true(
    knf_block.stmts[5] is Return(return_expr) &&
    return_expr is Ident({ id: "z", .. }),
  )
}

///|
test "Expr Knf Transformation Test" {
  // Prelucde Parts
  // set a, b, arr, sum, point, mat, sqrt type in typecheck and knf context
  let typecheck_ctx = @typecheck.Context::new()
  let point_struct_def : @typecheck.StructDef = {
    name: "Point",
    fields: [
      { name: "x", ty: { kind: Int, mutable: false } },
      { name: "y", ty: { kind: Int, mutable: false } },
    ],
    methods: Map::new(),
  }
  typecheck_ctx.struct_defs.set("Point", point_struct_def)
  typecheck_ctx.type_env.set("a", { kind: Double, mutable: false })
  typecheck_ctx.type_env.set("b", { kind: Double, mutable: false })
  typecheck_ctx.type_env.set("arr", { kind: Array(Int), mutable: false })
  typecheck_ctx.type_env.set("point", { kind: Struct("Point"), mutable: false })
  typecheck_ctx.type_env.set("sum", {
    kind: Function([Array(Int)], Int),
    mutable: false,
  })
  typecheck_ctx.type_env.set("max", {
    kind: Function([Double, Double], Double),
    mutable: false,
  })
  typecheck_ctx.type_env.set("min", {
    kind: Function([Double, Double], Double),
    mutable: false,
  })
  let knf_ctx = @knf.Context::new()
  knf_ctx.globals.set("max", Function([Double, Double], Double))
  knf_ctx.globals.set("min", Function([Double, Double], Double))
  knf_ctx.globals.set("sum", Function([Array(Int)], Int))
  let _ = knf_ctx.add_new_name("a", Double)
  let _ = knf_ctx.add_new_name("b", Double)
  let _ = knf_ctx.add_new_name("arr", Array(Int))

  // Test Parts
  let code =
    #|max(a, b) + min(a, b) ;
    #|sum(arr) / arr.length() ;
  // Code parse, typecheck, knf transform
  let tokens = @lexer.tokenize(code)
  // Parse and transform `max(a, b) + min(a, b)`
  let (e, _) = @parser.parse_expr(tokens)
  let e = typecheck_ctx.check_expr(e)
  let (stmts, knf_expr) = knf_ctx.expr_to_knf(e)
  assert_true(
    stmts is [s1, s2] &&
    s1 is Let(n1, Double, Call({ id: "max", .. }, [a1, a2])) &&
    s2 is Let(n2, Double, Call({ id: "min", .. }, [a3, a4])) &&
    a1 is { id: "a", .. } &&
    a2 is { id: "b", .. } &&
    a3 is { id: "a", .. } &&
    a4 is { id: "b", .. } &&
    knf_expr is Binary(Add, l, r) &&
    n1 == l &&
    n2 == r,
  )
}

///|
test "If Expr Knf Transformation Test" {
  // Prelude Parts
  let typecheck_ctx = @typecheck.Context::new()
  let knf_ctx = @knf.Context::new()

  // Setup type environment for testing
  typecheck_ctx.type_env.set("x", { kind: Int, mutable: true })
  typecheck_ctx.type_env.set("y", { kind: Int, mutable: false })
  typecheck_ctx.type_env.set("print_int", {
    kind: Function([Int], Unit),
    mutable: false,
  })

  // Setup knf context
  let _ = knf_ctx.add_new_name("x", Int)
  let _ = knf_ctx.add_new_name("y", Int)
  knf_ctx.globals.set("print_int", Function([Int], Unit))

  // Test 1: Simple if-else expression: if (y > 0) { x = 10; } else { x = 20; }
  let code1 =
    #|if (y > 0) {
    #|  x = 10;
    #|} else {
    #|  x = 20;
    #|}
  let tokens1 = @lexer.tokenize(code1)
  let (if_expr1, _) = @parser.parse_if_expr(tokens1)
  let checked_if_expr1 = typecheck_ctx.check_if_expr(if_expr1)
  let (stmts1, knf_if_expr1) = knf_ctx.if_expr_to_knf(checked_if_expr1)

  // Test 1: Check that condition generates a statement for the literal 0
  assert_true(stmts1.length() is 1)
  assert_true(
    stmts1[0] is Let(tmp_name, Int, Int(0)) && tmp_name is { id: "tmp", .. },
  )

  // Test 1: Check the if expression structure
  assert_true(
    knf_if_expr1 is If(cond, then_block, else_block) &&
    cond is Binary(GT, y_name, tmp_cond) &&
    y_name is { id: "y", .. } &&
    tmp_cond is { id: "tmp", .. } &&
    then_block.stmts.length() is 1 &&
    then_block.stmts[0] is Assign(x_name1, Int(10)) &&
    x_name1 is { id: "x", .. } &&
    else_block.stmts.length() is 1 &&
    else_block.stmts[0] is Assign(x_name2, Int(20)) &&
    x_name2 is { id: "x", .. },
  )

  // Test 2: If without else: if (x < 5) { print_int(x); }
  let code2 =
    #|if (x < 5) {
    #|  print_int(x);
    #|}
  let tokens2 = @lexer.tokenize(code2)
  let (if_expr2, _) = @parser.parse_if_expr(tokens2)
  let checked_if_expr2 = typecheck_ctx.check_if_expr(if_expr2)
  let (stmts2, knf_if_expr2) = knf_ctx.if_expr_to_knf(checked_if_expr2)

  // Test 2: Check that condition generates a statement for the literal 5
  assert_true(stmts2.length() is 1)
  assert_true(
    stmts2[0] is Let(tmp_name2, Int, Int(5)) &&
    tmp_name2 is { id: "tmp", slot: 1 },
  )

  // Test 2: Check the if expression structure (no else block)
  assert_true(
    knf_if_expr2 is If(cond2, then_block2, else_block2) &&
    cond2 is Binary(LT, x_name3, tmp_cond2) &&
    x_name3 is { id: "x", .. } &&
    tmp_cond2 is { id: "tmp", slot: 1 } &&
    then_block2.stmts.length() is 1 &&
    then_block2.stmts[0] is ExprStmt(Call(print_func, [x_arg])) &&
    print_func is { id: "print_int", .. } &&
    x_arg is { id: "x", .. } &&
    else_block2.stmts.is_empty(),
  )

  // Test 3: If-else if-else chain
  let code3 =
    #|if x > 10 {
    #|  y
    #|} else if x > 5 {
    #|  y + 1
    #|} else {
    #|  y + 2
    #|}
  let tokens3 = @lexer.tokenize(code3)
  let (if_expr3, _) = @parser.parse_if_expr(tokens3)
  let checked_if_expr3 = typecheck_ctx.check_if_expr(if_expr3)
  let (stmts3, knf_if_expr3) = knf_ctx.if_expr_to_knf(checked_if_expr3)

  // Test 3: Check that condition generates a statement for the literal 10
  assert_true(stmts3.length() is 2)
  assert_true(
    stmts3 is [s1, s2] &&
    s1 is Let(_, Int, Int(10)) &&
    s2 is Let(_, Int, Int(5)),
  )
  assert_true(
    knf_if_expr3 is If(cond3, then_block3, else_block3) &&
    cond3 is Binary(GT, _, _) &&
    then_block3.stmts is [_] &&
    else_block3.stmts is [ExprStmt(e1)] &&
    e1 is If(nested_cond, _, _) &&
    nested_cond is Binary(GT, _, _),
  )
}

///|
test "Let Mut Knf Transformation Test" {
  // Prelucde Parts
  let typecheck_ctx = @typecheck.Context::new()
  let knf_ctx = @knf.Context::new()
  // Test Parts
  let code =
    #|let mut x: Int = 10;
    #|let mut a = 42.0;
    #|let mut b = 33.0;
    #|let mut y: Double = a + b;
  // Code parse, typecheck, knf transform
  let tokens = @lexer.tokenize(code)
  // Parse and transform `let mut x: Int = 10;`
  let (stmt, tok_view) = @parser.parse_let_mut_stmt(tokens)
  let stmt = typecheck_ctx.check_let_mut_stmt(stmt)
  let knf_stmts = knf_ctx.let_mut_stmt_to_knf(stmt)
  assert_true(
    knf_stmts is [s] &&
    s is LetMut(name1, Int, init_expr) &&
    name1 is { id: "x", .. } &&
    init_expr is Int(10),
  )
  // Parse and transform `let mut a = 42.0;`
  let (stmt1, tok_view) = @parser.parse_let_mut_stmt(tok_view)
  let stmt1 = typecheck_ctx.check_let_mut_stmt(stmt1)
  let knf_stmts1 = knf_ctx.let_mut_stmt_to_knf(stmt1)
  assert_true(
    knf_stmts1 is [s1] &&
    s1 is LetMut(name_a, Double, init_expr1) &&
    name_a is { id: "a", .. } &&
    init_expr1 is Double(42.0),
  )
  // Parse and transform `let mut b = 33.0;`
  let (stmt_b, tok_view) = @parser.parse_let_mut_stmt(tok_view)
  let stmt_b = typecheck_ctx.check_let_mut_stmt(stmt_b)
  let knf_stmts_b = knf_ctx.let_mut_stmt_to_knf(stmt_b)
  assert_true(
    knf_stmts_b is [s_b] &&
    s_b is LetMut(name_b, Double, init_expr_b) &&
    name_b is { id: "b", .. } &&
    init_expr_b is Double(33.0),
  )
  // Parse and transform `let mut y: Double = a + b;`
  let (stmt2, _) = @parser.parse_let_mut_stmt(tok_view)
  let stmt2 = typecheck_ctx.check_let_mut_stmt(stmt2)
  let knf_stmts2 = knf_ctx.let_mut_stmt_to_knf(stmt2)
  assert_true(
    knf_stmts2 is [s2] &&
    s2 is LetMut(name2, Double, init_expr2) &&
    name2 is { id: "y", .. } &&
    init_expr2 is Binary(Add, left, right) &&
    left is { id: "a", .. } &&
    right is { id: "b", .. },
  )
}

///|
test "Let Stmt Knf Transformation Test" {
  // Prelucde Parts
  let typecheck_ctx = @typecheck.Context::new()
  typecheck_ctx.type_env.set("print_int", {
    kind: Function([Int], Unit),
    mutable: false,
  })
  let knf_ctx = @knf.Context::new()
  knf_ctx.globals.set("print_int", Function([Int], Unit))
  // Test Parts
  let code =
    #|let x: Int = 10;
    #|let (a, b) = (42.0, 33.0);
    #|let y: Double = a + b;
    #|let _ = print_int(x);
  // Code parse, typecheck, knf transform
  let tokens = @lexer.tokenize(code)
  // Parse and transform `let x: Int = 10;`
  let (stmt, tok_view) = @parser.parse_let_stmt(tokens)
  let stmt = typecheck_ctx.check_let_stmt(stmt)
  let knf_stmts = knf_ctx.let_stmt_to_knf(stmt)
  assert_true(
    knf_stmts is [s] &&
    s is Let(name1, Int, init_expr) &&
    name1 is { id: "x", .. } &&
    init_expr is Int(10),
  )
  // Parse and transform `let (a, b) = (42.0, 33.0);`
  // It Should be transformed into 4 let statements in knf
  // 1. let tmp1: Double = 42.0;
  // 2. let tmp2: Double = 33.0;
  // 3. let a = tmp1;
  // 4. let b = tmp2;
  // Not: let tmp3 = (tmp1, tmp2); then let a = tmp1.0; let b = tmp1.1
  // Although it's correct, it's not efficient way, be cause we need
  // to create a tuple object in memory.
  //
  // Ask: Does `let a = 42.0; let b = 33.0;` better?
  // Well, you can try it. But it may not easy in knf transformation phase.
  let (stmt1, tok_view) = @parser.parse_let_stmt(tok_view)
  let stmt1 = typecheck_ctx.check_let_stmt(stmt1)
  let knf_stmts1 = knf_ctx.let_stmt_to_knf(stmt1)
  assert_true(
    knf_stmts1 is [s1, s2, s3, s4] &&
    s1 is Let(n1, Double, Double(42.0)) &&
    s2 is Let(n2, Double, Double(33.0)) &&
    s3 is Let(a, _, Ident(n1_)) &&
    s4 is Let(b, _, Ident(n2_)) &&
    n1 == n1_ &&
    n2 == n2_ &&
    a is { id: "a", .. } &&
    b is { id: "b", .. },
  )
  // Parse and transform `let y: Double = a + b;`
  let (stmt2, tok_view) = @parser.parse_let_stmt(tok_view)
  let stmt2 = typecheck_ctx.check_let_stmt(stmt2)
  let knf_stmts2 = knf_ctx.let_stmt_to_knf(stmt2)
  assert_true(
    knf_stmts2 is [s2] &&
    s2 is Let(name2, Double, init_expr2) &&
    name2 is { id: "y", .. } &&
    init_expr2 is Binary(Add, left, right) &&
    left is { id: "a", .. } &&
    right is { id: "b", .. },
  )
  // Parse and transform `let _ = print_int(y);`
  let (stmt3, _) = @parser.parse_let_stmt(tok_view)
  let stmt3 = typecheck_ctx.check_let_stmt(stmt3)
  let knf_stmts3 = knf_ctx.let_stmt_to_knf(stmt3)
  assert_true(
    knf_stmts3 is [s3] &&
    s3 is Let(_, Unit, call_expr) &&
    call_expr is Call(func, args) &&
    func is { id: "print_int", .. } &&
    args is [arg] &&
    arg is { id: "x", .. },
  )
}

///|
test "Local Function Knf Transformation Test" {
  // Prelude Parts
  let typecheck_ctx = @typecheck.Context::new()
  let knf_ctx = @knf.Context::new()

  // Setup builtin functions
  typecheck_ctx.func_types.set("print_int", Function([Int], Unit))
  typecheck_ctx.type_env.set("print_int", {
    kind: Function([Int], Unit),
    mutable: false,
  })
  // Typecheck ctx need to know about 'foo' ahead of time.
  // So that we can call `check_top_function` directly.
  typecheck_ctx.func_types.set("foo", Function([], Unit))
  knf_ctx.globals.set("print_int", Function([Int], Unit))
  let code =
    #|fn foo() -> Unit {
    #|  let x = 1;
    #|  fn bar() -> Unit {
    #|    fn baz() -> Unit {
    #|      print_int(x);
    #|    }
    #|    baz();
    #|  }
    #|  bar();
    #|}
  let tokens = @lexer.tokenize(code)
  let (top_func, _) = @parser.parse_top_function(tokens)
  let typechecked_func = typecheck_ctx.check_top_function(top_func)
  let knf_func = knf_ctx.top_function_to_knf(typechecked_func)
  assert_true(knf_func.body.stmts.length() is 3)
  // Second statement is local function 'bar'
  assert_true(
    knf_func.body.stmts[1] is ClosureDef(closure) && // closure 'bar'
    closure.captured_vars.length() is 1 && // bar captures 'x'
    closure.body.stmts is [s1, _] &&
    s1 is ClosureDef(inner_closure) && // inner closure 'baz'
    inner_closure.captured_vars.length() is 1, // baz captures 'x' from bar
  )
}

///|
test "Top Function Knf Transformation Test" {
  let code =
    #|extern "C" fn print_int(n: Int) = "print_int";
    #|let a = 3;
    #|let b = 4;
    #|fn fold(arr: Array[Int], f: (Int, Int) -> Int, initv: Int) -> Int { 
    #|  let mut result = initv;
    #|  let mut i = 0; 
    #|  while i < arr.length() {
    #|    result = f(result, arr[i]);
    #|  }
    #|  result
    #|}
    #|
    #|fn main {
    #|  fn max(a, b) { if a > b { a } else { b } }
    #|  fn min(a, b) { if a < b { a } else { b } }
    #|  let numbers = [a, 1, b, 1, 5, 9, 2, 6, 5];
    #|  let maximum = fold(numbers, max, -1000);
    #|  let minimum = fold(numbers, min, 1000);
    #|  let max_min_diff = maximum - minimum;
    #|  print_int(max_min_diff);
    #|}
  let tokens = @lexer.tokenize(code)
  let program = @parser.parse(tokens)
  let program = @typecheck.typecheck(program)
  let knf = knf_transform(program)
  assert_true(knf.top_lets.contains("a"))
  assert_true(knf.top_lets.contains("b"))
  assert_true(knf.functions.contains("fold"))
  assert_true(knf.functions.contains("main"))
  // if you call println(knf), you should see
  // the knf program like follows: 
  // ```
  // let a : Int = 3;
  // let b : Int = 4;
  // fn fold(arr: Array[Int], f: (Int, Int) -> Int, initv: Int) -> Int {
  //   let mut result : Int = initv;
  //   let mut i : Int = 0;
  //   while {let tmp : () -> Int = arr.length; let tmp$1 : Int = tmp(); i < tmp$1; } {
  //     let tmp$2 : Int = arr[i];
  //     result = f(result, tmp$2);
  //   }
  //   result;
  // }
  // fn main {
  //   fn max(a$1 : Int, b$1 : Int) -> Int {
  //     if a$1 > b$1 {
  //       a$1;
  //     } else {
  //       b$1;
  //     };
  //   }
  //   fn min(a$1 : Int, b$1 : Int) -> Int {
  //     if a$1 < b$1 {
  //       a$1;
  //     } else {
  //       b$1;
  //     };
  //   }
  //   let tmp : Int = 1;
  //   let tmp$1 : Int = 1;
  //   let tmp$2 : Int = 5;
  //   let tmp$3 : Int = 9;
  //   let tmp$4 : Int = 2;
  //   let tmp$5 : Int = 6;
  //   let tmp$6 : Int = 5;
  //   let numbers : Array[Int] = [a, tmp, b, tmp$1, tmp$2, tmp$3, tmp$4, tmp$5, tmp$6];
  //   let tmp$7 : Int = 1000;
  //   let tmp$8 : Int = -tmp$7;
  //   let maximum : Int = fold(numbers, max, tmp$8);
  //   let tmp$9 : Int = 1000;
  //   let minimum : Int = fold(numbers, min, tmp$9);
  //   let max_min_diff : Int = maximum - minimum;
  //   print_int(max_min_diff);
  // }
  // ```
}

///|
test "Simple Apply Expr Knf Transformation Test" {
  // set x, y, z type in typecheck and knf context
  let typecheck_ctx = @typecheck.Context::new()
  typecheck_ctx.type_env.set("x", { kind: Int, mutable: false })
  typecheck_ctx.type_env.set("y", { kind: Double, mutable: false })
  typecheck_ctx.type_env.set("z", { kind: Bool, mutable: false })
  let knf_ctx = Context::new()
  knf_ctx.globals.set("x", Int)
  let _ = knf_ctx.add_new_name("y", Double)
  knf_ctx.enter_scope()
  let _ = knf_ctx.add_new_name("z", Bool)

  // Code parse, typecheck, knf transform
  let code =
    #|42 3.14 true "hello"
    #|x y z
  let tokens = @lexer.tokenize(code)
  let (e, tok_view) = @parser.parse_apply_expr(tokens)
  let e = typecheck_ctx.check_apply_expr(e)
  let (_, e) = knf_ctx.apply_expr_to_knf(e)
  assert_true(e is Int(42))
  let (e, tok_view) = @parser.parse_apply_expr(tok_view)
  let e = typecheck_ctx.check_apply_expr(e)
  let (_, e) = knf_ctx.apply_expr_to_knf(e)
  assert_true(e is Double(3.14))
  let (e, tok_view) = @parser.parse_apply_expr(tok_view)
  let e = typecheck_ctx.check_apply_expr(e)
  let (_, e) = knf_ctx.apply_expr_to_knf(e)
  assert_true(e is Bool(true))
  let (e, tok_view) = @parser.parse_apply_expr(tok_view)
  let e = typecheck_ctx.check_apply_expr(e)
  let (_, e) = knf_ctx.apply_expr_to_knf(e)
  assert_true(e is String("hello"))
  // find Global Ident `x`
  let (e, tok_view) = @parser.parse_apply_expr(tok_view)
  let e = typecheck_ctx.check_apply_expr(e)
  let (_, e) = knf_ctx.apply_expr_to_knf(e)
  assert_true(e is Ident({ id: "x", slot: 0 }))
  // find Parent Ident `y`
  let (e, tok_view) = @parser.parse_apply_expr(tok_view)
  let e = typecheck_ctx.check_apply_expr(e)
  let (_, e) = knf_ctx.apply_expr_to_knf(e)
  assert_true(e is Ident({ id: "y", slot: 0 }))
  // find Local Ident `z`
  let (e, _) = @parser.parse_apply_expr(tok_view)
  let e = typecheck_ctx.check_apply_expr(e)
  let (_, e) = knf_ctx.apply_expr_to_knf(e)
  assert_true(e is Ident({ id: "z", slot: 0 }))
}

///|
test "Simple Atom Expr Knf Transformation Test" {
  // set x, y, z type in typecheck and knf context
  let typecheck_ctx = @typecheck.Context::new()
  typecheck_ctx.type_env.set("x", { kind: Int, mutable: false })
  typecheck_ctx.type_env.set("y", { kind: Double, mutable: false })
  typecheck_ctx.type_env.set("z", { kind: Bool, mutable: false })
  let knf_ctx = Context::new()
  knf_ctx.globals.set("x", Int)
  let _ = knf_ctx.add_new_name("y", Double)
  knf_ctx.enter_scope()
  let _ = knf_ctx.add_new_name("z", Bool)

  // Code parse, typecheck, knf transform
  let code =
    #|42 3.14 true "hello"
    #|x y z
  // Parse
  let tokens = @lexer.tokenize(code)
  let (e, tok_view) = @parser.parse_atom_expr(tokens)
  let e = typecheck_ctx.check_atom_expr(e)
  let (_, e) = knf_ctx.atom_expr_to_knf(e)
  assert_true(e is Int(42))
  let (e, tok_view) = @parser.parse_atom_expr(tok_view)
  let e = typecheck_ctx.check_atom_expr(e)
  let (_, e) = knf_ctx.atom_expr_to_knf(e)
  assert_true(e is Double(3.14))
  let (e, tok_view) = @parser.parse_atom_expr(tok_view)
  let e = typecheck_ctx.check_atom_expr(e)
  let (_, e) = knf_ctx.atom_expr_to_knf(e)
  assert_true(e is Bool(true))
  let (e, tok_view) = @parser.parse_atom_expr(tok_view)
  let e = typecheck_ctx.check_atom_expr(e)
  let (_, e) = knf_ctx.atom_expr_to_knf(e)
  assert_true(e is String("hello"))
  // find Global Ident `x`
  let (e, tok_view) = @parser.parse_atom_expr(tok_view)
  let e = typecheck_ctx.check_atom_expr(e)
  let (_, e) = knf_ctx.atom_expr_to_knf(e)
  assert_true(e is Ident({ id: "x", slot: 0 }))
  // find Parent Ident `y`
  let (e, tok_view) = @parser.parse_atom_expr(tok_view)
  let e = typecheck_ctx.check_atom_expr(e)
  let (_, e) = knf_ctx.atom_expr_to_knf(e)
  assert_true(e is Ident({ id: "y", slot: 0 }))
  // find Local Ident `z`
  let (e, _) = @parser.parse_atom_expr(tok_view)
  let e = typecheck_ctx.check_atom_expr(e)
  let (_, e) = knf_ctx.atom_expr_to_knf(e)
  assert_true(e is Ident({ id: "z", slot: 0 }))
}

///|
test "Simple Expr Knf Transformation Test" {
  // set x, y, z type in typecheck and knf context
  let typecheck_ctx = @typecheck.Context::new()
  typecheck_ctx.type_env.set("x", { kind: Int, mutable: false })
  typecheck_ctx.type_env.set("y", { kind: Int, mutable: false })
  typecheck_ctx.type_env.set("z", { kind: Int, mutable: false })
  typecheck_ctx.type_env.set("w", { kind: Bool, mutable: false })
  let knf_ctx = Context::new()
  knf_ctx.globals.set("x", Int)
  let _ = knf_ctx.add_new_name("y", Int)
  let _ = knf_ctx.add_new_name("w", Int)
  knf_ctx.enter_scope()
  let _ = knf_ctx.add_new_name("z", Bool)

  // Code parse, typecheck, knf transform
  let code =
    #|42;
    #|-33;
    #|!w;
    #|x + y;
    #|2.0 * 3.14;
    #|x + y * z ;
  let tokens = @lexer.tokenize(code)
  // Parse and transform `42` 
  let (e, tok_view) = @parser.parse_expr(tokens)
  let e = typecheck_ctx.check_expr(e)
  let (_, e) = knf_ctx.expr_to_knf(e)
  assert_true(e is Int(42))
  // Parse and transform `-33`
  let (e, tok_view) = @parser.parse_expr(tok_view[1:])
  let e = typecheck_ctx.check_expr(e)
  let (stmts, e) = knf_ctx.expr_to_knf(e)
  assert_true(
    stmts is [s] && s is Let(n1, Int, Int(33)) && e is Neg(n2) && n1 == n2,
  )
  // Parse and transform `!z`
  let (e, tok_view) = @parser.parse_expr(tok_view[1:])
  let e = typecheck_ctx.check_expr(e)
  let (stmts, e) = knf_ctx.expr_to_knf(e)
  assert_true(
    stmts is [s] &&
    s is Let(n1, Bool, Ident(i)) &&
    i is { id: "w", .. } &&
    e is Not(n2) &&
    n1 == n2,
  )
  // Parse and transform `x + 10`
  let (e, tok_view) = @parser.parse_expr(tok_view[1:])
  let e = typecheck_ctx.check_expr(e)
  let (stmts, e) = knf_ctx.expr_to_knf(e)
  assert_true(
    stmts is [] &&
    e is Binary(Add, n1, n2) &&
    n1 is { id: "x", .. } &&
    n2 is { id: "y", .. },
  )
  // Parse and transform `2.0 * 3.14`
  let (e, tok_view) = @parser.parse_expr(tok_view[1:])
  let e = typecheck_ctx.check_expr(e)
  let (stmts, e) = knf_ctx.expr_to_knf(e)
  assert_true(
    stmts is [s1, s2] &&
    s1 is Let(n1, Double, Double(2.0)) &&
    s2 is Let(n2, Double, Double(3.14)) &&
    e is Binary(Mul, n3, n4) &&
    n1 == n3 &&
    n2 == n4,
  )
  // Parse and transform `x + y * z`
  let (e, _) = @parser.parse_expr(tok_view[1:])
  let e = typecheck_ctx.check_expr(e)
  let (stmts, e) = knf_ctx.expr_to_knf(e)
  assert_true(
    stmts is [s] &&
    s is Let(n1, Int, Binary(Mul, n2, n3)) &&
    e is Binary(Add, n4, n5) &&
    n1 is { id: "tmp", .. } &&
    n2 is { id: "y", .. } &&
    n3 is { id: "z", .. } &&
    n4 is { id: "x", .. } &&
    n5 == n1,
  )
}

///|
//test "Stmt Knf Transformation Test - 2" {
//  // Prelude Parts
//  let typecheck_ctx = @typecheck.Context::new()
//  let knf_ctx = @knf.Context::new()
//
//  // Setup struct definition for testing
//  let point_struct_def : @typecheck.StructDef = {
//    name: "Point",
//    fields: [
//      { name: "x", ty: { kind: Int, mutable: true } },
//      { name: "y", ty: { kind: Int, mutable: true } },
//    ],
//  }
//  typecheck_ctx.struct_defs.set("Point", point_struct_def)
//
//  // Setup type environment
//  typecheck_ctx.type_env.set("x", { kind: Int, mutable: true })
//  typecheck_ctx.type_env.set("arr", { kind: Array(Int), mutable: true })
//  typecheck_ctx.type_env.set("point", { kind: Struct("Point"), mutable: false })
//
//  // Set function context for return statement
//  typecheck_ctx.current_func_ret_ty = Some(Unit)
//
//  // Setup knf context
//  let _ = knf_ctx.add_new_name("x", Int)
//  let _ = knf_ctx.add_new_name("arr", Array(Int))
//  let _ = knf_ctx.add_new_name("point", Struct("Point"))
//
//  // Test Parts
//  let code =
//    #|let (a, b) = (10, 20);
//    #|x += 5;
//    #|arr[0] = 42;
//    #|point.x = 100;
//    #|return;
//
//  // Code parse, typecheck, knf transform
//  let tokens = @lexer.tokenize(code)
//
//  // Test 1: Parse and transform `let (a, b) = (10, 20);` (tuple pattern)
//  let (stmt, tok_view) = @parser.parse_stmt(tokens)
//  let stmt = typecheck_ctx.check_stmt(stmt)
//  let knf_stmts = knf_ctx.stmt_to_knf(stmt)
//  assert_true(
//    knf_stmts is [s1, s2, s3, s4] &&
//    s1 is Let(n1, Int, Int(10)) &&
//    s2 is Let(n2, Int, Int(20)) &&
//    s3 is Let(a, _, Ident(n1_)) &&
//    s4 is Let(b, _, Ident(n2_)) &&
//    n1 == n1_ &&
//    n2 == n2_ &&
//    a is { id: "a", .. } &&
//    b is { id: "b", .. },
//  )
//
//  // Test 2: Parse and transform `x += 5;` (compound assignment)
//  let (stmt, tok_view) = @parser.parse_stmt(tok_view)
//  let stmt = typecheck_ctx.check_stmt(stmt)
//  let knf_stmts = knf_ctx.stmt_to_knf(stmt)
//  assert_true(
//    knf_stmts is [s1, s2, s3] &&
//    s1 is Let(_, Int, Int(5)) &&
//    s2 is Let(_, Int, Binary(Add, _, _)) &&
//    s3 is Assign(name, Ident(_)) &&
//    name is { id: "x", .. },
//  )
//
//  // Test 3: Parse and transform `arr[0] = 42;` (array assignment)
//  let (stmt, tok_view) = @parser.parse_stmt(tok_view)
//  let stmt = typecheck_ctx.check_stmt(stmt)
//  let knf_stmts = knf_ctx.stmt_to_knf(stmt)
//  assert_true(
//    knf_stmts is [s1, s2] &&
//    s1 is Let(n1, Int, Int(0)) &&
//    s2 is ArrayPut(array_name, idx_name, Int(42)) &&
//    n1 == idx_name &&
//    array_name is { id: "arr", .. },
//  )
//
//  // Test 4: Parse and transform `point.x = 100;` (struct field assignment)
//  let (stmt, tok_view) = @parser.parse_stmt(tok_view)
//  let stmt = typecheck_ctx.check_stmt(stmt)
//  let knf_stmts = knf_ctx.stmt_to_knf(stmt)
//  assert_true(
//    knf_stmts is [s1, s2] &&
//    s1 is Let(n1, Int, Int(100)) &&
//    s2 is StructFieldSet(_, "x", value_name) &&
//    n1 == value_name,
//  )
//
//  // Test 5: Parse and transform `return;` (return without value)
//  let (stmt, _) = @parser.parse_stmt(tok_view)
//  let stmt = typecheck_ctx.check_stmt(stmt)
//  let knf_stmts = knf_ctx.stmt_to_knf(stmt)
//  assert_true(knf_stmts is [s] && s is ReturnUnit)
//}

test "Stmt Knf Transformation Test" {
  // Prelude Parts
  let typecheck_ctx = @typecheck.Context::new()
  let knf_ctx = @knf.Context::new()

  // Setup struct definition for testing
  let point_struct_def : @typecheck.StructDef = {
    name: "Point",
    fields: [
      { name: "x", ty: { kind: Int, mutable: true } },
      { name: "y", ty: { kind: Int, mutable: true } },
    ],
    methods: Map::new(),
  }
  typecheck_ctx.struct_defs.set("Point", point_struct_def)

  // Set function context for return statement
  typecheck_ctx.current_func_ret_ty = Some(Struct("Point"))
  let code =
    #|let mut p = Point::{ x: 0, y: 0 };
    #|let mut a = 100;
    #|let (b, c) = (200, 300);
    #|let arr = [a, b, c];
    #|a *= 50;
    #|p.x += b + c;
    #|arr[1] = a - 25;
    #|return p;

  // Code parse, typecheck, knf transform
  let tokens = @lexer.tokenize(code)

  // Test 1: Parse and transform `let mut p = Point::{ mut x: 0, y: 0 };`
  let (stmt, tok_view) = @parser.parse_stmt(tokens)
  let stmt = typecheck_ctx.check_stmt(stmt)
  let knf_stmts = knf_ctx.stmt_to_knf(stmt)
  assert_true(
    knf_stmts is [s1, s2, s3] &&
    s1 is Let(_, Int, Int(0)) &&
    s2 is Let(_, Int, Int(0)) &&
    s3 is LetMut(name, Struct("Point"), CreateStruct("Point", fields)) &&
    name is { id: "p", .. } &&
    fields is [field1, field2] &&
    field1 is ("x", _) &&
    field2 is ("y", _),
  )

  // Test 2: Parse and transform `let mut a = 100;`
  let (stmt, tok_view) = @parser.parse_stmt(tok_view)
  let stmt = typecheck_ctx.check_stmt(stmt)
  let knf_stmts = knf_ctx.stmt_to_knf(stmt)
  assert_true(
    knf_stmts is [s] &&
    s is LetMut(name, Int, Int(100)) &&
    name is { id: "a", .. },
  )

  // Test 3: Parse and transform `let (b, c) = (200, 300);`
  let (stmt, tok_view) = @parser.parse_stmt(tok_view)
  let stmt = typecheck_ctx.check_stmt(stmt)
  let knf_stmts = knf_ctx.stmt_to_knf(stmt)
  assert_true(
    knf_stmts is [s1, s2, s3, s4] &&
    s1 is Let(n1, Int, Int(200)) &&
    s2 is Let(n2, Int, Int(300)) &&
    s3 is Let(b, _, Ident(n1_)) &&
    s4 is Let(c, _, Ident(n2_)) &&
    n1 == n1_ &&
    n2 == n2_ &&
    b is { id: "b", .. } &&
    c is { id: "c", .. },
  )

  // Test 4: Parse and transform `let arr = [a, b, c];`
  let (stmt, tok_view) = @parser.parse_stmt(tok_view)
  let stmt = typecheck_ctx.check_stmt(stmt)
  let knf_stmts = knf_ctx.stmt_to_knf(stmt)
  assert_true(
    knf_stmts is [s] &&
    s is Let(name, Array(Int), ArrayLiteral(_, elements)) &&
    name is { id: "arr", .. } &&
    elements is [elem1, elem2, elem3] &&
    elem1 is { id: "a", .. } &&
    elem2 is { id: "b", .. } &&
    elem3 is { id: "c", .. },
  )

  // Test 5: Parse and transform `a *= 50;`
  let (stmt, tok_view) = @parser.parse_stmt(tok_view)
  let stmt = typecheck_ctx.check_stmt(stmt)
  let knf_stmts = knf_ctx.stmt_to_knf(stmt)
  assert_true(
    knf_stmts is [s1, s2, s3] &&
    s1 is Let(_, Int, Int(50)) &&
    s2 is Let(_, Int, Binary(Mul, _, _)) &&
    s3 is Assign(name, Ident(_)) &&
    name is { id: "a", .. },
  )

  // Test 6: Parse and transform `p.x += b + c;`
  let (stmt, tok_view) = @parser.parse_stmt(tok_view)
  let stmt = typecheck_ctx.check_stmt(stmt)
  let knf_stmts = knf_ctx.stmt_to_knf(stmt)
  assert_true(
    knf_stmts is [s1, s2, s3, s4, s5] &&
    s1 is Let(n1, Int, FieldAccess(_, "x")) &&
    s2 is Let(n2, Int, Binary(Add, { id: "b", .. }, { id: "c", .. })) &&
    s3 is Let(n3, Int, Binary(Add, n1_, n2_)) &&
    s4 is Let(n4, Int, Ident(n3_)) &&
    s5 is StructFieldSet(_, "x", n4_) &&
    n1 == n1_ &&
    n2 == n2_ &&
    n3 == n3_ &&
    n4 == n4_,
  )

  // Test 7: Parse and transform `arr[1] = a - 25;`
  let (stmt, tok_view) = @parser.parse_stmt(tok_view)
  let stmt = typecheck_ctx.check_stmt(stmt)
  let knf_stmts = knf_ctx.stmt_to_knf(stmt)
  assert_true(
    knf_stmts is [s1, s2, s3] &&
    s1 is Let(_, Int, Int(1)) &&
    s2 is Let(_, Int, Int(25)) &&
    s3 is ArrayPut(_),
  )

  // Test 8: Parse and transform `return p;`
  let (stmt, _) = @parser.parse_stmt(tok_view)
  let stmt = typecheck_ctx.check_stmt(stmt)
  let knf_stmts = knf_ctx.stmt_to_knf(stmt)
  assert_true(
    knf_stmts is [s] &&
    s is Return(return_expr) &&
    return_expr is Ident({ id: "p", .. }),
  )
}
/// ================================================================================
/// # 🏗️ 结构体定义的 KNF 转换
///
/// ## 🎯 什么是结构体定义？
///
/// 结构体定义是编程语言中定义复合数据类型的方式，它允许我们将多个相关的数据组合在一起。
/// 结构体定义的基本结构是：
/// struct StructName {
///   field1: Type1;
///   field2: Type2;
///   mut field3: Type3;
/// }
///
/// 结构体定义的特点：
/// - 定义了一个新的数据类型
/// - 包含多个字段，每个字段有名称和类型
/// - 字段可以是可变的（mut）或不可变的
/// - 结构体定义本身不产生运行时代码，只是类型定义
///
/// ## 🔍 结构差异分析
///
/// 在语法树中，结构体定义的结构相对简单：
/// - `name`: 结构体名称（String）
/// - `fields`: 字段列表（Array[StructField]）
///
/// 在 KNF 中，结构体定义的结构更加统一：
/// - `KnfStructDef`: 包含 name 和 fields 的结构体
/// - `fields`: 字段列表，每个字段包含（字段名，是否可变，字段类型）
///
/// ## 🛠️ 实现思路
///
/// 实现 `struct_def_to_knf` 函数需要两个主要步骤：
///
/// ### 1. 字段转换
/// - 遍历结构体的所有字段
/// - 对每个字段，提取字段名、可变性和类型
/// - 使用 `typekind_to_knf` 转换字段类型
/// - 将字段信息存储为（字段名，是否可变，字段类型）的元组
///
/// ### 2. 构造结构体定义
/// - 创建 `KnfStructDef` 结构
/// - 设置结构体名称和转换后的字段列表
/// - 返回转换后的结构体定义
///
/// ## 🔧 关键实现细节
///
/// ### 字段信息提取
/// 从 `StructField` 中提取字段信息：
/// - `name`: 字段名称
/// - `ty.kind`: 字段类型
/// - `ty.mutable`: 字段是否可变
///
/// ### 类型转换
/// 使用 `typekind_to_knf` 将字段类型转换为 KNF 类型：
/// - Int -> Int
/// - String -> String
/// - Double -> Double
/// - 其他类型按需转换
///
/// ### 字段存储
/// 将字段信息存储为元组格式：
/// (字段名: String, 是否可变: Bool, 字段类型: Type)
///
/// ## 📝 测试用例解析
///
/// ### 测试用例 1：简单结构体
/// struct Point {
///   x: Int;
///   y: Int;
/// }
/// 转换过程：
/// 1. 结构体名称：Point
/// 2. 字段列表：[(x, false, Int), (y, false, Int)]
/// 3. 返回 KnfStructDef { name: "Point", fields: [...] }
///
/// ### 测试用例 2：包含可变字段的结构体
/// struct Person {
///   name: String;
///   age: Int;
///   mut score: Double;
/// }
/// 转换过程：
/// 1. 结构体名称：Person
/// 2. 字段列表：[(name, false, String), (age, false, Int), (score, true, Double)]
/// 3. 返回 KnfStructDef { name: "Person", fields: [...] }
///
/// ### 测试用例 3：空结构体
/// struct Empty {}
/// 转换过程：
/// 1. 结构体名称：Empty
/// 2. 字段列表：[]
/// 3. 返回 KnfStructDef { name: "Empty", fields: [] }
///
/// ## 💡 设计思想
///
/// ### 类型定义
/// 结构体定义是类型定义，不产生运行时代码，只是定义数据结构。
///
/// ### 字段信息保留
/// 保留字段的完整信息，包括名称、可变性和类型。
///
/// ### 类型统一
/// 将字段类型转换为统一的 KNF 类型表示。
///
/// ### 结构简化
/// 在 KNF 中简化结构体定义的表示，便于后续处理。
///
/// ## 🚀 实现挑战
///
/// ### 字段遍历
/// 需要正确遍历结构体的所有字段。
///
/// ### 类型转换
/// 需要正确转换字段类型为 KNF 类型。
///
/// ### 信息提取
/// 需要正确提取字段的名称、可变性和类型信息。
///
/// ## 🎯 实现目标
///
/// 完成 `struct_def.mbt` 中的 `struct_def_to_knf` 函数，实现结构体定义的 KNF 转换。
/// 函数应该：
/// 1. 正确遍历结构体的所有字段
/// 2. 正确提取字段的名称、可变性和类型信息
/// 3. 正确转换字段类型为 KNF 类型
/// 4. 返回统一的 KnfStructDef 结构
///
/// 现在让我们开始实现结构体定义的转换吧！🚀
///
/// ================================================================================

///|
test "Struct Def Knf Transformation Test" {
  // Prelude Parts
  let typecheck_ctx = @typecheck.Context::new()
  let knf_ctx = @knf.Context::new()

  // Put all code together
  let code =
    #|struct Point {
    #|  x: Int;
    #|  y: Int;
    #|}
    #|struct Person {
    #|  name: String;
    #|  age: Int;
    #|  mut score: Double;
    #|}
    #|struct Empty {}
  let tokens = @lexer.tokenize(code)

  // Test 1: Simple struct with two immutable fields
  let (struct_def1, tok_view) = @parser.parse_struct_def(tokens)
  let checked_struct_def1 = typecheck_ctx.check_struct_def(struct_def1)
  let knf_struct_def1 = knf_ctx.struct_def_to_knf(checked_struct_def1)
  assert_true(knf_struct_def1.name == "Point")
  assert_true(knf_struct_def1.fields.length() is 2)
  assert_true(
    knf_struct_def1.fields[0] is (field_name1, is_mut1, field_type1) &&
    field_name1 == "x" &&
    is_mut1 == false &&
    field_type1 is Int,
  )
  assert_true(
    knf_struct_def1.fields[1] is (field_name2, is_mut2, field_type2) &&
    field_name2 == "y" &&
    is_mut2 == false &&
    field_type2 is Int,
  )

  // Test 2: Struct with mutable field
  let (struct_def2, tok_view) = @parser.parse_struct_def(tok_view)
  let checked_struct_def2 = typecheck_ctx.check_struct_def(struct_def2)
  let knf_struct_def2 = knf_ctx.struct_def_to_knf(checked_struct_def2)
  assert_true(knf_struct_def2.name == "Person")
  assert_true(knf_struct_def2.fields.length() is 3)
  assert_true(
    knf_struct_def2.fields[0] is (field_name3, is_mut3, field_type3) &&
    field_name3 == "name" &&
    is_mut3 == false &&
    field_type3 is String,
  )
  assert_true(
    knf_struct_def2.fields[1] is (field_name4, is_mut4, field_type4) &&
    field_name4 == "age" &&
    is_mut4 == false &&
    field_type4 is Int,
  )
  assert_true(
    knf_struct_def2.fields[2] is (field_name5, is_mut5, field_type5) &&
    field_name5 == "score" &&
    is_mut5 == true &&
    field_type5 is Double,
  )

  // Test 3: Empty struct
  let (struct_def3, _) = @parser.parse_struct_def(tok_view)
  let checked_struct_def3 = typecheck_ctx.check_struct_def(struct_def3)
  let knf_struct_def3 = knf_ctx.struct_def_to_knf(checked_struct_def3)
  assert_true(knf_struct_def3.name == "Empty")
  assert_true(knf_struct_def3.fields.is_empty())
}
/// ================================================================================
/// # 🔧 顶层函数的 KNF 转换
///
/// ## 🎯 什么是顶层函数？
///
/// 顶层函数是程序中最顶层的函数定义，它们定义全局可调用的函数。
/// 顶层函数的基本结构是：
/// fn function_name(param1: Type1, param2: Type2) -> ReturnType {
///   // 函数体
/// }
///
/// 顶层函数的特点：
/// - 定义了一个新的函数
/// - 包含参数列表、返回类型和函数体
/// - 函数体是一个 BlockExpr
/// - 需要在全局作用域中注册函数签名
/// - 函数参数在函数作用域中定义
///
/// ## 🔍 结构差异分析
///
/// 在语法树中，顶层函数的结构相对简单：
/// - `fname`: 函数名称（String）
/// - `param_list`: 参数列表（Array[Param]）
/// - `ret_ty`: 返回类型（TypeKind）
/// - `body`: 函数体（BlockExpr）
///
/// 在 KNF 中，顶层函数的结构更加统一：
/// - `KnfFunction`: 包含 name、ret_ty、params、body 的结构体
/// - `params`: 参数列表，每个参数包含（Name，Type）
/// - `body`: 函数体（KnfBlock）
///
/// ## 🛠️ 实现思路
///
/// 实现 `top_function_to_knf` 函数需要五个主要步骤：
///
/// ### 1. 进入函数作用域
/// - 使用 `enter_scope()` 创建新的作用域
/// - 为函数参数和局部变量提供独立的作用域
///
/// ### 2. 参数处理
/// - 遍历参数列表，为每个参数创建 Name
/// - 使用 `typekind_to_knf` 转换参数类型
/// - 将参数注册到当前作用域中
/// - 收集参数信息用于函数类型构造
///
/// ### 3. 返回类型转换
/// - 使用 `typekind_to_knf` 转换返回类型
/// - 构造函数类型 `Function(param_types, ret_ty)`
///
/// ### 4. 函数体转换
/// - 使用 `block_expr_to_knf` 转换函数体
/// - 函数体中的所有语句都在函数作用域中处理
///
/// ### 5. 退出作用域并注册
/// - 使用 `exit_scope()` 退出函数作用域
/// - 将函数注册到全局作用域中
/// - 返回 `KnfFunction` 结构
///
/// ## 🔧 关键实现细节
///
/// ### 作用域管理
/// 顶层函数的转换需要谨慎管理作用域：
/// - 在开始处理参数前进入作用域
/// - 在函数体转换完成后退出作用域
/// - 确保参数和局部变量在正确的作用域中
///
/// ### 参数处理
/// 为每个参数创建 Name 并注册到作用域：
/// fn add(x: Int, y: Int) -> Int { ... }
/// 转换为：
/// - 创建 Name { id: "x", slot: 0 } 和 Name { id: "y", slot: 0 }
/// - 注册到当前作用域
/// - 收集参数类型用于函数类型构造
///
/// ### 函数类型构造
/// 构造函数类型用于全局注册：
/// - 参数类型列表：[Int, Int]
/// - 返回类型：Int
/// - 函数类型：Function([Int, Int], Int)
///
/// ### 全局注册
/// 将函数注册到全局作用域：
/// - 使用函数名作为键
/// - 使用函数类型作为值
/// - 确保函数可以被其他代码调用
///
/// ## 📝 测试用例解析
///
/// ### 测试用例 1：简单函数
/// fn add(x: Int, y: Int) -> Int {
///   return x + y;
/// }
/// 转换过程：
/// 1. 进入作用域
/// 2. 处理参数：x, y
/// 3. 转换函数体：return x + y;
/// 4. 退出作用域
/// 5. 注册到全局作用域
///
/// ### 测试用例 2：Unit 返回类型
/// fn greet(name: String) -> Unit {
///   return ();
/// }
/// 转换过程：
/// 1. 进入作用域
/// 2. 处理参数：name
/// 3. 转换函数体：return ();
/// 4. 退出作用域
/// 5. 注册到全局作用域
///
/// ### 测试用例 3：递归函数
/// fn fib(n: Int) -> Int {
///   if n <= 1 {
///     return n;
///   } else {
///     return fib(n - 1) + fib(n - 2);
///   }
/// }
/// 转换过程：
/// 1. 进入作用域
/// 2. 处理参数：n
/// 3. 转换函数体：if 表达式和递归调用
/// 4. 退出作用域
/// 5. 注册到全局作用域
///
/// ### 测试用例 4：多语句函数
/// fn compute(a: Int, b: Int, c: Int) -> Int {
///   let sum = a + b;
///   let result = sum * c;
///   return result;
/// }
/// 转换过程：
/// 1. 进入作用域
/// 2. 处理参数：a, b, c
/// 3. 转换函数体：let 语句和 return 语句
/// 4. 退出作用域
/// 5. 注册到全局作用域
///
/// ## 💡 设计思想
///
/// ### 作用域隔离
/// 每个函数都有独立的作用域，参数和局部变量不会相互干扰。
///
/// ### 参数管理
/// 参数在函数作用域中定义，可以被函数体中的语句使用。
///
/// ### 全局注册
/// 函数定义后需要注册到全局作用域，供其他代码调用。
///
/// ### 类型安全
/// 确保函数参数和返回类型的类型安全。
///
/// ## 🚀 实现挑战
///
/// ### 作用域时机
/// 需要谨慎决策进入作用域和退出作用域的时机：
/// - 在参数处理前进入作用域
/// - 在函数体转换完成后退出作用域
/// - 确保全局注册在作用域外进行
///
/// ### 参数处理
/// 需要正确处理参数列表，为每个参数创建 Name 并注册到作用域。
///
/// ### 函数类型构造
/// 需要正确构造函数类型，包括参数类型列表和返回类型。
///
/// ### 全局注册
/// 需要将函数正确注册到全局作用域，确保函数可以被调用。
///
/// ## 🎯 实现目标
///
/// 完成 `function.mbt` 中的 `top_function_to_knf` 函数，实现顶层函数的 KNF 转换。
/// 函数应该：
/// 1. 正确管理函数作用域（enter_scope 和 exit_scope）
/// 2. 正确处理参数列表，为每个参数创建 Name
/// 3. 正确转换参数类型和返回类型
/// 4. 正确转换函数体为 KNF
/// 5. 将函数注册到全局作用域
/// 6. 返回统一的 KnfFunction 结构
///
/// 现在让我们开始实现顶层函数的转换吧！🚀
///
/// ================================================================================

///|
test "Top Function Knf Transformation Test - 2" {
  // Prelude Parts
  let typecheck_ctx = @typecheck.Context::new()
  let knf_ctx = @knf.Context::new()

  // Setup builtin functions
  typecheck_ctx.func_types.set("print_int", Function([Int], Unit))
  typecheck_ctx.type_env.set("print_int", {
    kind: Function([Int], Unit),
    mutable: false,
  })
  knf_ctx.globals.set("print_int", Function([Int], Unit))
  let code =
    #|fn add(x: Int, y: Int) -> Int {
    #|  return x + y;
    #|}
    #|fn greet(name: String) -> Unit {
    #|  return ();
    #|}
    #|fn fib(n: Int) -> Int {
    #|  if n <= 1 {
    #|    return n;
    #|  } else {
    #|    return fib(n - 1) + fib(n - 2);
    #|  }
    #|}
    #|fn compute(a: Int, b: Int, c: Int) -> Int {
    #|  let sum = a + b;
    #|  let result = sum * c;
    #|  return result;
    #|}

  // Register function signatures first
  typecheck_ctx.func_types.set("add", Function([Int, Int], Int))
  typecheck_ctx.type_env.set("add", {
    kind: Function([Int, Int], Int),
    mutable: false,
  })
  typecheck_ctx.func_types.set("greet", Function([String], Unit))
  typecheck_ctx.type_env.set("greet", {
    kind: Function([String], Unit),
    mutable: false,
  })
  typecheck_ctx.func_types.set("fib", Function([Int], Int))
  typecheck_ctx.type_env.set("fib", {
    kind: Function([Int], Int),
    mutable: false,
  })
  typecheck_ctx.func_types.set("compute", Function([Int, Int, Int], Int))
  typecheck_ctx.type_env.set("compute", {
    kind: Function([Int, Int, Int], Int),
    mutable: false,
  })
  let tokens = @lexer.tokenize(code)

  // Test 1: Simple function with two parameters and return
  let (top_func1, tok_view) = @parser.parse_top_function(tokens)
  let checked_func1 = typecheck_ctx.check_top_function(top_func1)
  let knf_func1 = knf_ctx.top_function_to_knf(checked_func1)
  assert_true(knf_func1.name == "add")
  assert_true(knf_func1.ret_ty is Int)
  assert_true(knf_func1.params.length() is 2)
  assert_true(
    knf_func1.params[0] is (param_name1, param_type1) &&
    param_name1 is { id: "x", slot: 0 } &&
    param_type1 is Int,
  )
  assert_true(
    knf_func1.params[1] is (param_name2, param_type2) &&
    param_name2 is { id: "y", slot: 0 } &&
    param_type2 is Int,
  )
  // Body should have: return x + y;
  assert_true(knf_func1.body.stmts.length() is 1)
  assert_true(
    knf_func1.body.stmts is [s] &&
    s is Return(Binary(Add, x_name, y_name)) &&
    x_name is { id: "x", .. } &&
    y_name is { id: "y", .. },
  )

  // Test 2: Function with String parameter returning Unit
  let (top_func2, tok_view) = @parser.parse_top_function(tok_view)
  let checked_func2 = typecheck_ctx.check_top_function(top_func2)
  let knf_func2 = knf_ctx.top_function_to_knf(checked_func2)
  assert_true(knf_func2.name == "greet")
  assert_true(knf_func2.ret_ty is Unit)
  assert_true(knf_func2.params.length() is 1)
  assert_true(
    knf_func2.params is [(param_name3, param_type3)] &&
    param_name3 is { id: "name", slot: 0 } &&
    param_type3 is String,
  )
  // Body should have: return ();
  assert_true(knf_func2.body.stmts.length() is 1)
  assert_true(knf_func2.body.stmts[0] is Return(Unit))

  // Test 3: Recursive function with if expression
  let (top_func3, tok_view) = @parser.parse_top_function(tok_view)
  let checked_func3 = typecheck_ctx.check_top_function(top_func3)
  let knf_func3 = knf_ctx.top_function_to_knf(checked_func3)
  assert_true(knf_func3.name == "fib")
  assert_true(knf_func3.ret_ty is Int)
  assert_true(knf_func3.params.length() is 1)
  assert_true(
    knf_func3.params[0] is (param_name4, param_type4) &&
    param_name4 is { id: "n", slot: 0 } &&
    param_type4 is Int,
  )
  // Body should contain if expression and recursive calls
  // We don't need to verify the exact structure, just that it's transformed
  assert_true(knf_func3.body.stmts.length() > 0)

  // Test 4: Function with multiple statements in body
  let (top_func4, _) = @parser.parse_top_function(tok_view)
  let checked_func4 = typecheck_ctx.check_top_function(top_func4)
  let knf_func4 = knf_ctx.top_function_to_knf(checked_func4)
  assert_true(knf_func4.name == "compute")
  assert_true(knf_func4.ret_ty is Int)
  assert_true(knf_func4.params.length() is 3)
  // Body should have: let sum = a + b; let result = sum * c; return result;
  assert_true(knf_func4.body.stmts.length() is 3)
  assert_true(
    knf_func4.body.stmts[0] is Let(sum_name, Int, Binary(Add, a_name, b_name)) &&
    sum_name is { id: "sum", .. } &&
    a_name is { id: "a", .. } &&
    b_name is { id: "b", .. },
  )
  assert_true(
    knf_func4.body.stmts[1]
    is Let(result_name, Int, Binary(Mul, sum_name2, c_name)) &&
    result_name is { id: "result", .. } &&
    sum_name2 is { id: "sum", .. } &&
    c_name is { id: "c", .. },
  )
  assert_true(
    knf_func4.body.stmts[2] is Return(Ident(result_name2)) &&
    result_name2 is { id: "result", .. },
  )
}
/// ================================================================================
/// # 🌍 顶层 Let 语句的 KNF 转换
///
/// ## 🎯 什么是顶层 Let 语句？
///
/// 顶层 Let 语句是程序中最顶层的变量声明，它们定义全局变量和常量。
/// 顶层 Let 语句的基本结构是：
/// let variable_name: Type = expression;
///
/// 与函数内的 Let 语句不同，顶层 Let 语句：
/// - 左边不是模式（Pattern），而是简单的标识符
/// - 声明的是全局变量，需要在全局作用域中注册
/// - 转换完成后需要注册到 Context 的 globals 字段中
///
/// ## 🔍 结构差异分析
///
/// 在语法树中，顶层 Let 语句的结构相对简单：
/// - `name`: 变量名（String）
/// - `ty`: 类型（Type）
/// - `expr`: 初始化表达式（Expr）
///
/// 但在 KNF 中，顶层 Let 语句的结构更加统一：
/// - `KnfTopLet`: 包含 name、ty、expr 的结构体
/// - 变量名被转换为 `Name` 结构
/// - 类型被转换为 KNF 类型
/// - 表达式被转换为 KNF 表达式
///
/// ## 🛠️ 实现思路
///
/// 实现 `top_let_to_knf` 函数需要四个主要步骤：
///
/// ### 1. 表达式转换
/// - 使用 `expr_to_knf` 转换初始化表达式
/// - 收集表达式转换过程中产生的语句
///
/// ### 2. 类型转换
/// - 使用 `typekind_to_knf` 转换类型
/// - 确保类型一致性
///
/// ### 3. 重复声明检查
/// - 检查 globals 中是否已存在同名变量
/// - 如果存在，抛出重复声明错误
///
/// ### 4. 全局注册
/// - 使用 `add_new_name` 创建新的 Name
/// - 将变量注册到 globals 字段中
/// - 返回 `KnfTopLet` 结构
///
/// ## 🔧 关键实现细节
///
/// ### 全局变量管理
/// 顶层 Let 语句声明的变量需要注册到全局作用域：
/// let x: Int = 42;
/// 转换为：
/// - 创建 Name { id: "x", slot: 0 }
/// - 注册到 globals["x"] = Int
/// - 返回 KnfTopLet { name, ty: Int, expr: Int(42) }
///
/// ### 重复声明检查
/// 在注册全局变量之前，需要检查是否已存在：
/// guard self.globals.get(top_let.name) is None else {
///   raise KnfTransformError("Duplicate global variable declaration: ...")
/// }
///
/// ### 表达式处理
/// 初始化表达式可能包含复杂的计算，需要先转换为 KNF：
/// let sum = a + b;
/// 转换为：
/// - 表达式 a + b 转换为 KNF
/// - 创建全局变量 sum
/// - 注册到 globals
///
/// ### 类型一致性
/// 确保声明的类型与表达式的类型一致：
/// - 如果提供了类型注解，需要验证类型兼容性
/// - 如果没有类型注解，使用表达式的推断类型
///
/// ## 📝 测试用例解析
///
/// ### 测试用例 1：简单类型注解
/// let x: Int = 42;
/// 转换过程：
/// 1. 表达式 42 转换为 Int(42)
/// 2. 类型 Int 保持不变
/// 3. 创建 Name { id: "x", slot: 0 }
/// 4. 注册到 globals["x"] = Int
///
/// ### 测试用例 2：类型推断
/// let y = 3.14;
/// 转换过程：
/// 1. 表达式 3.14 转换为 Double(3.14)
/// 2. 推断类型为 Double
/// 3. 创建 Name { id: "y", slot: 0 }
/// 4. 注册到 globals["y"] = Double
///
/// ### 测试用例 3：字符串类型
/// let s: String = "hello";
/// 转换过程：
/// 1. 表达式 "hello" 转换为 String("hello")
/// 2. 类型 String 保持不变
/// 3. 创建 Name { id: "s", slot: 0 }
/// 4. 注册到 globals["s"] = String
///
/// ### 测试用例 4：复杂表达式
/// let sum = a + b;
/// 转换过程：
/// 1. 表达式 a + b 转换为 Binary(Add, a_name, b_name)
/// 2. 推断类型为 Int
/// 3. 创建 Name { id: "sum", slot: 0 }
/// 4. 注册到 globals["sum"] = Int
///
/// ## 💡 设计思想
///
/// ### 全局作用域管理
/// 顶层 Let 语句声明的变量属于全局作用域，需要统一管理。
///
/// ### 重复声明防护
/// 通过检查 globals 字段，防止重复声明全局变量。
///
/// ### 类型安全
/// 确保声明的类型与表达式的类型一致，保证类型安全。
///
/// ### 统一结构
/// 将顶层 Let 语句转换为统一的 KnfTopLet 结构，便于后续处理。
///
/// ## 🚀 实现挑战
///
/// ### 全局变量管理
/// 需要正确管理全局变量的注册和查找，避免命名冲突。
///
/// ### 类型一致性检查
/// 需要确保声明的类型与表达式的类型一致。
///
/// ### 重复声明处理
/// 需要检查并防止重复声明全局变量。
///
/// ### 表达式复杂性
/// 初始化表达式可能包含复杂的计算，需要正确转换为 KNF。
///
/// ## 🎯 实现目标
///
/// 完成 `top_let.mbt` 中的 `top_let_to_knf` 函数，实现顶层 Let 语句的 KNF 转换。
/// 函数应该：
/// 1. 正确转换初始化表达式为 KNF
/// 2. 正确转换类型为 KNF 类型
/// 3. 检查重复声明并防止冲突
/// 4. 将变量注册到全局作用域
/// 5. 返回统一的 KnfTopLet 结构
///
/// 现在让我们开始实现顶层 Let 语句的转换吧！🚀
///
/// ================================================================================

///|
test "Top Let Knf Transformation Test" {
  // Prelude Parts
  let typecheck_ctx = @typecheck.Context::new()
  let knf_ctx = @knf.Context::new()

  // Test 1: Simple top-level let with type annotation: let x: Int = 42;
  let code =
    #|let x: Int = 42;
    #|let y = 3.14;
    #|let s: String = "hello";
    #|let a = 1;
    #|let b = 2;
    #|let sum = a + b;
  let tokens1 = @lexer.tokenize(code)
  // Test 1: Check the structure
  let (top_let1, tok_view) = @parser.parse_top_let(tokens1)
  let checked_top_let1 = typecheck_ctx.check_top_let(top_let1)
  let knf_top_let1 = knf_ctx.top_let_to_knf(checked_top_let1)
  assert_true(
    knf_top_let1.name is { id: "x", slot: 0 } &&
    knf_top_let1.ty is Int &&
    knf_top_let1.expr is Int(42),
  )

  // Test 2: Check the structure
  let (top_let2, tok_view) = @parser.parse_top_let(tok_view)
  let checked_top_let2 = typecheck_ctx.check_top_let(top_let2)
  let knf_top_let2 = knf_ctx.top_let_to_knf(checked_top_let2)
  assert_true(
    knf_top_let2.name is { id: "y", slot: 0 } &&
    knf_top_let2.ty is Double &&
    knf_top_let2.expr is Double(3.14),
  )

  // Test 3: Top-level let with string: let s: String = "hello";
  let (top_let3, tok_view) = @parser.parse_top_let(tok_view)
  let checked_top_let3 = typecheck_ctx.check_top_let(top_let3)
  let knf_top_let3 = knf_ctx.top_let_to_knf(checked_top_let3)

  // Test 3: Check the structure
  assert_true(
    knf_top_let3.name is { id: "s", slot: 0 } &&
    knf_top_let3.ty is String &&
    knf_top_let3.expr is String("hello"),
  )

  // Test 4: Top-level let with computation: let sum = 10 + 20;
  let (top_let, tok_view) = @parser.parse_top_let(tok_view)
  let checked_top_let4 = typecheck_ctx.check_top_let(top_let)
  let _ = knf_ctx.top_let_to_knf(checked_top_let4)
  let (top_let, tok_view) = @parser.parse_top_let(tok_view)
  let checked_top_let4 = typecheck_ctx.check_top_let(top_let)
  let _ = knf_ctx.top_let_to_knf(checked_top_let4)
  let (top_let4, _) = @parser.parse_top_let(tok_view)
  let checked_top_let4 = typecheck_ctx.check_top_let(top_let4)
  let knf_top_let4 = knf_ctx.top_let_to_knf(checked_top_let4)
  assert_true(
    knf_top_let4.name is { id: "sum", slot: 0 } &&
    knf_top_let4.ty is Int &&
    knf_top_let4.expr is Binary(Add, l, r) &&
    l is { id: "a", .. } &&
    r is { id: "b", .. },
  )
}
/// ================================================================================
/// # 🚀 欢迎来到 KNF 变换的世界！
///
/// 🎉 **恭喜你完成了类型检查阶段的所有挑战！** 🎉
///
/// 现在，我们将进入编译器构建之旅的第四个重要阶段：**KNF 变换 (Kernel Normal Form Transformation)**。
/// 这是连接高级语言和底层代码生成之间的关键桥梁！
///
/// ## 🌟 什么是中间表示 IR？
///
/// 在编译器的世界中，**中间表示 (Intermediate Representation, IR)** 是一个极其重要的概念。
/// 想象一下，编译器就像一个翻译官，需要将人类编写的高级语言代码翻译成机器能够理解的指令。
/// 但是，这个翻译过程往往不是一步到位的，而是需要经过多个中间步骤。
///
/// **IR 就是这些中间步骤中的"通用语言"**：
/// - 它既不像源代码那样复杂和多样化
/// - 也不像机器码那样底层和特定于硬件
/// - 而是处于两者之间的一个**抽象层次**，既保持了程序的核心语义，又简化了后续的处理
///
/// ## 🔄 什么是 ANF？
///
/// **ANF (Administrative Normal Form)** 是一种重要的中间表示形式。
/// 它的核心思想是：**将所有的复杂表达式都分解成简单的原子操作**。
///
/// 在 ANF 中：
/// - 每个表达式要么是一个**原子值**（变量、字面量等）
/// - 要么是一个**简单的函数调用**，其参数都是原子值
/// - 复杂的嵌套表达式会被"拉平"，通过引入临时变量来分解
///
/// 例如，`f(g(x), h(y))` 会被转换为：
/// ```
/// let temp1 = g(x)
/// let temp2 = h(y)
/// let result = f(temp1, temp2)
/// ```
///
/// ## ⚡ 什么是 KNF？
///
/// **KNF (Kernel Normal Form)** 是 ANF 的一个更严格的变体，也是我们当前阶段要实现的中间表示。
///
/// KNF 在 ANF 的基础上进一步简化：
/// - **更严格的表达式结构**：确保每个表达式都是"原子"的
/// - **统一的控制流**：所有的控制流都通过特定的结构来表达
/// - **简化的类型系统**：类型信息被规范化，便于后续处理
///
/// KNF 的主要优势：
/// - **便于优化**：简化的结构让编译器更容易进行各种优化
/// - **便于代码生成**：接近目标机器的执行模型
/// - **便于分析**：程序的结构更加清晰，便于静态分析
///
/// ## 🎯 我们现在处于什么位置？
///
/// 让我们回顾一下编译器的完整流程：
///
/// ```
/// 源代码 → 词法分析 → 语法分析 → 类型检查 → **KNF变换** → LLVM(SSA) → 机器码
/// ```
///
/// **我们现在正处于 KNF 变换阶段！**
///
/// - ✅ **已完成**：词法分析、语法分析、类型检查
/// - 🔄 **正在进行**：KNF 变换
/// - ⏳ **即将到来**：LLVM 代码生成（SSA 形式）
///
/// ## 🔮 接下来会进入 LLVM (SSA)
///
/// 完成 KNF 变换后，我们将进入 **LLVM 代码生成阶段**。
/// LLVM 使用 **SSA (Static Single Assignment)** 形式作为其核心中间表示：
///
/// - **SSA 特点**：每个变量只被赋值一次，通过 phi 函数处理控制流合并
/// - **LLVM 优势**：成熟的优化框架，支持多种目标架构
/// - **我们的目标**：将 KNF 形式的代码转换为 LLVM IR，最终生成可执行文件
///
/// ## 🎯 你的任务：实现类型变换
///
/// 在这个测试文件中，你需要完成 `type.mbt` 文件中的两个关键函数：
///
/// ### 1. `typekind_to_knf` 函数
///
/// 这个函数负责将类型检查阶段的 `TypeKind` 转换为 KNF 阶段的 `Type`。
/// 你需要处理各种类型：
/// - 基本类型：`Unit`、`Int`、`Bool`、`Double`、`String`
/// - 复合类型：`Array`、`Struct`、`Tuple`、`Function`
/// - 错误处理：对于不支持的类型，抛出 `KnfTransformError`
///
/// ### 2. `type_to_knf` 函数
///
/// 这个函数是 `typekind_to_knf` 的包装器，将完整的 `@typecheck.Type` 对象转换为 KNF 的 `Type`。
///
/// ## 🛠️ 上下文管理
///
/// 与typecheck阶段一样，我们同样需要一个Context结构体来管理上下文，但有所不同的是，Typecheck阶段，
/// 我们把每一个Block看做一个独立的作用域，而在KNF阶段，我们把整个函数体看做一个作用域，
///
/// `context.mbt` 文件中已经定义好了 `Context` 结构体，你需要使用它来管理类型变换过程中的上下文信息。
///
/// ## 🚀 开始你的 KNF 之旅！
///
/// 类型变换是 KNF 变换的基础，只有正确地将类型系统转换到 KNF 形式，
/// 我们才能继续进行表达式和语句的变换。
///
/// **准备好迎接这个激动人心的新阶段了吗？让我们开始吧！**
/// ================================================================================

///|
test "Type Knf Transformation Test" {
  let typecheck_ctx = @typecheck.Context::new()
  let knf_ctx = Context::new()
  let code =
    #|Int Unit Bool Double String Array[Int]
    #|(Int, Double, Bool)
    #|(Int, Int) -> Bool
    #|(Array[Double]) -> String
  // Parse
  let tokens = @lexer.tokenize(code)
  let (t, tok_view) = @parser.parse_type(tokens)
  let t = typecheck_ctx.check_parser_type(t)
  let t = knf_ctx.type_to_knf(t)
  assert_true(t is Int)
  let (t, tok_view) = @parser.parse_type(tok_view)
  let t = typecheck_ctx.check_parser_type(t)
  let t = knf_ctx.type_to_knf(t)
  assert_true(t is Unit)
  let (t, tok_view) = @parser.parse_type(tok_view)
  let t = typecheck_ctx.check_parser_type(t)
  let t = knf_ctx.type_to_knf(t)
  assert_true(t is Bool)
  let (t, tok_view) = @parser.parse_type(tok_view)
  let t = typecheck_ctx.check_parser_type(t)
  let t = knf_ctx.type_to_knf(t)
  assert_true(t is Double)
  let (t, tok_view) = @parser.parse_type(tok_view)
  let t = typecheck_ctx.check_parser_type(t)
  let t = knf_ctx.type_to_knf(t)
  assert_true(t is String)
  let (t, tok_view) = @parser.parse_type(tok_view)
  let t = typecheck_ctx.check_parser_type(t)
  let t = knf_ctx.type_to_knf(t)
  assert_true(t is Array(Int))
  let (t, tok_view) = @parser.parse_type(tok_view)
  let t = typecheck_ctx.check_parser_type(t)
  let t = knf_ctx.type_to_knf(t)
  assert_true(t is Tuple([Int, Double, Bool]))
  let (t, tok_view) = @parser.parse_type(tok_view)
  let t = typecheck_ctx.check_parser_type(t)
  let t = knf_ctx.type_to_knf(t)
  assert_true(t is Function([Int, Int], Bool))
  let (t, _) = @parser.parse_type(tok_view)
  let t = typecheck_ctx.check_parser_type(t)
  let t = knf_ctx.type_to_knf(t)
  assert_true(t is Function([Array(Double)], String))
}
/// ================================================================================
/// # 🔄 While 语句的 KNF 转换
///
/// ## 🎯 什么是 While 语句？
///
/// While 语句是编程语言中的循环控制结构，它允许程序重复执行一段代码，直到某个条件不再满足。
/// While 语句的基本结构是：
/// while (condition) {
///   // 循环体
/// }
///
/// ## 🔍 结构差异分析
///
/// 在语法树中，While 语句的结构相对简单：
/// - `cond`: 条件表达式
/// - `body`: 循环体（BlockExpr）
///
/// 但在 KNF 中，While 语句的结构更加统一：
/// - `KnfStmt::While(cond_block, body_block)`
/// - 条件被包装在一个 `KnfBlock` 中
/// - 循环体也被包装在一个 `KnfBlock` 中
///
/// ## 🛠️ 实现思路
///
/// 实现 `while_stmt_to_knf` 函数需要三个主要步骤：
///
/// ### 1. 条件转换
/// - 使用 `expr_to_knf` 转换条件表达式
/// - 将条件语句包装为 `ExprStmt`
/// - 创建条件块 `KnfBlock`
///
/// ### 2. 循环体转换
/// - 使用 `block_expr_to_knf` 转换循环体
/// - 直接得到 `KnfBlock`
///
/// ### 3. 构造 While 语句
/// - 创建 `KnfStmt::While(cond_block, body_block)`
/// - 返回包含单个 While 语句的数组
///
/// ## 🔧 关键实现细节
///
/// ### 条件块处理
/// 条件表达式可能包含复杂的子表达式，需要先转换为 KNF：
/// while (i < 10) { ... }
/// 转换为：
/// let tmp = 10;
/// while (i < tmp) { ... }
///
/// ### 循环体处理
/// 循环体是一个 `BlockExpr`，直接使用 `block_expr_to_knf` 转换：
/// {
///   sum = sum + i;
///   i = i + 1;
/// }
/// 转换为：
/// {
///   sum = sum + i;
///   let tmp = 1;
///   i = i + tmp;
/// }
///
/// ### 统一结构
/// KNF 中的 While 语句结构统一为：
/// While(cond_block, body_block)
/// 其中：
/// - `cond_block`: 包含条件计算和条件表达式的语句块
/// - `body_block`: 包含循环体语句的语句块
///
/// ## 📝 测试用例解析
///
/// ### 测试用例 1：简单循环
/// while (i < 10) {
///   sum = sum + i;
///   i = i + 1;
/// }
/// 转换过程：
/// 1. 条件 `i < 10` 转换为 `let tmp = 10; i < tmp`
/// 2. 循环体转换为包含赋值和增量操作的语句块
/// 3. 构造 `While(cond_block, body_block)`
///
/// ### 测试用例 2：带函数调用的循环
/// 
/// ```
/// while (x > 0) {
///   print_int(x);
///   x = x - 1;
/// }
/// ```
/// 转换过程：
/// 1. 条件 `x > 0` 转换为 `let tmp = 0; x > tmp`
/// 2. 循环体包含函数调用和递减操作
/// 3. 构造 `While(cond_block, body_block)`
///
/// ## 💡 设计思想
///
/// ### 统一结构
/// 将条件表达式包装在 `KnfBlock` 中，使得 While 语句的结构更加统一和一致。
///
/// ### 条件计算
/// 条件表达式中的复杂计算被提取为独立的语句，确保条件判断的原子性。
///
/// ### 循环体处理
/// 循环体作为 `BlockExpr` 直接转换，保持原有的语句结构。
///
/// ### 简化表示
/// 在 KNF 中简化循环控制流的表示，为后续的优化和代码生成做准备。
///
/// ## 🚀 实现挑战
///
/// ### 条件表达式复杂性
/// 条件表达式可能包含函数调用、复杂运算等，需要正确转换为 KNF 形式。
///
/// ### 循环体语句
/// 循环体中的语句需要正确转换，包括赋值、函数调用等。
///
/// ### 临时变量管理
/// 条件表达式中的临时变量需要正确管理，避免命名冲突。
///
/// ## 🎯 实现目标
///
/// 完成 `while_stmt.mbt` 中的 `while_stmt_to_knf` 函数，实现 While 语句的 KNF 转换。
/// 函数应该：
/// 1. 正确转换条件表达式为条件块
/// 2. 正确转换循环体为语句块
/// 3. 构造统一的 While 语句结构
/// 4. 处理复杂的条件表达式和循环体语句
///
/// 现在让我们开始实现 While 语句的转换吧！🚀
///
/// ================================================================================

///|
test "While Stmt Knf Transformation Test" {
  // Prelude Parts
  let typecheck_ctx = @typecheck.Context::new()
  let knf_ctx = @knf.Context::new()

  // Setup type environment for testing
  typecheck_ctx.type_env.set("i", { kind: Int, mutable: true })
  typecheck_ctx.type_env.set("sum", { kind: Int, mutable: true })
  typecheck_ctx.type_env.set("x", { kind: Int, mutable: true })
  typecheck_ctx.type_env.set("print_int", {
    kind: Function([Int], Unit),
    mutable: false,
  })

  // Setup knf context
  let _ = knf_ctx.add_new_name("i", Int)
  let _ = knf_ctx.add_new_name("sum", Int)
  let _ = knf_ctx.add_new_name("x", Int)
  knf_ctx.globals.set("print_int", Function([Int], Unit))

  // Test 1: Simple while loop: while (i < 10) { sum = sum + i; i = i + 1; }
  let code1 =
    #|while (i < 10) {
    #|  sum = sum + i;
    #|  i = i + 1;
    #|}
  let tokens1 = @lexer.tokenize(code1)
  let (while_stmt1, _) = @parser.parse_while_stmt(tokens1)
  let checked_while_stmt1 = typecheck_ctx.check_while_stmt(while_stmt1)
  let knf_while_stmts1 = knf_ctx.while_stmt_to_knf(checked_while_stmt1)

  // Test 1: Check that we get a While statement
  assert_true(knf_while_stmts1.length() is 1)
  assert_true(knf_while_stmts1[0] is While(_, _))
  guard knf_while_stmts1[0] is While(cond_block, body_block)

  // Test 1: Check condition block (should have let for 10 and the condition expression)
  // Condition block should have: let tmp = 10; and i < tmp;
  assert_true(cond_block.stmts.length() is 2)
  assert_true(
    cond_block.stmts[0] is Let(tmp_name, Int, Int(10)) &&
    tmp_name is { id: "tmp", slot: 0 },
  )
  assert_true(
    cond_block.stmts[1] is ExprStmt(Binary(LT, i_name, tmp_cond)) &&
    i_name is { id: "i", .. } &&
    tmp_cond is { id: "tmp", slot: 0 },
  )

  // Body block should have:
  // 1. sum = sum + i; (no expansion needed, operands are identifiers)
  // 2. let tmp$1 : Int = 1; (extract literal)
  // 3. i = i + tmp$1; (assignment)
  assert_true(body_block.stmts.length() is 3)
  assert_true(
    body_block.stmts[0] is Assign(sum_name, Binary(Add, sum_name2, i_name2)) &&
    sum_name is { id: "sum", .. } &&
    sum_name2 is { id: "sum", .. } &&
    i_name2 is { id: "i", .. },
  )
  assert_true(
    body_block.stmts[1] is Let(tmp_lit, Int, Int(1)) &&
    tmp_lit is { id: "tmp", slot: 1 },
  )
  assert_true(
    body_block.stmts[2] is Assign(i_name3, Binary(Add, i_name4, tmp_add)) &&
    i_name3 is { id: "i", .. } &&
    i_name4 is { id: "i", .. } &&
    tmp_add is { id: "tmp", slot: 1 },
  )

  // Test 2: While with function call: while (x > 0) { print_int(x); x = x - 1; }
  let code2 =
    #|while (x > 0) {
    #|  print_int(x);
    #|  x = x - 1;
    #|}
  let tokens2 = @lexer.tokenize(code2)
  let (while_stmt2, _) = @parser.parse_while_stmt(tokens2)
  let checked_while_stmt2 = typecheck_ctx.check_while_stmt(while_stmt2)
  let knf_while_stmts2 = knf_ctx.while_stmt_to_knf(checked_while_stmt2)
  assert_true(knf_while_stmts2.length() is 1)
  guard knf_while_stmts2[0] is While(cond_block, body_block)

  // Test 2: Check structure
  // Condition block: let tmp = 0; x > tmp;
  assert_true(cond_block.stmts.length() is 2)
  assert_true(
    cond_block.stmts[0] is Let(_, Int, Int(0)) &&
    cond_block.stmts[1] is ExprStmt(Binary(GT, _, _)),
  )

  // Body block: print_int(x); x = x - 1;
  // Similar to test 1: print_int(x); let tmp = 1; x = x - tmp;
  assert_true(body_block.stmts.length() is 3)
  assert_true(body_block.stmts[0] is ExprStmt(Call(_, _)))
  assert_true(body_block.stmts[1] is Let(_, Int, Int(1)))
  assert_true(body_block.stmts[2] is Assign(_, Binary(Sub, _, _)))
}
