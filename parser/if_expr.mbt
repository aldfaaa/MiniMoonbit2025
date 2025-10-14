
pub(all) enum Either[L, R] {
  Left(L)
  Right(R)
} derive(Show, Eq)

pub(all) struct IfExpr {
  cond : Expr
  then_block : BlockExpr
  else_block : Either[IfExpr, BlockExpr]?
} derive(Show, Eq)

pub fn parse_if_expr(tokens: ArrayView[Token]) -> (IfExpr, ArrayView[Token]) raise ParseError {
  ignore(tokens)
  ...
}
