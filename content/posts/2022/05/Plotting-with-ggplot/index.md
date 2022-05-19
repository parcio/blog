+++
title = "Plotting with ggplot"
date = "2022-05-06"
authors = ["julian.benda"]
tags = ["R", "ggplot", "plotting", "thesis"]
+++

In this post we will give an introduction in `ggplot`, a plotting library in `R`.
Do not turn off just because you can not program `R`, to use `ggplot` no substantial `R` knowledge is required, and that what is is similar to `C` and `Python`.

<!--more-->

In different to many other plotting solutions like `py-plotlib`, `gnuplot` or even `Matlab`; `ggplot` offers a layer based approach with sensible defaults. This means that if you put in data tuples with a group identifier a legend will be automatically generated with the identifier as label. If you want to change the appearance you add a naming-layer which specifies the label names. Or you want a scatter plot with a trend? No problem, just add a trend layer to your scatter plot.

In this post we will take a look at the fundamentals of plotting with `ggplot`. Therefore we start with a short introduction how to use R and how to install packages. Followed by the backbone of a line plot.

After this a introduction in the different plot kinds and how to combine them is given. Closed with a different customisation options. At the end a few tricks a need extending libraries are presented to ease your live for example how to zoom in to a plot or creating a interactive plot.

## Introduction in R ##

R is a programming language for data analysis and statistics. It is free, and very widely used by professional statisticians. It is also very popular in certain application areas, including bioinformatics. R is a dynamically typed interpreted language, and is typically used interactively. It has many built-in functions and libraries, and is extensible, allowing users to define their own functions and procedures using R, C or Fortran. It also has a simple object system.[1]

`R` can like python be used in two different modes. Once interactive as REPL, to view data easily or a script written in R can be executed. R-Studio offers a great IDE for using this two modes interleaving and many additional features, see section R-Studio for a small show case. If you preferred a more simple approach you can install the `R` interpreter and write the code in your preferred text editor, handy plugins and a few use case examples can be found in section R-from-the-command-line.

The main data structure used in R are `data.frame`. They are like a single spread sheet organized in columns and rows, where the rows can have different types and can be labeled. The content of each column is thereby represented as a vector. The syntax in R is very similar to C but instead of a `;` a line break is used to end a command like in python. 

```R
# creation of a vector of ints
age = c(23, 41, 32, 58, 26)
# [1] 23 41 32 58 26

# creation of a data farme with the columns "Name" and "Age"
data_frame = data.frame(
	Name = c("Jon", "Bill", "Maria", "Ben", "Tina"),
	Age = age
)
#    Name Age
# 1   Jon  23
# 2  Bill  41
# 3 Maria  32
# 4   Ben  58
# 5  Tina  26

# access column by name
data_frame$Name
# [1] "Jon" "Bill" "Maria" "Ben" "Tina"

# vector index is 1 based
data_frame$Name[1]
# "Jon"
```

Vectors are constructed with the `c([elem,]...)` method, it will auto deduce the type to used for storing all elements, eg. `c("jon", 3)`  will results in the vector of strings `"jon" "3"`. Like wise data frames are constructed with `data.frame()` function. One way to use this is by passing column name data pairs, like in the example above.

In any case if you want a more detailed explanation for an function just use `?<function_name>` like `?data.frame` to see the documentation.

{{<detail-tag "Output of `?data.frame`">}}
```
data.frame                package:base                 R Documentation

Data Frames

Description:

     The function ‘data.frame()’ creates data frames, tightly coupled
     collections of variables which share many of the properties of
     matrices and of lists, used as the fundamental data structure by
     most of R's modeling software.

Usage:

     data.frame(..., row.names = NULL, check.rows = FALSE,
                check.names = TRUE, fix.empty.names = TRUE,
                stringsAsFactors = FALSE)
     
Arguments:

     ...: these arguments are of either the form ‘value’ or ‘tag =
          value’.  Component names are created based on the tag (if
          present) or the deparsed argument itself.

row.names: ‘NULL’ or a single integer or character string specifying a
          column to be used as row names, or a character or integer
          vector giving the row names for the data frame.

check.rows: if ‘TRUE’ then the rows are checked for consistency of
          length and names.

check.names: logical.  If ‘TRUE’ then the names of the variables in the
          data frame are checked to ensure that they are syntactically
          valid variable names and are not duplicated.  If necessary
          they are adjusted (by ‘make.names’) so that they are.

fix.empty.names: logical indicating if arguments which are “unnamed”
          (in the sense of not being formally called as ‘someName =
          arg’) get an automatically constructed name or rather name
          ‘""’.  Needs to be set to ‘FALSE’ even when ‘check.names’ is
          false if ‘""’ names should be kept.

stringsAsFactors: logical: should character vectors be converted to
          factors?  The ‘factory-fresh’ default has been ‘TRUE’
          previously but has been changed to ‘FALSE’ for R 4.0.0.

Details:

     A data frame is a list of variables of the same number of rows
     with unique row names, given class ‘"data.frame"’.  If no
     variables are included, the row names determine the number of
     rows.

     The column names should be non-empty, and attempts to use empty
     names will have unsupported results.  Duplicate column names are
     allowed, but you need to use ‘check.names = FALSE’ for
     ‘data.frame’ to generate such a data frame.  However, not all
     operations on data frames will preserve duplicated column names:
     for example matrix-like subsetting will force column names in the
     result to be unique.

     ‘data.frame’ converts each of its arguments to a data frame by
     calling ‘as.data.frame(optional = TRUE)’.  As that is a generic
     function, methods can be written to change the behaviour of
     arguments according to their classes: R comes with many such
     methods.  Character variables passed to ‘data.frame’ are converted
     to factor columns if not protected by ‘I’ and argument
     ‘stringsAsFactors’ is true.  If a list or data frame or matrix is
     passed to ‘data.frame’ it is as if each component or column had
     been passed as a separate argument (except for matrices protected
     by ‘I’).

     Objects passed to ‘data.frame’ should have the same number of
     rows, but atomic vectors (see ‘is.vector’), factors and character
     vectors protected by ‘I’ will be recycled a whole number of times
     if necessary (including as elements of list arguments).

     If row names are not supplied in the call to ‘data.frame’, the row
     names are taken from the first component that has suitable names,
     for example a named vector or a matrix with rownames or a data
     frame.  (If that component is subsequently recycled, the names are
     discarded with a warning.)  If ‘row.names’ was supplied as ‘NULL’
     or no suitable component was found the row names are the integer
     sequence starting at one (and such row names are considered to be
     ‘automatic’, and not preserved by ‘as.matrix’).

     If row names are supplied of length one and the data frame has a
     single row, the ‘row.names’ is taken to specify the row names and
     not a column (by name or number).

     Names are removed from vector inputs not protected by ‘I’.

Value:

     A data frame, a matrix-like structure whose columns may be of
     differing types (numeric, logical, factor and character and so
     on).

     How the names of the data frame are created is complex, and the
     rest of this paragraph is only the basic story.  If the arguments
     are all named and simple objects (not lists, matrices of data
     frames) then the argument names give the column names.  For an
     unnamed simple argument, a deparsed version of the argument is
     used as the name (with an enclosing ‘I(...)’ removed).  For a
     named matrix/list/data frame argument with more than one named
     column, the names of the columns are the name of the argument
     followed by a dot and the column name inside the argument: if the
     argument is unnamed, the argument's column names are used.  For a
     named or unnamed matrix/list/data frame argument that contains a
     single column, the column name in the result is the column name in
     the argument.  Finally, the names are adjusted to be unique and
     syntactically valid unless ‘check.names = FALSE’.

Note:

     In versions of R prior to 2.4.0 ‘row.names’ had to be character:
     to ensure compatibility with such versions of R, supply a
     character vector as the ‘row.names’ argument.

References:

     Chambers, J. M. (1992) _Data for models._ Chapter 3 of
     _Statistical Models in S_ eds J. M. Chambers and T. J. Hastie,
     Wadsworth & Brooks/Cole.

See Also:

     ‘I’, ‘plot.data.frame’, ‘print.data.frame’, ‘row.names’, ‘names’
     (for the column names), ‘[.data.frame’ for subsetting methods and
     ‘I(matrix(..))’ examples; ‘Math.data.frame’ etc, about _Group_
     methods for ‘data.frame’s; ‘read.table’, ‘make.names’, ‘list2DF’
     for creating data frames from lists of variables.

Examples:

     L3 <- LETTERS[1:3]
     char <- sample(L3, 10, replace = TRUE)
     (d <- data.frame(x = 1, y = 1:10, char = char))
     ## The "same" with automatic column names:
     data.frame(1, 1:10, sample(L3, 10, replace = TRUE))
     
     is.data.frame(d)
     
     ## enable automatic conversion of character arguments to factor columns:
     (dd <- data.frame(d, fac = letters[1:10], stringsAsFactors = TRUE))
     rbind(class = sapply(dd, class), mode = sapply(dd, mode))
     
     stopifnot(1:10 == row.names(d))  # {coercion}
     
     (d0  <- d[, FALSE])   # data frame with 0 columns and 10 rows
     (d.0 <- d[FALSE, ])   # <0 rows> data frame  (3 named cols)
     (d00 <- d0[FALSE, ])  # data frame with 0 columns and 0 rows
 ```
{{</detail-tag>}}

### R from the command line ###

* easy to use
* install gui extension
* VSCode and Vim extensions for R

### R with R-Studio ###

* install 
* basic usage 
	* where is the REPL
	* reexecute script
	* script stop points

### factors vs numeric###

* R differentiate data between
	* factors (discreet values like labels)
	* continues (continues eg numbers)
* for each of them the representation in plots and as grouping label
  is different
* most times R detects correctly, but for example if you group your data with
  numbers you must tell R explicit that the Row is a factor
  `data$row = as.factor(data$row)`


## ggplot ##

* install a package in R
* ??

### Hello World ###

```
data = load.csv('---')
plot = ggplot(data = data, aes(x = time, y = speed, group = car)) + geom_line()

# show image in gui extension(if in repl) or R-stduio
plot

# store as pdf/png/jpg (and more) depending on the extension
ggsave(plot, "plot.pdf")
# to print in the right size (usefull for thesis)
ggsave(plot, "plot.pdf", unit="cm", width=8, height=8)
```

### ggplot construction ###

* `ggplot` set the default arguments for all following functions
	* example is equal to `ggplot() + geom_line(data = data, aes(x = time, y = speed, group = car))`
	* handy for eg `ggplot(...) + geom_line() + geom_errorbar()`
* if needed default argements can be overwritten (clima diagram)
	* `ggplot(...) + geom_line() + geom_line(aes(y = temprature)) + geom_`

### Plot kinds ###

* lineplot
* scatterplot
	* trend
	* ribbon
	* just some custom lines
* bar plots
	* histogram
	* with value
	* stacked
	* overlapping
	* side by side

### decoration layers ###

* axis ration
* log or sqroot axis
* custom axis labels
* custom tick labels
* legend position and orientation
* change colors
* change grid

## tricks and enhancing libraries ##

* zoom
* night mode	
* `dplyr` for better data editing	
* compose multiple diagrams with a shared legend

## further readings ##

[1]:http://www.mas.ncl.ac.uk/~ndjw1/teaching/sim/R-intro.html
http://r-statistics.co/Complete-Ggplot2-Tutorial-Part1-With-R-Code.html
