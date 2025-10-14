test "LeftValue Parsing Test" {
  let code = 
    #|obj.field1[0] ;
    #|matrix[1][2] ;
    #|arr[3][5].field

  let tokens = @lexer.tokenize(code)
  let (a, tok_view) = parse_left_value(tokens[:])
  assert_true(
    a.kind is ArrayAccess(array_access, index_expr) &&
    index_expr.kind is ApplyExpr(index_app) &&
    index_app.kind is AtomExpr(index_atom) &&
    index_atom.kind is Int(0) &&
    array_access.kind is FieldAccess(field_access, field_name) &&
    field_name is "field1" &&
    field_access.kind is Ident("obj")
  )
  let (a, tok_view) = parse_left_value(tok_view[1:])
  assert_true(
    a.kind is ArrayAccess(array_access2, index_expr2) &&
    index_expr2.kind is ApplyExpr(index_app2) &&
    index_app2.kind is AtomExpr(index_atom2) &&
    index_atom2.kind is Int(2) &&
    array_access2.kind is ArrayAccess(array_access1, index_expr1) &&
    index_expr1.kind is ApplyExpr(index_app1) &&
    index_app1.kind is AtomExpr(index_atom1) &&
    index_atom1.kind is Int(1) &&
    array_access1.kind is Ident("matrix")
  )
  let (a, _) = parse_left_value(tok_view[1:])
  assert_true(
    a.kind is FieldAccess(field_access2, field_name2) &&
    field_name2 is "field" &&
    field_access2.kind is ArrayAccess(array_access3, index_expr3) &&
    index_expr3.kind is ApplyExpr(index_app3) &&
    index_app3.kind is AtomExpr(index_atom3) &&
    index_atom3.kind is Int(5) &&
    array_access3.kind is ArrayAccess(array_access4, index_expr4) &&
    index_expr4.kind is ApplyExpr(index_app4) &&
    index_app4.kind is AtomExpr(index_atom4) &&
    index_atom4.kind is Int(3) &&
    array_access4.kind is Ident("arr")
  )
}

