+++
title = "Memory Optimization"
date = "2023-02-27"
authors = ["janik.teune"]
tags = ["C", "Memory", "Efficiency", "Cashing", "EPEA 2022", "Teaching"]
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

To encounter that problem cashes were developed and now you have multiple of them in your PC,
one faster and closer to your CPU than another.

Problem is, your cashe can only contain a very limited amount of data. 
Every time your CPU has to get information from your main memory, 
you waste a lot of time loading that data into your registers and cashes.

Just a small comparison:
- Main memory --> needs about 100ns to load your data
- lvl3 cashe --> about 10ns, thats already just a tenth
- lvl2 cashe --> about 5ns
- lvl1 cashe --> about 1ns

Using your memory efficiently and hence, using your cashes effectively will grant you a great performance-boost.

## Cashes

Cashe is SRAM - Static Random Access Memory. 
It has multiple advantages to your main memory (which is DRAM - Direct Random Access Memory).
SRAM is much faster in comparison to DRAM and does not need to be recharged. 
(The Data on your DRAM will be lost, if it is not recharged regularly.)
The Problem is that SRAM is much more complex than DRAM. 
While a memory cell of DRAM needs only one transistor, 
Static RAM needs six transistors per memory cell.
Hence, SRAM is more expensive and not as compact as your main memory.

<!DOCTYPE html><html>
<head><style>
img {
  background-color: #FFFFFF;
}
</style></head>
<body>
	<img src="SRAM_Cell_(6_Transistors).svg" height=300px alt="SRAM Cell with 6 Transistors" title="Fig. 1 - SRAM Cell with 6 Transistors" />
	<img src="DRAM_Cell_(1_Transistor).png" height=300px alt="DRAM Cell with 1 Transistor" title="Fig. 2 - DRAM Cell with 1 Transistor" />
</body>
</html>

### Cashe structure

Most PCs have three levels of cashe. 
To avoid von Neumann Bottleneck the first cashe is separated into a Level 1 instruction-cashe and a Level 1 data-cashe.
Each CPU-core has its own Level 1 cashes, hence, cores do not share any memory in the Level 1 cashe.

Next to it is the Level 2 cashe.
It can store more data than the Level 1 cashe, but takes longer to access.
All Cores of one CPU can share memory in the Level 2 cashe, 
but each CPU has its own Level 2 cashe so CPUs cannot use shared memory in the Level 2 cashes.

The same goes for the Level 3 cashe. Cores can share memory there, but CPUs cannot.
The Level 3 cashe is again bigger, but slower than the Level 2 cashe.

If multiple CPUs want to share memory or if the Level 3 cashe is not sufficient,
they need to use the main memory.

<!DOCTYPE html><html>
<head><style>
img {
  background-color: #FFFFFF;
}
</style></head>
<body>
	<img src="CasheStructure.svg" alt="Structure of CPU-cashes" title="Fig. 3 - Structure of CPU-cashes" />
</body>
</html>

### Cashe Access

When a CPU wants to load new data, it looks into the cashes first.
Therefore, it computes a Tag, from the Address of that data.
All data inside the cashe can be found with their Tag.
If the data is not found in any of the cashes, the CPU will load it from the main memory.
Doing so, the CPU will not only load one word at a time.
Instead, it will load one casheline at a time.
A casheline is a line of 8 consecutive words (that means 64 byte). 
The idea is that the Programm might need the surrounding data next, so the CPU can use the cashe for the upcomming tasks.

## Programming efficiently

Knowing how the cashe works, 
we can start thinking about improving the performance of our programs,
by effectively using the cashe.
Therefore, the first step is to decrease the memory that we use,
so more data can fit into the cashes.

### Padding

The first thing that might lead to used memory that we do not actually need is padding.
Padding is necessary because your CPU can only process one word at a time. 
Data has to be aligned on words or else the CPU will spend time on reading multiple words to process a single date.
To ensure that your data is aligned some memory cells will be left out, which is called padding.
 
Look at the images below:  
The left one shows two chars (**a** and **b**) and an integer **c** unaligned, so the CPU needs 2 cycles to read **c**.
 
<!DOCTYPE html><html>
<head><style>
img {
  background-color: #FFFFFF;
}
</style></head>
<body>
	<img src="int_c_two_cycles.png" alt="Unaligned data" title="Fig. 4 - Unaligned data" height=192px/>
	<img src="int_c_one_cycle.png" alt="Aligned data" title="Fig. 5 - Aligned data" height=192px/>
</body>
</html>

### Structure Packing

Padding may be necessary, but can be avoided mostly.
Lets analyze padding further!

Look at the following code:

```C
struct UNORDERED {
	char a; // a char needs 1 byte of memory
	int b; // an int needs 4 byte of memory
	char c;
};

int main() {
	struct UNORDERED s;
	printf("The structs size is %lu byte.", sizeof(s));
}
```

As you may have expected there is a 3 byte padding after `a`.
So we expect the output to be 9 byte.

```cmd
The structs size is 12 byte.
```

The struct needs even more space than we expected! What is going on?

At the end of each struct is another padding to ensure that the next struct will be aligned, as well!
However, we will notice that we can easily get rid of one padding just by changing the order of the elements in this struct.

```C
struct REORDERED {
	int b;
	char a;
	char c;
};

int main() {
	struct REORDERED s;
	printf("The structs size is %lu byte.", sizeof(s));
}
```

As you can see, I moved the integer `b` to the top
and since `a` and `c` are the same size, there will be no padding after `a`.

```cmd
The structs size is 8 byte.
```

Nice! We could already save 4 byte of memory. 

This may not seem like a lot, but imagine this kind of struct is used in an array.
Then we will save 4 byte for each element in this array!

Now, lets look at another example:

```C
struct OUTER {
    struct INNER {
        char *p; // a char* needs 8 byte of memory
        int x;
    } inner;
    char c;
};

int main() {
    struct OUTER outer_and_inner;
    printf("The structs size is %lu byte.", sizeof(outer_and_inner));
}
```

As we discussed earlier, there may be a padding at the end of each struct.
This happens,
even when we know 
that the element after the struct does not need a padding to be aligned.

```cmd
The structs size is 24 byte.
```

In this case we cannot change the order of the elements to save any memory.
But, if it is not important, we can just flatten this struct,
to get rid of the padding at the end of the inner struct.

```C
struct FLATTENED_STRUCT {
    char *p;
    int x;
    char c;
};

int main() {
    struct FLATTENED_STRUCT flattened;
    printf("The structs size is %lu byte.", sizeof(flattened));
}
```

By removing the inner struct and adding its elements to the outer struct we can again save 8 byte of memory!

```cmd
The structs size is 16 byte.
```

Another thing that you may have already noticed is the padding will not always align the data to fit a 8 byte (1 word) pattern.
Instead, the padding will align the data according to the largest element in the struct.
This inludes elements in inner structs as well.

### Array of Structs and Struct of Arrays

AoS and SoA (Array of Structs and Struct of Arrays) are ways to organize your data.
When you implement your functions you should carefully think about the way your data is accessed.
Accessing your data inefficiently can lead to surprising performance differences!

#### Array of Structs

This method is a simple and naive approach that *can* be efficient. 

Imagine you want to implement an array of 3-dimensional points
and a function to access a point from that list.

The naive approach is to implement a struct that represents a single point
and then simply take an array of those structs.

```C
struct point3D {
    float x;
    float y;
    float z;
};

struct point3D points[n];

float get_point_x(int i) {
	return points[i].x;
}
```

If you want to iterate over this list and change every point, then this is a good idea.
However, if you want to iterate over all `x` coordinates for instance, 
then your cashe is not used optimally. 
Every time you access the `x` coordinate of a point, its `y` and `z`.