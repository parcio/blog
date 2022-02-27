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
[[resources]]
name = "ast-dump"
src = "ast-dump.png"
title = "Clang AST dump for the hello world C program."
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

Basically, we're now recognizing the language structures of the programming language, like definitions, declarations, control flow statements, expressions, type casts, etc. 

{{< img name="ast-dump" lazy=true >}}

The above image shows the AST for the example C program in [3.1](#31-lexer). `<invalid sloc>` means `invalid source location`. The nodes with `<invalid sloc>` are "imaginary", they don't have any corresponding source location and were added by clang after the fact.

In the AST we can clearly recognize the structure of the hello world program above.
- The function declaration `int main(int, char **)` and the names of the two arguments, `argc` & `argv` (`FunctionDecl` & `ParmVarDecl`)
- The compound statement `{ ... }` after (`CompoundStmt`)
- The call to `printf` with some implicit casts (`CallExpr`)
- Finally, the `return 0` (`ReturnStmt`)

#### Ambiguity

The parser has some predefined rules, like `function-declaration = type identifier ( parameter-list ) ...`. Those rules it tries to match against the tokens and that way clang will build the AST. However, in practice it's not that easy. For example: in C there's two ways you can parse `a * b`.
- Either `a` and `b` are variables and that expression is a multiplication. 
- Or, `a` is a type name, and `a * b` is the declaration of a variable `b` with type `a*` (pointer to `a`)

So to be able to parse this correctly, you need to know beforehand if `a` is a type or a variable. In C++ it's even more complicated. There's a saying that "C is hard to parse and C++ is impossible to parse." The C++ grammar is [ambiguous](https://en.wikipedia.org/wiki/Most_vexing_parse), [C++ templates are turing complete](http://port70.net/~nsz/c/c%2B%2B/turing.pdf) and parsing it is [literally undecidable](https://blog.reverberate.org/2013/08/parsing-c-is-literally-undecidable.html). That's why Clang has hand-written parsers for both C and C++.

The parser works very closely together with the **semantic analyzer** (Sema). The sema will do things like inferring types, adding type casts, doing validity checks or throwing warnings. For example, warnings about unused code or infinite self-recursion will be thrown by the sema.

## 3.3 IR Generator

The IR generator will now (surprise!) generate rough, unoptimized **IR** using the *AST* from the previous step.

LLVM IR is a full-fledged language with well-defined semantics. The IR below was generated for the hello world program from Section [3.1](#31-lexer). However, I'd say it's workings are a bit out of scope for this blog post, so I'm not going to go into detail here.

```llvm
@.str = private unnamed_addr constant [15 x i8] c"hello, world!\0A\00", align 1

define dso_local i32 @main(i32 %0, i8** %1) #0 !dbg !8 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i8**, align 8
  store i32 0, i32* %3, align 4
  store i32 %0, i32* %4, align 4
  call void @llvm.dbg.declare(metadata i32* %4, metadata !17, metadata !DIExpression()), !dbg !18
  store i8** %1, i8*** %5, align 8
  call void @llvm.dbg.declare(metadata i8*** %5, metadata !19, metadata !DIExpression()), !dbg !20
  %6 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([15 x i8], [15 x i8]* @.str, i64 0, i64 0)), !dbg !21
  ret i32 0, !dbg !22
}

declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

declare dso_local i32 @printf(i8*, ...) #2

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree nosync nounwind readnone speculatable willreturn }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
```



[^1]: Not necessarily, there's something called [Function Multiversioning](https://hannes.hauswedell.net/post/2017/12/09/fmv/), but that's not automatic.

[^2]: [Profile guided optimization](https://en.wikipedia.org/wiki/Profile-guided_optimization) might help in that case though.