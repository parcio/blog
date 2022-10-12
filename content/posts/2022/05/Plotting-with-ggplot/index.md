+++
title = "Plotting with ggplot"
date = "2022-05-06"
authors = ["julian.benda"]
tags = ["R", "ggplot", "plotting", "thesis"]
+++

In this post we will give an introduction in `ggplot`, a plotting library in `R`.
Do not turn off just because you can not program `R`, to use `ggplot` no substantial `R` knowledge is required, and that what is is similar to `C` and `Python`.

<!--more-->

<div id="foobar" style="display: none; position: fixed;z-index:9999;top:0;left:0;width:100vw;height:100vh;background-size:contain;background-repeat: no-repeat no-repeat;background-position: center center; background-color:black"
	onclick="this.style.display='none'"></div>

In different to many other plotting solutions like `py-plotlib`, `gnuplot` or even `Matlab`; `ggplot` offers a layer based approach with sensible defaults. This means that if you put in data tuples with a group identifier a legend will be automatically generated with the identifier as label. If you want to change the appearance you add a naming-layer which specifies the label names. Or you want a scatter plot with a trend? No problem, just add a trend layer to your scatter plot.

In this post we will take a look at the fundamentals of plotting with `ggplot`. Therefore we start with a short introduction how to use R and how to install packages. Followed by the backbone of a line plot.

After this a introduction in the different plot kinds and how to combine them is given. Closed with a different customisation options. At the end a few tricks a need extending libraries are presented to ease your live for example how to zoom in to a plot or creating a interactive plot.

{{< toc >}}

## Introduction in R ##

R is a programming language for data analysis and statistics. It is free, and very widely used by professional statisticians. It is also very popular in certain application areas, including bioinformatics. R is a dynamically typed interpreted language, and is typically used interactively. It has many built-in functions and libraries, and is extensible, allowing users to define their own functions and procedures using R, C or Fortran. It also has a simple object system.[1]

`R` can like python be used in two different modes. Once interactive as REPL, to view data easily or a script written in R can be executed. R-Studio offers a great IDE for using this two modes interleaving and many additional features, see section R-Studio for a small show case. If you preferred a more simple approach you can install the `R` interpreter and write the code in your preferred text editor, handy plugins and a few use case examples can be found in section R-from-the-command-line.

The main data structure used in R are `data.frame`. They are like a single spread sheet organized in columns and rows, where the rows can have different types and can be labeled. The content of each column is thereby represented as a vector. The syntax in R is very similar to C but instead of a `;` a line break is used to end a command like in python. Also important to notice is that `R` supplies two kinds of assignments, once the in scope assignment `=` and the global assignment `<-`. `=` is generally used for assigning named parameters in functions, while `<-` is used if you want to set a global variable.

```R
# creation of a vector of ints
age <- c(23, 41, 32, 58, 26)
# [1] 23 41 32 58 26

# creation of a data farme with the columns "Name" and "Age"
data_frame <- data.frame(
	Name = c("Jon", "Bill", "Maria", "Ben", "Tina"),
	Age = age
)
#    Name Age
# 1   Jon  23
# 2  Bill  41
# 3 Maria  32
# 4   Ben  58
# 5  Tina  26
```
```R
# access column by name
data_frame$Name
# [1] "Jon" "Bill" "Maria" "Ben" "Tina"

# vector index is 1 based
data_frame$Name[1]
# "Jon"
```

Vectors are constructed with the `c([elem,]...)` method, it will auto deduce the type to used for storing all elements, e.g. `c("jon", 3)`  will results in the vector of strings `"jon" "3"`. Like wise data frames are constructed with `data.frame()` function. One way to use this is by passing column name data pairs, like in the example above. Operations such as `<`,`>`,`+`,`*` can be applied between different data types. `age < 40` will for example result in a vector of boolean for the results of the comparison. But if the types wont match the more penalized type is used for comparison, with `data_frame$Name < 40` each name is compared against the string `"30"` and is therefore false, because of alphabetic ordering.

```R
age < 40
# [1] TRUE FALSE TRUE FALSE TRUE
```
```R
data_frame$Name < 40
# [1] FALSE FALSE FALSE FALSE FALSE
```
```R
data_frame < 40
#       Name   Age
# [1,] FALSE  TRUE
# [2,] FALSE FALSE
# [3,] FALSE  TRUE
# [4,] FALSE FALSE
# [5,] FALSE  TRUE
```

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

The next step will be a short advices to setup your R environment for usage with the [command line tools](#r-from-the-command-line) or with an [IDE (RStudio)](#r-with-r-studio)

### R from the command line ###

The pros of using `R` directly from the command line with your favorite text editor is that you do not need to families you with yet another editor
and that the initial setup time is very small, and you can gradually advance your setup as needed. In this section we will give tips for setting up `R` and
list some `R` integration extension for common text editors. 

{{<detail-tag "**read section**">}}
#### Installation and Package installation ####

The first step is to install `R`, this can be done via the package manager of your trust or via the CRAN. CRAN is the content system of `R` providing the
newest stable versions of libraries and also `R` itself. For a list of mirrors please visit <https://cran.rstudio.com/mirrors.html> and select a fitting for you.
In further we will annotate it as `https://cran.your.selection`. The download of the current `R` binaries can be done via this mirror, just open it in your web-browser.
You can also use in your R-session the function `choosCRANmirror()` to set the default CRAN for that session via a GUI dialog.

{{<detail-tag "List of Some Mirrors">}}
**Germany**

* https://mirror.dogado.de/cran/ dogado GmbH
* https://ftp.gwdg.de/pub/misc/cran/ GWDG Göttingen
* https://cran.uni-muenster.de/ University of Münster, Germany 

**USA**
* https://repo.miserver.it.umich.edu/cran/ MBNI, University of Michigan, Ann Arbor, MI
* http://cran.wustl.edu/ Washington University, St. Louis, MO
* https://archive.linux.duke.edu/cran/ Duke University, Durham, NC
{{</detail-tag>}}

To install packages you can then use `install.packages(c("pkg1", "pkg2"), repos = "https://cran.your.selection")`. To not type your repos every time you can use once per session `choosCRANmirror()`, or 
use the R-config file `.Rprofile` in your home and add the following code:
```R
local({
	r <- getOptions("repos")
	r["CRAN"] = "https://cran.your.selection"
	options(repos = r)
})
```

You can also use the `.Rprofile` to load a set of libraries you frequently use e.g. `ggplot2`. But conceder that loading a library takes time.
```R
library(httpgd)
library(ggplot2)
```

#### Running Scripts ####

TODO: check for correctness
In difference python you can not run an R-script with `R script.R`, you will use `Rscript script.R` for that. The on reason beside freedom of design are sessions, which are not automatically loaded when using `Rscript` instead of `R`, which is for a scripted execution most time the expected behaviors, to be reproducible.

#### Sessions ####

The `R`-REPL uses Sessions. Which means if you want to exit `R` with CTRL-D or `q()` you get asked if you want to save the workspace. If you answer with yes, a `.Rhistory` and `.RData` file will be created in your current Directory. If you then start `R` again in this directory all your variables assigned, options set and commands executed will be amiable and you can continue were you stop. To store you workspace data use explicit `save.image()` or with optional `save.image(file="evreything.RData")`, you can also store and load specific R objects you can use the functions `save(obj1, obj2,file="objects.RData")` and `load("objects.RData")` to maybe share your data or create a backup. If you find the prompt at the end annoying you can start `R` with `R --no-save` or `R --save` to automatically answer this prompt, and to not have to type this every time you can use the alias system of your shell.

#### Extensions ####

[radian] is a interactive terminal to use `R` with syntax highlighting and autocompletion for multiple options. For interactive usage this can greatly improve the convenience. Radian requires python3 to run and can easily be installed with `pip install -U radian`

[httpgd] is a way to interactive view your plots. After installing the library you can start a server with `hgd()`. Every time you now have a plot, it will be automatically shown at the specified web address. There you can view the history of plots, changing interactive the zoom level and store the final version in a format you like (eg. SVG, PDF, PNG). This can save a lot of time for fiddling with the correct display parameters or for just viewing intermediate plots, it also avoids problems R might have with your image viewer.

If you like code completion in your editor or environment you need to install the `R` library `languageserver`, this will install a LSP in `R` for R, which can be used from a wide variety of code completion extensions.

##### VS-Code #####

Visual studio Code provides a overview about setting it up for `R`[2]. In short it's required the installation of [httpgd], [radian], the R library `languageserver` and [REditorSupport].
This will allow to view plots, and run code from your editor. For that you start a R-Terminal need to be started with <Ctrl+Shift+R>`R: Create R terminal`. To which then the current line or a selection of code can be send with <Ctrl+Enter>. For more details please read the official documentation for [Interaction with R terminals] and the priori referenced sources.

##### NVIM #####

For NVIM and VIM I recommend the plugin Nvim-R, which provides, object viewer, syntax highlighting, documentation viewing and despite its name also works for VIM. In addition [httpgd] works good since it's allows to view the plots easily. The short codes to use Nvim-R can be overwhelming, but you in the end you only need a view of them.
For syntax completion and highlighting my recommandation is to install the R-library `langugaeserver` and use the LSP via the NVIM internal LSP support or for VIM use it via [coc] or similar LSP support plugin. 
{{</detail-tag>}}


### R with R-Studio ###

If you like the working out of the box experience and may want to start using R for more then basic calculations and plotting you, the IDE RStudio might be the solution of your choice. This section is about  

{{<detail-tag "**read more**">}}

#### installation ####

Priori to installing RStudio you must install a recent version of R, this can be done via the package manager of your choice or manually from the [RStudio CRAN][rstudio-cran]. With `R` installed the RStudio installer can be fetched from there [download page][RStudio-Download], just select the matching version for your OS or use again the package manager of your trust. Then you are ready go.

> Note: If you using sway you propaly need to set `QT_QPA_PLATFORM=xcb`

#### setup ####

##### install packages

RStudio provides a list of all installed packages, at the bottom right in the `Packages` tab ([img](#carousel__slide1)).
Checked packages are available in the R-Repl and for Scripts executed in RStudio without explicit loading.
If you want to install new packages you can do this by click on `Install` in the `Package` tab ([img](#carousel__slide2)). The then opend Dialog you can type the packages you want to install (with auto completion) and may select a CRAN ([img](#carousel__slide3)).

##### set working directory #####

To effictive use the tools in RStudio you should set the working directory accordinly.
Do this under `Session->Set Working Directory->Choos Directory...` or `Ctrl+Shift+H` ([img](#carousel__slide4)).

<link rel="stylesheet" type="text/css" href="/css/carousel.css">
<section class="carousel" aria-label="Gallery">
  <ol class="carousel__viewport">
		{{% carousel id="1" prev="3" next="2" %}}
{{< figures show="foobar" src="./rstudio/installtab.png" caption="List of installed and loaded packages can be found in the `Package` tab." >}}
		{{% /carousel %}}
		{{% carousel id="2" prev="1" next="3" %}}
{{< figures show="foobar" src="./rstudio/update_install.png" caption="Use the buttons `Install` to install new packages and `update` to update installed once." >}}
		{{% /carousel %}}
		{{% carousel id="3" prev="2" next="4" %}}
{{< figures show="foobar" src="./rstudio/install_popup.png" caption="Write the packages you want to install." >}}
		{{% /carousel %}}
		{{% carousel id="4" prev="3" next="1" %}}
{{< figures show="fooblr" src="./rstudio/setworkingdir.png" caption="Set thi working directory to easly access all relevant data." >}}
		{{% /carousel %}}
  </ol>
  <aside class="carousel__navigation">
<ol class="carousel__navigation-list">
{{< goto id="1" >}}
{{< goto id="2" >}}
{{< goto id="3" >}}
{{< goto id="4" >}}
</ol>
  </aside>
</section>


* basic usage 
	* where is the REPL
	* reexecute script
	* script stop points

{{</detail-tag>}}

### factors vs numeric ###

* R differentiate data between
	* factors (discreet values like labels)
	* continues (continues eg numbers)
* for each of them the representation in plots and as grouping label
  is different
* most times R detects correctly, but for example if you group your data with
  numbers you must tell R explicit that the Row is a factor
  `data$row = as.factor(data$row)`


## ggplot ##

ggplot is a plotting library written in R. It adopts a R orientation on  data frames/tables and data flow instead of command flow. In addition it provides sensible defaults. Therefore most commands have many optional parameters, which behaves in sensible manners if let empty. This is also reflected in the construction of plots.
You don not draw individual points, you compose your plot out of layers, each layer therefore representing a kind of geometry, or modification at the axis, legend or theme.

First the general structure of a ggplot plotting sicript will be shown, followed by examples to layer based consrtuction of plots. After this basics set, the realisation of different plot types as there geometry to construct them is listed, followed by customizing the plot, e.g. changing colors, and legend descriptions. 

### Hello World ###

```
library("ggplot2")
# if used interactive from console
# library("httpgd")
# hgd()


data <- load.csv("timetable.csv")

plot <- ggplot(data = data, aes(x = time, y = station, group = train)) + geom_line()

# show image in gui extension(if in repl) or RStduio
plot

# store as pdf/png/jpg (and more) depending on the file extension(suffix)
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
[2]:https://code.visualstudio.com/docs/languages/r
[Interaction with R terminals]:https://github.com/REditorSupport/vscode-R/wiki/Interacting-with-R-terminals
http://r-statistics.co/Complete-Ggplot2-Tutorial-Part1-With-R-Code.html
https://cran.r-project.org/doc/manuals/r-release/R-admin.html
[radian]:https://github.com/randy3k/radian
[httpgd]:https://github.com/nx10/httpgd
[REditorSupport]:https://marketplace.visualstudio.com/items?itemName=REditorSupport.r
[Nvim-R]:https://github.com/jalvesaq/Nvim-R
[coc]:https://github.com/neoclide/coc.nvim
[RStduio-Download]:https://www.rstudio.com/products/rstudio/download/#download
[rstudio-rcan]:https://cran.rstudio.com/
