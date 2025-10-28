///|
pub(all) struct LocalFunction {
  fname : String
  param_list : Array[(String, Type)]
  ret_ty : Type
  body : BlockExpr
} derive(Show)

///|
pub fn Context::check_local_function(
  self : Context,
  func : @parser.LocalFunction,
) -> LocalFunction raise TypeCheckError {
  let param_types = Array::new()
  for param in func.param_list {
    let (_, param_type) = param
    let param_ty = match param_type {
      Some(ty) => self.check_parser_typekind(ty.kind)
      None => self.add_type_var()
    }
    param_types.push(param_ty)
  }
  let ret_ty = match func.ret_ty {
    Some(ty) => {
      let ty = self.check_parser_type(ty)
      ty.kind
    }
    None => {
      let kind = self.add_type_var()
      kind
    }
  }
  let parent_func_ret_ty = self.current_func_ret_ty
  self.set_current_func_ret_ty(ret_ty)
  let fty = Function(param_types, ret_ty)
  let fty = Type::{ kind: fty, mutable: false }
  self.type_env.set(func.fname, fty)
  self.enter_scope()
  let param_list = Array::new()
  for i, param in func.param_list {
    let (param_name, _) = param
    let param_ty = Type::{ kind: param_types[i], mutable: false }
    self.type_env.set(param_name, param_ty)
    param_list.push((param_name, param_ty))
  }
  let checked_block = self.check_block_expr(func.body)
  if !self.is_type_compatible(checked_block.ty, ret_ty) {
    raise TypeCheckError(
      "Body and Return Type: Type mismatch in local function \{func.fname}",
    )
  }
  self.exit_scope()
  let ret_ty = self.ensure_type(ret_ty)
  let local_func = LocalFunction::{
    fname: func.fname,
    param_list,
    ret_ty: { kind: ret_ty, mutable: false },
    body: checked_block,
  }
  self.current_func_ret_ty = parent_func_ret_ty
  local_func
}
