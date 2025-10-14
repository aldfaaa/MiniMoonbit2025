pub(all) struct ApplyExpr {
  kind : ApplyExprKind
} derive(Show, Eq)

///|
pub(all) enum ApplyExprKind {
  AtomExpr(AtomExpr)
  ArrayAccess(ApplyExpr, Expr)
  FieldAccess(ApplyExpr, String)
  TupleAccess(ApplyExpr, Int)
  Call(ApplyExpr, Array[Expr])
} derive(Show, Eq)

pub fn parse_apply_expr(
  tokens : ArrayView[Token],
) -> (ApplyExpr, ArrayView[Token]) raise ParseError {
  let (atom_expr, tokens) = parse_atom_expr(tokens)
  let apply_expr = ApplyExpr::{
    kind: ApplyExprKind::AtomExpr(atom_expr),
  }
  (apply_expr, tokens)
  //if !(tokens is [{ kind: Bracket('[') | Symbol(".") | Bracket('(') }, ..]) {
  //  return (apply_expr, tokens)
  //}
  //let mut apply_expr = apply_expr
  //loop tokens {
  //  [{ kind: Bracket('['), .. }, .. tokens] => {
  //    let (index_expr, tokens) = self.parse_expr(tokens)
  //    guard tokens is [{ kind: Bracket(']'), lineno, column }, .. tokens] else {
  //      raise ParseError((tokens[0], "Expect ']'"))
  //    }
  //    apply_expr = ApplyExpr::{
  //      kind: ApplyExprKind::ArrayAccess(apply_expr, index_expr),
  //    }
  //    continue tokens
  //  }
  //  [{ kind: Dot, .. }, { kind: Lower(field), lineno, column }, .. tokens] => {
  //    apply_expr = ApplyExpr::{
  //      kind: ApplyExprKind::FieldAccess(apply_expr, field),
  //    }
  //    continue tokens
  //  }
  //  [{ kind: Dot, .. }, { kind: Int(idx), lineno, column }, .. tokens] => {
  //    apply_expr = ApplyExpr::{
  //      kind: ApplyExprKind::TupleAccess(apply_expr, idx),
  //    }
  //    continue tokens
  //  }
  //  [{ kind: Bracket('('), .. }, .. tokens] => {
  //    let (args, tokens) = self.parse_expr_list(tokens)
  //    guard tokens is [{ kind: Bracket(')'), lineno, column }, .. tokens] else {
  //      raise ParseError((tokens[0], "Expect ')'"))
  //    }
  //    apply_expr = ApplyExpr::{
  //      kind: ApplyExprKind::Call(apply_expr, args),
  //    }
  //    continue tokens
  //  }
  //  tokens => break (apply_expr, tokens)
  //}
}

