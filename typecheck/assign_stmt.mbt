///|
pub(all) struct LeftValue {
  kind : LeftValueKind
  ty : Type
} derive(Show)

///|
pub(all) enum LeftValueKind {
  Ident(String)
  ArrayAccess(LeftValue, Expr)
  FieldAccess(LeftValue, String)
} derive(Show)

///|
pub(all) struct AssignStmt {
  left_value : LeftValue
  op : AssignOp
  expr : Expr
} derive(Show)

///|
pub(all) enum AssignOp {
  Assign // =
  PlusAssign // +=
  MinusAssign // -=
  MultAssign // *=
  DivAssign // /=
  ModAssign // %=
} derive(Show, Eq)

///|
fn AssignOp::from_parser_assign_op(op : @parser.AssignOp) -> AssignOp {
  match op {
    Assign => Assign
    PlusAssign => PlusAssign
    MinusAssign => MinusAssign
    MultAssign => MultAssign
    DivAssign => DivAssign
    ModAssign => ModAssign
  }
}

///|
pub fn Context::check_left_value(
  self : Context,
  left_value : @parser.LeftValue,
) -> LeftValue raise TypeCheckError {
  match left_value.kind {
    Ident(name) => {
      guard self.type_env.get(name) is Some(ty) else {
        raise TypeCheckError("Undefined variable: \{name}")
      }
      LeftValue::{ kind: LeftValueKind::Ident(name), ty }
    }
    ArrayAccess(array_lv, index_expr) => {
      let checked_array_lv = self.check_left_value(array_lv)
      let checked_index_expr = self.check_expr(index_expr)

      // Ensure the array left value is of array type
      match checked_array_lv.ty.kind {
        Array(element_type) => {
          // Ensure the index expression is of integer type
          if !(checked_index_expr.ty is Int) {
            raise TypeCheckError("Array index must be of type Int")
          }
          LeftValue::{
            kind: LeftValueKind::ArrayAccess(
              checked_array_lv, checked_index_expr,
            ),
            ty: Type::{ kind: element_type, mutable: true },
          }
        }
        _ => raise TypeCheckError("Attempted to index a non-array type")
      }
    }
    FieldAccess(struct_lv, field_name) => {
      let checked_struct_lv = self.check_left_value(struct_lv)
      guard checked_struct_lv.ty.kind is Struct(struct_type_name) else {
        raise TypeCheckError("Attempted to access field of a non-struct type")
      }
      guard self.struct_defs.get(struct_type_name) is Some(struct_def) else {
        raise TypeCheckError("Undefined struct type: \{struct_type_name}")
      }
      let ty = for field in struct_def.fields {
        if field.name == field_name {
          break field.ty
        }
      } else {
        raise TypeCheckError(
          "Struct \{struct_type_name} has no field named \{field_name}",
        )
      }
      LeftValue::{
        kind: LeftValueKind::FieldAccess(checked_struct_lv, field_name),
        ty,
      }
    }
  }
}

///|
pub fn Context::check_assign_stmt(
  self : Context,
  assign_stmt : @parser.AssignStmt,
) -> AssignStmt raise TypeCheckError {
  let checked_left_value = self.check_left_value(assign_stmt.left_value)
  guard checked_left_value.ty.mutable is true else {
    raise TypeCheckError("Cannot assign to an immutable left value")
  }
  let checked_expr = self.check_expr(assign_stmt.expr)
  guard self.is_type_compatible(checked_left_value.ty.kind, checked_expr.ty) else {
    raise TypeCheckError(
      "Type mismatch in assignment, left value type: \{checked_left_value.ty.kind}, expression type: \{checked_expr.ty}",
    )
  }
  let op = AssignOp::from_parser_assign_op(assign_stmt.op)
  let ty = self.ensure_type(checked_left_value.ty.kind)
  if !(op is Assign) && !(ty is (Int | Double)) {
    raise TypeCheckError(
      "Compound assignment operators can only be used with Int or Double types",
    )
  }
  AssignStmt::{ left_value: checked_left_value, op, expr: checked_expr }
}
