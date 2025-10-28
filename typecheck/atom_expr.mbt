///|
pub(all) struct AtomExpr {
  kind : AtomExprKind
  ty : TypeKind
} derive(Show)

///|
pub(all) enum AtomExprKind {
  Int(Int) // 1, 42, etc
  Double(Double) // 1.0, 3.14, etc
  Bool(Bool) // true | false
  String(String) // "hello", etc
  Ident(String) // var
  Unit // ()
  Paren(Expr) // (expr)
  Tuple(Array[Expr]) // (expr, expr, ...)
  Array(Array[Expr]) // [expr, expr, ...]
  ArrayMake(Expr, Expr) // Array::make(size, init)
  StructConstruct(StructConstructExpr) // StructName::{ field: expr, ... }
} derive(Show)

///|
pub fn Context::check_atom_expr(
  self : Self,
  atom_expr : @parser.AtomExpr,
) -> AtomExpr raise TypeCheckError {
  let (typed_atom_expr_kind, type_kind) = match atom_expr.kind {
    Int(v) => (AtomExprKind::Int(v), TypeKind::Int)
    Double(v) => (Double(v), Double)
    Bool(v) => (Bool(v), Bool)
    String(s) => (String(s), String)
    Unit => (Unit, Unit)
    Ident(name) => {
      let ty = match self.lookup_type(name) {
        Some(ty) => ty
        None => raise TypeCheckError("Undefined identifier: \{name}")
      }
      (Ident(name), ty.kind)
    }
    Paren(expr) => {
      let typed_expr = self.check_expr(expr)
      (Paren(typed_expr), typed_expr.ty)
    }
    Array(exprs) => self.check_array_expr(exprs)
    ArrayMake(size_expr, init_expr) =>
      self.check_array_make_expr(size_expr, init_expr)
    Tuple(exprs) => self.check_tuple_expr(exprs)
    StructConstruct(sc_expr) => self.check_struct_construct_expr(sc_expr)
  }
  AtomExpr::{ kind: typed_atom_expr_kind, ty: type_kind }
}

///|
pub fn Context::check_array_expr(
  self : Self,
  exprs : Array[@parser.Expr],
) -> (AtomExprKind, TypeKind) raise TypeCheckError {
  let exprs = exprs.map(e => self.check_expr(e))
  if exprs.length() == 0 {
    let atom_expr_kind = AtomExprKind::Array([])
    let type_kind = self.add_type_var()
    return (atom_expr_kind, Array(type_kind))
  }
  for expr in exprs {
    if self.is_type_compatible(expr.ty, exprs[0].ty) == false {
      raise TypeCheckError("Array elements must have the same type")
    }
  }
  let atom_expr_kind : AtomExprKind = AtomExprKind::Array(exprs)
  let type_kind = self.ensure_type(exprs[0].ty)
  (atom_expr_kind, Array(type_kind))
}

///|
pub fn Context::check_array_make_expr(
  self : Self,
  size_expr : @parser.Expr,
  init_expr : @parser.Expr,
) -> (AtomExprKind, TypeKind) raise TypeCheckError {
  let typed_size_expr = self.check_expr(size_expr)
  if !(typed_size_expr.ty is Int) {
    raise TypeCheckError("Array size must be of type Int")
  }
  let typed_init_expr = self.check_expr(init_expr)
  let atom_expr_kind = AtomExprKind::ArrayMake(typed_size_expr, typed_init_expr)
  let type_kind = TypeKind::Array(typed_init_expr.ty)
  (atom_expr_kind, type_kind)
}

///|
pub fn Context::check_tuple_expr(
  self : Self,
  exprs : Array[@parser.Expr],
) -> (AtomExprKind, TypeKind) raise TypeCheckError {
  let typed_exprs = exprs.map(e => self.check_expr(e))
  let atom_expr_kind = AtomExprKind::Tuple(typed_exprs)
  let type_kind = TypeKind::Tuple(typed_exprs.map(e => e.ty))
  (atom_expr_kind, type_kind)
}
