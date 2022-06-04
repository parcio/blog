+++
title = "Rust for Python developers: using basic Rust to optimize your python Code"
date = "2022-05-24"
authors = ["david.hausmann"]
tags = ["Rust", "Python"]
+++

This post covers how to use Rust and PyO3 to optimize existing Python projects. It will also give you a basic introduction to Rust on the way 

<!--more-->
  
## Example Program
The following python program creates a simple visualisation of the mandelbrot set in matplotlib. It takes about 20s to finish on my machine.

```python
import matplotlib.pyplot as plt
import math
import numpy as np
from time import time
 
def simple_stability(real:float, imag:float, max_iterations:int=100) -> int:
    zr = 0
    zi = 0
    for i in range(max_iterations):
        new_zr = zr**2 - zi**2 + real
        zi = 2 * zr * zi + imag
        zr = new_zr
        if math.sqrt(zr**2 + zi**2) > 2:
            return i
    return max_iterations
 
 
def main():
    start = time()
    values = []
    for y in np.linspace(-2, 2, 1000):
        line = []
        for x in np.linspace(-2, 2, 1000):
            line.append(simple_stability(x, y))
        values.append(line)
    values = np.array(values)
    print(time() - start)
    plt.imshow(values)
    plt.show()
 
if __name__ == '__main__':
    main()
```

We can see that most of the calculation time is spent in `simple_stability`, which makes it a performance critical function. This means that any speed up we achieve for simple_stability will also have a big impact on the overall performance of our program. 
With that in mind, let’s try translating this function into Rust.

## First Steps in Rust
Rust is a compiled language unlike Python, which is interpreted. This means that we can’t just start writing .rs files and run them from the console (or IDE). We have to compile them first.

Rust has an excellent tool called Cargo, that takes care of all our compilation and dependency management needs. 
To create a new “Crate” aka a new Rust project using Cargo. Run ```$ cargo new --lib mandelbrot_module``` in the directory of your choice. 
(install Rust and Cargo if you have not done so already)  
The contents of your new directory should look something like this:
```
mandelbrot_module/
├─ src/
│  ├─ lib.rs
├─ .gitignore
├─ Cargo.toml
```
This is the standard structure for all Rust crates.  
/src is where all our source code will be stored and cargo requires a specific name for our main file.  
If we were trying to write an executable our main file would be /src/main.rs and the execution of our compiled program would start in the `main` function of that file.  
Since we want to write a Library / Module our main file is going to be lib.rs and everything we might want to use from our library after compilation needs to be available from this file. 

Since Cargo already wrote some test code into our lib.rs, let’s run it to see that everything works.  
To do this run ```$ cargo test``` anywhere within the main directory of the crate.  

Test Code:
```rust
#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        assert_eq!(2 + 2, 4);
    }
}
```
Expected Console Output:
```
running 1 test
test tests::it_works ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

   Doc-tests mandelbrot_module

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
```

You should now have a /target directory in your crate. This directory contains all the files that get created during compilation, but we don't actually need it for this project.

We do however need to add PyO3 to our crates dependencies before we can start using it, so let’s do that now.
Adding dependencies to a crate is normally pretty simple. You just have to write the dependency name and version number under `[dependencies]` in your Cargo.toml file like this:
```
[dependencies]
threadpool = "1.8.1"
```
But PyO3 needs some extra configuration which I won’t explain in this post.
Just paste the following into your Cargo.toml file
```
[package]
name = "mandelbrot_module"
version = "0.1.0"
edition = "2018"

[lib]
name = "mandelbrot_module"
crate-type = ["cdylib"]

[dependencies.pyo3]
version = "0.15.1"
features = ["extension-module"]
```

With that done, let’s write some actual Rust code in lib.rs.

## Rust Functions
We’re going to start by just writing the function how you would in a pure rust program.

```rust
fn simple_stability(real:f64, imag:f64, max_iterations:usize) -> usize {
    let mut zr = 0f64;
    let mut zi = 0f64;
    for i in 0..max_iterations {
        let new_zr = zr.powi(2) - zi.powi(2) + real;
        zi = 2.0 * zr * zi + imag;
        zr = new_zr;
        if (zr.powi(2) + zi.powi(2)).sqrt() > 2.0 {
            return i;
        }
    }
    return max_iterations;
}
```

Let’s first look at the function declaration which looks pretty similar to it’s Python counterpart.  
Rust uses the `fn` keyword instead of `def` to declare functions. It also uses different names for its types. `f64` is a 64 bit float which is equivalent to python floats and C’s double type. 32 bit floats are `f32`.  
Integers in Rust use a similar naming scheme. The ‘u’ in `usize` tells us that we’re dealing with an unsigned integer. The ‘size’ means that the size of our integer is dependent on our operating system, so this type would be equivalent to `u64` on a 64bit OS and to `u32` on a 32bit OS. If we wanted to use more than just positive integers we could use `isize` and the same naming scheme applies to ‘i’-types.  
There are also integer types that fit into a single byte with `i8` and `u8`.  
Choosing a smaller type can make a huge difference in your programs memory usage and even performance so Rust takes typing very seriously. While type annotations in function declarations are only recommended and not mandatory in Python they are mandatory in Rust. In fact, the type of every variable has to be known at compile time or rust simply won’t compile your code. This may sound like a lot of type annotations, but the compiler does a great job at inferring a variable’s type most of the time.  
Note also that Rust functions do not support optional arguments so we always have to specify `max_iterations` with our new function. 

Let’s take a look at the declaration of `zr` and `zi` now. They’re both `f64`’s as can be inferred from the right handside of their declaration.
The `let` keyword is used to declare a new variable and the `mut` keyword specifies that this variable is mutable. Variables declared without `mut` are immutable. This might seem weird at first, but it actually makes the code more readable by telling you which values will change throughout this function's runtime.  

The rest of this code looks remarkably similar to its Python equivalent with the exeption, that rust has no power operator and that `sqrt` is a method of float types instead of being an import from the `math` module.

## Using PyO3 
We just need to make this function accessible in a Python module now.
First of all, let’s import  pyo3.  
```use pyo3::prelude::*;```   
Importing external crates in Rust is done via the ‘use’ keyword. The `::` are used to specify namespaces in Rust. The namespace `prelude` is a Rust convention and contains most functionality you’d need from this crate. We import everything from prelude the same way we would in Python via the `*` operator.

Every function we want to include in our final python module needs to be annotated with ```#[pyfunction]```. This is a ‘macro’ that will make some changes to our code during compilation to make it compatible with Python. 

```rust
#[pyfunction]
fn simple_stability(real:f64, imag:f64, max_iterations:usize) -> usize {
    // ...
}
```

It’s not always this simple though, because some Rust types can’t be converted to and from Python types. A list of all Rust types that implement `IntoPy` and are therefore valid argument and return types in a PyO3 pyfunctions can be found here:  https://docs.rs/pyo3/latest/pyo3/conversion/trait.IntoPy.html 

The last Thing we need before compilation is a piece of boilerplate code to assemble our module. Copy paste the following at the end of your lib.rs file.
```rust
#[pymodule]
fn mandelbrot_module(_py: Python, m: &PyModule) -> PyResult<()> {
    m.add_function(wrap_pyfunction!(simple_stability, m)?)?;
 
    Ok(())
}
```
The `#[pymodule]` macro stitches our Python module together from the function we attach it to. It's important, that your module has the same name as this function or Python won't be able to find it.  
The code for adding a function is a bit advanced and you don't really need to understand what's going on here.
just add another line of ```m.add_function...``` and replace the ‘`simple_stability`’ with the name of your function if you want to add another function to this module.


We can now finally build our module and try using it in our python program. There are multiple ways of going about this, but we are going to use maturin in this post. (have a look at https://pyo3.rs/latest/building_and_distribution.html#manual-builds if maturin doesn't suit your needs)

To use maturin we first need to create a virtual environment in our mandelbrot_module folder and then install and run maturin in said virtual environment.

```
$ py -m venv .env
$ ./.env/scripts/activate
$ pip install maturin
$ maturin develop
``` 
You should now see some build output in your console while maturin compiles your module. And it should finish with  
```🛠  Installed mandelbrot_module-0.1.0```

Let’s confirm that our module actually works. 
Drag the previous python program into the mandelbrot_module Folder and modify it so that it uses our new Rust module.
```python
import matplotlib.pyplot as plt
import numpy as np
from time import time
from mandelbrot_module import simple_stability
 
def main():
    values = []
    for y in np.linspace(-2, 2, 1000):
        line = []
        for x in np.linspace(-2, 2, 1000):
            line.append(simple_stability(x, y, 100))
        values.append(line)
    values = np.array(values)
    plt.imshow(values)
    plt.show()
 
if __name__ == '__main__':
    start = time()
    main()
    print(time() - start)
```

This new version of our program takes about 4.6s on my machine, which means we achieved a speedup of more than 400%! 
This Example is very simple and was specifically chosen to be translated into Rust so our speedup is close to a best case scenario, but it shows how powerful translating performance critical tasks into Rust can be.

## Writing Python Classes in Rust
Your real world code will most likely not be this simple. You might for instance have many different functions that rely on one or two classes for some shared functionality. In this case you could translate your class to improve your code’s performance. 

We are going to implement a complex-number class because our `simple_stability` function has been doing complex calculations all along. `zr`, `zi`, `real` and `imag` are the real and imaginary components of two complex numbers z and c. And our function is iterating over the formular z(n+1) = z(n)^2 + c with z(0) = 0 + 0i.

Let’s start with structs then. Rust’s rough equivalent to classes. 
Here is the declaration for a complex-number struct:
```rust
struct Complex {
    real: f64,
    imag: f64
}
```
Simply use the `struct` keyword followed by your structs name and a declaration of the data types that will be stored in your struct.  
We can now create objects of the type `Complex` with similar syntax.
```rust
fn _example1() {
    let _origin = Complex {
        real: 0.0,
        imag: 0.0
    };
}
```

Next up, we're going to create an `impl` block to implement the methods we need for our calculations.
```rust
impl Complex {
    fn new(real: f64, imag: f64) -> Self {
        return Complex {
            real: real,
            imag: imag
        };
    }
 
    fn add(self, other: Self) -> Self {
        return Self::new(self.real + other.real, self.imag + other.imag);
    }
 
    fn sub(self, other: Self) -> Self {
        return Self::new(self.real - other.real, self.imag - other.imag);
    }
 
    fn mul(self, other: Self) -> Self {
        let new_real = self.real * other.real - self.imag * other.imag;
        let new_imag = self.real * other.imag + self.imag * other.real;
        return Self::new(new_real, new_imag);
    }
 
    fn dist_from_origin(self) -> f64 {
        return (self.real.powi(2) + self.imag.powi(2)).sqrt()
    }
}
```
Notice that our methods use an uppercase `Self` and a lowercase `self`.  
Lowercase `self` refers to the object that this method is called on just like in python.  
Uppercase `Self` is shorthand for the type that we’re implementing this method for. So the `add` method takes an object of type `Complex` as an argument and also returns an object of type `Complex`

Let’s try using these Methods in some actual Rust code.
```rust
fn complex_test() {
    let x = Complex::new(1.0, 2.0);
    let y = Complex::new(-1.0, -2.0).add(x);
    let z = y.mul(x);
}
```
If we try to compile this code we will get this error:
```
error[E0382]: use of moved value: `x`
  --> src\lib.rs:82:23
   |
80 |         let x = Complex::new(1.0, 2.0);
   |             - move occurs because `x` has type `Complex`, which does not implement the `Copy` trait
81 |         let y = Complex::new(-1.0, -2.0).add(x);
   |                                              - value moved here
82 |         let z = y.mul(x);
   |                       ^ value used here after move
```
This error is a result of Rust’s “ownership” rules I mentioned earlier. So what is ownership?

## Ownership in Rust 
The basis of ownership is that every value has exactly one variable that “owns” it, and it gets automatically deallocated as soon as it’s owner variable leaves the current scope. This enables Rust to have automatic deallocation without a garbage collector.

The following example Code shows when values get dropped (deallocated) in Rust and how ownership gets moved between two values.
The `DropMe` struct used in this example will print a message to the console as soon as it’s value gets dropped.
```rust
fn drop_example() {
    let a = DropMe{val: 'a'};
    let b = DropMe{val: 'b'};
    {
        let other_b = b; // takes ownership
        // other_b leaves scope here
    }
    println!("b has been dropped");
    println!("a drops after this");
    // a leaves scope here
}
```
```
Output:
> dropping b
> b has been dropped
> a drops after this
> dropping a
```

We can see that the ownership of the value we initially stored in `b` gets moved to `other_b`, which then leaves the inner scope delimited by `{}`. This results in the value getting dropped and a message being written to the console. After this we print two more messages and then reach the end of the function. At this point `a` leaves the current scope and it’s value also gets dropped.  

It’s important to note that `b` becomes invalid after losing ownership of it’s value. This is the reason for the error we just encountered. We moved the value of `x` into the `add` function. After this `x` becomes invalid so we can’t use it again in the next line.

The reason we haven’t encountered this problem sooner is that numerical values like floats and integers are so small that they can be copied just as fast as references to them can be created so they just get copied and no ownership transfer takes place. (This is the “Copy trait” the error message mentions)

Giving up ownership to functions is obviously a huge problem if we want to work with any kind of function, because we want to reuse our values most of the time. We could simply copy our values before moving them into a function, but this gets expensive fast with bigger structs.

Rust has another system called borrowing instead.  
Borrowing a value lets us create a reference to said value without taking ownership of it. The actual owner of our value get’s disabled until all references to it get dropped. 

There are two types of references in Rust.  
Immutable `&` references, that give read-only access to the value they reference.  
Mutable `&mut` references, that let you modify their referenced value.  

You can either have arbitrarily many immutable references or only one mutable reference to a single value at any given point in time. This is to ensure that there is never more than one variable in your program that can modify a given value, which prevents a lot of tricky errors and data races.
```rust
Example:
fn foo(x: DropMe) {
    println!("foo {}", x.val);
}
fn foo_immut(x: &DropMe) {
    println!("foo_immut {}", x.val);
}
fn foo_mut(x: &mut DropMe) {
    println!("foo_mut {}", x.val);
    x.val = 'm';
}
fn borrowing_example() {
    let a = DropMe{val: 'a'};
    let b = DropMe{val: 'b'};
    let mut c = DropMe{val: 'c'};
    foo(a);
    foo_immut(&b);
    foo_mut(&mut c);
    println!("end.");
}
```
```
Output:
> foo a
> dropping a
> foo_immut b
> foo_mut c
> end.
> dropping m
> dropping b
```
You can see that `a` gets dropped as soon as `foo` finishes, because it takes ownership of it’s arguments. The other two values  only get dropped at the end of the main example function because their functions did not take ownership. (You can also see that Rust drops values in the opposite order they were created to not break any possible dependencies between them.)

We can just change all the arguments of our class methods to immutable references, because we don’t need to modify them. This step was also necessary to make our methods compatible with PyO3, because Rust can’t take ownership of Python values (because ownership doesn’t exist in Python). So we had to either copy our method arguments or take references to them instead.

After adding the references and the necessary PyO3 macros, our code looks like this:
```rust
#[pyclass]
struct Complex {
    real: f64,
    imag: f64
}
 
#[pymethods]
impl Complex {
    #[new]
    fn new(real: f64, imag: f64) -> Self {
        return Complex {
            real: real,
            imag: imag
        };
    }
 
    fn add(&self, other: &Self) -> Self {
        return Self::new(self.real + other.real, self.imag + other.imag);
    }
 
    fn sub(&self, other: &Self) -> Self {
        return Self::new(self.real - other.real, self.imag - other.imag);
    }
 
    fn mul(&self, other: &Self) -> Self {
        let new_real = self.real * other.real - self.imag * other.imag;
        let new_imag = self.real * other.imag + self.imag * other.real;
        return Self::new(new_real, new_imag);
    }
 
    fn dist_from_origin(&self) -> f64 {
        return (self.real.powi(2) + self.imag.powi(2)).sqrt()
    }
}
```
`#[pyclass]` and `#[pymethods]` perform the usual PyO3 magic of making our code compatible with Python. `#[new]` designates our `new` method as our class’ constructor, meaning it will be called if we try to create a new `Complex` object from Python.

We then add our new class to our Python module.
```rust
#[pymodule]
fn mandelbrot_module(_py: Python, m: &PyModule) -> PyResult<()> {
    m.add_function(wrap_pyfunction!(simple_stability, m)?)?;
    m.add_class::<Complex>()?;
 
    Ok(())
}
```

Once again you don’t need to understand what’s going on here. Just copy and paste the `m.add_class...` line and replace `Complex` with the name you gave your struct.

Finally we run ```$ maturin develop``` once again and integrate our new class into our example Python program.
```python
import matplotlib.pyplot as plt
import numpy as np
from time import time
from mandelbrot_module import Complex
 
def complex_stability(real:float, imag:float, max_iterations:int=100) -> int:
    c = Complex(real, imag)
    z = Complex(0, 0)
    for i in range(max_iterations):
        z = z.mul(z).add(c)
        if z.dist_from_origin() > 2:
            return i
    return max_iterations
 
def main():
    start = time()
    values = []
    for y in np.linspace(-2, 2, 1000):
        line = []
        for x in np.linspace(-2, 2, 1000):
            line.append(complex_stability(x, y, 100))
        values.append(line)
    values = np.array(values)
    print(time() - start)
    plt.imshow(values)
    plt.show()
 
if __name__ == '__main__':
    main()
```

This iteration of our program is... actually much slower at about 2 min.
This is probably because we spend a lot of time on switching between Rust and Python and creating new `Complex` objects, while the original program just ran some floating point operations instead, which have presumably already been heavily optimised using C.

I can say from experience though that translating bigger classes with more involved methods can significantly speed up your programs.

This concludes our Rust tutorial for Python programmers.  
I hope that this post has sparked your interest for Rust and has given you ideas on how to use it in your existing projects.  
If you want to learn more about rust check out the “Rust book”: https://doc.rust-lang.org/stable/book/  
If you want to learn more about PyO3 check out it’s official user guide: https://pyo3.rs/v0.15.1/  
The code for this post and the project it was based on can be found on my github:  
https://github.com/DrunkJon/Rust-for-Python-Example  
https://github.com/DrunkJon/MandelbrotViewer  
