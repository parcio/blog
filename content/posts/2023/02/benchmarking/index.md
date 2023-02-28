+++
title = "Benchmarking The World"
date = "2023-02-28"
authors = ["philipp.david"]
tags = ["Efficiency", "EPEA 2022", "Benchmarking"]
+++

Performance analysis is an important part of programming and computer science
in general and it is often done with the goal of increasing performance. To
find out how fast a program is in the first place and then verify whether or
not a change improves performance, benchmarking is used.

In this post, we will explore different types of benchmarking tools and how
they can help you improve the performance of your software. We will cover
microbenchmarking tools, macrobenchmarking tools and whole-system benchmarking
tools.

<!--more-->

## Setup

Before we begin, please note that all sample code shown in this blog post can
be downloaded [here](benchmarking_the_world.tar). If you want to go along with
the commands, you will have to install a working C++17 compiler,
[Meson](https://mesonbuild.com/) and [ninja](https://ninja-build.org/).

## Microbenchmarking Tools

Microbenchmarking is the process of measuring the performance of small code
snippets, usually at the function level. It is essential for identifying
performance issues in critical parts of your codebase. As such, it is often
employed by implementors of programming languages to measure and improve the
performance of standard library functions, such as operations on vectors.

### DIY Microbenchmarks

To illustrate how one would write a microbenchmark manually, let's consider the
following C++ function that calculates the sum of two integers:

```cpp {linenos=true}
int sum(int a, int b) {
  return a + b;
}
```

To benchmark this function, we can measure the time it takes to execute it for
different input values. Here's an example of how we can do that manually:

```cpp {linenos=true}
#include <chrono>
#include <iostream>
#include "sum.hpp"

using namespace std::chrono;

const int iterations = 100000000;

int main() {
  // Benchmark sum(1, 2)
  auto start = steady_clock::now();
  for (int i = 0; i < iterations; i++) {
    sum(1, 2);
  }
  auto end = steady_clock::now();
  auto duration = duration_cast<microseconds>(end - start).count();
  std::cout << "sum(1, 2) took " << duration << " microseconds" << std::endl;

  // Benchmark sum(10, 20)
  start = steady_clock::now();
  for (int i = 0; i < iterations; i++) {
    sum(10, 20);
  }
  end = steady_clock::now();
  duration = duration_cast<microseconds>(end - start).count();
  std::cout << "sum(10, 20) took " << duration << " microseconds" << std::endl;

  return 0;
}
```

This code tries to measure the time it takes to execute the sum function 100
million times for two different input values. To compile it, we can put
everything into a file named [`simple_micro.cpp`](simple_micro.cpp) and use our
build system of choice. For this post, we will be using the Meson build system.
Having created a simple build description file, [`meson.build`](meson.build),
we build the code and then run the executable:

```sh {linenos=true}
% meson setup builddir
% cd builddir
% ninja simple_micro
% ./simple_micro
sum(1, 2) took 0 microseconds
sum(10, 20) took 0 microseconds
```

However, as we can see, the execution time for both function calls is strangely
low. This happens because we forgot to use the results of `sum` and the
compiler is free to optimize away all calls to `sum`. When writing your own
microbenchmarking code from scratch, mistakes such as this one are very easy to
make. Therefore, using a robust, battle-tested microbenchmarking library is
highly recommended.

### Google Benchmark

One such library is [Google Benchmark](https://github.com/google/benchmark). It
provides a simple and reliable way to measure the performance of your code. It
takes care of warm-up, statistical analysis and can prevent excessive compiler
optimizations amongst other factors that can affect the accuracy of the
results.

Here's a simple example of how we can use Google Benchmark to measure the
performance of our sum function:

```cpp {linenos=true}
#include <benchmark/benchmark.h>
#include "sum.hpp"

static void BM_Sum(benchmark::State& state) {
  for (auto _ : state) {
    benchmark::DoNotOptimize(sum(state.range(0), state.range(1)));
  }
  state.SetComplexityN(state.range(0) + state.range(1));
}

BENCHMARK(BM_Sum)->Args({1, 2})->Args({10, 20})->Complexity();

BENCHMARK_MAIN();
```

This code creates a benchmark function `BM_Sum` that takes a benchmark `State`
as an argument, which provides an iterator that is used to run our benchmarks
for an appropriate amount of times. The `state` also contains arguments that
are passed to the benchmark function, which can be accessed using the
`state.range` function. Here, the first two arguments are simply passed onto
`sum`. Looking at the `sum` call again, we can see that it is surrounded by a
call to `DoNotOptimize`, which does exactly what it says: It prevents the
compiler from optimizing out the call to `sum` and it does so without
additional overhead.

We also set the complexity of the benchmark to be proportional to the sum of
the input values, which lets `benchmark` determine the complexity of our
function in Big O notation. For those familiar with this concept, this can be
an enormous help in comparing the performance of algorithms.

Finally, we use the `BENCHMARK` macro to register the `BM_Sum` function with
Google Benchmark and pass two sets of arguments to it: `{1, 2}` and `{10, 20}`.
To execute the benchmark, we use the `BENCHMARK_MAIN` macro to generate the
main function that runs the benchmarks.

Now that we understand what our sample program does, let's try running it.
First of all, we need to ensure that Google Benchmark is installed. Many
operating systems ship it in their package repositories and using
[Repology](https://repology.org/project/benchmark/versions) we can find out the
correct package name to install.

After installing the prerequisites, we navigate to our `builddir` and run
`ninja reconfigure` to detect the installed libraries. After that, we can
finally build and run our benchmark:

```sh {linenos=true}
% ninja google_micro
...
% ./google_micro
2023-02-28T09:34:02+01:00
Running ./google_micro
Run on (4 X 4600 MHz CPU s)
CPU Caches:
  L1 Data 32 KiB (x4)
  L1 Instruction 32 KiB (x4)
  L2 Unified 256 KiB (x4)
  L3 Unified 6144 KiB (x1)
Load Average: 0.46, 0.32, 0.30
***WARNING*** CPU scaling is enabled, the benchmark real time measurements may
be noisy and will incur extra overhead.
-------------------------------------------------------
Benchmark             Time             CPU   Iterations
-------------------------------------------------------
BM_Sum/1/2        0.655 ns        0.654 ns   1000000000
BM_Sum/10/20      0.655 ns        0.654 ns   1000000000
BM_Sum_BigO        0.65 (1)        0.65 (1)  
BM_Sum_RMS            0 %             0 %
```

As we can see, this provides much more information than our DIY implementation
and even warns us that CPU frequency scaling might be causing inconsistent
measurements.

Google Benchmark provides many more features that make it easy to write
accurate and reliable microbenchmarks. This small overview should help you get
started with it relatively quickly.

## Macrobenchmarking Tools

Contrary to microbenchmarking, macrobenchmarking is the process of measuring
the performance of larger code sections, usually at the program level. It is
useful for identifying performance issues that are not related to specific
functions or algorithms, as well as comparing different versions of programs or
even the same versions compiled with different compiler flags.

### POSIX time

One way to perform a macrobenchmark is with the POSIX `time` utility. A very
simple example would be to find out how long `ls` takes to list our directory
contents:

```sh {linenos=true}
% time ls
build.ninja            google_micro.p  meson-private
compile_commands.json  meson-info      monte_carlo.p
google_micro           meson-logs      simple_micro.p

real    0m0.001s
user    0m0.001s
sys     0m0.000s
```

This was a benchmark, just not a very good one. The major problems with using
`time` like this are that the benchmarked program is only run once, making the
result vary with the random error. We also need a more interesting program to
benchmark, since the runtime of `ls` is so low that it becomes hard to
benchmark even with better tools.

Here's a rather simple program we can benchmark that approximates the number Pi
using a [Monte Carlo method](https://en.wikipedia.org/wiki/Monte_Carlo_method):

```cpp {linenos=true}
#include <iostream>
#include <random>

int main() {
  std::random_device rd;
  std::mt19937 gen(rd());
  std::uniform_real_distribution<> dis(-1.0, 1.0);

  const size_t num_points = 10000000;
  size_t num_points_inside_circle = 0;

  for (size_t i = 0; i < num_points; ++i) {
    const double x = dis(gen);
    const double y = dis(gen);
    if (x * x + y * y <= 1.0) {
      ++num_points_inside_circle;
    }
  }

  const double pi = 4.0 * num_points_inside_circle / num_points;
  std::cout << "Pi: " << pi << '\n';

  return 0;
}
```

To build it, we can just issue `ninja monte_carlo` in our `builddir`.

### hyperfine

Now that we have a more interesting program to benchmark, we need a better way
to perform macrobenchmarks. The preferred way to do this is to use a dedicated
tool like [`hyperfine`](https://github.com/sharkdp/hyperfine)[^1]. `hyperfine`
is a command-line benchmarking tool written in Rust that provides a simple and
flexible way to measure the performance of your programs. Compared to `time`,
`hyperfine` actively tries to minimize random errors and will warn about
outliers. There are also many useful formats that `hyperfine` can output, such
as Markdown and raw JSON data.

To get `hyperfine`, once again check if it is provided by your distribution's
repositories at [Repology](https://repology.org/project/hyperfine/versions). If
you have a working Rust installation on your computer, you can also simply
install the latest version with `cargo install hyperfine`.

Here's how we can now benchmark our `monte_carlo` program:

```sh {linenos=true}
% hyperfine ./monte_carlo
Benchmark 1: ./monte_carlo
  Time (mean ± σ):     235.8 ms ±   0.9 ms    [User: 234.0 ms, System: 0.7 ms]
  Range (min … max):   234.5 ms … 237.3 ms    12 runs
```

This is much more helpful than the `time` output! We can clearly see the mean
runtime of our program along with the standard deviation, as well as the
minimum and maximum runtimes. Our program was run a total of 12 times until
`hyperfine` was satisfied with the results. We even saw a nice progress bar
while the benchmark was running!

Although the default settings are already helpful, `hyperfine` provides many
more options that make it easy to customize the benchmarking process. For
example, you can set the number of runs, the warm-up time, and the maximum
execution time of the benchmark. You can also control the environment
variables, the working directory, and the input arguments of the benchmark.

Using these advanced features, we can try to find the best compiler flags for
`monte_carlo`. The relevant flags in this case are `--setup` to build our
program with different flags and `--parameter-list` to specify the different
optimization levels we want to try. Putting it all together, we end up with
something along these lines:

```sh {linenos=true}
% hyperfine \
  --parameter-list opt 2,3,fast \
  --parameter-list march x86-64,native \
  --setup 'meson configure -Dcpp_args="-O{opt} -march={march}" && ninja' \
  --warmup 2 \
  --export-markdown monte_carlo_results.md \
  --command-name 'cpp -O{opt} -march={march}' \
  ./monte_carlo

Benchmark 1: cpp -O2 -march=x86-64
  Time (mean ± σ):     234.6 ms ±   0.0 ms    [User: 233.7 ms, System: 0.7 ms]
  Range (min … max):   234.5 ms … 234.7 ms    12 runs
 
Benchmark 2: cpp -O3 -march=x86-64
  Time (mean ± σ):     235.2 ms ±   1.0 ms    [User: 233.9 ms, System: 0.8 ms]
  Range (min … max):   234.2 ms … 237.4 ms    12 runs
 
Benchmark 3: cpp -Ofast -march=x86-64
  Time (mean ± σ):     230.0 ms ±   0.4 ms    [User: 229.4 ms, System: 0.3 ms]
  Range (min … max):   229.7 ms … 230.9 ms    13 runs
 
Benchmark 4: cpp -O2 -march=native
  Time (mean ± σ):     174.9 ms ±   0.4 ms    [User: 174.1 ms, System: 0.6 ms]
  Range (min … max):   174.2 ms … 175.5 ms    17 runs
 
Benchmark 5: cpp -O3 -march=native
  Time (mean ± σ):     142.1 ms ±   5.4 ms    [User: 140.8 ms, System: 0.7 ms]
  Range (min … max):   139.5 ms … 164.4 ms    20 runs

Benchmark 6: cpp -Ofast -march=native
  Time (mean ± σ):     132.9 ms ±   0.7 ms    [User: 131.9 ms, System: 0.6 ms]
  Range (min … max):   132.0 ms … 134.3 ms    22 runs
 
Summary
  'cpp -Ofast -march=native' ran
    1.07 ± 0.04 times faster than 'cpp -O3 -march=native'
    1.32 ± 0.01 times faster than 'cpp -O2 -march=native'
    1.73 ± 0.01 times faster than 'cpp -Ofast -march=x86-64'
    1.77 ± 0.01 times faster than 'cpp -O2 -march=x86-64'
    1.77 ± 0.01 times faster than 'cpp -O3 -march=x86-64'
```

Looking at the results, it's obvious that a great speedup can be achieved
simply by changing compiler flags, even with a simple program like
`monte_carlo`. Of course, this does not allow general assumptions about these
flags, since they may worsen performance on other machines or for other
programs and as such, benchmarking them would be necessary.

Apart from the command-line output, we also made `hyperfine` generate this nice
Markdown table:

| Command | Mean [ms] | Min [ms] | Max [ms] | Relative |
|:---|---:|---:|---:|---:|
| `cpp -O2 -march=x86-64` | 234.6 ± 0.0 | 234.5 | 234.7 | 1.77 ± 0.01 |
| `cpp -O3 -march=x86-64` | 235.2 ± 1.0 | 234.2 | 237.4 | 1.77 ± 0.01 |
| `cpp -Ofast -march=x86-64` | 230.0 ± 0.4 | 229.7 | 230.9 | 1.73 ± 0.01 |
| `cpp -O2 -march=native` | 174.9 ± 0.4 | 174.2 | 175.5 | 1.32 ± 0.01 |
| `cpp -O3 -march=native` | 142.1 ± 5.4 | 139.5 | 164.4 | 1.07 ± 0.04 |
| `cpp -Ofast -march=native` | 132.9 ± 0.7 | 132.0 | 134.3 | 1.00 |

With this knowledge and the excellent `hyperfine` manpage, you should be able
to tackle even more complex benchmarks with ease.

## Whole-System Benchmarking Tools

Whole-system benchmarking is the process of measuring the performance of your
entire system, including the operating system, the hardware, and the software
stack. Besides comparing different computer systems, it is useful for
identifying performance issues that are related to the system configuration,
such as memory usage, disk I/O, and network latency.

Since we need to run many different benchmarking programs to get a decent
picture of the many aspects of a system's performance, installing and running
these manually quickly becomes both cumber- and tiresome.

One way to deal with this is to use the
[Phoronix Test Suite](https://www.phoronix-test-suite.com/), which is a
cross-platform benchmarking tool written in PHP and which provides a
comprehensive collection of benchmarks and entire test suites. The Phoronix
Test Suite, from now on referred to as `PTS`, automates most of the aspects of
benchmarking a system: From installing dependencies, downloading and compiling
tests to generating and uploading results to
[OpenBenchmarking.org](https://openbenchmarking.org/).

Here's an example of how we can use the `PTS` to run a quick benchmark testing
the `lz4` compression program:

```sh {linenos=true}
% phoronix-test-suite benchmark compress-lz4
...
    Would you like to save these test results (Y/n): y
    Enter a name for the result file: ...
    Enter a unique name to describe this test run / configuration: ...
...
Current Description: ...
New Description: ...
...
    Would you like to upload the results to OpenBenchmarking.org (y/n): y
    Results Uploaded To: ...
```

Since this command will attempt to install missing dependencies using the
system package manager, I suggest running the `PTS` on a live system or inside
a [container](https://hub.docker.com/r/phoronix/pts/tags). Before the benchmark
starts, the `PTS` will ask for common options such as test name and
description. After completion, it will ask whether or not to upload results to
[OpenBenchmarking.org](https://openbenchmarking.org/). All of these questions
can be answered in advance for fully automatic test runs.

We have published the results of a sample test run
[here](https://openbenchmarking.org/result/2302281-NE-20230228P45) and if you
wish to compare your own system to these results, you can use the following
command to run the same tests and attach your results to this run:

```sh {linenos=true}
% phoronix-test-suite benchmark 2302281-NE-20230228P45
```

The `PTS` offers so many more features that covering them all would be
out-of-scope for this blog post, but we still hope that this small introduction
helped you.

## Conclusion

In this blog post, we have explored different tools for benchmarking, including
microbenchmarking tools, macrobenchmarking tools and whole-system benchmarking
tools. We have shown how to write microbenchmarks using Google Benchmark, how
to perform macrobenchmarks using `hyperfine` and find the best compiler flags
for a simple program and how to perform whole-system benchmarks using the
Phoronix Test Suite. We hope that this blog post has been useful for you and
that it has inspired you to improve the performance of your code.

Happy benchmarking!

[^1]: Peter, D. (2022). hyperfine (Version 1.15.0) [Computer software]. https://github.com/sharkdp/hyperfine
