///|
pub(all) struct Param {
  name : String
  ty : TypeKind
} derive(Show)

///|
pub(all) struct TopFunction {
  fname : String
  param_list : Array[Param]
  ret_ty : TypeKind
  body : BlockExpr
} derive(Show)

///|
pub fn Context::check_top_function(
  self : Context,
  func : @parser.TopFunction,
) -> TopFunction raise TypeCheckError {
  guard self.func_types.get(func.fname) is Some(Function(param_types, ret_ty)) else {
    raise TypeCheckError("Function not found in environment: \{func.fname}")
  }
  self.enter_scope()
  let param_list = Array::new()
  for i, param in func.param_list {
    let { name, .. } = param
    let param_ty = { kind: param_types[i], mutable: false }
    self.type_env.set(name, param_ty)
    param_list.push(Param::{ name, ty: param_ty.kind })
  }
  self.set_current_func_ret_ty(ret_ty)
  let checked_block = self.check_block_expr(func.body)
  if !self.is_type_compatible(checked_block.ty, ret_ty) {
    raise TypeCheckError(
      "Body and Return Type: Type mismatch in top-level function \{func.fname}",
    )
  }
  self.exit_scope()
  self.current_func_ret_ty = None
  TopFunction::{ fname: func.fname, param_list, ret_ty, body: checked_block }
}
