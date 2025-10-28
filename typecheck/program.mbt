///|
pub(all) suberror TypeCheckError String derive(Show)

///|
pub(all) struct Env {
  local_ : Map[String, Type]
  parent : Env?
}

///|
pub fn Env::new(parent? : Env? = None) -> Env {
  Env::{ local_: Map::new(), parent }
}

///|
pub fn Env::get(self : Env, name : String) -> Type? {
  match self.local_.get(name) {
    Some(t) => Some(t)
    None =>
      match self.parent {
        Some(p) => p.get(name)
        None => None
      }
  }
}

///|
pub fn Env::set(self : Env, name : String, t : Type) -> Unit {
  self.local_.set(name, t)
}

///|
pub(all) struct Context {
  mut type_env : Env
  type_vars : Map[Int, TypeKind]
  struct_defs : Map[String, StructDef]
  func_types : Map[String, TypeKind]
  mut current_func_ret_ty : TypeKind?
}

///|
pub fn Context::new() -> Context {
  let ctx = Context::{
    type_env: Env::new(),
    type_vars: Map::new(),
    struct_defs: Map::new(),
    func_types: Map::new(),
    current_func_ret_ty: None,
  }
  ctx.type_env.set("print_int", Type::{
    kind: Function([Int], Unit),
    mutable: false,
  })
  ctx.type_env.set("print_bool", Type::{
    kind: Function([Bool], Unit),
    mutable: false,
  })
  ctx.type_env.set("print_string", Type::{
    kind: Function([String], Unit),
    mutable: false,
  })
  ctx.type_env.set("sin", Type::{
    kind: Function([Double], Double),
    mutable: false,
  })
  ctx.type_env.set("cos", Type::{
    kind: Function([Double], Double),
    mutable: false,
  })
  ctx.type_env.set("sqrt", Type::{
    kind: Function([Double], Double),
    mutable: false,
  })
  ctx.type_env.set("atan", Type::{
    kind: Function([Double], Double),
    mutable: false,
  })
  ctx.type_env.set("float_of_int", Type::{
    kind: Function([Int], Double),
    mutable: false,
  })
  ctx.type_env.set("int_of_float", Type::{
    kind: Function([Double], Int),
    mutable: false,
  })
  ctx.type_env.set("abs_float", Type::{
    kind: Function([Double], Double),
    mutable: false,
  })
  ctx.type_env.set("print_endline", Type::{
    kind: Function([], Unit),
    mutable: false,
  })
  ctx.type_env.set("truncate", Type::{
    kind: Function([Double], Int),
    mutable: false,
  })
  ctx.func_types.set("print_int", Function([Int], Unit))
  ctx.func_types.set("print_bool", Function([Bool], Unit))
  ctx.func_types.set("print_string", Function([String], Unit))
  ctx.func_types.set("sin", Function([Double], Double))
  ctx.func_types.set("cos", Function([Double], Double))
  ctx.func_types.set("sqrt", Function([Double], Double))
  ctx.func_types.set("atan", Function([Double], Double))
  ctx.func_types.set("float_of_int", Function([Int], Double))
  ctx.func_types.set("int_of_float", Function([Double], Int))
  ctx.func_types.set("abs_float", Function([Double], Double))
  ctx.func_types.set("print_endline", Function([], Unit))
  ctx.func_types.set("truncate", Function([Double], Int))
  ctx
}

///|
pub fn Context::lookup_type(self : Context, name : String) -> Type? {
  match self.type_env.get(name) {
    None => None
    Some({ kind, mutable }) => {
      let t = self.ensure_type(kind) catch { _ => return None }
      let t = Type::{ kind: t, mutable }
      self.type_env.set(name, t)
      Some(t)
    }
  }
}

///|
pub fn Context::enter_scope(self : Self) -> Unit {
  let sub_env = Env::new(parent=Some(self.type_env))
  self.type_env = sub_env
}

///|
pub fn Context::exit_scope(self : Context) -> Unit {
  self.type_env = match self.type_env.parent {
    Some(p) => p
    None => self.type_env
  }
}

///|
pub fn Context::set_current_func_ret_ty(self : Context, ty : TypeKind) -> Unit {
  self.current_func_ret_ty = Some(ty)
}

///|
pub fn Context::add_type_var(self : Context) -> TypeKind {
  let new_id = self.type_vars.length()
  self.type_vars.set(new_id, TypeVar(new_id))
  TypeVar(new_id)
}

///|
pub(all) struct Program {
  top_lets : Map[String, TopLet]
  top_functions : Map[String, TopFunction]
  struct_defs : Map[String, StructDef]
} derive(Show)

///|
pub fn Context::check_program(
  self : Context,
  program : @parser.Program,
) -> Program raise TypeCheckError {
  self.collect_struct_names(program)
  self.collect_function_types(program)
  let struct_defs = Map::new()
  let top_lets = Map::new()
  let top_functions = Map::new()
  for name, struct_def in program.struct_defs {
    let check_struct_def = self.check_struct_def(struct_def)
    struct_defs.set(name, check_struct_def)
  }
  for name, top_let in program.top_lets {
    let checked_top_let = self.check_top_let(top_let)
    top_lets.set(name, checked_top_let)
  }
  for name, top_func in program.top_functions {
    let checked_top_func = self.check_top_function(top_func)
    top_functions.set(name, checked_top_func)
  }
  Program::{ top_lets, top_functions, struct_defs }
}

///|
pub fn Context::collect_struct_names(
  self : Context,
  program : @parser.Program,
) -> Unit raise TypeCheckError {
  for struct_def in program.struct_defs.values() {
    if self.struct_defs.contains(struct_def.name) {
      raise TypeCheckError("Duplicate struct name: \{struct_def.name}")
    } else {
      let struct_def = StructDef::{
        name: struct_def.name,
        fields: Array::new(),
      }
      self.struct_defs.set(struct_def.name, struct_def)
    }
  }
}

///|
pub fn Context::collect_function_types(
  self : Context,
  program : @parser.Program,
) -> Unit raise TypeCheckError {
  for func in program.top_functions.values() {
    if self.func_types.contains(func.fname) {
      raise TypeCheckError("Duplicate function name: \{func.fname}")
    } else {
      let param_types = Array::new()
      for param in func.param_list {
        let { ty, .. } = param
        let ty = self.check_parser_type(ty)
        param_types.push(ty.kind)
      }
      let ret_ty = self.check_parser_type(func.ret_ty)
      let fty = Function(param_types, ret_ty.kind)
      self.func_types.set(func.fname, fty)
      self.type_env.set(func.fname, Type::{ kind: fty, mutable: false })
    }
  }
}
