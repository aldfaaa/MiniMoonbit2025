test "Assign Stmt Parsing Test" {
  let code = 
    #|obj.field1 = 42 ;
    #|matrix[1][2] += 3.14 ;
    #|arr[3][5].field -= arr[0][0] ;
    #|x *= 10 ;
    #|y /= 2 ;
    #|z %= 5 ;

  let tokens = @lexer.tokenize(code)
  let (a, tok_view) = parse_assign_stmt(tokens[:])
  assert_true(
    a.left_value.kind is FieldAccess(field_access, field_name) &&
    field_name is "field1" &&
    field_access.kind is Ident("obj") &&
    a.op is Assign &&
    a.expr.kind is ApplyExpr(expr_app) &&
    expr_app.kind is AtomExpr(expr_atom) &&
    expr_atom.kind is Int(42)
  )
  let (a, tok_view) = parse_assign_stmt(tok_view)
  assert_true(
    a.left_value.kind is ArrayAccess(array_access2, index_expr2) &&
    index_expr2.kind is ApplyExpr(index_app2) &&
    index_app2.kind is AtomExpr(index_atom2) &&
    index_atom2.kind is Int(2) &&
    array_access2.kind is ArrayAccess(array_access1, index_expr1) &&
    index_expr1.kind is ApplyExpr(index_app1) &&
    index_app1.kind is AtomExpr(index_atom1) &&
    index_atom1.kind is Int(1) &&
    array_access1.kind is Ident("matrix") &&
    a.op is PlusAssign &&
    a.expr.kind is ApplyExpr(expr_app2) &&
    expr_app2.kind is AtomExpr(expr_atom2) &&
    expr_atom2.kind is Double(3.14)
  )
  let (a, tok_view) = parse_assign_stmt(tok_view)
  assert_true(
    a.left_value.kind is FieldAccess(field_access2, field_name2) &&
    field_name2 is "field" &&
    field_access2.kind is ArrayAccess(array_access3, index_expr3) &&
    index_expr3.kind is ApplyExpr(index_app3) &&
    index_app3.kind is AtomExpr(index_atom3) &&
    index_atom3.kind is Int(5) &&
    array_access3.kind is ArrayAccess(array_access4, index_expr4) &&
    index_expr4.kind is ApplyExpr(index_app4) &&
    index_app4.kind is AtomExpr(index_atom4) &&
    index_atom4.kind is Int(3) &&
    array_access4.kind is Ident("arr") &&
    a.op is MinusAssign &&
    a.expr.kind is ApplyExpr(expr_app3) &&
    expr_app3.kind is ArrayAccess(expr_array_access, expr_index_expr) &&
    expr_index_expr.kind is ApplyExpr(expr_index_app) &&
    expr_index_app.kind is AtomExpr(expr_index_atom) &&
    expr_index_atom.kind is Int(0) &&
    expr_array_access.kind is ArrayAccess(expr_array_access2, expr_index_expr2) &&
    expr_index_expr2.kind is ApplyExpr(expr_index_app2) &&
    expr_index_app2.kind is AtomExpr(expr_index_atom2) &&
    expr_index_atom2.kind is Int(0) &&
    expr_array_access2.kind is AtomExpr(expr_array_atom) &&
    expr_array_atom.kind is Ident("arr")
  )
  let (a, _) = parse_assign_stmt(tok_view)
  assert_true(
    a.left_value.kind is Ident("x") &&
    a.op is MultAssign &&
    a.expr.kind is ApplyExpr(expr_app4) &&
    expr_app4.kind is AtomExpr(expr_atom4) &&
    expr_atom4.kind is Int(10)
  )
}
