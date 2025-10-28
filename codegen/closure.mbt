///|
pub fn Context::closure_codegen(
  self : Context,
  closure_def : @knf.KnfClosure,
) -> Unit raise {
  let func_value = self.closure_func_codegen(closure_def)
  // Generate closure function
  let captured_vars : Array[(@knf.Name, @knf.Type)] = closure_def.captured_vars.to_array()
  let ptrty = self.llvm_ctx.getPtrTy()
  let zero = self.llvm_ctx.getConstInt32(0)

  // Generate closure struct
  let closure_struct_field_types : Array[&@llvm.Type] = Array::new()
  // first field: function pointer
  closure_struct_field_types.push(ptrty)
  // following fields: captured variables
  for _, captured_var in captured_vars {
    let (_, captured_ty) = captured_var
    let captured_llvm_ty = self.type_codegen_opaque(captured_ty)
    closure_struct_field_types.push(captured_llvm_ty)
  }
  let closure_struct_ty = self.llvm_ctx.getStructType(
    closure_struct_field_types,
  )
  let mbt_malloc = self.get_builtin_function("moonbit_malloc")
  let closure_size = self.llvm_mod
    .getDataLayout()
    .getTypeAllocSize(closure_struct_ty)
  let closure_size = self.llvm_ctx.getConstInt32(closure_size)
  let closure_ptr = self.builder.createCall(mbt_malloc, [closure_size])
  // Register the closure pointer first (for recursive closures)
  self.name_values.set(closure_def.name, closure_ptr)
  // Also register the closure type
  let param_types : Array[@knf.Type] = closure_def.params.map(fn(p) { p.1 })
  let closure_type = @knf.Type::Function(param_types, closure_def.ret_ty)
  self.name_types.set(closure_def.name, closure_type)
  // set function pointer
  let func_ptr_ptr = self.builder.createGEP(closure_ptr, closure_struct_ty, [
    zero, zero,
  ])
  let _ = self.builder.createStore(func_value, func_ptr_ptr)
  // set captured variables
  for i, captured_var in captured_vars {
    let (captured_name, _) = captured_var
    let captured_value = self.get_value_by_name_or_load(captured_name)
    let field_index_val = self.llvm_ctx.getConstInt32(i + 1) // +1 for function pointer
    let captured_ptr = self.builder.createGEP(closure_ptr, closure_struct_ty, [
      zero, field_index_val,
    ])
    let _ = self.builder.createStore(captured_value, captured_ptr)

  }
}

///|
pub fn Context::closure_func_codegen(
  self : Context,
  closure_def : @knf.KnfClosure,
) -> @llvm.Function raise {
  let current_insert_block = self.builder.getInsertBlock()
  let captured_vars : Array[(@knf.Name, @knf.Type)] = closure_def.captured_vars.to_array()
  let zero = self.llvm_ctx.getConstInt32(0)

  // Generate closure function declaration
  let ptrty = self.llvm_ctx.getPtrTy()
  let ret_ty = self.type_codegen_opaque(closure_def.ret_ty)
  let arg_types : Array[&@llvm.Type] = Array::new()
  // first argument: closure environment pointer
  arg_types.push(ptrty)
  // following arguments: closure parameters
  for param in closure_def.params {
    let (_, param_ty) = param
    //let param_llvm_ty = self.type_codegen_opaque(param_ty)
    let param_llvm_ty = match param_ty {
      Unit => (self.llvm_ctx.getPtrTy() : &@llvm.Type) // If parameter is Unit, use pointer type
      _ => self.type_codegen_opaque(param_ty)
    }
    arg_types.push(param_llvm_ty)
  }
  let func_ty = self.llvm_ctx.getFunctionType(ret_ty, arg_types)
  let func_name = closure_def.name.to_string()
  let parent_func_name = self.builder.getInsertFunction().getName().unwrap()
  let func_name = "\{parent_func_name}$\{func_name}"
  let func_value = self.llvm_mod.addFunction(func_ty, func_name)

  // Generate closure struct type
  let closure_struct_ty : Array[&@llvm.Type] = Array::new()
  closure_struct_ty.push(ptrty) // function pointer
  for _, captured_var in captured_vars {
    let (_, captured_ty) = captured_var
    let captured_llvm_ty = self.type_codegen_opaque(captured_ty)
    closure_struct_ty.push(captured_llvm_ty)
  }
  let closure_struct_ty = self.llvm_ctx.getStructType(closure_struct_ty)

  // Generate function body
  let old_name_value = self.name_values
  let old_name_knf_type = self.name_types
  self.name_values = Map::new()
  self.name_types = Map::new()
  let entry_bb = func_value.addBasicBlock(name="entry")
  self.builder.setInsertPoint(entry_bb)
  for i, param in closure_def.params {
    let (param_name, param_type) = param
    let llvm_arg = func_value.getArg(i + 1).unwrap() // +1 for closure environment
    self.name_values.set(param_name, llvm_arg)
    self.name_types.set(param_name, param_type)
  }
  let func_arg0 = func_value.getArg(0).unwrap() // closure environment pointer
  for i, captured_var in captured_vars {
    let (captured_name, captured_ty) = captured_var
    let field_index_val = self.llvm_ctx.getConstInt32(i + 1) // +1 for function pointer
    let captured_ptr = self.builder.createGEP(func_arg0, closure_struct_ty, [
      zero, field_index_val,
    ])
    let captured_value = self.builder.createLoad(
      self.type_codegen_opaque(captured_ty),
      captured_ptr,
    )
    self.name_values.set(captured_name, captured_value)
    self.name_types.set(captured_name, captured_ty)
  }
  let stmts_cnt = closure_def.body.stmts.length()
  if stmts_cnt > 0 {
    for stmt in closure_def.body.stmts[:stmts_cnt - 1] {
      self.stmt_codegen(stmt)
    }
    match closure_def.body.stmts.last().unwrap() {
      ExprStmt(expr) =>
        match self.expr_codegen(expr) {
          Some(ret_val) => {
            let _ = self.builder.createRet(ret_val)

          }
          None =>
            if func_ty.returnType.asTypeEnum() is VoidType(_) {
              let _ = self.builder.createRetVoid()

            }
        }
      Return(expr) => {
        guard self.expr_codegen(expr) is Some(ret_value) else {
          raise CodegenError("Return expression did not produce a value")
        }
        let _ = self.builder.createRet(ret_value)

      }
      ReturnUnit => {
        let _ = self.builder.createRetVoid()

      }
      stmt => {
        self.stmt_codegen(stmt)
        if func_ty.returnType.asTypeEnum() is VoidType(_) {
          let _ = self.builder.createRetVoid()

        }
      }
    }
  } else {
    let _ = self.builder.createRetVoid()

  }

  // Restore old mappings
  self.name_values = old_name_value
  self.name_types = old_name_knf_type
  self.builder.setInsertPoint(current_insert_block)
  func_value
}
