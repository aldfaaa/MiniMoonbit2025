test "Simple Field Access Parsing Test" {
  let code = 
    #|obj.field
    #|obj.nested.field

  let tokens = @lexer.tokenize(code)
  let (a, tok_view) = parse_apply_expr(tokens[:])
  assert_true(
    a.kind is ApplyExprKind::FieldAccess(obj_access, field) &&
    field == "field" &&
    obj_access.kind is ApplyExprKind::AtomExpr(atom_obj) &&
    atom_obj.kind is AtomExprKind::Ident("obj")
  )
  let (a, _) = parse_apply_expr(tok_view)
  assert_true(
    a.kind is ApplyExprKind::FieldAccess(nested_access, field2) &&
    field2 == "field" &&
    nested_access.kind is ApplyExprKind::FieldAccess(obj_access2, field1) &&
    field1 == "nested" &&
    obj_access2.kind is ApplyExprKind::AtomExpr(atom_obj2) &&
    atom_obj2.kind is AtomExprKind::Ident("obj")
  )
}

