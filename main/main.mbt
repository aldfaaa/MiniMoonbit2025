///|
fn main {
  let help_info =
    #|Usage: tmbt [options]
    #|
    #|Options:
    #|  -h, --help                                    Show this help message
    #|  -f, --file <file>                             Specify the input TinyMoonbit source file (Must provide)
    #|  -stop-after=lex, --stop-after=lex             Stop after Tokenization
    #|  -stop-after=parse, --stop-after=parse         Stop after parsing
    #|  -stop-after=typecheck --stop-after=typecheck  Stop after type checking
    #|  -stop-after=knf --stop-after=knf              Stop after Knf transformation
  let args = @env.args()
  let legal_args = [
    "-h", "--help", "-f", "--file", "-stop-after=lex", "--stop-after=lex", "-stop-after=parse",
    "--stop-after=parse", "-stop-after=typecheck", "--stop-after=typecheck", "-stop-after=knf",
    "--stop-after=knf",
  ]
  for arg in args[1:] {
    if arg.has_prefix("-") && !legal_args.contains(arg) {
      println("Unknown argument: \{arg}")
      println(help_info)
      return
    }
  }
  if args.contains("-h") || args.contains("--help") {
    println(help_info)
    return
  }
  let fidx = args.search_by(arg => arg is "-f" || arg is "--file")
  let code = match fidx {
    Some(idx) if idx + 1 < args.length() => {
      let filename = args[idx + 1]
      @fs.read_file_to_string(filename) catch {
        _ => {
          println("Error reading file '\{filename}'")
          return
        }
      }
    }
    Some(_) => {
      println("Error: No file specified after -f/--file option.")
      return
    }
    None => {
      println(
        "Error: No input file specified. Use -f or --file to specify the source file.",
      )
      println(help_info)
      return
    }
  }
  let tokens = @lexer.tokenize(code) catch {
    err => {
      println("Lexing Error: \{err}")
      return
    }
  }
  if args.contains("-stop-after=lex") {
    println("Tokens:")
    for token in tokens {
      println(token)
    }
    return
  }
  let prog = @parser.parse(tokens) catch {
    err => {
      println("Parsing Error: \{err}")
      return
    }
  }
  if args.contains("-stop-after=parse") || args.contains("--stop-after=parse") {
    println("Parsed AST:")
    println(prog)
    return
  }
  let checked_prog = @typecheck.typecheck(prog) catch {
    err => {
      println("Type Checking Error: \{err}")
      return
    }
  }
  if args.contains("-stop-after=typecheck") ||
    args.contains("--stop-after=typecheck") {
    println("Type-Checked AST:")
    println(checked_prog)
    return
  }
  let knf = @knf.knf_transform(checked_prog) catch {
    err => {
      println("KNF Transformation Error: \{err}")
      return
    }
  }
  if args.contains("-stop-after=knf") || args.contains("--stop-after=knf") {
    println("KNF Transformed:")
    println(knf)
    return
  }
  let llvm_mod = @codegen.codegen(knf) catch {
    err => {
      println("Code Generation Error: \{err}")
      return
    }
  }
  println(llvm_mod)
}
