# Concolic Execution
This document explains the use of concolic mode execution in Klee. 
In order to use this behavior you need to use the custom Klee version at Github Repo: https://github.com/rshariffdeen/klee.git , Git Branch: concolic.
You can either build the custom Klee using standard build instructions or use the docker image hosted at
https://hub.docker.com/r/rshariffdeen/klee. 

### Use Docker
To use the docker image pull the docker image to your PC
```
docker pull rshariffdeen/klee
```

## Example
Let's use an example to show the usage and features of the concolic execution.
We will use a real-world application 'Jasper' (https://github.com/mdadams/jasper) for this purpose. Following demonstrate the use
of command line arguments and file inputs to be used for the concolic
execution of a program. 

### Preparing Application
In order to use the application we first need to obtain the LLVM bitcode
which KLEE can operate on. You have two options;

* Use clang compiler with `-emit-llvm` flag
* Use wllvm compiler to obtain the complete bitcode for the whole program

For our example program 'Jasper' we simply use the make command by substituting 
the compiler to wllvm. In our example we will use the binary `imginfo` which simply
takes an image as an input and outputs information about the image.

```
autoreconf -i
CC=wllvm ./configure CFLAGS='-g -O0 -static'
make -j32
cd src/appl/
extract-bc imginfo
```

Now that we have obtained the bitcode for the `imginfo` binary, we can verify
it works with Klee using the following command, which prints the help menu of `imginfo`. 

```
klee --libc=uclibc --posix-runtime imginfo.bc -h
```

### Preparing Input
We make use of the ktest reproducing feature in Klee to execute a test case (i.e. concrete values)
in Concolic execution. For this purpose we re-arrange our input in ktest file format using the binary `gen-bout` and the 
following command:

```
gen-bout --sym-file <path/to/file>
```

This will produce a output named `file.bout` which is a ktest file, and can be
verified using the following command:

```
ktest-tool file.bout
```


#### Command Line Input
All preparations for the concolic execution are complete at this point,
the final step is to execute Klee in concolic mode. First, we will illustate
the use of concrete mode in Klee, using the following command:

```
klee --write-smt2s --libc=uclibc --posix-runtime imginfo.bc /input/image/path
```

This should execute the concrete input in Klee environment without any symbolic
analysis. If we check the symbolic path for this run in `klee-last/test00001.smt2`, the 
content would be empty. Now lets run the same image in concolic method using the 
following command:

```
klee --write-smt2s --libc=uclibc --posix-runtime --seed-out=file.bout imginfo.bc -f A --sym-files 1 <size of file>
```

In the above command `--seed-out` argument is used to feed the ktest file and invoke
the concolic mode in Klee. We make use of the klee symbolic environment to mark
our input as symbolic while using the ktest to maintain its symbolic values. Since,
we are using a input file the input should also reflect that using `<A/B/C> --symbolic-files <NUM> <N>` where
A/B/C is a identifier for each file in the given order, NUM is the number of files and
N is the file size for each. 

Once the concolic execution is complete, you can verify using the path
constraints collected at `klee-last/test00001.smt2`. 

#### Additional Analysis
If you need to collect the symbolic values of program variables,
you should instrument your source code using the intrinsic function `klee_print_expr()`
which will print the symbolic expression for the current test case. Note that,
this will only print the expression in terms of the input we marked as symbolic. 

Current implementation only marks input files as symbolic, however this can be extended to 
mark other types of inputs as symbolic and internal variables inside the program as well. 