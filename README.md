# MiniMoonbit

[中文](#中文)

**MiniMoonbit** is a subset of the [MoonBit](https://www.moonbitlang.com/) programming language. It serves as a compiler that translates MiniMoonbit source code into multiple targets, including LLVM IR, AArch64 assembly, and RISC-V 64 assembly.

This project leverages the power of the MoonBit ecosystem, particularly:
- **MoonLLVM**: A refactored version of LLVM written entirely in MoonBit, used for generating LLVM IR.
- **MoonMIR**: A tool, also written in MoonBit, that translates the LLVM IR from MoonLLVM into target-specific assembly code.

The compilation pipeline can be visualized as:
`MiniMoonbit Source` -> `MiniMoonbit Compiler` -> `MoonLLVM` -> `LLVM IR` -> `MoonMIR` -> `AArch64 / RISC-V 64 Assembly`

## Features

- **Multi-Target Compilation**: Compiles to LLVM IR, AArch64, and RISC-V 64.
- **Rich Language Subset**: Supports basic arithmetic, control flow, strings, arrays, structs, ADTs, and pattern matching.
- **Developer-Friendly Diagnostics**: Features simple error recovery and exhaustiveness checks for pattern matching to improve the development experience.
- **Introspection Tools**: Provides flags to print intermediate representations like tokens, AST, typed AST, and K-Normal Form (KNF) for debugging and educational purposes.

## Prerequisites

Before using MiniMoonbit, ensure you have the MoonBit toolchain installed.

**Linux/macOS:**
```sh
curl -fsSL https://cli.moonbitlang.cn/install/unix.sh | bash
```

**Windows (PowerShell):**
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser; irm https://cli.moonbitlang.cn/install/powershell.ps1 | iex
```

## Usage

You can run the compiler using the `moon run main` command. Let `{file}.mbt` be your MiniMoonbit source file (see the `/examples` directory for samples).

*   **Show Help Information:**
    ```sh
    # Note: A placeholder argument like 'x' is currently needed due to a bug in the toolchain.
    moon run main -- x --help
    ```

*   **Compile to LLVM IR (Default):**
    ```sh
    moon run main -- {file}.mbt
    # or explicitly
    moon run main -- {file}.mbt --emit-llvm
    ```

*   **Compile to AArch64 Assembly:**
    ```sh
    moon run main -- {file}.mbt --target=aarch64
    ```

*   **Compile to RISC-V 64 Assembly:**
    ```sh
    moon run main -- {file}.mbt --target=riscv64
    ```

**Note:** When compiling the generated output, remember to link it with the provided `runtime.c`.

## Debugging and Introspection

The compiler offers several flags to inspect its internal stages:

- `--print-tokens`: Print the result of lexical analysis.
- `--print-ast`: Print the Abstract Syntax Tree (AST).
- `--print-typed-ast`: Print the AST with type annotations.
- `--print-knf`: Print the K-Normal Form (KNF) representation.

### Example: Compiling Fibonacci

Consider the `examples/fib.mbt` file.

*   **Generate LLVM IR:**
    ```sh
    moon run main -- examples/fib.mbt
    ```
    This produces the following LLVM IR:
    ```llvm
    ;; ModuleID = 'demo'
    ;; Source File = "demo"

    declare void @print_int(i32)

    define i32 @fib(i32 %0) {
    entry:
      %1 = icmp sle i32 %0, 1
      br i1 %1, label %3, label %5

    3:
      ret i32 %0

    5:
      br label %7

    7:
      %8 = sub i32 %0, 1
      %9 = sub i32 %0, 2
      %10 = call i32 @fib(i32 %8)
      %11 = call i32 @fib(i32 %9)
      %12 = add i32 %10, %11
      ret i32 %12
    }

    define void @moonbit_main() {
    entry:
      %0 = call i32 @fib(i32 10)
      call void @print_int(i32 %0)
      ret void
    }
    ```

*   **Print the Typed AST:**
    ```sh
    moon run main -- examples/fib.mbt --print-typed-ast
    ```
    This shows the structured, type-checked representation of the code:
    ```plaintext
    Top function: fib
    ├-params:
    │ └-n: Int
    ├-return: Int
    └-block (Int)
      ├-if expression (Any)
      │ ├-cond: binary expr: <= (Bool)
      │ │       ├-variable n (Int)
      │ │       └-int literal 1 (Int)
      │ └-then: block (Any)
      │         └-return statement
      │           └-variable n (Int)
      │
      └-binary expr: + (Int)
        ├-function call (Int)
        │ ├-variable fib ((Int) -> Int)
        │ └-binary expr: - (Int)
        │   ├-variable n (Int)
        │   └-int literal 1 (Int)
        └-function call (Int)
          ├-variable fib ((Int) -> Int)
          └-binary expr: - (Int)
            ├-variable n (Int)
            └-int literal 2 (Int)
    ```

*   **Print KNF:**
    ```sh
    moon run main -- examples/fib.mbt --print-knf
    ```
    This shows the k normal form:
    ```plaintext
    ;; KnfProgram: examples/fib.mbt

    fn fib(n: Int) -> Int {
      let tmp : Int = 1;
      if n <= tmp {
        return n;
      };
      let tmp$1 : Int = 1;
      let tmp$2 : Int = n - tmp$1;
      let tmp$3 : Int = 2;
      let tmp$4 : Int = n - tmp$3;
      let tmp$5 : Int = fib(tmp$2);
      let tmp$6 : Int = fib(tmp$4);
      tmp$5 + tmp$6;
    }
    fn main {
      let tmp : Int = 10;
      let result : Int = fib(tmp);
      print_int(result);
    }
    ```

*   **Error recovery:**
    MiniMoonBit Compiler supporr error recovery, take `err.mbt` as example:
    ```sh
    moon run main -- err.mbt
    ```
    You will see:
    ```plaintext
    [err.mbt:10:7] Warning:
    9|  let y = x + true;
    10|  let (x) = 5;
    11|      ^ Warning: Should Not use tuple pattern for single pattern

    [err.mbt:8:15] Error:
    7|fn main {
    8|  let mut x = 8 + 1.0;
    9|              ^ TypeMismatch: Binary Expression Must have same type for both side while got Int and Double

    [err.mbt:9:12] Error:
    8|  let mut x = 8 + 1.0;
    9|  let y = x + true;
    10|           ^ TypeMismatch: Binary Expression Must have same type for both side while got Int and Bool

    [err.mbt:14:10] Error:
    13|
    14|  match a {
    15|         ^ Non-exhaustive match expression, some patterns are not covered:
    RGB(_, _, _)
    RGB(255, _, _)
    RGB(255, 0, _)
    RGBA(_, _, _, _)
    RGBA(255, _, _, _)
    ... and 2 more patterns

    [err.mbt:20:9] Error:
    19|
    20|  return false;
    21|        ^ Return type mismatch, wanted: Unit, got: Bool

    Compilation Error: TypeCheckError("Type checking failed.")
    ```
---

<a name="中文"></a>

# MiniMoonbit

[English](#minimoonbit)

**MiniMoonbit** 是 [MoonBit](https://www.moonbitlang.com/) 编程语言的一个子集。它是一个编译器，可将 MiniMoonbit 源代码编译到多个目标，包括 LLVM IR、AArch64 汇编和 RISC-V 64 汇编。

该项目借助了 MoonBit 生态系统的强大能力，特别是：
- **MoonLLVM**: 一个完全使用 MoonBit 重构的 LLVM 版本，用于生成 LLVM IR。
- **MoonMIR**: 一个同样由 MoonBit 编写的工具，用于将 MoonLLVM 生成的 LLVM IR 转译为特定目标的汇编代码。

编译流程可以简要地表示为：
`MiniMoonbit 源码` -> `MiniMoonbit 编译器` -> `MoonLLVM` -> `LLVM IR` -> `MoonMIR` -> `AArch64 / RISC-V 64 汇编`

## 功能特性

- **多目标编译**: 可编译至 LLVM IR、AArch64 和 RISC-V 64。
- **丰富的语言子集**: 支持基本运算、控制流、字符串、数组、结构体、代数数据类型（ADT）和模式匹配。
- **开发者友好的诊断信息**: 具备简单的错误恢复机制和模式匹配的完备性检查，以改善开发体验。
- **内部状态检视工具**: 提供多种标志位，用于打印词法分析、抽象语法树（AST）、类型化抽象语法树和 K范式（KNF）等中间表示，便于调试和学习。
- **功能完备**: 可以编译如光线追踪这样的中型程序。

## 环境准备

在使用 MiniMoonbit 之前，请确保已安装 MoonBit 工具链。

**Linux/macOS:**
```sh
curl -fsSL https://cli.moonbitlang.cn/install/unix.sh | bash
```

**Windows (PowerShell):**
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser; irm https://cli.moonbitlang.cn/install/powershell.ps1 | iex
```

## 如何使用

您可以使用 `moon run main` 命令来运行编译器。假设 `{file}.mbt` 是您的 MiniMoonbit 源文件（可参考 `examples` 目录下的示例）。

*   **显示帮助信息:**
    ```sh
    # 注意：由于当前工具链的一个 bug，需要一个额外的占位符参数，任何参数都可以。
    moon run main -- x --help
    ```

*   **编译到 LLVM IR (默认):**
    ```sh
    moon run main -- {file}.mbt
    # 或显式指定
    moon run main -- {file}.mbt --emit-llvm
    ```

*   **编译到 AArch64 汇编:**
    ```sh
    moon run main -- {file}.mbt --target=aarch64
    ```

*   **编译到 RISC-V 64 汇编:**
    ```sh
    moon run main -- {file}.mbt --target=riscv64
    ```

**注意:** 在编译生成的产物时，请记得链接项目提供的 `runtime.c` 文件。

## 调试与检视

编译器提供了几个标志位来检视其内部各个阶段的状态：

- `--print-tokens`: 打印词法分析的结果。
- `--print-ast`: 打印抽象语法树（AST）。
- `--print-typed-ast`: 打印带类型注解的抽象语法树。
- `--print-knf`: 打印 K范式（KNF）表示。

### 示例：编译斐波那契函数

以 `examples/fib.mbt` 文件为例。

*   **生成 LLVM IR:**
    ```sh
    moon run main -- examples/fib.mbt
    ```
    这将生成以下 LLVM IR:
    ```llvm
    ;; ModuleID = 'demo'
    ;; Source File = "demo"

    declare void @print_int(i32)

    define i32 @fib(i32 %0) {
    entry:
      %1 = icmp sle i32 %0, 1
      br i1 %1, label %3, label %5

    3:
      ret i32 %0

    5:
      br label %7

    7:
      %8 = sub i32 %0, 1
      %9 = sub i32 %0, 2
      %10 = call i32 @fib(i32 %8)
      %11 = call i32 @fib(i32 %9)
      %12 = add i32 %10, %11
      ret i32 %12
    }

    define void @moonbit_main() {
    entry:
      %0 = call i32 @fib(i32 10)
      call void @print_int(i32 %0)
      ret void
    }
    ```

*   **打印类型化抽象语法树:**
    ```sh
    moon run main -- examples/fib.mbt --print-typed-ast
    ```
    这将显示代码的结构化、类型检查后的表示：
    ```plaintext
    Top function: fib
    ├-params:
    │ └-n: Int
    ├-return: Int
    └-block (Int)
      ├-if expression (Any)
      │ ├-cond: binary expr: <= (Bool)
      │ │       ├-variable n (Int)
      │ │       └-int literal 1 (Int)
      │ └-then: block (Any)
      │         └-return statement
      │           └-variable n (Int)
      │
      └-binary expr: + (Int)
        ├-function call (Int)
        │ ├-variable fib ((Int) -> Int)
        │ └-binary expr: - (Int)
        │   ├-variable n (Int)
        │   └-int literal 1 (Int)
        └-function call (Int)
          ├-variable fib ((Int) -> Int)
          └-binary expr: - (Int)
            ├-variable n (Int)
            └-int literal 2 (Int)
    ```

*   **打印KNF:**
    ```sh
    moon run main -- examples/fib.mbt --print-knf
    ```
    这将显示代码的KNF表示：
    ```plaintext
    ;; KnfProgram: examples/fib.mbt

    fn fib(n: Int) -> Int {
      let tmp : Int = 1;
      if n <= tmp {
        return n;
      };
      let tmp$1 : Int = 1;
      let tmp$2 : Int = n - tmp$1;
      let tmp$3 : Int = 2;
      let tmp$4 : Int = n - tmp$3;
      let tmp$5 : Int = fib(tmp$2);
      let tmp$6 : Int = fib(tmp$4);
      tmp$5 + tmp$6;
    }
    fn main {
      let tmp : Int = 10;
      let result : Int = fib(tmp);
      print_int(result);
    }
    ```

*   **错误恢复与处理:**
    MiniMoonBit支持一定的错误处理，当代码存在语法错误时，编译器会试图进行错误恢复，以根目录下的err.mbt为例子。
    ```sh
    moon run main -- err.mbt
    ```
    你将会在终端中看到以下错误信息：
    ```plaintext
    [err.mbt:10:7] Warning:
    9|  let y = x + true;
    10|  let (x) = 5;
    11|      ^ Warning: Should Not use tuple pattern for single pattern

    [err.mbt:8:15] Error:
    7|fn main {
    8|  let mut x = 8 + 1.0;
    9|              ^ TypeMismatch: Binary Expression Must have same type for both side while got Int and Double

    [err.mbt:9:12] Error:
    8|  let mut x = 8 + 1.0;
    9|  let y = x + true;
    10|           ^ TypeMismatch: Binary Expression Must have same type for both side while got Int and Bool

    [err.mbt:14:10] Error:
    13|
    14|  match a {
    15|         ^ Non-exhaustive match expression, some patterns are not covered:
    RGB(_, _, _)
    RGB(255, _, _)
    RGB(255, 0, _)
    RGBA(_, _, _, _)
    RGBA(255, _, _, _)
    ... and 2 more patterns

    [err.mbt:20:9] Error:
    19|
    20|  return false;
    21|        ^ Return type mismatch, wanted: Unit, got: Bool

    Compilation Error: TypeCheckError("Type checking failed.")
    ```
