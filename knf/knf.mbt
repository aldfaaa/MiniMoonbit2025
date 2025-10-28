///|
pub(all) struct KnfProgram {
  struct_defs : Map[String, KnfStructDef]
  global_stmts : Array[KnfStmt]
  top_lets : Map[String, KnfTopLet]
  functions : Map[String, KnfFunction]
}

///|
pub impl Show for KnfProgram with output(self, logger) {
  for _, struct_def in self.struct_defs {
    logger.write_object(struct_def)
    logger.write_char('\n')
  }
  for s in self.global_stmts {
    logger.write_object(s)
    logger.write_char('\n')
  }
  for _, top_let in self.top_lets {
    logger.write_object(top_let)
    logger.write_char('\n')
  }
  for _, func in self.functions {
    logger.write_object(func)
    logger.write_char('\n')
  }
}

///|
pub fn Context::program_to_knf(
  self : Context,
  prog : @typecheck.Program,
) -> KnfProgram raise KnfTransformError {
  let struct_defs = Map::new()
  let top_lets = Map::new()
  let functions = Map::new()

  // First, register all struct definitions
  for sname, struct_def in prog.struct_defs {
    let knf_struct_def = self.struct_def_to_knf(struct_def)
    struct_defs.set(sname, knf_struct_def)
  }

  // Second, register all function signatures in globals
  // so that top_let expressions can reference them
  for fname, func in prog.top_functions {
    let param_types = func.param_list.map(fn(p) { self.typekind_to_knf(p.ty) })
    let ret_ty = self.typekind_to_knf(func.ret_ty)
    self.globals.set(fname, Function(param_types, ret_ty))
  }

  // Third, process top-level let declarations
  for let_name, top_let in prog.top_lets {
    let knf_top_let = self.top_let_to_knf(top_let)
    top_lets.set(let_name, knf_top_let)
  }

  // Finally, process function bodies
  for fname, func in prog.top_functions {
    let knf_func = self.top_function_to_knf(func)
    functions.set(fname, knf_func)
  }
  let global_stmts = self.global_stmts
  KnfProgram::{ struct_defs, top_lets, global_stmts, functions }
}

///|
pub fn knf_transform(
  prog : @typecheck.Program,
) -> KnfProgram raise KnfTransformError {
  let context = Context::new()
  context.globals.set("print_int", Function([Int], Unit))
  context.globals.set("print_bool", Function([Bool], Unit))
  context.globals.set("print_string", Function([Double], Unit))
  context.globals.set("sin", Function([Double], Double))
  context.globals.set("cos", Function([Double], Double))
  context.globals.set("sqrt", Function([Double], Double))
  context.globals.set("atan", Function([Double], Double))
  context.globals.set("float_of_int", Function([Int], Double))
  context.globals.set("int_of_float", Function([Double], Int))
  context.globals.set("abs_float", Function([Double], Double))
  context.globals.set("print_endline", Function([], Unit))
  context.globals.set("truncate", Function([Double], Int))
  context.program_to_knf(prog)
}
