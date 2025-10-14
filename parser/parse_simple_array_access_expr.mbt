test "Simple Array Access Parsing Test" {
  let code = 
    #|arr[42]
    #|matrix[3][4]

  let tokens = @lexer.tokenize(code)
  let (a, tok_view) = parse_apply_expr(tokens[:])
  assert_true(
    a.kind is ApplyExprKind::ArrayAccess(arr_access, index_expr) &&
    index_expr.kind is ApplyExpr(app_index) &&
    app_index.kind is AtomExpr(atom_index) &&
    atom_index.kind is Int(42) &&
    arr_access.kind is ApplyExprKind::AtomExpr(atom_arr) &&
    atom_arr.kind is AtomExprKind::Ident("arr")
  )
  let (a, _) = parse_apply_expr(tok_view)
  assert_true(
    a.kind is ApplyExprKind::ArrayAccess(arr_access2, index_expr2) &&
    index_expr2.kind is ApplyExpr(app_index2) &&
    app_index2.kind is AtomExpr(atom_index2) &&
    atom_index2.kind is Int(4) &&
    arr_access2.kind is ApplyExprKind::ArrayAccess(arr_access1, index_expr1) &&
    index_expr1.kind is ApplyExpr(app_index1) &&
    app_index1.kind is AtomExpr(atom_index1) &&
    atom_index1.kind is Int(3) &&
    arr_access1.kind is ApplyExprKind::AtomExpr(atom_arr) &&
    atom_arr.kind is AtomExprKind::Ident("matrix")
  )
}


