+++
title = "Clang/LLVM Overview"
date = "2022-02-26"
authors = ["hannes.winkler"]
tags = ["LLVM", "Clang", "compiler", "C", "optimization"]
[[resources]]
name = "compiler-terminology"
src = "compiler-terminology.png"
title = "Compiler Terminology "
[resources.params]
  credits = "[Ray Toal, Intro to Compilers](https://cs.lmu.edu/~ray/images/staticcompilation.png) (edited) (License: unknown)"
[[resources]]
name = "compilation-example"
src = "compilation-example.png"
title = "Example Compilation (C source code -> x86_64 assembly)"
[[resources]]
name = "clang-llvm-pipeline"
src = "clang-llvm-pipeline.png"
title = "Clang/LLVM pipeline"
[[resources]]
name = "ast"
src = "ast.png"
title = "Clang AST for hello world program"
+++

Compilers are complex programs with complex requirements. The two most widespread C-compilers, GCC and Clang/LLVM, are **10-15 million** lines of code behemoths, designed to produce optimal machine code for whatever arbitrary target the user desires.
In this blog post I'm going to give an overview of how the Clang/LLVM C-Compiler works; from processing the source code to writing native binaries.

<!--more-->

# 1. Introduction

First of all, what is a compiler?

A computer (or CPU, rather) executes binary **machine code**. The human-readable form of machine code is called **assembly code**. However, assembly code is very low-level and very unnatural to write for humans. So we write our programs in higher-level programming languages like *C*, *C++*, *Rust*, ... instead and let a compiler translate that source code into assembly code **or** directly into machine code. GCC for example compiles into assembly code as an intermediate step and then assembles that into machine code. Clang/LLVM can produce machine code directly.

{{< img name="compiler-terminology" lazy=true >}}
{{< img name="compilation-example" lazy=true >}}

There are many more compilers than GCC and Clang, for a wide variety of programming languages.

One can distinguish between two kinds of compilers:
1. **AOT (ahead-of-time) compilers.**  
  These are compilers where all of the source code is compiled to target code before the program is run.
  Basically, every C/C++ compiler is an AOT compiler for example.
2. **JIT (just-in-time) compilers.**  
  JIT compilers compile code even *while* the program is running.  
  Examples: [chromiums javascript engine](https://v8.dev/), [dart](https://dart.dev/overview), [LuaJIT](https://luajit.org/)

At first, this sounds like JIT is a lot slower than AOT compilation but that's not necessarily true. JIT compilers have more information about the machine/CPU they're targetting and can take that into account when compiling. AOT compilers on the other hand mostly produce code for the "lowest common denominator"[^1], if you don't explicitly tell it for what target it should tune the code. So even if you have the very latest Intel 12th gen CPU with the very latest feature set, your compiler will not make use of those features when targetting "just any x64 machine".

Additionally, JIT compilers have more information about the runtime behaviour of the program. For example, if the JIT compilers sees `Oh, this function is only called with an integer argument greater than 128`, it can use that to optimize the function. An AOT compiler can induce some information too, but in most cases that information is just very hard to find out without running the program. [^2]

# 2. Overview of the Clang/LLVM pipeline

{{< img name="clang-llvm-pipeline" lazy=true >}}

As you can see in the above picture, there's roughly 3 phases of compilation:
1. **Frontend**
    - In this step, all the source code is processed and an intermediate representation (IR) is generated.
    - In our case `Clang` is the frontend and `LLVM` is the middle- and backend.
2. **Middle-end (/ optimization)**
    - The middle-end is one of the great features of LLVM. In this phase, the IR is optimized. Most of the optimizations are done here. The cool thing is that LLVM IR is completely universal; all frontends produce IR and all backends consume IR. That way, if you write an optimization pass for the middle end, it'll work for many languages and many backends.
3. **Backend**
    - The backend will now consume the optimized IR and produce machine code, which (after linking) can be executed on the target machine. The backend will also apply some machine specific optimization passes.

I'll now go a bit more into detail about how these 3 parts work.

## 3.1 Lexer

The first thing the frontend does is read the source code character by character and produce so-called **Tokens**.

For example, for the following C source code:
```C
int main(int argc, char **argv) {
    printf("hello, world!\n");
    return 0;
}
```

The list of tokens could look like this:
```
int,
identifier(“main”),
lparen,
int,
identifier(“argc”),
comma,
// and so on ...
```

Additionally, each token will also have its source location (== line, column) associated with it.

In this phase you basically get rid of all whitespace, comments, and transform the source code into something that can more easily be processed to produce the the abstract syntax tree (AST) and following that, the IR.

The lexer only does very simple recognition of the basic syntactical building blocks of the source code. For example, if you forget the terminating `"` of a string, the lexer will complain; but not if you use a wrong type or an undefined symbol.

## 3.2 Parser / Semantic Analyzer

Using the list of tokens from the previous step, we're now constructing a tree. And not just any tree, we're constructing a so-called **abstract syntax tree** (AST).

Basically, we're now recognizing the language structures of the programming language, like definitions, declarations, control flow statements, expressions, etc. 

If you want to view the AST clang generated for some source file, you can do that using `clang -Xclang -ast-dump -fsyntax-only source-file.c`.

{{< img name="ast" lazy=true >}}



[^1]: Not necessarily, there's something called [Function Multiversioning](https://hannes.hauswedell.net/post/2017/12/09/fmv/), but that's not automatic.

[^2]: [Profile guided optimization](https://en.wikipedia.org/wiki/Profile-guided_optimization) might help in that case though.