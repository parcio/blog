+++
title = "Performance of conditional operator vs. fabs"
date = "2021-09-21T11:37:39+02:00"
authors = ["michael.kuhn"]
tags = ["Efficiency"]
+++

Today, we will take a look at potential performance problems when using the conditional operator `?:`.
Specifically, we will use it to calculate a variable's absolute value and compare its performance with that of the function `fabs`.

<!--more-->

Assume the following numerical code written in C, where we need to calculate the absolute value of a `double` variable called `residuum`.[^code]
Since we want to perform this operation within the inner loop, we will have to keep performance overhead as low as possible.
To reduce dependencies on math libraries and avoid function call overhead, we manually get the absolute value by first checking whether `residuum` is less than `0` and, if it is, negating it using the `-` operator.

```c {linenos=true,hl_lines=[7]}
for (int i = 0; i < 1000; i++)
{
	for (int j = 0; j < 1000; j++)
	{
		for (int k = 0; k < 1000; k++)
		{
			residuum = (residuum < 0) ? -residuum : residuum;
		}
	}
}
```

This looks easy enough and, in theory, should provide satisfactory performance.
Just to be sure, let's do the same using the `fabs` function from the math library, which returns the absolute value of a floating-point number.

```c {linenos=true,hl_lines=[7]}
for (int i = 0; i < 1000; i++)
{
	for (int j = 0; j < 1000; j++)
	{
		for (int k = 0; k < 1000; k++)
		{
			residuum = fabs(residuum);
		}
	}
}
```

Let's compare the two implementations using [hyperfine](https://github.com/sharkdp/hyperfine).[^hyperfine]

```plain {linenos=true,hl_lines=[11]}
Benchmark #1: ./conditional
  Time (mean ± σ):     476.3 ms ±   0.4 ms    [User: 474.5 ms, System: 0.7 ms]
  Range (min … max):   475.6 ms … 476.8 ms    10 runs

Benchmark #2: ./fabs
  Time (mean ± σ):     243.8 ms ±   2.0 ms    [User: 242.2 ms, System: 0.8 ms]
  Range (min … max):   242.1 ms … 249.0 ms    12 runs

Summary
  './fabs' ran
    1.95 ± 0.02 times faster than './conditional'
```

As we can see, the `fabs` implementation ran faster by more than a factor of 1.9!
Where does this massive performance difference come from?
Let's use `perf stat` to analyze the two implementations in a bit more detail.

```plain {linenos=true,hl_lines=[7,10]}
Performance counter stats for './conditional':

           478,51 msec task-clock:u              #    0,998 CPUs utilized
                0      context-switches:u        #    0,000 /sec
                0      cpu-migrations:u          #    0,000 /sec
               55      page-faults:u             #  114,940 /sec
    2.035.211.626      cycles:u                  #    4,253 GHz                      (83,28%)
        1.592.587      stalled-cycles-frontend:u #    0,08% frontend cycles idle     (83,28%)
          223.899      stalled-cycles-backend:u  #    0,01% backend cycles idle      (83,28%)
    4.009.332.175      instructions:u            #    1,97  insn per cycle
                                                 #    0,00  stalled cycles per insn  (83,32%)
    2.001.712.079      branches:u                #    4,183 G/sec                    (83,49%)
        1.503.325      branch-misses:u           #    0,08% of all branches          (83,34%)

      0,479296441 seconds time elapsed

      0,474423000 seconds user
      0,001996000 seconds sys
```

The most important metrics here are the number of instructions and the number of cycles.
Our processor can run around 4,250,000,000 cycles per second, resulting in a runtime of 0.48 seconds to process the roughly 4,000,000,000 instructions at 1.97 instructions per cycle.

```plain {linenos=true,hl_lines=[7,10]}
Performance counter stats for './fabs':

           245,48 msec task-clock:u              #    0,997 CPUs utilized
                0      context-switches:u        #    0,000 /sec
                0      cpu-migrations:u          #    0,000 /sec
               51      page-faults:u             #  207,757 /sec
    1.039.265.407      cycles:u                  #    4,234 GHz                      (83,31%)
        1.720.716      stalled-cycles-frontend:u #    0,17% frontend cycles idle     (83,30%)
          356.067      stalled-cycles-backend:u  #    0,03% backend cycles idle      (83,30%)
    3.007.112.338      instructions:u            #    2,89  insn per cycle
                                                 #    0,00  stalled cycles per insn  (83,29%)
    1.003.303.373      branches:u                #    4,087 G/sec                    (83,46%)
        1.662.984      branch-misses:u           #    0,17% of all branches          (83,34%)

      0,246272015 seconds time elapsed

      0,243024000 seconds user
      0,000977000 seconds sys
```

The reduction from 2,000,000,000 to 1,000,000,000 cycles corresponds to the performance improvement of 1.95.
Using the `fabs` function reduced the number of instructions by roughly 25% and, at the same time, increased the number of instructions per cycle to 2.89 (a factor of 1.47).
Getting rid of the conditional operator reduced the number of branches by half, allowing the processor to process more instructions per cycle.
The conditional operator is more or less a short-hand version of the `if` statement and introduced a significant number of branches into our inner loop.

Running three nested loops with 1,000 iterations each resulted in 1,000,000,000 inner loop iterations, that is, we saved one instruction per inner loop iteration.
These branch and instruction differences can be checked in even more detail using `objdump -S`; this is left as an exercise for the reader.

The magnitude of these performance differences is rather surprising and shows that it makes sense to check even seemingly simple code for potential performance problems.

[^code]: The code shown is only an excerpt, the full code is available [here](/code/2021/09/conditional-vs-fabs.c). It was compiled with GCC 11.2 using the `-O2 -Wall -Wextra -Wpedantic` flags and the `-lm` library.
[^hyperfine]: hyperfine performs a statistical performance analysis. It runs the provided commands multiple times to reduce the influence of random errors and calculates derived metrics such as the mean and standard deviation.
