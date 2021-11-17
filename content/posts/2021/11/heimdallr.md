+++
title = "heimdallr: Compile time correctness checking for message passing in Rust"
date = "2021-11-17T12:12:19+01:00"
authors = ["michael.blesel"]
tags = ["Correctness checking","Message passing", "Rust"]
+++

In this post we will look at how the Rust programming language and its built-in correctness features can be applied to
the message passing parallelization method. We will see how Rust's memory-safety features can be leveraged to design
a message passing library, which we call heimdallr, that is able to detect parallelization errors at compile time that would
go unnoticed by the compiler when using the prevalent message passing interface MPI.

For the uninitiated reader I will start with a very brief synopsis of message passing.
In the field of high performance computing (HPC) parallel programs are executed on large computing clusters with often
hundreds of computing nodes. Running an application in parallel on more than one computing node requires different
parallelization techniques than multi-threading because the computing nodes do not have shared memory.
Therefore a mechanism for sharing data between processes running on different nodes is needed.
In HPC the standard method of achieving this is called message passing. The applications have to explicitly send and receive
the data that needs to be shared over a network. The most commonly used library for this is called MPI which stands for message
passing interface.

At the start of an MPI application every participating process is given an ID (often called rank) that can be used to differentiate
between them in the code. MPI then provides many different send and receive functions with varying semantics such as blocking/non-blocking
and synchronous/asynchronous and additional collective operations such as barriers for synchronization or broadcast/gather operations.

```c {linenos=true,hl_lines=[1,4,5,13,16,19]}
MPI_Init(NULL, NULL);

int rank,size;
MPI_Comm_rank(MPI_COMM_WORLD, &rank);
MPI_Comm_size(MPI_COMM_WORLD, &size);

double *buf = malloc(sizeof(double) * BUF_SIZE);

if (rank == 0) {
    for (int i = 0; i < BUF_SIZE; ++i) {
        buf[i] = 42.0;
    }
    MPI_Send(buf, BUF_SIZE, MPI_FLOAT, 1, 0, MPI_COMM_WORLD);
}
else if (rank == 1) {
    MPI_Recv(buf, BUF_SIZE, MPI_FLOAT, 0, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
}

MPI_Finalize();
```

Here we can see a simple MPI program. After MPI's initialization in line 1 each process asks for the values of their own `rank` and the number of
overall participating processes (here called `size`) in lines 4-5. The goal of the program is to send a message containing the contents of the
`buf` array from process 0 to process 1. This message exchange happens in lines 13 and 16, where process 0 uses the `MPI_Send` function to send
the message and process 1 receives it with the `MPI_Receive` function.

As we can see the MPI functions take a lot of arguments but only the first four are important to follow this example.
First comes a pointer to the buffer that is being sent or received into. The next two arguments specify the number of elements that are sent and 
their data type, which is needed to calculate the correct number of bytes that will be sent. Lastly the target or source process rank for the
operation is specified. As mentioned in this example process 0 targets process 1 with its send operation and process 1 tries to receive the data
from process 0.

An avid reader might already have spotted that there is a problem in the code of the example. The data type of the `buf` array is `double` but
in the MPI function calls `MPI_FLOAT` is specified. This is in fact a bug and leads to the result that not all of the array's data is transmitted
but only half of it.

These kinds of parallelization errors can be hard to track down in real programs because no crash will occur here but the results of
the program will be wrong. Furthermore the C compiler and the MPI library are not able to detect this error and give the user a warning.
Programming with MPI has many such pitfalls which are often due to MPI's low-level nature combined with the dangers of C memory management with
`void` pointers.

## Compile time correctness through Rust

Rust is a modern system programming language that focuses on memory and concurrency safety with strong compile time correctness checks.
In recent times Rust has garnered more and more attention in circles where C is the current predominant language but a more safe solution is desired.
In the field of HPC C/C++ and Fortran are by far the most used languages. They provide great performance, have been around for a long time and
there exists a lot of infrastructure in the form of libraries and tools for them. However these languages do come with their drawbacks which can 
often be found in aspects like usability, programmability and a general lack of modern features.

Developing massive parallel programs for HPC is a complicated task and in our opinion the languages and libraries used should provide the developers
with as much help as possible. Therefore we asked ourselves whether a language like Rust could provide an easier programming experience for message
passing applications by avoiding and detecting as many errors in parallel code as possible at compile time.

Out of this research a Rust message passing library called heimdallr was developed. Heimdallr should currently be seen as a prototype implementation
but it already has good examples of correctness checks that are currently nonexistent for MPI.

## Eliminating type safety errors with generics

In the previously given example one might ask themselves why it is necessary for the user to manually specify the concrete data type
of a buffer when this is information that a compiler should absolutely be able to derive by itself.
The type safety problems with MPI stem from the fact that the whole API works on untyped memory addresses for data buffers via the use of
C's `void` pointers to allow the MPI functions to work with any type of data. The type information is therefore explicitly discarded and
must be manually passed to a MPI function call by the user.


```c {linenos=true,hl_lines=[1,8,10]}
let client = HeimdallrClient::init(env::args()).unwrap();
let mut buf = vec![0.0;BUF_SIZE];

if client.id == 0 {
    for i in 0..BUF_SIZE {
        buf[i] = 42.0;
    }
    client.send(&buf, 1, 0)?;
} else if client.id == 1 {
    buf = client.receive(0, 0)?;
}
```

Here we see an equivalent program written in Rust with our 'heimdallr' message passing library. First of all, it is apparent that the message passing code is
less verbose when compared to its MPI counterpart. Our design principles with heimdallr where safety and usability. From the usability perspective we
can see that some of the boilerplate code that is necessary in MPI, like for example manually asking for and storing a process's rank variable is not required
with heimdallr. 

More importantly the previously discussed type safety issue for sending a data buffer does not come up with heimdallr. We are making use of the language's
generic programming features to let the compiler handle the type deduction of a transmitted variable, which does not only make it more safe but also
easier to use for a developer.

Of course Rust is by far not the only modern language to provide generic programming features and this interface change to the `send` and `receive`
functions could have been done in a myriad of languages. Therefore we should go on to an example where some of Rust's unique features allow us
to provide a safer message passing interface to the users.


## Ensuring buffer safety for non-blocking communication

As previously mentioned MPI provides multiple send and receive functions with varying semantics. The mos basic form of message passing is called
'blocking'. When a message passing function is called in this context the sender process is blocked until the contents of the data buffer that is being
sent guaranteed to have been processed by the message passing library. The receiving process is also blocked until the contents of the incoming message
have been safely copied into the receiving data buffer. This form of message passing is the most intuitive from a users perspective but it can also be
subpar from a performance perspective due to the resulting idle time for both processes.

A often better solution from the performance perspective is the use of so called 'non-blocking' communication. Here the process of passing the message
is handled in the background and the program can continue with its execution almost immediately. This type of message passing however does not come
without dangers, as we will see in the following code snippet.


```c {linenos=true,hl_lines=[2,4,7]}
if(rank == 0) {
    MPI_Isend(buf, BUF_SIZE, MPI_DOUBLE, 1, 0, MPI_COMM_WORLD, &req);
    for(int i = 0; i < BUF_SIZE; ++i)
        buf[i] = 42.0;
}
else if(rank == 1) {
    MPI_Recv(buf, BUF_SIZE, MPI_DOUBLE, 0, 0, MPI_COMM_WORLD, &status);
}
```

In this example process 0 tries to send a buffer to process 1 using MPI's non-blocking send function `MPI_Isend`. 
The non-blocking send operation in line 2 allows process 0 to continue its execution before the sending of the message has concluded.
The problem arises in lines 3-4 where process 0 also modifies the contents of the data buffer that is being sent.
Since the message passing process might still be running this may also modify the contents of the sent message and thereby cause a program
error because this behavior was not intended by the programmer.

This is a known safety issue with the use of non-blocking communication in MPI. A data buffer that is used in a non-blocking operation
is in an 'unsafe' state until it has been made sure that the message passing operation on it has concluded. To check the status of a
non-blocking operation an thereby the safety status of its data buffer MPI provides functions like `MPI_Wait` that blocks the 
current process until the referenced message passing operation is confirmed to be finished. The MPI standard requires such a function
to be called before accessing a data buffer again that has been used in non-blocking communication. Adding a `MPI_Wait` call
between lines 2-3 of the example code would make this program work correctly.

The problem with all of this is that MPI requires the programmer to always remember this behavior and neither the library nor the compiler
are able to detect and warn users of potential errors with buffer safety for non-blocking communication.

## Leveraging Rust's ownership for buffer safety

The core concept of Rust's memory management is the so called 'ownership' feature. Ownership works in a way that every data object in Rust
has exactly one owner. Once the owner variable goes out of scope the data is automatically deallocated. There can be references to an object
but only within a limited rule-set. A variable can either have an unlimited number of immutable (read-only) references or exactly **one**
mutable reference. These limitations allow the Rust compiler to reason about correct memory usage.

```c {linenos=true,hl_lines=[2,3,8]}
if client.id == 0 {
    let handle = client.send_nb(buf, 1, 0)?;
    buf = handle.data()?;
    for i in 0..BUF_SIZE {
        buf[i] = 42.0;
    }
} else if client.id == 1 {
    buf = client.receive(0, 0)?;
}
```

This is the heimdallr equivalent of the non-blocking MPI code that we have seen previously. The send operation in line 2 makes use of Rust's ownership
concept to  protect the data buffer that is being sent. Since there can be only one owner of the `buf` variable passing it directly to a function call
means that the ownership is moved into the function. This has the side effect that `buf` is no longer accessible from outside the function.
Therefore it is impossible to modify the data buffer while the message passing operation is running. Trying to do so would lead to a compilation error.
For a user to access the data again they need to request ownership back from the message passing operation, which happens in line 3.
The there called `data` function of the `handle` that was returned by the non-blocking send function is an equivalent to `MPI_Wait`.
It blocks until the used data buffer is safe to be accessed again and then returns the ownership to the caller.

So in essence it is the same workflow as for an MPI application, but Rust's ownership rules allow the library to be designed in a way where
correct and safe usage of non-blocking communication can be enforced at compile time. This is a big step up in usability and correctness
because it is no longer on the user to remember the implicit rules of non-blocking communication but instead it is a detected program error
if the correct procedure is not followed.

This is of course just one small example on how the safety features of Rust can be used to design safer interfaces but in my opinion in showcases
the possibilities very well.

## Conclusion and further reading

This blog post is supposed to give a brief overview on the challenges of message passing parallelization and how the programming interfaces used
for it could be designed in a safer way. Parallel programming is a complex topic and introduces a variety of new error classes.
Therefore we find it very important that the libraries and tools used for it offer as much help as possible to developers by enforcing correctness
and detecting possible errors. 

The heimdallr library introduced in this post is a prototype implementation of a message passing library that 
concentrates on the compile time correctness aspects. It is not yet feature complete and is mainly supposed to show some of the open possibilities
for better usability and safety in MPI.

To keep this post brief I have not gone into too much detail about the implementation and some of the open problems with this solution.
Heimdallr does have some open problems which I could not go over here without making this blog way too long. We also did not talk about
the performance aspects, which is quite an important topic in the context of using it for HPC.

If your interest was piqued a more detailed discussion about the pros and cons of heimdallr can be found in our [heimdallr paper](https://doi.org/10.1007/978-3-030-90539-2_13).
There we also discuss some of the problems with the current implementation and show benchmark results where heimdallr's performance is compared to MPI.

If you would like to try out heimdallr or have a look at the code you can visit our [github](https://github.com/parcio/heimdallr) page.
