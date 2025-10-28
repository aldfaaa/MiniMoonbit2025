///|
pub(all) struct LetStmt {
  pattern : Pattern
  ty : TypeKind
  expr : Expr
} derive(Show)

///|
pub(all) struct Pattern {
  kind : PatternKind
} derive(Show, Eq)

///|
pub(all) enum PatternKind {
  Wildcard
  Ident(String)
  Tuple(Array[Pattern])
} derive(Show, Eq)

///|
fn Context::from_parser_pattern(
  self : Context,
  pattern : @parser.Pattern,
) -> Pattern raise TypeCheckError {
  match pattern.kind {
    Wildcard => Pattern::{ kind: PatternKind::Wildcard }
    Ident(name) => Pattern::{ kind: PatternKind::Ident(name) }
    Tuple(sub_patterns) => {
      let patterns = sub_patterns.map(p => self.from_parser_pattern(p))
      Pattern::{ kind: PatternKind::Tuple(patterns) }
    }
  }
}

///|
pub fn Context::check_let_stmt(
  self : Context,
  let_stmt : @parser.LetStmt,
) -> LetStmt raise TypeCheckError {
  let checked_expr = self.check_expr(let_stmt.expr)
  let type_kind = checked_expr.ty
  if let_stmt.ty is Some(type_annote) {
    let annoted_type = self.check_parser_typekind(type_annote.kind)
    if !self.is_type_compatible(annoted_type, checked_expr.ty) {
      raise TypeCheckError(
        "Type annotation does not match the expression type, annoted: \{annoted_type}, expr: \{checked_expr.ty}",
      )
    }
  }
  let type_kind = self.ensure_type(type_kind)
  let pattern = self.from_parser_pattern(let_stmt.pattern)
  self.bind_pattern_type(pattern, type_kind)
  LetStmt::{ pattern, ty: type_kind, expr: checked_expr }
}

///|
fn Context::bind_pattern_type(
  self : Context,
  pattern : Pattern,
  ty_kind : TypeKind,
) -> Unit raise TypeCheckError {
  match pattern.kind {
    Wildcard => ()
    Ident(name) =>
      self.type_env.set(name, Type::{ kind: ty_kind, mutable: false })
    Tuple(sub_patterns) => {
      guard ty_kind is Tuple(element_types) else {
        raise TypeCheckError("Pattern is a tuple but type is not a tuple")
      }
      if sub_patterns.length() != element_types.length() {
        raise TypeCheckError(
          "Tuple pattern length does not match tuple type length",
        )
      }
      for i in 0..<sub_patterns.length() {
        self.bind_pattern_type(sub_patterns[i], element_types[i])
      }
    }
  }
}
