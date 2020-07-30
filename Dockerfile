FROM ubuntu:16.04
MAINTAINER Ridwan Shariffdeen <ridwan@comp.nus.edu.sg>

RUN apt-get update && apt-get install -y \
    autoconf \
    bison \
    cmake \
    curl \
    flex \
    git \
    google-perftools \
    libboost-all-dev \
    libgoogle-perftools-dev \
    libncurses5-dev \
    minisat \
    nano \
    ninja \
    perl \
    python \
    python-pip \
    software-properties-common \
    subversion \
    unzip \
    zlib1g-dev \
    wget
RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key| apt-key add -


ENV LLVM_VERSION=6.0

RUN apt-get install -y clang-${LLVM_VERSION} \
                       llvm-${LLVM_VERSION} \
                       llvm-${LLVM_VERSION}-dev \
                       llvm-${LLVM_VERSION}-tools


RUN mkdir /stp; git clone https://github.com/stp/stp.git /stp/source
RUN mkdir /stp/build; cd /stp/build; cmake ../source/; make -j32; make install


RUN mkdir /klee; git clone https://github.com/klee/klee-uclibc.git /klee/uclibc
RUN cd /klee/uclibc; ./configure --make-llvm-lib; make -j32;
RUN curl -OL https://github.com/google/googletest/archive/release-1.7.0.zip; mv release-1.7.0.zip /klee/test.zip; cd /klee; unzip test.zip;
RUN git clone https://github.com/rshariffdeen/klee.git /klee/source; cd /klee/source; git checkout concolic
RUN mkdir /klee/build; cd /klee/build;  cmake -DCMAKE_CXX_FLAGS="-fno-rtti"   -DENABLE_SOLVER_STP=ON   -DENABLE_POSIX_RUNTIME=ON   -DENABLE_KLEE_UCLIBC=ON   -DKLEE_UCLIBC_PATH=/klee/uclibc  -DGTEST_SRC_DIR=/klee/test  -DENABLE_SYSTEM_TESTS=OFF   -DENABLE_UNIT_TESTS=OFF ../source/;
RUN cd /klee/build; make -j32; make install
 cmake \
        -DENABLE_SOLVER_Z3=ON \
        -DENABLE_POSIX_RUNTIME=ON \
        -DENABLE_KLEE_UCLIBC=ON \
        -DKLEE_UCLIBC_PATH=/klee-uclibc \
        -DENABLE_UNIT_TESTS=OFF \
        -DENABLE_SYSTEM_TESTS=OFF \
            .. && \
    make

RUN git clone https://github.com/Z3Prover/z3.git /z3;
RUN cd /z3; git checkout z3-4.8.1; python scripts/mk_make.py;
RUN cd /z3/build; make -j32; make install
ENV PYTHONPATH=/z3/build/python


# Tidy up the container
RUN DEBIAN_FRONTEND=noninteractive apt-get -y autoremove && apt-get clean && \
     rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
