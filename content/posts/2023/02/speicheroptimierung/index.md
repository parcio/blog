+++
title = "Speicheroptimierung"
date = "2023-02-23"
authors = []
tags = []
+++

In this post we will talk about memory optimization.
We will discuss why optimizing memory is important 
and we will see some examples on how to use memory efficiently.

<!--more-->

## Motivation
Using your memory efficiently is obviously a good idea.
However, there is more to it, than most people think.

When you look at how performance has increased in the last couple of years,
you will notice that in opposition to other things, the performance of main memory has barely increased at all.
The latency of your main memory could not even be halfed since 1993.

To encounter that problem cashes were developed and now you have multiple cashes in your PC,
one faster and closer to your CPU than the others.

Sadly, cashe memory is expensive and not as compact as your main memory.
Hence, your cashe can only contain a very limited amount of data. 
Every time your CPU has to get information from your main memory you waste a lot of time loading that data into your registers and cashes.

Just a small comparison
- Main memory -> needs about 100ns to load your data
- lvl3 cashe -> about 10ns, thats already just a tenth
- lvl2 cashe -> about 5ns
- lvl1 cashe -> about 1ns

Using your memory efficiently and hence, using your cashes effectively will grant you a great performance-boost.

## Cashes
Cashes are ...

### Cashe structure
Most PCs have three levels of cashe. 
To avoid von Neumann Bottleneck the first cashe is separated into a Level 1 instruction-cashe and a Level 1 data-cashe.
Each CPU-core has its own Level 1 cashes, hence, they do not share any memory in the Level 1 cashe.

Next to it is the slightly bigger Level 2 cashe.
All Cores of one CPU can use shared memory in the Level 2 cashe, 
but each CPU has its own Level 2 cashe so CPUs cannot use shared memory in the Level 2 cashes.

The same goes for the Level 3 cashe. Cores can share memory there, but CPUs cannot.
The Level 3 cashe is again bigger, but slower than the Level 2 cashe.

If multiple CPUs want to share memory or if the Level 3 cashe is not sufficient,
they need to use the main memory.

[Bilddatei](Bilddatei)

### Cashe Access
When a CPU wants to load new data, it looks into the cashes first.
Therefore, it computes a Tag, from the Address of the data.
All data inside the cashe can be found with this Tag.
If the data is not found in any of the cashes, the CPU will load it from the main memory.
Doing so, the CPU will not only load one word at a time.
Instead, it will load one casheline at a time.
A casheline is the amount of data that fits into the Level 1 cashe (usually 64 byte).
The idea is that hopefully the Programm will need ...