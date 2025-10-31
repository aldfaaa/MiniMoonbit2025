# Kaida-Aemthyst/MiniMoonbit

MiniMoonbit 是一个 MoonBit 语言子集的编译器，将 MoonBit 源代码编译到 LLVM IR。

## 特性

- 支持 MoonBit 语言的核心特性
- 编译到 LLVM IR
- 集成 Boehm GC 进行自动内存管理

## 依赖

### macOS

使用 Homebrew 安装 Boehm GC：

```bash
brew install bdw-gc
```

### Linux

使用包管理器安装：

```bash
# Ubuntu/Debian
sudo apt-get install libgc-dev

# Fedora/RHEL
sudo dnf install gc-devel

# Arch Linux
sudo pacman -S gc
```

## 使用方法

### 编译单个文件

```bash
# 编译 MoonBit 源文件到 LLVM IR
moon run main -- --file examples/hello_world.mbt > hello_world.ll

# 使用 clang 链接 runtime 和 Boehm GC
# macOS:
clang hello_world.ll runtime.c -I/opt/homebrew/opt/bdw-gc/include -L/opt/homebrew/opt/bdw-gc/lib -lgc -lm -o hello_world

# Linux:
clang hello_world.ll runtime.c -lgc -lm -o hello_world

# 运行程序
./hello_world
```

### 运行测试

```bash
# 运行编译器自身的测试
moon test

# 运行所有示例程序的测试
python3 test.py
```

## 内存管理

本编译器使用 Boehm GC（Boehm-Demers-Weiser Garbage Collector）进行自动内存管理：

- **类型**：保守式垃圾回收器
- **优点**：
  - 自动回收不再使用的内存
  - 无需手动管理内存
  - 防止内存泄漏
  - 支持大规模内存分配的程序

- **实现细节**：
  - `moonbit_malloc()` 使用 `GC_MALLOC()` 分配内存
  - `moonbit_realloc()` 使用 `GC_REALLOC()` 重新分配内存
  - 程序启动时自动调用 `GC_INIT()` 初始化 GC

## 项目结构

- `lexer/` - 词法分析器
- `parser/` - 语法分析器
- `typecheck/` - 类型检查器
- `knf/` - K-正则化
- `codegen/` - LLVM IR 代码生成
- `main/` - 编译器入口
- `runtime.c` - 运行时支持（包含 GC 集成）
- `examples/` - 示例程序
- `ans/` - 测试预期输出
- `test.py` - 测试脚本

## 许可证

见 LICENSE 文件
