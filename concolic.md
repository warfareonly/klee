# Concolic Execution
This document explains the use of concolic mode execution in Klee. 
In order to use this behavior you need to use the custom Klee version at Github Repo: https://github.com/rshariffdeen/klee.git , Git Branch: seedmode-external-calls.
You can either build the custom Klee using standard build instructions or use the docker image hosted at
https://hub.docker.com/r/rshariffdeen/klee. 

### Use Docker
To use the docker image pull the docker image to your PC
```
docker pull rshariffdeen/klee
```

## Example
Let's use an example to show the usage and features of the concolic execution.
We will use a real-world application 'Jasper' for this purpose. Following demonstrate the use
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
#### Command Line Input

