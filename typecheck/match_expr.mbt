///|
pub struct MatchExpr {
  cond : Expr
  arms : Array[MatchArm]
  ty : TypeKind
}

///|
pub impl Show for MatchExpr with output(self, logger) {
  let s = self.to_string(color=true)
  logger.write_string(s)
}

///|
pub fn MatchExpr::to_string(self : Self, color? : Bool = true) -> String {
  let prefix = "match expression"
  let prefix = if color { @color.taint(prefix, Magenta) } else { prefix }
  let ty_str = self.ty.to_string()
  let ty_str = if color { @color.taint(ty_str, Green) } else { ty_str }
  let prefix_with_type = "\{prefix} (\{ty_str})"

  // Format condition
  let cond_str = self.cond.to_string(color~)
  let cond_lines = cond_str
    .split("\n")
    .map(fn(sv) { sv.to_string() })
    .to_array()
  let cond_formatted = @parser.format_lines(
    cond_lines,
    head_with="├-cond: ",
    continue_with="│       ",
  )
  let mut result = "\{prefix_with_type}\n\{cond_formatted}"

  // Format arms
  for i = 0; i < self.arms.length(); i = i + 1 {
    let arm = self.arms[i]
    let arm_str = arm.to_string(color~)
    let arm_lines = arm_str
      .split("\n")
      .map(fn(sv) { sv.to_string() })
      .to_array()
    let is_last = i == self.arms.length() - 1
    let arm_formatted = if is_last {
      @parser.format_lines(arm_lines, head_with="└-", continue_with="  ")
    } else {
      @parser.format_lines(arm_lines, head_with="├-", continue_with="│ ")
    }
    result = "\{result}\n\{arm_formatted}"
  }
  result
}

///|
pub struct MatchArm {
  pattern : Pattern
  match_guard : Expr?
  body : Expr
}

///|
pub impl Show for MatchArm with output(self, logger) {
  let s = self.to_string(color=true)
  logger.write_string(s)
}

///|
pub fn MatchArm::to_string(self : Self, color? : Bool = true) -> String {
  let prefix = "match arm"
  let prefix = if color { @color.taint(prefix, Magenta) } else { prefix }

  // Format pattern
  let pattern_str = self.pattern.to_string(color~)
  let pattern_lines = pattern_str
    .split("\n")
    .map(fn(sv) { sv.to_string() })
    .to_array()
  match self.match_guard {
    None => {
      let pattern_formatted = @parser.format_lines(
        pattern_lines,
        head_with="├-pattern: ",
        continue_with="│          ",
      )
      let body_str = self.body.to_string(color~)
      let body_lines = body_str
        .split("\n")
        .map(fn(sv) { sv.to_string() })
        .to_array()
      let body_formatted = @parser.format_lines(
        body_lines,
        head_with="└-body: ",
        continue_with="        ",
      )
      "\{prefix}\n\{pattern_formatted}\n\{body_formatted}"
    }
    Some(guard_expr) => {
      let pattern_formatted = @parser.format_lines(
        pattern_lines,
        head_with="├-pattern: ",
        continue_with="│          ",
      )
      let guard_str = guard_expr.to_string(color~)
      let guard_lines = guard_str
        .split("\n")
        .map(fn(sv) { sv.to_string() })
        .to_array()
      let guard_formatted = @parser.format_lines(
        guard_lines,
        head_with="├-guard: ",
        continue_with="│        ",
      )
      let body_str = self.body.to_string(color~)
      let body_lines = body_str
        .split("\n")
        .map(fn(sv) { sv.to_string() })
        .to_array()
      let body_formatted = @parser.format_lines(
        body_lines,
        head_with="└-body: ",
        continue_with="        ",
      )
      "\{prefix}\n\{pattern_formatted}\n\{guard_formatted}\n\{body_formatted}"
    }
  }
}

///|
pub fn Context::check_match_expr(
  self : Context,
  match_expr : @parser.MatchExpr,
) -> MatchExpr {
  let checked_cond = self.check_expr(match_expr.cond)
  let checked_cond_ty = self.ensure_type(checked_cond.ty)
  if checked_cond_ty is TypeVar(_) {
    self.throw_(
      match_expr.cond.toks[0],
      "Cannot match on expression with unresolved type variable",
      Error,
    )
  }
  let checked_arms : Array[MatchArm] = Array::new()
  for arm in match_expr.arms {
    let pattern = try self.from_parser_pattern(arm.pattern) catch {
      err => {
        self.throw_(
          arm.toks[0],
          "Failed to parse pattern in match arm: \{err}",
          Error,
        )
        Pattern::{ kind: Wildcard }
      }
    } noraise {
      pat => pat
    }
    self.bind_pattern_type(pattern, checked_cond.ty) catch {
      err =>
        self.throw_(
          arm.toks[0],
          "Pattern type binding error in match arm: \{err}",
          Error,
        )
    }
    let checked_guard = match arm.match_guard {
      Some(guard_expr) => {
        let guard_ty = self.check_expr(guard_expr)
        let guard_ty_ty = self.ensure_type(guard_ty.ty)
        if !(guard_ty_ty is Bool) {
          self.throw_(
            guard_expr.toks[0],
            "Match arm guard expression must be of type `Bool`",
            Error,
          )
          None
        } else {
          Some(guard_ty)
        }
      }
      None => None
    }
    let checked_body = self.check_expr(arm.body)
    let checked_arm = MatchArm::{
      pattern,
      match_guard: checked_guard,
      body: checked_body,
    }
    checked_arms.push(checked_arm)
  }
  let tykind = if checked_arms.length() == 0 {
    TypeKind::Unit
  } else {
    let arm_types = checked_arms.map(a => a.body.ty)
    for i, arm_ty in arm_types {
      if !self.is_type_compatible(arm_types[0], arm_ty) {
        self.throw_(
          match_expr.arms[i].toks[0],
          "Type mismatch between match arms: expected \{arm_types[0]}, got \{arm_ty}",
          Error,
        )
      }
    }
    self.ensure_type(arm_types[0])
  }
  MatchExpr::{ cond: checked_cond, arms: checked_arms, ty: tykind }
}

///|
test "MatchExpr to_string Test - Simple" {
  let color = false
  let ctx = Context::new()
  ctx.type_env.set("x", { kind: TypeKind::Int, mutable: false })
  let code =
    #|match x { 0 => 1 ; 1 => 2 ; _ => 3 }
  let tokens = @lexer.tokenize(code)

  // Test simple match
  let (parsed, _) = @parser.parse_match_expr(tokens[:])
  let checked = ctx.check_match_expr(parsed)
  inspect(
    checked.to_string(color~),
    content=(
      #|match expression (Int)
      #|├-cond: variable x (Int)
      #|├-match arm
      #|│ ├-pattern: int pattern 0
      #|│ └-body: int literal 1 (Int)
      #|├-match arm
      #|│ ├-pattern: int pattern 1
      #|│ └-body: int literal 2 (Int)
      #|└-match arm
      #|  ├-pattern: _
      #|  └-body: int literal 3 (Int)
    ),
  )
}

///|
test "MatchExpr to_string Test - With Guard" {
  let color = false
  let ctx = Context::new()
  ctx.type_env.set("x", { kind: TypeKind::Int, mutable: false })
  let code =
    #|match x { n if n > 0 => 1 ; _ => 0 }
  let tokens = @lexer.tokenize(code)

  // Test match with guard
  let (parsed, _) = @parser.parse_match_expr(tokens[:])
  let checked = ctx.check_match_expr(parsed)
  inspect(
    checked.to_string(color~),
    content=(
      #|match expression (Int)
      #|├-cond: variable x (Int)
      #|├-match arm
      #|│ ├-pattern: ident pattern n
      #|│ ├-guard: binary expr: > (Bool)
      #|│ │        ├-variable n (Int)
      #|│ │        └-int literal 0 (Int)
      #|│ └-body: int literal 1 (Int)
      #|└-match arm
      #|  ├-pattern: _
      #|  └-body: int literal 0 (Int)
    ),
  )
}

///|
test "MatchExpr to_string Test - Tuple Pattern" {
  let color = false
  let ctx = Context::new()
  ctx.type_env.set("pair", {
    kind: TypeKind::Tuple([TypeKind::Int, TypeKind::Int]),
    mutable: false,
  })
  let code =
    #|match pair { (a, b) => a + b }
  let tokens = @lexer.tokenize(code)

  // Test match with tuple pattern
  let (parsed, _) = @parser.parse_match_expr(tokens[:])
  let checked = ctx.check_match_expr(parsed)
  inspect(
    checked.to_string(color~),
    content=(
      #|match expression (Int)
      #|├-cond: variable pair ((Int, Int))
      #|└-match arm
      #|  ├-pattern: tuple pattern
      #|  │          ├-ident pattern a
      #|  │          └-ident pattern b
      #|  └-body: binary expr: + (Int)
      #|          ├-variable a (Int)
      #|          └-variable b (Int)
    ),
  )
}
