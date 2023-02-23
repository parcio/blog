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
The latency of your main memory couldn't even be halfed since 1993.

To encounter that problem cashes were developed and now you have multiple cashes in your PC,
one faster and close to your CPU than the others.

Sadly, cashe memory is expensive and not as compact as your main memory.
Hence, your cashe can only contain a very limited amount of data. 
Every time your CPU has to get information from your main memory you waste a whole lotta time loading that data into your registers and cashes.

Just a small comparison
- Main memory -> needs about 100ns to load your data
- lvl3 cashe -> about 10ns, thats already just a tenth
- lvl2 cashe -> about 5ns
- lvl1 cashe -> about 1ns

As using your memory efficiently and hence, using your cashes effectively will grant you a great performance-boost.