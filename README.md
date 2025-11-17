# Kaida-Aemthyst/MiniMoonbit

MiniMoonbit 是一个 MoonBit 语言子集的编译器，将 MoonBit 源代码编译到 LLVM IR。

可以编译成llvm IR, aarch64汇编和riscv64汇编。

例子放在examples目录下

## Usage

1. `moon run main -- {file}.mbt` （默认输出llvm IR，无需安装llvm 工具链）

2. `moon run main -- {file}.mbt --emit-llvm` （输出llvm IR）

3. `moon run main -- {file}.mbt --target=aarch64` （输出aarch64汇编）

4. `moon run main -- {file}.mbt --target=riscv64` （输出riscv64汇编）

## 编译运行

无论何种target，都需要注意与runtime.c链接。

## 其它选项

1. `--print-tokens`: 打印词法分析的结果。
2. `--print-ast`: 打印词法分析的结果。
3. `--print-typed-ast`: 打印类型标记的结果。
4. `--print-knf`： 打印knf转换后的结果。

## Example

运行`moon run main -- examples/fib.mbt`:

```llvm
;; ModuleID = 'demo'
;; Source File = "demo"

declare void @print_int(i32)

define i32 @fib(i32 %0) {
entry:
  %1 = icmp sle i32 %0, 1
  br i1 %1, label %3, label %5

3:                                     ; preds = %entry
  ret i32 %0

5:                                     ; preds = %entry
  br label %7

7:                                     ; preds = %5
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

运行`moon run main -- examples/fib.mbt --print-ast`

```plaintext
extern function: print_int
├-params:
│ └-x: Int
└-ffi: "print_int"

Top function: fib
├-params:
│ └-n: Int
├-return: Int
└-block
  ├-if expression
  │ ├-cond: binary expr: <=
  │ │       ├-variable n
  │ │       └-int literal 1
  │ └-then: block
  │         └-return statement
  │           └-variable n
  │         
  └-binary expr: +
    ├-function call
    │ ├-variable fib
    │ └-binary expr: -
    │   ├-variable n
    │   └-int literal 1
    └-function call
      ├-variable fib
      └-binary expr: -
        ├-variable n
        └-int literal 2
  
Top function: main
├-return: Unit
└-block
  ├-let statement
  │ ├-pattern: ident pattern result
  │ └-expr: function call
  │         ├-variable fib
  │         └-int literal 10
  └-function call
    ├-variable print_int
    └-variable result
```

运行`moon run main -- examples/fib.mbt --print-typed-ast`

```plaintext
extern function: print_int
├-params:
│ └-x: Int
├-return: Unit
└-ffi: "print_int"

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
  
Top function: main
├-return: Unit
└-block (Unit)
  ├-let statement
  │ ├-pattern: ident pattern result
  │ ├-type: : Int
  │ └-expr: function call (Int)
  │         ├-variable fib ((Int) -> Int)
  │         └-int literal 10 (Int)
  └-function call (Unit)
    ├-variable print_int ((Int) -> Unit)
    └-variable result (Int)
```


运行`moon run main -- examples/fib.mbt --print-knf`

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
