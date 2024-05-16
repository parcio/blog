+++
title = "Plotting with ggplot"
date = "2022-05-06"
authors = ["julian.benda"]
tags = ["R", "ggplot", "plotting", "thesis"]
+++

In this post we will give introduction to `ggplot`, a plotting library in `R`.
Don't be deterred if you can't program in R; to use ggplot, substantial R knowledge isn't required. The necessary skills are similar to those used in C and Python."


<!--more-->

<div id="foobar" style="display: none; position: fixed;z-index:9999;top:0;left:0;width:100vw;height:100vh;background-size:contain;background-repeat: no-repeat no-repeat;background-position: center center; background-color:black"
	onclick="this.style.display='none'"></div>

Unlike many other plotting solutions like `matplotlib`, `gnuplot` or even `Matlab`; `ggplot` offers a layer based approach with sensible defaults.
This means that when you input data tuples with a group identifier, a legend is automatically generated using the identifier as a label. To change the appearance, you can add a naming layer which specifies the label names. Want a scatter plot with a trend? Simply add a trend layer to your scatter plot.

In this post we will take a look at the fundamentals of plotting with `ggplot`. Therefore, we start with a short introduction how to use R and how to install packages. Followed by the backbone of a line plot.

After this an introduction to the different plot kinds and how to combine them is given. Closed with a different customization options. At the end a few tricks a need extending libraries are presented to ease your life for example how to zoom in to a plot or creating an interactive plot.

{{< toc >}}

## Introduction in R ##

R is a programming language for data analysis and statistics. It is a free and widely by professional statisticians used language. It is also very popular in certain application areas, including bioinformatics. R is a dynamically typed interpreted language, and is typically used interactively. It has many built-in functions and libraries, and is extensible, allowing users to define their own functions and procedures using R, C or FORTRAN. It also has a simple object system.[1]

`R`, like `Python` be used in two different modes. Once interactively as REPL, to view data easily or a script written in R can be executed. R-Studio offers a great IDE for using this two modes interleaving and many additional features, see section R-Studio for a small showcase. If you preferred a more simple approach you can install the `R` interpreter and write the code in your preferred text editor, handy plugins and a few use case examples can be found in section R-from-the-command-line.

The main data structure used in R are `data.frame`. They are like a single spreadsheet organized in columns and rows, where the rows can have different types and can be labeled. The content of each column is thereby represented as a vector. The syntax in R is very similar to C but instead of a `;` a line break is used to end a command like in python. Also, important to notice is that `R` supplies two kinds of assignments, once the in scope assignment `=` and the global assignment `<-`. `=` is generally used for assigning named parameters in functions, while `<-` is used if you want to set a global variable.

```R
# creation of a vector of ints
age <- c(23, 41, 32, 58, 26)
# [1] 23 41 32 58 26

# creation of a data frame with the columns "Name" and "Age"
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

Vectors are constructed with the `c([elem,]...)` method, it will auto deduce the type to used for storing all elements, e.g. `c("jon", 3)` will result in the vector of strings `"jon" "3"`. Likewise, data frames are constructed with `data.frame()` function. One way to use this is providing column name data pairs, like in the example above. Operations such as `<`,`>`,`+`,`*` can be applied between different data types. `age < 40` will for example result in a vector of boolean for the results of the comparison. But if the types won't match the more penalized type is used for comparison, with `data_frame$Name < 40` each name is compared against the string `"30"` and is therefore false, because of alphabetic ordering.


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

If you want a more detailed explanation for a function just use `?<function_name>` like `?data.frame` to see the documentation.

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

Data frames can also be loaded from and written to CSV files with `read.csv` and `write.csv`.
```R
data = read.csv("data.csv")
write.csv(data, filename = "same_data.csv")
```
To store any object from R in a native way you should use `saveRDS(data, file = "data.rds")` and `readRDS(file = "data.rds")`, this allows sharing
RObjects or storing them for later.

The next step will contain short advices to set up your R environment for usage with the [command line tools](#r-from-the-command-line) or with an [IDE (RStudio)](#r-with-r-studio)

### R from the command line ###

The pros of using `R` directly from the command line with your favorite text editor is that you do not need to families you with yet another editor.
Also, the initial setup time is very small, and you can gradually advance your setup as needed. In this section we will give tips for setting up `R` and
list some `R` integration extension for common text editors.

{{<detail-tag "**read section**">}}

#### Installation and Package installation ####

The first step is to install `R`, this can be done via the package manager of your trust or via the CRAN. CRAN is the Comprehensive `R` Archive Network (CRAN) providing the
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

The `.Rprofile` contains code which will be executed each time you start a new instance of R.

You can also use the `.Rprofile` to load a set of libraries you frequently use e.g. `ggplot2`. But consider that loading a library takes time.
```R
library(httpgd)
library(ggplot2)
```

#### Running Scripts ####

Unlike `Python` you can not run an R-script with `R script.R`, you will use `Rscript script.R` for that. The reason for that is the `R` session system. Sessions are automatically loaded when using `R`. Therefore, `Rscript` is used to execute a script in a clean environment for reproducible results of the script.
To create your first plot install `ggplot2` with
```
$ R
> install.packages(c("ggplot2"))
> q()
```
And run `Rscript `[`hello_ggplot.R`][hello_ggplot.R] and you should see a `plot.pdf`.

#### Sessions ####

The `R`-REPL uses Sessions. Which means if you want to exit `R` with CTRL-D or `q()` you get asked if you want to save the workspace. If you answer with yes, a `.Rhistory` and `.RData` file will be created in your current Directory. If you then start `R` again in this directory all your variables assigned, options set and commands executed will be available, and you can continue were you stop. To store you workspace data use explicit `save.image()` or with optional `save.image(file="evreything.RData")`, you can also store and load specific R objects you can use the functions `save(obj1, obj2,file="objects.RData")` and `load("objects.RData")` to maybe share your data or create a backup. If you find exit prompt annoying you can start `R` with `R --no-save` or `R --save` to automatically answer this prompt. For more convenience you can use the alias system of your shell.
A for plotting with the REPL can be found in [`hello_ggplot.R`][hello_ggplot.R]. If you don't want to type everything use the `source` command from R.
```
$ R
> source('hello_ggplot.R')
httpgd server running at:
  http://127.0.0.1:36329/live?token=JtPoNeQ2
`geom_smooth()` using formula 'y ~ x'
Warning messages:
1: Removed 15 rows containing non-finite values (stat_smooth).
2: Removed 15 rows containing missing values (geom_point).
>
```

The output will contain view warnings we will care about later, but more important its contains a URL to view your newly created plot.


#### Extensions ####

[radian] is an interactive terminal to use `R` with syntax highlighting and autocompletion for multiple options. For interactive usage this can greatly improve the convenience. Radian requires python3 to run and can easily be installed with `pip install -U radian`

[httpgd] is an R package to interactive view your plots. After installing the package you can start a server with `hgd()`. Every time you now have a plot, it will be automatically shown at the specified web address. There you can view the history of plots, changing interactive the zoom level and store the final version in a format you like (e.g. SVG, PDF, PNG). This can save a lot of time for fiddling with the correct display parameters or for just viewing intermediate plots, it also avoids problems R might have with your image viewer.

If you like code completion in your editor or environment you need to install the `R` library `languageserver`, this will install an LSP in `R` for R, which can be used from a wide variety of code completion extensions.

##### VS-Code #####

Visual Studio Code provides an overview about setting it up for `R`[2]. In short, it's required the installation of [httpgd], [radian], the R library `languageserver` and [REditorSupport].
This will allow viewing plots, and run code from your editor. For that you start an R-Terminal need to be started with `Ctrl+Shift+R` `R: Create R terminal`. To which then the current line or a selection of code can be sent with `Ctrl+Enter`. For more details please read the official documentation for [Interaction with R terminals] and the previous referenced sources.

##### NVIM #####

For NVIM and VIM I recommend the plugin Nvim-R, which provides, object viewer, syntax highlighting, documentation viewing and despite its name also works for VIM. In addition, [httpgd] works good since it's allows to view the plots easily. Nvim-R has many features, but you'll likely only need a few of them.

For syntax completion and highlighting my recommendation is to install the R-library `langugaeserver` and use the LSP via the NVIM internal LSP support or for VIM use it via [coc] or similar LSP support plugin.
{{</detail-tag>}}


### R with R-Studio ###

If you like the working out of the box experience and may want to start using `R` for more than basic calculations and plotting you, the IDE RStudio might be the solution of your choice. RStudio offers Srcipt file editing, `R-Repl` execution, viewing data frames and a history of plots created.

{{<detail-tag "**read more**">}}

#### installation ####

Previous to installing RStudio you must install a recent version of R, this can be done via the package manager of your choice or manually from the [RStudio CRAN][rstudio-cran]. With `R` installed the RStudio installer can be fetched from there [download page][RStudio-Download], just select the matching version for your OS or use again the package manager of your trust. Then you are ready go.

> Note: If you are using sway you probably need to set `QT_QPA_PLATFORM=xcb`

#### install packages ####

RStudio provides a list of all installed packages, at the bottom right in the `Packages` tab ([img](#carousel__slide1)).
Checked packages are available in the R-Repl and for Scripts executed in RStudio without explicit loading.
If you want to install new packages you can do this by click on `Install` in the `Package` tab ([img](#carousel__slide2)). The then opened Dialog you can type the packages you want to install (with auto-completion) and may select a CRAN ([img](#carousel__slide3)).

##### Set working directory #####

To effective use the tools in RStudio you should set the working directory accordingly.
Do this under `Session->Set Working Directory->Choos Directory...` or `Ctrl+Shift+H` ([img](#carousel__slide4)).
For the Demo set the working directory to the folder containing [`hello_ggplot.R`][hello_ggplot.R]

##### working with script files #####

With the working directory set you can view the existing files in this directory in the file tab ([img](#carousel__slide5)).
An existing source file in the directory can be opened with double-click the file in the file tab, in this case it should be [hello_ggplot.R](hello_ggplot.R).
Then you can execute a script line by line with `cmd+Enter` or all at once with `cmd+shift+Enter` ([img](#carousel__slide6)).
Now one advantages about using RStudio is that you can now inspect all your data. In the bottom right is a plot tab which shows the newly created plot.
It also allows browsing all plots from the session via the arrow buttons. The same goes for all data objects (primary tables) you created in the session.
They are listed in the top right, and can be further inspected with a double click, which will in the top left (beside your code tab) a tab to inspect the table ([img](#carousel__slide7)).

Now if we might want to change the plot, you can command out the line `geom_smooth(method = "loess", se = FALSE) +` with prepending a `#`.
This will remove the interpolation shown at the bottom. If we now don't want to execute the whole file again we can use multiple times `cmd+enter`
or placing the cursor in line 11 and pressing `cmd+alt+E` to execute every line from the current one until the **E**nd of file ([img](#carousel__slide8)).

The REPL at the bottom left uses the same environment as the scripts executed, therefore you can type single commands if you want to modify data.
You can also use the REPL to install new libraries or apply settings, if you expect it closely you will see that installing new packages or changing the working directory
via the UI will result in an automated typed and executed command in the REPL.


<link rel="stylesheet" type="text/css" href="/css/carousel.css">
<section class="carousel" aria-label="Gallery">
  <ol class="carousel__viewport">
		{{< carousel id="1" prev="4" next="2" show="foobar"
			src="./rstudio/installtab.png"
			caption="List of installed and loaded packages can be found in the `Package` tab." >}}
		{{< carousel id="2" prev="1" next="3"  show="foobar"
			src="./rstudio/update_install.png"
			caption="Use the buttons `Install` to install new packages and `update` to update installed once." >}}
		{{< carousel id="3" prev="2" next="4"  show="foobar"
			src="./rstudio/install_popup.png"
			caption="Write the packages you want to install." >}}
		{{< carousel id="4" prev="3" next="5" show="foobar"
			src="./rstudio/setworkingdir.png"
			caption="Set the working directory to easly access all relevant data." >}}
		{{< carousel id="5" prev="4" next="6" show="foobar"
			src="./rstudio/filetree.png"
			caption="View files in you current working directory." >}}
		{{< carousel id="6" prev="5" next="7" show="foobar"
			src="./rstudio/executeExample.png"
			caption="Execute the file with `cmd+shift+enter` to see the plot." >}}
		{{< carousel id="7" prev="6" next="8" show="foobar"
			src="./rstudio/viewdata.png"
			caption="Old plots can be browsed via the arrow buttons. Also data objects are listed and can be inspected via doubleclick." >}}
		{{< carousel id="8" prev="7" next="1" show="foobar"
			src="./rstudio/newdata.png"
			caption="The script can be changed and reexecuted which will update all other views." >}}
  </ol>
  <aside class="carousel__navigation">
<ol class="carousel__navigation-list">
{{< goto id="1" >}}
{{< goto id="2" >}}
{{< goto id="3" >}}
{{< goto id="4" >}}
{{< goto id="5" >}}
{{< goto id="6" >}}
{{< goto id="7" >}}
{{< goto id="8" >}}
</ol>
  </aside>
</section>



{{</detail-tag>}}

### R in jupyter notebook ##

Additionally, you can also use `R` in Jupyter notebook. For an example please refer the official [documentation][jupyter]

### factors vs numeric ###

Concluding a small caviar in R. R differentiates between factors and numbers, factors are comparable with enum in other languages. They have in a strict order and
are discrete. While numbers represent points in a continues spectrum. Because of there different nature also there visualization is different. If you for example want to plot a numeric values as color, ggplot will use a gradient
to display that continuous value, for factors, it will use a different color for each label / factor.

Most times R will import the data correctly, but if you for example use numbers as labels, you need to manually define which type it is.
This can be easily done by `data$row = as.factor(data$row)`.

## ggplot ##

ggplot is a plotting library written in R. It adopts an R orientation on data frames/tables and data flow instead of command flow. In addition, it provides sensible defaults. Therefore, most commands have many optional parameters, which behaves in sensible manners if let empty. This is also reflected in the construction of plots.
You do not draw individual points, you compose your plot out of layers, each layer therefore representing a kind of geometry, or modification at the axis, legend or theme.

First the general structure of a ggplot plotting script will be shown, followed by examples to layer based construction of plots. After this basics set, the realization of different plot types as there geometry to construct them is listed, followed by customizing the plot, e.g. changing colors, and legend descriptions.

### Hello World ###

```R
library(ggplot2)

data("midwest", package = "ggplot2") # use example data provided by ggplot

# magic code for loading hgd() plot server if not executed as script or in rstudio
is_rstudio <- Sys.getenv("RSTUDIO") == "1"
if (interactive() && ! is_rstudio) {
  library(httpgd)
  hgd()
}

# creating the Scatterplot
gg <- ggplot(midwest, aes(x = area, y = poptotal)) + # mapping between column and axis
  geom_point(aes(color = state, size = popdensity)) + # plot a point for each row
																											# where the labels from column 'state' is displayed as color
																											# and the the value popdentsity as radius
  geom_smooth(method = "loess",	# interpolate data points with loess: Local Polynomial Regression Fitting
							se = FALSE) + # not displaying the confident interval
  xlim(c(0, 0.1)) + # only include data with a x value in [0,0.1]
  ylim(c(0, 500000)) + # onyl include data with a y value in [0,500000]
  labs(subtitle = "Area Vs Population", # set diifferent labels
       y = "Population",
       x = "Area",
       title = "Scatterplot",
       caption = "Source: midwest")

if (interactive()) {
  plot(gg)	# show plot
} else {
  ggsave("plot.pdf", plot = gg) # store plot as pdf
}
```

If you already run that code you may have spotted the warning messages:

```sh
Warning messages:
1: Removed 15 rows containing non-finite values (stat_smooth).
2: Removed 15 rows containing missing values (geom_point).
```

This is a result of setting `xlim` and `ylim`. Because setting limits will ignore data points
outside this limit, which will be 15 in total for that dataset. If you want to zoom in instead of
ignoring data you can use: `coord_cartesian(xlim=c(0,0.1), ylim=c(0,500000)) + `.
You can remove the `xlim` and `ylim` line to remove the error and see how all data plotted will look.
To get a zoomed view add the `coord_cartesian` line. You will see that the interpolation differs from before,
this is because now also points outside the plot will be used for the calculation.

{{< detail-tag "Example without warnings" >}}
```R
library(ggplot2)

data("midwest", package = "ggplot2") # use example data provided by ggplot

# magic code for loading hgd() plot server if not executed as script or in rstudio
is_rstudio <- Sys.getenv("RSTUDIO") == "1"
if (interactive() && ! is_rstudio) {
  library(httpgd)
  hgd()
}

# creating the Scatterplot
gg <- ggplot(midwest, aes(x = area, y = poptotal)) + # mapping between column and axis
  geom_point(aes(color = state, size = popdensity)) + # plot a point for each row
																											# where the labels from column 'state' is displayed as color
																											# and the the value popdentsity as radius
  geom_smooth(method = "loess",	# interpolate data points with loess: Local Polynomial Regression Fitting
							se = FALSE) + # not displaying the confident interval
	coord_cartesian(xlim = c(0, 0.1), ylim = c(0, 500000)) + # only shows plot area in limits
  labs(subtitle = "Area Vs Population", # set diifferent labels
       y = "Population",
       x = "Area",
       title = "Scatterplot",
       caption = "Source: midwest")

if (interactive()) {
  plot(gg)	# show plot
} else {
  ggsave("plot.pdf", plot = gg) # store plot as pdf
}
```
{{< /detail-tag >}}}



### ggplot construction ###

The base of a plot is constructed with the `ggplot` function. In that function
the default arguments for all flowing layers will be defined. The most prominent is the `aes()` aka the axis definition and data.

```R
clima_data <- read.csv("clima_DE.csv")
ggplot(data = clima_data, aes(x = Month, y = Temperature)) +
	geom_point()
```

Which would be equivalent to:

```R
clima_data <- read.csv("clima_DE.csv")
clima_data$Month <- as.numeric(factor(clima_data$Month))
ggplot() +
	geom_point(data = clima_data, aes(x = Month, y = Temperature))
```

this could be useful if data from multiple data frames should be plotted in one plot:

```R
data_DE <- read.csv("clima_DE.csv")
data_IT <- read.csv("clima_IT.csv")
ggplot(mapping = aes(x = Month, y = Temperature)) +
	geom_point(data = data_DE, aes(color = "DE")) +
	geom_point(data = data_IT, aes(color = "IT"))
```

Also, you can see in this example that you can also directly label a dimension (`color`).

The month is currently ordered alphabetic, which is not helpful.

To define a custom factor, we can use the [`factor`][R_factor] command.
The order of the values in the factor also defining the order.

```R
MonthLevels <- c('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec')

data_DE <- read.csv("clima_DE.csv")
data_IT <- read.csv("clima_IT.csv")
ggplot(mapping = aes(x = Month, y = Temperature)) +
	geom_point(data = data_DE, aes(color = "DE")) +
	geom_point(data = data_IT, aes(color = "IT"))
```

If you want to use the factor also as numbers (e.g. smoothing the points to a line)
you can transform a factor to numbers with `as.numeric`.
To keep the axis label tidy we can use `scale_x` for a custom defined x-axis label.

```R
MonthLevels <- c('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec')

data_DE <- read.csv("clima_DE.csv")
data_DE$Month <- as.numeric(factor(data_DE$Month, levels=MonthLevels))
data_IT <- read.csv("clima_IT.csv")
data_IT$Month <- as.numeric(factor(data_IT$Month, levels=MonthLevels))
ggplot(mapping = aes(x = Month, y = Temperature)) +
	geom_smooth(data = data_DE, aes(color = "DE"), method = "loess", se = FALSE) +
	geom_point(data = data_DE, aes(color = "DE")) +
	geom_smooth(data = data_IT, aes(color = "IT"), method = "loess", se = FALSE) +
	geom_point(data = data_IT, aes(color = "IT")) +
	scale_x_continuous(breaks = 1:length(MonthLevels))
```

Other axis can also be defined, like the `color` axis for example to change the labels:

```R
MonthLevels <- c('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec')

data_DE <- read.csv("clima_DE.csv")
data_DE$Month <- as.numeric(factor(data_DE$Month, levels=MonthLevels))
data_IT <- read.csv("clima_IT.csv")
data_IT$Month <- as.numeric(factor(data_IT$Month, levels=MonthLevels))
ggplot(mapping = aes(x = Month, y = Temperature)) +
	geom_smooth(data = data_DE, aes(color = "DE"), method = "loess", se = FALSE) +
	geom_point(data = data_DE, aes(color = "DE")) +
	geom_smooth(data = data_IT, aes(color = "IT"), method = "loess", se = FALSE) +
	geom_point(data = data_IT, aes(color = "IT")) +
	scale_x_continuous(breaks = 1:length(MonthLevels)) +
	scale_color_discrete(name="Country", labels=c("DE"="Germany", "IT"="Italy")) # look here
```

### Plot kinds ###

#### line plot

For Line plots in general two options are provided:
usage of `geom_smooth` to interpolate data
or `geom_line` to directly plot them, fer the second you need to set `group = 1` because of legacy reasons.

```R
data = read.csv("clima_DE.csv")
ggplot(data, aes(x = Month, y = Temperature)) + geom_line(group = 1)
```

If you have multiple lines in your plot each line needs to be in a different group:


```R
data = read.csv("clima_DE.csv")
ggplot(data, aes(x=Month)) +
	geom_line(aes(y=Temperature), group = 1) +
	geom_line(aes(y=Precipitation), group = 2)
```

To distinguish this lines further we can set a color:

```R
data = read.csv("clima_DE.csv")
ggplot(data, aes(x=Month)) +
	geom_line(aes(y=Temperature), group = 1, color = "blue") +
	geom_line(aes(y=Precipitation, group = 2, color = "red")
```

For better readability we can give this colors labels and a legend:

```R
data = read.csv("clima_DE.csv")
ggplot(data, aes(x=Month)) +
	geom_line(aes(y=Temperature, color = "Temp"), group = 1) +
	geom_line(aes(y=Precipitation, color = "Prec"), group = 2)
```

And to set the legend title we can use a custom scale:

```R
data = read.csv("clima_DE.csv")
ggplot(data, aes(x=Month)) +
	geom_line(aes(y=Temperature, color = "Temp"), group = 1) +
	geom_line(aes(y=Precipitation, color = "Prec"), group = 2) +
	scale_color_discrete(name = "Value Type")
```


#### error bars

You can plot confidence intervals or min max values with `geom_errorbar` and `geom_crossbar`.
Both of them require the binding of `ymin` and `ymax` in the `aes`, which denotes where to find these values.
Because of the layering nature you also can use multiple error bars to denote different values, or use a combination of error bars and cross boxes.

```R
data = read.csv("clima_DE.csv")
ggplot(data, aes(x = month, y = temperature)) +
	geom_line(group = 1) +
	geom_errorbar(aes(ymin = temperature_min, ymax = temperature_max), width = 0.1) +
	geom_errorbar(aes(ymin = temperature - 2 * temperature_sig, ymax = temperature + 2 * temperature_sig), width = 0.2) +

ggplot(data, aes(x = month, y = temperatuere)) +
	geom_line(group = 1) +
	geom_errorbar(aes(ymin = temperature_min, ymax = temperature_max)) +
	geom_crossbox(aes(ymin = temperature - 2 * temperature_sig, ymax = temperature + 2 * temperature_sig))
```

#### Scatter plots

If you just want to plot you data points you can use `geom_points`, interesting to notice is that you could denote further information
in the geometry(`shape`) and size(`size`) of the point, beside its color.

```R
data <- read.csv("clima_DE.csv")
ggplot(data, aes(x = Month, y = Temperature)) +
	geom_point(aes(size = Precipitation), shape = 0)
```

Or like in the examples before we can also set the color:

```R
data <- read.csv("clima_DE.csv")
ggplot(data, aes(x = Month, y = Temperature)) +
	geom_point(aes(color = Precipitation), shape = 15, size = 10) # shape 15 is a filled square
```

Also, if a custom color is required like, red for dry month, and blue for rainy, and yellow in between you can define your
own gradient for continues values (`numeric`)

```R
data <- read.csv("clima_DE.csv")
ggplot(data, aes(x = Month, y = Temperature)) +
	geom_point(aes(color = Precipitation), shape = 15, size = 10) +
	scale_color_gradientn(colors = c("red", "yellow", "blue"), limits = c(0, 100), values = c(0, 0.25, 1))
```

In this case we define a gradient between the colors red-yellow and yellow blue, for the scale from 0 to 100,
where red is at 0, yellow at 25 (25 * 100 + 0) and blue at 100.

For more options like log scale or custom labels at breaks, see [here][scale_gradient]

In addition to this basic illustration
ggplot offers interpolation via `geom_smooth`. With `geom_smooth` you can set the interpolation.
The arguments of highest interest are:
* `se: bool` weather or not to print the confident interval
* `method` which method should be uses for interpolation e.g.:
	* `lm` uses a linear model filtering
	* `loess` (default) Local Polynomial Regression Fitting
	* or a function which does the interpolation
* `formular` if you now the relation between x any y you can pass them via this argument, in addition you should set `method = lm`. For example
	* logarithmic: `formular = y ~ log(x), method = lm`
	* polynomial of degree 3: `formular = y ~ poly(x, degree = 3), method = lm`

A usage example can be found in [section ggplot construction](#ggplot-construction)

#### Ribbon plots

Think of ribbon plots as enhanced line plots, where not only do you get a sense of the central tendency (like a mean), but you also see the spread or uncertainty around it—visualized as a shaded 'ribbon'.

A ribbon plot uses 3 aesthetics to display:
+ `y` the mean val
+ `ymin` the lower bound of the ribbon
+ `ymax` the higher bound of the ribbon

```R
huron <- data.frame(year = 1875:1972, level = as.vector(LakeHuron))
ggplot(huron, aes(x=year,y=level)) +
	geom_ribbon(aes(ymin=level-1,ymax=level+1), alpha = 0.2) +
	geom_line()
```

The `alpha` allows seeing other parts of the graph behind the ribbon.
To change the color of the ribbon use the `fill` aesthetic.

#### Custom lines and other annotations

Sometimes you want to plot a reference line. This can be done with `geom_vline`, `geom_hline` and `geom_abline`
```R
ggplot() +
	geom_vline(xintercept=5, color="red") +
	geom_hline(yintercept=5, linetype="dotted") +
	geom_abline(intercept=0, slope=1, color="black")
```

With `annotate` you can print labels/text in your plot:

```R
ggplot() +
	geom_hline(yintercept=5, linetype="dotted", color="red") +
	annotate("text", x = 0, y = 5, label = "Refernce line", vjust=0, hjust=0, size=11)
```

Other handy annotation types are `rect` and `segment`:
```R
ggplot() +
	annotate("rect", ymin=1,ymax=4,xmin=1,xmax=4,fill="green",alpha=0.4) +
	annotate("segment",y=0,yend=5,x=0,xend=5,color="blue")
```

#### Bar plots

Bar plots are a versatile and commonly used type of plot in data visualization, particularly useful for displaying categorical data. In ggplot, creating bar plots is straightforward yet highly customizable. Here, we'll explore the creation and customization of various bar plots using ggplot.

##### Basic Bar Plot / Histogram

A basic bar plot can be created using `geom_bar()`. This function will automatically count the number of occurrences of each category unless otherwise specified.

```R
data <- read.csv("bars.csv")
ggplot(data, aes(x = category)) +
  geom_bar()
```

##### Bar Plot with Values/Weights

To display specific values for each bar, particularly when the data frame contains a column with these values, use `geom_bar()` with `stat = "identity"`.
Please notice that if multiple entries are in the same category,
the values/weigths of these entries will be added.

```R
ggplot(data, aes(x = category, y = value)) +
  geom_bar(stat = "identity")
```

##### Stacked Bar Plot

Stacked bar plots show the total amount for each category, broken down into sub-categories. This is achieved by adding a fill attribute.

```R
ggplot(data, aes(x = category, fill = subcategory)) +
  geom_bar()
ggplot(data, aes(x = category, fill = subcategory, y=value)) +
  geom_bar(position = "dodge", stat="identity")
```

##### Side-by-Side Bar Plot

To compare subcategories side by side, we use position = "dodge" within geom_bar().

```R
ggplot(data, aes(x = category, fill = subcategory)) +
  geom_bar(position = "dodge")
```

##### Overlapping Bar Plot

An overlapping bar plot can be created by setting the position argument to position_dodge() with a specified width, and adjusting the alpha for transparency.

```R
ggplot(data, aes(x = category, fill = subcategory)) +
  geom_bar(position = position_identity(), alpha = 0.5)
```

##### Customizing Bar Plots

ggplot allows extensive customization of bar plots. You can change the colors, add labels, modify axis labels, and more. For instance, to add labels on top of each bar:


```R
ggplot(data, aes(x = category, y = value, fill=subcategory)) +
  geom_bar(stat = "identity", position = "dodge") +
  geom_text(aes(label = value), position=position_dodge(width=1), vjust=0)
```

### decoration layers

This section contains ways to modify the layout of a plot:

#### axis ration

Sometimes you want a ration between your x- and y-axis, like for a speedup over number of processes.
This can be done with `coord_fixed(ratio = 1)`

#### log or sqroot axis

If you want to scale the x- or y-axis you can do this with:
`scale_x_continuous(trans="log10")`

Where trans contains a transformation object, or the name of it.
Default implemented transformations are: `asn`, `atanh`, `boxcox`, `date`, `exp`, `hms`, `identity`, `log`, `log10`, `log1p`, `log2`, `logit`, `modulus`, `probability`, `probit`, `pseudo_log`, `reciprocal`, `reverse`, `sqrt` and `time`. [src][scale_continuous]

#### custom axis labels

`labs(x="X-axis", y="Y-axis", title="My plot", subtitle="y over x axis", caption="A demo plot where we wanted to include a caption, because it is maybe not imcluded in a paper")`

#### custom tick labels

To fit the tick labels you can modify the `labels` attribute in `scale_continuous`.

Beside a list of labels you can also give it a function which transforms a break value to a label.

```R
library(scales)
data <- read.csv("clima_DE.csv")
p <- ggplot(data, aes(x=Month, y=Precipitation)) + geom_line(group=1)

p + scale_y_continuous(labels = scientific)

p + scale_y_continuous(labels = percent)

p + scale_y_continuous(breaks = c(0, 50, 100), labels = c("None", "Some", "Too much"), limits=c(0,100))

label_fn <- function(x) paste("my label: ", x)
p + scale_y_continuous(labels = label_fn)

p + scale_y_continuous(labels = function(x) paste("my label: ", x))
```

#### Legend position and orientation

The position and orientation of legends can also be modified in ggplot.
For this and modifications at the optic (size, color) of labels the `theme` layer is used.

```R
p + theme(legend.position = "top") # legend outside of plot: "left", "right", "bottom", "none"
p + theme(legend.position = c(0.2, 0.8)) # legend inside of plot
p + theme(legend.title = element_text(color = "blue", size = "13", face = "bold")) # legend title/name
p + theme(legend.text = element_text(color = "blue", size = "13", face = "bold")) # text for legend entries
p + theme(axis.text = element_text(color = "blue", size = "13", face = "bold")) # text axis labels
```

A complete list of all theme modules can be found [here][theme].

#### Change grid

If you want to change the grid optic you use the theme modules `panal.grid`.
If you want to set custom breaks you need to define it in the scales.

```R
p +
	theme(
		panal.grid.minor = element_line(),
		panal.grid.major = element_line(),
		panal.grid.major.x = element_line()) +
	scale_y_continouse(breaks = , minor_breaks = ) +
	scale_x_continouse(breaks = , minor_breaks = )
```

A complete list of all themes can be found [here][theme].

## Tricks and enhancing libraries ##

Now we will take a look at libraries and functionality I find handy and will hopefully too:

### zoom in a plot (facets)

Sometimes it is beneficial to zoom in on a portion of a plot.
An easy way for this provides the package [`ggforce`][ggforce].
It provides the function [`facet_zoom()`][facet_zoom] which creates a zoomed in version of the plot.

```R
library(ggforce)
p <- ggplot(iris, aes(Petal.Length, Petal.Width, colour = Species)) +
  geom_point()

p + facet_zoom(x = Species == "versicolor")
p + facet_zoom(x = Species == "versicolor", zoom.size=1)
p + facet_zoom(x = Species == "versicolor", zoom.size=0.5)
p + facet_zoom(y = Species == "versicolor")
p + facet_zoom(xlim = c(1,3))
```

To select the data for the zoomed facet is providing
a vector containing `TRUE` for each element which should be included, or given the limits of the zoomed range.

This can be done for the x- or y-axis respectively.

One important aesthetic argument is `zoom.size` which is the relative size of the zoomed area in relation to the normal plot (default 2).


### Dark themes

If you want to use dark themes for your plots the library
[`ggdark`][ggdark] offers the theme `dark_theme_gray()`.

### `dplyr` for advanced data manipulation

`dplyr` is a library for stream processing data frames. It introduced the stream operator `%>%`.

A handy usage is the calculation of a new column based group depending on values. For example, calculating the speedup for
different setups.

```R
df <- read.csv('messung.csv')
df$parameter_threads <- as.factor(df$parameter_threads)
# group data to calculate speedup relative to execution on one thread for this execution variant
df <- df %>% group_by(parameter_variant) %>% group_map(~ {
	t0 <- .x[.x$parameter_threads==1]$mean # get execution time for one thread in group
	.x$speedup <- t0 / .x$mean # add new column speedup
	.x # return new data frame for group
}) %>% ungroup()

ggplot(df, aes(y=speedup, x = parameter_threads, group=parameter_variant, color=parameter_variant)) +
	geom_line() +
	geom_point() +
	geom_abline(intercept=0, slope=1) +
	coord_fixed() +
	labs(title="Speedup", subtitle="Messung 1", y = "t0/t", x="#Threads", color = "Parallelisierungs Schema")
```

### Compose multiple diagrams with a shared legend

Sometimes you have multiple Plots using the same color legend, and you want to no print the redundant legend.
To hide all legends use `theme(legend.position="none")`, to hide only one legend/guide, (e.g. color) use `guides(color=FALSE)`.

```R
mtcars$cyl<-as.factor(mtcars$cyl)
mtcars$gear <- as.factor(mtcars$gear)
p2 <- ggplot(data = mtcars, aes(x = mpg, y = wt))+
    geom_point(aes(color = cyl, size = qsec, shape = gear))

p2 + theme(legend.position = "none")

p2 + guides(color=FALSE)
```

If you want to arrange multiple plots in one the library [`ggpubr`][ggpubr]. This provides the function `ggarrange`

```R
library(ggpubr)

dsamp <- diamonds[sample(nrow(diamonds), 1000), ]
p <- ggplot(dsamp, aes(y=price, color=clarity))
p1 <- p + geom_point(aes(x=carat))
p2 <- p + geom_point(aes(x=cut))
p3 <- p + geom_point(aes(x=color))
p4 <- p + geom_point(aes(x=depth))

ggarrange(p1, p2, p3, p4, ncol=2, nrow=2, common.legend = TRUE, legend="bottom")
```

## further readings ##

* http://r-statistics.co/Complete-Ggplot2-Tutorial-Part1-With-R-Code.html
* http://r-statistics.co/Top50-Ggplot2-Visualizations-MasterList-R-Code.html
* https://cran.r-project.org/doc/manuals/r-release/R-admin.html
* https://appsilon.com/rstudio-shortcuts-and-tips/

**Referenced in the article:**

* [jupyter]:https://docs.anaconda.com/free/navigator/tutorials/r-lang/
	https://docs.anaconda.com/free/navigator/tutorials/r-lang/
* [radian]:https://github.com/randy3k/radian
	https://github.com/randy3k/radian
* [httpgd]:https://github.com/nx10/httpgd
	https://github.com/nx10/httpgd
* [REditorSupport]:https://marketplace.visualstudio.com/items?itemName=REditorSupport.r
	https://marketplace.visualstudio.com/items?itemName=REditorSupport.r
* [Nvim-R]:https://github.com/jalvesaq/Nvim-R
	https://github.com/jalvesaq/Nvim-R
* [coc]:https://github.com/neoclide/coc.nvim
	https://github.com/neoclide/coc.nvim
* [RStduio-Download]:https://www.rstudio.com/products/rstudio/download/#download
	https://www.rstudio.com/products/rstudio/download/#download
* [rstudio-rcan]:https://cran.rstudio.com/
	https://cran.rstudio.com/
* [hello_ggplot.R]:./examples/hello_ggplot.R
	[./examples/hello_ggplot.R](./examples/hello_ggplot.R)
* [1]:http://www.mas.ncl.ac.uk/~ndjw1/teaching/sim/R-intro.html
	http://www.mas.ncl.ac.uk/~ndjw1/teaching/sim/R-intro.html
* [2]:https://code.visualstudio.com/docs/languages/r
	https://code.visualstudio.com/docs/languages/r
* [Interaction with R terminals]:https://github.com/REditorSupport/vscode-R/wiki/Interacting-with-R-terminals
	https://github.com/REditorSupport/vscode-R/wiki/Interacting-with-R-terminals
* [weather data]:https://data.open-power-system-data.org/weather_data/
	https://data.open-power-system-data.org/weather_data/
* [R_factor]:https://www.rdocumentation.org/packages/base/versions/3.6.2/topics/factor
	https://www.rdocumentation.org/packages/base/versions/3.6.2/topics/factor
* [shapes]:http://www.sthda.com/sthda/RDoc/images/points-symbols.png
	http://www.sthda.com/sthda/RDoc/images/points-symbols.png
* [scale_gradient]:https://ggplot2.tidyverse.org/reference/scale_gradient.html
	https://ggplot2.tidyverse.org/reference/scale_gradient.html
* [scale_continuous]:https://search.r-project.org/CRAN/refmans/ggplot2/html/scale_continuous.html
	https://search.r-project.org/CRAN/refmans/ggplot2/html/scale_continuous.html
* [theme]:https://ggplot2.tidyverse.org/reference/theme.html
	https://ggplot2.tidyverse.org/reference/theme.html
* [ggpubr]:https://rpkgs.datanovia.com/ggpubr/
	https://rpkgs.datanovia.com/ggpubr/
* [ggdark]:https://cran.r-project.org/web/packages/ggdark/readme/README.html
	https://cran.r-project.org/web/packages/ggdark/readme/README.html
* [facet_zoom]:https://ggforce.data-imaginist.com/reference/facet_zoom.html
	https://ggforce.data-imaginist.com/reference/facet_zoom.html
* [ggforce]:https://ggforce.data-imaginist.com/index.html
	https://ggforce.data-imaginist.com/index.html
